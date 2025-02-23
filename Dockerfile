FROM mysql:latest

COPY create_database.sql /docker-entrypoint-initdb.d/
COPY insert_data.sql /docker-entrypoint-initdb.d/
COPY /procedures/Update_points.sql /docker-entrypoint-initdb.d/
COPY /views/Teams_in_single_season.sql /docker-entrypoint-initdb.d/

COPY load_data.sh /docker-entrypoint-initdb.d/

RUN chmod +x /docker-entrypoint-initdb.d/load_data.sh


