DROP PROCEDURE IF EXISTS Update_match_type();

CREATE OR REPLACE PROCEDURE Update_match_type()
LANGUAGE plpgsql
AS $$
BEGIN

    UPDATE Matches SET match_type = 'play-off';

    WITH MatchPairs AS (
        SELECT
            LEAST(team_1, team_2) AS team_a,
            GREATEST(team_1, team_2) AS team_b,
            season,
            id,
            date,
            ROW_NUMBER() OVER (PARTITION BY LEAST(team_1, team_2), GREATEST(team_1, team_2), season ORDER BY date) AS match_number
        FROM Matches
    )
    UPDATE Matches m
    SET match_type = 'league'
    FROM MatchPairs mp
    WHERE m.id = mp.id AND mp.match_number <= 2;
END;
$$
