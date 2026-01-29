-- Initialize Everything databases (database-per-service pattern)
-- Each service gets its own database for full isolation
-- This simulates having separate RDS instances in production

-- Create databases
CREATE DATABASE order_db;
CREATE DATABASE customer_db;
CREATE DATABASE temporal;
CREATE DATABASE temporal_visibility;

-- Create service users
CREATE USER order_service WITH PASSWORD 'order_service';
CREATE USER customer_service WITH PASSWORD 'customer_service';
CREATE USER temporal WITH PASSWORD 'temporal';

-- Grant database access
GRANT ALL PRIVILEGES ON DATABASE order_db TO order_service;
GRANT ALL PRIVILEGES ON DATABASE customer_db TO customer_service;
GRANT ALL PRIVILEGES ON DATABASE temporal TO temporal;
GRANT ALL PRIVILEGES ON DATABASE temporal_visibility TO temporal;

-- Connect to each database and set up permissions
\c order_db
GRANT ALL ON SCHEMA public TO order_service;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO order_service;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO order_service;

\c customer_db
GRANT ALL ON SCHEMA public TO customer_service;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO customer_service;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO customer_service;

\c temporal
GRANT ALL ON SCHEMA public TO temporal;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO temporal;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO temporal;

\c temporal_visibility
GRANT ALL ON SCHEMA public TO temporal;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO temporal;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO temporal;
