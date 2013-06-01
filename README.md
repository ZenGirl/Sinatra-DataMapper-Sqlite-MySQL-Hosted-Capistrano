Sinatra-DataMapper-Sqlite-MySQL-Hosted-Capistrano
=================================================

Example Sinatra app using Sqlite development, MySQL production deployed to a hosted server via capistrano

To run, do a bundle install.

Then simply type:

    rackup

For testing production, simply use:

    RACKUP_ENV=production rackup

The system does not install the database rows by default.
You can cause this by making a call to http://whatever.com/idl/SEED_SECRET
Obviously this is FAR from secure, and is shown simply to illustrate the point.
The seed data itself is in the seed_data folder.
Be aware that the IpToCountry.2013-05.27.csv is huge.
It was drawn down from http://software77.net/geo-ip and massaged to create the addresses.csv and countries.csv.
In that folder is some example shell script to create new csv files based on a new original file.

I strongly suggest reading the application.rb file as it is chock full of comments.

NOTICE:
-------
The Gemfile has:

    group :production do
      # Now notice we are using the mysql not mysql2 gem!
      gem 'mysql'
      gem 'dm-mysql-adapter'
    end

Notice that the gem is the mysql gem and not the mysql2 gem.
The gem reference is also in the database.yml file:

    production:
      adapter: mysql
      encoding: utf8
      username: sdshmc
      password: sdshmc
      database: sdshmc

Notice that the adapter is mysql and not mysql2.
Supposedly the dm-mysql-adapter does not suffer from the utf8 issue.
Having said that, setting the encoding to utf8, UTF8, utf-8 or UTF-8 causes:

    /Users/kim/.rvm/gems/ruby-2.0.0-p0/gems/data_objects-0.10.12/lib/data_objects/connection.rb:79: warning: Encoding utf8 is not a known Ruby encoding for MySQL

This appears to be an issue with the DataMapper DataObject library that, when run, to attempt to require a mysql2 version of it's code.
Which of course does not exist.
It's only a warning, but it disturbs me.
