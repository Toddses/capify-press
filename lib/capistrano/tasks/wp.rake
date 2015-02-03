namespace :wp do

	namespace :local do

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