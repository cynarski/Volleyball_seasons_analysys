#!/bin/bash

export PGPASSWORD="password"

psql -U user -d mydb -f /docker-entrypoint-initdb.d/create_database.sql
psql -U user -d mydb -f /docker-entrypoint-initdb.d/insert_data.sql
psql -U user -d mydb -f /docker-entrypoint-initdb.d/Teams_in_single_season.sql
psql -U user -d mydb -f /docker-entrypoint-initdb.d/Teams_matches_in_season.sql
psql -U user -d mydb -f /docker-entrypoint-initdb.d/Update_points.sql
