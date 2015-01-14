# cap-press

A framework for installing and deploying WordPress websites with Capistrano 3.

## Requirements

Make sure you have Ruby installed. [RVM](https://rvm.io/) is a good option for managing Ruby and Rubygems. [Git](http://git-scm.com/) is also required. You must have already installed your ssh keys into your remote repository and the environments you'll be deploying to.

## Installation

Clone this repo into a deployment directory of your choosing and run the installer:

	$ git clone git@github.com:Toddses/cap-press.git /home/user/deployments/example
	$ cd /home/user/deployments/example
	$ bundle install

### Setup

Create a remote repository somewhere, for instance at [GitHub]() or [BitBucket]().

Edit the required settings in ./config/deploy.rb :

```ruby
# Required Settings
# ==================

set :application, "example"
set :wp_version, "4.1"
set :repo_url, "git@github.com:User/example.git"
set :admin_email, "user@example.com"

set :local_url, "http://localhost"
set :local_path, "/var/www/html/example"
```

Set up your database info :

	$ cp ./config/ex-database.yml ./config/database.yml

Edit database.yml with your own details for each environment. Prefix is the table prefix WordPress will use for each environment. Do not include this file in any repo!

Three environments will be created by default :

	./config/deploy/local.rb
	./config/deploy/staging.rb
	./config/deploy/production.rb

Edit the settings in ./config/deploy/staging.rb and/or ./config/deploy/production.rb with your own info :

```ruby
# Required Settings
# ==================

server "xxx.xxx.xxx.xxx", user: "your_ssh_user", roles: %w{web app db}
set :stage_url, "http://example.com"
set :deploy_to, '/var/www/example'

# Git Setup
# ==================

set :branch, "master"

# WordPress Setup
# ==================

set :wp_debug, true
set :wp_cache, false
```

You can leave ./config/deploy/local.rb alone.

You're good to go!

### Slack

Slack integration provided by [capistrano-slackify](https://github.com/onthebeach/capistrano-slackify). In slack, ensure you have enabled the [incoming webhooks integration](https://api.slack.com/). Edit in .config/slack.rb with your webhook url provided in the setup instructions : 

```ruby
# Required Setting
# ==================
set :slack_url, 'https://hooks.slack.com/services/xxxxxxx'
```

There are also a number of optional settings you can customize. The task will run automatically during deployments.

## Usage

You can see all described tasks at any time with the command :

	$ cap -T

### WordPress Installation

	$ cap local wp:local:install

Clones the official WordPress repository (whichever version you have in the settings) to your local path and creates the local wp-config and .htaccess. Will then initialize the git repository, create three branches (master, staging, dev) and push everything to the remote repository for an initial commit. Finally, will create the local database on the mysql server. After its all said and done, just visit your local site and complete the WordPress install.

	$ cap stage wp:remote:install

Deploys from the remote repository to the stage in the command. This will automatically set up your remote config files, set up and push your local database to the stage mysql server, and push your local uploads files to the stage server. The URLs in the database will automatically be updated to the correct URLs for the stage site. Your site is now ready to go on your stage server, no need to bring up the site and complete the WordPress installation.

	$ cap stage deploy

Will deploy your site from the remote repository to the stage in the command. Nothing else will be pushed to the server, just the code from the repository.

## License

MIT License (MIT)

Copyright (c) 2012-2015 Tom Clements, Lee Hambley

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.