#!/bin/bash

mysql -u user -ppassword < /docker-entrypoint-initdb.d/create_database.sql
mysql -u user -ppassword < /docker-entrypoint-initdb.d/insert_data.sql
mysql -u user -ppassword < /docker-entrypoint-initdb.d/Teams_in_single_season.sql
mysql -u user -ppassword < /docker-entrypoint-initdb.d/Update_points.sql

