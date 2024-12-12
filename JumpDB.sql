-- Opretter databasen og vælger den
USE JumpDB; -- Sørg for at bruge denne database til at køre alle efterfølgende scripts

-- 1. Medlemmer
CREATE TABLE Member (
    MemberID INT IDENTITY(200000, 1) PRIMARY KEY, -- Autoinkrement starter fra 200000
    FirstName NVARCHAR(50) NOT NULL, -- Fornavn på medlem
    LastName NVARCHAR(50) NOT NULL, -- Efternavn på medlem
    PhoneNumber NVARCHAR(15) UNIQUE NOT NULL, -- Unikt telefonnummer
    Email NVARCHAR(100) UNIQUE NOT NULL, -- Unik e-mailadresse
    BirthDate DATE NOT NULL CHECK (BirthDate <= DATEADD(YEAR, -16, GETDATE())), -- Minimumsalder: 16 år
    Address NVARCHAR(255) NOT NULL, -- Adresse på medlemmet
    JoinDate DATE DEFAULT GETDATE() NOT NULL, -- Dato for oprettelse
    MembershipPlan NVARCHAR(50) NOT NULL CHECK (MembershipPlan IN ('Standard', 'VIP')) -- Medlemskabsplaner
);

-- 2. Fitnesscenter
CREATE TABLE FitnessCenter (
    CenterID INT IDENTITY(1, 1) PRIMARY KEY, -- Autoinkrement for center ID
    CenterName NVARCHAR(100) NOT NULL, -- Fitnesscenterets navn
    Location NVARCHAR(100) NOT NULL -- Fitnesscenterets lokation
);

-- 3. Instruktører
CREATE TABLE Instructor (
    InstructorID INT IDENTITY(1, 1) PRIMARY KEY, -- Autoinkrement for instruktør ID
    FullName NVARCHAR(100) NOT NULL, -- Instruktørens fulde navn
    Phone NVARCHAR(15) UNIQUE NOT NULL -- Instruktørens telefonnummer
);

-- 4. Træningsområder
CREATE TABLE TrainingRoom (
    RoomID INT IDENTITY(1, 1) PRIMARY KEY, -- ID for træningsrum
    CenterID INT NOT NULL, -- Hvilket fitnesscenter rummet tilhører
    RoomNumber INT NOT NULL, -- Unikt nummer for hvert rum i centeret
    FOREIGN KEY (CenterID) REFERENCES FitnessCenter(CenterID), -- Relation til fitnesscenter
    CONSTRAINT UniqueRoom UNIQUE (CenterID, RoomNumber) -- Unik kombination af center og rum
);

-- 5. Holdtræning
CREATE TABLE FitnessClass (
    ClassID INT IDENTITY(1, 1) PRIMARY KEY, -- Autoinkrement for hold ID
    ClassName NVARCHAR(50) NOT NULL, -- Navn på holdet
    MaxParticipants INT DEFAULT 20 CHECK (MaxParticipants > 0), -- Maksimalt antal deltagere
    StartTime DATETIME NOT NULL, -- Starttidspunkt for holdet
    EndTime DATETIME NOT NULL, -- Sluttidspunkt for holdet
    RoomID INT NOT NULL, -- Træningsrum hvor holdet finder sted
    InstructorID INT NOT NULL, -- Instruktør der leder holdet
    FOREIGN KEY (RoomID) REFERENCES TrainingRoom(RoomID), -- Relation til træningsrum
    FOREIGN KEY (InstructorID) REFERENCES Instructor(InstructorID) -- Relation til instruktør
);

-- 6. Reservationer
CREATE TABLE Booking (
    BookingID INT IDENTITY(1, 1) PRIMARY KEY, -- Autoinkrement for booking ID
    MemberID INT NOT NULL, -- Medlem der laver reservationen
    ClassID INT NOT NULL, -- Hold der reserveres
    BookingDate DATE DEFAULT GETDATE() NOT NULL, -- Dato for reservationen
    FOREIGN KEY (MemberID) REFERENCES Member(MemberID), -- Relation til medlem
    FOREIGN KEY (ClassID) REFERENCES FitnessClass(ClassID), -- Relation til hold
    CONSTRAINT UniqueBooking UNIQUE (MemberID, ClassID) -- Hver reservation er unik for medlem og hold
);

-- Adskil batchen før triggeren
GO

-- Trigger til at validere tider for hold
CREATE TRIGGER ValidateClassTiming
ON FitnessClass
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM Inserted
        WHERE StartTime >= EndTime
    )
    BEGIN
        RAISERROR ('StartTime skal være før EndTime.', 16, 1);
        ROLLBACK;
    END
END;

-- Afslut batchen for triggeren
GO

-- Testdata til fitnesscentre
INSERT INTO FitnessCenter (CenterName, Location)
VALUES ('Fitness Roskilde', 'Roskildevej 100'),
       ('Fitness København', 'Amagerbrogade 50'),
       ('Fitness Aarhus', 'Vester Allé 25');

-- Testdata til instruktører
INSERT INTO Instructor (FullName, Phone)
VALUES ('Lars Andersen', '11223344'),
       ('Mette Jensen', '99887766');

-- Testdata til træningsrum
INSERT INTO TrainingRoom (CenterID, RoomNumber)
VALUES (1, 101), (1, 102), (2, 201), (3, 301);

-- Testdata til hold
INSERT INTO FitnessClass (ClassName, MaxParticipants, StartTime, EndTime, RoomID, InstructorID)
VALUES ('Cardio Blast', 15, '2024-12-01 10:00:00', '2024-12-01 11:00:00', 1, 1),
       ('Yoga Flow', 20, '2024-12-01 12:00:00', '2024-12-01 13:00:00', 2, 2);

-- Testdata til medlemmer
INSERT INTO Member (FirstName, LastName, PhoneNumber, Email, BirthDate, Address, MembershipPlan)
VALUES ('Peter', 'Hansen', '44332211', 'peter.h@gmail.com', '1974-07-14', 'Nørregade 10, København', 'Standard'),
       ('Maria', 'Larsen', '55667788', 'maria.l@gmail.com', '1983-03-18', 'Vestergade 20, Aarhus', 'VIP');

-- Testdata til reservationer
INSERT INTO Booking (MemberID, ClassID)
VALUES (200000, 1), (200001, 2);

-- Fremvisning af tabeller
SELECT * FROM Member;
SELECT * FROM FitnessCenter;
SELECT * FROM Instructor;
SELECT * FROM TrainingRoom;
SELECT * FROM FitnessClass;
SELECT * FROM Booking;

-- Visning af holdtræninger med instruktører og lokation
SELECT 
    fc.ClassName AS ClassName,
    i.FullName AS Instructor,
    tr.RoomNumber AS RoomNumber,
    c.CenterName AS CenterName
FROM FitnessClass fc
JOIN Instructor i ON fc.InstructorID = i.InstructorID
JOIN TrainingRoom tr ON fc.RoomID = tr.RoomID
JOIN FitnessCenter c ON tr.CenterID = c.CenterID; -- Forbind FitnessCenter for at få adgang til CenterName


-- Invalid data to test trigger
INSERT INTO FitnessClass (ClassName, MaxParticipants, StartTime, EndTime, RoomID, InstructorID)
VALUES ('Invalid Class', 15, '2024-12-01 12:00:00', '2024-12-01 11:00:00', 1, 1);

INSERT INTO Member (FirstName, LastName, PhoneNumber, Email, BirthDate, Address, MembershipPlan)
VALUES ('InvalidMember', 'Test', '87654321', 'invalidmember@test.com', '2010-01-01', 'Test Address', 'Standard');
