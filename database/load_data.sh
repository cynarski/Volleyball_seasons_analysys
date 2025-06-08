#!/bin/bash

export PGPASSWORD="password"

psql -U user -d volleyball_app -f /docker-entrypoint-initdb.d/create_database.sql
psql -U user -d volleyball_app -f /docker-entrypoint-initdb.d/Teams_in_single_season.sql
psql -U user -d volleyball_app -f /docker-entrypoint-initdb.d/Teams_matches_in_season.sql
psql -U user -d volleyball_app -f /docker-entrypoint-initdb.d/Match_statistics.sql
psql -U user -d volleyball_app -f /docker-entrypoint-initdb.d/Update_points.sql
psql -U user -d volleyball_app -f /docker-entrypoint-initdb.d/Update_match_type.sql
psql -U user -d volleyball_app -f /docker-entrypoint-initdb.d/Count_home_and_away_stats.sql
psql -U user -d volleyball_app -f /docker-entrypoint-initdb.d/Count_wins_and_loses.sql
psql -U user -d volleyball_app -f /docker-entrypoint-initdb.d/Top_teams_in_league.sql
psql -U user -d volleyball_app -f /docker-entrypoint-initdb.d/Get_teams_sets_stats.sql
psql -U user -d volleyball_app -f /docker-entrypoint-initdb.d/Get_matches_results.sql
psql -U user -d volleyball_app -f /docker-entrypoint-initdb.d/Count_points.sql
psql -U user -d volleyball_app -f /docker-entrypoint-initdb.d/insert_data.sql

