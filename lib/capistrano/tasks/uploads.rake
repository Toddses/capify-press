namespace :uploads do

	desc "Transfer local uploads content to remote server"
	task :push do
		on roles(:app) do
			upload! "#{fetch(:local_path)}/wp-content/uploads", "#{shared_path}/wp-content", recursive: true
		end
	end

	desc "Transfer remote uploads content to local server"
	task :pull do
		on roles(:app) do
			download! "#{shared_path}/wp-content/uploads", "#{fetch(:local_path)}/wp-content", recursive: true
		end
	end

end