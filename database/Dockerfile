# Database Dockerfile - PostgreSQL
# Custom PostgreSQL image with initialization script

FROM postgres:15-alpine

# Set environment variables
ENV POSTGRES_DB=transport_db \
    POSTGRES_USER=postgres \
    POSTGRES_PASSWORD=postgres \
    POSTGRES_INITDB_ARGS="-c shared_buffers=256MB -c max_connections=200"

# Copy initialization script
COPY init.sql /docker-entrypoint-initdb.d/01-init.sql

# Add health check
HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=5 \
    CMD pg_isready -U postgres -d transport_db

# Expose port
EXPOSE 5432

# Run PostgreSQL
# Default entrypoint handles initialization automatically
