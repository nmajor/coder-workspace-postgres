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

This image comes with the following extensions pre-installed and initialized in `template1`:

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
- `fuzzystrmatch` - Fuzzy string matching
- `address_standardizer` - Address normalization
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

Extensions are already created in `template1`, so they're available in all new databases:

```sql
-- Create a new database (extensions are already available)
CREATE DATABASE myapp;

-- Connect to it
\c myapp

-- Extensions are ready to use
SELECT uuid_generate_v4();
SELECT ST_AsText(ST_Point(-71.060316, 48.432044));
SELECT '[1,2,3]'::vector;
```

If you need to create them manually:

```sql
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "vector";
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
- `16-postgis3.4-pgvector` - Explicit version tag (PostgreSQL 16, PostGIS 3.4)
- `sha-<commit>` - Specific commit builds

## 🏗️ Building Locally

```bash
# Build the image
docker build -t postgres-dev .

# Run it
docker run -d -e POSTGRES_PASSWORD=postgres -p 5432:5432 postgres-dev

# Test extensions
docker exec -it <container-id> psql -U postgres -c "SELECT version();"
docker exec -it <container-id> psql -U postgres -c "SELECT PostGIS_Version();"
docker exec -it <container-id> psql -U postgres -c "SELECT vector_version();"
```

## 🔒 Making the Image Public

To ensure the image is publicly accessible:

1. Go to your GitHub repository
2. Navigate to **Packages** (on the right sidebar)
3. Click on your package (`coder-workspace-postgres`)
4. Click **Package settings**
5. Scroll to **Danger Zone**
6. Click **Change visibility** → **Public**

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
