--CREATE DATABASE Budowlanka

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--CREATE LOGIN Pracownik WITH PASSWORD = 'Pracownik123';
--GO
--CREATE LOGIN Uzytkownik WITH PASSWORD = 'Uzytkownik123';
--go

--USE Budowlanka;
--GO

--CREATE USER Pracownik FOR LOGIN Pracownik;
--GO
--ALTER SERVER ROLE sysadmin ADD MEMBER Pracownik;

--GRANT CONNECT TO Pracownik;
--GRANT CREATE TABLE TO Pracownik;
--GRANT CREATE VIEW TO Pracownik;
--GRANT CREATE PROCEDURE TO Pracownik;
--GRANT CREATE FUNCTION TO Pracownik;
--GRANT CREATE SCHEMA TO Pracownik;
--GRANT CREATE TYPE TO Pracownik;
--GRANT CREATE SYNONYM TO Pracownik;
--GRANT VIEW DEFINITION ON SCHEMA::dbo TO Pracownik;
--GRANT SELECT ON SCHEMA::dbo TO Pracownik;
--GRANT CONTROL ON SCHEMA::dbo TO Pracownik;
--GRANT CREATE TRIGGER TO Pracownik;
--GO


--Na sys takie prawa trzeba daæ 

--Dodanie linked server Oracle
--EXEC sp_addlinkedserver
--    @server = N'OracleProjekt',
--    @srvproduct = N'Oracle',
--    @provider = N'OraOLEDB.Oracle',
--    @datasrc = N'localhost:1521/pd19c'; 

--EXEC sp_addlinkedsrvlogin
--    @rmtsrvname = N'OracleProjekt', 
--    @useself = N'False',
--    @locallogin = NULL,
--    @rmtuser = N'Pracownik',
--    @rmtpassword = N'Pracownik123';  
--EXEC sp_serveroption 'OracleProjekt', 'rpc', 'true';
--EXEC sp_serveroption 'OracleProjekt', 'rpc out', 'true';


----Drop ExcelWypozyczeniaArch
--EXEC sp_droplinkedsrvlogin @rmtsrvname = 'ExcelWypozyczeniaArch', @locallogin = NULL;

--EXEC sp_dropserver @server = 'ExcelWypozyczeniaArch', @droplogins = 'droplogins';

--Dodanie linked server ExcelWypozyczeniaArch
--EXEC sp_addlinkedserver
--@server = 'ExcelWypozyczeniaArch',
--@srvproduct = '',
--@provider = 'Microsoft.ACE.OLEDB.16.0',
--@datasrc = 'C:\moje\budArch.xlsx',
--@provstr = 'Excel 12.0;HDR=YES';

--EXEC sp_addlinkedsrvlogin
--    @rmtsrvname = 'ExcelWypozyczeniaArch',
--    @useself = 'false',
--    @locallogin = NULL,
--    @rmtuser = '',
--    @rmtpassword = '';


--EXEC sp_droplinkedsrvlogin @rmtsrvname = 'ExcelRezerwacjeArch', @locallogin = NULL;

--EXEC sp_dropserver @server = 'ExcelRezerwacjeArch', @droplogins = 'droplogins';

--Dodanie linked server ExcelRezerwacjeArch

--EXEC sp_addlinkedserver
--@server = 'ExcelRezerwacjeArch',
--@srvproduct = '',
--@provider = 'Microsoft.ACE.OLEDB.16.0',
--@datasrc = 'C:\moje\budArch.xlsx',
--@provstr = 'Excel 12.0;HDR=YES';

--EXEC sp_addlinkedsrvlogin
--    @rmtsrvname = 'ExcelRezerwacjeArch',
--    @useself = 'false',
--    @locallogin = NULL,
--    @rmtuser = '',
--    @rmtpassword = '';


--GRANT ALTER ON SCHEMA::dbo TO Pracownik;
--GRANT CONTROL ON SCHEMA::dbo TO Pracownik;
--GRANT EXECUTE ON SCHEMA::dbo TO Pracownik;
--GRANT INSERT, UPDATE, DELETE, SELECT ON SCHEMA::dbo TO Pracownik;
--use master
--GRANT ALTER ANY LINKED SERVER TO Pracownik;
--use Budowlanka

--SELECT name, default_schema_name FROM sys.database_principals WHERE name = 'Pracownik';

--CREATE USER Uzytkownik FOR LOGIN Uzytkownik;

--GRANT EXECUTE ON OBJECT::dbo.AktualizujFirme TO Uzytkownik;
--GRANT EXECUTE ON OBJECT::dbo.DodajKlientaFirma TO Uzytkownik;
--GRANT EXECUTE ON OBJECT::dbo.AktualizujOsobe TO Uzytkownik;
--GRANT EXECUTE ON OBJECT::dbo.DodajKlientaOsoba TO Uzytkownik;
--GRANT EXECUTE ON OBJECT::dbo.CzyLimitCzasuWypozyczeniaPrzekroczony TO Uzytkownik;
--GRANT EXECUTE ON OBJECT::dbo.DodajRezerwacje TO Uzytkownik;
--GRANT EXECUTE ON OBJECT::dbo.DodajWypozyczenie TO Uzytkownik;
--GRANT EXECUTE ON OBJECT::dbo.DoZaplaty TO Uzytkownik;
--GRANT EXECUTE ON OBJECT::dbo.ObliczKwoteWypozyczenia TO Uzytkownik;
--GRANT EXECUTE ON OBJECT::dbo.PobierzDodatkowyKoszt TO Uzytkownik;
--GRANT EXECUTE ON OBJECT::dbo.PokazPrzegladyNaprawy TO Uzytkownik;
--GRANT EXECUTE ON OBJECT::dbo.PokazRezerwacje TO Uzytkownik;
--GRANT EXECUTE ON OBJECT::dbo.PokazWolneTerminy TO Uzytkownik;
--GRANT EXECUTE ON OBJECT::dbo.PokazWypozyczenia TO Uzytkownik;
--GRANT EXECUTE ON OBJECT::dbo.SprawdzUprawnieniaKlienta TO Uzytkownik;
--GRANT EXECUTE ON OBJECT::dbo.usunieciePrzeterminowychDanychIEksportDoExecl TO Uzytkownik;
--GRANT EXECUTE ON OBJECT::dbo.wyeksportowanieKonkretnychRezerwacjiDoExcel_ByID TO Uzytkownik;
--GRANT EXECUTE ON OBJECT::dbo.wyeksportowanieKonkretnychWypozyczenDoExcel_ByID TO Uzytkownik;
--GRANT EXECUTE ON OBJECT::dbo.wyeksportowanieWypozyczenRezerwacjiDoExcel TO Uzytkownik;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
USE Budowlanka
--Tworzenie tabel 

DROP TABLE IF EXISTS DodatkoweKoszta;
DROP TABLE IF EXISTS Wypozyczenia;
DROP TABLE IF EXISTS Rezerwacje;
DROP TABLE IF EXISTS Klienci;
DROP TABLE IF EXISTS OsobyPrywatne;
DROP TABLE IF EXISTS Firmy;


-- Tabela FIRM
CREATE TABLE Firmy (
    IDFirma INT IDENTITY(1,1) PRIMARY KEY,
    NazwaFirmy VARCHAR(100),
    NIP VARCHAR(20),
    KRS VARCHAR(20),
    Telefon VARCHAR(20),
    Email VARCHAR(50),
    AdresFirmy VARCHAR(200)
);

-- Tabela OSOBY PRYWATNE
CREATE TABLE OsobyPrywatne (
    IDOsoba INT IDENTITY(1,1) PRIMARY KEY,
    Imie VARCHAR(50),
    Nazwisko VARCHAR(50),
    Uprawnienia TINYINT,
    AdresZamieszkania VARCHAR(200),
    Telefon VARCHAR(20)
);

-- Tabela KLIENCI
CREATE TABLE Klienci (
    IDKlient INT IDENTITY(1,1) PRIMARY KEY,
    IDFirma INT NULL,
    IDOsoba INT NULL,
    FOREIGN KEY (IDFirma) REFERENCES Firmy(IDFirma),
    FOREIGN KEY (IDOsoba) REFERENCES OsobyPrywatne(IDOsoba)
);

-- Tabela Rezerwacje 
CREATE TABLE Rezerwacje (
    IDRezerwacja INT IDENTITY(1,1) PRIMARY KEY,
    IDKlient INT NOT NULL,
    IDSprzet INT NOT NULL,
    data_rezerwacji DATE NOT NULL,
    data_startu DATE NOT NULL,
    data_konca DATE NOT NULL,

    FOREIGN KEY (IDKlient) REFERENCES Klienci(IDKlient),
    --FOREIGN KEY (IDSprzet) REFERENCES Sprzet(IDSprzet)
);

-- Tabela Wypozyczenia 
CREATE TABLE Wypozyczenia (
    IDWypozyczenie INT IDENTITY(1,1) PRIMARY KEY,
    IDKlient INT NOT NULL,
    IDSprzet INT NOT NULL,
    DataWypozyczenia DATE NOT NULL,
    DataZwrotu DATE,
    Kwota DECIMAL(10, 2) NOT NULL,
    Zaliczka DECIMAL(10, 2) NOT NULL, 

    FOREIGN KEY (IDKlient) REFERENCES Klienci(IDKlient),

    CONSTRAINT chk_kaucja CHECK (Zaliczka >= 0.3 * Kwota)
);

-- Tabela DodatkoweKoszta 
CREATE TABLE DodatkoweKoszta (
    IDKoszt INT IDENTITY(1,1) PRIMARY KEY,
    Nazwa VARCHAR(100) NOT NULL,
    Opis VARCHAR(500),
    Kwota DECIMAL(10, 2) NOT NULL,
    IDWypozyczenie INT NOT NULL,

    FOREIGN KEY (IDWypozyczenie) REFERENCES Wypozyczenia(IDWypozyczenie)
);


--Excel
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--DANE#####################################################################
-----------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO Firmy (NazwaFirmy, NIP, KRS, Telefon, Email, AdresFirmy) VALUES ('Budex Sp. z o.o.', '5212345678', '0000456789', '22-555-1234', 'kontakt@budex.pl', 'ul. Budowlana 12, 00-001 Warszawa'), ('Konstruktor S.A.', '5223456789', '0000567890', '22-555-2345', 'biuro@konstruktor.pl', 'ul. Konstrukcyjna 5, 00-002 Warszawa'), ('Murarz i Synowie', '5234567890', '0000678901', '22-555-3456', 'kontakt@murarzsynowie.pl', 'ul. Ceglana 10, 00-003 Warszawa'), ('StalTech', '5245678901', '0000789012', '22-555-4567', 'info@staltech.pl', 'ul. Stalowa 3, 00-004 Warszawa'), ('DomBud', '5256789012', '0000890123', '22-555-5678', 'kontakt@dombud.pl', 'ul. Mieszkaniowa 8, 00-005 Warszawa'), ('Betonex', '5267890123', '0000901234', '22-555-6789', 'biuro@betonex.pl', 'ul. Betonowa 7, 00-006 Warszawa'), ('InwestBud', '5278901234', '0001012345', '22-555-7890', 'kontakt@inwestbud.pl', 'ul. Inwestycyjna 20, 00-007 Warszawa'), ('Remonty Polska', '5289012345', '0001123456', '22-555-8901', 'biuro@remontypolska.pl', 'ul. Remontowa 15, 00-008 Warszawa'), ('ElektroBud', '5290123456', '0001234567', '22-555-9012', 'kontakt@elektrobud.pl', 'ul. Elektryczna 2, 00-009 Warszawa'), ('MegaBudowa', '5301234567', '0001345678', '22-555-0123', 'info@megabudowa.pl', 'ul. Budowlana 25, 00-010 Warszawa'), ('SolidHaus', '5312345678', '0001456789', '22-556-1234', 'kontakt@solidhaus.pl', 'ul. Solidna 4, 00-011 Warszawa'), ('TechBud', '5323456789', '0001567890', '22-556-2345', 'biuro@techbud.pl', 'ul. Techniczna 11, 00-012 Warszawa'), ('ProBudowa', '5334567890', '0001678901', '22-556-3456', 'kontakt@probudowa.pl', 'ul. Profesjonalna 9, 00-013 Warszawa'), ('KreoBud', '5345678901', '0001789012', '22-556-4567', 'info@kreobud.pl', 'ul. Kreatywna 6, 00-014 Warszawa'), ('MaxBud', '5356789012', '0001890123', '22-556-5678', 'biuro@maxbud.pl', 'ul. Maksymalna 22, 00-015 Warszawa'), ('DomSerwis', '5367890123', '0001901234', '22-556-6789', 'kontakt@domserwis.pl', 'ul. Serwisowa 18, 00-016 Warszawa'), ('EcoBudownictwo', '5378901234', '0002012345', '22-556-7890', 'biuro@ecobudownictwo.pl', 'ul. Ekologiczna 7, 00-017 Warszawa'), ('KonstrukcjePlus', '5389012345', '0002123456', '22-556-8901', 'kontakt@konstrukcjeplus.pl', 'ul. Konstrukcyjna 33, 00-018 Warszawa'), ('Firma Remontowa', '5390123456', '0002234567', '22-556-9012', 'biuro@firmaremontowa.pl', 'ul. Remontowa 27, 00-019 Warszawa'), ('Budo-Mix', '5401234567', '0002345678', '22-556-0123', 'info@budomix.pl', 'ul. Mixowa 1, 00-020 Warszawa');

INSERT INTO OsobyPrywatne (Imie, Nazwisko, Uprawnienia, AdresZamieszkania, Telefon) VALUES ('Anna', 'Kowalska', 0, 'ul. Kwiatowa 12, 00-001 Warszawa', '600-123-456'), ('Piotr', 'Nowak', 2, 'ul. Lipowa 5, 30-002 Kraków', '601-234-567'), ('Katarzyna', 'Wiœniewska', 1, 'ul. S³oneczna 9, 50-003 Wroc³aw', '602-345-678'), ('Micha³', 'Wójcik', 3, 'ul. Leœna 4, 70-004 Szczecin', '603-456-789'), ('Ewa', 'Kaczmarek', 1, 'ul. Polna 15, 40-005 Katowice', '604-567-890'), ('Tomasz', 'Mazur', 2, 'ul. Ogrodowa 8, 60-006 Poznañ', '605-678-901'), ('Monika', 'Krawczyk', 1, 'ul. Warszawska 20, 80-007 Gdañsk', '606-789-012'), ('Jan', 'Zieliñski', 3, 'ul. Wroc³awska 7, 90-008 Lublin', '607-890-123'), ('Agnieszka', 'Sikora', 2, 'ul. Krakowska 3, 10-009 Bia³ystok', '608-901-234'), ('£ukasz', 'D¹browski', 1, 'ul. £ódzka 14, 20-010 £ódŸ', '609-012-345'), ('Magdalena', 'Czarnecka', 2, 'ul. Górska 11, 30-011 Kraków', '610-123-456'), ('Pawe³', 'Baran', 1, 'ul. Morska 19, 40-012 Katowice', '611-234-567'), ('Natalia', 'Kowalczyk', 3, 'ul. Rzeczna 5, 50-013 Wroc³aw', '612-345-678'), ('Grzegorz', 'Król', 1, 'ul. Piêkna 6, 60-014 Poznañ', '613-456-789'), ('Joanna', 'Jab³oñska', 2, 'ul. S³owackiego 2, 70-015 Szczecin', '614-567-890'), ('Marek', 'Gajda', 1, 'ul. Powstañców 23, 80-016 Gdañsk', '615-678-901'), ('Barbara', 'Zaj¹c', 2, 'ul. Warszawska 18, 90-017 Lublin', '616-789-012'), ('Dariusz', 'Sadowski', 3, 'ul. Boczna 9, 10-018 Bia³ystok', '617-890-123'), ('Olga', 'Lewandowska', 1, 'ul. Zielona 21, 20-019 £ódŸ', '618-901-234'), ('Rafa³', 'W³odarczyk', 2, 'ul. Jasna 10, 30-020 Kraków', '619-012-345');

INSERT INTO Klienci (IDFirma, IDOsoba) VALUES (1, NULL), (2, NULL), (3, NULL), (4, NULL), (5, NULL), (6, NULL), (7, NULL), (8, NULL), (9, NULL), (10, NULL), (11, NULL), (12, NULL), (13, NULL), (14, NULL), (15, NULL), (16, NULL), (17, NULL), (18, NULL), (19, NULL), (20, NULL);

INSERT INTO Klienci (IDFirma, IDOsoba) VALUES (NULL, 1), (NULL, 2), (NULL, 3), (NULL, 4), (NULL, 5), (NULL, 6), (NULL, 7), (NULL, 8), (NULL, 9), (NULL, 10), (NULL, 11), (NULL, 12), (NULL, 13), (NULL, 14), (NULL, 15), (NULL, 16), (NULL, 17), (NULL, 18), (NULL, 19), (NULL, 20);

INSERT INTO Rezerwacje (IDKlient, IDSprzet, data_rezerwacji, data_startu, data_konca) VALUES (1, 1005, '2025-04-05', '2025-06-09', '2025-06-13'), (2, 2, '2025-04-05', '2025-04-07', '2025-04-14'), (3, 3, '2025-05-01', '2025-05-05', '2025-05-10'), (4, 4, '2025-05-02', '2025-05-06', '2025-05-12'), (5, 5, '2025-05-03', '2025-05-07', '2025-05-15');

INSERT INTO Wypozyczenia (IDKlient, IDSprzet, DataWypozyczenia, DataZwrotu, Kwota, Zaliczka) VALUES (1, 1, '2025-04-01', '2025-04-10', 150.00, 50.00), (2, 2, '2025-04-03', '2025-04-14', 200.00, 70.00), (3, 3, '2025-05-01', '2025-05-10', 300.00, 100.00), (4, 4, '2025-05-02', '2025-05-12', 250.00, 80.00), (5, 5, '2025-05-03', '2025-05-15', 180.00, 60.00), (6, 6, '2025-07-18', '2025-07-22', 220.00, 70.00), (7, 7, '2025-07-19', '2025-07-23', 175.00, 60.00), (8, 8, '2025-07-20', '2025-07-24', 190.00, 60.00), (9, 9, '2025-07-21', '2025-07-25', 210.00, 70.00), (10, 10, '2025-07-22', '2025-07-26', 160.00, 50.00);



--####################################################################################################################################################################
--PRZYKLADOWE UZYCIE
--####################################################################################################################################################################

--#################################################
--usuniêcie konkretnych danych z rezerwacji i dodanie do execla
select * from Rezerwacje
EXEC usunRezerwacjeID @ID = 26
go

--#################################################
--usuniêcie konkretnych danych z wypozyczen i dodanie do execla
select * from Wypozyczenia
EXEC dbo.usunWypozyczenieID @ID = 30
go

--#################################################
--usuniêcie wszystkich przeterminowanch danych 
EXEC dbo.usunieciePrzeterminowychDanychIEksportDoExecl;
go

--#################################################
--sprawdzenie konkretnego uzytkownika ma prawa
DECLARE @wynik BIT;
EXEC dbo.SprawdzUprawnieniaKlienta @IDKlient = 1, @IDSprzet = 1001, @CzyMaUprawnienia = @wynik OUTPUT;
PRINT 'Czy ma uprawnienia: ' + CAST(@wynik AS VARCHAR);
go

--#################################################
--sprawdzenie konkretnego uzytkownika ma prawa
DECLARE @wynik BIT;
EXEC dbo.SprawdzUprawnieniaKlienta @IDKlient = 21, @IDSprzet = 1001, @CzyMaUprawnienia = @wynik OUTPUT;
PRINT 'Czy ma uprawnienia: ' + CAST(@wynik AS VARCHAR);
go

--#################################################
--dodanie klienta firmy
EXEC DodajKlientaFirma
    @NazwaFirmy = 'TechSpó³ka',
    @NIP = '1234567890',
    @KRS = '0000123456',
    @Telefon = '123456789',
    @Email = 'kontakt@firma.pl',
    @AdresFirmy = 'ul. Przyk³adowa 1';
go

--#################################################
--dodanie klienta osoby prwatnej
EXEC DodajKlientaOsoba
    @Imie = 'Jan',
    @Nazwisko = 'Kowalski',
    @Uprawnienia = 1,
    @AdresZamieszkania = 'ul. Domowa 2',
    @Telefon = '987654321';
go


--#################################################
--zaaktualiwaonie danych firmy
EXEC AktualizujFirme
    @IDFirma = 1,
    @NazwaFirmy = 'TechSpó³ka Zmieniona',
    @NIP = '9999999999',
    @KRS = '0000999999',
    @Telefon = '111111111',
    @Email = 'nowy@firma.pl',
    @AdresFirmy = 'ul. Nowa 10';
go

--#################################################
--zaaktualiwaonie danych osoby
EXEC AktualizujOsobe
    @IDOsoba = 1,
    @Imie = 'Janusz',
    @Nazwisko = 'Nowak',
    @Uprawnienia = 2,
    @AdresZamieszkania = 'ul. Nowa 2',
    @Telefon = '123123123';
go

--#################################################
--dodanie poprawnej rezerwacji
DECLARE @KodStatus INT;
DECLARE @Komunikat NVARCHAR(200);
EXEC DodajRezerwacje
    @IDKlient = 1,
	@IDSprzet = 1005,
    @DataRezerwacji = '2025-06-07',
    @DataZwrotu = '2025-06-41',
    @KodStatus = @KodStatus OUTPUT,
    @Komunikat = @Komunikat OUTPUT;
PRINT 'Kod statusu: ' + CAST(@KodStatus AS NVARCHAR);
PRINT 'Komunikat: ' + @Komunikat;
go

--#################################################
--dodanie rezerwacji o zajêtym teminie
DECLARE @KodStatus INT;
DECLARE @Komunikat NVARCHAR(200);
EXEC DodajRezerwacje
    @IDKlient = 1,
    @IDSprzet = 3001,
    @DataRezerwacji = '2025-06-07',
    @DataZwrotu = '2025-06-08',
    @KodStatus = @KodStatus OUTPUT,
    @Komunikat = @Komunikat OUTPUT;
PRINT 'Kod statusu: ' + CAST(@KodStatus AS NVARCHAR);
PRINT 'Komunikat: ' + @Komunikat;
go

--#################################################
--dodanie rezerwacji ze sprzetem w zajêtym terminie
DECLARE @KodStatus INT;
DECLARE @Komunikat NVARCHAR(200);
EXEC DodajRezerwacje
    @IDKlient = 1,
    @IDSprzet = 3001,
    @DataRezerwacji = '2025-11-11',
    @DataZwrotu = '2025-11-17',
    @KodStatus = @KodStatus OUTPUT,
    @Komunikat = @Komunikat OUTPUT;
PRINT 'Kod statusu: ' + CAST(@KodStatus AS NVARCHAR);
PRINT 'Komunikat: ' + @Komunikat;
go

--#################################################
--dodanie rezerwacji z bledem na jeden dzien
DECLARE @KodStatus INT;
DECLARE @Komunikat NVARCHAR(200);
EXEC DodajRezerwacje
    @IDKlient = 1,
    @IDSprzet = 3002,
    @DataRezerwacji = '2025-06-11',
    @DataZwrotu = '2025-06-12',
    @KodStatus = @KodStatus OUTPUT,
    @Komunikat = @Komunikat OUTPUT;
PRINT 'Kod statusu: ' + CAST(@KodStatus AS NVARCHAR);
PRINT 'Komunikat: ' + @Komunikat;
go

--#################################################
--dodanie rezerwacji klient nie ma uprawnien
DECLARE @KodStatus INT;
DECLARE @Komunikat NVARCHAR(200);
EXEC DodajRezerwacje
    @IDKlient = 21,
    @IDSprzet = 1001,
    @DataRezerwacji = '2025-06-27',
    @DataZwrotu = '2025-06-30',
    @KodStatus = @KodStatus OUTPUT,
    @Komunikat = @Komunikat OUTPUT;
PRINT 'Kod statusu: ' + CAST(@KodStatus AS NVARCHAR);
PRINT 'Komunikat: ' + @Komunikat;
go

--#################################################
--dodanie rezerwacji gdzie data zwrotu musi byc pozniejsza niz data wypozyczneia
DECLARE @KodStatus INT;
DECLARE @Komunikat NVARCHAR(200);
EXEC DodajRezerwacje
    @IDKlient = 21,
    @IDSprzet = 1001,
    @DataRezerwacji = '2025-06-27',
    @DataZwrotu = '2025-06-26',
    @KodStatus = @KodStatus OUTPUT,
    @Komunikat = @Komunikat OUTPUT;
PRINT 'Kod statusu: ' + CAST(@KodStatus AS NVARCHAR);
PRINT 'Komunikat: ' + @Komunikat;
go


--#################################################
--dodanie rezerwacji gdzie data wypozyczneia musi byc pozniejsza niz 3 miesiace od dzisiaj
DECLARE @KodStatus INT;
DECLARE @Komunikat NVARCHAR(200);
EXEC DodajRezerwacje
    @IDKlient = 19,
    @IDSprzet = 1001,
    @DataRezerwacji = '2025-10-27',
    @DataZwrotu = '2025-10-30',
    @KodStatus = @KodStatus OUTPUT,
    @Komunikat = @Komunikat OUTPUT;
PRINT 'Kod statusu: ' + CAST(@KodStatus AS NVARCHAR);
PRINT 'Komunikat: ' + @Komunikat;
go

--#################################################
--usuniêcie rezerwacji
select * from Rezerwacje

DECLARE @KodStatus INT;
DECLARE @Komunikat NVARCHAR(200);
EXEC UsunRezerwacje
    @IDRezerwacji = 22,         
    @KodStatus = @KodStatus OUTPUT,
    @Komunikat = @Komunikat OUTPUT;
PRINT 'Kod statusu: ' + CAST(@KodStatus AS NVARCHAR);
PRINT 'Komunikat: ' + @Komunikat;

--#################################################
--usuniêcie rezerwacji i wyeksportowanie 
go
DECLARE @KodStatus INT;
DECLARE @Komunikat NVARCHAR(200);

EXEC UsunRezerwacjeIWyeksportuj
    @IDRezerwacja = 8,
    @KodStatus = @KodStatus OUTPUT,
    @Komunikat = @Komunikat OUTPUT;

PRINT 'Kod statusu: ' + CAST(@KodStatus AS NVARCHAR);
PRINT 'Komunikat: ' + @Komunikat;


--#################################################
--dodanie poprawnego wypozyczenia
go
DECLARE @KodStatus INT;
DECLARE @Komunikat NVARCHAR(200);
EXEC DodajWypozyczenie
    @IDKlient = 1,
    @IDSprzet = 3001,
    @DataWypozyczenia = '2025-06-04',
    @DataZwrotu = '2025-06-04',
    @KodStatus = @KodStatus OUTPUT,
    @Komunikat = @Komunikat OUTPUT;
PRINT 'Kod statusu: ' + CAST(@KodStatus AS NVARCHAR);
PRINT 'Komunikat: ' + @Komunikat;
go
--#################################################
--usuniecie wypozyczenia
go
--select * from Wypozyczenia

DECLARE @KodStatus INT;
DECLARE @Komunikat NVARCHAR(200);
EXEC UsunWypozyczenie
    @IDWypozyczenie = 35,         
    @KodStatus = @KodStatus OUTPUT,
    @Komunikat = @Komunikat OUTPUT;
PRINT 'Kod statusu: ' + CAST(@KodStatus AS NVARCHAR);
PRINT 'Komunikat: ' + @Komunikat;
go
--#################################################
--usuniêcie wypozyczenia i weeksporowanie
DECLARE @KodStatus INT;
DECLARE @Komunikat NVARCHAR(200);
EXEC UsunWypozyczenieIWyeksportuj
    @IDWypozyczenie = 11,
    @KodStatus = @KodStatus OUTPUT,
    @Komunikat = @Komunikat OUTPUT;
PRINT 'Kod statusu: ' + CAST(@KodStatus AS NVARCHAR);
PRINT 'Komunikat: ' + @Komunikat;
go








--####################################################################################################################################################################
--PRZYKLADOWE UZYCIE
--####################################################################################################################################################################

--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
--UZYTKOWNIK
--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


--#################################################
--dodanie klienta firmy
EXEC DodajKlientaFirma
    @NazwaFirmy = 'TechSpó³ka',
    @NIP = '1234567890',
    @KRS = '0000123456',
    @Telefon = '123456789',
    @Email = 'kontakt@firma.pl',
    @AdresFirmy = 'ul. Przyk³adowa 1';
go

--#################################################
--dodanie klienta osoby prwatnej
EXEC DodajKlientaOsoba
    @Imie = 'Jan',
    @Nazwisko = 'Kowalski',
    @Uprawnienia = 1,
    @AdresZamieszkania = 'ul. Domowa 2',
    @Telefon = '987654321';
go

--#################################################
--zaaktualiwaonie danych osoby
EXEC AktualizujOsobe
    @IDOsoba = 1,
    @Imie = 'Janusz',
    @Nazwisko = 'Nowak',
    @Uprawnienia = 2,
    @AdresZamieszkania = 'ul. Nowa 2',
    @Telefon = '123123123';
go

--#################################################
--zaaktualiwaonie danych firmy
EXEC AktualizujFirme
    @IDFirma = 1,
    @NazwaFirmy = 'TechSpó³ka Zmieniona',
    @NIP = '9999999999',
    @KRS = '0000999999',
    @Telefon = '111111111',
    @Email = 'nowy@firma.pl',
    @AdresFirmy = 'ul. Nowa 10';
go

--#################################################
--dodanie poprawnej rezerwacji
DECLARE @KodStatus INT;
DECLARE @Komunikat NVARCHAR(200);
EXEC DodajRezerwacje
    @IDKlient = 1,
    @IDSprzet = 3004,
    @DataRezerwacji = '2025-06-10',
    @DataZwrotu = '2025-06-14',
    @KodStatus = @KodStatus OUTPUT,
    @Komunikat = @Komunikat OUTPUT;
PRINT 'Kod statusu: ' + CAST(@KodStatus AS NVARCHAR);
PRINT 'Komunikat: ' + @Komunikat;
go

--#################################################
--dodanie rezerwacji o zajêtym teminie
DECLARE @KodStatus INT;
DECLARE @Komunikat NVARCHAR(200);
EXEC DodajRezerwacje
    @IDKlient = 1,
    @IDSprzet = 3001,
    @DataRezerwacji = '2025-06-07',
    @DataZwrotu = '2025-06-11',
    @KodStatus = @KodStatus OUTPUT,
    @Komunikat = @Komunikat OUTPUT;
PRINT 'Kod statusu: ' + CAST(@KodStatus AS NVARCHAR);
PRINT 'Komunikat: ' + @Komunikat;
go

--#################################################
--dodanie rezerwacji ze sprzetem w zajêtym terminie
DECLARE @KodStatus INT;
DECLARE @Komunikat NVARCHAR(200);
EXEC DodajRezerwacje
    @IDKlient = 1,
    @IDSprzet = 3004,
    @DataRezerwacji = '2025-06-03',
    @DataZwrotu = '2025-06-12',
    @KodStatus = @KodStatus OUTPUT,
    @Komunikat = @Komunikat OUTPUT;
PRINT 'Kod statusu: ' + CAST(@KodStatus AS NVARCHAR);
PRINT 'Komunikat: ' + @Komunikat;
go

--#################################################
--dodanie rezerwacji z bledem na jeden dzien
DECLARE @KodStatus INT;
DECLARE @Komunikat NVARCHAR(200);
EXEC DodajRezerwacje
    @IDKlient = 1,
    @IDSprzet = 3002,
    @DataRezerwacji = '2025-06-11',
    @DataZwrotu = '2025-06-12',
    @KodStatus = @KodStatus OUTPUT,
    @Komunikat = @Komunikat OUTPUT;
PRINT 'Kod statusu: ' + CAST(@KodStatus AS NVARCHAR);
PRINT 'Komunikat: ' + @Komunikat;
go

--#################################################
--dodanie rezerwacji klient nie ma uprawnien
DECLARE @KodStatus INT;
DECLARE @Komunikat NVARCHAR(200);
EXEC DodajRezerwacje
    @IDKlient = 21,
    @IDSprzet = 1001,
    @DataRezerwacji = '2025-06-27',
    @DataZwrotu = '2025-06-30',
    @KodStatus = @KodStatus OUTPUT,
    @Komunikat = @Komunikat OUTPUT;
PRINT 'Kod statusu: ' + CAST(@KodStatus AS NVARCHAR);
PRINT 'Komunikat: ' + @Komunikat;
go

--#################################################
--dodanie rezerwacji gdzie data zwrotu musi byc pozniejsza niz data wypozyczneia
DECLARE @KodStatus INT;
DECLARE @Komunikat NVARCHAR(200);
EXEC DodajRezerwacje
    @IDKlient = 1,
    @IDSprzet = 1001,
    @DataRezerwacji = '2025-06-09',
    @DataZwrotu = '2025-06-32',
    @KodStatus = @KodStatus OUTPUT,
    @Komunikat = @Komunikat OUTPUT;
PRINT 'Kod statusu: ' + CAST(@KodStatus AS NVARCHAR);
PRINT 'Komunikat: ' + @Komunikat;
go

--#################################################
--dodanie rezerwacji gdzie data wypozyczneia musi byc pozniejsza niz 3 miesiace od dzisiaj
DECLARE @KodStatus INT;
DECLARE @Komunikat NVARCHAR(200);
EXEC DodajRezerwacje
    @IDKlient = 19,
    @IDSprzet = 1001,
    @DataRezerwacji = '2025-10-27',
    @DataZwrotu = '2025-10-30',
    @KodStatus = @KodStatus OUTPUT,
    @Komunikat = @Komunikat OUTPUT;
PRINT 'Kod statusu: ' + CAST(@KodStatus AS NVARCHAR);
PRINT 'Komunikat: ' + @Komunikat;
go

--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
--ADMIN
--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

--#################################################
--usuniêcie konkretnych danych z rezerwacji i dodanie do execla
select * from Rezerwacje
EXEC usunRezerwacjeID @ID = 20
go

--#################################################
--usuniêcie konkretnych danych z wypozyczen i dodanie do execla
select * from Wypozyczenia
EXEC dbo.usunWypozyczenieID @ID = 20
go

--#################################################
--usuniêcie wszystkich przeterminowanch danych 
EXEC dbo.usunieciePrzeterminowychDanychIEksportDoExecl;
go

--#################################################
--usuniêcie rezerwacji
select * from Rezerwacje

DECLARE @KodStatus INT;
DECLARE @Komunikat NVARCHAR(200);
EXEC UsunRezerwacje
    @IDRezerwacji = 8,         
    @KodStatus = @KodStatus OUTPUT,
    @Komunikat = @Komunikat OUTPUT;
PRINT 'Kod statusu: ' + CAST(@KodStatus AS NVARCHAR);
PRINT 'Komunikat: ' + @Komunikat;

--#################################################
--usuniêcie rezerwacji i wyeksportowanie 
go
DECLARE @KodStatus INT;
DECLARE @Komunikat NVARCHAR(200);

EXEC UsunRezerwacjeIWyeksportuj
    @IDRezerwacja = 8,
    @KodStatus = @KodStatus OUTPUT,
    @Komunikat = @Komunikat OUTPUT;

PRINT 'Kod statusu: ' + CAST(@KodStatus AS NVARCHAR);
PRINT 'Komunikat: ' + @Komunikat;

--#################################################
--dodanie poprawnego wypozyczenia
go
DECLARE @KodStatus INT;
DECLARE @Komunikat NVARCHAR(200);
EXEC DodajWypozyczenie
    @IDKlient = 1,
    @IDSprzet = 1001,
    @DataWypozyczenia = '2025-06-15',
    @DataZwrotu = '2025-06-19',
    @KodStatus = @KodStatus OUTPUT,
    @Komunikat = @Komunikat OUTPUT;
PRINT 'Kod statusu: ' + CAST(@KodStatus AS NVARCHAR);
PRINT 'Komunikat: ' + @Komunikat;
go

--#################################################
--pokaz wypozyczenia dla danego klienta
EXEC PokazWypozyczenia @IDKlient = 1

--#################################################
--pokaz wypozyczenia dla wszystkich klientow (ADMIN)
EXEC PokazWypozyczenia

--#################################################
--usuniecie wypozyczenia
go
--select * from Wypozyczenia

DECLARE @KodStatus INT;
DECLARE @Komunikat NVARCHAR(200);
EXEC UsunWypozyczenie
    @IDWypozyczenie = 35,         
    @KodStatus = @KodStatus OUTPUT,
    @Komunikat = @Komunikat OUTPUT;
PRINT 'Kod statusu: ' + CAST(@KodStatus AS NVARCHAR);
PRINT 'Komunikat: ' + @Komunikat;
go
--#################################################
--usuniêcie wypozyczenia i weeksporowanie
DECLARE @KodStatus INT;
DECLARE @Komunikat NVARCHAR(200);
EXEC UsunWypozyczenieIWyeksportuj
    @IDWypozyczenie = 11,
    @KodStatus = @KodStatus OUTPUT,
    @Komunikat = @Komunikat OUTPUT;
PRINT 'Kod statusu: ' + CAST(@KodStatus AS NVARCHAR);
PRINT 'Komunikat: ' + @Komunikat;
go

--#################################################
--dodanie dodatkowych kosztow do wypozyczenia
select * from wypozyczenia

EXEC DodajDodatkowyKoszt
    @Nazwa = 'Usterka z silnikiem',
    @Opis = 'pekla uszczelka',
    @Kwota = 2000,
    @IDWypozyczenie = 10
go

--#################################################
--procedura obliczajaca cal¹ kwote do zaplaty
EXEC DoZaplaty @IDWypozyczenia = 10
go

--#################################################
--procedura podajaca ile mamy dodatkowych kosztow
EXEC PobierzDodatkowyKoszt @IDWypozyczenie = 10

--#################################################
--procedura podajaca ile mamy dodatkowych kosztow
EXEC PobierzDodatkowyKoszt @IDWypozyczenie = 10

--#################################################
--procedura usuwajaca dodatkowe koszty
select * from DodatkoweKoszta
EXEC UsunDodatkowyKoszt @IDKoszt = 1


--#################################################
--procedura podajaca ile mamy do zaplaty
EXEC DoZaplaty @IDWypozyczenia = 10;

--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
--Dodatkowe procedury pomocnicze
--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

--#################################################
--sprawdzenie konkretnego uzytkownika ma prawa
DECLARE @wynik BIT;
EXEC dbo.SprawdzUprawnieniaKlienta @IDKlient = 1, @IDSprzet = 1001, @CzyMaUprawnienia = @wynik OUTPUT;
PRINT 'Czy ma uprawnienia: ' + CAST(@wynik AS VARCHAR);
go

--#################################################
--sprawdzenie konkretnego uzytkownika ma prawa
DECLARE @wynik BIT;
EXEC dbo.SprawdzUprawnieniaKlienta @IDKlient = 21, @IDSprzet = 1001, @CzyMaUprawnienia = @wynik OUTPUT;
PRINT 'Czy ma uprawnienia: ' + CAST(@wynik AS VARCHAR);
go

--#######





-------Poprawki
go
DECLARE @KodStatus INT;
DECLARE @Komunikat NVARCHAR(200);

EXEC DodajKlientaFirma 
    @NazwaFirmy = 'firm2a',
    @NIP = '1234564444222',
    @KRS = '000012222',
    @Telefon = '555-123-456',
    @Email = 'kontakt2@techsolutions2.pl',
    @AdresFirmy = 'ul. Nowa 12, 00-001 Warszawa',
    @KodStatus = @KodStatus OUTPUT,
    @Komunikat = @Komunikat OUTPUT;

PRINT 'Kod statusu: ' + CAST(@KodStatus AS NVARCHAR);
PRINT 'Komunikat: ' + @Komunikat;

go
DECLARE @KodStatus INT, @Komunikat NVARCHAR(200);

EXEC DodajKlientaOsoba 
    @Imie = 'Jan2',
    @Nazwisko = 'Kowalski2',
    @Uprawnienia = 1,
    @AdresZamieszkania = 'ul. Zielona 5, 00-002 Warszawa',
    @Telefon = '666-777-888',
    @KodStatus = @KodStatus OUTPUT,
    @Komunikat = @Komunikat OUTPUT;

PRINT 'Kod statusu: ' + CAST(@KodStatus AS NVARCHAR);
PRINT 'Komunikat: ' + @Komunikat;


BEGIN 
    EXEC PrzetworzDzisiejszeRezerwacje @IDRezerwacji = 33
END
go
EXEC PobierzWolneDniSprzetu @IDSprzet = 1005;

EXEC PokazWolneTerminy @IDSprzet = 1005;

EXEC dbo.PobierzMaszynyZZajetymiDniami;
EXEC dbo.PobierzWszystkieMaszyny;
EXEC dbo.PobierzMaszynyZKategoria;