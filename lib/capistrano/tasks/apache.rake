namespace :apache do

	desc "Set up the apache server with the rewrite module (usually it is not already enabled) and disable the default site"
	task :setup do
		on roles(:web) do
			execute :a2enmod, "rewrite"
			execute :a2dissite, "000-default.conf"

			# restart the server for the changes to take effect
			execute :service, "apache2 restart"
		end
	end

	namespace :vhost do

		# Build the variables and filenames for the apache configuration file.
		task :build_data do
			set :conf_filename, "#{fetch(:application)}.conf"
			set :doc_root, "#{fetch(:deploy_to)}/current"
			set :server_name, fetch(:stage_url).split("//").fetch(1)

			#run_locally do
				#execute :echo, "conf_file #{fetch(:conf_file)}"
				#execute :echo, "doc_root #{fetch(:doc_root)}"
				#execute :echo, "server_name #{fetch(:server_name)}"
			#end
		end

		desc "Create an apache configuration file and enable the site"
		task :create do
			invoke "apache:vhost:build_data"

			on roles(:web) do
				# set up the data for the configuration template
				admin_email = fetch(:admin_email)
				doc_root = fetch(:doc_root)
				server_name = fetch(:server_name)

				# create and upload the configuration
        		conf_file = ERB.new(File.read('config/templates/apache.conf.erb')).result(binding)
        		io = StringIO.new(conf_file)
        		upload! io, File.join("/etc/apache2/sites-available", fetch(:conf_filename))

        		# enable the new vhost and restart the server
        		execute :a2ensite, fetch(:conf_filename)
        		execute :service, "apache2 restart"
			end
		end

		desc "Delete the apache configuration file and disable the site"
		task :destroy do
			invoke "apache:vhost:build_data"

			on roles(:web) do
				# disable the vhost
				execute :a2dissite, fetch(:conf_filename)

				# restart the server
				execute :service, "apache2 restart"

				# remove the configuration file
				execute :rm, File.join("/etc/apache2/sites-available", fetch(:conf_filename))
			end
		end

	end

end