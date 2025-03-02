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
  match_id INT,
  T1_sum INT,
  T2_sum INT,
  FOREIGN KEY (match_id) REFERENCES Matches(id) ON DELETE CASCADE
);

