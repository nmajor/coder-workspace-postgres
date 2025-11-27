# PostgreSQL Development Image with PostGIS and pgvector
# Base: PostGIS for spatial support, adds pgvector for AI/ML vector operations
# Includes common development extensions

ARG PG_MAJOR=17
ARG POSTGIS_VERSION=3.5

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

# Function to create extensions in a database
create_extensions() {
    local db=$1
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$db" <<-EOSQL
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
        CREATE EXTENSION IF NOT EXISTS "fuzzystrmatch";  -- Fuzzy string matching (required by tiger_geocoder)
        CREATE EXTENSION IF NOT EXISTS "postgis_tiger_geocoder"; -- Tiger geocoder (depends on fuzzystrmatch)
        CREATE EXTENSION IF NOT EXISTS "address_standardizer"; -- Address normalization
        CREATE EXTENSION IF NOT EXISTS "address_standardizer_data_us"; -- US address data

        -- Additional extensions
        CREATE EXTENSION IF NOT EXISTS "vector";         -- pgvector for AI/ML embeddings
        CREATE EXTENSION IF NOT EXISTS "pgrouting";      -- Routing algorithms
        CREATE EXTENSION IF NOT EXISTS "http";           -- HTTP client
        -- Note: pg_cron requires shared_preload_libraries config, created separately below
EOSQL
}

# Create extensions in template1 so they're available in all new databases
echo "Creating extensions in template1..."
create_extensions "template1"

# Also create extensions in the default database if it exists and is not template1
if [ "$POSTGRES_DB" != "template1" ]; then
    echo "Creating extensions in database: $POSTGRES_DB"
    create_extensions "$POSTGRES_DB"
fi

echo "Extensions initialized successfully"
EOF

RUN chmod +x /docker-entrypoint-initdb.d/00-init-extensions.sh

# Add pg_cron to shared_preload_libraries (required for pg_cron extension)
# This script runs after PostgreSQL is initialized but before it accepts connections
COPY <<'EOF' /docker-entrypoint-initdb.d/01-setup-pg-cron.sh
#!/bin/bash
set -e

# pg_cron requires shared_preload_libraries and can only be created in one database
# Add the configuration
echo "shared_preload_libraries = 'pg_cron'" >> "$PGDATA/postgresql.conf"
echo "cron.database_name = '${POSTGRES_DB:-postgres}'" >> "$PGDATA/postgresql.conf"

echo "pg_cron configuration added to postgresql.conf"
EOF

RUN chmod +x /docker-entrypoint-initdb.d/01-setup-pg-cron.sh

# Create pg_cron extension after restart (runs on subsequent startups)
COPY <<'EOF' /docker-entrypoint-initdb.d/02-create-pg-cron.sh
#!/bin/bash
set -e

# pg_cron extension can only be created after postgres restarts with shared_preload_libraries
# This will fail on first init but succeed on restart, which is expected behavior
# Users can manually run: CREATE EXTENSION IF NOT EXISTS "pg_cron";
echo "Note: pg_cron extension must be created manually after first container start:"
echo "  psql -U postgres -c 'CREATE EXTENSION IF NOT EXISTS pg_cron;'"
EOF

RUN chmod +x /docker-entrypoint-initdb.d/02-create-pg-cron.sh

# Environment variables for PostgreSQL configuration
ENV POSTGRES_INITDB_ARGS="--encoding=UTF8 --locale=en_US.utf8"

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD pg_isready -U ${POSTGRES_USER:-postgres} || exit 1

# Expose PostgreSQL port
EXPOSE 5432

# Use the default PostgreSQL entrypoint
# The image already has ENTRYPOINT and CMD from postgis/postgis
