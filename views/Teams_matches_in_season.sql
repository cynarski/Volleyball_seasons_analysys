DROP VIEW IF EXISTS Teams_matches_in_season;

CREATE VIEW Teams_matches_in_season AS
SELECT
    m.date,
    m.id,
    s.season AS season,
    t.TeamName AS team_1,
    ti.TeamName AS team_2,
    m.T1_score,
    m.T2_score,
    m.T1_points,
    m.T2_points,
    m.winner,
    m.match_type
FROM Matches m
JOIN Season s ON m.season = s.id
JOIN Team t ON m.team_1 = t.id
JOIN Team ti ON m.team_2 = ti.id;
