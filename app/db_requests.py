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


def get_matches_for_team_and_season(
    team: str,
    season: str,
    match_id=False,
    date=False,
    match_type: str = 'league',
    sets_sum: List = [3, 4, 5]
) -> List[Tuple]:
    fields = []
    if match_id:
        fields.append("id")
    if date:
        fields.append("date")
    fields.extend(["team_1", "team_2", "T1_score", "T2_score"])

    # Przygotuj odpowiednią liczbę placeholderów dla sets_sum
    sets_placeholders = ','.join(['%s'] * len(sets_sum))

    query = f"""
         SELECT {", ".join(fields)}
         FROM Teams_matches_in_season
         WHERE (team_1 = %s OR team_2 = %s)
             AND season = %s
             AND match_type = %s
             AND COALESCE(t1_score,0) + COALESCE(t2_score,0) IN ({sets_placeholders})
         ORDER BY date;
     """

    params = [team, team, season, match_type] + sets_sum

    conn = db.get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, params)
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


def get_home_and_away_stats(team: str, season: str, match_type: str, sets_sum: List = [3,4,5]) -> Tuple:
    query = "SELECT * FROM count_home_and_away_stats(%s, %s, %s, %s);"

    conn = db.get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, (team, season, match_type, sets_sum))
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

            return dict(zip(keys, row))
    finally:
        db.release_connection(conn)

def get_top_teams_in_league(season: str, limit: int = 8):
    query = "SELECT place, team_name, total_points FROM top_teams_in_league(%s, %s);"
    conn = db.get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, (season, limit))
            result = cursor.fetchall()
            print("DEBUG top_teams_in_league:", result)  # <--- dodaj to
            return result
    finally:
        db.release_connection(conn)

def get_playoff_matches_simple(season):
    query = """
        SELECT t1.TeamName, t2.TeamName, m.t1_score, m.t2_score
        FROM matches m
        JOIN season s ON m.season = s.id
        JOIN team t1 ON m.team_1 = t1.id
        JOIN team t2 ON m.team_2 = t2.id
        WHERE m.match_type = 'play-off' AND s.season = %s
        ORDER BY m.id;
    """
    conn = db.get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, (season,))
            return cursor.fetchall()
    finally:
        db.release_connection(conn)