# PostgreSQL Development Image with PostGIS and pgvector
# Base: PostGIS for spatial support, adds pgvector for AI/ML vector operations
# Includes common development extensions

ARG PG_MAJOR=16
ARG POSTGIS_VERSION=3.4

FROM postgis/postgis:${PG_MAJOR}-${POSTGIS_VERSION}

LABEL org.opencontainers.image.title="PostgreSQL Dev with PostGIS & Extensions"
LABEL org.opencontainers.image.description="Robust PostgreSQL image for development with PostGIS, pgvector, and common extensions"
LABEL org.opencontainers.image.source="https://github.com/nmajor/coder-workspace-postgres"

# Install build dependencies and pgvector
RUN apt-get update && apt-get install -y \
    postgresql-${PG_MAJOR}-pgvector \
    postgresql-${PG_MAJOR}-pgrouting \
    postgresql-${PG_MAJOR}-http \
    postgresql-${PG_MAJOR}-cron \
    && rm -rf /var/lib/apt/lists/*

# Create initialization script to enable extensions
RUN mkdir -p /docker-entrypoint-initdb.d
COPY <<'EOF' /docker-entrypoint-initdb.d/00-init-extensions.sh
#!/bin/bash
set -e

# This script creates common extensions in template1 so they're available in all new databases
# Users can still manually CREATE EXTENSION for these if preferred

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname template1 <<-EOSQL
    -- Core PostgreSQL extensions (usually pre-installed)
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";      -- UUID generation
    CREATE EXTENSION IF NOT EXISTS "hstore";         -- Key-value store
    CREATE EXTENSION IF NOT EXISTS "pg_trgm";        -- Trigram matching for fuzzy search
    CREATE EXTENSION IF NOT EXISTS "btree_gist";     -- Additional index types
    CREATE EXTENSION IF NOT EXISTS "btree_gin";      -- Additional index types
    CREATE EXTENSION IF NOT EXISTS "citext";         -- Case-insensitive text
    CREATE EXTENSION IF NOT EXISTS "pgcrypto";       -- Cryptographic functions
    CREATE EXTENSION IF NOT EXISTS "tablefunc";      -- Crosstab and pivot functions

    -- Spatial extensions (from PostGIS image)
    CREATE EXTENSION IF NOT EXISTS "postgis";        -- Spatial data types and functions
    CREATE EXTENSION IF NOT EXISTS "postgis_topology"; -- Topology support
    CREATE EXTENSION IF NOT EXISTS "postgis_raster"; -- Raster data support
    CREATE EXTENSION IF NOT EXISTS "fuzzystrmatch";  -- Fuzzy string matching
    CREATE EXTENSION IF NOT EXISTS "address_standardizer"; -- Address normalization

    -- Additional extensions
    CREATE EXTENSION IF NOT EXISTS "vector";         -- pgvector for AI/ML embeddings
    CREATE EXTENSION IF NOT EXISTS "pgrouting";      -- Routing algorithms
    CREATE EXTENSION IF NOT EXISTS "http";           -- HTTP client
    CREATE EXTENSION IF NOT EXISTS "pg_cron";        -- Job scheduling
EOSQL

echo "Extensions initialized in template1"
EOF

RUN chmod +x /docker-entrypoint-initdb.d/00-init-extensions.sh

# Environment variables for PostgreSQL configuration
ENV POSTGRES_INITDB_ARGS="--encoding=UTF8 --locale=en_US.utf8"

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD pg_isready -U ${POSTGRES_USER:-postgres} || exit 1

# Expose PostgreSQL port
EXPOSE 5432

# Use the default PostgreSQL entrypoint
# The image already has ENTRYPOINT and CMD from postgis/postgis
