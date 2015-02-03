# config valid only for current version of Capistrano
lock '3.3.5'

# slack configuration
require "./config/slack"

# Required Settings
# =================

set :application, "example"
set :repo_url, "git@github.com:User/example.git"
set :admin_email, "user@example.com"

set :local_url, "http://localhost"
set :local_path, "/var/www/html/example"

# Soft Link Settings
# ==================

set :linked_files, %w{wp-config.php .htaccess}
set :linked_dirs, %w{wp-content/uploads}

# Capistrano Settings
# ===================

set :log_level, :error

# Default value for :format is :pretty
# set :format, :pretty

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

namespace :deploy do

	task :create_linked_files do
		on roles(:web) do
			execute :touch, "#{shared_path}/wp-config.php"
			execute :touch, "#{shared_path}/.htaccess"
		end
	end

	before 'check:linked_files', :create_linked_files
end
