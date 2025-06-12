CREATE OR REPLACE FUNCTION count_home_and_away_stats(
    p_team character varying,
    p_season character varying,
    p_match_type character varying,
    p_sets_sum integer[],
    p_location character varying DEFAULT 'All'::character varying
)
RETURNS TABLE(wins_home bigint, losses_home bigint, wins_away bigint, losses_away bigint)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) FILTER (WHERE (team_1 = p_team AND T1_score > T2_score)) AS wins_home,
        COUNT(*) FILTER (WHERE (team_1 = p_team AND T1_score < T2_score)) AS losses_home,
        COUNT(*) FILTER (WHERE (team_2 = p_team AND T1_score < T2_score)) AS wins_away,
        COUNT(*) FILTER (WHERE (team_2 = p_team AND T1_score > T2_score)) AS losses_away
    FROM teams_matches_in_season
    WHERE season = p_season
      AND match_type = p_match_type
      AND (COALESCE(T1_score,0) + COALESCE(T2_score,0)) = ANY(p_sets_sum)
      AND (
            p_location = 'All'
            OR (p_location = 'Home' AND team_1 = p_team)
            OR (p_location = 'Away' AND team_2 = p_team)
          );
END;
$$;