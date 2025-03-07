#!/bin/bash

export PGPASSWORD="password"

psql -U user -d volleyball_app -f /docker-entrypoint-initdb.d/create_database.sql
psql -U user -d volleyball_app -f /docker-entrypoint-initdb.d/Teams_in_single_season.sql
psql -U user -d volleyball_app -f /docker-entrypoint-initdb.d/Teams_matches_in_season.sql
psql -U user -d volleyball_app -f /docker-entrypoint-initdb.d/Update_points.sql
psql -U user -d volleyball_app -f /docker-entrypoint-initdb.d/Count_home_and_away_stats.sql
psql -U user -d volleyball_app -f /docker-entrypoint-initdb.d/Count_wins_and_loses.sql
psql -U user -d volleyball_app -f /docker-entrypoint-initdb.d/insert_data.sql

