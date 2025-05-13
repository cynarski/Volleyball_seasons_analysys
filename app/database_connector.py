import os
from psycopg2 import pool
from urllib.parse import urlparse, unquote

class DatabaseConnector:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(DatabaseConnector, cls).__new__(cls)
            cls._instance._connect()
        return cls._instance

    def _connect(self):
        url = os.getenv("DATABASE_URL")
        print(f">>> [DBG] Connecting to DB with: {url}")
        if not url:
            raise RuntimeError("DATABASE_URL is not set")

        parsed = urlparse(url)
        user = unquote(parsed.username)
        password = unquote(parsed.password)
        host = parsed.hostname
        port = parsed.port
        database = parsed.path.lstrip("/")

        try:
            self.connection_pool = pool.SimpleConnectionPool(
                minconn=1,
                maxconn=50,
                user=user,
                password=password,
                host=host,
                port=port,
                database=database
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

