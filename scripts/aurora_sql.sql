CREATE EXTENSION IF NOT EXISTS vector;
CREATE SCHEMA IF NOT EXISTS bedrock_integration;

-- Roles cannot be created with 'IF NOT EXISTS' easily, so we use a DO block
DO $$ 
BEGIN 
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'bedrock_user') THEN
    CREATE ROLE bedrock_user LOGIN;
  END IF;
END $$;

GRANT ALL ON SCHEMA bedrock_integration to bedrock_user;

CREATE TABLE IF NOT EXISTS {{TABLE_NAME}} (
    id uuid PRIMARY KEY,
    embedding vector(1536),
    chunks text,
    metadata json
);

CREATE INDEX IF NOT EXISTS bedrock_kb_embedding_idx ON {{TABLE_NAME}} USING hnsw (embedding vector_cosine_ops);