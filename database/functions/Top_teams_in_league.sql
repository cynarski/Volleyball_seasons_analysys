DROP FUNCTION top_teams_in_league(VARCHAR, INT);
CREATE OR REPLACE FUNCTION top_teams_in_league(p_season VARCHAR, p_limit INT DEFAULT 8)
RETURNS TABLE(place BIGINT, team_name VARCHAR, total_points BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT ranked.rank AS place, ranked.team AS team_name, ranked.total_points
    FROM (
        SELECT 
            ROW_NUMBER() OVER (ORDER BY SUM(points) DESC, team) AS rank,
            team,
            SUM(points) AS total_points
        FROM (
            SELECT team_1 AS team, T1_points AS points
            FROM Teams_matches_in_season
            WHERE season = p_season AND match_type = 'league'
            UNION ALL
            SELECT team_2 AS team, T2_points AS points
            FROM Teams_matches_in_season
            WHERE season = p_season AND match_type = 'league'
        ) AS all_points
        GROUP BY team
    ) ranked
    ORDER BY ranked.rank
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;