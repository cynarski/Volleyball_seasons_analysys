from typing import List, Dict, Tuple

from database_connector import DatabaseConnector

db = DatabaseConnector()

def get_teams_name() -> List[Dict[str, str]]:
    conn = db.get_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT TeamName FROM Team ORDER BY TeamName;")
    teams = [{'label': row[0], 'value': row[0]} for row in cursor.fetchall()]
    cursor.close()
    return teams

def get_seasons() -> List:
    conn = db.get_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT season FROM Season;")
    seasons = [row[0] for row in cursor.fetchall()]
    cursor.close()
    return seasons

def check_team_in_season(team, season) -> Tuple:
    conn = db.get_connection()
    cursor = conn.cursor()

    cursor.execute(f"SELECT * FROM Teams_in_single_sason WHERE TeamName = '{team}' AND season = '{season}';")
    result = cursor.fetchall()
    return result