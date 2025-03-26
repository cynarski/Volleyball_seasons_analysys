CREATE OR REPLACE FUNCTION get_matches_results(selected_team TEXT, selected_season TEXT)
RETURNS TABLE (wins INT, losses INT) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        CAST(COUNT(CASE
                  WHEN (team_1 = selected_team AND winner = 0)
                       OR (team_2 = selected_team AND winner = 1)
                  THEN 1
                  ELSE NULL
              END) AS INTEGER) AS wins,
        CAST(COUNT(CASE
                  WHEN (team_1 = selected_team AND winner = 1)
                       OR (team_2 = selected_team AND winner = 0)
                  THEN 1
                  ELSE NULL
              END) AS INTEGER) AS losses
    FROM teams_matches_in_season
    WHERE (team_1 = selected_team OR team_2 = selected_team)
    AND season = selected_season
    AND match_type = 'league';
END;
$$ LANGUAGE plpgsql;
