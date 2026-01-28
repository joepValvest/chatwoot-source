#!/bin/sh

set -e

echo "Waiting for database..."

# Let DATABASE_URL env take precedence over individual connection params
if [ -z "$DATABASE_URL" ]; then
  export PGHOST=${POSTGRES_HOST}
  export PGPORT=${POSTGRES_PORT}
  export PGUSER=${POSTGRES_USERNAME}
fi

# Wait for database
until pg_isready -h ${POSTGRES_HOST:-localhost} -p ${POSTGRES_PORT:-5432}; do
  sleep 1
done

echo "Database is now available"

# Prepare database (creates if doesn't exist)
bundle exec rails db:chatwoot_prepare

# Run migrations
bundle exec rails db:migrate

# Start Sidekiq in background
bundle exec sidekiq -C config/sidekiq.yml &

# Start Rails server in foreground
exec bundle exec rails s -b 0.0.0.0 -p ${PORT:-3000}
