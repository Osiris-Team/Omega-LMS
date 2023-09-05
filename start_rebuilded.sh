#!/bin/bash

# Build
rvm install "ruby-3.1.0"
rvm use 3.1.0
gem install bundle
gem install bundler:2.3.26
bundle _2.3.26_ install
yarn install --pure-lockfile
bundle _2.3.26_ update
bundle exec rails canvas:compile_assets

# Run
export PGHOST=localhost
/usr/lib/postgresql/14/bin/pg_ctl start -D ~/postgresql-data/
bundle exec rails server
