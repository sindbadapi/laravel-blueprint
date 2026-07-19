#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${POSTGRES_TEST_DB:-}" ]]; then
    psql --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<SQL
SELECT 'CREATE DATABASE ${POSTGRES_TEST_DB}'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${POSTGRES_TEST_DB}')\gexec
SQL
fi
