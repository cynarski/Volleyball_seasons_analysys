from typing import List, Dict, Tuple

from database_connector import DatabaseConnector

db = DatabaseConnector()


def get_teams_name() -> List[Dict[str, str]]:
    query = "SELECT TeamName FROM Team ORDER BY TeamName;"

    conn = db.get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute(query)
            return [{'label': row[0], 'value': row[0]} for row in cursor.fetchall()]
    finally:
        db.release_connection(conn)


def get_seasons() -> List[str]:
    query = "SELECT season FROM Season ORDER BY season;"
    conn = db.get_connection()

    try:
        with conn.cursor() as cursor:
            cursor.execute(query)
            return [row[0] for row in cursor.fetchall()]
    finally:
        db.release_connection(conn)


def check_team_in_season(team: str, season: str) -> List[Tuple]:
    query = "SELECT * FROM teams_in_single_season WHERE TeamName = %s AND season = %s;"

    conn = db.get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, (team, season))
            return cursor.fetchall()
    finally:
        db.release_connection(conn)


def get_matches_for_team_and_season(team: str, season: str, match_id=False, date=False, match_type:str = 'league') -> List[Tuple]:
    fields = []
    if match_id:
        fields.append("id")
    if date:
        fields.append("date")
    fields.extend(["team_1", "team_2", "T1_score", "T2_score"])

    query = f"""
         SELECT {", ".join(fields)}
         FROM Teams_matches_in_season
         WHERE (team_1 = %s OR team_2 = %s) 
             AND season = %s 
             AND match_type = '{match_type}'
         ORDER BY date;
     """

    conn = db.get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, (team, team, season))
            return cursor.fetchall()
    finally:
        db.release_connection(conn)


def get_wins_and_losses(team: str, season: str) -> Tuple:
    query = "SELECT * FROM count_wins_and_losses(%s, %s);"

    conn = db.get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, (team, season))
            return cursor.fetchone()
    finally:
        db.release_connection(conn)


def get_sets_scores(match_id: int) -> List[Tuple[int, int]]:
    query = "SELECT host_score, guest_score FROM set_scores WHERE match_id = %s;"

    conn = db.get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, (match_id,))
            return cursor.fetchall()
    finally:
        db.release_connection(conn)


def get_home_and_away_stats(team: str, season: str, match_type: str) -> Tuple:
    query = "SELECT * FROM count_home_and_away_stats(%s, %s, %s);"

    conn = db.get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, (team, season, match_type))
            result = cursor.fetchone()
            return result
    finally:
        db.release_connection(conn)


def get_season_table(season: str) -> List[Tuple[int, str, int]]:
    query = """
         SELECT 
             t.TeamName,
             COALESCE(cp.points, 0) AS total_points
         FROM Teams_in_single_season t
         LEFT JOIN LATERAL Count_points(t.TeamName, t.season) AS cp ON true
         WHERE season = %s
         ORDER BY total_points DESC;
     """

    conn = db.get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, (season,))
            result = cursor.fetchall()

            ranked_result = [(i + 1, team, points) for i, (team, points) in enumerate(result)]
            return ranked_result
    finally:
        db.release_connection(conn)


def get_team_sets_stats(team: str, season: str) -> Tuple:
    query = "SELECT * FROM get_team_sets_stats(%s, %s);"

    conn = db.get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, (team, season))
            result = cursor.fetchone()
            return result
    finally:
        db.release_connection(conn)


def get_matches_results(team: str, season: str) -> Tuple:
    query = "SELECT * FROM get_matches_results(%s, %s);"

    conn = db.get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, (team, season))
            result = cursor.fetchone()
            return result
    finally:
        db.release_connection(conn)


def get_match_details(match_id: int) -> Dict[str, any]:
    query = f'''
        SELECT * FROM Match_statistics WHERE id = {match_id};
    '''
    conn = db.get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute(query)
            row = cursor.fetchone()
            keys = ['id','team1','team2',
                    't1_ace','t1_srv_err','t2_ace','t2_srv_err',
                    't1_rec_pos', 't1_rec_perf', 't2_rec_pos', 't2_rec_perf',
                    't1_att_err', 't1_att_perc', 't2_att_err', 't2_att_perc',
                    't1_blocks', 't2_blocks']


            print(dict(zip(keys, row)))
            return dict(zip(keys, row))
    finally:
        db.release_connection(conn)