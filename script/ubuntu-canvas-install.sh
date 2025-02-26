#!/bin/bash

baseDir=$(pwd)

cdCanvasDir () {
  cd "${baseDir}/canvas-lms"
}

echo "!!! READ THE TEXT BELOW !!!"
echo "Make sure you are OK with everything below, or enter CTRL+C to exit and retry."
echo "->  This script will install Canvas-LMS into the current directory: $(pwd)"
echo "->  The downloaded files will only be accessible to the current user: $(whoami)"
echo "->  This script uses apt-get, thus only works on Ubuntu systems."
echo "->  Make sure to run this with 'sudo' prepended,"
echo "since it needs elevated access to install the dependecies."
echo "->  Once finished run ./start.sh to run Canvas-LMS."
echo "->  A database user named 'canvas' will be created,"
echo "and you will have to provide a (strong) password later."
echo "!!! READ THE TEXT ABOVE !!!"
echo "Press ENTER to proceed."
read

# Update package repositories
echo -e "\nUpdating package repositories...\n"
sudo apt-get -y install software-properties-common 
sudo add-apt-repository ppa:instructure/ruby
sudo apt-get update

echo -e "\Getting PostgreSQL Certificates...\n"
# Fetch the PostgreSQL key and add the repository to sources.list.d
sudo apt-get install wget ca-certificates
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
sudo apt-get update

# Install dependencies
echo -e "\nInstalling dependencies...\n"
sudo apt-get -y install ruby3.1 ruby3.1-dev libldap2-dev libidn11-dev postgresql-14 zlib1g-dev \
   libldap2-dev libidn11-dev libxml2-dev libsqlite3-dev libpq-dev libyaml-dev \
   libxmlsec1-dev curl build-essential git-core
sudo npm -g install yarn

sudo curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
nvm install 20
nvm use 20
node -v
npm -v

# Downloading Canvas-LMS
echo -e "\Downloading Canvas-LMS...\n"
git clone https://github.com/Osiris-Team/canvas-lms.git
cdCanvasDir
pwd
git checkout prod

# Install Ruby
echo -e "\nInstalling Ruby gems...\n"
gem install bundle
gem install bundler:2.3.26
gem install nokogumbo scrypt sanitize ruby-debug-ide

# Install project dependencies
echo -e "\nInstalling project dependencies...\n"
bundle _2.3.26_ install
yarn install --pure-lockfile

# Copy configuration files
echo -e "\nCopying configuration files...\n"
for config in amazon_s3 delayed_jobs domain file_store outgoing_mail security external_migration dynamic_settings database; \
          do cp -v config/$config.yml.example config/$config.yml; done

# Update project dependencies
echo -e "\nUpdating project dependencies...\n"
bundle _2.3.26_ update

# Initialize PostgreSQL
echo -e "\nInitializing PostgreSQL...\n"
export PGHOST=localhost
/usr/lib/postgresql/14/bin/initdb ~/postgresql-data/ -E utf8
/usr/lib/postgresql/14/bin/pg_ctl -D ~/postgresql-data/ -l ~/postgresql-data/server.log start
/usr/lib/postgresql/14/bin/createdb canvas_production

# Compile assets and set up the database
echo -e "\nCompiling assets and setting up the database...\n"
bundle exec rails canvas:compile_assets
bundle exec rails db:initial_setup
