FROM postgres:latest

COPY create_database.sql /docker-entrypoint-initdb.d/
COPY procedures/Update_points.sql /docker-entrypoint-initdb.d/
COPY procedures/Update_match_type.sql /docker-entrypoint-initdb.d/
COPY functions/Count_home_and_away_stats.sql /docker-entrypoint-initdb.d/
COPY functions/Count_wins_and_loses.sql /docker-entrypoint-initdb.d/
COPY functions/Count_points.sql /docker-entrypoint-initdb.d/
COPY functions/Get_teams_sets_stats.sql /docker-entrypoint-initdb.d/
COPY functions/Get_matches_results.sql /docker-entrypoint-initdb.d/
COPY views/Teams_in_single_season.sql /docker-entrypoint-initdb.d/
COPY views/Teams_matches_in_season.sql /docker-entrypoint-initdb.d/
COPY views/Match_statistic.sql /docker-entrypoint-initdb.d/

COPY insert_data.sql /docker-entrypoint-initdb.d/

COPY load_data.sh /docker-entrypoint-initdb.d/

RUN chmod +x /docker-entrypoint-initdb.d/load_data.sh

COPY init.sh /docker-entrypoint-initdb.d/
RUN chmod +x /docker-entrypoint-initdb.d/init.sh

EXPOSE 5432
