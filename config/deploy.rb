set :application, 'IPv42Country'

# I'm using git. If you use svn, put that here
set :scm, :git
set :repository, 'https://github.com/ZenGirl/Sinatra-DataMapper-Sqlite-MySQL-Hosted-Capistrano.git'
set :scm_username, 'kimberley.r.scott@mac.com'
set :scm_passphrase, 'Ruby56Rocks'

# Must be set for the password prompt from git to work
default_run_options[:pty] = true

# The server user and password
set :user, 'alltama'

# We always deploy the master branch
set :branch, 'master'

# Where we are going to deploy the code
set :deploy_to, '/home/alltama/sdshmc'

# Now we set roles
role :web, 'sdshmc.alltamaservices.com'
role :app, 'sdshmc.alltamaservices.com'
role :db,  'sdshmc.alltamaservices.com', :primary => true # This is where Rails migrations will run
# We could have done this:
# server 'sdshmc.alltamaservices.com', :app, :web, :db, :primary => true


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