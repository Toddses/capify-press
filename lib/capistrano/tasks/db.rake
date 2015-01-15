namespace :db do

	# Creates a backup filename based on the server date / time.
	task :get_backup_name do
		on roles(:db) do

			execute :mkdir, "-p #{shared_path}/db-backups"

			now = Time.now
			date_string = now.strftime("%Y%m%d")
			time_string = now.strftime("%H%M%S")
			file_string = "db-#{date_string}-#{time_string}.sql"

			set :backup_filename, file_string
			set :backup_file, "#{shared_path}/db-backups/#{file_string}"
		end
	end

	desc "Pushes a local export of the MySQL database to the remote server"
	task :push do
		invoke "db:get_backup_name"

		db_local = YAML::load_file('config/database.yml')['local']
		db_stage = YAML::load_file('config/database.yml')[fetch(:stage).to_s]

		on roles(:db) do
			run_locally do
				execute :mkdir, "-p tmp"
				execute :mysqldump, "-h#{db_local['host']} -u#{db_local['username']} -p#{db_local['password']} #{db_local['database']} > tmp/#{fetch(:backup_filename)}"
			end

			upload! "tmp/#{fetch(:backup_filename)}", "#{fetch(:backup_file)}"

			within "#{shared_path}/db-backups" do
				# replace the local url with the remote url
				# note the use of % as the delimeter to avoid conflict with slashes in urls
				execute :sed, "-i s%#{fetch(:local_url)}%#{fetch(:stage_url)}%g #{fetch(:backup_filename)}"

				# replace the local table prefix with the remote prefix
				execute :sed, "-i s/#{db_local['prefix']}_/#{db_stage['prefix']}_/g #{fetch(:backup_filename)}"

				# create the remote database if it doesn't already exist
				execute :mysql, "-h#{db_stage['host']} -u#{db_stage['username']} -p#{db_stage['password']} -e 'CREATE DATABASE IF NOT EXISTS #{db_stage['database']}'"

				# execute the sql script on the remote database
				execute :mysql, "-h#{db_stage['host']} -u#{db_stage['username']} -p#{db_stage['password']} #{db_stage['database']} < #{fetch(:backup_filename)}"
			end

			run_locally do
				# delete the exported sql backup and delete the tmp directory if its empty
				execute :rm, "tmp/#{fetch(:backup_filename)}"
				if Dir['tmp/*'].empty?
					execute :rmdir, "tmp"
				end
			end
		end
	end

	desc "Pulls a remote export of the MySQL database and imports to the local server"
	task :pull do
		invoke "db:get_backup_name"

		db_local = YAML::load_file('config/database.yml')['local']
		db_stage = YAML::load_file('config/database.yml')[fetch(:stage).to_s]

		on roles(:db) do
			run_locally do
				execute :mkdir, "-p tmp"
			end

			# create the export and download to local machine
			execute :mysqldump, "-h#{db_stage['host']} -u#{db_stage['username']} -p#{db_stage['password']} #{db_stage['database']} > #{fetch(:backup_file)}"
			download! "#{fetch(:backup_file)}", "tmp/#{fetch(:backup_filename)}"

			run_locally do
				within "tmp" do
					# replace the remote url with the local url
					# note the use of % as the delimeter to avoid conflict with slashes in urls
					execute :sed, "-i s%#{fetch(:stage_url)}%#{fetch(:local_url)}%g #{fetch(:backup_filename)}"

					# replace the remote table prefix with the local prefix
					execute :sed, "-i s/#{db_stage['prefix']}_/#{db_local['prefix']}_/g #{fetch(:backup_filename)}"

					# create the local database if it doesn't already exist
					execute :mysql, "-h#{db_local['host']} -u#{db_local['username']} -p#{db_local['password']} -e 'CREATE DATABASE IF NOT EXISTS #{db_local['database']}'"

					# execute the sql script on the local database
					execute :mysql, "-h#{db_local['host']} -u#{db_local['username']} -p#{db_local['password']} #{db_local['database']} < #{fetch(:backup_filename)}"
				end
			end

			run_locally do
				# delete the downloaded sql backup and delete the tmp directory if its empty
				execute :rm, "tmp/#{fetch(:backup_filename)}"
				if Dir['tmp/*'].empty?
					execute :rmdir, "tmp"
				end
			end
		end
	end

end