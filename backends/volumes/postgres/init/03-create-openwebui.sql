-- Create openwebui user and database
CREATE USER openwebui WITH PASSWORD 'openwebui';
CREATE DATABASE openwebui OWNER openwebui;
GRANT ALL PRIVILEGES ON DATABASE openwebui TO openwebui;
