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

    cursor.execute("SELECT season FROM Season ORDER BY season;")
    seasons = [row[0] for row in cursor.fetchall()]
    cursor.close()
    return seasons

def check_team_in_season(team, season) -> Tuple:
    conn = db.get_connection()
    cursor = conn.cursor()

    cursor.execute(f"SELECT * FROM teams_in_single_season WHERE TeamName = '{team}' AND season = '{season}';")

    result = cursor.fetchall()
    cursor.close()
    return result


def get_matches_for_team_and_season(team, season, match_id=False, date=False):
    conn = db.get_connection()
    cursor = conn.cursor()

    query = f"""SELECT {'id,' if match_id else '' } {'date,' if date else '' } team_1, team_2, T1_score, T2_score FROM Teams_matches_in_season
                WHERE (team_1 = '{team}' OR team_2 = '{team}') AND season = '{season}' AND match_type = 'league' ORDER BY date;"""


    cursor.execute(query)
    result = cursor.fetchall()

    cursor.close()
    return result


def get_wins_and_losses(team, season):
    conn = db.get_connection()
    cursor = conn.cursor()

    cursor.execute(f"""SELECT * FROM count_wins_and_losses('{team}', '{season}');""")
    result = cursor.fetchall()
    cursor.close()

    return result

def get_sets_scores(match_id):
    conn = db.get_connection()
    cursor = conn.cursor()

    cursor.execute(f"""SELECT host_score, guest_score FROM set_scores WHERE match_id = '{match_id}';""")
    result = cursor.fetchall()
    cursor.close()

    return result


def get_home_and_away_stats(team, season):
    conn = db.get_connection()
    cursor = conn.cursor()

    cursor.execute(f"""SELECT * FROM count_home_and_away_stats('{team}', '{season}');""")
    result = cursor.fetchall()
    cursor.close()

    return result[0]

def get_season_table(season):
    conn = db.get_connection()
    cursor = conn.cursor()

    cursor.execute(
        f"""
        SELECT 
            t.TeamName,
            COALESCE(cp.points, 0) AS total_points
        FROM Teams_in_single_season t
        LEFT JOIN LATERAL Count_points(t.TeamName, t.season) AS cp ON true
        WHERE season = '{season}'
        ORDER BY total_points DESC;
    """)
    result = cursor.fetchall()
    cursor.close()

    ranked_result = [(i + 1, team, points) for i, (team, points) in enumerate(result)]

    return ranked_result