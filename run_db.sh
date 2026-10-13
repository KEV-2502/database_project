#!/usr/bin/env bash
# ==============================================================================
# Event and Ticket Booking System - Database Automation Helper Script
# BCSE302L - Database Systems
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
    echo "  init        Run schema (DDL) and seed data (DML)"
    echo "  queries     Execute Review II SQL queries"
    echo "  psql        Open interactive psql terminal inside the database"
    echo "  reset       Drop all data, re-apply schema, and re-seed database"
    echo ""
}

case "$1" in
    start)
        echo "Starting PostgreSQL container..."
        docker compose up -d
        ;;
    stop)
        echo "Stopping PostgreSQL container..."
        docker compose down
        ;;
    status)
        docker ps --filter "name=$CONTAINER_NAME"
        ;;
    init)
        echo "Applying schema (01_schema.sql)..."
        docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -f /docker-entrypoint-initdb.d/01_schema.sql
        echo "Seeding data (02_seed_data.sql)..."
        docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -f /docker-entrypoint-initdb.d/02_seed_data.sql
        echo "Initialization complete!"
        ;;
    queries)
        echo "Executing Review II query suite..."
        docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -f /docker-entrypoint-initdb.d/03_review2_queries.sql
        ;;
    psql)
        echo "Opening interactive PostgreSQL shell..."
        docker exec -it "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME"
        ;;
    reset)
        echo "Resetting database..."
        docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -f /docker-entrypoint-initdb.d/01_schema.sql
        docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -f /docker-entrypoint-initdb.d/02_seed_data.sql
        echo "Database reset and re-seeded successfully!"
        ;;
    *)
        show_help
        ;;
esac
