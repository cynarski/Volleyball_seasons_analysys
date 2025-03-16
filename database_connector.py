import psycopg2
from psycopg2 import pool

class DatabaseConnector:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(DatabaseConnector, cls).__new__(cls)
            cls._instance._connect()
        return cls._instance

    def _connect(self):
        try:
            self.connection_pool = psycopg2.pool.SimpleConnectionPool(
                minconn=1,
                maxconn=50,
                user='user',
                password='password',
                database='volleyball_app',
                host='localhost',
                port=1234,
            )
            print("Connected to database with connection pool")
        except Exception as e:
            print(f"Error with database connection: {e}")
            self.connection_pool = None

    def get_connection(self):
        if self.connection_pool is None:
            self._connect()
        return self.connection_pool.getconn()

    def release_connection(self, conn):
        if self.connection_pool and conn:
            self.connection_pool.putconn(conn)

    def close_pool(self):
        if self.connection_pool:
            self.connection_pool.closeall()
