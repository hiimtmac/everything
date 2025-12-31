#!/bin/sh
set -eu

echo 'Starting PostgreSQL schema setup...'
echo 'Waiting for PostgreSQL port to be available...'
nc -z -w 10 $POSTGRES_SEEDS $DB_PORT
echo 'PostgreSQL port is available'

# Create and setup temporal database
temporal-sql-tool --plugin postgres12 --ep $POSTGRES_SEEDS -u $POSTGRES_USER -p $DB_PORT --pw $POSTGRES_PWD --db $DBNAME create
temporal-sql-tool --plugin postgres12 --ep $POSTGRES_SEEDS -u $POSTGRES_USER -p $DB_PORT --pw $POSTGRES_PWD --db $DBNAME setup-schema -v 0.0
temporal-sql-tool --plugin postgres12 --ep $POSTGRES_SEEDS -u $POSTGRES_USER -p $DB_PORT --pw $POSTGRES_PWD --db $DBNAME update-schema -d /etc/temporal/schema/postgresql/v12/temporal/versioned

# Create and setup visibility database
temporal-sql-tool --plugin postgres12 --ep $VISIBILITY_POSTGRES_SEEDS -u $VISIBILITY_POSTGRES_USER -p $VISIBILITY_DB_PORT --pw $VISIBILITY_POSTGRES_PWD --db $VISIBILITY_DBNAME create
temporal-sql-tool --plugin postgres12 --ep $VISIBILITY_POSTGRES_SEEDS -u $VISIBILITY_POSTGRES_USER -p $VISIBILITY_DB_PORT --pw $VISIBILITY_POSTGRES_PWD --db $VISIBILITY_DBNAME setup-schema -v 0.0
temporal-sql-tool --plugin postgres12 --ep $VISIBILITY_POSTGRES_SEEDS -u $VISIBILITY_POSTGRES_USER -p $VISIBILITY_DB_PORT --pw $VISIBILITY_POSTGRES_PWD --db $VISIBILITY_DBNAME update-schema -d /etc/temporal/schema/postgresql/v12/visibility/versioned

echo 'PostgreSQL schema setup complete'