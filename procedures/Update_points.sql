DROP PROCEDURE IF EXISTS Update_points();

CREATE PROCEDURE Update_points() 
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE Matches
    SET
        T1_points = CASE
            WHEN T1_score > T2_score AND T1_score - T2_score != 1 THEN 3
            WHEN T1_score > T2_score AND T1_score - T2_score = 1 THEN 2
            WHEN T1_score < T2_score AND T2_score - T1_score = 1 THEN 1
            WHEN T1_score < T2_score AND T2_score - T1_score != 1 THEN 0
            ELSE T1_points
        END,
        T2_points = CASE
            WHEN T1_score > T2_score AND T1_score - T2_score != 1 THEN 0
            WHEN T1_score > T2_score AND T1_score - T2_score = 1 THEN 1
            WHEN T1_score < T2_score AND T2_score - T1_score = 1 THEN 2
            WHEN T1_score < T2_score AND T2_score - T1_score != 1 THEN 3
            ELSE T2_points
        END
    WHERE T1_points IS NULL OR T2_points IS NULL;
END;
$$;