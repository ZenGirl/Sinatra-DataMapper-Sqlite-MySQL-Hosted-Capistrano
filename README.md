# Sinatra-DataMapper-Sqlite-MySQL-Hosted-Capistrano

## Local development

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

### Passenger

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

You'll have to `a2enmod passenger` to create the links from `/etc/apache2/mods-enabled` to `/etc/apache2/mods-available`.
After that, just restart Apache.

### DNS

You can't make your site run properly (I'm excluding accessing it from an IP address) without a name.
So access your DNS zone settings (netregistry or whatever) and ensure you have the A or CNAME records configured for that name.
In the case of this application the name is `sdshmc.mydomain.com` and the record in DNS looks like this:

    sdshmc	3600	IN	A	192.168.170.115

Once the name has propagated, you can check it like this:

    my_remote_name@my_remote_host:~$ nslookup sdshmc.mydomain.com
    Server:		74.207.242.5
    Address:	74.207.242.5#53

    Non-authoritative answer:
    Name:	sdshmc.mydomain.com
    Address: 192.168.170.115

Cool.

### Database

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

### Web Server

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
    ├── public
    │   └── folder_must_exist
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

```sh
my_remote_name@my_remote_host:~/sdshmc$ export PATH=/opt/ruby-2.0.0-p195/bin:$PATH
my_remote_name@my_remote_host:~/sdshmc$ which ruby
/opt/ruby-2.0.0-p195/bin/ruby
my_remote_name@my_remote_host:~/sdshmc$ ruby -v
ruby 2.0.0p195 (2013-05-14 revision 40734) [x86_64-linux]
```

In my case I have a global install of ruby2.
You might have an RVM version.
Whatever.
Now we do a bundle install:

```sh
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
```

So... How do we see if it's working?
Well first we create a virtual host definition.
For Apache2, this is done by creating a file in `/etc/apache2/sites-available` named after your site.
In this case we're creating a site named `sdshmc.mydomain.com`, so the file will be `/etc/apache2/sites-available/sdshmc.mydomain.com`.
I have included an example Apache2 VHost config here:

```ApacheConf
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
```

Edit your file like this:

```sh
sudo vi /etc/apache2/sites-available/sdshmc.mydomain.com
```

SideStep: The `logs` folder will need to be writable by Apache, so do this:

```sh
sudo chown www-data.www-data logs
```

Enable the site:

```sh
sudo a2ensite sdshmc.mydomain.com
```

You'll see a message about reloading Apache. So we need to do that:

```sh
sudo /etc/init.d/apache2 reload
```

You should see something like this:

```sh
sudo /etc/init.d/apache2 reload
 * Reloading web server config apache2   [ OK ]
```

Sometimes you make a syntax error like I did doing this. An example might be:

```sh
Syntax error on line 30 of /etc/apache2/sites-enabled/sdshmc.mydomain.com:
order takes one argument, 'allow,deny', 'deny,allow', or 'mutual-failure'
   ...fail!
```

As you can see, I made a mistake with the `Order` directive.
In my case I had a space between the 'Allow,' and the 'Deny'

Ok. You should now be able to browse to `http://sdshmc.mydomain.com` and see your first message:

```json
{"errors":["You need to provide an IPv4 address"]}
```

Now try `http://sdshmc.mydomain.com/60.240.233.28/this_app/df76f1e54f63eae442ebf3b4d6c46531`:

```json
{"errors":["Unknown vendor"]}
```

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
Now we check the logs to see we now have a `production.log`:

```sh
my_remote_name@my_remote_host:~/sdshmc/logs$ ls -l
total 16
-rw-r--r-- 1 my_remote_name my_remote_name 5446 2013-06-03 00:09 access.log
-rw-r--r-- 1 my_remote_name my_remote_name    0 2013-06-02 23:20 development.log
-rw-r--r-- 1 root           root            999 2013-06-02 23:48 error.log
-rw-r--r-- 1 my_remote_name my_remote_name  576 2013-06-03 00:07 production.log
```

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

```json
{"iso3":"AUS","country":"Australia"}
```

And a call to `http://sdshmc.mydomain.com/60.240.233.28/this_app/df76f1e54f63eae442ebf3b4d6c46531.xml` yields:

```xml
<response>
  <iso3>AUS</iso3>
  <country>Australia</country>
</response>
```

In browsers you'll see this:

        This XML file does not appear to have any style information associated with it. The document tree is shown below.

The error is because we didn't include an `<xml .../>` header.

We'll be deleting all the code later and pointing to a capistrano structured layout later, but this proves our app works.

### Capistrano

Finally. We're close.
First you need to ensure the capistrano gem is installed:

```sh
gem install capistrano
Fetching: highline-1.6.19.gem (100%)
Successfully installed highline-1.6.19
Fetching: net-ssh-2.6.7.gem (100%)
Successfully installed net-ssh-2.6.7
Fetching: net-sftp-2.1.2.gem (100%)
Successfully installed net-sftp-2.1.2
Fetching: net-scp-1.1.1.gem (100%)
Successfully installed net-scp-1.1.1
Fetching: net-ssh-gateway-1.2.0.gem (100%)
Successfully installed net-ssh-gateway-1.2.0
Fetching: capistrano-2.15.4.gem (100%)
Successfully installed capistrano-2.15.4
6 gems installed
```

Next we need to `capify` our app.
If you're doing this yourself, you'll have to do this:

```sh
capify .
[add] writing './Capfile'
[add] writing './config/deploy.rb'
[done] capified!
```

If you're using this application, I've already done it.
You'll see that two files get created; `Capfile` and `config/deploy.rb`.

`Capfile` is very basic and we won't need to fiddle with it:

```ruby
load 'deploy'
# Uncomment if you are using Rails' asset pipeline
    # load 'deploy/assets'
load 'config/deploy' # remove this line to skip loading any of the default tasks
```

The `config/deploy.rb` is where most of the work is done.
Initially it will be like this:

```ruby
set :application, "set your application name here"
set :repository,  "set your repository location here"

# set :scm, :git # You can set :scm explicitly or Capistrano will make an intelligent guess based on known version control directory names
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`

role :web, "your web-server here"                          # Your HTTP server, Apache/etc
role :app, "your app-server here"                          # This may be the same as your `Web` server
role :db,  "your primary db-server here", :primary => true # This is where Rails migrations will run
role :db,  "your slave db-server here"

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
# namespace :deploy do
#   task :start do ; end
#   task :stop do ; end
#   task :restart, :roles => :app, :except => { :no_release => true } do
#     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#   end
# end
```

I've made some changes to the deploy.rb to illustrate what you need to change:

```ruby
set :application, 'IPv42Country'

# I'm using git. If you use svn, put that here
set :scm, :git
set :repository, 'https://github.com/YOUR_GIT_USERNAME/YOUR_GIT_PROJECT.git'
set :scm_username, 'YOUR_GIT_LOGIN'
set :scm_passphrase, 'YOUR_GIT_PASSWORD'

# Must be set for the password prompt from git to work
default_run_options[:pty] = true

# The server user and password
set :user, 'YOUR_REMOTE_SERVER_USERNAME'

# We always deploy the master branch
set :branch, 'master'

# Where we are going to deploy the code
set :deploy_to, '/home/your_remote_folder/sdshmc'

# Now we set roles
role :web, 'sdshmc.mydomain.com'
role :app, 'sdshmc.mydomain.com'
role :db,  'sdshmc.mydomain.com', :primary => true # This is where Rails migrations will run
# We could have done this:
# server 'sdshmc.mydomain.com', :app, :web, :db, :primary => true


# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end
```

You'll have to fix all the locations I have used of course.
Now we have to get rid of that test app we used `scp` to load.
So go to your server and get rid of all the files excep logs.
Your tree should look like this:

```sh
my_remote_name@my_remote_host:~/sdshmc$ tree .
.
└── logs
    ├── access.log
    ├── development.log
    ├── error.log
    └── production.log

1 directory, 4 files
```

Now we run our first capistrano command!
On your local machine, in the root folder of your site you do the initial setup:

```sh
my_machine:your_root_site_folder your_username$ cap deploy:setup
  * 2013-06-03 11:55:08 executing `deploy:setup'
  * executing "sudo -p 'sudo password: ' mkdir -p /home/remote_user/sdshmc \
    /home/remote_user/sdshmc/releases \
    /home/remote_user/sdshmc/shared \
    /home/remote_user/sdshmc/shared/system \
    /home/remote_user/sdshmc/shared/log \
    /home/remote_user/sdshmc/shared/pids"
    servers: ["sdshmc.mydomain.com"]
Password:
    [sdshmc.mydomain.com] executing command
 ** [out :: sdshmc.mydomain.com]
    command finished in 903ms
  * executing "sudo -p 'sudo password: ' chmod g+w /home/remote_user/sdshmc \
    /home/remote_user/sdshmc/releases \
    /home/remote_user/sdshmc/shared \
    /home/remote_user/sdshmc/shared/system \
    /home/remote_user/sdshmc/shared/log \
    /home/remote_user/sdshmc/shared/pids"
    servers: ["sdshmc.mydomain.com"]
    [sdshmc.mydomain.com] executing command
    command finished in 695ms
```

I've split the lines up to make it clear what is happening.
Notice that you had to enter tour remote servers password.

Your remote server tree should now look like this:

```sh
my_remote_name@my_remote_host:~/sdshmc$ tree .
.
├── logs
│   ├── access.log
│   ├── development.log
│   ├── error.log
│   └── production.log
├── releases
└── shared
    ├── log
    ├── pids
    └── system

6 directories, 4 files
```

See the new folders?

Ok. Now we do a check on your local machine:

```sh
my_machine:your_root_site_folder your_username$ cap deploy:check
  * 2013-06-03 12:05:44 executing `deploy:check'
  * executing "test -d /home/remote_user/sdshmc/releases"
    servers: ["sdshmc.mydomain.com"]
Password:
    [sdshmc.mydomain.com] executing command
    command finished in 650ms
  * executing "test -w /home/remote_user/sdshmc"
    servers: ["sdshmc.mydomain.com"]
    [sdshmc.mydomain.com] executing command
    command finished in 649ms
  * executing "test -w /home/remote_user/sdshmc/releases"
    servers: ["sdshmc.mydomain.com"]
    [sdshmc.mydomain.com] executing command
    command finished in 649ms
  * executing "which git"
    servers: ["sdshmc.mydomain.com"]
    [sdshmc.mydomain.com] executing command
    command finished in 639ms
The following dependencies failed. Please check them and try again:
--> You do not have permissions to write to `/home/remote_user/sdshmc/releases'. (sdshmc.mydomain.com)
```

Ah. Now see what happened? So we check the permissions for our user:

```sh
my_remote_name@my_remote_host:~/sdshmc$ ls -l
total 12
drwxr-xr-x 2 www-data www-data 4096 2013-06-02 23:36 logs
drwxrwxr-x 2 root     root     4096 2013-06-03 01:55 releases
drwxrwxr-x 5 root     root     4096 2013-06-03 01:55 shared
```

Well there's the problem. `root` owns releases and shared.
So we need to change the permissions:

```sh
my_remote_name@my_remote_host:~/sdshmc$ sudo chown -Rv my_remote_name.my_remote_name releases shared
[sudo] password for my_remote_name:
changed ownership of `releases' to my_remote_name:my_remote_name
changed ownership of `shared/pids' to my_remote_name:my_remote_name
changed ownership of `shared/log' to my_remote_name:my_remote_name
changed ownership of `shared/system' to my_remote_name:my_remote_name
changed ownership of `shared' to my_remote_name:my_remote_name
my_remote_name@my_remote_host:~/sdshmc$ ls -l
total 12
drwxr-xr-x 2 www-data        www-data        4096 2013-06-02 23:36 logs
drwxrwxr-x 2 my_remote_name  my_remote_name  4096 2013-06-03 01:55 releases
drwxrwxr-x 5 my_remote_name  my_remote_name  4096 2013-06-03 01:55 shared
```

And a test of `cap deploy:check` locally again:

```sh
my_machine:your_root_site_folder your_username$ cap deploy:check
  * 2013-06-03 12:05:44 executing `deploy:check'
  * executing "test -d /home/remote_user/sdshmc/releases"
    servers: ["sdshmc.mydomain.com"]
Password:
    [sdshmc.mydomain.com] executing command
    command finished in 650ms
  * executing "test -w /home/remote_user/sdshmc"
    servers: ["sdshmc.mydomain.com"]
    [sdshmc.mydomain.com] executing command
    command finished in 649ms
  * executing "test -w /home/remote_user/sdshmc/releases"
    servers: ["sdshmc.mydomain.com"]
    [sdshmc.mydomain.com] executing command
    command finished in 649ms
  * executing "which git"
    servers: ["sdshmc.mydomain.com"]
    [sdshmc.mydomain.com] executing command
    command finished in 639ms
You appear to have all necessary dependencies installed
```

Ok. Next step.
Normally at this point you would create the database and add credentials, but we've already done that above.
So we skip onto actually doing a test push to our server.
So on our local machine we do:

```sh
my_machine:your_root_site_folder your_username$ cap deploy:check
  * 2013-06-03 12:11:26 executing `deploy:check'
  * executing "test -d /home/remote_user/sdshmc/releases"
    servers: ["sdshmc.mydomain.com"]
Password:
    [sdshmc.mydomain.com] executing command
    command finished in 647ms
  * executing "test -w /home/remote_user/sdshmc"
    servers: ["sdshmc.mydomain.com"]
    [sdshmc.mydomain.com] executing command
    command finished in 700ms
  * executing "test -w /home/remote_user/sdshmc/releases"
    servers: ["sdshmc.mydomain.com"]
    [sdshmc.mydomain.com] executing command
    command finished in 638ms
  * executing "which git"
    servers: ["sdshmc.mydomain.com"]
    [sdshmc.mydomain.com] executing command
    command finished in 665ms
You appear to have all necessary dependencies installed
bandit:Sinatra-DataMapper-Sqlite-MySQL-Hosted-Capistrano kim$ cap deploy:update
  * 2013-06-03 12:14:32 executing `deploy:update'
 ** transaction: start
  * 2013-06-03 12:14:32 executing `deploy:update_code'
    executing locally: "git ls-remote https://github.com/YOUR_GIT_USER/YOUR_GIT_PROJECT.git master"
    command finished in 1840ms
  * executing "git clone -q -b master https://github.com/YOUR_GIT_USER/YOUR_GIT_PROJECT.git \
    /home/remote_user/sdshmc/releases/20130603021433 && \
    cd /home/remote_user/sdshmc/releases/20130603021433 && \
    git checkout -q -b deploy f288a7baf7389fd486a777755a3415bec8a90025 && \
    (echo f288a7baf7389fd486a777755a3415bec8a90025 > /home/remote_user/sdshmc/releases/20130603021433/REVISION)"
    servers: ["sdshmc.mydomain.com"]
Password:
    [sdshmc.mydomain.com] executing command
 ** [sdshmc.mydomain.com :: out] Unpacking objects:   1% (1/74)
 ** [sdshmc.mydomain.com :: out] Unpacking objects:   2% (2/74)
 ** [sdshmc.mydomain.com :: out] Unpacking objects:   4% (3/74)
 ** [sdshmc.mydomain.com :: out] Unpacking objects:   5% (4/74)
 ...elided for brevity...
 ** [sdshmc.mydomain.com :: out] Unpacking objects:  97% (72/74)
 ** [sdshmc.mydomain.com :: out] Unpacking objects:  98% (73/74)
Unpacking objects: 100% (74/74), done.] Unpacking objects: 100% (74/74)
    command finished in 4488ms
  * 2013-06-03 12:14:47 executing `deploy:finalize_update'
  * executing "chmod -R -- g+w /home/remote_user/sdshmc/releases/20130603021433 && \
    rm -rf -- /home/remote_user/sdshmc/releases/20130603021433/public/system && \
    mkdir -p -- /home/remote_user/sdshmc/releases/20130603021433/public/ && \
    ln -s -- /home/remote_user/sdshmc/shared/system /home/remote_user/sdshmc/releases/20130603021433/public/system && \
    rm -rf -- /home/remote_user/sdshmc/releases/20130603021433/log && \
    ln -s -- /home/remote_user/sdshmc/shared/log /home/remote_user/sdshmc/releases/20130603021433/log && \
    rm -rf -- /home/remote_user/sdshmc/releases/20130603021433/tmp/pids && \
    mkdir -p -- /home/remote_user/sdshmc/releases/20130603021433/tmp/ && \
    ln -s -- /home/remote_user/sdshmc/shared/pids /home/remote_user/sdshmc/releases/20130603021433/tmp/pids"
    servers: ["sdshmc.mydomain.com"]
    [sdshmc.mydomain.com] executing command
    command finished in 732ms
  * executing "find /home/remote_user/sdshmc/releases/20130603021433/public/images \
    /home/remote_user/sdshmc/releases/20130603021433/public/stylesheets \
    /home/remote_user/sdshmc/releases/20130603021433/public/javascripts -exec touch -t 201306030214.48 -- {} ';'; true"
    servers: ["sdshmc.mydomain.com"]
    [sdshmc.mydomain.com] executing command
 ** [out :: sdshmc.mydomain.com] find: `/home/remote_user/sdshmc/releases/20130603021433/public/images'
 ** [out :: sdshmc.mydomain.com] : No such file or directory
 ** [out :: sdshmc.mydomain.com] find:
 ** [out :: sdshmc.mydomain.com] `/home/remote_user/sdshmc/releases/20130603021433/public/stylesheets': No such file or directory
 ** [out :: sdshmc.mydomain.com]
 ** [out :: sdshmc.mydomain.com] find: `/home/remote_user/sdshmc/releases/20130603021433/public/javascripts'
 ** [out :: sdshmc.mydomain.com] : No such file or directory
    command finished in 669ms
  * 2013-06-03 12:14:48 executing `deploy:create_symlink'
  * executing "sudo -p 'sudo password: ' rm -f /home/remote_user/sdshmc/current && \
    sudo -p 'sudo password: ' ln -s /home/remote_user/sdshmc/releases/20130603021433 /home/remote_user/sdshmc/current"
    servers: ["sdshmc.mydomain.com"]
    [sdshmc.mydomain.com] executing command
 ** [out :: sdshmc.mydomain.com]
    command finished in 897ms
 ** transaction: commit
```

Whoah! Lot's happened.
I won't go through all the goriness of it.
It's easier to show what happened on our remote server:

```sh
my_remote_name@my_remote_host~/sdshmc$ tree .
.
├── current -> /home/remote_user/sdshmc/releases/20130603021433
├── logs
│   ├── access.log
│   ├── development.log
│   ├── error.log
│   └── production.log
├── releases
│   └── 20130603021433
│       ├── application.rb
│       ├── config
│       │   └── database.yml
│       ├── config.ru
│       ├── db
│       │   └── development.db
│       ├── Gemfile
│       ├── LICENSE
│       ├── log -> /home/remote_user/sdshmc/shared/log
│       ├── logs
│       │   ├── access.log
│       │   ├── development.log
│       │   └── production.log
│       ├── models
│       │   ├── Country.rb
│       │   ├── IPv4.rb
│       │   └── Vendor.rb
│       ├── public
│       │   ├── folder_must_exist
│       │   └── system -> /home/remote_user/sdshmc/shared/system
│       ├── README.md
│       ├── REVISION
│       ├── seed_data
│       │   ├── addresses.csv
│       │   ├── countries.csv
│       │   ├── IpToCountry.2013-05-27.csv
│       │   └── make_seed_data.sh
│       └── tmp
│           └── pids -> /home/remote_user/sdshmc/shared/pids
└── shared
    ├── log
    ├── pids
    └── system

18 directories, 23 files
```

Ah. So now we see that `current` points to the `releases/20130603021433` folder which has all our code.
Each new release will get another timestamp and get a new folder with current pointing to it.
Cool.

Ok. We're not done yet. We have to modify our Apache virtual host config to point to the public folder under current.
So we make these changes:

```ApacheConf
<VirtualHost *:80>
  ...elided...

  # Points to your site files
  # NOTE: You must have a public folder even if it's empty
  DocumentRoot    /home/some_user/sdshmc/current/public

  ...elided...

  # The directory where the site is stored
  # NOTE the trailing slash!
  <Directory /home/some_user/sdshmc/current/public/>
    ...elided...
  </Directory>
</VirtualHost>
```

Restart Apache and test it. All should work.

### Deploying a new version

Ok. You've made a ton of changes, tested them locally and want to get it live.
Make sure all has been pushed to your repo and then:

```sh
cap deploy
```

You can see what options are available using:

```sh
cap -T
```

### Making one-off changes to an existing deployment

Sometimes you have to change just one thing and don't want to do a complete redeployment.
So go ahead, change your file and push it to your repo.
Then on your local machine do:

```sh
cap deploy:upload
```











### NOTICE:

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

```yaml
production:
  adapter: mysql
  encoding: utf8
  username: sdshmc
  password: sdshmc
  database: sdshmc
```

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
