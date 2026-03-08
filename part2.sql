CREATE DATABASE IF NOT EXISTS TransferDB;
USE TransferDB;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS Match_Participation;
DROP TABLE IF EXISTS Match;
DROP TABLE IF EXISTS Club_Competition_Participation;
DROP TABLE IF EXISTS Club_Home_Stadium;
DROP TABLE IF EXISTS TransferRecord;
DROP TABLE IF EXISTS LoanContract;
DROP TABLE IF EXISTS PermanentContract;
DROP TABLE IF EXISTS Contract;
DROP TABLE IF EXISTS Leads;
DROP TABLE IF EXISTS Referee;
DROP TABLE IF EXISTS Manager;
DROP TABLE IF EXISTS Player;
DROP TABLE IF EXISTS Club;
DROP TABLE IF EXISTS Stadium;
DROP TABLE IF EXISTS Competition;
DROP TABLE IF EXISTS Person;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE Person(
    person_ID INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    surname VARCHAR(100) NOT NULL,
    nationality VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    CHECK (CHAR_LENGTH(TRIM(name)) > 0),
    CHECK (CHAR_LENGTH(TRIM(surname)) > 0),
    CHECK (CHAR_LENGTH(TRIM(nationality)) > 0),
    CHECK (date_of_birth < CURRENT_DATE)
);

CREATE TABLE Player(
    person_ID INT PRIMARY KEY,
    market_value DECIMAL(15,2) NOT NULL,
    main_position ENUM('Goalkeeper', 'Defender', 'Midfielder', 'Forward') NOT NULL,
    strong_foot ENUM('Right', 'Left', 'Both') NOT NULL,
    height_cm INT NOT NULL,
    FOREIGN KEY (person_ID) REFERENCES Person(person_ID),
    CHECK (market_value > 0),
    CHECK (height_cm > 0)
);

CREATE TABLE Manager(
    person_ID INT PRIMARY KEY,
    preferred_formation VARCHAR(20) NOT NULL,
    experience_level ENUM('Beginner', 'Intermediate', 'Elite') NOT NULL,
    FOREIGN KEY (person_ID) REFERENCES Person(person_ID),
    CHECK (CHAR_LENGTH(TRIM(preferred_formation)) > 0)
);

CREATE TABLE Referee(
    person_ID INT PRIMARY KEY,
    license_level ENUM('FIFA', 'Continental', 'National') NOT NULL,
    years_experience INT NOT NULL,
    FOREIGN KEY (person_ID) REFERENCES Person(person_ID),
    CHECK (years_experience >= 0)
);

CREATE TABLE Club(
    club_ID INT PRIMARY KEY,
    club_name VARCHAR(150) NOT NULL UNIQUE,
    city VARCHAR(100) NOT NULL,
    foundation_year INT NOT NULL,
    CHECK (CHAR_LENGTH(TRIM(club_name)) > 0),
    CHECK (CHAR_LENGTH(TRIM(city)) > 0),
    CHECK (foundation_year < YEAR(CURDATE()))
);

CREATE TABLE Leads(
    club_ID INT NOT NULL,
    manager_ID INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NULL,
    PRIMARY KEY (club_ID, manager_ID, start_date),
    FOREIGN KEY (club_ID) REFERENCES Club(club_ID),
    FOREIGN KEY (manager_ID) REFERENCES Manager(person_ID),
    CHECK (end_date IS NULL OR end_date > start_date)
);

CREATE TABLE Contract(
    contract_id INT PRIMARY KEY,
    player_id INT NOT NULL,
    club_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    weekly_wage DECIMAL(15,2) NOT NULL,
    contract_type ENUM('Permanent', 'Loan') NOT NULL,
    FOREIGN KEY (player_id) REFERENCES Player(person_ID),
    FOREIGN KEY (club_id) REFERENCES Club(club_ID),
    CHECK (end_date > start_date),
    CHECK (weekly_wage > 0)
);

CREATE TABLE PermanentContract(
    contract_id INT PRIMARY KEY,
    FOREIGN KEY (contract_id) REFERENCES Contract(contract_id) ON DELETE CASCADE
);

CREATE TABLE LoanContract(
    contract_id INT PRIMARY KEY,
    parent_permanent_contract_id INT NOT NULL,
    FOREIGN KEY (contract_id) REFERENCES Contract(contract_id) ON DELETE CASCADE,
    FOREIGN KEY (parent_permanent_contract_id) REFERENCES PermanentContract(contract_id),
    CHECK (contract_id <> parent_permanent_contract_id)
);

CREATE TABLE TransferRecord(
    transfer_id INT PRIMARY KEY,
    player_id INT NOT NULL,
    from_club_id INT NOT NULL,
    to_club_id INT NOT NULL,
    transfer_date DATE NOT NULL,
    transfer_fee DECIMAL(15,2) NOT NULL,
    transfer_type ENUM('Free', 'Purchase', 'Loan') NOT NULL,
    FOREIGN KEY (player_id) REFERENCES Player(person_ID),
    FOREIGN KEY (from_club_id) REFERENCES Club(club_ID),
    FOREIGN KEY (to_club_id) REFERENCES Club(club_ID),
    CHECK (from_club_id <> to_club_id),
    CHECK (transfer_fee >= 0),
    CHECK (
        (transfer_type = 'Free' AND transfer_fee = 0) OR
        (transfer_type IN ('Purchase', 'Loan') AND transfer_fee > 0)
    )
);

CREATE TABLE Stadium(
    stadium_ID INT PRIMARY KEY,
    stadium_name VARCHAR(150) NOT NULL,
    city VARCHAR(100) NOT NULL,
    capacity INT NOT NULL,
    UNIQUE (stadium_name, city),
    CHECK (CHAR_LENGTH(TRIM(stadium_name)) > 0),
    CHECK (CHAR_LENGTH(TRIM(city)) > 0),
    CHECK (capacity > 0)
);

CREATE TABLE Competition(
    competition_ID INT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    season VARCHAR(20) NOT NULL,
    country VARCHAR(100) NOT NULL,
    competition_type VARCHAR(50) NOT NULL,
    UNIQUE (name, season),
    CHECK (CHAR_LENGTH(TRIM(name)) > 0),
    CHECK (CHAR_LENGTH(TRIM(country)) > 0)
);

CREATE TABLE Club_Home_Stadium(
    club_ID INT PRIMARY KEY,
    stadium_ID INT NOT NULL,
    FOREIGN KEY (club_ID) REFERENCES Club(club_ID),
    FOREIGN KEY (stadium_ID) REFERENCES Stadium(stadium_ID)
);

CREATE TABLE Club_Competition_Participation(
    club_ID INT NOT NULL,
    competition_ID INT NOT NULL,
    PRIMARY KEY (club_ID, competition_ID),
    FOREIGN KEY (club_ID) REFERENCES Club(club_ID),
    FOREIGN KEY (competition_ID) REFERENCES Competition(competition_ID)
);

CREATE TABLE Match(
    match_ID INT PRIMARY KEY,
    match_datetime DATETIME NOT NULL,
    attendance INT NOT NULL,
    home_goals INT NOT NULL,
    away_goals INT NOT NULL,
    home_club_ID INT NOT NULL,
    away_club_ID INT NOT NULL,
    referee_ID INT NOT NULL,
    stadium_ID INT NOT NULL,
    competition_ID INT NOT NULL,
    FOREIGN KEY (home_club_ID) REFERENCES Club(club_ID),
    FOREIGN KEY (away_club_ID) REFERENCES Club(club_ID),
    FOREIGN KEY (referee_ID) REFERENCES Referee(person_ID),
    FOREIGN KEY (stadium_ID) REFERENCES Stadium(stadium_ID),
    FOREIGN KEY (competition_ID) REFERENCES Competition(competition_ID),
    CHECK (home_club_ID <> away_club_ID),
    CHECK (attendance >= 0),
    CHECK (home_goals >= 0),
    CHECK (away_goals >= 0)
);

CREATE TABLE Match_Participation(
    match_ID INT NOT NULL,
    player_id INT NOT NULL,
    is_starter BOOLEAN NOT NULL,
    minutes_played INT NOT NULL,
    position_in_match VARCHAR(30) NOT NULL,
    goals INT NOT NULL DEFAULT 0,
    assists INT NOT NULL DEFAULT 0,
    yellow_cards INT NOT NULL DEFAULT 0,
    red_cards INT NOT NULL DEFAULT 0,
    rating DECIMAL(4,2) NULL,
    PRIMARY KEY (match_ID, player_id),
    FOREIGN KEY (match_ID) REFERENCES Match(match_ID),
    FOREIGN KEY (player_id) REFERENCES Player(person_ID),
    CHECK (minutes_played >= 0 AND minutes_played <= 120),
    CHECK (goals >= 0),
    CHECK (assists >= 0),
    CHECK (yellow_cards >= 0 AND yellow_cards <= 2),
    CHECK (red_cards >= 0 AND red_cards <= 1),
    CHECK (rating IS NULL OR (rating >= 1.0 AND rating <= 10.0))
);

-- Constraints below cannot be fully enforced with only PK/FK/UNIQUE/NOT NULL/CHECK:
-- 1) Person specialization total+disjoint (exactly one of Player/Manager/Referee)
-- 2) Manager/Club temporal exclusivity in Leads (no overlapping date intervals)
-- 3) No overlapping same-type active contracts for a player
-- 4) Loan contract requiring overlapping permanent parent contract at different club
-- 5) TransferRecord loan rule requiring active parent permanent contract at transfer date
-- 6) Match.attendance must not exceed the capacity of the stadium where the match was played
-- 7) No two matches can be scheduled at the same stadium within 120 minutes of each other
-- 8) No club (home or away) can appear in two matches whose start times are within 120 minutes of each other
-- 9) No referee can officiate two matches whose start times are within 120 minutes of each other
-- 10) At most 11 players with is_starter=TRUE per club per match in Match_Participation
-- 11) At most 23 players total per club per match in Match_Participation
-- 12) A player cannot appear in the same match as both a home-team and away-team participant
