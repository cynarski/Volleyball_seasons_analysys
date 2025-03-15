import psycopg2
from psycopg2 import sql
import subprocess
from database_connector import DatabaseConnector


class DatabaseChecker:

    def __init__(self):
        self.db_connector = DatabaseConnector()
        self.conn = self.db_connector.get_connection()

    def check_tables(self):
        tables_to_check = ['Team', 'season']

        cursor = self.conn.cursor()
        cursor.execute("""
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'public';
        """)
        existing_tables = {row[0] for row in cursor.fetchall()}

        missing_tables = [table for table in tables_to_check if table not in existing_tables]

        if missing_tables:
            print(f"Missing tables: {missing_tables}")
            self.run_init_script()
        else:
            self.check_data_in_tables()

    def check_data_in_tables(self):
        cursor = self.conn.cursor()
        for table in ['Team', 'season']:
            cursor.execute(sql.SQL("SELECT COUNT(*) FROM {}").format(sql.Identifier(table)))
            count = cursor.fetchone()[0]
            if count == 0:
                print(f"Table {table} is empty.")
            else:
                print(f"Table {table} contains {count} rows.")

    def run_init_script(self):
        try:
            print("Running init.sh script to create tables...")
            subprocess.run(['docker', 'exec', '-it', 'postgres', '/bin/bash', '/docker-entrypoint-initdb.d/init.sh'],
                           check=True)
            print("Init script executed successfully.")
        except subprocess.CalledProcessError as e:
            print(f"Error while running init.sh: {e}")


if __name__ == "__main__":
    db_checker = DatabaseChecker()
    db_checker.check_tables()
