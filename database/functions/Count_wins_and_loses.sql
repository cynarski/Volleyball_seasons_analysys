DROP FUNCTION IF EXISTS count_home_and_away_stats(VARCHAR, VARCHAR, VARCHAR, INTEGER[]);

CREATE OR REPLACE FUNCTION count_home_and_away_stats(
    p_team VARCHAR,
    p_season VARCHAR,
    p_match_type VARCHAR,
    p_sets_sum INTEGER[]
)
RETURNS TABLE(wins_home BIGINT, losses_home BIGINT, wins_away BIGINT, losses_away BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) FILTER (WHERE (team_1 = p_team AND T1_score > T2_score)) AS wins_home,
        COUNT(*) FILTER (WHERE (team_1 = p_team AND T1_score < T2_score)) AS losses_home,
        COUNT(*) FILTER (WHERE (team_2 = p_team AND T1_score < T2_score)) AS wins_away,
        COUNT(*) FILTER (WHERE (team_2 = p_team AND T1_score > T2_score)) AS losses_away
    FROM teams_matches_in_season
    WHERE season = p_season
      AND (team_1 = p_team OR team_2 = p_team)
      AND match_type = p_match_type
      AND (COALESCE(T1_score,0) + COALESCE(T2_score,0)) = ANY(p_sets_sum);
END;
$$ LANGUAGE plpgsql;