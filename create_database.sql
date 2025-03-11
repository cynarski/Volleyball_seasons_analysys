GRANT ALL PRIVILEGES ON DATABASE volleyball_app TO "user";

CREATE TABLE IF NOT EXISTS Team (
  id SERIAL PRIMARY KEY,
  TeamName VARCHAR(255) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS Season (
  id SERIAL PRIMARY KEY,
  season VARCHAR(10) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS Teams_in_season (
  id SERIAL PRIMARY KEY,
  season INT,
  team INT,
  FOREIGN KEY (season) REFERENCES Season(id) ON DELETE CASCADE,
  FOREIGN KEY (team) REFERENCES Team(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Points_in_season (
  id SERIAL PRIMARY KEY,
  team INT,
  points INT,
  FOREIGN KEY (team) REFERENCES Teams_in_season(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Matches (
  id SERIAL PRIMARY KEY,
  date TIMESTAMP,
  season INT,
  team_1 INT,
  team_2 INT,
  T1_score INT,
  T2_score INT,
  T1_points INT DEFAULT NULL,
  T2_points INT DEFAULT NULL,
  winner INT,
  FOREIGN KEY (season) REFERENCES Season(id) ON DELETE CASCADE,
  FOREIGN KEY (team_1) REFERENCES Team(id) ON DELETE CASCADE,
  FOREIGN KEY (team_2) REFERENCES Team(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Match_details (
  id SERIAL PRIMARY KEY,
  match_id INT NOT NULL,
  T1_sum FLOAT,
  T1_BP FLOAT,
  T1_Ratio FLOAT,
  T1_Srv_Sum FLOAT,
  T1_Srv_Err FLOAT,
  T1_Srv_Ace FLOAT,
  T1_Srv_Eff FLOAT,
  T1_Rec_Sum FLOAT,
  T1_Rec_Err FLOAT,
  T1_Rec_Pos FLOAT,
  T1_Rec_Perf FLOAT,
  T1_Att_Sum FLOAT,
  T1_Att_Err FLOAT,
  T1_Att_Blk FLOAT,
  T1_Att_Kill FLOAT,
  T1_Att_Kill_Perc FLOAT,
  T1_Att_Eff FLOAT,
  T1_Blk_Sum FLOAT,
  T1_Blk_As FLOAT,
  T2_Sum FLOAT,
  T2_BP FLOAT,
  T2_Ratio FLOAT,
  T2_Srv_Sum FLOAT,
  T2_Srv_Err FLOAT,
  T2_Srv_Ace FLOAT,
  T2_Srv_Eff FLOAT,
  T2_Rec_Sum FLOAT,
  T2_Rec_Err FLOAT,
  T2_Rec_Pos FLOAT,
  T2_Rec_Perf FLOAT,
  T2_Att_Sum FLOAT,
  T2_Att_Err FLOAT,
  T2_Att_Blk FLOAT,
  T2_Att_Kill FLOAT,
  T2_Att_Kill_Perc FLOAT,
  T2_Att_Eff FLOAT,
  T2_Blk_Sum FLOAT,
  T2_Blk_As FLOAT,
  FOREIGN KEY (match_id) REFERENCES Matches(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Matches_extended (
  id SERIAL PRIMARY KEY,
  match_id INT UNIQUE NOT NULL,
  audience INT,
  mvp VARCHAR(255),
  FOREIGN KEY (match_id) REFERENCES Matches(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Set_scores (
  id SERIAL PRIMARY KEY,
  match_id INT NOT NULL,
  set_number INT NOT NULL,
  host_score INT NOT NULL,
  guest_score INT NOT NULL,
  FOREIGN KEY (match_id) REFERENCES Matches(id) ON DELETE CASCADE
);


ALTER TABLE matches ADD COLUMN match_type VARCHAR(10);