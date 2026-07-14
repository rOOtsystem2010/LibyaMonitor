-- Create service databases required by the Docker stack.
-- The LGNM application schema is installed into POSTGRES_DB (default: lgnm).
SELECT 'CREATE DATABASE n8n'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'n8n')\gexec
