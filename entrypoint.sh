#!/bin/sh
set -e

echo "=== Garfenter Mercado Startup ==="

# Database configuration from environment
DB_HOST="${TYPEORM_HOST:-garfenter-mysql}"
DB_PORT="${TYPEORM_PORT:-3306}"
DB_USER="${TYPEORM_USERNAME:-garfenter}"
DB_PASS="${TYPEORM_PASSWORD}"
DB_NAME="${TYPEORM_DATABASE:-garfenter_mercado}"

# Wait for MySQL to be ready (using simple connection test, skip SSL)
echo "Waiting for MySQL at ${DB_HOST}:${DB_PORT}..."
max_attempts=60
attempt=0

while [ $attempt -lt $max_attempts ]; do
    # Use mysql query instead of mysqladmin ping to avoid SSL issues
    if mysql --skip-ssl -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" -e "SELECT 1" >/dev/null 2>&1; then
        echo "MySQL is ready!"
        break
    fi
    attempt=$((attempt + 1))
    echo "MySQL not ready, waiting... (attempt ${attempt}/${max_attempts})"
    sleep 2
done

if [ $attempt -eq $max_attempts ]; then
    echo "ERROR: MySQL not available after ${max_attempts} attempts"
    exit 1
fi

# Check if database needs initialization
echo "Checking if database needs initialization..."
TABLE_COUNT=$(mysql --skip-ssl -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${DB_NAME}';" 2>/dev/null || echo "0")

if [ "$TABLE_COUNT" = "0" ] || [ -z "$TABLE_COUNT" ]; then
    echo "Database is empty. Importing schema..."

    # Create database if not exists
    mysql --skip-ssl -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};" 2>/dev/null || true

    # Import the SQL schema
    if [ -f /spurtcommerce-api/init.sql ]; then
        echo "Importing spurtcommerce schema (this may take a few minutes)..."
        mysql --skip-ssl -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < /spurtcommerce-api/init.sql
        echo "Database schema imported successfully!"
    else
        echo "WARNING: init.sql not found, skipping schema import"
    fi
else
    echo "Database already has ${TABLE_COUNT} tables, skipping initialization"
fi

echo "Starting Spurt Commerce API..."
exec node dist-obf/src/app.js
