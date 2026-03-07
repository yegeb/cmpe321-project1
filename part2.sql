CREATE DATABASE IF NOT EXISTS TransferDB;
USE TransferDB;

SET FOREIGN_KEY_CHECKS = 0;
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

CREATE TABLE Club_Home_Stadium(
    club_ID INT PRIMARY KEY,
    stadium_ID INT NOT NULL,
    FOREIGN KEY (club_ID) REFERENCES Club(club_ID)
    -- FK to be added when Stadium table exists:
    -- ,FOREIGN KEY (stadium_ID) REFERENCES Stadium(stadium_ID)
);

CREATE TABLE Club_Competition_Participation(
    club_ID INT NOT NULL,
    competition_ID INT NOT NULL,
    PRIMARY KEY (club_ID, competition_ID),
    FOREIGN KEY (club_ID) REFERENCES Club(club_ID)
    -- FK to be added when Competition table exists:
    -- ,FOREIGN KEY (competition_ID) REFERENCES Competition(competition_ID)
);

-- Constraints below cannot be fully enforced with only PK/FK/UNIQUE/NOT NULL/CHECK:
-- 1) Person specialization total+disjoint (exactly one of Player/Manager/Referee)
-- 2) Manager/Club temporal exclusivity in Leads (no overlapping date intervals)
-- 3) No overlapping same-type active contracts for a player
-- 4) Loan contract requiring overlapping permanent parent contract at different club
-- 5) TransferRecord loan rule requiring active parent permanent contract at transfer date

-- External-table relations (do not run until those tables exist):
-- 1) Match.referee_ID -> Referee(person_ID)
--    ALTER TABLE Match
--      ADD CONSTRAINT fk_match_referee
--      FOREIGN KEY (referee_ID) REFERENCES Referee(person_ID);
--
-- 2) Match.home_club_ID / Match.away_club_ID -> Club(club_ID)
--    ALTER TABLE Match
--      ADD CONSTRAINT fk_match_home_club FOREIGN KEY (home_club_ID) REFERENCES Club(club_ID),
--      ADD CONSTRAINT fk_match_away_club FOREIGN KEY (away_club_ID) REFERENCES Club(club_ID);
--
-- 3) Match_Participation.player_id -> Player(person_ID)
--    ALTER TABLE Match_Participation
--      ADD CONSTRAINT fk_match_participation_player
--      FOREIGN KEY (player_id) REFERENCES Player(person_ID);
--
-- 4) Club_Home_Stadium.stadium_ID -> Stadium(stadium_ID)
--    ALTER TABLE Club_Home_Stadium
--      ADD CONSTRAINT fk_club_home_stadium_stadium
--      FOREIGN KEY (stadium_ID) REFERENCES Stadium(stadium_ID);
--
-- 5) Club_Competition_Participation.competition_ID -> Competition(competition_ID)
--    ALTER TABLE Club_Competition_Participation
--      ADD CONSTRAINT fk_club_competition_competition
--      FOREIGN KEY (competition_ID) REFERENCES Competition(competition_ID);
