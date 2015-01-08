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
			# set up variables for config file
			siteurl = fetch(:stage_url)
			wp_debug = fetch(:wp_debug)
			wp_cache = fetch(:wp_cache)
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

end