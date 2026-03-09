# Project 1: TransferDB
**CMPE 321, Introduction to Database Systems, Spring 2026**
**Deadline: 9 March 2026, 17:00**

## 1. Introduction
Football is more than just a game; it is a global industry, a clash of tactics, and a continuous cycle of talent development and acquisition. From the muddy pitches of Sunday leagues to the electrifying atmosphere of the Champions League final, football generates an immense amount of data.

In the modern era, the market value of a player is as significant as their performance on the pitch. Managing the complex web of player transfers, loan agreements, match statistics, and squad registrations requires a robust and precise system. As the transfer window opens and matches kick off, clubs, agents, and fans alike rely on accurate data to make decisions.

As a database architect, your task is to design TransferDB, a comprehensive database inspired by platforms like Transfermarkt. Your database will handle key components such as player valuations, complex contract types (loans vs. permanent), match events, and historical transfer records.

Are you ready to build the backend for the world’s football market? Let’s kick off.

## 2. Project Description
This project involves designing a database to manage a football ecosystem. The system will store and organize data on players, managers, clubs, matches, and the transfer market, ensuring data integrity across competitions.

You will begin with a detailed description of the content. Then you will need to systematically go through parts of the standard database design process as you learned about in class, including conceptual and logical design.

Our database should contain the following information:

### 1. Person
The system tracks various individuals. A Person has the following attributes: person ID, name, surname, nationality, and date of birth. Each person has a unique person ID.
- Each person must have only one primary nationality (dual citizenship is not tracked).
- A Person is either a Player, a Manager, or a Referee. These are mutually exclusive roles; a person cannot hold more than one role simultaneously.

**(a) Players** additionally have attributes of market value (in Euros, must be greater than 0), main position (Goalkeeper, Defender, Midfielder or Forward), strong foot (Right, Left or Both), and height (in centimeters, must be a positive integer).
- A player’s relationship with clubs is defined by their active contract(s).
- **Loan Constraint:** A player may be employed by a parent club under a permanent contract and simultaneously assigned to a loan club under a loan contract. Therefore, a player may be associated with at most two clubs at the same time. A player cannot be on loan without first having a parent club.
- A player who currently has no active contract is considered a free agent and is not associated with any club.

**(b) Managers** additionally have preferred formation (e.g., 4-3-3, 4-4-2) and experience level (e.g., Beginner, Intermediate, Elite).
- A manager can only manage one club at a time.
- A club must be led by exactly one manager at any given time.

**(c) Referees** additionally have license level (e.g., FIFA, Continental, National) and years of experience (a non-negative integer).
- A referee officiates matches and is responsible for reporting the result.
- A referee may not be assigned to two matches whose start times are within 120 minutes of each other.
- A match must be assigned exactly one referee.

### 2. Club
Club includes the following attributes: club ID (unique), club name (unique), stadium name, city, foundation year.
- Each club maintains a squad: the set of players currently under contract.
- Each club is led by exactly one Manager at any point in time.
- A club maintains a full history of its Transfers (both incoming and outgoing). Each transfer record is permanently stored even after a player leaves.
- **Stadium Habitancy:** Each stadium is identified by its name and city. Two clubs can co-habit a stadium i.e. have the same city, stadium name.

### 3. Stadium
A Stadium is a physical venue where matches are played. A Stadium has the following attributes: stadium ID (unique), stadium name, city, and capacity (a positive integer representing the maximum number of spectators).
- **Uniqueness Constraint:** The combination of stadium name and city must be unique. Two stadiums in different cities may share the same name, but no two stadiums within the same city may share the same name.
- A Club is associated with a home stadium, referred to as its primary venue. Multiple clubs may share the same stadium (e.g., clubs co-habiting a ground).
- A Match is played at exactly one stadium. The stadium used for a match does not need to be the home club’s primary venue.
- **Scheduling Constraint:** No two matches may be scheduled at the same stadium if their start times are within 120 minutes of each other.
- **Attendance Constraint:** The attendance recorded for a match must be a non-negative integer and must not exceed the capacity of the stadium in which the match is played.

### 4. Contract
A Contract is the formal agreement that binds a Player to a Club for a defined period of time. Over the course of a career, a player will sign many contracts with different clubs, and the database must preserve this full history. Each contract record is permanent and must never be deleted, even after it expires. Each contract has the following attributes: contract id (unique), player id, club id, start date, end date, weekly wage (in Euros, must be greater than 0), and contract type (Permanent or Loan).
- The end date of a contract must be strictly later than its start date.
- A player may sign any number of contracts over their career. However, at any given point in time, a player must not have two active contracts of the same type running concurrently. An active contract is one whose start date is in the past and whose end date is in the future. There is no restriction on the total number of contracts a player holds across their career.
- A Loan contract is only valid if the player holds an active Permanent contract with a different club at the same time. That club is referred to as the player’s parent club. A player cannot be on loan without a parent club.

### 5. Transfer Record
The system must permanently store the history of all player movements between clubs. A Transfer Record has the following attributes: transfer id (unique), player id, from club id, to club id, transfer date, transfer fee (in Euros, must be greater than or equal to 0), and transfer type (Free, Purchase, or Loan).
- The from club id and to club id must refer to different clubs.
- For a Loan transfer, the from club id must match the player’s current parent club. A Loan transfer cannot occur if the player has no existing permanent contract.
- For a Free transfer, the transfer fee must be 0. For Purchase and Loan transfers, the fee may be any positive value.

### 6. Competition
A Competition has the following attributes: competition ID (unique), name (e.g., Premier League, Bundesliga, Serie A, UEFA Champions League, Copa Del Rey), season (e.g., 2024/2025), and country (the country whose football association organises the competition, e.g., Türkiye, England, Germany, Italy) and competition type (e.g., League, Cup, International).
- Every competition must be associated with exactly one country. Competitions without a governing national association (e.g., UEFA club competitions) has “International” as the country.
- Matches belong to a specific competition and season.
- A club may participate in multiple competitions in the same season.
- The combination of competition name and season must be unique, the same competition cannot run twice in the same season.

### 7. Match
A Match has the following attributes: match ID, competition ID, home club ID, away club ID, stadium ID, match datetime, attendance (non-negative integer), home goals (non-negative integer), away goals (non-negative integer), and referee ID.
- match ID must be unique.
- A match is played between exactly two distinct clubs: one designated as Home and one as Away.
- **Score Handling:** The score is stored as two atomic integers: home goals and away goals.
- **Result:** The outcome of the match (Home Win, Away Win, Draw) is derived from the score by comparing home goals and away goals and does not need to be stored as a separate attribute.
- **Scheduling Constraint:** A match has a fixed duration of 120 minutes. No two matches may be played in the same stadium if their start times are within 120 minutes of each other. A club may not appear in two matches (as either the home or away side) whose start times are within 120 minutes of each other. A referee may not be assigned to two matches whose start times are within 120 minutes of each other.
- Attendance must be a non-negative integer and must not exceed the stated capacity of the stadium used for the match.

### 8. Match Participation & Stats
To manage squads and performance, the database must track which players participated in which match. This is likely a many-to-many relationship between Player and Match, often called Match Stats or Lineup.
- **Participation Attributes:**
  - is starter (Boolean): Did the player start the match?
  - minutes played (Integer, 0-120): Total minutes the player was on the pitch.
  - position in match (e.g., CF, CB, LW): The position played in this specific match, which may differ from the player’s main position.
- **Performance Metrics (Per Match):**
  - goals (Integer non-negative): Number of goals scored in this specific match.
  - assists (Integer non-negative): Number of assists in this specific match.
  - yellow cards (Integer 0, 1 or 2): Yellow cards received. A player cannot receive more than 2 in a single match.
  - red cards (Boolean/Integer): Whether the player received a red card. A player who receives 2 yellow cards in a single match receives a red card automatically.
  - rating (Decimal 1.0 - 10.0): Performance score given by pundits.
- **Squad and Selection Rules:**
  - A maximum of 11 players may be starters in any given match for the same club. Each club may register up to 23 players per match squad.
  - A player cannot appear in a match as both a home team and away team participant.
  - **Suspension Rule 1 - Red Card:** A player who receives a red card in a match is automatically suspended for the club’s next match in the same competition. The suspension flag is derived from the red card record. The database must store the card information accurately so applications can check eligibility.
  - **Suspension Rule 2 - Yellow Card Accumulation:** A player who accumulates 5 yellow cards across a single season in a given competition is suspended for that club’s next match in the same competition.

## 3. Part 1: Conceptual Database Design
Your task in Part 1 is to perform the Conceptual Database Design (i.e., ER Design) — draw ER diagrams to capture all the information, following the approach described in the lectures.
- Use the ER notation from the textbook/lectures.
- Identify all entity sets, relationship sets, key constraints, participation constraints, weak entities, and class hierarchies (Is-A relationships).
- You must use computer-based tools (Lucidchart, diagrams.net). Handcrafted diagrams will not be accepted.
- Include a discussion at the end of the report indicating any constraints you were unable to represent in your ER design.

## 4. Part 2: Logical Database Design
For the second part of the project, your task is to convert the ER diagrams into relational tables based on the standard mapping rules.
- Write SQL DDL statements to create the relational tables.
- Specify all integrity constraints: PRIMARY KEY, FOREIGN KEY, UNIQUE, NOT NULL.
- Define general constraints using the CHECK construct (e.g., market value > 0, rating BETWEEN 1 AND 10).
- **Note:** For this part, you must use MySQL Server syntax.

## 5. Submission
This project must be completed and submitted in teams of two people. Each group should submit exactly one ZIP file.

**File Naming and Structure**
- The ZIP file must be named: `GroupXX.zip`
- Content:
  - `part1.pdf` (Conceptual Design Report)
  - `part2.pdf` (Logical Design Report)
  - `Student1ID_Contribution.pdf` (Individual Contribution Report for Student 1)
  - `Student2ID_Contribution.pdf` (Individual Contribution Report for Student 2)

**Individual Contribution Report Guidelines**
Each student must prepare an Individual Contribution Report and include it in the group ZIP file. The report must be in PDF format, named as: `Student_ID_Contribution.pdf` (e.g., `123456_Contribution.pdf`).

**What to Include:**
- **Personal Information:** Name, Student ID, Group Number.
- **Tasks & Contributions:** Briefly describe what you worked on (ER diagram, SQL DDL statements, queries, documentation, debugging, etc.).
- **Collaboration & Challenges:** How the team worked together, any difficulties, and how they were resolved.
- **Self-Assessment:** Reflection on your role, skills learned, and areas for improvement.
- **Use of AI Tools:** Specify which AI tools were used (if any), how they were used for your specific tasks, and how they helped you obtain a better solution.

**Formatting:**
- **Length:** 1 page (max 2 pages)
- **Font & Size:** Times New Roman, 12pt, 1.5 spacing
- **File Format:** PDF

**Important Notes:**
- Each student must submit their own report within the ZIP file.

**Late Submission Policy**
- One day late: -20 points. (even one minute will be considered a day late)
- Two days late: -50 points. (even one minute and a day will be considered two days late)
- Moodle closes after two days.

## 6. Academic Integrity
Plagiarism or sharing solutions between groups will result in disciplinary action. All code/solution should be written by you and your teammate. Both team members should contribute (almost) equally to the project.

You are allowed to use AI tools in your projects, provided that their use is clearly acknowledged in a separate section entitled “Use of AI Tools” in your project report. You must specify which tools were used, how they were used, and (if so) how these tools helped you obtain a better solution.

AI tools may be consulted as collaborators or assistants. However, projects must not be entirely produced by AI and should primarily reflect your own work and understanding. You are fully responsible for the content of your submissions.

Please refer to the syllabus for details.