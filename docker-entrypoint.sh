#!/bin/bash

set -Eeou pipefail

# https://medium.com/@adrian.gheorghe.dev/using-docker-secrets-in-your-environment-variables-7a0609659aab
file_env() {
   local var="$1"
   local fileVar="${var}_FILE"
   local def="${2:-}"

   if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
      echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
      exit 1
   fi
   local val="$def"
   if [ "${!var:-}" ]; then
      val="${!var}"
   elif [ "${!fileVar:-}" ]; then
      val="$(< "${!fileVar}")"
   fi
   export "$var"="$val"
   unset "$fileVar"
}

ensure_env() {
    # [required] The hostname of the target Postgres instance.
    export PG_HOST="${PG_HOST:?required}"

    # [optional] The port of the target Postgres instance (default 5432).
    export PG_PORT="${PG_PORT:=5432}"

    # [optional] The username of the admin user (default postgres).
    export PG_USERNAME="${PG_USERNAME:=postgres}"

    # [required] The password of the admin user. Can also use PG_PASSWORD_FILE.
    file_env "PG_PASSWORD"
    export PG_PASSWORD="${PG_PASSWORD:?required}"

    # [required] The database/username of the newly created user.
    export DB_USERNAME="${DB_USERNAME:?required}"

    # [required] The password for the newly created user. Can also use DB_PASSWORD_FILE.
    file_env "DB_PASSWORD"
    export DB_PASSWORD="${DB_PASSWORD:?required}"
}

run_psql() {
    PGPASSWORD="$PG_PASSWORD" psql \
        --host $PG_HOST \
        --port $PG_PORT \
        --username $PG_USERNAME \
        --no-password \
        --tuples-only \
        --set ON_ERROR_STOP=1 \
        --set v_database="$DB_USERNAME" \
        --set v_username="$DB_USERNAME" \
        --set v_password="$DB_PASSWORD" \
        "$@"
}

ensure_database() {
    local check="SELECT 1 FROM pg_database where datname = :'v_database'"
    local create="CREATE DATABASE :\"v_database\""

    if [ -z $( echo $check | run_psql ) ]; then
        echo $create | run_psql
    fi
}

ensure_user() {
    local check="SELECT 1 FROM pg_roles WHERE rolname = :'v_username'"
    local create="CREATE USER :v_username WITH PASSWORD :'v_password'"

    if [ -z $( echo $check | run_psql ) ]; then
        echo $create | run_psql
    fi
}

ensure_grant() {
    echo "GRANT ALL PRIVILEGES ON DATABASE :v_database TO :v_username" | run_psql
    echo "GRANT ALL ON schema public TO :v_username" | run_psql --dbname $DB_USERNAME
}

ensure_env
ensure_database
ensure_user
ensure_grant
