#!/bin/bash

export PGHOST=localhost
/usr/lib/postgresql/14/bin/pg_ctl start -D ~/postgresql-data/
bundle exec rails server
