require 'sinatra/base'
require 'data_mapper'
require 'dm-migrations'

class Vendor
  include DataMapper::Resource

  # -------------------------------------------------------------------------
  # Forces the table name
  # -------------------------------------------------------------------------
  storage_names[:default] = 'vendors'

  # -------------------------------------------------------------------------
  # Our properties
  # -------------------------------------------------------------------------
  property :id, Serial
  property :code, String, :key => true
  property :name, String
  property :secret, String

  # -------------------------------------------------------------------------
  # Simple finder to allow ORM neutral calls
  # -------------------------------------------------------------------------
  def self.find_by_code(code)
    Vendor.first(:code => code)
  end

end
