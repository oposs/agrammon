FROM postgres:16-alpine

# Set environment variables for PostgreSQL
# Note: POSTGRES_USER creates the initial superuser role
# We'll create the agrammon user in init-roles.sh and change ownership
ENV POSTGRES_DB=agrammon_test
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres

# Copy initialization scripts
# PostgreSQL automatically runs scripts in /docker-entrypoint-initdb.d/ in alphabetical order
# 01-init-roles.sh will run before 02-agrammon_test.dump.sql
COPY init-roles.sh /docker-entrypoint-initdb.d/01-init-roles.sh
COPY test-data/agrammon.schema.sql /docker-entrypoint-initdb.d/02-agrammon.schema.sql

# Make sure the init script is executable
RUN chmod +x /docker-entrypoint-initdb.d/01-init-roles.sh

# Expose PostgreSQL port
EXPOSE 5432
