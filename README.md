# cap-press

A framework for installing and deploying WordPress websites with Capistrano 3.

## Requirements

Make sure you have Ruby installed. [RVM](https://rvm.io/) is a good option for managing Ruby and Rubygems. [Git](http://git-scm.com/) is also required. You must have already installed your ssh keys into your remote repository and the environments you'll be deploying to.

## Installation

Clone this repo into a deployment directory of your choosing and run the installer:

	git clone git@github.com:Toddses/cap-press.git /home/user/deployments/example
	cd /home/user/deployments/example
	bundle install

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

	cp ./config/ex-database.yml ./config/database.yml

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

	cap -T

Install and set up WordPress locally with :

	cap local wp:local:install

This will install WordPress based on your settings and create a mysql database, initialize a git repo with three branches (dev, staging, master), and push the files to the remote repository. You must then set up WordPress by visiting the local site and following the instructions.

To deploy your site from git into an environment use :

	cap environment deploy

### License