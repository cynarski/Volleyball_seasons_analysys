import psycopg2

class DatabaseConnector:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(DatabaseConnector, cls).__new__(cls)
            cls._instance._connect()
        return cls._instance

    def _connect(self):
        try:
            self.conn = psycopg2.connect(
                user='user',
                password='password',
                database='volleyball_app',
                host='localhost',
                port=1234,
            )
            print("Connected to database")
        except Exception as e:
            print(f"Error with database connection: {e}")
            self.conn = None

    def get_connection(self):
        try:
            if self.conn is None or self.conn.closed != 0:
                self._connect()
            return self.conn
        except Exception as e:
            print(f"Error with reconnecting: {e}")
            return None