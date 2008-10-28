=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

require 'erb'
require 'config/accelerator/accelerator_tasks'
require 'config/recipes/joyent'

set :svn, "/opt/local/bin/svn"
set :ggrep, "/opt/local/bin/ggrep"
set :rake, "/opt/local/bin/rake"
set :sudo, "/opt/local/bin/sudo"

set :application, "connector"
set :repository,  "http://svn.joyent.com/opensource/connector/source/trunk"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, "/opt/joyent/#{application}" # I like this location
set :deploy_via, :remote_cache
 
# If you aren't using Subversion to manage your source code, specify
# your SCM below:
set :scm, :subversion

set :use_sudo, false
set :user, 'joyent'
set :runner, 'joyent'

# Do not run the sudo command through sh
# default_run_options[:shell] = false

# We are going to get role based servers and other details from the stage files
# give a look to the config/deploy/ directory for specific stages
set :stages, %w(staging production testing)
set :default_stage, "testing"
require 'capistrano/ext/multistage'

 
# Example dependancies
depend :remote, :command, :gem, :roles => :app
depend :remote, :command, :ggrep, :roles => :app # This is due to the way we're getting the IP Address into accelerator_tasks.rb
depend :remote, :gem, :rcov, '>=0.8.0', :roles => :app
depend :remote, :gem, :mongrel, '>=1.0.1',:roles => :app
depend :remote, :gem, :hpricot, '>=0.6.0', :roles => :app
depend :remote, :gem, :rake, '>=0.7.3', :roles => :app
depend :remote, :gem, :tzinfo, '>=0.3.3', :roles => :app
depend :remote, :gem, :ezcrypto, '>=0.7.0', :roles => :app
depend :remote, :gem, :gettext, '=1.9.0', :roles => :app
depend :remote, :gem, :mongrel_cluster, '>=1.0.4', :roles => :app
 
desc "Overriden deploy:restart task. It will run
\naccelerator.smf_restart
accelerator.restart_apache\n"
deploy.task :restart do
  accelerator.smf_restart
  accelerator.restart_apache
end

desc "Overriden deploy:start task. It will run
\naccelerator.smf_start
accelerator.restart_apache\n"
deploy.task :start do
  accelerator.smf_start
  accelerator.restart_apache
end

desc "Overriden deploy:stop task. It will run
\naccelerator.smf_stop
accelerator.restart_apache\n"
deploy.task :stop do
  accelerator.smf_stop
  accelerator.restart_apache
end

# Override the default deploy:cold to include the schema load
desc "Override the default deploy:cold to include schema load before migrate

Deploys and starts a `cold' application. This is useful if you have not deployed
your application before, or if your application is (for some other reason) not
currently running. It will deploy the code, run any pending migrations, and then
instead of invoking `deploy:restart', it will invoke `deploy:start' to fire up
the application servers."
deploy.task :cold do
  update
  run "cd #{current_path}; rake RAILS_ENV=production db:schema:load"
  migrate
  start
end
 
after :deploy, 'deploy:cleanup'
