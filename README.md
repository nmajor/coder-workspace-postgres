# PostgreSQL Development Image

A robust PostgreSQL Docker image designed for general development use in Coder workspaces. Built on the official PostGIS image with pgvector and common extensions pre-installed.

## 🚀 Quick Start

```bash
# Pull the latest image
docker pull ghcr.io/nmajor/coder-workspace-postgres:latest

# Run with default settings
docker run -d \
  --name postgres-dev \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  ghcr.io/nmajor/coder-workspace-postgres:latest

# Connect
psql -h localhost -U postgres
```

## 📦 Included Extensions

This image comes with the following extensions pre-installed and initialized in both `template1` and the default database:

### Core Extensions
- `uuid-ossp` - UUID generation functions
- `hstore` - Key-value pair storage
- `pg_trgm` - Trigram matching for fuzzy text search
- `btree_gist` / `btree_gin` - Additional index types
- `citext` - Case-insensitive text type
- `pgcrypto` - Cryptographic functions
- `tablefunc` - Crosstab and pivot table functions

### Spatial Extensions (from PostGIS)
- `postgis` - Spatial data types and functions
- `postgis_topology` - Topology support
- `postgis_raster` - Raster data support
- `postgis_tiger_geocoder` - TIGER geocoder for US addresses
- `fuzzystrmatch` - Fuzzy string matching
- `address_standardizer` - Address normalization
- `address_standardizer_data_us` - US address standardization data
- `pgrouting` - Routing and network analysis algorithms

### AI/ML Extensions
- `vector` (pgvector) - Vector similarity search for embeddings

### Utility Extensions
- `http` - HTTP client for making requests from SQL
- `pg_cron` - Job scheduling within PostgreSQL

## 🔧 Usage in Coder Workspaces

Add to your Coder template:

```hcl
resource "docker_container" "postgres" {
  image = "ghcr.io/nmajor/coder-workspace-postgres:latest"
  name  = "postgres-${data.coder_workspace.me.id}"

  env = [
    "POSTGRES_PASSWORD=postgres",
    "POSTGRES_DB=development"
  ]

  ports {
    internal = 5432
    external = 5432
  }
}
```

## 🛠️ Using Extensions

Extensions are already created in both `template1` and the default database, so they're ready to use immediately:

```sql
-- In the default database, extensions are already available
SELECT uuid_generate_v4();
SELECT ST_AsText(ST_Point(-71.060316, 48.432044));
SELECT '[1,2,3]'::vector;

-- Create a new database (extensions inherit from template1)
CREATE DATABASE myapp;

-- Connect to it
\c myapp

-- Extensions are already available here too
SELECT uuid_generate_v4();
```

If you need to create them manually in a new database:

```sql
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "vector";
```

## ✅ Verifying Extensions

To verify that all extensions are properly installed:

```sql
-- List all available extensions
SELECT * FROM pg_available_extensions WHERE name IN (
    'postgis', 'vector', 'pgrouting', 'http', 'pg_cron',
    'uuid-ossp', 'hstore', 'pg_trgm'
) ORDER BY name;

-- List all installed extensions in current database
SELECT * FROM pg_extension ORDER BY extname;

-- Check specific extension versions
SELECT PostGIS_Version();
SELECT extversion FROM pg_extension WHERE extname = 'vector';
SELECT extversion FROM pg_extension WHERE extname = 'http';
```

## 🔄 Adding More Extensions

To add additional extensions, edit the `Dockerfile`:

1. Install the package (if needed):
```dockerfile
RUN apt-get update && apt-get install -y \
    postgresql-${PG_MAJOR}-your-extension \
    && rm -rf /var/lib/apt/lists/*
```

2. Add to the initialization script:
```bash
CREATE EXTENSION IF NOT EXISTS "your_extension";
```

3. Push to trigger automatic rebuild via GitHub Actions

## 📝 Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `POSTGRES_USER` | `postgres` | PostgreSQL superuser name |
| `POSTGRES_PASSWORD` | (required) | PostgreSQL superuser password |
| `POSTGRES_DB` | `postgres` | Default database to create |
| `POSTGRES_INITDB_ARGS` | `--encoding=UTF8 --locale=en_US.utf8` | Arguments for initdb |

## 🏷️ Available Tags

- `latest` - Latest build from main branch
- `17-postgis3.5-pgvector` - Explicit version tag (PostgreSQL 17, PostGIS 3.5)
- `sha-<commit>` - Specific commit builds

## 🏗️ Building Locally

```bash
# Build the image
docker build -t postgres-dev .

# Run it
docker run -d \
  --name postgres-dev \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  postgres-dev

# Test extensions are installed
docker exec -it postgres-dev psql -U postgres -c "SELECT version();"
docker exec -it postgres-dev psql -U postgres -c "SELECT PostGIS_Version();"
docker exec -it postgres-dev psql -U postgres -c "SELECT extversion FROM pg_extension WHERE extname = 'vector';"

# Verify all extensions are available
docker exec -it postgres-dev psql -U postgres -c "SELECT extname FROM pg_extension ORDER BY extname;"

# Test pgvector functionality
docker exec -it postgres-dev psql -U postgres -c "SELECT '[1,2,3]'::vector <-> '[4,5,6]'::vector;"

# Cleanup
docker stop postgres-dev && docker rm postgres-dev
```

## 🔒 Making the Image Public

To ensure the image is publicly accessible:

1. Go to your GitHub repository
2. Navigate to **Packages** (on the right sidebar)
3. Click on your package (`coder-workspace-postgres`)
4. Click **Package settings**
5. Scroll to **Danger Zone**
6. Click **Change visibility** → **Public**

## ⚠️ Platform Support & ARM64 Limitation

### Current Status
This image currently builds for **linux/amd64 only**.

### Why No ARM64?
The base image `postgis/postgis:17-3.5` does not provide ARM64 builds. When multi-platform builds were attempted with `linux/amd64,linux/arm64`, the build failed with:

```
.buildkit_qemu_emulator: /bin/sh: Invalid ELF image for this architecture
```

This occurs because:
1. The PostGIS base image is amd64-only
2. QEMU emulation cannot run amd64 binaries on ARM64 build nodes

### How to Enable ARM64 (If PostGIS Adds Support)

If `postgis/postgis` releases ARM64 images in the future, update `.github/workflows/build-and-push.yml`:

```yaml
# Change this line:
platforms: linux/amd64

# To:
platforms: linux/amd64,linux/arm64
```

### Alternative: Build ARM64 from Source

To support ARM64 now, you would need to:

1. Use `postgres:17` as the base instead of `postgis/postgis`
2. Compile PostGIS from source for ARM64
3. This significantly increases build complexity and time

Example approach (not implemented):
```dockerfile
FROM postgres:17

# Install PostGIS build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libgeos-dev \
    libproj-dev \
    libgdal-dev \
    # ... many more dependencies

# Build PostGIS from source
RUN wget https://postgis.net/stuff/postgis-3.5.0.tar.gz \
    && tar xzf postgis-3.5.0.tar.gz \
    && cd postgis-3.5.0 \
    && ./configure \
    && make \
    && make install
```

**Recommendation:** Wait for official PostGIS ARM64 support rather than maintaining a custom build.

### Checking PostGIS ARM64 Availability

To check if ARM64 support has been added:
```bash
docker manifest inspect postgis/postgis:17-3.5 | grep arm64
```

If output shows `arm64`, you can enable multi-platform builds.

## 🤝 Contributing

To add more extensions or improve the image:

1. Fork this repository
2. Make your changes to the `Dockerfile`
3. Submit a pull request

The GitHub Actions workflow will automatically build and test your changes.

## 📚 Resources

- [PostgreSQL Official Documentation](https://www.postgresql.org/docs/)
- [PostGIS Documentation](https://postgis.net/documentation/)
- [pgvector Documentation](https://github.com/pgvector/pgvector)
- [Coder Documentation](https://coder.com/docs)

## 📄 License

This image is based on the official PostgreSQL and PostGIS images. Please refer to their respective licenses.
