#!/usr/bin/env bash
# ==============================================================================
# Event and Ticket Booking System - Database Automation Helper Script
# BCSE302L - Database Systems
# Authors: Kevin T John, Govind B Nair, Shaarav S
# ==============================================================================

set -e

CONTAINER_NAME="ticket_booking_db"
DB_NAME="ticket_booking_system"
DB_USER="postgres"

function show_help() {
    echo "Usage: ./run_db.sh [command]"
    echo ""
    echo "Commands:"
    echo "  start       Start PostgreSQL container using Docker Compose"
    echo "  stop        Stop PostgreSQL container"
    echo "  status      Check container health status"
    echo "  init        Run schema (DDL), seed data (DML), and PL/pgSQL routines"
    echo "  queries     Execute Review II SQL queries suite"
    echo "  demo        Execute DML demo and 7 Real-World Transactions"
    echo "  psql        Open interactive psql terminal inside the database"
    echo "  reset       Drop all data, re-apply schema, seed data, and PL/pgSQL"
    echo ""
}

case "$1" in
    start)
        echo "Starting PostgreSQL container..."
        if docker compose version >/dev/null 2>&1; then
            docker compose up -d
        elif command -v docker-compose >/dev/null 2>&1; then
            docker-compose up -d
        else
            docker run --name "$CONTAINER_NAME" \
                -e POSTGRES_USER="$DB_USER" \
                -e POSTGRES_PASSWORD=postgrespassword \
                -e POSTGRES_DB="$DB_NAME" \
                -p 5432:5432 \
                -v "$(pwd)/database":/docker-entrypoint-initdb.d:ro \
                -d postgres:16-alpine
        fi
        echo "Container started! Waiting for PostgreSQL to be ready..."
        sleep 2
        ;;
    stop)
        echo "Stopping PostgreSQL container..."
        if docker compose version >/dev/null 2>&1; then
            docker compose down
        elif command -v docker-compose >/dev/null 2>&1; then
            docker-compose down
        else
            docker stop "$CONTAINER_NAME" || true
            docker rm "$CONTAINER_NAME" || true
        fi
        ;;
    status)
        docker ps --filter "name=$CONTAINER_NAME"
        ;;
    init)
        echo "1/3 Applying Schema DDL (01_schema.sql)..."
        docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -f /docker-entrypoint-initdb.d/01_schema.sql
        echo "2/3 Seeding Comprehensive Dataset (02_seed_data.sql)..."
        docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -f /docker-entrypoint-initdb.d/02_seed_data.sql
        echo "3/3 Installing PL/pgSQL Routines & Triggers (04_plsql.sql)..."
        docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -f /docker-entrypoint-initdb.d/04_plsql.sql
        echo "Database Initialization complete!"
        ;;
    queries)
        echo "Executing Review II SQL Query Suite..."
        docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -f /docker-entrypoint-initdb.d/03_review2_queries.sql
        ;;
    demo)
        echo "Executing Section 6.4: DML Operations Demo (06_dml_demo.sql)..."
        docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -f /docker-entrypoint-initdb.d/demos/06_dml_demo.sql
        echo ""
        echo "Executing Section 9: 7 Real-World Transactions Demo (07_transactions_demo.sql)..."
        docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -f /docker-entrypoint-initdb.d/demos/07_transactions_demo.sql
        ;;
    psql)
        echo "Opening interactive PostgreSQL shell..."
        docker exec -it "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME"
        ;;
    reset)
        echo "Resetting database to clean initial state..."
        docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -f /docker-entrypoint-initdb.d/01_schema.sql
        docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -f /docker-entrypoint-initdb.d/02_seed_data.sql
        docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -f /docker-entrypoint-initdb.d/04_plsql.sql
        echo "Database reset and re-seeded successfully!"
        ;;
    *)
        show_help
        ;;
esac
