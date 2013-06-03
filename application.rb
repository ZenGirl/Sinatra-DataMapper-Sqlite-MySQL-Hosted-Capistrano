# ---------------------------------------------------------------------------
# Obviously need this.
# ---------------------------------------------------------------------------
require 'sinatra'

# ---------------------------------------------------------------------------
# For providing JSON responses
# ---------------------------------------------------------------------------
p 'Requiring JSON responses'
require 'json'

# ---------------------------------------------------------------------------
# For using regex matching of IPv4 addresses
# ---------------------------------------------------------------------------
p 'Requiring IPv4 Regex resolution'
require 'resolv'
# ---------------------------------------------------------------------------
# You could use ipaddr instead of resolv, like this:
# ip = IPAddr.new(range[:from], Socket::AF_INET).to_s
# ---------------------------------------------------------------------------
#require 'ipaddr'

# ---------------------------------------------------------------------------
# For MD5 digests in vendor secrets
# ---------------------------------------------------------------------------
p 'Requiring MD5 digests'
require 'digest/md5'

# ---------------------------------------------------------------------------
# Configure the basics for DataMapper
# ---------------------------------------------------------------------------
p 'Requiring ORM DataMapper'
require 'data_mapper'

# ---------------------------------------------------------------------------
# Access logging (ala Apache2 logging) uses Rack::CommonLogger
# This is only apparent in development and test.
# In production this would be done by the server.
# ---------------------------------------------------------------------------
p 'Requiring Rack::CommonLogger'
require 'logger'


# =========================================================================
# START Execution Logging configuration block
# =========================================================================

# ---------------------------------------------------------------------------
# We want execution logging.
# We could use the logger, but it's fiddly and not friendly.
# I kinda like log4j style logging, so I chose log4r
# ---------------------------------------------------------------------------
require 'log4r'
include Log4r

# -----------------------------------------------------------------------
# Configure log4r...
# First create two output_formatters: 1 for console, 1 for file
# The output folder is 'logs'
# -----------------------------------------------------------------------
output_formatters = [
    Log4r::Outputter.stdout,
    Log4r::FileOutputter.new('file', :filename => "#{settings.root}/logs/#{settings.environment}.log")
]
# -----------------------------------------------------------------------
# Create a nice pattern formatter as in:
# 2013-05-28 12:04:35 INFO  -  - Configured log4r format. See:
# http://log4r.rubyforge.org/rdoc/Log4r/PatternFormatter.html for details.
# -----------------------------------------------------------------------
log_pattern = Log4r::PatternFormatter.new(:pattern => '%d %-5l - %x - %m')
output_formatters.each do |output_format|
  output_format.formatter = log_pattern
end

# -----------------------------------------------------------------------
# Create the logger, add the output_formatters and set the level to DEBUG
# -----------------------------------------------------------------------
$log = Log4r::Logger.new("app")
$log.outputters = output_formatters
$log.level = Log4r::DEBUG
$log.info 'Configured log4r'

# Showing use of tests for environment
if Sinatra::Base.development? or Sinatra::Base.test?
  # -----------------------------------------------------------------------
  # We only use Access CommonLogger in development to console and file
  # -----------------------------------------------------------------------
  $log.debug 'Configuring access log'
  file = File.new("#{settings.root}/logs/access.log", 'a+')
  file.sync = true
  use Rack::CommonLogger, file
  # -----------------------------------------------------------------------
  # We want data mapper logging for development
  # Kinda awkward configuring the outputters, but you get nice stuff like:
  # 2013-05-28 12:05:18 DEBUG -  - (0.000034) SELECT COUNT(*) FROM "ipv4"
  # -----------------------------------------------------------------------
  $log.debug 'Configuring DataMapper logging'
  DataMapper.logger = Log4r::Logger.new('datamapper')
  output_formatters.each do |output_formatter|
    DataMapper.logger.add(output_formatter)
  end
elsif Sinatra::Base.production?
  # -----------------------------------------------------------------------
  # Access Logging will be done by Apache/Passenger or whatever
  # But production uses warn not debug
  # -----------------------------------------------------------------------
  $log.level = Log4r::WARN
end

# =========================================================================
# END Execution Logging configuration block
# =========================================================================


# =========================================================================
# START Database configuration
# =========================================================================
$log.info "Configuring DB for [#{settings.environment}]"
db_config = YAML.load(File.read("#{settings.root}/config/database.yml"))
# Just dump out the details for us to view
$log.debug "Complete DB Config loaded: #{db_config.inspect}"
# Notice the use of to_s to get the String of the environment and not a Symbol
$log.debug "ENV #{settings.environment} DB Config loaded: #{db_config[settings.environment.to_s].inspect}"
DataMapper.setup(:default, db_config[settings.environment.to_s])
# =========================================================================
# END Database configuration
# =========================================================================


# =========================================================================
# START Model configuration
# =========================================================================

# -------------------------------------------------------------------------
# Load the models first
#
# NOTE 1: See that I have capitalized the model names. In production,
# passenger will sometimes get confused if you use the lowercase name
# while Webrick or Thin will not.
#
# NOTE 2: You may need to have the full path as sometimes passenger will
# yield errors like this:
#   cannot load such file -- ./models/ipv4 (LoadError)
# -------------------------------------------------------------------------
$log.debug 'Loading DataMapper models'
require './models/IPv4'
require './models/Country'
require './models/Vendor'

# -------------------------------------------------------------------------
# For DataMapper we need to finalize and upgrade
# -------------------------------------------------------------------------
DataMapper.finalize
#DataMapper.auto_migrate! # Using this whacks the tables
DataMapper.auto_upgrade! # Just updates existing tables

# =========================================================================
# END Model configuration
# =========================================================================


# =========================================================================
# START Helpers
# =========================================================================
helpers do
  # -------------------------------------------------------------------------
  # Is the address a valid IPv4 one?
  # -------------------------------------------------------------------------
  def is_valid_ip4v_address(val)
    params[:address] =~ Resolv::IPv4::Regex
  end

  # -------------------------------------------------------------------------
  # Is this a valid vendor?
  # -------------------------------------------------------------------------
  def is_valid_vendor(code, secret)
    $log.debug "Looking up Vendor: [#{code}] with secret [#{secret}]"
    vendor = Vendor.find_by_code(code)
    return true if !vendor.nil? and secret == vendor.secret
    false
  end

  # -------------------------------------------------------------------------
  # The basic connection...
  # http://whatever.com/1.2.3.4
  # Try http://whatever.com/69.171.228.24 which is one facebook.com address
  # Notice that I didn't use the builder gem to create the xml. This app
  # is far too simple to have that level of requirement.
  # -------------------------------------------------------------------------
  def perform_base_action(response_type, params)
    if is_valid_ip4v_address(params[:address])
      # ---------------------------------------------------------------------
      # Stupidly simple vendor validation
      # ---------------------------------------------------------------------
      if !is_valid_vendor(params[:code], params[:secret])
        halt 401, '<response><errors>Unknown vendor</errors></response>' if response_type == 'xml'
        halt 401, {:errors => ['Unknown vendor']}.to_json
      end
      # ---------------------------------------------------------------------
      # Create a value for the IP address.
      # ---------------------------------------------------------------------
      ip_address = params[:address]
      octets = ip_address.split('.')
      ip_value = (octets[0].to_i * 256 * 256 * 256) + (octets[1].to_i * 256 * 256) + (octets[2].to_i * 256) + (octets[3].to_i)
      # ---------------------------------------------------------------------
      # Now look it up
      # ---------------------------------------------------------------------
      ipv4_row = IPv4.find_by_ip_value(ip_value)
      $log.debug "response_type==[#{response_type}]"
      if ipv4_row.nil?
        halt 401, '<response><iso3></iso3><country>Unknown</country></response>' if response_type == 'xml'
        {:iso3 => '', :country => 'Unknown'}.to_json
      else
        iso3_row = Country.find_by_iso3(ipv4_row.iso3)
        if iso3_row.nil?
          halt 401, '<response><iso3></iso3><country>Unknown</country></response>' if response_type == 'xml'
          {:iso3 => '', :country => 'Unknown'}.to_json
        else
          $log.debug "[#{iso3_row.inspect}][#{iso3_row.name}]"
          halt 401, "<response><iso3>#{ipv4_row.iso3}</iso3><country>#{iso3_row.name}</country></response>" if response_type == 'xml'
          {:iso3 => ipv4_row.iso3, :country => iso3_row.name}.to_json
        end
      end
    else
      # ---------------------------------------------------------------------
      # Ain't no IPv4 address this can figure out
      # ---------------------------------------------------------------------
      halt 401, '<response><errors>Not a valid an IPv4 address</errors></response>' if response_type == 'xml'
      halt 401, {:errors => ['Not a valid an IPv4 address']}.to_json
    end
  end
end
# =========================================================================
# END Helpers
# =========================================================================


# =========================================================================
# Routes
# =========================================================================


# -------------------------------------------------------------------------
# e.g. http://whatever.com/69.171.228.24/this_app/df76f1e54f63eae442ebf3b4d6c46531
# The whole vendor and secret thing is highly simplified.
# Normally I would require HTTPS and use X-MYAPP-VENDOR and X-MYAPP-SECRET
# headers instead.
# -------------------------------------------------------------------------
get '/:address/:code/:secret.xml' do
  $log.debug 'Valid route'
  content_type :xml
  return perform_base_action 'xml', params
end
get '/:address/:code/:secret' do
  $log.debug 'Valid route'
  content_type :json
  perform_base_action 'json', params
end

# -------------------------------------------------------------------------
# If you make your calls from a browser, they often do a request for the
# icon after the main call. This route just captures that and ignores it.
# -------------------------------------------------------------------------
get '/favicon.ico' do
  $log.debug 'Browsers request this after main call, just drop it on the floor'
end

# -------------------------------------------------------------------------
# Initial Data Seeder
# Takes quite some time, so don't hold your breath or you'll end up on
# the floor unconscious.
# Also could be used if you want to 'reload' data on changes to the
# underlying csv files.
# It fails fast, so you'll have to delete the rows from *both* tables
# before loading.
# Obviously you should have better authorization than this!
# -------------------------------------------------------------------------
get '/idl/SEED_SECRET' do
  $log.debug 'Initial Data Load'
  # -----------------------------------------------------------------------
  # Brute force seeding as example
  # This *not* elegant and is shown purely to illustrate insertions and tests.
  # You could of course use migrations which I didn't for example sake.
  # -----------------------------------------------------------------------

  # -----------------------------------------------------------------------
  # Countries
  # -----------------------------------------------------------------------
  $log.warn('Seeding countries table')
  filename = "#{settings.root}/seed_data/countries.csv"
  if !File.exist?(filename)
    $log.error('No countries.csv found')
    halt 500, {:errors => ['Internal error']}.to_json
  elsif Country.count > 0
    $log.error('Table already has  data')
    halt 500, {:errors => ['Data already loaded']}.to_json
  else
    CSV.foreach(filename) do |row|
      country = Country.new
      country.iso3 = row[0]
      country.name = row[1]
      $log.warn "Inserting #{row[0]} - #{row[1]}"
      country.save
    end
  end
  # -----------------------------------------------------------------------
  # Addresses
  # -----------------------------------------------------------------------
  $log.warn('Seeding addresses table')
  filename = "#{settings.root}/seed_data/addresses.csv"
  if !File.exist?(filename)
    $log.error('No addresses.csv found')
    halt 500, {:errors => ['Internal error']}.to_json
  elsif IPv4.count > 0
    $log.error('Table already has  data')
    halt 500, {:errors => ['Data already loaded']}.to_json
  else
    CSV.foreach(filename) do |row|
      address = IPv4.new
      address.from_ip = row[0].to_i
      address.to_ip = row[1].to_i
      address.iso3 = row[2]
      $log.warn "Inserting #{row[0]} - #{row[1]} - #{row[2]}"
      address.save
    end
  end
  # -----------------------------------------------------------------------
  # Vendors
  # -----------------------------------------------------------------------
  $log.warn('Seeding vendor table')
  if Vendor.count > 0
    $log.error('Table already has  data')
    halt 500, {:errors => ['Data already loaded']}.to_json
  else
    # -----------------------------------------------------------------------
    # Our own application
    # e.g. http://whatever.com/69.171.228.24/this_app/df76f1e54f63eae442ebf3b4d6c46531
    # -----------------------------------------------------------------------
    vendor = Vendor.new
    vendor.code = 'this_app'
    vendor.name = 'Our own application'
    vendor.secret = Digest::MD5.hexdigest('just_us_chickens')
    vendor.save
    # -----------------------------------------------------------------------
    # A dummy vendor
    # e.g. http://whatever.com/69.171.228.24/dummy/a4b947cb355c3fe9e6c4d83d4d83c23a
    # -----------------------------------------------------------------------
    vendor = Vendor.new
    vendor.code = 'dummy'
    vendor.name = 'Dummy vendor'
    vendor.secret = Digest::MD5.hexdigest('Our Dummy Vendor')
    vendor.save
  end
end

# -------------------------------------------------------------------------
# Invalid routes
# Notice we ignore response type here and always return json
# -------------------------------------------------------------------------
get '/:address/*' do
  $log.debug 'Route without vendor secret'
  content_type :json
  halt 401, {:errors => ['Unknown vendor']}.to_json
end
get '/:address' do
  $log.debug 'Route without vendor'
  content_type :json
  halt 401, {:errors => ['Unknown vendor']}.to_json
end

# -------------------------------------------------------------------------
# Hello, you forgot to pass an address
# Notice we ignore response type here and always return json
# -------------------------------------------------------------------------
get '/', :provides => :json do
  $log.debug 'Route with no parameters'
  {:errors => ['You need to provide an IPv4 address']}.to_json
end



