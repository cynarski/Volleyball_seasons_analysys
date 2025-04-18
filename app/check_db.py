import psycopg2
from psycopg2 import sql
import subprocess
from database_connector import DatabaseConnector
from logger import Logger


class DatabaseChecker:

    def __init__(self):
        self.logger = Logger.get_logger()
        self.db_connector = DatabaseConnector()
        self.conn = self.db_connector.get_connection()
        self.tables = ['team', 'season', 'teams_in_season', 'matches', 'match_details', 'matches_extended',
                       'set_scores']
        self.functions = ['Count_home_and_away_stats', 'Count_points', 'Count_wins_and_loses', 'Get_matches_results', 'Get_team_sets_stats']
        self.views = ['Teams_in_single_season', 'Teams_matches_in_season']
        self.procedures = ['Update_match_type', 'Update_points']

    def check_tables(self):
        cursor = self.conn.cursor()
        cursor.execute("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';")
        existing_tables = {row[0] for row in cursor.fetchall()}

        missing_tables = [table for table in self.tables if table not in existing_tables]

        if missing_tables:
            self.logger.warning(f"Missing tables: {missing_tables}")
            self.execute_sql_file("../database/create_database.sql")
        else:
            self.check_data_in_tables()

    def check_data_in_tables(self):
        cursor = self.conn.cursor()
        for table in self.tables:
            cursor.execute(sql.SQL("SELECT COUNT(*) FROM {}").format(sql.Identifier(table)))
            count = cursor.fetchone()[0]
            if count == 0:
                self.logger.warning(f"Table {table} is empty. Executing insert_data.sql.")
                self.execute_sql_file("insert_data.sql")
            else:
                self.logger.info(f"Table {table} contains {count} rows.")

    def check_functions(self):
        cursor = self.conn.cursor()
        cursor.execute(
            """SELECT routine_name 
                FROM information_schema.routines 
                WHERE routine_type = 'FUNCTION'
                AND specific_schema = 'public';
                """)
        existing_functions = {row[0] for row in cursor.fetchall()}
        for function in self.functions:
            if function not in existing_functions:
                self.logger.warning(f"Missing function: {function}, executing SQL file...")
                self.execute_sql_file(f"{function}.sql")
            else:
                self.logger.info(f"Function {function} exists.")

    def check_views(self):
        cursor = self.conn.cursor()
        cursor.execute("SELECT table_name FROM information_schema.views WHERE table_schema = 'public';")
        existing_views = {row[0] for row in cursor.fetchall()}

        for view in self.views:
            if view not in existing_views:
                self.logger.warning(f"Missing view: {view}, executing SQL file...")
                self.execute_sql_file(f"{view}.sql")
            else:
                self.logger.info(f"View {view} exists.")

    def check_procedures(self):
        cursor = self.conn.cursor()
        cursor.execute(
            """SELECT routine_name 
                FROM information_schema.routines 
                WHERE routine_type = 'PROCEDURE'
                AND specific_schema = 'public';
                """)
        existing_procedures = {row[0] for row in cursor.fetchall()}

        for procedure in self.procedures:
            if procedure not in existing_procedures:
                self.logger.warning(f"Missing procedure: {procedure}, executing SQL file...")
                self.execute_sql_file(f"{procedure}.sql")
            else:
                self.logger.info(f"Procedure {procedure} exists.")

    def execute_sql_file(self, filename):
        file_path = f"/docker-entrypoint-initdb.d/{filename}"
        try:
            self.logger.info(f"Executing SQL file: {file_path}")
            result = subprocess.run(
                ['docker', 'exec', '-i', 'postgres', 'psql', '-U', 'user', '-d', 'volleyball_app', '-f', file_path],
                check=True, capture_output=True, text=True
            )

            if result.stdout:
                for line in result.stdout.strip().split("\n"):
                    self.logger.info(f"PostgreSQL: {line.strip()}")

            self.logger.info(f"SQL file {file_path} executed successfully.")

        except subprocess.CalledProcessError as e:
            self.logger.error(f"Error while executing {file_path}: {e.stderr.strip()}")

    def run_checks(self):
        self.logger.info("Starting database checks...")
        self.check_tables()
        self.check_functions()
        self.check_views()
        self.check_procedures()
        self.logger.info("Database checks completed.")


if __name__ == "__main__":
    db_checker = DatabaseChecker()
    db_checker.run_checks()
