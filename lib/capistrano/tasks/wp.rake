namespace :wp do

	namespace :local do

		desc "Install WordPress and set up the repo and database"
		task :install do
			# clone the selected version of wordpress to the local server
			invoke "wp:local:wp_clone"

			# set up the wordpress config files
			invoke "wp:local:config"
			invoke "wp:local:permissions"

			# initialize the git repository and make the initial commit
			invoke "wp:local:init_git"

			# create the local database
			invoke "wp:local:init_db"

			# give the user some helpful hints on what to do next
			run_locally do
				puts ""
				puts "\033[32mOpen your browser and bring up the local URL to complete WordPress installation."
			end
		end

		# clone the official wordpress repo based on the version setting
		task :wp_clone do
			run_locally do
				# inform user we're downloading WordPress
				puts "\033[32mDownloading WordPress #{fetch(:wp_version)}... this may take several minutes"

				# clone the WordPress repo
				execute :git, "clone --branch #{fetch(:wp_version)} https://github.com/WordPress/WordPress.git #{fetch(:local_path)}"

				within "#{fetch(:local_path)}" do
					# get rid of the WordPress repo so we're starting from scratch
					execute :rm, "-rf .git"
				end
			end
		end

		# clone the project remote repo
		task :clone do
			run_locally do
				# inform user we're cloning the remote repo
				puts "\033[32mCloning repository from remote repository... this may take several minutes"

				# clone the remote repo based on the stage branch
				execute :git, "clone #{fetch(:repo_url)} #{fetch(:local_path)}"

				# pull down and checkout the stage branch
				within "#{fetch(:local_path)}" do
					execute :git, "checkout #{fetch(:branch)}"
				end
			end
		end

		# set up the local wp-config and .htaccess files
		task :config do
			run_locally do
				# get the database info for the local stage
				database = YAML::load_file('config/database.yml')['local']

				# generate wordpress authentication keys and salts
				keys_and_salts = capture("curl -s https://api.wordpress.org/secret-key/1.1/salt/")

				# build the config files
    			config = ERB.new(File.read("config/templates/wp-config.php.erb")).result(binding)
    			File.open(File.join(fetch(:local_path), "wp-config.php"), "w") { |f| f.write(config) }

    			config = ERB.new(File.read("config/templates/.htaccess.erb")).result(binding)
    			File.open(File.join(fetch(:local_path), ".htaccess"), "w") { |f| f.write(config) }
			end
		end

		# set the permissions on files and dirs for wordpress
		task :permissions do
			run_locally do
				execute :mkdir, "-p #{fetch(:local_path)}/wp-content/uploads"
				execute :chmod, "-R 777 #{fetch(:local_path)}/wp-content/uploads"
				execute :chmod, "666 #{fetch(:local_path)}/.htaccess"
			end
		end

		# initialize the local git repo and create master, staging, dev branches
		task :init_git do
			run_locally do
				within "#{fetch(:local_path)}" do
					# create a basic .gitignore and README for the repo
					config = ERB.new(File.read("config/templates/.gitignore.erb")).result(binding)
    				File.open(File.join(fetch(:local_path), ".gitignore"), "w") { |f| f.write(config) }

					config = ERB.new(File.read("config/templates/README.md.erb")).result(binding)
    				File.open(File.join(fetch(:local_path), "README.md"), "w") { |f| f.write(config) }

    				# initialize the repo, make an initial commit, and push it to the remote repo
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

		# create the local database
		task :init_db do
			db_local = YAML::load_file('config/database.yml')['local']

			run_locally do
				execute :mysql, "-h#{db_local['host']} -u#{db_local['username']} -p#{db_local['password']} -e 'CREATE DATABASE IF NOT EXISTS #{db_local['database']};'"
			end
		end

	end

	namespace :remote do

		desc "Deploy the site and push the database and uploads from the local server"
		task :push do
			# deploy the site from git
			invoke "deploy"

			# set up the wordpress config files
			invoke "wp:remote:config"
			invoke "wp:remote:permissions"

			# push the local uploads directory to the remote server
			invoke "uploads:push"

			# push the local database to the remote server
			invoke "db:push"

			# set up the virtual host on the remote server
			# i'm not sure we want to make this a default task. it won't work on shared environments anyway.
			#invoke "apache:vhost:create"
		end

		desc "Clone a remote repository and pull the database and uploads from the stage server"
		task :pull do
			# clone the repository to the local server
			invoke "wp:local:clone"

			# set up local configs
			invoke "wp:local:config"
			invoke "wp:local:permissions"

			# plul down the remote database and import it locally
			invoke "db:pull"

			# transfer the remote uploads to the local server
			invoke "uploads:pull"
		end

		# set up the wp-config and .htaccess on the stage server
		task :config do
			on roles(:web) do
				# get the database info for the current stage
				database = YAML::load_file('config/database.yml')[fetch(:stage).to_s]

				# generate wordpress authentication keys and salts
				keys_and_salts = capture("curl -s https://api.wordpress.org/secret-key/1.1/salt/")

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

	    # set the permissions on files and dirs for the stage wordpress install
		task :permissions do
			on roles(:web) do
				execute :chmod, "-R 777 #{shared_path}/wp-content/uploads"
				execute :chmod, "666 #{shared_path}/.htaccess"
			end
		end

	end

end