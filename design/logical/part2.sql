-- ============================================================
-- TransferDB - Logical Database Design (SQL DDL)
-- CMPE 321, Introduction to Database Systems, Spring 2026
-- ============================================================
-- MySQL Server Syntax
-- ============================================================
CREATE DATABASE IF NOT EXISTS TransferDB;
USE TransferDB;
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS Match_Participation;
DROP TABLE IF EXISTS Match;
DROP TABLE IF EXISTS Club_Competition_Participation;
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
-- ============================================================
-- 1. Person
-- ============================================================
-- NOTE: Disjoint, Total ISA: each Person must be exactly one of
-- Player, Manager, or Referee. The application must enforce this.
CREATE TABLE Person(
    person_ID INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    surname VARCHAR(100) NOT NULL,
    nationality VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    CHECK (CHAR_LENGTH(TRIM(name)) > 0),
    CHECK (CHAR_LENGTH(TRIM(surname)) > 0),
    CHECK (CHAR_LENGTH(TRIM(nationality)) > 0)
);
-- ============================================================
-- 2. Player (ISA Person)
-- ============================================================
CREATE TABLE Player(
    person_ID INT PRIMARY KEY,
    market_value DECIMAL(15, 2) NOT NULL,
    main_position ENUM(
        'Goalkeeper',
        'Defender',
        'Midfielder',
        'Forward'
    ) NOT NULL,
    strong_foot ENUM('Right', 'Left', 'Both') NOT NULL,
    height_cm INT NOT NULL,
    FOREIGN KEY (person_ID) REFERENCES Person(person_ID),
    CHECK (market_value > 0),
    CHECK (height_cm > 0)
);
-- ============================================================
-- 3. Manager (ISA Person)
-- ============================================================
CREATE TABLE Manager(
    person_ID INT PRIMARY KEY,
    preferred_formation VARCHAR(20) NOT NULL,
    experience_level VARCHAR(50) NOT NULL,
    FOREIGN KEY (person_ID) REFERENCES Person(person_ID),
    CHECK (CHAR_LENGTH(TRIM(preferred_formation)) > 0),
    CHECK (CHAR_LENGTH(TRIM(experience_level)) > 0)
);
-- ============================================================
-- 4. Referee (ISA Person)
-- ============================================================
CREATE TABLE Referee(
    person_ID INT PRIMARY KEY,
    license_level VARCHAR(50) NOT NULL,
    years_experience INT NOT NULL,
    FOREIGN KEY (person_ID) REFERENCES Person(person_ID),
    CHECK (years_experience >= 0),
    CHECK (CHAR_LENGTH(TRIM(license_level)) > 0)
);
-- ============================================================
-- 5. Stadium
-- ============================================================
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
-- ============================================================
-- 6. Club
-- ============================================================
CREATE TABLE Club(
    club_ID INT PRIMARY KEY,
    club_name VARCHAR(150) NOT NULL UNIQUE,
    stadium_ID INT NOT NULL,
    city VARCHAR(100) NOT NULL,
    foundation_year INT NOT NULL,
    FOREIGN KEY (stadium_ID) REFERENCES Stadium(stadium_ID),
    CHECK (CHAR_LENGTH(TRIM(club_name)) > 0),
    CHECK (CHAR_LENGTH(TRIM(city)) > 0)
);
-- ============================================================
-- 7. Leads (Manager <-> Club)
-- ============================================================
-- NOTE: Manager/Club temporal exclusivity (no overlapping date
-- intervals) cannot be fully enforced via CHECK constraints.
CREATE TABLE Leads(
    club_ID INT NOT NULL,
    manager_ID INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NULL,
    PRIMARY KEY (club_ID, manager_ID, start_date),
    FOREIGN KEY (club_ID) REFERENCES Club(club_ID),
    FOREIGN KEY (manager_ID) REFERENCES Manager(person_ID),
    CHECK (
        end_date IS NULL
        OR end_date > start_date
    )
);
-- ============================================================
-- 8. Contract (Permanent & Loan)
-- ============================================================
-- NOTE: A player must not have two active contracts of the same 
-- type concurrently. A Loan contract is only valid if the player 
-- holds an active Permanent contract with a different parent club.
-- These cross-table/temporal constraints aren't checkable here.
CREATE TABLE Contract(
    contract_id INT PRIMARY KEY,
    player_id INT NOT NULL,
    club_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    weekly_wage DECIMAL(15, 2) NOT NULL,
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
-- ============================================================
-- 9. Transfer Record
-- ============================================================
-- NOTE: For a Loan transfer, from_club_id must match the player's
-- current parent club and they must have an active permanent contract.
CREATE TABLE TransferRecord(
    transfer_id INT PRIMARY KEY,
    player_id INT NOT NULL,
    from_club_id INT NOT NULL,
    to_club_id INT NOT NULL,
    transfer_date DATE NOT NULL,
    transfer_fee DECIMAL(15, 2) NOT NULL,
    transfer_type ENUM('Free', 'Purchase', 'Loan') NOT NULL,
    FOREIGN KEY (player_id) REFERENCES Player(person_ID),
    FOREIGN KEY (from_club_id) REFERENCES Club(club_ID),
    FOREIGN KEY (to_club_id) REFERENCES Club(club_ID),
    CHECK (from_club_id <> to_club_id),
    CHECK (transfer_fee >= 0),
    CHECK (
        (
            transfer_type = 'Free'
            AND transfer_fee = 0
        )
        OR (
            transfer_type IN ('Purchase', 'Loan')
            AND transfer_fee > 0
        )
    )
);
-- ============================================================
-- 10. Competition
-- ============================================================
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
-- ============================================================
-- 11. Club_Competition_Participation
-- ============================================================
CREATE TABLE Club_Competition_Participation(
    club_ID INT NOT NULL,
    competition_ID INT NOT NULL,
    PRIMARY KEY (club_ID, competition_ID),
    FOREIGN KEY (club_ID) REFERENCES Club(club_ID),
    FOREIGN KEY (competition_ID) REFERENCES Competition(competition_ID)
);
-- ============================================================
-- 12. Match
-- ============================================================
-- NOTE: Scheduling capabilities (no two matches at same stadium within
-- 120 mins, no club playing twice within 120 mins) can't be CHECKed.
-- NOTE: Match attendance cannot exceed Stadium capacity.
-- NOTE: Match result is derived from goals, not stored.
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
-- ============================================================
-- 13. Match Participation & Stats
-- ============================================================
-- NOTE: Max 11 starters and 23 total squad players limit per club
-- per match cannot be enforced here.
-- NOTE: Red/Yellow card suspensions must be handled via application logic.
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
    rating DECIMAL(4, 2) NULL,
    PRIMARY KEY (match_ID, player_id),
    FOREIGN KEY (match_ID) REFERENCES Match(match_ID),
    FOREIGN KEY (player_id) REFERENCES Player(person_ID),
    CHECK (
        minutes_played >= 0
        AND minutes_played <= 120
    ),
    CHECK (goals >= 0),
    CHECK (assists >= 0),
    CHECK (
        yellow_cards >= 0
        AND yellow_cards <= 2
    ),
    CHECK (
        red_cards >= 0
        AND red_cards <= 1
    ),
    CHECK (
        rating IS NULL
        OR (
            rating >= 1.0
            AND rating <= 10.0
        )
    )
);
-- ============================================================
-- Constraints we couldn't express in DDL (CHECK/FK/UNIQUE):
-- ============================================================
-- 1) Person specialization total+disjoint (exactly one of Player/Manager/Referee) requires application logic.
-- 2) Manager/Club temporal exclusivity in Leads (no overlapping date intervals).
-- 3) No overlapping same-type active contracts for a player concurrently.
-- 4) Match.attendance must not exceed the capacity of the stadium where the match was played.
-- 5) No two matches can be scheduled at the same stadium within 120 minutes of each other.
-- 6) No club (home or away) can appear in two matches whose start times are within 120 minutes of each other.
-- 7) No referee can officiate two matches whose start times are within 120 minutes of each other.
-- 8) At most 11 players with is_starter=TRUE per club per match in Match_Participation.
-- 9) At most 23 players total per club per match in Match_Participation.
-- 10) A player cannot appear in the same match as both a home-team and away-team participant.
-- 11) Person.date_of_birth must be strictly less than the current date (requires triggers in MySQL).
-- 12) Club.foundation_year must be strictly less than the current year (requires triggers in MySQL).
-- 13) Two yellow cards in one match should automatically set red_cards to true.
-- 14) Suspension rules (Red card = 1 match suspension, 5 yellows = 1 match suspension) require historical querying.
-- 15) Match Result (Win/Loss/Draw) is dynamically derived from home/away goals, rather than stored.