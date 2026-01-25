#!/bin/sh
set -e

echo 'Starting PostgreSQL schema setup...'
echo 'Waiting for PostgreSQL port to be available...'
until nc -z -w 10 $POSTGRES_SEEDS $DB_PORT; do
  echo 'Waiting for PostgreSQL...'
  sleep 2
done
echo 'PostgreSQL port is available'

# Create and setup temporal database (ignore error if already exists)
temporal-sql-tool --plugin postgres12 --ep $POSTGRES_SEEDS -u $POSTGRES_USER -p $DB_PORT --pw $POSTGRES_PWD --db $DBNAME create || echo "Database $DBNAME may already exist, continuing..."
temporal-sql-tool --plugin postgres12 --ep $POSTGRES_SEEDS -u $POSTGRES_USER -p $DB_PORT --pw $POSTGRES_PWD --db $DBNAME setup-schema -v 0.0 || echo "Schema already set up for $DBNAME, continuing..."
temporal-sql-tool --plugin postgres12 --ep $POSTGRES_SEEDS -u $POSTGRES_USER -p $DB_PORT --pw $POSTGRES_PWD --db $DBNAME update-schema -d /etc/temporal/schema/postgresql/v12/temporal/versioned

# Create and setup visibility database (ignore error if already exists)
temporal-sql-tool --plugin postgres12 --ep $VISIBILITY_POSTGRES_SEEDS -u $VISIBILITY_POSTGRES_USER -p $VISIBILITY_DB_PORT --pw $VISIBILITY_POSTGRES_PWD --db $VISIBILITY_DBNAME create || echo "Database $VISIBILITY_DBNAME may already exist, continuing..."
temporal-sql-tool --plugin postgres12 --ep $VISIBILITY_POSTGRES_SEEDS -u $VISIBILITY_POSTGRES_USER -p $VISIBILITY_DB_PORT --pw $VISIBILITY_POSTGRES_PWD --db $VISIBILITY_DBNAME setup-schema -v 0.0 || echo "Schema already set up for $VISIBILITY_DBNAME, continuing..."
temporal-sql-tool --plugin postgres12 --ep $VISIBILITY_POSTGRES_SEEDS -u $VISIBILITY_POSTGRES_USER -p $VISIBILITY_DB_PORT --pw $VISIBILITY_POSTGRES_PWD --db $VISIBILITY_DBNAME update-schema -d /etc/temporal/schema/postgresql/v12/visibility/versioned

echo 'PostgreSQL schema setup complete'