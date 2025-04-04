--
-- PostgreSQL database dump
--

-- Dumped from database version 17.4 (Debian 17.4-1.pgdg120+2)
-- Dumped by pg_dump version 17.4 (Debian 17.4-1.pgdg120+2)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: count_home_and_away_stats(character varying, character varying); Type: FUNCTION; Schema: public; Owner: user
--

CREATE FUNCTION public.count_home_and_away_stats(p_team character varying, p_season character varying) RETURNS TABLE(wins_home bigint, losses_home bigint, wins_away bigint, losses_away bigint)
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
    WHERE season = p_season AND (team_1 = p_team OR team_2 = p_team) AND match_type = 'league';
END;
$$;


ALTER FUNCTION public.count_home_and_away_stats(p_team character varying, p_season character varying) OWNER TO "user";

--
-- Name: count_points(character varying, character varying); Type: FUNCTION; Schema: public; Owner: user
--

CREATE FUNCTION public.count_points(p_team character varying, p_season character varying) RETURNS TABLE(points bigint)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        SUM(
            CASE
                WHEN team_1 = p_team THEN t1_points
                WHEN team_2 = p_team THEN t2_points
                ELSE 0
            END
        )
    FROM teams_matches_in_season
    WHERE season = p_season
    AND (team_1 = p_team OR team_2 = p_team)
    AND match_type = 'league';
END;
$$;


ALTER FUNCTION public.count_points(p_team character varying, p_season character varying) OWNER TO "user";

--
-- Name: count_wins_and_losses(character varying, character varying); Type: FUNCTION; Schema: public; Owner: user
--

CREATE FUNCTION public.count_wins_and_losses(p_team character varying, p_season character varying) RETURNS TABLE(wins bigint, losses bigint)
    LANGUAGE plpgsql
    AS $$

BEGIN

    RETURN QUERY

    SELECT

        COUNT(*) FILTER (WHERE (team_1 = p_team AND T1_score > T2_score) OR

                                (team_2 = p_team AND T2_score > T1_score)) AS wins,

        COUNT(*) FILTER (WHERE (team_1 = p_team AND T1_score < T2_score) OR

                                (team_2 = p_team AND T2_score < T1_score)) AS losses

    FROM teams_matches_in_season

    WHERE season = p_season AND (team_1 = p_team OR team_2 = p_team);

END;

$$;


ALTER FUNCTION public.count_wins_and_losses(p_team character varying, p_season character varying) OWNER TO "user";

--
-- Name: update_match_type(); Type: PROCEDURE; Schema: public; Owner: user
--

CREATE PROCEDURE public.update_match_type()
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
$$;


ALTER PROCEDURE public.update_match_type() OWNER TO "user";

--
-- Name: update_points(); Type: PROCEDURE; Schema: public; Owner: user
--

CREATE PROCEDURE public.update_points()
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


ALTER PROCEDURE public.update_points() OWNER TO "user";

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: match_details; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.match_details (
    id integer NOT NULL,
    match_id integer NOT NULL,
    t1_sum double precision,
    t1_bp double precision,
    t1_ratio double precision,
    t1_srv_sum double precision,
    t1_srv_err double precision,
    t1_srv_ace double precision,
    t1_srv_eff double precision,
    t1_rec_sum double precision,
    t1_rec_err double precision,
    t1_rec_pos double precision,
    t1_rec_perf double precision,
    t1_att_sum double precision,
    t1_att_err double precision,
    t1_att_blk double precision,
    t1_att_kill double precision,
    t1_att_kill_perc double precision,
    t1_att_eff double precision,
    t1_blk_sum double precision,
    t1_blk_as double precision,
    t2_sum double precision,
    t2_bp double precision,
    t2_ratio double precision,
    t2_srv_sum double precision,
    t2_srv_err double precision,
    t2_srv_ace double precision,
    t2_srv_eff double precision,
    t2_rec_sum double precision,
    t2_rec_err double precision,
    t2_rec_pos double precision,
    t2_rec_perf double precision,
    t2_att_sum double precision,
    t2_att_err double precision,
    t2_att_blk double precision,
    t2_att_kill double precision,
    t2_att_kill_perc double precision,
    t2_att_eff double precision,
    t2_blk_sum double precision,
    t2_blk_as double precision
);


ALTER TABLE public.match_details OWNER TO "user";

--
-- Name: match_details_id_seq; Type: SEQUENCE; Schema: public; Owner: user
--

CREATE SEQUENCE public.match_details_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.match_details_id_seq OWNER TO "user";

--
-- Name: match_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user
--

ALTER SEQUENCE public.match_details_id_seq OWNED BY public.match_details.id;


--
-- Name: matches; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.matches (
    id integer NOT NULL,
    date timestamp without time zone,
    season integer,
    team_1 integer,
    team_2 integer,
    t1_score integer,
    t2_score integer,
    t1_points integer,
    t2_points integer,
    winner integer,
    match_type character varying(10)
);


ALTER TABLE public.matches OWNER TO "user";

--
-- Name: matches_extended; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.matches_extended (
    id integer NOT NULL,
    match_id integer NOT NULL,
    audience integer,
    mvp character varying(255)
);


ALTER TABLE public.matches_extended OWNER TO "user";

--
-- Name: matches_extended_id_seq; Type: SEQUENCE; Schema: public; Owner: user
--

CREATE SEQUENCE public.matches_extended_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.matches_extended_id_seq OWNER TO "user";

--
-- Name: matches_extended_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user
--

ALTER SEQUENCE public.matches_extended_id_seq OWNED BY public.matches_extended.id;


--
-- Name: matches_id_seq; Type: SEQUENCE; Schema: public; Owner: user
--

CREATE SEQUENCE public.matches_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.matches_id_seq OWNER TO "user";

--
-- Name: matches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user
--

ALTER SEQUENCE public.matches_id_seq OWNED BY public.matches.id;


--
-- Name: points_in_season; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.points_in_season (
    id integer NOT NULL,
    team integer,
    points integer
);


ALTER TABLE public.points_in_season OWNER TO "user";

--
-- Name: points_in_season_id_seq; Type: SEQUENCE; Schema: public; Owner: user
--

CREATE SEQUENCE public.points_in_season_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.points_in_season_id_seq OWNER TO "user";

--
-- Name: points_in_season_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user
--

ALTER SEQUENCE public.points_in_season_id_seq OWNED BY public.points_in_season.id;


--
-- Name: season; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.season (
    id integer NOT NULL,
    season character varying(10) NOT NULL
);


ALTER TABLE public.season OWNER TO "user";

--
-- Name: season_id_seq; Type: SEQUENCE; Schema: public; Owner: user
--

CREATE SEQUENCE public.season_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.season_id_seq OWNER TO "user";

--
-- Name: season_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user
--

ALTER SEQUENCE public.season_id_seq OWNED BY public.season.id;


--
-- Name: set_scores; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.set_scores (
    id integer NOT NULL,
    match_id integer NOT NULL,
    set_number integer NOT NULL,
    host_score integer NOT NULL,
    guest_score integer NOT NULL
);


ALTER TABLE public.set_scores OWNER TO "user";

--
-- Name: set_scores_id_seq; Type: SEQUENCE; Schema: public; Owner: user
--

CREATE SEQUENCE public.set_scores_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.set_scores_id_seq OWNER TO "user";

--
-- Name: set_scores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user
--

ALTER SEQUENCE public.set_scores_id_seq OWNED BY public.set_scores.id;


--
-- Name: team; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.team (
    id integer NOT NULL,
    teamname character varying(255) NOT NULL
);


ALTER TABLE public.team OWNER TO "user";

--
-- Name: team_id_seq; Type: SEQUENCE; Schema: public; Owner: user
--

CREATE SEQUENCE public.team_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.team_id_seq OWNER TO "user";

--
-- Name: team_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user
--

ALTER SEQUENCE public.team_id_seq OWNED BY public.team.id;


--
-- Name: teams_in_season; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.teams_in_season (
    id integer NOT NULL,
    season integer,
    team integer
);


ALTER TABLE public.teams_in_season OWNER TO "user";

--
-- Name: teams_in_season_id_seq; Type: SEQUENCE; Schema: public; Owner: user
--

CREATE SEQUENCE public.teams_in_season_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.teams_in_season_id_seq OWNER TO "user";

--
-- Name: teams_in_season_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user
--

ALTER SEQUENCE public.teams_in_season_id_seq OWNED BY public.teams_in_season.id;


--
-- Name: teams_in_single_season; Type: VIEW; Schema: public; Owner: user
--

CREATE VIEW public.teams_in_single_season AS
 SELECT t.teamname,
    s.season
   FROM ((public.teams_in_season tis
     JOIN public.team t ON ((tis.team = t.id)))
     JOIN public.season s ON ((tis.season = s.id)));


ALTER VIEW public.teams_in_single_season OWNER TO "user";

--
-- Name: teams_matches_in_season; Type: VIEW; Schema: public; Owner: user
--

CREATE VIEW public.teams_matches_in_season AS
 SELECT m.date,
    m.id,
    s.season,
    t.teamname AS team_1,
    ti.teamname AS team_2,
    m.t1_score,
    m.t2_score,
    m.t1_points,
    m.t2_points,
    m.winner,
    m.match_type
   FROM (((public.matches m
     JOIN public.season s ON ((m.season = s.id)))
     JOIN public.team t ON ((m.team_1 = t.id)))
     JOIN public.team ti ON ((m.team_2 = ti.id)));


ALTER VIEW public.teams_matches_in_season OWNER TO "user";

--
-- Name: match_details id; Type: DEFAULT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.match_details ALTER COLUMN id SET DEFAULT nextval('public.match_details_id_seq'::regclass);


--
-- Name: matches id; Type: DEFAULT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.matches ALTER COLUMN id SET DEFAULT nextval('public.matches_id_seq'::regclass);


--
-- Name: matches_extended id; Type: DEFAULT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.matches_extended ALTER COLUMN id SET DEFAULT nextval('public.matches_extended_id_seq'::regclass);


--
-- Name: points_in_season id; Type: DEFAULT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.points_in_season ALTER COLUMN id SET DEFAULT nextval('public.points_in_season_id_seq'::regclass);


--
-- Name: season id; Type: DEFAULT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.season ALTER COLUMN id SET DEFAULT nextval('public.season_id_seq'::regclass);


--
-- Name: set_scores id; Type: DEFAULT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.set_scores ALTER COLUMN id SET DEFAULT nextval('public.set_scores_id_seq'::regclass);


--
-- Name: team id; Type: DEFAULT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.team ALTER COLUMN id SET DEFAULT nextval('public.team_id_seq'::regclass);


--
-- Name: teams_in_season id; Type: DEFAULT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.teams_in_season ALTER COLUMN id SET DEFAULT nextval('public.teams_in_season_id_seq'::regclass);


--
-- Data for Name: match_details; Type: TABLE DATA; Schema: public; Owner: user
--

INSERT INTO public.match_details VALUES (205, 205, 59, 28, 41, 73, 8, 7, 5, 48, 3, 41, 27, 70, 3, 4, 40, 57, 47, 12, 11, 42, 12, 8, 57, 9, 3, -10, 65, 7, 36, 15, 80, 6, 12, 35, 43, 21, 4, 5);
INSERT INTO public.match_details VALUES (206, 206, 64, 20, 24, 88, 14, 5, -6, 87, 5, 52, 14, 130, 7, 14, 53, 40, 24, 6, 8, 79, 38, 47, 101, 14, 5, -7, 74, 5, 45, 20, 118, 7, 6, 60, 50, 39, 14, 17);
INSERT INTO public.match_details VALUES (207, 207, 77, 22, 32, 105, 20, 4, -9, 88, 3, 60, 28, 121, 9, 13, 62, 51, 33, 11, 11, 74, 22, 33, 109, 21, 3, -12, 85, 4, 40, 18, 119, 5, 11, 58, 48, 35, 13, 14);
INSERT INTO public.match_details VALUES (208, 208, 42, 17, 10, 62, 11, 5, -1, 60, 3, 41, 13, 83, 8, 10, 32, 38, 16, 5, 8, 54, 27, 26, 73, 13, 3, -4, 51, 5, 45, 13, 76, 5, 5, 41, 53, 40, 10, 11);
INSERT INTO public.match_details VALUES (209, 209, 51, 23, 28, 73, 13, 4, -6, 41, 2, 46, 21, 59, 3, 5, 36, 61, 47, 11, 10, 34, 8, -4, 53, 12, 2, -15, 60, 4, 48, 15, 69, 11, 11, 27, 39, 7, 5, 3);
INSERT INTO public.match_details VALUES (210, 210, 65, 18, 21, 90, 16, 3, -7, 79, 11, 45, 24, 101, 7, 10, 57, 56, 39, 5, 10, 73, 28, 43, 97, 18, 11, -3, 74, 3, 35, 14, 96, 4, 5, 52, 54, 44, 10, 5);
INSERT INTO public.match_details VALUES (211, 211, 36, 9, 0, 58, 13, 2, -18, 60, 8, 28, 16, 60, 8, 7, 26, 43, 18, 8, 6, 53, 22, 22, 74, 14, 8, 4, 45, 2, 55, 35, 70, 7, 8, 38, 54, 32, 7, 6);
INSERT INTO public.match_details VALUES (212, 212, 80, 27, 36, 114, 18, 9, -2, 85, 5, 47, 27, 123, 9, 12, 66, 53, 36, 5, 18, 81, 20, 34, 109, 24, 5, -15, 96, 9, 44, 25, 117, 9, 5, 64, 54, 42, 12, 7);
INSERT INTO public.match_details VALUES (213, 213, 77, 27, 42, 102, 14, 7, -1, 80, 9, 33, 13, 110, 5, 7, 66, 60, 49, 4, 10, 75, 27, 38, 97, 17, 9, 0, 88, 7, 44, 15, 108, 9, 4, 59, 54, 42, 7, 8);
INSERT INTO public.match_details VALUES (214, 214, 65, 22, 29, 94, 18, 5, -10, 75, 6, 54, 33, 92, 9, 3, 48, 52, 39, 12, 7, 64, 18, 20, 93, 18, 6, -7, 76, 5, 44, 31, 105, 9, 12, 55, 52, 32, 3, 7);
INSERT INTO public.match_details VALUES (215, 215, 58, 16, 21, 88, 15, 4, -9, 72, 5, 43, 22, 92, 11, 6, 41, 44, 26, 13, 13, 70, 21, 24, 96, 24, 5, -15, 73, 4, 36, 8, 114, 5, 13, 59, 51, 35, 6, 5);
INSERT INTO public.match_details VALUES (216, 216, 48, 10, 20, 64, 10, 2, -9, 63, 2, 30, 9, 82, 5, 11, 42, 51, 31, 4, 6, 59, 19, 40, 73, 10, 2, -8, 54, 2, 46, 16, 71, 3, 4, 46, 64, 54, 11, 5);
INSERT INTO public.match_details VALUES (217, 217, 73, 35, 43, 92, 10, 10, 1, 68, 7, 48, 27, 96, 7, 6, 48, 50, 36, 15, 15, 60, 19, 17, 79, 11, 7, -2, 81, 10, 37, 9, 117, 7, 15, 47, 40, 21, 6, 15);
INSERT INTO public.match_details VALUES (218, 218, 62, 31, 32, 80, 17, 8, -7, 53, 6, 52, 22, 81, 3, 4, 45, 55, 46, 9, 18, 43, 18, 8, 67, 14, 6, -8, 63, 8, 30, 15, 79, 4, 9, 33, 41, 25, 4, 9);
INSERT INTO public.match_details VALUES (219, 219, 44, 11, 11, 61, 14, 4, -6, 61, 6, 42, 13, 78, 5, 8, 37, 47, 30, 3, 9, 56, 23, 35, 73, 12, 6, -1, 47, 4, 44, 25, 73, 2, 3, 42, 57, 50, 8, 11);
INSERT INTO public.match_details VALUES (220, 220, 51, 22, 24, 75, 12, 4, -4, 52, 6, 32, 17, 74, 5, 4, 38, 51, 39, 9, 8, 51, 16, 14, 71, 19, 6, -14, 63, 4, 39, 26, 84, 5, 9, 41, 48, 32, 4, 10);
INSERT INTO public.match_details VALUES (221, 221, 69, 22, 29, 95, 13, 8, -3, 92, 8, 47, 20, 130, 9, 10, 57, 43, 29, 4, 21, 82, 32, 46, 109, 17, 8, -3, 82, 8, 47, 20, 124, 7, 4, 64, 51, 42, 10, 11);
INSERT INTO public.match_details VALUES (222, 222, 64, 21, 27, 95, 20, 2, -12, 73, 4, 43, 13, 96, 6, 7, 51, 53, 39, 11, 9, 66, 20, 25, 95, 22, 4, -14, 75, 2, 50, 33, 105, 6, 11, 55, 52, 36, 7, 10);
INSERT INTO public.match_details VALUES (223, 223, 44, 11, 7, 63, 15, 4, -15, 64, 6, 50, 23, 79, 9, 7, 40, 50, 30, 0, 0, 51, 24, 31, 73, 9, 6, 1, 48, 4, 45, 18, 61, 7, 0, 38, 62, 50, 7, 0);
INSERT INTO public.match_details VALUES (224, 224, 82, 36, 29, 111, 22, 13, -1, 86, 6, 40, 12, 112, 12, 13, 49, 43, 21, 20, 18, 71, 30, 11, 107, 21, 6, -6, 89, 13, 37, 7, 118, 6, 20, 52, 44, 22, 13, 18);
INSERT INTO public.match_details VALUES (225, 225, 73, 25, 29, 111, 19, 6, -9, 83, 7, 45, 16, 113, 11, 7, 60, 53, 37, 7, 14, 75, 21, 28, 105, 22, 7, -14, 92, 6, 54, 10, 112, 12, 7, 61, 54, 37, 7, 16);
INSERT INTO public.match_details VALUES (226, 226, 52, 12, 22, 68, 14, 4, -10, 62, 5, 50, 20, 71, 4, 7, 40, 56, 40, 8, 7, 53, 15, 27, 73, 11, 5, -6, 54, 4, 37, 7, 75, 3, 8, 41, 54, 40, 7, 9);
INSERT INTO public.match_details VALUES (227, 227, 76, 30, 37, 106, 13, 10, 0, 76, 6, 44, 6, 101, 8, 12, 56, 55, 35, 10, 10, 76, 22, 26, 98, 22, 6, -10, 93, 10, 38, 17, 111, 8, 10, 58, 52, 36, 12, 9);
INSERT INTO public.match_details VALUES (228, 228, 60, 23, 18, 86, 14, 5, -8, 76, 7, 42, 19, 103, 12, 9, 48, 46, 26, 7, 15, 66, 29, 31, 94, 18, 7, 0, 72, 5, 36, 13, 104, 5, 7, 50, 48, 36, 9, 8);
INSERT INTO public.match_details VALUES (229, 229, 72, 29, 30, 105, 16, 8, 0, 85, 7, 32, 15, 121, 11, 8, 51, 42, 26, 13, 10, 74, 27, 25, 103, 18, 7, -3, 89, 8, 42, 23, 125, 10, 13, 59, 47, 28, 8, 15);
INSERT INTO public.match_details VALUES (230, 230, 74, 29, 36, 101, 13, 6, -3, 82, 4, 53, 19, 111, 11, 10, 58, 52, 33, 10, 8, 74, 25, 34, 100, 18, 4, -9, 88, 6, 54, 25, 113, 6, 10, 60, 53, 38, 10, 9);
INSERT INTO public.match_details VALUES (231, 231, 55, 21, 30, 73, 14, 4, -9, 52, 4, 51, 15, 67, 3, 4, 42, 62, 52, 9, 7, 41, 12, 10, 61, 9, 4, -3, 59, 4, 54, 20, 75, 9, 9, 33, 44, 20, 4, 4);
INSERT INTO public.match_details VALUES (232, 232, 43, 10, 11, 56, 12, 1, -14, 69, 4, 42, 21, 84, 6, 10, 36, 42, 23, 6, 6, 57, 29, 41, 74, 5, 4, 14, 44, 1, 50, 27, 73, 4, 6, 43, 58, 45, 10, 6);
INSERT INTO public.match_details VALUES (233, 233, 75, 25, 38, 106, 17, 6, 0, 84, 9, 54, 16, 131, 6, 5, 64, 48, 40, 5, 16, 73, 24, 37, 100, 16, 9, -2, 89, 6, 51, 25, 125, 9, 5, 59, 47, 36, 5, 15);
INSERT INTO public.match_details VALUES (234, 234, 73, 24, 22, 100, 21, 6, -10, 86, 9, 50, 22, 108, 4, 17, 62, 57, 37, 5, 9, 81, 32, 43, 106, 20, 9, -6, 79, 6, 54, 22, 95, 7, 5, 55, 57, 45, 17, 3);
INSERT INTO public.match_details VALUES (235, 235, 80, 32, 37, 106, 21, 6, -9, 85, 5, 51, 28, 112, 8, 9, 60, 53, 38, 14, 16, 66, 27, 25, 99, 14, 5, -1, 85, 6, 47, 15, 121, 7, 14, 52, 42, 25, 9, 6);
INSERT INTO public.match_details VALUES (236, 236, 56, 28, 34, 76, 7, 5, 0, 47, 3, 42, 21, 73, 8, 4, 40, 54, 38, 11, 12, 43, 9, 7, 62, 15, 3, -16, 69, 5, 40, 18, 87, 5, 11, 36, 41, 22, 4, 5);
INSERT INTO public.match_details VALUES (237, 237, 40, 11, 9, 62, 14, 3, -17, 65, 6, 49, 13, 74, 4, 7, 33, 44, 29, 4, 7, 60, 28, 33, 77, 12, 6, -1, 48, 3, 52, 22, 84, 8, 4, 47, 55, 41, 7, 11);
INSERT INTO public.match_details VALUES (238, 238, 58, 17, 14, 78, 20, 4, -19, 81, 5, 48, 25, 119, 5, 14, 45, 37, 21, 9, 10, 70, 33, 38, 95, 14, 5, -8, 58, 4, 56, 43, 100, 5, 9, 51, 51, 37, 14, 16);
INSERT INTO public.match_details VALUES (239, 239, 44, 13, 9, 65, 13, 3, -6, 58, 6, 37, 8, 72, 6, 10, 34, 47, 25, 7, 7, 55, 21, 27, 73, 15, 6, -8, 52, 3, 42, 17, 70, 3, 7, 39, 55, 41, 10, 4);
INSERT INTO public.match_details VALUES (240, 240, 44, 11, 14, 57, 15, 4, -15, 68, 3, 48, 26, 81, 7, 5, 40, 49, 34, 0, 5, 50, 25, 34, 74, 6, 3, 4, 42, 4, 57, 40, 67, 6, 0, 42, 62, 53, 5, 5);
INSERT INTO public.match_details VALUES (241, 241, 66, 24, 23, 92, 20, 6, -14, 86, 4, 38, 17, 112, 7, 12, 52, 46, 29, 8, 13, 71, 33, 34, 98, 12, 4, 1, 72, 6, 47, 19, 107, 11, 8, 55, 51, 33, 12, 14);
INSERT INTO public.match_details VALUES (242, 242, 38, 13, -2, 61, 15, 6, -13, 63, 8, 42, 30, 78, 9, 8, 30, 38, 16, 2, 7, 49, 23, 22, 74, 11, 8, 2, 46, 6, 56, 28, 75, 8, 2, 33, 44, 30, 8, 6);
INSERT INTO public.match_details VALUES (243, 243, 76, 34, 29, 105, 16, 10, 0, 80, 3, 51, 20, 133, 15, 13, 59, 44, 23, 7, 14, 67, 25, 24, 102, 22, 3, -12, 89, 10, 53, 24, 120, 4, 7, 51, 42, 33, 13, 11);
INSERT INTO public.match_details VALUES (244, 244, 72, 29, 36, 97, 11, 5, -1, 74, 7, 45, 14, 114, 3, 15, 56, 49, 33, 11, 16, 72, 28, 32, 93, 19, 7, -8, 86, 5, 38, 8, 107, 5, 11, 50, 46, 31, 15, 16);
INSERT INTO public.match_details VALUES (245, 245, 58, 23, 36, 73, 13, 5, -9, 49, 2, 53, 20, 72, 2, 5, 48, 66, 56, 5, 10, 42, 11, 15, 59, 10, 2, -6, 60, 5, 60, 21, 82, 7, 5, 35, 42, 28, 5, 3);
INSERT INTO public.match_details VALUES (246, 246, 71, 22, 32, 88, 17, 7, -7, 83, 4, 45, 19, 114, 6, 12, 56, 49, 33, 8, 7, 70, 28, 41, 95, 12, 4, -6, 71, 7, 52, 29, 108, 2, 8, 54, 50, 40, 12, 15);
INSERT INTO public.match_details VALUES (247, 247, 50, 15, 24, 74, 14, 5, -12, 53, 2, 54, 22, 78, 5, 5, 40, 51, 38, 5, 6, 45, 10, 11, 68, 15, 2, -16, 60, 5, 45, 20, 80, 9, 5, 38, 47, 30, 5, 5);
INSERT INTO public.match_details VALUES (248, 248, 70, 25, 27, 104, 15, 10, 2, 77, 9, 33, 12, 105, 7, 12, 55, 52, 34, 5, 6, 75, 26, 27, 99, 22, 9, -12, 89, 10, 38, 19, 101, 11, 5, 54, 53, 37, 12, 13);
INSERT INTO public.match_details VALUES (249, 249, 74, 25, 51, 98, 11, 6, -2, 76, 3, 44, 15, 105, 3, 6, 52, 49, 40, 16, 15, 72, 20, 30, 89, 13, 3, -5, 87, 6, 43, 20, 131, 7, 16, 63, 48, 30, 6, 13);
INSERT INTO public.match_details VALUES (250, 250, 35, 8, -5, 54, 15, 4, -20, 61, 9, 36, 19, 63, 9, 7, 28, 44, 19, 3, 1, 50, 23, 25, 75, 14, 9, -1, 39, 4, 46, 28, 57, 4, 3, 34, 59, 47, 7, 2);
INSERT INTO public.match_details VALUES (251, 251, 55, 24, 34, 74, 9, 3, -1, 47, 2, 46, 25, 79, 5, 5, 38, 48, 35, 14, 7, 42, 10, 8, 58, 11, 2, -10, 65, 3, 55, 13, 92, 6, 14, 35, 38, 16, 5, 7);
INSERT INTO public.match_details VALUES (252, 252, 56, 24, 34, 74, 11, 4, -4, 45, 2, 57, 20, 67, 6, 3, 43, 64, 50, 9, 9, 36, 7, 6, 55, 10, 2, -12, 63, 4, 49, 31, 72, 7, 9, 31, 43, 20, 3, 3);
INSERT INTO public.match_details VALUES (253, 253, 85, 25, 44, 118, 18, 4, -9, 98, 4, 54, 14, 133, 11, 8, 70, 52, 38, 11, 14, 88, 24, 45, 121, 23, 4, -12, 100, 4, 57, 21, 138, 5, 11, 76, 55, 43, 8, 13);
INSERT INTO public.match_details VALUES (254, 254, 75, 31, 22, 109, 19, 9, -3, 84, 11, 39, 13, 114, 12, 11, 55, 48, 28, 11, 8, 75, 27, 22, 109, 25, 11, -8, 90, 9, 48, 17, 106, 8, 11, 53, 50, 32, 11, 12);
INSERT INTO public.match_details VALUES (255, 255, 56, 23, 30, 74, 15, 7, -6, 50, 2, 64, 14, 65, 5, 4, 40, 61, 47, 9, 5, 40, 13, 5, 63, 13, 2, -15, 59, 7, 49, 20, 72, 6, 9, 34, 47, 26, 4, 5);
INSERT INTO public.match_details VALUES (256, 256, 49, 23, 24, 72, 17, 2, -16, 42, 2, 33, 14, 59, 4, 2, 34, 57, 47, 13, 10, 32, 8, -2, 55, 13, 2, -7, 55, 2, 43, 20, 79, 6, 13, 28, 35, 11, 2, 6);
INSERT INTO public.match_details VALUES (257, 257, 51, 13, 19, 77, 15, 2, -11, 68, 4, 48, 14, 93, 4, 9, 44, 47, 33, 5, 2, 63, 22, 33, 83, 15, 4, -8, 62, 2, 54, 19, 90, 8, 5, 50, 55, 41, 9, 8);
INSERT INTO public.match_details VALUES (258, 258, 73, 29, 40, 95, 11, 10, 4, 75, 4, 54, 13, 115, 10, 8, 55, 47, 32, 8, 12, 60, 18, 22, 86, 11, 4, -2, 84, 10, 35, 4, 108, 9, 8, 48, 44, 28, 8, 14);
INSERT INTO public.match_details VALUES (259, 259, 52, 20, 30, 74, 11, 1, -13, 53, 2, 60, 32, 90, 5, 4, 38, 42, 32, 13, 6, 47, 13, 11, 62, 12, 2, -16, 63, 1, 60, 31, 102, 10, 13, 41, 40, 17, 4, 15);
INSERT INTO public.match_details VALUES (260, 260, 59, 23, 39, 74, 13, 5, 1, 53, 1, 56, 26, 79, 2, 4, 48, 60, 53, 6, 5, 46, 15, 21, 62, 9, 1, -6, 61, 5, 45, 22, 77, 5, 6, 41, 53, 38, 4, 8);
INSERT INTO public.match_details VALUES (261, 261, 63, 18, 42, 73, 11, 6, -1, 57, 1, 50, 26, 83, 3, 6, 53, 63, 53, 4, 9, 47, 10, 28, 64, 7, 1, -6, 62, 6, 46, 24, 72, 2, 4, 40, 55, 47, 6, 4);
INSERT INTO public.match_details VALUES (262, 262, 75, 27, 32, 101, 18, 7, -8, 82, 6, 52, 29, 108, 9, 10, 56, 51, 34, 12, 10, 68, 23, 24, 98, 16, 6, -7, 83, 7, 51, 36, 109, 9, 12, 52, 47, 28, 10, 10);
INSERT INTO public.match_details VALUES (263, 263, 63, 19, 30, 86, 11, 6, -2, 77, 2, 46, 16, 109, 9, 11, 51, 46, 28, 6, 6, 66, 22, 33, 91, 14, 2, -9, 75, 6, 41, 16, 97, 7, 6, 53, 54, 41, 11, 9);
INSERT INTO public.match_details VALUES (264, 264, 61, 24, 25, 91, 15, 5, -4, 62, 4, 51, 32, 92, 9, 8, 43, 46, 28, 13, 11, 55, 17, 6, 82, 20, 4, -10, 76, 5, 35, 14, 98, 11, 13, 43, 43, 19, 8, 17);
INSERT INTO public.match_details VALUES (265, 265, 83, 37, 39, 103, 14, 5, -2, 86, 4, 44, 29, 149, 12, 14, 67, 44, 27, 11, 18, 69, 28, 33, 98, 12, 4, -7, 89, 5, 46, 23, 128, 8, 11, 51, 39, 25, 14, 7);
INSERT INTO public.match_details VALUES (266, 266, 74, 25, 35, 103, 17, 8, -3, 76, 3, 55, 18, 114, 12, 7, 59, 51, 35, 7, 6, 60, 15, 21, 92, 16, 3, -10, 86, 8, 47, 24, 105, 8, 7, 50, 47, 33, 7, 3);
INSERT INTO public.match_details VALUES (267, 267, 77, 28, 24, 109, 14, 12, 5, 93, 9, 36, 13, 134, 11, 19, 60, 44, 22, 5, 14, 89, 34, 41, 116, 23, 9, -10, 95, 12, 33, 15, 113, 8, 5, 61, 53, 42, 19, 10);
INSERT INTO public.match_details VALUES (268, 268, 47, 13, 15, 64, 11, 2, -14, 60, 4, 46, 21, 80, 7, 10, 38, 47, 26, 7, 6, 57, 21, 33, 73, 13, 4, -5, 53, 2, 49, 28, 81, 2, 7, 43, 53, 41, 10, 10);
INSERT INTO public.match_details VALUES (269, 269, 56, 25, 25, 74, 13, 6, -2, 55, 7, 41, 27, 92, 4, 7, 42, 45, 33, 8, 10, 45, 15, 14, 63, 8, 7, 1, 61, 6, 39, 21, 84, 9, 8, 31, 36, 16, 7, 8);
INSERT INTO public.match_details VALUES (270, 270, 67, 22, 6, 102, 30, 5, -19, 83, 8, 40, 15, 104, 11, 12, 48, 46, 24, 14, 9, 62, 22, 9, 104, 21, 8, -8, 72, 5, 61, 16, 101, 13, 14, 42, 41, 14, 12, 5);
INSERT INTO public.match_details VALUES (271, 271, 74, 30, 26, 105, 19, 5, -11, 80, 8, 45, 15, 109, 8, 13, 56, 51, 32, 13, 13, 74, 28, 24, 105, 24, 8, -12, 86, 5, 41, 19, 111, 8, 13, 53, 47, 28, 13, 11);
INSERT INTO public.match_details VALUES (272, 272, 36, 9, 0, 54, 13, 3, -14, 61, 8, 52, 18, 82, 6, 9, 30, 36, 18, 3, 2, 55, 27, 32, 74, 13, 8, -4, 41, 3, 51, 19, 61, 4, 3, 38, 62, 50, 9, 12);
INSERT INTO public.match_details VALUES (273, 273, 73, 27, 39, 103, 14, 7, -4, 90, 5, 47, 27, 135, 6, 9, 58, 42, 31, 8, 16, 82, 30, 40, 106, 16, 5, -7, 89, 7, 38, 21, 145, 11, 8, 68, 46, 33, 9, 17);
INSERT INTO public.match_details VALUES (274, 274, 76, 28, 41, 99, 18, 7, -6, 71, 4, 50, 14, 93, 3, 10, 59, 63, 49, 10, 8, 63, 18, 23, 86, 15, 4, -8, 81, 7, 46, 20, 102, 8, 10, 49, 48, 30, 10, 7);
INSERT INTO public.match_details VALUES (275, 275, 47, 13, 17, 61, 10, 3, -9, 65, 3, 53, 40, 94, 10, 7, 41, 43, 25, 3, 4, 51, 20, 33, 74, 9, 3, -8, 51, 3, 45, 27, 76, 3, 3, 41, 53, 46, 7, 7);
INSERT INTO public.match_details VALUES (276, 276, 58, 16, 15, 83, 20, 6, -15, 77, 2, 54, 24, 104, 8, 13, 44, 42, 22, 8, 8, 61, 24, 26, 90, 13, 2, -8, 63, 6, 38, 17, 91, 8, 8, 46, 50, 32, 13, 9);
INSERT INTO public.match_details VALUES (277, 277, 62, 28, 39, 74, 11, 5, -1, 52, 4, 61, 28, 88, 3, 5, 50, 56, 47, 7, 14, 44, 14, 20, 59, 7, 4, -1, 63, 5, 38, 23, 78, 5, 7, 35, 44, 29, 5, 3);
INSERT INTO public.match_details VALUES (278, 278, 64, 27, 31, 91, 17, 6, -3, 60, 2, 48, 26, 91, 10, 4, 52, 57, 41, 6, 12, 49, 14, 11, 78, 18, 2, -17, 74, 6, 44, 28, 87, 8, 6, 43, 49, 33, 4, 7);
INSERT INTO public.match_details VALUES (279, 279, 45, 7, 7, 63, 20, 0, -26, 65, 9, 36, 18, 74, 3, 6, 42, 56, 44, 3, 2, 50, 21, 31, 73, 8, 9, 6, 43, 0, 37, 23, 64, 8, 3, 35, 54, 37, 6, 12);
INSERT INTO public.match_details VALUES (280, 280, 78, 25, 32, 103, 20, 7, -9, 88, 7, 44, 19, 125, 11, 8, 64, 51, 36, 7, 18, 69, 21, 32, 105, 17, 7, -4, 83, 7, 34, 12, 126, 6, 7, 54, 42, 32, 8, 12);
INSERT INTO public.match_details VALUES (281, 281, 53, 23, 25, 74, 17, 3, -13, 55, 5, 52, 30, 80, 2, 4, 38, 47, 40, 12, 6, 44, 19, 10, 67, 12, 5, -5, 57, 3, 49, 24, 82, 7, 12, 35, 42, 19, 4, 6);
INSERT INTO public.match_details VALUES (282, 282, 41, 8, 7, 59, 14, 3, -15, 64, 10, 29, 14, 69, 5, 5, 35, 50, 36, 3, 1, 53, 25, 32, 73, 9, 10, 5, 45, 3, 46, 31, 70, 6, 3, 38, 54, 41, 5, 10);
INSERT INTO public.match_details VALUES (283, 283, 45, 12, 15, 62, 13, 1, -16, 64, 3, 51, 18, 81, 9, 5, 35, 43, 25, 9, 6, 50, 19, 27, 74, 10, 3, 0, 49, 1, 67, 30, 79, 3, 9, 42, 53, 37, 5, 7);
INSERT INTO public.match_details VALUES (284, 284, 59, 22, 24, 73, 18, 4, -12, 57, 5, 49, 17, 75, 2, 10, 47, 62, 46, 8, 7, 44, 18, 21, 66, 9, 5, -3, 55, 4, 36, 18, 62, 2, 8, 29, 46, 30, 10, 5);
INSERT INTO public.match_details VALUES (285, 285, 70, 30, 29, 96, 18, 6, -9, 74, 7, 48, 17, 115, 4, 12, 53, 46, 32, 11, 15, 66, 28, 23, 91, 17, 7, -8, 78, 6, 50, 25, 110, 9, 11, 47, 42, 24, 12, 10);
INSERT INTO public.match_details VALUES (286, 286, 54, 22, 27, 74, 20, 7, -16, 46, 2, 56, 30, 58, 3, 2, 38, 65, 56, 9, 3, 34, 9, 0, 59, 13, 2, -15, 54, 7, 44, 25, 67, 5, 9, 30, 44, 23, 2, 7);
INSERT INTO public.match_details VALUES (287, 287, 72, 29, 22, 106, 22, 8, -4, 80, 12, 35, 10, 94, 10, 6, 56, 59, 42, 8, 6, 65, 24, 18, 100, 20, 12, -5, 84, 8, 44, 8, 88, 11, 8, 47, 53, 31, 6, 6);
INSERT INTO public.match_details VALUES (288, 288, 89, 39, 56, 116, 16, 6, -4, 91, 1, 48, 24, 135, 9, 7, 68, 50, 38, 15, 15, 78, 26, 33, 106, 15, 1, -10, 100, 6, 41, 22, 144, 9, 15, 70, 48, 31, 7, 19);
INSERT INTO public.match_details VALUES (289, 289, 42, 11, 11, 70, 11, 3, -7, 60, 3, 53, 30, 88, 6, 11, 32, 36, 17, 7, 4, 58, 22, 24, 74, 14, 3, -10, 59, 3, 54, 30, 87, 10, 7, 44, 50, 31, 11, 9);
INSERT INTO public.match_details VALUES (290, 290, 83, 30, 47, 103, 16, 5, -5, 92, 8, 50, 20, 121, 7, 5, 67, 55, 45, 11, 18, 76, 28, 43, 102, 10, 8, 3, 87, 5, 47, 16, 128, 7, 11, 63, 49, 35, 5, 16);
INSERT INTO public.match_details VALUES (291, 291, 72, 26, 31, 107, 20, 7, -8, 75, 3, 46, 24, 104, 9, 9, 50, 48, 30, 15, 9, 69, 21, 17, 99, 24, 3, -17, 87, 7, 41, 20, 105, 6, 15, 57, 54, 34, 9, 12);
INSERT INTO public.match_details VALUES (292, 292, 60, 21, 41, 73, 11, 3, -8, 48, 3, 56, 29, 74, 0, 5, 47, 63, 56, 10, 8, 44, 8, 16, 59, 11, 3, -13, 62, 3, 43, 20, 78, 4, 10, 36, 46, 28, 5, 7);
INSERT INTO public.match_details VALUES (293, 293, 55, 25, 34, 74, 6, 8, 9, 48, 3, 62, 27, 67, 4, 8, 36, 53, 35, 11, 6, 49, 13, 12, 62, 14, 3, -16, 68, 8, 51, 22, 87, 4, 11, 38, 43, 26, 8, 9);
INSERT INTO public.match_details VALUES (294, 294, 65, 20, 27, 92, 18, 3, -11, 78, 5, 51, 21, 104, 6, 9, 57, 54, 40, 5, 15, 69, 26, 35, 97, 19, 5, -12, 74, 3, 51, 25, 112, 7, 5, 55, 49, 38, 9, 10);
INSERT INTO public.match_details VALUES (295, 295, 35, 12, -1, 55, 15, 5, -14, 61, 5, 39, 16, 76, 5, 11, 26, 34, 13, 4, 10, 54, 28, 31, 73, 12, 5, -4, 40, 5, 47, 20, 67, 2, 4, 38, 56, 47, 11, 9);
INSERT INTO public.match_details VALUES (296, 296, 60, 17, 27, 89, 13, 3, -7, 83, 8, 49, 14, 111, 6, 6, 53, 47, 36, 4, 10, 77, 30, 43, 97, 14, 8, -5, 76, 3, 53, 18, 126, 13, 4, 63, 50, 36, 6, 13);
INSERT INTO public.match_details VALUES (297, 297, 38, 9, -1, 64, 12, 3, -12, 65, 9, 33, 10, 79, 7, 11, 30, 37, 15, 5, 9, 66, 29, 34, 87, 22, 9, -9, 52, 3, 42, 21, 82, 2, 5, 46, 56, 47, 11, 13);
INSERT INTO public.match_details VALUES (298, 298, 43, 8, 13, 59, 15, 1, -22, 62, 3, 46, 20, 75, 7, 5, 38, 50, 34, 4, 8, 52, 22, 33, 74, 12, 3, -9, 44, 1, 65, 34, 73, 2, 4, 44, 60, 52, 5, 4);
INSERT INTO public.match_details VALUES (299, 299, 73, 35, 36, 105, 11, 14, 10, 77, 6, 42, 23, 95, 9, 11, 48, 50, 29, 11, 7, 74, 26, 18, 99, 22, 6, -9, 94, 14, 32, 14, 113, 9, 11, 57, 50, 32, 11, 11);
INSERT INTO public.match_details VALUES (300, 300, 82, 31, 43, 112, 16, 8, -4, 89, 4, 51, 17, 122, 7, 12, 64, 52, 36, 10, 12, 84, 29, 36, 110, 21, 4, -10, 96, 8, 43, 16, 126, 9, 10, 68, 53, 38, 12, 9);
INSERT INTO public.match_details VALUES (301, 301, 69, 38, 41, 96, 14, 7, -2, 57, 4, 61, 31, 99, 4, 6, 44, 44, 34, 18, 6, 51, 17, 2, 71, 14, 4, -14, 82, 7, 50, 23, 100, 10, 18, 41, 41, 13, 6, 11);
INSERT INTO public.match_details VALUES (302, 302, 67, 17, 26, 95, 18, 5, -10, 90, 7, 55, 18, 119, 8, 8, 56, 47, 33, 6, 17, 77, 29, 42, 106, 16, 7, -5, 77, 5, 48, 16, 117, 8, 6, 62, 52, 41, 8, 9);
INSERT INTO public.match_details VALUES (303, 303, 46, 14, 16, 61, 11, 3, -8, 65, 6, 46, 23, 83, 7, 6, 37, 44, 28, 6, 9, 55, 24, 34, 73, 8, 6, 2, 50, 3, 52, 22, 78, 4, 6, 43, 55, 42, 6, 14);
INSERT INTO public.match_details VALUES (304, 304, 53, 20, 38, 73, 5, 3, 2, 50, 1, 70, 36, 76, 3, 6, 35, 46, 34, 15, 5, 51, 14, 13, 62, 12, 1, -14, 68, 3, 44, 20, 98, 8, 15, 44, 44, 21, 6, 9);
INSERT INTO public.match_details VALUES (305, 305, 78, 28, 41, 106, 17, 4, -5, 87, 5, 48, 22, 125, 5, 10, 60, 48, 36, 14, 13, 76, 24, 33, 100, 13, 5, -2, 89, 4, 46, 13, 128, 12, 14, 61, 47, 27, 10, 12);
INSERT INTO public.match_details VALUES (306, 306, 62, 25, 38, 73, 11, 7, -1, 58, 5, 39, 6, 75, 3, 5, 43, 57, 46, 12, 4, 52, 16, 20, 68, 10, 5, -4, 62, 7, 50, 8, 78, 3, 12, 42, 53, 34, 5, 7);
INSERT INTO public.match_details VALUES (307, 307, 47, 12, 14, 64, 16, 6, -15, 61, 4, 60, 31, 78, 7, 6, 39, 50, 33, 2, 6, 52, 18, 29, 73, 12, 4, -8, 48, 6, 50, 16, 65, 3, 2, 42, 64, 56, 6, 5);
INSERT INTO public.match_details VALUES (308, 308, 55, 26, 35, 74, 9, 5, 0, 46, 2, 39, 28, 70, 3, 6, 38, 54, 41, 12, 10, 46, 13, 10, 59, 13, 2, -16, 65, 5, 47, 20, 77, 6, 12, 37, 48, 24, 7, 7);
INSERT INTO public.match_details VALUES (309, 309, 43, 13, 13, 63, 12, 2, -11, 63, 9, 36, 23, 77, 3, 6, 38, 49, 37, 3, 4, 56, 24, 35, 73, 10, 9, 5, 51, 2, 56, 21, 74, 6, 3, 41, 55, 43, 6, 5);
INSERT INTO public.match_details VALUES (310, 310, 76, 21, 29, 108, 20, 2, -11, 94, 6, 44, 19, 128, 9, 12, 62, 48, 32, 12, 12, 81, 28, 36, 114, 20, 6, -7, 88, 2, 54, 13, 117, 11, 12, 63, 53, 34, 12, 19);
INSERT INTO public.match_details VALUES (311, 311, 70, 21, 25, 99, 17, 8, -4, 87, 3, 57, 22, 123, 4, 21, 56, 45, 25, 6, 11, 81, 32, 40, 106, 19, 3, -13, 82, 8, 58, 24, 117, 8, 6, 57, 48, 36, 21, 16);
INSERT INTO public.match_details VALUES (312, 312, 58, 25, 30, 73, 12, 8, -1, 53, 5, 49, 32, 83, 7, 4, 46, 55, 42, 4, 6, 38, 11, 10, 61, 8, 5, -1, 61, 8, 36, 24, 75, 8, 4, 29, 38, 22, 4, 4);
INSERT INTO public.match_details VALUES (313, 313, 43, 12, 0, 64, 14, 4, -12, 66, 4, 42, 24, 93, 10, 15, 32, 34, 7, 7, 8, 54, 27, 24, 79, 13, 4, -2, 50, 4, 64, 30, 84, 6, 7, 35, 41, 26, 15, 8);
INSERT INTO public.match_details VALUES (314, 314, 68, 25, 37, 95, 16, 6, -10, 69, 5, 57, 40, 78, 5, 5, 50, 64, 51, 12, 7, 64, 19, 19, 88, 19, 5, -12, 78, 6, 56, 38, 96, 8, 12, 54, 56, 35, 5, 3);
INSERT INTO public.match_details VALUES (315, 315, 58, 24, 23, 76, 13, 6, -5, 71, 2, 54, 26, 96, 12, 8, 40, 41, 20, 12, 9, 56, 23, 25, 80, 9, 2, -6, 63, 6, 49, 22, 90, 4, 12, 46, 51, 33, 8, 10);
INSERT INTO public.match_details VALUES (316, 316, 61, 35, 43, 74, 7, 11, 13, 43, 1, 53, 30, 63, 4, 6, 37, 58, 42, 13, 3, 38, 13, 3, 50, 7, 1, -10, 67, 11, 35, 17, 64, 4, 13, 31, 48, 21, 6, 4);
INSERT INTO public.match_details VALUES (317, 317, 70, 31, 33, 96, 19, 5, -10, 66, 6, 57, 36, 103, 5, 7, 48, 46, 34, 17, 14, 58, 24, 9, 86, 20, 6, -11, 77, 5, 35, 23, 110, 7, 17, 45, 40, 19, 7, 8);
INSERT INTO public.match_details VALUES (318, 318, 81, 43, 46, 109, 13, 13, 8, 70, 8, 42, 17, 107, 4, 10, 59, 55, 42, 9, 7, 68, 25, 22, 86, 16, 8, -1, 96, 13, 47, 17, 108, 8, 9, 50, 46, 30, 10, 8);
INSERT INTO public.match_details VALUES (319, 319, 69, 22, 31, 93, 16, 3, -11, 73, 4, 45, 12, 105, 6, 12, 53, 50, 33, 13, 8, 60, 16, 20, 84, 11, 4, -7, 77, 3, 48, 6, 101, 13, 13, 44, 43, 17, 12, 6);
INSERT INTO public.match_details VALUES (320, 320, 57, 19, 18, 83, 18, 3, -14, 78, 5, 50, 26, 99, 4, 12, 43, 43, 27, 11, 9, 71, 33, 34, 92, 14, 5, -4, 65, 3, 41, 16, 112, 9, 11, 54, 48, 30, 12, 14);
INSERT INTO public.match_details VALUES (321, 321, 67, 18, 31, 95, 21, 4, -16, 81, 4, 51, 22, 105, 7, 4, 54, 51, 40, 9, 8, 67, 21, 32, 99, 18, 4, -10, 74, 4, 39, 17, 114, 4, 9, 59, 51, 40, 4, 12);
INSERT INTO public.match_details VALUES (322, 322, 68, 27, 29, 92, 23, 9, -13, 78, 4, 43, 20, 104, 5, 7, 46, 44, 32, 13, 12, 63, 30, 20, 91, 13, 4, -6, 69, 9, 33, 15, 104, 8, 13, 52, 50, 29, 7, 7);
INSERT INTO public.match_details VALUES (323, 323, 69, 20, 25, 105, 22, 4, -16, 82, 7, 48, 25, 123, 7, 8, 58, 47, 34, 7, 12, 78, 25, 34, 107, 25, 7, -14, 83, 4, 50, 27, 113, 8, 7, 63, 55, 42, 8, 12);
INSERT INTO public.match_details VALUES (324, 324, 66, 29, 29, 97, 12, 5, -1, 70, 11, 35, 20, 99, 8, 6, 55, 55, 41, 6, 15, 65, 24, 25, 90, 20, 11, -5, 85, 5, 47, 17, 100, 9, 6, 48, 48, 33, 6, 7);
INSERT INTO public.match_details VALUES (325, 325, 68, 18, 22, 96, 17, 8, -3, 79, 9, 49, 17, 108, 8, 12, 58, 53, 35, 2, 8, 76, 25, 41, 101, 22, 9, -9, 79, 8, 44, 20, 94, 3, 2, 55, 58, 53, 12, 7);
INSERT INTO public.match_details VALUES (326, 326, 42, 10, 5, 62, 16, 6, -12, 62, 6, 50, 35, 64, 8, 7, 34, 53, 29, 2, 3, 49, 21, 24, 74, 12, 6, -4, 46, 6, 54, 30, 57, 5, 2, 36, 63, 50, 7, 4);
INSERT INTO public.match_details VALUES (327, 327, 63, 18, 18, 90, 21, 5, -11, 80, 7, 40, 16, 95, 8, 9, 53, 55, 37, 5, 7, 65, 24, 32, 96, 16, 7, -4, 69, 5, 52, 20, 89, 7, 5, 49, 55, 41, 9, 6);
INSERT INTO public.match_details VALUES (328, 328, 57, 18, 32, 75, 13, 6, -8, 60, 4, 53, 21, 90, 4, 4, 45, 50, 41, 6, 10, 52, 14, 22, 72, 12, 4, -8, 62, 6, 51, 30, 99, 6, 6, 44, 44, 32, 4, 11);
INSERT INTO public.match_details VALUES (329, 329, 52, 21, 35, 73, 8, 3, -1, 44, 0, 54, 27, 71, 2, 7, 37, 52, 39, 12, 11, 44, 9, 7, 60, 16, 0, -20, 65, 3, 52, 26, 86, 6, 12, 37, 43, 22, 7, 9);
INSERT INTO public.match_details VALUES (330, 330, 62, 25, 38, 73, 16, 9, -5, 51, 4, 49, 23, 65, 2, 2, 42, 64, 58, 11, 6, 37, 11, 6, 60, 9, 4, -6, 57, 9, 47, 21, 59, 2, 11, 31, 52, 30, 2, 5);
INSERT INTO public.match_details VALUES (331, 331, 74, 26, 24, 108, 21, 7, -5, 92, 11, 41, 8, 113, 13, 5, 55, 48, 32, 12, 16, 73, 24, 26, 110, 18, 11, 0, 87, 7, 49, 19, 123, 10, 12, 57, 46, 28, 5, 10);
INSERT INTO public.match_details VALUES (332, 332, 71, 27, 36, 97, 16, 13, 5, 74, 4, 45, 9, 97, 9, 6, 54, 55, 40, 4, 10, 62, 19, 20, 90, 16, 4, -10, 81, 13, 37, 9, 97, 9, 4, 52, 53, 40, 6, 11);
INSERT INTO public.match_details VALUES (333, 333, 52, 21, 24, 79, 17, 2, -12, 50, 0, 56, 32, 81, 5, 6, 43, 53, 39, 7, 6, 43, 13, 7, 67, 17, 0, -23, 62, 2, 51, 25, 86, 10, 7, 37, 43, 23, 6, 8);
INSERT INTO public.match_details VALUES (334, 334, 62, 19, 25, 86, 14, 4, -8, 82, 4, 47, 28, 118, 10, 9, 47, 39, 23, 11, 8, 70, 26, 36, 98, 16, 4, -7, 72, 4, 43, 22, 104, 3, 11, 57, 54, 41, 9, 20);
INSERT INTO public.match_details VALUES (335, 335, 39, 11, 9, 66, 15, 3, -15, 55, 7, 34, 18, 70, 3, 5, 33, 47, 35, 3, 7, 55, 19, 26, 73, 18, 7, -8, 51, 3, 54, 31, 75, 5, 3, 43, 57, 46, 5, 3);
INSERT INTO public.match_details VALUES (336, 336, 67, 24, 35, 92, 20, 4, -14, 71, 2, 56, 26, 104, 3, 7, 52, 50, 40, 11, 11, 58, 21, 19, 85, 14, 2, -14, 72, 4, 52, 25, 104, 10, 11, 49, 47, 26, 7, 13);
INSERT INTO public.match_details VALUES (337, 337, 53, 18, 40, 73, 7, 4, 5, 43, 0, 48, 18, 67, 1, 5, 46, 68, 59, 3, 4, 47, 5, 20, 59, 16, 0, -23, 66, 4, 45, 19, 66, 4, 3, 42, 63, 53, 5, 2);
INSERT INTO public.match_details VALUES (338, 338, 82, 24, 50, 103, 20, 5, -6, 87, 4, 59, 25, 115, 1, 7, 72, 62, 55, 5, 10, 74, 23, 45, 97, 10, 4, 2, 83, 5, 48, 21, 111, 9, 5, 63, 56, 44, 7, 5);
INSERT INTO public.match_details VALUES (339, 339, 64, 27, 28, 101, 15, 5, -4, 73, 6, 43, 27, 105, 9, 6, 50, 47, 33, 9, 8, 75, 26, 29, 101, 28, 6, -17, 86, 5, 45, 15, 116, 4, 9, 63, 54, 43, 6, 8);
INSERT INTO public.match_details VALUES (340, 340, 62, 16, 23, 92, 14, 2, -7, 75, 4, 57, 30, 113, 11, 10, 56, 49, 30, 4, 10, 68, 19, 37, 93, 18, 4, -11, 78, 2, 64, 29, 109, 7, 4, 54, 49, 39, 10, 9);
INSERT INTO public.match_details VALUES (341, 341, 69, 24, 36, 90, 14, 7, -5, 80, 5, 60, 32, 118, 6, 8, 53, 44, 33, 9, 9, 72, 26, 39, 92, 12, 5, -7, 76, 7, 51, 26, 111, 5, 9, 59, 53, 40, 8, 10);
INSERT INTO public.match_details VALUES (342, 342, 43, 14, 8, 58, 13, 8, -5, 62, 2, 46, 16, 76, 9, 11, 31, 40, 14, 4, 4, 52, 23, 27, 73, 11, 2, -8, 45, 8, 48, 13, 65, 2, 4, 39, 60, 50, 11, 4);
INSERT INTO public.match_details VALUES (343, 343, 59, 18, 17, 91, 19, 3, -15, 80, 8, 48, 25, 112, 4, 11, 48, 42, 29, 8, 8, 76, 31, 39, 98, 18, 8, -7, 72, 3, 45, 18, 101, 8, 8, 57, 56, 40, 11, 9);
INSERT INTO public.match_details VALUES (344, 344, 71, 34, 42, 95, 13, 10, -1, 67, 6, 49, 19, 103, 5, 5, 47, 45, 35, 14, 18, 64, 24, 18, 84, 17, 6, -5, 82, 10, 43, 21, 115, 5, 14, 53, 46, 29, 5, 22);
INSERT INTO public.match_details VALUES (345, 345, 56, 22, 15, 84, 15, 5, -3, 75, 5, 38, 16, 91, 9, 12, 43, 47, 24, 8, 5, 67, 25, 31, 93, 18, 5, -7, 69, 5, 40, 18, 88, 5, 8, 50, 56, 42, 12, 9);
INSERT INTO public.match_details VALUES (346, 346, 48, 13, 15, 66, 12, 2, -12, 66, 6, 33, 24, 88, 4, 11, 42, 47, 30, 4, 3, 63, 25, 40, 79, 13, 6, -5, 54, 2, 46, 25, 78, 4, 4, 46, 58, 48, 11, 4);
INSERT INTO public.match_details VALUES (347, 347, 67, 25, 37, 92, 13, 4, -6, 70, 4, 48, 30, 104, 5, 8, 54, 51, 39, 9, 18, 64, 24, 25, 89, 19, 4, -15, 79, 4, 53, 24, 109, 7, 9, 52, 47, 33, 8, 8);
INSERT INTO public.match_details VALUES (348, 348, 81, 26, 43, 113, 18, 13, -1, 87, 10, 43, 19, 101, 4, 6, 64, 63, 53, 4, 9, 84, 28, 36, 110, 23, 10, -8, 95, 13, 48, 22, 114, 8, 4, 68, 59, 49, 6, 9);
INSERT INTO public.match_details VALUES (349, 349, 64, 26, 32, 83, 14, 5, -6, 63, 1, 50, 22, 105, 8, 9, 49, 46, 30, 10, 15, 48, 17, 15, 77, 14, 1, -11, 69, 5, 39, 15, 98, 4, 10, 38, 38, 24, 9, 8);
INSERT INTO public.match_details VALUES (350, 350, 75, 26, 42, 99, 14, 3, -10, 76, 4, 50, 19, 119, 8, 7, 63, 52, 40, 9, 15, 65, 20, 28, 88, 12, 4, -7, 85, 3, 55, 29, 127, 13, 9, 54, 42, 25, 7, 8);
INSERT INTO public.match_details VALUES (351, 351, 75, 27, 24, 103, 18, 5, -8, 86, 6, 47, 17, 116, 11, 16, 59, 50, 27, 11, 10, 71, 25, 30, 104, 18, 6, -7, 85, 5, 57, 24, 100, 7, 11, 49, 49, 31, 16, 7);
INSERT INTO public.match_details VALUES (352, 352, 69, 27, 35, 92, 13, 5, -2, 67, 9, 55, 28, 97, 6, 6, 56, 57, 45, 8, 8, 60, 20, 24, 82, 15, 9, -7, 79, 5, 50, 22, 102, 8, 8, 45, 44, 28, 6, 3);
INSERT INTO public.match_details VALUES (353, 353, 54, 28, 31, 73, 9, 8, 6, 41, 4, 60, 21, 62, 1, 9, 35, 56, 40, 11, 10, 42, 14, 5, 55, 14, 4, -18, 64, 8, 34, 12, 66, 4, 11, 29, 43, 21, 9, 5);
INSERT INTO public.match_details VALUES (354, 354, 77, 28, 31, 106, 24, 12, -4, 79, 3, 53, 20, 111, 10, 9, 55, 49, 32, 10, 9, 60, 18, 10, 95, 16, 3, -12, 82, 12, 42, 19, 107, 12, 10, 48, 44, 24, 9, 11);
INSERT INTO public.match_details VALUES (355, 355, 77, 27, 25, 103, 17, 9, -2, 94, 10, 40, 19, 134, 10, 15, 58, 43, 24, 10, 16, 84, 31, 44, 111, 17, 10, -1, 86, 9, 39, 11, 120, 4, 10, 59, 49, 37, 15, 18);
INSERT INTO public.match_details VALUES (356, 356, 61, 20, 19, 82, 16, 10, -7, 85, 4, 50, 22, 100, 9, 13, 43, 43, 21, 8, 14, 69, 30, 35, 96, 11, 4, 1, 66, 10, 50, 21, 84, 5, 8, 52, 61, 46, 13, 14);
INSERT INTO public.match_details VALUES (357, 357, 52, 21, 28, 74, 13, 2, -8, 47, 0, 44, 25, 81, 3, 8, 38, 46, 33, 12, 8, 40, 9, 5, 61, 14, 0, -21, 61, 2, 54, 16, 81, 7, 12, 32, 39, 16, 8, 12);
INSERT INTO public.match_details VALUES (358, 358, 76, 24, 37, 101, 18, 9, -7, 88, 6, 48, 21, 111, 12, 3, 60, 54, 40, 7, 16, 69, 20, 30, 99, 11, 6, -1, 83, 9, 45, 22, 125, 12, 7, 60, 48, 32, 3, 5);
INSERT INTO public.match_details VALUES (359, 359, 67, 28, 31, 95, 14, 8, 0, 71, 8, 52, 29, 92, 5, 9, 51, 55, 40, 8, 10, 71, 28, 27, 92, 21, 8, -9, 81, 8, 50, 17, 100, 7, 8, 54, 54, 39, 9, 8);
INSERT INTO public.match_details VALUES (360, 360, 78, 32, 32, 107, 23, 10, -11, 88, 10, 43, 23, 116, 8, 5, 57, 49, 37, 11, 14, 72, 30, 24, 107, 19, 10, -5, 84, 10, 41, 19, 120, 8, 11, 57, 47, 31, 5, 11);
INSERT INTO public.match_details VALUES (361, 361, 41, 16, 7, 70, 11, 5, -2, 59, 11, 30, 13, 81, 4, 8, 29, 35, 20, 7, 10, 56, 23, 25, 73, 14, 11, 4, 59, 5, 33, 13, 88, 5, 7, 37, 42, 28, 8, 9);
INSERT INTO public.match_details VALUES (362, 362, 46, 14, 17, 62, 13, 5, -11, 62, 8, 46, 25, 77, 6, 2, 35, 45, 35, 6, 3, 51, 21, 26, 74, 12, 8, -1, 49, 5, 57, 28, 75, 2, 6, 41, 54, 44, 2, 9);
INSERT INTO public.match_details VALUES (363, 363, 74, 25, 23, 104, 16, 6, -1, 95, 11, 47, 26, 137, 12, 12, 61, 44, 27, 7, 15, 82, 32, 42, 110, 15, 11, 2, 88, 6, 51, 22, 129, 12, 7, 59, 45, 31, 12, 22);
INSERT INTO public.match_details VALUES (364, 364, 57, 29, 38, 74, 13, 3, -8, 40, 3, 60, 40, 67, 2, 1, 44, 65, 61, 10, 10, 32, 8, 3, 52, 12, 3, -11, 61, 3, 50, 18, 71, 4, 10, 28, 39, 19, 1, 4);
INSERT INTO public.match_details VALUES (365, 365, 66, 25, 26, 101, 15, 7, -5, 83, 4, 55, 27, 114, 11, 10, 47, 41, 22, 12, 10, 74, 27, 26, 103, 20, 4, -13, 86, 7, 44, 15, 120, 9, 12, 60, 50, 32, 10, 11);
INSERT INTO public.match_details VALUES (366, 366, 43, 10, 11, 61, 17, 2, -22, 61, 2, 70, 18, 71, 6, 7, 35, 49, 30, 6, 2, 51, 21, 28, 73, 12, 2, -10, 44, 2, 70, 20, 63, 3, 6, 42, 66, 52, 7, 7);
INSERT INTO public.match_details VALUES (367, 367, 71, 22, 30, 101, 23, 7, -11, 81, 7, 58, 27, 109, 5, 6, 54, 49, 39, 10, 6, 76, 26, 31, 105, 24, 7, -13, 78, 7, 57, 14, 119, 4, 10, 63, 52, 41, 6, 2);
INSERT INTO public.match_details VALUES (368, 368, 89, 25, 43, 113, 20, 7, -7, 104, 3, 34, 14, 149, 7, 16, 70, 46, 31, 12, 18, 90, 30, 48, 119, 15, 3, -5, 93, 7, 37, 20, 146, 8, 12, 71, 48, 34, 16, 21);
INSERT INTO public.match_details VALUES (369, 369, 76, 27, 21, 104, 20, 8, -8, 92, 11, 36, 18, 119, 10, 14, 57, 47, 27, 11, 11, 79, 31, 33, 109, 17, 11, 0, 84, 8, 41, 17, 111, 10, 11, 54, 48, 29, 14, 6);
INSERT INTO public.match_details VALUES (370, 370, 66, 25, 28, 89, 14, 4, -8, 72, 7, 43, 15, 95, 9, 8, 49, 51, 33, 13, 13, 63, 24, 23, 90, 18, 7, -6, 75, 4, 50, 21, 106, 5, 13, 48, 45, 28, 8, 9);
INSERT INTO public.match_details VALUES (371, 371, 38, 10, 8, 55, 10, 3, -9, 63, 10, 33, 12, 70, 3, 7, 33, 47, 32, 2, 4, 59, 28, 40, 74, 11, 10, 2, 45, 3, 42, 17, 68, 3, 2, 42, 61, 54, 7, 10);
INSERT INTO public.match_details VALUES (372, 372, 55, 15, 14, 75, 16, 3, -10, 79, 4, 44, 15, 107, 12, 9, 44, 41, 21, 8, 15, 65, 27, 32, 95, 16, 4, -8, 64, 3, 43, 14, 110, 6, 8, 52, 47, 34, 9, 7);
INSERT INTO public.match_details VALUES (373, 373, 73, 20, 30, 99, 19, 3, -12, 93, 9, 46, 22, 135, 6, 9, 62, 45, 34, 8, 21, 81, 33, 47, 107, 14, 9, -1, 80, 3, 42, 20, 135, 9, 8, 63, 46, 34, 9, 27);
INSERT INTO public.match_details VALUES (374, 374, 57, 23, 37, 73, 9, 5, -1, 48, 2, 47, 20, 71, 5, 4, 45, 63, 50, 7, 9, 43, 8, 15, 61, 13, 2, -14, 64, 5, 62, 28, 73, 3, 7, 37, 50, 36, 4, 5);
INSERT INTO public.match_details VALUES (375, 375, 68, 22, 22, 89, 19, 6, -12, 84, 8, 40, 14, 96, 9, 10, 48, 50, 30, 14, 9, 68, 30, 29, 96, 12, 8, 0, 70, 6, 44, 18, 95, 7, 14, 50, 52, 30, 10, 9);
INSERT INTO public.match_details VALUES (376, 376, 38, 12, 4, 57, 11, 2, -14, 64, 8, 45, 21, 75, 4, 11, 33, 44, 24, 3, 4, 59, 29, 40, 74, 10, 8, 6, 46, 2, 65, 41, 80, 4, 3, 40, 50, 41, 11, 6);
INSERT INTO public.match_details VALUES (377, 377, 36, 6, 5, 51, 9, 2, -9, 64, 7, 42, 21, 78, 4, 11, 33, 42, 23, 1, 2, 61, 28, 44, 74, 10, 7, 1, 42, 2, 54, 26, 69, 4, 1, 43, 62, 55, 11, 9);
INSERT INTO public.match_details VALUES (378, 378, 80, 28, 36, 108, 17, 5, -2, 87, 5, 41, 19, 135, 11, 11, 65, 48, 31, 10, 18, 71, 28, 32, 102, 15, 5, -5, 91, 5, 46, 23, 125, 9, 10, 55, 44, 28, 11, 16);
INSERT INTO public.match_details VALUES (379, 379, 45, 22, 17, 73, 16, 4, -12, 42, 3, 40, 33, 63, 2, 7, 36, 57, 42, 5, 9, 41, 13, 3, 63, 21, 3, -17, 57, 4, 50, 22, 75, 8, 5, 31, 41, 24, 7, 4);
INSERT INTO public.match_details VALUES (380, 380, 64, 24, 30, 91, 14, 2, -7, 77, 5, 45, 25, 102, 6, 9, 51, 50, 35, 11, 7, 69, 27, 34, 93, 16, 5, -7, 77, 2, 49, 15, 110, 6, 11, 55, 50, 34, 9, 9);
INSERT INTO public.match_details VALUES (381, 381, 56, 18, 25, 79, 9, 5, -3, 72, 4, 47, 13, 100, 8, 10, 46, 46, 28, 5, 10, 70, 24, 40, 90, 18, 4, -12, 70, 5, 57, 20, 99, 2, 5, 56, 56, 49, 10, 11);
INSERT INTO public.match_details VALUES (382, 382, 49, 13, 20, 66, 11, 3, -12, 63, 8, 47, 15, 86, 4, 6, 44, 51, 39, 2, 10, 60, 21, 43, 73, 10, 8, 4, 55, 3, 56, 18, 88, 2, 2, 46, 52, 47, 6, 6);
INSERT INTO public.match_details VALUES (383, 383, 54, 26, 28, 73, 14, 10, -4, 50, 1, 46, 26, 89, 5, 6, 34, 38, 25, 10, 9, 41, 16, 2, 63, 13, 1, -17, 59, 10, 44, 20, 77, 6, 10, 34, 44, 23, 6, 10);
INSERT INTO public.match_details VALUES (384, 384, 65, 26, 34, 102, 14, 7, -3, 79, 4, 44, 17, 119, 3, 10, 53, 44, 33, 5, 11, 86, 32, 38, 104, 25, 4, -12, 88, 7, 32, 12, 129, 11, 5, 72, 55, 43, 10, 17);
INSERT INTO public.match_details VALUES (385, 385, 61, 22, 19, 83, 17, 4, -13, 85, 8, 43, 15, 102, 5, 12, 48, 47, 30, 9, 5, 73, 34, 43, 98, 13, 8, -2, 66, 4, 50, 19, 92, 4, 9, 53, 57, 43, 12, 10);
INSERT INTO public.match_details VALUES (386, 386, 73, 30, 30, 108, 18, 6, -7, 77, 8, 48, 28, 110, 9, 8, 51, 46, 30, 16, 16, 69, 23, 13, 101, 24, 8, -13, 90, 6, 46, 21, 128, 10, 16, 53, 41, 21, 8, 14);
INSERT INTO public.match_details VALUES (387, 387, 68, 24, 38, 94, 15, 6, -2, 74, 2, 54, 10, 114, 6, 7, 54, 47, 35, 8, 17, 67, 19, 29, 91, 17, 2, -14, 79, 6, 44, 17, 116, 7, 8, 58, 50, 37, 7, 15);
INSERT INTO public.match_details VALUES (388, 388, 62, 16, 37, 86, 15, 3, -8, 71, 4, 43, 25, 91, 2, 4, 49, 53, 47, 10, 8, 65, 21, 27, 84, 13, 4, -4, 71, 3, 38, 16, 103, 12, 10, 57, 55, 33, 4, 5);
INSERT INTO public.match_details VALUES (389, 389, 87, 28, 45, 118, 19, 4, -7, 91, 7, 47, 24, 156, 8, 8, 76, 48, 38, 7, 14, 84, 25, 44, 113, 22, 7, -7, 99, 4, 41, 23, 139, 7, 7, 69, 49, 39, 8, 17);
INSERT INTO public.match_details VALUES (390, 390, 70, 26, 35, 97, 18, 5, -9, 67, 6, 41, 13, 95, 7, 4, 54, 56, 45, 11, 8, 56, 13, 16, 84, 17, 6, -13, 79, 5, 53, 24, 92, 7, 11, 46, 50, 30, 4, 7);
INSERT INTO public.match_details VALUES (391, 391, 75, 26, 37, 103, 14, 1, -10, 82, 4, 58, 35, 127, 13, 7, 60, 47, 31, 14, 15, 74, 20, 33, 103, 21, 4, -14, 89, 1, 67, 41, 124, 5, 14, 63, 50, 35, 7, 8);
INSERT INTO public.match_details VALUES (392, 392, 60, 19, 23, 80, 11, 11, 3, 80, 10, 45, 30, 96, 4, 12, 43, 44, 28, 6, 7, 76, 32, 41, 94, 14, 10, 2, 69, 11, 37, 24, 98, 4, 6, 54, 55, 44, 12, 4);
INSERT INTO public.match_details VALUES (393, 393, 62, 24, 34, 75, 13, 9, -2, 60, 2, 46, 28, 89, 7, 6, 47, 52, 38, 6, 11, 47, 13, 17, 70, 10, 2, -8, 62, 9, 43, 20, 87, 5, 6, 39, 44, 32, 6, 13);
INSERT INTO public.match_details VALUES (394, 394, 69, 22, 36, 95, 14, 8, -3, 73, 4, 61, 42, 101, 7, 8, 53, 52, 37, 8, 8, 65, 15, 26, 90, 17, 4, -11, 81, 8, 41, 14, 104, 6, 8, 53, 50, 37, 8, 4);
INSERT INTO public.match_details VALUES (395, 395, 38, 8, 13, 56, 10, 3, -10, 62, 2, 54, 24, 69, 7, 6, 29, 42, 23, 6, 1, 56, 24, 32, 74, 12, 2, -9, 46, 3, 50, 28, 73, 3, 6, 48, 65, 53, 6, 9);
INSERT INTO public.match_details VALUES (396, 396, 80, 27, 44, 98, 15, 7, -5, 78, 6, 51, 20, 118, 6, 9, 71, 60, 47, 2, 13, 70, 19, 42, 94, 16, 6, -7, 83, 7, 48, 21, 107, 3, 2, 55, 51, 46, 9, 14);
INSERT INTO public.match_details VALUES (397, 397, 39, 11, 8, 59, 14, 3, -15, 65, 3, 47, 20, 84, 8, 6, 35, 41, 25, 1, 5, 51, 21, 30, 74, 9, 3, -5, 45, 3, 48, 26, 77, 8, 1, 42, 54, 42, 6, 4);
INSERT INTO public.match_details VALUES (398, 398, 65, 31, 16, 102, 23, 7, -10, 74, 9, 36, 8, 103, 7, 10, 43, 41, 25, 15, 7, 67, 27, 7, 102, 28, 9, -16, 79, 7, 45, 24, 106, 10, 15, 48, 45, 21, 10, 15);
INSERT INTO public.match_details VALUES (399, 399, 64, 20, 29, 92, 15, 9, -3, 73, 7, 54, 21, 91, 5, 8, 47, 51, 37, 8, 10, 73, 25, 30, 93, 20, 7, -8, 77, 9, 42, 15, 105, 6, 8, 58, 55, 41, 8, 4);
INSERT INTO public.match_details VALUES (400, 400, 79, 27, 38, 103, 21, 7, -10, 92, 4, 43, 18, 136, 8, 8, 59, 43, 31, 13, 13, 75, 30, 37, 105, 13, 4, -5, 82, 7, 37, 14, 116, 5, 13, 63, 54, 38, 8, 16);
INSERT INTO public.match_details VALUES (401, 401, 88, 36, 36, 107, 21, 9, -1, 89, 16, 38, 15, 99, 8, 7, 67, 67, 52, 12, 8, 73, 32, 34, 105, 16, 16, 4, 86, 9, 31, 13, 88, 2, 12, 50, 56, 40, 7, 5);
INSERT INTO public.match_details VALUES (402, 402, 44, 14, 9, 68, 17, 0, -20, 59, 10, 44, 18, 73, 6, 2, 40, 54, 43, 4, 16, 50, 22, 27, 73, 14, 10, 2, 51, 0, 45, 17, 86, 5, 4, 38, 44, 33, 2, 8);
INSERT INTO public.match_details VALUES (403, 403, 45, 11, 10, 67, 10, 2, -10, 67, 8, 44, 26, 85, 5, 12, 39, 45, 25, 4, 14, 59, 23, 36, 79, 12, 8, -1, 57, 2, 56, 28, 82, 5, 4, 39, 47, 36, 12, 4);
INSERT INTO public.match_details VALUES (404, 404, 76, 31, 40, 92, 12, 7, -2, 77, 6, 55, 24, 104, 5, 13, 53, 50, 33, 16, 8, 70, 26, 32, 88, 11, 6, -2, 80, 7, 52, 26, 105, 4, 16, 51, 48, 29, 13, 9);
INSERT INTO public.match_details VALUES (405, 405, 78, 37, 45, 100, 16, 9, -2, 64, 5, 43, 18, 112, 5, 7, 58, 51, 41, 11, 17, 55, 17, 13, 77, 13, 5, -7, 84, 9, 39, 17, 104, 9, 11, 43, 41, 22, 7, 5);
INSERT INTO public.match_details VALUES (406, 406, 59, 22, 23, 78, 13, 10, 5, 57, 2, 45, 15, 90, 9, 12, 43, 47, 24, 6, 10, 44, 12, 8, 69, 12, 2, -13, 65, 10, 41, 15, 74, 8, 6, 30, 40, 21, 12, 7);
INSERT INTO public.match_details VALUES (407, 407, 38, 8, 1, 52, 11, 2, -15, 66, 7, 43, 25, 81, 10, 9, 29, 35, 12, 7, 4, 53, 24, 32, 73, 7, 7, 6, 41, 2, 51, 31, 80, 5, 7, 37, 46, 31, 9, 4);
INSERT INTO public.match_details VALUES (408, 408, 72, 24, 31, 107, 16, 9, -2, 91, 4, 49, 24, 115, 10, 11, 52, 45, 26, 11, 13, 81, 24, 31, 109, 18, 4, -7, 91, 9, 59, 31, 130, 12, 11, 66, 50, 33, 11, 17);
INSERT INTO public.match_details VALUES (409, 409, 60, 20, 35, 73, 16, 6, -12, 53, 2, 47, 11, 76, 4, 3, 51, 67, 57, 3, 12, 37, 9, 14, 62, 9, 2, -9, 57, 6, 54, 19, 69, 5, 3, 32, 46, 34, 3, 2);
INSERT INTO public.match_details VALUES (410, 410, 64, 17, 26, 85, 15, 4, -9, 80, 3, 55, 21, 113, 9, 11, 56, 49, 31, 4, 11, 72, 23, 45, 95, 15, 3, -9, 70, 4, 55, 24, 95, 4, 4, 58, 61, 52, 11, 11);
INSERT INTO public.match_details VALUES (411, 411, 64, 19, 22, 92, 19, 7, -11, 81, 5, 48, 22, 106, 8, 10, 53, 50, 33, 4, 7, 69, 23, 34, 97, 16, 5, -3, 73, 7, 49, 13, 94, 8, 4, 54, 57, 44, 10, 11);
INSERT INTO public.match_details VALUES (412, 412, 70, 20, 25, 97, 15, 4, -6, 93, 4, 55, 25, 122, 7, 19, 54, 44, 22, 12, 9, 82, 33, 39, 105, 12, 4, -3, 82, 4, 48, 19, 122, 15, 12, 59, 48, 26, 19, 10);
INSERT INTO public.match_details VALUES (413, 413, 70, 22, 30, 96, 23, 7, -16, 64, 4, 50, 15, 89, 6, 7, 56, 62, 48, 7, 8, 54, 12, 14, 87, 23, 4, -19, 73, 7, 52, 20, 90, 3, 7, 43, 47, 36, 7, 8);
INSERT INTO public.match_details VALUES (414, 414, 71, 23, 30, 107, 15, 9, -1, 90, 7, 54, 18, 113, 6, 13, 55, 48, 31, 7, 4, 91, 32, 40, 114, 24, 7, -10, 92, 9, 48, 13, 124, 11, 7, 71, 57, 42, 13, 9);
INSERT INTO public.match_details VALUES (415, 415, 55, 20, 36, 74, 11, 5, 1, 49, 1, 40, 22, 67, 5, 2, 43, 64, 53, 7, 5, 43, 7, 14, 61, 12, 1, -14, 63, 5, 49, 25, 70, 5, 7, 40, 57, 40, 2, 5);
INSERT INTO public.match_details VALUES (416, 416, 61, 31, 40, 73, 10, 7, 2, 49, 4, 38, 16, 74, 3, 4, 45, 60, 51, 9, 8, 40, 14, 10, 55, 6, 4, 0, 63, 7, 46, 22, 79, 8, 9, 32, 40, 18, 4, 11);
INSERT INTO public.match_details VALUES (417, 417, 71, 28, 20, 104, 21, 9, -3, 85, 11, 45, 23, 107, 10, 9, 54, 50, 32, 8, 5, 72, 27, 24, 106, 21, 11, -5, 83, 9, 45, 26, 100, 10, 8, 52, 52, 34, 9, 7);
INSERT INTO public.match_details VALUES (418, 418, 72, 25, 35, 103, 14, 4, -3, 89, 8, 43, 17, 111, 5, 10, 54, 48, 35, 14, 6, 84, 32, 39, 107, 18, 8, -3, 89, 4, 42, 11, 126, 9, 14, 66, 52, 34, 10, 11);
INSERT INTO public.match_details VALUES (419, 419, 45, 10, 11, 53, 10, 1, -13, 68, 10, 47, 20, 74, 5, 9, 38, 51, 32, 6, 0, 60, 29, 47, 73, 5, 10, 13, 43, 1, 32, 16, 70, 1, 6, 41, 58, 48, 9, 1);
INSERT INTO public.match_details VALUES (420, 420, 66, 28, 34, 91, 12, 6, -3, 63, 9, 52, 30, 91, 7, 4, 50, 54, 42, 10, 6, 59, 17, 18, 79, 16, 9, -7, 79, 6, 40, 27, 95, 9, 10, 46, 48, 28, 4, 9);
INSERT INTO public.match_details VALUES (421, 421, 62, 16, 25, 88, 20, 7, -11, 78, 5, 60, 21, 108, 4, 8, 50, 46, 35, 5, 9, 70, 27, 35, 94, 16, 5, -10, 68, 7, 54, 27, 106, 7, 5, 57, 53, 42, 8, 7);
INSERT INTO public.match_details VALUES (422, 422, 56, 22, 28, 73, 15, 5, -8, 51, 2, 66, 35, 79, 3, 8, 45, 56, 43, 6, 12, 43, 14, 13, 64, 13, 2, -17, 58, 5, 41, 18, 72, 6, 6, 33, 45, 29, 8, 10);
INSERT INTO public.match_details VALUES (423, 423, 58, 16, 15, 90, 17, 3, -14, 78, 6, 38, 15, 100, 11, 9, 44, 44, 24, 11, 8, 69, 26, 26, 98, 20, 6, -11, 73, 3, 46, 23, 109, 9, 11, 54, 49, 31, 9, 10);
INSERT INTO public.match_details VALUES (424, 424, 70, 28, 43, 95, 13, 8, -2, 72, 3, 51, 29, 107, 4, 7, 58, 54, 43, 4, 10, 67, 21, 32, 86, 14, 3, -11, 82, 8, 45, 23, 103, 9, 4, 57, 55, 42, 7, 10);
INSERT INTO public.match_details VALUES (425, 425, 78, 35, 38, 107, 15, 4, -8, 83, 5, 55, 27, 128, 12, 8, 60, 46, 31, 14, 18, 77, 27, 30, 108, 25, 5, -14, 92, 4, 58, 19, 145, 4, 14, 64, 44, 31, 8, 14);
INSERT INTO public.match_details VALUES (426, 426, 43, 14, 11, 59, 12, 7, 0, 64, 3, 51, 29, 95, 7, 10, 31, 32, 14, 5, 5, 55, 24, 29, 74, 10, 3, -4, 47, 7, 38, 23, 73, 4, 5, 42, 57, 45, 10, 14);
INSERT INTO public.match_details VALUES (427, 427, 59, 26, 15, 85, 19, 7, -7, 71, 12, 43, 16, 93, 5, 8, 42, 45, 31, 10, 13, 63, 31, 21, 88, 17, 12, 1, 66, 7, 37, 13, 94, 8, 10, 43, 45, 26, 8, 11);
INSERT INTO public.match_details VALUES (428, 428, 41, 13, 2, 65, 18, 5, -15, 57, 8, 49, 24, 67, 2, 11, 32, 47, 28, 4, 8, 53, 25, 23, 73, 16, 8, -8, 47, 5, 42, 12, 68, 5, 4, 34, 50, 36, 11, 13);
INSERT INTO public.match_details VALUES (429, 429, 52, 23, 30, 74, 10, 8, 5, 45, 5, 35, 15, 65, 4, 3, 35, 53, 43, 9, 4, 45, 12, 5, 61, 16, 5, -14, 64, 8, 43, 18, 72, 7, 9, 37, 51, 29, 3, 5);
INSERT INTO public.match_details VALUES (430, 430, 75, 29, 36, 99, 16, 7, -1, 84, 9, 46, 20, 114, 7, 7, 60, 52, 40, 8, 13, 74, 32, 36, 100, 16, 9, -4, 83, 7, 45, 20, 104, 7, 8, 58, 55, 41, 7, 12);
INSERT INTO public.match_details VALUES (431, 431, 46, 23, 21, 73, 7, 3, -1, 48, 5, 52, 33, 71, 9, 4, 37, 52, 33, 6, 10, 46, 14, 10, 65, 17, 5, -16, 66, 3, 50, 22, 85, 10, 6, 37, 43, 24, 4, 5);
INSERT INTO public.match_details VALUES (432, 432, 81, 25, 29, 109, 28, 6, -17, 87, 8, 55, 28, 111, 4, 12, 66, 59, 45, 9, 19, 72, 26, 29, 106, 19, 8, -4, 81, 6, 46, 27, 113, 9, 9, 52, 46, 30, 12, 11);
INSERT INTO public.match_details VALUES (433, 433, 72, 24, 24, 101, 18, 3, -10, 84, 8, 45, 26, 122, 11, 11, 58, 47, 29, 11, 14, 77, 27, 35, 106, 22, 8, -7, 83, 3, 51, 26, 121, 6, 11, 58, 47, 33, 11, 8);
INSERT INTO public.match_details VALUES (434, 434, 63, 22, 25, 89, 13, 4, -7, 76, 9, 40, 18, 96, 8, 8, 48, 50, 33, 11, 14, 68, 23, 31, 90, 14, 9, 2, 76, 4, 53, 25, 110, 8, 11, 51, 46, 29, 8, 7);
INSERT INTO public.match_details VALUES (435, 435, 66, 24, 20, 98, 21, 7, -12, 76, 11, 46, 21, 109, 7, 7, 47, 43, 30, 12, 13, 62, 21, 15, 93, 17, 11, -6, 77, 7, 49, 18, 105, 11, 12, 44, 41, 20, 7, 13);
INSERT INTO public.match_details VALUES (436, 436, 86, 33, 44, 108, 25, 12, -5, 85, 3, 42, 16, 110, 8, 6, 66, 60, 47, 8, 15, 62, 23, 21, 97, 12, 3, -2, 83, 12, 43, 14, 101, 9, 8, 53, 52, 35, 6, 9);
INSERT INTO public.match_details VALUES (437, 437, 66, 23, 31, 92, 14, 5, -6, 70, 8, 44, 14, 99, 6, 7, 51, 51, 38, 10, 17, 67, 20, 29, 87, 17, 8, -8, 78, 5, 53, 16, 107, 6, 10, 52, 48, 33, 7, 6);
INSERT INTO public.match_details VALUES (438, 438, 50, 13, 19, 63, 13, 2, -12, 66, 5, 54, 25, 80, 7, 6, 41, 51, 35, 7, 4, 55, 21, 35, 74, 8, 5, -1, 50, 2, 46, 24, 75, 3, 7, 44, 58, 45, 6, 5);
INSERT INTO public.match_details VALUES (439, 439, 71, 28, 32, 96, 16, 4, -8, 72, 6, 55, 26, 109, 4, 13, 54, 49, 33, 13, 17, 67, 25, 24, 90, 18, 6, -11, 80, 4, 52, 23, 118, 8, 13, 48, 40, 22, 13, 15);
INSERT INTO public.match_details VALUES (440, 440, 52, 15, 13, 75, 18, 4, -17, 68, 4, 39, 22, 95, 7, 10, 41, 43, 25, 7, 1, 58, 22, 26, 84, 16, 4, -10, 57, 4, 49, 31, 90, 5, 7, 44, 48, 35, 10, 5);
INSERT INTO public.match_details VALUES (441, 441, 80, 27, 47, 100, 21, 8, -10, 79, 3, 59, 18, 113, 3, 6, 65, 57, 49, 7, 11, 60, 18, 28, 87, 8, 3, -3, 79, 8, 50, 13, 112, 9, 7, 51, 45, 31, 6, 10);
INSERT INTO public.match_details VALUES (442, 442, 70, 27, 35, 107, 15, 3, -8, 76, 5, 42, 25, 109, 6, 9, 52, 47, 33, 15, 12, 77, 22, 24, 104, 28, 5, -19, 92, 3, 46, 20, 136, 7, 15, 63, 46, 30, 9, 13);
INSERT INTO public.match_details VALUES (443, 443, 73, 23, 38, 97, 17, 1, -14, 78, 3, 56, 17, 107, 8, 7, 59, 55, 41, 13, 14, 65, 20, 28, 93, 15, 3, -6, 80, 1, 51, 25, 117, 8, 13, 55, 47, 29, 7, 5);
INSERT INTO public.match_details VALUES (444, 444, 81, 35, 40, 118, 20, 5, -9, 81, 4, 50, 25, 123, 2, 15, 63, 51, 37, 13, 10, 80, 29, 31, 104, 23, 4, -11, 98, 5, 43, 28, 132, 8, 13, 61, 46, 30, 15, 14);
INSERT INTO public.match_details VALUES (445, 445, 56, 21, 28, 74, 17, 4, -10, 50, 4, 42, 14, 74, 2, 5, 46, 62, 52, 6, 4, 37, 10, 11, 57, 7, 4, -1, 57, 4, 50, 21, 71, 9, 6, 28, 39, 18, 5, 4);
INSERT INTO public.match_details VALUES (446, 446, 73, 33, 40, 89, 20, 6, -11, 59, 1, 59, 30, 100, 7, 5, 58, 57, 46, 9, 14, 39, 11, 8, 70, 11, 1, -12, 69, 6, 49, 14, 96, 5, 9, 33, 34, 19, 5, 10);
INSERT INTO public.match_details VALUES (447, 447, 35, 6, -1, 50, 12, 0, -22, 63, 7, 42, 15, 74, 9, 8, 30, 40, 17, 5, 5, 49, 23, 32, 73, 10, 7, 1, 38, 0, 47, 15, 67, 2, 5, 34, 50, 40, 8, 7);
INSERT INTO public.match_details VALUES (448, 448, 62, 17, 17, 84, 16, 5, -11, 86, 8, 50, 23, 118, 12, 9, 52, 44, 26, 5, 11, 66, 26, 36, 95, 9, 8, 1, 68, 5, 61, 38, 98, 11, 5, 49, 50, 33, 9, 14);
INSERT INTO public.match_details VALUES (449, 449, 70, 20, 30, 100, 21, 4, -14, 80, 4, 36, 20, 115, 8, 7, 59, 51, 38, 7, 9, 71, 20, 33, 100, 20, 4, -11, 79, 4, 48, 30, 113, 7, 7, 60, 53, 40, 7, 11);
INSERT INTO public.match_details VALUES (450, 450, 73, 26, 37, 108, 11, 6, 0, 85, 9, 43, 9, 121, 7, 9, 60, 49, 36, 7, 17, 85, 30, 39, 104, 19, 9, -4, 97, 6, 40, 13, 136, 14, 7, 67, 49, 33, 9, 17);
INSERT INTO public.match_details VALUES (451, 451, 78, 26, 26, 113, 23, 6, -10, 91, 7, 61, 31, 130, 13, 9, 59, 45, 28, 13, 20, 78, 24, 23, 116, 25, 7, -12, 90, 6, 51, 15, 131, 11, 13, 62, 47, 29, 9, 14);
INSERT INTO public.match_details VALUES (452, 452, 72, 28, 31, 107, 26, 8, -14, 76, 5, 47, 19, 103, 3, 7, 55, 53, 43, 9, 10, 68, 27, 17, 101, 25, 5, -16, 81, 8, 59, 32, 110, 9, 9, 56, 50, 34, 7, 17);
INSERT INTO public.match_details VALUES (453, 453, 47, 12, 19, 67, 9, 3, -7, 66, 5, 56, 18, 85, 4, 10, 38, 44, 28, 6, 5, 62, 24, 37, 75, 9, 5, -4, 58, 3, 48, 22, 90, 7, 6, 47, 52, 37, 10, 12);
INSERT INTO public.match_details VALUES (454, 454, 36, 12, -1, 52, 12, 7, -9, 60, 7, 50, 26, 68, 8, 10, 24, 35, 8, 5, 0, 54, 27, 27, 74, 14, 7, -5, 40, 7, 37, 7, 56, 1, 5, 37, 66, 55, 10, 9);
INSERT INTO public.match_details VALUES (455, 455, 53, 27, 33, 74, 11, 10, 5, 41, 6, 53, 21, 63, 0, 3, 35, 55, 50, 8, 15, 44, 13, 5, 56, 15, 6, -12, 63, 10, 26, 9, 79, 6, 8, 35, 44, 26, 3, 5);
INSERT INTO public.match_details VALUES (456, 456, 79, 22, 36, 99, 18, 4, -9, 91, 6, 49, 24, 116, 9, 10, 67, 57, 41, 8, 11, 76, 27, 47, 101, 10, 6, 4, 81, 4, 43, 29, 111, 7, 8, 60, 54, 40, 10, 5);
INSERT INTO public.match_details VALUES (457, 457, 72, 22, 35, 102, 16, 3, -11, 85, 4, 52, 18, 112, 8, 9, 56, 50, 34, 13, 10, 83, 25, 40, 107, 22, 4, -15, 86, 3, 53, 19, 116, 5, 13, 70, 60, 44, 9, 12);
INSERT INTO public.match_details VALUES (458, 458, 52, 23, 28, 73, 12, 2, -6, 45, 3, 57, 22, 73, 4, 5, 41, 56, 43, 9, 3, 37, 9, 4, 60, 15, 3, -20, 61, 2, 50, 21, 83, 7, 9, 29, 34, 15, 5, 4);
INSERT INTO public.match_details VALUES (459, 459, 81, 23, 37, 108, 25, 8, -13, 87, 5, 52, 16, 123, 5, 9, 69, 56, 44, 4, 11, 67, 19, 33, 101, 14, 5, -4, 83, 8, 38, 16, 108, 8, 4, 53, 49, 37, 9, 8);
INSERT INTO public.match_details VALUES (460, 460, 54, 15, 21, 71, 14, 4, -9, 67, 4, 58, 23, 94, 7, 8, 43, 45, 29, 7, 11, 58, 21, 32, 78, 11, 4, -5, 57, 4, 56, 17, 89, 4, 7, 46, 51, 39, 8, 7);
INSERT INTO public.match_details VALUES (461, 461, 88, 37, 52, 114, 14, 9, 0, 83, 7, 57, 26, 128, 8, 7, 67, 52, 40, 12, 15, 77, 25, 32, 101, 18, 7, -8, 100, 9, 39, 12, 123, 6, 12, 63, 51, 36, 7, 11);
INSERT INTO public.match_details VALUES (462, 462, 64, 19, 19, 87, 20, 8, -12, 81, 11, 46, 24, 101, 5, 9, 51, 50, 36, 5, 10, 71, 28, 37, 97, 16, 11, -2, 67, 8, 56, 32, 94, 5, 5, 51, 54, 43, 9, 12);
INSERT INTO public.match_details VALUES (463, 463, 50, 17, 8, 77, 14, 6, -7, 76, 9, 40, 23, 96, 7, 12, 36, 37, 17, 8, 11, 73, 38, 33, 96, 20, 9, -8, 63, 6, 46, 14, 105, 6, 8, 52, 49, 36, 12, 16);
INSERT INTO public.match_details VALUES (464, 464, 65, 25, 31, 90, 20, 9, -10, 61, 3, 54, 24, 84, 2, 9, 45, 53, 40, 11, 7, 53, 16, 10, 77, 16, 3, -15, 70, 9, 45, 20, 83, 7, 11, 41, 49, 27, 9, 9);
INSERT INTO public.match_details VALUES (465, 465, 47, 12, 17, 57, 14, 3, -14, 66, 3, 56, 28, 81, 5, 8, 42, 51, 35, 2, 5, 54, 24, 41, 74, 8, 3, -2, 43, 3, 51, 20, 67, 0, 2, 43, 64, 61, 8, 9);
INSERT INTO public.match_details VALUES (466, 466, 63, 20, 20, 90, 21, 5, -14, 88, 4, 50, 25, 123, 10, 8, 53, 43, 28, 5, 13, 73, 34, 39, 106, 18, 4, -8, 69, 5, 59, 27, 109, 6, 5, 61, 55, 45, 8, 14);
INSERT INTO public.match_details VALUES (467, 467, 82, 34, 37, 113, 16, 9, 0, 79, 8, 65, 29, 129, 10, 11, 63, 48, 32, 10, 5, 73, 22, 26, 99, 20, 8, -10, 97, 9, 39, 8, 124, 8, 10, 54, 43, 29, 11, 14);
INSERT INTO public.match_details VALUES (468, 468, 73, 26, 22, 106, 18, 4, -6, 93, 9, 47, 24, 127, 11, 13, 62, 48, 29, 7, 14, 83, 31, 42, 116, 23, 9, -11, 88, 4, 46, 25, 108, 7, 7, 61, 56, 43, 13, 12);
INSERT INTO public.match_details VALUES (469, 469, 68, 23, 18, 91, 18, 9, -3, 78, 4, 55, 24, 121, 13, 15, 54, 44, 21, 5, 10, 61, 22, 26, 93, 15, 4, -10, 73, 9, 43, 19, 89, 6, 5, 42, 47, 34, 15, 10);
INSERT INTO public.match_details VALUES (470, 470, 61, 25, 43, 74, 5, 5, 5, 51, 2, 56, 25, 83, 5, 6, 51, 61, 48, 5, 6, 49, 14, 27, 61, 10, 2, -11, 69, 5, 43, 21, 86, 2, 5, 41, 47, 39, 6, 12);
INSERT INTO public.match_details VALUES (471, 471, 42, 13, 18, 65, 9, 1, -9, 58, 4, 44, 25, 83, 4, 7, 36, 43, 30, 5, 11, 58, 20, 32, 73, 15, 4, -9, 56, 1, 41, 19, 89, 5, 5, 47, 52, 41, 7, 8);
INSERT INTO public.match_details VALUES (472, 472, 75, 21, 30, 103, 22, 4, -15, 90, 5, 48, 16, 118, 8, 10, 62, 52, 37, 9, 11, 80, 29, 43, 109, 19, 5, -8, 81, 4, 54, 19, 117, 5, 9, 65, 55, 43, 10, 11);
INSERT INTO public.match_details VALUES (473, 473, 73, 27, 37, 101, 17, 4, -11, 75, 7, 45, 22, 108, 6, 6, 55, 50, 39, 14, 10, 64, 23, 21, 93, 18, 7, -10, 84, 4, 51, 27, 120, 7, 14, 51, 42, 25, 6, 8);
INSERT INTO public.match_details VALUES (474, 474, 80, 27, 42, 101, 18, 1, -14, 72, 5, 52, 22, 106, 3, 12, 66, 62, 48, 13, 21, 65, 18, 30, 87, 15, 5, -9, 83, 1, 59, 24, 110, 6, 13, 48, 43, 26, 12, 13);
INSERT INTO public.match_details VALUES (475, 475, 54, 21, 35, 74, 14, 10, 0, 41, 1, 63, 26, 63, 1, 3, 39, 61, 55, 5, 5, 42, 7, 8, 58, 17, 1, -24, 60, 10, 50, 23, 60, 2, 5, 38, 63, 51, 3, 4);
INSERT INTO public.match_details VALUES (476, 476, 80, 21, 40, 104, 22, 10, -8, 95, 3, 60, 22, 120, 9, 6, 67, 55, 43, 3, 13, 74, 21, 43, 107, 12, 3, -3, 82, 10, 56, 25, 106, 6, 3, 65, 61, 52, 6, 8);
INSERT INTO public.match_details VALUES (477, 477, 50, 13, 21, 66, 9, 4, -6, 65, 4, 41, 23, 92, 4, 12, 41, 44, 27, 5, 5, 61, 23, 40, 73, 8, 4, 0, 57, 4, 43, 28, 87, 4, 5, 45, 51, 41, 12, 10);
INSERT INTO public.match_details VALUES (478, 478, 53, 24, 40, 74, 9, 4, 0, 32, 1, 59, 15, 59, 1, 2, 42, 71, 66, 7, 10, 31, 2, 4, 44, 12, 1, -22, 65, 4, 33, 9, 64, 4, 7, 28, 43, 26, 2, 4);
INSERT INTO public.match_details VALUES (479, 479, 75, 23, 22, 108, 24, 5, -14, 88, 5, 48, 27, 122, 5, 19, 66, 54, 34, 4, 14, 77, 26, 40, 107, 19, 5, -10, 84, 5, 46, 22, 105, 9, 4, 53, 50, 38, 19, 8);
INSERT INTO public.match_details VALUES (480, 480, 82, 29, 56, 108, 10, 5, 0, 77, 4, 51, 27, 117, 5, 7, 70, 59, 49, 7, 8, 75, 16, 37, 92, 15, 4, -10, 98, 5, 50, 19, 120, 11, 7, 64, 53, 38, 7, 7);
INSERT INTO public.match_details VALUES (481, 481, 78, 20, 38, 107, 16, 5, -3, 95, 8, 51, 18, 117, 9, 7, 67, 57, 43, 6, 13, 86, 26, 47, 112, 17, 8, 0, 91, 5, 52, 27, 118, 11, 6, 71, 60, 45, 7, 10);
INSERT INTO public.match_details VALUES (482, 482, 74, 30, 30, 103, 18, 7, -10, 83, 7, 38, 19, 101, 7, 12, 55, 54, 35, 12, 9, 74, 27, 27, 104, 21, 7, -8, 85, 7, 61, 21, 116, 7, 12, 55, 47, 31, 12, 8);
INSERT INTO public.match_details VALUES (483, 483, 54, 19, 29, 74, 11, 3, -8, 49, 3, 48, 20, 71, 4, 7, 40, 56, 40, 11, 7, 45, 11, 12, 64, 15, 3, -15, 63, 3, 36, 12, 80, 4, 11, 35, 43, 25, 7, 6);
INSERT INTO public.match_details VALUES (484, 484, 43, 12, 13, 63, 10, 2, -4, 61, 6, 40, 18, 83, 8, 6, 35, 42, 25, 6, 5, 52, 17, 27, 73, 12, 6, -5, 53, 2, 43, 15, 83, 5, 6, 40, 48, 34, 6, 9);
INSERT INTO public.match_details VALUES (485, 485, 49, 12, 17, 68, 11, 2, -4, 62, 1, 56, 20, 92, 6, 14, 44, 47, 26, 3, 8, 56, 21, 33, 77, 15, 1, -14, 57, 2, 42, 19, 75, 3, 3, 41, 54, 46, 14, 11);
INSERT INTO public.match_details VALUES (486, 486, 61, 24, 27, 91, 16, 5, -6, 59, 5, 45, 28, 101, 8, 5, 47, 46, 33, 9, 11, 55, 14, 11, 81, 22, 5, -19, 75, 5, 44, 22, 110, 8, 9, 45, 40, 25, 5, 8);
INSERT INTO public.match_details VALUES (487, 487, 63, 22, 27, 91, 16, 5, -7, 79, 4, 53, 27, 99, 10, 6, 48, 48, 32, 10, 10, 70, 25, 31, 99, 20, 4, -10, 75, 5, 44, 18, 108, 4, 10, 60, 55, 42, 6, 14);
INSERT INTO public.match_details VALUES (488, 488, 44, 13, 8, 67, 15, 3, -16, 61, 8, 42, 24, 71, 8, 5, 35, 49, 30, 6, 5, 53, 20, 24, 76, 15, 8, -9, 52, 3, 53, 23, 73, 5, 6, 40, 54, 39, 5, 7);
INSERT INTO public.match_details VALUES (489, 489, 58, 27, 28, 75, 18, 8, -5, 51, 1, 58, 23, 79, 7, 4, 48, 60, 46, 2, 10, 38, 12, 10, 66, 15, 1, -16, 57, 8, 35, 14, 60, 3, 2, 33, 55, 46, 4, 9);
INSERT INTO public.match_details VALUES (490, 490, 63, 22, 17, 84, 21, 3, -17, 88, 6, 45, 18, 109, 11, 8, 48, 44, 26, 12, 9, 63, 28, 31, 97, 9, 6, 4, 63, 3, 49, 28, 101, 9, 11, 49, 48, 28, 8, 11);
INSERT INTO public.match_details VALUES (491, 491, 73, 26, 33, 107, 15, 8, -4, 82, 5, 62, 37, 116, 7, 13, 52, 44, 27, 13, 12, 73, 26, 18, 100, 18, 5, -12, 92, 8, 43, 20, 119, 16, 13, 55, 46, 21, 13, 10);
INSERT INTO public.match_details VALUES (492, 492, 57, 22, 36, 74, 14, 6, -6, 45, 0, 66, 51, 72, 5, 2, 45, 62, 52, 6, 3, 37, 5, 7, 58, 13, 0, -18, 60, 6, 58, 30, 69, 5, 6, 35, 50, 34, 2, 4);
INSERT INTO public.match_details VALUES (493, 493, 46, 10, 15, 67, 13, 3, -10, 60, 2, 46, 30, 80, 8, 8, 42, 52, 32, 1, 5, 52, 16, 33, 73, 13, 2, -10, 54, 3, 46, 12, 70, 2, 1, 42, 60, 55, 8, 9);
INSERT INTO public.match_details VALUES (494, 494, 72, 25, 40, 92, 14, 2, -7, 80, 7, 51, 26, 105, 3, 8, 55, 52, 41, 15, 9, 71, 29, 39, 92, 12, 7, -2, 78, 2, 51, 19, 111, 3, 15, 56, 50, 34, 8, 10);
INSERT INTO public.match_details VALUES (495, 495, 58, 24, 33, 75, 13, 7, -5, 51, 4, 56, 31, 79, 4, 4, 47, 59, 49, 4, 10, 47, 14, 18, 66, 15, 4, -15, 62, 7, 62, 29, 76, 3, 4, 39, 51, 42, 4, 5);
INSERT INTO public.match_details VALUES (496, 496, 66, 17, 37, 90, 6, 5, 0, 82, 6, 51, 23, 124, 8, 9, 58, 46, 33, 3, 5, 79, 25, 50, 96, 14, 6, -4, 84, 5, 52, 21, 114, 7, 3, 64, 56, 47, 9, 5);
INSERT INTO public.match_details VALUES (497, 497, 71, 26, 34, 95, 22, 6, -13, 78, 5, 50, 25, 99, 6, 4, 52, 52, 42, 13, 5, 59, 20, 16, 92, 14, 5, -7, 73, 6, 52, 32, 108, 10, 13, 50, 46, 25, 4, 16);
INSERT INTO public.match_details VALUES (498, 498, 63, 20, 23, 89, 20, 4, -13, 74, 3, 50, 25, 108, 8, 9, 50, 46, 30, 9, 12, 61, 18, 26, 92, 18, 3, -15, 69, 4, 52, 17, 104, 4, 9, 49, 47, 34, 9, 18);
INSERT INTO public.match_details VALUES (499, 499, 44, 10, 13, 68, 17, 4, -16, 58, 4, 50, 20, 75, 3, 7, 36, 48, 34, 4, 8, 54, 18, 25, 74, 16, 4, -12, 51, 4, 58, 25, 75, 5, 4, 43, 57, 45, 7, 5);
INSERT INTO public.match_details VALUES (500, 500, 66, 27, 41, 95, 15, 1, -10, 53, 2, 64, 26, 84, 3, 5, 47, 55, 46, 18, 9, 53, 9, 11, 74, 21, 2, -22, 80, 1, 53, 25, 109, 2, 18, 46, 42, 23, 5, 6);
INSERT INTO public.match_details VALUES (501, 501, 53, 24, 26, 73, 14, 6, -5, 48, 9, 50, 25, 60, 3, 1, 38, 63, 56, 9, 5, 41, 13, 6, 62, 14, 9, -3, 59, 6, 54, 30, 71, 6, 9, 31, 43, 22, 1, 6);
INSERT INTO public.match_details VALUES (502, 502, 61, 23, 34, 82, 15, 5, -4, 55, 5, 50, 20, 84, 2, 5, 50, 59, 51, 6, 12, 48, 12, 19, 70, 15, 5, -11, 67, 5, 52, 17, 82, 3, 6, 38, 46, 35, 5, 7);
INSERT INTO public.match_details VALUES (503, 503, 53, 22, 27, 75, 14, 7, -5, 50, 2, 46, 20, 75, 4, 6, 41, 54, 41, 5, 9, 41, 11, 10, 60, 10, 2, -11, 61, 7, 52, 22, 73, 9, 5, 33, 45, 26, 6, 4);
INSERT INTO public.match_details VALUES (504, 504, 71, 25, 43, 92, 14, 6, -5, 78, 2, 46, 26, 111, 8, 4, 58, 52, 41, 7, 11, 64, 21, 32, 91, 13, 2, -10, 78, 6, 52, 24, 113, 6, 7, 58, 51, 39, 4, 9);
INSERT INTO public.match_details VALUES (505, 505, 51, 11, 24, 73, 8, 3, -4, 66, 8, 54, 27, 88, 4, 7, 46, 52, 39, 2, 11, 70, 23, 45, 82, 16, 8, -7, 65, 3, 47, 21, 93, 4, 2, 55, 59, 52, 7, 9);
INSERT INTO public.match_details VALUES (506, 506, 61, 14, 23, 87, 16, 4, -11, 74, 4, 54, 20, 100, 4, 14, 48, 48, 30, 9, 4, 74, 24, 37, 94, 20, 4, -13, 71, 4, 61, 19, 97, 4, 9, 56, 57, 44, 14, 2);
INSERT INTO public.match_details VALUES (507, 507, 34, 4, -4, 51, 15, 0, -19, 64, 3, 50, 18, 90, 3, 17, 32, 35, 13, 2, 7, 57, 33, 42, 74, 10, 3, -4, 36, 0, 63, 41, 67, 3, 2, 37, 55, 47, 17, 5);
INSERT INTO public.match_details VALUES (508, 508, 58, 17, 14, 83, 15, 4, -9, 80, 17, 37, 17, 83, 5, 7, 46, 55, 40, 8, 11, 77, 32, 43, 97, 17, 17, 2, 68, 4, 47, 16, 88, 5, 8, 53, 60, 45, 7, 8);
INSERT INTO public.match_details VALUES (509, 509, 52, 22, 32, 73, 10, 7, 2, 49, 1, 61, 28, 86, 4, 5, 44, 51, 40, 1, 6, 40, 15, 11, 58, 9, 1, -12, 63, 7, 47, 17, 78, 12, 1, 34, 43, 26, 5, 7);
INSERT INTO public.match_details VALUES (510, 510, 60, 20, 14, 94, 19, 3, -13, 78, 6, 48, 12, 97, 7, 14, 44, 45, 23, 13, 13, 74, 32, 27, 100, 22, 6, -13, 75, 3, 52, 16, 113, 9, 13, 54, 47, 28, 14, 9);
INSERT INTO public.match_details VALUES (511, 511, 73, 26, 36, 89, 15, 9, -4, 86, 6, 41, 18, 105, 9, 7, 53, 50, 35, 11, 8, 62, 24, 29, 93, 7, 6, 5, 74, 9, 47, 22, 99, 6, 11, 49, 49, 32, 7, 15);
INSERT INTO public.match_details VALUES (512, 512, 81, 35, 39, 105, 16, 6, -7, 83, 10, 40, 25, 116, 6, 10, 66, 56, 43, 9, 16, 78, 30, 40, 101, 18, 10, -3, 89, 6, 46, 25, 126, 5, 9, 58, 46, 34, 10, 9);
INSERT INTO public.match_details VALUES (513, 513, 42, 13, 8, 60, 14, 3, -13, 63, 5, 52, 20, 82, 8, 7, 31, 37, 19, 8, 7, 52, 24, 27, 74, 11, 5, -1, 46, 3, 56, 19, 75, 3, 8, 40, 53, 38, 7, 11);
INSERT INTO public.match_details VALUES (514, 514, 64, 32, 44, 74, 6, 7, 8, 49, 7, 44, 26, 74, 1, 6, 47, 63, 54, 10, 10, 48, 14, 21, 58, 9, 7, 1, 68, 7, 33, 23, 75, 1, 10, 35, 46, 32, 6, 5);
INSERT INTO public.match_details VALUES (515, 515, 56, 24, 33, 74, 15, 4, -6, 47, 4, 57, 25, 75, 2, 2, 39, 52, 46, 13, 0, 41, 15, 8, 59, 12, 4, -10, 59, 4, 49, 15, 71, 4, 13, 35, 49, 25, 2, 0);
INSERT INTO public.match_details VALUES (516, 516, 70, 25, 38, 95, 14, 6, -4, 78, 1, 47, 28, 120, 5, 12, 52, 43, 29, 12, 12, 70, 24, 28, 91, 13, 1, -7, 81, 6, 39, 18, 139, 11, 12, 57, 41, 24, 12, 20);
INSERT INTO public.match_details VALUES (517, 517, 73, 26, 40, 94, 18, 9, -3, 72, 3, 51, 30, 105, 6, 6, 54, 51, 40, 10, 9, 61, 18, 22, 87, 15, 3, -9, 76, 9, 46, 18, 100, 5, 10, 52, 52, 37, 6, 18);
INSERT INTO public.match_details VALUES (518, 518, 68, 21, 26, 98, 17, 7, -8, 88, 6, 47, 12, 120, 10, 9, 56, 46, 30, 5, 12, 74, 25, 34, 104, 16, 6, -2, 81, 7, 46, 29, 109, 12, 5, 59, 54, 38, 9, 10);
INSERT INTO public.match_details VALUES (519, 519, 54, 16, 11, 87, 17, 5, -6, 70, 9, 50, 25, 93, 11, 6, 41, 44, 25, 8, 7, 61, 18, 18, 92, 22, 9, -10, 70, 5, 57, 22, 97, 8, 8, 46, 47, 30, 6, 3);
INSERT INTO public.match_details VALUES (520, 520, 62, 26, 38, 76, 15, 7, -5, 49, 3, 51, 32, 74, 4, 2, 46, 62, 54, 9, 13, 38, 8, 8, 60, 11, 3, -8, 61, 7, 47, 9, 77, 3, 9, 33, 42, 27, 2, 7);
INSERT INTO public.match_details VALUES (521, 521, 80, 21, 31, 108, 30, 5, -22, 95, 6, 63, 36, 131, 5, 8, 68, 51, 41, 7, 11, 75, 27, 38, 111, 16, 6, -6, 78, 5, 65, 30, 114, 9, 7, 61, 53, 39, 8, 13);
INSERT INTO public.match_details VALUES (522, 522, 57, 13, 26, 79, 6, 2, -3, 85, 4, 52, 12, 109, 7, 14, 49, 44, 25, 6, 10, 78, 27, 51, 97, 12, 4, -5, 73, 2, 46, 13, 116, 7, 6, 60, 51, 40, 14, 14);
INSERT INTO public.match_details VALUES (523, 523, 70, 24, 45, 94, 12, 9, -1, 73, 4, 38, 10, 93, 4, 5, 52, 55, 46, 9, 10, 71, 19, 31, 90, 17, 4, -11, 82, 9, 46, 26, 108, 5, 9, 62, 57, 44, 5, 12);
INSERT INTO public.match_details VALUES (524, 524, 80, 31, 31, 107, 20, 7, -9, 90, 5, 48, 21, 123, 10, 14, 62, 50, 30, 11, 15, 71, 27, 31, 105, 15, 5, -9, 87, 7, 43, 10, 108, 7, 11, 52, 48, 31, 14, 11);
INSERT INTO public.match_details VALUES (525, 525, 59, 16, 17, 77, 15, 2, -12, 85, 5, 43, 22, 112, 8, 14, 50, 44, 25, 7, 9, 73, 33, 51, 95, 10, 5, 0, 62, 2, 66, 35, 98, 3, 7, 54, 55, 44, 14, 5);
INSERT INTO public.match_details VALUES (526, 526, 44, 11, 12, 62, 18, 2, -24, 63, 7, 60, 20, 85, 6, 1, 41, 48, 40, 1, 17, 49, 22, 31, 74, 11, 7, -2, 44, 2, 50, 22, 80, 4, 1, 41, 51, 45, 1, 13);
INSERT INTO public.match_details VALUES (527, 527, 75, 30, 28, 94, 17, 8, -3, 89, 10, 39, 17, 126, 11, 9, 53, 42, 26, 14, 15, 72, 32, 32, 103, 14, 10, 2, 77, 8, 37, 22, 123, 4, 14, 53, 43, 28, 9, 6);
INSERT INTO public.match_details VALUES (528, 528, 73, 35, 41, 98, 15, 11, 2, 64, 3, 48, 28, 98, 10, 4, 53, 54, 39, 9, 5, 50, 13, 8, 78, 14, 3, -11, 83, 11, 38, 16, 98, 8, 9, 43, 43, 26, 4, 9);
INSERT INTO public.match_details VALUES (529, 529, 67, 27, 38, 84, 18, 7, -4, 60, 1, 53, 21, 95, 2, 8, 47, 49, 38, 13, 8, 43, 14, 6, 70, 10, 1, -10, 66, 7, 45, 19, 81, 7, 13, 34, 41, 17, 8, 11);
INSERT INTO public.match_details VALUES (530, 530, 77, 25, 49, 96, 14, 3, -9, 74, 2, 63, 28, 118, 7, 5, 62, 52, 42, 12, 11, 61, 13, 29, 83, 9, 2, -8, 82, 3, 62, 30, 120, 8, 12, 54, 45, 28, 5, 7);
INSERT INTO public.match_details VALUES (531, 531, 68, 22, 31, 91, 14, 3, -9, 82, 12, 47, 25, 103, 6, 5, 57, 55, 44, 8, 11, 72, 26, 43, 97, 15, 12, 0, 77, 3, 49, 23, 103, 3, 8, 55, 53, 42, 5, 10);
INSERT INTO public.match_details VALUES (532, 532, 41, 9, 15, 54, 10, 4, -5, 66, 4, 50, 13, 80, 5, 7, 30, 37, 22, 7, 2, 60, 28, 39, 74, 8, 4, 1, 44, 4, 61, 29, 68, 2, 7, 49, 72, 58, 7, 11);
INSERT INTO public.match_details VALUES (533, 533, 69, 24, 30, 100, 19, 8, -7, 69, 6, 44, 26, 97, 4, 10, 57, 58, 44, 4, 10, 64, 18, 22, 89, 20, 6, -11, 81, 8, 41, 19, 104, 10, 4, 48, 46, 32, 10, 9);
INSERT INTO public.match_details VALUES (534, 534, 45, 15, 13, 68, 10, 1, -13, 59, 4, 52, 22, 72, 5, 13, 37, 51, 26, 7, 8, 59, 22, 33, 73, 14, 4, -9, 58, 1, 37, 13, 82, 4, 7, 42, 51, 37, 13, 6);
INSERT INTO public.match_details VALUES (535, 535, 51, 25, 19, 76, 16, 10, -1, 46, 5, 56, 23, 74, 6, 5, 33, 44, 29, 8, 7, 35, 17, -7, 60, 14, 5, -11, 60, 10, 40, 15, 74, 10, 8, 25, 33, 9, 5, 8);
INSERT INTO public.match_details VALUES (536, 536, 40, 9, 14, 58, 9, 2, -8, 60, 5, 46, 20, 69, 6, 6, 34, 49, 31, 4, 4, 57, 21, 35, 73, 13, 5, -4, 49, 2, 55, 28, 72, 3, 4, 46, 63, 54, 6, 7);
INSERT INTO public.match_details VALUES (537, 537, 56, 18, 19, 81, 17, 7, -6, 78, 5, 41, 14, 88, 6, 9, 44, 50, 32, 5, 13, 71, 28, 37, 97, 19, 5, -9, 64, 7, 48, 23, 92, 3, 5, 57, 61, 53, 9, 12);
INSERT INTO public.match_details VALUES (538, 538, 60, 24, 39, 73, 12, 9, -1, 46, 0, 67, 28, 70, 3, 6, 45, 64, 51, 6, 7, 37, 7, 7, 55, 9, 0, -14, 61, 9, 37, 22, 74, 6, 6, 31, 41, 25, 6, 5);
INSERT INTO public.match_details VALUES (539, 539, 57, 26, 34, 75, 9, 7, -1, 54, 4, 50, 18, 85, 6, 4, 40, 47, 35, 10, 13, 49, 14, 15, 66, 12, 4, -7, 66, 7, 56, 13, 90, 5, 10, 41, 45, 28, 4, 15);
INSERT INTO public.match_details VALUES (540, 540, 42, 8, 15, 62, 13, 3, -11, 60, 4, 51, 15, 75, 4, 6, 35, 46, 33, 4, 5, 56, 21, 33, 74, 14, 4, -12, 49, 3, 46, 22, 77, 2, 4, 46, 59, 51, 6, 15);
INSERT INTO public.match_details VALUES (541, 541, 66, 18, 19, 78, 17, 5, -10, 90, 7, 46, 27, 120, 14, 9, 55, 45, 26, 6, 7, 62, 27, 44, 94, 4, 7, 8, 61, 5, 44, 18, 93, 3, 6, 46, 49, 39, 9, 14);
INSERT INTO public.match_details VALUES (542, 542, 55, 22, 31, 74, 11, 5, -1, 53, 5, 41, 15, 80, 4, 4, 39, 48, 38, 11, 8, 45, 14, 12, 64, 11, 5, -3, 63, 5, 58, 39, 92, 6, 11, 36, 39, 20, 4, 8);
INSERT INTO public.match_details VALUES (543, 543, 73, 30, 35, 100, 17, 7, -2, 69, 2, 56, 23, 113, 11, 8, 58, 51, 34, 8, 14, 57, 15, 18, 89, 20, 2, -20, 83, 7, 43, 13, 106, 4, 8, 47, 44, 33, 8, 7);
INSERT INTO public.match_details VALUES (544, 544, 74, 25, 31, 100, 14, 5, -9, 76, 8, 48, 22, 115, 10, 11, 61, 53, 34, 8, 15, 68, 22, 30, 96, 20, 8, -9, 86, 5, 48, 24, 110, 5, 8, 49, 44, 32, 11, 6);
INSERT INTO public.match_details VALUES (545, 545, 56, 16, 23, 85, 11, 3, -8, 78, 6, 57, 21, 105, 8, 8, 49, 46, 31, 4, 8, 78, 30, 45, 96, 18, 6, -10, 74, 3, 60, 20, 114, 8, 4, 64, 56, 45, 8, 9);
INSERT INTO public.match_details VALUES (546, 546, 69, 35, 38, 101, 17, 14, 0, 63, 4, 46, 23, 78, 6, 4, 42, 53, 41, 13, 6, 53, 17, 0, 78, 15, 4, -6, 84, 14, 36, 17, 91, 11, 13, 45, 49, 23, 4, 9);
INSERT INTO public.match_details VALUES (547, 547, 38, 9, 10, 64, 11, 4, -9, 57, 6, 59, 29, 72, 6, 5, 32, 44, 29, 2, 9, 57, 17, 28, 74, 17, 6, -12, 53, 4, 62, 28, 78, 6, 2, 46, 58, 48, 5, 8);
INSERT INTO public.match_details VALUES (548, 548, 36, 13, -1, 57, 10, 1, -10, 58, 6, 29, 17, 76, 7, 14, 30, 39, 11, 5, 10, 57, 29, 31, 74, 16, 6, -8, 47, 1, 46, 27, 80, 4, 5, 37, 46, 35, 14, 6);
INSERT INTO public.match_details VALUES (549, 549, 66, 29, 34, 93, 12, 3, -4, 64, 9, 46, 25, 95, 8, 3, 47, 49, 37, 16, 21, 62, 17, 16, 83, 19, 9, -9, 81, 3, 43, 13, 111, 8, 16, 50, 45, 23, 3, 14);
INSERT INTO public.match_details VALUES (550, 550, 59, 21, 14, 90, 20, 6, -12, 74, 7, 47, 25, 97, 11, 7, 48, 49, 30, 5, 11, 60, 22, 24, 96, 22, 7, -13, 70, 6, 51, 21, 91, 3, 5, 46, 50, 41, 7, 6);
INSERT INTO public.match_details VALUES (551, 551, 83, 26, 49, 106, 15, 5, -2, 88, 3, 44, 15, 122, 5, 11, 62, 50, 37, 16, 11, 81, 27, 40, 101, 13, 3, -2, 91, 5, 46, 14, 126, 7, 16, 67, 53, 34, 11, 18);
INSERT INTO public.match_details VALUES (552, 552, 78, 21, 35, 99, 22, 5, -14, 94, 4, 61, 22, 143, 5, 12, 68, 47, 35, 5, 19, 77, 28, 50, 106, 12, 4, -3, 77, 5, 50, 19, 128, 5, 5, 61, 47, 39, 12, 17);
INSERT INTO public.match_details VALUES (553, 553, 90, 38, 50, 113, 18, 11, -2, 79, 4, 45, 22, 123, 10, 8, 69, 56, 41, 10, 18, 65, 19, 21, 96, 17, 4, -9, 95, 11, 47, 23, 120, 6, 10, 53, 44, 30, 8, 9);
INSERT INTO public.match_details VALUES (554, 554, 73, 24, 45, 97, 16, 6, -6, 62, 2, 61, 29, 93, 6, 4, 63, 67, 56, 4, 10, 55, 6, 22, 80, 18, 2, -20, 81, 6, 30, 7, 89, 5, 4, 49, 55, 44, 4, 7);
INSERT INTO public.match_details VALUES (555, 555, 79, 25, 34, 109, 19, 5, -8, 88, 4, 57, 27, 135, 11, 11, 62, 45, 29, 12, 9, 82, 26, 35, 113, 24, 4, -14, 90, 5, 47, 17, 128, 6, 12, 67, 52, 38, 11, 14);
INSERT INTO public.match_details VALUES (556, 556, 50, 23, 32, 73, 8, 5, -1, 50, 3, 46, 20, 71, 1, 6, 38, 53, 43, 7, 9, 54, 17, 18, 68, 18, 3, -16, 65, 5, 50, 16, 90, 6, 7, 45, 50, 35, 6, 5);
INSERT INTO public.match_details VALUES (557, 557, 65, 28, 36, 73, 15, 5, -9, 51, 5, 58, 19, 97, 4, 5, 52, 53, 44, 8, 14, 36, 11, 13, 57, 6, 5, 0, 58, 5, 60, 32, 85, 4, 8, 26, 30, 16, 5, 14);
INSERT INTO public.match_details VALUES (558, 558, 50, 17, 11, 76, 14, 7, -2, 65, 8, 43, 16, 85, 10, 7, 39, 45, 25, 4, 10, 56, 20, 23, 80, 15, 8, -2, 62, 7, 32, 11, 80, 7, 4, 41, 51, 37, 7, 8);
INSERT INTO public.match_details VALUES (559, 559, 68, 23, 24, 94, 18, 5, -10, 72, 9, 47, 16, 104, 7, 10, 53, 50, 34, 10, 10, 59, 20, 20, 86, 14, 9, -4, 76, 5, 50, 23, 100, 10, 10, 40, 40, 20, 10, 10);
INSERT INTO public.match_details VALUES (560, 560, 69, 31, 35, 95, 12, 10, 0, 67, 4, 44, 19, 102, 8, 10, 51, 50, 32, 8, 10, 61, 20, 19, 82, 15, 4, -9, 83, 10, 54, 26, 108, 9, 8, 47, 43, 27, 10, 4);
INSERT INTO public.match_details VALUES (561, 561, 71, 19, 32, 98, 21, 1, -17, 79, 1, 60, 24, 109, 9, 8, 56, 51, 35, 14, 12, 54, 17, 14, 91, 12, 1, -7, 77, 1, 61, 27, 107, 13, 14, 45, 42, 16, 8, 18);
INSERT INTO public.match_details VALUES (562, 562, 43, 12, 11, 65, 10, 1, -12, 62, 5, 58, 37, 92, 8, 9, 37, 40, 21, 5, 8, 53, 20, 29, 73, 11, 5, -5, 55, 1, 56, 29, 98, 7, 5, 39, 39, 27, 9, 11);
INSERT INTO public.match_details VALUES (563, 563, 54, 24, 32, 73, 12, 6, -2, 44, 4, 56, 27, 69, 4, 2, 41, 59, 50, 7, 5, 32, 10, 3, 54, 10, 4, -7, 61, 6, 40, 18, 78, 6, 7, 26, 33, 16, 2, 4);
INSERT INTO public.match_details VALUES (564, 564, 73, 23, 37, 96, 15, 9, -2, 87, 2, 57, 28, 130, 9, 10, 55, 42, 27, 9, 13, 73, 21, 38, 99, 12, 2, -7, 81, 9, 51, 24, 115, 5, 9, 61, 53, 40, 10, 18);
INSERT INTO public.match_details VALUES (565, 565, 69, 26, 32, 95, 20, 9, -7, 74, 4, 52, 20, 97, 4, 9, 49, 50, 37, 11, 12, 65, 24, 22, 92, 18, 4, -13, 75, 9, 52, 20, 97, 5, 11, 52, 53, 37, 9, 13);
INSERT INTO public.match_details VALUES (566, 566, 52, 18, 31, 74, 11, 5, -6, 50, 4, 50, 10, 63, 4, 2, 39, 61, 52, 8, 7, 49, 11, 12, 68, 18, 4, -19, 63, 5, 50, 12, 81, 6, 8, 43, 53, 35, 2, 5);
INSERT INTO public.match_details VALUES (567, 567, 62, 21, 21, 98, 16, 5, -8, 76, 11, 44, 18, 90, 8, 6, 47, 52, 36, 10, 20, 75, 25, 27, 101, 25, 11, -10, 82, 5, 52, 29, 116, 8, 10, 58, 50, 34, 6, 13);
INSERT INTO public.match_details VALUES (568, 568, 54, 22, 35, 74, 4, 5, 5, 50, 3, 44, 18, 77, 7, 5, 38, 49, 33, 11, 11, 47, 10, 13, 61, 11, 3, -9, 70, 5, 48, 21, 89, 7, 11, 39, 43, 23, 5, 7);
INSERT INTO public.match_details VALUES (569, 569, 41, 10, 10, 64, 12, 2, -7, 59, 4, 52, 13, 76, 4, 11, 38, 50, 30, 1, 9, 57, 20, 34, 74, 15, 4, -10, 52, 2, 50, 17, 71, 5, 1, 42, 59, 50, 11, 8);
INSERT INTO public.match_details VALUES (570, 570, 80, 26, 32, 108, 23, 6, -11, 98, 3, 60, 26, 134, 10, 12, 63, 47, 30, 11, 12, 79, 32, 40, 113, 15, 3, -7, 85, 6, 52, 22, 123, 7, 11, 64, 52, 37, 12, 17);
INSERT INTO public.match_details VALUES (571, 571, 48, 14, 16, 64, 17, 2, -20, 64, 3, 62, 32, 84, 4, 8, 42, 50, 35, 4, 9, 54, 25, 36, 75, 11, 3, -9, 47, 2, 57, 21, 76, 1, 4, 43, 56, 50, 8, 9);
INSERT INTO public.match_details VALUES (572, 572, 62, 23, 40, 80, 10, 6, 0, 62, 0, 64, 37, 89, 3, 9, 52, 58, 44, 4, 12, 59, 18, 29, 74, 12, 0, -10, 70, 6, 47, 18, 86, 8, 4, 50, 58, 44, 9, 6);
INSERT INTO public.match_details VALUES (573, 573, 71, 27, 38, 95, 14, 8, -4, 68, 5, 60, 25, 99, 7, 7, 57, 57, 43, 6, 18, 58, 15, 22, 80, 12, 5, -7, 81, 8, 56, 24, 99, 10, 6, 46, 46, 30, 7, 9);
INSERT INTO public.match_details VALUES (574, 574, 82, 33, 43, 107, 14, 3, -6, 88, 6, 60, 26, 145, 6, 13, 62, 42, 29, 17, 21, 81, 31, 39, 101, 13, 6, -2, 93, 3, 55, 25, 148, 9, 17, 62, 41, 24, 13, 21);
INSERT INTO public.match_details VALUES (575, 575, 69, 26, 39, 97, 15, 3, -7, 68, 3, 51, 23, 112, 8, 4, 62, 55, 44, 4, 12, 61, 14, 25, 87, 19, 3, -14, 82, 3, 54, 21, 116, 10, 4, 54, 46, 34, 4, 7);
INSERT INTO public.match_details VALUES (576, 576, 63, 25, 27, 98, 15, 10, -3, 66, 8, 74, 39, 94, 7, 6, 49, 52, 38, 4, 9, 64, 19, 17, 89, 23, 8, -16, 83, 10, 49, 22, 91, 10, 4, 50, 54, 39, 6, 7);
INSERT INTO public.match_details VALUES (577, 577, 42, 10, 13, 60, 13, 3, -16, 64, 0, 57, 25, 93, 6, 10, 36, 38, 21, 3, 10, 57, 25, 37, 75, 11, 0, -12, 47, 3, 42, 17, 83, 3, 3, 47, 56, 49, 10, 17);
INSERT INTO public.match_details VALUES (578, 578, 80, 31, 36, 104, 20, 6, -5, 83, 3, 57, 32, 134, 8, 13, 67, 50, 34, 7, 14, 71, 26, 34, 101, 18, 3, -11, 84, 6, 42, 16, 109, 6, 7, 55, 50, 38, 13, 14);
INSERT INTO public.match_details VALUES (579, 579, 78, 32, 33, 108, 22, 8, -8, 80, 2, 51, 27, 133, 11, 10, 61, 45, 30, 9, 14, 67, 20, 24, 101, 21, 2, -14, 86, 8, 47, 15, 117, 5, 9, 55, 47, 35, 10, 18);
INSERT INTO public.match_details VALUES (580, 580, 64, 22, 33, 92, 15, 5, -8, 64, 6, 50, 25, 92, 2, 8, 51, 55, 44, 8, 14, 65, 18, 26, 85, 21, 6, -16, 77, 5, 49, 20, 101, 5, 8, 51, 50, 37, 8, 4);
INSERT INTO public.match_details VALUES (581, 581, 68, 20, 20, 94, 20, 7, -10, 79, 10, 45, 18, 96, 5, 13, 52, 54, 35, 9, 9, 70, 27, 29, 98, 19, 10, -8, 74, 7, 45, 12, 93, 6, 9, 47, 50, 34, 13, 8);
INSERT INTO public.match_details VALUES (582, 582, 54, 17, 33, 75, 14, 2, -14, 49, 2, 69, 38, 77, 2, 3, 44, 57, 50, 8, 7, 46, 9, 15, 64, 15, 2, -17, 61, 2, 59, 27, 89, 6, 8, 41, 46, 30, 3, 6);
INSERT INTO public.match_details VALUES (583, 583, 55, 16, 21, 88, 14, 7, -3, 71, 4, 46, 28, 108, 4, 12, 46, 42, 27, 2, 13, 73, 25, 33, 93, 22, 4, -17, 74, 7, 47, 17, 95, 9, 2, 57, 60, 48, 12, 13);
INSERT INTO public.match_details VALUES (584, 584, 50, 23, 23, 73, 17, 6, -13, 37, 3, 67, 18, 60, 4, 3, 35, 58, 46, 9, 7, 34, 6, -6, 58, 21, 3, -31, 56, 6, 51, 19, 65, 4, 9, 28, 43, 23, 3, 5);
INSERT INTO public.match_details VALUES (585, 585, 57, 22, 35, 75, 12, 3, -8, 50, 1, 62, 32, 88, 3, 6, 49, 55, 45, 5, 10, 44, 10, 19, 63, 13, 1, -19, 63, 3, 57, 23, 86, 4, 5, 37, 43, 32, 6, 5);
INSERT INTO public.match_details VALUES (586, 586, 42, 8, 13, 62, 9, 0, -6, 61, 4, 49, 18, 85, 6, 10, 39, 45, 27, 3, 7, 58, 20, 36, 74, 13, 4, -9, 53, 0, 33, 11, 87, 6, 3, 44, 50, 40, 10, 4);
INSERT INTO public.match_details VALUES (587, 587, 82, 28, 28, 104, 27, 7, -14, 93, 6, 40, 16, 121, 10, 11, 62, 51, 33, 13, 12, 71, 27, 33, 108, 15, 6, -3, 77, 7, 38, 16, 99, 3, 13, 54, 54, 38, 11, 7);
INSERT INTO public.match_details VALUES (588, 588, 77, 35, 51, 99, 12, 9, 4, 64, 6, 51, 28, 105, 4, 4, 59, 56, 48, 9, 14, 65, 18, 25, 84, 20, 6, -14, 87, 9, 55, 25, 109, 2, 9, 55, 50, 40, 4, 14);
INSERT INTO public.match_details VALUES (589, 589, 67, 29, 35, 79, 13, 5, -6, 62, 9, 51, 19, 90, 5, 5, 55, 61, 50, 7, 11, 50, 20, 25, 72, 10, 9, 1, 66, 5, 57, 21, 80, 3, 7, 36, 45, 32, 5, 6);
INSERT INTO public.match_details VALUES (590, 590, 77, 31, 41, 99, 14, 6, -3, 80, 5, 52, 20, 120, 7, 10, 61, 50, 36, 10, 14, 72, 24, 35, 97, 17, 5, -10, 85, 6, 31, 14, 116, 4, 10, 57, 49, 37, 10, 16);
INSERT INTO public.match_details VALUES (591, 591, 38, 6, 5, 55, 9, 0, -14, 66, 4, 62, 24, 97, 7, 13, 35, 36, 15, 3, 6, 59, 25, 41, 76, 10, 4, -7, 46, 0, 69, 28, 77, 5, 3, 42, 54, 44, 13, 11);
INSERT INTO public.match_details VALUES (592, 592, 53, 14, 19, 79, 14, 2, -8, 72, 6, 54, 29, 97, 9, 5, 45, 46, 31, 6, 9, 61, 19, 30, 88, 16, 6, -9, 65, 2, 53, 27, 96, 7, 6, 50, 52, 38, 5, 8);
INSERT INTO public.match_details VALUES (593, 593, 52, 16, 4, 82, 21, 4, -18, 76, 7, 44, 23, 100, 9, 11, 43, 43, 23, 5, 8, 64, 30, 30, 94, 18, 7, -8, 61, 4, 50, 31, 88, 7, 5, 46, 52, 38, 11, 15);
INSERT INTO public.match_details VALUES (594, 594, 42, 15, 5, 62, 12, 4, -9, 60, 4, 40, 13, 73, 7, 14, 30, 41, 12, 8, 7, 53, 23, 25, 73, 13, 4, -6, 50, 4, 42, 18, 72, 3, 8, 35, 48, 33, 14, 7);
INSERT INTO public.match_details VALUES (595, 595, 81, 31, 35, 109, 23, 5, -9, 90, 7, 47, 31, 133, 6, 10, 68, 51, 39, 8, 18, 77, 32, 38, 108, 18, 7, -7, 86, 5, 32, 11, 127, 8, 8, 60, 47, 34, 10, 20);
INSERT INTO public.match_details VALUES (596, 596, 70, 26, 45, 92, 11, 6, 2, 66, 0, 56, 21, 105, 7, 7, 57, 54, 40, 7, 10, 62, 14, 27, 81, 15, 0, -13, 81, 6, 49, 20, 98, 7, 7, 55, 56, 41, 7, 11);
INSERT INTO public.match_details VALUES (597, 597, 89, 27, 39, 112, 25, 2, -19, 99, 5, 54, 26, 149, 11, 9, 72, 48, 34, 15, 18, 76, 25, 38, 115, 16, 5, -6, 87, 2, 62, 17, 140, 5, 15, 62, 44, 30, 9, 19);
INSERT INTO public.match_details VALUES (598, 598, 51, 22, 26, 74, 12, 7, 2, 42, 2, 61, 35, 67, 5, 6, 37, 55, 38, 7, 11, 39, 8, 2, 58, 16, 2, -22, 62, 7, 43, 17, 68, 7, 7, 31, 45, 25, 6, 5);
INSERT INTO public.match_details VALUES (599, 599, 55, 23, 27, 76, 17, 5, -13, 56, 5, 55, 37, 74, 5, 1, 41, 55, 47, 9, 10, 46, 16, 11, 69, 13, 5, -5, 59, 5, 54, 27, 84, 8, 9, 40, 47, 27, 1, 6);
INSERT INTO public.match_details VALUES (600, 600, 83, 26, 44, 100, 15, 7, -4, 93, 5, 38, 12, 125, 8, 11, 66, 52, 37, 10, 10, 78, 28, 43, 102, 9, 5, 0, 85, 7, 48, 17, 128, 9, 10, 62, 48, 33, 11, 12);
INSERT INTO public.match_details VALUES (601, 601, 70, 23, 28, 102, 20, 7, -10, 84, 4, 58, 32, 112, 10, 8, 56, 50, 33, 7, 9, 68, 24, 25, 103, 19, 4, -8, 82, 7, 53, 28, 115, 10, 7, 56, 48, 33, 8, 9);
INSERT INTO public.match_details VALUES (602, 602, 77, 29, 40, 110, 16, 9, -2, 83, 5, 63, 27, 117, 7, 9, 59, 50, 36, 9, 10, 76, 25, 28, 103, 20, 5, -11, 94, 9, 40, 17, 121, 10, 9, 62, 51, 35, 9, 10);
INSERT INTO public.match_details VALUES (603, 603, 44, 11, 21, 60, 13, 3, -13, 60, 5, 51, 31, 71, 1, 4, 37, 52, 45, 4, 6, 61, 26, 40, 73, 13, 5, -8, 47, 3, 55, 25, 75, 1, 4, 52, 69, 62, 4, 14);
INSERT INTO public.match_details VALUES (604, 604, 55, 14, 22, 85, 16, 5, -10, 79, 4, 68, 32, 107, 7, 6, 44, 41, 28, 6, 7, 70, 26, 31, 96, 17, 4, -10, 69, 5, 60, 28, 109, 11, 6, 60, 55, 39, 6, 18);
INSERT INTO public.match_details VALUES (605, 605, 58, 14, 15, 94, 22, 2, -17, 73, 5, 50, 19, 104, 6, 10, 50, 48, 32, 6, 9, 69, 21, 29, 98, 25, 5, -20, 72, 2, 63, 26, 103, 7, 6, 54, 52, 39, 10, 12);
INSERT INTO public.match_details VALUES (606, 606, 75, 21, 24, 106, 21, 2, -16, 90, 4, 58, 25, 129, 9, 17, 63, 48, 28, 10, 13, 83, 28, 43, 113, 23, 4, -15, 85, 2, 58, 28, 118, 5, 10, 62, 52, 39, 17, 13);
INSERT INTO public.match_details VALUES (607, 607, 51, 27, 31, 73, 12, 6, -4, 44, 3, 54, 25, 75, 3, 2, 35, 46, 40, 10, 6, 43, 14, 5, 61, 17, 3, -19, 61, 6, 49, 16, 85, 5, 10, 38, 44, 27, 2, 8);
INSERT INTO public.match_details VALUES (608, 608, 67, 20, 32, 101, 10, 3, -2, 78, 5, 47, 14, 119, 8, 12, 56, 47, 30, 8, 13, 78, 20, 38, 99, 21, 5, -13, 91, 3, 49, 20, 120, 8, 8, 61, 50, 37, 12, 9);
INSERT INTO public.match_details VALUES (609, 609, 70, 17, 33, 95, 22, 3, -18, 76, 0, 60, 32, 116, 8, 7, 58, 50, 37, 9, 8, 60, 14, 23, 92, 16, 0, -14, 73, 3, 49, 24, 114, 9, 9, 53, 46, 30, 7, 15);
INSERT INTO public.match_details VALUES (610, 610, 57, 16, 28, 83, 22, 4, -19, 49, 1, 55, 26, 70, 3, 3, 45, 64, 55, 8, 9, 43, 7, 6, 69, 20, 1, -23, 61, 4, 44, 16, 79, 5, 8, 39, 49, 32, 3, 4);
INSERT INTO public.match_details VALUES (611, 611, 55, 8, 10, 84, 23, 1, -25, 78, 12, 52, 19, 75, 4, 6, 47, 62, 49, 7, 1, 70, 26, 33, 98, 20, 12, -8, 61, 1, 57, 24, 83, 9, 7, 52, 62, 43, 6, 7);
INSERT INTO public.match_details VALUES (612, 612, 56, 18, 20, 81, 17, 4, -14, 78, 7, 35, 12, 108, 9, 3, 43, 39, 28, 9, 13, 70, 28, 34, 96, 18, 7, -3, 64, 4, 46, 12, 121, 5, 9, 60, 49, 38, 3, 14);
INSERT INTO public.match_details VALUES (613, 613, 44, 9, 11, 62, 13, 3, -11, 64, 5, 54, 28, 74, 8, 7, 33, 44, 24, 8, 3, 51, 19, 26, 73, 9, 5, -4, 49, 3, 38, 22, 68, 5, 8, 39, 57, 38, 7, 6);
INSERT INTO public.match_details VALUES (614, 614, 52, 28, 36, 74, 7, 8, 4, 40, 4, 37, 22, 61, 1, 4, 34, 55, 47, 10, 7, 43, 14, 3, 52, 12, 4, -9, 67, 8, 44, 26, 82, 10, 10, 35, 42, 18, 4, 6);
INSERT INTO public.match_details VALUES (615, 615, 44, 10, 11, 54, 12, 2, -11, 67, 6, 46, 20, 69, 8, 7, 39, 56, 34, 3, 3, 50, 23, 37, 73, 6, 6, 4, 42, 2, 45, 14, 56, 2, 3, 37, 66, 57, 7, 7);
INSERT INTO public.match_details VALUES (616, 616, 73, 27, 30, 104, 17, 6, -5, 80, 6, 41, 28, 116, 9, 11, 54, 46, 29, 13, 13, 77, 24, 27, 106, 26, 6, -13, 87, 6, 41, 22, 121, 5, 13, 60, 49, 34, 11, 7);
INSERT INTO public.match_details VALUES (617, 617, 40, 9, 8, 55, 9, 1, -9, 62, 4, 50, 20, 82, 8, 11, 36, 43, 20, 3, 8, 57, 25, 39, 74, 12, 4, -5, 46, 1, 45, 26, 75, 2, 3, 42, 56, 49, 11, 12);
INSERT INTO public.match_details VALUES (618, 618, 59, 22, 35, 79, 15, 3, -12, 55, 3, 47, 20, 75, 3, 3, 49, 65, 57, 7, 9, 45, 11, 14, 67, 12, 3, -7, 64, 3, 46, 23, 83, 9, 7, 39, 46, 27, 3, 4);
INSERT INTO public.match_details VALUES (619, 619, 40, 11, 8, 61, 14, 5, -13, 64, 10, 43, 17, 75, 3, 5, 33, 44, 33, 2, 5, 59, 29, 34, 78, 14, 10, -1, 47, 5, 63, 34, 69, 4, 2, 44, 63, 55, 5, 10);
INSERT INTO public.match_details VALUES (620, 620, 64, 20, 31, 98, 13, 6, -6, 70, 5, 37, 12, 88, 7, 8, 46, 52, 35, 12, 11, 67, 16, 17, 89, 19, 5, -10, 85, 6, 55, 24, 113, 13, 12, 54, 47, 25, 8, 4);
INSERT INTO public.match_details VALUES (621, 621, 66, 28, 29, 96, 18, 7, -9, 66, 7, 59, 28, 107, 6, 6, 55, 51, 40, 4, 17, 59, 20, 19, 88, 22, 7, -13, 78, 7, 55, 17, 107, 7, 4, 46, 42, 32, 6, 7);
INSERT INTO public.match_details VALUES (622, 622, 65, 27, 33, 93, 12, 6, -1, 65, 4, 52, 13, 100, 6, 10, 51, 51, 35, 8, 11, 62, 19, 21, 83, 18, 4, -13, 81, 6, 45, 11, 108, 9, 8, 48, 44, 28, 10, 8);
INSERT INTO public.match_details VALUES (623, 623, 69, 27, 21, 95, 18, 7, -6, 91, 3, 53, 19, 131, 13, 14, 56, 42, 22, 6, 12, 77, 32, 39, 110, 19, 3, -8, 77, 7, 41, 15, 119, 6, 6, 60, 50, 40, 14, 12);
INSERT INTO public.match_details VALUES (624, 624, 66, 23, 33, 97, 19, 8, -10, 72, 4, 48, 27, 103, 4, 6, 52, 50, 40, 6, 10, 69, 21, 24, 94, 22, 4, -17, 78, 8, 43, 20, 113, 9, 6, 59, 52, 38, 6, 5);
INSERT INTO public.match_details VALUES (625, 625, 83, 34, 58, 98, 11, 9, 7, 79, 3, 39, 24, 121, 2, 9, 61, 50, 41, 13, 16, 67, 23, 33, 86, 7, 3, 0, 87, 9, 31, 14, 120, 5, 13, 55, 45, 30, 9, 15);
INSERT INTO public.match_details VALUES (626, 626, 47, 10, 12, 65, 15, 5, -10, 67, 9, 38, 14, 97, 6, 5, 39, 40, 28, 3, 14, 56, 23, 33, 77, 10, 9, 0, 50, 5, 36, 20, 77, 5, 3, 42, 54, 44, 5, 13);
INSERT INTO public.match_details VALUES (627, 627, 54, 26, 28, 73, 14, 10, -2, 49, 5, 51, 26, 60, 6, 1, 38, 63, 51, 6, 7, 40, 16, 4, 62, 13, 5, -4, 59, 10, 32, 16, 65, 7, 6, 34, 52, 32, 1, 7);
INSERT INTO public.match_details VALUES (628, 628, 49, 18, 26, 73, 11, 3, -4, 48, 4, 39, 16, 66, 3, 5, 41, 62, 50, 5, 9, 48, 12, 18, 64, 16, 4, -15, 62, 3, 40, 20, 76, 6, 5, 39, 51, 36, 5, 3);
INSERT INTO public.match_details VALUES (629, 629, 84, 112, 3, 20, 0.6, 92, 6, 18, 47, 51, 25, 27, 132, 8, 7, 74, 56, 7, 1.4, 75, 108, 6, 16, 1.2, 92, 3, 20, 48, 52, 10, 10, 123, 11, 7, 62, 50, 7, 1.4);
INSERT INTO public.match_details VALUES (630, 630, 44, 58, 3, 18, 1, 64, 9, 23, 26, 40, 12, 18, 68, 5, 10, 34, 50, 7, 2.33, 50, 73, 9, 9, 3, 40, 3, 13, 17, 42, 9, 22, 64, 2, 7, 31, 48, 10, 3.33);
INSERT INTO public.match_details VALUES (631, 631, 84, 112, 14, 19, 2.8, 87, 12, 20, 37, 42, 8, 9, 113, 8, 12, 61, 54, 9, 1.8, 79, 107, 12, 20, 2.4, 93, 14, 26, 40, 43, 10, 10, 108, 7, 9, 55, 51, 12, 2.4);
INSERT INTO public.match_details VALUES (632, 632, 78, 109, 4, 19, 1, 81, 7, 24, 34, 41, 10, 12, 104, 4, 9, 60, 58, 14, 3.5, 76, 102, 7, 21, 1.75, 90, 4, 23, 48, 53, 21, 23, 128, 10, 14, 60, 47, 9, 2.25);
INSERT INTO public.match_details VALUES (633, 633, 48, 74, 2, 14, 0.67, 41, 2, 7, 22, 53, 4, 9, 72, 5, 4, 42, 58, 4, 1.33, 37, 58, 2, 17, 0.67, 60, 2, 20, 29, 48, 5, 8, 67, 8, 4, 31, 46, 4, 1.33);
INSERT INTO public.match_details VALUES (634, 634, 64, 92, 3, 15, 0.75, 80, 3, 27, 38, 47, 17, 21, 123, 7, 7, 54, 44, 7, 1.75, 70, 94, 3, 14, 0.75, 77, 3, 24, 34, 44, 20, 25, 122, 10, 7, 60, 49, 7, 1.75);
INSERT INTO public.match_details VALUES (635, 635, 79, 100, 7, 18, 1.4, 90, 9, 30, 37, 41, 8, 8, 123, 13, 11, 67, 54, 5, 1, 72, 103, 9, 13, 1.8, 82, 7, 25, 32, 39, 8, 9, 96, 7, 5, 52, 54, 11, 2.2);
INSERT INTO public.match_details VALUES (636, 636, 62, 95, 10, 17, 2.5, 67, 2, 19, 37, 55, 19, 28, 102, 11, 3, 45, 44, 7, 1.75, 56, 87, 2, 20, 0.5, 78, 10, 22, 36, 46, 11, 14, 108, 9, 7, 51, 47, 3, 0.75);
INSERT INTO public.match_details VALUES (637, 637, 75, 96, 4, 15, 1, 84, 4, 23, 36, 42, 20, 23, 125, 8, 9, 55, 44, 16, 4, 70, 96, 4, 12, 1, 81, 4, 26, 41, 50, 19, 23, 120, 6, 16, 57, 48, 9, 2.25);
INSERT INTO public.match_details VALUES (638, 638, 50, 65, 6, 13, 2, 64, 2, 10, 37, 57, 15, 23, 82, 5, 15, 36, 44, 8, 2.67, 55, 73, 2, 9, 0.67, 52, 6, 15, 18, 34, 6, 11, 76, 3, 8, 38, 50, 15, 5);
INSERT INTO public.match_details VALUES (639, 639, 78, 107, 5, 18, 1, 83, 8, 26, 31, 37, 15, 18, 107, 4, 11, 56, 52, 17, 3.4, 80, 106, 8, 23, 1.6, 89, 5, 17, 49, 55, 23, 25, 138, 7, 17, 61, 44, 11, 2.2);
INSERT INTO public.match_details VALUES (640, 640, 82, 112, 9, 16, 1.8, 96, 2, 25, 52, 54, 30, 31, 141, 12, 17, 66, 47, 7, 1.4, 82, 115, 2, 19, 0.4, 96, 9, 25, 48, 50, 30, 31, 124, 9, 7, 63, 51, 17, 3.4);
INSERT INTO public.match_details VALUES (641, 641, 53, 69, 3, 11, 1, 68, 10, 13, 34, 50, 20, 29, 85, 5, 5, 39, 46, 11, 3.67, 57, 75, 10, 7, 3.33, 58, 3, 18, 25, 43, 14, 24, 89, 5, 11, 42, 47, 5, 1.67);
INSERT INTO public.match_details VALUES (642, 642, 72, 100, 4, 13, 1, 83, 3, 19, 47, 56, 20, 24, 126, 9, 10, 60, 48, 8, 2, 72, 97, 3, 14, 0.75, 87, 4, 24, 33, 37, 9, 10, 124, 12, 8, 59, 48, 10, 2.5);
INSERT INTO public.match_details VALUES (643, 643, 86, 114, 5, 23, 1, 84, 5, 17, 49, 58, 19, 22, 129, 4, 5, 71, 55, 10, 2, 67, 98, 5, 14, 1, 91, 5, 24, 42, 46, 12, 13, 129, 9, 10, 57, 44, 5, 1);
INSERT INTO public.match_details VALUES (644, 644, 85, 112, 7, 18, 1.4, 96, 11, 15, 49, 51, 15, 15, 137, 11, 7, 71, 52, 7, 1.4, 82, 115, 11, 19, 2.2, 94, 7, 23, 39, 41, 8, 8, 136, 6, 7, 64, 47, 7, 1.4);
INSERT INTO public.match_details VALUES (645, 645, 50, 74, 8, 18, 2.67, 47, 0, 6, 28, 59, 10, 21, 75, 1, 4, 37, 49, 5, 1.67, 40, 61, 0, 14, 0, 56, 8, 15, 24, 42, 12, 21, 80, 9, 5, 36, 45, 4, 1.33);
INSERT INTO public.match_details VALUES (646, 646, 79, 111, 10, 24, 2, 83, 8, 23, 43, 51, 17, 20, 100, 8, 10, 49, 49, 20, 4, 75, 109, 8, 26, 1.6, 87, 10, 17, 46, 52, 14, 16, 124, 3, 20, 57, 46, 10, 2);
INSERT INTO public.match_details VALUES (647, 647, 89, 114, 11, 22, 2.2, 87, 5, 25, 41, 47, 26, 29, 121, 8, 17, 59, 49, 19, 3.8, 70, 107, 5, 20, 1, 92, 11, 28, 40, 43, 19, 20, 110, 6, 19, 48, 44, 17, 3.4);
INSERT INTO public.match_details VALUES (648, 648, 53, 74, 8, 10, 2.67, 49, 7, 16, 16, 32, 8, 16, 65, 2, 8, 35, 54, 10, 3.33, 46, 62, 7, 13, 2.33, 64, 8, 16, 30, 46, 12, 18, 86, 9, 10, 31, 36, 8, 2.67);
INSERT INTO public.match_details VALUES (649, 649, 52, 74, 7, 15, 2.33, 47, 3, 14, 25, 53, 9, 19, 74, 3, 8, 37, 50, 8, 2.67, 39, 60, 3, 13, 1, 59, 7, 24, 18, 30, 6, 10, 77, 7, 8, 28, 36, 8, 2.67);
INSERT INTO public.match_details VALUES (650, 650, 39, 61, 6, 15, 2, 59, 12, 23, 15, 25, 12, 20, 62, 7, 6, 26, 42, 7, 2.33, 51, 74, 12, 15, 4, 46, 6, 10, 24, 52, 13, 28, 66, 3, 7, 33, 50, 6, 2);
INSERT INTO public.match_details VALUES (651, 651, 45, 65, 2, 11, 0.67, 61, 4, 23, 24, 39, 9, 14, 86, 6, 9, 38, 44, 5, 1.67, 57, 77, 4, 16, 1.33, 54, 2, 16, 30, 55, 15, 27, 81, 3, 5, 44, 54, 9, 3);
INSERT INTO public.match_details VALUES (652, 652, 56, 73, 7, 13, 2.33, 57, 5, 14, 31, 54, 15, 26, 81, 6, 7, 39, 48, 10, 3.33, 48, 70, 5, 13, 1.67, 60, 7, 21, 20, 33, 11, 18, 78, 4, 10, 36, 46, 7, 2.33);
INSERT INTO public.match_details VALUES (653, 653, 69, 96, 10, 20, 2, 95, 8, 26, 43, 45, 21, 22, 110, 10, 13, 46, 42, 13, 2.6, 72, 109, 8, 14, 1.6, 76, 10, 22, 32, 42, 14, 18, 105, 6, 13, 51, 49, 13, 2.6);
INSERT INTO public.match_details VALUES (654, 654, 67, 100, 1, 15, 0.25, 65, 4, 12, 30, 46, 9, 13, 106, 5, 9, 54, 51, 12, 3, 63, 86, 4, 21, 1, 85, 1, 21, 49, 57, 18, 21, 118, 10, 12, 50, 42, 9, 2.25);
INSERT INTO public.match_details VALUES (655, 655, 84, 116, 6, 20, 1.2, 90, 3, 34, 41, 45, 17, 18, 131, 8, 15, 65, 50, 13, 2.6, 81, 112, 3, 22, 0.6, 96, 6, 22, 54, 56, 25, 26, 140, 9, 13, 63, 45, 15, 3);
INSERT INTO public.match_details VALUES (656, 656, 69, 93, 3, 16, 0.75, 86, 5, 25, 39, 45, 19, 22, 112, 9, 8, 61, 54, 5, 1.25, 74, 101, 5, 15, 1.25, 77, 3, 17, 40, 51, 22, 28, 112, 8, 5, 61, 54, 8, 2);
INSERT INTO public.match_details VALUES (657, 657, 73, 97, 10, 14, 2.5, 70, 4, 32, 27, 38, 13, 18, 97, 6, 10, 49, 51, 14, 3.5, 61, 89, 4, 18, 1, 83, 10, 30, 33, 39, 14, 16, 108, 4, 14, 47, 44, 10, 2.5);
INSERT INTO public.match_details VALUES (658, 658, 47, 64, 3, 13, 1, 64, 4, 22, 29, 45, 7, 10, 85, 9, 10, 36, 42, 8, 2.67, 51, 73, 4, 9, 1.33, 51, 3, 14, 30, 58, 15, 29, 76, 4, 8, 37, 49, 10, 3.33);
INSERT INTO public.match_details VALUES (659, 659, 79, 109, 4, 12, 0.8, 88, 9, 19, 38, 43, 21, 23, 128, 9, 9, 66, 52, 9, 1.8, 80, 105, 9, 17, 1.8, 97, 4, 29, 41, 42, 26, 26, 129, 15, 9, 62, 48, 9, 1.8);
INSERT INTO public.match_details VALUES (660, 660, 46, 73, 6, 14, 2, 47, 2, 12, 22, 46, 12, 25, 68, 4, 4, 35, 51, 5, 1.67, 43, 64, 2, 17, 0.67, 59, 6, 19, 19, 32, 9, 15, 83, 7, 5, 37, 45, 4, 1.33);
INSERT INTO public.match_details VALUES (661, 661, 62, 90, 7, 13, 1.75, 79, 2, 16, 42, 53, 25, 31, 116, 10, 13, 47, 41, 8, 2, 67, 90, 2, 11, 0.5, 77, 7, 20, 37, 48, 19, 24, 110, 13, 8, 52, 47, 13, 3.25);
INSERT INTO public.match_details VALUES (662, 662, 65, 88, 7, 13, 1.75, 85, 7, 31, 40, 47, 13, 15, 102, 4, 15, 54, 53, 4, 1, 77, 97, 4, 12, 1, 75, 9, 22, 35, 46, 16, 21, 100, 7, 4, 58, 58, 15, 3.75);
INSERT INTO public.match_details VALUES (663, 663, 88, 106, 6, 16, 1.2, 86, 3, 18, 49, 56, 25, 29, 145, 11, 16, 68, 47, 14, 2.8, 67, 98, 3, 12, 0.6, 89, 6, 28, 35, 39, 17, 19, 129, 4, 14, 48, 37, 16, 3.2);
INSERT INTO public.match_details VALUES (664, 664, 41, 63, 4, 9, 1.33, 61, 4, 21, 23, 37, 8, 13, 87, 7, 12, 33, 38, 4, 1.33, 58, 73, 4, 12, 1.33, 54, 4, 16, 28, 51, 8, 14, 83, 8, 4, 42, 51, 12, 4);
INSERT INTO public.match_details VALUES (665, 665, 74, 99, 8, 17, 1.6, 89, 5, 33, 28, 31, 13, 14, 131, 12, 14, 58, 44, 8, 1.6, 75, 108, 5, 19, 1, 82, 8, 27, 28, 34, 4, 4, 128, 4, 8, 56, 44, 14, 2.8);
INSERT INTO public.match_details VALUES (666, 666, 74, 99, 12, 16, 3, 69, 5, 18, 32, 46, 13, 18, 110, 5, 10, 50, 45, 12, 3, 63, 87, 5, 18, 1.25, 83, 12, 22, 39, 46, 17, 20, 117, 7, 12, 48, 41, 10, 2.5);
INSERT INTO public.match_details VALUES (667, 667, 56, 73, 7, 10, 2.33, 40, 1, 9, 24, 60, 15, 37, 68, 4, 1, 42, 62, 7, 2.33, 32, 49, 1, 9, 0.33, 63, 7, 19, 25, 39, 13, 20, 65, 6, 7, 30, 46, 1, 0.33);
INSERT INTO public.match_details VALUES (668, 668, 59, 100, 4, 22, 0.8, 85, 4, 22, 40, 47, 16, 18, 111, 10, 10, 47, 42, 8, 1.6, 67, 104, 4, 19, 0.8, 78, 4, 26, 37, 47, 10, 12, 117, 16, 8, 53, 45, 10, 2);
INSERT INTO public.match_details VALUES (669, 669, 58, 75, 4, 12, 1.33, 54, 1, 19, 23, 42, 11, 20, 95, 5, 9, 47, 49, 7, 2.33, 44, 63, 1, 9, 0.33, 63, 4, 21, 33, 52, 7, 11, 86, 7, 7, 34, 40, 9, 3);
INSERT INTO public.match_details VALUES (670, 670, 60, 77, 2, 11, 0.67, 75, 7, 22, 41, 54, 18, 24, 100, 11, 9, 51, 51, 7, 2.33, 64, 84, 4, 9, 1.33, 66, 5, 16, 36, 54, 14, 21, 89, 4, 7, 51, 57, 9, 3);
INSERT INTO public.match_details VALUES (671, 671, 47, 64, 2, 13, 0.67, 65, 9, 23, 23, 35, 14, 21, 82, 9, 8, 34, 41, 11, 3.67, 53, 75, 9, 10, 3, 51, 2, 13, 23, 45, 11, 21, 81, 5, 11, 36, 44, 8, 2.67);
INSERT INTO public.match_details VALUES (672, 672, 67, 94, 6, 15, 1.5, 75, 3, 22, 31, 41, 17, 22, 99, 14, 3, 48, 48, 13, 3.25, 51, 87, 3, 12, 0.75, 79, 6, 23, 41, 51, 23, 29, 105, 14, 13, 45, 43, 3, 0.75);
INSERT INTO public.match_details VALUES (673, 673, 36, 53, 3, 16, 1, 64, 15, 12, 30, 46, 8, 12, 63, 1, 5, 32, 51, 1, 0.33, 58, 73, 15, 9, 5, 37, 3, 8, 20, 54, 6, 16, 65, 6, 1, 38, 58, 5, 1.67);
INSERT INTO public.match_details VALUES (674, 674, 56, 74, 4, 14, 1.33, 52, 4, 17, 22, 42, 11, 21, 78, 3, 7, 43, 55, 9, 3, 47, 66, 4, 14, 1.33, 60, 4, 15, 27, 45, 15, 25, 83, 2, 9, 36, 43, 7, 2.33);
INSERT INTO public.match_details VALUES (675, 675, 48, 69, 3, 9, 1, 65, 10, 24, 20, 30, 6, 9, 71, 6, 9, 36, 51, 9, 3, 58, 74, 10, 9, 3.33, 60, 3, 17, 28, 46, 10, 16, 85, 8, 9, 39, 46, 9, 3);
INSERT INTO public.match_details VALUES (676, 676, 60, 94, 9, 23, 1.8, 87, 4, 32, 40, 45, 17, 19, 108, 11, 11, 39, 36, 12, 2.4, 63, 105, 4, 18, 0.8, 71, 9, 21, 31, 43, 16, 22, 110, 8, 12, 48, 44, 11, 2.2);
INSERT INTO public.match_details VALUES (677, 677, 48, 64, 1, 14, 0.33, 63, 7, 8, 32, 50, 16, 25, 78, 3, 8, 38, 49, 9, 3, 58, 75, 7, 12, 2.33, 50, 1, 17, 26, 52, 12, 24, 78, 2, 9, 43, 55, 8, 2.67);
INSERT INTO public.match_details VALUES (678, 678, 55, 75, 4, 13, 1.33, 60, 4, 27, 23, 38, 13, 21, 88, 1, 5, 41, 47, 10, 3.33, 50, 69, 4, 9, 1.33, 62, 4, 18, 27, 43, 13, 20, 96, 9, 10, 41, 43, 5, 1.67);
INSERT INTO public.match_details VALUES (679, 679, 69, 98, 5, 15, 1.25, 67, 4, 12, 37, 55, 20, 29, 107, 5, 9, 60, 56, 4, 1, 65, 88, 4, 21, 1, 83, 5, 22, 41, 49, 15, 18, 111, 7, 4, 52, 47, 9, 2.25);
INSERT INTO public.match_details VALUES (680, 680, 70, 92, 3, 13, 0.75, 90, 10, 29, 38, 42, 13, 14, 123, 9, 9, 63, 51, 4, 1, 75, 102, 10, 12, 2.5, 79, 3, 18, 40, 50, 17, 21, 114, 7, 4, 56, 49, 9, 2.25);
INSERT INTO public.match_details VALUES (681, 681, 68, 93, 8, 18, 2, 76, 8, 19, 35, 46, 10, 13, 101, 3, 10, 56, 55, 4, 1, 69, 94, 8, 18, 2, 75, 8, 17, 27, 36, 15, 20, 94, 6, 4, 51, 54, 10, 2.5);
INSERT INTO public.match_details VALUES (682, 682, 51, 71, 5, 13, 1.67, 74, 11, 25, 30, 40, 3, 4, 106, 10, 9, 42, 40, 4, 1.33, 55, 83, 6, 9, 2, 58, 5, 15, 32, 55, 12, 20, 98, 9, 4, 40, 41, 9, 3);
INSERT INTO public.match_details VALUES (683, 683, 74, 97, 9, 17, 2.25, 64, 6, 17, 30, 46, 13, 20, 92, 4, 4, 54, 59, 11, 2.75, 51, 76, 6, 12, 1.5, 80, 9, 32, 32, 40, 8, 10, 99, 10, 11, 41, 41, 4, 1);
INSERT INTO public.match_details VALUES (684, 684, 38, 56, 1, 11, 0.33, 62, 5, 19, 28, 45, 9, 14, 82, 5, 9, 35, 43, 2, 0.67, 58, 74, 5, 12, 1.67, 45, 1, 10, 20, 44, 5, 11, 71, 4, 2, 44, 62, 9, 3);
INSERT INTO public.match_details VALUES (685, 685, 67, 86, 5, 14, 1.25, 87, 4, 29, 38, 43, 12, 13, 106, 9, 10, 53, 50, 9, 2.25, 66, 93, 4, 6, 1, 72, 5, 14, 34, 47, 9, 12, 96, 7, 9, 52, 54, 10, 2.5);
INSERT INTO public.match_details VALUES (686, 686, 70, 99, 8, 13, 2, 71, 3, 13, 39, 54, 15, 21, 105, 8, 13, 54, 51, 8, 2, 66, 91, 3, 19, 0.75, 86, 8, 21, 32, 37, 11, 12, 97, 8, 8, 50, 52, 13, 3.25);
INSERT INTO public.match_details VALUES (687, 687, 61, 84, 5, 22, 1.25, 84, 6, 23, 42, 50, 22, 26, 106, 8, 13, 48, 45, 8, 2, 64, 96, 6, 12, 1.5, 62, 5, 15, 33, 53, 13, 20, 84, 6, 8, 45, 54, 13, 3.25);
INSERT INTO public.match_details VALUES (688, 688, 80, 103, 6, 12, 1.5, 87, 10, 26, 40, 45, 17, 19, 109, 5, 8, 57, 52, 17, 4.25, 83, 101, 10, 14, 2.5, 91, 6, 26, 46, 50, 20, 21, 130, 6, 17, 65, 50, 8, 2);
INSERT INTO public.match_details VALUES (689, 689, 54, 73, 5, 9, 1.67, 50, 4, 11, 30, 60, 14, 28, 90, 1, 7, 41, 46, 8, 2.67, 46, 62, 4, 12, 1.33, 64, 5, 19, 23, 35, 8, 12, 105, 8, 8, 35, 33, 7, 2.33);
INSERT INTO public.match_details VALUES (690, 690, 89, 112, 4, 20, 0.8, 95, 12, 27, 47, 49, 21, 22, 127, 8, 5, 70, 55, 15, 3, 76, 105, 12, 10, 2.4, 92, 4, 30, 42, 45, 14, 15, 123, 10, 15, 59, 48, 5, 1);
INSERT INTO public.match_details VALUES (691, 691, 65, 80, 10, 8, 3.33, 58, 3, 16, 27, 46, 10, 17, 86, 4, 8, 48, 56, 7, 2.33, 56, 70, 3, 12, 1, 72, 10, 21, 30, 41, 7, 9, 85, 2, 7, 45, 53, 8, 2.67);
INSERT INTO public.match_details VALUES (692, 692, 54, 74, 3, 9, 1, 47, 4, 12, 18, 38, 8, 17, 73, 5, 3, 41, 56, 10, 3.33, 41, 57, 3, 10, 1, 65, 10, 20, 18, 27, 8, 12, 84, 8, 10, 35, 42, 3, 1);
INSERT INTO public.match_details VALUES (693, 693, 79, 108, 9, 13, 1.8, 103, 10, 33, 55, 53, 19, 18, 138, 8, 13, 59, 43, 11, 2.2, 92, 115, 3, 12, 0.6, 95, 12, 25, 50, 52, 17, 17, 143, 11, 11, 76, 53, 13, 2.6);
INSERT INTO public.match_details VALUES (694, 694, 38, 57, 2, 11, 0.67, 59, 4, 17, 26, 44, 14, 23, 70, 9, 5, 33, 47, 3, 1, 53, 73, 4, 14, 1.33, 46, 2, 13, 21, 45, 12, 26, 65, 3, 3, 44, 68, 5, 1.67);
INSERT INTO public.match_details VALUES (695, 695, 63, 80, 5, 18, 1.25, 85, 7, 21, 41, 48, 15, 17, 103, 8, 12, 49, 48, 9, 2.25, 69, 96, 7, 11, 1.75, 62, 5, 18, 31, 50, 17, 27, 76, 3, 9, 50, 66, 12, 3);
INSERT INTO public.match_details VALUES (696, 696, 55, 73, 9, 10, 3, 48, 4, 12, 26, 54, 10, 20, 63, 5, 5, 41, 65, 5, 1.67, 41, 58, 4, 10, 1.33, 63, 9, 17, 26, 41, 9, 14, 66, 7, 5, 32, 48, 5, 1.67);
INSERT INTO public.match_details VALUES (697, 697, 66, 93, 5, 12, 1.25, 65, 6, 24, 30, 46, 10, 15, 94, 6, 4, 49, 52, 12, 3, 62, 83, 6, 18, 1.5, 81, 5, 26, 38, 46, 13, 16, 110, 7, 12, 52, 47, 4, 1);
INSERT INTO public.match_details VALUES (698, 698, 69, 105, 8, 21, 1.6, 84, 5, 24, 41, 48, 18, 21, 110, 5, 5, 50, 45, 11, 2.2, 75, 104, 5, 20, 1, 84, 8, 18, 36, 42, 20, 23, 119, 9, 11, 65, 55, 5, 1);
INSERT INTO public.match_details VALUES (699, 699, 61, 73, 7, 15, 2.33, 56, 5, 22, 20, 35, 11, 19, 78, 4, 4, 46, 59, 8, 2.67, 40, 64, 5, 8, 1.67, 58, 7, 22, 25, 43, 12, 20, 66, 4, 8, 31, 47, 4, 1.33);
INSERT INTO public.match_details VALUES (700, 700, 55, 74, 5, 13, 1.67, 41, 5, 12, 19, 46, 9, 21, 63, 4, 3, 40, 63, 10, 3.33, 33, 53, 5, 12, 1.67, 61, 5, 25, 19, 31, 9, 14, 70, 7, 10, 25, 36, 3, 1);
INSERT INTO public.match_details VALUES (701, 701, 56, 84, 6, 9, 1.5, 84, 3, 20, 45, 53, 28, 33, 110, 7, 6, 42, 38, 8, 2, 75, 96, 3, 12, 0.75, 75, 6, 21, 29, 38, 12, 16, 123, 12, 8, 66, 54, 6, 1.5);
INSERT INTO public.match_details VALUES (702, 702, 64, 87, 4, 14, 1, 83, 10, 24, 32, 38, 9, 10, 116, 4, 12, 51, 44, 9, 2.25, 71, 94, 10, 11, 2.5, 73, 4, 19, 36, 49, 14, 19, 119, 6, 9, 49, 41, 12, 3);
INSERT INTO public.match_details VALUES (703, 703, 47, 63, 3, 12, 1, 63, 8, 14, 26, 41, 12, 19, 85, 9, 14, 37, 44, 7, 2.33, 48, 73, 8, 10, 2.67, 51, 3, 18, 21, 41, 12, 23, 62, 4, 7, 26, 42, 14, 4.67);
INSERT INTO public.match_details VALUES (704, 704, 72, 108, 7, 15, 1.4, 83, 5, 20, 54, 65, 12, 14, 137, 13, 13, 54, 39, 11, 2.2, 67, 98, 3, 15, 0.6, 93, 14, 28, 40, 43, 7, 7, 128, 14, 11, 51, 40, 13, 2.6);
INSERT INTO public.match_details VALUES (705, 705, 47, 61, 2, 16, 0.67, 65, 8, 15, 25, 38, 10, 15, 96, 6, 7, 39, 41, 6, 2, 50, 74, 8, 9, 2.67, 45, 2, 16, 20, 44, 6, 13, 80, 4, 6, 35, 44, 7, 2.33);
INSERT INTO public.match_details VALUES (706, 706, 59, 75, 2, 15, 0.5, 84, 8, 21, 37, 44, 24, 28, 97, 10, 8, 44, 45, 13, 3.25, 64, 92, 8, 8, 2, 60, 2, 12, 38, 63, 24, 40, 89, 6, 13, 48, 54, 8, 2);
INSERT INTO public.match_details VALUES (707, 707, 68, 99, 10, 18, 2.5, 68, 5, 27, 18, 26, 4, 5, 107, 10, 8, 50, 47, 8, 2, 57, 89, 5, 21, 1.25, 81, 10, 26, 26, 32, 3, 3, 96, 7, 8, 44, 46, 8, 2);
INSERT INTO public.match_details VALUES (708, 708, 55, 73, 8, 15, 2.67, 37, 2, 13, 18, 48, 7, 18, 59, 4, 3, 33, 56, 14, 4.67, 25, 47, 2, 10, 0.67, 58, 8, 22, 25, 43, 5, 8, 69, 8, 14, 20, 29, 3, 1);
INSERT INTO public.match_details VALUES (709, 709, 88, 117, 6, 27, 1.2, 105, 6, 35, 49, 46, 14, 13, 136, 9, 13, 69, 51, 13, 2.6, 83, 121, 6, 15, 1.2, 90, 6, 29, 38, 42, 19, 21, 128, 11, 13, 64, 50, 13, 2.6);
INSERT INTO public.match_details VALUES (710, 710, 68, 90, 6, 21, 1.5, 70, 7, 20, 34, 48, 11, 15, 97, 8, 13, 51, 53, 11, 2.75, 56, 89, 7, 19, 1.75, 70, 6, 25, 26, 37, 8, 11, 83, 3, 11, 36, 43, 13, 3.25);
INSERT INTO public.match_details VALUES (711, 711, 68, 97, 5, 15, 1.25, 74, 5, 27, 33, 44, 16, 21, 105, 6, 5, 49, 47, 14, 3.5, 64, 88, 5, 14, 1.25, 82, 5, 23, 39, 47, 18, 21, 117, 12, 14, 54, 46, 5, 1.25);
INSERT INTO public.match_details VALUES (712, 712, 44, 73, 3, 13, 0.75, 78, 7, 29, 27, 34, 12, 15, 91, 8, 19, 35, 38, 6, 1.5, 70, 94, 7, 16, 1.75, 60, 3, 15, 27, 45, 10, 16, 82, 10, 6, 44, 54, 19, 4.75);
INSERT INTO public.match_details VALUES (713, 713, 66, 90, 3, 17, 0.6, 85, 9, 24, 36, 42, 12, 14, 114, 9, 13, 55, 48, 8, 1.6, 69, 97, 9, 12, 1.8, 73, 3, 19, 31, 42, 19, 26, 111, 9, 8, 47, 42, 13, 2.6);
INSERT INTO public.match_details VALUES (714, 714, 77, 101, 6, 13, 1.5, 76, 4, 28, 21, 27, 3, 3, 115, 6, 9, 58, 50, 13, 3.25, 71, 92, 4, 16, 1, 88, 6, 27, 31, 35, 12, 13, 128, 8, 13, 58, 45, 9, 2.25);
INSERT INTO public.match_details VALUES (715, 715, 85, 116, 7, 19, 1.4, 99, 6, 22, 66, 66, 18, 18, 123, 8, 13, 66, 54, 12, 2.4, 84, 117, 5, 18, 1, 97, 12, 34, 43, 44, 10, 10, 117, 10, 12, 66, 56, 13, 2.6);
INSERT INTO public.match_details VALUES (716, 716, 64, 98, 7, 17, 1.4, 86, 6, 27, 36, 41, 12, 13, 126, 8, 12, 49, 39, 8, 1.6, 81, 109, 6, 23, 1.2, 81, 7, 23, 33, 40, 15, 18, 127, 7, 8, 63, 50, 12, 2.4);
INSERT INTO public.match_details VALUES (717, 717, 67, 95, 7, 13, 1.75, 61, 5, 13, 35, 57, 13, 21, 91, 4, 6, 51, 56, 9, 2.25, 54, 76, 5, 15, 1.25, 82, 7, 27, 34, 41, 17, 20, 102, 11, 9, 43, 42, 6, 1.5);
INSERT INTO public.match_details VALUES (718, 718, 82, 111, 12, 16, 2.4, 88, 2, 15, 53, 60, 15, 17, 135, 12, 12, 64, 47, 6, 1.2, 74, 107, 2, 19, 0.4, 95, 12, 21, 43, 45, 10, 10, 120, 7, 6, 60, 50, 12, 2.4);
INSERT INTO public.match_details VALUES (719, 719, 43, 60, 4, 19, 1.33, 65, 5, 16, 39, 60, 11, 16, 83, 9, 6, 38, 46, 1, 0.33, 45, 73, 5, 8, 1.67, 41, 4, 14, 17, 41, 7, 17, 59, 6, 1, 34, 58, 6, 2);
INSERT INTO public.match_details VALUES (720, 720, 52, 74, 7, 15, 2.33, 45, 1, 18, 17, 37, 8, 17, 71, 3, 2, 38, 54, 7, 2.33, 39, 60, 1, 15, 0.33, 59, 7, 29, 21, 35, 11, 18, 74, 7, 7, 36, 49, 2, 0.67);
INSERT INTO public.match_details VALUES (721, 721, 56, 73, 7, 10, 2.33, 51, 1, 17, 28, 54, 8, 15, 81, 1, 4, 42, 52, 7, 2.33, 46, 61, 1, 10, 0.33, 63, 7, 14, 36, 57, 17, 26, 82, 4, 7, 41, 50, 4, 1.33);
INSERT INTO public.match_details VALUES (722, 722, 66, 97, 6, 13, 1.5, 62, 7, 15, 34, 54, 18, 29, 99, 4, 4, 52, 53, 8, 2, 64, 83, 7, 21, 1.75, 84, 6, 28, 37, 44, 12, 14, 108, 9, 8, 53, 49, 4, 1);
INSERT INTO public.match_details VALUES (723, 723, 43, 62, 3, 9, 1, 63, 7, 18, 30, 47, 13, 20, 76, 9, 9, 33, 43, 7, 2.33, 55, 74, 7, 11, 2.33, 53, 3, 10, 25, 47, 10, 18, 74, 7, 7, 39, 53, 9, 3);
INSERT INTO public.match_details VALUES (724, 724, 62, 101, 5, 13, 1, 84, 9, 25, 32, 38, 17, 20, 130, 9, 15, 43, 33, 14, 2.8, 77, 103, 9, 19, 1.8, 88, 5, 16, 45, 51, 17, 19, 136, 13, 14, 53, 39, 15, 3);
INSERT INTO public.match_details VALUES (725, 725, 67, 100, 9, 15, 1.8, 81, 7, 21, 36, 44, 14, 17, 112, 8, 18, 48, 43, 10, 2, 75, 103, 7, 22, 1.4, 85, 9, 28, 26, 30, 7, 8, 108, 8, 10, 50, 46, 18, 3.6);
INSERT INTO public.match_details VALUES (726, 726, 49, 74, 7, 9, 2.33, 46, 4, 17, 22, 47, 6, 13, 68, 6, 2, 39, 57, 3, 1, 40, 59, 3, 13, 1, 65, 10, 14, 35, 53, 10, 15, 69, 10, 3, 35, 51, 2, 0.67);
INSERT INTO public.match_details VALUES (727, 727, 54, 83, 5, 16, 1.25, 77, 8, 25, 33, 42, 11, 14, 91, 5, 9, 44, 48, 5, 1.25, 72, 96, 8, 19, 2, 67, 5, 28, 27, 40, 7, 10, 92, 5, 5, 55, 60, 9, 2.25);
INSERT INTO public.match_details VALUES (728, 728, 71, 89, 8, 10, 2, 78, 8, 14, 37, 47, 6, 7, 101, 6, 11, 58, 57, 5, 1.25, 72, 91, 8, 13, 2, 79, 8, 24, 23, 29, 4, 5, 104, 3, 5, 53, 51, 11, 2.75);
INSERT INTO public.match_details VALUES (729, 729, 61, 89, 8, 19, 2, 82, 4, 29, 35, 42, 12, 14, 104, 11, 14, 43, 41, 10, 2.5, 70, 100, 4, 18, 1, 70, 8, 21, 33, 47, 11, 15, 98, 8, 10, 52, 53, 14, 3.5);
INSERT INTO public.match_details VALUES (730, 730, 54, 74, 8, 12, 2.67, 46, 2, 12, 28, 60, 9, 19, 72, 5, 4, 38, 53, 8, 2.67, 36, 59, 2, 13, 0.67, 62, 8, 9, 35, 56, 12, 19, 71, 6, 8, 30, 42, 4, 1.33);
INSERT INTO public.match_details VALUES (731, 731, 47, 66, 2, 12, 0.67, 63, 5, 20, 30, 47, 14, 22, 72, 6, 7, 39, 54, 6, 2, 54, 74, 5, 11, 1.67, 54, 2, 15, 28, 51, 17, 31, 72, 3, 6, 42, 58, 7, 2.33);
INSERT INTO public.match_details VALUES (732, 732, 70, 93, 4, 19, 1, 84, 4, 15, 45, 53, 19, 22, 111, 5, 12, 60, 54, 6, 1.5, 76, 99, 4, 15, 1, 74, 4, 21, 36, 48, 19, 25, 101, 5, 6, 60, 59, 12, 3);
INSERT INTO public.match_details VALUES (733, 733, 55, 74, 9, 10, 3, 46, 8, 11, 19, 41, 13, 28, 64, 5, 5, 35, 55, 11, 3.67, 42, 59, 8, 13, 2.67, 64, 9, 18, 22, 34, 8, 12, 61, 5, 11, 29, 48, 5, 1.67);
INSERT INTO public.match_details VALUES (734, 734, 58, 73, 3, 13, 1, 50, 4, 8, 31, 62, 15, 30, 69, 4, 1, 47, 68, 8, 2.67, 38, 58, 4, 8, 1.33, 60, 3, 17, 28, 46, 10, 16, 84, 7, 8, 33, 39, 1, 0.33);
INSERT INTO public.match_details VALUES (735, 735, 52, 78, 1, 9, 0.25, 78, 6, 21, 33, 42, 14, 17, 113, 9, 13, 49, 43, 2, 0.5, 75, 95, 6, 17, 1.5, 69, 1, 20, 27, 39, 10, 14, 105, 4, 2, 56, 53, 13, 3.25);
INSERT INTO public.match_details VALUES (736, 736, 54, 74, 8, 10, 2.67, 42, 2, 10, 21, 50, 5, 11, 69, 1, 8, 38, 55, 8, 2.67, 41, 53, 2, 11, 0.67, 64, 8, 17, 28, 43, 10, 15, 73, 6, 8, 31, 42, 8, 2.67);
INSERT INTO public.match_details VALUES (737, 737, 53, 68, 3, 12, 1, 67, 6, 28, 27, 40, 7, 10, 87, 4, 4, 39, 45, 11, 3.67, 58, 73, 6, 6, 2, 56, 3, 22, 24, 42, 4, 7, 109, 6, 11, 48, 44, 4, 1.33);
INSERT INTO public.match_details VALUES (738, 738, 59, 86, 7, 16, 1.75, 81, 6, 24, 38, 46, 16, 19, 111, 8, 12, 45, 41, 7, 1.75, 72, 99, 6, 18, 1.5, 70, 7, 22, 24, 34, 10, 14, 108, 7, 7, 54, 50, 12, 3);
INSERT INTO public.match_details VALUES (739, 739, 78, 101, 4, 22, 0.8, 93, 2, 31, 50, 53, 16, 17, 116, 9, 10, 60, 52, 14, 2.8, 70, 105, 2, 12, 0.4, 79, 4, 28, 34, 43, 16, 20, 114, 5, 14, 58, 51, 10, 2);
INSERT INTO public.match_details VALUES (740, 740, 53, 73, 8, 13, 2.67, 42, 1, 8, 21, 50, 12, 28, 58, 4, 1, 37, 64, 8, 2.67, 33, 55, 1, 13, 0.33, 60, 8, 12, 26, 43, 14, 23, 68, 7, 8, 31, 46, 1, 0.33);
INSERT INTO public.match_details VALUES (741, 741, 72, 96, 7, 15, 1.75, 62, 6, 15, 30, 48, 14, 22, 103, 5, 5, 53, 51, 12, 3, 52, 76, 6, 14, 1.5, 81, 7, 24, 34, 41, 17, 20, 106, 5, 12, 41, 39, 5, 1.25);
INSERT INTO public.match_details VALUES (742, 742, 75, 98, 7, 14, 1.4, 80, 12, 28, 28, 35, 7, 8, 103, 6, 9, 50, 49, 18, 3.6, 71, 92, 12, 12, 2.4, 84, 7, 15, 42, 50, 23, 27, 126, 11, 18, 50, 40, 9, 1.8);
INSERT INTO public.match_details VALUES (743, 743, 66, 100, 7, 16, 1.75, 69, 2, 22, 31, 44, 13, 18, 102, 11, 3, 53, 52, 6, 1.5, 58, 87, 2, 18, 0.5, 84, 7, 18, 48, 57, 22, 26, 109, 16, 6, 53, 49, 3, 0.75);
INSERT INTO public.match_details VALUES (744, 744, 42, 57, 2, 10, 0.67, 67, 5, 19, 31, 46, 19, 28, 81, 3, 14, 37, 46, 3, 1, 61, 74, 5, 7, 1.67, 47, 2, 11, 24, 51, 14, 29, 78, 5, 3, 42, 54, 14, 4.67);
INSERT INTO public.match_details VALUES (745, 745, 37, 56, 2, 9, 0.67, 61, 6, 22, 29, 47, 9, 14, 74, 4, 8, 33, 45, 2, 0.67, 58, 73, 6, 12, 2, 47, 2, 12, 25, 53, 13, 27, 73, 3, 2, 44, 60, 8, 2.67);
INSERT INTO public.match_details VALUES (746, 746, 74, 111, 4, 19, 0.8, 82, 6, 23, 41, 50, 14, 17, 119, 6, 6, 56, 47, 14, 2.8, 77, 109, 6, 27, 1.2, 92, 4, 21, 42, 45, 17, 18, 144, 8, 14, 65, 45, 6, 1.2);
INSERT INTO public.match_details VALUES (747, 747, 57, 71, 3, 14, 1, 79, 7, 20, 36, 45, 23, 29, 108, 7, 13, 46, 43, 8, 2.67, 63, 86, 7, 7, 2.33, 57, 3, 18, 24, 42, 10, 17, 100, 3, 8, 43, 43, 13, 4.33);
INSERT INTO public.match_details VALUES (748, 748, 49, 73, 6, 9, 2, 47, 3, 19, 18, 38, 5, 10, 68, 3, 4, 34, 50, 9, 3, 49, 64, 3, 17, 1, 64, 6, 23, 29, 45, 18, 28, 90, 8, 9, 42, 47, 4, 1.33);
INSERT INTO public.match_details VALUES (749, 749, 74, 89, 8, 14, 2, 74, 6, 18, 40, 54, 23, 31, 97, 4, 8, 62, 64, 4, 1, 59, 83, 6, 9, 1.5, 75, 8, 29, 29, 38, 12, 16, 87, 3, 4, 45, 52, 8, 2);
INSERT INTO public.match_details VALUES (750, 750, 67, 96, 10, 23, 2.5, 70, 3, 25, 30, 42, 9, 12, 97, 6, 13, 46, 47, 11, 2.75, 60, 91, 3, 21, 0.75, 73, 10, 24, 27, 36, 13, 17, 96, 5, 11, 44, 46, 13, 3.25);
INSERT INTO public.match_details VALUES (751, 751, 79, 102, 9, 17, 2.25, 80, 5, 20, 44, 55, 6, 7, 117, 9, 12, 58, 50, 12, 3, 69, 98, 5, 18, 1.25, 85, 9, 31, 29, 34, 4, 4, 110, 7, 12, 52, 47, 12, 3);
INSERT INTO public.match_details VALUES (752, 752, 54, 73, 5, 15, 1.67, 41, 1, 8, 22, 53, 10, 24, 70, 4, 7, 38, 54, 11, 3.67, 36, 58, 1, 17, 0.33, 58, 5, 20, 19, 32, 9, 15, 69, 3, 11, 28, 41, 7, 2.33);
INSERT INTO public.match_details VALUES (753, 753, 70, 97, 4, 21, 1, 69, 2, 14, 36, 52, 14, 20, 102, 7, 8, 52, 51, 14, 3.5, 53, 82, 2, 13, 0.5, 76, 4, 16, 38, 50, 9, 11, 104, 12, 14, 43, 41, 8, 2);
INSERT INTO public.match_details VALUES (754, 754, 51, 73, 4, 10, 1.33, 44, 4, 15, 16, 36, 5, 11, 66, 3, 7, 39, 59, 8, 2.67, 45, 60, 4, 16, 1.33, 63, 4, 15, 34, 53, 10, 15, 78, 7, 8, 34, 44, 7, 2.33);
INSERT INTO public.match_details VALUES (755, 755, 77, 105, 6, 13, 1.5, 79, 1, 24, 37, 46, 17, 21, 124, 11, 7, 59, 48, 12, 3, 70, 96, 1, 17, 0.25, 92, 6, 26, 48, 52, 16, 17, 124, 9, 12, 62, 50, 7, 1.75);
INSERT INTO public.match_details VALUES (756, 756, 82, 98, 4, 12, 1, 79, 7, 19, 32, 40, 13, 16, 117, 4, 12, 71, 61, 7, 1.75, 68, 91, 7, 12, 1.75, 86, 4, 22, 44, 51, 12, 13, 111, 2, 7, 49, 44, 12, 3);
INSERT INTO public.match_details VALUES (757, 757, 42, 64, 2, 11, 0.67, 62, 5, 22, 30, 48, 15, 24, 74, 7, 5, 31, 42, 9, 3, 55, 74, 5, 12, 1.67, 53, 2, 11, 28, 52, 14, 26, 86, 7, 9, 45, 52, 5, 1.67);
INSERT INTO public.match_details VALUES (758, 758, 81, 107, 4, 17, 1, 79, 6, 19, 43, 54, 26, 32, 119, 4, 5, 70, 59, 7, 1.75, 73, 96, 6, 17, 1.5, 90, 4, 20, 50, 55, 18, 20, 120, 7, 7, 62, 52, 5, 1.25);
INSERT INTO public.match_details VALUES (759, 759, 73, 101, 10, 21, 2.5, 82, 5, 34, 27, 32, 10, 12, 115, 9, 6, 50, 43, 13, 3.25, 69, 100, 5, 18, 1.25, 80, 10, 18, 44, 55, 19, 23, 118, 8, 13, 58, 49, 6, 1.5);
INSERT INTO public.match_details VALUES (760, 760, 54, 79, 5, 25, 1.25, 83, 3, 21, 44, 53, 21, 25, 113, 11, 12, 44, 39, 5, 1.25, 61, 96, 3, 13, 0.75, 54, 5, 18, 21, 38, 11, 20, 104, 8, 5, 46, 44, 12, 3);
INSERT INTO public.match_details VALUES (761, 761, 61, 82, 5, 12, 1.25, 84, 7, 26, 36, 42, 12, 14, 101, 7, 14, 45, 45, 11, 2.75, 77, 98, 7, 14, 1.75, 70, 5, 12, 40, 57, 21, 30, 110, 4, 11, 56, 51, 14, 3.5);
INSERT INTO public.match_details VALUES (762, 762, 73, 99, 9, 19, 2.25, 83, 13, 23, 36, 43, 14, 16, 105, 4, 10, 52, 50, 12, 3, 74, 99, 13, 16, 3.25, 80, 9, 23, 37, 46, 13, 16, 116, 10, 12, 51, 44, 10, 2.5);
INSERT INTO public.match_details VALUES (763, 763, 72, 97, 9, 19, 2.25, 68, 7, 22, 31, 45, 13, 19, 93, 8, 7, 54, 58, 9, 2.25, 52, 84, 7, 16, 1.75, 78, 9, 14, 44, 56, 25, 32, 87, 7, 9, 38, 44, 7, 1.75);
INSERT INTO public.match_details VALUES (764, 764, 55, 75, 4, 11, 1.33, 59, 3, 21, 22, 37, 9, 15, 85, 6, 5, 38, 45, 13, 4.33, 46, 66, 3, 7, 1, 64, 4, 13, 34, 53, 14, 21, 103, 11, 13, 38, 37, 5, 1.67);
INSERT INTO public.match_details VALUES (765, 765, 54, 73, 3, 11, 1, 55, 1, 15, 28, 50, 8, 14, 83, 8, 4, 43, 52, 8, 2.67, 45, 67, 1, 12, 0.33, 62, 3, 8, 34, 54, 13, 20, 85, 6, 8, 40, 47, 4, 1.33);
INSERT INTO public.match_details VALUES (766, 766, 78, 97, 11, 13, 2.75, 75, 3, 32, 32, 42, 4, 5, 110, 7, 10, 60, 55, 7, 1.75, 65, 88, 3, 13, 0.75, 84, 11, 31, 33, 39, 10, 11, 107, 6, 7, 52, 49, 10, 2.5);
INSERT INTO public.match_details VALUES (767, 767, 43, 60, 5, 14, 1.67, 66, 5, 20, 34, 51, 13, 19, 93, 9, 5, 33, 35, 5, 1.67, 49, 73, 5, 7, 1.67, 46, 5, 11, 13, 28, 5, 10, 77, 5, 5, 39, 51, 5, 1.67);
INSERT INTO public.match_details VALUES (768, 768, 65, 96, 2, 15, 0.4, 89, 8, 24, 42, 47, 14, 15, 117, 6, 8, 54, 46, 9, 1.8, 81, 103, 8, 14, 1.6, 81, 2, 24, 36, 44, 11, 13, 123, 8, 9, 65, 53, 8, 1.6);
INSERT INTO public.match_details VALUES (769, 769, 67, 94, 6, 14, 1.5, 73, 5, 26, 33, 45, 18, 24, 109, 5, 9, 54, 50, 7, 1.75, 67, 88, 5, 15, 1.25, 80, 6, 16, 48, 60, 12, 15, 118, 11, 7, 53, 45, 9, 2.25);
INSERT INTO public.match_details VALUES (770, 770, 72, 94, 3, 6, 0.75, 83, 9, 28, 27, 32, 10, 12, 120, 13, 11, 52, 43, 17, 4.25, 78, 96, 9, 13, 2.25, 88, 3, 29, 42, 47, 11, 12, 137, 6, 17, 58, 42, 11, 2.75);
INSERT INTO public.match_details VALUES (771, 771, 42, 60, 0, 11, 0, 61, 1, 17, 34, 55, 18, 29, 93, 6, 10, 36, 39, 6, 2, 54, 74, 1, 13, 0.33, 49, 0, 18, 26, 53, 10, 20, 84, 3, 6, 43, 51, 10, 3.33);
INSERT INTO public.match_details VALUES (772, 772, 59, 95, 3, 15, 0.75, 61, 8, 22, 23, 37, 10, 16, 91, 6, 9, 45, 49, 11, 2.75, 63, 86, 8, 25, 2, 80, 3, 28, 35, 43, 16, 20, 106, 8, 11, 46, 43, 9, 2.25);
INSERT INTO public.match_details VALUES (773, 773, 54, 73, 6, 17, 2, 50, 7, 12, 25, 50, 15, 30, 63, 2, 3, 39, 62, 9, 3, 42, 66, 7, 16, 2.33, 56, 6, 13, 27, 48, 9, 16, 61, 3, 9, 32, 52, 3, 1);
INSERT INTO public.match_details VALUES (774, 774, 57, 79, 9, 6, 3, 49, 1, 17, 22, 44, 8, 16, 83, 3, 4, 38, 46, 10, 3.33, 49, 63, 1, 14, 0.33, 72, 9, 25, 26, 36, 14, 19, 91, 7, 10, 44, 48, 4, 1.33);
INSERT INTO public.match_details VALUES (775, 775, 75, 96, 7, 19, 1.75, 63, 2, 20, 32, 50, 10, 15, 101, 6, 3, 52, 51, 16, 4, 49, 77, 2, 14, 0.5, 77, 7, 25, 40, 51, 17, 22, 99, 4, 16, 44, 44, 3, 0.75);
INSERT INTO public.match_details VALUES (776, 776, 73, 98, 11, 13, 2.75, 73, 11, 15, 31, 42, 10, 13, 86, 6, 7, 51, 59, 11, 2.75, 67, 93, 11, 20, 2.75, 85, 11, 17, 43, 50, 7, 8, 97, 5, 11, 49, 51, 7, 1.75);
INSERT INTO public.match_details VALUES (777, 777, 80, 109, 8, 19, 1.6, 91, 11, 27, 38, 41, 22, 24, 103, 5, 9, 62, 60, 10, 2, 85, 112, 11, 21, 2.2, 90, 8, 24, 37, 41, 17, 18, 111, 6, 10, 65, 59, 9, 1.8);
INSERT INTO public.match_details VALUES (778, 778, 45, 64, 1, 11, 0.33, 64, 2, 21, 32, 50, 12, 18, 82, 4, 3, 35, 43, 9, 3, 56, 73, 2, 9, 0.67, 53, 1, 11, 28, 52, 17, 32, 98, 5, 9, 51, 52, 3, 1);
INSERT INTO public.match_details VALUES (779, 779, 78, 97, 7, 14, 1.75, 77, 8, 22, 40, 51, 13, 16, 125, 5, 9, 65, 52, 6, 1.5, 64, 90, 8, 13, 2, 83, 7, 31, 38, 45, 8, 9, 109, 5, 6, 47, 43, 9, 2.25);
INSERT INTO public.match_details VALUES (780, 780, 86, 117, 1, 27, 0.2, 101, 5, 28, 48, 47, 19, 18, 147, 7, 15, 69, 47, 16, 3.2, 77, 117, 5, 16, 1, 90, 1, 22, 44, 48, 12, 13, 142, 10, 16, 57, 40, 15, 3);
INSERT INTO public.match_details VALUES (781, 781, 48, 64, 6, 13, 2, 64, 4, 20, 35, 54, 6, 9, 96, 7, 9, 35, 36, 7, 2.33, 52, 73, 4, 9, 1.33, 51, 6, 12, 32, 62, 11, 21, 94, 3, 7, 39, 41, 9, 3);
INSERT INTO public.match_details VALUES (782, 782, 53, 73, 4, 11, 1.33, 51, 4, 14, 22, 43, 7, 13, 86, 4, 3, 41, 48, 8, 2.67, 45, 64, 4, 13, 1.33, 62, 4, 18, 34, 54, 16, 25, 96, 6, 8, 38, 40, 3, 1);
INSERT INTO public.match_details VALUES (783, 783, 58, 74, 6, 8, 2, 49, 2, 16, 28, 57, 9, 18, 73, 5, 8, 41, 56, 11, 3.67, 44, 59, 2, 10, 0.67, 66, 6, 29, 23, 34, 2, 3, 82, 6, 11, 34, 41, 8, 2.67);
INSERT INTO public.match_details VALUES (784, 784, 62, 87, 3, 14, 0.75, 79, 14, 18, 34, 43, 23, 29, 112, 3, 11, 57, 51, 2, 0.5, 80, 97, 14, 18, 3.5, 73, 3, 26, 36, 49, 18, 24, 100, 4, 2, 55, 55, 11, 2.75);
INSERT INTO public.match_details VALUES (785, 785, 83, 103, 10, 16, 2, 93, 7, 27, 42, 45, 15, 16, 113, 5, 8, 63, 56, 10, 2, 79, 102, 7, 9, 1.4, 87, 10, 32, 33, 37, 12, 13, 114, 9, 10, 64, 56, 8, 1.6);
INSERT INTO public.match_details VALUES (786, 786, 53, 85, 5, 14, 1.25, 83, 11, 24, 38, 45, 15, 18, 106, 8, 9, 41, 39, 7, 1.75, 79, 102, 11, 19, 2.75, 71, 5, 25, 36, 50, 18, 25, 107, 9, 7, 59, 55, 9, 2.25);
INSERT INTO public.match_details VALUES (787, 787, 73, 102, 4, 16, 0.8, 74, 9, 25, 32, 43, 14, 18, 114, 7, 4, 53, 46, 16, 3.2, 68, 91, 9, 17, 1.8, 86, 4, 29, 43, 50, 18, 20, 139, 11, 16, 55, 40, 4, 0.8);
INSERT INTO public.match_details VALUES (788, 788, 78, 102, 10, 26, 2, 90, 10, 28, 41, 45, 14, 15, 107, 8, 11, 58, 54, 10, 2, 70, 105, 10, 15, 2, 76, 10, 18, 37, 48, 14, 18, 94, 5, 10, 49, 52, 11, 2.2);
INSERT INTO public.match_details VALUES (789, 789, 66, 82, 9, 24, 2.25, 86, 3, 28, 42, 48, 10, 11, 106, 12, 7, 52, 49, 5, 1.25, 60, 96, 3, 10, 0.75, 58, 9, 18, 23, 39, 9, 15, 88, 5, 5, 50, 57, 7, 1.75);
INSERT INTO public.match_details VALUES (790, 790, 58, 73, 9, 16, 3, 47, 3, 14, 22, 46, 7, 14, 66, 6, 4, 43, 65, 6, 2, 31, 56, 3, 9, 1, 57, 9, 18, 21, 36, 10, 17, 57, 4, 6, 24, 42, 4, 1.33);
INSERT INTO public.match_details VALUES (791, 791, 71, 89, 0, 13, 0, 83, 3, 27, 36, 43, 17, 20, 129, 10, 9, 61, 47, 10, 2.5, 68, 93, 3, 10, 0.75, 76, 0, 19, 34, 44, 11, 14, 122, 3, 10, 56, 46, 9, 2.25);
INSERT INTO public.match_details VALUES (792, 792, 56, 74, 7, 13, 2.33, 48, 3, 20, 22, 45, 5, 10, 82, 7, 3, 38, 46, 11, 3.67, 37, 60, 3, 12, 1, 61, 7, 26, 20, 32, 6, 9, 90, 4, 11, 31, 34, 3, 1);
INSERT INTO public.match_details VALUES (793, 793, 57, 77, 3, 10, 0.75, 82, 9, 27, 33, 40, 11, 13, 91, 7, 12, 47, 52, 7, 1.75, 75, 96, 9, 14, 2.25, 67, 3, 22, 35, 52, 16, 23, 93, 4, 7, 54, 58, 12, 3);
INSERT INTO public.match_details VALUES (794, 794, 58, 73, 7, 12, 2.33, 46, 2, 5, 26, 56, 9, 19, 71, 0, 4, 41, 58, 10, 3.33, 42, 57, 2, 11, 0.67, 61, 7, 13, 29, 47, 10, 16, 82, 5, 10, 36, 44, 4, 1.33);
INSERT INTO public.match_details VALUES (795, 795, 51, 84, 2, 17, 0.5, 75, 7, 24, 36, 48, 11, 14, 104, 8, 13, 40, 38, 9, 2.25, 68, 94, 7, 19, 1.75, 67, 2, 20, 32, 47, 15, 22, 102, 12, 9, 48, 47, 13, 3.25);
INSERT INTO public.match_details VALUES (796, 796, 66, 92, 5, 18, 1.25, 85, 5, 40, 27, 31, 11, 12, 114, 10, 6, 53, 46, 8, 2, 70, 98, 5, 13, 1.25, 74, 5, 15, 42, 56, 10, 13, 104, 8, 8, 59, 57, 6, 1.5);
INSERT INTO public.match_details VALUES (797, 797, 66, 97, 5, 14, 1.25, 74, 5, 21, 37, 50, 17, 22, 115, 5, 11, 56, 49, 5, 1.25, 67, 93, 5, 19, 1.25, 83, 5, 27, 38, 45, 16, 19, 100, 11, 5, 51, 51, 11, 2.75);
INSERT INTO public.match_details VALUES (798, 798, 70, 97, 10, 16, 2.5, 63, 7, 13, 31, 49, 14, 22, 95, 6, 6, 51, 54, 9, 2.25, 57, 84, 7, 21, 1.75, 81, 10, 28, 30, 37, 16, 19, 104, 5, 9, 44, 42, 6, 1.5);
INSERT INTO public.match_details VALUES (799, 799, 66, 86, 10, 19, 2.5, 85, 3, 22, 52, 61, 21, 24, 109, 11, 19, 49, 45, 7, 1.75, 62, 97, 3, 11, 0.75, 67, 10, 23, 27, 40, 11, 16, 81, 5, 7, 40, 49, 19, 4.75);
INSERT INTO public.match_details VALUES (800, 800, 58, 85, 3, 21, 0.75, 83, 5, 30, 37, 44, 19, 22, 106, 9, 6, 50, 47, 5, 1.25, 68, 98, 5, 15, 1.25, 64, 3, 19, 32, 50, 17, 26, 101, 6, 5, 57, 56, 6, 1.5);
INSERT INTO public.match_details VALUES (801, 801, 56, 74, 7, 21, 2.33, 53, 7, 11, 27, 50, 8, 15, 74, 3, 5, 41, 55, 8, 2.67, 38, 67, 7, 14, 2.33, 53, 7, 14, 27, 50, 12, 22, 60, 3, 8, 26, 43, 5, 1.67);
INSERT INTO public.match_details VALUES (802, 802, 58, 73, 13, 8, 4.33, 48, 4, 9, 24, 50, 7, 14, 75, 6, 4, 39, 52, 6, 2, 43, 60, 4, 12, 1.33, 65, 13, 24, 22, 33, 3, 4, 74, 3, 6, 35, 47, 4, 1.33);
INSERT INTO public.match_details VALUES (803, 803, 50, 76, 5, 15, 1.67, 48, 3, 16, 23, 47, 14, 29, 68, 3, 7, 37, 54, 8, 2.67, 43, 62, 3, 14, 1, 61, 5, 19, 21, 34, 7, 11, 74, 9, 8, 33, 45, 7, 2.33);
INSERT INTO public.match_details VALUES (804, 804, 56, 76, 3, 9, 1, 58, 7, 15, 25, 43, 8, 13, 88, 7, 7, 40, 45, 13, 4.33, 52, 72, 7, 14, 2.33, 67, 3, 18, 26, 38, 7, 10, 90, 7, 13, 38, 42, 7, 2.33);
INSERT INTO public.match_details VALUES (805, 805, 53, 73, 5, 14, 1.67, 40, 2, 6, 23, 57, 15, 37, 68, 4, 5, 35, 51, 13, 4.33, 36, 57, 2, 17, 0.67, 59, 5, 21, 22, 37, 9, 15, 76, 5, 13, 29, 38, 5, 1.67);
INSERT INTO public.match_details VALUES (806, 806, 37, 60, 1, 17, 0.33, 59, 1, 20, 25, 42, 12, 20, 85, 5, 14, 33, 39, 3, 1, 48, 74, 1, 15, 0.33, 43, 1, 13, 21, 48, 11, 25, 70, 4, 3, 33, 47, 14, 4.67);
INSERT INTO public.match_details VALUES (807, 807, 68, 92, 6, 16, 1.5, 73, 4, 30, 36, 49, 10, 13, 100, 8, 8, 48, 48, 14, 3.5, 59, 89, 4, 16, 1, 76, 6, 25, 39, 51, 9, 11, 103, 6, 14, 47, 46, 8, 2);
INSERT INTO public.match_details VALUES (808, 808, 65, 86, 3, 15, 0.75, 87, 6, 28, 33, 37, 14, 16, 113, 8, 8, 47, 42, 15, 3.75, 74, 100, 6, 13, 1.5, 71, 3, 22, 31, 43, 11, 15, 119, 1, 15, 60, 50, 8, 2);
INSERT INTO public.match_details VALUES (809, 809, 79, 116, 9, 21, 1.8, 90, 11, 29, 42, 46, 18, 20, 111, 6, 8, 65, 59, 5, 1, 81, 113, 11, 23, 2.2, 95, 9, 31, 47, 49, 20, 21, 120, 14, 5, 62, 52, 8, 1.6);
INSERT INTO public.match_details VALUES (810, 810, 75, 106, 6, 19, 1.5, 87, 6, 25, 45, 51, 22, 25, 123, 9, 11, 61, 50, 8, 2, 75, 108, 6, 21, 1.5, 87, 6, 23, 39, 44, 21, 24, 120, 10, 8, 58, 48, 11, 2.75);
INSERT INTO public.match_details VALUES (811, 811, 60, 84, 0, 15, 0, 74, 4, 16, 32, 43, 9, 12, 107, 8, 9, 52, 49, 8, 2, 65, 88, 4, 14, 1, 69, 0, 21, 29, 42, 14, 20, 102, 7, 8, 52, 51, 9, 2.25);
INSERT INTO public.match_details VALUES (812, 812, 70, 91, 2, 16, 0.5, 89, 4, 29, 38, 42, 20, 22, 122, 12, 4, 61, 50, 7, 1.75, 67, 101, 4, 12, 1, 75, 2, 17, 46, 61, 18, 24, 121, 8, 7, 59, 49, 4, 1);
INSERT INTO public.match_details VALUES (813, 813, 76, 106, 5, 18, 1, 84, 6, 29, 29, 34, 15, 17, 110, 5, 11, 59, 54, 12, 2.4, 78, 105, 6, 21, 1.2, 88, 5, 30, 36, 40, 19, 21, 126, 9, 12, 61, 48, 11, 2.2);
INSERT INTO public.match_details VALUES (814, 814, 75, 100, 5, 16, 1, 100, 7, 23, 54, 54, 22, 22, 139, 16, 7, 60, 43, 10, 2, 77, 112, 7, 12, 1.4, 84, 5, 18, 47, 55, 18, 21, 130, 7, 10, 63, 48, 7, 1.4);
INSERT INTO public.match_details VALUES (815, 815, 65, 92, 4, 19, 1, 88, 16, 21, 42, 47, 16, 18, 121, 12, 11, 54, 45, 7, 1.75, 71, 100, 12, 12, 3, 73, 9, 26, 31, 42, 14, 19, 108, 11, 7, 48, 44, 11, 2.75);
INSERT INTO public.match_details VALUES (816, 816, 74, 100, 4, 11, 1, 84, 7, 24, 41, 48, 10, 11, 127, 11, 14, 61, 48, 9, 2.25, 73, 98, 3, 14, 0.75, 89, 7, 33, 39, 43, 6, 6, 123, 9, 9, 56, 46, 14, 3.5);
INSERT INTO public.match_details VALUES (817, 817, 85, 118, 7, 15, 1.4, 92, 2, 19, 54, 58, 17, 18, 149, 14, 9, 73, 49, 5, 1, 82, 115, 2, 23, 0.4, 103, 7, 23, 54, 52, 24, 23, 139, 8, 5, 71, 51, 9, 1.8);
INSERT INTO public.match_details VALUES (818, 818, 71, 104, 7, 17, 1.4, 80, 4, 21, 44, 55, 18, 22, 118, 7, 12, 54, 46, 10, 2, 71, 98, 4, 18, 0.8, 87, 7, 28, 38, 43, 14, 16, 113, 11, 10, 55, 49, 12, 2.4);
INSERT INTO public.match_details VALUES (819, 819, 76, 102, 7, 14, 1.4, 99, 13, 28, 43, 43, 18, 18, 117, 11, 7, 61, 52, 8, 1.6, 84, 112, 13, 13, 2.6, 88, 7, 21, 41, 46, 22, 25, 125, 12, 8, 64, 51, 7, 1.4);
INSERT INTO public.match_details VALUES (820, 820, 84, 119, 6, 27, 1.2, 84, 5, 28, 36, 42, 23, 27, 128, 9, 9, 70, 55, 8, 1.6, 70, 109, 5, 25, 1, 92, 6, 36, 34, 36, 15, 16, 118, 10, 8, 56, 47, 9, 1.8);
INSERT INTO public.match_details VALUES (821, 821, 62, 74, 6, 15, 2, 65, 3, 16, 41, 63, 23, 35, 90, 7, 3, 45, 50, 11, 3.67, 44, 72, 3, 7, 1, 59, 6, 17, 27, 45, 12, 20, 86, 7, 11, 38, 44, 3, 1);
INSERT INTO public.match_details VALUES (822, 822, 67, 90, 9, 17, 2.25, 74, 10, 19, 32, 43, 16, 21, 99, 10, 9, 50, 51, 8, 2, 62, 89, 10, 15, 2.5, 73, 9, 13, 38, 52, 16, 21, 98, 5, 8, 43, 44, 9, 2.25);
INSERT INTO public.match_details VALUES (823, 823, 85, 112, 6, 11, 1.2, 94, 3, 26, 50, 53, 15, 15, 136, 11, 18, 62, 46, 17, 3.4, 85, 108, 3, 14, 0.6, 101, 6, 32, 47, 46, 18, 17, 134, 11, 17, 64, 48, 18, 3.6);
INSERT INTO public.match_details VALUES (824, 824, 71, 94, 5, 13, 1.25, 66, 8, 19, 27, 40, 13, 19, 106, 5, 5, 58, 55, 8, 2, 60, 79, 8, 13, 2, 81, 5, 27, 40, 49, 15, 18, 118, 10, 8, 47, 40, 5, 1.25);
INSERT INTO public.match_details VALUES (825, 825, 69, 101, 8, 14, 1.6, 78, 3, 23, 34, 43, 10, 12, 117, 11, 6, 55, 47, 6, 1.2, 67, 95, 3, 17, 0.6, 87, 8, 22, 36, 41, 20, 22, 118, 12, 6, 58, 49, 6, 1.2);
INSERT INTO public.match_details VALUES (826, 826, 80, 103, 9, 18, 2.25, 88, 12, 30, 35, 39, 12, 13, 115, 9, 8, 60, 52, 11, 2.75, 75, 105, 6, 17, 1.5, 85, 15, 31, 34, 40, 19, 22, 118, 5, 11, 61, 52, 8, 2);
INSERT INTO public.match_details VALUES (827, 827, 77, 98, 2, 24, 0.5, 88, 11, 20, 50, 56, 21, 23, 122, 10, 7, 64, 52, 11, 2.75, 65, 103, 5, 15, 1.25, 74, 6, 11, 47, 63, 13, 17, 113, 6, 11, 53, 47, 7, 1.75);
INSERT INTO public.match_details VALUES (828, 828, 55, 83, 4, 12, 1, 80, 10, 23, 34, 42, 8, 10, 119, 6, 10, 48, 40, 3, 0.75, 79, 96, 10, 16, 2.5, 71, 4, 19, 39, 54, 22, 30, 113, 7, 3, 59, 52, 10, 2.5);
INSERT INTO public.match_details VALUES (829, 829, 71, 97, 2, 24, 0.5, 97, 5, 33, 41, 42, 28, 28, 128, 8, 9, 60, 47, 9, 2.25, 78, 110, 5, 13, 1.25, 73, 2, 28, 32, 43, 22, 30, 134, 10, 9, 64, 48, 9, 2.25);
INSERT INTO public.match_details VALUES (830, 830, 69, 97, 9, 18, 2.25, 72, 14, 13, 31, 43, 20, 27, 85, 5, 5, 52, 61, 8, 2, 61, 88, 14, 16, 3.5, 79, 9, 26, 32, 40, 20, 25, 98, 10, 8, 42, 43, 5, 1.25);
INSERT INTO public.match_details VALUES (831, 831, 58, 85, 7, 13, 2.33, 56, 7, 12, 31, 55, 19, 33, 66, 2, 6, 41, 62, 10, 3.33, 52, 72, 7, 16, 2.33, 72, 7, 21, 33, 45, 15, 20, 87, 11, 10, 39, 45, 6, 2);
INSERT INTO public.match_details VALUES (832, 832, 72, 105, 10, 17, 2, 84, 5, 15, 48, 57, 29, 34, 125, 5, 15, 53, 42, 9, 1.8, 81, 106, 5, 22, 1, 88, 10, 25, 32, 36, 15, 17, 123, 10, 9, 61, 50, 15, 3);
INSERT INTO public.match_details VALUES (833, 833, 57, 73, 4, 14, 1.33, 43, 4, 7, 17, 39, 12, 27, 60, 2, 1, 42, 70, 11, 3.67, 37, 58, 4, 15, 1.33, 59, 4, 9, 30, 50, 22, 37, 66, 3, 11, 32, 48, 1, 0.33);
INSERT INTO public.match_details VALUES (834, 834, 74, 103, 8, 12, 1.6, 91, 4, 31, 44, 48, 16, 17, 121, 18, 14, 53, 44, 13, 2.6, 77, 108, 4, 17, 0.8, 91, 8, 24, 43, 47, 23, 25, 116, 8, 13, 59, 51, 14, 2.8);
INSERT INTO public.match_details VALUES (835, 835, 53, 73, 5, 15, 1.67, 47, 4, 7, 25, 53, 10, 21, 65, 6, 1, 38, 58, 10, 3.33, 31, 60, 4, 13, 1.33, 58, 5, 14, 27, 46, 13, 22, 73, 5, 10, 26, 36, 1, 0.33);
INSERT INTO public.match_details VALUES (836, 836, 53, 73, 9, 14, 3, 47, 3, 15, 19, 40, 13, 27, 69, 5, 4, 38, 55, 6, 2, 40, 62, 3, 15, 1, 59, 9, 24, 21, 35, 10, 16, 67, 5, 6, 33, 49, 4, 1.33);
INSERT INTO public.match_details VALUES (837, 837, 56, 88, 2, 15, 0.5, 77, 12, 19, 29, 37, 9, 11, 109, 7, 8, 48, 44, 6, 1.5, 67, 93, 6, 16, 1.5, 72, 5, 8, 36, 50, 13, 18, 122, 12, 6, 53, 43, 8, 2);
INSERT INTO public.match_details VALUES (838, 838, 55, 73, 9, 9, 3, 41, 3, 7, 21, 51, 11, 26, 56, 4, 4, 36, 64, 10, 3.33, 42, 57, 3, 16, 1, 63, 9, 15, 24, 38, 11, 17, 66, 3, 10, 35, 53, 4, 1.33);
INSERT INTO public.match_details VALUES (839, 839, 74, 94, 7, 19, 1.75, 76, 2, 17, 37, 48, 17, 22, 113, 7, 9, 54, 48, 13, 3.25, 55, 86, 2, 10, 0.5, 75, 7, 15, 43, 57, 22, 29, 114, 9, 13, 44, 39, 9, 2.25);
INSERT INTO public.match_details VALUES (840, 840, 55, 76, 7, 8, 2.33, 45, 2, 18, 22, 48, 8, 17, 75, 4, 5, 38, 51, 10, 3.33, 44, 57, 2, 12, 0.67, 68, 7, 16, 31, 45, 11, 16, 82, 7, 10, 37, 45, 5, 1.67);
INSERT INTO public.match_details VALUES (841, 841, 55, 80, 3, 23, 0.75, 77, 5, 35, 25, 32, 9, 11, 93, 12, 8, 44, 47, 8, 2, 59, 93, 5, 16, 1.25, 57, 3, 13, 30, 52, 10, 17, 92, 6, 8, 45, 49, 9, 2.25);
INSERT INTO public.match_details VALUES (842, 842, 54, 74, 2, 14, 0.67, 48, 3, 13, 26, 54, 18, 37, 68, 2, 5, 43, 63, 9, 3, 40, 59, 3, 11, 1, 60, 2, 14, 32, 53, 9, 15, 89, 8, 9, 32, 36, 5, 1.67);
INSERT INTO public.match_details VALUES (843, 843, 43, 59, 2, 13, 0.67, 60, 3, 16, 21, 35, 5, 8, 77, 6, 8, 34, 44, 7, 2.33, 53, 74, 3, 14, 1, 46, 2, 4, 30, 65, 18, 39, 76, 1, 7, 42, 55, 8, 2.67);
INSERT INTO public.match_details VALUES (844, 844, 73, 104, 4, 24, 0.8, 85, 4, 30, 34, 40, 16, 18, 124, 7, 10, 62, 50, 7, 1.4, 63, 98, 4, 13, 0.8, 80, 4, 16, 49, 61, 21, 26, 114, 13, 7, 49, 43, 10, 2);
INSERT INTO public.match_details VALUES (845, 845, 75, 98, 1, 23, 0.25, 87, 2, 11, 51, 58, 31, 35, 124, 6, 10, 64, 52, 10, 2.5, 70, 101, 2, 14, 0.5, 75, 1, 9, 34, 45, 24, 32, 108, 3, 10, 58, 54, 10, 2.5);
INSERT INTO public.match_details VALUES (846, 846, 52, 86, 3, 14, 0.75, 76, 7, 21, 30, 39, 14, 18, 76, 7, 11, 40, 53, 9, 2.25, 70, 98, 7, 22, 1.75, 72, 3, 15, 35, 48, 14, 19, 90, 7, 9, 52, 58, 11, 2.75);
INSERT INTO public.match_details VALUES (847, 847, 81, 114, 8, 15, 1.6, 95, 5, 13, 64, 67, 34, 35, 156, 6, 15, 66, 42, 7, 1.4, 88, 111, 5, 16, 1, 99, 8, 30, 40, 40, 16, 16, 147, 13, 7, 68, 46, 15, 3);
INSERT INTO public.match_details VALUES (848, 848, 37, 48, 0, 9, 0, 65, 8, 23, 24, 36, 18, 27, 91, 5, 10, 31, 34, 6, 2, 59, 74, 8, 9, 2.67, 39, 0, 10, 19, 48, 8, 20, 81, 1, 6, 41, 51, 10, 3.33);
INSERT INTO public.match_details VALUES (849, 849, 68, 92, 7, 9, 1.75, 78, 4, 28, 41, 52, 25, 32, 114, 11, 8, 42, 37, 19, 4.75, 72, 92, 5, 13, 1.25, 84, 8, 24, 47, 55, 33, 39, 131, 5, 19, 59, 45, 8, 2);
INSERT INTO public.match_details VALUES (850, 850, 58, 82, 4, 14, 1.33, 55, 2, 15, 22, 40, 10, 18, 84, 6, 5, 46, 55, 8, 2.67, 43, 67, 2, 12, 0.67, 68, 4, 18, 27, 39, 14, 20, 91, 11, 8, 36, 40, 5, 1.67);
INSERT INTO public.match_details VALUES (851, 851, 57, 76, 9, 11, 3, 63, 8, 16, 28, 44, 17, 26, 84, 10, 5, 42, 50, 6, 2, 48, 73, 8, 10, 2.67, 65, 9, 23, 22, 33, 8, 12, 78, 9, 6, 35, 45, 5, 1.67);
INSERT INTO public.match_details VALUES (852, 852, 37, 57, 3, 15, 1, 59, 8, 13, 25, 42, 14, 23, 72, 8, 5, 33, 46, 1, 0.33, 48, 74, 6, 15, 2, 42, 7, 13, 15, 35, 8, 19, 60, 2, 1, 37, 62, 5, 1.67);
INSERT INTO public.match_details VALUES (853, 853, 67, 99, 8, 18, 2, 72, 1, 20, 33, 45, 13, 18, 95, 7, 7, 51, 54, 8, 2, 62, 92, 1, 20, 0.25, 81, 8, 12, 33, 40, 15, 18, 106, 10, 8, 54, 51, 7, 1.75);
INSERT INTO public.match_details VALUES (854, 854, 71, 101, 6, 17, 1.5, 88, 8, 29, 42, 47, 23, 26, 118, 11, 6, 57, 48, 8, 2, 79, 108, 4, 20, 1, 84, 9, 21, 48, 57, 24, 28, 126, 8, 8, 69, 55, 6, 1.5);
INSERT INTO public.match_details VALUES (855, 855, 71, 97, 5, 12, 1.25, 56, 2, 11, 33, 58, 11, 19, 97, 10, 7, 53, 55, 13, 3.25, 49, 73, 2, 17, 0.5, 85, 5, 24, 41, 48, 9, 10, 101, 9, 13, 40, 40, 7, 1.75);
INSERT INTO public.match_details VALUES (856, 856, 50, 74, 3, 8, 1, 48, 0, 9, 30, 62, 11, 22, 75, 2, 7, 37, 49, 10, 3.33, 44, 57, 0, 9, 0, 66, 3, 19, 35, 53, 14, 21, 83, 12, 10, 37, 45, 7, 2.33);
INSERT INTO public.match_details VALUES (857, 857, 66, 94, 2, 13, 0.5, 87, 5, 25, 40, 45, 14, 16, 107, 11, 15, 55, 51, 9, 2.25, 74, 101, 5, 14, 1.25, 81, 2, 25, 37, 45, 14, 17, 106, 11, 9, 54, 51, 15, 3.75);
INSERT INTO public.match_details VALUES (858, 858, 46, 64, 1, 11, 0.33, 64, 6, 14, 36, 56, 17, 26, 88, 7, 10, 36, 41, 9, 3, 53, 73, 6, 9, 2, 53, 1, 12, 32, 60, 21, 39, 78, 5, 9, 37, 47, 10, 3.33);
INSERT INTO public.match_details VALUES (859, 859, 57, 84, 9, 12, 2.25, 65, 7, 17, 34, 52, 20, 30, 91, 7, 6, 43, 47, 5, 1.25, 57, 84, 7, 19, 1.75, 72, 9, 17, 32, 44, 14, 19, 101, 4, 5, 44, 44, 6, 1.5);
INSERT INTO public.match_details VALUES (860, 860, 53, 66, 2, 13, 0.67, 64, 4, 20, 21, 32, 13, 20, 90, 6, 4, 43, 48, 8, 2.67, 51, 74, 4, 10, 1.33, 53, 2, 16, 22, 41, 11, 20, 85, 2, 8, 43, 51, 4, 1.33);
INSERT INTO public.match_details VALUES (861, 861, 90, 112, 8, 19, 1.6, 91, 3, 16, 44, 48, 26, 28, 130, 5, 12, 69, 53, 13, 2.6, 78, 106, 3, 15, 0.6, 93, 8, 9, 49, 52, 28, 30, 128, 7, 13, 63, 49, 12, 2.4);
INSERT INTO public.match_details VALUES (862, 862, 70, 98, 10, 9, 2, 84, 5, 24, 43, 51, 23, 27, 117, 11, 19, 49, 42, 11, 2.2, 75, 100, 5, 16, 1, 89, 10, 20, 43, 48, 21, 23, 111, 10, 11, 51, 46, 19, 3.8);
INSERT INTO public.match_details VALUES (863, 863, 72, 110, 4, 20, 0.8, 82, 6, 23, 36, 43, 26, 31, 106, 9, 8, 51, 48, 17, 3.4, 77, 109, 6, 27, 1.2, 90, 4, 17, 52, 57, 26, 28, 121, 10, 17, 63, 52, 8, 1.6);
INSERT INTO public.match_details VALUES (864, 864, 55, 85, 2, 15, 0.5, 81, 8, 23, 45, 55, 25, 30, 113, 7, 12, 51, 45, 2, 0.5, 73, 97, 8, 16, 2, 70, 2, 16, 46, 65, 23, 32, 114, 9, 2, 53, 46, 12, 3);
INSERT INTO public.match_details VALUES (865, 865, 83, 105, 6, 22, 1.2, 81, 2, 22, 46, 56, 20, 24, 126, 6, 10, 67, 53, 10, 2, 65, 96, 2, 15, 0.4, 83, 6, 19, 37, 44, 14, 16, 119, 7, 10, 53, 45, 10, 2);
INSERT INTO public.match_details VALUES (866, 866, 55, 73, 9, 18, 3, 43, 3, 14, 17, 39, 10, 23, 53, 0, 2, 36, 68, 10, 3.33, 36, 59, 3, 16, 1, 55, 9, 16, 24, 43, 16, 29, 65, 1, 10, 31, 48, 2, 0.67);
INSERT INTO public.match_details VALUES (867, 867, 45, 60, 3, 13, 1, 66, 5, 22, 31, 46, 18, 27, 73, 4, 6, 35, 48, 7, 2.33, 55, 73, 5, 7, 1.67, 47, 3, 12, 21, 44, 15, 31, 71, 4, 7, 44, 62, 6, 2);
INSERT INTO public.match_details VALUES (868, 868, 77, 106, 4, 21, 0.8, 101, 4, 24, 55, 54, 29, 28, 160, 16, 14, 63, 39, 10, 2, 78, 114, 4, 13, 0.8, 84, 4, 18, 45, 53, 16, 19, 134, 11, 10, 60, 45, 14, 2.8);
INSERT INTO public.match_details VALUES (869, 869, 68, 103, 7, 18, 1.4, 82, 12, 18, 41, 50, 20, 24, 114, 12, 10, 53, 46, 8, 1.6, 74, 103, 8, 21, 1.6, 85, 14, 24, 40, 47, 19, 22, 127, 11, 8, 56, 44, 10, 2);
INSERT INTO public.match_details VALUES (870, 870, 72, 111, 8, 18, 1.6, 85, 3, 15, 51, 60, 19, 22, 120, 2, 6, 55, 46, 9, 1.8, 87, 111, 3, 26, 0.6, 93, 8, 13, 60, 64, 28, 30, 131, 9, 9, 78, 60, 6, 1.2);
INSERT INTO public.match_details VALUES (871, 871, 74, 95, 3, 12, 0.75, 86, 4, 30, 36, 41, 9, 10, 126, 5, 11, 60, 48, 11, 2.75, 74, 94, 4, 8, 1, 83, 3, 29, 42, 50, 21, 25, 124, 8, 11, 59, 48, 11, 2.75);
INSERT INTO public.match_details VALUES (872, 872, 53, 74, 8, 14, 2.67, 60, 3, 8, 32, 53, 21, 35, 83, 5, 6, 36, 43, 9, 3, 44, 70, 3, 10, 1, 60, 8, 10, 21, 35, 15, 25, 88, 9, 9, 35, 40, 6, 2);
INSERT INTO public.match_details VALUES (873, 873, 56, 73, 5, 13, 1.67, 47, 3, 11, 24, 51, 10, 21, 69, 3, 6, 43, 62, 8, 2.67, 38, 58, 3, 11, 1, 60, 5, 24, 21, 35, 5, 8, 71, 5, 8, 29, 41, 6, 2);
INSERT INTO public.match_details VALUES (874, 874, 61, 75, 7, 11, 2.33, 55, 4, 16, 32, 58, 17, 30, 81, 2, 9, 47, 58, 7, 2.33, 48, 65, 4, 10, 1.33, 64, 7, 13, 34, 53, 19, 29, 72, 4, 7, 35, 49, 9, 3);
INSERT INTO public.match_details VALUES (875, 875, 51, 66, 2, 14, 0.67, 66, 6, 14, 34, 51, 22, 33, 83, 10, 5, 42, 51, 7, 2.33, 51, 74, 6, 8, 2, 52, 2, 10, 27, 51, 12, 23, 83, 5, 7, 40, 48, 5, 1.67);
INSERT INTO public.match_details VALUES (876, 876, 56, 73, 3, 9, 1, 56, 6, 11, 30, 53, 22, 39, 82, 3, 8, 43, 52, 10, 3.33, 50, 64, 6, 8, 2, 64, 3, 19, 24, 37, 16, 25, 90, 11, 10, 36, 40, 8, 2.67);
INSERT INTO public.match_details VALUES (877, 877, 69, 104, 6, 27, 1.2, 77, 8, 14, 40, 51, 21, 27, 99, 3, 10, 53, 54, 10, 2, 73, 104, 8, 27, 1.6, 77, 6, 18, 41, 53, 19, 24, 103, 4, 10, 55, 53, 10, 2);
INSERT INTO public.match_details VALUES (878, 878, 50, 66, 4, 13, 1.33, 64, 5, 11, 37, 57, 28, 43, 83, 7, 7, 41, 49, 5, 1.67, 52, 74, 5, 10, 1.67, 53, 4, 11, 30, 56, 18, 33, 72, 4, 5, 39, 54, 8, 2.67);
INSERT INTO public.match_details VALUES (879, 879, 54, 74, 6, 12, 2, 45, 3, 15, 22, 48, 10, 22, 65, 3, 3, 38, 58, 10, 3.33, 37, 55, 3, 10, 1, 62, 6, 26, 28, 45, 17, 27, 74, 6, 10, 31, 42, 3, 1);
INSERT INTO public.match_details VALUES (880, 880, 54, 78, 1, 13, 0.33, 51, 4, 16, 26, 50, 9, 17, 73, 5, 5, 38, 52, 15, 5, 44, 67, 4, 16, 1.33, 65, 1, 22, 29, 44, 11, 16, 86, 7, 15, 35, 41, 5, 1.67);
INSERT INTO public.match_details VALUES (881, 881, 61, 74, 9, 13, 3, 60, 6, 19, 25, 41, 10, 16, 86, 11, 6, 45, 52, 7, 2.33, 42, 70, 6, 10, 2, 61, 9, 21, 22, 36, 12, 19, 72, 3, 7, 30, 42, 6, 2);
INSERT INTO public.match_details VALUES (882, 882, 85, 111, 3, 12, 0.6, 94, 6, 26, 42, 44, 27, 28, 146, 9, 13, 69, 47, 13, 2.6, 82, 106, 6, 12, 1.2, 99, 3, 32, 43, 43, 24, 24, 153, 11, 13, 63, 41, 13, 2.6);
INSERT INTO public.match_details VALUES (883, 883, 70, 99, 4, 22, 0.8, 88, 4, 33, 39, 44, 23, 26, 117, 10, 14, 55, 47, 11, 2.2, 68, 105, 4, 17, 0.8, 77, 4, 19, 39, 50, 13, 16, 106, 9, 11, 50, 47, 14, 2.8);
INSERT INTO public.match_details VALUES (884, 884, 46, 64, 3, 15, 1, 63, 7, 14, 32, 50, 11, 17, 78, 7, 6, 37, 47, 6, 2, 46, 73, 3, 10, 1, 49, 6, 9, 28, 57, 11, 22, 71, 2, 6, 37, 52, 6, 2);
INSERT INTO public.match_details VALUES (885, 885, 55, 80, 5, 10, 1.67, 57, 3, 8, 37, 64, 18, 31, 76, 2, 7, 41, 54, 9, 3, 57, 71, 3, 14, 1, 70, 5, 7, 44, 62, 25, 35, 92, 9, 9, 47, 51, 7, 2.33);
INSERT INTO public.match_details VALUES (886, 886, 68, 106, 7, 9, 1.4, 75, 7, 27, 35, 46, 12, 16, 106, 4, 8, 53, 50, 8, 1.6, 84, 98, 7, 23, 1.4, 97, 7, 26, 47, 48, 18, 18, 136, 12, 8, 69, 51, 8, 1.6);
INSERT INTO public.match_details VALUES (887, 887, 70, 103, 3, 19, 0.6, 81, 6, 24, 40, 49, 20, 24, 125, 9, 10, 60, 48, 7, 1.4, 75, 104, 6, 23, 1.2, 84, 3, 34, 37, 44, 16, 19, 110, 6, 7, 59, 54, 10, 2);
INSERT INTO public.match_details VALUES (888, 888, 40, 59, 4, 20, 1.33, 64, 4, 18, 30, 46, 17, 26, 75, 4, 6, 33, 44, 3, 1, 48, 73, 4, 9, 1.33, 39, 4, 6, 20, 51, 11, 28, 65, 4, 3, 38, 58, 6, 2);
INSERT INTO public.match_details VALUES (889, 889, 57, 73, 4, 11, 1.33, 52, 0, 13, 31, 59, 19, 36, 82, 1, 6, 41, 50, 12, 4, 39, 59, 0, 7, 0, 62, 4, 25, 20, 32, 10, 16, 88, 9, 12, 33, 38, 6, 2);
INSERT INTO public.match_details VALUES (890, 890, 47, 74, 5, 15, 1.67, 35, 0, 6, 18, 51, 11, 31, 70, 3, 2, 37, 53, 5, 1.67, 30, 49, 0, 14, 0, 59, 5, 13, 25, 42, 16, 27, 70, 12, 5, 28, 40, 2, 0.67);
INSERT INTO public.match_details VALUES (891, 891, 79, 105, 6, 23, 1.2, 95, 5, 25, 34, 35, 13, 13, 131, 15, 9, 60, 46, 13, 2.6, 70, 111, 5, 16, 1, 82, 6, 18, 41, 50, 20, 24, 122, 7, 13, 56, 46, 9, 1.8);
INSERT INTO public.match_details VALUES (892, 892, 69, 90, 4, 16, 1, 84, 7, 28, 31, 36, 15, 17, 103, 10, 4, 54, 52, 11, 2.75, 68, 98, 7, 14, 1.75, 74, 4, 19, 35, 47, 22, 29, 108, 5, 11, 57, 53, 4, 1);
INSERT INTO public.match_details VALUES (893, 893, 69, 93, 6, 15, 1.5, 77, 5, 21, 41, 53, 25, 32, 111, 10, 8, 50, 45, 13, 3.25, 60, 89, 5, 12, 1.25, 78, 6, 20, 38, 48, 18, 23, 105, 9, 13, 47, 45, 8, 2);
INSERT INTO public.match_details VALUES (894, 894, 76, 101, 10, 13, 2.5, 83, 7, 26, 39, 46, 20, 24, 117, 13, 11, 55, 47, 11, 2.75, 74, 102, 7, 19, 1.75, 88, 10, 24, 47, 53, 32, 36, 122, 4, 11, 56, 46, 11, 2.75);
INSERT INTO public.match_details VALUES (895, 895, 69, 100, 3, 18, 0.75, 73, 8, 16, 38, 52, 20, 27, 110, 5, 14, 59, 54, 7, 1.75, 65, 91, 8, 18, 2, 82, 3, 26, 40, 48, 17, 20, 107, 10, 7, 43, 40, 14, 3.5);
INSERT INTO public.match_details VALUES (896, 896, 54, 73, 10, 15, 3.33, 48, 6, 11, 27, 56, 14, 29, 61, 3, 3, 37, 61, 7, 2.33, 40, 62, 6, 14, 2, 58, 10, 16, 26, 44, 15, 25, 63, 4, 7, 31, 49, 3, 1);
INSERT INTO public.match_details VALUES (897, 897, 71, 106, 7, 15, 1.4, 83, 5, 26, 30, 36, 20, 24, 114, 5, 14, 52, 46, 12, 2.4, 82, 104, 5, 21, 1, 91, 7, 26, 42, 46, 24, 26, 131, 13, 12, 63, 48, 14, 2.8);
INSERT INTO public.match_details VALUES (898, 898, 63, 73, 5, 12, 1.67, 49, 1, 7, 27, 55, 15, 30, 99, 4, 6, 48, 48, 10, 3.33, 36, 54, 1, 5, 0.33, 61, 5, 14, 28, 45, 12, 19, 90, 7, 10, 29, 32, 6, 2);
INSERT INTO public.match_details VALUES (899, 899, 58, 75, 4, 11, 1.33, 57, 4, 12, 34, 59, 12, 21, 90, 3, 5, 45, 50, 9, 3, 49, 68, 3, 11, 1, 64, 6, 17, 32, 50, 7, 10, 91, 5, 9, 41, 45, 5, 1.67);
INSERT INTO public.match_details VALUES (900, 900, 76, 102, 8, 13, 1.6, 86, 6, 13, 51, 59, 21, 24, 118, 7, 8, 56, 47, 12, 2.4, 78, 104, 6, 18, 1.2, 89, 8, 19, 48, 53, 24, 26, 128, 6, 12, 64, 50, 8, 1.6);
INSERT INTO public.match_details VALUES (901, 901, 75, 99, 5, 11, 1, 83, 2, 19, 43, 51, 18, 21, 126, 10, 11, 58, 46, 12, 2.4, 70, 95, 2, 12, 0.4, 88, 5, 22, 41, 46, 17, 19, 120, 5, 12, 57, 48, 11, 2.2);
INSERT INTO public.match_details VALUES (902, 902, 44, 59, 3, 19, 1, 64, 5, 13, 35, 54, 16, 25, 76, 9, 2, 37, 49, 4, 1.33, 43, 73, 5, 9, 1.67, 40, 3, 15, 17, 42, 6, 15, 66, 3, 4, 36, 55, 2, 0.67);
INSERT INTO public.match_details VALUES (903, 903, 50, 74, 0, 16, 0, 42, 1, 10, 22, 52, 9, 21, 87, 3, 8, 40, 46, 10, 3.33, 39, 61, 1, 19, 0.33, 58, 0, 13, 34, 58, 18, 31, 92, 6, 10, 30, 33, 8, 2.67);
INSERT INTO public.match_details VALUES (904, 904, 62, 77, 8, 21, 2.67, 60, 5, 13, 26, 43, 19, 31, 82, 4, 5, 45, 55, 9, 3, 47, 74, 5, 14, 1.67, 56, 8, 14, 22, 39, 13, 23, 74, 3, 9, 37, 50, 5, 1.67);
INSERT INTO public.match_details VALUES (905, 905, 28, 44, 1, 13, 0.33, 64, 4, 11, 26, 40, 19, 29, 74, 11, 9, 26, 35, 1, 0.33, 50, 74, 4, 10, 1.33, 31, 1, 7, 17, 54, 11, 35, 57, 4, 1, 37, 65, 9, 3);
INSERT INTO public.match_details VALUES (906, 906, 84, 107, 8, 16, 2, 88, 1, 20, 45, 51, 22, 25, 122, 13, 6, 62, 51, 14, 3.5, 63, 97, 1, 9, 0.25, 91, 8, 18, 33, 36, 12, 13, 121, 7, 14, 56, 46, 6, 1.5);
INSERT INTO public.match_details VALUES (907, 907, 49, 73, 7, 9, 2.33, 45, 2, 4, 27, 60, 17, 37, 83, 4, 6, 39, 47, 3, 1, 41, 57, 2, 12, 0.67, 64, 7, 17, 22, 34, 13, 20, 77, 8, 3, 33, 43, 6, 2);
INSERT INTO public.match_details VALUES (908, 908, 44, 69, 0, 12, 0, 70, 10, 21, 24, 34, 20, 28, 80, 9, 5, 42, 52, 2, 0.67, 62, 83, 10, 13, 3.33, 57, 0, 17, 29, 50, 15, 26, 81, 9, 2, 47, 58, 5, 1.67);
INSERT INTO public.match_details VALUES (909, 909, 76, 96, 14, 10, 3.5, 64, 2, 12, 42, 65, 22, 34, 90, 6, 1, 50, 56, 12, 3, 53, 73, 2, 9, 0.5, 86, 14, 19, 41, 47, 21, 24, 114, 12, 12, 50, 44, 1, 0.25);
INSERT INTO public.match_details VALUES (910, 910, 70, 103, 6, 17, 1.2, 82, 11, 29, 27, 32, 10, 12, 99, 9, 11, 44, 44, 20, 4, 76, 103, 11, 21, 2.2, 86, 6, 23, 49, 56, 20, 23, 115, 9, 20, 54, 47, 11, 2.2);
INSERT INTO public.match_details VALUES (911, 911, 52, 73, 5, 15, 1.67, 52, 1, 14, 31, 59, 13, 25, 77, 9, 7, 37, 48, 10, 3.33, 39, 68, 1, 16, 0.33, 58, 5, 22, 24, 41, 13, 22, 78, 5, 10, 31, 40, 7, 2.33);
INSERT INTO public.match_details VALUES (912, 912, 67, 104, 5, 23, 1, 79, 6, 17, 35, 44, 22, 27, 117, 4, 10, 54, 46, 8, 1.6, 73, 103, 6, 24, 1.2, 81, 5, 19, 30, 37, 13, 16, 131, 10, 8, 57, 44, 10, 2);
INSERT INTO public.match_details VALUES (913, 913, 51, 73, 1, 9, 0.33, 51, 7, 7, 30, 58, 18, 35, 73, 5, 11, 42, 58, 8, 2.67, 44, 63, 7, 12, 2.33, 64, 1, 24, 30, 46, 10, 15, 70, 9, 8, 26, 37, 11, 3.67);
INSERT INTO public.match_details VALUES (914, 914, 71, 93, 9, 15, 2.25, 74, 17, 10, 40, 54, 18, 24, 99, 5, 6, 51, 52, 11, 2.75, 61, 86, 12, 12, 3, 78, 12, 20, 41, 52, 20, 25, 90, 4, 11, 43, 48, 6, 1.5);
INSERT INTO public.match_details VALUES (915, 915, 59, 75, 2, 8, 0.67, 50, 0, 8, 26, 52, 13, 26, 98, 4, 5, 48, 49, 9, 3, 47, 64, 0, 14, 0, 67, 2, 21, 31, 46, 12, 17, 95, 3, 9, 42, 44, 5, 1.67);
INSERT INTO public.match_details VALUES (916, 916, 82, 115, 10, 13, 2, 105, 6, 32, 45, 42, 18, 17, 153, 6, 10, 70, 46, 2, 0.4, 103, 123, 6, 18, 1.2, 102, 10, 31, 42, 41, 17, 16, 148, 10, 2, 87, 59, 10, 2);
INSERT INTO public.match_details VALUES (917, 917, 56, 74, 7, 14, 2.33, 54, 3, 9, 39, 72, 17, 31, 75, 5, 7, 43, 57, 6, 2, 43, 64, 3, 10, 1, 60, 7, 23, 18, 30, 8, 13, 71, 5, 6, 33, 46, 7, 2.33);
INSERT INTO public.match_details VALUES (918, 918, 55, 87, 8, 21, 2, 80, 10, 31, 20, 25, 12, 15, 103, 9, 8, 40, 39, 7, 1.75, 65, 96, 10, 16, 2.5, 66, 8, 19, 33, 50, 13, 19, 98, 12, 7, 47, 48, 8, 2);
INSERT INTO public.match_details VALUES (919, 919, 57, 78, 6, 17, 2, 59, 2, 11, 34, 57, 17, 28, 86, 6, 4, 42, 49, 9, 3, 43, 69, 2, 10, 0.67, 61, 6, 16, 25, 40, 12, 19, 79, 8, 9, 37, 47, 4, 1.33);
INSERT INTO public.match_details VALUES (920, 920, 40, 55, 5, 11, 1.67, 64, 14, 5, 26, 40, 18, 28, 72, 9, 4, 32, 44, 3, 1, 55, 74, 14, 10, 4.67, 44, 5, 9, 22, 50, 15, 34, 71, 3, 3, 37, 52, 4, 1.33);
INSERT INTO public.match_details VALUES (921, 921, 30, 53, 0, 9, 0, 60, 7, 7, 30, 50, 13, 21, 67, 5, 10, 25, 37, 5, 1.67, 60, 74, 7, 14, 2.33, 44, 0, 8, 21, 47, 10, 22, 66, 6, 5, 43, 65, 10, 3.33);
INSERT INTO public.match_details VALUES (922, 922, 70, 96, 9, 17, 1.8, 95, 6, 17, 49, 51, 33, 34, 124, 11, 15, 51, 41, 10, 2, 81, 111, 6, 16, 1.2, 79, 9, 12, 36, 45, 22, 27, 107, 6, 10, 60, 56, 15, 3);
INSERT INTO public.match_details VALUES (923, 923, 75, 104, 4, 17, 0.8, 99, 6, 29, 55, 55, 32, 32, 134, 14, 14, 61, 46, 10, 2, 78, 114, 6, 15, 1.2, 87, 4, 31, 37, 42, 18, 20, 123, 11, 10, 58, 47, 14, 2.8);
INSERT INTO public.match_details VALUES (924, 924, 61, 75, 7, 10, 2.33, 49, 4, 7, 30, 61, 19, 38, 64, 2, 5, 46, 72, 8, 2.67, 46, 60, 4, 11, 1.33, 65, 7, 19, 29, 44, 18, 27, 66, 4, 8, 37, 56, 5, 1.67);
INSERT INTO public.match_details VALUES (925, 925, 59, 72, 8, 10, 2.67, 41, 4, 9, 25, 60, 13, 31, 57, 2, 3, 39, 68, 12, 4, 33, 48, 4, 7, 1.33, 62, 8, 21, 21, 33, 12, 19, 69, 6, 12, 26, 38, 3, 1);
INSERT INTO public.match_details VALUES (926, 926, 76, 97, 8, 22, 2, 73, 8, 19, 34, 46, 19, 26, 92, 10, 3, 58, 63, 10, 2.5, 48, 85, 8, 12, 2, 75, 8, 27, 31, 41, 18, 24, 90, 8, 10, 37, 41, 3, 0.75);
INSERT INTO public.match_details VALUES (927, 927, 67, 96, 7, 21, 1.75, 69, 4, 15, 34, 49, 20, 28, 116, 8, 8, 52, 45, 8, 2, 54, 85, 4, 16, 1, 75, 7, 14, 38, 50, 21, 28, 109, 9, 8, 42, 39, 8, 2);
INSERT INTO public.match_details VALUES (928, 928, 65, 93, 6, 17, 1.5, 73, 9, 19, 27, 36, 8, 10, 104, 7, 10, 55, 53, 4, 1, 61, 87, 9, 14, 2.25, 76, 6, 23, 33, 43, 11, 14, 103, 9, 4, 42, 41, 10, 2.5);
INSERT INTO public.match_details VALUES (929, 929, 43, 65, 3, 11, 1, 55, 10, 8, 27, 49, 6, 10, 71, 2, 9, 38, 54, 2, 0.67, 59, 73, 3, 18, 1, 54, 4, 11, 34, 62, 15, 27, 79, 1, 2, 47, 59, 9, 3);
INSERT INTO public.match_details VALUES (930, 930, 80, 111, 7, 19, 1.4, 78, 0, 14, 47, 60, 17, 21, 130, 10, 10, 58, 45, 15, 3, 65, 98, 0, 20, 0, 92, 7, 19, 51, 55, 26, 28, 129, 9, 15, 55, 43, 10, 2);
INSERT INTO public.match_details VALUES (931, 931, 66, 97, 4, 13, 0.8, 93, 8, 28, 40, 43, 14, 15, 116, 6, 11, 48, 41, 14, 2.8, 88, 109, 8, 16, 1.6, 84, 4, 14, 53, 63, 25, 29, 132, 8, 14, 69, 52, 11, 2.2);
INSERT INTO public.match_details VALUES (932, 932, 60, 89, 9, 22, 2.25, 75, 7, 19, 41, 54, 24, 32, 95, 10, 9, 42, 44, 9, 2.25, 58, 90, 7, 15, 1.75, 67, 9, 26, 22, 32, 11, 16, 89, 12, 9, 42, 47, 9, 2.25);
INSERT INTO public.match_details VALUES (933, 933, 46, 57, 3, 9, 1, 68, 5, 13, 35, 51, 14, 20, 84, 10, 9, 37, 44, 6, 2, 54, 73, 5, 5, 1.67, 48, 3, 16, 21, 43, 10, 20, 73, 2, 6, 40, 55, 9, 3);
INSERT INTO public.match_details VALUES (934, 934, 65, 93, 8, 15, 2, 75, 4, 17, 41, 54, 25, 33, 118, 10, 6, 46, 39, 11, 2.75, 63, 91, 4, 16, 1, 78, 8, 13, 35, 44, 14, 17, 117, 9, 11, 53, 45, 6, 1.5);
INSERT INTO public.match_details VALUES (935, 935, 44, 62, 1, 12, 0.33, 66, 6, 16, 24, 36, 11, 16, 87, 7, 6, 37, 43, 6, 2, 54, 76, 6, 10, 2, 50, 1, 6, 22, 44, 13, 26, 86, 4, 6, 42, 49, 6, 2);
INSERT INTO public.match_details VALUES (936, 936, 70, 107, 4, 17, 0.8, 83, 6, 19, 38, 45, 20, 24, 110, 6, 14, 56, 51, 10, 2, 75, 105, 6, 22, 1.2, 90, 4, 26, 47, 52, 26, 28, 121, 11, 10, 55, 45, 14, 2.8);
INSERT INTO public.match_details VALUES (937, 937, 77, 108, 6, 20, 1.2, 86, 8, 22, 47, 54, 24, 27, 134, 9, 11, 67, 50, 4, 0.8, 70, 104, 8, 18, 1.6, 88, 6, 29, 45, 51, 21, 23, 111, 10, 4, 51, 46, 11, 2.2);
INSERT INTO public.match_details VALUES (938, 938, 54, 74, 11, 15, 3.67, 42, 1, 11, 19, 45, 9, 21, 69, 7, 10, 39, 57, 4, 1.33, 36, 60, 1, 18, 0.33, 59, 11, 17, 24, 40, 8, 13, 59, 1, 4, 25, 42, 10, 3.33);
INSERT INTO public.match_details VALUES (939, 939, 50, 73, 5, 4, 1.67, 37, 1, 7, 25, 67, 8, 21, 64, 5, 3, 40, 62, 5, 1.67, 34, 44, 1, 8, 0.33, 68, 5, 24, 23, 33, 4, 5, 80, 11, 5, 30, 38, 3, 1);
INSERT INTO public.match_details VALUES (940, 940, 46, 64, 4, 11, 1.33, 65, 6, 19, 26, 40, 15, 23, 79, 7, 8, 36, 46, 6, 2, 54, 74, 6, 9, 2, 53, 4, 8, 34, 64, 22, 41, 79, 7, 6, 40, 51, 8, 2.67);
INSERT INTO public.match_details VALUES (941, 941, 46, 74, 8, 15, 2.67, 48, 5, 9, 26, 54, 11, 22, 64, 8, 2, 34, 53, 4, 1.33, 40, 67, 5, 19, 1.67, 59, 8, 24, 19, 32, 11, 18, 59, 9, 4, 33, 56, 2, 0.67);
INSERT INTO public.match_details VALUES (942, 942, 67, 92, 6, 19, 1.5, 72, 5, 18, 36, 50, 17, 23, 96, 4, 4, 54, 56, 7, 1.75, 62, 89, 5, 16, 1.25, 73, 6, 20, 37, 50, 19, 26, 111, 6, 7, 53, 48, 4, 1);
INSERT INTO public.match_details VALUES (943, 943, 73, 100, 8, 17, 1.6, 88, 4, 30, 32, 36, 10, 11, 107, 10, 15, 52, 49, 13, 2.6, 79, 107, 4, 19, 0.8, 83, 8, 8, 51, 61, 24, 28, 120, 7, 13, 60, 50, 15, 3);
INSERT INTO public.match_details VALUES (944, 944, 50, 74, 8, 12, 2.67, 42, 5, 12, 20, 47, 8, 19, 61, 5, 3, 33, 54, 9, 3, 37, 58, 2, 16, 0.67, 61, 10, 15, 33, 54, 12, 19, 68, 7, 9, 32, 47, 3, 1);
INSERT INTO public.match_details VALUES (945, 945, 75, 108, 3, 14, 0.6, 84, 3, 17, 47, 55, 21, 25, 125, 9, 9, 58, 46, 14, 2.8, 80, 106, 3, 22, 0.6, 94, 3, 19, 52, 55, 20, 21, 134, 8, 14, 68, 51, 9, 1.8);
INSERT INTO public.match_details VALUES (946, 946, 47, 72, 3, 12, 1, 64, 2, 20, 28, 43, 9, 14, 89, 4, 8, 38, 43, 6, 2, 61, 78, 2, 14, 0.67, 60, 3, 19, 30, 50, 15, 25, 96, 8, 6, 51, 53, 8, 2.67);
INSERT INTO public.match_details VALUES (947, 947, 68, 97, 11, 19, 2.75, 57, 4, 13, 31, 54, 13, 22, 88, 7, 6, 48, 55, 9, 2.25, 43, 71, 4, 14, 1, 78, 11, 28, 31, 39, 13, 16, 88, 13, 9, 33, 38, 6, 1.5);
INSERT INTO public.match_details VALUES (948, 948, 31, 52, 2, 6, 0.67, 60, 7, 10, 34, 56, 14, 23, 66, 8, 15, 25, 38, 4, 1.33, 57, 73, 7, 13, 2.33, 46, 2, 13, 24, 52, 11, 23, 58, 4, 4, 35, 60, 15, 5);
INSERT INTO public.match_details VALUES (949, 949, 76, 106, 8, 17, 2, 73, 5, 12, 47, 64, 16, 21, 116, 5, 7, 54, 47, 14, 3.5, 70, 95, 5, 22, 1.25, 89, 8, 20, 41, 46, 22, 24, 116, 4, 14, 58, 50, 7, 1.75);
INSERT INTO public.match_details VALUES (950, 950, 67, 85, 5, 19, 1.25, 84, 4, 9, 48, 57, 35, 41, 105, 9, 6, 52, 50, 10, 2.5, 60, 92, 4, 8, 1, 66, 5, 6, 27, 40, 16, 24, 115, 9, 10, 50, 43, 6, 1.5);
INSERT INTO public.match_details VALUES (951, 951, 65, 96, 3, 14, 0.75, 75, 5, 13, 37, 49, 18, 24, 103, 12, 7, 52, 50, 10, 2.5, 62, 92, 5, 16, 1.25, 81, 3, 23, 33, 40, 12, 14, 113, 13, 10, 50, 44, 7, 1.75);
INSERT INTO public.match_details VALUES (952, 952, 48, 70, 4, 15, 1.33, 65, 3, 17, 29, 44, 19, 29, 95, 8, 13, 36, 38, 8, 2.67, 56, 78, 3, 13, 1, 55, 4, 21, 18, 32, 9, 16, 80, 3, 8, 39, 49, 14, 4.67);
INSERT INTO public.match_details VALUES (953, 953, 47, 60, 2, 6, 0.67, 63, 4, 21, 30, 47, 12, 19, 76, 11, 5, 39, 51, 6, 2, 55, 73, 4, 10, 1.33, 54, 2, 17, 25, 46, 10, 18, 75, 1, 6, 46, 61, 5, 1.67);
INSERT INTO public.match_details VALUES (954, 954, 75, 113, 4, 16, 0.8, 89, 6, 32, 43, 48, 24, 26, 137, 10, 14, 56, 41, 15, 3, 87, 113, 6, 24, 1.2, 97, 4, 41, 48, 49, 33, 34, 142, 10, 15, 67, 47, 14, 2.8);
INSERT INTO public.match_details VALUES (955, 955, 57, 94, 9, 13, 2.25, 64, 7, 14, 36, 56, 18, 28, 86, 6, 10, 42, 49, 6, 1.5, 67, 87, 7, 23, 1.75, 81, 9, 25, 33, 40, 12, 14, 95, 12, 6, 50, 53, 10, 2.5);
INSERT INTO public.match_details VALUES (956, 956, 72, 99, 5, 19, 1.25, 86, 4, 26, 32, 37, 17, 19, 116, 8, 10, 55, 47, 12, 3, 76, 103, 4, 17, 1, 80, 5, 16, 44, 55, 22, 27, 112, 8, 12, 62, 55, 10, 2.5);
INSERT INTO public.match_details VALUES (957, 957, 67, 97, 5, 16, 1.25, 68, 12, 17, 28, 41, 12, 17, 96, 5, 8, 52, 54, 10, 2.5, 67, 90, 12, 22, 3, 81, 5, 28, 37, 45, 18, 22, 104, 8, 10, 47, 45, 8, 2);
INSERT INTO public.match_details VALUES (958, 958, 77, 101, 6, 16, 1.2, 95, 2, 40, 41, 43, 21, 22, 130, 8, 12, 60, 46, 11, 2.2, 76, 104, 2, 9, 0.4, 85, 6, 32, 43, 50, 28, 32, 134, 14, 11, 62, 46, 12, 2.4);
INSERT INTO public.match_details VALUES (959, 959, 78, 103, 4, 15, 1, 87, 12, 27, 33, 37, 17, 19, 112, 7, 6, 57, 51, 17, 4.25, 72, 102, 12, 15, 3, 88, 4, 20, 46, 52, 29, 32, 125, 10, 17, 54, 43, 6, 1.5);
INSERT INTO public.match_details VALUES (960, 960, 38, 57, 5, 12, 1.67, 63, 8, 12, 32, 50, 16, 25, 81, 8, 7, 28, 35, 5, 1.67, 54, 73, 8, 10, 2.67, 45, 5, 11, 18, 40, 5, 11, 89, 6, 5, 39, 44, 7, 2.33);
INSERT INTO public.match_details VALUES (961, 961, 66, 79, 5, 13, 1.25, 88, 5, 20, 41, 46, 17, 19, 109, 13, 11, 52, 48, 9, 2.25, 65, 94, 5, 6, 1.25, 66, 5, 13, 30, 45, 15, 22, 91, 5, 9, 49, 54, 11, 2.75);
INSERT INTO public.match_details VALUES (962, 962, 72, 95, 5, 19, 1.25, 75, 7, 11, 38, 50, 27, 36, 104, 3, 6, 60, 58, 7, 1.75, 62, 87, 7, 12, 1.75, 76, 5, 10, 42, 55, 33, 43, 104, 10, 7, 49, 47, 6, 1.5);
INSERT INTO public.match_details VALUES (963, 963, 85, 109, 9, 18, 1.8, 74, 9, 20, 34, 45, 15, 20, 102, 5, 3, 66, 65, 10, 2, 68, 94, 9, 20, 1.8, 91, 9, 28, 36, 39, 11, 12, 111, 3, 10, 56, 50, 3, 0.6);
INSERT INTO public.match_details VALUES (964, 964, 52, 74, 3, 14, 1, 36, 3, 11, 19, 52, 10, 27, 70, 1, 5, 34, 49, 15, 5, 37, 53, 3, 17, 1, 60, 3, 18, 24, 40, 13, 21, 85, 4, 15, 29, 34, 5, 1.67);
INSERT INTO public.match_details VALUES (965, 965, 64, 94, 6, 10, 1.5, 71, 6, 15, 31, 43, 20, 28, 107, 14, 8, 48, 45, 10, 2.5, 54, 84, 6, 13, 1.5, 84, 6, 16, 37, 44, 23, 27, 111, 12, 10, 40, 36, 8, 2);
INSERT INTO public.match_details VALUES (966, 966, 53, 73, 11, 12, 3.67, 52, 6, 7, 31, 59, 9, 17, 73, 4, 8, 36, 49, 6, 2, 45, 65, 6, 13, 2, 61, 11, 18, 27, 44, 11, 18, 74, 7, 6, 31, 42, 8, 2.67);
INSERT INTO public.match_details VALUES (967, 967, 72, 101, 12, 9, 3, 66, 2, 23, 30, 45, 10, 15, 98, 6, 8, 51, 52, 9, 2.25, 71, 88, 2, 22, 0.5, 92, 12, 21, 47, 51, 20, 21, 105, 6, 9, 61, 58, 8, 2);
INSERT INTO public.match_details VALUES (968, 968, 55, 74, 6, 5, 2, 58, 2, 11, 35, 60, 14, 24, 81, 4, 10, 39, 48, 10, 3.33, 55, 66, 2, 8, 0.67, 69, 6, 11, 40, 57, 13, 18, 89, 11, 10, 43, 48, 10, 3.33);
INSERT INTO public.match_details VALUES (969, 969, 57, 73, 11, 14, 3.67, 52, 4, 12, 29, 55, 13, 25, 62, 3, 6, 41, 66, 5, 1.67, 40, 63, 3, 11, 1, 59, 15, 14, 23, 38, 7, 11, 62, 6, 5, 31, 50, 6, 2);
INSERT INTO public.match_details VALUES (970, 970, 60, 86, 2, 14, 0.5, 84, 8, 22, 43, 51, 19, 22, 124, 8, 11, 54, 44, 4, 1, 76, 99, 8, 15, 2, 72, 2, 21, 36, 50, 16, 22, 112, 9, 4, 57, 51, 11, 2.75);
INSERT INTO public.match_details VALUES (971, 971, 45, 75, 7, 13, 2.33, 45, 4, 15, 14, 31, 7, 15, 69, 6, 7, 30, 43, 8, 2.67, 44, 65, 4, 20, 1.33, 62, 7, 12, 33, 53, 15, 24, 81, 9, 8, 33, 41, 7, 2.33);
INSERT INTO public.match_details VALUES (972, 972, 71, 94, 6, 15, 1.5, 64, 7, 14, 27, 42, 12, 18, 87, 6, 9, 55, 63, 10, 2.5, 60, 83, 7, 19, 1.75, 79, 6, 20, 43, 54, 18, 22, 92, 4, 10, 44, 48, 9, 2.25);
INSERT INTO public.match_details VALUES (973, 973, 69, 97, 11, 32, 2.2, 88, 6, 25, 34, 38, 15, 17, 100, 6, 7, 47, 47, 11, 2.2, 62, 105, 6, 17, 1.2, 65, 11, 20, 22, 33, 12, 18, 88, 5, 11, 49, 56, 7, 1.4);
INSERT INTO public.match_details VALUES (974, 974, 59, 95, 5, 21, 1.25, 75, 2, 22, 40, 53, 18, 24, 110, 5, 8, 48, 44, 6, 1.5, 72, 97, 2, 22, 0.5, 74, 5, 18, 36, 48, 14, 18, 110, 10, 6, 62, 56, 8, 2);
INSERT INTO public.match_details VALUES (975, 975, 64, 78, 1, 8, 0.25, 83, 4, 29, 37, 44, 16, 19, 117, 8, 11, 53, 45, 10, 2.5, 75, 91, 4, 8, 1, 70, 1, 23, 30, 42, 11, 15, 113, 5, 10, 60, 53, 11, 2.75);
INSERT INTO public.match_details VALUES (976, 976, 79, 107, 8, 18, 1.6, 94, 7, 22, 46, 48, 17, 18, 141, 16, 12, 60, 43, 11, 2.2, 73, 107, 7, 13, 1.4, 89, 8, 23, 44, 49, 17, 19, 116, 10, 11, 54, 47, 12, 2.4);
INSERT INTO public.match_details VALUES (977, 977, 72, 98, 7, 17, 1.4, 96, 2, 30, 49, 51, 31, 32, 145, 15, 9, 57, 39, 8, 1.6, 75, 109, 2, 13, 0.4, 81, 7, 25, 34, 41, 15, 18, 127, 11, 8, 64, 50, 9, 1.8);
INSERT INTO public.match_details VALUES (978, 978, 68, 90, 8, 16, 2, 75, 4, 17, 34, 45, 17, 22, 101, 9, 10, 46, 46, 14, 3.5, 64, 91, 4, 16, 1, 74, 8, 24, 29, 39, 12, 16, 103, 5, 14, 50, 49, 10, 2.5);
INSERT INTO public.match_details VALUES (979, 979, 65, 91, 7, 31, 1.75, 73, 5, 14, 29, 39, 16, 21, 91, 5, 8, 54, 59, 4, 1, 54, 91, 5, 18, 1.25, 60, 7, 13, 24, 40, 14, 23, 80, 7, 4, 40, 50, 9, 2.25);
INSERT INTO public.match_details VALUES (980, 980, 45, 70, 4, 16, 1.33, 67, 11, 13, 24, 35, 14, 20, 86, 7, 7, 36, 42, 5, 1.67, 58, 80, 11, 13, 3.67, 54, 4, 6, 26, 48, 19, 35, 76, 8, 5, 40, 53, 7, 2.33);
INSERT INTO public.match_details VALUES (981, 981, 64, 94, 6, 17, 1.5, 63, 1, 20, 31, 49, 22, 34, 96, 6, 4, 47, 49, 11, 2.75, 52, 77, 1, 14, 0.25, 77, 6, 20, 31, 40, 17, 22, 110, 15, 11, 47, 43, 4, 1);
INSERT INTO public.match_details VALUES (982, 982, 94, 127, 2, 13, 0.4, 105, 7, 27, 49, 46, 30, 28, 153, 9, 11, 79, 52, 13, 2.6, 101, 126, 7, 21, 1.4, 114, 2, 27, 66, 57, 41, 35, 178, 10, 13, 83, 47, 11, 2.2);
INSERT INTO public.match_details VALUES (983, 983, 57, 76, 5, 16, 1.67, 53, 1, 11, 31, 58, 14, 26, 82, 5, 6, 46, 56, 6, 2, 41, 66, 1, 13, 0.33, 60, 5, 17, 27, 45, 8, 13, 83, 9, 6, 34, 41, 6, 2);
INSERT INTO public.match_details VALUES (984, 984, 52, 74, 5, 6, 1.67, 45, 4, 9, 26, 57, 11, 24, 74, 4, 7, 41, 55, 6, 2, 44, 56, 4, 11, 1.33, 68, 5, 28, 22, 32, 7, 10, 77, 11, 6, 33, 43, 7, 2.33);
INSERT INTO public.match_details VALUES (985, 985, 41, 56, 1, 8, 0.33, 64, 1, 18, 33, 51, 11, 17, 97, 8, 12, 36, 37, 4, 1.33, 56, 73, 1, 9, 0.33, 48, 1, 7, 31, 64, 22, 45, 91, 3, 4, 43, 47, 12, 4);
INSERT INTO public.match_details VALUES (986, 986, 67, 108, 9, 26, 1.8, 79, 10, 23, 33, 41, 12, 15, 113, 4, 15, 52, 46, 6, 1.2, 72, 105, 9, 26, 1.8, 82, 15, 23, 40, 48, 21, 25, 110, 13, 6, 48, 44, 15, 3);
INSERT INTO public.match_details VALUES (987, 987, 55, 78, 5, 18, 1.67, 52, 4, 14, 20, 38, 10, 19, 69, 6, 2, 41, 59, 9, 3, 40, 67, 4, 15, 1.33, 60, 5, 11, 26, 43, 11, 18, 73, 8, 9, 34, 47, 2, 0.67);
INSERT INTO public.match_details VALUES (988, 988, 80, 106, 7, 15, 1.4, 96, 4, 35, 37, 38, 13, 13, 120, 7, 9, 62, 52, 11, 2.2, 85, 108, 4, 12, 0.8, 91, 7, 35, 39, 42, 18, 19, 140, 10, 11, 72, 51, 9, 1.8);
INSERT INTO public.match_details VALUES (989, 989, 50, 64, 5, 14, 1.67, 66, 4, 13, 34, 51, 21, 31, 91, 5, 8, 42, 46, 3, 1, 55, 74, 4, 8, 1.33, 50, 5, 8, 22, 44, 12, 24, 79, 4, 3, 43, 54, 8, 2.67);
INSERT INTO public.match_details VALUES (990, 990, 90, 109, 7, 25, 1.4, 91, 5, 20, 60, 65, 30, 32, 135, 9, 11, 69, 51, 14, 2.8, 65, 102, 5, 11, 1, 84, 7, 25, 39, 46, 17, 20, 119, 8, 14, 49, 41, 11, 2.2);
INSERT INTO public.match_details VALUES (991, 991, 53, 73, 4, 13, 1.33, 61, 5, 16, 30, 49, 12, 19, 80, 4, 2, 47, 59, 2, 0.67, 50, 70, 5, 9, 1.67, 60, 4, 16, 27, 45, 14, 23, 88, 9, 2, 43, 49, 2, 0.67);
INSERT INTO public.match_details VALUES (992, 992, 73, 97, 7, 14, 1.75, 88, 1, 35, 34, 38, 13, 14, 126, 8, 13, 56, 44, 10, 2.5, 75, 101, 1, 12, 0.25, 83, 7, 20, 38, 45, 18, 21, 121, 11, 10, 61, 50, 13, 3.25);
INSERT INTO public.match_details VALUES (993, 993, 75, 96, 3, 15, 0.75, 81, 6, 12, 40, 49, 19, 23, 110, 7, 8, 59, 54, 13, 3.25, 68, 91, 6, 10, 1.5, 81, 3, 20, 46, 56, 19, 23, 115, 8, 13, 54, 47, 8, 2);
INSERT INTO public.match_details VALUES (994, 994, 59, 89, 8, 7, 2, 77, 10, 15, 43, 55, 29, 37, 102, 6, 12, 48, 47, 3, 0.75, 83, 99, 10, 22, 2.5, 82, 8, 15, 45, 54, 30, 36, 101, 7, 3, 61, 60, 12, 3);
INSERT INTO public.match_details VALUES (995, 995, 72, 107, 7, 17, 1.4, 77, 5, 14, 44, 57, 17, 22, 102, 8, 9, 55, 54, 10, 2, 71, 99, 5, 22, 1, 90, 7, 19, 40, 44, 16, 17, 121, 11, 10, 57, 47, 9, 1.8);
INSERT INTO public.match_details VALUES (996, 996, 43, 63, 2, 12, 0.67, 62, 6, 15, 31, 50, 15, 24, 84, 11, 11, 37, 44, 4, 1.33, 52, 74, 6, 12, 2, 51, 2, 13, 25, 49, 12, 23, 77, 6, 4, 35, 45, 11, 3.67);
INSERT INTO public.match_details VALUES (997, 997, 75, 96, 11, 15, 2.75, 66, 5, 13, 20, 30, 16, 24, 93, 4, 2, 54, 58, 10, 2.5, 60, 81, 5, 15, 1.25, 81, 11, 14, 38, 46, 24, 29, 99, 6, 10, 53, 54, 2, 0.5);
INSERT INTO public.match_details VALUES (998, 998, 72, 102, 3, 15, 0.6, 82, 7, 23, 37, 45, 22, 26, 115, 6, 10, 58, 50, 11, 2.2, 69, 97, 7, 15, 1.4, 87, 3, 26, 44, 50, 25, 28, 119, 16, 11, 52, 44, 10, 2);
INSERT INTO public.match_details VALUES (999, 999, 82, 110, 6, 13, 1.2, 75, 1, 27, 29, 38, 10, 13, 112, 5, 9, 59, 53, 17, 3.4, 72, 92, 1, 17, 0.2, 97, 6, 23, 55, 56, 36, 37, 126, 9, 17, 62, 49, 9, 1.8);
INSERT INTO public.match_details VALUES (1000, 1000, 57, 81, 4, 22, 1, 76, 4, 22, 37, 48, 16, 21, 96, 11, 10, 49, 51, 4, 1, 62, 94, 4, 18, 1, 59, 4, 12, 35, 59, 15, 25, 88, 5, 4, 48, 55, 10, 2.5);
INSERT INTO public.match_details VALUES (1001, 1001, 36, 60, 5, 6, 1.67, 56, 7, 19, 20, 35, 7, 12, 74, 5, 7, 29, 39, 2, 0.67, 60, 73, 7, 17, 2.33, 54, 5, 15, 27, 50, 13, 24, 89, 4, 2, 46, 52, 7, 2.33);
INSERT INTO public.match_details VALUES (1002, 1002, 92, 125, 7, 14, 1.4, 98, 6, 26, 48, 48, 23, 23, 147, 9, 12, 64, 44, 21, 4.2, 95, 122, 6, 24, 1.2, 111, 7, 23, 65, 58, 27, 24, 168, 8, 21, 77, 46, 12, 2.4);
INSERT INTO public.match_details VALUES (1003, 1003, 55, 73, 8, 10, 2.67, 52, 9, 11, 25, 48, 14, 26, 65, 3, 4, 40, 62, 7, 2.33, 45, 64, 7, 12, 2.33, 63, 14, 14, 29, 46, 9, 14, 62, 3, 7, 34, 55, 4, 1.33);
INSERT INTO public.match_details VALUES (1004, 1004, 51, 74, 6, 12, 2, 51, 4, 19, 19, 37, 11, 21, 80, 4, 5, 36, 45, 9, 3, 43, 62, 4, 11, 1.33, 62, 6, 15, 31, 50, 15, 24, 96, 11, 9, 34, 35, 5, 1.67);
INSERT INTO public.match_details VALUES (1005, 1005, 72, 85, 10, 17, 3.33, 74, 6, 13, 36, 48, 16, 21, 96, 8, 6, 52, 54, 10, 3.33, 48, 80, 6, 6, 2, 68, 10, 21, 22, 32, 10, 14, 90, 7, 10, 36, 40, 6, 2);
INSERT INTO public.match_details VALUES (1006, 1006, 80, 98, 9, 22, 1.8, 90, 9, 17, 53, 58, 28, 31, 123, 9, 7, 62, 50, 9, 1.8, 69, 101, 9, 11, 1.8, 76, 9, 18, 34, 44, 21, 27, 98, 5, 9, 53, 54, 7, 1.4);
INSERT INTO public.match_details VALUES (1007, 1007, 68, 101, 9, 18, 1.8, 87, 9, 30, 44, 50, 28, 32, 119, 5, 13, 51, 43, 8, 1.6, 80, 107, 9, 20, 1.8, 83, 9, 26, 40, 48, 23, 27, 121, 9, 8, 58, 48, 13, 2.6);
INSERT INTO public.match_details VALUES (1008, 1008, 65, 96, 12, 11, 3, 57, 6, 11, 32, 56, 9, 15, 89, 5, 9, 48, 54, 5, 1.25, 58, 75, 6, 18, 1.5, 85, 12, 21, 30, 35, 11, 12, 102, 13, 5, 43, 42, 9, 2.25);
INSERT INTO public.match_details VALUES (1009, 1009, 73, 96, 5, 12, 1.25, 79, 5, 22, 34, 43, 17, 21, 110, 10, 5, 55, 50, 13, 3.25, 64, 91, 5, 12, 1.25, 84, 5, 18, 48, 57, 21, 25, 114, 10, 13, 54, 47, 5, 1.25);
INSERT INTO public.match_details VALUES (1010, 1010, 48, 66, 6, 12, 2, 63, 6, 20, 29, 46, 16, 25, 91, 4, 6, 41, 45, 1, 0.33, 56, 73, 6, 10, 2, 54, 6, 16, 21, 38, 3, 5, 91, 5, 1, 44, 48, 6, 2);
INSERT INTO public.match_details VALUES (1011, 1011, 63, 84, 7, 16, 1.75, 84, 3, 18, 54, 64, 24, 28, 110, 8, 14, 52, 47, 4, 1, 69, 96, 3, 12, 0.75, 68, 7, 12, 41, 60, 21, 30, 98, 7, 4, 52, 53, 14, 3.5);
INSERT INTO public.match_details VALUES (1012, 1012, 34, 56, 2, 13, 0.67, 62, 8, 14, 28, 45, 10, 16, 81, 5, 8, 29, 36, 3, 1, 57, 74, 8, 12, 2.67, 43, 2, 6, 24, 55, 13, 30, 74, 7, 3, 41, 55, 8, 2.67);
INSERT INTO public.match_details VALUES (1013, 1013, 54, 77, 3, 12, 1, 53, 2, 10, 32, 60, 19, 35, 74, 6, 4, 41, 55, 10, 3.33, 48, 68, 2, 15, 0.67, 65, 3, 13, 28, 43, 14, 21, 88, 6, 10, 42, 48, 4, 1.33);
INSERT INTO public.match_details VALUES (1014, 1014, 70, 105, 7, 26, 1.4, 86, 6, 20, 32, 37, 24, 27, 129, 8, 14, 58, 45, 5, 1, 72, 108, 6, 22, 1.2, 79, 7, 16, 33, 41, 23, 29, 98, 9, 5, 52, 53, 14, 2.8);
INSERT INTO public.match_details VALUES (1015, 1015, 74, 108, 1, 21, 0.2, 83, 6, 21, 43, 51, 19, 22, 115, 9, 10, 62, 54, 11, 2.2, 75, 107, 6, 24, 1.2, 87, 1, 25, 49, 56, 26, 29, 110, 8, 11, 59, 54, 10, 2);
INSERT INTO public.match_details VALUES (1016, 1016, 41, 60, 7, 11, 2.33, 64, 8, 18, 29, 45, 12, 18, 69, 7, 10, 29, 42, 5, 1.67, 54, 73, 8, 9, 2.67, 49, 7, 12, 16, 32, 7, 14, 72, 5, 5, 36, 50, 10, 3.33);
INSERT INTO public.match_details VALUES (1017, 1017, 56, 73, 4, 7, 1.33, 51, 4, 20, 22, 43, 12, 23, 78, 7, 3, 46, 59, 6, 2, 44, 64, 4, 13, 1.33, 66, 4, 21, 38, 57, 9, 13, 81, 6, 6, 37, 46, 3, 1);
INSERT INTO public.match_details VALUES (1018, 1018, 54, 74, 4, 15, 1.33, 49, 3, 17, 19, 38, 9, 18, 84, 4, 4, 37, 44, 13, 4.33, 43, 63, 3, 14, 1, 59, 4, 22, 27, 45, 10, 16, 81, 6, 13, 36, 44, 4, 1.33);
INSERT INTO public.match_details VALUES (1019, 1019, 81, 97, 5, 16, 1.25, 71, 2, 17, 35, 49, 9, 12, 107, 2, 4, 61, 57, 15, 3.75, 62, 81, 2, 10, 0.5, 81, 5, 24, 38, 46, 16, 19, 112, 6, 15, 56, 50, 4, 1);
INSERT INTO public.match_details VALUES (1020, 1020, 84, 104, 8, 14, 1.6, 92, 11, 28, 40, 43, 21, 22, 135, 4, 10, 64, 47, 12, 2.4, 83, 103, 11, 11, 2.2, 90, 8, 18, 44, 48, 25, 27, 154, 7, 12, 62, 40, 10, 2);
INSERT INTO public.match_details VALUES (1021, 1021, 62, 74, 5, 8, 1.67, 52, 5, 9, 35, 67, 14, 26, 86, 5, 4, 51, 59, 6, 2, 43, 62, 1, 10, 0.33, 66, 13, 15, 30, 45, 9, 13, 78, 1, 6, 38, 49, 4, 1.33);
INSERT INTO public.match_details VALUES (1022, 1022, 74, 91, 7, 13, 1.75, 71, 1, 16, 31, 43, 9, 12, 110, 6, 10, 56, 51, 11, 2.75, 64, 84, 1, 13, 0.25, 78, 7, 16, 35, 44, 7, 8, 94, 6, 11, 53, 56, 10, 2.5);
INSERT INTO public.match_details VALUES (1023, 1023, 57, 73, 7, 14, 2.33, 53, 2, 10, 28, 52, 15, 28, 77, 3, 4, 43, 56, 7, 2.33, 45, 67, 2, 14, 0.67, 59, 7, 14, 25, 42, 12, 20, 72, 4, 7, 39, 54, 4, 1.33);
INSERT INTO public.match_details VALUES (1024, 1024, 57, 82, 5, 19, 1.25, 76, 7, 26, 32, 42, 16, 21, 101, 7, 5, 44, 44, 8, 2, 67, 95, 7, 19, 1.75, 63, 5, 13, 30, 47, 14, 22, 98, 4, 8, 55, 56, 5, 1.25);
INSERT INTO public.match_details VALUES (1025, 1025, 63, 89, 4, 18, 1, 81, 10, 18, 35, 43, 18, 22, 102, 4, 10, 54, 53, 5, 1.25, 73, 98, 10, 17, 2.5, 71, 4, 18, 31, 43, 11, 15, 106, 6, 5, 53, 50, 10, 2.5);
INSERT INTO public.match_details VALUES (1026, 1026, 63, 85, 4, 13, 1, 88, 7, 28, 32, 36, 15, 17, 113, 12, 7, 48, 42, 11, 2.75, 68, 94, 7, 6, 1.75, 72, 4, 14, 45, 62, 26, 36, 111, 8, 11, 54, 49, 7, 1.75);
INSERT INTO public.match_details VALUES (1027, 1027, 55, 70, 3, 13, 1, 70, 2, 17, 32, 45, 14, 20, 91, 8, 12, 44, 48, 8, 2.67, 57, 78, 2, 8, 0.67, 57, 3, 12, 30, 52, 15, 26, 86, 6, 8, 43, 50, 12, 4);
INSERT INTO public.match_details VALUES (1028, 1028, 59, 74, 5, 10, 1.67, 50, 0, 11, 28, 56, 19, 38, 77, 2, 6, 46, 60, 8, 2.67, 45, 59, 0, 9, 0, 64, 5, 15, 34, 53, 21, 32, 79, 7, 8, 39, 49, 6, 2);
INSERT INTO public.match_details VALUES (1029, 1029, 61, 91, 11, 16, 2.75, 81, 5, 26, 34, 41, 15, 18, 104, 6, 10, 48, 46, 2, 0.5, 72, 99, 5, 18, 1.25, 75, 11, 15, 39, 52, 22, 29, 106, 9, 2, 57, 54, 10, 2.5);
INSERT INTO public.match_details VALUES (1030, 1030, 79, 104, 12, 15, 2.4, 90, 6, 14, 58, 64, 37, 41, 132, 6, 14, 63, 48, 4, 0.8, 81, 105, 6, 15, 1.2, 89, 12, 25, 35, 39, 17, 19, 117, 7, 4, 61, 52, 14, 2.8);
INSERT INTO public.match_details VALUES (1031, 1031, 42, 62, 4, 12, 1.33, 62, 2, 7, 31, 50, 17, 27, 77, 6, 8, 33, 43, 5, 1.67, 55, 74, 2, 12, 0.67, 50, 4, 4, 33, 66, 27, 54, 71, 5, 5, 45, 63, 8, 2.67);
INSERT INTO public.match_details VALUES (1032, 1032, 83, 115, 5, 17, 1, 82, 7, 29, 36, 43, 18, 21, 129, 3, 12, 64, 50, 14, 2.8, 78, 101, 7, 19, 1.4, 98, 5, 35, 43, 43, 20, 20, 137, 7, 14, 59, 43, 12, 2.4);
INSERT INTO public.match_details VALUES (1033, 1033, 66, 82, 10, 12, 2.5, 86, 4, 23, 42, 48, 22, 25, 110, 4, 11, 45, 41, 11, 2.75, 74, 94, 4, 8, 1, 70, 10, 19, 29, 41, 16, 22, 113, 2, 11, 59, 52, 11, 2.75);
INSERT INTO public.match_details VALUES (1034, 1034, 59, 73, 8, 10, 2.67, 52, 3, 17, 26, 50, 10, 19, 78, 5, 4, 43, 55, 8, 2.67, 43, 62, 3, 10, 1, 62, 8, 15, 33, 53, 12, 19, 79, 6, 8, 36, 46, 4, 1.33);
INSERT INTO public.match_details VALUES (1035, 1035, 57, 85, 2, 12, 0.5, 80, 4, 25, 34, 42, 16, 20, 113, 8, 12, 48, 42, 7, 1.75, 78, 97, 4, 17, 1, 73, 2, 20, 39, 53, 13, 17, 116, 6, 7, 62, 53, 12, 3);
INSERT INTO public.match_details VALUES (1036, 1036, 63, 76, 5, 15, 1.67, 51, 4, 14, 29, 56, 16, 31, 77, 1, 4, 46, 60, 12, 4, 43, 62, 4, 11, 1.33, 61, 5, 23, 25, 40, 7, 11, 88, 2, 12, 35, 40, 4, 1.33);
INSERT INTO public.match_details VALUES (1037, 1037, 59, 75, 2, 8, 0.67, 62, 7, 14, 31, 50, 13, 20, 91, 3, 4, 47, 52, 10, 3.33, 54, 69, 7, 7, 2.33, 67, 2, 16, 38, 56, 12, 17, 95, 10, 10, 43, 45, 4, 1.33);
INSERT INTO public.match_details VALUES (1038, 1038, 60, 74, 5, 14, 1.67, 63, 2, 13, 42, 66, 18, 28, 93, 6, 8, 49, 53, 6, 2, 45, 68, 2, 5, 0.67, 60, 5, 15, 34, 56, 15, 25, 79, 7, 6, 35, 44, 8, 2.67);
INSERT INTO public.match_details VALUES (1039, 1039, 71, 93, 9, 18, 2.25, 74, 2, 14, 33, 44, 20, 27, 115, 3, 14, 56, 49, 6, 1.5, 65, 88, 2, 14, 0.5, 75, 9, 17, 29, 38, 13, 17, 107, 6, 6, 49, 46, 14, 3.5);
INSERT INTO public.match_details VALUES (1040, 1040, 54, 73, 3, 10, 1, 49, 6, 14, 19, 38, 14, 28, 76, 9, 6, 42, 55, 9, 3, 39, 59, 6, 10, 2, 63, 3, 19, 23, 36, 12, 19, 72, 8, 9, 27, 38, 6, 2);
INSERT INTO public.match_details VALUES (1041, 1041, 60, 72, 14, 18, 4.67, 47, 1, 15, 28, 59, 18, 38, 56, 2, 2, 36, 64, 10, 3.33, 32, 54, 1, 7, 0.33, 54, 14, 12, 22, 40, 10, 18, 64, 7, 10, 29, 45, 2, 0.67);
INSERT INTO public.match_details VALUES (1042, 1042, 55, 73, 5, 11, 1.67, 35, 2, 9, 19, 54, 6, 17, 65, 1, 3, 40, 62, 10, 3.33, 30, 45, 2, 10, 0.67, 62, 5, 20, 27, 43, 9, 14, 68, 7, 10, 25, 37, 3, 1);
INSERT INTO public.match_details VALUES (1043, 1043, 64, 92, 2, 18, 0.5, 72, 5, 22, 27, 37, 12, 16, 90, 5, 9, 52, 58, 10, 2.5, 61, 86, 5, 14, 1.25, 74, 2, 25, 32, 43, 17, 22, 97, 12, 10, 47, 48, 9, 2.25);
INSERT INTO public.match_details VALUES (1044, 1044, 52, 83, 5, 13, 1.25, 80, 5, 20, 36, 45, 17, 21, 105, 16, 8, 39, 37, 8, 2, 69, 98, 5, 18, 1.25, 70, 5, 14, 34, 48, 17, 24, 98, 9, 8, 56, 57, 8, 2);
INSERT INTO public.match_details VALUES (1045, 1045, 46, 69, 4, 11, 1, 81, 9, 16, 40, 49, 22, 27, 119, 8, 12, 37, 31, 5, 1.25, 76, 97, 9, 16, 2.25, 58, 4, 13, 28, 48, 17, 29, 101, 5, 5, 55, 54, 12, 3);
INSERT INTO public.match_details VALUES (1046, 1046, 50, 66, 2, 11, 0.67, 66, 4, 17, 37, 56, 25, 37, 90, 8, 6, 42, 47, 6, 2, 55, 76, 4, 10, 1.33, 55, 2, 14, 29, 52, 18, 32, 83, 2, 6, 45, 54, 6, 2);
INSERT INTO public.match_details VALUES (1047, 1047, 78, 108, 5, 20, 1, 92, 5, 23, 40, 43, 21, 22, 132, 14, 16, 62, 47, 11, 2.2, 76, 112, 5, 20, 1, 88, 5, 23, 43, 48, 18, 20, 121, 8, 11, 55, 45, 16, 3.2);
INSERT INTO public.match_details VALUES (1048, 1048, 64, 96, 6, 13, 1.2, 83, 9, 13, 36, 43, 28, 33, 113, 9, 5, 50, 44, 8, 1.6, 83, 107, 9, 24, 1.8, 83, 6, 16, 33, 39, 23, 27, 116, 7, 8, 69, 59, 5, 1);
INSERT INTO public.match_details VALUES (1049, 1049, 53, 76, 5, 18, 1.67, 52, 2, 10, 26, 50, 15, 28, 83, 6, 6, 37, 45, 11, 3.67, 44, 69, 2, 17, 0.67, 58, 5, 7, 32, 55, 22, 37, 83, 5, 11, 36, 43, 6, 2);
INSERT INTO public.match_details VALUES (1050, 1050, 45, 70, 4, 9, 1.33, 68, 7, 14, 27, 39, 14, 20, 90, 8, 13, 39, 43, 2, 0.67, 64, 82, 7, 14, 2.33, 61, 4, 9, 25, 40, 10, 16, 85, 9, 2, 44, 52, 13, 4.33);
INSERT INTO public.match_details VALUES (1051, 1051, 75, 92, 3, 16, 0.75, 74, 4, 16, 44, 59, 19, 25, 112, 3, 8, 64, 57, 8, 2, 63, 85, 4, 11, 1, 76, 3, 18, 41, 53, 20, 26, 107, 6, 8, 51, 48, 8, 2);
INSERT INTO public.match_details VALUES (1052, 1052, 53, 74, 2, 13, 0.67, 45, 3, 14, 22, 48, 9, 20, 77, 5, 5, 43, 56, 8, 2.67, 33, 54, 3, 9, 1, 61, 2, 21, 30, 49, 14, 22, 74, 7, 8, 25, 34, 5, 1.67);
INSERT INTO public.match_details VALUES (1053, 1053, 87, 116, 6, 21, 1.2, 101, 5, 35, 44, 43, 14, 13, 143, 4, 14, 67, 47, 14, 2.8, 90, 118, 5, 17, 1, 95, 6, 29, 41, 43, 12, 12, 140, 7, 14, 71, 51, 14, 2.8);
INSERT INTO public.match_details VALUES (1054, 1054, 74, 94, 7, 15, 1.75, 72, 4, 13, 42, 58, 16, 22, 100, 7, 6, 54, 54, 13, 3.25, 62, 86, 4, 14, 1, 79, 7, 16, 43, 54, 17, 21, 97, 5, 13, 52, 54, 6, 1.5);
INSERT INTO public.match_details VALUES (1055, 1055, 55, 74, 6, 14, 2, 49, 6, 7, 28, 57, 16, 32, 68, 3, 2, 42, 62, 7, 2.33, 42, 61, 4, 12, 1.33, 60, 11, 14, 28, 46, 11, 18, 71, 6, 7, 36, 51, 2, 0.67);
INSERT INTO public.match_details VALUES (1056, 1056, 58, 74, 6, 10, 2, 48, 2, 12, 22, 45, 16, 33, 86, 6, 11, 44, 51, 8, 2.67, 40, 58, 2, 10, 0.67, 64, 6, 17, 24, 37, 12, 18, 79, 5, 8, 27, 34, 11, 3.67);
INSERT INTO public.match_details VALUES (1057, 1057, 69, 102, 6, 20, 1.5, 84, 5, 23, 34, 40, 18, 21, 113, 8, 10, 50, 44, 13, 3.25, 79, 106, 5, 22, 1.25, 82, 6, 10, 51, 62, 34, 41, 118, 8, 13, 64, 54, 10, 2.5);
INSERT INTO public.match_details VALUES (1058, 1058, 68, 103, 4, 14, 0.8, 82, 6, 28, 38, 46, 16, 19, 109, 6, 11, 52, 48, 12, 2.4, 81, 105, 6, 23, 1.2, 89, 4, 25, 38, 42, 26, 29, 125, 8, 12, 64, 51, 11, 2.2);
INSERT INTO public.match_details VALUES (1059, 1059, 45, 70, 4, 9, 1.33, 61, 2, 15, 28, 45, 12, 19, 89, 11, 9, 30, 34, 11, 3.67, 54, 75, 2, 14, 0.67, 61, 4, 13, 30, 49, 18, 29, 98, 8, 11, 43, 44, 9, 3);
INSERT INTO public.match_details VALUES (1060, 1060, 77, 102, 3, 22, 0.6, 91, 7, 32, 37, 40, 11, 12, 124, 5, 7, 64, 52, 10, 2, 78, 105, 7, 14, 1.4, 80, 3, 28, 36, 45, 11, 13, 115, 6, 10, 64, 56, 7, 1.4);
INSERT INTO public.match_details VALUES (1061, 1061, 60, 89, 2, 11, 0.5, 77, 7, 21, 31, 40, 21, 27, 96, 10, 11, 45, 47, 13, 3.25, 75, 97, 7, 20, 1.75, 78, 2, 14, 48, 61, 20, 25, 108, 8, 13, 57, 53, 11, 2.75);
INSERT INTO public.match_details VALUES (1062, 1062, 62, 88, 8, 19, 2, 78, 13, 23, 30, 38, 16, 20, 97, 6, 11, 43, 44, 11, 2.75, 70, 96, 13, 18, 3.25, 69, 8, 22, 28, 40, 9, 13, 98, 5, 11, 46, 47, 11, 2.75);
INSERT INTO public.match_details VALUES (1063, 1063, 70, 102, 8, 8, 1.6, 83, 6, 16, 48, 57, 27, 32, 140, 10, 11, 53, 38, 9, 1.8, 82, 101, 6, 18, 1.2, 94, 8, 26, 40, 42, 20, 21, 136, 14, 9, 65, 48, 11, 2.2);
INSERT INTO public.match_details VALUES (1064, 1064, 56, 87, 7, 17, 1.75, 77, 5, 21, 36, 46, 15, 19, 105, 10, 10, 44, 42, 5, 1.25, 69, 100, 5, 23, 1.25, 70, 7, 19, 29, 41, 16, 22, 97, 5, 5, 54, 56, 10, 2.5);
INSERT INTO public.match_details VALUES (1065, 1065, 67, 102, 4, 19, 0.8, 87, 3, 12, 39, 44, 24, 27, 124, 10, 14, 54, 44, 9, 1.8, 75, 107, 3, 20, 0.6, 83, 4, 8, 48, 57, 36, 43, 115, 12, 9, 58, 50, 14, 2.8);
INSERT INTO public.match_details VALUES (1066, 1066, 63, 90, 5, 14, 1.25, 74, 2, 22, 37, 50, 23, 31, 102, 6, 8, 48, 47, 10, 2.5, 66, 87, 2, 13, 0.5, 76, 5, 15, 39, 51, 22, 28, 114, 11, 10, 56, 49, 8, 2);
INSERT INTO public.match_details VALUES (1067, 1067, 51, 70, 1, 12, 0.33, 67, 7, 24, 21, 31, 8, 11, 100, 6, 6, 41, 41, 9, 3, 60, 80, 7, 13, 2.33, 58, 1, 19, 25, 43, 15, 25, 97, 3, 9, 47, 48, 6, 2);
INSERT INTO public.match_details VALUES (1068, 1068, 56, 80, 3, 4, 1, 51, 2, 19, 23, 45, 8, 15, 82, 2, 4, 45, 55, 8, 2.67, 61, 70, 2, 19, 0.67, 76, 3, 28, 36, 47, 21, 27, 95, 6, 8, 55, 58, 4, 1.33);
INSERT INTO public.match_details VALUES (1069, 1069, 77, 113, 16, 24, 3.2, 84, 7, 22, 43, 51, 15, 17, 107, 9, 15, 51, 48, 10, 2, 72, 106, 7, 22, 1.4, 89, 16, 21, 42, 47, 20, 22, 119, 9, 10, 50, 42, 15, 3);
INSERT INTO public.match_details VALUES (1070, 1070, 63, 89, 4, 16, 1, 64, 7, 19, 28, 43, 8, 12, 95, 6, 3, 53, 56, 6, 1.5, 54, 80, 7, 16, 1.75, 73, 4, 28, 29, 39, 8, 10, 91, 10, 6, 44, 48, 3, 0.75);
INSERT INTO public.match_details VALUES (1071, 1071, 57, 74, 8, 5, 2.67, 34, 2, 12, 15, 44, 8, 23, 65, 4, 1, 38, 58, 11, 3.67, 32, 43, 2, 9, 0.67, 69, 8, 22, 32, 46, 15, 21, 79, 7, 11, 29, 37, 1, 0.33);
INSERT INTO public.match_details VALUES (1072, 1072, 56, 73, 7, 11, 2.33, 46, 2, 12, 31, 67, 12, 26, 82, 6, 4, 44, 54, 5, 1.67, 38, 60, 1, 14, 0.33, 62, 13, 17, 27, 43, 9, 14, 76, 4, 5, 33, 43, 4, 1.33);
INSERT INTO public.match_details VALUES (1073, 1073, 51, 73, 9, 12, 3, 49, 2, 15, 18, 36, 9, 18, 81, 4, 11, 32, 40, 10, 3.33, 41, 62, 2, 13, 0.67, 61, 9, 18, 24, 39, 8, 13, 70, 5, 10, 28, 40, 11, 3.67);
INSERT INTO public.match_details VALUES (1074, 1074, 70, 97, 6, 18, 1.5, 79, 12, 22, 32, 40, 18, 22, 104, 8, 10, 54, 52, 10, 2.5, 69, 98, 12, 18, 3, 79, 6, 20, 34, 43, 22, 27, 100, 7, 10, 47, 47, 10, 2.5);
INSERT INTO public.match_details VALUES (1075, 1075, 65, 83, 9, 16, 3, 59, 2, 15, 30, 50, 16, 27, 90, 5, 10, 48, 53, 8, 2.67, 51, 75, 2, 16, 0.67, 67, 9, 14, 38, 56, 15, 22, 94, 4, 8, 39, 41, 10, 3.33);
INSERT INTO public.match_details VALUES (1076, 1076, 43, 63, 2, 16, 0.67, 60, 3, 17, 23, 38, 10, 16, 73, 7, 10, 36, 49, 5, 1.67, 49, 74, 3, 14, 1, 47, 2, 11, 26, 55, 14, 29, 71, 2, 5, 36, 51, 10, 3.33);
INSERT INTO public.match_details VALUES (1077, 1077, 50, 73, 8, 9, 2.67, 31, 3, 9, 16, 51, 8, 25, 64, 1, 7, 34, 53, 8, 2.67, 37, 51, 3, 20, 1, 64, 8, 24, 21, 32, 11, 17, 64, 3, 8, 27, 42, 7, 2.33);
INSERT INTO public.match_details VALUES (1078, 1078, 53, 74, 6, 13, 2, 44, 3, 15, 17, 38, 6, 13, 58, 2, 3, 36, 62, 11, 3.67, 37, 57, 3, 13, 1, 61, 6, 16, 23, 37, 8, 13, 72, 9, 11, 31, 43, 3, 1);
INSERT INTO public.match_details VALUES (1079, 1079, 60, 95, 5, 14, 1, 86, 14, 22, 31, 36, 12, 13, 101, 5, 8, 44, 44, 11, 2.2, 84, 107, 10, 21, 2, 81, 7, 18, 50, 61, 17, 20, 122, 11, 11, 66, 54, 8, 1.6);
INSERT INTO public.match_details VALUES (1080, 1080, 45, 66, 3, 8, 1, 66, 5, 17, 38, 57, 24, 36, 86, 6, 12, 31, 36, 11, 3.67, 60, 76, 5, 10, 1.67, 58, 3, 20, 28, 48, 11, 18, 90, 5, 11, 43, 48, 12, 4);
INSERT INTO public.match_details VALUES (1081, 1081, 63, 97, 9, 13, 2.25, 73, 9, 26, 29, 39, 13, 17, 115, 6, 14, 48, 42, 6, 1.5, 70, 92, 9, 19, 2.25, 84, 9, 29, 35, 41, 18, 21, 115, 12, 6, 47, 41, 14, 3.5);
INSERT INTO public.match_details VALUES (1082, 1082, 73, 107, 7, 18, 1.75, 80, 9, 22, 27, 33, 13, 16, 118, 7, 11, 58, 49, 8, 2, 71, 101, 9, 21, 2.25, 88, 7, 12, 39, 44, 19, 21, 116, 11, 8, 51, 44, 11, 2.75);
INSERT INTO public.match_details VALUES (1083, 1083, 73, 108, 6, 18, 1.2, 88, 16, 23, 38, 43, 16, 18, 129, 10, 11, 53, 41, 14, 2.8, 81, 108, 12, 20, 2.4, 90, 11, 29, 39, 43, 15, 16, 135, 11, 14, 58, 43, 11, 2.2);
INSERT INTO public.match_details VALUES (1084, 1084, 57, 87, 6, 14, 1.5, 75, 5, 21, 35, 46, 12, 16, 104, 7, 7, 43, 41, 8, 2, 67, 91, 5, 16, 1.25, 73, 6, 17, 35, 47, 14, 19, 124, 9, 8, 55, 44, 7, 1.75);
INSERT INTO public.match_details VALUES (1085, 1085, 72, 99, 1, 17, 0.25, 71, 2, 26, 26, 36, 8, 11, 113, 6, 6, 60, 53, 11, 2.75, 63, 88, 2, 17, 0.5, 82, 1, 24, 31, 37, 18, 21, 119, 7, 11, 55, 46, 6, 1.5);
INSERT INTO public.match_details VALUES (1086, 1086, 77, 101, 7, 18, 1.4, 87, 7, 20, 48, 55, 23, 26, 111, 10, 10, 60, 54, 10, 2, 72, 103, 7, 16, 1.4, 83, 7, 15, 41, 49, 14, 16, 106, 8, 10, 55, 52, 10, 2);
INSERT INTO public.match_details VALUES (1087, 1087, 54, 86, 4, 18, 1, 80, 14, 18, 32, 40, 13, 16, 87, 7, 8, 44, 51, 6, 1.5, 72, 102, 14, 22, 3.5, 68, 4, 13, 36, 52, 20, 29, 97, 6, 6, 50, 52, 8, 2);
INSERT INTO public.match_details VALUES (1088, 1088, 63, 91, 4, 10, 1, 62, 5, 8, 29, 46, 14, 22, 91, 5, 12, 47, 52, 12, 3, 61, 80, 5, 18, 1.25, 81, 4, 22, 41, 50, 22, 27, 99, 10, 12, 44, 44, 12, 3);
INSERT INTO public.match_details VALUES (1089, 1089, 92, 120, 7, 21, 1.75, 95, 5, 7, 53, 55, 30, 31, 140, 10, 8, 72, 51, 13, 3.25, 76, 115, 5, 20, 1.25, 99, 7, 19, 40, 40, 27, 27, 125, 8, 13, 63, 50, 8, 2);
INSERT INTO public.match_details VALUES (1090, 1090, 69, 104, 4, 22, 1, 90, 9, 22, 35, 38, 23, 25, 117, 7, 10, 56, 48, 9, 2.25, 79, 109, 9, 19, 2.25, 82, 4, 17, 39, 47, 23, 28, 109, 12, 9, 60, 55, 10, 2.5);
INSERT INTO public.match_details VALUES (1091, 1091, 51, 74, 5, 11, 1.67, 49, 1, 17, 19, 38, 7, 14, 75, 7, 8, 35, 47, 11, 3.67, 37, 64, 1, 15, 0.33, 62, 5, 18, 24, 38, 8, 12, 77, 6, 11, 28, 36, 8, 2.67);
INSERT INTO public.match_details VALUES (1092, 1092, 79, 108, 4, 16, 0.8, 86, 4, 16, 48, 55, 32, 37, 137, 13, 13, 62, 45, 13, 2.6, 71, 104, 4, 18, 0.8, 92, 4, 16, 51, 55, 30, 32, 122, 8, 13, 54, 44, 13, 2.6);
INSERT INTO public.match_details VALUES (1093, 1093, 54, 73, 9, 13, 3, 45, 2, 10, 23, 51, 9, 20, 62, 5, 8, 31, 50, 14, 4.67, 37, 57, 2, 12, 0.67, 60, 9, 17, 22, 36, 11, 18, 66, 5, 14, 27, 41, 8, 2.67);
INSERT INTO public.match_details VALUES (1094, 1094, 68, 100, 2, 13, 0.4, 85, 3, 23, 48, 56, 28, 32, 137, 13, 15, 52, 38, 14, 2.8, 70, 99, 3, 14, 0.6, 87, 2, 24, 48, 55, 25, 28, 139, 16, 14, 52, 37, 15, 3);
INSERT INTO public.match_details VALUES (1095, 1095, 70, 97, 7, 13, 1.75, 67, 5, 20, 37, 55, 7, 10, 97, 3, 6, 49, 51, 14, 3.5, 64, 84, 5, 17, 1.25, 84, 7, 27, 47, 55, 12, 14, 110, 5, 14, 53, 48, 6, 1.5);
INSERT INTO public.match_details VALUES (1096, 1096, 35, 61, 1, 12, 0.33, 58, 8, 13, 28, 48, 15, 25, 57, 3, 5, 27, 47, 7, 2.33, 54, 74, 8, 16, 2.67, 49, 1, 9, 23, 46, 11, 22, 78, 6, 7, 41, 53, 5, 1.67);
INSERT INTO public.match_details VALUES (1097, 1097, 32, 50, 1, 14, 0.33, 62, 3, 10, 40, 64, 13, 20, 69, 8, 12, 29, 42, 2, 0.67, 52, 73, 3, 11, 1, 36, 1, 11, 19, 52, 12, 33, 51, 5, 2, 37, 73, 12, 4);
INSERT INTO public.match_details VALUES (1098, 1098, 59, 73, 2, 14, 0.67, 50, 1, 12, 33, 66, 18, 36, 88, 4, 8, 49, 56, 8, 2.67, 39, 61, 1, 11, 0.33, 59, 2, 28, 22, 37, 12, 20, 75, 4, 8, 30, 40, 8, 2.67);
INSERT INTO public.match_details VALUES (1099, 1099, 70, 94, 6, 15, 1.5, 78, 5, 25, 36, 46, 15, 19, 114, 9, 11, 62, 54, 2, 0.5, 61, 92, 5, 14, 1.25, 79, 6, 30, 37, 46, 14, 17, 106, 11, 2, 45, 42, 11, 2.75);
INSERT INTO public.match_details VALUES (1100, 1100, 42, 54, 0, 10, 0, 67, 5, 16, 29, 43, 20, 29, 78, 7, 9, 36, 46, 6, 2, 56, 74, 5, 6, 1.67, 44, 0, 11, 20, 45, 12, 27, 76, 4, 6, 42, 55, 9, 3);
INSERT INTO public.match_details VALUES (1101, 1101, 55, 76, 4, 13, 1.33, 45, 5, 9, 25, 55, 14, 31, 69, 5, 3, 42, 61, 9, 3, 42, 64, 3, 19, 1, 62, 7, 18, 23, 37, 14, 22, 72, 3, 9, 36, 50, 3, 1);
INSERT INTO public.match_details VALUES (1102, 1102, 89, 114, 6, 16, 1.2, 90, 2, 10, 59, 65, 28, 31, 129, 9, 7, 73, 57, 10, 2, 73, 102, 2, 12, 0.4, 98, 6, 17, 54, 55, 17, 17, 124, 8, 10, 64, 52, 7, 1.4);
INSERT INTO public.match_details VALUES (1103, 1103, 65, 88, 10, 11, 2.5, 65, 6, 11, 22, 33, 9, 13, 97, 10, 11, 48, 49, 7, 1.75, 60, 82, 6, 17, 1.5, 77, 10, 10, 37, 48, 23, 29, 95, 3, 7, 43, 45, 11, 2.75);
INSERT INTO public.match_details VALUES (1104, 1104, 53, 74, 5, 12, 1.67, 47, 4, 9, 25, 53, 13, 27, 66, 3, 5, 39, 59, 9, 3, 40, 59, 4, 12, 1.33, 62, 5, 18, 30, 48, 16, 25, 66, 7, 9, 31, 47, 5, 1.67);
INSERT INTO public.match_details VALUES (1105, 1105, 49, 73, 4, 7, 1.33, 38, 2, 9, 18, 47, 6, 15, 75, 2, 4, 39, 52, 6, 2, 41, 53, 2, 15, 0.67, 66, 4, 14, 36, 54, 14, 21, 91, 7, 6, 35, 38, 4, 1.33);
INSERT INTO public.match_details VALUES (1106, 1106, 40, 55, 2, 13, 0.67, 69, 2, 24, 36, 52, 16, 23, 84, 7, 13, 31, 37, 7, 2.33, 53, 74, 2, 5, 0.67, 42, 2, 15, 21, 50, 6, 14, 72, 7, 7, 38, 53, 13, 4.33);
INSERT INTO public.match_details VALUES (1107, 1107, 73, 92, 7, 20, 1.75, 89, 13, 8, 50, 56, 29, 32, 122, 12, 13, 56, 46, 10, 2.5, 65, 99, 6, 10, 1.5, 72, 10, 13, 33, 45, 19, 26, 111, 7, 10, 47, 42, 12, 3);
INSERT INTO public.match_details VALUES (1108, 1108, 75, 101, 4, 15, 0.8, 89, 8, 35, 39, 43, 19, 21, 121, 12, 10, 59, 49, 12, 2.4, 73, 104, 8, 15, 1.6, 86, 4, 26, 41, 47, 21, 24, 129, 6, 12, 55, 43, 10, 2);
INSERT INTO public.match_details VALUES (1109, 1109, 82, 105, 10, 15, 2, 86, 5, 18, 45, 52, 19, 22, 113, 12, 8, 59, 52, 13, 2.6, 71, 103, 5, 17, 1, 90, 10, 26, 36, 40, 12, 13, 118, 4, 13, 58, 49, 8, 1.6);
INSERT INTO public.match_details VALUES (1110, 1110, 69, 99, 5, 19, 1.25, 81, 4, 30, 31, 38, 13, 16, 114, 10, 7, 54, 47, 10, 2.5, 68, 100, 4, 19, 1, 80, 5, 19, 39, 48, 20, 25, 113, 6, 10, 57, 50, 7, 1.75);
INSERT INTO public.match_details VALUES (1111, 1111, 38, 64, 3, 11, 1, 58, 6, 14, 27, 46, 17, 29, 76, 7, 9, 29, 38, 6, 2, 56, 74, 6, 16, 2, 53, 3, 14, 30, 56, 16, 30, 76, 8, 6, 41, 54, 9, 3);
INSERT INTO public.match_details VALUES (1112, 1112, 49, 64, 7, 13, 2.33, 64, 6, 8, 42, 65, 31, 48, 84, 5, 13, 35, 42, 7, 2.33, 58, 74, 6, 10, 2, 51, 7, 11, 29, 56, 15, 29, 68, 2, 7, 39, 57, 13, 4.33);
INSERT INTO public.match_details VALUES (1113, 1113, 65, 87, 7, 20, 1.75, 76, 6, 27, 40, 52, 25, 32, 109, 6, 11, 49, 45, 9, 2.25, 66, 93, 6, 17, 1.5, 67, 7, 26, 26, 38, 11, 16, 96, 3, 9, 49, 51, 11, 2.75);
INSERT INTO public.match_details VALUES (1114, 1114, 70, 91, 5, 19, 1.25, 84, 6, 21, 44, 52, 18, 21, 122, 12, 10, 61, 50, 4, 1, 64, 96, 6, 12, 1.5, 72, 5, 16, 33, 45, 20, 27, 99, 6, 4, 48, 48, 10, 2.5);
INSERT INTO public.match_details VALUES (1115, 1115, 55, 73, 11, 10, 3.67, 39, 2, 10, 21, 53, 9, 23, 75, 4, 4, 33, 44, 11, 3.67, 33, 49, 2, 10, 0.67, 63, 11, 15, 30, 47, 13, 20, 95, 7, 11, 27, 28, 4, 1.33);
INSERT INTO public.match_details VALUES (1116, 1116, 79, 107, 5, 15, 1, 86, 4, 19, 45, 52, 21, 24, 119, 12, 11, 62, 52, 12, 2.4, 74, 102, 4, 16, 0.8, 92, 5, 10, 52, 56, 27, 29, 122, 10, 12, 59, 48, 11, 2.2);
INSERT INTO public.match_details VALUES (1117, 1117, 47, 73, 11, 15, 3.67, 29, 0, 5, 13, 44, 6, 20, 45, 2, 1, 31, 69, 5, 1.67, 25, 45, 0, 16, 0, 58, 11, 16, 23, 39, 8, 13, 56, 9, 5, 24, 43, 1, 0.33);
INSERT INTO public.match_details VALUES (1118, 1118, 56, 74, 4, 13, 1.33, 52, 3, 4, 19, 36, 10, 19, 76, 5, 5, 43, 57, 9, 3, 42, 65, 3, 13, 1, 61, 4, 4, 32, 52, 15, 24, 77, 4, 9, 34, 44, 5, 1.67);
INSERT INTO public.match_details VALUES (1119, 1119, 54, 74, 1, 11, 0.25, 81, 7, 28, 33, 40, 10, 12, 104, 10, 10, 44, 42, 9, 2.25, 66, 92, 7, 11, 1.75, 63, 1, 24, 25, 39, 3, 4, 107, 5, 9, 49, 46, 10, 2.5);
INSERT INTO public.match_details VALUES (1120, 1120, 76, 95, 7, 22, 1.75, 80, 6, 18, 36, 45, 24, 30, 105, 10, 6, 59, 56, 10, 2.5, 58, 95, 6, 14, 1.5, 73, 7, 12, 33, 45, 18, 24, 94, 5, 10, 46, 49, 6, 1.5);
INSERT INTO public.match_details VALUES (1121, 1121, 78, 107, 8, 14, 1.6, 85, 4, 31, 41, 48, 18, 21, 121, 10, 11, 56, 46, 14, 2.8, 74, 104, 4, 19, 0.8, 93, 8, 25, 48, 51, 27, 29, 126, 9, 14, 59, 47, 11, 2.2);
INSERT INTO public.match_details VALUES (1122, 1122, 37, 63, 4, 6, 1.33, 61, 3, 11, 34, 55, 21, 34, 100, 10, 16, 27, 27, 6, 2, 55, 74, 3, 12, 1, 57, 4, 11, 29, 50, 13, 22, 94, 11, 6, 36, 38, 16, 5.33);
INSERT INTO public.match_details VALUES (1123, 1123, 71, 92, 4, 17, 0.8, 95, 7, 26, 34, 35, 22, 23, 128, 5, 16, 60, 47, 7, 1.4, 83, 109, 7, 14, 1.4, 75, 4, 20, 43, 57, 23, 30, 127, 6, 7, 60, 47, 16, 3.2);
INSERT INTO public.match_details VALUES (1124, 1124, 41, 62, 1, 10, 0.33, 65, 5, 17, 28, 43, 9, 13, 75, 7, 7, 35, 47, 5, 1.67, 55, 73, 5, 8, 1.67, 52, 1, 11, 27, 51, 8, 15, 75, 7, 5, 43, 57, 7, 2.33);
INSERT INTO public.match_details VALUES (1125, 1125, 57, 73, 7, 8, 2.33, 48, 2, 8, 27, 56, 15, 31, 84, 1, 7, 39, 46, 11, 3.67, 45, 57, 2, 9, 0.67, 65, 7, 16, 27, 41, 9, 13, 89, 8, 11, 36, 40, 7, 2.33);
INSERT INTO public.match_details VALUES (1126, 1126, 58, 91, 9, 21, 2.25, 61, 7, 24, 26, 42, 13, 21, 80, 5, 9, 38, 48, 11, 2.75, 50, 78, 7, 17, 1.75, 70, 9, 25, 29, 41, 10, 14, 94, 14, 11, 34, 36, 9, 2.25);
INSERT INTO public.match_details VALUES (1127, 1127, 46, 74, 2, 20, 0.67, 63, 3, 23, 25, 39, 11, 17, 81, 4, 8, 37, 46, 7, 2.33, 56, 82, 3, 19, 1, 54, 2, 18, 25, 46, 11, 20, 84, 6, 7, 45, 54, 8, 2.67);
INSERT INTO public.match_details VALUES (1128, 1128, 61, 78, 5, 14, 1.67, 60, 5, 13, 38, 63, 21, 35, 80, 4, 3, 46, 57, 10, 3.33, 49, 71, 5, 11, 1.67, 64, 5, 21, 26, 40, 6, 9, 87, 4, 10, 41, 47, 3, 1);
INSERT INTO public.match_details VALUES (1129, 1129, 69, 102, 6, 14, 1.5, 69, 2, 16, 32, 46, 12, 17, 103, 6, 5, 55, 53, 8, 2, 63, 88, 2, 19, 0.5, 88, 6, 27, 38, 43, 15, 17, 128, 11, 8, 56, 44, 5, 1.25);
INSERT INTO public.match_details VALUES (1130, 1130, 53, 74, 5, 7, 1.67, 48, 1, 14, 28, 58, 8, 16, 81, 3, 5, 43, 53, 5, 1.67, 49, 63, 1, 15, 0.33, 67, 5, 13, 40, 59, 19, 28, 87, 6, 5, 43, 49, 5, 1.67);
INSERT INTO public.match_details VALUES (1131, 1131, 58, 87, 9, 20, 2.25, 76, 6, 23, 37, 48, 16, 21, 96, 12, 8, 37, 39, 12, 3, 66, 97, 6, 21, 1.5, 67, 9, 10, 31, 46, 14, 20, 99, 5, 12, 52, 53, 8, 2);
INSERT INTO public.match_details VALUES (1132, 1132, 65, 96, 7, 15, 1.75, 86, 8, 17, 45, 52, 22, 25, 124, 16, 13, 50, 40, 8, 2, 68, 103, 8, 17, 2, 81, 7, 16, 30, 37, 13, 16, 103, 12, 8, 47, 46, 13, 3.25);
INSERT INTO public.match_details VALUES (1133, 1133, 46, 72, 3, 12, 1, 65, 3, 15, 24, 36, 12, 18, 92, 6, 7, 40, 43, 3, 1, 60, 78, 3, 13, 1, 60, 3, 9, 28, 46, 18, 30, 100, 8, 3, 50, 50, 7, 2.33);
INSERT INTO public.match_details VALUES (1134, 1134, 60, 73, 6, 12, 2, 55, 3, 18, 26, 47, 8, 14, 89, 7, 3, 43, 48, 11, 3.67, 39, 61, 3, 6, 1, 61, 6, 17, 26, 42, 9, 14, 87, 8, 11, 33, 38, 3, 1);
INSERT INTO public.match_details VALUES (1135, 1135, 72, 94, 6, 14, 1.5, 78, 4, 22, 41, 52, 17, 21, 111, 7, 12, 52, 47, 14, 3.5, 67, 92, 4, 14, 1, 80, 6, 17, 42, 52, 20, 25, 114, 6, 14, 51, 45, 12, 3);
INSERT INTO public.match_details VALUES (1136, 1136, 64, 98, 1, 20, 0.25, 85, 7, 20, 44, 51, 28, 32, 111, 9, 8, 59, 53, 4, 1, 72, 102, 7, 17, 1.75, 78, 1, 17, 46, 58, 29, 37, 110, 13, 4, 57, 52, 8, 2);
INSERT INTO public.match_details VALUES (1137, 1137, 40, 63, 2, 11, 0.67, 59, 4, 12, 29, 49, 15, 25, 83, 7, 10, 34, 41, 4, 1.33, 53, 73, 4, 14, 1.33, 52, 2, 5, 28, 53, 15, 28, 78, 6, 4, 39, 50, 10, 3.33);
INSERT INTO public.match_details VALUES (1138, 1138, 78, 102, 8, 16, 1.6, 88, 6, 22, 42, 47, 24, 27, 123, 9, 13, 66, 54, 4, 0.8, 72, 102, 6, 14, 1.2, 86, 8, 29, 32, 37, 23, 26, 125, 10, 4, 53, 42, 13, 2.6);
INSERT INTO public.match_details VALUES (1139, 1139, 68, 96, 2, 13, 0.5, 65, 3, 11, 33, 50, 11, 16, 98, 5, 9, 56, 57, 10, 2.5, 60, 86, 3, 21, 0.75, 83, 2, 29, 30, 36, 7, 8, 108, 7, 10, 48, 44, 9, 2.25);
INSERT INTO public.match_details VALUES (1140, 1140, 90, 117, 4, 17, 0.8, 92, 5, 27, 35, 38, 20, 21, 132, 7, 6, 73, 55, 13, 2.6, 82, 109, 5, 17, 1, 100, 4, 31, 44, 44, 19, 19, 134, 5, 13, 71, 53, 6, 1.2);
INSERT INTO public.match_details VALUES (1141, 1141, 50, 73, 13, 9, 4.33, 33, 3, 11, 17, 51, 9, 27, 54, 2, 3, 29, 54, 8, 2.67, 36, 51, 3, 18, 1, 64, 13, 21, 25, 39, 9, 14, 68, 5, 8, 30, 44, 3, 1);
INSERT INTO public.match_details VALUES (1142, 1142, 60, 75, 6, 10, 2, 42, 1, 13, 21, 50, 11, 26, 69, 0, 2, 43, 62, 11, 3.67, 37, 51, 1, 9, 0.33, 65, 6, 16, 32, 49, 14, 21, 86, 5, 11, 34, 40, 2, 0.67);
INSERT INTO public.match_details VALUES (1143, 1143, 60, 79, 8, 14, 2.67, 50, 1, 14, 27, 54, 16, 32, 92, 7, 7, 41, 45, 11, 3.67, 40, 63, 1, 13, 0.33, 64, 8, 22, 22, 34, 12, 18, 78, 7, 11, 32, 41, 7, 2.33);
INSERT INTO public.match_details VALUES (1144, 1144, 65, 97, 7, 13, 1.75, 64, 5, 17, 32, 50, 11, 17, 94, 10, 6, 47, 50, 11, 2.75, 57, 82, 5, 18, 1.25, 84, 7, 26, 41, 48, 23, 27, 108, 9, 11, 46, 43, 6, 1.5);
INSERT INTO public.match_details VALUES (1145, 1145, 46, 63, 2, 14, 0.67, 62, 2, 17, 27, 43, 9, 14, 78, 2, 6, 37, 47, 7, 2.33, 58, 73, 2, 11, 0.67, 49, 2, 9, 28, 57, 14, 28, 82, 3, 7, 50, 61, 6, 2);
INSERT INTO public.match_details VALUES (1146, 1146, 72, 101, 5, 20, 1.25, 72, 4, 12, 36, 50, 27, 37, 105, 6, 10, 59, 56, 8, 2, 60, 89, 4, 17, 1, 80, 5, 13, 43, 53, 19, 23, 99, 8, 8, 46, 46, 10, 2.5);
INSERT INTO public.match_details VALUES (1147, 1147, 72, 97, 6, 11, 1.5, 70, 6, 20, 27, 38, 16, 22, 102, 5, 8, 57, 56, 9, 2.25, 64, 84, 6, 14, 1.5, 86, 6, 12, 40, 46, 18, 20, 103, 7, 9, 50, 49, 8, 2);
INSERT INTO public.match_details VALUES (1148, 1148, 42, 63, 4, 12, 1.33, 64, 5, 21, 16, 25, 10, 15, 92, 5, 12, 33, 36, 5, 1.67, 57, 77, 5, 13, 1.67, 51, 4, 13, 20, 39, 11, 21, 87, 4, 5, 40, 46, 12, 4);
INSERT INTO public.match_details VALUES (1149, 1149, 50, 74, 2, 9, 0.67, 50, 1, 9, 28, 56, 14, 28, 82, 3, 7, 39, 48, 9, 3, 47, 61, 1, 11, 0.33, 65, 2, 17, 34, 52, 9, 13, 86, 11, 9, 39, 45, 7, 2.33);
INSERT INTO public.match_details VALUES (1150, 1150, 54, 73, 3, 8, 1, 52, 5, 14, 23, 44, 10, 19, 84, 9, 5, 42, 50, 9, 3, 45, 65, 5, 13, 1.67, 65, 3, 17, 35, 53, 15, 23, 82, 7, 9, 35, 43, 5, 1.67);
INSERT INTO public.match_details VALUES (1151, 1151, 75, 101, 5, 17, 1, 87, 3, 26, 45, 51, 24, 27, 114, 6, 9, 57, 50, 13, 2.6, 70, 100, 3, 13, 0.6, 84, 5, 30, 40, 47, 21, 25, 119, 9, 13, 58, 49, 9, 1.8);
INSERT INTO public.match_details VALUES (1152, 1152, 66, 93, 6, 12, 1.5, 81, 2, 22, 46, 56, 25, 30, 116, 13, 6, 57, 49, 3, 0.75, 66, 94, 2, 13, 0.5, 81, 6, 28, 34, 41, 12, 14, 115, 9, 3, 58, 50, 6, 1.5);
INSERT INTO public.match_details VALUES (1153, 1153, 71, 93, 5, 15, 1.25, 77, 2, 27, 36, 46, 19, 24, 113, 11, 10, 56, 50, 10, 2.5, 57, 90, 2, 13, 0.5, 78, 5, 26, 34, 43, 21, 26, 107, 7, 10, 45, 42, 10, 2.5);
INSERT INTO public.match_details VALUES (1154, 1154, 67, 91, 3, 15, 0.6, 93, 4, 16, 54, 58, 26, 27, 126, 17, 14, 53, 42, 11, 2.2, 74, 108, 4, 15, 0.8, 76, 3, 20, 33, 43, 11, 14, 106, 8, 11, 56, 53, 14, 2.8);
INSERT INTO public.match_details VALUES (1155, 1155, 71, 94, 5, 15, 1.25, 67, 3, 18, 32, 47, 14, 20, 101, 7, 4, 61, 60, 5, 1.25, 59, 83, 3, 16, 0.75, 79, 5, 24, 33, 41, 13, 16, 98, 7, 5, 52, 53, 4, 1);
INSERT INTO public.match_details VALUES (1156, 1156, 75, 107, 8, 27, 1.6, 84, 8, 23, 45, 53, 14, 16, 125, 7, 8, 56, 45, 11, 2.2, 69, 104, 8, 20, 1.6, 80, 8, 29, 34, 42, 10, 12, 117, 10, 11, 53, 45, 8, 1.6);
INSERT INTO public.match_details VALUES (1157, 1157, 49, 81, 5, 11, 1.25, 77, 8, 16, 33, 42, 15, 19, 95, 8, 11, 35, 37, 9, 2.25, 76, 97, 8, 20, 2, 70, 5, 20, 36, 51, 21, 30, 107, 5, 9, 57, 53, 11, 2.75);
INSERT INTO public.match_details VALUES (1158, 1158, 49, 74, 5, 16, 1.67, 42, 3, 12, 20, 47, 7, 16, 77, 6, 4, 41, 53, 3, 1, 29, 54, 3, 12, 1, 58, 5, 26, 22, 37, 7, 12, 64, 11, 3, 22, 34, 4, 1.33);
INSERT INTO public.match_details VALUES (1159, 1159, 75, 99, 9, 15, 1.8, 86, 8, 25, 42, 48, 10, 11, 111, 8, 12, 53, 48, 13, 2.6, 74, 102, 8, 16, 1.6, 84, 9, 29, 33, 39, 17, 20, 119, 8, 13, 54, 45, 12, 2.4);
INSERT INTO public.match_details VALUES (1160, 1160, 71, 95, 4, 8, 1, 68, 2, 22, 36, 52, 21, 30, 113, 6, 10, 58, 51, 9, 2.25, 63, 79, 2, 11, 0.5, 87, 4, 22, 48, 55, 26, 29, 114, 10, 9, 51, 45, 10, 2.5);
INSERT INTO public.match_details VALUES (1161, 1161, 82, 107, 6, 20, 1.5, 88, 6, 22, 40, 45, 20, 22, 120, 5, 9, 71, 59, 5, 1.25, 76, 106, 6, 18, 1.5, 87, 6, 16, 45, 51, 18, 20, 112, 7, 5, 61, 54, 9, 2.25);
INSERT INTO public.match_details VALUES (1162, 1162, 77, 109, 6, 12, 1.2, 80, 3, 21, 39, 48, 14, 17, 129, 9, 10, 61, 47, 10, 2, 79, 105, 3, 25, 0.6, 96, 5, 23, 48, 50, 21, 21, 134, 6, 10, 66, 49, 10, 2);
INSERT INTO public.match_details VALUES (1163, 1163, 71, 105, 9, 18, 2.25, 73, 7, 9, 29, 39, 12, 16, 105, 4, 11, 48, 46, 14, 3.5, 68, 94, 7, 21, 1.75, 87, 9, 10, 41, 47, 26, 29, 112, 10, 14, 50, 45, 11, 2.75);
INSERT INTO public.match_details VALUES (1164, 1164, 43, 60, 2, 13, 0.67, 62, 4, 16, 31, 50, 14, 22, 79, 6, 7, 39, 49, 2, 0.67, 49, 74, 4, 12, 1.33, 47, 2, 11, 26, 55, 11, 23, 63, 2, 2, 38, 60, 7, 2.33);
INSERT INTO public.match_details VALUES (1165, 1165, 35, 58, 2, 12, 0.67, 59, 4, 14, 26, 44, 10, 16, 73, 5, 9, 29, 40, 4, 1.33, 57, 73, 4, 14, 1.33, 46, 2, 12, 22, 47, 11, 23, 78, 3, 4, 44, 56, 9, 3);
INSERT INTO public.match_details VALUES (1166, 1166, 77, 111, 5, 13, 1, 96, 1, 33, 50, 52, 30, 31, 135, 14, 18, 64, 47, 8, 1.6, 80, 110, 1, 14, 0.2, 98, 5, 31, 48, 48, 18, 18, 125, 16, 8, 61, 49, 18, 3.6);
INSERT INTO public.match_details VALUES (1167, 1167, 74, 105, 7, 9, 1.4, 95, 2, 22, 51, 53, 33, 34, 139, 10, 16, 55, 40, 12, 2.4, 88, 109, 2, 14, 0.4, 96, 7, 20, 44, 45, 28, 29, 148, 13, 12, 70, 47, 16, 3.2);
INSERT INTO public.match_details VALUES (1168, 1168, 70, 94, 5, 18, 1.25, 90, 4, 21, 53, 58, 30, 33, 113, 9, 10, 55, 49, 10, 2.5, 69, 101, 4, 11, 1, 76, 5, 17, 41, 53, 31, 40, 105, 9, 10, 55, 52, 10, 2.5);
INSERT INTO public.match_details VALUES (1169, 1169, 53, 73, 8, 10, 2.67, 40, 3, 7, 18, 45, 8, 20, 69, 5, 7, 40, 58, 5, 1.67, 36, 53, 3, 13, 1, 63, 8, 21, 27, 42, 6, 9, 65, 5, 5, 26, 40, 7, 2.33);
INSERT INTO public.match_details VALUES (1170, 1170, 54, 73, 9, 9, 3, 35, 5, 6, 19, 54, 8, 22, 61, 2, 4, 36, 59, 9, 3, 32, 46, 5, 11, 1.67, 64, 9, 18, 27, 42, 6, 9, 65, 5, 9, 23, 35, 4, 1.33);
INSERT INTO public.match_details VALUES (1171, 1171, 77, 96, 7, 12, 1.75, 75, 4, 22, 36, 48, 15, 20, 109, 4, 6, 59, 54, 11, 2.75, 66, 87, 4, 12, 1, 84, 7, 25, 48, 57, 17, 20, 119, 5, 11, 56, 47, 6, 1.5);
INSERT INTO public.match_details VALUES (1172, 1172, 71, 101, 7, 17, 1.4, 79, 5, 15, 38, 48, 22, 27, 102, 7, 12, 51, 50, 13, 2.6, 73, 97, 5, 18, 1, 84, 7, 13, 39, 46, 23, 27, 110, 5, 13, 56, 51, 12, 2.4);
INSERT INTO public.match_details VALUES (1173, 1173, 57, 73, 8, 12, 2.67, 49, 2, 10, 31, 63, 15, 30, 72, 4, 4, 40, 56, 9, 3, 36, 60, 2, 11, 0.67, 61, 8, 26, 16, 26, 7, 11, 68, 6, 9, 30, 44, 4, 1.33);
INSERT INTO public.match_details VALUES (1174, 1174, 78, 110, 9, 23, 1.8, 84, 8, 14, 42, 50, 23, 27, 114, 10, 10, 62, 54, 7, 1.4, 66, 104, 8, 20, 1.6, 87, 9, 9, 45, 51, 20, 22, 109, 9, 7, 48, 44, 10, 2);
INSERT INTO public.match_details VALUES (1175, 1175, 76, 104, 2, 13, 0.5, 88, 2, 33, 36, 40, 7, 7, 134, 7, 13, 64, 48, 10, 2.5, 86, 106, 2, 18, 0.5, 91, 2, 15, 64, 70, 37, 40, 134, 7, 10, 71, 53, 13, 3.25);
INSERT INTO public.match_details VALUES (1176, 1176, 70, 96, 3, 18, 0.75, 71, 1, 9, 49, 69, 24, 33, 115, 5, 10, 62, 54, 5, 1.25, 63, 88, 1, 17, 0.25, 78, 3, 17, 40, 51, 25, 32, 102, 7, 5, 52, 51, 10, 2.5);
INSERT INTO public.match_details VALUES (1177, 1177, 74, 103, 5, 19, 1, 81, 4, 11, 50, 61, 26, 32, 126, 14, 10, 61, 48, 8, 1.6, 67, 101, 4, 20, 0.8, 84, 5, 21, 30, 35, 12, 14, 122, 7, 8, 53, 43, 10, 2);
INSERT INTO public.match_details VALUES (1178, 1178, 40, 62, 2, 11, 0.67, 59, 8, 17, 30, 50, 14, 23, 66, 5, 10, 29, 44, 9, 3, 55, 73, 8, 14, 2.67, 51, 2, 14, 24, 47, 11, 21, 76, 6, 9, 37, 49, 10, 3.33);
INSERT INTO public.match_details VALUES (1179, 1179, 48, 67, 3, 10, 1, 64, 7, 21, 28, 43, 9, 14, 79, 5, 7, 40, 51, 5, 1.67, 57, 73, 7, 9, 2.33, 57, 3, 11, 37, 64, 12, 21, 91, 7, 5, 43, 47, 7, 2.33);
INSERT INTO public.match_details VALUES (1180, 1180, 73, 103, 9, 18, 2.25, 71, 3, 12, 32, 45, 12, 16, 96, 8, 7, 54, 56, 10, 2.5, 63, 91, 3, 20, 0.75, 85, 9, 16, 41, 48, 17, 20, 98, 7, 10, 53, 54, 7, 1.75);
INSERT INTO public.match_details VALUES (1181, 1181, 42, 63, 3, 13, 1, 60, 8, 21, 23, 38, 15, 25, 73, 7, 3, 32, 44, 7, 2.33, 53, 74, 8, 14, 2.67, 50, 3, 20, 18, 36, 5, 10, 78, 4, 7, 42, 54, 3, 1);
INSERT INTO public.match_details VALUES (1182, 1182, 30, 49, 0, 8, 0, 62, 6, 21, 25, 40, 12, 19, 81, 9, 10, 26, 32, 4, 1.33, 53, 73, 6, 11, 2, 41, 0, 6, 26, 63, 14, 34, 74, 4, 4, 37, 50, 10, 3.33);
INSERT INTO public.match_details VALUES (1183, 1183, 73, 97, 5, 17, 1, 96, 7, 34, 40, 41, 20, 20, 129, 9, 6, 62, 48, 6, 1.2, 82, 110, 7, 14, 1.4, 80, 5, 21, 36, 45, 23, 28, 118, 7, 6, 69, 58, 6, 1.2);
INSERT INTO public.match_details VALUES (1184, 1184, 88, 124, 8, 23, 1.6, 86, 7, 18, 44, 51, 18, 20, 108, 10, 5, 67, 62, 13, 2.6, 69, 105, 7, 19, 1.4, 101, 8, 25, 50, 49, 25, 24, 132, 11, 13, 57, 43, 5, 1);
INSERT INTO public.match_details VALUES (1185, 1185, 61, 77, 3, 13, 1, 59, 3, 23, 26, 44, 8, 13, 92, 5, 3, 50, 54, 8, 2.67, 47, 66, 3, 7, 1, 64, 3, 25, 26, 40, 12, 18, 81, 6, 8, 41, 51, 3, 1);
INSERT INTO public.match_details VALUES (1186, 1186, 74, 113, 10, 22, 2, 73, 4, 19, 45, 61, 17, 23, 108, 11, 1, 58, 54, 6, 1.2, 61, 97, 4, 24, 0.8, 91, 10, 26, 44, 48, 15, 16, 109, 6, 6, 56, 51, 1, 0.2);
INSERT INTO public.match_details VALUES (1187, 1187, 74, 104, 2, 14, 0.4, 86, 8, 20, 43, 50, 24, 27, 130, 10, 18, 60, 46, 12, 2.4, 77, 104, 8, 18, 1.6, 90, 2, 29, 42, 46, 29, 32, 115, 9, 13, 51, 44, 18, 3.6);
INSERT INTO public.match_details VALUES (1188, 1188, 74, 99, 9, 21, 2.25, 66, 5, 22, 34, 51, 18, 27, 96, 5, 10, 53, 55, 12, 3, 56, 84, 5, 18, 1.25, 78, 9, 23, 32, 41, 11, 14, 107, 5, 12, 41, 38, 10, 2.5);
INSERT INTO public.match_details VALUES (1189, 1189, 87, 110, 3, 19, 0.75, 73, 3, 15, 46, 63, 24, 32, 124, 7, 6, 69, 56, 15, 3.75, 59, 89, 3, 16, 0.75, 91, 3, 25, 50, 54, 29, 31, 121, 6, 15, 50, 41, 6, 1.5);
INSERT INTO public.match_details VALUES (1190, 1190, 78, 118, 6, 29, 1.2, 83, 3, 18, 49, 59, 22, 26, 126, 3, 13, 68, 54, 4, 0.8, 72, 109, 3, 26, 0.6, 89, 6, 24, 45, 50, 21, 23, 126, 11, 4, 56, 44, 13, 2.6);
INSERT INTO public.match_details VALUES (1191, 1191, 60, 91, 3, 24, 0.75, 83, 6, 21, 37, 44, 14, 16, 115, 9, 8, 51, 44, 6, 1.5, 64, 100, 6, 17, 1.5, 67, 3, 9, 39, 58, 21, 31, 104, 10, 6, 50, 48, 8, 2);
INSERT INTO public.match_details VALUES (1192, 1192, 68, 112, 3, 15, 0.6, 77, 8, 18, 33, 42, 22, 28, 113, 4, 10, 62, 55, 3, 0.6, 81, 105, 8, 28, 1.6, 97, 3, 24, 46, 47, 24, 24, 116, 12, 3, 63, 54, 10, 2);
INSERT INTO public.match_details VALUES (1193, 1193, 53, 70, 3, 16, 1, 65, 6, 17, 28, 43, 16, 24, 86, 4, 8, 43, 50, 7, 2.33, 58, 78, 6, 13, 2, 54, 3, 14, 22, 40, 14, 25, 76, 1, 7, 44, 58, 8, 2.67);
INSERT INTO public.match_details VALUES (1194, 1194, 68, 91, 6, 14, 1.5, 86, 9, 20, 46, 53, 8, 9, 117, 8, 7, 57, 49, 5, 1.25, 74, 99, 9, 13, 2.25, 77, 6, 33, 27, 35, 6, 7, 128, 4, 5, 58, 45, 7, 1.75);
INSERT INTO public.match_details VALUES (1195, 1195, 78, 99, 8, 13, 1.6, 81, 6, 27, 33, 40, 10, 12, 120, 8, 13, 67, 56, 3, 0.6, 72, 100, 6, 19, 1.2, 86, 8, 27, 31, 36, 17, 19, 107, 1, 3, 53, 50, 13, 2.6);
INSERT INTO public.match_details VALUES (1196, 1196, 61, 89, 5, 11, 1.25, 88, 4, 30, 45, 51, 29, 32, 107, 9, 8, 49, 46, 7, 1.75, 74, 102, 4, 14, 1, 78, 5, 20, 39, 50, 23, 29, 111, 9, 7, 62, 56, 8, 2);
INSERT INTO public.match_details VALUES (1197, 1197, 59, 94, 4, 8, 1, 72, 10, 19, 35, 48, 23, 31, 97, 13, 7, 44, 45, 11, 2.75, 67, 92, 10, 20, 2.5, 86, 4, 20, 44, 51, 23, 26, 105, 10, 11, 50, 48, 7, 1.75);
INSERT INTO public.match_details VALUES (1198, 1198, 40, 64, 2, 9, 0.67, 65, 7, 20, 24, 36, 15, 23, 73, 5, 10, 32, 44, 6, 2, 65, 79, 7, 14, 2.33, 55, 2, 10, 30, 54, 20, 36, 79, 6, 6, 48, 61, 10, 3.33);
INSERT INTO public.match_details VALUES (1199, 1199, 33, 51, 3, 13, 1, 64, 7, 20, 22, 34, 12, 18, 70, 4, 14, 24, 34, 6, 2, 56, 74, 7, 10, 2.33, 38, 3, 6, 18, 47, 7, 18, 63, 5, 6, 35, 56, 14, 4.67);
INSERT INTO public.match_details VALUES (1200, 1200, 39, 57, 2, 10, 0.67, 63, 8, 13, 27, 42, 11, 17, 71, 4, 5, 35, 49, 2, 0.67, 60, 73, 8, 10, 2.67, 47, 2, 8, 29, 61, 14, 29, 76, 6, 2, 47, 62, 5, 1.67);
INSERT INTO public.match_details VALUES (1201, 1201, 52, 74, 7, 20, 2.33, 41, 0, 9, 28, 68, 12, 29, 65, 3, 4, 42, 65, 3, 1, 31, 56, 0, 15, 0, 54, 7, 27, 17, 31, 9, 16, 60, 5, 3, 27, 45, 4, 1.33);
INSERT INTO public.match_details VALUES (1202, 1202, 56, 80, 3, 16, 1, 55, 2, 8, 27, 49, 17, 30, 83, 4, 6, 46, 55, 7, 2.33, 52, 74, 2, 19, 0.67, 64, 3, 15, 26, 40, 14, 21, 78, 4, 8, 44, 56, 6, 2);
INSERT INTO public.match_details VALUES (1203, 1203, 56, 73, 7, 14, 2.33, 42, 2, 14, 18, 42, 8, 19, 66, 5, 4, 40, 61, 9, 3, 32, 54, 2, 12, 0.67, 59, 7, 26, 18, 30, 6, 10, 70, 5, 9, 26, 37, 4, 1.33);
INSERT INTO public.match_details VALUES (1204, 1204, 75, 96, 3, 21, 0.75, 71, 6, 20, 32, 45, 16, 22, 115, 4, 3, 64, 56, 8, 2, 51, 78, 6, 7, 1.5, 75, 3, 29, 35, 46, 27, 36, 114, 10, 8, 42, 37, 3, 0.75);
INSERT INTO public.match_details VALUES (1205, 1205, 60, 90, 5, 9, 1.25, 80, 6, 21, 35, 43, 15, 18, 112, 8, 10, 43, 38, 12, 3, 76, 95, 6, 15, 1.5, 81, 5, 23, 38, 46, 13, 16, 116, 10, 12, 60, 52, 10, 2.5);
INSERT INTO public.match_details VALUES (1206, 1206, 68, 109, 5, 17, 1, 86, 6, 31, 39, 45, 16, 18, 117, 6, 13, 47, 40, 16, 3.2, 76, 103, 6, 17, 1.2, 90, 5, 20, 48, 53, 11, 12, 128, 11, 17, 56, 44, 14, 2.8);
INSERT INTO public.match_details VALUES (1207, 1207, 70, 98, 6, 13, 1.5, 57, 5, 16, 19, 33, 9, 15, 99, 4, 12, 51, 52, 13, 3.25, 55, 77, 5, 20, 1.25, 85, 6, 20, 36, 42, 10, 11, 101, 9, 13, 38, 38, 12, 3);
INSERT INTO public.match_details VALUES (1208, 1208, 83, 111, 5, 18, 1, 86, 4, 19, 27, 31, 18, 20, 123, 5, 9, 67, 54, 11, 2.2, 77, 104, 4, 18, 0.8, 93, 5, 17, 43, 46, 27, 29, 132, 6, 11, 64, 48, 9, 1.8);
INSERT INTO public.match_details VALUES (1209, 1209, 42, 57, 5, 12, 1.67, 67, 5, 9, 39, 58, 13, 19, 76, 12, 5, 30, 39, 7, 2.33, 50, 74, 5, 7, 1.67, 45, 5, 12, 22, 48, 5, 11, 74, 3, 7, 40, 54, 5, 1.67);
INSERT INTO public.match_details VALUES (1210, 1210, 67, 96, 6, 12, 1.5, 57, 4, 15, 27, 47, 13, 22, 87, 4, 3, 49, 56, 12, 3, 58, 77, 4, 20, 1, 84, 6, 28, 32, 38, 14, 16, 108, 7, 12, 51, 47, 3, 0.75);
INSERT INTO public.match_details VALUES (1211, 1211, 63, 95, 8, 17, 2, 81, 6, 17, 49, 60, 26, 32, 102, 5, 9, 45, 44, 10, 2.5, 74, 100, 6, 19, 1.5, 78, 8, 27, 35, 44, 11, 14, 116, 9, 10, 59, 51, 9, 2.25);
INSERT INTO public.match_details VALUES (1212, 1212, 69, 95, 7, 15, 1.75, 63, 0, 13, 38, 60, 19, 30, 111, 9, 5, 51, 46, 11, 2.75, 54, 80, 0, 17, 0, 80, 7, 25, 38, 47, 17, 21, 111, 7, 11, 49, 44, 5, 1.25);
INSERT INTO public.match_details VALUES (1213, 1213, 33, 58, 3, 14, 1, 56, 4, 18, 18, 32, 13, 23, 63, 5, 4, 30, 48, 0, 0, 52, 74, 4, 18, 1.33, 44, 3, 10, 27, 61, 18, 40, 66, 5, 0, 44, 67, 4, 1.33);
INSERT INTO public.match_details VALUES (1214, 1214, 53, 73, 3, 10, 1, 49, 7, 14, 16, 32, 4, 8, 71, 8, 2, 41, 58, 9, 3, 35, 58, 7, 9, 2.33, 62, 3, 17, 24, 38, 11, 17, 76, 8, 9, 26, 34, 2, 0.67);
INSERT INTO public.match_details VALUES (1215, 1215, 67, 104, 4, 14, 0.8, 79, 7, 20, 34, 43, 21, 26, 114, 9, 11, 54, 47, 9, 1.8, 74, 101, 7, 22, 1.4, 90, 4, 27, 38, 42, 23, 25, 125, 13, 9, 56, 45, 11, 2.2);
INSERT INTO public.match_details VALUES (1216, 1216, 49, 74, 8, 16, 2.67, 40, 4, 7, 26, 65, 12, 30, 61, 3, 4, 37, 61, 4, 1.33, 33, 55, 4, 15, 1.33, 58, 8, 28, 16, 27, 5, 8, 59, 7, 4, 25, 42, 4, 1.33);
INSERT INTO public.match_details VALUES (1217, 1217, 50, 74, 5, 7, 1.67, 41, 1, 7, 23, 56, 11, 26, 71, 4, 3, 38, 54, 7, 2.33, 40, 53, 1, 12, 0.33, 67, 5, 23, 31, 46, 14, 20, 80, 7, 7, 36, 45, 3, 1);
INSERT INTO public.match_details VALUES (1218, 1218, 69, 104, 5, 20, 1, 89, 6, 23, 37, 41, 16, 17, 117, 7, 13, 53, 45, 11, 2.2, 84, 113, 6, 24, 1.2, 84, 5, 25, 36, 42, 18, 21, 125, 8, 11, 65, 52, 13, 2.6);
INSERT INTO public.match_details VALUES (1219, 1219, 48, 61, 2, 12, 0.67, 64, 2, 18, 30, 46, 15, 23, 85, 7, 9, 41, 48, 5, 1.67, 55, 73, 2, 9, 0.67, 49, 2, 17, 23, 46, 15, 30, 76, 2, 5, 44, 58, 9, 3);
INSERT INTO public.match_details VALUES (1220, 1220, 53, 74, 8, 12, 2.67, 43, 3, 10, 25, 58, 10, 23, 71, 4, 3, 41, 58, 4, 1.33, 39, 58, 3, 15, 1, 62, 8, 16, 31, 50, 9, 14, 75, 6, 4, 33, 44, 3, 1);
INSERT INTO public.match_details VALUES (1221, 1221, 33, 50, 3, 12, 1, 63, 6, 21, 33, 52, 17, 26, 71, 8, 8, 26, 37, 4, 1.33, 53, 74, 6, 11, 2, 38, 3, 9, 21, 55, 12, 31, 63, 2, 4, 39, 62, 8, 2.67);
INSERT INTO public.match_details VALUES (1222, 1222, 73, 100, 4, 15, 1, 79, 5, 25, 38, 48, 19, 24, 103, 5, 10, 55, 53, 14, 3.5, 72, 93, 5, 14, 1.25, 85, 4, 31, 36, 42, 15, 17, 120, 12, 14, 57, 48, 10, 2.5);
INSERT INTO public.match_details VALUES (1223, 1223, 81, 106, 7, 14, 1.4, 93, 4, 20, 54, 58, 16, 17, 139, 8, 11, 61, 44, 13, 2.6, 82, 108, 4, 15, 0.8, 92, 7, 31, 41, 44, 18, 19, 137, 5, 13, 67, 49, 11, 2.2);
INSERT INTO public.match_details VALUES (1224, 1224, 46, 64, 3, 14, 1, 64, 5, 16, 36, 56, 9, 14, 89, 8, 8, 38, 43, 5, 1.67, 54, 77, 5, 13, 1.67, 50, 3, 13, 25, 50, 10, 20, 78, 3, 5, 41, 53, 8, 2.67);
INSERT INTO public.match_details VALUES (1225, 1225, 37, 51, 2, 17, 0.67, 66, 2, 12, 23, 34, 15, 22, 81, 8, 7, 32, 40, 3, 1, 44, 73, 2, 7, 0.67, 34, 2, 4, 15, 44, 9, 26, 65, 4, 3, 35, 54, 7, 2.33);
INSERT INTO public.match_details VALUES (1226, 1226, 54, 74, 6, 13, 2, 40, 1, 10, 19, 47, 9, 22, 62, 7, 5, 35, 56, 13, 4.33, 29, 51, 1, 11, 0.33, 61, 6, 18, 25, 40, 12, 19, 63, 6, 13, 23, 37, 5, 1.67);
INSERT INTO public.match_details VALUES (1227, 1227, 62, 94, 2, 11, 0.5, 70, 5, 23, 34, 48, 15, 21, 101, 8, 9, 49, 49, 11, 2.75, 65, 88, 5, 18, 1.25, 83, 2, 24, 34, 40, 17, 20, 118, 11, 11, 51, 43, 9, 2.25);
INSERT INTO public.match_details VALUES (1228, 1228, 59, 74, 6, 13, 2, 43, 0, 11, 23, 53, 11, 25, 68, 2, 4, 43, 63, 10, 3.33, 35, 54, 0, 11, 0, 61, 6, 19, 29, 47, 11, 18, 74, 5, 10, 31, 42, 4, 1.33);
INSERT INTO public.match_details VALUES (1229, 1229, 57, 76, 5, 11, 1.67, 56, 3, 13, 27, 48, 14, 25, 88, 6, 8, 41, 47, 11, 3.67, 45, 66, 3, 10, 1, 65, 5, 11, 39, 60, 26, 40, 94, 7, 11, 33, 35, 9, 3);
INSERT INTO public.match_details VALUES (1230, 1230, 83, 107, 15, 24, 3, 80, 3, 27, 39, 48, 20, 25, 108, 6, 10, 55, 51, 13, 2.6, 64, 97, 3, 17, 0.6, 83, 15, 22, 35, 42, 18, 21, 108, 6, 13, 51, 47, 10, 2);
INSERT INTO public.match_details VALUES (1231, 1231, 52, 73, 9, 14, 3, 49, 4, 13, 26, 53, 9, 18, 66, 5, 5, 38, 58, 5, 1.67, 36, 60, 4, 11, 1.33, 59, 9, 19, 25, 42, 11, 18, 77, 8, 5, 27, 35, 5, 1.67);
INSERT INTO public.match_details VALUES (1232, 1232, 55, 73, 3, 11, 1, 47, 4, 14, 23, 48, 13, 27, 63, 2, 2, 38, 60, 14, 4.67, 40, 58, 4, 11, 1.33, 62, 3, 11, 39, 62, 23, 37, 85, 8, 14, 34, 40, 2, 0.67);
INSERT INTO public.match_details VALUES (1233, 1233, 71, 99, 10, 22, 2.5, 75, 4, 26, 36, 48, 12, 16, 103, 7, 11, 51, 50, 10, 2.5, 60, 93, 4, 18, 1, 77, 10, 18, 38, 49, 18, 23, 92, 10, 10, 45, 49, 11, 2.75);
INSERT INTO public.match_details VALUES (1234, 1234, 58, 74, 10, 7, 3.33, 41, 2, 11, 24, 58, 14, 34, 74, 6, 3, 41, 55, 7, 2.33, 39, 54, 2, 13, 0.67, 67, 10, 23, 24, 35, 15, 22, 71, 2, 7, 34, 48, 3, 1);
INSERT INTO public.match_details VALUES (1235, 1235, 85, 108, 7, 12, 1.4, 93, 10, 12, 45, 48, 18, 19, 135, 10, 9, 56, 41, 22, 4.4, 82, 107, 10, 14, 2, 96, 7, 23, 45, 46, 14, 14, 139, 4, 22, 63, 45, 9, 1.8);
INSERT INTO public.match_details VALUES (1236, 1236, 35, 60, 5, 13, 1.67, 57, 4, 16, 24, 42, 14, 24, 68, 3, 12, 30, 44, 0, 0, 58, 73, 4, 16, 1.33, 47, 5, 8, 24, 51, 13, 27, 73, 5, 0, 42, 58, 12, 4);
INSERT INTO public.match_details VALUES (1237, 1237, 54, 82, 2, 16, 0.5, 80, 8, 24, 36, 45, 22, 27, 102, 9, 10, 41, 40, 11, 2.75, 71, 96, 8, 16, 2, 66, 2, 18, 32, 48, 17, 25, 101, 8, 11, 53, 52, 10, 2.5);
INSERT INTO public.match_details VALUES (1238, 1238, 67, 95, 6, 22, 1.2, 95, 6, 29, 42, 44, 18, 18, 131, 8, 12, 51, 39, 10, 2, 77, 108, 6, 13, 1.2, 73, 6, 22, 36, 49, 13, 17, 125, 8, 10, 59, 47, 12, 2.4);
INSERT INTO public.match_details VALUES (1239, 1239, 67, 94, 6, 11, 1.5, 67, 6, 16, 27, 40, 14, 20, 98, 11, 4, 48, 49, 13, 3.25, 65, 89, 6, 22, 1.5, 83, 6, 19, 38, 45, 15, 18, 113, 4, 13, 55, 49, 4, 1);
INSERT INTO public.match_details VALUES (1240, 1240, 58, 78, 4, 12, 1.33, 58, 3, 21, 18, 31, 9, 15, 85, 5, 4, 51, 60, 3, 1, 48, 68, 3, 10, 1, 66, 4, 19, 27, 40, 8, 12, 80, 11, 3, 41, 51, 4, 1.33);
INSERT INTO public.match_details VALUES (1241, 1241, 50, 75, 4, 15, 1.33, 52, 6, 20, 20, 38, 5, 9, 80, 3, 7, 34, 42, 12, 4, 45, 68, 6, 16, 2, 59, 4, 14, 29, 49, 13, 22, 82, 9, 12, 32, 39, 7, 2.33);
INSERT INTO public.match_details VALUES (1242, 1242, 54, 73, 9, 17, 3, 48, 4, 8, 23, 47, 10, 20, 65, 3, 4, 35, 54, 10, 3.33, 32, 58, 4, 10, 1.33, 56, 9, 9, 22, 39, 17, 30, 71, 8, 10, 24, 34, 4, 1.33);
INSERT INTO public.match_details VALUES (1243, 1243, 58, 73, 5, 14, 1.67, 51, 3, 14, 18, 35, 10, 19, 75, 2, 7, 41, 55, 12, 4, 43, 63, 4, 11, 1.33, 59, 5, 12, 25, 42, 12, 20, 75, 4, 12, 32, 43, 7, 2.33);
INSERT INTO public.match_details VALUES (1244, 1244, 67, 96, 10, 19, 2.5, 75, 4, 19, 38, 50, 18, 24, 97, 10, 6, 49, 51, 8, 2, 57, 89, 4, 14, 1, 77, 10, 17, 35, 45, 18, 23, 110, 13, 8, 47, 43, 6, 1.5);
INSERT INTO public.match_details VALUES (1245, 1245, 55, 85, 3, 13, 0.75, 79, 3, 22, 36, 45, 19, 24, 135, 7, 7, 45, 33, 7, 1.75, 72, 93, 3, 14, 0.75, 72, 3, 13, 47, 65, 23, 31, 138, 13, 7, 62, 45, 7, 1.75);
INSERT INTO public.match_details VALUES (1246, 1246, 80, 105, 9, 16, 1.8, 87, 12, 28, 40, 45, 19, 21, 102, 5, 2, 61, 60, 10, 2, 80, 105, 12, 18, 2.4, 89, 9, 27, 35, 39, 20, 22, 119, 6, 10, 66, 55, 2, 0.4);
INSERT INTO public.match_details VALUES (1247, 1247, 55, 73, 3, 15, 1, 57, 6, 15, 24, 42, 17, 29, 76, 7, 4, 38, 50, 14, 4.67, 45, 69, 6, 12, 2, 58, 3, 25, 23, 39, 15, 25, 81, 6, 14, 35, 43, 4, 1.33);
INSERT INTO public.match_details VALUES (1248, 1248, 68, 96, 8, 17, 2, 70, 4, 22, 32, 45, 14, 20, 91, 1, 12, 49, 54, 11, 2.75, 67, 89, 4, 19, 1, 79, 8, 17, 41, 51, 24, 30, 100, 8, 11, 51, 51, 12, 3);
INSERT INTO public.match_details VALUES (1249, 1249, 79, 102, 7, 22, 1.75, 86, 5, 24, 38, 44, 24, 27, 114, 6, 7, 63, 55, 9, 2.25, 69, 99, 5, 13, 1.25, 80, 7, 24, 32, 40, 14, 17, 102, 8, 9, 57, 56, 7, 1.75);
INSERT INTO public.match_details VALUES (1250, 1250, 76, 103, 11, 13, 2.2, 88, 13, 26, 33, 37, 14, 15, 110, 10, 7, 49, 45, 16, 3.2, 78, 106, 8, 18, 1.6, 90, 14, 31, 35, 38, 9, 10, 126, 5, 16, 63, 50, 7, 1.4);
INSERT INTO public.match_details VALUES (1251, 1251, 72, 108, 7, 18, 1.4, 85, 5, 29, 40, 47, 15, 17, 109, 9, 7, 52, 48, 13, 2.6, 81, 110, 5, 25, 1, 90, 7, 25, 36, 40, 21, 23, 128, 10, 13, 69, 54, 7, 1.4);
INSERT INTO public.match_details VALUES (1252, 1252, 65, 94, 6, 9, 1.5, 84, 13, 26, 31, 36, 8, 9, 96, 11, 5, 49, 51, 10, 2.5, 78, 98, 13, 14, 3.25, 85, 6, 24, 36, 42, 16, 18, 109, 9, 10, 60, 55, 5, 1.25);
INSERT INTO public.match_details VALUES (1253, 1253, 48, 81, 0, 17, 0, 80, 7, 23, 29, 36, 21, 26, 117, 13, 10, 43, 37, 5, 1.25, 62, 96, 7, 16, 1.75, 64, 0, 19, 26, 40, 19, 29, 105, 14, 5, 45, 43, 10, 2.5);
INSERT INTO public.match_details VALUES (1254, 1254, 78, 108, 4, 16, 0.8, 89, 6, 27, 38, 42, 16, 17, 129, 12, 14, 63, 49, 11, 2.2, 76, 108, 6, 19, 1.2, 92, 4, 23, 46, 50, 23, 25, 133, 7, 11, 56, 42, 14, 2.8);
INSERT INTO public.match_details VALUES (1255, 1255, 41, 64, 3, 10, 1, 61, 4, 17, 29, 47, 11, 18, 78, 6, 11, 31, 40, 7, 2.33, 57, 74, 4, 13, 1.33, 54, 3, 18, 22, 40, 5, 9, 82, 6, 7, 42, 51, 11, 3.67);
INSERT INTO public.match_details VALUES (1256, 1256, 63, 94, 5, 13, 1.25, 76, 5, 17, 44, 57, 21, 27, 98, 6, 8, 44, 45, 14, 3.5, 71, 95, 5, 19, 1.25, 81, 5, 26, 34, 41, 11, 13, 117, 9, 14, 58, 50, 8, 2);
INSERT INTO public.match_details VALUES (1257, 1257, 56, 73, 5, 9, 1.67, 52, 2, 13, 25, 48, 17, 32, 77, 5, 6, 44, 57, 7, 2.33, 42, 59, 2, 7, 0.67, 64, 5, 22, 28, 43, 17, 26, 83, 11, 7, 34, 41, 6, 2);
INSERT INTO public.match_details VALUES (1258, 1258, 73, 108, 5, 15, 1, 86, 3, 25, 40, 46, 18, 20, 130, 6, 14, 60, 46, 8, 1.6, 82, 106, 3, 20, 0.6, 93, 5, 37, 44, 47, 18, 19, 140, 12, 8, 65, 46, 14, 2.8);
INSERT INTO public.match_details VALUES (1259, 1259, 41, 67, 5, 11, 1.67, 55, 5, 9, 19, 34, 7, 12, 73, 9, 6, 29, 40, 7, 2.33, 55, 73, 5, 18, 1.67, 56, 5, 2, 33, 58, 18, 32, 83, 4, 7, 44, 53, 6, 2);
INSERT INTO public.match_details VALUES (1260, 1260, 72, 99, 4, 25, 0.8, 89, 9, 31, 27, 30, 14, 15, 115, 8, 11, 63, 55, 5, 1, 76, 110, 9, 21, 1.8, 74, 4, 17, 44, 59, 28, 37, 107, 3, 5, 56, 52, 11, 2.2);
INSERT INTO public.match_details VALUES (1261, 1261, 63, 79, 3, 15, 0.75, 83, 15, 15, 38, 45, 21, 25, 101, 6, 6, 50, 50, 10, 2.5, 70, 93, 15, 10, 3.75, 64, 3, 16, 35, 54, 17, 26, 97, 4, 10, 49, 51, 6, 1.5);
INSERT INTO public.match_details VALUES (1262, 1262, 36, 51, 4, 17, 1.33, 62, 8, 8, 33, 53, 21, 33, 72, 6, 7, 28, 39, 4, 1.33, 50, 74, 8, 12, 2.67, 34, 4, 8, 14, 41, 7, 20, 66, 2, 4, 35, 53, 7, 2.33);
INSERT INTO public.match_details VALUES (1263, 1263, 73, 98, 6, 22, 1.2, 85, 9, 27, 41, 48, 17, 20, 109, 6, 7, 55, 50, 12, 2.4, 73, 101, 9, 16, 1.8, 76, 6, 21, 40, 52, 19, 25, 109, 6, 12, 57, 52, 7, 1.4);
INSERT INTO public.match_details VALUES (1264, 1264, 67, 92, 5, 15, 1.25, 85, 4, 14, 51, 60, 30, 35, 115, 10, 9, 52, 45, 10, 2.5, 67, 97, 4, 12, 1, 77, 5, 17, 35, 45, 22, 28, 106, 6, 10, 54, 51, 9, 2.25);
INSERT INTO public.match_details VALUES (1265, 1265, 61, 73, 5, 18, 1.67, 53, 7, 17, 27, 50, 18, 33, 77, 2, 4, 46, 60, 10, 3.33, 36, 61, 7, 8, 2.33, 55, 5, 26, 15, 27, 2, 3, 64, 3, 10, 25, 39, 4, 1.33);
INSERT INTO public.match_details VALUES (1266, 1266, 59, 91, 2, 14, 0.4, 95, 9, 11, 53, 55, 33, 34, 117, 10, 16, 47, 40, 10, 2, 86, 110, 9, 15, 1.8, 77, 2, 13, 33, 42, 26, 33, 109, 11, 10, 61, 56, 16, 3.2);
INSERT INTO public.match_details VALUES (1267, 1267, 65, 91, 9, 16, 2.25, 74, 7, 27, 32, 43, 11, 14, 98, 9, 9, 43, 44, 13, 3.25, 62, 90, 7, 16, 1.75, 75, 9, 24, 31, 41, 11, 14, 97, 6, 13, 46, 47, 9, 2.25);
INSERT INTO public.match_details VALUES (1268, 1268, 65, 91, 2, 19, 0.67, 71, 0, 14, 42, 59, 17, 23, 106, 4, 9, 56, 53, 7, 2.33, 61, 89, 0, 18, 0, 72, 2, 27, 28, 38, 15, 20, 96, 4, 7, 52, 54, 9, 3);
INSERT INTO public.match_details VALUES (1269, 1269, 71, 104, 11, 14, 2.2, 76, 7, 14, 40, 52, 21, 27, 109, 11, 14, 48, 44, 12, 2.4, 67, 96, 7, 20, 1.4, 90, 11, 27, 34, 37, 15, 16, 106, 10, 12, 46, 43, 14, 2.8);
INSERT INTO public.match_details VALUES (1270, 1270, 44, 63, 3, 14, 1, 61, 4, 15, 23, 37, 9, 14, 87, 6, 9, 36, 41, 5, 1.67, 54, 73, 4, 12, 1.33, 49, 3, 15, 22, 44, 11, 22, 72, 3, 5, 41, 57, 9, 3);
INSERT INTO public.match_details VALUES (1271, 1271, 67, 89, 4, 13, 1, 84, 5, 18, 44, 52, 29, 34, 128, 8, 14, 51, 40, 12, 3, 70, 93, 5, 9, 1.25, 75, 4, 14, 43, 57, 26, 34, 115, 7, 12, 51, 44, 14, 3.5);
INSERT INTO public.match_details VALUES (1272, 1272, 56, 80, 2, 13, 0.67, 57, 5, 15, 28, 49, 19, 33, 84, 6, 5, 46, 55, 8, 2.67, 50, 73, 5, 16, 1.67, 67, 2, 8, 45, 67, 23, 34, 93, 6, 8, 40, 43, 5, 1.67);
INSERT INTO public.match_details VALUES (1273, 1273, 60, 91, 2, 10, 0.5, 79, 5, 21, 41, 51, 22, 27, 112, 12, 13, 47, 42, 11, 2.75, 69, 93, 5, 14, 1.25, 81, 2, 23, 38, 46, 16, 19, 113, 10, 11, 51, 45, 13, 3.25);
INSERT INTO public.match_details VALUES (1274, 1274, 70, 107, 8, 16, 1.6, 72, 3, 16, 41, 56, 13, 18, 99, 11, 8, 51, 52, 11, 2.2, 57, 87, 3, 15, 0.6, 91, 8, 21, 49, 53, 22, 24, 109, 16, 11, 46, 42, 8, 1.6);
INSERT INTO public.match_details VALUES (1275, 1275, 45, 63, 3, 12, 1, 63, 3, 23, 34, 53, 13, 20, 77, 5, 7, 39, 51, 3, 1, 53, 73, 3, 10, 1, 51, 3, 13, 29, 56, 18, 35, 68, 6, 3, 43, 63, 7, 2.33);
INSERT INTO public.match_details VALUES (1276, 1276, 78, 112, 7, 19, 1.4, 91, 2, 19, 37, 40, 27, 29, 141, 12, 9, 57, 40, 14, 2.8, 79, 109, 2, 18, 0.4, 93, 7, 14, 45, 48, 30, 32, 138, 8, 14, 68, 49, 9, 1.8);
INSERT INTO public.match_details VALUES (1277, 1277, 48, 73, 6, 13, 2, 40, 1, 7, 24, 60, 9, 22, 53, 0, 5, 33, 62, 9, 3, 39, 60, 1, 20, 0.33, 60, 6, 14, 29, 48, 7, 11, 71, 5, 9, 33, 46, 5, 1.67);
INSERT INTO public.match_details VALUES (1278, 1278, 72, 97, 5, 16, 1, 84, 9, 23, 34, 40, 18, 21, 112, 6, 14, 49, 44, 18, 3.6, 78, 102, 9, 18, 1.8, 81, 5, 19, 36, 44, 17, 20, 116, 4, 18, 55, 47, 14, 2.8);
INSERT INTO public.match_details VALUES (1279, 1279, 71, 98, 9, 12, 2.25, 59, 2, 17, 30, 50, 17, 28, 92, 4, 5, 50, 54, 12, 3, 56, 74, 2, 15, 0.5, 86, 9, 21, 42, 48, 18, 20, 111, 12, 12, 49, 44, 5, 1.25);
INSERT INTO public.match_details VALUES (1280, 1280, 40, 56, 2, 11, 0.67, 62, 5, 12, 36, 58, 21, 33, 69, 5, 8, 35, 51, 3, 1, 58, 74, 5, 12, 1.67, 45, 2, 6, 19, 42, 8, 17, 64, 2, 3, 45, 70, 8, 2.67);
INSERT INTO public.match_details VALUES (1281, 1281, 70, 96, 5, 14, 1.25, 72, 12, 18, 31, 43, 19, 26, 96, 4, 7, 52, 54, 13, 3.25, 65, 87, 12, 15, 3, 82, 5, 22, 46, 56, 30, 36, 100, 6, 13, 46, 46, 7, 1.75);
INSERT INTO public.match_details VALUES (1282, 1282, 77, 112, 7, 25, 1.4, 73, 7, 19, 37, 50, 22, 30, 101, 7, 6, 56, 55, 14, 2.8, 62, 95, 7, 22, 1.4, 87, 7, 37, 32, 36, 7, 8, 96, 11, 14, 49, 51, 6, 1.2);
INSERT INTO public.match_details VALUES (1283, 1283, 81, 101, 6, 13, 1.2, 100, 7, 25, 52, 52, 32, 32, 142, 9, 12, 63, 44, 12, 2.4, 84, 112, 7, 12, 1.4, 88, 6, 33, 36, 40, 22, 25, 135, 5, 12, 65, 48, 12, 2.4);
INSERT INTO public.match_details VALUES (1284, 1284, 60, 73, 4, 11, 1.33, 43, 0, 8, 29, 67, 13, 30, 82, 2, 7, 51, 62, 5, 1.67, 36, 53, 0, 10, 0, 62, 4, 25, 31, 50, 11, 17, 71, 3, 5, 29, 41, 7, 2.33);
INSERT INTO public.match_details VALUES (1285, 1285, 67, 95, 9, 13, 2.25, 74, 3, 28, 35, 47, 19, 25, 117, 9, 8, 52, 44, 6, 1.5, 63, 90, 3, 16, 0.75, 82, 9, 30, 29, 35, 13, 15, 116, 10, 6, 52, 45, 8, 2);
INSERT INTO public.match_details VALUES (1286, 1286, 79, 101, 9, 11, 2.25, 63, 2, 14, 33, 52, 14, 22, 95, 8, 8, 56, 59, 14, 3.5, 51, 73, 2, 10, 0.5, 90, 9, 22, 35, 38, 16, 17, 97, 9, 14, 41, 42, 8, 2);
INSERT INTO public.match_details VALUES (1287, 1287, 58, 73, 9, 18, 3, 40, 0, 12, 20, 50, 14, 35, 67, 5, 4, 39, 58, 10, 3.33, 24, 49, 0, 9, 0, 55, 9, 9, 31, 56, 23, 41, 58, 4, 10, 20, 34, 4, 1.33);
INSERT INTO public.match_details VALUES (1288, 1288, 58, 87, 2, 11, 0.5, 71, 5, 16, 38, 53, 20, 28, 100, 9, 6, 52, 52, 4, 1, 66, 92, 5, 21, 1.25, 76, 2, 23, 33, 43, 16, 21, 100, 6, 4, 55, 55, 6, 1.5);
INSERT INTO public.match_details VALUES (1289, 1289, 35, 52, 3, 8, 1, 63, 7, 18, 25, 39, 15, 23, 83, 10, 7, 26, 31, 6, 2, 53, 74, 7, 11, 2.33, 44, 3, 10, 25, 56, 13, 29, 75, 4, 6, 39, 52, 7, 2.33);
INSERT INTO public.match_details VALUES (1290, 1290, 53, 83, 1, 13, 0.25, 79, 3, 15, 47, 59, 27, 34, 108, 9, 16, 46, 43, 6, 1.5, 74, 97, 3, 18, 0.75, 70, 1, 17, 36, 51, 22, 31, 104, 9, 6, 55, 53, 16, 4);
INSERT INTO public.match_details VALUES (1291, 1291, 65, 99, 7, 17, 1.4, 84, 10, 20, 38, 45, 14, 16, 117, 14, 9, 49, 42, 9, 1.8, 76, 106, 10, 22, 2, 82, 7, 19, 39, 47, 18, 21, 117, 9, 9, 57, 49, 9, 1.8);
INSERT INTO public.match_details VALUES (1292, 1292, 61, 92, 3, 11, 0.75, 78, 5, 26, 36, 46, 17, 21, 102, 11, 10, 46, 45, 12, 3, 72, 94, 5, 16, 1.25, 81, 3, 23, 49, 60, 20, 24, 122, 12, 12, 57, 47, 10, 2.5);
INSERT INTO public.match_details VALUES (1293, 1293, 74, 106, 8, 15, 1.6, 84, 7, 19, 22, 26, 16, 19, 107, 7, 6, 52, 49, 14, 2.8, 80, 106, 7, 22, 1.4, 91, 8, 13, 43, 47, 29, 31, 125, 8, 14, 67, 54, 6, 1.2);
INSERT INTO public.match_details VALUES (1294, 1294, 64, 90, 3, 13, 0.75, 78, 6, 22, 38, 48, 14, 17, 91, 5, 5, 47, 52, 14, 3.5, 74, 91, 6, 13, 1.5, 77, 3, 29, 29, 37, 12, 15, 114, 10, 14, 63, 55, 5, 1.25);
INSERT INTO public.match_details VALUES (1295, 1295, 59, 76, 3, 17, 1, 58, 1, 8, 36, 62, 20, 34, 84, 5, 4, 48, 57, 8, 2.67, 46, 72, 1, 14, 0.33, 59, 3, 15, 31, 52, 17, 28, 83, 4, 8, 41, 49, 4, 1.33);
INSERT INTO public.match_details VALUES (1296, 1296, 63, 95, 3, 13, 0.75, 61, 5, 16, 27, 44, 15, 24, 87, 9, 11, 47, 54, 13, 3.25, 58, 84, 5, 23, 1.25, 82, 3, 25, 40, 48, 25, 30, 95, 9, 13, 42, 44, 11, 2.75);
INSERT INTO public.match_details VALUES (1297, 1297, 68, 104, 6, 20, 1.2, 85, 3, 32, 32, 37, 16, 18, 129, 7, 10, 54, 42, 8, 1.6, 76, 104, 3, 19, 0.6, 84, 6, 15, 47, 55, 19, 22, 141, 16, 8, 63, 45, 10, 2);
INSERT INTO public.match_details VALUES (1298, 1298, 69, 101, 6, 21, 1.2, 82, 7, 12, 29, 35, 19, 23, 110, 5, 9, 55, 50, 8, 1.6, 70, 98, 7, 16, 1.4, 80, 6, 11, 41, 51, 21, 26, 108, 12, 8, 54, 50, 9, 1.8);
INSERT INTO public.match_details VALUES (1299, 1299, 57, 73, 12, 10, 4, 30, 2, 5, 21, 70, 12, 40, 56, 1, 2, 37, 66, 8, 2.67, 24, 39, 2, 9, 0.67, 63, 12, 23, 26, 41, 6, 9, 63, 6, 8, 20, 32, 2, 0.67);
INSERT INTO public.match_details VALUES (1300, 1300, 76, 103, 7, 17, 1.4, 90, 1, 12, 58, 64, 33, 36, 138, 9, 17, 56, 41, 13, 2.6, 76, 103, 1, 13, 0.2, 86, 7, 29, 29, 33, 17, 19, 140, 11, 13, 58, 41, 17, 3.4);
INSERT INTO public.match_details VALUES (1301, 1301, 56, 73, 9, 13, 3, 45, 5, 10, 22, 48, 6, 13, 71, 3, 8, 41, 58, 6, 2, 36, 58, 2, 13, 0.67, 60, 14, 15, 25, 41, 7, 11, 60, 6, 6, 26, 43, 8, 2.67);
INSERT INTO public.match_details VALUES (1302, 1302, 50, 74, 1, 8, 0.33, 38, 0, 7, 25, 65, 12, 31, 67, 5, 2, 41, 61, 8, 2.67, 36, 52, 0, 14, 0, 66, 1, 20, 31, 46, 16, 24, 81, 9, 8, 34, 42, 2, 0.67);
INSERT INTO public.match_details VALUES (1303, 1303, 67, 94, 7, 14, 1.75, 64, 4, 17, 35, 54, 20, 31, 89, 7, 5, 51, 57, 9, 2.25, 55, 81, 4, 17, 1, 79, 7, 24, 33, 41, 14, 17, 86, 8, 9, 46, 53, 5, 1.25);
INSERT INTO public.match_details VALUES (1304, 1304, 69, 91, 7, 20, 1.75, 82, 1, 27, 32, 39, 11, 13, 107, 12, 10, 51, 48, 11, 2.75, 60, 92, 1, 10, 0.25, 71, 7, 14, 34, 47, 24, 33, 97, 9, 11, 49, 51, 10, 2.5);
INSERT INTO public.match_details VALUES (1305, 1305, 38, 55, 2, 9, 0.67, 61, 7, 23, 21, 34, 13, 21, 71, 6, 7, 28, 39, 8, 2.67, 57, 73, 7, 12, 2.33, 46, 2, 14, 24, 52, 17, 36, 76, 2, 8, 43, 57, 7, 2.33);
INSERT INTO public.match_details VALUES (1306, 1306, 35, 55, 1, 11, 0.33, 58, 7, 16, 26, 44, 17, 29, 83, 5, 8, 29, 35, 5, 1.67, 56, 74, 7, 16, 2.33, 44, 1, 14, 22, 50, 10, 22, 80, 1, 5, 41, 51, 8, 2.67);
INSERT INTO public.match_details VALUES (1307, 1307, 49, 76, 3, 10, 0.75, 76, 2, 27, 33, 43, 15, 19, 86, 10, 3, 39, 45, 7, 1.75, 73, 95, 2, 19, 0.5, 66, 3, 17, 27, 40, 16, 24, 114, 5, 7, 68, 60, 3, 0.75);
INSERT INTO public.match_details VALUES (1308, 1308, 79, 102, 5, 17, 1, 93, 8, 31, 30, 32, 15, 16, 126, 8, 9, 64, 51, 10, 2, 81, 109, 8, 16, 1.6, 85, 5, 27, 45, 52, 21, 24, 118, 5, 10, 64, 54, 9, 1.8);
INSERT INTO public.match_details VALUES (1309, 1309, 73, 103, 6, 22, 1.2, 86, 6, 19, 50, 58, 20, 23, 111, 9, 7, 54, 49, 13, 2.6, 73, 107, 6, 21, 1.2, 81, 6, 16, 48, 59, 22, 27, 119, 6, 13, 60, 50, 7, 1.4);
INSERT INTO public.match_details VALUES (1310, 1310, 62, 97, 5, 18, 1, 95, 5, 23, 38, 40, 25, 26, 130, 10, 8, 49, 38, 8, 1.6, 81, 115, 5, 20, 1, 79, 5, 8, 39, 49, 25, 31, 123, 10, 8, 68, 55, 8, 1.6);
INSERT INTO public.match_details VALUES (1311, 1311, 52, 75, 8, 13, 2.67, 49, 3, 9, 21, 42, 9, 18, 76, 2, 10, 41, 54, 3, 1, 46, 63, 3, 14, 1, 62, 8, 17, 21, 33, 6, 9, 75, 10, 3, 33, 44, 10, 3.33);
INSERT INTO public.match_details VALUES (1312, 1312, 64, 103, 7, 18, 1.4, 77, 7, 20, 39, 50, 22, 28, 95, 11, 7, 51, 54, 6, 1.2, 76, 107, 7, 30, 1.4, 85, 7, 26, 41, 48, 27, 31, 102, 7, 6, 62, 61, 7, 1.4);
INSERT INTO public.match_details VALUES (1313, 1313, 77, 110, 6, 26, 1.2, 98, 8, 22, 42, 42, 23, 23, 123, 8, 16, 59, 48, 12, 2.4, 82, 116, 8, 18, 1.6, 84, 6, 25, 34, 40, 17, 20, 125, 13, 12, 58, 46, 16, 3.2);
INSERT INTO public.match_details VALUES (1314, 1314, 71, 92, 6, 13, 1.5, 77, 4, 11, 48, 62, 27, 35, 100, 7, 6, 60, 60, 5, 1.25, 68, 90, 4, 13, 1, 79, 6, 19, 45, 56, 27, 34, 103, 7, 5, 58, 56, 6, 1.5);
INSERT INTO public.match_details VALUES (1315, 1315, 54, 71, 7, 12, 2.33, 69, 4, 17, 33, 47, 19, 27, 98, 8, 10, 42, 43, 5, 1.67, 58, 78, 4, 9, 1.33, 59, 7, 15, 26, 44, 17, 28, 87, 4, 5, 44, 51, 10, 3.33);
INSERT INTO public.match_details VALUES (1316, 1316, 60, 73, 6, 15, 2, 50, 3, 13, 21, 42, 15, 30, 73, 5, 7, 42, 58, 12, 4, 35, 58, 3, 8, 1, 58, 6, 19, 26, 44, 9, 15, 63, 5, 12, 25, 40, 7, 2.33);
INSERT INTO public.match_details VALUES (1317, 1317, 74, 114, 7, 19, 1.4, 88, 5, 26, 45, 51, 28, 31, 125, 10, 8, 58, 46, 9, 1.8, 77, 108, 5, 20, 1, 95, 7, 22, 48, 50, 31, 32, 124, 18, 9, 64, 52, 8, 1.6);
INSERT INTO public.match_details VALUES (1318, 1318, 66, 94, 14, 13, 3.5, 58, 7, 11, 35, 60, 12, 20, 84, 10, 7, 48, 57, 4, 1, 47, 72, 5, 14, 1.25, 81, 19, 30, 26, 32, 9, 11, 83, 12, 4, 35, 42, 7, 1.75);
INSERT INTO public.match_details VALUES (1319, 1319, 75, 104, 2, 22, 0.5, 83, 2, 23, 46, 55, 18, 21, 136, 5, 8, 63, 46, 10, 2.5, 65, 97, 2, 14, 0.5, 82, 2, 24, 39, 47, 16, 19, 127, 8, 10, 55, 43, 8, 2);
INSERT INTO public.match_details VALUES (1320, 1320, 54, 72, 5, 14, 1.67, 42, 2, 17, 16, 38, 6, 14, 81, 3, 0, 42, 52, 7, 2.33, 32, 52, 2, 10, 0.67, 58, 5, 17, 24, 41, 15, 25, 81, 9, 7, 30, 37, 0, 0);
INSERT INTO public.match_details VALUES (1321, 1321, 35, 53, 3, 14, 1, 61, 4, 14, 28, 45, 12, 19, 75, 8, 9, 31, 41, 1, 0.33, 49, 73, 4, 12, 1.33, 39, 3, 10, 20, 51, 5, 12, 60, 4, 1, 36, 60, 9, 3);
INSERT INTO public.match_details VALUES (1322, 1322, 78, 108, 7, 26, 1.4, 90, 6, 27, 38, 42, 24, 26, 119, 7, 7, 57, 48, 14, 2.8, 75, 110, 6, 20, 1.2, 82, 7, 23, 45, 54, 25, 30, 126, 6, 14, 62, 49, 7, 1.4);
INSERT INTO public.match_details VALUES (1323, 1323, 36, 59, 2, 7, 0.67, 56, 6, 15, 19, 33, 11, 19, 73, 8, 13, 29, 40, 5, 1.67, 58, 74, 6, 18, 2, 52, 2, 9, 38, 73, 20, 38, 68, 2, 5, 39, 57, 13, 4.33);
INSERT INTO public.match_details VALUES (1324, 1324, 38, 58, 1, 7, 0.33, 62, 7, 18, 26, 41, 16, 25, 78, 7, 7, 28, 36, 9, 3, 56, 74, 7, 12, 2.33, 51, 1, 16, 26, 50, 12, 23, 89, 5, 9, 42, 47, 7, 2.33);
INSERT INTO public.match_details VALUES (1325, 1325, 69, 91, 3, 9, 0.75, 75, 3, 22, 40, 53, 17, 22, 105, 8, 5, 53, 50, 13, 3.25, 66, 87, 3, 12, 0.75, 82, 3, 17, 37, 45, 19, 23, 111, 9, 13, 58, 52, 5, 1.25);
INSERT INTO public.match_details VALUES (1326, 1326, 77, 97, 12, 15, 3, 65, 6, 14, 31, 47, 18, 27, 102, 4, 12, 50, 49, 15, 3.75, 55, 77, 6, 12, 1.5, 82, 12, 13, 41, 50, 24, 29, 107, 7, 16, 37, 35, 12, 3);
INSERT INTO public.match_details VALUES (1327, 1327, 74, 102, 8, 21, 1.6, 89, 7, 21, 30, 33, 18, 20, 105, 2, 10, 54, 51, 12, 2.4, 82, 108, 7, 19, 1.4, 81, 8, 12, 38, 46, 29, 35, 110, 8, 12, 65, 59, 10, 2);
INSERT INTO public.match_details VALUES (1328, 1328, 51, 77, 1, 10, 0.33, 53, 5, 23, 15, 28, 12, 22, 87, 7, 6, 43, 49, 7, 2.33, 43, 66, 5, 13, 1.67, 67, 1, 15, 35, 52, 19, 28, 97, 10, 7, 32, 33, 6, 2);
INSERT INTO public.match_details VALUES (1329, 1329, 60, 73, 9, 11, 3, 51, 2, 11, 25, 49, 8, 15, 74, 6, 7, 48, 65, 3, 1, 37, 59, 2, 8, 0.67, 62, 9, 18, 20, 32, 12, 19, 74, 4, 3, 28, 38, 7, 2.33);
INSERT INTO public.match_details VALUES (1330, 1330, 54, 79, 4, 17, 1, 83, 5, 22, 35, 42, 15, 18, 104, 16, 13, 43, 41, 7, 1.75, 66, 97, 5, 14, 1.25, 62, 4, 16, 26, 41, 13, 20, 93, 9, 7, 47, 51, 14, 3.5);
INSERT INTO public.match_details VALUES (1331, 1331, 59, 74, 5, 12, 1.67, 42, 1, 11, 24, 57, 14, 33, 75, 4, 3, 47, 63, 7, 2.33, 33, 52, 1, 10, 0.33, 62, 5, 19, 32, 51, 17, 27, 79, 6, 7, 29, 37, 3, 1);
INSERT INTO public.match_details VALUES (1332, 1332, 79, 112, 7, 16, 1.4, 80, 4, 25, 35, 43, 22, 27, 114, 4, 12, 59, 52, 13, 2.6, 82, 104, 4, 24, 0.8, 96, 7, 17, 53, 55, 30, 31, 126, 6, 13, 66, 52, 12, 2.4);
INSERT INTO public.match_details VALUES (1333, 1333, 58, 73, 11, 14, 3.67, 42, 1, 6, 27, 64, 18, 42, 63, 3, 1, 44, 70, 3, 1, 33, 52, 1, 10, 0.33, 59, 11, 22, 22, 37, 8, 13, 62, 7, 3, 31, 50, 1, 0.33);
INSERT INTO public.match_details VALUES (1334, 1334, 72, 104, 13, 17, 2.6, 88, 7, 19, 38, 43, 17, 19, 124, 12, 15, 49, 40, 10, 2, 75, 106, 7, 17, 1.4, 87, 13, 15, 38, 43, 21, 24, 115, 14, 10, 53, 46, 15, 3);
INSERT INTO public.match_details VALUES (1335, 1335, 51, 73, 6, 10, 2, 45, 8, 10, 22, 48, 13, 28, 57, 4, 2, 38, 67, 7, 2.33, 48, 64, 5, 19, 1.67, 63, 8, 19, 28, 44, 14, 22, 79, 5, 7, 41, 52, 2, 0.67);


--
-- Data for Name: matches; Type: TABLE DATA; Schema: public; Owner: user
--

INSERT INTO public.matches VALUES (205, '2022-04-13 20:30:00', 2, 15, 9, 3, 0, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (206, '2022-04-18 14:45:00', 2, 9, 15, 1, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (207, '2022-04-13 17:30:00', 2, 2, 7, 2, 3, 1, 2, 1, 'play-off');
INSERT INTO public.matches VALUES (208, '2022-04-16 14:45:00', 2, 7, 2, 0, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (209, '2022-04-20 17:30:00', 2, 2, 7, 3, 0, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (210, '2022-04-12 17:30:00', 2, 13, 1, 1, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (211, '2022-04-15 17:30:00', 2, 1, 13, 0, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (212, '2022-04-19 17:30:00', 2, 13, 1, 3, 2, 2, 1, 0, 'play-off');
INSERT INTO public.matches VALUES (213, '2022-04-12 20:30:00', 2, 4, 8, 3, 1, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (214, '2022-04-15 20:30:00', 2, 8, 4, 1, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (215, '2022-04-23 14:45:00', 2, 15, 4, 1, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (216, '2022-04-26 17:30:00', 2, 4, 15, 0, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (217, '2022-04-30 14:45:00', 2, 15, 4, 3, 1, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (218, '2022-04-23 17:30:00', 2, 2, 13, 3, 0, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (219, '2022-04-26 20:30:00', 2, 13, 2, 0, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (220, '2022-05-04 17:30:00', 2, 15, 2, 3, 0, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (221, '2022-05-07 14:45:00', 2, 2, 15, 2, 3, 1, 2, 1, 'play-off');
INSERT INTO public.matches VALUES (222, '2022-05-11 17:30:00', 2, 15, 2, 1, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (223, '2022-05-14 14:45:00', 2, 2, 15, 0, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (224, '2022-05-04 20:30:00', 2, 13, 4, 2, 3, 1, 2, 1, 'play-off');
INSERT INTO public.matches VALUES (225, '2022-05-07 17:30:00', 2, 4, 13, 2, 3, 1, 2, 1, 'play-off');
INSERT INTO public.matches VALUES (226, '2022-05-10 17:30:00', 2, 13, 4, 0, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (227, '2022-05-13 20:30:00', 2, 4, 13, 3, 2, 2, 1, 0, 'play-off');
INSERT INTO public.matches VALUES (228, '2022-04-24 14:45:00', 2, 1, 8, 1, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (229, '2022-04-27 17:30:00', 2, 8, 1, 1, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (230, '2022-04-23 20:30:00', 2, 9, 7, 2, 3, 1, 2, 1, 'play-off');
INSERT INTO public.matches VALUES (231, '2022-04-27 20:30:00', 2, 7, 9, 3, 0, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (232, '2022-04-14 17:30:00', 2, 12, 16, 0, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (233, '2022-04-22 20:30:00', 2, 16, 12, 3, 2, 2, 1, 0, 'play-off');
INSERT INTO public.matches VALUES (234, '2022-04-14 20:30:00', 2, 11, 3, 2, 3, 1, 2, 1, 'play-off');
INSERT INTO public.matches VALUES (235, '2022-04-20 20:30:00', 2, 3, 11, 3, 2, 2, 1, 0, 'play-off');
INSERT INTO public.matches VALUES (420, '2021-03-21 14:45:00', 3, 15, 11, 3, 1, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (421, '2021-03-28 14:45:00', 3, 11, 15, 1, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (422, '2021-03-21 20:30:00', 3, 2, 4, 3, 0, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (423, '2021-03-27 14:45:00', 3, 4, 2, 1, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (424, '2021-03-20 14:45:00', 3, 7, 16, 3, 1, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (425, '2021-03-27 17:30:00', 3, 16, 7, 3, 2, 2, 1, 0, 'play-off');
INSERT INTO public.matches VALUES (426, '2021-03-31 18:00:00', 3, 7, 16, 0, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (427, '2021-03-20 20:30:00', 3, 13, 8, 3, 1, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (428, '2021-03-27 20:30:00', 3, 8, 13, 0, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (429, '2021-04-03 14:45:00', 3, 15, 13, 3, 0, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (430, '2021-04-07 20:30:00', 3, 13, 15, 3, 1, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (431, '2021-04-11 14:45:00', 3, 15, 13, 3, 0, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (432, '2021-04-03 17:30:00', 3, 2, 16, 3, 2, 2, 1, 0, 'play-off');
INSERT INTO public.matches VALUES (433, '2021-04-07 17:30:00', 3, 16, 2, 1, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (434, '2021-04-14 20:30:00', 3, 15, 2, 1, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (435, '2021-04-18 17:30:00', 3, 2, 15, 3, 1, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (436, '2021-04-14 17:30:00', 3, 13, 16, 2, 3, 1, 2, 1, 'play-off');
INSERT INTO public.matches VALUES (437, '2021-04-18 14:45:00', 3, 16, 13, 1, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (438, '2021-04-21 17:30:00', 3, 13, 16, 0, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (439, '2021-04-03 20:30:00', 3, 8, 7, 3, 1, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (440, '2021-04-08 17:30:00', 3, 7, 8, 0, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (441, '2021-04-02 20:30:00', 3, 11, 4, 3, 1, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (442, '2021-04-08 20:30:00', 3, 4, 11, 3, 1, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (443, '2021-03-22 20:30:00', 3, 9, 1, 3, 1, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (444, '2021-03-26 17:30:00', 3, 1, 9, 2, 3, 1, 2, 1, 'play-off');
INSERT INTO public.matches VALUES (445, '2021-03-19 20:30:00', 3, 14, 12, 3, 0, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (446, '2021-03-28 20:30:00', 3, 12, 14, 3, 0, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (629, '2019-03-27 17:30:00', 4, 2, 13, 3, 2, 2, 1, 0, 'play-off');
INSERT INTO public.matches VALUES (630, '2019-03-30 14:45:00', 4, 13, 2, 0, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (631, '2019-03-27 20:30:00', 4, 4, 14, 3, 2, 2, 1, 0, 'play-off');
INSERT INTO public.matches VALUES (632, '2019-03-31 14:45:00', 4, 14, 4, 3, 1, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (633, '2019-04-07 17:30:00', 4, 4, 14, 3, 0, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (634, '2019-04-13 14:45:00', 4, 15, 4, 1, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (635, '2019-04-17 17:30:00', 4, 4, 15, 2, 3, 1, 2, 1, 'play-off');
INSERT INTO public.matches VALUES (636, '2019-04-24 17:30:00', 4, 15, 4, 3, 1, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (637, '2019-04-16 20:30:00', 4, 16, 2, 1, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (638, '2019-04-19 17:30:00', 4, 2, 16, 0, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (639, '2019-04-24 20:30:00', 4, 16, 2, 3, 2, 2, 1, 0, 'play-off');
INSERT INTO public.matches VALUES (640, '2019-04-27 14:45:00', 4, 15, 16, 3, 2, 2, 1, 0, 'play-off');
INSERT INTO public.matches VALUES (641, '2019-05-01 20:30:00', 4, 16, 15, 0, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (642, '2019-05-04 17:30:00', 4, 15, 16, 3, 1, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (643, '2019-04-27 17:30:00', 4, 2, 4, 3, 2, 2, 1, 0, 'play-off');
INSERT INTO public.matches VALUES (644, '2019-05-01 17:30:00', 4, 4, 2, 2, 3, 1, 2, 1, 'play-off');
INSERT INTO public.matches VALUES (645, '2019-05-04 14:45:00', 4, 2, 4, 3, 0, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (646, '2019-04-13 20:30:00', 4, 14, 13, 3, 2, 2, 1, 0, 'play-off');
INSERT INTO public.matches VALUES (647, '2019-04-16 17:30:00', 4, 13, 14, 3, 2, 2, 1, 0, 'play-off');
INSERT INTO public.matches VALUES (648, '2019-04-25 17:30:00', 4, 14, 13, 3, 0, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (649, '2019-04-01 20:30:00', 4, 8, 9, 3, 0, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (650, '2019-04-06 20:30:00', 4, 9, 8, 0, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (651, '2019-03-30 17:30:00', 4, 1, 7, 0, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (652, '2019-04-05 17:30:00', 4, 7, 1, 3, 0, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (653, '2019-03-31 17:30:00', 4, 18, 12, 2, 3, 1, 2, 1, 'play-off');
INSERT INTO public.matches VALUES (654, '2019-04-05 18:00:00', 4, 12, 18, 3, 1, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (811, '2018-04-18 20:30:00', 5, 2, 7, 1, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (812, '2018-04-21 20:00:00', 5, 7, 2, 1, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (813, '2018-04-22 20:00:00', 5, 7, 2, 3, 2, 2, 1, 0, 'play-off');
INSERT INTO public.matches VALUES (814, '2018-04-18 17:00:00', 5, 1, 8, 2, 3, 1, 2, 1, 'play-off');
INSERT INTO public.matches VALUES (815, '2018-04-21 14:45:00', 5, 8, 1, 1, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (816, '2018-04-22 14:45:00', 5, 8, 1, 1, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (817, '2018-04-25 20:30:00', 5, 1, 15, 2, 3, 1, 2, 1, 'play-off');
INSERT INTO public.matches VALUES (818, '2018-04-28 20:30:00', 5, 15, 1, 3, 2, 2, 1, 0, 'play-off');
INSERT INTO public.matches VALUES (819, '2018-04-25 17:30:00', 5, 7, 13, 2, 3, 1, 2, 1, 'play-off');
INSERT INTO public.matches VALUES (820, '2018-04-28 17:30:00', 5, 13, 7, 3, 2, 2, 1, 0, 'play-off');
INSERT INTO public.matches VALUES (821, '2018-05-02 20:30:00', 5, 13, 15, 3, 0, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (822, '2018-05-05 20:30:00', 5, 15, 13, 1, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (823, '2018-05-02 17:30:00', 5, 1, 7, 2, 3, 1, 2, 1, 'play-off');
INSERT INTO public.matches VALUES (824, '2018-05-05 17:30:00', 5, 7, 1, 3, 1, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (825, '2018-04-25 18:00:00', 5, 2, 8, 3, 2, 2, 1, 0, 'play-off');
INSERT INTO public.matches VALUES (826, '2018-04-28 17:00:00', 5, 8, 2, 3, 1, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (827, '2018-04-29 14:45:00', 5, 8, 2, 1, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (828, '2018-04-18 18:00:00', 5, 12, 16, 1, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (829, '2018-04-23 20:00:00', 5, 16, 12, 1, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (830, '2018-04-18 18:00:00', 5, 4, 14, 3, 1, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (831, '2018-04-20 18:30:00', 5, 14, 4, 3, 0, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (832, '2018-04-18 18:00:00', 5, 19, 9, 2, 3, 1, 2, 1, 'play-off');
INSERT INTO public.matches VALUES (833, '2018-04-21 17:00:00', 5, 9, 19, 3, 0, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (834, '2018-04-19 18:00:00', 5, 18, 17, 2, 3, 1, 2, 1, 'play-off');
INSERT INTO public.matches VALUES (835, '2018-04-22 17:00:00', 5, 17, 18, 3, 0, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (1076, '2017-04-07 17:30:00', 6, 2, 15, 0, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (1077, '2017-04-09 17:30:00', 6, 13, 8, 3, 0, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (1078, '2017-04-12 18:00:00', 6, 15, 2, 3, 0, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (1079, '2017-04-12 20:30:00', 6, 8, 13, 2, 3, 1, 2, 1, 'play-off');
INSERT INTO public.matches VALUES (1080, '2017-04-19 18:00:00', 6, 13, 15, 0, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (1081, '2017-04-23 20:30:00', 6, 15, 13, 3, 1, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (1082, '2017-04-18 18:00:00', 6, 2, 8, 3, 1, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (1083, '2017-04-23 17:30:00', 6, 8, 2, 2, 3, 1, 2, 1, 'play-off');
INSERT INTO public.matches VALUES (1084, '2017-04-07 18:00:00', 6, 12, 1, 1, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (1085, '2017-04-12 18:00:00', 6, 1, 12, 3, 1, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (1086, '2017-04-08 17:00:00', 6, 14, 7, 2, 3, 1, 2, 1, 'play-off');
INSERT INTO public.matches VALUES (1087, '2017-04-13 18:00:00', 6, 7, 14, 1, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (1088, '2017-04-08 14:45:00', 6, 16, 9, 3, 1, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (1089, '2017-04-09 17:00:00', 6, 9, 16, 3, 1, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (1090, '2017-04-04 19:00:00', 6, 19, 17, 1, 3, 0, 3, 1, 'play-off');
INSERT INTO public.matches VALUES (1091, '2017-04-12 19:00:00', 6, 17, 19, 3, 0, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (1092, '2017-04-11 18:00:00', 6, 5, 20, 2, 3, 1, 2, 1, 'play-off');
INSERT INTO public.matches VALUES (1093, '2017-04-13 18:00:00', 6, 20, 5, 3, 0, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (1094, '2017-04-12 18:00:00', 6, 21, 18, 3, 2, 2, 1, 0, 'play-off');
INSERT INTO public.matches VALUES (1095, '2017-04-19 18:00:00', 6, 18, 21, 3, 1, 3, 0, 0, 'play-off');
INSERT INTO public.matches VALUES (303, '2021-12-04 14:45:00', 2, 1, 2, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (394, '2022-03-12 14:45:00', 2, 2, 1, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (504, '2021-01-20 17:30:00', 3, 1, 2, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (595, '2021-01-23 14:45:00', 3, 2, 1, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (702, '2018-11-18 14:45:00', 4, 1, 2, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (780, '2019-02-20 18:00:00', 4, 2, 1, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (885, '2017-10-29 14:45:00', 5, 1, 2, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1005, '2018-02-24 14:45:00', 5, 2, 1, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1102, '2016-10-01 18:00:00', 6, 2, 1, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (1222, '2016-12-22 20:30:00', 6, 1, 2, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (273, '2021-11-05 20:30:00', 2, 3, 1, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (364, '2022-02-07 17:30:00', 2, 1, 3, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (260, '2021-10-24 17:30:00', 2, 1, 4, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (351, '2022-01-23 14:45:00', 2, 4, 1, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (465, '2020-09-26 17:30:00', 3, 1, 4, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (556, '2020-12-05 14:45:00', 3, 4, 1, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (724, '2018-12-15 20:30:00', 4, 1, 4, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (802, '2019-03-17 14:45:00', 4, 4, 1, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (882, '2017-10-21 17:00:00', 5, 4, 1, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (1002, '2018-02-17 17:00:00', 5, 1, 4, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (855, '2017-10-07 17:00:00', 5, 1, 5, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (975, '2018-01-20 17:00:00', 5, 5, 1, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1137, '2016-10-29 17:00:00', 6, 5, 1, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1257, '2017-02-11 17:00:00', 6, 1, 5, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (299, '2021-11-28 17:30:00', 2, 1, 6, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (390, '2022-03-07 17:30:00', 2, 6, 1, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (517, '2021-01-14 17:30:00', 3, 1, 6, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (608, '2021-02-06 20:30:00', 3, 6, 1, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (324, '2022-03-16 17:30:00', 2, 1, 7, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (415, '2022-04-03 17:30:00', 2, 7, 1, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (607, '2021-01-31 17:30:00', 3, 1, 7, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (516, '2021-02-04 15:00:00', 3, 7, 1, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (690, '2018-10-31 18:00:00', 4, 7, 1, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (768, '2019-02-10 17:30:00', 4, 1, 7, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (900, '2017-11-10 18:00:00', 5, 1, 7, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1020, '2018-03-07 20:30:00', 5, 7, 1, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (1195, '2016-12-09 20:15:00', 6, 1, 7, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (1315, '2017-03-18 20:00:00', 6, 7, 1, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (242, '2021-10-02 14:45:00', 2, 1, 8, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (333, '2022-01-05 17:30:00', 2, 8, 1, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (533, '2020-11-13 20:30:00', 3, 8, 1, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (624, '2021-03-08 20:30:00', 3, 1, 8, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (704, '2018-11-23 20:30:00', 4, 8, 1, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (782, '2019-02-24 17:30:00', 4, 1, 8, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (899, '2017-11-04 14:45:00', 5, 8, 1, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1019, '2018-03-03 14:45:00', 5, 1, 8, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1171, '2016-11-26 20:00:00', 6, 8, 1, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1291, '2017-03-04 14:45:00', 6, 1, 8, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (272, '2021-10-31 20:30:00', 2, 9, 1, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (360, '2022-01-30 14:45:00', 2, 1, 9, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (530, '2021-02-10 18:00:00', 3, 1, 9, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (621, '2021-02-27 14:45:00', 3, 9, 1, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (657, '2018-10-14 17:30:00', 4, 9, 1, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (735, '2018-12-28 20:30:00', 4, 1, 9, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (945, '2017-12-22 18:00:00', 5, 1, 9, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (1065, '2018-04-07 17:30:00', 5, 9, 1, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1105, '2016-10-08 17:00:00', 6, 1, 9, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1225, '2017-01-08 14:45:00', 6, 9, 1, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (257, '2021-10-17 20:30:00', 2, 11, 1, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (348, '2022-01-15 14:45:00', 2, 1, 11, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (460, '2020-09-19 17:30:00', 3, 1, 11, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (545, '2020-12-01 17:30:00', 3, 11, 1, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (286, '2021-11-15 17:30:00', 2, 1, 12, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (377, '2022-02-12 18:00:00', 2, 12, 1, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (471, '2020-09-29 17:30:00', 3, 12, 1, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (562, '2020-11-08 14:45:00', 3, 1, 12, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (713, '2018-12-09 17:30:00', 4, 1, 12, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (791, '2019-03-03 17:30:00', 4, 12, 1, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (915, '2017-11-19 14:45:00', 5, 1, 12, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1035, '2018-03-11 20:00:00', 5, 12, 1, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1205, '2016-12-14 18:00:00', 6, 12, 1, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1325, '2017-03-25 14:45:00', 6, 1, 12, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (248, '2021-10-10 17:30:00', 2, 13, 1, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (339, '2022-01-08 14:45:00', 2, 1, 13, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (501, '2020-12-16 17:30:00', 3, 13, 1, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (592, '2021-02-13 14:45:00', 3, 1, 13, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (677, '2018-10-27 14:45:00', 4, 13, 1, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (755, '2019-02-02 14:45:00', 4, 1, 13, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (870, '2017-10-18 18:00:00', 5, 1, 13, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (990, '2018-02-09 18:00:00', 5, 13, 1, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (1188, '2016-12-03 14:45:00', 6, 13, 1, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1308, '2017-03-11 14:45:00', 6, 1, 13, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (289, '2021-11-20 20:30:00', 2, 14, 1, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (379, '2022-02-21 17:30:00', 2, 1, 14, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (452, '2020-09-12 14:45:00', 3, 14, 1, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (543, '2020-11-22 14:45:00', 3, 1, 14, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (664, '2018-10-17 18:00:00', 4, 1, 14, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (742, '2019-01-13 14:45:00', 4, 14, 1, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (917, '2017-11-25 14:45:00', 5, 14, 1, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1037, '2018-03-18 14:45:00', 5, 1, 14, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1210, '2016-12-18 15:00:00', 6, 1, 14, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1330, '2017-03-31 18:00:00', 6, 14, 1, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (312, '2021-12-10 20:30:00', 2, 15, 1, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (403, '2022-03-20 14:45:00', 2, 1, 15, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (486, '2020-10-10 17:30:00', 3, 15, 1, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (577, '2020-12-22 17:30:00', 3, 1, 15, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (680, '2018-11-02 20:30:00', 4, 1, 15, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (758, '2019-02-06 18:30:00', 4, 15, 1, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (865, '2017-11-14 18:30:00', 5, 15, 1, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (985, '2018-02-03 14:45:00', 5, 1, 15, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1165, '2016-11-18 20:15:00', 6, 1, 15, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1285, '2017-02-25 14:45:00', 6, 15, 1, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (318, '2021-12-19 14:45:00', 2, 16, 1, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (409, '2022-03-28 17:30:00', 2, 1, 16, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (491, '2020-10-15 17:30:00', 3, 1, 16, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (582, '2021-01-09 17:30:00', 3, 16, 1, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (717, '2018-12-12 20:30:00', 4, 16, 1, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (795, '2019-03-08 20:30:00', 4, 1, 16, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (934, '2017-12-12 19:00:00', 5, 16, 1, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1054, '2018-03-30 18:00:00', 5, 1, 16, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1120, '2016-10-22 15:00:00', 6, 16, 1, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1240, '2017-01-21 17:00:00', 6, 1, 16, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (478, '2020-11-18 18:00:00', 3, 1, 17, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (569, '2020-12-19 17:30:00', 3, 17, 1, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (669, '2018-10-20 17:30:00', 4, 1, 17, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (747, '2019-01-21 20:30:00', 4, 17, 1, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (951, '2017-12-30 18:00:00', 5, 17, 1, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1071, '2018-04-15 14:45:00', 5, 1, 17, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1154, '2016-11-12 20:00:00', 6, 17, 1, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1274, '2017-02-22 18:00:00', 6, 1, 17, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (691, '2018-11-10 20:00:00', 4, 1, 18, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (769, '2019-02-15 17:30:00', 4, 18, 1, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (930, '2017-12-04 18:00:00', 5, 1, 18, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (1050, '2018-03-24 14:45:00', 5, 18, 1, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1119, '2016-10-14 20:15:00', 6, 18, 1, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1239, '2017-01-27 18:00:00', 6, 1, 18, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (839, '2017-09-30 14:45:00', 5, 1, 19, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (960, '2018-01-07 20:00:00', 5, 19, 1, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1180, '2016-11-30 18:00:00', 6, 1, 19, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1300, '2017-03-08 18:00:00', 6, 19, 1, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (848, '2017-10-04 18:00:00', 5, 20, 1, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (968, '2018-01-14 15:00:00', 5, 1, 20, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1150, '2016-11-07 18:00:00', 6, 1, 20, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1270, '2017-02-18 18:00:00', 6, 20, 1, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1135, '2016-10-26 18:00:00', 6, 1, 21, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1255, '2017-02-04 17:00:00', 6, 21, 1, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (238, '2021-10-01 20:30:00', 2, 3, 2, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (329, '2022-01-03 20:30:00', 2, 2, 3, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (291, '2021-11-20 14:45:00', 2, 2, 4, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (381, '2022-02-19 17:30:00', 2, 4, 2, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (450, '2020-09-13 20:30:00', 3, 4, 2, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (541, '2021-02-24 15:00:00', 3, 2, 4, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (663, '2018-10-17 18:00:00', 4, 4, 2, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (741, '2019-01-14 17:30:00', 4, 2, 4, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (867, '2017-10-15 14:45:00', 5, 4, 2, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (987, '2018-02-03 15:00:00', 5, 2, 4, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (838, '2017-10-25 18:00:00', 5, 2, 5, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (958, '2018-01-06 17:00:00', 5, 5, 2, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1117, '2016-10-15 17:30:00', 6, 2, 5, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1237, '2017-01-30 18:00:00', 6, 5, 2, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (251, '2021-10-08 17:30:00', 2, 2, 6, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (342, '2022-01-08 20:30:00', 2, 6, 2, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (580, '2021-01-09 20:30:00', 3, 6, 2, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (489, '2021-02-02 15:00:00', 3, 2, 6, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (277, '2021-11-07 17:30:00', 2, 2, 7, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (368, '2022-04-09 14:45:00', 2, 7, 2, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (502, '2020-10-24 17:30:00', 3, 2, 7, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (593, '2020-11-01 14:45:00', 3, 7, 2, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (692, '2018-11-10 14:45:00', 4, 2, 7, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (770, '2019-02-17 14:45:00', 4, 7, 2, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (868, '2017-10-18 18:00:00', 5, 2, 7, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (988, '2018-02-07 20:30:00', 5, 7, 2, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (1174, '2016-11-26 14:45:00', 6, 2, 7, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (1294, '2017-03-05 15:00:00', 6, 7, 2, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (268, '2021-10-31 14:45:00', 2, 8, 2, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (359, '2022-01-16 14:45:00', 2, 2, 8, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (455, '2020-09-19 14:45:00', 3, 2, 8, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (547, '2020-12-30 20:30:00', 3, 8, 2, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (714, '2018-12-08 14:45:00', 4, 2, 8, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (792, '2019-03-02 20:30:00', 4, 8, 2, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (883, '2017-10-21 14:45:00', 5, 2, 8, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1003, '2018-02-18 14:45:00', 5, 8, 2, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1147, '2016-11-04 20:15:00', 6, 2, 8, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1267, '2017-02-18 20:00:00', 6, 8, 2, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (298, '2021-11-27 17:30:00', 2, 9, 2, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (389, '2022-03-05 20:30:00', 2, 2, 9, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (515, '2021-01-06 17:30:00', 3, 2, 9, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (606, '2021-01-30 17:30:00', 3, 9, 2, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (730, '2018-12-22 17:30:00', 4, 2, 9, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (808, '2019-03-19 17:30:00', 4, 9, 2, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (928, '2017-12-02 14:45:00', 5, 2, 9, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1048, '2018-03-25 14:45:00', 5, 9, 2, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1207, '2016-12-14 18:00:00', 6, 2, 9, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1327, '2017-03-28 18:00:00', 6, 9, 2, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (283, '2021-11-14 17:30:00', 2, 11, 2, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (374, '2022-02-13 14:45:00', 2, 2, 11, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (519, '2020-11-04 17:30:00', 3, 11, 2, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (610, '2021-02-05 20:30:00', 3, 2, 11, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (313, '2021-12-11 14:45:00', 2, 12, 2, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (404, '2022-03-20 20:30:00', 2, 2, 12, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (535, '2020-11-15 20:30:00', 3, 2, 12, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (626, '2021-03-05 20:30:00', 3, 12, 2, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (716, '2018-12-12 18:00:00', 4, 12, 2, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (794, '2019-03-07 17:30:00', 4, 2, 12, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (898, '2017-11-03 18:00:00', 5, 2, 12, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1018, '2018-03-04 14:45:00', 5, 12, 2, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1177, '2016-11-30 18:00:00', 6, 2, 12, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1297, '2017-03-08 18:00:00', 6, 12, 2, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (264, '2021-10-24 14:45:00', 2, 2, 13, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (355, '2022-01-22 14:45:00', 2, 13, 2, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (579, '2020-12-23 17:30:00', 3, 2, 13, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (488, '2021-01-16 14:45:00', 3, 13, 2, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (681, '2018-11-03 14:45:00', 4, 2, 13, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (759, '2019-02-06 20:30:00', 4, 13, 2, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (853, '2017-10-08 12:30:00', 5, 2, 13, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (973, '2018-01-21 14:45:00', 5, 13, 2, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1162, '2016-11-09 18:00:00', 6, 2, 13, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (1282, '2017-02-26 14:45:00', 6, 13, 2, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (316, '2021-12-18 20:30:00', 2, 2, 14, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (407, '2022-03-27 20:30:00', 2, 14, 2, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (528, '2020-11-07 17:30:00', 3, 2, 14, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (619, '2021-02-21 17:30:00', 3, 14, 2, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (658, '2018-10-12 18:00:00', 4, 14, 2, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (736, '2018-12-29 14:45:00', 4, 2, 14, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (902, '2017-11-29 18:00:00', 5, 14, 2, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1022, '2018-03-07 18:00:00', 5, 2, 14, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1191, '2016-12-02 20:15:00', 6, 14, 2, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1311, '2017-03-13 18:00:00', 6, 2, 14, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (328, '2021-11-10 17:30:00', 2, 15, 2, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (419, '2022-04-03 14:45:00', 2, 2, 15, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (473, '2020-09-30 17:30:00', 3, 15, 2, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (564, '2020-12-13 17:30:00', 3, 2, 15, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (689, '2018-11-07 20:30:00', 4, 15, 2, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (767, '2019-02-09 14:45:00', 4, 2, 15, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (850, '2017-10-11 20:30:00', 5, 15, 2, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (970, '2018-01-13 14:45:00', 5, 2, 15, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1140, '2016-10-29 20:00:00', 6, 15, 2, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (1260, '2017-02-10 18:00:00', 6, 2, 15, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (253, '2021-10-15 20:30:00', 2, 16, 2, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (344, '2022-03-23 17:30:00', 2, 2, 16, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (567, '2020-12-20 14:45:00', 3, 16, 2, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (476, '2021-01-12 20:30:00', 3, 2, 16, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (725, '2018-12-16 17:30:00', 4, 2, 16, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (803, '2019-03-17 20:30:00', 4, 16, 2, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (919, '2017-11-26 14:45:00', 5, 16, 2, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1039, '2018-03-17 14:45:00', 5, 2, 16, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1192, '2016-12-10 14:45:00', 6, 2, 16, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (1312, '2017-03-18 14:45:00', 6, 16, 2, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (463, '2020-09-27 14:45:00', 3, 17, 2, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (554, '2020-12-16 18:00:00', 3, 2, 17, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (676, '2018-10-29 18:00:00', 4, 17, 2, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (754, '2019-02-03 17:30:00', 4, 2, 17, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (936, '2017-12-10 20:00:00', 5, 17, 2, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (1056, '2018-03-30 17:00:00', 5, 2, 17, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1132, '2016-10-26 18:00:00', 6, 2, 17, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1252, '2017-02-03 19:00:00', 6, 17, 2, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (703, '2018-11-26 18:00:00', 4, 2, 18, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (781, '2019-02-25 17:30:00', 4, 18, 2, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (913, '2017-11-18 15:00:00', 5, 2, 18, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1033, '2018-03-10 15:00:00', 5, 18, 2, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1209, '2016-12-16 20:15:00', 6, 18, 2, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1329, '2017-04-01 14:45:00', 6, 2, 18, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (943, '2017-12-23 15:00:00', 5, 2, 19, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1063, '2018-04-06 19:00:00', 5, 19, 2, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (1157, '2016-11-14 19:00:00', 6, 19, 2, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1277, '2017-02-22 18:00:00', 6, 2, 19, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (953, '2017-12-30 17:00:00', 5, 20, 2, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1073, '2018-04-15 14:45:00', 5, 2, 20, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1123, '2016-10-21 18:00:00', 6, 20, 2, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1243, '2017-01-21 14:45:00', 6, 2, 20, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1106, '2016-10-07 17:30:00', 6, 21, 2, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1226, '2017-01-07 15:00:00', 6, 2, 21, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (322, '2021-12-29 17:30:00', 2, 3, 4, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (413, '2022-04-02 17:30:00', 2, 4, 3, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (315, '2021-12-20 20:30:00', 2, 3, 6, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (406, '2022-03-28 20:30:00', 2, 6, 3, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (308, '2021-12-12 20:30:00', 2, 7, 3, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (399, '2022-03-19 17:30:00', 2, 3, 7, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (294, '2021-11-27 20:30:00', 2, 8, 3, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (385, '2022-03-04 20:30:00', 2, 3, 8, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (259, '2021-10-22 20:30:00', 2, 3, 9, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (350, '2022-01-24 17:30:00', 2, 9, 3, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (245, '2021-10-09 20:30:00', 2, 11, 3, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (336, '2022-01-10 20:30:00', 2, 3, 11, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (288, '2021-11-21 17:30:00', 2, 3, 12, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (378, '2022-02-18 20:30:00', 2, 12, 3, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (280, '2021-11-13 17:30:00', 2, 13, 3, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (371, '2022-02-11 20:30:00', 2, 3, 13, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (301, '2021-12-05 17:30:00', 2, 3, 14, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (392, '2022-03-13 17:30:00', 2, 14, 3, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (252, '2021-10-16 17:30:00', 2, 15, 3, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (343, '2022-01-15 20:30:00', 2, 3, 15, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (266, '2021-10-29 20:30:00', 2, 16, 3, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (357, '2022-01-29 14:45:00', 2, 3, 16, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (954, '2017-12-18 18:00:00', 5, 5, 4, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1074, '2018-04-15 14:45:00', 5, 4, 5, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (284, '2021-11-13 20:30:00', 2, 4, 6, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (375, '2022-02-12 20:30:00', 2, 6, 4, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (496, '2020-11-17 20:30:00', 3, 4, 6, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (587, '2021-02-27 20:30:00', 3, 6, 4, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (246, '2021-10-10 14:45:00', 2, 7, 4, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (337, '2022-01-09 20:30:00', 2, 4, 7, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (534, '2020-11-15 17:30:00', 3, 4, 7, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (625, '2021-03-07 17:30:00', 3, 7, 4, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (718, '2018-12-12 18:00:00', 4, 4, 7, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (796, '2019-03-08 17:30:00', 4, 7, 4, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (852, '2017-10-08 17:00:00', 5, 4, 7, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (972, '2018-01-22 18:00:00', 5, 7, 4, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (320, '2021-12-18 14:45:00', 2, 8, 4, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (411, '2022-03-27 18:00:00', 2, 4, 8, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (495, '2020-12-02 17:30:00', 3, 8, 4, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (586, '2021-02-09 20:30:00', 3, 4, 8, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (659, '2018-10-13 14:45:00', 4, 4, 8, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (737, '2019-02-01 20:30:00', 4, 8, 4, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (869, '2017-11-22 20:30:00', 5, 8, 4, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (989, '2018-02-10 14:45:00', 5, 4, 8, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (258, '2021-10-16 14:45:00', 2, 4, 9, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (349, '2022-01-16 17:30:00', 2, 9, 4, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (470, '2020-09-29 20:30:00', 3, 4, 9, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (561, '2020-12-12 14:45:00', 3, 9, 4, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (686, '2018-11-07 18:00:00', 4, 4, 9, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (764, '2019-01-16 20:30:00', 4, 9, 4, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (920, '2017-11-25 18:30:00', 5, 9, 4, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1040, '2018-03-19 18:00:00', 5, 4, 9, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (244, '2021-10-03 14:45:00', 2, 4, 11, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (335, '2022-01-06 17:30:00', 2, 11, 4, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (571, '2020-12-18 20:30:00', 3, 11, 4, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (480, '2021-01-27 15:00:00', 3, 4, 11, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (271, '2021-10-28 17:30:00', 2, 4, 12, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (363, '2022-01-27 17:30:00', 2, 12, 4, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (509, '2020-12-15 17:30:00', 3, 4, 12, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (600, '2021-01-24 17:30:00', 3, 12, 4, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (728, '2018-12-21 17:30:00', 4, 4, 12, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (806, '2019-03-23 14:45:00', 4, 12, 4, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (886, '2017-10-28 17:00:00', 5, 12, 4, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (1006, '2018-02-24 17:00:00', 5, 4, 12, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (310, '2021-12-13 17:30:00', 2, 4, 13, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (401, '2022-03-19 14:45:00', 2, 13, 4, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (456, '2020-09-20 14:45:00', 3, 13, 4, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (548, '2020-11-29 14:45:00', 3, 4, 13, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (707, '2018-11-24 17:30:00', 4, 4, 13, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (785, '2019-02-24 14:45:00', 4, 13, 4, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (851, '2017-11-15 20:30:00', 5, 13, 4, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (971, '2018-01-14 14:45:00', 5, 4, 13, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (275, '2021-11-06 20:30:00', 2, 14, 4, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (366, '2022-02-06 17:30:00', 2, 4, 14, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (483, '2020-10-10 14:45:00', 3, 4, 14, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (574, '2020-12-23 20:30:00', 3, 14, 4, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (684, '2018-11-04 14:45:00', 4, 4, 14, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (762, '2019-02-07 20:30:00', 4, 14, 4, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (897, '2017-11-06 18:00:00', 5, 4, 14, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1017, '2018-03-02 18:00:00', 5, 14, 4, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (297, '2021-11-27 14:45:00', 2, 4, 15, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (388, '2022-03-05 14:45:00', 2, 15, 4, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (522, '2021-01-19 20:30:00', 3, 4, 15, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (613, '2021-02-06 17:30:00', 3, 15, 4, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (711, '2018-12-08 17:30:00', 4, 15, 4, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (789, '2019-03-03 14:45:00', 4, 4, 15, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (837, '2017-10-01 20:00:00', 5, 4, 15, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (957, '2018-01-06 17:00:00', 5, 15, 4, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (305, '2021-12-06 20:30:00', 2, 16, 4, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (396, '2022-03-13 14:45:00', 2, 4, 16, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (526, '2020-11-08 20:30:00', 3, 16, 4, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (617, '2021-02-21 20:30:00', 3, 4, 16, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (672, '2018-10-21 20:00:00', 4, 16, 4, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (750, '2019-01-19 14:45:00', 4, 4, 16, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (912, '2017-11-18 17:00:00', 5, 4, 16, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1032, '2018-03-12 18:00:00', 5, 16, 4, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (511, '2020-12-07 20:30:00', 3, 17, 4, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (602, '2021-01-29 20:30:00', 3, 4, 17, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (698, '2018-11-19 18:00:00', 4, 17, 4, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (776, '2019-02-20 18:00:00', 4, 4, 17, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (927, '2017-12-02 17:00:00', 5, 4, 17, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1047, '2018-03-25 18:00:00', 5, 17, 4, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (673, '2018-10-27 17:30:00', 4, 18, 4, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (751, '2019-01-30 20:30:00', 4, 4, 18, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (903, '2017-11-12 14:45:00', 5, 18, 4, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1023, '2018-03-07 18:00:00', 5, 4, 18, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (937, '2017-12-10 17:00:00', 5, 19, 4, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (1057, '2018-03-30 18:00:00', 5, 4, 19, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (942, '2017-12-23 17:00:00', 5, 4, 20, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1062, '2018-04-09 18:00:00', 5, 20, 4, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (924, '2017-12-02 14:45:00', 5, 7, 5, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1044, '2018-04-04 18:00:00', 5, 5, 7, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1212, '2016-12-17 17:00:00', 6, 7, 5, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1332, '2017-04-01 15:00:00', 6, 5, 7, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (849, '2017-10-04 18:30:00', 5, 5, 8, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (969, '2018-01-13 17:00:00', 5, 8, 5, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1186, '2016-12-03 17:00:00', 6, 8, 5, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (1306, '2017-03-11 15:00:00', 6, 5, 8, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (894, '2017-11-04 17:00:00', 5, 5, 9, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1014, '2018-03-03 17:00:00', 5, 9, 5, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (1122, '2016-10-22 14:00:00', 6, 5, 9, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1242, '2017-01-23 18:00:00', 6, 9, 5, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (864, '2017-10-11 18:00:00', 5, 5, 12, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (984, '2018-02-03 17:00:00', 5, 12, 5, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1100, '2016-10-19 18:00:00', 6, 5, 12, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1220, '2016-12-30 18:00:00', 6, 12, 5, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (941, '2017-12-22 18:00:00', 5, 13, 5, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1061, '2018-04-07 17:00:00', 5, 5, 13, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1203, '2016-12-14 18:00:00', 6, 13, 5, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1323, '2017-03-25 15:00:00', 6, 5, 13, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (873, '2017-10-18 18:00:00', 5, 14, 5, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (992, '2018-02-10 17:00:00', 5, 5, 14, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1107, '2016-10-10 17:30:00', 6, 14, 5, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1227, '2017-01-07 15:00:00', 6, 5, 14, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (939, '2017-11-08 18:30:00', 5, 15, 5, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1059, '2018-03-31 14:45:00', 5, 5, 15, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1182, '2016-11-30 18:00:00', 6, 5, 15, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1302, '2017-03-08 18:00:00', 6, 15, 5, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (889, '2017-10-28 17:00:00', 5, 16, 5, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1009, '2018-02-24 17:00:00', 5, 5, 16, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1152, '2016-12-21 19:30:00', 6, 16, 5, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1272, '2017-02-22 18:00:00', 6, 5, 16, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (906, '2017-11-11 14:45:00', 5, 17, 5, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1026, '2018-03-07 18:00:00', 5, 5, 17, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1170, '2016-11-26 18:00:00', 6, 17, 5, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1290, '2017-03-04 17:00:00', 6, 5, 17, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (879, '2017-11-21 18:30:00', 5, 5, 18, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (999, '2018-02-16 18:00:00', 5, 18, 5, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (1134, '2016-10-26 18:00:00', 6, 18, 5, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1254, '2017-02-03 18:00:00', 6, 5, 18, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (910, '2017-11-17 18:00:00', 5, 5, 19, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (1030, '2018-03-11 17:00:00', 5, 19, 5, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1197, '2016-12-10 17:00:00', 6, 5, 19, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1317, '2017-03-17 18:00:00', 6, 19, 5, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (923, '2017-11-24 18:00:00', 5, 20, 5, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1043, '2018-03-17 17:00:00', 5, 5, 20, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1167, '2016-11-17 18:00:00', 6, 5, 20, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1287, '2017-02-25 17:00:00', 6, 20, 5, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1151, '2016-11-05 17:00:00', 6, 21, 5, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (1271, '2017-02-17 18:00:00', 6, 5, 21, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (269, '2021-10-30 17:30:00', 2, 7, 6, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (361, '2022-01-28 20:30:00', 2, 6, 7, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (503, '2020-12-15 20:30:00', 3, 7, 6, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (594, '2021-01-23 17:30:00', 3, 6, 7, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (263, '2021-10-23 20:30:00', 2, 6, 8, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (354, '2022-01-22 20:30:00', 2, 8, 6, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (482, '2020-10-10 20:30:00', 3, 6, 8, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (573, '2020-10-17 20:30:00', 3, 8, 6, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (290, '2021-11-19 20:30:00', 2, 6, 9, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (380, '2022-02-19 20:30:00', 2, 9, 6, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (459, '2020-09-21 20:30:00', 3, 9, 6, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (551, '2020-11-29 20:30:00', 3, 6, 9, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (276, '2021-11-07 20:30:00', 2, 6, 11, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (367, '2022-02-05 20:30:00', 2, 11, 6, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (531, '2020-11-14 20:30:00', 3, 6, 11, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (622, '2021-03-06 14:45:00', 3, 11, 6, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (302, '2021-12-05 20:30:00', 2, 6, 12, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (393, '2022-03-12 20:30:00', 2, 12, 6, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (510, '2021-01-19 17:30:00', 3, 6, 12, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (601, '2021-01-30 20:30:00', 3, 12, 6, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (254, '2021-10-16 20:30:00', 2, 13, 6, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (345, '2022-01-15 17:30:00', 2, 6, 13, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (475, '2020-10-05 20:30:00', 3, 13, 6, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (566, '2020-12-20 17:30:00', 3, 6, 13, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (314, '2021-12-11 20:30:00', 2, 14, 6, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (405, '2022-03-19 20:30:00', 2, 6, 14, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (468, '2020-10-01 17:30:00', 3, 6, 14, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (559, '2020-12-11 20:30:00', 3, 14, 6, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (239, '2021-10-02 17:30:00', 2, 6, 15, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (330, '2022-01-04 20:30:00', 2, 15, 6, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (447, '2020-09-11 17:30:00', 3, 6, 15, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (538, '2020-11-21 14:45:00', 3, 15, 6, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (327, '2021-11-10 20:30:00', 2, 6, 16, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (418, '2022-04-01 20:30:00', 2, 16, 6, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (552, '2020-12-04 20:30:00', 3, 6, 16, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (461, '2021-01-05 17:30:00', 3, 16, 6, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (236, '2022-05-17 17:30:00', 2, 6, 17, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (237, '2022-05-23 17:30:00', 2, 6, 17, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (524, '2020-11-09 17:30:00', 3, 6, 17, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (615, '2021-02-19 20:30:00', 3, 17, 6, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (307, '2021-12-05 14:45:00', 2, 8, 7, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (398, '2022-02-06 14:45:00', 2, 7, 8, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (542, '2020-11-22 17:30:00', 3, 7, 8, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (451, '2021-01-17 14:45:00', 3, 8, 7, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (701, '2018-11-16 18:00:00', 4, 7, 8, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (779, '2019-02-20 17:30:00', 4, 8, 7, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (884, '2017-10-28 17:00:00', 5, 8, 7, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1004, '2018-02-23 18:00:00', 5, 7, 8, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1126, '2016-10-21 20:15:00', 6, 8, 7, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1246, '2017-01-22 14:45:00', 6, 7, 8, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (243, '2021-10-03 17:30:00', 2, 9, 7, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (334, '2022-01-05 20:30:00', 2, 7, 9, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (518, '2021-01-20 20:30:00', 3, 9, 7, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (609, '2021-02-07 20:30:00', 3, 7, 9, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (665, '2018-10-17 18:30:00', 4, 7, 9, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (743, '2019-01-11 20:30:00', 4, 9, 7, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (860, '2017-10-14 15:00:00', 5, 7, 9, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (980, '2018-02-02 18:00:00', 5, 9, 7, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1178, '2016-11-30 20:00:00', 6, 7, 9, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1298, '2017-01-17 18:00:00', 6, 9, 7, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (321, '2021-12-19 20:30:00', 2, 7, 11, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (412, '2022-03-25 17:30:00', 2, 11, 7, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (529, '2020-11-07 20:30:00', 3, 7, 11, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (620, '2021-02-22 17:30:00', 3, 11, 7, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (256, '2021-10-17 17:30:00', 2, 7, 12, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (347, '2022-01-14 20:30:00', 2, 12, 7, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (464, '2020-09-25 20:30:00', 3, 7, 12, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (555, '2020-12-05 17:30:00', 3, 12, 7, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (705, '2018-11-25 14:45:00', 4, 12, 7, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (783, '2019-02-23 20:30:00', 4, 7, 12, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (916, '2017-11-26 20:00:00', 5, 12, 7, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1036, '2018-03-16 18:00:00', 5, 7, 12, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1159, '2016-11-11 14:45:00', 6, 7, 12, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (1279, '2017-02-22 18:00:00', 6, 12, 7, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (295, '2021-11-28 14:45:00', 2, 7, 13, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (386, '2022-03-06 14:45:00', 2, 13, 7, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (490, '2020-10-14 20:30:00', 3, 7, 13, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (581, '2021-01-09 14:45:00', 3, 13, 7, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (668, '2018-10-20 14:45:00', 4, 13, 7, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (746, '2019-03-11 20:30:00', 4, 7, 13, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (836, '2017-11-22 18:00:00', 5, 13, 7, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (956, '2018-01-05 18:00:00', 5, 7, 13, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1143, '2016-10-29 14:45:00', 6, 13, 7, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1263, '2017-02-11 14:45:00', 6, 7, 13, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (262, '2021-10-23 17:30:00', 2, 14, 7, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (353, '2022-01-24 20:30:00', 2, 7, 14, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (454, '2020-09-20 20:30:00', 3, 14, 7, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (546, '2020-11-28 17:30:00', 3, 7, 14, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (723, '2018-12-16 14:45:00', 4, 7, 14, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (801, '2019-03-16 17:30:00', 4, 14, 7, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (932, '2017-12-10 14:45:00', 5, 14, 7, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1052, '2018-03-29 18:00:00', 5, 7, 14, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1161, '2016-11-19 14:45:00', 6, 14, 7, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1281, '2017-02-26 14:30:00', 6, 7, 14, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (282, '2021-11-14 14:45:00', 2, 7, 15, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (373, '2022-04-11 17:30:00', 2, 15, 7, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (477, '2020-10-03 20:30:00', 3, 7, 15, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (568, '2020-12-19 14:45:00', 3, 15, 7, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (678, '2018-10-28 17:30:00', 4, 15, 7, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (756, '2019-03-05 20:30:00', 4, 7, 15, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (940, '2017-12-23 14:45:00', 5, 7, 15, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1060, '2018-04-07 14:45:00', 5, 15, 7, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1114, '2016-10-16 14:45:00', 6, 7, 15, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1234, '2017-01-28 20:00:00', 6, 15, 7, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (293, '2021-11-21 14:45:00', 2, 16, 7, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (383, '2022-02-20 17:30:00', 2, 7, 16, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (487, '2020-10-28 20:30:00', 3, 16, 7, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (578, '2020-11-03 20:30:00', 3, 7, 16, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (712, '2018-12-07 20:30:00', 4, 7, 16, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (790, '2019-03-02 17:30:00', 4, 16, 7, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (844, '2017-10-04 18:30:00', 5, 7, 16, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (964, '2018-01-13 20:00:00', 5, 16, 7, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1144, '2016-11-05 17:00:00', 6, 7, 16, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1264, '2017-02-19 14:45:00', 6, 16, 7, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (472, '2020-09-30 20:30:00', 3, 17, 7, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (563, '2020-12-12 17:30:00', 3, 7, 17, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (731, '2018-12-22 20:30:00', 4, 17, 7, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (809, '2019-03-23 17:30:00', 4, 7, 17, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (876, '2017-10-23 18:30:00', 5, 7, 17, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (996, '2018-02-17 18:00:00', 5, 17, 7, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1109, '2016-10-09 18:00:00', 6, 17, 7, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1229, '2017-01-08 16:00:00', 6, 7, 17, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (679, '2018-11-04 17:30:00', 4, 7, 18, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (757, '2019-02-03 14:45:00', 4, 18, 7, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (948, '2017-12-13 18:00:00', 5, 18, 7, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1068, '2018-04-15 14:45:00', 5, 7, 18, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1189, '2016-12-04 16:00:00', 6, 7, 18, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1309, '2017-03-11 17:00:00', 6, 18, 7, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (892, '2017-11-03 18:00:00', 5, 7, 19, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1012, '2018-03-01 19:00:00', 5, 19, 7, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1129, '2016-10-26 19:00:00', 6, 7, 19, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1249, '2017-02-06 18:00:00', 6, 19, 7, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (908, '2017-11-19 15:00:00', 5, 20, 7, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1028, '2018-03-11 15:00:00', 5, 7, 20, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1099, '2016-10-03 18:00:00', 6, 7, 20, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1219, '2016-12-21 18:00:00', 6, 20, 7, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1204, '2016-12-14 18:30:00', 6, 7, 21, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1324, '2017-03-24 20:30:00', 6, 21, 7, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (247, '2021-10-09 17:30:00', 2, 9, 8, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (338, '2022-01-09 17:30:00', 2, 8, 9, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (466, '2020-09-25 17:30:00', 3, 9, 8, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (557, '2020-12-06 14:45:00', 3, 8, 9, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (670, '2018-10-22 18:00:00', 4, 8, 9, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (748, '2019-01-20 17:30:00', 4, 9, 8, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (935, '2017-12-13 18:00:00', 5, 9, 8, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1055, '2018-03-30 18:00:00', 5, 8, 9, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1156, '2016-11-12 17:00:00', 6, 8, 9, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1276, '2017-02-22 20:30:00', 6, 9, 8, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (309, '2021-12-12 17:30:00', 2, 11, 8, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (400, '2022-03-18 20:30:00', 2, 8, 11, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (469, '2020-11-17 17:30:00', 3, 8, 11, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (560, '2020-12-14 17:30:00', 3, 11, 8, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (325, '2021-12-30 17:30:00', 2, 12, 8, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (416, '2022-04-02 20:30:00', 2, 8, 12, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (497, '2020-12-09 17:30:00', 3, 12, 8, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (588, '2021-02-13 17:30:00', 3, 8, 12, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (726, '2018-12-16 20:30:00', 4, 8, 12, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (804, '2019-03-15 17:30:00', 4, 12, 8, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (901, '2017-11-10 18:00:00', 5, 12, 8, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1021, '2018-03-07 18:00:00', 5, 8, 12, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1130, '2016-10-26 18:00:00', 6, 12, 8, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1250, '2017-02-05 18:00:00', 6, 8, 12, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (287, '2021-11-22 20:30:00', 2, 13, 8, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (384, '2022-02-19 14:45:00', 2, 8, 13, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (527, '2021-01-13 17:30:00', 3, 13, 8, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (618, '2021-02-20 20:30:00', 3, 8, 13, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (688, '2018-11-07 18:00:00', 4, 13, 8, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (766, '2019-02-10 14:45:00', 4, 8, 13, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (866, '2017-10-14 14:45:00', 5, 13, 8, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (986, '2018-02-04 14:45:00', 5, 8, 13, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1113, '2016-10-15 14:45:00', 6, 13, 8, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1233, '2017-01-28 14:45:00', 6, 8, 13, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (255, '2021-10-17 14:45:00', 2, 8, 14, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (346, '2022-03-09 17:30:00', 2, 14, 8, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (481, '2020-10-04 17:30:00', 3, 14, 8, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (572, '2020-12-20 20:30:00', 3, 8, 14, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (729, '2018-12-20 20:30:00', 4, 14, 8, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (807, '2019-03-19 20:30:00', 4, 8, 14, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (914, '2017-11-18 14:45:00', 5, 8, 14, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1034, '2018-03-10 17:00:00', 5, 14, 8, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1141, '2016-10-30 14:45:00', 6, 8, 14, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1261, '2017-02-10 18:00:00', 6, 14, 8, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (278, '2021-11-06 14:45:00', 2, 15, 8, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (369, '2022-03-22 17:30:00', 2, 8, 15, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (512, '2021-01-31 14:45:00', 3, 15, 8, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (603, '2021-02-03 15:00:00', 3, 8, 15, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (693, '2018-11-11 14:45:00', 4, 8, 15, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (771, '2019-02-16 14:45:00', 4, 15, 8, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (854, '2017-10-07 13:00:00', 5, 8, 15, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (974, '2018-01-21 20:00:00', 5, 15, 8, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1215, '2016-12-17 14:45:00', 6, 15, 8, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1335, '2017-04-01 20:00:00', 6, 8, 15, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (281, '2021-11-13 14:45:00', 2, 8, 16, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (372, '2022-02-12 15:30:00', 2, 16, 8, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (521, '2021-01-28 15:00:00', 3, 8, 16, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (612, '2021-02-06 14:45:00', 3, 16, 8, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (662, '2018-10-17 20:30:00', 4, 8, 16, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (740, '2019-01-12 14:45:00', 4, 16, 8, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (929, '2017-12-01 18:00:00', 5, 8, 16, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1049, '2018-03-25 20:00:00', 5, 16, 8, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1096, '2016-10-01 15:00:00', 6, 16, 8, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1216, '2016-12-30 20:15:00', 6, 8, 16, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (508, '2021-01-07 17:30:00', 3, 17, 8, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (599, '2021-01-23 20:30:00', 3, 8, 17, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (682, '2018-11-03 17:30:00', 4, 8, 17, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (760, '2019-02-05 20:30:00', 4, 17, 8, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (944, '2017-12-23 17:00:00', 5, 8, 17, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1064, '2018-04-08 17:30:00', 5, 17, 8, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1201, '2016-12-14 18:00:00', 6, 8, 17, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1321, '2017-03-26 17:00:00', 6, 17, 8, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (715, '2018-12-12 18:00:00', 4, 8, 18, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (793, '2019-03-11 17:30:00', 4, 18, 8, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (918, '2017-11-25 17:00:00', 5, 18, 8, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1038, '2018-03-17 14:45:00', 5, 8, 18, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1164, '2016-11-19 17:00:00', 6, 18, 8, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1284, '2017-02-25 20:00:00', 6, 8, 18, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (952, '2017-12-29 18:00:00', 5, 19, 8, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1072, '2018-04-15 14:45:00', 5, 8, 19, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1111, '2016-10-06 18:00:00', 6, 19, 8, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1231, '2017-01-07 17:00:00', 6, 8, 19, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (842, '2017-09-30 17:00:00', 5, 8, 20, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (959, '2018-01-06 14:45:00', 5, 20, 8, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1198, '2016-12-10 17:00:00', 6, 20, 8, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1318, '2017-03-18 17:00:00', 6, 8, 20, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1181, '2016-11-30 20:30:00', 6, 21, 8, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1301, '2017-03-08 18:00:00', 6, 8, 21, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (323, '2022-02-25 20:30:00', 2, 9, 11, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (414, '2022-04-01 17:30:00', 2, 11, 9, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (453, '2020-09-12 20:30:00', 3, 11, 9, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (544, '2020-11-21 20:30:00', 3, 9, 11, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (274, '2021-11-06 17:30:00', 2, 12, 9, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (365, '2022-02-06 20:30:00', 2, 9, 12, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (479, '2020-11-18 17:30:00', 3, 9, 12, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (570, '2020-12-19 20:30:00', 3, 12, 9, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (675, '2018-10-26 18:00:00', 4, 9, 12, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (753, '2019-02-01 17:30:00', 4, 12, 9, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (950, '2017-12-17 15:00:00', 5, 9, 12, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1070, '2018-04-15 14:45:00', 5, 12, 9, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1190, '2016-12-06 18:00:00', 6, 12, 9, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (1310, '2017-03-11 17:00:00', 6, 9, 12, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (319, '2021-12-17 20:30:00', 2, 13, 9, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (410, '2022-03-25 20:30:00', 2, 9, 13, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (505, '2021-01-03 14:45:00', 3, 9, 13, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (596, '2021-01-22 17:30:00', 3, 13, 9, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (720, '2018-12-12 19:00:00', 4, 9, 13, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (798, '2019-03-07 20:30:00', 4, 13, 9, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (911, '2017-11-18 15:00:00', 5, 13, 9, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1031, '2018-03-09 18:00:00', 5, 9, 13, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1173, '2016-11-25 20:15:00', 6, 13, 9, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1293, '2017-03-04 20:00:00', 6, 9, 13, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (285, '2021-11-12 17:30:00', 2, 9, 14, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (376, '2022-02-14 20:30:00', 2, 14, 9, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (532, '2020-11-14 14:45:00', 3, 14, 9, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (623, '2021-03-06 20:30:00', 3, 9, 14, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (696, '2018-11-12 20:30:00', 4, 14, 9, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (774, '2019-02-16 17:30:00', 4, 9, 14, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (841, '2017-09-30 17:00:00', 5, 14, 9, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (962, '2018-01-06 17:00:00', 5, 9, 14, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1193, '2016-12-10 17:00:00', 6, 9, 14, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1313, '2017-03-17 18:00:00', 6, 14, 9, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (304, '2021-12-03 17:30:00', 2, 15, 9, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (395, '2022-03-12 17:30:00', 2, 9, 15, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (492, '2021-01-10 14:45:00', 3, 15, 9, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (583, '2021-02-14 14:45:00', 3, 9, 15, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (722, '2018-12-15 17:30:00', 4, 15, 9, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (800, '2019-03-16 14:45:00', 4, 9, 15, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (905, '2017-11-21 19:45:00', 5, 9, 15, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1025, '2018-03-07 18:30:00', 5, 15, 9, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1148, '2016-11-05 20:00:00', 6, 9, 15, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1268, '2017-02-18 17:00:00', 6, 15, 9, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (311, '2021-12-12 14:45:00', 2, 9, 16, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (402, '2022-03-18 17:30:00', 2, 16, 9, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (500, '2020-10-18 14:45:00', 3, 16, 9, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (591, '2021-01-17 17:30:00', 3, 9, 16, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (683, '2018-12-04 20:30:00', 4, 16, 9, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (761, '2019-02-06 17:30:00', 4, 9, 16, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (859, '2017-10-09 18:00:00', 5, 16, 9, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (979, '2018-01-19 18:00:00', 5, 9, 16, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1208, '2016-12-17 17:00:00', 6, 9, 16, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1328, '2017-04-01 14:45:00', 6, 16, 9, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (485, '2020-10-20 20:30:00', 3, 17, 9, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (576, '2020-12-22 17:00:00', 3, 9, 17, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (709, '2018-12-10 18:00:00', 4, 17, 9, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (787, '2019-03-01 20:30:00', 4, 9, 17, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (872, '2017-10-18 17:00:00', 5, 9, 17, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (995, '2018-02-11 14:45:00', 5, 17, 9, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1139, '2016-10-29 18:00:00', 6, 17, 9, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1259, '2017-02-11 17:00:00', 6, 9, 17, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (697, '2018-11-17 17:30:00', 4, 18, 9, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (775, '2019-02-20 18:30:00', 4, 9, 18, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (845, '2017-10-04 20:30:00', 5, 9, 18, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (965, '2018-01-13 16:00:00', 5, 18, 9, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1103, '2016-10-02 18:00:00', 6, 9, 18, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1223, '2016-12-30 18:00:00', 6, 18, 9, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (877, '2017-10-22 14:45:00', 5, 19, 9, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (997, '2018-02-17 17:00:00', 5, 9, 19, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1163, '2016-11-19 17:00:00', 6, 9, 19, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1283, '2017-02-26 17:00:00', 6, 19, 9, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (890, '2017-10-28 17:00:00', 5, 9, 20, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1010, '2018-02-25 14:45:00', 5, 20, 9, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1133, '2016-10-26 18:00:00', 6, 9, 20, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1253, '2017-02-04 17:00:00', 6, 20, 9, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1118, '2016-10-15 17:00:00', 6, 9, 21, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1238, '2017-01-28 17:00:00', 6, 21, 9, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (261, '2021-10-25 20:30:00', 2, 12, 11, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (352, '2022-01-23 17:30:00', 2, 11, 12, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (484, '2020-10-11 17:30:00', 3, 12, 11, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (575, '2020-12-22 20:30:00', 3, 11, 12, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (306, '2021-12-04 17:30:00', 2, 13, 11, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (397, '2022-03-11 17:30:00', 2, 11, 13, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (514, '2021-02-01 17:30:00', 3, 13, 11, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (605, '2021-02-10 14:30:00', 3, 11, 13, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (270, '2021-10-30 20:30:00', 2, 11, 14, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (362, '2022-01-28 17:30:00', 2, 14, 11, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (558, '2020-10-20 17:30:00', 3, 14, 11, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (467, '2020-10-28 17:30:00', 3, 11, 14, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (292, '2021-11-20 17:30:00', 2, 15, 11, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (382, '2022-02-20 14:45:00', 2, 11, 15, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (499, '2020-10-31 14:45:00', 3, 11, 15, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (590, '2021-01-16 17:30:00', 3, 15, 11, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (296, '2021-11-26 20:30:00', 2, 11, 16, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (387, '2022-03-05 17:30:00', 2, 16, 11, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (506, '2020-10-23 20:30:00', 3, 11, 16, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (597, '2021-01-24 14:45:00', 3, 16, 11, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (493, '2020-11-11 20:30:00', 3, 17, 11, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (584, '2021-02-28 17:30:00', 3, 11, 17, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (241, '2021-10-04 20:30:00', 2, 12, 13, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (332, '2022-01-04 17:30:00', 2, 13, 12, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (449, '2020-09-12 17:30:00', 3, 12, 13, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (540, '2020-11-21 17:30:00', 3, 13, 12, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (694, '2018-11-10 17:30:00', 4, 12, 13, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (772, '2019-02-17 17:30:00', 4, 13, 12, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (881, '2017-10-20 18:00:00', 5, 13, 12, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1001, '2018-02-17 14:45:00', 5, 12, 13, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1145, '2016-11-05 14:45:00', 6, 12, 13, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1265, '2017-02-18 14:45:00', 6, 13, 12, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (300, '2021-11-29 20:30:00', 2, 12, 14, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (391, '2022-03-06 17:30:00', 2, 14, 12, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (494, '2020-11-04 20:30:00', 3, 14, 12, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (585, '2021-01-10 20:30:00', 3, 12, 14, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (671, '2018-10-21 17:30:00', 4, 12, 14, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (749, '2019-01-18 17:30:00', 4, 14, 12, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (931, '2017-12-03 20:00:00', 5, 12, 14, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1051, '2018-03-23 18:00:00', 5, 14, 12, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1175, '2016-11-24 18:00:00', 6, 12, 14, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1295, '2017-03-04 17:00:00', 6, 14, 12, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (317, '2021-12-19 17:30:00', 2, 15, 12, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (408, '2022-03-26 20:30:00', 2, 12, 15, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (525, '2020-10-27 17:30:00', 3, 12, 15, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (616, '2021-02-27 17:30:00', 3, 15, 12, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (700, '2018-11-16 20:30:00', 4, 15, 12, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (778, '2019-02-20 18:00:00', 4, 12, 15, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (871, '2017-10-18 20:30:00', 5, 12, 15, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (991, '2018-02-10 18:00:00', 5, 15, 12, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1125, '2016-10-22 14:45:00', 6, 15, 12, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1245, '2017-01-24 18:00:00', 6, 12, 15, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (249, '2021-10-08 20:30:00', 2, 16, 12, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (340, '2022-03-02 20:30:00', 2, 12, 16, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (457, '2020-09-18 20:30:00', 3, 12, 16, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (549, '2020-11-29 17:30:00', 3, 16, 12, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (660, '2018-10-12 20:30:00', 4, 16, 12, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (738, '2018-11-21 18:00:00', 4, 12, 16, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (946, '2017-12-20 18:00:00', 5, 12, 16, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1066, '2018-04-08 20:00:00', 5, 16, 12, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1160, '2016-11-19 18:00:00', 6, 12, 16, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1280, '2017-01-18 19:30:00', 6, 16, 12, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (523, '2020-11-01 17:30:00', 3, 17, 12, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (614, '2021-02-08 17:30:00', 3, 12, 17, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (687, '2018-11-07 18:00:00', 4, 17, 12, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (765, '2019-02-09 17:30:00', 4, 12, 17, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (840, '2017-09-29 18:00:00', 5, 12, 17, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (961, '2018-01-06 18:00:00', 5, 17, 12, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1115, '2016-10-15 20:00:00', 6, 12, 17, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1235, '2017-01-27 18:00:00', 6, 17, 12, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (661, '2018-10-17 18:00:00', 4, 12, 18, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (739, '2019-01-13 20:30:00', 4, 18, 12, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (933, '2017-12-08 18:00:00', 5, 18, 12, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1053, '2018-03-29 17:00:00', 5, 12, 18, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1194, '2016-12-09 18:00:00', 6, 18, 12, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1314, '2017-03-18 17:00:00', 6, 12, 18, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (847, '2017-10-04 18:00:00', 5, 19, 12, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (967, '2018-01-12 18:00:00', 5, 12, 19, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1142, '2016-10-29 17:00:00', 6, 12, 19, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1262, '2017-02-12 14:45:00', 6, 19, 12, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (856, '2017-10-07 17:00:00', 5, 12, 20, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (976, '2018-01-18 18:00:00', 5, 20, 12, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1108, '2016-11-02 18:00:00', 6, 20, 12, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1228, '2017-01-07 17:00:00', 6, 12, 20, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1211, '2016-12-17 17:00:00', 6, 21, 12, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1331, '2017-04-01 17:00:00', 6, 12, 21, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (326, '2021-12-30 20:30:00', 2, 14, 13, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (417, '2022-04-02 14:45:00', 2, 13, 14, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (520, '2020-12-29 20:30:00', 3, 13, 14, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (611, '2021-02-07 14:45:00', 3, 14, 13, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (710, '2018-12-09 14:45:00', 4, 13, 14, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (788, '2019-03-02 14:45:00', 4, 14, 13, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (887, '2017-10-27 18:00:00', 5, 14, 13, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1007, '2018-02-25 18:00:00', 5, 13, 14, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (1158, '2016-11-12 14:45:00', 6, 13, 14, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1278, '2017-02-21 20:30:00', 6, 14, 13, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (267, '2021-10-30 14:45:00', 2, 13, 15, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (358, '2022-03-15 20:30:00', 2, 15, 13, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (462, '2020-09-26 14:45:00', 3, 13, 15, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (553, '2020-12-04 17:30:00', 3, 15, 13, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (732, '2018-12-22 14:45:00', 4, 13, 15, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (810, '2019-03-24 14:45:00', 4, 15, 13, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (955, '2017-12-30 14:45:00', 5, 15, 13, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1075, '2018-04-14 14:45:00', 5, 13, 15, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1110, '2016-10-09 14:45:00', 6, 15, 13, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1230, '2017-01-07 14:45:00', 6, 13, 15, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (279, '2021-11-07 14:45:00', 2, 16, 13, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (370, '2022-02-05 17:30:00', 2, 13, 16, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (474, '2020-11-25 20:30:00', 3, 16, 13, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (565, '2021-02-28 14:45:00', 3, 13, 16, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (699, '2018-11-17 14:45:00', 4, 13, 16, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (777, '2019-02-20 20:30:00', 4, 16, 13, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (904, '2017-11-09 18:00:00', 5, 13, 16, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1024, '2018-03-28 20:30:00', 5, 16, 13, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1128, '2016-10-26 18:00:00', 6, 13, 16, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1248, '2017-02-04 14:45:00', 6, 16, 13, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (536, '2020-11-15 14:45:00', 3, 17, 13, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (627, '2021-03-09 17:30:00', 3, 13, 17, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (666, '2018-10-17 17:00:00', 4, 13, 17, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (744, '2019-01-11 17:30:00', 4, 17, 13, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (921, '2017-11-25 18:00:00', 5, 17, 13, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1041, '2018-03-17 15:00:00', 5, 13, 17, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1098, '2016-10-05 18:00:00', 6, 13, 17, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1218, '2016-12-30 19:00:00', 6, 17, 13, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (655, '2018-10-15 18:00:00', 4, 18, 13, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (733, '2018-12-28 17:30:00', 4, 13, 18, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (896, '2017-11-04 15:00:00', 5, 13, 18, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1016, '2018-03-03 15:00:00', 5, 18, 13, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1179, '2016-11-30 18:00:00', 6, 18, 13, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1299, '2017-03-08 17:00:00', 6, 13, 18, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (926, '2017-12-02 15:00:00', 5, 13, 19, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1046, '2018-03-26 18:00:00', 5, 19, 13, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1127, '2016-10-20 19:00:00', 6, 19, 13, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1247, '2017-01-22 18:00:00', 6, 13, 19, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (938, '2017-12-09 18:00:00', 5, 13, 20, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1058, '2018-03-30 18:00:00', 5, 20, 13, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1213, '2016-12-17 18:00:00', 6, 20, 13, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1333, '2017-04-02 17:30:00', 6, 13, 20, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1196, '2016-12-10 20:00:00', 6, 21, 13, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1316, '2017-03-18 17:00:00', 6, 13, 21, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (250, '2021-10-09 14:45:00', 2, 14, 15, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (341, '2022-03-02 17:30:00', 2, 15, 14, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (507, '2021-01-13 20:30:00', 3, 14, 15, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (598, '2021-02-11 14:30:00', 3, 15, 14, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (719, '2018-12-12 17:30:00', 4, 14, 15, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (797, '2019-03-10 20:30:00', 4, 15, 14, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (880, '2017-10-21 17:00:00', 5, 15, 14, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1000, '2018-02-17 17:00:00', 5, 14, 15, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1131, '2016-10-26 20:30:00', 6, 14, 15, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1251, '2017-02-04 17:00:00', 6, 15, 14, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (240, '2021-10-03 20:30:00', 2, 14, 16, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (331, '2022-01-03 17:30:00', 2, 16, 14, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (513, '2020-10-31 20:30:00', 3, 16, 14, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (604, '2021-01-30 14:45:00', 3, 14, 16, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (674, '2018-10-26 20:30:00', 4, 14, 16, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (752, '2019-02-02 17:30:00', 4, 16, 14, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (949, '2017-12-30 18:00:00', 5, 16, 14, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1069, '2018-04-13 18:00:00', 5, 14, 16, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1176, '2016-11-29 18:00:00', 6, 14, 16, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1296, '2017-03-07 19:00:00', 6, 16, 14, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (498, '2020-12-03 17:30:00', 3, 17, 14, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (589, '2021-01-17 20:30:00', 3, 14, 17, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (708, '2018-11-23 18:00:00', 4, 14, 17, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (786, '2019-02-25 20:30:00', 4, 17, 14, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (846, '2017-10-04 19:00:00', 5, 17, 14, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (966, '2018-01-12 18:00:00', 5, 14, 17, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1124, '2016-12-22 19:00:00', 6, 17, 14, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1244, '2017-01-20 18:00:00', 6, 14, 17, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (685, '2018-11-07 18:00:00', 4, 18, 14, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (763, '2019-02-11 20:30:00', 4, 14, 18, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (947, '2017-12-22 18:00:00', 5, 14, 18, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1067, '2018-04-04 18:00:00', 5, 18, 14, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1206, '2016-12-14 18:00:00', 6, 18, 14, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1326, '2017-03-25 17:00:00', 6, 14, 18, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (857, '2017-10-08 17:00:00', 5, 14, 19, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (977, '2018-01-19 18:00:00', 5, 19, 14, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1146, '2016-11-05 17:00:00', 6, 14, 19, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1266, '2017-02-17 18:00:00', 6, 19, 14, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (863, '2017-10-13 18:00:00', 5, 20, 14, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (983, '2018-02-04 17:00:00', 5, 14, 20, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1116, '2016-10-14 18:00:00', 6, 14, 20, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1236, '2017-01-28 17:00:00', 6, 20, 14, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1101, '2016-10-04 18:00:00', 6, 14, 21, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1221, '2016-12-30 18:00:00', 6, 21, 14, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (265, '2021-10-23 14:45:00', 2, 15, 16, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (356, '2022-01-22 17:30:00', 2, 16, 15, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (537, '2020-12-30 17:30:00', 3, 16, 15, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (628, '2021-03-07 14:45:00', 3, 15, 16, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (706, '2018-11-27 19:00:00', 4, 16, 15, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (784, '2019-02-23 14:45:00', 4, 15, 16, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (895, '2017-11-04 17:00:00', 5, 15, 16, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1015, '2018-02-20 19:00:00', 5, 16, 15, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (1200, '2016-12-14 20:30:00', 6, 16, 15, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1320, '2017-03-26 18:00:00', 6, 15, 16, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (458, '2020-09-19 20:30:00', 3, 15, 17, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (550, '2020-11-28 20:30:00', 3, 17, 15, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (656, '2018-10-13 17:30:00', 4, 17, 15, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (734, '2018-11-30 20:30:00', 4, 15, 17, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (909, '2017-11-18 17:00:00', 5, 15, 17, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1029, '2018-03-10 18:00:00', 5, 17, 15, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1199, '2016-12-09 18:00:00', 6, 17, 15, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1319, '2017-03-19 17:00:00', 6, 15, 17, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (667, '2018-10-19 18:00:00', 4, 15, 18, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (745, '2019-01-19 20:30:00', 4, 18, 15, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (888, '2017-10-28 14:45:00', 5, 18, 15, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1008, '2018-02-24 17:00:00', 5, 15, 18, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1155, '2016-11-12 17:00:00', 6, 15, 18, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1275, '2017-02-22 18:00:00', 6, 18, 15, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (922, '2017-11-24 18:00:00', 5, 19, 15, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1042, '2018-03-17 17:00:00', 5, 15, 19, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1097, '2016-09-30 20:15:00', 6, 19, 15, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1217, '2016-12-30 18:00:00', 6, 15, 19, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (925, '2017-12-02 17:00:00', 5, 15, 20, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1045, '2018-03-25 17:00:00', 5, 20, 15, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1185, '2016-12-03 16:30:00', 6, 15, 20, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1305, '2017-03-12 17:00:00', 6, 20, 15, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1169, '2016-11-26 17:00:00', 6, 15, 21, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1289, '2017-03-06 18:00:00', 6, 21, 15, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (448, '2020-09-13 17:30:00', 3, 17, 16, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (539, '2020-11-22 20:30:00', 3, 16, 17, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (695, '2018-11-12 18:00:00', 4, 17, 16, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (773, '2019-02-14 20:30:00', 4, 16, 17, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (861, '2017-10-12 19:00:00', 5, 17, 16, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (981, '2018-02-03 20:00:00', 5, 16, 17, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1184, '2016-12-03 20:00:00', 6, 16, 17, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (1304, '2017-03-11 18:00:00', 6, 17, 16, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (727, '2018-12-21 20:30:00', 4, 18, 16, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (805, '2019-03-20 20:30:00', 4, 16, 18, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (843, '2017-10-01 15:00:00', 5, 18, 16, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (963, '2018-01-06 14:45:00', 5, 16, 18, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (1104, '2016-10-08 14:45:00', 6, 16, 18, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1224, '2017-01-06 20:15:00', 6, 18, 16, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (875, '2017-10-17 19:00:00', 5, 16, 19, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (994, '2018-02-07 19:00:00', 5, 19, 16, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1112, '2016-10-14 18:00:00', 6, 19, 16, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1232, '2017-01-28 18:00:00', 6, 16, 19, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (878, '2017-10-21 17:00:00', 5, 20, 16, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (998, '2018-02-16 18:00:00', 5, 16, 20, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (1168, '2016-11-25 18:00:00', 6, 20, 16, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1288, '2017-03-02 19:00:00', 6, 16, 20, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1136, '2016-10-31 18:00:00', 6, 16, 21, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1256, '2017-02-13 18:00:00', 6, 21, 16, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (721, '2018-12-17 17:30:00', 4, 18, 17, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (799, '2019-03-15 20:30:00', 4, 17, 18, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (858, '2017-10-07 17:00:00', 5, 18, 17, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (978, '2018-01-20 18:00:00', 5, 17, 18, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1149, '2016-11-05 17:00:00', 6, 18, 17, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1269, '2017-02-17 18:00:00', 6, 17, 18, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (891, '2017-10-28 19:00:00', 5, 17, 19, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (1011, '2018-02-24 17:00:00', 5, 19, 17, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1214, '2016-12-19 18:00:00', 6, 17, 19, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1334, '2017-04-02 16:30:00', 6, 19, 17, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (893, '2017-11-04 17:00:00', 5, 20, 17, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1013, '2018-03-04 20:00:00', 5, 17, 20, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1183, '2016-11-30 18:00:00', 6, 20, 17, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1303, '2017-03-08 20:30:00', 6, 17, 20, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1166, '2016-11-19 17:00:00', 6, 21, 17, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1286, '2017-02-24 18:00:00', 6, 17, 21, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (862, '2017-10-12 18:00:00', 5, 19, 18, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (982, '2018-02-02 18:00:00', 5, 18, 19, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (1172, '2016-11-27 20:00:00', 6, 19, 18, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (1292, '2017-03-03 18:00:00', 6, 18, 19, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (874, '2017-10-18 18:00:00', 5, 18, 20, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (993, '2018-02-10 17:00:00', 5, 20, 18, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1138, '2016-10-29 17:00:00', 6, 20, 18, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (1258, '2017-02-10 18:00:00', 6, 18, 20, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1121, '2016-10-23 17:00:00', 6, 21, 18, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (1241, '2017-01-21 17:00:00', 6, 18, 21, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (907, '2017-11-13 19:00:00', 5, 19, 20, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1027, '2018-03-07 18:00:00', 5, 20, 19, 0, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1202, '2016-12-13 18:00:00', 6, 19, 20, 3, 0, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1322, '2017-03-25 20:00:00', 6, 20, 19, 2, 3, 1, 2, 1, 'league');
INSERT INTO public.matches VALUES (1187, '2016-12-05 18:00:00', 6, 19, 21, 3, 2, 2, 1, 0, 'league');
INSERT INTO public.matches VALUES (1307, '2017-03-11 17:00:00', 6, 21, 19, 1, 3, 0, 3, 1, 'league');
INSERT INTO public.matches VALUES (1153, '2016-11-12 17:00:00', 6, 20, 21, 3, 1, 3, 0, 0, 'league');
INSERT INTO public.matches VALUES (1273, '2017-02-22 18:30:00', 6, 21, 20, 1, 3, 0, 3, 1, 'league');


--
-- Data for Name: matches_extended; Type: TABLE DATA; Schema: public; Owner: user
--

INSERT INTO public.matches_extended VALUES (1, 238, 3482, 'Tomasz Fornal');
INSERT INTO public.matches_extended VALUES (2, 242, 1499, 'Fabian Drzyzga');
INSERT INTO public.matches_extended VALUES (3, 239, 1900, 'Kamil Semeniuk');
INSERT INTO public.matches_extended VALUES (4, 244, 1500, 'Uro┼í Kova─Źevi─ç');
INSERT INTO public.matches_extended VALUES (5, 243, 496, 'Micah Ma╩╗a');
INSERT INTO public.matches_extended VALUES (6, 240, 1200, 'Bartosz Kwolek');
INSERT INTO public.matches_extended VALUES (7, 241, 786, 'Dick Kooy');
INSERT INTO public.matches_extended VALUES (8, 251, 1116, 'Tomasz Fornal');
INSERT INTO public.matches_extended VALUES (9, 249, 1610, 'Bartosz Kwolek');
INSERT INTO public.matches_extended VALUES (10, 250, 1200, 'David Smith');
INSERT INTO public.matches_extended VALUES (11, 247, 621, 'Jakub Jarosz');
INSERT INTO public.matches_extended VALUES (12, 245, 1100, 'Bart┼éomiej Bo┼é─ůd┼║');
INSERT INTO public.matches_extended VALUES (13, 246, 4250, 'Uro┼í Kova─Źevi─ç');
INSERT INTO public.matches_extended VALUES (14, 248, 1138, 'Aleksandar Atanasijevi─ç');
INSERT INTO public.matches_extended VALUES (15, 253, 3012, '├üngel Trinidad de Haro');
INSERT INTO public.matches_extended VALUES (16, 258, 1392, 'Piotr Orczyk');
INSERT INTO public.matches_extended VALUES (17, 252, 1500, 'Norbert Huber');
INSERT INTO public.matches_extended VALUES (18, 254, 598, 'Mateusz Bieniek');
INSERT INTO public.matches_extended VALUES (19, 255, 2800, 'Klemen ─îebulj');
INSERT INTO public.matches_extended VALUES (20, 256, 3100, 'Lukas Kampa');
INSERT INTO public.matches_extended VALUES (21, 257, 1326, 'Torey Defalco');
INSERT INTO public.matches_extended VALUES (22, 259, 2173, 'Bartosz Filipiak');
INSERT INTO public.matches_extended VALUES (23, 265, 1450, '┼üukasz Kaczmarek');
INSERT INTO public.matches_extended VALUES (24, 262, 1000, 'Pawe┼é Rusin');
INSERT INTO public.matches_extended VALUES (25, 263, 1878, 'Klemen ─îebulj');
INSERT INTO public.matches_extended VALUES (26, 264, 1500, 'Benjamin Toniutti');
INSERT INTO public.matches_extended VALUES (27, 260, 1250, 'Karol Butryn');
INSERT INTO public.matches_extended VALUES (28, 261, 345, 'Masahiro Sekita');
INSERT INTO public.matches_extended VALUES (29, 271, 1468, 'Facundo Conte');
INSERT INTO public.matches_extended VALUES (30, 266, 1228, 'Du┼ían Petkovi─ç');
INSERT INTO public.matches_extended VALUES (31, 267, 1362, '┼üukasz Kaczmarek');
INSERT INTO public.matches_extended VALUES (32, 269, 1900, 'Kewin Sasak');
INSERT INTO public.matches_extended VALUES (33, 270, 1200, 'Bart┼éomiej Lema┼äski');
INSERT INTO public.matches_extended VALUES (34, 268, 3700, 'St├ęphen Boyer');
INSERT INTO public.matches_extended VALUES (35, 272, 286, 'Karol Butryn');
INSERT INTO public.matches_extended VALUES (36, 273, 2088, 'Torey Defalco');
INSERT INTO public.matches_extended VALUES (37, 278, 1900, 'Marcin Janusz');
INSERT INTO public.matches_extended VALUES (38, 274, 878, 'Wojciech Ferens');
INSERT INTO public.matches_extended VALUES (39, 275, 1100, 'Facundo Conte');
INSERT INTO public.matches_extended VALUES (40, 279, 1730, 'Dick Kooy');
INSERT INTO public.matches_extended VALUES (41, 277, 1500, 'Jurij H┼éadyr');
INSERT INTO public.matches_extended VALUES (42, 276, 1500, 'Bart┼éomiej Bo┼é─ůd┼║');
INSERT INTO public.matches_extended VALUES (43, 285, 261, 'Jakub Szyma┼äski');
INSERT INTO public.matches_extended VALUES (44, 281, 2500, 'Maciej Muzaj');
INSERT INTO public.matches_extended VALUES (47, 282, 6250, 'Marcin Janusz');
INSERT INTO public.matches_extended VALUES (48, 283, 1650, 'Tr├ęvor Cl├ęvenot');
INSERT INTO public.matches_extended VALUES (49, 286, 1070, 'Torey Defalco');
INSERT INTO public.matches_extended VALUES (50, 290, 1250, 'Jakub Jarosz');
INSERT INTO public.matches_extended VALUES (51, 291, 1500, 'Facundo Conte');
INSERT INTO public.matches_extended VALUES (52, 292, 1050, '┼üukasz Kaczmarek');
INSERT INTO public.matches_extended VALUES (53, 289, 700, 'Karol Butryn');
INSERT INTO public.matches_extended VALUES (54, 293, 2089, 'Igor Grobelny');
INSERT INTO public.matches_extended VALUES (55, 288, 2522, 'Wojciech W┼éodarczyk');
INSERT INTO public.matches_extended VALUES (56, 287, 783, 'Aleksandar Atanasijevi─ç');
INSERT INTO public.matches_extended VALUES (57, 296, 980, 'Bartosz Kwolek');
INSERT INTO public.matches_extended VALUES (58, 297, 1500, '┼üukasz Kaczmarek');
INSERT INTO public.matches_extended VALUES (59, 298, 753, 'Jan Hadrava');
INSERT INTO public.matches_extended VALUES (60, 294, 1300, 'Jakub Wachnik');
INSERT INTO public.matches_extended VALUES (61, 295, 4800, 'Grzegorz ┼üomacz');
INSERT INTO public.matches_extended VALUES (62, 299, 1050, 'Torey Defalco');
INSERT INTO public.matches_extended VALUES (63, 300, 312, 'Rafa┼é Faryna');
INSERT INTO public.matches_extended VALUES (64, 304, 550, 'Aleksander ┼Üliwka');
INSERT INTO public.matches_extended VALUES (65, 303, 1250, 'Jan Hadrava');
INSERT INTO public.matches_extended VALUES (66, 306, 601, 'Aleksandar Atanasijevi─ç');
INSERT INTO public.matches_extended VALUES (67, 307, 1500, 'Mateusz Mika');
INSERT INTO public.matches_extended VALUES (68, 301, 2808, 'Jan Nowakowski');
INSERT INTO public.matches_extended VALUES (69, 302, 1000, 'Wojciech Ferens');
INSERT INTO public.matches_extended VALUES (70, 305, 1685, 'Igor Grobelny');
INSERT INTO public.matches_extended VALUES (71, 312, 650, 'Marcin Janusz');
INSERT INTO public.matches_extended VALUES (72, 313, 818, 'Jakub Popiwczak');
INSERT INTO public.matches_extended VALUES (73, 314, 800, 'Mateusz Mas┼éowski');
INSERT INTO public.matches_extended VALUES (74, 311, 476, 'Micha┼é Superlak');
INSERT INTO public.matches_extended VALUES (75, 309, 1200, 'Klemen ─îebulj');
INSERT INTO public.matches_extended VALUES (76, 308, 1550, 'Mariusz Wlaz┼éy');
INSERT INTO public.matches_extended VALUES (77, 310, 1463, 'Dawid Konarski');
INSERT INTO public.matches_extended VALUES (78, 319, 440, 'Mateusz Bieniek');
INSERT INTO public.matches_extended VALUES (79, 320, 1500, 'Miguel Tavares');
INSERT INTO public.matches_extended VALUES (80, 316, 715, 'Tomasz Fornal');
INSERT INTO public.matches_extended VALUES (81, 318, 986, 'Bartosz Kwolek');
INSERT INTO public.matches_extended VALUES (82, 317, 850, 'Kamil Semeniuk');
INSERT INTO public.matches_extended VALUES (83, 321, 1640, 'Pawe┼é Halaba');
INSERT INTO public.matches_extended VALUES (84, 315, 2033, 'Wassim Ben Tara');
INSERT INTO public.matches_extended VALUES (45, 280, 2100, 'Norbert Huber');
INSERT INTO public.matches_extended VALUES (46, 284, 1500, 'Andrzej Wrona');
INSERT INTO public.matches_extended VALUES (87, 322, 2096, 'Facundo Conte');
INSERT INTO public.matches_extended VALUES (88, 325, 927, 'Sam Deroo');
INSERT INTO public.matches_extended VALUES (89, 326, 1500, 'Mateusz Bieniek');
INSERT INTO public.matches_extended VALUES (90, 323, 315, 'Bart┼éomiej Bo┼é─ůd┼║');
INSERT INTO public.matches_extended VALUES (91, 324, 1200, 'Torey Defalco');
INSERT INTO public.matches_extended VALUES (92, 331, 628, 'Pawe┼é Rusin');
INSERT INTO public.matches_extended VALUES (93, 329, 783, 'Jan Hadrava');
INSERT INTO public.matches_extended VALUES (94, 332, 246, 'Mateusz Bieniek');
INSERT INTO public.matches_extended VALUES (95, 330, 950, 'Aleksander ┼Üliwka');
INSERT INTO public.matches_extended VALUES (96, 333, 1500, 'Pawe┼é Zatorski');
INSERT INTO public.matches_extended VALUES (97, 334, 2200, 'Tomas Rousseaux');
INSERT INTO public.matches_extended VALUES (98, 335, 1380, 'Dawid Konarski');
INSERT INTO public.matches_extended VALUES (99, 339, 1200, 'Milad Ebadipur');
INSERT INTO public.matches_extended VALUES (100, 342, 1093, 'Tomasz Fornal');
INSERT INTO public.matches_extended VALUES (101, 338, 1550, 'Maciej Muzaj');
INSERT INTO public.matches_extended VALUES (102, 337, 1347, 'Miguel Tavares');
INSERT INTO public.matches_extended VALUES (103, 336, 1506, 'Grzegorz Paj─ůk');
INSERT INTO public.matches_extended VALUES (104, 341, 410, 'Pawe┼é Rusin');
INSERT INTO public.matches_extended VALUES (105, 340, 258, 'Andrzej Wrona');
INSERT INTO public.matches_extended VALUES (106, 347, 565, 'Marcin Wali┼äski');
INSERT INTO public.matches_extended VALUES (107, 348, 1010, 'Karol Butryn');
INSERT INTO public.matches_extended VALUES (108, 345, 1400, 'Mateusz Bieniek');
INSERT INTO public.matches_extended VALUES (109, 343, 3667, '┼üukasz Kaczmarek');
INSERT INTO public.matches_extended VALUES (110, 349, 790, 'Tomas Rousseaux');
INSERT INTO public.matches_extended VALUES (111, 346, 1000, 'Nicolas Szersze┼ä');
INSERT INTO public.matches_extended VALUES (112, 344, 1084, 'Tomasz Fornal');
INSERT INTO public.matches_extended VALUES (113, 355, 945, 'Jan Hadrava');
INSERT INTO public.matches_extended VALUES (114, 356, 2210, 'Norbert Huber');
INSERT INTO public.matches_extended VALUES (115, 354, 1000, 'Jakub Kochanowski');
INSERT INTO public.matches_extended VALUES (116, 351, 1443, 'Dawid Konarski');
INSERT INTO public.matches_extended VALUES (117, 352, 1100, 'Bart┼éomiej Bo┼é─ůd┼║');
INSERT INTO public.matches_extended VALUES (118, 350, 350, 'Tomas Rousseaux');
INSERT INTO public.matches_extended VALUES (119, 353, 500, 'Karol Urbanowicz');
INSERT INTO public.matches_extended VALUES (120, 359, 900, 'Tr├ęvor Cl├ęvenot');
INSERT INTO public.matches_extended VALUES (121, 363, 420, 'Uro┼í Kova─Źevi─ç');
INSERT INTO public.matches_extended VALUES (122, 362, 3500, 'Pawe┼é Halaba');
INSERT INTO public.matches_extended VALUES (123, 361, 1100, 'Karol Urbanowicz');
INSERT INTO public.matches_extended VALUES (124, 357, 2073, 'Grzegorz Paj─ůk');
INSERT INTO public.matches_extended VALUES (125, 360, 920, 'Jan Firlej');
INSERT INTO public.matches_extended VALUES (126, 358, 880, 'Aleksandar Atanasijevi─ç');
INSERT INTO public.matches_extended VALUES (127, 370, 896, 'Grzegorz ┼üomacz');
INSERT INTO public.matches_extended VALUES (128, 367, 1150, 'Wassim Ben Tara');
INSERT INTO public.matches_extended VALUES (129, 366, 1250, 'Pawe┼é Rusin');
INSERT INTO public.matches_extended VALUES (130, 365, 375, 'Gonzalo Quiroga');
INSERT INTO public.matches_extended VALUES (131, 364, 810, 'Jan Firlej');
INSERT INTO public.matches_extended VALUES (132, 369, 1900, 'Kamil Semeniuk');
INSERT INTO public.matches_extended VALUES (133, 368, 3900, 'Rafa┼é Szymura');
INSERT INTO public.matches_extended VALUES (134, 371, 3513, 'Dick Kooy');
INSERT INTO public.matches_extended VALUES (135, 372, 1360, 'Sam Deroo');
INSERT INTO public.matches_extended VALUES (136, 377, 559, 'Jan Firlej');
INSERT INTO public.matches_extended VALUES (239, 514, 0, 'Karol K┼éos');
INSERT INTO public.matches_extended VALUES (405, 513, 0, 'Dawid Dryja');
INSERT INTO public.matches_extended VALUES (257, 534, 0, 'Kewin Sasak');
INSERT INTO public.matches_extended VALUES (137, 375, 1500, 'Dawid Konarski');
INSERT INTO public.matches_extended VALUES (138, 374, 850, 'Tomasz Fornal');
INSERT INTO public.matches_extended VALUES (139, 376, 1200, 'Jakub Jarosz');
INSERT INTO public.matches_extended VALUES (140, 373, 800, 'Bart┼éomiej Lipi┼äski');
INSERT INTO public.matches_extended VALUES (141, 378, 376, 'Marcin Wali┼äski');
INSERT INTO public.matches_extended VALUES (142, 384, 2700, 'Robert T├Ąht');
INSERT INTO public.matches_extended VALUES (143, 381, 1453, 'Tr├ęvor Cl├ęvenot');
INSERT INTO public.matches_extended VALUES (144, 380, 410, 'Micah Ma╩╗a');
INSERT INTO public.matches_extended VALUES (145, 382, 1750, '┼üukasz Kaczmarek');
INSERT INTO public.matches_extended VALUES (146, 383, 3850, 'Bart┼éomiej Mordyl');
INSERT INTO public.matches_extended VALUES (147, 379, 1200, 'Jan Firlej');
INSERT INTO public.matches_extended VALUES (148, 385, 3580, 'Maciej Muzaj');
INSERT INTO public.matches_extended VALUES (149, 388, 1220, 'Marcin Janusz');
INSERT INTO public.matches_extended VALUES (150, 387, 299, 'Du┼ían Petkovi─ç');
INSERT INTO public.matches_extended VALUES (151, 389, 987, 'Tomasz Fornal');
INSERT INTO public.matches_extended VALUES (152, 386, 1656, 'Damian Schulz');
INSERT INTO public.matches_extended VALUES (153, 391, 1500, 'Remigiusz Kapica');
INSERT INTO public.matches_extended VALUES (154, 390, 1200, 'Zouheir El Graoui');
INSERT INTO public.matches_extended VALUES (155, 398, 3450, 'Lukas Kampa');
INSERT INTO public.matches_extended VALUES (156, 397, 1318, 'Grzegorz ┼üomacz');
INSERT INTO public.matches_extended VALUES (157, 394, 1511, 'Jan Hadrava');
INSERT INTO public.matches_extended VALUES (158, 395, 1120, 'Marcin Janusz');
INSERT INTO public.matches_extended VALUES (159, 393, 232, 'Grzegorz Bociek');
INSERT INTO public.matches_extended VALUES (160, 396, 1429, 'Uro┼í Kova─Źevi─ç');
INSERT INTO public.matches_extended VALUES (161, 392, 1200, 'Grzegorz Paj─ůk');
INSERT INTO public.matches_extended VALUES (162, 402, 299, 'Jakub Jarosz');
INSERT INTO public.matches_extended VALUES (163, 400, 1250, 'Pawe┼é Halaba');
INSERT INTO public.matches_extended VALUES (164, 401, 643, 'Grzegorz ┼üomacz');
INSERT INTO public.matches_extended VALUES (165, 399, 2569, 'Bart┼éomiej Lipi┼äski');
INSERT INTO public.matches_extended VALUES (166, 405, 1100, 'Marcin Komenda');
INSERT INTO public.matches_extended VALUES (167, 403, 1200, 'Norbert Huber');
INSERT INTO public.matches_extended VALUES (168, 404, 712, 'St├ęphen Boyer');
INSERT INTO public.matches_extended VALUES (169, 412, 1215, 'Bart┼éomiej Lipi┼äski');
INSERT INTO public.matches_extended VALUES (170, 410, 770, 'Grzegorz ┼üomacz');
INSERT INTO public.matches_extended VALUES (171, 408, 1216, 'Marcin Wali┼äski');
INSERT INTO public.matches_extended VALUES (172, 411, 1481, 'Maciej Muzaj');
INSERT INTO public.matches_extended VALUES (173, 407, 2000, 'Jan Hadrava');
INSERT INTO public.matches_extended VALUES (174, 409, 950, 'Jan Firlej');
INSERT INTO public.matches_extended VALUES (175, 406, 1200, 'Marcin Komenda');
INSERT INTO public.matches_extended VALUES (176, 414, 1025, 'Micah Ma╩╗a');
INSERT INTO public.matches_extended VALUES (177, 418, 299, 'Marcin Komenda');
INSERT INTO public.matches_extended VALUES (178, 417, 824, 'Robert T├Ąht');
INSERT INTO public.matches_extended VALUES (179, 413, 1475, 'Facundo Conte');
INSERT INTO public.matches_extended VALUES (180, 416, 1200, 'Sam Deroo');
INSERT INTO public.matches_extended VALUES (181, 419, 2987, '┼üukasz Kaczmarek');
INSERT INTO public.matches_extended VALUES (182, 415, 3800, '┼üukasz Kozub');
INSERT INTO public.matches_extended VALUES (258, 533, 0, 'Klemen ─îebulj');
INSERT INTO public.matches_extended VALUES (259, 532, 0, 'Kamil Kwasowski');
INSERT INTO public.matches_extended VALUES (260, 531, 0, 'Tomas Rousseaux');
INSERT INTO public.matches_extended VALUES (261, 544, 0, 'Jan Firlej');
INSERT INTO public.matches_extended VALUES (262, 543, 0, 'Wojciech ┼╗ali┼äski');
INSERT INTO public.matches_extended VALUES (263, 542, 0, 'Marcin Janusz');
INSERT INTO public.matches_extended VALUES (264, 541, 0, 'Mateusz Malinowski');
INSERT INTO public.matches_extended VALUES (265, 540, 0, 'Ronald Jimenez');
INSERT INTO public.matches_extended VALUES (435, 539, 0, 'Artur Szalpuk');
INSERT INTO public.matches_extended VALUES (266, 538, 0, 'Kamil Semeniuk');
INSERT INTO public.matches_extended VALUES (267, 551, 0, 'Jakub Jarosz');
INSERT INTO public.matches_extended VALUES (268, 545, 0, 'Wojciech ┼╗ali┼äski');
INSERT INTO public.matches_extended VALUES (269, 546, 0, 'Bart┼éomiej Lipi┼äski');
INSERT INTO public.matches_extended VALUES (270, 547, 0, 'Mohammed Al Hachdadi');
INSERT INTO public.matches_extended VALUES (271, 548, 0, 'Bartosz Filipiak');
INSERT INTO public.matches_extended VALUES (442, 549, 0, 'Andrzej Wrona');
INSERT INTO public.matches_extended VALUES (272, 550, 0, 'Kamil Semeniuk');
INSERT INTO public.matches_extended VALUES (444, 552, 0, 'Igor Grobelny');
INSERT INTO public.matches_extended VALUES (273, 553, 0, 'Aleksander ┼Üliwka');
INSERT INTO public.matches_extended VALUES (274, 554, 0, 'Jakub Bucki');
INSERT INTO public.matches_extended VALUES (275, 555, 0, 'Mariusz Wlaz┼éy');
INSERT INTO public.matches_extended VALUES (276, 556, 0, 'Piotr Orczyk');
INSERT INTO public.matches_extended VALUES (277, 557, 0, 'Fabian Drzyzga');
INSERT INTO public.matches_extended VALUES (278, 558, 0, 'Joshua Tuaniga');
INSERT INTO public.matches_extended VALUES (451, 565, 0, 'Du┼ían Petkovi─ç');
INSERT INTO public.matches_extended VALUES (279, 564, 0, 'Jakub Kochanowski');
INSERT INTO public.matches_extended VALUES (280, 563, 0, 'Maciej Olenderek');
INSERT INTO public.matches_extended VALUES (281, 562, 0, 'Ronald Jimenez');
INSERT INTO public.matches_extended VALUES (282, 561, 0, 'Kamil Kwasowski');
INSERT INTO public.matches_extended VALUES (283, 560, 0, 'Bart┼éomiej Bo┼é─ůd┼║');
INSERT INTO public.matches_extended VALUES (284, 559, 0, 'Micha┼é K─Ödzierski');
INSERT INTO public.matches_extended VALUES (285, 572, 0, 'Karol Butryn');
INSERT INTO public.matches_extended VALUES (286, 571, 0, 'Garrett Muagututia');
INSERT INTO public.matches_extended VALUES (287, 570, 0, 'Kamil Kwasowski');
INSERT INTO public.matches_extended VALUES (288, 569, 0, 'Ruben Schott');
INSERT INTO public.matches_extended VALUES (289, 568, 0, 'Kamil Semeniuk');
INSERT INTO public.matches_extended VALUES (463, 567, 0, 'Lukas Kampa');
INSERT INTO public.matches_extended VALUES (290, 566, 0, 'Maciej Zajder');
INSERT INTO public.matches_extended VALUES (291, 579, 0, 'Rafa┼é Szymura');
INSERT INTO public.matches_extended VALUES (466, 578, 0, 'Marcin Janusz');
INSERT INTO public.matches_extended VALUES (292, 577, 0, 'Benjamin Toniutti');
INSERT INTO public.matches_extended VALUES (293, 576, 0, 'Mi┼éosz Zniszczo┼é');
INSERT INTO public.matches_extended VALUES (294, 575, 0, 'Joshua Tuaniga');
INSERT INTO public.matches_extended VALUES (295, 574, 0, 'Piotr Orczyk');
INSERT INTO public.matches_extended VALUES (296, 573, 0, 'Pawe┼é Woicki');
INSERT INTO public.matches_extended VALUES (297, 584, 0, 'Bart┼éomiej Bo┼é─ůd┼║');
INSERT INTO public.matches_extended VALUES (298, 586, 0, 'Fabian Drzyzga');
INSERT INTO public.matches_extended VALUES (474, 582, 0, 'Andrzej Wrona');
INSERT INTO public.matches_extended VALUES (299, 583, 0, 'Bart┼éomiej Kluth');
INSERT INTO public.matches_extended VALUES (300, 585, 0, 'Szymon Jakubiszak');
INSERT INTO public.matches_extended VALUES (301, 581, 0, 'Bart┼éomiej Lipi┼äski');
INSERT INTO public.matches_extended VALUES (302, 580, 0, '┼üukasz ┼üapszy┼äski');
INSERT INTO public.matches_extended VALUES (303, 593, 0, 'Jurij H┼éadyr');
INSERT INTO public.matches_extended VALUES (304, 592, 0, 'Taylor Sander');
INSERT INTO public.matches_extended VALUES (481, 591, 0, 'Piotr Nowakowski');
INSERT INTO public.matches_extended VALUES (305, 590, 0, 'Jakub Kochanowski');
INSERT INTO public.matches_extended VALUES (306, 589, 0, 'Micha┼é K─Ödzierski');
INSERT INTO public.matches_extended VALUES (307, 588, 0, 'Karol Butryn');
INSERT INTO public.matches_extended VALUES (308, 587, 0, 'Piotr Orczyk');
INSERT INTO public.matches_extended VALUES (309, 594, 0, 'Moritz Reichert');
INSERT INTO public.matches_extended VALUES (310, 595, 0, 'Jurij H┼éadyr');
INSERT INTO public.matches_extended VALUES (311, 596, 0, 'Taylor Sander');
INSERT INTO public.matches_extended VALUES (489, 597, 0, 'Piotr Nowakowski');
INSERT INTO public.matches_extended VALUES (312, 598, 0, 'Pawe┼é Zatorski');
INSERT INTO public.matches_extended VALUES (313, 599, 0, 'Rafa┼é Buszek');
INSERT INTO public.matches_extended VALUES (314, 600, 0, 'Ronald Jimenez');
INSERT INTO public.matches_extended VALUES (315, 607, 0, 'J─Ödrzej Gruszczy┼äski');
INSERT INTO public.matches_extended VALUES (316, 606, 0, 'Rafa┼é Szymura');
INSERT INTO public.matches_extended VALUES (317, 605, 0, 'Grzegorz ┼üomacz');
INSERT INTO public.matches_extended VALUES (496, 604, 0, 'Jan Fornal');
INSERT INTO public.matches_extended VALUES (318, 603, 0, '┼üukasz Kaczmarek');
INSERT INTO public.matches_extended VALUES (319, 602, 0, 'Fl├ívio Gualberto');
INSERT INTO public.matches_extended VALUES (320, 601, 0, 'Miguel Tavares');
INSERT INTO public.matches_extended VALUES (321, 608, 0, 'Bartosz Bu─çko');
INSERT INTO public.matches_extended VALUES (322, 609, 0, 'Mariusz Wlaz┼éy');
INSERT INTO public.matches_extended VALUES (323, 610, 0, 'Micha┼é Gier┼╝ot');
INSERT INTO public.matches_extended VALUES (324, 611, 0, 'Taylor Sander');
INSERT INTO public.matches_extended VALUES (504, 612, 0, 'Karol Butryn');
INSERT INTO public.matches_extended VALUES (325, 613, 0, 'Mateusz Malinowski');
INSERT INTO public.matches_extended VALUES (326, 614, 0, 'Dawid Gunia');
INSERT INTO public.matches_extended VALUES (327, 616, 0, 'Ronald Jimenez');
INSERT INTO public.matches_extended VALUES (508, 617, 0, 'Igor Grobelny');
INSERT INTO public.matches_extended VALUES (328, 618, 0, 'Karol Butryn');
INSERT INTO public.matches_extended VALUES (329, 619, 0, 'Tomasz Fornal');
INSERT INTO public.matches_extended VALUES (330, 620, 0, 'Joshua Tuaniga');
INSERT INTO public.matches_extended VALUES (331, 621, 0, 'Wiktor Musia┼é');
INSERT INTO public.matches_extended VALUES (332, 615, 0, 'Kamil D┼éugosz');
INSERT INTO public.matches_extended VALUES (514, 628, 0, 'Krzysztof Rejno');
INSERT INTO public.matches_extended VALUES (333, 627, 0, 'Mateusz Bieniek');
INSERT INTO public.matches_extended VALUES (334, 626, 0, 'Mohammed Al Hachdadi');
INSERT INTO public.matches_extended VALUES (183, 447, 1252, '┼üukasz Kaczmarek');
INSERT INTO public.matches_extended VALUES (340, 448, 350, 'Piotr Nowakowski');
INSERT INTO public.matches_extended VALUES (184, 449, 460, 'Norbert Huber');
INSERT INTO public.matches_extended VALUES (185, 450, 750, 'Tomasz Fornal');
INSERT INTO public.matches_extended VALUES (186, 451, 0, 'Timo Tammemaa');
INSERT INTO public.matches_extended VALUES (187, 452, 700, 'Dawid Konarski');
INSERT INTO public.matches_extended VALUES (188, 453, 1175, 'Mi┼éosz Zniszczo┼é');
INSERT INTO public.matches_extended VALUES (189, 459, 276, 'Jakub Jarosz');
INSERT INTO public.matches_extended VALUES (190, 460, 850, 'Bart┼éomiej Bo┼é─ůd┼║');
INSERT INTO public.matches_extended VALUES (191, 454, 700, 'Mariusz Wlaz┼éy');
INSERT INTO public.matches_extended VALUES (192, 455, 873, 'Mohammed Al Hachdadi');
INSERT INTO public.matches_extended VALUES (193, 456, 638, 'Mateusz Malinowski');
INSERT INTO public.matches_extended VALUES (351, 457, 390, 'Artur Szalpuk');
INSERT INTO public.matches_extended VALUES (194, 458, 480, 'Kamil Semeniuk');
INSERT INTO public.matches_extended VALUES (353, 461, 0, 'Bartosz Kwolek');
INSERT INTO public.matches_extended VALUES (195, 462, 563, 'Aleksander ┼Üliwka');
INSERT INTO public.matches_extended VALUES (196, 463, 360, 'Mohammed Al Hachdadi');
INSERT INTO public.matches_extended VALUES (197, 464, 1600, 'Bart┼éomiej Lipi┼äski');
INSERT INTO public.matches_extended VALUES (198, 465, 714, 'Maximiliano Cavanna');
INSERT INTO public.matches_extended VALUES (199, 466, 326, 'Klemen ─îebulj');
INSERT INTO public.matches_extended VALUES (200, 467, 0, 'Bart┼éomiej Bo┼é─ůd┼║');
INSERT INTO public.matches_extended VALUES (201, 468, 1250, 'Brenden Sander');
INSERT INTO public.matches_extended VALUES (202, 469, 0, 'Bart┼éomiej Bo┼é─ůd┼║');
INSERT INTO public.matches_extended VALUES (203, 470, 617, 'Maximiliano Cavanna');
INSERT INTO public.matches_extended VALUES (204, 471, 290, 'Damian Schulz');
INSERT INTO public.matches_extended VALUES (205, 472, 240, 'Bart┼éomiej Lipi┼äski');
INSERT INTO public.matches_extended VALUES (206, 473, 980, 'Kamil Semeniuk');
INSERT INTO public.matches_extended VALUES (366, 474, 0, 'Micha┼é Superlak');
INSERT INTO public.matches_extended VALUES (207, 475, 219, 'Bartosz Filipiak');
INSERT INTO public.matches_extended VALUES (368, 476, 0, 'Igor Grobelny');
INSERT INTO public.matches_extended VALUES (208, 477, 0, '┼üukasz Kaczmarek');
INSERT INTO public.matches_extended VALUES (209, 479, 0, 'Przemys┼éaw Smoli┼äski');
INSERT INTO public.matches_extended VALUES (210, 480, 0, 'Garrett Muagututia');
INSERT INTO public.matches_extended VALUES (211, 481, 700, 'Karol Butryn');
INSERT INTO public.matches_extended VALUES (212, 478, 0, 'Wojciech ┼╗ali┼äski');
INSERT INTO public.matches_extended VALUES (213, 482, 450, 'Karol Butryn');
INSERT INTO public.matches_extended VALUES (214, 483, 375, 'Fl├ívio Gualberto');
INSERT INTO public.matches_extended VALUES (215, 484, 250, 'K├ęvin Klinkenberg');
INSERT INTO public.matches_extended VALUES (216, 485, 0, 'Mi┼éosz Zniszczo┼é');
INSERT INTO public.matches_extended VALUES (217, 486, 560, 'Aleksander ┼Üliwka');
INSERT INTO public.matches_extended VALUES (379, 487, 0, 'Bart┼éomiej Lipi┼äski');
INSERT INTO public.matches_extended VALUES (218, 488, 0, 'Jakub Popiwczak');
INSERT INTO public.matches_extended VALUES (219, 489, 0, 'Mohammed Al Hachdadi');
INSERT INTO public.matches_extended VALUES (220, 490, 0, 'Milan Kati─ç');
INSERT INTO public.matches_extended VALUES (383, 491, 238, 'Damian Schulz');
INSERT INTO public.matches_extended VALUES (221, 492, 0, '┼üukasz Kaczmarek');
INSERT INTO public.matches_extended VALUES (222, 493, 0, 'Bart┼éomiej Bo┼é─ůd┼║');
INSERT INTO public.matches_extended VALUES (223, 494, 0, 'Micha┼é K─Ödzierski');
INSERT INTO public.matches_extended VALUES (224, 495, 0, 'Klemen ─îebulj');
INSERT INTO public.matches_extended VALUES (225, 502, 0, 'Mohammed Al Hachdadi');
INSERT INTO public.matches_extended VALUES (226, 501, 0, 'Norbert Huber');
INSERT INTO public.matches_extended VALUES (390, 500, 0, 'Piotr Nowakowski');
INSERT INTO public.matches_extended VALUES (227, 499, 0, '┼üukasz Kaczmarek');
INSERT INTO public.matches_extended VALUES (228, 498, 0, 'Dawid Konarski');
INSERT INTO public.matches_extended VALUES (229, 497, 0, 'Miguel Tavares');
INSERT INTO public.matches_extended VALUES (230, 496, 0, 'Wassim Ben Tara');
INSERT INTO public.matches_extended VALUES (231, 509, 0, 'Mateusz Malinowski');
INSERT INTO public.matches_extended VALUES (232, 508, 0, 'Karol Butryn');
INSERT INTO public.matches_extended VALUES (233, 507, 0, 'Aleksander ┼Üliwka');
INSERT INTO public.matches_extended VALUES (398, 506, 0, 'Igor Grobelny');
INSERT INTO public.matches_extended VALUES (234, 505, 0, 'Milad Ebadipur');
INSERT INTO public.matches_extended VALUES (235, 504, 0, 'Damian Schulz');
INSERT INTO public.matches_extended VALUES (236, 503, 0, 'Bart┼éomiej Lipi┼äski');
INSERT INTO public.matches_extended VALUES (237, 516, 0, '┼üukasz Kozub');
INSERT INTO public.matches_extended VALUES (238, 515, 0, 'Tomasz Fornal');
INSERT INTO public.matches_extended VALUES (703, 658, 1500, 'Lukas Kampa');
INSERT INTO public.matches_extended VALUES (704, 656, 1456, 'Aleksander ┼Üliwka');
INSERT INTO public.matches_extended VALUES (705, 657, 650, 'Karol Butryn');
INSERT INTO public.matches_extended VALUES (706, 655, 3935, 'Bart┼éomiej Lipi┼äski');
INSERT INTO public.matches_extended VALUES (707, 666, 1952, 'Kacper Piechocki');
INSERT INTO public.matches_extended VALUES (762, 743, 600, 'Marcin Komenda');
INSERT INTO public.matches_extended VALUES (897, 740, 5588, 'Niko┼éaj Penczew');
INSERT INTO public.matches_extended VALUES (763, 742, 1500, 'Micha┼é Filip');
INSERT INTO public.matches_extended VALUES (764, 739, 1274, 'Maciej Gorzkiewicz');
INSERT INTO public.matches_extended VALUES (900, 741, 2400, 'Christian Fromm');
INSERT INTO public.matches_extended VALUES (765, 749, 1500, 'Micha┼é Filip');
INSERT INTO public.matches_extended VALUES (902, 750, 1500, 'Marcin Wali┼äski');
INSERT INTO public.matches_extended VALUES (766, 745, 1429, 'Pawe┼é Zatorski');
INSERT INTO public.matches_extended VALUES (767, 748, 1200, 'Karol Butryn');
INSERT INTO public.matches_extended VALUES (768, 747, 350, 'Mi┼éosz Zniszczo┼é');
INSERT INTO public.matches_extended VALUES (769, 746, 3400, 'Mariusz Wlaz┼éy');
INSERT INTO public.matches_extended VALUES (907, 751, 1500, 'Kamil Semeniuk');
INSERT INTO public.matches_extended VALUES (770, 753, 1063, 'Masahiro Yanagida');
INSERT INTO public.matches_extended VALUES (771, 755, 2390, 'Pawe┼é Woicki');
INSERT INTO public.matches_extended VALUES (910, 752, 4128, 'Damian Wojtaszek');
INSERT INTO public.matches_extended VALUES (772, 754, 2667, 'Lukas Kampa');
INSERT INTO public.matches_extended VALUES (773, 756, 2500, 'Micha┼é Koz┼éowski');
INSERT INTO public.matches_extended VALUES (774, 757, 2075, 'Maciej Muzaj');
INSERT INTO public.matches_extended VALUES (775, 760, 1000, 'Thibault Rossard');
INSERT INTO public.matches_extended VALUES (915, 761, 3500, 'Bartosz Kurek');
INSERT INTO public.matches_extended VALUES (776, 758, 1583, 'Pawe┼é Zatorski');
INSERT INTO public.matches_extended VALUES (777, 759, 2366, 'Jakub Bucki');
INSERT INTO public.matches_extended VALUES (918, 762, 1500, 'Wojciech ┼╗ali┼äski');
INSERT INTO public.matches_extended VALUES (919, 764, 3200, 'Tomas Rousseaux');
INSERT INTO public.matches_extended VALUES (778, 767, 3112, 'Pawe┼é Zatorski');
INSERT INTO public.matches_extended VALUES (793, 782, 2031, 'Jan Hadrava');
INSERT INTO public.matches_extended VALUES (1432, 840, 1556, 'Michal Masn├Ż');
INSERT INTO public.matches_extended VALUES (1830, 1097, 4150, '┼üukasz Wi┼Ťniewski');
INSERT INTO public.matches_extended VALUES (1831, 1102, 980, 'Salvador Hidalgo Oliva');
INSERT INTO public.matches_extended VALUES (1433, 842, 1300, 'Marcin Komenda');
INSERT INTO public.matches_extended VALUES (1434, 837, 1500, 'Benjamin Toniutti');
INSERT INTO public.matches_extended VALUES (1832, 1103, 760, 'Micha┼é B┼éo┼äski');
INSERT INTO public.matches_extended VALUES (733, 693, 4045, 'Sam Deroo');
INSERT INTO public.matches_extended VALUES (853, 695, 1420, 'Rafael Rodrigues de Ara├║jo');
INSERT INTO public.matches_extended VALUES (734, 696, 1500, 'Dejan Vin─Źi─ç');
INSERT INTO public.matches_extended VALUES (735, 701, 4918, 'Damian Schulz');
INSERT INTO public.matches_extended VALUES (736, 700, 1601, 'Benjamin Toniutti');
INSERT INTO public.matches_extended VALUES (857, 699, 2437, 'Milad Ebadipur');
INSERT INTO public.matches_extended VALUES (737, 697, 1985, 'Raphael Margarido');
INSERT INTO public.matches_extended VALUES (738, 702, 2368, 'Julien Lyneel');
INSERT INTO public.matches_extended VALUES (860, 698, 1450, 'Bartosz Gawryszewski');
INSERT INTO public.matches_extended VALUES (739, 708, 1500, 'Maksim ┼╗yga┼éow');
INSERT INTO public.matches_extended VALUES (740, 704, 3937, 'Serhij Kape┼éu┼Ť');
INSERT INTO public.matches_extended VALUES (1464, 887, 1500, 'Mariusz Wlaz┼éy');
INSERT INTO public.matches_extended VALUES (863, 707, 1500, 'Marcin Wali┼äski');
INSERT INTO public.matches_extended VALUES (1859, 1131, 1600, 'Dawid Konarski');
INSERT INTO public.matches_extended VALUES (741, 705, 950, 'Maciej Muzaj');
INSERT INTO public.matches_extended VALUES (742, 703, 1739, 'Micha┼é Szalacha');
INSERT INTO public.matches_extended VALUES (1860, 1143, 2700, 'Micha┼é Winiarski');
INSERT INTO public.matches_extended VALUES (866, 706, 4385, 'Sam Deroo');
INSERT INTO public.matches_extended VALUES (867, 712, 2900, 'Piotr ┼üukasik');
INSERT INTO public.matches_extended VALUES (743, 714, 2462, 'Julien Lyneel');
INSERT INTO public.matches_extended VALUES (869, 711, 1852, 'Sam Deroo');
INSERT INTO public.matches_extended VALUES (744, 710, 2410, 'Grzegorz ┼üomacz');
INSERT INTO public.matches_extended VALUES (745, 713, 1874, 'Igor Grobelny');
INSERT INTO public.matches_extended VALUES (746, 709, 1020, 'Tomas Rousseaux');
INSERT INTO public.matches_extended VALUES (747, 719, 1500, '┼üukasz Kaczmarek');
INSERT INTO public.matches_extended VALUES (748, 716, 3423, 'Bart┼éomiej Lema┼äski');
INSERT INTO public.matches_extended VALUES (750, 720, 1150, 'Tomas Rousseaux');
INSERT INTO public.matches_extended VALUES (878, 717, 4525, 'Bartosz Kurek');
INSERT INTO public.matches_extended VALUES (751, 722, 1186, 'Sam Deroo');
INSERT INTO public.matches_extended VALUES (880, 724, 1682, 'Kamil Semeniuk');
INSERT INTO public.matches_extended VALUES (752, 723, 2150, 'Maksim ┼╗yga┼éow');
INSERT INTO public.matches_extended VALUES (882, 725, 2811, 'Bartosz Kwolek');
INSERT INTO public.matches_extended VALUES (753, 726, 2547, 'David Smith');
INSERT INTO public.matches_extended VALUES (754, 721, 1074, 'Bartosz Filipiak');
INSERT INTO public.matches_extended VALUES (755, 729, 1500, 'Damian Schulz');
INSERT INTO public.matches_extended VALUES (886, 728, 1500, 'Michal Masn├Ż');
INSERT INTO public.matches_extended VALUES (887, 727, 3058, 'Piotr ┼üukasik');
INSERT INTO public.matches_extended VALUES (756, 732, 2460, 'Aleksander ┼Üliwka');
INSERT INTO public.matches_extended VALUES (757, 730, 2206, 'Dawid Konarski');
INSERT INTO public.matches_extended VALUES (758, 731, 1000, 'Maciej Muzaj');
INSERT INTO public.matches_extended VALUES (891, 738, 1058, 'Bartosz Kwolek');
INSERT INTO public.matches_extended VALUES (759, 734, 1003, 'Pawe┼é Zatorski');
INSERT INTO public.matches_extended VALUES (760, 736, 2920, 'Julien Lyneel');
INSERT INTO public.matches_extended VALUES (894, 737, 3125, 'Michal Masn├Ż');
INSERT INTO public.matches_extended VALUES (761, 744, 1450, 'Jakub Kochanowski');
INSERT INTO public.matches_extended VALUES (240, 512, 0, 'Karol Butryn');
INSERT INTO public.matches_extended VALUES (241, 511, 0, 'Maximiliano Cavanna');
INSERT INTO public.matches_extended VALUES (242, 510, 0, 'Ronald Jimenez');
INSERT INTO public.matches_extended VALUES (243, 523, 0, 'Rafa┼é Faryna');
INSERT INTO public.matches_extended VALUES (244, 522, 0, 'Jakub Kochanowski');
INSERT INTO public.matches_extended VALUES (245, 520, 0, 'Du┼ían Petkovi─ç');
INSERT INTO public.matches_extended VALUES (246, 519, 0, 'Jakub Popiwczak');
INSERT INTO public.matches_extended VALUES (247, 518, 0, 'Mi┼éosz Zniszczo┼é');
INSERT INTO public.matches_extended VALUES (248, 517, 0, 'Damian Schulz');
INSERT INTO public.matches_extended VALUES (415, 521, 0, 'Bartosz Kwolek');
INSERT INTO public.matches_extended VALUES (249, 524, 0, 'Jos├ę Ademar Santana');
INSERT INTO public.matches_extended VALUES (250, 525, 0, 'Aleksander ┼Üliwka');
INSERT INTO public.matches_extended VALUES (418, 526, 0, 'Mateusz Malinowski');
INSERT INTO public.matches_extended VALUES (251, 527, 0, 'Klemen ─îebulj');
INSERT INTO public.matches_extended VALUES (252, 528, 0, 'Mohammed Al Hachdadi');
INSERT INTO public.matches_extended VALUES (253, 529, 0, 'Pablo Crer');
INSERT INTO public.matches_extended VALUES (254, 530, 0, 'Wojciech ┼╗ali┼äski');
INSERT INTO public.matches_extended VALUES (423, 537, 0, 'Jakub Kochanowski');
INSERT INTO public.matches_extended VALUES (255, 536, 0, 'Kacper Piechocki');
INSERT INTO public.matches_extended VALUES (256, 535, 0, 'Jurij H┼éadyr');
INSERT INTO public.matches_extended VALUES (1861, 1137, 1950, 'Leo Andri─ç');
INSERT INTO public.matches_extended VALUES (1863, 1139, 1300, 'Rafael Rodrigues de Ara├║jo');
INSERT INTO public.matches_extended VALUES (1864, 1140, 2800, 'Dawid Konarski');
INSERT INTO public.matches_extended VALUES (1865, 1141, 4000, 'Marko Ivovi─ç');
INSERT INTO public.matches_extended VALUES (1465, 886, 1365, 'Michal Masn├Ż');
INSERT INTO public.matches_extended VALUES (1468, 885, 2400, 'Jan Hadrava');
INSERT INTO public.matches_extended VALUES (1866, 1147, 3000, 'Salvador Hidalgo Oliva');
INSERT INTO public.matches_extended VALUES (1469, 898, 2700, 'Bart┼éomiej Kluth');
INSERT INTO public.matches_extended VALUES (1470, 899, 4087, 'Micha┼é K─Ödzierski');
INSERT INTO public.matches_extended VALUES (1867, 1145, 3350, 'Mariusz Wlaz┼éy');
INSERT INTO public.matches_extended VALUES (1868, 1151, 1100, 'Pawe┼é Adamajtis');
INSERT INTO public.matches_extended VALUES (1871, 1148, 1500, 'Sam Deroo');
INSERT INTO public.matches_extended VALUES (1872, 1159, 3000, 'Michal Masn├Ż');
INSERT INTO public.matches_extended VALUES (1873, 1158, 2700, 'Nicol├ís Uriarte');
INSERT INTO public.matches_extended VALUES (335, 625, 0, 'Marcin Janusz');
INSERT INTO public.matches_extended VALUES (336, 624, 0, 'Javier Concepci├│n');
INSERT INTO public.matches_extended VALUES (337, 623, 0, 'Dawid Konarski');
INSERT INTO public.matches_extended VALUES (338, 622, 0, 'Bart┼éomiej Bo┼é─ůd┼║');
INSERT INTO public.matches_extended VALUES (813, 660, 3285, 'Andrzej Wrona');
INSERT INTO public.matches_extended VALUES (814, 659, 1500, 'Kamil Semeniuk');
INSERT INTO public.matches_extended VALUES (708, 664, 1500, 'Piotr Hain');
INSERT INTO public.matches_extended VALUES (711, 665, 3700, 'Maciej Muzaj');
INSERT INTO public.matches_extended VALUES (1520, 979, 1080, 'Kamil Kwasowski');
INSERT INTO public.matches_extended VALUES (824, 662, 3500, 'Rafael Rodrigues de Ara├║jo');
INSERT INTO public.matches_extended VALUES (712, 667, 1595, 'Benjamin Toniutti');
INSERT INTO public.matches_extended VALUES (713, 668, 2293, 'Milad Ebadipur');
INSERT INTO public.matches_extended VALUES (714, 669, 1738, 'Jan Hadrava');
INSERT INTO public.matches_extended VALUES (715, 671, 1504, 'Wojciech ┼╗ali┼äski');
INSERT INTO public.matches_extended VALUES (829, 672, 2247, 'Rafael Rodrigues de Ara├║jo');
INSERT INTO public.matches_extended VALUES (716, 670, 3362, 'Karol Butryn');
INSERT INTO public.matches_extended VALUES (717, 675, 700, 'Igor Grobelny');
INSERT INTO public.matches_extended VALUES (832, 674, 1500, 'Wojciech ┼╗ali┼äski');
INSERT INTO public.matches_extended VALUES (718, 677, 2142, 'Jan Hadrava');
INSERT INTO public.matches_extended VALUES (834, 673, 2736, 'Mateusz Malinowski');
INSERT INTO public.matches_extended VALUES (719, 678, 3000, '┼üukasz Kaczmarek');
INSERT INTO public.matches_extended VALUES (720, 676, 1280, 'Lukas Kampa');
INSERT INTO public.matches_extended VALUES (721, 680, 2399, 'Mateusz Bieniek');
INSERT INTO public.matches_extended VALUES (722, 681, 3087, 'Julien Lyneel');
INSERT INTO public.matches_extended VALUES (723, 682, 3653, 'Lincoln Williams');
INSERT INTO public.matches_extended VALUES (840, 684, 1500, 'Maksim ┼╗yga┼éow');
INSERT INTO public.matches_extended VALUES (724, 679, 1250, 'Maciej Olenderek');
INSERT INTO public.matches_extended VALUES (842, 683, 2000, 'Antoine Brizard');
INSERT INTO public.matches_extended VALUES (725, 690, 2100, 'Maciej Muzaj');
INSERT INTO public.matches_extended VALUES (726, 686, 2010, 'Mariusz Wlaz┼éy');
INSERT INTO public.matches_extended VALUES (729, 689, 2110, 'Pawe┼é Zatorski');
INSERT INTO public.matches_extended VALUES (730, 692, 2517, 'Dawid Konarski');
INSERT INTO public.matches_extended VALUES (731, 694, 2358, 'Jakub Kochanowski');
INSERT INTO public.matches_extended VALUES (732, 691, 1839, 'Pawe┼é Woicki');
INSERT INTO public.matches_extended VALUES (1922, 1220, 1200, 'Rafa┼é Soba┼äski');
INSERT INTO public.matches_extended VALUES (1521, 975, 800, 'Tomas Rousseaux');
INSERT INTO public.matches_extended VALUES (1730, 978, 1020, 'Jakub Peszko');
INSERT INTO public.matches_extended VALUES (1500, 946, 1542, 'Nikola ă┤orăÁiev');
INSERT INTO public.matches_extended VALUES (1501, 945, 1800, 'Jan Hadrava');
INSERT INTO public.matches_extended VALUES (1503, 940, 3200, 'Benjamin Toniutti');
INSERT INTO public.matches_extended VALUES (1699, 943, 1541, 'Bart┼éomiej Kluth');
INSERT INTO public.matches_extended VALUES (1504, 942, 1500, 'Grzegorz Paj─ůk');
INSERT INTO public.matches_extended VALUES (1499, 948, 1127, 'Tyler Sanders');
INSERT INTO public.matches_extended VALUES (1505, 950, 430, 'Keith Pupart');
INSERT INTO public.matches_extended VALUES (1506, 954, 850, 'Grzegorz Bociek');
INSERT INTO public.matches_extended VALUES (1705, 952, 3580, 'Aleksander ┼Üliwka');
INSERT INTO public.matches_extended VALUES (1507, 955, 3000, 'Pawe┼é Zatorski');
INSERT INTO public.matches_extended VALUES (1707, 953, 2457, 'Salvador Hidalgo Oliva');
INSERT INTO public.matches_extended VALUES (1508, 951, 2800, 'Wojciech W┼éodarczyk');
INSERT INTO public.matches_extended VALUES (1510, 956, 5500, 'Mariusz Wlaz┼éy');
INSERT INTO public.matches_extended VALUES (1711, 959, 1200, 'Andrzej Wrona');
INSERT INTO public.matches_extended VALUES (1511, 958, 800, 'Lukas Kampa');
INSERT INTO public.matches_extended VALUES (1514, 961, 1316, 'Dawid Gunia');
INSERT INTO public.matches_extended VALUES (1717, 960, 1500, 'Pawe┼é Woicki');
INSERT INTO public.matches_extended VALUES (1515, 967, 1515, '┼üukasz Kaczmarek');
INSERT INTO public.matches_extended VALUES (1516, 970, 3052, 'Maurice Torres');
INSERT INTO public.matches_extended VALUES (1721, 965, 1270, 'Bartosz Filipiak');
INSERT INTO public.matches_extended VALUES (1517, 969, 3118, 'Aleksander ┼Üliwka');
INSERT INTO public.matches_extended VALUES (1518, 964, 2065, 'Wojciech W┼éodarczyk');
INSERT INTO public.matches_extended VALUES (1519, 971, 1500, 'Grzegorz Bociek');
INSERT INTO public.matches_extended VALUES (1725, 968, 1800, 'Pawe┼é Woicki');
INSERT INTO public.matches_extended VALUES (1726, 976, 1316, '┼üukasz Kaczmarek');
INSERT INTO public.matches_extended VALUES (1522, 973, 2463, 'Maciej Muzaj');
INSERT INTO public.matches_extended VALUES (1523, 974, 2100, 'Aleksander ┼Üliwka');
INSERT INTO public.matches_extended VALUES (1524, 972, 2100, 'Damian Schulz');
INSERT INTO public.matches_extended VALUES (1525, 980, 1630, 'Bartosz Filipiak');
INSERT INTO public.matches_extended VALUES (1526, 985, 2400, 'Mateusz Bieniek');
INSERT INTO public.matches_extended VALUES (1527, 987, 1680, 'Maciej Muzaj');
INSERT INTO public.matches_extended VALUES (1528, 984, 1273, 'Michal Masn├Ż');
INSERT INTO public.matches_extended VALUES (1529, 981, 2130, 'Jan Nowakowski');
INSERT INTO public.matches_extended VALUES (1530, 986, 4304, 'Mariusz Wlaz┼éy');
INSERT INTO public.matches_extended VALUES (1741, 983, 1500, 'Kamil Kwasowski');
INSERT INTO public.matches_extended VALUES (1742, 994, 1485, 'Wojciech W┼éodarczyk');
INSERT INTO public.matches_extended VALUES (1531, 988, 3700, 'Artur Szalpuk');
INSERT INTO public.matches_extended VALUES (1532, 990, 2044, 'Sre─çko Lisinac');
INSERT INTO public.matches_extended VALUES (1533, 989, 1500, 'Aleksander ┼Üliwka');
INSERT INTO public.matches_extended VALUES (1926, 1218, 1400, 'Sre─çko Lisinac');
INSERT INTO public.matches_extended VALUES (1927, 1230, 2700, 'Mariusz Wlaz┼éy');
INSERT INTO public.matches_extended VALUES (1928, 1226, 700, 'Bartosz Janeczek');
INSERT INTO public.matches_extended VALUES (1930, 1231, 3500, 'Mateusz Mas┼éowski');
INSERT INTO public.matches_extended VALUES (1931, 1225, 600, 'Pawe┼é Woicki');
INSERT INTO public.matches_extended VALUES (1932, 1229, 1950, 'Dmytro Paszycki');
INSERT INTO public.matches_extended VALUES (1591, 839, 1800, 'Jan Hadrava');
INSERT INTO public.matches_extended VALUES (779, 765, 1188, 'Maciej Gorzkiewicz');
INSERT INTO public.matches_extended VALUES (1594, 843, 2120, 'Wojciech W┼éodarczyk');
INSERT INTO public.matches_extended VALUES (1435, 838, 1617, 'Jason De Rocco');
INSERT INTO public.matches_extended VALUES (1436, 836, 2165, 'Milad Ebadipur');
INSERT INTO public.matches_extended VALUES (1598, 848, 620, '┼üukasz Kaczmarek');
INSERT INTO public.matches_extended VALUES (1437, 849, 2700, 'Piotr Nowakowski');
INSERT INTO public.matches_extended VALUES (1439, 846, 1150, 'Dmytro Teriomenko');
INSERT INTO public.matches_extended VALUES (1603, 845, 1850, 'Pawe┼é Gryc');
INSERT INTO public.matches_extended VALUES (1440, 850, 2950, 'Sam Deroo');
INSERT INTO public.matches_extended VALUES (780, 766, 4223, 'Thibault Rossard');
INSERT INTO public.matches_extended VALUES (781, 768, 2234, 'Piotr Nowakowski');
INSERT INTO public.matches_extended VALUES (1441, 851, 1941, 'Milad Ebadipur');
INSERT INTO public.matches_extended VALUES (1442, 854, 4286, 'Sam Deroo');
INSERT INTO public.matches_extended VALUES (1443, 855, 1800, 'Jakub Kochanowski');
INSERT INTO public.matches_extended VALUES (1444, 853, 3015, 'Salvador Hidalgo Oliva');
INSERT INTO public.matches_extended VALUES (1445, 852, 1200, 'Eemi Tervaportti');
INSERT INTO public.matches_extended VALUES (1446, 859, 1600, 'Bartosz Kwolek');
INSERT INTO public.matches_extended VALUES (1447, 864, 850, '┼üukasz Kaczmarek');
INSERT INTO public.matches_extended VALUES (1615, 862, 600, 'Bart┼éomiej Kluth');
INSERT INTO public.matches_extended VALUES (1448, 861, 1300, 'Marcin Wali┼äski');
INSERT INTO public.matches_extended VALUES (1617, 863, 1760, 'Jakub Wachnik');
INSERT INTO public.matches_extended VALUES (1449, 866, 2234, 'Sre─çko Lisinac');
INSERT INTO public.matches_extended VALUES (1450, 860, 2300, 'Marcin Komenda');
INSERT INTO public.matches_extended VALUES (1451, 867, 1500, 'Lukas Kampa');
INSERT INTO public.matches_extended VALUES (1452, 865, 1758, 'Sam Deroo');
INSERT INTO public.matches_extended VALUES (1622, 875, 1100, 'Marcin Wika');
INSERT INTO public.matches_extended VALUES (1453, 872, 450, 'Bartosz Maria┼äski');
INSERT INTO public.matches_extended VALUES (1982, 1299, 1800, 'Mariusz Wlaz┼éy');
INSERT INTO public.matches_extended VALUES (1454, 870, 2390, 'Jan Hadrava');
INSERT INTO public.matches_extended VALUES (1457, 871, 2100, 'Mateusz Bieniek');
INSERT INTO public.matches_extended VALUES (1458, 869, 3543, 'Grzegorz Bociek');
INSERT INTO public.matches_extended VALUES (1459, 881, 1938, 'Mariusz Wlaz┼éy');
INSERT INTO public.matches_extended VALUES (1460, 883, 2997, 'Jakub Jarosz');
INSERT INTO public.matches_extended VALUES (1461, 882, 1500, 'Grzegorz Paj─ůk');
INSERT INTO public.matches_extended VALUES (1635, 877, 940, 'Karol Butryn');
INSERT INTO public.matches_extended VALUES (1463, 876, 2100, 'Mateusz Mika');
INSERT INTO public.matches_extended VALUES (782, 763, 1500, 'Dejan Vin─Źi─ç');
INSERT INTO public.matches_extended VALUES (925, 773, 3286, 'Andrzej Wrona');
INSERT INTO public.matches_extended VALUES (783, 769, 1850, 'Raphael Margarido');
INSERT INTO public.matches_extended VALUES (784, 771, 2444, 'Kawika Shoji');
INSERT INTO public.matches_extended VALUES (785, 774, 550, 'Bartosz Krzysiek');
INSERT INTO public.matches_extended VALUES (786, 770, 3050, 'Dawid Konarski');
INSERT INTO public.matches_extended VALUES (787, 772, 2106, 'Jakub Kochanowski');
INSERT INTO public.matches_extended VALUES (788, 779, 4293, 'Thibault Rossard');
INSERT INTO public.matches_extended VALUES (1637, 879, 500, 'Jakub Bucki');
INSERT INTO public.matches_extended VALUES (1639, 888, 2948, 'Sam Deroo');
INSERT INTO public.matches_extended VALUES (789, 780, 2611, 'Marcel Lux');
INSERT INTO public.matches_extended VALUES (791, 775, 450, 'Rafa┼é Soba┼äski');
INSERT INTO public.matches_extended VALUES (936, 777, 5372, 'Grzegorz ┼üomacz');
INSERT INTO public.matches_extended VALUES (937, 784, 2033, 'Bartosz Kwolek');
INSERT INTO public.matches_extended VALUES (792, 783, 1000, 'Piotr Nowakowski');
INSERT INTO public.matches_extended VALUES (939, 785, 2348, 'Jakub Kochanowski');
INSERT INTO public.matches_extended VALUES (794, 781, 1170, 'Julien Lyneel');
INSERT INTO public.matches_extended VALUES (795, 786, 500, 'Wojciech ┼╗ali┼äski');
INSERT INTO public.matches_extended VALUES (796, 787, 500, 'Rafa┼é Soba┼äski');
INSERT INTO public.matches_extended VALUES (797, 788, 1500, 'Milad Ebadipur');
INSERT INTO public.matches_extended VALUES (945, 790, 1238, 'Bartosz Kurek');
INSERT INTO public.matches_extended VALUES (798, 792, 3428, 'Jakub Jarosz');
INSERT INTO public.matches_extended VALUES (947, 789, 1500, '┼üukasz Kaczmarek');
INSERT INTO public.matches_extended VALUES (799, 791, 1122, 'Pawe┼é Woicki');
INSERT INTO public.matches_extended VALUES (800, 794, 2596, 'Wojciech Ferens');
INSERT INTO public.matches_extended VALUES (801, 798, 2219, 'Milad Ebadipur');
INSERT INTO public.matches_extended VALUES (951, 796, 1250, 'Mateusz Malinowski');
INSERT INTO public.matches_extended VALUES (952, 795, 2399, 'Bartosz Kurek');
INSERT INTO public.matches_extended VALUES (802, 797, 848, 'Rafa┼é Szymura');
INSERT INTO public.matches_extended VALUES (803, 793, 2000, 'Damian Schulz');
INSERT INTO public.matches_extended VALUES (804, 804, 1281, 'Kert Toobal');
INSERT INTO public.matches_extended VALUES (805, 799, 550, 'Bart┼éomiej Lipi┼äski');
INSERT INTO public.matches_extended VALUES (806, 800, 1100, '┼üukasz Kaczmarek');
INSERT INTO public.matches_extended VALUES (807, 801, 1500, 'Micha┼é Filip');
INSERT INTO public.matches_extended VALUES (959, 802, 1500, 'Mateusz Malinowski');
INSERT INTO public.matches_extended VALUES (960, 803, 4268, 'Graham Vigrass');
INSERT INTO public.matches_extended VALUES (808, 808, 2100, 'Wojciech Ferens');
INSERT INTO public.matches_extended VALUES (809, 807, 2837, 'Bart┼éomiej Lema┼äski');
INSERT INTO public.matches_extended VALUES (963, 805, 3410, 'Konrad Buczek');
INSERT INTO public.matches_extended VALUES (964, 806, 1116, 'Krzysztof Rejno');
INSERT INTO public.matches_extended VALUES (810, 809, 1190, 'Rafa┼é Faryna');
INSERT INTO public.matches_extended VALUES (811, 810, 2200, 'Sam Deroo');
INSERT INTO public.matches_extended VALUES (1644, 891, 1150, 'Marcin Wali┼äski');
INSERT INTO public.matches_extended VALUES (1649, 896, 2326, 'Patryk Czarnowski');
INSERT INTO public.matches_extended VALUES (1471, 894, 700, 'Gonzalo Quiroga');
INSERT INTO public.matches_extended VALUES (1473, 897, 1500, 'Micha┼é Filip');
INSERT INTO public.matches_extended VALUES (1474, 904, 2217, 'Sre─çko Lisinac');
INSERT INTO public.matches_extended VALUES (1475, 900, 2846, 'Jakub Jarosz');
INSERT INTO public.matches_extended VALUES (1477, 906, 1140, 'Bart┼éomiej Grzechnik');
INSERT INTO public.matches_extended VALUES (1658, 903, 1860, 'Bartosz Filipiak');
INSERT INTO public.matches_extended VALUES (1659, 907, 604, 'Marcin Wika');
INSERT INTO public.matches_extended VALUES (1478, 905, 4200, 'Benjamin Toniutti');
INSERT INTO public.matches_extended VALUES (1479, 902, 1500, 'Maciej Muzaj');
INSERT INTO public.matches_extended VALUES (1662, 910, 500, 'Piotr ┼üukasik');
INSERT INTO public.matches_extended VALUES (1480, 914, 4138, 'Bart┼éomiej Lema┼äski');
INSERT INTO public.matches_extended VALUES (1481, 913, 2331, 'Patryk Czarnowski');
INSERT INTO public.matches_extended VALUES (1482, 912, 1500, 'Nikola ă┤orăÁiev');
INSERT INTO public.matches_extended VALUES (1484, 915, 1800, 'Jakub Kochanowski');
INSERT INTO public.matches_extended VALUES (1669, 908, 1360, 'Damian Schulz');
INSERT INTO public.matches_extended VALUES (1670, 923, 967, 'Bartosz Janeczek');
INSERT INTO public.matches_extended VALUES (1485, 917, 1500, 'Micha┼é Filip');
INSERT INTO public.matches_extended VALUES (1673, 918, 2500, 'Bart┼éomiej Lema┼äski');
INSERT INTO public.matches_extended VALUES (1486, 921, 1400, 'Bartosz Bednorz');
INSERT INTO public.matches_extended VALUES (1487, 920, 800, 'Taichir┼Ź Koga');
INSERT INTO public.matches_extended VALUES (1488, 919, 3500, 'Bartosz Kwolek');
INSERT INTO public.matches_extended VALUES (1489, 916, 1572, 'Damian Schulz');
INSERT INTO public.matches_extended VALUES (1490, 929, 4023, 'Antoine Brizard');
INSERT INTO public.matches_extended VALUES (1491, 928, 1612, 'Salvador Hidalgo Oliva');
INSERT INTO public.matches_extended VALUES (1681, 926, 2279, 'Kacper Piechocki');
INSERT INTO public.matches_extended VALUES (1493, 927, 1500, '┼üukasz Swodczyk');
INSERT INTO public.matches_extended VALUES (1494, 931, 900, 'Kamil Droszy┼äski');
INSERT INTO public.matches_extended VALUES (1685, 930, 1600, 'Pawe┼é Woicki');
INSERT INTO public.matches_extended VALUES (1495, 939, 1069, 'Rafa┼é Szymura');
INSERT INTO public.matches_extended VALUES (1687, 933, 1060, 'Michal Masn├Ż');
INSERT INTO public.matches_extended VALUES (1688, 938, 1232, 'Patryk Czarnowski');
INSERT INTO public.matches_extended VALUES (1496, 932, 1500, 'Tyler Sanders');
INSERT INTO public.matches_extended VALUES (1690, 937, 1100, 'Bart┼éomiej Kluth');
INSERT INTO public.matches_extended VALUES (1497, 936, 1325, 'Rafael Rodrigues de Ara├║jo');
INSERT INTO public.matches_extended VALUES (1498, 934, 2100, 'Bartosz Kwolek');
INSERT INTO public.matches_extended VALUES (1983, 1300, 2600, 'Patryk Strze┼╝ek');
INSERT INTO public.matches_extended VALUES (1987, 1308, 2400, 'Sre─çko Lisinac');
INSERT INTO public.matches_extended VALUES (1988, 1306, 1500, 'John Perrin');
INSERT INTO public.matches_extended VALUES (1534, 992, 500, 'Kamil Kwasowski');
INSERT INTO public.matches_extended VALUES (1535, 991, 1350, 'Benjamin Toniutti');
INSERT INTO public.matches_extended VALUES (1536, 995, 1500, 'Karol Butryn');
INSERT INTO public.matches_extended VALUES (1750, 999, 1800, 'Guillaume Samica');
INSERT INTO public.matches_extended VALUES (1537, 1001, 2806, 'Mariusz Wlaz┼éy');
INSERT INTO public.matches_extended VALUES (1538, 1002, 2000, 'Jan Hadrava');
INSERT INTO public.matches_extended VALUES (1540, 996, 1395, 'Artur Szalpuk');
INSERT INTO public.matches_extended VALUES (1541, 1003, 4304, 'Thibault Rossard');
INSERT INTO public.matches_extended VALUES (1542, 1004, 4450, 'Mateusz Mika');
INSERT INTO public.matches_extended VALUES (1543, 1005, 1698, 'Maciej Muzaj');
INSERT INTO public.matches_extended VALUES (1544, 1006, 1500, '┼üukasz Kaczmarek');
INSERT INTO public.matches_extended VALUES (1764, 1010, 2174, 'Marcin Komenda');
INSERT INTO public.matches_extended VALUES (1546, 1007, 2345, 'Milad Ebadipur');
INSERT INTO public.matches_extended VALUES (1547, 1015, 4230, 'Nikola ă┤orăÁiev');
INSERT INTO public.matches_extended VALUES (1767, 1012, 1015, 'Tyler Sanders');
INSERT INTO public.matches_extended VALUES (1548, 1017, 1500, 'Wojciech ┼╗ali┼äski');
INSERT INTO public.matches_extended VALUES (1549, 1019, 2100, 'Adrian Buchowski');
INSERT INTO public.matches_extended VALUES (1770, 1016, 4150, 'Karol K┼éos');
INSERT INTO public.matches_extended VALUES (1550, 1014, 550, 'Rafa┼é Soba┼äski');
INSERT INTO public.matches_extended VALUES (1551, 1018, 2009, 'Michal Masn├Ż');
INSERT INTO public.matches_extended VALUES (1773, 1013, 1210, 'Marcin Wali┼äski');
INSERT INTO public.matches_extended VALUES (1552, 1022, 500, 'Marcin Wali┼äski');
INSERT INTO public.matches_extended VALUES (1555, 1025, 1100, 'Marcin Komenda');
INSERT INTO public.matches_extended VALUES (1556, 1020, 2700, 'Micha┼é Koz┼éowski');
INSERT INTO public.matches_extended VALUES (1557, 1024, 4530, 'Mariusz Wlaz┼éy');
INSERT INTO public.matches_extended VALUES (1558, 1031, 3100, 'Grzegorz ┼üomacz');
INSERT INTO public.matches_extended VALUES (1783, 1033, 1510, 'Maciej Muzaj');
INSERT INTO public.matches_extended VALUES (1559, 1034, 1500, 'Tomasz Fornal');
INSERT INTO public.matches_extended VALUES (1560, 1029, 1476, '┼üukasz Wi┼Ťniewski');
INSERT INTO public.matches_extended VALUES (1786, 1028, 2250, 'Damian Schulz');
INSERT INTO public.matches_extended VALUES (1787, 1030, 785, 'Wiaczes┼éaw Tarasow');
INSERT INTO public.matches_extended VALUES (1561, 1035, 1290, 'Tomas Rousseaux');
INSERT INTO public.matches_extended VALUES (1562, 1032, 2030, 'Jan Nowakowski');
INSERT INTO public.matches_extended VALUES (1563, 1036, 9781, 'Artur Szalpuk');
INSERT INTO public.matches_extended VALUES (1564, 1039, 1769, 'Jason De Rocco');
INSERT INTO public.matches_extended VALUES (1565, 1041, 2122, 'Karol K┼éos');
INSERT INTO public.matches_extended VALUES (1794, 1043, 500, 'Piotr ┼üukasik');
INSERT INTO public.matches_extended VALUES (1566, 1037, 2100, 'Jan Hadrava');
INSERT INTO public.matches_extended VALUES (1567, 1040, 1500, 'Grzegorz Bociek');
INSERT INTO public.matches_extended VALUES (1568, 1051, 1400, 'Tomasz Fornal');
INSERT INTO public.matches_extended VALUES (1799, 1050, 1570, 'Jakub Kochanowski');
INSERT INTO public.matches_extended VALUES (1569, 1048, 3200, 'Maciej Muzaj');
INSERT INTO public.matches_extended VALUES (1801, 1045, 2164, 'Mateusz Bieniek');
INSERT INTO public.matches_extended VALUES (1570, 1047, 1500, 'Grzegorz Bociek');
INSERT INTO public.matches_extended VALUES (1571, 1049, 4200, 'Wojciech W┼éodarczyk');
INSERT INTO public.matches_extended VALUES (1804, 1046, 2200, 'Marcin Janusz');
INSERT INTO public.matches_extended VALUES (1806, 1053, 1105, 'Pawe┼é Gryc');
INSERT INTO public.matches_extended VALUES (1573, 1052, 2050, 'Tyler Sanders');
INSERT INTO public.matches_extended VALUES (1574, 1056, 1237, 'Lukas Kampa');
INSERT INTO public.matches_extended VALUES (1575, 1054, 1374, 'Patryk Czarnowski');
INSERT INTO public.matches_extended VALUES (1577, 1059, 1000, 'Maurice Torres');
INSERT INTO public.matches_extended VALUES (1572, 1044, 1130, 'Dejan Vin─Źi─ç');
INSERT INTO public.matches_extended VALUES (1578, 1063, 1800, 'Mateusz Malinowski');
INSERT INTO public.matches_extended VALUES (1579, 1060, 1241, 'Artur Szalpuk');
INSERT INTO public.matches_extended VALUES (1580, 1061, 1500, 'Bartosz Bednorz');
INSERT INTO public.matches_extended VALUES (1581, 1065, 550, 'Micha┼é ┼╗urek');
INSERT INTO public.matches_extended VALUES (1582, 1064, 1200, 'Jakub Jarosz');
INSERT INTO public.matches_extended VALUES (1583, 1066, 3748, '┼üukasz Kaczmarek');
INSERT INTO public.matches_extended VALUES (1821, 1062, 1520, 'Grzegorz Bociek');
INSERT INTO public.matches_extended VALUES (1584, 1069, 1500, 'Andrzej Wrona');
INSERT INTO public.matches_extended VALUES (1585, 1075, 2491, 'Mariusz Wlaz┼éy');
INSERT INTO public.matches_extended VALUES (2014, 1099, 2600, 'Michal Masn├Ż');
INSERT INTO public.matches_extended VALUES (1586, 1071, 1500, 'Grzegorz Paj─ůk');
INSERT INTO public.matches_extended VALUES (1833, 1101, 1300, 'Wojciech ┼╗ali┼äski');
INSERT INTO public.matches_extended VALUES (1834, 1098, 2000, 'Mariusz Wlaz┼éy');
INSERT INTO public.matches_extended VALUES (1835, 1100, 800, 'Robert T├Ąht');
INSERT INTO public.matches_extended VALUES (1836, 1111, 1800, 'Fabian Drzyzga');
INSERT INTO public.matches_extended VALUES (1837, 1106, 1020, 'Lukas Kampa');
INSERT INTO public.matches_extended VALUES (1838, 1105, 1500, 'Jan Hadrava');
INSERT INTO public.matches_extended VALUES (1839, 1110, 3300, 'Sre─çko Lisinac');
INSERT INTO public.matches_extended VALUES (1840, 1109, 1350, 'Mateusz Mika');
INSERT INTO public.matches_extended VALUES (1841, 1107, 1200, 'Bartosz Janeczek');
INSERT INTO public.matches_extended VALUES (2024, 1108, 1500, 'Grzegorz ┼üomacz');
INSERT INTO public.matches_extended VALUES (2025, 1116, 1450, 'Jakub Wachnik');
INSERT INTO public.matches_extended VALUES (1842, 1119, 1970, 'Jan Hadrava');
INSERT INTO public.matches_extended VALUES (1843, 1113, 2700, 'Fabian Drzyzga');
INSERT INTO public.matches_extended VALUES (1844, 1118, 500, 'Serhij Kape┼éu┼Ť');
INSERT INTO public.matches_extended VALUES (1845, 1117, 1700, 'Maciej Muzaj');
INSERT INTO public.matches_extended VALUES (1846, 1115, 1600, 'Robert T├Ąht');
INSERT INTO public.matches_extended VALUES (1847, 1114, 4600, 'Sam Deroo');
INSERT INTO public.matches_extended VALUES (1848, 1127, 2060, 'Marcin Janusz');
INSERT INTO public.matches_extended VALUES (2033, 1123, 3000, 'Lukas Kampa');
INSERT INTO public.matches_extended VALUES (1849, 1126, 4380, 'John Perrin');
INSERT INTO public.matches_extended VALUES (1850, 1122, 500, 'Rafa┼é Soba┼äski');
INSERT INTO public.matches_extended VALUES (1851, 1125, 2150, 'Mateusz Bieniek');
INSERT INTO public.matches_extended VALUES (1852, 1121, 1050, 'Pawe┼é Adamajtis');
INSERT INTO public.matches_extended VALUES (1853, 1124, 1200, 'Micha┼é K─Ödzierski');
INSERT INTO public.matches_extended VALUES (1854, 1135, 1500, 'Jakub Kochanowski');
INSERT INTO public.matches_extended VALUES (1858, 1129, 2250, 'Damian Schulz');
INSERT INTO public.matches_extended VALUES (2059, 1150, 1500, 'Wojciech W┼éodarczyk');
INSERT INTO public.matches_extended VALUES (1874, 1156, 4050, 'Karol Butryn');
INSERT INTO public.matches_extended VALUES (1876, 1154, 1350, 'Jan Hadrava');
INSERT INTO public.matches_extended VALUES (1877, 1157, 960, 'Damian Boruch');
INSERT INTO public.matches_extended VALUES (1878, 1162, 3000, 'Salvador Hidalgo Oliva');
INSERT INTO public.matches_extended VALUES (2068, 1167, 400, 'Marcin Komenda');
INSERT INTO public.matches_extended VALUES (1879, 1165, 2400, 'Dawid Konarski');
INSERT INTO public.matches_extended VALUES (1880, 1161, 1400, 'Bart┼éomiej Bo┼é─ůd┼║');
INSERT INTO public.matches_extended VALUES (1881, 1164, 1450, 'Marcin Wali┼äski');
INSERT INTO public.matches_extended VALUES (1884, 1175, 1850, 'David Smith');
INSERT INTO public.matches_extended VALUES (1885, 1173, 2500, 'Kacper Piechocki');
INSERT INTO public.matches_extended VALUES (1886, 1174, 2500, 'Salvador Hidalgo Oliva');
INSERT INTO public.matches_extended VALUES (1887, 1169, 2200, 'Mateusz Bieniek');
INSERT INTO public.matches_extended VALUES (1888, 1170, 1300, 'Artur Ratajczak');
INSERT INTO public.matches_extended VALUES (1889, 1171, 4150, 'Gavin Schmitt');
INSERT INTO public.matches_extended VALUES (1890, 1172, 950, 'Janusz Ga┼é─ůzka');
INSERT INTO public.matches_extended VALUES (1891, 1180, 2730, 'Robert T├Ąht');
INSERT INTO public.matches_extended VALUES (1895, 1178, 2250, 'Serhij Kape┼éu┼Ť');
INSERT INTO public.matches_extended VALUES (1896, 1181, 1700, 'Marko Ivovi─ç');
INSERT INTO public.matches_extended VALUES (1897, 1191, 1500, 'Scott Touzinsky');
INSERT INTO public.matches_extended VALUES (1898, 1188, 2650, 'Artur Szalpuk');
INSERT INTO public.matches_extended VALUES (2090, 1185, 2650, 'Mateusz Bieniek');
INSERT INTO public.matches_extended VALUES (1899, 1186, 4050, 'Gavin Schmitt');
INSERT INTO public.matches_extended VALUES (1900, 1189, 2520, 'Dmytro Paszycki');
INSERT INTO public.matches_extended VALUES (1901, 1187, 650, 'Micha┼é Ruciak');
INSERT INTO public.matches_extended VALUES (1902, 1190, 1560, '┼üukasz Kaczmarek');
INSERT INTO public.matches_extended VALUES (1903, 1194, 1450, 'Grzegorz ┼üomacz');
INSERT INTO public.matches_extended VALUES (1905, 1195, 2000, 'Jan Hadrava');
INSERT INTO public.matches_extended VALUES (1906, 1197, 800, 'Pawe┼é Gryc');
INSERT INTO public.matches_extended VALUES (1908, 1196, 2750, 'Artur Szalpuk');
INSERT INTO public.matches_extended VALUES (2102, 1202, 790, 'Bart┼éomiej Kluth');
INSERT INTO public.matches_extended VALUES (1909, 1205, 1050, 'Wojciech ┼╗ali┼äski');
INSERT INTO public.matches_extended VALUES (1914, 1204, 2217, 'Mateusz Mika');
INSERT INTO public.matches_extended VALUES (1915, 1209, 1800, 'Jakub Popiwczak');
INSERT INTO public.matches_extended VALUES (1916, 1215, 3000, 'Marko Ivovi─ç');
INSERT INTO public.matches_extended VALUES (1917, 1212, 1130, 'Grzegorz ┼üomacz');
INSERT INTO public.matches_extended VALUES (2113, 1213, 2750, 'Kacper Piechocki');
INSERT INTO public.matches_extended VALUES (1919, 1210, 1800, 'Wojciech W┼éodarczyk');
INSERT INTO public.matches_extended VALUES (1920, 1214, 1300, 'Marcin Wali┼äski');
INSERT INTO public.matches_extended VALUES (2116, 1219, 1000, 'Mi┼éosz Hebda');
INSERT INTO public.matches_extended VALUES (1921, 1222, 1800, 'Wojciech W┼éodarczyk');
INSERT INTO public.matches_extended VALUES (2130, 1243, 2100, 'Salvador Hidalgo Oliva');
INSERT INTO public.matches_extended VALUES (1933, 1240, 1250, 'Piotr Sie┼äko');
INSERT INTO public.matches_extended VALUES (1934, 1246, 4150, 'Damian Schulz');
INSERT INTO public.matches_extended VALUES (1935, 1247, 2000, 'Jurij G┼éadyr');
INSERT INTO public.matches_extended VALUES (1936, 1242, 2650, 'Karol Butryn');
INSERT INTO public.matches_extended VALUES (1937, 1245, 2745, 'Sam Deroo');
INSERT INTO public.matches_extended VALUES (1938, 1239, 1000, 'Krzysztof Rejno');
INSERT INTO public.matches_extended VALUES (1940, 1233, 4300, 'Gavin Schmitt');
INSERT INTO public.matches_extended VALUES (1941, 1238, 900, 'Tomasz Kalembka');
INSERT INTO public.matches_extended VALUES (1942, 1234, 2250, '┼üukasz Wi┼Ťniewski');
INSERT INTO public.matches_extended VALUES (1943, 1237, 1000, 'Grzegorz Kosok');
INSERT INTO public.matches_extended VALUES (1944, 1254, 500, 'Bartosz Filipiak');
INSERT INTO public.matches_extended VALUES (1945, 1252, 1300, 'Lukas Kampa');
INSERT INTO public.matches_extended VALUES (1946, 1255, 1800, 'Sam Deroo');
INSERT INTO public.matches_extended VALUES (1948, 1250, 4070, 'Marcin Mo┼╝d┼╝onek');
INSERT INTO public.matches_extended VALUES (1949, 1249, 1230, 'Bart┼éomiej Kluth');
INSERT INTO public.matches_extended VALUES (1950, 1260, 3112, '┼üukasz Wi┼Ťniewski');
INSERT INTO public.matches_extended VALUES (1952, 1263, 6850, 'Bartosz Kurek');
INSERT INTO public.matches_extended VALUES (1953, 1257, 800, 'Krzysztof Rejno');
INSERT INTO public.matches_extended VALUES (1955, 1262, 1370, 'Rafail Kumendakis');
INSERT INTO public.matches_extended VALUES (1956, 1271, 1150, 'Bartosz Filipak');
INSERT INTO public.matches_extended VALUES (1959, 1265, 2700, 'Mariusz Wlaz┼éy');
INSERT INTO public.matches_extended VALUES (1960, 1268, 2100, 'Mi┼éosz Zniszczo┼é');
INSERT INTO public.matches_extended VALUES (1961, 1267, 4512, 'Lukas Kampa');
INSERT INTO public.matches_extended VALUES (1962, 1278, 1510, 'Sre─çko Lisinac');
INSERT INTO public.matches_extended VALUES (1963, 1274, 2000, 'Daniel Pli┼äski');
INSERT INTO public.matches_extended VALUES (2169, 1273, 1000, 'Marcin Komenda');
INSERT INTO public.matches_extended VALUES (1967, 1276, 1500, 'Jochen Sch├Âps');
INSERT INTO public.matches_extended VALUES (1968, 1286, 1100, 'Marcin Wali┼äski');
INSERT INTO public.matches_extended VALUES (1969, 1285, 2250, 'Benjamin Toniutti');
INSERT INTO public.matches_extended VALUES (2173, 1287, 970, 'Leo Andri─ç');
INSERT INTO public.matches_extended VALUES (1970, 1284, 4094, 'Jochen Sch├Âps');
INSERT INTO public.matches_extended VALUES (1971, 1281, 2850, 'Mateusz Mika');
INSERT INTO public.matches_extended VALUES (1972, 1282, 2700, 'Bartosz Kurek');
INSERT INTO public.matches_extended VALUES (1973, 1283, 930, 'Karol Butryn');
INSERT INTO public.matches_extended VALUES (1974, 1292, 1420, 'Janusz Ga┼é─ůzka');
INSERT INTO public.matches_extended VALUES (1975, 1291, 2350, 'Fabian Drzyzga');
INSERT INTO public.matches_extended VALUES (1976, 1290, 700, 'Rafael Rodrigues de Ara├║jo');
INSERT INTO public.matches_extended VALUES (1978, 1293, 1500, 'Karol K┼éos');
INSERT INTO public.matches_extended VALUES (1979, 1294, 3700, 'Lukas Kampa');
INSERT INTO public.matches_extended VALUES (1980, 1289, 1000, 'Grzegorz Paj─ůk');
INSERT INTO public.matches_extended VALUES (1981, 1298, 2500, 'Serhij Kape┼éu┼Ť');
INSERT INTO public.matches_extended VALUES (2191, 1303, 1100, 'Marcin Wali┼äski');
INSERT INTO public.matches_extended VALUES (1989, 1309, 750, 'Robert T├Ąht');
INSERT INTO public.matches_extended VALUES (2197, 1305, 3100, 'Sam Deroo');
INSERT INTO public.matches_extended VALUES (1992, 1311, 2450, 'Maciej Muzaj');
INSERT INTO public.matches_extended VALUES (1993, 1317, 1500, 'Serhij Kape┼éu┼Ť');
INSERT INTO public.matches_extended VALUES (1995, 1318, 1700, '┼üukasz Kaczmarek');
INSERT INTO public.matches_extended VALUES (1997, 1315, 3500, 'Jan Hadrava');
INSERT INTO public.matches_extended VALUES (1998, 1319, 2300, 'Dawid Konarski');
INSERT INTO public.matches_extended VALUES (1999, 1324, 900, 'Damian Schulz');
INSERT INTO public.matches_extended VALUES (2000, 1325, 1800, 'Pawe┼é Woicki');
INSERT INTO public.matches_extended VALUES (2001, 1323, 2501, 'Mariusz Wlaz┼éy');
INSERT INTO public.matches_extended VALUES (2002, 1326, 1300, 'Tomasz Fornal');
INSERT INTO public.matches_extended VALUES (2210, 1322, 2600, 'Micha┼é Ruciak');
INSERT INTO public.matches_extended VALUES (2003, 1321, 1400, 'Marko Ivovi─ç');
INSERT INTO public.matches_extended VALUES (2004, 1327, 4600, 'Lukas Kampa');
INSERT INTO public.matches_extended VALUES (2005, 1330, 1100, 'Pawe┼é Woicki');
INSERT INTO public.matches_extended VALUES (2006, 1329, 2270, 'Salvador Hidalgo Oliva');
INSERT INTO public.matches_extended VALUES (2007, 1332, 800, 'Mateusz Mika');
INSERT INTO public.matches_extended VALUES (2008, 1331, 1300, 'Grzegorz ┼üomacz');
INSERT INTO public.matches_extended VALUES (2009, 1335, 4300, 'Jochen Sch├Âps');
INSERT INTO public.matches_extended VALUES (2010, 1334, 430, 'Micha┼é Ruciak');
INSERT INTO public.matches_extended VALUES (2219, 1333, 2700, 'Karol K┼éos');


--
-- Data for Name: points_in_season; Type: TABLE DATA; Schema: public; Owner: user
--



--
-- Data for Name: season; Type: TABLE DATA; Schema: public; Owner: user
--

INSERT INTO public.season VALUES (2, '2021/2022');
INSERT INTO public.season VALUES (3, '2020/2021');
INSERT INTO public.season VALUES (4, '2018/2019');
INSERT INTO public.season VALUES (5, '2017/2018');
INSERT INTO public.season VALUES (6, '2016/2017');


--
-- Data for Name: set_scores; Type: TABLE DATA; Schema: public; Owner: user
--

INSERT INTO public.set_scores VALUES (1, 238, 1, 15, 25);
INSERT INTO public.set_scores VALUES (2, 238, 2, 21, 25);
INSERT INTO public.set_scores VALUES (3, 238, 3, 25, 21);
INSERT INTO public.set_scores VALUES (4, 238, 4, 16, 25);
INSERT INTO public.set_scores VALUES (5, 242, 1, 22, 25);
INSERT INTO public.set_scores VALUES (6, 242, 2, 18, 25);
INSERT INTO public.set_scores VALUES (7, 242, 3, 20, 25);
INSERT INTO public.set_scores VALUES (8, 239, 1, 22, 25);
INSERT INTO public.set_scores VALUES (9, 239, 2, 21, 25);
INSERT INTO public.set_scores VALUES (10, 239, 3, 20, 25);
INSERT INTO public.set_scores VALUES (11, 244, 1, 25, 23);
INSERT INTO public.set_scores VALUES (12, 244, 2, 23, 25);
INSERT INTO public.set_scores VALUES (13, 244, 3, 25, 23);
INSERT INTO public.set_scores VALUES (14, 244, 4, 25, 21);
INSERT INTO public.set_scores VALUES (15, 243, 1, 25, 20);
INSERT INTO public.set_scores VALUES (16, 243, 2, 25, 20);
INSERT INTO public.set_scores VALUES (17, 243, 3, 19, 25);
INSERT INTO public.set_scores VALUES (18, 243, 4, 21, 25);
INSERT INTO public.set_scores VALUES (19, 243, 5, 15, 12);
INSERT INTO public.set_scores VALUES (20, 240, 1, 16, 25);
INSERT INTO public.set_scores VALUES (21, 240, 2, 17, 25);
INSERT INTO public.set_scores VALUES (22, 240, 3, 23, 25);
INSERT INTO public.set_scores VALUES (23, 241, 1, 22, 25);
INSERT INTO public.set_scores VALUES (24, 241, 2, 19, 25);
INSERT INTO public.set_scores VALUES (25, 241, 3, 25, 22);
INSERT INTO public.set_scores VALUES (26, 241, 4, 25, 27);
INSERT INTO public.set_scores VALUES (27, 251, 1, 25, 18);
INSERT INTO public.set_scores VALUES (28, 251, 2, 25, 20);
INSERT INTO public.set_scores VALUES (29, 251, 3, 25, 19);
INSERT INTO public.set_scores VALUES (30, 249, 1, 18, 25);
INSERT INTO public.set_scores VALUES (31, 249, 2, 25, 17);
INSERT INTO public.set_scores VALUES (32, 249, 3, 25, 17);
INSERT INTO public.set_scores VALUES (33, 249, 4, 31, 29);
INSERT INTO public.set_scores VALUES (34, 250, 1, 20, 25);
INSERT INTO public.set_scores VALUES (35, 250, 2, 16, 25);
INSERT INTO public.set_scores VALUES (36, 250, 3, 17, 25);
INSERT INTO public.set_scores VALUES (37, 247, 1, 25, 22);
INSERT INTO public.set_scores VALUES (38, 247, 2, 25, 22);
INSERT INTO public.set_scores VALUES (39, 247, 3, 25, 23);
INSERT INTO public.set_scores VALUES (40, 245, 1, 25, 19);
INSERT INTO public.set_scores VALUES (41, 245, 2, 25, 16);
INSERT INTO public.set_scores VALUES (42, 245, 3, 25, 22);
INSERT INTO public.set_scores VALUES (43, 246, 1, 25, 21);
INSERT INTO public.set_scores VALUES (44, 246, 2, 18, 25);
INSERT INTO public.set_scores VALUES (45, 246, 3, 22, 25);
INSERT INTO public.set_scores VALUES (46, 246, 4, 22, 25);
INSERT INTO public.set_scores VALUES (47, 248, 1, 25, 16);
INSERT INTO public.set_scores VALUES (48, 248, 2, 25, 22);
INSERT INTO public.set_scores VALUES (49, 248, 3, 23, 25);
INSERT INTO public.set_scores VALUES (50, 248, 4, 17, 25);
INSERT INTO public.set_scores VALUES (51, 248, 5, 15, 10);
INSERT INTO public.set_scores VALUES (52, 253, 1, 20, 25);
INSERT INTO public.set_scores VALUES (53, 253, 2, 25, 21);
INSERT INTO public.set_scores VALUES (54, 253, 3, 19, 25);
INSERT INTO public.set_scores VALUES (55, 253, 4, 32, 30);
INSERT INTO public.set_scores VALUES (56, 253, 5, 22, 20);
INSERT INTO public.set_scores VALUES (57, 258, 1, 21, 25);
INSERT INTO public.set_scores VALUES (58, 258, 2, 25, 20);
INSERT INTO public.set_scores VALUES (59, 258, 3, 25, 19);
INSERT INTO public.set_scores VALUES (60, 258, 4, 25, 21);
INSERT INTO public.set_scores VALUES (61, 252, 1, 25, 22);
INSERT INTO public.set_scores VALUES (62, 252, 2, 25, 13);
INSERT INTO public.set_scores VALUES (63, 252, 3, 25, 19);
INSERT INTO public.set_scores VALUES (64, 254, 1, 25, 17);
INSERT INTO public.set_scores VALUES (65, 254, 2, 19, 25);
INSERT INTO public.set_scores VALUES (66, 254, 3, 25, 23);
INSERT INTO public.set_scores VALUES (67, 254, 4, 21, 25);
INSERT INTO public.set_scores VALUES (68, 254, 5, 20, 18);
INSERT INTO public.set_scores VALUES (69, 255, 1, 25, 23);
INSERT INTO public.set_scores VALUES (70, 255, 2, 26, 24);
INSERT INTO public.set_scores VALUES (71, 255, 3, 25, 14);
INSERT INTO public.set_scores VALUES (72, 256, 1, 25, 23);
INSERT INTO public.set_scores VALUES (73, 256, 2, 25, 15);
INSERT INTO public.set_scores VALUES (74, 256, 3, 25, 15);
INSERT INTO public.set_scores VALUES (75, 257, 1, 29, 31);
INSERT INTO public.set_scores VALUES (76, 257, 2, 21, 25);
INSERT INTO public.set_scores VALUES (77, 257, 3, 26, 28);
INSERT INTO public.set_scores VALUES (78, 259, 1, 25, 19);
INSERT INTO public.set_scores VALUES (79, 259, 2, 26, 24);
INSERT INTO public.set_scores VALUES (80, 259, 3, 25, 22);
INSERT INTO public.set_scores VALUES (81, 265, 1, 25, 27);
INSERT INTO public.set_scores VALUES (82, 265, 2, 25, 18);
INSERT INTO public.set_scores VALUES (83, 265, 3, 14, 25);
INSERT INTO public.set_scores VALUES (84, 265, 4, 25, 18);
INSERT INTO public.set_scores VALUES (85, 265, 5, 15, 9);
INSERT INTO public.set_scores VALUES (86, 262, 1, 25, 19);
INSERT INTO public.set_scores VALUES (87, 262, 2, 20, 25);
INSERT INTO public.set_scores VALUES (88, 262, 3, 31, 29);
INSERT INTO public.set_scores VALUES (89, 262, 4, 26, 24);
INSERT INTO public.set_scores VALUES (90, 263, 1, 21, 25);
INSERT INTO public.set_scores VALUES (91, 263, 2, 25, 17);
INSERT INTO public.set_scores VALUES (92, 263, 3, 21, 25);
INSERT INTO public.set_scores VALUES (93, 263, 4, 18, 25);
INSERT INTO public.set_scores VALUES (94, 264, 1, 25, 18);
INSERT INTO public.set_scores VALUES (95, 264, 2, 25, 20);
INSERT INTO public.set_scores VALUES (96, 264, 3, 17, 25);
INSERT INTO public.set_scores VALUES (97, 264, 4, 25, 18);
INSERT INTO public.set_scores VALUES (98, 260, 1, 25, 18);
INSERT INTO public.set_scores VALUES (99, 260, 2, 25, 20);
INSERT INTO public.set_scores VALUES (100, 260, 3, 25, 23);
INSERT INTO public.set_scores VALUES (101, 261, 1, 25, 18);
INSERT INTO public.set_scores VALUES (102, 261, 2, 25, 22);
INSERT INTO public.set_scores VALUES (103, 261, 3, 25, 22);
INSERT INTO public.set_scores VALUES (104, 271, 1, 25, 20);
INSERT INTO public.set_scores VALUES (105, 271, 2, 24, 26);
INSERT INTO public.set_scores VALUES (106, 271, 3, 17, 25);
INSERT INTO public.set_scores VALUES (107, 271, 4, 25, 22);
INSERT INTO public.set_scores VALUES (108, 271, 5, 15, 11);
INSERT INTO public.set_scores VALUES (109, 266, 1, 29, 31);
INSERT INTO public.set_scores VALUES (110, 266, 2, 25, 19);
INSERT INTO public.set_scores VALUES (111, 266, 3, 25, 22);
INSERT INTO public.set_scores VALUES (112, 266, 4, 25, 19);
INSERT INTO public.set_scores VALUES (113, 267, 1, 26, 24);
INSERT INTO public.set_scores VALUES (114, 267, 2, 29, 27);
INSERT INTO public.set_scores VALUES (115, 267, 3, 23, 25);
INSERT INTO public.set_scores VALUES (116, 267, 4, 19, 25);
INSERT INTO public.set_scores VALUES (117, 267, 5, 12, 15);
INSERT INTO public.set_scores VALUES (118, 269, 1, 25, 22);
INSERT INTO public.set_scores VALUES (119, 269, 2, 25, 19);
INSERT INTO public.set_scores VALUES (120, 269, 3, 25, 21);
INSERT INTO public.set_scores VALUES (121, 270, 1, 26, 28);
INSERT INTO public.set_scores VALUES (122, 270, 2, 25, 23);
INSERT INTO public.set_scores VALUES (123, 270, 3, 27, 29);
INSERT INTO public.set_scores VALUES (124, 270, 4, 23, 25);
INSERT INTO public.set_scores VALUES (125, 268, 1, 23, 25);
INSERT INTO public.set_scores VALUES (126, 268, 2, 21, 25);
INSERT INTO public.set_scores VALUES (127, 268, 3, 18, 25);
INSERT INTO public.set_scores VALUES (128, 272, 1, 16, 25);
INSERT INTO public.set_scores VALUES (129, 272, 2, 17, 25);
INSERT INTO public.set_scores VALUES (130, 272, 3, 20, 25);
INSERT INTO public.set_scores VALUES (131, 273, 1, 25, 21);
INSERT INTO public.set_scores VALUES (132, 273, 2, 20, 25);
INSERT INTO public.set_scores VALUES (133, 273, 3, 21, 25);
INSERT INTO public.set_scores VALUES (134, 273, 4, 25, 20);
INSERT INTO public.set_scores VALUES (135, 273, 5, 12, 15);
INSERT INTO public.set_scores VALUES (136, 278, 1, 17, 25);
INSERT INTO public.set_scores VALUES (137, 278, 2, 25, 15);
INSERT INTO public.set_scores VALUES (138, 278, 3, 25, 18);
INSERT INTO public.set_scores VALUES (139, 278, 4, 25, 19);
INSERT INTO public.set_scores VALUES (140, 274, 1, 25, 27);
INSERT INTO public.set_scores VALUES (141, 274, 2, 25, 20);
INSERT INTO public.set_scores VALUES (142, 274, 3, 25, 19);
INSERT INTO public.set_scores VALUES (143, 274, 4, 25, 19);
INSERT INTO public.set_scores VALUES (144, 275, 1, 21, 25);
INSERT INTO public.set_scores VALUES (145, 275, 2, 20, 25);
INSERT INTO public.set_scores VALUES (146, 275, 3, 19, 25);
INSERT INTO public.set_scores VALUES (147, 279, 1, 17, 25);
INSERT INTO public.set_scores VALUES (148, 279, 2, 21, 25);
INSERT INTO public.set_scores VALUES (149, 279, 3, 23, 25);
INSERT INTO public.set_scores VALUES (150, 277, 1, 25, 14);
INSERT INTO public.set_scores VALUES (151, 277, 2, 25, 22);
INSERT INTO public.set_scores VALUES (152, 277, 3, 25, 22);
INSERT INTO public.set_scores VALUES (153, 276, 1, 22, 25);
INSERT INTO public.set_scores VALUES (154, 276, 2, 25, 17);
INSERT INTO public.set_scores VALUES (155, 276, 3, 15, 25);
INSERT INTO public.set_scores VALUES (156, 276, 4, 21, 25);
INSERT INTO public.set_scores VALUES (157, 285, 1, 25, 17);
INSERT INTO public.set_scores VALUES (158, 285, 2, 18, 25);
INSERT INTO public.set_scores VALUES (159, 285, 3, 29, 27);
INSERT INTO public.set_scores VALUES (160, 285, 4, 25, 21);
INSERT INTO public.set_scores VALUES (161, 281, 1, 25, 21);
INSERT INTO public.set_scores VALUES (162, 281, 2, 26, 24);
INSERT INTO public.set_scores VALUES (163, 281, 3, 25, 19);
INSERT INTO public.set_scores VALUES (1968, 447, 1, 19, 25);
INSERT INTO public.set_scores VALUES (1969, 447, 2, 13, 25);
INSERT INTO public.set_scores VALUES (1970, 447, 3, 16, 25);
INSERT INTO public.set_scores VALUES (1971, 448, 1, 20, 25);
INSERT INTO public.set_scores VALUES (1972, 448, 2, 14, 25);
INSERT INTO public.set_scores VALUES (1973, 448, 3, 25, 20);
INSERT INTO public.set_scores VALUES (1974, 448, 4, 24, 26);
INSERT INTO public.set_scores VALUES (1975, 449, 1, 25, 20);
INSERT INTO public.set_scores VALUES (172, 282, 1, 23, 25);
INSERT INTO public.set_scores VALUES (173, 282, 2, 20, 25);
INSERT INTO public.set_scores VALUES (174, 282, 3, 14, 25);
INSERT INTO public.set_scores VALUES (175, 283, 1, 22, 25);
INSERT INTO public.set_scores VALUES (176, 283, 2, 20, 25);
INSERT INTO public.set_scores VALUES (177, 283, 3, 19, 25);
INSERT INTO public.set_scores VALUES (178, 286, 1, 25, 20);
INSERT INTO public.set_scores VALUES (179, 286, 2, 25, 21);
INSERT INTO public.set_scores VALUES (180, 286, 3, 25, 17);
INSERT INTO public.set_scores VALUES (181, 290, 1, 22, 25);
INSERT INTO public.set_scores VALUES (182, 290, 2, 21, 25);
INSERT INTO public.set_scores VALUES (183, 290, 3, 25, 20);
INSERT INTO public.set_scores VALUES (184, 290, 4, 25, 17);
INSERT INTO public.set_scores VALUES (185, 290, 5, 10, 15);
INSERT INTO public.set_scores VALUES (186, 291, 1, 18, 25);
INSERT INTO public.set_scores VALUES (187, 291, 2, 25, 17);
INSERT INTO public.set_scores VALUES (188, 291, 3, 25, 27);
INSERT INTO public.set_scores VALUES (189, 291, 4, 25, 16);
INSERT INTO public.set_scores VALUES (190, 291, 5, 13, 15);
INSERT INTO public.set_scores VALUES (191, 292, 1, 25, 17);
INSERT INTO public.set_scores VALUES (192, 292, 2, 25, 22);
INSERT INTO public.set_scores VALUES (193, 292, 3, 25, 18);
INSERT INTO public.set_scores VALUES (194, 289, 1, 23, 25);
INSERT INTO public.set_scores VALUES (195, 289, 2, 23, 25);
INSERT INTO public.set_scores VALUES (196, 289, 3, 23, 25);
INSERT INTO public.set_scores VALUES (197, 293, 1, 25, 21);
INSERT INTO public.set_scores VALUES (198, 293, 2, 25, 20);
INSERT INTO public.set_scores VALUES (199, 293, 3, 25, 20);
INSERT INTO public.set_scores VALUES (200, 288, 1, 19, 25);
INSERT INTO public.set_scores VALUES (201, 288, 2, 25, 17);
INSERT INTO public.set_scores VALUES (202, 288, 3, 25, 17);
INSERT INTO public.set_scores VALUES (203, 288, 4, 28, 30);
INSERT INTO public.set_scores VALUES (204, 288, 5, 19, 17);
INSERT INTO public.set_scores VALUES (205, 287, 1, 22, 25);
INSERT INTO public.set_scores VALUES (206, 287, 2, 20, 25);
INSERT INTO public.set_scores VALUES (207, 287, 3, 25, 17);
INSERT INTO public.set_scores VALUES (208, 287, 4, 25, 19);
INSERT INTO public.set_scores VALUES (209, 287, 5, 15, 13);
INSERT INTO public.set_scores VALUES (210, 296, 1, 18, 25);
INSERT INTO public.set_scores VALUES (211, 296, 2, 25, 23);
INSERT INTO public.set_scores VALUES (212, 296, 3, 22, 25);
INSERT INTO public.set_scores VALUES (213, 296, 4, 23, 25);
INSERT INTO public.set_scores VALUES (214, 297, 1, 36, 38);
INSERT INTO public.set_scores VALUES (215, 297, 2, 13, 25);
INSERT INTO public.set_scores VALUES (216, 297, 3, 14, 25);
INSERT INTO public.set_scores VALUES (217, 298, 1, 17, 25);
INSERT INTO public.set_scores VALUES (218, 298, 2, 20, 25);
INSERT INTO public.set_scores VALUES (219, 298, 3, 21, 25);
INSERT INTO public.set_scores VALUES (220, 294, 1, 21, 25);
INSERT INTO public.set_scores VALUES (221, 294, 2, 25, 23);
INSERT INTO public.set_scores VALUES (222, 294, 3, 22, 25);
INSERT INTO public.set_scores VALUES (223, 294, 4, 23, 25);
INSERT INTO public.set_scores VALUES (224, 295, 1, 18, 25);
INSERT INTO public.set_scores VALUES (225, 295, 2, 13, 25);
INSERT INTO public.set_scores VALUES (226, 295, 3, 22, 25);
INSERT INTO public.set_scores VALUES (227, 299, 1, 25, 23);
INSERT INTO public.set_scores VALUES (228, 299, 2, 20, 25);
INSERT INTO public.set_scores VALUES (229, 299, 3, 20, 25);
INSERT INTO public.set_scores VALUES (230, 299, 4, 25, 13);
INSERT INTO public.set_scores VALUES (231, 299, 5, 15, 13);
INSERT INTO public.set_scores VALUES (232, 300, 1, 23, 25);
INSERT INTO public.set_scores VALUES (233, 300, 2, 25, 19);
INSERT INTO public.set_scores VALUES (234, 300, 3, 26, 24);
INSERT INTO public.set_scores VALUES (235, 300, 4, 23, 25);
INSERT INTO public.set_scores VALUES (236, 300, 5, 15, 17);
INSERT INTO public.set_scores VALUES (237, 304, 1, 25, 18);
INSERT INTO public.set_scores VALUES (238, 304, 2, 25, 23);
INSERT INTO public.set_scores VALUES (239, 304, 3, 25, 19);
INSERT INTO public.set_scores VALUES (240, 303, 1, 21, 25);
INSERT INTO public.set_scores VALUES (241, 303, 2, 18, 25);
INSERT INTO public.set_scores VALUES (242, 303, 3, 20, 25);
INSERT INTO public.set_scores VALUES (243, 306, 1, 25, 22);
INSERT INTO public.set_scores VALUES (244, 306, 2, 25, 22);
INSERT INTO public.set_scores VALUES (245, 306, 3, 25, 22);
INSERT INTO public.set_scores VALUES (246, 307, 1, 21, 25);
INSERT INTO public.set_scores VALUES (247, 307, 2, 20, 25);
INSERT INTO public.set_scores VALUES (248, 307, 3, 21, 25);
INSERT INTO public.set_scores VALUES (249, 301, 1, 25, 13);
INSERT INTO public.set_scores VALUES (250, 301, 2, 22, 25);
INSERT INTO public.set_scores VALUES (251, 301, 3, 25, 18);
INSERT INTO public.set_scores VALUES (252, 301, 4, 25, 14);
INSERT INTO public.set_scores VALUES (253, 302, 1, 23, 25);
INSERT INTO public.set_scores VALUES (254, 302, 2, 35, 33);
INSERT INTO public.set_scores VALUES (255, 302, 3, 17, 25);
INSERT INTO public.set_scores VALUES (256, 302, 4, 19, 25);
INSERT INTO public.set_scores VALUES (257, 305, 1, 31, 33);
INSERT INTO public.set_scores VALUES (258, 305, 2, 25, 23);
INSERT INTO public.set_scores VALUES (259, 305, 3, 25, 19);
INSERT INTO public.set_scores VALUES (260, 305, 4, 26, 24);
INSERT INTO public.set_scores VALUES (261, 312, 1, 25, 23);
INSERT INTO public.set_scores VALUES (262, 312, 2, 25, 20);
INSERT INTO public.set_scores VALUES (263, 312, 3, 25, 16);
INSERT INTO public.set_scores VALUES (264, 313, 1, 28, 30);
INSERT INTO public.set_scores VALUES (265, 313, 2, 18, 25);
INSERT INTO public.set_scores VALUES (266, 313, 3, 17, 25);
INSERT INTO public.set_scores VALUES (267, 314, 1, 25, 18);
INSERT INTO public.set_scores VALUES (268, 314, 2, 21, 25);
INSERT INTO public.set_scores VALUES (269, 314, 3, 25, 23);
INSERT INTO public.set_scores VALUES (270, 314, 4, 25, 21);
INSERT INTO public.set_scores VALUES (271, 311, 1, 25, 21);
INSERT INTO public.set_scores VALUES (272, 311, 2, 22, 25);
INSERT INTO public.set_scores VALUES (273, 311, 3, 25, 20);
INSERT INTO public.set_scores VALUES (274, 311, 4, 18, 25);
INSERT INTO public.set_scores VALUES (275, 311, 5, 9, 15);
INSERT INTO public.set_scores VALUES (276, 309, 1, 21, 25);
INSERT INTO public.set_scores VALUES (277, 309, 2, 18, 25);
INSERT INTO public.set_scores VALUES (278, 309, 3, 22, 25);
INSERT INTO public.set_scores VALUES (279, 308, 1, 25, 20);
INSERT INTO public.set_scores VALUES (280, 308, 2, 25, 22);
INSERT INTO public.set_scores VALUES (281, 308, 3, 25, 16);
INSERT INTO public.set_scores VALUES (282, 310, 1, 25, 21);
INSERT INTO public.set_scores VALUES (283, 310, 2, 10, 25);
INSERT INTO public.set_scores VALUES (284, 310, 3, 25, 18);
INSERT INTO public.set_scores VALUES (285, 310, 4, 23, 25);
INSERT INTO public.set_scores VALUES (286, 310, 5, 26, 24);
INSERT INTO public.set_scores VALUES (287, 319, 1, 25, 22);
INSERT INTO public.set_scores VALUES (288, 319, 2, 19, 25);
INSERT INTO public.set_scores VALUES (289, 319, 3, 25, 20);
INSERT INTO public.set_scores VALUES (290, 319, 4, 25, 16);
INSERT INTO public.set_scores VALUES (291, 320, 1, 15, 25);
INSERT INTO public.set_scores VALUES (292, 320, 2, 20, 25);
INSERT INTO public.set_scores VALUES (293, 320, 3, 25, 18);
INSERT INTO public.set_scores VALUES (294, 320, 4, 22, 25);
INSERT INTO public.set_scores VALUES (295, 316, 1, 25, 18);
INSERT INTO public.set_scores VALUES (296, 316, 2, 25, 9);
INSERT INTO public.set_scores VALUES (297, 316, 3, 25, 22);
INSERT INTO public.set_scores VALUES (298, 318, 1, 21, 25);
INSERT INTO public.set_scores VALUES (299, 318, 2, 25, 14);
INSERT INTO public.set_scores VALUES (300, 318, 3, 23, 25);
INSERT INTO public.set_scores VALUES (301, 318, 4, 25, 14);
INSERT INTO public.set_scores VALUES (302, 318, 5, 15, 8);
INSERT INTO public.set_scores VALUES (303, 317, 1, 25, 23);
INSERT INTO public.set_scores VALUES (304, 317, 2, 22, 25);
INSERT INTO public.set_scores VALUES (305, 317, 3, 25, 18);
INSERT INTO public.set_scores VALUES (306, 317, 4, 25, 19);
INSERT INTO public.set_scores VALUES (307, 321, 1, 26, 28);
INSERT INTO public.set_scores VALUES (308, 321, 2, 19, 25);
INSERT INTO public.set_scores VALUES (309, 321, 3, 25, 20);
INSERT INTO public.set_scores VALUES (310, 321, 4, 25, 27);
INSERT INTO public.set_scores VALUES (311, 315, 1, 30, 32);
INSERT INTO public.set_scores VALUES (312, 315, 2, 22, 25);
INSERT INTO public.set_scores VALUES (313, 315, 3, 22, 25);
INSERT INTO public.set_scores VALUES (314, 280, 1, 28, 26);
INSERT INTO public.set_scores VALUES (315, 280, 2, 25, 22);
INSERT INTO public.set_scores VALUES (316, 280, 3, 25, 22);
INSERT INTO public.set_scores VALUES (317, 284, 1, 25, 23);
INSERT INTO public.set_scores VALUES (318, 284, 2, 23, 25);
INSERT INTO public.set_scores VALUES (319, 284, 3, 23, 25);
INSERT INTO public.set_scores VALUES (320, 284, 4, 19, 25);
INSERT INTO public.set_scores VALUES (321, 322, 1, 23, 25);
INSERT INTO public.set_scores VALUES (322, 322, 2, 22, 25);
INSERT INTO public.set_scores VALUES (323, 322, 3, 25, 17);
INSERT INTO public.set_scores VALUES (324, 322, 4, 21, 25);
INSERT INTO public.set_scores VALUES (325, 325, 1, 20, 25);
INSERT INTO public.set_scores VALUES (326, 325, 2, 25, 23);
INSERT INTO public.set_scores VALUES (327, 325, 3, 27, 29);
INSERT INTO public.set_scores VALUES (328, 325, 4, 23, 25);
INSERT INTO public.set_scores VALUES (329, 326, 1, 20, 25);
INSERT INTO public.set_scores VALUES (330, 326, 2, 19, 25);
INSERT INTO public.set_scores VALUES (331, 326, 3, 22, 25);
INSERT INTO public.set_scores VALUES (332, 323, 1, 18, 25);
INSERT INTO public.set_scores VALUES (333, 323, 2, 25, 18);
INSERT INTO public.set_scores VALUES (334, 323, 3, 20, 25);
INSERT INTO public.set_scores VALUES (335, 323, 4, 25, 22);
INSERT INTO public.set_scores VALUES (336, 323, 5, 16, 18);
INSERT INTO public.set_scores VALUES (337, 324, 1, 23, 25);
INSERT INTO public.set_scores VALUES (338, 324, 2, 25, 22);
INSERT INTO public.set_scores VALUES (339, 324, 3, 25, 22);
INSERT INTO public.set_scores VALUES (340, 324, 4, 25, 20);
INSERT INTO public.set_scores VALUES (341, 331, 1, 28, 26);
INSERT INTO public.set_scores VALUES (342, 331, 2, 25, 19);
INSERT INTO public.set_scores VALUES (343, 331, 3, 17, 25);
INSERT INTO public.set_scores VALUES (344, 331, 4, 24, 26);
INSERT INTO public.set_scores VALUES (345, 331, 5, 13, 15);
INSERT INTO public.set_scores VALUES (346, 329, 1, 25, 15);
INSERT INTO public.set_scores VALUES (347, 329, 2, 25, 21);
INSERT INTO public.set_scores VALUES (348, 329, 3, 25, 22);
INSERT INTO public.set_scores VALUES (349, 332, 1, 25, 22);
INSERT INTO public.set_scores VALUES (350, 332, 2, 23, 25);
INSERT INTO public.set_scores VALUES (351, 332, 3, 25, 22);
INSERT INTO public.set_scores VALUES (352, 332, 4, 25, 20);
INSERT INTO public.set_scores VALUES (353, 330, 1, 25, 20);
INSERT INTO public.set_scores VALUES (354, 330, 2, 25, 15);
INSERT INTO public.set_scores VALUES (355, 330, 3, 25, 23);
INSERT INTO public.set_scores VALUES (356, 333, 1, 31, 29);
INSERT INTO public.set_scores VALUES (357, 333, 2, 25, 22);
INSERT INTO public.set_scores VALUES (358, 333, 3, 25, 14);
INSERT INTO public.set_scores VALUES (359, 334, 1, 23, 25);
INSERT INTO public.set_scores VALUES (360, 334, 2, 25, 23);
INSERT INTO public.set_scores VALUES (361, 334, 3, 13, 25);
INSERT INTO public.set_scores VALUES (362, 334, 4, 24, 26);
INSERT INTO public.set_scores VALUES (363, 335, 1, 21, 25);
INSERT INTO public.set_scores VALUES (364, 335, 2, 23, 25);
INSERT INTO public.set_scores VALUES (365, 335, 3, 20, 25);
INSERT INTO public.set_scores VALUES (366, 339, 1, 23, 25);
INSERT INTO public.set_scores VALUES (367, 339, 2, 25, 21);
INSERT INTO public.set_scores VALUES (368, 339, 3, 26, 28);
INSERT INTO public.set_scores VALUES (369, 339, 4, 26, 28);
INSERT INTO public.set_scores VALUES (370, 342, 1, 18, 25);
INSERT INTO public.set_scores VALUES (371, 342, 2, 16, 25);
INSERT INTO public.set_scores VALUES (372, 342, 3, 22, 25);
INSERT INTO public.set_scores VALUES (373, 338, 1, 21, 25);
INSERT INTO public.set_scores VALUES (374, 338, 2, 25, 18);
INSERT INTO public.set_scores VALUES (375, 338, 3, 33, 31);
INSERT INTO public.set_scores VALUES (376, 338, 4, 25, 22);
INSERT INTO public.set_scores VALUES (377, 337, 1, 25, 19);
INSERT INTO public.set_scores VALUES (378, 337, 2, 25, 16);
INSERT INTO public.set_scores VALUES (379, 337, 3, 25, 22);
INSERT INTO public.set_scores VALUES (380, 336, 1, 25, 16);
INSERT INTO public.set_scores VALUES (381, 336, 2, 18, 25);
INSERT INTO public.set_scores VALUES (382, 336, 3, 25, 22);
INSERT INTO public.set_scores VALUES (383, 336, 4, 25, 21);
INSERT INTO public.set_scores VALUES (384, 341, 1, 25, 18);
INSERT INTO public.set_scores VALUES (385, 341, 2, 22, 25);
INSERT INTO public.set_scores VALUES (386, 341, 3, 23, 25);
INSERT INTO public.set_scores VALUES (387, 341, 4, 19, 25);
INSERT INTO public.set_scores VALUES (388, 340, 1, 23, 25);
INSERT INTO public.set_scores VALUES (389, 340, 2, 25, 19);
INSERT INTO public.set_scores VALUES (390, 340, 3, 23, 25);
INSERT INTO public.set_scores VALUES (391, 340, 4, 20, 25);
INSERT INTO public.set_scores VALUES (392, 347, 1, 18, 25);
INSERT INTO public.set_scores VALUES (393, 347, 2, 25, 20);
INSERT INTO public.set_scores VALUES (394, 347, 3, 25, 22);
INSERT INTO public.set_scores VALUES (395, 347, 4, 25, 21);
INSERT INTO public.set_scores VALUES (396, 348, 1, 25, 23);
INSERT INTO public.set_scores VALUES (397, 348, 2, 23, 25);
INSERT INTO public.set_scores VALUES (398, 348, 3, 25, 23);
INSERT INTO public.set_scores VALUES (399, 348, 4, 25, 27);
INSERT INTO public.set_scores VALUES (400, 348, 5, 15, 12);
INSERT INTO public.set_scores VALUES (401, 345, 1, 18, 25);
INSERT INTO public.set_scores VALUES (402, 345, 2, 18, 25);
INSERT INTO public.set_scores VALUES (403, 345, 3, 25, 19);
INSERT INTO public.set_scores VALUES (404, 345, 4, 22, 25);
INSERT INTO public.set_scores VALUES (405, 343, 1, 18, 25);
INSERT INTO public.set_scores VALUES (406, 343, 2, 25, 22);
INSERT INTO public.set_scores VALUES (407, 343, 3, 22, 25);
INSERT INTO public.set_scores VALUES (408, 343, 4, 25, 27);
INSERT INTO public.set_scores VALUES (409, 349, 1, 28, 26);
INSERT INTO public.set_scores VALUES (410, 349, 2, 31, 29);
INSERT INTO public.set_scores VALUES (411, 349, 3, 25, 21);
INSERT INTO public.set_scores VALUES (412, 346, 1, 21, 25);
INSERT INTO public.set_scores VALUES (413, 346, 2, 28, 30);
INSERT INTO public.set_scores VALUES (414, 346, 3, 16, 25);
INSERT INTO public.set_scores VALUES (415, 344, 1, 21, 25);
INSERT INTO public.set_scores VALUES (416, 344, 2, 25, 21);
INSERT INTO public.set_scores VALUES (417, 344, 3, 25, 20);
INSERT INTO public.set_scores VALUES (418, 344, 4, 25, 17);
INSERT INTO public.set_scores VALUES (419, 355, 1, 25, 23);
INSERT INTO public.set_scores VALUES (420, 355, 2, 20, 25);
INSERT INTO public.set_scores VALUES (421, 355, 3, 23, 25);
INSERT INTO public.set_scores VALUES (422, 355, 4, 26, 24);
INSERT INTO public.set_scores VALUES (423, 355, 5, 10, 15);
INSERT INTO public.set_scores VALUES (424, 356, 1, 25, 22);
INSERT INTO public.set_scores VALUES (425, 356, 2, 15, 25);
INSERT INTO public.set_scores VALUES (426, 356, 3, 22, 25);
INSERT INTO public.set_scores VALUES (427, 356, 4, 19, 25);
INSERT INTO public.set_scores VALUES (428, 354, 1, 23, 25);
INSERT INTO public.set_scores VALUES (429, 354, 2, 25, 17);
INSERT INTO public.set_scores VALUES (430, 354, 3, 18, 25);
INSERT INTO public.set_scores VALUES (431, 354, 4, 25, 15);
INSERT INTO public.set_scores VALUES (432, 354, 5, 15, 13);
INSERT INTO public.set_scores VALUES (433, 351, 1, 25, 19);
INSERT INTO public.set_scores VALUES (434, 351, 2, 21, 25);
INSERT INTO public.set_scores VALUES (435, 351, 3, 25, 20);
INSERT INTO public.set_scores VALUES (436, 351, 4, 17, 25);
INSERT INTO public.set_scores VALUES (437, 351, 5, 16, 14);
INSERT INTO public.set_scores VALUES (438, 352, 1, 25, 18);
INSERT INTO public.set_scores VALUES (439, 352, 2, 25, 20);
INSERT INTO public.set_scores VALUES (440, 352, 3, 18, 25);
INSERT INTO public.set_scores VALUES (441, 352, 4, 25, 18);
INSERT INTO public.set_scores VALUES (442, 350, 1, 25, 20);
INSERT INTO public.set_scores VALUES (443, 350, 2, 25, 17);
INSERT INTO public.set_scores VALUES (444, 350, 3, 23, 25);
INSERT INTO public.set_scores VALUES (445, 350, 4, 27, 25);
INSERT INTO public.set_scores VALUES (446, 353, 1, 25, 13);
INSERT INTO public.set_scores VALUES (447, 353, 2, 25, 23);
INSERT INTO public.set_scores VALUES (448, 353, 3, 25, 17);
INSERT INTO public.set_scores VALUES (449, 359, 1, 26, 24);
INSERT INTO public.set_scores VALUES (450, 359, 2, 25, 23);
INSERT INTO public.set_scores VALUES (451, 359, 3, 20, 25);
INSERT INTO public.set_scores VALUES (452, 359, 4, 25, 19);
INSERT INTO public.set_scores VALUES (453, 363, 1, 20, 25);
INSERT INTO public.set_scores VALUES (454, 363, 2, 21, 25);
INSERT INTO public.set_scores VALUES (455, 363, 3, 25, 22);
INSERT INTO public.set_scores VALUES (456, 363, 4, 26, 24);
INSERT INTO public.set_scores VALUES (457, 363, 5, 11, 15);
INSERT INTO public.set_scores VALUES (458, 362, 1, 20, 25);
INSERT INTO public.set_scores VALUES (459, 362, 2, 24, 26);
INSERT INTO public.set_scores VALUES (460, 362, 3, 16, 25);
INSERT INTO public.set_scores VALUES (461, 361, 1, 23, 25);
INSERT INTO public.set_scores VALUES (462, 361, 2, 23, 25);
INSERT INTO public.set_scores VALUES (463, 361, 3, 22, 25);
INSERT INTO public.set_scores VALUES (464, 357, 1, 25, 23);
INSERT INTO public.set_scores VALUES (465, 357, 2, 26, 24);
INSERT INTO public.set_scores VALUES (466, 357, 3, 25, 12);
INSERT INTO public.set_scores VALUES (467, 360, 1, 26, 24);
INSERT INTO public.set_scores VALUES (468, 360, 2, 26, 28);
INSERT INTO public.set_scores VALUES (469, 360, 3, 16, 25);
INSERT INTO public.set_scores VALUES (470, 360, 4, 25, 17);
INSERT INTO public.set_scores VALUES (471, 360, 5, 15, 12);
INSERT INTO public.set_scores VALUES (472, 358, 1, 23, 25);
INSERT INTO public.set_scores VALUES (473, 358, 2, 27, 29);
INSERT INTO public.set_scores VALUES (474, 358, 3, 25, 19);
INSERT INTO public.set_scores VALUES (475, 358, 4, 25, 27);
INSERT INTO public.set_scores VALUES (476, 370, 1, 25, 21);
INSERT INTO public.set_scores VALUES (477, 370, 2, 15, 25);
INSERT INTO public.set_scores VALUES (478, 370, 3, 25, 23);
INSERT INTO public.set_scores VALUES (479, 370, 4, 25, 20);
INSERT INTO public.set_scores VALUES (480, 367, 1, 25, 18);
INSERT INTO public.set_scores VALUES (481, 367, 2, 25, 23);
INSERT INTO public.set_scores VALUES (482, 367, 3, 18, 25);
INSERT INTO public.set_scores VALUES (483, 367, 4, 22, 25);
INSERT INTO public.set_scores VALUES (484, 367, 5, 10, 15);
INSERT INTO public.set_scores VALUES (485, 366, 1, 22, 25);
INSERT INTO public.set_scores VALUES (486, 366, 2, 16, 25);
INSERT INTO public.set_scores VALUES (487, 366, 3, 21, 25);
INSERT INTO public.set_scores VALUES (488, 365, 1, 18, 25);
INSERT INTO public.set_scores VALUES (489, 365, 2, 25, 17);
INSERT INTO public.set_scores VALUES (490, 365, 3, 25, 23);
INSERT INTO public.set_scores VALUES (491, 365, 4, 19, 25);
INSERT INTO public.set_scores VALUES (492, 365, 5, 15, 12);
INSERT INTO public.set_scores VALUES (493, 364, 1, 25, 20);
INSERT INTO public.set_scores VALUES (494, 364, 2, 25, 14);
INSERT INTO public.set_scores VALUES (495, 364, 3, 25, 17);
INSERT INTO public.set_scores VALUES (496, 369, 1, 27, 25);
INSERT INTO public.set_scores VALUES (497, 369, 2, 25, 20);
INSERT INTO public.set_scores VALUES (498, 369, 3, 16, 25);
INSERT INTO public.set_scores VALUES (499, 369, 4, 23, 25);
INSERT INTO public.set_scores VALUES (500, 369, 5, 13, 15);
INSERT INTO public.set_scores VALUES (501, 368, 1, 25, 23);
INSERT INTO public.set_scores VALUES (502, 368, 2, 25, 23);
INSERT INTO public.set_scores VALUES (503, 368, 3, 22, 25);
INSERT INTO public.set_scores VALUES (504, 368, 4, 20, 25);
INSERT INTO public.set_scores VALUES (505, 368, 5, 21, 23);
INSERT INTO public.set_scores VALUES (506, 371, 1, 17, 25);
INSERT INTO public.set_scores VALUES (507, 371, 2, 19, 25);
INSERT INTO public.set_scores VALUES (508, 371, 3, 18, 25);
INSERT INTO public.set_scores VALUES (509, 372, 1, 25, 21);
INSERT INTO public.set_scores VALUES (510, 372, 2, 21, 25);
INSERT INTO public.set_scores VALUES (511, 372, 3, 15, 25);
INSERT INTO public.set_scores VALUES (512, 372, 4, 18, 25);
INSERT INTO public.set_scores VALUES (513, 377, 1, 18, 25);
INSERT INTO public.set_scores VALUES (514, 377, 2, 16, 25);
INSERT INTO public.set_scores VALUES (515, 377, 3, 16, 25);
INSERT INTO public.set_scores VALUES (516, 375, 1, 22, 25);
INSERT INTO public.set_scores VALUES (517, 375, 2, 25, 22);
INSERT INTO public.set_scores VALUES (518, 375, 3, 22, 25);
INSERT INTO public.set_scores VALUES (519, 375, 4, 19, 25);
INSERT INTO public.set_scores VALUES (520, 374, 1, 25, 21);
INSERT INTO public.set_scores VALUES (521, 374, 2, 25, 19);
INSERT INTO public.set_scores VALUES (522, 374, 3, 25, 20);
INSERT INTO public.set_scores VALUES (523, 376, 1, 15, 25);
INSERT INTO public.set_scores VALUES (524, 376, 2, 24, 26);
INSERT INTO public.set_scores VALUES (525, 376, 3, 16, 25);
INSERT INTO public.set_scores VALUES (526, 373, 1, 25, 22);
INSERT INTO public.set_scores VALUES (527, 373, 2, 25, 21);
INSERT INTO public.set_scores VALUES (528, 373, 3, 20, 25);
INSERT INTO public.set_scores VALUES (529, 373, 4, 16, 25);
INSERT INTO public.set_scores VALUES (530, 373, 5, 12, 15);
INSERT INTO public.set_scores VALUES (531, 378, 1, 25, 20);
INSERT INTO public.set_scores VALUES (532, 378, 2, 21, 25);
INSERT INTO public.set_scores VALUES (533, 378, 3, 22, 25);
INSERT INTO public.set_scores VALUES (534, 378, 4, 25, 20);
INSERT INTO public.set_scores VALUES (535, 378, 5, 15, 12);
INSERT INTO public.set_scores VALUES (536, 384, 1, 21, 25);
INSERT INTO public.set_scores VALUES (537, 384, 2, 25, 21);
INSERT INTO public.set_scores VALUES (538, 384, 3, 19, 25);
INSERT INTO public.set_scores VALUES (539, 384, 4, 25, 18);
INSERT INTO public.set_scores VALUES (540, 384, 5, 12, 15);
INSERT INTO public.set_scores VALUES (541, 381, 1, 25, 16);
INSERT INTO public.set_scores VALUES (542, 381, 2, 18, 25);
INSERT INTO public.set_scores VALUES (543, 381, 3, 18, 25);
INSERT INTO public.set_scores VALUES (544, 381, 4, 17, 25);
INSERT INTO public.set_scores VALUES (545, 380, 1, 13, 25);
INSERT INTO public.set_scores VALUES (546, 380, 2, 25, 20);
INSERT INTO public.set_scores VALUES (547, 380, 3, 29, 27);
INSERT INTO public.set_scores VALUES (548, 380, 4, 25, 20);
INSERT INTO public.set_scores VALUES (549, 382, 1, 22, 25);
INSERT INTO public.set_scores VALUES (550, 382, 2, 21, 25);
INSERT INTO public.set_scores VALUES (551, 382, 3, 21, 25);
INSERT INTO public.set_scores VALUES (552, 383, 1, 25, 16);
INSERT INTO public.set_scores VALUES (553, 383, 2, 25, 22);
INSERT INTO public.set_scores VALUES (554, 383, 3, 25, 23);
INSERT INTO public.set_scores VALUES (555, 379, 1, 25, 22);
INSERT INTO public.set_scores VALUES (556, 379, 2, 25, 23);
INSERT INTO public.set_scores VALUES (557, 379, 3, 25, 16);
INSERT INTO public.set_scores VALUES (558, 385, 1, 18, 25);
INSERT INTO public.set_scores VALUES (559, 385, 2, 23, 25);
INSERT INTO public.set_scores VALUES (560, 385, 3, 26, 24);
INSERT INTO public.set_scores VALUES (561, 385, 4, 15, 25);
INSERT INTO public.set_scores VALUES (562, 388, 1, 26, 24);
INSERT INTO public.set_scores VALUES (563, 388, 2, 35, 33);
INSERT INTO public.set_scores VALUES (564, 388, 3, 27, 25);
INSERT INTO public.set_scores VALUES (565, 387, 1, 25, 21);
INSERT INTO public.set_scores VALUES (566, 387, 2, 25, 21);
INSERT INTO public.set_scores VALUES (567, 387, 3, 20, 25);
INSERT INTO public.set_scores VALUES (568, 387, 4, 25, 23);
INSERT INTO public.set_scores VALUES (569, 389, 1, 25, 23);
INSERT INTO public.set_scores VALUES (570, 389, 2, 25, 18);
INSERT INTO public.set_scores VALUES (571, 389, 3, 22, 25);
INSERT INTO public.set_scores VALUES (572, 389, 4, 32, 34);
INSERT INTO public.set_scores VALUES (573, 389, 5, 15, 12);
INSERT INTO public.set_scores VALUES (574, 386, 1, 25, 20);
INSERT INTO public.set_scores VALUES (575, 386, 2, 25, 20);
INSERT INTO public.set_scores VALUES (576, 386, 3, 23, 25);
INSERT INTO public.set_scores VALUES (577, 386, 4, 21, 25);
INSERT INTO public.set_scores VALUES (578, 386, 5, 15, 11);
INSERT INTO public.set_scores VALUES (579, 391, 1, 25, 18);
INSERT INTO public.set_scores VALUES (580, 391, 2, 25, 21);
INSERT INTO public.set_scores VALUES (581, 391, 3, 19, 25);
INSERT INTO public.set_scores VALUES (582, 391, 4, 22, 25);
INSERT INTO public.set_scores VALUES (583, 391, 5, 13, 15);
INSERT INTO public.set_scores VALUES (584, 390, 1, 23, 25);
INSERT INTO public.set_scores VALUES (585, 390, 2, 25, 21);
INSERT INTO public.set_scores VALUES (586, 390, 3, 25, 21);
INSERT INTO public.set_scores VALUES (587, 390, 4, 25, 16);
INSERT INTO public.set_scores VALUES (588, 398, 1, 20, 25);
INSERT INTO public.set_scores VALUES (589, 398, 2, 25, 19);
INSERT INTO public.set_scores VALUES (590, 398, 3, 25, 19);
INSERT INTO public.set_scores VALUES (591, 398, 4, 18, 25);
INSERT INTO public.set_scores VALUES (592, 398, 5, 15, 13);
INSERT INTO public.set_scores VALUES (593, 397, 1, 17, 25);
INSERT INTO public.set_scores VALUES (594, 397, 2, 22, 25);
INSERT INTO public.set_scores VALUES (595, 397, 3, 19, 25);
INSERT INTO public.set_scores VALUES (596, 394, 1, 25, 21);
INSERT INTO public.set_scores VALUES (597, 394, 2, 22, 25);
INSERT INTO public.set_scores VALUES (598, 394, 3, 25, 20);
INSERT INTO public.set_scores VALUES (599, 394, 4, 25, 23);
INSERT INTO public.set_scores VALUES (600, 395, 1, 18, 25);
INSERT INTO public.set_scores VALUES (601, 395, 2, 17, 25);
INSERT INTO public.set_scores VALUES (602, 395, 3, 20, 25);
INSERT INTO public.set_scores VALUES (603, 393, 1, 27, 25);
INSERT INTO public.set_scores VALUES (604, 393, 2, 25, 20);
INSERT INTO public.set_scores VALUES (605, 393, 3, 25, 23);
INSERT INTO public.set_scores VALUES (606, 396, 1, 25, 21);
INSERT INTO public.set_scores VALUES (607, 396, 2, 22, 25);
INSERT INTO public.set_scores VALUES (608, 396, 3, 27, 25);
INSERT INTO public.set_scores VALUES (609, 396, 4, 25, 22);
INSERT INTO public.set_scores VALUES (610, 392, 1, 14, 25);
INSERT INTO public.set_scores VALUES (611, 392, 2, 25, 20);
INSERT INTO public.set_scores VALUES (612, 392, 3, 22, 25);
INSERT INTO public.set_scores VALUES (613, 392, 4, 18, 25);
INSERT INTO public.set_scores VALUES (614, 402, 1, 22, 25);
INSERT INTO public.set_scores VALUES (615, 402, 2, 23, 25);
INSERT INTO public.set_scores VALUES (616, 402, 3, 21, 25);
INSERT INTO public.set_scores VALUES (617, 400, 1, 23, 25);
INSERT INTO public.set_scores VALUES (618, 400, 2, 27, 25);
INSERT INTO public.set_scores VALUES (619, 400, 3, 25, 27);
INSERT INTO public.set_scores VALUES (620, 400, 4, 27, 29);
INSERT INTO public.set_scores VALUES (621, 401, 1, 25, 23);
INSERT INTO public.set_scores VALUES (622, 401, 2, 20, 25);
INSERT INTO public.set_scores VALUES (623, 401, 3, 25, 21);
INSERT INTO public.set_scores VALUES (624, 401, 4, 23, 25);
INSERT INTO public.set_scores VALUES (625, 401, 5, 15, 10);
INSERT INTO public.set_scores VALUES (626, 399, 1, 25, 19);
INSERT INTO public.set_scores VALUES (627, 399, 2, 23, 25);
INSERT INTO public.set_scores VALUES (628, 399, 3, 20, 25);
INSERT INTO public.set_scores VALUES (629, 399, 4, 23, 25);
INSERT INTO public.set_scores VALUES (630, 405, 1, 28, 26);
INSERT INTO public.set_scores VALUES (631, 405, 2, 23, 25);
INSERT INTO public.set_scores VALUES (632, 405, 3, 25, 12);
INSERT INTO public.set_scores VALUES (633, 405, 4, 25, 13);
INSERT INTO public.set_scores VALUES (634, 403, 1, 28, 30);
INSERT INTO public.set_scores VALUES (635, 403, 2, 18, 25);
INSERT INTO public.set_scores VALUES (636, 403, 3, 20, 25);
INSERT INTO public.set_scores VALUES (637, 404, 1, 25, 22);
INSERT INTO public.set_scores VALUES (638, 404, 2, 18, 25);
INSERT INTO public.set_scores VALUES (639, 404, 3, 25, 19);
INSERT INTO public.set_scores VALUES (640, 404, 4, 25, 21);
INSERT INTO public.set_scores VALUES (641, 412, 1, 25, 20);
INSERT INTO public.set_scores VALUES (642, 412, 2, 15, 25);
INSERT INTO public.set_scores VALUES (643, 412, 3, 25, 20);
INSERT INTO public.set_scores VALUES (644, 412, 4, 20, 25);
INSERT INTO public.set_scores VALUES (645, 412, 5, 12, 15);
INSERT INTO public.set_scores VALUES (646, 410, 1, 25, 21);
INSERT INTO public.set_scores VALUES (647, 410, 2, 19, 25);
INSERT INTO public.set_scores VALUES (648, 410, 3, 21, 25);
INSERT INTO public.set_scores VALUES (649, 410, 4, 19, 25);
INSERT INTO public.set_scores VALUES (650, 408, 1, 25, 22);
INSERT INTO public.set_scores VALUES (651, 408, 2, 19, 25);
INSERT INTO public.set_scores VALUES (652, 408, 3, 22, 25);
INSERT INTO public.set_scores VALUES (653, 408, 4, 27, 25);
INSERT INTO public.set_scores VALUES (654, 408, 5, 15, 11);
INSERT INTO public.set_scores VALUES (655, 411, 1, 25, 23);
INSERT INTO public.set_scores VALUES (656, 411, 2, 20, 25);
INSERT INTO public.set_scores VALUES (657, 411, 3, 23, 25);
INSERT INTO public.set_scores VALUES (658, 411, 4, 23, 25);
INSERT INTO public.set_scores VALUES (659, 407, 1, 20, 25);
INSERT INTO public.set_scores VALUES (660, 407, 2, 14, 25);
INSERT INTO public.set_scores VALUES (661, 407, 3, 16, 25);
INSERT INTO public.set_scores VALUES (662, 409, 1, 25, 19);
INSERT INTO public.set_scores VALUES (663, 409, 2, 25, 21);
INSERT INTO public.set_scores VALUES (664, 409, 3, 25, 20);
INSERT INTO public.set_scores VALUES (665, 406, 1, 25, 18);
INSERT INTO public.set_scores VALUES (666, 406, 2, 25, 21);
INSERT INTO public.set_scores VALUES (667, 406, 3, 30, 28);
INSERT INTO public.set_scores VALUES (668, 414, 1, 21, 25);
INSERT INTO public.set_scores VALUES (669, 414, 2, 27, 25);
INSERT INTO public.set_scores VALUES (670, 414, 3, 18, 25);
INSERT INTO public.set_scores VALUES (671, 414, 4, 25, 21);
INSERT INTO public.set_scores VALUES (672, 414, 5, 17, 19);
INSERT INTO public.set_scores VALUES (673, 418, 1, 20, 25);
INSERT INTO public.set_scores VALUES (674, 418, 2, 20, 25);
INSERT INTO public.set_scores VALUES (675, 418, 3, 25, 23);
INSERT INTO public.set_scores VALUES (676, 418, 4, 25, 20);
INSERT INTO public.set_scores VALUES (677, 418, 5, 12, 15);
INSERT INTO public.set_scores VALUES (678, 417, 1, 25, 23);
INSERT INTO public.set_scores VALUES (679, 417, 2, 21, 25);
INSERT INTO public.set_scores VALUES (680, 417, 3, 19, 25);
INSERT INTO public.set_scores VALUES (681, 417, 4, 25, 23);
INSERT INTO public.set_scores VALUES (682, 417, 5, 15, 10);
INSERT INTO public.set_scores VALUES (683, 413, 1, 25, 22);
INSERT INTO public.set_scores VALUES (684, 413, 2, 25, 18);
INSERT INTO public.set_scores VALUES (685, 413, 3, 22, 25);
INSERT INTO public.set_scores VALUES (686, 413, 4, 25, 21);
INSERT INTO public.set_scores VALUES (687, 416, 1, 25, 19);
INSERT INTO public.set_scores VALUES (688, 416, 2, 25, 14);
INSERT INTO public.set_scores VALUES (689, 416, 3, 25, 20);
INSERT INTO public.set_scores VALUES (690, 419, 1, 20, 25);
INSERT INTO public.set_scores VALUES (691, 419, 2, 16, 25);
INSERT INTO public.set_scores VALUES (692, 419, 3, 15, 25);
INSERT INTO public.set_scores VALUES (693, 415, 1, 25, 20);
INSERT INTO public.set_scores VALUES (694, 415, 2, 25, 20);
INSERT INTO public.set_scores VALUES (695, 415, 3, 25, 20);
INSERT INTO public.set_scores VALUES (1976, 449, 2, 22, 25);
INSERT INTO public.set_scores VALUES (1977, 449, 3, 28, 30);
INSERT INTO public.set_scores VALUES (1978, 449, 4, 24, 26);
INSERT INTO public.set_scores VALUES (1979, 450, 1, 21, 25);
INSERT INTO public.set_scores VALUES (1980, 450, 2, 25, 19);
INSERT INTO public.set_scores VALUES (1981, 450, 3, 25, 19);
INSERT INTO public.set_scores VALUES (1982, 450, 4, 25, 27);
INSERT INTO public.set_scores VALUES (1983, 450, 5, 12, 15);
INSERT INTO public.set_scores VALUES (1984, 451, 1, 25, 20);
INSERT INTO public.set_scores VALUES (1985, 451, 2, 29, 31);
INSERT INTO public.set_scores VALUES (1986, 451, 3, 26, 24);
INSERT INTO public.set_scores VALUES (1987, 451, 4, 17, 25);
INSERT INTO public.set_scores VALUES (1988, 451, 5, 17, 15);
INSERT INTO public.set_scores VALUES (1989, 452, 1, 25, 17);
INSERT INTO public.set_scores VALUES (1990, 452, 2, 23, 25);
INSERT INTO public.set_scores VALUES (1991, 452, 3, 19, 25);
INSERT INTO public.set_scores VALUES (1992, 452, 4, 25, 21);
INSERT INTO public.set_scores VALUES (1993, 452, 5, 15, 13);
INSERT INTO public.set_scores VALUES (1994, 453, 1, 18, 25);
INSERT INTO public.set_scores VALUES (1995, 453, 2, 22, 25);
INSERT INTO public.set_scores VALUES (1996, 453, 3, 25, 27);
INSERT INTO public.set_scores VALUES (1997, 459, 1, 23, 25);
INSERT INTO public.set_scores VALUES (1998, 459, 2, 20, 25);
INSERT INTO public.set_scores VALUES (1999, 459, 3, 25, 21);
INSERT INTO public.set_scores VALUES (2000, 459, 4, 25, 18);
INSERT INTO public.set_scores VALUES (2001, 459, 5, 15, 12);
INSERT INTO public.set_scores VALUES (2002, 460, 1, 22, 25);
INSERT INTO public.set_scores VALUES (2003, 460, 2, 21, 25);
INSERT INTO public.set_scores VALUES (2004, 460, 3, 27, 29);
INSERT INTO public.set_scores VALUES (2005, 454, 1, 19, 25);
INSERT INTO public.set_scores VALUES (2006, 454, 2, 21, 25);
INSERT INTO public.set_scores VALUES (2007, 454, 3, 11, 25);
INSERT INTO public.set_scores VALUES (2008, 455, 1, 25, 21);
INSERT INTO public.set_scores VALUES (2009, 455, 2, 25, 16);
INSERT INTO public.set_scores VALUES (2010, 455, 3, 25, 18);
INSERT INTO public.set_scores VALUES (2011, 456, 1, 27, 25);
INSERT INTO public.set_scores VALUES (2012, 456, 2, 24, 26);
INSERT INTO public.set_scores VALUES (2013, 456, 3, 24, 26);
INSERT INTO public.set_scores VALUES (2014, 456, 4, 23, 25);
INSERT INTO public.set_scores VALUES (2015, 457, 1, 25, 20);
INSERT INTO public.set_scores VALUES (2016, 457, 2, 25, 23);
INSERT INTO public.set_scores VALUES (2017, 457, 3, 18, 25);
INSERT INTO public.set_scores VALUES (2018, 457, 4, 21, 25);
INSERT INTO public.set_scores VALUES (2019, 457, 5, 12, 15);
INSERT INTO public.set_scores VALUES (2020, 458, 1, 25, 16);
INSERT INTO public.set_scores VALUES (2021, 458, 2, 25, 19);
INSERT INTO public.set_scores VALUES (2022, 458, 3, 25, 23);
INSERT INTO public.set_scores VALUES (2023, 461, 1, 25, 10);
INSERT INTO public.set_scores VALUES (2024, 461, 2, 22, 25);
INSERT INTO public.set_scores VALUES (2025, 461, 3, 23, 25);
INSERT INTO public.set_scores VALUES (2026, 461, 4, 25, 22);
INSERT INTO public.set_scores VALUES (2027, 461, 5, 20, 18);
INSERT INTO public.set_scores VALUES (2028, 462, 1, 25, 23);
INSERT INTO public.set_scores VALUES (2029, 462, 2, 21, 25);
INSERT INTO public.set_scores VALUES (2030, 462, 3, 17, 25);
INSERT INTO public.set_scores VALUES (2031, 462, 4, 23, 25);
INSERT INTO public.set_scores VALUES (2032, 463, 1, 25, 22);
INSERT INTO public.set_scores VALUES (2033, 463, 2, 15, 25);
INSERT INTO public.set_scores VALUES (2034, 463, 3, 18, 25);
INSERT INTO public.set_scores VALUES (2035, 463, 4, 18, 25);
INSERT INTO public.set_scores VALUES (2036, 464, 1, 16, 25);
INSERT INTO public.set_scores VALUES (2037, 464, 2, 25, 18);
INSERT INTO public.set_scores VALUES (2038, 464, 3, 25, 15);
INSERT INTO public.set_scores VALUES (2039, 464, 4, 25, 18);
INSERT INTO public.set_scores VALUES (2040, 465, 1, 23, 25);
INSERT INTO public.set_scores VALUES (2041, 465, 2, 18, 25);
INSERT INTO public.set_scores VALUES (2042, 465, 3, 15, 25);
INSERT INTO public.set_scores VALUES (2043, 466, 1, 15, 25);
INSERT INTO public.set_scores VALUES (2044, 466, 2, 18, 25);
INSERT INTO public.set_scores VALUES (2045, 466, 3, 25, 19);
INSERT INTO public.set_scores VALUES (2046, 466, 4, 25, 22);
INSERT INTO public.set_scores VALUES (2047, 466, 5, 7, 15);
INSERT INTO public.set_scores VALUES (2048, 467, 1, 23, 25);
INSERT INTO public.set_scores VALUES (2049, 467, 2, 25, 23);
INSERT INTO public.set_scores VALUES (2050, 467, 3, 25, 16);
INSERT INTO public.set_scores VALUES (2051, 467, 4, 25, 27);
INSERT INTO public.set_scores VALUES (2052, 467, 5, 15, 8);
INSERT INTO public.set_scores VALUES (2053, 468, 1, 25, 21);
INSERT INTO public.set_scores VALUES (2054, 468, 2, 25, 27);
INSERT INTO public.set_scores VALUES (2055, 468, 3, 25, 22);
INSERT INTO public.set_scores VALUES (2056, 468, 4, 12, 25);
INSERT INTO public.set_scores VALUES (2057, 468, 5, 19, 21);
INSERT INTO public.set_scores VALUES (2058, 469, 1, 25, 19);
INSERT INTO public.set_scores VALUES (2059, 469, 2, 23, 25);
INSERT INTO public.set_scores VALUES (2060, 469, 3, 21, 25);
INSERT INTO public.set_scores VALUES (2061, 469, 4, 21, 25);
INSERT INTO public.set_scores VALUES (2062, 470, 1, 25, 21);
INSERT INTO public.set_scores VALUES (2063, 470, 2, 25, 16);
INSERT INTO public.set_scores VALUES (2064, 470, 3, 25, 23);
INSERT INTO public.set_scores VALUES (2065, 471, 1, 22, 25);
INSERT INTO public.set_scores VALUES (2066, 471, 2, 20, 25);
INSERT INTO public.set_scores VALUES (2067, 471, 3, 21, 25);
INSERT INTO public.set_scores VALUES (2068, 472, 1, 25, 23);
INSERT INTO public.set_scores VALUES (2069, 472, 2, 21, 25);
INSERT INTO public.set_scores VALUES (2070, 472, 3, 20, 25);
INSERT INTO public.set_scores VALUES (2071, 472, 4, 25, 22);
INSERT INTO public.set_scores VALUES (2072, 472, 5, 11, 15);
INSERT INTO public.set_scores VALUES (2073, 473, 1, 25, 20);
INSERT INTO public.set_scores VALUES (2074, 473, 2, 27, 29);
INSERT INTO public.set_scores VALUES (2075, 473, 3, 25, 23);
INSERT INTO public.set_scores VALUES (2076, 473, 4, 25, 20);
INSERT INTO public.set_scores VALUES (2077, 474, 1, 23, 25);
INSERT INTO public.set_scores VALUES (2078, 474, 2, 25, 11);
INSERT INTO public.set_scores VALUES (2079, 474, 3, 29, 27);
INSERT INTO public.set_scores VALUES (2080, 474, 4, 25, 23);
INSERT INTO public.set_scores VALUES (2081, 475, 1, 25, 22);
INSERT INTO public.set_scores VALUES (2082, 475, 2, 25, 15);
INSERT INTO public.set_scores VALUES (2083, 475, 3, 25, 20);
INSERT INTO public.set_scores VALUES (2084, 476, 1, 25, 18);
INSERT INTO public.set_scores VALUES (2085, 476, 2, 25, 23);
INSERT INTO public.set_scores VALUES (2086, 476, 3, 25, 27);
INSERT INTO public.set_scores VALUES (2087, 476, 4, 19, 25);
INSERT INTO public.set_scores VALUES (2088, 476, 5, 9, 15);
INSERT INTO public.set_scores VALUES (2089, 477, 1, 21, 25);
INSERT INTO public.set_scores VALUES (2090, 477, 2, 20, 25);
INSERT INTO public.set_scores VALUES (2091, 477, 3, 23, 25);
INSERT INTO public.set_scores VALUES (2092, 479, 1, 23, 25);
INSERT INTO public.set_scores VALUES (2093, 479, 2, 21, 25);
INSERT INTO public.set_scores VALUES (2094, 479, 3, 25, 23);
INSERT INTO public.set_scores VALUES (2095, 479, 4, 25, 21);
INSERT INTO public.set_scores VALUES (2096, 479, 5, 13, 15);
INSERT INTO public.set_scores VALUES (2097, 480, 1, 32, 34);
INSERT INTO public.set_scores VALUES (2098, 480, 2, 25, 19);
INSERT INTO public.set_scores VALUES (2099, 480, 3, 27, 25);
INSERT INTO public.set_scores VALUES (2100, 480, 4, 25, 13);
INSERT INTO public.set_scores VALUES (2101, 481, 1, 23, 25);
INSERT INTO public.set_scores VALUES (2102, 481, 2, 17, 25);
INSERT INTO public.set_scores VALUES (2103, 481, 3, 25, 23);
INSERT INTO public.set_scores VALUES (2104, 481, 4, 25, 20);
INSERT INTO public.set_scores VALUES (2105, 481, 5, 17, 19);
INSERT INTO public.set_scores VALUES (2106, 478, 1, 25, 18);
INSERT INTO public.set_scores VALUES (2107, 478, 2, 25, 18);
INSERT INTO public.set_scores VALUES (2108, 478, 3, 25, 7);
INSERT INTO public.set_scores VALUES (2109, 482, 1, 22, 25);
INSERT INTO public.set_scores VALUES (2110, 482, 2, 25, 19);
INSERT INTO public.set_scores VALUES (2111, 482, 3, 25, 22);
INSERT INTO public.set_scores VALUES (2112, 482, 4, 18, 25);
INSERT INTO public.set_scores VALUES (2113, 482, 5, 12, 15);
INSERT INTO public.set_scores VALUES (2114, 483, 1, 25, 21);
INSERT INTO public.set_scores VALUES (2115, 483, 2, 25, 20);
INSERT INTO public.set_scores VALUES (2116, 483, 3, 25, 22);
INSERT INTO public.set_scores VALUES (2117, 484, 1, 19, 25);
INSERT INTO public.set_scores VALUES (2118, 484, 2, 22, 25);
INSERT INTO public.set_scores VALUES (2119, 484, 3, 20, 25);
INSERT INTO public.set_scores VALUES (2120, 485, 1, 26, 28);
INSERT INTO public.set_scores VALUES (2121, 485, 2, 23, 25);
INSERT INTO public.set_scores VALUES (2122, 485, 3, 18, 25);
INSERT INTO public.set_scores VALUES (2123, 486, 1, 25, 21);
INSERT INTO public.set_scores VALUES (2124, 486, 2, 25, 18);
INSERT INTO public.set_scores VALUES (2125, 486, 3, 17, 25);
INSERT INTO public.set_scores VALUES (2126, 486, 4, 25, 16);
INSERT INTO public.set_scores VALUES (2127, 487, 1, 25, 23);
INSERT INTO public.set_scores VALUES (2128, 487, 2, 23, 25);
INSERT INTO public.set_scores VALUES (2129, 487, 3, 17, 25);
INSERT INTO public.set_scores VALUES (2130, 487, 4, 25, 27);
INSERT INTO public.set_scores VALUES (2131, 488, 1, 25, 27);
INSERT INTO public.set_scores VALUES (2132, 488, 2, 23, 25);
INSERT INTO public.set_scores VALUES (2133, 488, 3, 18, 25);
INSERT INTO public.set_scores VALUES (2134, 489, 1, 27, 25);
INSERT INTO public.set_scores VALUES (2135, 489, 2, 25, 19);
INSERT INTO public.set_scores VALUES (2136, 489, 3, 25, 20);
INSERT INTO public.set_scores VALUES (2137, 490, 1, 25, 23);
INSERT INTO public.set_scores VALUES (2138, 490, 2, 23, 25);
INSERT INTO public.set_scores VALUES (2139, 490, 3, 20, 25);
INSERT INTO public.set_scores VALUES (2140, 490, 4, 15, 25);
INSERT INTO public.set_scores VALUES (2141, 491, 1, 22, 25);
INSERT INTO public.set_scores VALUES (2142, 491, 2, 25, 22);
INSERT INTO public.set_scores VALUES (2143, 491, 3, 21, 25);
INSERT INTO public.set_scores VALUES (2144, 491, 4, 25, 14);
INSERT INTO public.set_scores VALUES (2145, 491, 5, 15, 13);
INSERT INTO public.set_scores VALUES (2146, 492, 1, 25, 16);
INSERT INTO public.set_scores VALUES (2147, 492, 2, 26, 24);
INSERT INTO public.set_scores VALUES (2148, 492, 3, 25, 16);
INSERT INTO public.set_scores VALUES (2149, 493, 1, 22, 25);
INSERT INTO public.set_scores VALUES (2150, 493, 2, 23, 25);
INSERT INTO public.set_scores VALUES (2151, 493, 3, 20, 25);
INSERT INTO public.set_scores VALUES (2152, 494, 1, 16, 25);
INSERT INTO public.set_scores VALUES (2153, 494, 2, 27, 25);
INSERT INTO public.set_scores VALUES (2154, 494, 3, 25, 22);
INSERT INTO public.set_scores VALUES (2155, 494, 4, 25, 19);
INSERT INTO public.set_scores VALUES (2156, 495, 1, 25, 18);
INSERT INTO public.set_scores VALUES (2157, 495, 2, 25, 23);
INSERT INTO public.set_scores VALUES (2158, 495, 3, 26, 24);
INSERT INTO public.set_scores VALUES (2159, 502, 1, 25, 19);
INSERT INTO public.set_scores VALUES (2160, 502, 2, 25, 19);
INSERT INTO public.set_scores VALUES (2161, 502, 3, 33, 31);
INSERT INTO public.set_scores VALUES (2162, 501, 1, 25, 17);
INSERT INTO public.set_scores VALUES (2163, 501, 2, 25, 21);
INSERT INTO public.set_scores VALUES (2164, 501, 3, 25, 22);
INSERT INTO public.set_scores VALUES (2165, 500, 1, 21, 25);
INSERT INTO public.set_scores VALUES (2166, 500, 2, 25, 11);
INSERT INTO public.set_scores VALUES (2167, 500, 3, 25, 22);
INSERT INTO public.set_scores VALUES (2168, 500, 4, 25, 16);
INSERT INTO public.set_scores VALUES (2169, 499, 1, 24, 26);
INSERT INTO public.set_scores VALUES (2170, 499, 2, 23, 25);
INSERT INTO public.set_scores VALUES (2171, 499, 3, 19, 25);
INSERT INTO public.set_scores VALUES (2172, 498, 1, 23, 25);
INSERT INTO public.set_scores VALUES (2173, 498, 2, 25, 18);
INSERT INTO public.set_scores VALUES (2174, 498, 3, 23, 25);
INSERT INTO public.set_scores VALUES (2175, 498, 4, 17, 25);
INSERT INTO public.set_scores VALUES (2176, 497, 1, 25, 21);
INSERT INTO public.set_scores VALUES (2177, 497, 2, 21, 25);
INSERT INTO public.set_scores VALUES (2178, 497, 3, 25, 23);
INSERT INTO public.set_scores VALUES (2179, 497, 4, 25, 23);
INSERT INTO public.set_scores VALUES (2180, 496, 1, 25, 22);
INSERT INTO public.set_scores VALUES (2181, 496, 2, 22, 25);
INSERT INTO public.set_scores VALUES (2182, 496, 3, 20, 25);
INSERT INTO public.set_scores VALUES (2183, 496, 4, 22, 25);
INSERT INTO public.set_scores VALUES (2184, 509, 1, 25, 23);
INSERT INTO public.set_scores VALUES (2185, 509, 2, 25, 14);
INSERT INTO public.set_scores VALUES (2186, 509, 3, 25, 19);
INSERT INTO public.set_scores VALUES (2187, 508, 1, 21, 25);
INSERT INTO public.set_scores VALUES (2188, 508, 2, 25, 23);
INSERT INTO public.set_scores VALUES (2189, 508, 3, 20, 25);
INSERT INTO public.set_scores VALUES (2190, 508, 4, 16, 25);
INSERT INTO public.set_scores VALUES (2191, 507, 1, 19, 25);
INSERT INTO public.set_scores VALUES (2192, 507, 2, 14, 25);
INSERT INTO public.set_scores VALUES (2193, 507, 3, 17, 25);
INSERT INTO public.set_scores VALUES (2194, 506, 1, 25, 20);
INSERT INTO public.set_scores VALUES (2195, 506, 2, 22, 25);
INSERT INTO public.set_scores VALUES (2196, 506, 3, 16, 25);
INSERT INTO public.set_scores VALUES (2197, 506, 4, 23, 25);
INSERT INTO public.set_scores VALUES (2198, 505, 1, 19, 25);
INSERT INTO public.set_scores VALUES (2199, 505, 2, 22, 25);
INSERT INTO public.set_scores VALUES (2200, 505, 3, 31, 33);
INSERT INTO public.set_scores VALUES (2201, 504, 1, 15, 25);
INSERT INTO public.set_scores VALUES (2202, 504, 2, 27, 25);
INSERT INTO public.set_scores VALUES (2203, 504, 3, 26, 24);
INSERT INTO public.set_scores VALUES (2204, 504, 4, 25, 16);
INSERT INTO public.set_scores VALUES (2205, 503, 1, 25, 19);
INSERT INTO public.set_scores VALUES (2206, 503, 2, 26, 24);
INSERT INTO public.set_scores VALUES (2207, 503, 3, 25, 16);
INSERT INTO public.set_scores VALUES (2208, 516, 1, 21, 25);
INSERT INTO public.set_scores VALUES (2209, 516, 2, 25, 22);
INSERT INTO public.set_scores VALUES (2210, 516, 3, 25, 22);
INSERT INTO public.set_scores VALUES (2211, 516, 4, 25, 21);
INSERT INTO public.set_scores VALUES (2212, 515, 1, 26, 24);
INSERT INTO public.set_scores VALUES (2213, 515, 2, 25, 18);
INSERT INTO public.set_scores VALUES (2214, 515, 3, 25, 18);
INSERT INTO public.set_scores VALUES (2215, 514, 1, 25, 17);
INSERT INTO public.set_scores VALUES (2216, 514, 2, 26, 24);
INSERT INTO public.set_scores VALUES (2217, 514, 3, 25, 15);
INSERT INTO public.set_scores VALUES (2218, 513, 1, 17, 25);
INSERT INTO public.set_scores VALUES (2219, 513, 2, 23, 25);
INSERT INTO public.set_scores VALUES (2220, 513, 3, 19, 25);
INSERT INTO public.set_scores VALUES (2221, 512, 1, 19, 25);
INSERT INTO public.set_scores VALUES (2222, 512, 2, 21, 25);
INSERT INTO public.set_scores VALUES (2223, 512, 3, 25, 17);
INSERT INTO public.set_scores VALUES (2224, 512, 4, 25, 19);
INSERT INTO public.set_scores VALUES (2225, 512, 5, 14, 16);
INSERT INTO public.set_scores VALUES (2226, 511, 1, 25, 19);
INSERT INTO public.set_scores VALUES (2227, 511, 2, 23, 25);
INSERT INTO public.set_scores VALUES (2228, 511, 3, 23, 25);
INSERT INTO public.set_scores VALUES (2229, 511, 4, 17, 25);
INSERT INTO public.set_scores VALUES (2230, 510, 1, 25, 20);
INSERT INTO public.set_scores VALUES (2231, 510, 2, 23, 25);
INSERT INTO public.set_scores VALUES (2232, 510, 3, 29, 31);
INSERT INTO public.set_scores VALUES (2233, 510, 4, 16, 25);
INSERT INTO public.set_scores VALUES (2234, 523, 1, 25, 20);
INSERT INTO public.set_scores VALUES (2235, 523, 2, 25, 23);
INSERT INTO public.set_scores VALUES (2236, 523, 3, 20, 25);
INSERT INTO public.set_scores VALUES (2237, 523, 4, 25, 21);
INSERT INTO public.set_scores VALUES (2238, 522, 1, 21, 25);
INSERT INTO public.set_scores VALUES (2239, 522, 2, 25, 23);
INSERT INTO public.set_scores VALUES (2240, 522, 3, 13, 25);
INSERT INTO public.set_scores VALUES (2241, 522, 4, 19, 25);
INSERT INTO public.set_scores VALUES (2242, 520, 1, 27, 25);
INSERT INTO public.set_scores VALUES (2243, 520, 2, 25, 22);
INSERT INTO public.set_scores VALUES (2244, 520, 3, 25, 12);
INSERT INTO public.set_scores VALUES (2245, 519, 1, 17, 25);
INSERT INTO public.set_scores VALUES (2246, 519, 2, 25, 18);
INSERT INTO public.set_scores VALUES (2247, 519, 3, 22, 25);
INSERT INTO public.set_scores VALUES (2248, 519, 4, 22, 25);
INSERT INTO public.set_scores VALUES (2249, 518, 1, 15, 25);
INSERT INTO public.set_scores VALUES (2250, 518, 2, 25, 23);
INSERT INTO public.set_scores VALUES (2251, 518, 3, 25, 19);
INSERT INTO public.set_scores VALUES (2252, 518, 4, 19, 25);
INSERT INTO public.set_scores VALUES (2253, 518, 5, 15, 11);
INSERT INTO public.set_scores VALUES (2254, 517, 1, 25, 19);
INSERT INTO public.set_scores VALUES (2255, 517, 2, 25, 22);
INSERT INTO public.set_scores VALUES (2256, 517, 3, 20, 25);
INSERT INTO public.set_scores VALUES (2257, 517, 4, 25, 20);
INSERT INTO public.set_scores VALUES (2258, 521, 1, 25, 22);
INSERT INTO public.set_scores VALUES (2259, 521, 2, 27, 25);
INSERT INTO public.set_scores VALUES (2260, 521, 3, 22, 25);
INSERT INTO public.set_scores VALUES (2261, 521, 4, 23, 25);
INSERT INTO public.set_scores VALUES (2262, 521, 5, 10, 15);
INSERT INTO public.set_scores VALUES (2263, 524, 1, 21, 25);
INSERT INTO public.set_scores VALUES (2264, 524, 2, 25, 17);
INSERT INTO public.set_scores VALUES (2265, 524, 3, 25, 22);
INSERT INTO public.set_scores VALUES (2266, 524, 4, 24, 26);
INSERT INTO public.set_scores VALUES (2267, 524, 5, 12, 15);
INSERT INTO public.set_scores VALUES (2268, 525, 1, 15, 25);
INSERT INTO public.set_scores VALUES (2269, 525, 2, 25, 21);
INSERT INTO public.set_scores VALUES (2270, 525, 3, 20, 25);
INSERT INTO public.set_scores VALUES (2271, 525, 4, 16, 25);
INSERT INTO public.set_scores VALUES (2272, 526, 1, 18, 25);
INSERT INTO public.set_scores VALUES (2273, 526, 2, 20, 25);
INSERT INTO public.set_scores VALUES (2274, 526, 3, 23, 25);
INSERT INTO public.set_scores VALUES (2275, 527, 1, 17, 25);
INSERT INTO public.set_scores VALUES (2276, 527, 2, 16, 25);
INSERT INTO public.set_scores VALUES (2277, 527, 3, 25, 16);
INSERT INTO public.set_scores VALUES (2278, 527, 4, 25, 23);
INSERT INTO public.set_scores VALUES (2279, 527, 5, 11, 15);
INSERT INTO public.set_scores VALUES (2280, 528, 1, 25, 17);
INSERT INTO public.set_scores VALUES (2281, 528, 2, 25, 17);
INSERT INTO public.set_scores VALUES (2282, 528, 3, 24, 26);
INSERT INTO public.set_scores VALUES (2283, 528, 4, 25, 17);
INSERT INTO public.set_scores VALUES (2284, 529, 1, 36, 34);
INSERT INTO public.set_scores VALUES (2285, 529, 2, 25, 14);
INSERT INTO public.set_scores VALUES (2286, 529, 3, 25, 20);
INSERT INTO public.set_scores VALUES (2287, 530, 1, 25, 18);
INSERT INTO public.set_scores VALUES (2288, 530, 2, 22, 25);
INSERT INTO public.set_scores VALUES (2289, 530, 3, 25, 23);
INSERT INTO public.set_scores VALUES (2290, 530, 4, 25, 16);
INSERT INTO public.set_scores VALUES (2291, 537, 1, 17, 25);
INSERT INTO public.set_scores VALUES (2292, 537, 2, 22, 25);
INSERT INTO public.set_scores VALUES (2293, 537, 3, 25, 23);
INSERT INTO public.set_scores VALUES (2294, 537, 4, 16, 25);
INSERT INTO public.set_scores VALUES (2295, 536, 1, 17, 25);
INSERT INTO public.set_scores VALUES (2296, 536, 2, 17, 25);
INSERT INTO public.set_scores VALUES (2297, 536, 3, 22, 25);
INSERT INTO public.set_scores VALUES (2298, 535, 1, 25, 17);
INSERT INTO public.set_scores VALUES (2299, 535, 2, 25, 15);
INSERT INTO public.set_scores VALUES (2300, 535, 3, 28, 26);
INSERT INTO public.set_scores VALUES (2301, 534, 1, 22, 25);
INSERT INTO public.set_scores VALUES (2302, 534, 2, 21, 25);
INSERT INTO public.set_scores VALUES (2303, 534, 3, 23, 25);
INSERT INTO public.set_scores VALUES (2304, 533, 1, 29, 27);
INSERT INTO public.set_scores VALUES (2305, 533, 2, 23, 25);
INSERT INTO public.set_scores VALUES (2306, 533, 3, 25, 13);
INSERT INTO public.set_scores VALUES (2307, 533, 4, 25, 23);
INSERT INTO public.set_scores VALUES (2308, 532, 1, 16, 25);
INSERT INTO public.set_scores VALUES (2309, 532, 2, 16, 25);
INSERT INTO public.set_scores VALUES (2310, 532, 3, 21, 25);
INSERT INTO public.set_scores VALUES (2311, 531, 1, 23, 25);
INSERT INTO public.set_scores VALUES (2312, 531, 2, 25, 23);
INSERT INTO public.set_scores VALUES (2313, 531, 3, 20, 25);
INSERT INTO public.set_scores VALUES (2314, 531, 4, 22, 25);
INSERT INTO public.set_scores VALUES (2315, 544, 1, 28, 26);
INSERT INTO public.set_scores VALUES (2316, 544, 2, 23, 25);
INSERT INTO public.set_scores VALUES (2317, 544, 3, 25, 21);
INSERT INTO public.set_scores VALUES (2318, 544, 4, 25, 23);
INSERT INTO public.set_scores VALUES (2319, 543, 1, 25, 19);
INSERT INTO public.set_scores VALUES (2320, 543, 2, 26, 28);
INSERT INTO public.set_scores VALUES (2321, 543, 3, 25, 21);
INSERT INTO public.set_scores VALUES (2322, 543, 4, 25, 20);
INSERT INTO public.set_scores VALUES (2323, 542, 1, 25, 18);
INSERT INTO public.set_scores VALUES (2324, 542, 2, 26, 24);
INSERT INTO public.set_scores VALUES (2325, 542, 3, 25, 20);
INSERT INTO public.set_scores VALUES (2326, 541, 1, 19, 25);
INSERT INTO public.set_scores VALUES (2327, 541, 2, 25, 20);
INSERT INTO public.set_scores VALUES (2328, 541, 3, 20, 25);
INSERT INTO public.set_scores VALUES (2329, 541, 4, 13, 25);
INSERT INTO public.set_scores VALUES (2330, 540, 1, 22, 25);
INSERT INTO public.set_scores VALUES (2331, 540, 2, 18, 25);
INSERT INTO public.set_scores VALUES (2332, 540, 3, 21, 25);
INSERT INTO public.set_scores VALUES (2333, 539, 1, 25, 22);
INSERT INTO public.set_scores VALUES (2334, 539, 2, 27, 25);
INSERT INTO public.set_scores VALUES (2335, 539, 3, 25, 17);
INSERT INTO public.set_scores VALUES (2336, 538, 1, 25, 21);
INSERT INTO public.set_scores VALUES (2337, 538, 2, 25, 13);
INSERT INTO public.set_scores VALUES (2338, 538, 3, 25, 19);
INSERT INTO public.set_scores VALUES (2339, 551, 1, 25, 18);
INSERT INTO public.set_scores VALUES (2340, 551, 2, 21, 25);
INSERT INTO public.set_scores VALUES (2341, 551, 3, 25, 20);
INSERT INTO public.set_scores VALUES (2342, 551, 4, 23, 25);
INSERT INTO public.set_scores VALUES (2343, 551, 5, 11, 15);
INSERT INTO public.set_scores VALUES (2344, 545, 1, 19, 25);
INSERT INTO public.set_scores VALUES (2345, 545, 2, 26, 28);
INSERT INTO public.set_scores VALUES (2346, 545, 3, 25, 19);
INSERT INTO public.set_scores VALUES (2347, 545, 4, 14, 25);
INSERT INTO public.set_scores VALUES (2348, 546, 1, 28, 30);
INSERT INTO public.set_scores VALUES (2349, 546, 2, 25, 12);
INSERT INTO public.set_scores VALUES (2350, 546, 3, 25, 18);
INSERT INTO public.set_scores VALUES (2351, 546, 4, 25, 17);
INSERT INTO public.set_scores VALUES (2352, 547, 1, 23, 25);
INSERT INTO public.set_scores VALUES (2353, 547, 2, 18, 25);
INSERT INTO public.set_scores VALUES (2354, 547, 3, 22, 25);
INSERT INTO public.set_scores VALUES (2355, 548, 1, 15, 25);
INSERT INTO public.set_scores VALUES (2356, 548, 2, 22, 25);
INSERT INTO public.set_scores VALUES (2357, 548, 3, 19, 25);
INSERT INTO public.set_scores VALUES (2358, 549, 1, 25, 19);
INSERT INTO public.set_scores VALUES (2359, 549, 2, 25, 15);
INSERT INTO public.set_scores VALUES (2360, 549, 3, 19, 25);
INSERT INTO public.set_scores VALUES (2361, 549, 4, 25, 23);
INSERT INTO public.set_scores VALUES (2362, 550, 1, 25, 21);
INSERT INTO public.set_scores VALUES (2363, 550, 2, 24, 26);
INSERT INTO public.set_scores VALUES (2364, 550, 3, 23, 25);
INSERT INTO public.set_scores VALUES (2365, 550, 4, 17, 25);
INSERT INTO public.set_scores VALUES (2366, 552, 1, 25, 21);
INSERT INTO public.set_scores VALUES (2367, 552, 2, 23, 25);
INSERT INTO public.set_scores VALUES (2368, 552, 3, 15, 25);
INSERT INTO public.set_scores VALUES (2369, 552, 4, 25, 21);
INSERT INTO public.set_scores VALUES (2370, 552, 5, 10, 15);
INSERT INTO public.set_scores VALUES (2371, 553, 1, 22, 25);
INSERT INTO public.set_scores VALUES (2372, 553, 2, 25, 23);
INSERT INTO public.set_scores VALUES (2373, 553, 3, 25, 13);
INSERT INTO public.set_scores VALUES (2374, 553, 4, 26, 28);
INSERT INTO public.set_scores VALUES (2375, 553, 5, 15, 7);
INSERT INTO public.set_scores VALUES (2376, 554, 1, 25, 17);
INSERT INTO public.set_scores VALUES (2377, 554, 2, 23, 25);
INSERT INTO public.set_scores VALUES (2378, 554, 3, 25, 23);
INSERT INTO public.set_scores VALUES (2379, 554, 4, 25, 14);
INSERT INTO public.set_scores VALUES (2380, 555, 1, 23, 25);
INSERT INTO public.set_scores VALUES (2381, 555, 2, 25, 20);
INSERT INTO public.set_scores VALUES (2382, 555, 3, 27, 25);
INSERT INTO public.set_scores VALUES (2383, 555, 4, 18, 25);
INSERT INTO public.set_scores VALUES (2384, 555, 5, 16, 18);
INSERT INTO public.set_scores VALUES (2385, 556, 1, 25, 23);
INSERT INTO public.set_scores VALUES (2386, 556, 2, 25, 23);
INSERT INTO public.set_scores VALUES (2387, 556, 3, 25, 20);
INSERT INTO public.set_scores VALUES (2388, 557, 1, 25, 13);
INSERT INTO public.set_scores VALUES (2389, 557, 2, 25, 23);
INSERT INTO public.set_scores VALUES (2390, 557, 3, 25, 19);
INSERT INTO public.set_scores VALUES (2391, 558, 1, 24, 26);
INSERT INTO public.set_scores VALUES (2392, 558, 2, 23, 25);
INSERT INTO public.set_scores VALUES (2393, 558, 3, 28, 30);
INSERT INTO public.set_scores VALUES (2394, 565, 1, 17, 25);
INSERT INTO public.set_scores VALUES (2395, 565, 2, 25, 20);
INSERT INTO public.set_scores VALUES (2396, 565, 3, 29, 27);
INSERT INTO public.set_scores VALUES (2397, 565, 4, 25, 19);
INSERT INTO public.set_scores VALUES (2398, 564, 1, 23, 25);
INSERT INTO public.set_scores VALUES (2399, 564, 2, 25, 27);
INSERT INTO public.set_scores VALUES (2400, 564, 3, 25, 23);
INSERT INTO public.set_scores VALUES (2401, 564, 4, 22, 25);
INSERT INTO public.set_scores VALUES (2402, 563, 1, 25, 21);
INSERT INTO public.set_scores VALUES (2403, 563, 2, 25, 15);
INSERT INTO public.set_scores VALUES (2404, 563, 3, 25, 16);
INSERT INTO public.set_scores VALUES (2405, 562, 1, 19, 25);
INSERT INTO public.set_scores VALUES (2406, 562, 2, 22, 25);
INSERT INTO public.set_scores VALUES (2407, 562, 3, 22, 25);
INSERT INTO public.set_scores VALUES (2408, 561, 1, 28, 26);
INSERT INTO public.set_scores VALUES (2409, 561, 2, 25, 15);
INSERT INTO public.set_scores VALUES (2410, 561, 3, 20, 25);
INSERT INTO public.set_scores VALUES (2411, 561, 4, 26, 24);
INSERT INTO public.set_scores VALUES (2412, 560, 1, 25, 12);
INSERT INTO public.set_scores VALUES (2413, 560, 2, 25, 21);
INSERT INTO public.set_scores VALUES (2414, 560, 3, 21, 25);
INSERT INTO public.set_scores VALUES (2415, 560, 4, 25, 23);
INSERT INTO public.set_scores VALUES (2416, 559, 1, 25, 19);
INSERT INTO public.set_scores VALUES (2417, 559, 2, 20, 25);
INSERT INTO public.set_scores VALUES (2418, 559, 3, 25, 18);
INSERT INTO public.set_scores VALUES (2419, 559, 4, 25, 23);
INSERT INTO public.set_scores VALUES (2420, 572, 1, 32, 30);
INSERT INTO public.set_scores VALUES (2421, 572, 2, 25, 22);
INSERT INTO public.set_scores VALUES (2422, 572, 3, 25, 20);
INSERT INTO public.set_scores VALUES (2423, 571, 1, 24, 26);
INSERT INTO public.set_scores VALUES (2424, 571, 2, 22, 25);
INSERT INTO public.set_scores VALUES (2425, 571, 3, 17, 25);
INSERT INTO public.set_scores VALUES (2426, 570, 1, 24, 26);
INSERT INTO public.set_scores VALUES (2427, 570, 2, 27, 25);
INSERT INTO public.set_scores VALUES (2428, 570, 3, 25, 23);
INSERT INTO public.set_scores VALUES (2429, 570, 4, 18, 25);
INSERT INTO public.set_scores VALUES (2430, 570, 5, 13, 15);
INSERT INTO public.set_scores VALUES (2431, 569, 1, 19, 25);
INSERT INTO public.set_scores VALUES (2432, 569, 2, 23, 25);
INSERT INTO public.set_scores VALUES (2433, 569, 3, 21, 25);
INSERT INTO public.set_scores VALUES (2434, 568, 1, 25, 17);
INSERT INTO public.set_scores VALUES (2435, 568, 2, 25, 21);
INSERT INTO public.set_scores VALUES (2436, 568, 3, 25, 22);
INSERT INTO public.set_scores VALUES (2437, 567, 1, 21, 25);
INSERT INTO public.set_scores VALUES (2438, 567, 2, 17, 25);
INSERT INTO public.set_scores VALUES (2439, 567, 3, 25, 17);
INSERT INTO public.set_scores VALUES (2440, 567, 4, 25, 20);
INSERT INTO public.set_scores VALUES (2441, 567, 5, 9, 15);
INSERT INTO public.set_scores VALUES (2442, 566, 1, 25, 20);
INSERT INTO public.set_scores VALUES (2443, 566, 2, 25, 22);
INSERT INTO public.set_scores VALUES (2444, 566, 3, 26, 24);
INSERT INTO public.set_scores VALUES (2445, 579, 1, 22, 25);
INSERT INTO public.set_scores VALUES (2446, 579, 2, 25, 21);
INSERT INTO public.set_scores VALUES (2447, 579, 3, 25, 22);
INSERT INTO public.set_scores VALUES (2448, 579, 4, 21, 25);
INSERT INTO public.set_scores VALUES (2449, 579, 5, 15, 8);
INSERT INTO public.set_scores VALUES (2450, 578, 1, 25, 17);
INSERT INTO public.set_scores VALUES (2451, 578, 2, 25, 27);
INSERT INTO public.set_scores VALUES (2452, 578, 3, 14, 25);
INSERT INTO public.set_scores VALUES (2453, 578, 4, 25, 21);
INSERT INTO public.set_scores VALUES (2454, 578, 5, 15, 11);
INSERT INTO public.set_scores VALUES (2455, 577, 1, 25, 27);
INSERT INTO public.set_scores VALUES (2456, 577, 2, 17, 25);
INSERT INTO public.set_scores VALUES (2457, 577, 3, 16, 25);
INSERT INTO public.set_scores VALUES (2458, 576, 1, 25, 21);
INSERT INTO public.set_scores VALUES (2459, 576, 2, 25, 19);
INSERT INTO public.set_scores VALUES (2460, 576, 3, 24, 26);
INSERT INTO public.set_scores VALUES (2461, 576, 4, 25, 22);
INSERT INTO public.set_scores VALUES (2462, 575, 1, 25, 22);
INSERT INTO public.set_scores VALUES (2463, 575, 2, 23, 25);
INSERT INTO public.set_scores VALUES (2464, 575, 3, 25, 21);
INSERT INTO public.set_scores VALUES (2465, 575, 4, 25, 18);
INSERT INTO public.set_scores VALUES (2466, 574, 1, 26, 24);
INSERT INTO public.set_scores VALUES (2467, 574, 2, 25, 13);
INSERT INTO public.set_scores VALUES (2468, 574, 3, 20, 25);
INSERT INTO public.set_scores VALUES (2469, 574, 4, 23, 25);
INSERT INTO public.set_scores VALUES (2470, 574, 5, 12, 15);
INSERT INTO public.set_scores VALUES (2471, 573, 1, 25, 19);
INSERT INTO public.set_scores VALUES (2472, 573, 2, 21, 25);
INSERT INTO public.set_scores VALUES (2473, 573, 3, 25, 17);
INSERT INTO public.set_scores VALUES (2474, 573, 4, 25, 18);
INSERT INTO public.set_scores VALUES (2475, 584, 1, 25, 20);
INSERT INTO public.set_scores VALUES (2476, 584, 2, 25, 19);
INSERT INTO public.set_scores VALUES (2477, 584, 3, 25, 17);
INSERT INTO public.set_scores VALUES (2478, 586, 1, 22, 25);
INSERT INTO public.set_scores VALUES (2479, 586, 2, 19, 25);
INSERT INTO public.set_scores VALUES (2480, 586, 3, 20, 25);
INSERT INTO public.set_scores VALUES (2481, 582, 1, 25, 19);
INSERT INTO public.set_scores VALUES (2482, 582, 2, 26, 24);
INSERT INTO public.set_scores VALUES (2483, 582, 3, 25, 20);
INSERT INTO public.set_scores VALUES (2484, 583, 1, 20, 25);
INSERT INTO public.set_scores VALUES (2485, 583, 2, 19, 25);
INSERT INTO public.set_scores VALUES (2486, 583, 3, 25, 19);
INSERT INTO public.set_scores VALUES (2487, 583, 4, 23, 25);
INSERT INTO public.set_scores VALUES (2488, 585, 1, 25, 21);
INSERT INTO public.set_scores VALUES (2489, 585, 2, 25, 17);
INSERT INTO public.set_scores VALUES (2490, 585, 3, 26, 24);
INSERT INTO public.set_scores VALUES (2491, 581, 1, 18, 25);
INSERT INTO public.set_scores VALUES (2492, 581, 2, 25, 18);
INSERT INTO public.set_scores VALUES (2493, 581, 3, 29, 31);
INSERT INTO public.set_scores VALUES (2494, 581, 4, 21, 25);
INSERT INTO public.set_scores VALUES (2495, 580, 1, 18, 25);
INSERT INTO public.set_scores VALUES (2496, 580, 2, 25, 18);
INSERT INTO public.set_scores VALUES (2497, 580, 3, 25, 18);
INSERT INTO public.set_scores VALUES (2498, 580, 4, 25, 23);
INSERT INTO public.set_scores VALUES (2499, 593, 1, 25, 20);
INSERT INTO public.set_scores VALUES (2500, 593, 2, 21, 25);
INSERT INTO public.set_scores VALUES (2501, 593, 3, 17, 25);
INSERT INTO public.set_scores VALUES (2502, 593, 4, 18, 25);
INSERT INTO public.set_scores VALUES (2503, 592, 1, 23, 25);
INSERT INTO public.set_scores VALUES (2504, 592, 2, 38, 40);
INSERT INTO public.set_scores VALUES (2505, 592, 3, 16, 25);
INSERT INTO public.set_scores VALUES (2506, 591, 1, 25, 27);
INSERT INTO public.set_scores VALUES (2507, 591, 2, 10, 25);
INSERT INTO public.set_scores VALUES (2508, 591, 3, 19, 25);
INSERT INTO public.set_scores VALUES (2509, 590, 1, 26, 24);
INSERT INTO public.set_scores VALUES (2510, 590, 2, 26, 24);
INSERT INTO public.set_scores VALUES (2511, 590, 3, 23, 25);
INSERT INTO public.set_scores VALUES (2512, 590, 4, 25, 23);
INSERT INTO public.set_scores VALUES (2513, 589, 1, 29, 27);
INSERT INTO public.set_scores VALUES (2514, 589, 2, 25, 20);
INSERT INTO public.set_scores VALUES (2515, 589, 3, 26, 24);
INSERT INTO public.set_scores VALUES (2516, 588, 1, 25, 16);
INSERT INTO public.set_scores VALUES (2517, 588, 2, 25, 27);
INSERT INTO public.set_scores VALUES (2518, 588, 3, 25, 17);
INSERT INTO public.set_scores VALUES (2519, 588, 4, 25, 23);
INSERT INTO public.set_scores VALUES (2520, 587, 1, 23, 25);
INSERT INTO public.set_scores VALUES (2521, 587, 2, 19, 25);
INSERT INTO public.set_scores VALUES (2522, 587, 3, 25, 23);
INSERT INTO public.set_scores VALUES (2523, 587, 4, 25, 21);
INSERT INTO public.set_scores VALUES (2524, 587, 5, 11, 15);
INSERT INTO public.set_scores VALUES (2525, 594, 1, 18, 25);
INSERT INTO public.set_scores VALUES (2526, 594, 2, 19, 25);
INSERT INTO public.set_scores VALUES (2527, 594, 3, 23, 25);
INSERT INTO public.set_scores VALUES (2528, 595, 1, 21, 25);
INSERT INTO public.set_scores VALUES (2529, 595, 2, 20, 25);
INSERT INTO public.set_scores VALUES (2530, 595, 3, 27, 25);
INSERT INTO public.set_scores VALUES (2531, 595, 4, 26, 24);
INSERT INTO public.set_scores VALUES (2532, 595, 5, 15, 9);
INSERT INTO public.set_scores VALUES (2533, 596, 1, 25, 19);
INSERT INTO public.set_scores VALUES (2534, 596, 2, 25, 16);
INSERT INTO public.set_scores VALUES (2535, 596, 3, 18, 25);
INSERT INTO public.set_scores VALUES (2536, 596, 4, 25, 20);
INSERT INTO public.set_scores VALUES (2537, 597, 1, 28, 26);
INSERT INTO public.set_scores VALUES (2538, 597, 2, 19, 25);
INSERT INTO public.set_scores VALUES (2539, 597, 3, 26, 28);
INSERT INTO public.set_scores VALUES (2540, 597, 4, 25, 22);
INSERT INTO public.set_scores VALUES (2541, 597, 5, 15, 13);
INSERT INTO public.set_scores VALUES (2542, 598, 1, 25, 19);
INSERT INTO public.set_scores VALUES (2543, 598, 2, 25, 18);
INSERT INTO public.set_scores VALUES (2544, 598, 3, 25, 20);
INSERT INTO public.set_scores VALUES (2545, 599, 1, 25, 20);
INSERT INTO public.set_scores VALUES (2546, 599, 2, 27, 25);
INSERT INTO public.set_scores VALUES (2547, 599, 3, 25, 23);
INSERT INTO public.set_scores VALUES (2548, 600, 1, 30, 28);
INSERT INTO public.set_scores VALUES (2549, 600, 2, 25, 22);
INSERT INTO public.set_scores VALUES (2550, 600, 3, 18, 25);
INSERT INTO public.set_scores VALUES (2551, 600, 4, 28, 26);
INSERT INTO public.set_scores VALUES (2552, 607, 1, 25, 21);
INSERT INTO public.set_scores VALUES (2553, 607, 2, 25, 21);
INSERT INTO public.set_scores VALUES (2554, 607, 3, 25, 17);
INSERT INTO public.set_scores VALUES (2555, 606, 1, 23, 25);
INSERT INTO public.set_scores VALUES (2556, 606, 2, 25, 23);
INSERT INTO public.set_scores VALUES (2557, 606, 3, 20, 25);
INSERT INTO public.set_scores VALUES (2558, 606, 4, 28, 26);
INSERT INTO public.set_scores VALUES (4820, 658, 1, 23, 25);
INSERT INTO public.set_scores VALUES (4821, 658, 2, 19, 25);
INSERT INTO public.set_scores VALUES (4822, 658, 3, 20, 25);
INSERT INTO public.set_scores VALUES (4823, 660, 1, 25, 22);
INSERT INTO public.set_scores VALUES (4824, 660, 2, 25, 21);
INSERT INTO public.set_scores VALUES (4825, 660, 3, 25, 19);
INSERT INTO public.set_scores VALUES (4826, 659, 1, 25, 23);
INSERT INTO public.set_scores VALUES (4827, 659, 2, 23, 25);
INSERT INTO public.set_scores VALUES (4828, 659, 3, 25, 19);
INSERT INTO public.set_scores VALUES (4829, 659, 4, 21, 25);
INSERT INTO public.set_scores VALUES (4830, 659, 5, 15, 13);
INSERT INTO public.set_scores VALUES (4831, 656, 1, 29, 27);
INSERT INTO public.set_scores VALUES (4832, 656, 2, 18, 25);
INSERT INTO public.set_scores VALUES (4833, 656, 3, 22, 25);
INSERT INTO public.set_scores VALUES (4834, 656, 4, 23, 25);
INSERT INTO public.set_scores VALUES (4835, 657, 1, 25, 23);
INSERT INTO public.set_scores VALUES (4836, 657, 2, 25, 17);
INSERT INTO public.set_scores VALUES (4837, 657, 3, 23, 25);
INSERT INTO public.set_scores VALUES (4838, 657, 4, 25, 23);
INSERT INTO public.set_scores VALUES (4839, 655, 1, 21, 25);
INSERT INTO public.set_scores VALUES (4840, 655, 2, 25, 23);
INSERT INTO public.set_scores VALUES (4841, 655, 3, 25, 19);
INSERT INTO public.set_scores VALUES (4842, 655, 4, 27, 29);
INSERT INTO public.set_scores VALUES (4843, 655, 5, 18, 16);
INSERT INTO public.set_scores VALUES (4844, 666, 1, 25, 21);
INSERT INTO public.set_scores VALUES (4845, 666, 2, 25, 27);
INSERT INTO public.set_scores VALUES (4846, 666, 3, 25, 18);
INSERT INTO public.set_scores VALUES (4847, 666, 4, 25, 20);
INSERT INTO public.set_scores VALUES (4858, 664, 1, 20, 25);
INSERT INTO public.set_scores VALUES (4859, 664, 2, 25, 21);
INSERT INTO public.set_scores VALUES (4860, 664, 3, 25, 13);
INSERT INTO public.set_scores VALUES (4861, 664, 4, 22, 25);
INSERT INTO public.set_scores VALUES (4862, 664, 5, 13, 15);
INSERT INTO public.set_scores VALUES (4863, 665, 1, 25, 21);
INSERT INTO public.set_scores VALUES (4864, 665, 2, 19, 25);
INSERT INTO public.set_scores VALUES (4865, 665, 3, 15, 25);
INSERT INTO public.set_scores VALUES (4866, 665, 4, 25, 22);
INSERT INTO public.set_scores VALUES (4867, 665, 5, 16, 14);
INSERT INTO public.set_scores VALUES (4868, 662, 1, 18, 25);
INSERT INTO public.set_scores VALUES (4869, 662, 2, 23, 25);
INSERT INTO public.set_scores VALUES (4870, 662, 3, 25, 23);
INSERT INTO public.set_scores VALUES (4871, 662, 4, 21, 25);
INSERT INTO public.set_scores VALUES (4872, 667, 1, 25, 15);
INSERT INTO public.set_scores VALUES (4873, 667, 2, 25, 14);
INSERT INTO public.set_scores VALUES (4874, 667, 3, 25, 18);
INSERT INTO public.set_scores VALUES (4875, 668, 1, 20, 25);
INSERT INTO public.set_scores VALUES (4876, 668, 2, 25, 23);
INSERT INTO public.set_scores VALUES (4877, 668, 3, 25, 19);
INSERT INTO public.set_scores VALUES (4878, 668, 4, 16, 25);
INSERT INTO public.set_scores VALUES (4879, 668, 5, 15, 11);
INSERT INTO public.set_scores VALUES (4880, 669, 1, 26, 24);
INSERT INTO public.set_scores VALUES (4881, 669, 2, 25, 23);
INSERT INTO public.set_scores VALUES (4882, 669, 3, 25, 15);
INSERT INTO public.set_scores VALUES (4883, 671, 1, 18, 25);
INSERT INTO public.set_scores VALUES (4884, 671, 2, 19, 25);
INSERT INTO public.set_scores VALUES (4885, 671, 3, 25, 27);
INSERT INTO public.set_scores VALUES (4886, 672, 1, 25, 17);
INSERT INTO public.set_scores VALUES (4887, 672, 2, 25, 21);
INSERT INTO public.set_scores VALUES (4888, 672, 3, 20, 25);
INSERT INTO public.set_scores VALUES (4889, 672, 4, 25, 23);
INSERT INTO public.set_scores VALUES (4890, 670, 1, 22, 25);
INSERT INTO public.set_scores VALUES (4891, 670, 2, 19, 25);
INSERT INTO public.set_scores VALUES (4892, 670, 3, 34, 36);
INSERT INTO public.set_scores VALUES (4893, 675, 1, 21, 25);
INSERT INTO public.set_scores VALUES (4894, 675, 2, 22, 25);
INSERT INTO public.set_scores VALUES (4895, 675, 3, 24, 26);
INSERT INTO public.set_scores VALUES (4896, 674, 1, 25, 21);
INSERT INTO public.set_scores VALUES (4897, 674, 2, 25, 22);
INSERT INTO public.set_scores VALUES (4898, 674, 3, 25, 22);
INSERT INTO public.set_scores VALUES (4899, 677, 1, 24, 26);
INSERT INTO public.set_scores VALUES (4900, 677, 2, 17, 25);
INSERT INTO public.set_scores VALUES (4901, 677, 3, 22, 25);
INSERT INTO public.set_scores VALUES (4902, 673, 1, 20, 25);
INSERT INTO public.set_scores VALUES (4903, 673, 2, 18, 25);
INSERT INTO public.set_scores VALUES (4904, 673, 3, 13, 25);
INSERT INTO public.set_scores VALUES (4905, 678, 1, 25, 21);
INSERT INTO public.set_scores VALUES (4906, 678, 2, 26, 24);
INSERT INTO public.set_scores VALUES (4907, 678, 3, 25, 23);
INSERT INTO public.set_scores VALUES (4908, 676, 1, 21, 25);
INSERT INTO public.set_scores VALUES (4909, 676, 2, 25, 21);
INSERT INTO public.set_scores VALUES (4910, 676, 3, 25, 19);
INSERT INTO public.set_scores VALUES (4911, 676, 4, 13, 25);
INSERT INTO public.set_scores VALUES (4912, 676, 5, 10, 15);
INSERT INTO public.set_scores VALUES (4913, 680, 1, 22, 25);
INSERT INTO public.set_scores VALUES (4914, 680, 2, 28, 30);
INSERT INTO public.set_scores VALUES (4915, 680, 3, 25, 23);
INSERT INTO public.set_scores VALUES (4916, 680, 4, 16, 25);
INSERT INTO public.set_scores VALUES (4917, 681, 1, 25, 22);
INSERT INTO public.set_scores VALUES (4918, 681, 2, 17, 25);
INSERT INTO public.set_scores VALUES (4919, 681, 3, 27, 25);
INSERT INTO public.set_scores VALUES (4920, 681, 4, 25, 21);
INSERT INTO public.set_scores VALUES (4921, 682, 1, 33, 35);
INSERT INTO public.set_scores VALUES (4922, 682, 2, 14, 25);
INSERT INTO public.set_scores VALUES (4923, 682, 3, 22, 25);
INSERT INTO public.set_scores VALUES (4924, 684, 1, 13, 25);
INSERT INTO public.set_scores VALUES (4925, 684, 2, 23, 25);
INSERT INTO public.set_scores VALUES (4926, 684, 3, 19, 25);
INSERT INTO public.set_scores VALUES (4927, 679, 1, 23, 25);
INSERT INTO public.set_scores VALUES (4928, 679, 2, 25, 17);
INSERT INTO public.set_scores VALUES (4929, 679, 3, 26, 24);
INSERT INTO public.set_scores VALUES (4930, 679, 4, 25, 21);
INSERT INTO public.set_scores VALUES (4931, 683, 1, 23, 25);
INSERT INTO public.set_scores VALUES (4932, 683, 2, 25, 17);
INSERT INTO public.set_scores VALUES (4933, 683, 3, 25, 15);
INSERT INTO public.set_scores VALUES (4934, 683, 4, 25, 18);
INSERT INTO public.set_scores VALUES (4935, 690, 1, 19, 25);
INSERT INTO public.set_scores VALUES (4936, 690, 2, 22, 25);
INSERT INTO public.set_scores VALUES (4937, 690, 3, 25, 20);
INSERT INTO public.set_scores VALUES (4938, 690, 4, 31, 29);
INSERT INTO public.set_scores VALUES (4939, 690, 5, 15, 6);
INSERT INTO public.set_scores VALUES (4952, 686, 1, 32, 30);
INSERT INTO public.set_scores VALUES (4953, 686, 2, 21, 25);
INSERT INTO public.set_scores VALUES (4954, 686, 3, 26, 24);
INSERT INTO public.set_scores VALUES (4955, 686, 4, 25, 21);
INSERT INTO public.set_scores VALUES (4956, 689, 1, 25, 18);
INSERT INTO public.set_scores VALUES (4957, 689, 2, 25, 22);
INSERT INTO public.set_scores VALUES (4958, 689, 3, 25, 20);
INSERT INTO public.set_scores VALUES (4959, 692, 1, 25, 22);
INSERT INTO public.set_scores VALUES (4960, 692, 2, 25, 16);
INSERT INTO public.set_scores VALUES (4961, 692, 3, 25, 18);
INSERT INTO public.set_scores VALUES (4962, 694, 1, 16, 25);
INSERT INTO public.set_scores VALUES (4963, 694, 2, 17, 25);
INSERT INTO public.set_scores VALUES (4964, 694, 3, 22, 25);
INSERT INTO public.set_scores VALUES (4965, 691, 1, 30, 28);
INSERT INTO public.set_scores VALUES (4966, 691, 2, 25, 17);
INSERT INTO public.set_scores VALUES (4967, 691, 3, 26, 24);
INSERT INTO public.set_scores VALUES (4968, 693, 1, 13, 25);
INSERT INTO public.set_scores VALUES (4969, 693, 2, 26, 28);
INSERT INTO public.set_scores VALUES (4970, 693, 3, 25, 20);
INSERT INTO public.set_scores VALUES (4971, 693, 4, 25, 23);
INSERT INTO public.set_scores VALUES (4972, 693, 5, 18, 20);
INSERT INTO public.set_scores VALUES (4973, 695, 1, 25, 22);
INSERT INTO public.set_scores VALUES (4974, 695, 2, 17, 25);
INSERT INTO public.set_scores VALUES (4975, 695, 3, 17, 25);
INSERT INTO public.set_scores VALUES (4976, 695, 4, 20, 25);
INSERT INTO public.set_scores VALUES (4977, 696, 1, 25, 18);
INSERT INTO public.set_scores VALUES (4978, 696, 2, 25, 16);
INSERT INTO public.set_scores VALUES (4979, 696, 3, 25, 22);
INSERT INTO public.set_scores VALUES (4980, 701, 1, 16, 25);
INSERT INTO public.set_scores VALUES (4981, 701, 2, 25, 22);
INSERT INTO public.set_scores VALUES (4982, 701, 3, 20, 25);
INSERT INTO public.set_scores VALUES (4983, 701, 4, 22, 25);
INSERT INTO public.set_scores VALUES (4984, 700, 1, 25, 16);
INSERT INTO public.set_scores VALUES (4985, 700, 2, 25, 22);
INSERT INTO public.set_scores VALUES (4986, 700, 3, 25, 14);
INSERT INTO public.set_scores VALUES (4987, 699, 1, 25, 21);
INSERT INTO public.set_scores VALUES (4988, 699, 2, 25, 21);
INSERT INTO public.set_scores VALUES (4989, 699, 3, 25, 20);
INSERT INTO public.set_scores VALUES (4990, 697, 1, 19, 25);
INSERT INTO public.set_scores VALUES (4991, 697, 2, 25, 21);
INSERT INTO public.set_scores VALUES (4992, 697, 3, 25, 21);
INSERT INTO public.set_scores VALUES (4993, 697, 4, 25, 15);
INSERT INTO public.set_scores VALUES (4994, 702, 1, 22, 25);
INSERT INTO public.set_scores VALUES (4995, 702, 2, 25, 27);
INSERT INTO public.set_scores VALUES (4996, 702, 3, 25, 18);
INSERT INTO public.set_scores VALUES (4997, 702, 4, 14, 25);
INSERT INTO public.set_scores VALUES (4998, 698, 1, 25, 20);
INSERT INTO public.set_scores VALUES (4999, 698, 2, 21, 25);
INSERT INTO public.set_scores VALUES (5000, 698, 3, 21, 25);
INSERT INTO public.set_scores VALUES (5001, 698, 4, 25, 20);
INSERT INTO public.set_scores VALUES (5002, 698, 5, 12, 15);
INSERT INTO public.set_scores VALUES (5003, 708, 1, 25, 10);
INSERT INTO public.set_scores VALUES (5004, 708, 2, 25, 16);
INSERT INTO public.set_scores VALUES (5005, 708, 3, 25, 17);
INSERT INTO public.set_scores VALUES (5006, 704, 1, 23, 25);
INSERT INTO public.set_scores VALUES (5007, 704, 2, 23, 25);
INSERT INTO public.set_scores VALUES (5008, 704, 3, 25, 18);
INSERT INTO public.set_scores VALUES (5009, 704, 4, 25, 16);
INSERT INTO public.set_scores VALUES (5010, 704, 5, 11, 15);
INSERT INTO public.set_scores VALUES (5011, 707, 1, 25, 20);
INSERT INTO public.set_scores VALUES (5012, 707, 2, 25, 20);
INSERT INTO public.set_scores VALUES (5013, 707, 3, 25, 27);
INSERT INTO public.set_scores VALUES (5014, 707, 4, 25, 21);
INSERT INTO public.set_scores VALUES (5015, 705, 1, 19, 25);
INSERT INTO public.set_scores VALUES (5016, 705, 2, 21, 25);
INSERT INTO public.set_scores VALUES (5017, 705, 3, 20, 25);
INSERT INTO public.set_scores VALUES (5018, 703, 1, 23, 25);
INSERT INTO public.set_scores VALUES (5019, 703, 2, 16, 25);
INSERT INTO public.set_scores VALUES (5020, 703, 3, 22, 25);
INSERT INTO public.set_scores VALUES (5021, 706, 1, 17, 25);
INSERT INTO public.set_scores VALUES (5022, 706, 2, 19, 25);
INSERT INTO public.set_scores VALUES (5023, 706, 3, 25, 18);
INSERT INTO public.set_scores VALUES (5024, 706, 4, 13, 25);
INSERT INTO public.set_scores VALUES (5025, 712, 1, 25, 20);
INSERT INTO public.set_scores VALUES (5026, 712, 2, 18, 25);
INSERT INTO public.set_scores VALUES (5027, 712, 3, 15, 25);
INSERT INTO public.set_scores VALUES (5028, 712, 4, 14, 25);
INSERT INTO public.set_scores VALUES (5029, 714, 1, 25, 23);
INSERT INTO public.set_scores VALUES (5030, 714, 2, 27, 29);
INSERT INTO public.set_scores VALUES (5031, 714, 3, 25, 18);
INSERT INTO public.set_scores VALUES (5032, 714, 4, 25, 21);
INSERT INTO public.set_scores VALUES (5033, 711, 1, 25, 19);
INSERT INTO public.set_scores VALUES (5034, 711, 2, 20, 25);
INSERT INTO public.set_scores VALUES (5035, 711, 3, 25, 17);
INSERT INTO public.set_scores VALUES (5036, 711, 4, 28, 26);
INSERT INTO public.set_scores VALUES (5037, 710, 1, 16, 25);
INSERT INTO public.set_scores VALUES (5038, 710, 2, 25, 23);
INSERT INTO public.set_scores VALUES (5039, 710, 3, 25, 21);
INSERT INTO public.set_scores VALUES (5040, 710, 4, 25, 19);
INSERT INTO public.set_scores VALUES (5041, 713, 1, 25, 11);
INSERT INTO public.set_scores VALUES (5042, 713, 2, 10, 25);
INSERT INTO public.set_scores VALUES (5043, 713, 3, 25, 22);
INSERT INTO public.set_scores VALUES (5044, 713, 4, 18, 25);
INSERT INTO public.set_scores VALUES (5045, 713, 5, 11, 15);
INSERT INTO public.set_scores VALUES (5046, 709, 1, 22, 25);
INSERT INTO public.set_scores VALUES (5047, 709, 2, 25, 23);
INSERT INTO public.set_scores VALUES (5048, 709, 3, 20, 25);
INSERT INTO public.set_scores VALUES (5049, 709, 4, 25, 23);
INSERT INTO public.set_scores VALUES (5050, 709, 5, 24, 26);
INSERT INTO public.set_scores VALUES (5051, 719, 1, 21, 25);
INSERT INTO public.set_scores VALUES (5052, 719, 2, 18, 25);
INSERT INTO public.set_scores VALUES (5053, 719, 3, 20, 25);
INSERT INTO public.set_scores VALUES (5064, 716, 1, 27, 25);
INSERT INTO public.set_scores VALUES (5065, 716, 2, 22, 25);
INSERT INTO public.set_scores VALUES (5066, 716, 3, 26, 24);
INSERT INTO public.set_scores VALUES (5067, 716, 4, 26, 28);
INSERT INTO public.set_scores VALUES (5068, 716, 5, 16, 14);
INSERT INTO public.set_scores VALUES (5069, 720, 1, 25, 23);
INSERT INTO public.set_scores VALUES (5070, 720, 2, 25, 17);
INSERT INTO public.set_scores VALUES (5071, 720, 3, 25, 19);
INSERT INTO public.set_scores VALUES (5072, 717, 1, 25, 18);
INSERT INTO public.set_scores VALUES (5073, 717, 2, 25, 21);
INSERT INTO public.set_scores VALUES (5074, 717, 3, 21, 25);
INSERT INTO public.set_scores VALUES (5075, 717, 4, 25, 11);
INSERT INTO public.set_scores VALUES (5076, 722, 1, 23, 25);
INSERT INTO public.set_scores VALUES (5077, 722, 2, 25, 19);
INSERT INTO public.set_scores VALUES (5078, 722, 3, 25, 18);
INSERT INTO public.set_scores VALUES (5079, 722, 4, 25, 20);
INSERT INTO public.set_scores VALUES (5080, 724, 1, 23, 25);
INSERT INTO public.set_scores VALUES (5081, 724, 2, 18, 25);
INSERT INTO public.set_scores VALUES (5082, 724, 3, 25, 23);
INSERT INTO public.set_scores VALUES (5083, 724, 4, 25, 17);
INSERT INTO public.set_scores VALUES (5084, 724, 5, 9, 15);
INSERT INTO public.set_scores VALUES (5085, 723, 1, 23, 25);
INSERT INTO public.set_scores VALUES (5086, 723, 2, 20, 25);
INSERT INTO public.set_scores VALUES (5087, 723, 3, 18, 25);
INSERT INTO public.set_scores VALUES (5088, 725, 1, 22, 25);
INSERT INTO public.set_scores VALUES (5089, 725, 2, 17, 25);
INSERT INTO public.set_scores VALUES (5090, 725, 3, 25, 19);
INSERT INTO public.set_scores VALUES (5091, 725, 4, 25, 20);
INSERT INTO public.set_scores VALUES (5092, 725, 5, 11, 15);
INSERT INTO public.set_scores VALUES (5093, 726, 1, 25, 21);
INSERT INTO public.set_scores VALUES (5094, 726, 2, 25, 22);
INSERT INTO public.set_scores VALUES (5095, 726, 3, 25, 15);
INSERT INTO public.set_scores VALUES (5096, 721, 1, 25, 18);
INSERT INTO public.set_scores VALUES (5097, 721, 2, 25, 21);
INSERT INTO public.set_scores VALUES (5098, 721, 3, 25, 20);
INSERT INTO public.set_scores VALUES (5099, 729, 1, 22, 25);
INSERT INTO public.set_scores VALUES (5100, 729, 2, 22, 25);
INSERT INTO public.set_scores VALUES (5101, 729, 3, 28, 26);
INSERT INTO public.set_scores VALUES (5102, 729, 4, 16, 25);
INSERT INTO public.set_scores VALUES (5103, 728, 1, 25, 22);
INSERT INTO public.set_scores VALUES (5104, 728, 2, 25, 20);
INSERT INTO public.set_scores VALUES (5105, 728, 3, 15, 25);
INSERT INTO public.set_scores VALUES (5106, 728, 4, 25, 23);
INSERT INTO public.set_scores VALUES (5107, 727, 1, 25, 22);
INSERT INTO public.set_scores VALUES (5108, 727, 2, 18, 25);
INSERT INTO public.set_scores VALUES (5109, 727, 3, 19, 25);
INSERT INTO public.set_scores VALUES (5110, 727, 4, 19, 25);
INSERT INTO public.set_scores VALUES (5111, 732, 1, 25, 27);
INSERT INTO public.set_scores VALUES (5112, 732, 2, 25, 23);
INSERT INTO public.set_scores VALUES (5113, 732, 3, 20, 25);
INSERT INTO public.set_scores VALUES (5114, 732, 4, 22, 25);
INSERT INTO public.set_scores VALUES (5115, 730, 1, 25, 18);
INSERT INTO public.set_scores VALUES (5116, 730, 2, 25, 20);
INSERT INTO public.set_scores VALUES (5117, 730, 3, 25, 20);
INSERT INTO public.set_scores VALUES (5118, 731, 1, 23, 25);
INSERT INTO public.set_scores VALUES (5119, 731, 2, 23, 25);
INSERT INTO public.set_scores VALUES (5120, 731, 3, 19, 25);
INSERT INTO public.set_scores VALUES (5121, 738, 1, 19, 25);
INSERT INTO public.set_scores VALUES (5122, 738, 2, 27, 25);
INSERT INTO public.set_scores VALUES (5123, 738, 3, 23, 25);
INSERT INTO public.set_scores VALUES (5124, 738, 4, 16, 25);
INSERT INTO public.set_scores VALUES (5125, 734, 1, 25, 16);
INSERT INTO public.set_scores VALUES (5126, 734, 2, 25, 18);
INSERT INTO public.set_scores VALUES (5127, 734, 3, 25, 22);
INSERT INTO public.set_scores VALUES (5128, 736, 1, 25, 16);
INSERT INTO public.set_scores VALUES (5129, 736, 2, 25, 16);
INSERT INTO public.set_scores VALUES (5130, 736, 3, 25, 20);
INSERT INTO public.set_scores VALUES (5131, 737, 1, 21, 25);
INSERT INTO public.set_scores VALUES (5132, 737, 2, 23, 25);
INSERT INTO public.set_scores VALUES (5133, 737, 3, 22, 25);
INSERT INTO public.set_scores VALUES (5134, 744, 1, 22, 25);
INSERT INTO public.set_scores VALUES (5135, 744, 2, 14, 25);
INSERT INTO public.set_scores VALUES (5136, 744, 3, 20, 25);
INSERT INTO public.set_scores VALUES (5137, 743, 1, 25, 20);
INSERT INTO public.set_scores VALUES (5138, 743, 2, 27, 29);
INSERT INTO public.set_scores VALUES (5139, 743, 3, 25, 19);
INSERT INTO public.set_scores VALUES (5140, 743, 4, 25, 18);
INSERT INTO public.set_scores VALUES (5141, 740, 1, 25, 18);
INSERT INTO public.set_scores VALUES (5142, 740, 2, 25, 21);
INSERT INTO public.set_scores VALUES (5143, 740, 3, 25, 14);
INSERT INTO public.set_scores VALUES (5144, 742, 1, 16, 25);
INSERT INTO public.set_scores VALUES (5145, 742, 2, 25, 20);
INSERT INTO public.set_scores VALUES (5146, 742, 3, 25, 14);
INSERT INTO public.set_scores VALUES (5147, 742, 4, 18, 25);
INSERT INTO public.set_scores VALUES (5148, 742, 5, 15, 7);
INSERT INTO public.set_scores VALUES (5149, 739, 1, 25, 19);
INSERT INTO public.set_scores VALUES (5150, 739, 2, 25, 22);
INSERT INTO public.set_scores VALUES (5151, 739, 3, 17, 25);
INSERT INTO public.set_scores VALUES (5152, 739, 4, 23, 25);
INSERT INTO public.set_scores VALUES (5153, 739, 5, 10, 15);
INSERT INTO public.set_scores VALUES (5154, 741, 1, 25, 21);
INSERT INTO public.set_scores VALUES (5155, 741, 2, 25, 15);
INSERT INTO public.set_scores VALUES (5156, 741, 3, 22, 25);
INSERT INTO public.set_scores VALUES (5157, 741, 4, 25, 14);
INSERT INTO public.set_scores VALUES (5158, 749, 1, 25, 20);
INSERT INTO public.set_scores VALUES (5159, 749, 2, 25, 20);
INSERT INTO public.set_scores VALUES (5160, 749, 3, 15, 25);
INSERT INTO public.set_scores VALUES (5161, 749, 4, 25, 17);
INSERT INTO public.set_scores VALUES (5162, 750, 1, 22, 25);
INSERT INTO public.set_scores VALUES (5163, 750, 2, 25, 19);
INSERT INTO public.set_scores VALUES (5164, 750, 3, 25, 23);
INSERT INTO public.set_scores VALUES (5165, 750, 4, 25, 23);
INSERT INTO public.set_scores VALUES (5166, 745, 1, 14, 25);
INSERT INTO public.set_scores VALUES (5167, 745, 2, 20, 25);
INSERT INTO public.set_scores VALUES (5168, 745, 3, 20, 25);
INSERT INTO public.set_scores VALUES (5169, 748, 1, 25, 21);
INSERT INTO public.set_scores VALUES (5170, 748, 2, 25, 23);
INSERT INTO public.set_scores VALUES (5171, 748, 3, 25, 18);
INSERT INTO public.set_scores VALUES (5172, 747, 1, 14, 25);
INSERT INTO public.set_scores VALUES (5173, 747, 2, 36, 38);
INSERT INTO public.set_scores VALUES (5174, 747, 3, 19, 25);
INSERT INTO public.set_scores VALUES (5175, 746, 1, 25, 27);
INSERT INTO public.set_scores VALUES (5176, 746, 2, 25, 27);
INSERT INTO public.set_scores VALUES (5177, 746, 3, 25, 18);
INSERT INTO public.set_scores VALUES (5178, 746, 4, 25, 22);
INSERT INTO public.set_scores VALUES (5179, 746, 5, 11, 15);
INSERT INTO public.set_scores VALUES (5180, 751, 1, 25, 27);
INSERT INTO public.set_scores VALUES (5181, 751, 2, 27, 25);
INSERT INTO public.set_scores VALUES (5182, 751, 3, 26, 24);
INSERT INTO public.set_scores VALUES (5183, 751, 4, 25, 21);
INSERT INTO public.set_scores VALUES (5184, 753, 1, 23, 25);
INSERT INTO public.set_scores VALUES (5185, 753, 2, 25, 18);
INSERT INTO public.set_scores VALUES (5186, 753, 3, 25, 19);
INSERT INTO public.set_scores VALUES (5187, 753, 4, 25, 19);
INSERT INTO public.set_scores VALUES (5188, 755, 1, 20, 25);
INSERT INTO public.set_scores VALUES (5189, 755, 2, 36, 34);
INSERT INTO public.set_scores VALUES (5190, 755, 3, 25, 21);
INSERT INTO public.set_scores VALUES (5191, 755, 4, 25, 15);
INSERT INTO public.set_scores VALUES (5192, 752, 1, 25, 21);
INSERT INTO public.set_scores VALUES (5193, 752, 2, 25, 19);
INSERT INTO public.set_scores VALUES (5194, 752, 3, 25, 16);
INSERT INTO public.set_scores VALUES (5195, 754, 1, 25, 17);
INSERT INTO public.set_scores VALUES (5196, 754, 2, 25, 20);
INSERT INTO public.set_scores VALUES (5197, 754, 3, 25, 21);
INSERT INTO public.set_scores VALUES (5198, 756, 1, 26, 24);
INSERT INTO public.set_scores VALUES (5199, 756, 2, 25, 20);
INSERT INTO public.set_scores VALUES (5200, 756, 3, 23, 25);
INSERT INTO public.set_scores VALUES (5201, 756, 4, 25, 21);
INSERT INTO public.set_scores VALUES (5202, 757, 1, 17, 25);
INSERT INTO public.set_scores VALUES (5203, 757, 2, 24, 26);
INSERT INTO public.set_scores VALUES (5204, 757, 3, 21, 25);
INSERT INTO public.set_scores VALUES (5205, 760, 1, 25, 22);
INSERT INTO public.set_scores VALUES (5206, 760, 2, 15, 25);
INSERT INTO public.set_scores VALUES (5207, 760, 3, 15, 25);
INSERT INTO public.set_scores VALUES (5208, 760, 4, 23, 25);
INSERT INTO public.set_scores VALUES (5209, 761, 1, 22, 25);
INSERT INTO public.set_scores VALUES (5210, 761, 2, 26, 24);
INSERT INTO public.set_scores VALUES (5211, 761, 3, 18, 25);
INSERT INTO public.set_scores VALUES (5212, 761, 4, 15, 25);
INSERT INTO public.set_scores VALUES (5213, 758, 1, 25, 18);
INSERT INTO public.set_scores VALUES (5214, 758, 2, 33, 35);
INSERT INTO public.set_scores VALUES (5215, 758, 3, 25, 20);
INSERT INTO public.set_scores VALUES (5216, 758, 4, 25, 22);
INSERT INTO public.set_scores VALUES (5217, 759, 1, 25, 27);
INSERT INTO public.set_scores VALUES (5218, 759, 2, 25, 20);
INSERT INTO public.set_scores VALUES (5219, 759, 3, 23, 25);
INSERT INTO public.set_scores VALUES (5220, 759, 4, 27, 29);
INSERT INTO public.set_scores VALUES (5221, 762, 1, 25, 21);
INSERT INTO public.set_scores VALUES (5222, 762, 2, 19, 25);
INSERT INTO public.set_scores VALUES (5223, 762, 3, 26, 24);
INSERT INTO public.set_scores VALUES (5224, 762, 4, 30, 28);
INSERT INTO public.set_scores VALUES (5225, 764, 1, 25, 20);
INSERT INTO public.set_scores VALUES (5226, 764, 2, 25, 19);
INSERT INTO public.set_scores VALUES (5227, 764, 3, 27, 25);
INSERT INTO public.set_scores VALUES (5228, 767, 1, 20, 25);
INSERT INTO public.set_scores VALUES (5229, 767, 2, 19, 25);
INSERT INTO public.set_scores VALUES (5230, 767, 3, 20, 25);
INSERT INTO public.set_scores VALUES (5231, 765, 1, 25, 20);
INSERT INTO public.set_scores VALUES (5232, 765, 2, 25, 22);
INSERT INTO public.set_scores VALUES (5233, 765, 3, 25, 23);
INSERT INTO public.set_scores VALUES (5234, 766, 1, 23, 25);
INSERT INTO public.set_scores VALUES (5235, 766, 2, 25, 17);
INSERT INTO public.set_scores VALUES (5236, 766, 3, 25, 23);
INSERT INTO public.set_scores VALUES (5237, 766, 4, 25, 22);
INSERT INTO public.set_scores VALUES (5238, 768, 1, 25, 20);
INSERT INTO public.set_scores VALUES (5239, 768, 2, 16, 25);
INSERT INTO public.set_scores VALUES (5240, 768, 3, 18, 25);
INSERT INTO public.set_scores VALUES (5241, 768, 4, 25, 19);
INSERT INTO public.set_scores VALUES (5242, 768, 5, 11, 15);
INSERT INTO public.set_scores VALUES (5243, 763, 1, 23, 25);
INSERT INTO public.set_scores VALUES (5244, 763, 2, 25, 23);
INSERT INTO public.set_scores VALUES (5245, 763, 3, 25, 14);
INSERT INTO public.set_scores VALUES (5246, 763, 4, 25, 21);
INSERT INTO public.set_scores VALUES (5247, 773, 1, 25, 22);
INSERT INTO public.set_scores VALUES (5248, 773, 2, 25, 20);
INSERT INTO public.set_scores VALUES (5249, 773, 3, 25, 22);
INSERT INTO public.set_scores VALUES (5250, 769, 1, 25, 19);
INSERT INTO public.set_scores VALUES (5251, 769, 2, 20, 25);
INSERT INTO public.set_scores VALUES (5252, 769, 3, 25, 23);
INSERT INTO public.set_scores VALUES (2559, 606, 5, 9, 15);
INSERT INTO public.set_scores VALUES (2560, 605, 1, 25, 23);
INSERT INTO public.set_scores VALUES (2561, 605, 2, 22, 25);
INSERT INTO public.set_scores VALUES (2562, 605, 3, 22, 25);
INSERT INTO public.set_scores VALUES (2563, 605, 4, 24, 26);
INSERT INTO public.set_scores VALUES (2564, 604, 1, 22, 25);
INSERT INTO public.set_scores VALUES (2565, 604, 2, 25, 22);
INSERT INTO public.set_scores VALUES (2566, 604, 3, 20, 25);
INSERT INTO public.set_scores VALUES (2567, 604, 4, 17, 25);
INSERT INTO public.set_scores VALUES (2568, 603, 1, 19, 25);
INSERT INTO public.set_scores VALUES (2569, 603, 2, 18, 25);
INSERT INTO public.set_scores VALUES (2570, 603, 3, 21, 25);
INSERT INTO public.set_scores VALUES (2571, 602, 1, 25, 23);
INSERT INTO public.set_scores VALUES (2572, 602, 2, 23, 25);
INSERT INTO public.set_scores VALUES (2573, 602, 3, 21, 25);
INSERT INTO public.set_scores VALUES (2574, 602, 4, 25, 14);
INSERT INTO public.set_scores VALUES (2575, 602, 5, 17, 15);
INSERT INTO public.set_scores VALUES (2576, 601, 1, 25, 20);
INSERT INTO public.set_scores VALUES (2577, 601, 2, 23, 25);
INSERT INTO public.set_scores VALUES (2578, 601, 3, 25, 23);
INSERT INTO public.set_scores VALUES (2579, 601, 4, 14, 25);
INSERT INTO public.set_scores VALUES (2580, 601, 5, 15, 10);
INSERT INTO public.set_scores VALUES (2581, 608, 1, 30, 28);
INSERT INTO public.set_scores VALUES (2582, 608, 2, 25, 22);
INSERT INTO public.set_scores VALUES (2583, 608, 3, 22, 25);
INSERT INTO public.set_scores VALUES (2584, 608, 4, 25, 23);
INSERT INTO public.set_scores VALUES (2585, 609, 1, 21, 25);
INSERT INTO public.set_scores VALUES (2586, 609, 2, 25, 22);
INSERT INTO public.set_scores VALUES (2587, 609, 3, 25, 23);
INSERT INTO public.set_scores VALUES (2588, 609, 4, 25, 21);
INSERT INTO public.set_scores VALUES (2589, 610, 1, 32, 30);
INSERT INTO public.set_scores VALUES (2590, 610, 2, 27, 25);
INSERT INTO public.set_scores VALUES (2591, 610, 3, 25, 13);
INSERT INTO public.set_scores VALUES (2592, 611, 1, 18, 25);
INSERT INTO public.set_scores VALUES (2593, 611, 2, 23, 25);
INSERT INTO public.set_scores VALUES (2594, 611, 3, 26, 24);
INSERT INTO public.set_scores VALUES (2595, 611, 4, 16, 25);
INSERT INTO public.set_scores VALUES (2596, 612, 1, 22, 25);
INSERT INTO public.set_scores VALUES (2597, 612, 2, 25, 22);
INSERT INTO public.set_scores VALUES (2598, 612, 3, 17, 25);
INSERT INTO public.set_scores VALUES (2599, 612, 4, 16, 25);
INSERT INTO public.set_scores VALUES (2600, 613, 1, 18, 25);
INSERT INTO public.set_scores VALUES (2601, 613, 2, 23, 25);
INSERT INTO public.set_scores VALUES (2602, 613, 3, 19, 25);
INSERT INTO public.set_scores VALUES (2603, 614, 1, 25, 11);
INSERT INTO public.set_scores VALUES (2604, 614, 2, 25, 20);
INSERT INTO public.set_scores VALUES (2605, 614, 3, 25, 20);
INSERT INTO public.set_scores VALUES (2606, 616, 1, 25, 20);
INSERT INTO public.set_scores VALUES (2607, 616, 2, 25, 21);
INSERT INTO public.set_scores VALUES (2608, 616, 3, 20, 25);
INSERT INTO public.set_scores VALUES (2609, 616, 4, 23, 25);
INSERT INTO public.set_scores VALUES (2610, 616, 5, 11, 15);
INSERT INTO public.set_scores VALUES (2611, 617, 1, 21, 25);
INSERT INTO public.set_scores VALUES (2612, 617, 2, 13, 25);
INSERT INTO public.set_scores VALUES (2613, 617, 3, 20, 25);
INSERT INTO public.set_scores VALUES (2614, 618, 1, 25, 15);
INSERT INTO public.set_scores VALUES (2615, 618, 2, 26, 24);
INSERT INTO public.set_scores VALUES (2616, 618, 3, 29, 27);
INSERT INTO public.set_scores VALUES (2617, 619, 1, 27, 29);
INSERT INTO public.set_scores VALUES (2618, 619, 2, 18, 25);
INSERT INTO public.set_scores VALUES (2619, 619, 3, 15, 25);
INSERT INTO public.set_scores VALUES (2620, 620, 1, 25, 21);
INSERT INTO public.set_scores VALUES (2621, 620, 2, 26, 24);
INSERT INTO public.set_scores VALUES (2622, 620, 3, 23, 25);
INSERT INTO public.set_scores VALUES (2623, 620, 4, 25, 18);
INSERT INTO public.set_scores VALUES (2624, 621, 1, 25, 20);
INSERT INTO public.set_scores VALUES (2625, 621, 2, 25, 22);
INSERT INTO public.set_scores VALUES (2626, 621, 3, 22, 25);
INSERT INTO public.set_scores VALUES (2627, 621, 4, 25, 20);
INSERT INTO public.set_scores VALUES (2628, 615, 1, 23, 25);
INSERT INTO public.set_scores VALUES (2629, 615, 2, 12, 25);
INSERT INTO public.set_scores VALUES (2630, 615, 3, 18, 25);
INSERT INTO public.set_scores VALUES (2631, 628, 1, 25, 20);
INSERT INTO public.set_scores VALUES (2632, 628, 2, 25, 20);
INSERT INTO public.set_scores VALUES (2633, 628, 3, 25, 22);
INSERT INTO public.set_scores VALUES (2634, 627, 1, 25, 23);
INSERT INTO public.set_scores VALUES (2635, 627, 2, 25, 16);
INSERT INTO public.set_scores VALUES (2636, 627, 3, 25, 21);
INSERT INTO public.set_scores VALUES (2637, 626, 1, 25, 27);
INSERT INTO public.set_scores VALUES (2638, 626, 2, 25, 27);
INSERT INTO public.set_scores VALUES (2639, 626, 3, 13, 25);
INSERT INTO public.set_scores VALUES (2640, 625, 1, 25, 21);
INSERT INTO public.set_scores VALUES (2641, 625, 2, 25, 15);
INSERT INTO public.set_scores VALUES (2642, 625, 3, 23, 25);
INSERT INTO public.set_scores VALUES (2643, 625, 4, 26, 24);
INSERT INTO public.set_scores VALUES (2644, 624, 1, 29, 27);
INSERT INTO public.set_scores VALUES (2645, 624, 2, 25, 23);
INSERT INTO public.set_scores VALUES (2646, 624, 3, 19, 25);
INSERT INTO public.set_scores VALUES (2647, 624, 4, 25, 18);
INSERT INTO public.set_scores VALUES (2648, 623, 1, 25, 21);
INSERT INTO public.set_scores VALUES (2649, 623, 2, 26, 24);
INSERT INTO public.set_scores VALUES (2650, 623, 3, 17, 25);
INSERT INTO public.set_scores VALUES (2651, 623, 4, 18, 25);
INSERT INTO public.set_scores VALUES (2652, 623, 5, 9, 15);
INSERT INTO public.set_scores VALUES (2653, 622, 1, 25, 17);
INSERT INTO public.set_scores VALUES (2654, 622, 2, 25, 20);
INSERT INTO public.set_scores VALUES (2655, 622, 3, 19, 25);
INSERT INTO public.set_scores VALUES (2656, 622, 4, 25, 20);
INSERT INTO public.set_scores VALUES (5253, 769, 4, 25, 20);
INSERT INTO public.set_scores VALUES (5254, 771, 1, 17, 25);
INSERT INTO public.set_scores VALUES (5255, 771, 2, 21, 25);
INSERT INTO public.set_scores VALUES (5256, 771, 3, 21, 25);
INSERT INTO public.set_scores VALUES (5257, 774, 1, 25, 15);
INSERT INTO public.set_scores VALUES (5258, 774, 2, 25, 17);
INSERT INTO public.set_scores VALUES (5259, 774, 3, 31, 29);
INSERT INTO public.set_scores VALUES (5260, 770, 1, 20, 25);
INSERT INTO public.set_scores VALUES (5261, 770, 2, 25, 19);
INSERT INTO public.set_scores VALUES (5262, 770, 3, 22, 25);
INSERT INTO public.set_scores VALUES (5263, 770, 4, 26, 28);
INSERT INTO public.set_scores VALUES (5264, 772, 1, 25, 20);
INSERT INTO public.set_scores VALUES (5265, 772, 2, 21, 25);
INSERT INTO public.set_scores VALUES (5266, 772, 3, 25, 21);
INSERT INTO public.set_scores VALUES (5267, 772, 4, 25, 19);
INSERT INTO public.set_scores VALUES (5268, 779, 1, 25, 21);
INSERT INTO public.set_scores VALUES (5269, 779, 2, 25, 16);
INSERT INTO public.set_scores VALUES (5270, 779, 3, 19, 25);
INSERT INTO public.set_scores VALUES (5271, 779, 4, 29, 27);
INSERT INTO public.set_scores VALUES (5279, 780, 1, 31, 33);
INSERT INTO public.set_scores VALUES (5280, 780, 2, 25, 21);
INSERT INTO public.set_scores VALUES (5281, 780, 3, 27, 25);
INSERT INTO public.set_scores VALUES (5282, 780, 4, 22, 25);
INSERT INTO public.set_scores VALUES (5283, 780, 5, 13, 15);
INSERT INTO public.set_scores VALUES (5284, 775, 1, 22, 25);
INSERT INTO public.set_scores VALUES (5285, 775, 2, 25, 18);
INSERT INTO public.set_scores VALUES (5286, 775, 3, 25, 20);
INSERT INTO public.set_scores VALUES (5287, 775, 4, 25, 13);
INSERT INTO public.set_scores VALUES (5288, 777, 1, 21, 25);
INSERT INTO public.set_scores VALUES (5289, 777, 2, 17, 25);
INSERT INTO public.set_scores VALUES (5290, 777, 3, 30, 28);
INSERT INTO public.set_scores VALUES (5291, 777, 4, 25, 16);
INSERT INTO public.set_scores VALUES (5292, 777, 5, 16, 18);
INSERT INTO public.set_scores VALUES (5293, 784, 1, 17, 25);
INSERT INTO public.set_scores VALUES (5294, 784, 2, 25, 23);
INSERT INTO public.set_scores VALUES (5295, 784, 3, 21, 25);
INSERT INTO public.set_scores VALUES (5296, 784, 4, 23, 25);
INSERT INTO public.set_scores VALUES (5297, 783, 1, 25, 20);
INSERT INTO public.set_scores VALUES (5298, 783, 2, 25, 17);
INSERT INTO public.set_scores VALUES (5299, 783, 3, 25, 21);
INSERT INTO public.set_scores VALUES (5300, 785, 1, 15, 25);
INSERT INTO public.set_scores VALUES (5301, 785, 2, 23, 25);
INSERT INTO public.set_scores VALUES (5302, 785, 3, 25, 23);
INSERT INTO public.set_scores VALUES (5303, 785, 4, 25, 16);
INSERT INTO public.set_scores VALUES (5304, 785, 5, 15, 13);
INSERT INTO public.set_scores VALUES (5305, 782, 1, 25, 22);
INSERT INTO public.set_scores VALUES (5306, 782, 2, 25, 22);
INSERT INTO public.set_scores VALUES (5307, 782, 3, 25, 18);
INSERT INTO public.set_scores VALUES (5308, 781, 1, 19, 25);
INSERT INTO public.set_scores VALUES (5309, 781, 2, 20, 25);
INSERT INTO public.set_scores VALUES (5310, 781, 3, 23, 25);
INSERT INTO public.set_scores VALUES (5311, 786, 1, 25, 23);
INSERT INTO public.set_scores VALUES (5312, 786, 2, 12, 25);
INSERT INTO public.set_scores VALUES (5313, 786, 3, 28, 30);
INSERT INTO public.set_scores VALUES (5314, 786, 4, 19, 25);
INSERT INTO public.set_scores VALUES (5315, 787, 1, 25, 20);
INSERT INTO public.set_scores VALUES (5316, 787, 2, 18, 25);
INSERT INTO public.set_scores VALUES (5317, 787, 3, 25, 15);
INSERT INTO public.set_scores VALUES (5318, 787, 4, 19, 25);
INSERT INTO public.set_scores VALUES (5319, 787, 5, 15, 6);
INSERT INTO public.set_scores VALUES (5320, 788, 1, 25, 20);
INSERT INTO public.set_scores VALUES (5321, 788, 2, 25, 21);
INSERT INTO public.set_scores VALUES (5322, 788, 3, 20, 25);
INSERT INTO public.set_scores VALUES (5323, 788, 4, 21, 25);
INSERT INTO public.set_scores VALUES (5324, 788, 5, 10, 15);
INSERT INTO public.set_scores VALUES (5325, 790, 1, 25, 19);
INSERT INTO public.set_scores VALUES (5326, 790, 2, 25, 17);
INSERT INTO public.set_scores VALUES (5327, 790, 3, 25, 18);
INSERT INTO public.set_scores VALUES (5328, 792, 1, 25, 21);
INSERT INTO public.set_scores VALUES (5329, 792, 2, 25, 21);
INSERT INTO public.set_scores VALUES (5330, 792, 3, 25, 17);
INSERT INTO public.set_scores VALUES (5331, 789, 1, 25, 22);
INSERT INTO public.set_scores VALUES (5332, 789, 2, 19, 25);
INSERT INTO public.set_scores VALUES (5333, 789, 3, 21, 25);
INSERT INTO public.set_scores VALUES (5334, 789, 4, 16, 25);
INSERT INTO public.set_scores VALUES (5335, 791, 1, 25, 19);
INSERT INTO public.set_scores VALUES (5336, 791, 2, 22, 25);
INSERT INTO public.set_scores VALUES (5337, 791, 3, 20, 25);
INSERT INTO public.set_scores VALUES (5338, 791, 4, 21, 25);
INSERT INTO public.set_scores VALUES (5339, 794, 1, 25, 18);
INSERT INTO public.set_scores VALUES (5340, 794, 2, 25, 20);
INSERT INTO public.set_scores VALUES (5341, 794, 3, 25, 17);
INSERT INTO public.set_scores VALUES (5342, 798, 1, 25, 20);
INSERT INTO public.set_scores VALUES (5343, 798, 2, 23, 25);
INSERT INTO public.set_scores VALUES (5344, 798, 3, 25, 23);
INSERT INTO public.set_scores VALUES (5345, 798, 4, 25, 15);
INSERT INTO public.set_scores VALUES (5346, 796, 1, 17, 25);
INSERT INTO public.set_scores VALUES (5347, 796, 2, 25, 21);
INSERT INTO public.set_scores VALUES (5348, 796, 3, 26, 28);
INSERT INTO public.set_scores VALUES (5349, 796, 4, 23, 25);
INSERT INTO public.set_scores VALUES (5350, 795, 1, 19, 25);
INSERT INTO public.set_scores VALUES (5351, 795, 2, 21, 25);
INSERT INTO public.set_scores VALUES (5352, 795, 3, 25, 20);
INSERT INTO public.set_scores VALUES (5353, 795, 4, 18, 25);
INSERT INTO public.set_scores VALUES (5354, 797, 1, 25, 21);
INSERT INTO public.set_scores VALUES (5355, 797, 2, 23, 25);
INSERT INTO public.set_scores VALUES (5356, 797, 3, 25, 23);
INSERT INTO public.set_scores VALUES (5357, 797, 4, 25, 23);
INSERT INTO public.set_scores VALUES (5358, 793, 1, 20, 25);
INSERT INTO public.set_scores VALUES (5359, 793, 2, 25, 22);
INSERT INTO public.set_scores VALUES (5360, 793, 3, 16, 25);
INSERT INTO public.set_scores VALUES (5361, 793, 4, 15, 25);
INSERT INTO public.set_scores VALUES (5362, 804, 1, 25, 22);
INSERT INTO public.set_scores VALUES (5363, 804, 2, 25, 22);
INSERT INTO public.set_scores VALUES (5364, 804, 3, 28, 26);
INSERT INTO public.set_scores VALUES (5365, 799, 1, 22, 25);
INSERT INTO public.set_scores VALUES (5366, 799, 2, 25, 23);
INSERT INTO public.set_scores VALUES (5367, 799, 3, 18, 25);
INSERT INTO public.set_scores VALUES (5368, 799, 4, 20, 25);
INSERT INTO public.set_scores VALUES (5369, 800, 1, 26, 24);
INSERT INTO public.set_scores VALUES (5370, 800, 2, 18, 25);
INSERT INTO public.set_scores VALUES (5371, 800, 3, 18, 25);
INSERT INTO public.set_scores VALUES (5372, 800, 4, 22, 25);
INSERT INTO public.set_scores VALUES (5373, 801, 1, 25, 23);
INSERT INTO public.set_scores VALUES (5374, 801, 2, 25, 21);
INSERT INTO public.set_scores VALUES (5375, 801, 3, 25, 22);
INSERT INTO public.set_scores VALUES (5376, 802, 1, 25, 15);
INSERT INTO public.set_scores VALUES (5377, 802, 2, 25, 21);
INSERT INTO public.set_scores VALUES (5378, 802, 3, 25, 22);
INSERT INTO public.set_scores VALUES (5379, 803, 1, 27, 25);
INSERT INTO public.set_scores VALUES (5380, 803, 2, 25, 15);
INSERT INTO public.set_scores VALUES (5381, 803, 3, 25, 21);
INSERT INTO public.set_scores VALUES (5382, 808, 1, 21, 25);
INSERT INTO public.set_scores VALUES (5383, 808, 2, 18, 25);
INSERT INTO public.set_scores VALUES (5384, 808, 3, 28, 26);
INSERT INTO public.set_scores VALUES (5385, 808, 4, 18, 25);
INSERT INTO public.set_scores VALUES (5386, 807, 1, 25, 22);
INSERT INTO public.set_scores VALUES (5387, 807, 2, 18, 25);
INSERT INTO public.set_scores VALUES (5388, 807, 3, 25, 21);
INSERT INTO public.set_scores VALUES (5389, 807, 4, 25, 20);
INSERT INTO public.set_scores VALUES (5390, 805, 1, 25, 13);
INSERT INTO public.set_scores VALUES (5391, 805, 2, 25, 22);
INSERT INTO public.set_scores VALUES (5392, 805, 3, 25, 20);
INSERT INTO public.set_scores VALUES (5393, 806, 1, 18, 25);
INSERT INTO public.set_scores VALUES (5394, 806, 2, 22, 25);
INSERT INTO public.set_scores VALUES (5395, 806, 3, 19, 25);
INSERT INTO public.set_scores VALUES (5396, 809, 1, 25, 18);
INSERT INTO public.set_scores VALUES (5397, 809, 2, 25, 21);
INSERT INTO public.set_scores VALUES (5398, 809, 3, 23, 25);
INSERT INTO public.set_scores VALUES (5399, 809, 4, 32, 24);
INSERT INTO public.set_scores VALUES (5400, 809, 5, 11, 15);
INSERT INTO public.set_scores VALUES (5401, 810, 1, 25, 23);
INSERT INTO public.set_scores VALUES (5402, 810, 2, 38, 36);
INSERT INTO public.set_scores VALUES (5403, 810, 3, 19, 25);
INSERT INTO public.set_scores VALUES (5404, 810, 4, 25, 23);
INSERT INTO public.set_scores VALUES (6007, 840, 1, 25, 19);
INSERT INTO public.set_scores VALUES (6008, 840, 2, 27, 25);
INSERT INTO public.set_scores VALUES (6009, 840, 3, 25, 12);
INSERT INTO public.set_scores VALUES (6010, 839, 1, 25, 22);
INSERT INTO public.set_scores VALUES (6011, 839, 2, 25, 18);
INSERT INTO public.set_scores VALUES (6012, 839, 3, 20, 25);
INSERT INTO public.set_scores VALUES (6013, 839, 4, 25, 20);
INSERT INTO public.set_scores VALUES (6017, 842, 1, 15, 25);
INSERT INTO public.set_scores VALUES (6018, 842, 2, 16, 25);
INSERT INTO public.set_scores VALUES (6019, 842, 3, 25, 19);
INSERT INTO public.set_scores VALUES (6020, 842, 4, 23, 25);
INSERT INTO public.set_scores VALUES (6021, 843, 1, 22, 25);
INSERT INTO public.set_scores VALUES (6022, 843, 2, 18, 25);
INSERT INTO public.set_scores VALUES (6023, 843, 3, 18, 25);
INSERT INTO public.set_scores VALUES (6024, 837, 1, 23, 25);
INSERT INTO public.set_scores VALUES (6025, 837, 2, 25, 18);
INSERT INTO public.set_scores VALUES (6026, 837, 3, 24, 26);
INSERT INTO public.set_scores VALUES (6027, 837, 4, 15, 25);
INSERT INTO public.set_scores VALUES (6028, 838, 1, 25, 16);
INSERT INTO public.set_scores VALUES (6029, 838, 2, 25, 21);
INSERT INTO public.set_scores VALUES (6030, 838, 3, 25, 18);
INSERT INTO public.set_scores VALUES (6031, 836, 1, 25, 23);
INSERT INTO public.set_scores VALUES (6032, 836, 2, 25, 18);
INSERT INTO public.set_scores VALUES (6033, 836, 3, 25, 20);
INSERT INTO public.set_scores VALUES (6037, 848, 1, 22, 25);
INSERT INTO public.set_scores VALUES (6038, 848, 2, 25, 17);
INSERT INTO public.set_scores VALUES (6039, 848, 3, 23, 25);
INSERT INTO public.set_scores VALUES (6040, 848, 4, 31, 29);
INSERT INTO public.set_scores VALUES (6041, 848, 5, 13, 15);
INSERT INTO public.set_scores VALUES (6046, 849, 1, 25, 20);
INSERT INTO public.set_scores VALUES (6047, 849, 2, 17, 25);
INSERT INTO public.set_scores VALUES (6048, 849, 3, 25, 18);
INSERT INTO public.set_scores VALUES (6049, 849, 4, 23, 25);
INSERT INTO public.set_scores VALUES (6050, 849, 5, 15, 9);
INSERT INTO public.set_scores VALUES (6051, 846, 1, 20, 25);
INSERT INTO public.set_scores VALUES (6052, 846, 2, 21, 25);
INSERT INTO public.set_scores VALUES (6053, 846, 3, 26, 24);
INSERT INTO public.set_scores VALUES (6054, 846, 4, 18, 25);
INSERT INTO public.set_scores VALUES (6055, 845, 1, 22, 25);
INSERT INTO public.set_scores VALUES (6056, 845, 2, 23, 25);
INSERT INTO public.set_scores VALUES (6057, 845, 3, 25, 23);
INSERT INTO public.set_scores VALUES (6058, 845, 4, 27, 29);
INSERT INTO public.set_scores VALUES (6059, 850, 1, 25, 17);
INSERT INTO public.set_scores VALUES (6060, 850, 2, 25, 18);
INSERT INTO public.set_scores VALUES (6061, 850, 3, 33, 31);
INSERT INTO public.set_scores VALUES (6062, 851, 1, 25, 23);
INSERT INTO public.set_scores VALUES (6063, 851, 2, 29, 27);
INSERT INTO public.set_scores VALUES (6064, 851, 3, 25, 21);
INSERT INTO public.set_scores VALUES (6065, 854, 1, 35, 33);
INSERT INTO public.set_scores VALUES (6066, 854, 2, 18, 25);
INSERT INTO public.set_scores VALUES (6067, 854, 3, 23, 25);
INSERT INTO public.set_scores VALUES (6068, 854, 4, 24, 26);
INSERT INTO public.set_scores VALUES (6075, 855, 1, 23, 25);
INSERT INTO public.set_scores VALUES (6076, 855, 2, 25, 13);
INSERT INTO public.set_scores VALUES (6077, 855, 3, 25, 11);
INSERT INTO public.set_scores VALUES (6078, 855, 4, 25, 23);
INSERT INTO public.set_scores VALUES (6079, 853, 1, 25, 21);
INSERT INTO public.set_scores VALUES (6080, 853, 2, 23, 25);
INSERT INTO public.set_scores VALUES (6081, 853, 3, 27, 25);
INSERT INTO public.set_scores VALUES (6082, 853, 4, 25, 20);
INSERT INTO public.set_scores VALUES (6086, 852, 1, 26, 28);
INSERT INTO public.set_scores VALUES (6087, 852, 2, 16, 25);
INSERT INTO public.set_scores VALUES (6088, 852, 3, 25, 21);
INSERT INTO public.set_scores VALUES (6089, 852, 4, 26, 28);
INSERT INTO public.set_scores VALUES (6090, 859, 1, 10, 25);
INSERT INTO public.set_scores VALUES (6091, 859, 2, 25, 20);
INSERT INTO public.set_scores VALUES (6092, 859, 3, 25, 17);
INSERT INTO public.set_scores VALUES (6093, 859, 4, 25, 21);
INSERT INTO public.set_scores VALUES (6094, 864, 1, 17, 25);
INSERT INTO public.set_scores VALUES (6095, 864, 2, 22, 25);
INSERT INTO public.set_scores VALUES (6096, 864, 3, 25, 23);
INSERT INTO public.set_scores VALUES (6097, 864, 4, 20, 25);
INSERT INTO public.set_scores VALUES (6098, 862, 1, 14, 25);
INSERT INTO public.set_scores VALUES (6099, 862, 2, 25, 19);
INSERT INTO public.set_scores VALUES (6100, 862, 3, 20, 25);
INSERT INTO public.set_scores VALUES (6101, 862, 4, 25, 20);
INSERT INTO public.set_scores VALUES (6102, 862, 5, 15, 11);
INSERT INTO public.set_scores VALUES (6103, 861, 1, 21, 25);
INSERT INTO public.set_scores VALUES (6104, 861, 2, 29, 27);
INSERT INTO public.set_scores VALUES (6105, 861, 3, 23, 25);
INSERT INTO public.set_scores VALUES (6106, 861, 4, 25, 17);
INSERT INTO public.set_scores VALUES (6107, 861, 5, 15, 11);
INSERT INTO public.set_scores VALUES (6108, 863, 1, 25, 21);
INSERT INTO public.set_scores VALUES (6109, 863, 2, 18, 25);
INSERT INTO public.set_scores VALUES (6110, 863, 3, 25, 23);
INSERT INTO public.set_scores VALUES (6111, 863, 4, 27, 29);
INSERT INTO public.set_scores VALUES (6112, 863, 5, 15, 11);
INSERT INTO public.set_scores VALUES (6113, 866, 1, 25, 17);
INSERT INTO public.set_scores VALUES (6114, 866, 2, 25, 17);
INSERT INTO public.set_scores VALUES (6115, 866, 3, 25, 23);
INSERT INTO public.set_scores VALUES (6116, 860, 1, 20, 25);
INSERT INTO public.set_scores VALUES (6117, 860, 2, 23, 25);
INSERT INTO public.set_scores VALUES (6118, 860, 3, 22, 25);
INSERT INTO public.set_scores VALUES (6119, 867, 1, 14, 25);
INSERT INTO public.set_scores VALUES (6120, 867, 2, 21, 25);
INSERT INTO public.set_scores VALUES (6121, 867, 3, 23, 25);
INSERT INTO public.set_scores VALUES (6122, 865, 1, 21, 25);
INSERT INTO public.set_scores VALUES (6123, 865, 2, 25, 19);
INSERT INTO public.set_scores VALUES (6124, 865, 3, 20, 25);
INSERT INTO public.set_scores VALUES (6125, 865, 4, 25, 17);
INSERT INTO public.set_scores VALUES (6126, 865, 5, 15, 9);
INSERT INTO public.set_scores VALUES (6127, 875, 1, 24, 26);
INSERT INTO public.set_scores VALUES (6128, 875, 2, 17, 25);
INSERT INTO public.set_scores VALUES (6129, 875, 3, 23, 25);
INSERT INTO public.set_scores VALUES (6130, 872, 1, 25, 21);
INSERT INTO public.set_scores VALUES (6131, 872, 2, 25, 23);
INSERT INTO public.set_scores VALUES (6132, 872, 3, 26, 24);
INSERT INTO public.set_scores VALUES (6144, 870, 1, 18, 25);
INSERT INTO public.set_scores VALUES (6145, 870, 2, 25, 21);
INSERT INTO public.set_scores VALUES (6146, 870, 3, 25, 23);
INSERT INTO public.set_scores VALUES (6147, 870, 4, 28, 30);
INSERT INTO public.set_scores VALUES (6148, 870, 5, 15, 12);
INSERT INTO public.set_scores VALUES (6149, 871, 1, 24, 26);
INSERT INTO public.set_scores VALUES (6150, 871, 2, 25, 18);
INSERT INTO public.set_scores VALUES (6151, 871, 3, 24, 26);
INSERT INTO public.set_scores VALUES (6152, 871, 4, 20, 25);
INSERT INTO public.set_scores VALUES (6153, 869, 1, 21, 25);
INSERT INTO public.set_scores VALUES (6154, 869, 2, 25, 16);
INSERT INTO public.set_scores VALUES (6155, 869, 3, 25, 23);
INSERT INTO public.set_scores VALUES (6156, 869, 4, 20, 25);
INSERT INTO public.set_scores VALUES (6157, 869, 5, 11, 15);
INSERT INTO public.set_scores VALUES (6158, 881, 1, 25, 22);
INSERT INTO public.set_scores VALUES (6159, 881, 2, 25, 22);
INSERT INTO public.set_scores VALUES (6160, 881, 3, 26, 24);
INSERT INTO public.set_scores VALUES (6161, 883, 1, 23, 25);
INSERT INTO public.set_scores VALUES (6162, 883, 2, 18, 25);
INSERT INTO public.set_scores VALUES (6163, 883, 3, 25, 21);
INSERT INTO public.set_scores VALUES (6164, 883, 4, 25, 19);
INSERT INTO public.set_scores VALUES (6165, 883, 5, 8, 15);
INSERT INTO public.set_scores VALUES (6172, 882, 1, 21, 25);
INSERT INTO public.set_scores VALUES (6173, 882, 2, 23, 25);
INSERT INTO public.set_scores VALUES (6174, 882, 3, 25, 18);
INSERT INTO public.set_scores VALUES (6175, 882, 4, 26, 24);
INSERT INTO public.set_scores VALUES (6176, 882, 5, 16, 14);
INSERT INTO public.set_scores VALUES (6177, 877, 1, 20, 25);
INSERT INTO public.set_scores VALUES (6178, 877, 2, 21, 25);
INSERT INTO public.set_scores VALUES (6179, 877, 3, 25, 23);
INSERT INTO public.set_scores VALUES (6180, 877, 4, 25, 17);
INSERT INTO public.set_scores VALUES (6181, 877, 5, 12, 15);
INSERT INTO public.set_scores VALUES (6182, 876, 1, 25, 23);
INSERT INTO public.set_scores VALUES (6183, 876, 2, 25, 18);
INSERT INTO public.set_scores VALUES (6184, 876, 3, 25, 21);
INSERT INTO public.set_scores VALUES (6185, 879, 1, 25, 18);
INSERT INTO public.set_scores VALUES (6186, 879, 2, 25, 21);
INSERT INTO public.set_scores VALUES (6187, 879, 3, 25, 15);
INSERT INTO public.set_scores VALUES (6188, 887, 1, 25, 21);
INSERT INTO public.set_scores VALUES (6189, 887, 2, 25, 18);
INSERT INTO public.set_scores VALUES (6190, 887, 3, 20, 25);
INSERT INTO public.set_scores VALUES (6191, 887, 4, 21, 25);
INSERT INTO public.set_scores VALUES (6192, 887, 5, 12, 15);
INSERT INTO public.set_scores VALUES (6193, 888, 1, 21, 25);
INSERT INTO public.set_scores VALUES (6194, 888, 2, 18, 25);
INSERT INTO public.set_scores VALUES (6195, 888, 3, 18, 25);
INSERT INTO public.set_scores VALUES (6205, 886, 1, 25, 18);
INSERT INTO public.set_scores VALUES (6206, 886, 2, 21, 25);
INSERT INTO public.set_scores VALUES (6207, 886, 3, 20, 25);
INSERT INTO public.set_scores VALUES (6208, 886, 4, 25, 18);
INSERT INTO public.set_scores VALUES (6209, 886, 5, 15, 12);
INSERT INTO public.set_scores VALUES (6210, 891, 1, 15, 25);
INSERT INTO public.set_scores VALUES (6211, 891, 2, 28, 26);
INSERT INTO public.set_scores VALUES (6212, 891, 3, 22, 25);
INSERT INTO public.set_scores VALUES (6213, 891, 4, 25, 23);
INSERT INTO public.set_scores VALUES (6214, 891, 5, 15, 12);
INSERT INTO public.set_scores VALUES (6215, 885, 1, 25, 18);
INSERT INTO public.set_scores VALUES (6216, 885, 2, 25, 23);
INSERT INTO public.set_scores VALUES (6217, 885, 3, 31, 29);
INSERT INTO public.set_scores VALUES (6221, 898, 1, 21, 25);
INSERT INTO public.set_scores VALUES (6222, 898, 2, 25, 22);
INSERT INTO public.set_scores VALUES (6223, 898, 3, 18, 25);
INSERT INTO public.set_scores VALUES (6224, 898, 4, 25, 27);
INSERT INTO public.set_scores VALUES (6225, 899, 1, 25, 23);
INSERT INTO public.set_scores VALUES (6226, 899, 2, 25, 20);
INSERT INTO public.set_scores VALUES (6227, 899, 3, 26, 24);
INSERT INTO public.set_scores VALUES (6228, 896, 1, 25, 22);
INSERT INTO public.set_scores VALUES (6229, 896, 2, 25, 16);
INSERT INTO public.set_scores VALUES (6230, 896, 3, 25, 22);
INSERT INTO public.set_scores VALUES (6239, 894, 1, 24, 26);
INSERT INTO public.set_scores VALUES (6240, 894, 2, 28, 30);
INSERT INTO public.set_scores VALUES (6241, 894, 3, 25, 22);
INSERT INTO public.set_scores VALUES (6242, 894, 4, 23, 25);
INSERT INTO public.set_scores VALUES (6243, 897, 1, 21, 25);
INSERT INTO public.set_scores VALUES (6244, 897, 2, 21, 25);
INSERT INTO public.set_scores VALUES (6245, 897, 3, 25, 19);
INSERT INTO public.set_scores VALUES (6246, 897, 4, 25, 19);
INSERT INTO public.set_scores VALUES (6247, 897, 5, 14, 16);
INSERT INTO public.set_scores VALUES (6248, 904, 1, 26, 24);
INSERT INTO public.set_scores VALUES (6249, 904, 2, 25, 22);
INSERT INTO public.set_scores VALUES (6250, 904, 3, 28, 26);
INSERT INTO public.set_scores VALUES (6256, 900, 1, 25, 12);
INSERT INTO public.set_scores VALUES (6257, 900, 2, 25, 20);
INSERT INTO public.set_scores VALUES (6258, 900, 3, 23, 25);
INSERT INTO public.set_scores VALUES (6259, 900, 4, 15, 25);
INSERT INTO public.set_scores VALUES (6260, 900, 5, 10, 15);
INSERT INTO public.set_scores VALUES (6261, 906, 1, 37, 35);
INSERT INTO public.set_scores VALUES (6262, 906, 2, 25, 19);
INSERT INTO public.set_scores VALUES (6263, 906, 3, 21, 25);
INSERT INTO public.set_scores VALUES (6264, 906, 4, 25, 17);
INSERT INTO public.set_scores VALUES (6265, 903, 1, 25, 23);
INSERT INTO public.set_scores VALUES (6266, 903, 2, 25, 19);
INSERT INTO public.set_scores VALUES (6267, 903, 3, 25, 18);
INSERT INTO public.set_scores VALUES (6268, 907, 1, 25, 21);
INSERT INTO public.set_scores VALUES (6269, 907, 2, 25, 16);
INSERT INTO public.set_scores VALUES (6270, 907, 3, 25, 18);
INSERT INTO public.set_scores VALUES (6271, 905, 1, 14, 25);
INSERT INTO public.set_scores VALUES (6272, 905, 2, 16, 25);
INSERT INTO public.set_scores VALUES (6273, 905, 3, 13, 25);
INSERT INTO public.set_scores VALUES (6274, 902, 1, 21, 25);
INSERT INTO public.set_scores VALUES (6275, 902, 2, 22, 25);
INSERT INTO public.set_scores VALUES (6276, 902, 3, 14, 25);
INSERT INTO public.set_scores VALUES (6277, 910, 1, 18, 25);
INSERT INTO public.set_scores VALUES (6278, 910, 2, 25, 20);
INSERT INTO public.set_scores VALUES (6279, 910, 3, 20, 25);
INSERT INTO public.set_scores VALUES (6280, 910, 4, 25, 21);
INSERT INTO public.set_scores VALUES (6281, 910, 5, 15, 12);
INSERT INTO public.set_scores VALUES (6282, 914, 1, 25, 21);
INSERT INTO public.set_scores VALUES (6283, 914, 2, 25, 16);
INSERT INTO public.set_scores VALUES (6284, 914, 3, 19, 25);
INSERT INTO public.set_scores VALUES (6285, 914, 4, 25, 23);
INSERT INTO public.set_scores VALUES (6289, 913, 1, 25, 22);
INSERT INTO public.set_scores VALUES (6290, 913, 2, 25, 22);
INSERT INTO public.set_scores VALUES (6291, 913, 3, 25, 22);
INSERT INTO public.set_scores VALUES (6296, 912, 1, 25, 23);
INSERT INTO public.set_scores VALUES (6297, 912, 2, 18, 25);
INSERT INTO public.set_scores VALUES (6298, 912, 3, 23, 25);
INSERT INTO public.set_scores VALUES (6299, 912, 4, 25, 16);
INSERT INTO public.set_scores VALUES (6300, 912, 5, 12, 15);
INSERT INTO public.set_scores VALUES (6301, 915, 1, 27, 25);
INSERT INTO public.set_scores VALUES (6302, 915, 2, 25, 22);
INSERT INTO public.set_scores VALUES (6303, 915, 3, 25, 15);
INSERT INTO public.set_scores VALUES (6304, 908, 1, 23, 25);
INSERT INTO public.set_scores VALUES (6305, 908, 2, 33, 35);
INSERT INTO public.set_scores VALUES (6306, 908, 3, 11, 25);
INSERT INTO public.set_scores VALUES (6312, 923, 1, 17, 25);
INSERT INTO public.set_scores VALUES (6313, 923, 2, 25, 23);
INSERT INTO public.set_scores VALUES (6314, 923, 3, 25, 22);
INSERT INTO public.set_scores VALUES (6315, 923, 4, 27, 29);
INSERT INTO public.set_scores VALUES (6316, 923, 5, 10, 15);
INSERT INTO public.set_scores VALUES (6317, 917, 1, 25, 17);
INSERT INTO public.set_scores VALUES (6318, 917, 2, 25, 20);
INSERT INTO public.set_scores VALUES (6319, 917, 3, 27, 25);
INSERT INTO public.set_scores VALUES (6320, 918, 1, 23, 25);
INSERT INTO public.set_scores VALUES (6321, 918, 2, 21, 25);
INSERT INTO public.set_scores VALUES (6322, 918, 3, 25, 22);
INSERT INTO public.set_scores VALUES (6323, 918, 4, 17, 25);
INSERT INTO public.set_scores VALUES (6324, 921, 1, 17, 25);
INSERT INTO public.set_scores VALUES (6325, 921, 2, 14, 25);
INSERT INTO public.set_scores VALUES (6326, 921, 3, 21, 25);
INSERT INTO public.set_scores VALUES (6327, 920, 1, 10, 25);
INSERT INTO public.set_scores VALUES (6328, 920, 2, 23, 25);
INSERT INTO public.set_scores VALUES (6329, 920, 3, 21, 25);
INSERT INTO public.set_scores VALUES (6330, 919, 1, 25, 16);
INSERT INTO public.set_scores VALUES (6331, 919, 2, 27, 25);
INSERT INTO public.set_scores VALUES (6332, 919, 3, 28, 26);
INSERT INTO public.set_scores VALUES (6333, 916, 1, 40, 38);
INSERT INTO public.set_scores VALUES (6334, 916, 2, 25, 19);
INSERT INTO public.set_scores VALUES (6335, 916, 3, 18, 25);
INSERT INTO public.set_scores VALUES (6336, 916, 4, 18, 25);
INSERT INTO public.set_scores VALUES (6337, 916, 5, 14, 16);
INSERT INTO public.set_scores VALUES (6338, 929, 1, 23, 25);
INSERT INTO public.set_scores VALUES (6339, 929, 2, 23, 25);
INSERT INTO public.set_scores VALUES (6340, 929, 3, 17, 25);
INSERT INTO public.set_scores VALUES (6344, 928, 1, 19, 25);
INSERT INTO public.set_scores VALUES (6345, 928, 2, 25, 20);
INSERT INTO public.set_scores VALUES (6346, 928, 3, 25, 19);
INSERT INTO public.set_scores VALUES (6347, 928, 4, 25, 22);
INSERT INTO public.set_scores VALUES (6348, 926, 1, 25, 16);
INSERT INTO public.set_scores VALUES (6349, 926, 2, 25, 22);
INSERT INTO public.set_scores VALUES (6350, 926, 3, 23, 25);
INSERT INTO public.set_scores VALUES (6351, 926, 4, 25, 21);
INSERT INTO public.set_scores VALUES (6355, 927, 1, 22, 25);
INSERT INTO public.set_scores VALUES (6356, 927, 2, 25, 23);
INSERT INTO public.set_scores VALUES (6357, 927, 3, 25, 19);
INSERT INTO public.set_scores VALUES (6358, 927, 4, 25, 17);
INSERT INTO public.set_scores VALUES (6359, 931, 1, 19, 25);
INSERT INTO public.set_scores VALUES (6360, 931, 2, 25, 21);
INSERT INTO public.set_scores VALUES (6361, 931, 3, 26, 24);
INSERT INTO public.set_scores VALUES (6362, 931, 4, 16, 25);
INSERT INTO public.set_scores VALUES (6363, 931, 5, 10, 15);
INSERT INTO public.set_scores VALUES (6364, 930, 1, 25, 15);
INSERT INTO public.set_scores VALUES (6365, 930, 2, 23, 25);
INSERT INTO public.set_scores VALUES (6366, 930, 3, 24, 26);
INSERT INTO public.set_scores VALUES (6367, 930, 4, 25, 19);
INSERT INTO public.set_scores VALUES (6368, 930, 5, 15, 12);
INSERT INTO public.set_scores VALUES (6369, 939, 1, 25, 10);
INSERT INTO public.set_scores VALUES (6370, 939, 2, 25, 15);
INSERT INTO public.set_scores VALUES (6371, 939, 3, 25, 18);
INSERT INTO public.set_scores VALUES (6372, 933, 1, 15, 25);
INSERT INTO public.set_scores VALUES (6373, 933, 2, 17, 25);
INSERT INTO public.set_scores VALUES (6374, 933, 3, 23, 25);
INSERT INTO public.set_scores VALUES (6375, 938, 1, 25, 15);
INSERT INTO public.set_scores VALUES (6376, 938, 2, 27, 25);
INSERT INTO public.set_scores VALUES (6377, 938, 3, 25, 19);
INSERT INTO public.set_scores VALUES (6378, 932, 1, 18, 25);
INSERT INTO public.set_scores VALUES (6379, 932, 2, 22, 25);
INSERT INTO public.set_scores VALUES (6380, 932, 3, 25, 16);
INSERT INTO public.set_scores VALUES (6381, 932, 4, 23, 25);
INSERT INTO public.set_scores VALUES (6382, 937, 1, 21, 25);
INSERT INTO public.set_scores VALUES (6383, 937, 2, 25, 23);
INSERT INTO public.set_scores VALUES (6384, 937, 3, 23, 25);
INSERT INTO public.set_scores VALUES (6385, 937, 4, 25, 18);
INSERT INTO public.set_scores VALUES (6386, 937, 5, 15, 12);
INSERT INTO public.set_scores VALUES (6387, 936, 1, 22, 25);
INSERT INTO public.set_scores VALUES (6388, 936, 2, 20, 25);
INSERT INTO public.set_scores VALUES (6389, 936, 3, 25, 19);
INSERT INTO public.set_scores VALUES (6390, 936, 4, 25, 23);
INSERT INTO public.set_scores VALUES (6391, 936, 5, 15, 13);
INSERT INTO public.set_scores VALUES (6392, 934, 1, 25, 22);
INSERT INTO public.set_scores VALUES (6393, 934, 2, 25, 22);
INSERT INTO public.set_scores VALUES (6394, 934, 3, 20, 25);
INSERT INTO public.set_scores VALUES (6395, 934, 4, 25, 22);
INSERT INTO public.set_scores VALUES (6399, 946, 1, 19, 25);
INSERT INTO public.set_scores VALUES (6400, 946, 2, 23, 25);
INSERT INTO public.set_scores VALUES (6401, 946, 3, 28, 30);
INSERT INTO public.set_scores VALUES (6409, 945, 1, 25, 20);
INSERT INTO public.set_scores VALUES (6410, 945, 2, 19, 25);
INSERT INTO public.set_scores VALUES (6411, 945, 3, 25, 20);
INSERT INTO public.set_scores VALUES (6412, 945, 4, 23, 25);
INSERT INTO public.set_scores VALUES (6413, 945, 5, 17, 15);
INSERT INTO public.set_scores VALUES (6414, 940, 1, 20, 25);
INSERT INTO public.set_scores VALUES (6415, 940, 2, 20, 25);
INSERT INTO public.set_scores VALUES (6416, 940, 3, 23, 25);
INSERT INTO public.set_scores VALUES (6417, 943, 1, 18, 25);
INSERT INTO public.set_scores VALUES (6418, 943, 2, 25, 20);
INSERT INTO public.set_scores VALUES (6419, 943, 3, 25, 22);
INSERT INTO public.set_scores VALUES (6420, 943, 4, 21, 25);
INSERT INTO public.set_scores VALUES (6421, 943, 5, 11, 15);
INSERT INTO public.set_scores VALUES (6425, 942, 1, 15, 25);
INSERT INTO public.set_scores VALUES (6426, 942, 2, 28, 26);
INSERT INTO public.set_scores VALUES (6427, 942, 3, 25, 19);
INSERT INTO public.set_scores VALUES (6428, 942, 4, 25, 18);
INSERT INTO public.set_scores VALUES (6429, 948, 1, 11, 25);
INSERT INTO public.set_scores VALUES (6430, 948, 2, 20, 25);
INSERT INTO public.set_scores VALUES (6431, 948, 3, 19, 25);
INSERT INTO public.set_scores VALUES (6432, 950, 1, 25, 18);
INSERT INTO public.set_scores VALUES (6433, 950, 2, 17, 25);
INSERT INTO public.set_scores VALUES (6434, 950, 3, 21, 25);
INSERT INTO public.set_scores VALUES (6435, 950, 4, 21, 25);
INSERT INTO public.set_scores VALUES (6436, 954, 1, 26, 24);
INSERT INTO public.set_scores VALUES (6437, 954, 2, 27, 29);
INSERT INTO public.set_scores VALUES (6438, 954, 3, 22, 25);
INSERT INTO public.set_scores VALUES (6439, 954, 4, 25, 21);
INSERT INTO public.set_scores VALUES (6440, 954, 5, 12, 15);
INSERT INTO public.set_scores VALUES (6441, 952, 1, 28, 30);
INSERT INTO public.set_scores VALUES (6442, 952, 2, 20, 25);
INSERT INTO public.set_scores VALUES (6443, 952, 3, 20, 25);
INSERT INTO public.set_scores VALUES (6444, 955, 1, 25, 20);
INSERT INTO public.set_scores VALUES (6445, 955, 2, 25, 21);
INSERT INTO public.set_scores VALUES (6446, 955, 3, 20, 25);
INSERT INTO public.set_scores VALUES (6447, 955, 4, 25, 20);
INSERT INTO public.set_scores VALUES (6448, 953, 1, 17, 25);
INSERT INTO public.set_scores VALUES (6449, 953, 2, 22, 25);
INSERT INTO public.set_scores VALUES (6450, 953, 3, 19, 25);
INSERT INTO public.set_scores VALUES (6455, 951, 1, 25, 15);
INSERT INTO public.set_scores VALUES (6456, 951, 2, 31, 29);
INSERT INTO public.set_scores VALUES (6457, 951, 3, 26, 28);
INSERT INTO public.set_scores VALUES (6458, 951, 4, 25, 22);
INSERT INTO public.set_scores VALUES (6459, 956, 1, 28, 26);
INSERT INTO public.set_scores VALUES (6460, 956, 2, 25, 27);
INSERT INTO public.set_scores VALUES (6461, 956, 3, 21, 25);
INSERT INTO public.set_scores VALUES (6462, 956, 4, 24, 26);
INSERT INTO public.set_scores VALUES (6467, 959, 1, 25, 17);
INSERT INTO public.set_scores VALUES (6468, 959, 2, 23, 25);
INSERT INTO public.set_scores VALUES (6469, 959, 3, 25, 15);
INSERT INTO public.set_scores VALUES (6470, 959, 4, 21, 25);
INSERT INTO public.set_scores VALUES (6471, 959, 5, 15, 12);
INSERT INTO public.set_scores VALUES (7713, 1125, 3, 25, 16);
INSERT INTO public.set_scores VALUES (7714, 1121, 1, 20, 25);
INSERT INTO public.set_scores VALUES (6480, 958, 1, 25, 19);
INSERT INTO public.set_scores VALUES (6481, 958, 2, 19, 25);
INSERT INTO public.set_scores VALUES (6482, 958, 3, 25, 21);
INSERT INTO public.set_scores VALUES (6483, 958, 4, 23, 25);
INSERT INTO public.set_scores VALUES (6484, 958, 5, 8, 15);
INSERT INTO public.set_scores VALUES (6485, 961, 1, 25, 20);
INSERT INTO public.set_scores VALUES (6486, 961, 2, 23, 25);
INSERT INTO public.set_scores VALUES (6487, 961, 3, 11, 25);
INSERT INTO public.set_scores VALUES (6488, 961, 4, 19, 25);
INSERT INTO public.set_scores VALUES (6489, 960, 1, 14, 25);
INSERT INTO public.set_scores VALUES (6490, 960, 2, 23, 25);
INSERT INTO public.set_scores VALUES (6491, 960, 3, 18, 25);
INSERT INTO public.set_scores VALUES (7715, 1121, 2, 27, 25);
INSERT INTO public.set_scores VALUES (7716, 1121, 3, 21, 25);
INSERT INTO public.set_scores VALUES (7717, 1121, 4, 25, 17);
INSERT INTO public.set_scores VALUES (6495, 967, 1, 25, 23);
INSERT INTO public.set_scores VALUES (6496, 967, 2, 25, 18);
INSERT INTO public.set_scores VALUES (6497, 967, 3, 27, 29);
INSERT INTO public.set_scores VALUES (6498, 967, 4, 25, 17);
INSERT INTO public.set_scores VALUES (6499, 970, 1, 27, 25);
INSERT INTO public.set_scores VALUES (6500, 970, 2, 17, 25);
INSERT INTO public.set_scores VALUES (6501, 970, 3, 20, 25);
INSERT INTO public.set_scores VALUES (6502, 970, 4, 21, 25);
INSERT INTO public.set_scores VALUES (6503, 965, 1, 25, 23);
INSERT INTO public.set_scores VALUES (6504, 965, 2, 20, 25);
INSERT INTO public.set_scores VALUES (6505, 965, 3, 25, 13);
INSERT INTO public.set_scores VALUES (6506, 965, 4, 25, 22);
INSERT INTO public.set_scores VALUES (6507, 969, 1, 25, 22);
INSERT INTO public.set_scores VALUES (6508, 969, 2, 25, 18);
INSERT INTO public.set_scores VALUES (6509, 969, 3, 25, 21);
INSERT INTO public.set_scores VALUES (6510, 964, 1, 25, 16);
INSERT INTO public.set_scores VALUES (6511, 964, 2, 25, 18);
INSERT INTO public.set_scores VALUES (6512, 964, 3, 25, 18);
INSERT INTO public.set_scores VALUES (6513, 971, 1, 26, 24);
INSERT INTO public.set_scores VALUES (6514, 971, 2, 25, 21);
INSERT INTO public.set_scores VALUES (6515, 971, 3, 25, 19);
INSERT INTO public.set_scores VALUES (6516, 968, 1, 25, 22);
INSERT INTO public.set_scores VALUES (6517, 968, 2, 25, 20);
INSERT INTO public.set_scores VALUES (6518, 968, 3, 25, 23);
INSERT INTO public.set_scores VALUES (6519, 976, 1, 25, 23);
INSERT INTO public.set_scores VALUES (6520, 976, 2, 20, 25);
INSERT INTO public.set_scores VALUES (6521, 976, 3, 22, 25);
INSERT INTO public.set_scores VALUES (6522, 976, 4, 25, 19);
INSERT INTO public.set_scores VALUES (6523, 976, 5, 14, 16);
INSERT INTO public.set_scores VALUES (7718, 1121, 5, 15, 11);
INSERT INTO public.set_scores VALUES (7719, 1124, 1, 18, 25);
INSERT INTO public.set_scores VALUES (7720, 1124, 2, 20, 25);
INSERT INTO public.set_scores VALUES (7721, 1124, 3, 22, 25);
INSERT INTO public.set_scores VALUES (6528, 979, 1, 17, 25);
INSERT INTO public.set_scores VALUES (6529, 979, 2, 15, 25);
INSERT INTO public.set_scores VALUES (6530, 979, 3, 25, 20);
INSERT INTO public.set_scores VALUES (6531, 979, 4, 27, 25);
INSERT INTO public.set_scores VALUES (6532, 979, 5, 13, 15);
INSERT INTO public.set_scores VALUES (6533, 975, 1, 15, 25);
INSERT INTO public.set_scores VALUES (6534, 975, 2, 22, 25);
INSERT INTO public.set_scores VALUES (6535, 975, 3, 25, 17);
INSERT INTO public.set_scores VALUES (6536, 975, 4, 15, 25);
INSERT INTO public.set_scores VALUES (6537, 978, 1, 25, 23);
INSERT INTO public.set_scores VALUES (6538, 978, 2, 16, 25);
INSERT INTO public.set_scores VALUES (6539, 978, 3, 25, 19);
INSERT INTO public.set_scores VALUES (6540, 978, 4, 25, 23);
INSERT INTO public.set_scores VALUES (6541, 973, 1, 25, 22);
INSERT INTO public.set_scores VALUES (6542, 973, 2, 16, 25);
INSERT INTO public.set_scores VALUES (6543, 973, 3, 25, 18);
INSERT INTO public.set_scores VALUES (6544, 973, 4, 21, 25);
INSERT INTO public.set_scores VALUES (6545, 973, 5, 10, 15);
INSERT INTO public.set_scores VALUES (6546, 974, 1, 25, 21);
INSERT INTO public.set_scores VALUES (6547, 974, 2, 22, 25);
INSERT INTO public.set_scores VALUES (6548, 974, 3, 25, 27);
INSERT INTO public.set_scores VALUES (6549, 974, 4, 22, 25);
INSERT INTO public.set_scores VALUES (6550, 972, 1, 20, 25);
INSERT INTO public.set_scores VALUES (6551, 972, 2, 25, 20);
INSERT INTO public.set_scores VALUES (6552, 972, 3, 25, 22);
INSERT INTO public.set_scores VALUES (6553, 972, 4, 25, 15);
INSERT INTO public.set_scores VALUES (6557, 980, 1, 25, 20);
INSERT INTO public.set_scores VALUES (6558, 980, 2, 25, 21);
INSERT INTO public.set_scores VALUES (6559, 980, 3, 18, 25);
INSERT INTO public.set_scores VALUES (6560, 980, 4, 40, 42);
INSERT INTO public.set_scores VALUES (6561, 980, 5, 20, 18);
INSERT INTO public.set_scores VALUES (6562, 985, 1, 17, 25);
INSERT INTO public.set_scores VALUES (6563, 985, 2, 22, 25);
INSERT INTO public.set_scores VALUES (6564, 985, 3, 15, 25);
INSERT INTO public.set_scores VALUES (6565, 987, 1, 25, 15);
INSERT INTO public.set_scores VALUES (6566, 987, 2, 30, 28);
INSERT INTO public.set_scores VALUES (6567, 987, 3, 25, 22);
INSERT INTO public.set_scores VALUES (6568, 984, 1, 25, 22);
INSERT INTO public.set_scores VALUES (6569, 984, 2, 25, 15);
INSERT INTO public.set_scores VALUES (6570, 984, 3, 25, 18);
INSERT INTO public.set_scores VALUES (6571, 981, 1, 20, 25);
INSERT INTO public.set_scores VALUES (6572, 981, 2, 25, 17);
INSERT INTO public.set_scores VALUES (6573, 981, 3, 25, 12);
INSERT INTO public.set_scores VALUES (6574, 981, 4, 25, 22);
INSERT INTO public.set_scores VALUES (6575, 986, 1, 23, 25);
INSERT INTO public.set_scores VALUES (6576, 986, 2, 25, 15);
INSERT INTO public.set_scores VALUES (6577, 986, 3, 26, 24);
INSERT INTO public.set_scores VALUES (6578, 986, 4, 24, 26);
INSERT INTO public.set_scores VALUES (6579, 986, 5, 10, 15);
INSERT INTO public.set_scores VALUES (6580, 983, 1, 25, 18);
INSERT INTO public.set_scores VALUES (6581, 983, 2, 25, 20);
INSERT INTO public.set_scores VALUES (6582, 983, 3, 28, 26);
INSERT INTO public.set_scores VALUES (6583, 994, 1, 27, 25);
INSERT INTO public.set_scores VALUES (6584, 994, 2, 22, 25);
INSERT INTO public.set_scores VALUES (6585, 994, 3, 16, 25);
INSERT INTO public.set_scores VALUES (6586, 994, 4, 23, 25);
INSERT INTO public.set_scores VALUES (6587, 988, 1, 20, 25);
INSERT INTO public.set_scores VALUES (6588, 988, 2, 18, 25);
INSERT INTO public.set_scores VALUES (6589, 988, 3, 28, 26);
INSERT INTO public.set_scores VALUES (6590, 988, 4, 25, 19);
INSERT INTO public.set_scores VALUES (6591, 988, 5, 15, 13);
INSERT INTO public.set_scores VALUES (6592, 990, 1, 18, 25);
INSERT INTO public.set_scores VALUES (6593, 990, 2, 23, 25);
INSERT INTO public.set_scores VALUES (6594, 990, 3, 25, 22);
INSERT INTO public.set_scores VALUES (6595, 990, 4, 25, 14);
INSERT INTO public.set_scores VALUES (6596, 990, 5, 18, 16);
INSERT INTO public.set_scores VALUES (6597, 989, 1, 21, 25);
INSERT INTO public.set_scores VALUES (6598, 989, 2, 19, 25);
INSERT INTO public.set_scores VALUES (6599, 989, 3, 23, 25);
INSERT INTO public.set_scores VALUES (6604, 992, 1, 22, 25);
INSERT INTO public.set_scores VALUES (6605, 992, 2, 22, 25);
INSERT INTO public.set_scores VALUES (6606, 992, 3, 26, 24);
INSERT INTO public.set_scores VALUES (6607, 992, 4, 26, 28);
INSERT INTO public.set_scores VALUES (6608, 991, 1, 25, 22);
INSERT INTO public.set_scores VALUES (6609, 991, 2, 25, 23);
INSERT INTO public.set_scores VALUES (6610, 991, 3, 25, 23);
INSERT INTO public.set_scores VALUES (6611, 995, 1, 23, 25);
INSERT INTO public.set_scores VALUES (6612, 995, 2, 25, 14);
INSERT INTO public.set_scores VALUES (6613, 995, 3, 21, 25);
INSERT INTO public.set_scores VALUES (6614, 995, 4, 25, 21);
INSERT INTO public.set_scores VALUES (6615, 995, 5, 12, 15);
INSERT INTO public.set_scores VALUES (6621, 999, 1, 25, 15);
INSERT INTO public.set_scores VALUES (6622, 999, 2, 23, 25);
INSERT INTO public.set_scores VALUES (6623, 999, 3, 25, 21);
INSERT INTO public.set_scores VALUES (6624, 999, 4, 15, 25);
INSERT INTO public.set_scores VALUES (6625, 999, 5, 15, 10);
INSERT INTO public.set_scores VALUES (6626, 1001, 1, 20, 25);
INSERT INTO public.set_scores VALUES (6627, 1001, 2, 15, 25);
INSERT INTO public.set_scores VALUES (6628, 1001, 3, 23, 25);
INSERT INTO public.set_scores VALUES (7618, 1097, 1, 15, 25);
INSERT INTO public.set_scores VALUES (7619, 1097, 2, 11, 25);
INSERT INTO public.set_scores VALUES (7620, 1097, 3, 22, 25);
INSERT INTO public.set_scores VALUES (7621, 1102, 1, 25, 19);
INSERT INTO public.set_scores VALUES (7622, 1102, 2, 23, 25);
INSERT INTO public.set_scores VALUES (7623, 1102, 3, 22, 25);
INSERT INTO public.set_scores VALUES (7624, 1102, 4, 29, 27);
INSERT INTO public.set_scores VALUES (6637, 1002, 1, 29, 27);
INSERT INTO public.set_scores VALUES (6638, 1002, 2, 25, 16);
INSERT INTO public.set_scores VALUES (6639, 1002, 3, 19, 25);
INSERT INTO public.set_scores VALUES (6640, 1002, 4, 24, 26);
INSERT INTO public.set_scores VALUES (6641, 1002, 5, 29, 27);
INSERT INTO public.set_scores VALUES (6642, 996, 1, 19, 25);
INSERT INTO public.set_scores VALUES (6643, 996, 2, 20, 25);
INSERT INTO public.set_scores VALUES (6644, 996, 3, 23, 25);
INSERT INTO public.set_scores VALUES (6645, 1003, 1, 25, 21);
INSERT INTO public.set_scores VALUES (6646, 1003, 2, 25, 20);
INSERT INTO public.set_scores VALUES (6647, 1003, 3, 25, 21);
INSERT INTO public.set_scores VALUES (6648, 1004, 1, 25, 20);
INSERT INTO public.set_scores VALUES (6649, 1004, 2, 25, 21);
INSERT INTO public.set_scores VALUES (6650, 1004, 3, 25, 20);
INSERT INTO public.set_scores VALUES (6651, 1005, 1, 36, 34);
INSERT INTO public.set_scores VALUES (6652, 1005, 2, 25, 20);
INSERT INTO public.set_scores VALUES (6653, 1005, 3, 26, 24);
INSERT INTO public.set_scores VALUES (7625, 1102, 5, 15, 7);
INSERT INTO public.set_scores VALUES (7626, 1103, 1, 25, 19);
INSERT INTO public.set_scores VALUES (7627, 1103, 2, 14, 25);
INSERT INTO public.set_scores VALUES (7628, 1103, 3, 25, 18);
INSERT INTO public.set_scores VALUES (7629, 1103, 4, 25, 19);
INSERT INTO public.set_scores VALUES (7630, 1099, 1, 20, 25);
INSERT INTO public.set_scores VALUES (7631, 1099, 2, 25, 22);
INSERT INTO public.set_scores VALUES (7632, 1099, 3, 25, 21);
INSERT INTO public.set_scores VALUES (7633, 1099, 4, 25, 23);
INSERT INTO public.set_scores VALUES (7634, 1101, 1, 27, 25);
INSERT INTO public.set_scores VALUES (7635, 1101, 2, 25, 21);
INSERT INTO public.set_scores VALUES (7636, 1101, 3, 25, 17);
INSERT INTO public.set_scores VALUES (6666, 1006, 1, 25, 14);
INSERT INTO public.set_scores VALUES (6667, 1006, 2, 20, 25);
INSERT INTO public.set_scores VALUES (6668, 1006, 3, 17, 25);
INSERT INTO public.set_scores VALUES (6669, 1006, 4, 25, 23);
INSERT INTO public.set_scores VALUES (6670, 1006, 5, 10, 15);
INSERT INTO public.set_scores VALUES (6671, 1010, 1, 18, 25);
INSERT INTO public.set_scores VALUES (6672, 1010, 2, 23, 25);
INSERT INTO public.set_scores VALUES (6673, 1010, 3, 23, 25);
INSERT INTO public.set_scores VALUES (6674, 1007, 1, 25, 23);
INSERT INTO public.set_scores VALUES (6675, 1007, 2, 18, 25);
INSERT INTO public.set_scores VALUES (6676, 1007, 3, 18, 25);
INSERT INTO public.set_scores VALUES (6677, 1007, 4, 25, 22);
INSERT INTO public.set_scores VALUES (6678, 1007, 5, 15, 12);
INSERT INTO public.set_scores VALUES (6679, 1015, 1, 25, 21);
INSERT INTO public.set_scores VALUES (6680, 1015, 2, 27, 25);
INSERT INTO public.set_scores VALUES (6681, 1015, 3, 20, 25);
INSERT INTO public.set_scores VALUES (6682, 1015, 4, 21, 25);
INSERT INTO public.set_scores VALUES (6683, 1015, 5, 15, 11);
INSERT INTO public.set_scores VALUES (6684, 1012, 1, 20, 25);
INSERT INTO public.set_scores VALUES (6685, 1012, 2, 14, 25);
INSERT INTO public.set_scores VALUES (6686, 1012, 3, 21, 25);
INSERT INTO public.set_scores VALUES (6687, 1017, 1, 25, 19);
INSERT INTO public.set_scores VALUES (6688, 1017, 2, 25, 21);
INSERT INTO public.set_scores VALUES (6689, 1017, 3, 25, 22);
INSERT INTO public.set_scores VALUES (6690, 1019, 1, 23, 25);
INSERT INTO public.set_scores VALUES (6691, 1019, 2, 25, 23);
INSERT INTO public.set_scores VALUES (6692, 1019, 3, 25, 19);
INSERT INTO public.set_scores VALUES (6693, 1019, 4, 25, 13);
INSERT INTO public.set_scores VALUES (6694, 1016, 1, 20, 25);
INSERT INTO public.set_scores VALUES (6695, 1016, 2, 21, 25);
INSERT INTO public.set_scores VALUES (6696, 1016, 3, 17, 25);
INSERT INTO public.set_scores VALUES (6697, 1014, 1, 19, 25);
INSERT INTO public.set_scores VALUES (6698, 1014, 2, 22, 25);
INSERT INTO public.set_scores VALUES (6699, 1014, 3, 25, 22);
INSERT INTO public.set_scores VALUES (6700, 1014, 4, 25, 23);
INSERT INTO public.set_scores VALUES (6701, 1014, 5, 15, 12);
INSERT INTO public.set_scores VALUES (6702, 1018, 1, 25, 23);
INSERT INTO public.set_scores VALUES (6703, 1018, 2, 25, 23);
INSERT INTO public.set_scores VALUES (6704, 1018, 3, 25, 16);
INSERT INTO public.set_scores VALUES (6705, 1013, 1, 25, 22);
INSERT INTO public.set_scores VALUES (6706, 1013, 2, 25, 19);
INSERT INTO public.set_scores VALUES (6707, 1013, 3, 28, 26);
INSERT INTO public.set_scores VALUES (7637, 1098, 1, 25, 18);
INSERT INTO public.set_scores VALUES (7638, 1098, 2, 25, 18);
INSERT INTO public.set_scores VALUES (7639, 1098, 3, 26, 24);
INSERT INTO public.set_scores VALUES (7640, 1100, 1, 17, 25);
INSERT INTO public.set_scores VALUES (7641, 1100, 2, 16, 25);
INSERT INTO public.set_scores VALUES (7642, 1100, 3, 20, 25);
INSERT INTO public.set_scores VALUES (7643, 1111, 1, 21, 25);
INSERT INTO public.set_scores VALUES (7644, 1111, 2, 20, 25);
INSERT INTO public.set_scores VALUES (7645, 1111, 3, 22, 25);
INSERT INTO public.set_scores VALUES (7646, 1106, 1, 16, 25);
INSERT INTO public.set_scores VALUES (7647, 1106, 2, 22, 25);
INSERT INTO public.set_scores VALUES (7648, 1106, 3, 16, 25);
INSERT INTO public.set_scores VALUES (7649, 1105, 1, 25, 18);
INSERT INTO public.set_scores VALUES (6721, 1022, 1, 18, 25);
INSERT INTO public.set_scores VALUES (6722, 1022, 2, 20, 25);
INSERT INTO public.set_scores VALUES (6723, 1022, 3, 25, 20);
INSERT INTO public.set_scores VALUES (6724, 1022, 4, 21, 25);
INSERT INTO public.set_scores VALUES (6725, 1025, 1, 20, 25);
INSERT INTO public.set_scores VALUES (6726, 1025, 2, 19, 25);
INSERT INTO public.set_scores VALUES (6727, 1025, 3, 26, 24);
INSERT INTO public.set_scores VALUES (6728, 1025, 4, 23, 25);
INSERT INTO public.set_scores VALUES (6729, 1020, 1, 17, 25);
INSERT INTO public.set_scores VALUES (6730, 1020, 2, 21, 25);
INSERT INTO public.set_scores VALUES (6731, 1020, 3, 25, 22);
INSERT INTO public.set_scores VALUES (6732, 1020, 4, 25, 17);
INSERT INTO public.set_scores VALUES (6733, 1020, 5, 16, 14);
INSERT INTO public.set_scores VALUES (6734, 1024, 1, 19, 25);
INSERT INTO public.set_scores VALUES (6735, 1024, 2, 21, 25);
INSERT INTO public.set_scores VALUES (6736, 1024, 3, 25, 21);
INSERT INTO public.set_scores VALUES (6737, 1024, 4, 16, 25);
INSERT INTO public.set_scores VALUES (6738, 1031, 1, 20, 25);
INSERT INTO public.set_scores VALUES (6739, 1031, 2, 23, 25);
INSERT INTO public.set_scores VALUES (6740, 1031, 3, 18, 25);
INSERT INTO public.set_scores VALUES (6741, 1033, 1, 13, 25);
INSERT INTO public.set_scores VALUES (6742, 1033, 2, 22, 25);
INSERT INTO public.set_scores VALUES (6743, 1033, 3, 25, 20);
INSERT INTO public.set_scores VALUES (6744, 1033, 4, 21, 25);
INSERT INTO public.set_scores VALUES (6745, 1034, 1, 25, 18);
INSERT INTO public.set_scores VALUES (6746, 1034, 2, 25, 22);
INSERT INTO public.set_scores VALUES (6747, 1034, 3, 25, 20);
INSERT INTO public.set_scores VALUES (6748, 1029, 1, 23, 25);
INSERT INTO public.set_scores VALUES (6749, 1029, 2, 26, 24);
INSERT INTO public.set_scores VALUES (6750, 1029, 3, 17, 25);
INSERT INTO public.set_scores VALUES (6751, 1029, 4, 24, 26);
INSERT INTO public.set_scores VALUES (6752, 1028, 1, 25, 18);
INSERT INTO public.set_scores VALUES (6753, 1028, 2, 25, 19);
INSERT INTO public.set_scores VALUES (6754, 1028, 3, 25, 21);
INSERT INTO public.set_scores VALUES (6755, 1030, 1, 22, 25);
INSERT INTO public.set_scores VALUES (6756, 1030, 2, 25, 20);
INSERT INTO public.set_scores VALUES (6757, 1030, 3, 19, 25);
INSERT INTO public.set_scores VALUES (6758, 1030, 4, 25, 20);
INSERT INTO public.set_scores VALUES (6759, 1030, 5, 13, 15);
INSERT INTO public.set_scores VALUES (6760, 1035, 1, 25, 23);
INSERT INTO public.set_scores VALUES (6761, 1035, 2, 21, 25);
INSERT INTO public.set_scores VALUES (6762, 1035, 3, 20, 25);
INSERT INTO public.set_scores VALUES (6763, 1035, 4, 18, 25);
INSERT INTO public.set_scores VALUES (6764, 1032, 1, 25, 14);
INSERT INTO public.set_scores VALUES (6765, 1032, 2, 23, 25);
INSERT INTO public.set_scores VALUES (6766, 1032, 3, 28, 30);
INSERT INTO public.set_scores VALUES (6767, 1032, 4, 25, 23);
INSERT INTO public.set_scores VALUES (6768, 1032, 5, 15, 8);
INSERT INTO public.set_scores VALUES (6769, 1036, 1, 25, 18);
INSERT INTO public.set_scores VALUES (6770, 1036, 2, 27, 25);
INSERT INTO public.set_scores VALUES (6771, 1036, 3, 25, 18);
INSERT INTO public.set_scores VALUES (7650, 1105, 2, 25, 21);
INSERT INTO public.set_scores VALUES (7651, 1105, 3, 25, 12);
INSERT INTO public.set_scores VALUES (7652, 1110, 1, 25, 22);
INSERT INTO public.set_scores VALUES (6775, 1039, 1, 25, 18);
INSERT INTO public.set_scores VALUES (6776, 1039, 2, 25, 21);
INSERT INTO public.set_scores VALUES (6777, 1039, 3, 19, 25);
INSERT INTO public.set_scores VALUES (6778, 1039, 4, 25, 23);
INSERT INTO public.set_scores VALUES (6779, 1041, 1, 25, 20);
INSERT INTO public.set_scores VALUES (6780, 1041, 2, 25, 12);
INSERT INTO public.set_scores VALUES (6781, 1041, 3, 25, 20);
INSERT INTO public.set_scores VALUES (7653, 1110, 2, 26, 28);
INSERT INTO public.set_scores VALUES (7654, 1110, 3, 24, 26);
INSERT INTO public.set_scores VALUES (7655, 1110, 4, 23, 25);
INSERT INTO public.set_scores VALUES (6785, 1043, 1, 25, 21);
INSERT INTO public.set_scores VALUES (6786, 1043, 2, 25, 20);
INSERT INTO public.set_scores VALUES (6787, 1043, 3, 18, 25);
INSERT INTO public.set_scores VALUES (6788, 1043, 4, 25, 19);
INSERT INTO public.set_scores VALUES (6789, 1037, 1, 27, 25);
INSERT INTO public.set_scores VALUES (6790, 1037, 2, 25, 22);
INSERT INTO public.set_scores VALUES (6791, 1037, 3, 25, 20);
INSERT INTO public.set_scores VALUES (6792, 1040, 1, 25, 15);
INSERT INTO public.set_scores VALUES (6793, 1040, 2, 25, 21);
INSERT INTO public.set_scores VALUES (6794, 1040, 3, 25, 21);
INSERT INTO public.set_scores VALUES (6795, 1051, 1, 25, 20);
INSERT INTO public.set_scores VALUES (6796, 1051, 2, 25, 20);
INSERT INTO public.set_scores VALUES (6797, 1051, 3, 18, 25);
INSERT INTO public.set_scores VALUES (6798, 1051, 4, 25, 19);
INSERT INTO public.set_scores VALUES (6799, 1050, 1, 19, 25);
INSERT INTO public.set_scores VALUES (6800, 1050, 2, 32, 34);
INSERT INTO public.set_scores VALUES (6801, 1050, 3, 17, 25);
INSERT INTO public.set_scores VALUES (6802, 1048, 1, 20, 25);
INSERT INTO public.set_scores VALUES (6803, 1048, 2, 19, 25);
INSERT INTO public.set_scores VALUES (6804, 1048, 3, 25, 22);
INSERT INTO public.set_scores VALUES (6805, 1048, 4, 25, 20);
INSERT INTO public.set_scores VALUES (6806, 1048, 5, 7, 15);
INSERT INTO public.set_scores VALUES (6807, 1045, 1, 15, 25);
INSERT INTO public.set_scores VALUES (6808, 1045, 2, 25, 23);
INSERT INTO public.set_scores VALUES (6809, 1045, 3, 15, 25);
INSERT INTO public.set_scores VALUES (6810, 1045, 4, 13, 25);
INSERT INTO public.set_scores VALUES (6811, 1047, 1, 20, 25);
INSERT INTO public.set_scores VALUES (6812, 1047, 2, 23, 25);
INSERT INTO public.set_scores VALUES (6813, 1047, 3, 25, 23);
INSERT INTO public.set_scores VALUES (6814, 1047, 4, 25, 23);
INSERT INTO public.set_scores VALUES (6815, 1047, 5, 15, 17);
INSERT INTO public.set_scores VALUES (6816, 1049, 1, 25, 20);
INSERT INTO public.set_scores VALUES (6817, 1049, 2, 27, 25);
INSERT INTO public.set_scores VALUES (6818, 1049, 3, 25, 23);
INSERT INTO public.set_scores VALUES (6819, 1046, 1, 21, 25);
INSERT INTO public.set_scores VALUES (6820, 1046, 2, 19, 25);
INSERT INTO public.set_scores VALUES (6821, 1046, 3, 25, 27);
INSERT INTO public.set_scores VALUES (7656, 1109, 1, 22, 25);
INSERT INTO public.set_scores VALUES (7657, 1109, 2, 25, 17);
INSERT INTO public.set_scores VALUES (7658, 1109, 3, 20, 25);
INSERT INTO public.set_scores VALUES (7659, 1109, 4, 25, 20);
INSERT INTO public.set_scores VALUES (6826, 1053, 1, 23, 25);
INSERT INTO public.set_scores VALUES (6827, 1053, 2, 31, 33);
INSERT INTO public.set_scores VALUES (6828, 1053, 3, 25, 23);
INSERT INTO public.set_scores VALUES (6829, 1053, 4, 25, 23);
INSERT INTO public.set_scores VALUES (6830, 1053, 5, 11, 15);
INSERT INTO public.set_scores VALUES (6831, 1052, 1, 25, 21);
INSERT INTO public.set_scores VALUES (6832, 1052, 2, 25, 16);
INSERT INTO public.set_scores VALUES (6833, 1052, 3, 25, 16);
INSERT INTO public.set_scores VALUES (6834, 1056, 1, 25, 16);
INSERT INTO public.set_scores VALUES (6835, 1056, 2, 25, 21);
INSERT INTO public.set_scores VALUES (6836, 1056, 3, 25, 20);
INSERT INTO public.set_scores VALUES (7660, 1109, 5, 13, 15);
INSERT INTO public.set_scores VALUES (7661, 1107, 1, 20, 25);
INSERT INTO public.set_scores VALUES (7662, 1107, 2, 23, 25);
INSERT INTO public.set_scores VALUES (7663, 1107, 3, 27, 25);
INSERT INTO public.set_scores VALUES (7664, 1107, 4, 21, 25);
INSERT INTO public.set_scores VALUES (7665, 1108, 1, 18, 25);
INSERT INTO public.set_scores VALUES (7666, 1108, 2, 23, 25);
INSERT INTO public.set_scores VALUES (7667, 1108, 3, 25, 22);
INSERT INTO public.set_scores VALUES (7668, 1108, 4, 25, 18);
INSERT INTO public.set_scores VALUES (7669, 1108, 5, 9, 15);
INSERT INTO public.set_scores VALUES (7670, 1116, 1, 23, 25);
INSERT INTO public.set_scores VALUES (6848, 1054, 1, 20, 25);
INSERT INTO public.set_scores VALUES (6849, 1054, 2, 25, 23);
INSERT INTO public.set_scores VALUES (6850, 1054, 3, 19, 25);
INSERT INTO public.set_scores VALUES (6851, 1054, 4, 25, 18);
INSERT INTO public.set_scores VALUES (6852, 1054, 5, 13, 15);
INSERT INTO public.set_scores VALUES (6853, 1059, 1, 24, 26);
INSERT INTO public.set_scores VALUES (6854, 1059, 2, 20, 25);
INSERT INTO public.set_scores VALUES (6855, 1059, 3, 24, 26);
INSERT INTO public.set_scores VALUES (6856, 1044, 1, 20, 25);
INSERT INTO public.set_scores VALUES (6857, 1044, 2, 29, 31);
INSERT INTO public.set_scores VALUES (6858, 1044, 3, 20, 25);
INSERT INTO public.set_scores VALUES (6859, 1063, 1, 18, 25);
INSERT INTO public.set_scores VALUES (6860, 1063, 2, 25, 23);
INSERT INTO public.set_scores VALUES (6861, 1063, 3, 25, 17);
INSERT INTO public.set_scores VALUES (6862, 1063, 4, 19, 25);
INSERT INTO public.set_scores VALUES (6863, 1063, 5, 15, 11);
INSERT INTO public.set_scores VALUES (6864, 1060, 1, 25, 18);
INSERT INTO public.set_scores VALUES (6865, 1060, 2, 25, 23);
INSERT INTO public.set_scores VALUES (6866, 1060, 3, 19, 25);
INSERT INTO public.set_scores VALUES (6867, 1060, 4, 21, 25);
INSERT INTO public.set_scores VALUES (6868, 1060, 5, 11, 15);
INSERT INTO public.set_scores VALUES (6869, 1061, 1, 25, 23);
INSERT INTO public.set_scores VALUES (6870, 1061, 2, 22, 25);
INSERT INTO public.set_scores VALUES (6871, 1061, 3, 23, 25);
INSERT INTO public.set_scores VALUES (6872, 1061, 4, 18, 25);
INSERT INTO public.set_scores VALUES (6873, 1065, 1, 25, 20);
INSERT INTO public.set_scores VALUES (6874, 1065, 2, 25, 22);
INSERT INTO public.set_scores VALUES (6875, 1065, 3, 21, 25);
INSERT INTO public.set_scores VALUES (6876, 1065, 4, 20, 25);
INSERT INTO public.set_scores VALUES (6877, 1065, 5, 11, 15);
INSERT INTO public.set_scores VALUES (6878, 1064, 1, 28, 26);
INSERT INTO public.set_scores VALUES (6879, 1064, 2, 23, 25);
INSERT INTO public.set_scores VALUES (6880, 1064, 3, 19, 25);
INSERT INTO public.set_scores VALUES (6881, 1064, 4, 16, 25);
INSERT INTO public.set_scores VALUES (6882, 1066, 1, 21, 25);
INSERT INTO public.set_scores VALUES (6883, 1066, 2, 23, 25);
INSERT INTO public.set_scores VALUES (6884, 1066, 3, 25, 13);
INSERT INTO public.set_scores VALUES (6885, 1066, 4, 20, 25);
INSERT INTO public.set_scores VALUES (6886, 1062, 1, 23, 25);
INSERT INTO public.set_scores VALUES (6887, 1062, 2, 19, 25);
INSERT INTO public.set_scores VALUES (6888, 1062, 3, 25, 22);
INSERT INTO public.set_scores VALUES (6889, 1062, 4, 20, 25);
INSERT INTO public.set_scores VALUES (6890, 1069, 1, 25, 22);
INSERT INTO public.set_scores VALUES (6891, 1069, 2, 25, 16);
INSERT INTO public.set_scores VALUES (6892, 1069, 3, 26, 28);
INSERT INTO public.set_scores VALUES (6893, 1069, 4, 22, 25);
INSERT INTO public.set_scores VALUES (6894, 1069, 5, 14, 16);
INSERT INTO public.set_scores VALUES (6895, 1075, 1, 26, 24);
INSERT INTO public.set_scores VALUES (6896, 1075, 2, 25, 17);
INSERT INTO public.set_scores VALUES (6897, 1075, 3, 34, 32);
INSERT INTO public.set_scores VALUES (7671, 1116, 2, 25, 20);
INSERT INTO public.set_scores VALUES (7672, 1116, 3, 25, 17);
INSERT INTO public.set_scores VALUES (7673, 1116, 4, 21, 25);
INSERT INTO public.set_scores VALUES (7674, 1116, 5, 13, 15);
INSERT INTO public.set_scores VALUES (7675, 1119, 1, 18, 25);
INSERT INTO public.set_scores VALUES (7676, 1119, 2, 16, 25);
INSERT INTO public.set_scores VALUES (7677, 1119, 3, 25, 19);
INSERT INTO public.set_scores VALUES (7678, 1119, 4, 14, 25);
INSERT INTO public.set_scores VALUES (7679, 1113, 1, 23, 25);
INSERT INTO public.set_scores VALUES (7680, 1113, 2, 18, 25);
INSERT INTO public.set_scores VALUES (7681, 1113, 3, 25, 19);
INSERT INTO public.set_scores VALUES (7682, 1113, 4, 20, 25);
INSERT INTO public.set_scores VALUES (7683, 1118, 1, 25, 16);
INSERT INTO public.set_scores VALUES (7684, 1118, 2, 25, 23);
INSERT INTO public.set_scores VALUES (7685, 1118, 3, 26, 24);
INSERT INTO public.set_scores VALUES (7686, 1117, 1, 25, 13);
INSERT INTO public.set_scores VALUES (6914, 1071, 1, 32, 30);
INSERT INTO public.set_scores VALUES (6915, 1071, 2, 16, 25);
INSERT INTO public.set_scores VALUES (6916, 1071, 3, 25, 21);
INSERT INTO public.set_scores VALUES (6917, 1071, 4, 25, 21);
INSERT INTO public.set_scores VALUES (7687, 1117, 2, 25, 14);
INSERT INTO public.set_scores VALUES (7688, 1117, 3, 25, 16);
INSERT INTO public.set_scores VALUES (7689, 1115, 1, 25, 16);
INSERT INTO public.set_scores VALUES (7690, 1115, 2, 25, 13);
INSERT INTO public.set_scores VALUES (7691, 1115, 3, 25, 19);
INSERT INTO public.set_scores VALUES (7692, 1114, 1, 18, 25);
INSERT INTO public.set_scores VALUES (7693, 1114, 2, 25, 21);
INSERT INTO public.set_scores VALUES (7694, 1114, 3, 24, 26);
INSERT INTO public.set_scores VALUES (7695, 1114, 4, 23, 25);
INSERT INTO public.set_scores VALUES (7696, 1127, 1, 25, 0);
INSERT INTO public.set_scores VALUES (7697, 1127, 2, 25, 0);
INSERT INTO public.set_scores VALUES (7698, 1127, 3, 25, 0);
INSERT INTO public.set_scores VALUES (7699, 1123, 1, 25, 22);
INSERT INTO public.set_scores VALUES (7700, 1123, 2, 25, 22);
INSERT INTO public.set_scores VALUES (7701, 1123, 3, 14, 25);
INSERT INTO public.set_scores VALUES (7702, 1123, 4, 15, 25);
INSERT INTO public.set_scores VALUES (7703, 1123, 5, 13, 15);
INSERT INTO public.set_scores VALUES (7704, 1126, 1, 25, 18);
INSERT INTO public.set_scores VALUES (7705, 1126, 2, 25, 17);
INSERT INTO public.set_scores VALUES (7706, 1126, 3, 17, 25);
INSERT INTO public.set_scores VALUES (7707, 1126, 4, 25, 17);
INSERT INTO public.set_scores VALUES (7708, 1122, 1, 24, 26);
INSERT INTO public.set_scores VALUES (7709, 1122, 2, 22, 25);
INSERT INTO public.set_scores VALUES (7710, 1122, 3, 15, 25);
INSERT INTO public.set_scores VALUES (7711, 1125, 1, 25, 21);
INSERT INTO public.set_scores VALUES (7712, 1125, 2, 25, 19);
INSERT INTO public.set_scores VALUES (7735, 1135, 1, 25, 22);
INSERT INTO public.set_scores VALUES (7736, 1135, 2, 27, 25);
INSERT INTO public.set_scores VALUES (7737, 1135, 3, 18, 25);
INSERT INTO public.set_scores VALUES (7738, 1135, 4, 25, 19);
INSERT INTO public.set_scores VALUES (7739, 1129, 1, 25, 15);
INSERT INTO public.set_scores VALUES (7740, 1129, 2, 26, 28);
INSERT INTO public.set_scores VALUES (7741, 1129, 3, 27, 25);
INSERT INTO public.set_scores VALUES (7742, 1129, 4, 25, 19);
INSERT INTO public.set_scores VALUES (7743, 1131, 1, 22, 25);
INSERT INTO public.set_scores VALUES (7744, 1131, 2, 20, 25);
INSERT INTO public.set_scores VALUES (7745, 1131, 3, 25, 23);
INSERT INTO public.set_scores VALUES (7746, 1131, 4, 19, 25);
INSERT INTO public.set_scores VALUES (7747, 1143, 1, 25, 18);
INSERT INTO public.set_scores VALUES (7748, 1143, 2, 30, 28);
INSERT INTO public.set_scores VALUES (7749, 1143, 3, 25, 16);
INSERT INTO public.set_scores VALUES (7756, 1137, 1, 15, 25);
INSERT INTO public.set_scores VALUES (7757, 1137, 2, 25, 23);
INSERT INTO public.set_scores VALUES (7758, 1137, 3, 22, 25);
INSERT INTO public.set_scores VALUES (7759, 1137, 4, 25, 18);
INSERT INTO public.set_scores VALUES (7760, 1137, 5, 15, 11);
INSERT INTO public.set_scores VALUES (7761, 1139, 1, 25, 22);
INSERT INTO public.set_scores VALUES (7762, 1139, 2, 22, 25);
INSERT INTO public.set_scores VALUES (7763, 1139, 3, 25, 21);
INSERT INTO public.set_scores VALUES (7764, 1139, 4, 25, 17);
INSERT INTO public.set_scores VALUES (7765, 1140, 1, 25, 21);
INSERT INTO public.set_scores VALUES (7766, 1140, 2, 20, 25);
INSERT INTO public.set_scores VALUES (7767, 1140, 3, 25, 16);
INSERT INTO public.set_scores VALUES (7768, 1140, 4, 25, 27);
INSERT INTO public.set_scores VALUES (7769, 1140, 5, 22, 20);
INSERT INTO public.set_scores VALUES (7770, 1141, 1, 25, 18);
INSERT INTO public.set_scores VALUES (7771, 1141, 2, 25, 16);
INSERT INTO public.set_scores VALUES (7772, 1141, 3, 25, 15);
INSERT INTO public.set_scores VALUES (7773, 1147, 1, 25, 17);
INSERT INTO public.set_scores VALUES (7774, 1147, 2, 25, 21);
INSERT INTO public.set_scores VALUES (7775, 1147, 3, 23, 25);
INSERT INTO public.set_scores VALUES (7776, 1147, 4, 25, 20);
INSERT INTO public.set_scores VALUES (7777, 1145, 1, 23, 25);
INSERT INTO public.set_scores VALUES (7778, 1145, 2, 19, 25);
INSERT INTO public.set_scores VALUES (7779, 1145, 3, 19, 25);
INSERT INTO public.set_scores VALUES (7787, 1151, 1, 16, 25);
INSERT INTO public.set_scores VALUES (7788, 1151, 2, 25, 22);
INSERT INTO public.set_scores VALUES (7789, 1151, 3, 25, 23);
INSERT INTO public.set_scores VALUES (7790, 1151, 4, 22, 25);
INSERT INTO public.set_scores VALUES (7791, 1151, 5, 15, 4);
INSERT INTO public.set_scores VALUES (7792, 1148, 1, 26, 28);
INSERT INTO public.set_scores VALUES (7793, 1148, 2, 16, 25);
INSERT INTO public.set_scores VALUES (7794, 1148, 3, 20, 25);
INSERT INTO public.set_scores VALUES (7795, 1150, 1, 25, 20);
INSERT INTO public.set_scores VALUES (7796, 1150, 2, 25, 23);
INSERT INTO public.set_scores VALUES (7797, 1150, 3, 25, 20);
INSERT INTO public.set_scores VALUES (7798, 1159, 1, 25, 16);
INSERT INTO public.set_scores VALUES (7799, 1159, 2, 18, 25);
INSERT INTO public.set_scores VALUES (7800, 1159, 3, 17, 25);
INSERT INTO public.set_scores VALUES (7801, 1159, 4, 25, 22);
INSERT INTO public.set_scores VALUES (7802, 1159, 5, 15, 13);
INSERT INTO public.set_scores VALUES (7803, 1158, 1, 25, 12);
INSERT INTO public.set_scores VALUES (7804, 1158, 2, 25, 23);
INSERT INTO public.set_scores VALUES (7805, 1158, 3, 25, 18);
INSERT INTO public.set_scores VALUES (7814, 1156, 1, 25, 17);
INSERT INTO public.set_scores VALUES (7815, 1156, 2, 23, 25);
INSERT INTO public.set_scores VALUES (7816, 1156, 3, 23, 25);
INSERT INTO public.set_scores VALUES (7817, 1156, 4, 25, 22);
INSERT INTO public.set_scores VALUES (7818, 1156, 5, 11, 15);
INSERT INTO public.set_scores VALUES (7819, 1154, 1, 25, 20);
INSERT INTO public.set_scores VALUES (7820, 1154, 2, 22, 25);
INSERT INTO public.set_scores VALUES (7821, 1154, 3, 13, 25);
INSERT INTO public.set_scores VALUES (7822, 1154, 4, 25, 22);
INSERT INTO public.set_scores VALUES (7823, 1154, 5, 6, 15);
INSERT INTO public.set_scores VALUES (7824, 1157, 1, 23, 25);
INSERT INTO public.set_scores VALUES (7825, 1157, 2, 25, 23);
INSERT INTO public.set_scores VALUES (7826, 1157, 3, 17, 25);
INSERT INTO public.set_scores VALUES (7827, 1157, 4, 15, 25);
INSERT INTO public.set_scores VALUES (7828, 1162, 1, 22, 25);
INSERT INTO public.set_scores VALUES (7829, 1162, 2, 25, 22);
INSERT INTO public.set_scores VALUES (7830, 1162, 3, 25, 21);
INSERT INTO public.set_scores VALUES (7831, 1162, 4, 23, 25);
INSERT INTO public.set_scores VALUES (7832, 1162, 5, 15, 11);
INSERT INTO public.set_scores VALUES (7833, 1167, 1, 21, 25);
INSERT INTO public.set_scores VALUES (7834, 1167, 2, 25, 23);
INSERT INTO public.set_scores VALUES (7835, 1167, 3, 25, 21);
INSERT INTO public.set_scores VALUES (7836, 1167, 4, 22, 25);
INSERT INTO public.set_scores VALUES (7837, 1167, 5, 12, 15);
INSERT INTO public.set_scores VALUES (7838, 1165, 1, 19, 25);
INSERT INTO public.set_scores VALUES (7839, 1165, 2, 16, 25);
INSERT INTO public.set_scores VALUES (7840, 1165, 3, 21, 25);
INSERT INTO public.set_scores VALUES (7841, 1161, 1, 21, 25);
INSERT INTO public.set_scores VALUES (7842, 1161, 2, 25, 22);
INSERT INTO public.set_scores VALUES (7843, 1161, 3, 30, 28);
INSERT INTO public.set_scores VALUES (7844, 1161, 4, 32, 30);
INSERT INTO public.set_scores VALUES (7852, 1164, 1, 25, 19);
INSERT INTO public.set_scores VALUES (7853, 1164, 2, 18, 25);
INSERT INTO public.set_scores VALUES (7854, 1164, 3, 32, 34);
INSERT INTO public.set_scores VALUES (7855, 1164, 4, 25, 18);
INSERT INTO public.set_scores VALUES (7856, 1164, 5, 10, 15);
INSERT INTO public.set_scores VALUES (7857, 1175, 1, 26, 28);
INSERT INTO public.set_scores VALUES (7858, 1175, 2, 25, 23);
INSERT INTO public.set_scores VALUES (7859, 1175, 3, 29, 31);
INSERT INTO public.set_scores VALUES (7860, 1175, 4, 23, 25);
INSERT INTO public.set_scores VALUES (7861, 1173, 1, 25, 19);
INSERT INTO public.set_scores VALUES (7862, 1173, 2, 25, 17);
INSERT INTO public.set_scores VALUES (7863, 1173, 3, 25, 22);
INSERT INTO public.set_scores VALUES (7864, 1174, 1, 25, 21);
INSERT INTO public.set_scores VALUES (7865, 1174, 2, 25, 20);
INSERT INTO public.set_scores VALUES (7866, 1174, 3, 23, 25);
INSERT INTO public.set_scores VALUES (7867, 1174, 4, 22, 25);
INSERT INTO public.set_scores VALUES (7868, 1174, 5, 15, 13);
INSERT INTO public.set_scores VALUES (7869, 1169, 1, 25, 11);
INSERT INTO public.set_scores VALUES (7870, 1169, 2, 25, 21);
INSERT INTO public.set_scores VALUES (7871, 1169, 3, 25, 19);
INSERT INTO public.set_scores VALUES (7872, 1170, 1, 25, 12);
INSERT INTO public.set_scores VALUES (7873, 1170, 2, 25, 19);
INSERT INTO public.set_scores VALUES (7874, 1170, 3, 25, 13);
INSERT INTO public.set_scores VALUES (7875, 1171, 1, 25, 19);
INSERT INTO public.set_scores VALUES (7876, 1171, 2, 22, 25);
INSERT INTO public.set_scores VALUES (7877, 1171, 3, 25, 22);
INSERT INTO public.set_scores VALUES (7878, 1171, 4, 25, 21);
INSERT INTO public.set_scores VALUES (7879, 1172, 1, 20, 25);
INSERT INTO public.set_scores VALUES (7880, 1172, 2, 25, 21);
INSERT INTO public.set_scores VALUES (7881, 1172, 3, 16, 25);
INSERT INTO public.set_scores VALUES (7882, 1172, 4, 25, 14);
INSERT INTO public.set_scores VALUES (7883, 1172, 5, 15, 12);
INSERT INTO public.set_scores VALUES (7899, 1180, 1, 24, 26);
INSERT INTO public.set_scores VALUES (7900, 1180, 2, 26, 24);
INSERT INTO public.set_scores VALUES (7901, 1180, 3, 25, 12);
INSERT INTO public.set_scores VALUES (7902, 1180, 4, 16, 25);
INSERT INTO public.set_scores VALUES (7903, 1180, 5, 11, 15);
INSERT INTO public.set_scores VALUES (7904, 1178, 1, 18, 25);
INSERT INTO public.set_scores VALUES (7905, 1178, 2, 22, 25);
INSERT INTO public.set_scores VALUES (7906, 1178, 3, 20, 25);
INSERT INTO public.set_scores VALUES (7907, 1181, 1, 23, 25);
INSERT INTO public.set_scores VALUES (7908, 1181, 2, 18, 25);
INSERT INTO public.set_scores VALUES (7909, 1181, 3, 21, 25);
INSERT INTO public.set_scores VALUES (7910, 1191, 1, 23, 25);
INSERT INTO public.set_scores VALUES (7911, 1191, 2, 28, 26);
INSERT INTO public.set_scores VALUES (7912, 1191, 3, 16, 25);
INSERT INTO public.set_scores VALUES (7913, 1191, 4, 23, 25);
INSERT INTO public.set_scores VALUES (7914, 1188, 1, 25, 27);
INSERT INTO public.set_scores VALUES (7915, 1188, 2, 25, 22);
INSERT INTO public.set_scores VALUES (7916, 1188, 3, 25, 13);
INSERT INTO public.set_scores VALUES (7917, 1188, 4, 25, 21);
INSERT INTO public.set_scores VALUES (7918, 1185, 1, 28, 26);
INSERT INTO public.set_scores VALUES (7919, 1185, 2, 25, 18);
INSERT INTO public.set_scores VALUES (7920, 1185, 3, 25, 21);
INSERT INTO public.set_scores VALUES (7921, 1186, 1, 28, 30);
INSERT INTO public.set_scores VALUES (7922, 1186, 2, 25, 16);
INSERT INTO public.set_scores VALUES (7923, 1186, 3, 21, 25);
INSERT INTO public.set_scores VALUES (7924, 1186, 4, 25, 18);
INSERT INTO public.set_scores VALUES (7925, 1186, 5, 15, 7);
INSERT INTO public.set_scores VALUES (7926, 1189, 1, 36, 38);
INSERT INTO public.set_scores VALUES (7927, 1189, 2, 25, 18);
INSERT INTO public.set_scores VALUES (7928, 1189, 3, 25, 14);
INSERT INTO public.set_scores VALUES (7929, 1189, 4, 25, 18);
INSERT INTO public.set_scores VALUES (7930, 1187, 1, 21, 25);
INSERT INTO public.set_scores VALUES (7931, 1187, 2, 25, 20);
INSERT INTO public.set_scores VALUES (7932, 1187, 3, 25, 23);
INSERT INTO public.set_scores VALUES (7933, 1187, 4, 19, 25);
INSERT INTO public.set_scores VALUES (7934, 1187, 5, 15, 10);
INSERT INTO public.set_scores VALUES (7935, 1190, 1, 33, 35);
INSERT INTO public.set_scores VALUES (7936, 1190, 2, 25, 18);
INSERT INTO public.set_scores VALUES (7937, 1190, 3, 25, 20);
INSERT INTO public.set_scores VALUES (7938, 1190, 4, 21, 25);
INSERT INTO public.set_scores VALUES (7939, 1190, 5, 15, 10);
INSERT INTO public.set_scores VALUES (7943, 1194, 1, 27, 25);
INSERT INTO public.set_scores VALUES (7944, 1194, 2, 23, 25);
INSERT INTO public.set_scores VALUES (7945, 1194, 3, 20, 25);
INSERT INTO public.set_scores VALUES (7946, 1194, 4, 20, 25);
INSERT INTO public.set_scores VALUES (7947, 1195, 1, 25, 21);
INSERT INTO public.set_scores VALUES (7948, 1195, 2, 25, 14);
INSERT INTO public.set_scores VALUES (7949, 1195, 3, 21, 25);
INSERT INTO public.set_scores VALUES (7950, 1195, 4, 13, 25);
INSERT INTO public.set_scores VALUES (7951, 1195, 5, 16, 14);
INSERT INTO public.set_scores VALUES (7958, 1197, 1, 25, 21);
INSERT INTO public.set_scores VALUES (7959, 1197, 2, 25, 21);
INSERT INTO public.set_scores VALUES (7960, 1197, 3, 19, 25);
INSERT INTO public.set_scores VALUES (7961, 1197, 4, 26, 24);
INSERT INTO public.set_scores VALUES (7962, 1196, 1, 30, 28);
INSERT INTO public.set_scores VALUES (7963, 1196, 2, 15, 25);
INSERT INTO public.set_scores VALUES (7964, 1196, 3, 22, 25);
INSERT INTO public.set_scores VALUES (7965, 1196, 4, 21, 25);
INSERT INTO public.set_scores VALUES (7966, 1202, 1, 25, 23);
INSERT INTO public.set_scores VALUES (7967, 1202, 2, 31, 29);
INSERT INTO public.set_scores VALUES (7968, 1202, 3, 25, 21);
INSERT INTO public.set_scores VALUES (7983, 1205, 1, 25, 18);
INSERT INTO public.set_scores VALUES (7984, 1205, 2, 30, 32);
INSERT INTO public.set_scores VALUES (7985, 1205, 3, 25, 14);
INSERT INTO public.set_scores VALUES (7986, 1205, 4, 17, 25);
INSERT INTO public.set_scores VALUES (7987, 1205, 5, 11, 15);
INSERT INTO public.set_scores VALUES (7988, 1204, 1, 22, 25);
INSERT INTO public.set_scores VALUES (7989, 1204, 2, 25, 15);
INSERT INTO public.set_scores VALUES (7990, 1204, 3, 25, 18);
INSERT INTO public.set_scores VALUES (7991, 1204, 4, 25, 19);
INSERT INTO public.set_scores VALUES (7992, 1209, 1, 18, 25);
INSERT INTO public.set_scores VALUES (7993, 1209, 2, 18, 25);
INSERT INTO public.set_scores VALUES (7994, 1209, 3, 20, 25);
INSERT INTO public.set_scores VALUES (7995, 1215, 1, 23, 25);
INSERT INTO public.set_scores VALUES (7996, 1215, 2, 25, 18);
INSERT INTO public.set_scores VALUES (7997, 1215, 3, 25, 18);
INSERT INTO public.set_scores VALUES (7998, 1215, 4, 18, 25);
INSERT INTO public.set_scores VALUES (7999, 1215, 5, 13, 15);
INSERT INTO public.set_scores VALUES (8004, 1212, 1, 22, 25);
INSERT INTO public.set_scores VALUES (8005, 1212, 2, 22, 25);
INSERT INTO public.set_scores VALUES (8006, 1212, 3, 28, 26);
INSERT INTO public.set_scores VALUES (8007, 1212, 4, 22, 25);
INSERT INTO public.set_scores VALUES (8008, 1213, 1, 20, 25);
INSERT INTO public.set_scores VALUES (8009, 1213, 2, 20, 25);
INSERT INTO public.set_scores VALUES (8010, 1213, 3, 17, 25);
INSERT INTO public.set_scores VALUES (8011, 1210, 1, 22, 25);
INSERT INTO public.set_scores VALUES (8012, 1210, 2, 25, 16);
INSERT INTO public.set_scores VALUES (8013, 1210, 3, 25, 20);
INSERT INTO public.set_scores VALUES (8014, 1210, 4, 25, 15);
INSERT INTO public.set_scores VALUES (8015, 1214, 1, 25, 19);
INSERT INTO public.set_scores VALUES (8016, 1214, 2, 25, 16);
INSERT INTO public.set_scores VALUES (8017, 1214, 3, 25, 21);
INSERT INTO public.set_scores VALUES (8018, 1219, 1, 15, 25);
INSERT INTO public.set_scores VALUES (8019, 1219, 2, 22, 25);
INSERT INTO public.set_scores VALUES (8020, 1219, 3, 22, 25);
INSERT INTO public.set_scores VALUES (8021, 1222, 1, 24, 26);
INSERT INTO public.set_scores VALUES (8022, 1222, 2, 25, 18);
INSERT INTO public.set_scores VALUES (8023, 1222, 3, 25, 23);
INSERT INTO public.set_scores VALUES (8024, 1222, 4, 27, 25);
INSERT INTO public.set_scores VALUES (8034, 1220, 1, 25, 22);
INSERT INTO public.set_scores VALUES (8035, 1220, 2, 17, 25);
INSERT INTO public.set_scores VALUES (8036, 1220, 3, 25, 21);
INSERT INTO public.set_scores VALUES (8037, 1220, 4, 23, 25);
INSERT INTO public.set_scores VALUES (8038, 1220, 5, 15, 17);
INSERT INTO public.set_scores VALUES (8039, 1218, 1, 18, 25);
INSERT INTO public.set_scores VALUES (8040, 1218, 2, 28, 26);
INSERT INTO public.set_scores VALUES (8041, 1218, 3, 25, 22);
INSERT INTO public.set_scores VALUES (8042, 1218, 4, 23, 25);
INSERT INTO public.set_scores VALUES (8043, 1218, 5, 10, 15);
INSERT INTO public.set_scores VALUES (8044, 1230, 1, 23, 25);
INSERT INTO public.set_scores VALUES (8045, 1230, 2, 19, 25);
INSERT INTO public.set_scores VALUES (8046, 1230, 3, 25, 18);
INSERT INTO public.set_scores VALUES (8047, 1230, 4, 25, 20);
INSERT INTO public.set_scores VALUES (8048, 1230, 5, 15, 9);
INSERT INTO public.set_scores VALUES (8052, 1226, 1, 25, 20);
INSERT INTO public.set_scores VALUES (8053, 1226, 2, 20, 25);
INSERT INTO public.set_scores VALUES (8054, 1226, 3, 25, 23);
INSERT INTO public.set_scores VALUES (8055, 1226, 4, 25, 20);
INSERT INTO public.set_scores VALUES (8059, 1231, 1, 25, 23);
INSERT INTO public.set_scores VALUES (8060, 1231, 2, 25, 18);
INSERT INTO public.set_scores VALUES (8061, 1231, 3, 25, 17);
INSERT INTO public.set_scores VALUES (8062, 1225, 1, 14, 25);
INSERT INTO public.set_scores VALUES (8063, 1225, 2, 20, 25);
INSERT INTO public.set_scores VALUES (8064, 1225, 3, 15, 25);
INSERT INTO public.set_scores VALUES (8065, 1229, 1, 25, 21);
INSERT INTO public.set_scores VALUES (8066, 1229, 2, 25, 19);
INSERT INTO public.set_scores VALUES (8067, 1229, 3, 27, 25);
INSERT INTO public.set_scores VALUES (8068, 1243, 1, 25, 21);
INSERT INTO public.set_scores VALUES (8069, 1243, 2, 25, 17);
INSERT INTO public.set_scores VALUES (8070, 1243, 3, 25, 23);
INSERT INTO public.set_scores VALUES (8071, 1240, 1, 25, 18);
INSERT INTO public.set_scores VALUES (8072, 1240, 2, 25, 23);
INSERT INTO public.set_scores VALUES (8073, 1240, 3, 27, 25);
INSERT INTO public.set_scores VALUES (8074, 1246, 1, 23, 25);
INSERT INTO public.set_scores VALUES (8075, 1246, 2, 26, 24);
INSERT INTO public.set_scores VALUES (8076, 1246, 3, 17, 25);
INSERT INTO public.set_scores VALUES (8077, 1246, 4, 25, 20);
INSERT INTO public.set_scores VALUES (8078, 1246, 5, 15, 10);
INSERT INTO public.set_scores VALUES (8079, 1247, 1, 25, 23);
INSERT INTO public.set_scores VALUES (8080, 1247, 2, 25, 21);
INSERT INTO public.set_scores VALUES (8081, 1247, 3, 25, 23);
INSERT INTO public.set_scores VALUES (8082, 1242, 1, 25, 22);
INSERT INTO public.set_scores VALUES (8083, 1242, 2, 25, 21);
INSERT INTO public.set_scores VALUES (8084, 1242, 3, 25, 13);
INSERT INTO public.set_scores VALUES (8085, 1245, 1, 17, 25);
INSERT INTO public.set_scores VALUES (8086, 1245, 2, 25, 19);
INSERT INTO public.set_scores VALUES (8087, 1245, 3, 23, 25);
INSERT INTO public.set_scores VALUES (8088, 1245, 4, 19, 25);
INSERT INTO public.set_scores VALUES (8093, 1239, 1, 25, 23);
INSERT INTO public.set_scores VALUES (8094, 1239, 2, 20, 25);
INSERT INTO public.set_scores VALUES (8095, 1239, 3, 25, 23);
INSERT INTO public.set_scores VALUES (8096, 1239, 4, 23, 25);
INSERT INTO public.set_scores VALUES (8097, 1239, 5, 15, 11);
INSERT INTO public.set_scores VALUES (8098, 1233, 1, 20, 25);
INSERT INTO public.set_scores VALUES (8099, 1233, 2, 25, 22);
INSERT INTO public.set_scores VALUES (8100, 1233, 3, 30, 28);
INSERT INTO public.set_scores VALUES (8101, 1233, 4, 25, 17);
INSERT INTO public.set_scores VALUES (8105, 1238, 1, 14, 25);
INSERT INTO public.set_scores VALUES (8106, 1238, 2, 25, 21);
INSERT INTO public.set_scores VALUES (8107, 1238, 3, 22, 25);
INSERT INTO public.set_scores VALUES (8108, 1238, 4, 25, 22);
INSERT INTO public.set_scores VALUES (8109, 1238, 5, 10, 15);
INSERT INTO public.set_scores VALUES (8110, 1234, 1, 25, 22);
INSERT INTO public.set_scores VALUES (8111, 1234, 2, 25, 15);
INSERT INTO public.set_scores VALUES (8112, 1234, 3, 25, 16);
INSERT INTO public.set_scores VALUES (8113, 1237, 1, 25, 22);
INSERT INTO public.set_scores VALUES (8114, 1237, 2, 17, 25);
INSERT INTO public.set_scores VALUES (8115, 1237, 3, 19, 25);
INSERT INTO public.set_scores VALUES (8116, 1237, 4, 20, 25);
INSERT INTO public.set_scores VALUES (8117, 1254, 1, 29, 31);
INSERT INTO public.set_scores VALUES (8118, 1254, 2, 25, 16);
INSERT INTO public.set_scores VALUES (8119, 1254, 3, 25, 22);
INSERT INTO public.set_scores VALUES (8120, 1254, 4, 17, 25);
INSERT INTO public.set_scores VALUES (8121, 1254, 5, 11, 15);
INSERT INTO public.set_scores VALUES (8122, 1252, 1, 25, 21);
INSERT INTO public.set_scores VALUES (8123, 1252, 2, 22, 25);
INSERT INTO public.set_scores VALUES (8124, 1252, 3, 26, 28);
INSERT INTO public.set_scores VALUES (8125, 1252, 4, 20, 25);
INSERT INTO public.set_scores VALUES (8133, 1255, 1, 21, 25);
INSERT INTO public.set_scores VALUES (8134, 1255, 2, 26, 24);
INSERT INTO public.set_scores VALUES (8135, 1255, 3, 17, 25);
INSERT INTO public.set_scores VALUES (8136, 1255, 4, 25, 19);
INSERT INTO public.set_scores VALUES (8137, 1255, 5, 19, 17);
INSERT INTO public.set_scores VALUES (8138, 1250, 1, 26, 24);
INSERT INTO public.set_scores VALUES (8139, 1250, 2, 25, 16);
INSERT INTO public.set_scores VALUES (8140, 1250, 3, 15, 25);
INSERT INTO public.set_scores VALUES (8141, 1250, 4, 21, 25);
INSERT INTO public.set_scores VALUES (8142, 1250, 5, 17, 15);
INSERT INTO public.set_scores VALUES (8143, 1249, 1, 22, 25);
INSERT INTO public.set_scores VALUES (8144, 1249, 2, 25, 22);
INSERT INTO public.set_scores VALUES (8145, 1249, 3, 31, 29);
INSERT INTO public.set_scores VALUES (8146, 1249, 4, 25, 23);
INSERT INTO public.set_scores VALUES (8156, 1260, 1, 25, 23);
INSERT INTO public.set_scores VALUES (8157, 1260, 2, 25, 23);
INSERT INTO public.set_scores VALUES (8158, 1260, 3, 19, 25);
INSERT INTO public.set_scores VALUES (8159, 1260, 4, 18, 25);
INSERT INTO public.set_scores VALUES (8160, 1260, 5, 11, 15);
INSERT INTO public.set_scores VALUES (8161, 1263, 1, 25, 21);
INSERT INTO public.set_scores VALUES (8162, 1263, 2, 20, 25);
INSERT INTO public.set_scores VALUES (8163, 1263, 3, 25, 16);
INSERT INTO public.set_scores VALUES (8164, 1263, 4, 18, 25);
INSERT INTO public.set_scores VALUES (8165, 1263, 5, 10, 15);
INSERT INTO public.set_scores VALUES (8169, 1257, 1, 20, 25);
INSERT INTO public.set_scores VALUES (8170, 1257, 2, 22, 25);
INSERT INTO public.set_scores VALUES (8171, 1257, 3, 23, 25);
INSERT INTO public.set_scores VALUES (8172, 1262, 1, 19, 25);
INSERT INTO public.set_scores VALUES (8173, 1262, 2, 16, 25);
INSERT INTO public.set_scores VALUES (8174, 1262, 3, 15, 25);
INSERT INTO public.set_scores VALUES (8184, 1271, 1, 25, 17);
INSERT INTO public.set_scores VALUES (8185, 1271, 2, 19, 25);
INSERT INTO public.set_scores VALUES (8186, 1271, 3, 22, 25);
INSERT INTO public.set_scores VALUES (8187, 1271, 4, 25, 14);
INSERT INTO public.set_scores VALUES (8188, 1271, 5, 13, 15);
INSERT INTO public.set_scores VALUES (8189, 1265, 1, 25, 20);
INSERT INTO public.set_scores VALUES (8190, 1265, 2, 25, 16);
INSERT INTO public.set_scores VALUES (8191, 1265, 3, 25, 23);
INSERT INTO public.set_scores VALUES (8195, 1268, 1, 23, 25);
INSERT INTO public.set_scores VALUES (8196, 1268, 2, 19, 25);
INSERT INTO public.set_scores VALUES (8197, 1268, 3, 19, 25);
INSERT INTO public.set_scores VALUES (8198, 1267, 1, 21, 25);
INSERT INTO public.set_scores VALUES (8199, 1267, 2, 25, 15);
INSERT INTO public.set_scores VALUES (8200, 1267, 3, 24, 26);
INSERT INTO public.set_scores VALUES (8201, 1267, 4, 20, 25);
INSERT INTO public.set_scores VALUES (8202, 1278, 1, 25, 16);
INSERT INTO public.set_scores VALUES (8203, 1278, 2, 19, 25);
INSERT INTO public.set_scores VALUES (8204, 1278, 3, 25, 22);
INSERT INTO public.set_scores VALUES (8205, 1278, 4, 17, 25);
INSERT INTO public.set_scores VALUES (8206, 1278, 5, 10, 15);
INSERT INTO public.set_scores VALUES (8217, 1274, 1, 24, 26);
INSERT INTO public.set_scores VALUES (8218, 1274, 2, 19, 25);
INSERT INTO public.set_scores VALUES (8219, 1274, 3, 25, 13);
INSERT INTO public.set_scores VALUES (8220, 1274, 4, 25, 13);
INSERT INTO public.set_scores VALUES (8221, 1274, 5, 15, 9);
INSERT INTO public.set_scores VALUES (8222, 1273, 1, 20, 25);
INSERT INTO public.set_scores VALUES (8223, 1273, 2, 20, 25);
INSERT INTO public.set_scores VALUES (8224, 1273, 3, 25, 17);
INSERT INTO public.set_scores VALUES (8225, 1273, 4, 25, 27);
INSERT INTO public.set_scores VALUES (8226, 1276, 1, 26, 28);
INSERT INTO public.set_scores VALUES (8227, 1276, 2, 25, 20);
INSERT INTO public.set_scores VALUES (8228, 1276, 3, 25, 22);
INSERT INTO public.set_scores VALUES (8229, 1276, 4, 23, 25);
INSERT INTO public.set_scores VALUES (8230, 1276, 5, 12, 15);
INSERT INTO public.set_scores VALUES (8231, 1286, 1, 27, 29);
INSERT INTO public.set_scores VALUES (8232, 1286, 2, 25, 19);
INSERT INTO public.set_scores VALUES (8233, 1286, 3, 25, 14);
INSERT INTO public.set_scores VALUES (8234, 1286, 4, 25, 10);
INSERT INTO public.set_scores VALUES (8235, 1285, 1, 21, 25);
INSERT INTO public.set_scores VALUES (8236, 1285, 2, 25, 21);
INSERT INTO public.set_scores VALUES (8237, 1285, 3, 25, 21);
INSERT INTO public.set_scores VALUES (8238, 1285, 4, 25, 22);
INSERT INTO public.set_scores VALUES (8239, 1287, 1, 25, 21);
INSERT INTO public.set_scores VALUES (8240, 1287, 2, 25, 13);
INSERT INTO public.set_scores VALUES (8241, 1287, 3, 25, 13);
INSERT INTO public.set_scores VALUES (8242, 1284, 1, 25, 17);
INSERT INTO public.set_scores VALUES (8243, 1284, 2, 25, 21);
INSERT INTO public.set_scores VALUES (8244, 1284, 3, 25, 13);
INSERT INTO public.set_scores VALUES (8245, 1281, 1, 22, 25);
INSERT INTO public.set_scores VALUES (8246, 1281, 2, 25, 18);
INSERT INTO public.set_scores VALUES (8247, 1281, 3, 25, 23);
INSERT INTO public.set_scores VALUES (8248, 1281, 4, 25, 20);
INSERT INTO public.set_scores VALUES (8249, 1282, 1, 25, 27);
INSERT INTO public.set_scores VALUES (8250, 1282, 2, 25, 17);
INSERT INTO public.set_scores VALUES (8251, 1282, 3, 23, 25);
INSERT INTO public.set_scores VALUES (8252, 1282, 4, 25, 15);
INSERT INTO public.set_scores VALUES (8253, 1282, 5, 15, 10);
INSERT INTO public.set_scores VALUES (8254, 1283, 1, 16, 25);
INSERT INTO public.set_scores VALUES (8255, 1283, 2, 28, 26);
INSERT INTO public.set_scores VALUES (8256, 1283, 3, 25, 22);
INSERT INTO public.set_scores VALUES (8257, 1283, 4, 20, 25);
INSERT INTO public.set_scores VALUES (8258, 1283, 5, 11, 15);
INSERT INTO public.set_scores VALUES (8259, 1292, 1, 21, 25);
INSERT INTO public.set_scores VALUES (8260, 1292, 2, 25, 20);
INSERT INTO public.set_scores VALUES (8261, 1292, 3, 23, 25);
INSERT INTO public.set_scores VALUES (8262, 1292, 4, 22, 25);
INSERT INTO public.set_scores VALUES (8263, 1291, 1, 25, 19);
INSERT INTO public.set_scores VALUES (8264, 1291, 2, 25, 23);
INSERT INTO public.set_scores VALUES (8265, 1291, 3, 17, 25);
INSERT INTO public.set_scores VALUES (8266, 1291, 4, 21, 25);
INSERT INTO public.set_scores VALUES (8267, 1291, 5, 10, 15);
INSERT INTO public.set_scores VALUES (8271, 1290, 1, 25, 20);
INSERT INTO public.set_scores VALUES (8272, 1290, 2, 17, 25);
INSERT INTO public.set_scores VALUES (8273, 1290, 3, 14, 25);
INSERT INTO public.set_scores VALUES (8274, 1290, 4, 26, 28);
INSERT INTO public.set_scores VALUES (8275, 1293, 1, 22, 25);
INSERT INTO public.set_scores VALUES (8276, 1293, 2, 25, 21);
INSERT INTO public.set_scores VALUES (8277, 1293, 3, 20, 25);
INSERT INTO public.set_scores VALUES (8278, 1293, 4, 25, 22);
INSERT INTO public.set_scores VALUES (8279, 1293, 5, 13, 15);
INSERT INTO public.set_scores VALUES (8280, 1294, 1, 20, 25);
INSERT INTO public.set_scores VALUES (8281, 1294, 2, 25, 14);
INSERT INTO public.set_scores VALUES (8282, 1294, 3, 18, 25);
INSERT INTO public.set_scores VALUES (8283, 1294, 4, 26, 28);
INSERT INTO public.set_scores VALUES (8284, 1289, 1, 15, 25);
INSERT INTO public.set_scores VALUES (8285, 1289, 2, 16, 25);
INSERT INTO public.set_scores VALUES (8286, 1289, 3, 20, 25);
INSERT INTO public.set_scores VALUES (8287, 1298, 1, 25, 22);
INSERT INTO public.set_scores VALUES (8288, 1298, 2, 25, 13);
INSERT INTO public.set_scores VALUES (8289, 1298, 3, 20, 25);
INSERT INTO public.set_scores VALUES (8290, 1298, 4, 16, 25);
INSERT INTO public.set_scores VALUES (8291, 1298, 5, 15, 13);
INSERT INTO public.set_scores VALUES (8292, 1299, 1, 25, 14);
INSERT INTO public.set_scores VALUES (8293, 1299, 2, 25, 14);
INSERT INTO public.set_scores VALUES (8294, 1299, 3, 25, 9);
INSERT INTO public.set_scores VALUES (8306, 1300, 1, 25, 17);
INSERT INTO public.set_scores VALUES (8307, 1300, 2, 25, 22);
INSERT INTO public.set_scores VALUES (8308, 1300, 3, 22, 25);
INSERT INTO public.set_scores VALUES (8309, 1300, 4, 21, 25);
INSERT INTO public.set_scores VALUES (8310, 1300, 5, 11, 15);
INSERT INTO public.set_scores VALUES (8311, 1303, 1, 25, 22);
INSERT INTO public.set_scores VALUES (8312, 1303, 2, 25, 13);
INSERT INTO public.set_scores VALUES (8313, 1303, 3, 19, 25);
INSERT INTO public.set_scores VALUES (8314, 1303, 4, 25, 20);
INSERT INTO public.set_scores VALUES (8315, 1308, 1, 27, 29);
INSERT INTO public.set_scores VALUES (8316, 1308, 2, 15, 25);
INSERT INTO public.set_scores VALUES (8317, 1308, 3, 25, 22);
INSERT INTO public.set_scores VALUES (8318, 1308, 4, 25, 19);
INSERT INTO public.set_scores VALUES (8319, 1308, 5, 9, 15);
INSERT INTO public.set_scores VALUES (8320, 1306, 1, 16, 25);
INSERT INTO public.set_scores VALUES (8321, 1306, 2, 19, 25);
INSERT INTO public.set_scores VALUES (8322, 1306, 3, 19, 25);
INSERT INTO public.set_scores VALUES (8332, 1309, 1, 25, 23);
INSERT INTO public.set_scores VALUES (8333, 1309, 2, 13, 25);
INSERT INTO public.set_scores VALUES (8334, 1309, 3, 18, 25);
INSERT INTO public.set_scores VALUES (8335, 1309, 4, 29, 27);
INSERT INTO public.set_scores VALUES (8336, 1309, 5, 12, 15);
INSERT INTO public.set_scores VALUES (8337, 1305, 1, 19, 25);
INSERT INTO public.set_scores VALUES (8338, 1305, 2, 19, 25);
INSERT INTO public.set_scores VALUES (8339, 1305, 3, 15, 25);
INSERT INTO public.set_scores VALUES (8340, 1311, 1, 25, 23);
INSERT INTO public.set_scores VALUES (8341, 1311, 2, 25, 20);
INSERT INTO public.set_scores VALUES (8342, 1311, 3, 25, 19);
INSERT INTO public.set_scores VALUES (8348, 1317, 1, 24, 26);
INSERT INTO public.set_scores VALUES (8349, 1317, 2, 14, 25);
INSERT INTO public.set_scores VALUES (8350, 1317, 3, 25, 18);
INSERT INTO public.set_scores VALUES (8351, 1317, 4, 25, 23);
INSERT INTO public.set_scores VALUES (8352, 1317, 5, 22, 24);
INSERT INTO public.set_scores VALUES (8360, 1318, 1, 26, 24);
INSERT INTO public.set_scores VALUES (8361, 1318, 2, 17, 25);
INSERT INTO public.set_scores VALUES (8362, 1318, 3, 25, 21);
INSERT INTO public.set_scores VALUES (8363, 1318, 4, 25, 19);
INSERT INTO public.set_scores VALUES (8364, 1315, 1, 26, 28);
INSERT INTO public.set_scores VALUES (8365, 1315, 2, 25, 27);
INSERT INTO public.set_scores VALUES (8366, 1315, 3, 18, 25);
INSERT INTO public.set_scores VALUES (8367, 1319, 1, 28, 30);
INSERT INTO public.set_scores VALUES (8368, 1319, 2, 25, 18);
INSERT INTO public.set_scores VALUES (8369, 1319, 3, 25, 23);
INSERT INTO public.set_scores VALUES (8370, 1319, 4, 27, 25);
INSERT INTO public.set_scores VALUES (8371, 1324, 1, 17, 25);
INSERT INTO public.set_scores VALUES (8372, 1324, 2, 24, 26);
INSERT INTO public.set_scores VALUES (8373, 1324, 3, 15, 25);
INSERT INTO public.set_scores VALUES (8374, 1325, 1, 17, 25);
INSERT INTO public.set_scores VALUES (8375, 1325, 2, 25, 17);
INSERT INTO public.set_scores VALUES (8376, 1325, 3, 25, 21);
INSERT INTO public.set_scores VALUES (8377, 1325, 4, 25, 23);
INSERT INTO public.set_scores VALUES (8378, 1323, 1, 19, 25);
INSERT INTO public.set_scores VALUES (8379, 1323, 2, 24, 26);
INSERT INTO public.set_scores VALUES (8380, 1323, 3, 14, 25);
INSERT INTO public.set_scores VALUES (8381, 1326, 1, 25, 11);
INSERT INTO public.set_scores VALUES (8382, 1326, 2, 25, 18);
INSERT INTO public.set_scores VALUES (8383, 1326, 3, 23, 25);
INSERT INTO public.set_scores VALUES (8384, 1326, 4, 25, 22);
INSERT INTO public.set_scores VALUES (8385, 1322, 1, 25, 20);
INSERT INTO public.set_scores VALUES (8386, 1322, 2, 25, 27);
INSERT INTO public.set_scores VALUES (8387, 1322, 3, 22, 25);
INSERT INTO public.set_scores VALUES (8388, 1322, 4, 25, 23);
INSERT INTO public.set_scores VALUES (8389, 1322, 5, 11, 15);
INSERT INTO public.set_scores VALUES (8390, 1321, 1, 17, 25);
INSERT INTO public.set_scores VALUES (8391, 1321, 2, 16, 25);
INSERT INTO public.set_scores VALUES (8392, 1321, 3, 18, 25);
INSERT INTO public.set_scores VALUES (8393, 1327, 1, 20, 25);
INSERT INTO public.set_scores VALUES (8394, 1327, 2, 23, 25);
INSERT INTO public.set_scores VALUES (8395, 1327, 3, 25, 22);
INSERT INTO public.set_scores VALUES (8396, 1327, 4, 25, 21);
INSERT INTO public.set_scores VALUES (8397, 1327, 5, 9, 15);
INSERT INTO public.set_scores VALUES (8398, 1330, 1, 25, 23);
INSERT INTO public.set_scores VALUES (8399, 1330, 2, 15, 25);
INSERT INTO public.set_scores VALUES (8400, 1330, 3, 19, 25);
INSERT INTO public.set_scores VALUES (8401, 1330, 4, 19, 25);
INSERT INTO public.set_scores VALUES (8402, 1329, 1, 25, 17);
INSERT INTO public.set_scores VALUES (8403, 1329, 2, 25, 21);
INSERT INTO public.set_scores VALUES (8404, 1329, 3, 25, 19);
INSERT INTO public.set_scores VALUES (8405, 1332, 1, 21, 25);
INSERT INTO public.set_scores VALUES (8406, 1332, 2, 23, 25);
INSERT INTO public.set_scores VALUES (8407, 1332, 3, 25, 20);
INSERT INTO public.set_scores VALUES (8408, 1332, 4, 25, 16);
INSERT INTO public.set_scores VALUES (8409, 1332, 5, 17, 19);
INSERT INTO public.set_scores VALUES (8410, 1331, 1, 25, 23);
INSERT INTO public.set_scores VALUES (8411, 1331, 2, 25, 8);
INSERT INTO public.set_scores VALUES (8412, 1331, 3, 25, 20);
INSERT INTO public.set_scores VALUES (8413, 1335, 1, 25, 21);
INSERT INTO public.set_scores VALUES (8414, 1335, 2, 25, 22);
INSERT INTO public.set_scores VALUES (8415, 1335, 3, 25, 19);
INSERT INTO public.set_scores VALUES (8416, 1334, 1, 25, 23);
INSERT INTO public.set_scores VALUES (8417, 1334, 2, 19, 25);
INSERT INTO public.set_scores VALUES (8418, 1334, 3, 21, 25);
INSERT INTO public.set_scores VALUES (8419, 1334, 4, 25, 21);
INSERT INTO public.set_scores VALUES (8420, 1334, 5, 15, 11);
INSERT INTO public.set_scores VALUES (8421, 1333, 1, 25, 14);
INSERT INTO public.set_scores VALUES (8422, 1333, 2, 25, 19);
INSERT INTO public.set_scores VALUES (8423, 1333, 3, 25, 17);


--
-- Data for Name: team; Type: TABLE DATA; Schema: public; Owner: user
--

INSERT INTO public.team VALUES (1, 'AZS Olsztyn');
INSERT INTO public.team VALUES (2, 'Jastrz─Öbski W─Ögiel');
INSERT INTO public.team VALUES (3, 'LUK  Lublin');
INSERT INTO public.team VALUES (4, 'Warta Zawiercie');
INSERT INTO public.team VALUES (5, 'BBTS Bielsko-Bia┼éa');
INSERT INTO public.team VALUES (6, 'Stal Nysa');
INSERT INTO public.team VALUES (7, 'Trefl Gda┼äsk');
INSERT INTO public.team VALUES (8, 'Asseco Resovia');
INSERT INTO public.team VALUES (9, 'GKS Katowice');
INSERT INTO public.team VALUES (10, 'Barkom Ka┼╝any Lw├│w');
INSERT INTO public.team VALUES (11, '┼Ülepsk Malow Suwa┼éki');
INSERT INTO public.team VALUES (12, 'Cuprum Lubin');
INSERT INTO public.team VALUES (13, 'PGE Skra Be┼échat├│w');
INSERT INTO public.team VALUES (14, 'Czarni Radom');
INSERT INTO public.team VALUES (15, 'ZAKSA K─Ödzierzyn-Ko┼║le');
INSERT INTO public.team VALUES (16, 'Projekt Warszawa');
INSERT INTO public.team VALUES (17, 'MKS B─Ödzin');
INSERT INTO public.team VALUES (18, 'Chemik Bydgoszcz');
INSERT INTO public.team VALUES (19, 'Stocznia Szczecin');
INSERT INTO public.team VALUES (20, 'Spo┼éem Kielce');
INSERT INTO public.team VALUES (21, 'AZS Cz─Östochowa');
INSERT INTO public.team VALUES (22, 'Pamapol Wielton Wielu┼ä');
INSERT INTO public.team VALUES (23, 'Jadar Radom');


--
-- Data for Name: teams_in_season; Type: TABLE DATA; Schema: public; Owner: user
--

INSERT INTO public.teams_in_season VALUES (17, 2, 15);
INSERT INTO public.teams_in_season VALUES (18, 2, 9);
INSERT INTO public.teams_in_season VALUES (19, 2, 2);
INSERT INTO public.teams_in_season VALUES (20, 2, 7);
INSERT INTO public.teams_in_season VALUES (21, 2, 13);
INSERT INTO public.teams_in_season VALUES (22, 2, 1);
INSERT INTO public.teams_in_season VALUES (23, 2, 4);
INSERT INTO public.teams_in_season VALUES (24, 2, 8);
INSERT INTO public.teams_in_season VALUES (25, 2, 12);
INSERT INTO public.teams_in_season VALUES (26, 2, 16);
INSERT INTO public.teams_in_season VALUES (27, 2, 11);
INSERT INTO public.teams_in_season VALUES (28, 2, 3);
INSERT INTO public.teams_in_season VALUES (29, 2, 6);
INSERT INTO public.teams_in_season VALUES (30, 2, 14);
INSERT INTO public.teams_in_season VALUES (31, 3, 15);
INSERT INTO public.teams_in_season VALUES (32, 3, 11);
INSERT INTO public.teams_in_season VALUES (33, 3, 2);
INSERT INTO public.teams_in_season VALUES (34, 3, 4);
INSERT INTO public.teams_in_season VALUES (35, 3, 7);
INSERT INTO public.teams_in_season VALUES (36, 3, 16);
INSERT INTO public.teams_in_season VALUES (37, 3, 13);
INSERT INTO public.teams_in_season VALUES (38, 3, 8);
INSERT INTO public.teams_in_season VALUES (39, 3, 9);
INSERT INTO public.teams_in_season VALUES (40, 3, 1);
INSERT INTO public.teams_in_season VALUES (41, 3, 14);
INSERT INTO public.teams_in_season VALUES (42, 3, 12);
INSERT INTO public.teams_in_season VALUES (43, 3, 6);
INSERT INTO public.teams_in_season VALUES (44, 3, 17);
INSERT INTO public.teams_in_season VALUES (45, 4, 2);
INSERT INTO public.teams_in_season VALUES (46, 4, 13);
INSERT INTO public.teams_in_season VALUES (47, 4, 4);
INSERT INTO public.teams_in_season VALUES (48, 4, 14);
INSERT INTO public.teams_in_season VALUES (49, 4, 15);
INSERT INTO public.teams_in_season VALUES (50, 4, 16);
INSERT INTO public.teams_in_season VALUES (51, 4, 8);
INSERT INTO public.teams_in_season VALUES (52, 4, 9);
INSERT INTO public.teams_in_season VALUES (53, 4, 1);
INSERT INTO public.teams_in_season VALUES (54, 4, 7);
INSERT INTO public.teams_in_season VALUES (55, 4, 18);
INSERT INTO public.teams_in_season VALUES (56, 4, 12);
INSERT INTO public.teams_in_season VALUES (57, 4, 17);
INSERT INTO public.teams_in_season VALUES (58, 5, 2);
INSERT INTO public.teams_in_season VALUES (59, 5, 7);
INSERT INTO public.teams_in_season VALUES (60, 5, 1);
INSERT INTO public.teams_in_season VALUES (61, 5, 8);
INSERT INTO public.teams_in_season VALUES (62, 5, 15);
INSERT INTO public.teams_in_season VALUES (63, 5, 13);
INSERT INTO public.teams_in_season VALUES (64, 5, 12);
INSERT INTO public.teams_in_season VALUES (65, 5, 16);
INSERT INTO public.teams_in_season VALUES (66, 5, 4);
INSERT INTO public.teams_in_season VALUES (67, 5, 14);
INSERT INTO public.teams_in_season VALUES (68, 5, 19);
INSERT INTO public.teams_in_season VALUES (69, 5, 9);
INSERT INTO public.teams_in_season VALUES (70, 5, 18);
INSERT INTO public.teams_in_season VALUES (71, 5, 17);
INSERT INTO public.teams_in_season VALUES (72, 5, 20);
INSERT INTO public.teams_in_season VALUES (73, 5, 5);
INSERT INTO public.teams_in_season VALUES (74, 6, 2);
INSERT INTO public.teams_in_season VALUES (75, 6, 13);
INSERT INTO public.teams_in_season VALUES (76, 6, 15);
INSERT INTO public.teams_in_season VALUES (77, 6, 8);
INSERT INTO public.teams_in_season VALUES (78, 6, 12);
INSERT INTO public.teams_in_season VALUES (79, 6, 1);
INSERT INTO public.teams_in_season VALUES (80, 6, 14);
INSERT INTO public.teams_in_season VALUES (81, 6, 7);
INSERT INTO public.teams_in_season VALUES (82, 6, 16);
INSERT INTO public.teams_in_season VALUES (83, 6, 9);
INSERT INTO public.teams_in_season VALUES (84, 6, 19);
INSERT INTO public.teams_in_season VALUES (85, 6, 17);
INSERT INTO public.teams_in_season VALUES (86, 6, 5);
INSERT INTO public.teams_in_season VALUES (87, 6, 20);
INSERT INTO public.teams_in_season VALUES (88, 6, 21);
INSERT INTO public.teams_in_season VALUES (89, 6, 18);


--
-- Name: match_details_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user
--

SELECT pg_catalog.setval('public.match_details_id_seq', 2639, true);


--
-- Name: matches_extended_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user
--

SELECT pg_catalog.setval('public.matches_extended_id_seq', 2219, true);


--
-- Name: matches_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user
--

SELECT pg_catalog.setval('public.matches_id_seq', 2639, true);


--
-- Name: points_in_season_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user
--

SELECT pg_catalog.setval('public.points_in_season_id_seq', 1, false);


--
-- Name: season_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user
--

SELECT pg_catalog.setval('public.season_id_seq', 14, true);


--
-- Name: set_scores_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user
--

SELECT pg_catalog.setval('public.set_scores_id_seq', 8423, true);


--
-- Name: team_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user
--

SELECT pg_catalog.setval('public.team_id_seq', 23, true);


--
-- Name: teams_in_season_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user
--

SELECT pg_catalog.setval('public.teams_in_season_id_seq', 179, true);


--
-- Name: match_details match_details_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.match_details
    ADD CONSTRAINT match_details_pkey PRIMARY KEY (id);


--
-- Name: matches_extended matches_extended_match_id_key; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.matches_extended
    ADD CONSTRAINT matches_extended_match_id_key UNIQUE (match_id);


--
-- Name: matches_extended matches_extended_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.matches_extended
    ADD CONSTRAINT matches_extended_pkey PRIMARY KEY (id);


--
-- Name: matches matches_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.matches
    ADD CONSTRAINT matches_pkey PRIMARY KEY (id);


--
-- Name: points_in_season points_in_season_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.points_in_season
    ADD CONSTRAINT points_in_season_pkey PRIMARY KEY (id);


--
-- Name: season season_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.season
    ADD CONSTRAINT season_pkey PRIMARY KEY (id);


--
-- Name: season season_season_key; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.season
    ADD CONSTRAINT season_season_key UNIQUE (season);


--
-- Name: set_scores set_scores_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.set_scores
    ADD CONSTRAINT set_scores_pkey PRIMARY KEY (id);


--
-- Name: team team_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.team
    ADD CONSTRAINT team_pkey PRIMARY KEY (id);


--
-- Name: team team_teamname_key; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.team
    ADD CONSTRAINT team_teamname_key UNIQUE (teamname);


--
-- Name: teams_in_season teams_in_season_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.teams_in_season
    ADD CONSTRAINT teams_in_season_pkey PRIMARY KEY (id);


--
-- Name: match_details match_details_match_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.match_details
    ADD CONSTRAINT match_details_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE CASCADE;


--
-- Name: matches_extended matches_extended_match_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.matches_extended
    ADD CONSTRAINT matches_extended_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE CASCADE;


--
-- Name: matches matches_season_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.matches
    ADD CONSTRAINT matches_season_fkey FOREIGN KEY (season) REFERENCES public.season(id) ON DELETE CASCADE;


--
-- Name: matches matches_team_1_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.matches
    ADD CONSTRAINT matches_team_1_fkey FOREIGN KEY (team_1) REFERENCES public.team(id) ON DELETE CASCADE;


--
-- Name: matches matches_team_2_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.matches
    ADD CONSTRAINT matches_team_2_fkey FOREIGN KEY (team_2) REFERENCES public.team(id) ON DELETE CASCADE;


--
-- Name: points_in_season points_in_season_team_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.points_in_season
    ADD CONSTRAINT points_in_season_team_fkey FOREIGN KEY (team) REFERENCES public.teams_in_season(id) ON DELETE CASCADE;


--
-- Name: set_scores set_scores_match_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.set_scores
    ADD CONSTRAINT set_scores_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE CASCADE;


--
-- Name: teams_in_season teams_in_season_season_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.teams_in_season
    ADD CONSTRAINT teams_in_season_season_fkey FOREIGN KEY (season) REFERENCES public.season(id) ON DELETE CASCADE;


--
-- Name: teams_in_season teams_in_season_team_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.teams_in_season
    ADD CONSTRAINT teams_in_season_team_fkey FOREIGN KEY (team) REFERENCES public.team(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

