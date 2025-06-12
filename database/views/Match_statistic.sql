DROP VIEW IF EXISTS Match_statistics;

CREATE VIEW Match_statistics AS
SELECT m.id,
    t1.teamname AS team1,
    t2.teamname AS team2,
    md.t1_srv_ace,
    md.t1_srv_err,
    md.t2_srv_ace,
    md.t2_srv_err,
    md.t1_rec_pos,
    md.t1_rec_perf,
    md.t2_rec_pos,
    md.t2_rec_perf,
    md.t1_att_err,
    md.t1_att_kill_perc,
    md.t2_att_err,
    md.t2_att_kill_perc,
    md.t1_blk_sum,
    md.t2_blk_sum
FROM (((match_details md
 JOIN matches m ON ((md.match_id = m.id)))
 JOIN team t1 ON ((m.team_1 = t1.id)))
 JOIN team t2 ON ((m.team_2 = t2.id)));