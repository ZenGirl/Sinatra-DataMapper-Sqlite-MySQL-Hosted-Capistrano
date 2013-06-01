# ---------------------------------------------------------------------------
# Where to get the gems
# ---------------------------------------------------------------------------
source 'https://rubygems.org'

# ---------------------------------------------------------------------------
# Obviously need this.
# ---------------------------------------------------------------------------
gem 'sinatra'

# ---------------------------------------------------------------------------
# For database access
# ---------------------------------------------------------------------------
gem 'data_mapper'

group :development, :test do
  gem 'sqlite3'
  gem 'dm-sqlite-adapter'
end

group :production do
  # Now notice we are using the mysql not mysql2 gem!
  gem 'mysql'
  gem 'dm-mysql-adapter'
end

# ---------------------------------------------------------------------------
# We will be using a logger like log4j for execution logging
# ---------------------------------------------------------------------------
gem 'log4r'

