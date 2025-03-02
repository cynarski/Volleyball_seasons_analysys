CREATE OR REPLACE FUNCTION count_wins_and_losses(p_team VARCHAR, p_season VARCHAR)
RETURNS TABLE(wins BIGINT, losses BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) FILTER (WHERE (team_1 = p_team AND T1_score > T2_score) OR
                                (team_2 = p_team AND T2_score > T1_score)) AS wins,
        COUNT(*) FILTER (WHERE (team_1 = p_team AND T1_score < T2_score) OR
                                (team_2 = p_team AND T2_score < T1_score)) AS losses
    FROM teams_matches_in_season
    WHERE season = p_season AND (team_1 = p_team OR team_2 = p_team);
END;
$$ LANGUAGE plpgsql;