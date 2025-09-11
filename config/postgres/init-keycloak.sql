-- PostgreSQL initialization script for Keycloak
-- This script creates separate user and database for Keycloak

-- Create keycloak user
CREATE USER keycloak WITH PASSWORD 'KEYCLOAK_DB_PASSWORD_PLACEHOLDER';

-- Create keycloak database
CREATE DATABASE keycloak OWNER keycloak;

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;

