CREATE OR REPLACE FUNCTION Count_points(p_team VARCHAR, p_season VARCHAR)
RETURNS TABLE(points BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT
        SUM(
            CASE
                WHEN team_1 = p_team THEN t1_points
                WHEN team_2 = p_team THEN t2_points
                ELSE 0
            END
        )
    FROM teams_matches_in_season
    WHERE season = p_season
    AND (team_1 = p_team OR team_2 = p_team)
    AND match_type = 'league';
END;
$$ LANGUAGE plpgsql;