require 'sinatra/base'
require 'data_mapper'
require 'dm-migrations'

class Country
  include DataMapper::Resource

  # -------------------------------------------------------------------------
  # Forces the table name
  # -------------------------------------------------------------------------
  storage_names[:default] = 'countries'

  # -------------------------------------------------------------------------
  # Our properties
  # -------------------------------------------------------------------------
  property :id, Serial
  property :iso3, String, :key => true
  property :name, String

  # -------------------------------------------------------------------------
  # Simple finder to allow ORM neutral calls
  # -------------------------------------------------------------------------
  def self.find_by_iso3(iso3)
    first(:iso3 => iso3)
  end
end

