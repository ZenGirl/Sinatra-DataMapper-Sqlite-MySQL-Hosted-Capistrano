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

## Passenger

Installing Passenger is simple assuming you have all the required packages installed.
The Passenger install users guides are here:

http://www.modrails.com/documentation/Users%20guide%20Apache.html
http://www.modrails.com/documentation/Users%20guide%20Nginx.html

The users guides are *long* but the gist is:

1) gem install passenger
2) passenger-install-apache2-module

To ensure you have the Apache headers and linux modules, review: http://www.modrails.com/documentation/Users%20guide%20Apache.html#troubleshooting.
For NGinx users, the install is virtually identical.

In any case, all the installer does is use your ruby install to create some files:

    [/etc/apache2/mods-available/passenger.conf]
    PassengerRoot /opt/ruby-2.0.0-p195/lib/ruby/gems/2.0.0/gems/passenger-4.0.2
    PassengerRuby /opt/ruby-2.0.0-p195/bin/ruby
    PassengerDefaultRuby /opt/ruby-2.0.0-p195/bin/ruby
    PassengerMaxPoolSize 6
    PassengerPoolIdleTime 0
    PassengerMaxRequests 1000

and

    [/etc/apache2/mods-available/passenger.load]
    LoadModule passenger_module /opt/ruby-2.0.0-p195/lib/ruby/gems/2.0.0/gems/passenger-4.0.2/libout/apache2/mod_passenger.so

OBVIOUSLY you'll want to change the path to the gems and ruby2!

You'll have to `a2enmod passenger` to create the links from /etc/apache2/mods-enabled to /etc/apache2/mods-available.
After that, just restart Apache.

## DNS

You can't make your site run properly (I'm excluding accessing it from an IP address) without a name.
So access your DNS zone settings (netregistry or whatever) and ensure you have the A or CNAME records configured for that name.
In the case of this application the name is sdshmc.mydomain.com and the record in netregistry looks like this:

    sdshmc	3600	IN	A	192.168.170.115

Once the name has propagated, you can check it like this:

    my_remote_name@my_remote_host:~$ nslookup sdshmc.mydomain.com
    Server:		74.207.242.5
    Address:	74.207.242.5#53

    Non-authoritative answer:
    Name:	sdshmc.mydomain.com
    Address: 192.168.170.115

Cool.

## Database

The site uses MySQL in production, so you will have to ensure that the database defined in `config/database.yml` exists and is accessible.
Here is a mysql command line example:

    mysql> create database sdshmc;
    Query OK, 1 row affected (0.01 sec)

    mysql> show create database sdshmc;
    +----------+-----------------------------------------------------------------+
    | Database | Create Database                                                 |
    +----------+-----------------------------------------------------------------+
    | sdshmc   | CREATE DATABASE `sdshmc` /*!40100 DEFAULT CHARACTER SET utf8 */ |
    +----------+-----------------------------------------------------------------+
    1 row in set (0.06 sec)

    mysql> grant all on sdshmc.* to 'sdshmc'@'localhost' identified by 'sdshmc';
    Query OK, 0 rows affected (0.21 sec)

    mysql> flush privileges;
    Query OK, 0 rows affected (0.00 sec)

Don't worry about creating tables as DataMapper will do that.

## Web Server

I'm illustrating Apache2 here, but the steps are similar for NGinx.
(I'll cover NGinx setup in a separate post)

First you need to configure the directory where your site will run from.
Before we use capistrano, we'll just test whether your site even functions correctly.
So create your site folder, such as `sdshmc` and use scp to copy your sites files into it.

This is only a test step to make sure your web server configuration is working at all.
Although you could use this method (copying individually changed files) to work on your remote site, it is easy to forget a change.
It's also a PITA.

An example transcript of this looks like this:

    my_home_machine:sdshmc my_user_name$ scp -r * my_remote_name@my_remote_host:/home/my_remote_name/sdshmc
    The authenticity of host 'my_remote_host (192.168.170.115)' can't be established.
    RSA key fingerprint is d6:60:3e:51:07:e0:43:82:cf:5b:49:76:e7:1a:ef:d6.
    Are you sure you want to continue connecting (yes/no)? yes
    Warning: Permanently added 'my_remote_host' (RSA) to the list of known hosts.
    my_remote_name@my_remote_host's password:
    Gemfile                      100% 1027     1.0KB/s   00:00
    Gemfile.lock                 100% 2000     2.0KB/s   00:00
    LICENSE                      100% 1061     1.0KB/s   00:00
    README.md                    100% 7036     6.9KB/s   00:00
    application.rb               100%   16KB  15.7KB/s   00:00
    database.yml                 100%  938     0.9KB/s   00:00
    config.ru                    100%  587     0.6KB/s   00:00
    ...elided for brevity...
    IpToCountry.2013-05-27.csv   100% 8827KB  76.1KB/s   01:56
    make_seed_data.sh            100%  654     0.6KB/s   00:00

Obviously you'll have different user names, hosts, IP addresses, fingerprints etc.
Once you're done your folder, probably `/home/yourname/sdshmc` will look something like this:

    my_remote_name@my_remote_host:~/sdshmc$ tree .
    .
    ├── application.rb
    ├── config
    │   └── database.yml
    ├── config.ru
    ├── db
    │   └── development.db
    ├── Gemfile
    ├── Gemfile.lock
    ├── LICENSE
    ├── logs
    │   ├── access.log
    │   ├── development.log
    │   └── production.log
    ├── models
    │   ├── Country.rb
    │   ├── IPv4.rb
    │   └── Vendor.rb
    ├── README.md
    └── seed_data
        ├── addresses.csv
        ├── countries.csv
        ├── IpToCountry.2013-05-27.csv
        └── make_seed_data.sh

    5 directories, 18 files

BTW: The `tree` program is very useful to see the structure of a folder.

Now there is an important step.
You need to ensure your gems are installed.
First check your ruby version is valid:

    my_remote_name@my_remote_host:~/sdshmc$ export PATH=/opt/ruby-2.0.0-p195/bin:$PATH
    my_remote_name@my_remote_host:~/sdshmc$ which ruby
    /opt/ruby-2.0.0-p195/bin/ruby
    my_remote_name@my_remote_host:~/sdshmc$ ruby -v
    ruby 2.0.0p195 (2013-05-14 revision 40734) [x86_64-linux]

In my case I have a global install of ruby2.
You might have an RVM version.
Whatever.
Now we do a bundle install:

    my_remote_name@my_remote_host:~/sdshmc$ which bundle
    /opt/ruby-2.0.0-p195/bin/bundle
    my_remote_name@my_remote_host:~/sdshmc$ bundle install
    Fetching gem metadata from https://rubygems.org/.........
    Fetching gem metadata from https://rubygems.org/..
    Installing addressable (2.2.8)
    Installing bcrypt-ruby (3.0.1)
    Installing dm-core (1.2.0)
    Installing dm-aggregates (1.2.0)
    Installing dm-constraints (1.2.0)
    Installing dm-migrations (1.2.0)
    Installing fastercsv (1.5.5)
    Using json (1.8.0)
    Installing json_pure (1.8.0)
    Installing multi_json (1.7.4)
    Installing dm-serializer (1.2.2)
    Installing dm-timestamps (1.2.0)
    Installing dm-transactions (1.2.0)
    Installing stringex (1.5.1)
    Installing uuidtools (2.1.4)
    Installing dm-types (1.2.2)
    Installing dm-validations (1.2.0)
    Installing data_mapper (1.2.0)
    Installing data_objects (0.10.12)
    Installing dm-do-adapter (1.2.0)
    Installing do_mysql (0.10.12)
    Installing dm-mysql-adapter (1.2.0)
    Installing do_sqlite3 (0.10.12)
    Installing dm-sqlite-adapter (1.2.0)
    Installing log4r (1.1.10)
    Installing mysql (2.9.1)
    Using rack (1.5.2)
    Installing rack-protection (1.5.0)
    Using tilt (1.4.1)
    Installing sinatra (1.4.2)
    Installing sqlite3 (1.3.7)
    Using bundler (1.3.5)
    Your bundle is complete!
    Use `bundle show [gemname]` to see where a bundled gem is installed.

So... How do we see if it's working?
Well first we create a virtual host definition.
For Apache2, this is done by creating a file in `/etc/apache2/sites-available` named after your site.
In this case we're creating a site named `sdshmc.mydomain.com`, so the file will be `/etc/apache2/sites-available/sdshmc.mydomain.com`.
I have included an example Apache2 VHost config here:

    <VirtualHost *:80>
      ServerAdmin     your.name@some.email.service.com

      ServerName      sdshmc.mydomain.com
      # If you want an alias for your site using CNAME for example, do womthing like this:
      #ServerAlias     sdshmc.your-app-name.com

      ServerSignature Off

      # Points to your site files
      # NOTE: You must have a public folder even if it's empty
      DocumentRoot    /home/some_user/sdshmc/public

      # Only interested in warnings and above
      LogLevel        warn

      # For access and error logging
      # Note that you'll have to ensure this folder is wriatble by www-data
      ErrorLog        /home/some_user/sdshmc/logs/error.log
      CustomLog       /home/some_user/sdshmc/logs/access.log combined

      # If you're using cgi-bin programs
      #ScriptAlias     /cgi-bin/ /usr/lib/cgi-bin/

      # The directory where the site is stored
      # NOTE the trailing slash!
      <Directory /home/some_user/sdshmc/public/>
        Options       Indexes FollowSymLinks MultiViews
        AllowOverride All
        # We allow first, then deny
        Order         Allow,Deny
        # For security during testing, put your home IP address here
        #Allow from    200.200.200.200
        # Otherwise, use this:
        Allow from     All
      </Directory>
    </VirtualHost>

Edit your file like this:

    sudo vi /etc/apache2/sites-available/sdshmc.mydomain.com

SideStep: The `logs` folder will need to be writable by Apache, so do this:

    chown www-data.www-data logs

Enable the site:

    sudo a2ensite sdshmc.mydomain.com

You'll see a message about reloading Apache. So we need to do that:

    sudo /etc/init.d/apache2 reload

You should see something like this:

    sudo /etc/init.d/apache2 reload
     * Reloading web server config apache2   [ OK ]

Sometimes you make a syntax error like I did doing this. An example might be:

    Syntax error on line 30 of /etc/apache2/sites-enabled/sdshmc.mydomain.com:
    order takes one argument, 'allow,deny', 'deny,allow', or 'mutual-failure'
       ...fail!

As you can see, I made a mistake with the `Order` directive.
In my case I had a space between the ',' and the 'Deny'

Ok. You should now be able to browse to `http://sdshmc.mydomain.com` and see your first message:

    {"errors":["You need to provide an IPv4 address"]}

Now try `http://sdshmc.mydomain.com/60.240.233.28/this_app/df76f1e54f63eae442ebf3b4d6c46531`:

    {"errors":["Unknown vendor"]}

What's wrong?
Well the database tables have not been seeded.
To see that, go to your mysql command prompt and look at the created tables:

    mysql> show table status;
    +-----------+--------+---------+------------+------+-...-+
    | Name      | Engine | Version | Row_format | Rows | ... |
    +-----------+--------+---------+------------+------+-...-+
    | addresses | InnoDB |      10 | Compact    |    0 | ... |
    | countries | InnoDB |      10 | Compact    |    0 | ... |
    | vendors   | InnoDB |      10 | Compact    |    0 | ... |
    +-----------+--------+---------+------------+------+-...-+
    3 rows in set (0.00 sec)

The tables are created but are empty.
Now we check the logs:

    my_remote_name@my_remote_host:~/sdshmc/logs$ ls -l
    total 16
    -rw-r--r-- 1 my_remote_name my_remote_name 5446 2013-06-03 00:09 access.log
    -rw-r--r-- 1 my_remote_name my_remote_name    0 2013-06-02 23:20 development.log
    -rw-r--r-- 1 root           root            999 2013-06-02 23:48 error.log
    -rw-r--r-- 1 my_remote_name my_remote_name  576 2013-06-03 00:07 production.log

Let's view the production log:


If you tail it while we use the `http://sdshmc.mydomain.com/idl/SEED_SECRET` url you'll see the tables filling up with data.
Afterwards you can use the mysql command line to check the results:

    mysql> show table status;
    +-----------+--------+---------+------------+--------+-...-+
    | Name      | Engine | Version | Row_format | Rows   | ... |
    +-----------+--------+---------+------------+--------+-...-+
    | addresses | InnoDB |      10 | Compact    | 127157 | ... |
    | countries | InnoDB |      10 | Compact    |    238 | ... |
    | vendors   | InnoDB |      10 | Compact    |      2 | ... |
    +-----------+--------+---------+------------+--------+-...-+
    3 rows in set (0.00 sec)

Now a call to `http://sdshmc.mydomain.com/60.240.233.28/this_app/df76f1e54f63eae442ebf3b4d6c46531` yields:

    {"iso3":"AUS","country":"Australia"}

And a call to `http://sdshmc.mydomain.com/60.240.233.28/this_app/df76f1e54f63eae442ebf3b4d6c46531.xml` yields:

    This XML file does not appear to have any style information associated with it. The document tree is shown below.
    <response>
      <iso3>AUS</iso3>
      <country>Australia</country>
    </response>

The error is because we didn't include an `<xml .../>` header.

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
