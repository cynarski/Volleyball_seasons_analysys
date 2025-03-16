import logging

class Logger:

    _instance = None

    @staticmethod
    def get_logger():
        if Logger._instance is None:
            Logger._instance = logging.getLogger("DatabaseChecker")
            Logger._instance.setLevel(logging.INFO)

            formatter = logging.Formatter("%(asctime)s - %(levelname)s - %(message)s", datefmt="%Y-%m-%d %H:%M:%S")

            file_handler = logging.FileHandler("database_checker.log")
            file_handler.setFormatter(formatter)

            console_handler = logging.StreamHandler()
            console_handler.setFormatter(formatter)

            Logger._instance.addHandler(file_handler)
            Logger._instance.addHandler(console_handler)

        return Logger._instance