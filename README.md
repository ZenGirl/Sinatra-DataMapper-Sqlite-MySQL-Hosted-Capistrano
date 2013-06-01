# Sinatra-DataMapper-Sqlite-MySQL-Hosted-Capistrano

Example Sinatra app using Sqlite development, MySQL production deployed to a hosted server via capistrano

To run, do:

```sh
bundle install
```

Then simply type:

```sh
rackup
```

For testing production, simply use:

```sh
RACKUP_ENV=production rackup
```

For reference purposes the output of `bundle show` is as follows:

    Gems included by the bundle:
      * addressable (2.2.8)
      * bcrypt-ruby (3.0.1)
      * bundler (1.3.5)
      * data_mapper (1.2.0)
      * data_objects (0.10.12)
      * dm-aggregates (1.2.0)
      * dm-constraints (1.2.0)
      * dm-core (1.2.0)
      * dm-do-adapter (1.2.0)
      * dm-migrations (1.2.0)
      * dm-mysql-adapter (1.2.0)
      * dm-serializer (1.2.2)
      * dm-sqlite-adapter (1.2.0)
      * dm-timestamps (1.2.0)
      * dm-transactions (1.2.0)
      * dm-types (1.2.2)
      * dm-validations (1.2.0)
      * do_mysql (0.10.12)
      * do_sqlite3 (0.10.12)
      * fastercsv (1.5.5)
      * json (1.8.0)
      * json_pure (1.8.0)
      * log4r (1.1.10)
      * multi_json (1.7.4)
      * mysql (2.9.1)
      * rack (1.5.2)
      * rack-protection (1.5.0)
      * sinatra (1.4.2)
      * sqlite3 (1.3.7)
      * stringex (1.5.1)
      * tilt (1.4.1)
      * uuidtools (2.1.4)

The system does not install the database rows by default.
You can cause this by making a call to http://whatever.com/idl/SEED_SECRET
Obviously this is FAR from secure, and is shown simply to illustrate the point.
The seed data itself is in the `seed_data` folder.
Be aware that the `IpToCountry.2013-05.27.csv` is huge.
It was drawn down from http://software77.net/geo-ip and massaged to create the `addresses.csv` and `countries.csv`.
In that folder is an example shell script to create new csv files based on a new original file.

I strongly suggest reading the application.rb file as it is chock full of comments.

## Production

Since this example assumes MySQL in production you will have to create the database itself.
In the `database.yml`, you'll see:

    production:
      adapter: mysql
      encoding: utf8
      username: sdshmc
      password: sdshmc
      database: sdshmc

Which will obviously have to be changed to use your dbname, user and pass.

Once that has been done, you'll probably be using either Apache2 or NGinx as a server.
Under passenger presumably.

NOTICE:
-------
The Gemfile has:

```ruby
group :production do
  # Now notice we are using the mysql not mysql2 gem!
  gem 'mysql'
  gem 'dm-mysql-adapter'
end
```

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

```sh
/Users/kim/.rvm/gems/ruby-2.0.0-p0/gems/data_objects-0.10.12/lib/data_objects/connection.rb:79: warning: Encoding utf8 is not a known Ruby encoding for MySQL
```

This appears to be an issue with the DataMapper DataObject library.
Which of course does not exist.
It's only a warning, but it disturbs me.

If you try to use the mysql2 gem and adapter DataMapper barfs on the DataObject requires.
When run, it attempts to require a mysql2 version of it's code.
