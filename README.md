# capify-press

A framework for managing WordPress websites with multiple server environments using Capistrano 3.

## Requirements

* Ruby >= 1.9.3

[RVM](https://rvm.io/) is a good option for managing Ruby and Gems. [Git](http://git-scm.com/) is also required. You must have already installed your ssh keys into your remote repository and the environments you'll be deploying to.

## Installation

Clone this repo into a deployment directory of your choosing and run the installer:

``` sh
$ git clone git@github.com:Toddses/cap-press.git /home/user/deployments/example
$ cd /home/user/deployments/example
$ bundle install
```

### Setup

Create a remote repository somewhere, for instance at [GitHub](https://github.com/) or [BitBucket](https://bitbucket.org/).

Edit the required settings in `config/deploy.rb`:

``` ruby
# Required Settings
# ==================

set:application, "example"
set:wp_version, "4.1"
set:repo_url, "git@github.com:User/example.git"
set:admin_email, "user@example.com"

set:local_url, "http://localhost"
set:local_path, "/var/www/html/example"
```

Set up your database info:

``` sh
$ cd config
$ cp ex-database.yml database.yml
```

Edit `database.yml` with your own details for each environment. Prefix is the table prefix WordPress will use for each environment. Do not include this file in any repo!

Three environments will be created by default:

``` sh
$ ls config/deploy
local.rb
staging.rb
production.rb
```

Edit the settings in `staging.rb` and/or `production.rb` with your own info:

```ruby
# Required Settings
# ==================

server "xxx.xxx.xxx.xxx", user: "your_ssh_user", roles: %w{web app db}
set:stage_url, "http://example.com"
set:deploy_to, '/var/www/example'

# Git Setup
# ==================

set:branch, "master"

# WordPress Setup
# ==================

set:wp_debug, true
set:wp_cache, false
```

You can leave `local.rb` alone. For now, it is mostly for semantic purposes.

You're good to go!

### Adding Environments

You can add or change environments as needed. Say you want to change staging to test, simply rename `staging.rb` to `test.rb`. If you'd like to create additional environments, copy one of the stage files and edit the settings from there:

``` sh
$ cp config/deploy/staging.rb config/deploy/test.rb
```

### Slack

Slack integration provided by [capistrano-slackify](https://github.com/onthebeach/capistrano-slackify). In slack, ensure you have enabled the [incoming webhooks integration](https://api.slack.com/). Edit `config/slack.rb` with your webhook url provided in the setup instructions: 

```ruby
# Required Setting
# ==================
set:slack_url, 'https://hooks.slack.com/services/xxxxxxx'
```

There are also a number of optional settings you can customize. The task will run automatically during deployments.

## Usage

You can see all described tasks at any time with the command:

``` sh
$ cap -T
```

### Commands

* **cap stage deploy**: Deploy the site from the repository to the remote server
* **cap local wp:local:install**: Install WordPress locally and set up the repo and database
* **cap stage wp:remote:push**: Deploy the site and push the database and uploads from the local server
* **cap stage wp:remote:pull**: Clone a remote repository and pull the database and uploads from the stage server
* **cap stage db:push**: Pushes a local export of the MySQL database to the remote server
* **cap stage db:pull**: Pulls a remote export of the MySQL database and imports to the local server
* **cap stage uploads:push**: Transfer local uploads content to remote server
* **cap stage uploads:pull**: Transfer remote uploads content to local server

Each of these tasks takes care of the basic legwork for you. Installing WordPress will create the database, if necessary, set up your local config files (`wp-config.php` and `.htaccess`), start your repo with a `.gitignore` that's good for WordPress and a basic README, and push it to the remote repo with an initial commit.

Deploying will create the config files for the stage automatically.

Pushing/pulling the database will replace the URLs in the database, as well as the table prefixes, so you can bring up the site with no additional set up necessary.

Pushing/pulling the uploads will not overwrite, but merge. Existing files will be overwritten, but new files will not be deleted.

### Additional Commands

If your remote server is running Apache 2, there's already a few tasks to automate the basics. These can easily be extended to handle more of the legwork, and additional tasks for different servers may be added in the future.

* **cap stage apache:setup**: Enable the rewrite module (usually it is not already enabled)
* **cap stage apache:vhost:create**: Create an apache configuration file and enable the site
* **cap stage apache:vhost:destroy**: Delete the apache configuration file and disable the site

The vhost tasks will set up the host with the stage URL you have set.

Feel free to fork this project and create pull requests for any additional tasks you may have created!

## License

MIT License (MIT)

Copyright (c) 2012-2015 Tom Clements, Lee Hambley

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.