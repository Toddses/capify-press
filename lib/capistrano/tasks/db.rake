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
				# replace the local url with the remote url, using the escaped strings
				execute :sed, "-i s%#{fetch(:local_url)}%#{fetch(:stage_url)}%g #{fetch(:backup_filename)}"

				# create the remote database if it doesn't already exist
				execute :mysqladmin, "-h#{db_stage['host']} -u#{db_stage['username']} -p#{db_stage['password']} create #{db_stage['database']}"

				# execute the sql script on the database
				execute :mysql, "-h#{db_stage['host']} -u#{db_stage['username']} -p#{db_stage['password']} #{db_stage['database']} < #{fetch(:backup_filename)}"
			end

			run_locally do
				execute "rm tmp/#{fetch(:backup_filename)}"
				if Dir['tmp/*'].empty?
					execute :rmdir, "tmp"
				end
			end
		end
	end

	desc "TEST"
	task :test do
		run_locally do
			db_local = YAML::load_file('config/database.yml')['local']
			db_stage = YAML::load_file('config/database.yml')[fetch(:stage).to_s]
			execute :echo, "#{db_local['password']}"
			execute :echo, "#{db_stage['password']}"
		end
	end

end