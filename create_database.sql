CREATE DATABASE IF NOT EXISTS volleyball_app;

GRANT ALL PRIVILEGES ON `volleyball_app`.* TO 'user'@'%';
FLUSH PRIVILEGES;

USE volleyball_app;

CREATE TABLE IF NOT EXISTS Team (
  id INT PRIMARY KEY AUTO_INCREMENT,
  TeamName VARCHAR(255) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS Season (
    id INT PRIMARY KEY AUTO_INCREMENT,
    season VARCHAR(10) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS Teams_in_season (
	id INT NOT NULL AUTO_INCREMENT,
	season INT,
    team INT,
    PRIMARY KEY (id),
    FOREIGN KEY (season) REFERENCES Season(id),
    FOREIGN KEY (team) REFERENCES Team(id)
);

CREATE TABLE IF NOT EXISTS Points_in_season (
	id int NOT NULL AUTO_INCREMENT,
    team INT,
    points INT,
    PRIMARY KEY (id),
    FOREIGN KEY (team) REFERENCES Teams_in_season(id)
);

CREATE TABLE IF NOT EXISTS Matches (
	id INT,
    date TIMESTAMP,
    season INT,
    team_1 INT,
    team_2 INT,
    T1_score INT,
    T2_score INT,
    T1_points INT DEFAULT NULL,
    T2_points INT DEFAULT NULL,
    winner INT,
    PRIMARY KEY (id),
    FOREIGN KEY (season) REFERENCES Season(id),
	FOREIGN KEY (team_1) REFERENCES Team(id),
	FOREIGN KEY (team_2) REFERENCES Team(id)
);

CREATE TABLE IF NOT EXISTS Match_details (
	id INT,
    match_id INT,
    T1_sum INT,
    T2_sum INT,
    PRIMARY KEY (id),
    FOREIGN KEY (match_id) REFERENCES Matches(id)
);

ALTER TABLE Matches MODIFY date DATETIME;
ALTER TABLE Match_details DROP FOREIGN KEY Match_details_ibfk_1;
ALTER TABLE Matches MODIFY COLUMN id INT AUTO_INCREMENT;
ALTER TABLE Match_details ADD CONSTRAINT Match_details_ibfk_1 FOREIGN KEY (id) REFERENCES Matches(id);