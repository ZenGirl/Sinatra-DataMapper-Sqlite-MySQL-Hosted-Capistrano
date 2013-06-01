require 'sinatra/base'
require 'data_mapper'
require 'dm-migrations'

class IPv4
  include DataMapper::Resource

  # -------------------------------------------------------------------------
  # Specific example showing how to radically change a table name.
  # Forces the table name from i_pv4s to addresses
  # -------------------------------------------------------------------------
  storage_names[:default] = 'addresses'

  # -------------------------------------------------------------------------
  # Our properties
  # iso3 is the 3 letter code for the country used to lookup in countries
  # NOTE: The min and max are used for mysql to ensure that the created
  # column is an UNSIGNED INT. If you don't do this you get a SIGNED INT
  # which means inserts will fail above 2147483647
  # -------------------------------------------------------------------------
  property :id, Serial
  property :from_ip, Integer, :key => true, :min => 0, :max => 4294967295
  property :to_ip, Integer, :key => true, :min => 0, :max => 4294967295
  property :iso3, String

  # -------------------------------------------------------------------------
  # Simple finder to allow ORM neutral calls
  # -------------------------------------------------------------------------
  def self.find_by_ip_value(ip_value)
    first(:from_ip.gte => ip_value)
  end
end

