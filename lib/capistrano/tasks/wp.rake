namespace :wp do
	
	desc "Set up the remote server and virtual host and deploy the site."
	task :remote_install do
		# deploy the site from git
		invoke "deploy"

		# set up the wordpress config files
		invoke "wp:upload_linked_files"
		invoke "wp:setup_permissions"

		# push the local uploads directory to the remote server
		invoke "uploads:push"

		# push the local database to the remote server
		invoke "db:push"

		# set up the virtual host on the remote server
		invoke "apache:vhost:create"
	end

	task :upload_linked_files do
		on roles(:web) do
			# get the database info for the current stage
			database = YAML::load_file('config/database.yml')[fetch(:stage).to_s]

			# create and upload config to remote server
			db_config = ERB.new(File.read('config/templates/wp-config.php.erb')).result(binding)
	    	io = StringIO.new(db_config)
	    	upload! io, File.join(shared_path, "wp-config.php")

	    	# create and upload basic .htaccess to remote server
	    	access_file = ERB.new(File.read('config/templates/.htaccess.erb')).result(binding)
	    	io = StringIO.new(access_file)
	    	upload! io, File.join(shared_path, ".htaccess")
	    end
    end

    task :setup_permissions do
		on roles(:web) do
			execute :chmod, "-R 777 #{shared_path}/wp-content/uploads"
			execute :chmod, "666 #{shared_path}/.htaccess"
		end
	end

	namespace :local do

		desc "Install WordPress and set up the repo and database"
		task :install do
			invoke "wp:local:clone"
			invoke "wp:local:config"
			invoke "wp:local:init_git"
			invoke "wp:local:init_db"
		end

		task :clone do
			run_locally do
				# inform user we're downloading WordPress
				info "downloading WordPress #{fetch(:wp_version)}... this may take several minutes"

				# clone the WordPress repo
				execute :git, "clone --branch #{fetch(:wp_version)} https://github.com/WordPress/WordPress.git #{fetch(:local_path)}"

				within "#{fetch(:local_path)}" do
					# get rid of the WordPress repo so we're starting from scratch
					execute :rm, "-rf .git"
				end
			end
		end

		task :config do
			run_locally do
				# get the database info for the current stage
				database = YAML::load_file('config/database.yml')[fetch(:stage).to_s]

				# build all the config files
				config = ERB.new(File.read("config/templates/.gitignore.erb")).result(binding)
    			File.open(File.join(fetch(:local_path), ".gitignore"), "w") { |f| f.write(config) }

				config = ERB.new(File.read("config/templates/README.md.erb")).result(binding)
    			File.open(File.join(fetch(:local_path), "README.md"), "w") { |f| f.write(config) }

    			config = ERB.new(File.read("config/templates/wp-config.php.erb")).result(binding)
    			File.open(File.join(fetch(:local_path), "wp-config.php"), "w") { |f| f.write(config) }

    			config = ERB.new(File.read("config/templates/.htaccess.erb")).result(binding)
    			File.open(File.join(fetch(:local_path), ".htaccess"), "w") { |f| f.write(config) }
			end
		end

		task :init_git do
			run_locally do
				within "#{fetch(:local_path)}" do
					execute :git, "init"
					execute :git, "remote add origin #{fetch(:repo_url)}"
					execute :git, "add -A"
					execute :git, "commit -m 'WordPress installation and initial commit.'"
					execute :git, "push -u origin master"
					execute :git, "checkout -b staging"
					execute :git, "push -u origin staging"
					execute :git, "checkout -b dev"
					execute :git, "push -u origin dev"
				end
			end
		end

		task :init_db do
			db_local = YAML::load_file('config/database.yml')['local']

			run_locally do
				execute :mysql, "-h#{db_local['host']} -u#{db_local['username']} -p#{db_local['password']} -e 'CREATE DATABASE #{db_local['database']};'"
			end
		end

	end

end