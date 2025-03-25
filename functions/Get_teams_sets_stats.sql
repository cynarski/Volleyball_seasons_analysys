CREATE OR REPLACE FUNCTION get_team_sets_stats(selected_team TEXT, selected_season TEXT)
RETURNS TABLE (team_name TEXT, total_sets_won INT, total_sets_lost INT, ratio NUMERIC(10,2)) AS $$
BEGIN
    RETURN QUERY
    SELECT
        team_sets.team::TEXT AS team_name,
        SUM(team_sets.sets_won)::INT AS total_sets_won,
        SUM(team_sets.sets_lost)::INT AS total_sets_lost,
        ROUND(SUM(team_sets.sets_won)::NUMERIC / NULLIF(SUM(team_sets.sets_lost), 0), 2) AS ratio
    FROM (
        SELECT
            team_1::TEXT AS team,
            T1_score AS sets_won,
            T2_score AS sets_lost
        FROM Teams_matches_in_season
        WHERE team_1 = selected_team
          AND season = selected_season
          AND match_type = 'league'

        UNION ALL

        SELECT
            team_2::TEXT AS team,
            T2_score AS sets_won,
            T1_score AS sets_lost
        FROM Teams_matches_in_season
        WHERE team_2 = selected_team
          AND season = selected_season
          AND match_type = 'league'
    ) AS team_sets
    GROUP BY team_sets.team;
END;
$$ LANGUAGE plpgsql;
