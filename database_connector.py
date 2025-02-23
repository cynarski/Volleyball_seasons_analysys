import pymysql

class DatabaseConnector:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(DatabaseConnector, cls).__new__(cls)
            cls._instance.conn = pymysql.connect(
                user='user',
                password='password',
                database='volleyball_app',
                host='localhost',
                port=3307)
        return cls._instance

    def get_connection(self):
        return self.conn