USE volleyball_app;

DROP VIEW IF EXISTS Teams_in_single_sason;

CREATE VIEW Teams_in_single_sason AS
SELECT
	t.TeamName,
    s.season
FROM Teams_in_season tis
JOIN Team t ON tis.team = t.id
JOIN Season s ON tis.season = s.id;