from typing import List, Dict, Tuple, Optional
from database_connector import DatabaseConnector

class DbRequests:
    def __init__(self):
        self.db = DatabaseConnector()

    def _fetchall(self, query: str, params: Optional[tuple] = None):
        conn = self.db.get_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute(query, params or ())
                return cursor.fetchall()
        finally:
            self.db.release_connection(conn)

    def _fetchone(self, query: str, params: Optional[tuple] = None):
        conn = self.db.get_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute(query, params or ())
                return cursor.fetchone()
        finally:
            self.db.release_connection(conn)

    def get_teams_name(self) -> List[Dict[str, str]]:
        query = "SELECT TeamName FROM Team ORDER BY TeamName;"
        return [{'label': row[0], 'value': row[0]} for row in self._fetchall(query)]

    def get_seasons(self) -> List[str]:
        query = "SELECT season FROM Season ORDER BY season;"
        return [row[0] for row in self._fetchall(query)]

    def check_team_in_season(self, team: str, season: str) -> List[Tuple]:
        query = "SELECT * FROM teams_in_single_season WHERE TeamName = %s AND season = %s;"
        return self._fetchall(query, (team, season))

    def get_matches_for_team_and_season(
        self,
        team: str,
        season: str,
        location: str = 'All',
        match_id=False,
        date=False,
        match_type: str = 'league',
        sets_sum: Optional[List[int]] = None
    ) -> List[Tuple]:
        if sets_sum is None:
            sets_sum = [3, 4, 5]
        fields = []
        if match_id:
            fields.append("id")
        if date:
            fields.append("date")
        fields.extend(["team_1", "team_2", "T1_score", "T2_score"])
        sets_placeholders = ','.join(['%s'] * len(sets_sum))

        if location == 'Home':
            where_clause = "team_1 = %s"
            params = [team]
        elif location == 'Away':
            where_clause = "team_2 = %s"
            params = [team]
        else:
            where_clause = "(team_1 = %s OR team_2 = %s)"
            params = [team, team]

        params += [season, match_type] + sets_sum

        query = f"""
            SELECT {", ".join(fields)}
            FROM Teams_matches_in_season
            WHERE {where_clause}
                AND season = %s
                AND match_type = %s
                AND COALESCE(t1_score,0) + COALESCE(t2_score,0) IN ({sets_placeholders})
            ORDER BY date;
        """
        return self._fetchall(query, params)

    def get_wins_and_losses(self, team: str, season: str) -> Tuple:
        query = "SELECT * FROM count_wins_and_losses(%s, %s);"
        return self._fetchone(query, (team, season))

    def get_sets_scores(self, match_id: int) -> List[Tuple[int, int]]:
        query = "SELECT host_score, guest_score FROM set_scores WHERE match_id = %s;"
        return self._fetchall(query, (match_id,))

    def get_home_and_away_stats(self, team: str, season: str, match_type: str, sets_sum: Optional[List[int]] = None, location: str = 'All') -> Tuple:
        if sets_sum is None:
            sets_sum = [3, 4, 5]
        query = "SELECT * FROM count_home_and_away_stats(%s, %s, %s, %s, %s);"
        return self._fetchone(query, (team, season, match_type, sets_sum, location))

    def get_season_table(self, season: str) -> List[Tuple[int, str, int]]:
        query = """
             SELECT 
                 t.TeamName,
                 COALESCE(cp.points, 0) AS total_points
             FROM Teams_in_single_season t
             LEFT JOIN LATERAL Count_points(t.TeamName, t.season) AS cp ON true
             WHERE season = %s
             ORDER BY total_points DESC;
         """
        result = self._fetchall(query, (season,))
        ranked_result = [(i + 1, team, points) for i, (team, points) in enumerate(result)]
        return ranked_result

    def get_team_sets_stats(self, team: str, season: str) -> Tuple:
        query = "SELECT * FROM get_team_sets_stats(%s, %s);"
        return self._fetchone(query, (team, season))

    def get_matches_results(self, team: str, season: str) -> Tuple:
        query = "SELECT * FROM get_matches_results(%s, %s);"
        return self._fetchone(query, (team, season))

    def get_match_details(self, match_id: int) -> Dict[str, any]:
        query = f'''
            SELECT * FROM Match_statistics WHERE id = {match_id};
        '''
        row = self._fetchone(query)
        keys = ['id','team1','team2',
                't1_ace','t1_srv_err','t2_ace','t2_srv_err',
                't1_rec_pos', 't1_rec_perf', 't2_rec_pos', 't2_rec_perf',
                't1_att_err', 't1_att_perc', 't2_att_err', 't2_att_perc',
                't1_blocks', 't2_blocks']
        return dict(zip(keys, row)) if row else {}

    def get_top_teams_in_league(self, season: str, limit: int = 8):
        # query = "SELECT place, team_name, total_points FROM top_teams_in_league(%s, %s);"
        query = """
             SELECT 
                 t.TeamName,
                 COALESCE(cp.points, 0) AS total_points
             FROM Teams_in_single_season t
             LEFT JOIN LATERAL Count_points(t.TeamName, t.season) AS cp ON true
             WHERE season = %s
             ORDER BY total_points DESC
             LIMIT %s;
         """
        result = self._fetchall(query, (season,limit))
        ranked_result = [(i + 1, team, points) for i, (team, points) in enumerate(result)]

        return ranked_result

    def get_playoff_matches_simple(self, season):
        query = """
            SELECT t1.TeamName, t2.TeamName, m.t1_score, m.t2_score
            FROM matches m
            JOIN season s ON m.season = s.id
            JOIN team t1 ON m.team_1 = t1.id
            JOIN team t2 ON m.team_2 = t2.id
            WHERE m.match_type = 'play-off' AND s.season = %s
            ORDER BY m.id;
        """
        return self._fetchall(query, (season,))

db_requests = DbRequests()