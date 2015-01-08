# config valid only for current version of Capistrano
lock '3.3.5'

# slack configuration
require "./config/slack"

set :application, "tester"
set :repo_url, "git@github.com:Toddses/tester.git"

# Default branch is :master
# set :branch, 'test'
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, '/var/www/html/hockinghills'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, fetch(:linked_files, []).push('config/database.yml')
set :linked_files, %w{wp-config.php .htaccess}

# Default value for linked_dirs is []
# set :linked_dirs, fetch(:linked_dirs, []).push('bin', 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')
set :linked_dirs, %w{wp-content/uploads}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Some additional vars we will need
set :admin_email, "todd@rainydaymedia.net"
set :local_url, "http://hockinghills.dev"
set :local_path, "/var/www/html/tester"

set :wp_version, "4.1"

namespace :deploy do

	task :create_linked_files do
		on roles(:web) do
			execute :touch, "#{shared_path}/wp-config.php"
			execute :touch, "#{shared_path}/.htaccess"
		end
	end

	before 'check:linked_files', :create_linked_files
end
