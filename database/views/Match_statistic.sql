DROP VIEW IF EXISTS Match_statistics;

CREATE VIEW Match_statistics AS
SELECT
	m.id,
	t1.TeamName AS team1,
	t2.TeamName AS team2,
	md.T1_Srv_Ace,
	md.T1_Srv_Err,
	md.T2_Srv_Ace,
	md.T2_Srv_Err,

	md.T1_Rec_pos,
	md.T1_Rec_perf,

	md.T2_Rec_pos,
	md.T2_Rec_perf,

	md.T1_att_err,
	md.T1_att_kill_perc,
	md.T2_att_err,
	md.T2_att_kill_perc,

	md.T1_Blk_Sum,
	md.T2_Blk_Sum

FROM Match_details md
JOIN Matches m ON md.match_id = m.id
JOIN Team t1 ON m.team_1 = t1.id
JOIN Team t2 ON m.team_2 = t2.id;