USE Budowlanka

--PROCEDURY

--###################################################################################################################
--CzyLimitCzasuWypozyczeniaPrzekroczony
--###################################################################################################################
GO
CREATE OR ALTER PROCEDURE CzyLimitCzasuWypozyczeniaPrzekroczony
    @IDKlient INT,
    @DataZwrotu DATE,
    @DataWypozyczenia DATE,
    @KodStatus INT OUTPUT,
    @Komunikat NVARCHAR(4000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

IF @DataWypozyczenia IS NULL OR @DataZwrotu IS NULL
    BEGIN
        SET @KodStatus = -1;
        SET @Komunikat = N'Daty wypo¿yczenia i/lub zwrotu nie mog¹ byæ puste.';
        RETURN;
    END;

    DECLARE @DniLimit INT;
    DECLARE @RodzajKlienta VARCHAR(20);

    SELECT @RodzajKlienta = CASE 
        WHEN IDFirma IS NOT NULL THEN 'Firma'
        WHEN IDOsoba IS NOT NULL THEN 'OsobaPrywatna'
        ELSE 'Nieznany'
    END
    FROM Klienci
    WHERE IDKlient = @IDKlient;

    IF @RodzajKlienta = 'Nieznany' OR @RodzajKlienta IS NULL
    BEGIN
        SET @KodStatus = 1;
        SET @Komunikat = 'Nieznany typ klienta';
        RETURN;
    END

    IF @RodzajKlienta = 'Firma'
        SET @DniLimit = 30;
    ELSE IF @RodzajKlienta = 'OsobaPrywatna'
        SET @DniLimit = 14;

    IF @DataZwrotu < @DataWypozyczenia
    BEGIN
        SET @KodStatus = 2;
        SET @Komunikat = 'Data zwrotu musi byæ póŸniejsza ni¿ data wypo¿yczenia.';
        RETURN;
    END

    IF DATEDIFF(DAY, @DataWypozyczenia, @DataZwrotu) <= 1
    BEGIN
        SET @KodStatus = 3;
        SET @Komunikat = 'Nie mo¿na wypo¿yczyæ na jeden dzieñ.';
        RETURN;
    END

    IF DATEDIFF(DAY, @DataWypozyczenia, @DataZwrotu) > @DniLimit
    BEGIN
        SET @KodStatus = 4;
        SET @Komunikat = 'Przekroczony limit dni.';
        RETURN;
    END

    IF @DataWypozyczenia < CAST(GETDATE() AS DATE)
    BEGIN
        SET @KodStatus = 5;
        SET @Komunikat = 'Data wypo¿yczenia nie mo¿e byæ wczeœniejsza ni¿ dzisiaj.';
        RETURN;
    END

    IF @DataWypozyczenia > DATEADD(MONTH, 3, CAST(GETDATE() AS DATE))
    BEGIN
        SET @KodStatus = 6;
        SET @Komunikat = 'Data wypo¿yczenia nie mo¿e byæ póŸniejsza ni¿ 3 miesi¹ce od dzisiaj.';
        RETURN;
    END

    IF @DataZwrotu > DATEADD(MONTH, 3, CAST(GETDATE() AS DATE))
    BEGIN
        SET @KodStatus = 7;
        SET @Komunikat = 'Data zwrotu nie mo¿e byæ póŸniejsza ni¿ 3 miesi¹ce od dzisiaj.';
        RETURN;
    END

    SET @KodStatus = 0;
    SET @Komunikat = 'Limit czasu wypo¿yczenia nie zosta³ przekroczony.';
END;

--###################################################################################################################
--Funkcja do sprawdzania czy klient ma uprawnienia
--###################################################################################################################

go
CREATE OR ALTER PROCEDURE dbo.SprawdzUprawnieniaKlienta
(
    @IDKlient INT,
    @IDSprzet INT,
    @CzyMaUprawnienia BIT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RodzajKlienta VARCHAR(10);
    DECLARE @UprawnieniaSprzetu INT;
    DECLARE @IDOsoba INT;
    DECLARE @UprawnieniaKlienta INT;

    -- Pobierz rodzaj klienta i IDOsoba
    SELECT 
        @RodzajKlienta = CASE 
            WHEN IDFirma IS NOT NULL THEN 'Firma'
            WHEN IDOsoba IS NOT NULL THEN 'Osoba'
            ELSE 'Nieznany'
        END,
        @IDOsoba = IDOsoba
    FROM Klienci
    WHERE IDKlient = @IDKlient;

    IF @RodzajKlienta = 'Nieznany' OR @RodzajKlienta IS NULL
    BEGIN
        SET @CzyMaUprawnienia = 0;
        RETURN;
    END

    DECLARE @sql NVARCHAR(MAX);
    DECLARE @UprawnieniaSprzetuTemp TABLE (Uprawnienia INT);

    SET @sql = N'SELECT Uprawnienia FROM OPENQUERY(OracleProjekt, 
        ''SELECT Uprawnienia FROM SprzetBudowlany WHERE IDSprzet = ' + CAST(@IDSprzet AS NVARCHAR(20)) + ''')';

    INSERT INTO @UprawnieniaSprzetuTemp
    EXEC sp_executesql @sql;

    SELECT TOP 1 @UprawnieniaSprzetu = Uprawnienia FROM @UprawnieniaSprzetuTemp;

    -- Jeœli sprzêt nie wymaga uprawnieñ, ka¿dy klient mo¿e wypo¿yczyæ
    IF @UprawnieniaSprzetu IS NOT NULL AND @UprawnieniaSprzetu = 0
    BEGIN
        SET @CzyMaUprawnienia = 1;
        RETURN;
    END

    -- Klient typu Firma zawsze ma uprawnienia
    IF @RodzajKlienta = 'Firma'
    BEGIN
        SET @CzyMaUprawnienia = 1;
        RETURN;
    END

    -- SprawdŸ uprawnienia osoby prywatnej
    IF @RodzajKlienta = 'Osoba' AND @IDOsoba IS NOT NULL
    BEGIN
        SELECT @UprawnieniaKlienta = Uprawnienia FROM OsobyPrywatne WHERE IDOsoba = @IDOsoba;

        IF @UprawnieniaKlienta IS NOT NULL AND @UprawnieniaKlienta = 1
            SET @CzyMaUprawnienia = 1;
        ELSE
            SET @CzyMaUprawnienia = 0;

        RETURN;
    END

    SET @CzyMaUprawnienia = 0;
END;


--DECLARE @wynik BIT;
--EXEC dbo.SprawdzUprawnieniaKlienta @IDKlient = 43, @IDSprzet = 1001, @CzyMaUprawnienia = @wynik OUTPUT;
--PRINT 'Czy ma uprawnienia: ' + CAST(@wynik AS VARCHAR);


--###################################################################################################################
--procedura do sprawdzania kwoty wypozyczneia
--###################################################################################################################

go
CREATE OR ALTER PROCEDURE ObliczKwoteWypozyczenia
(
    @IDSprzet INT,
    @DataWyp DATE,
    @DataZwrotu DATE,
    @KwotaCalkowita DECIMAL(18,2) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StawkaDzienna DECIMAL(18,2);
    DECLARE @sql NVARCHAR(MAX);

    DECLARE @StawkaTemp TABLE (KwotaZaDzien DECIMAL(18,2));

    SET @sql = N'SELECT KwotaZaDzien FROM OPENQUERY(OracleProjekt, 
        ''SELECT KwotaZaDzien FROM V_SprzetBudowlany  WHERE IDSprzet = ' + CAST(@IDSprzet AS NVARCHAR(20)) + ''')';

    INSERT INTO @StawkaTemp
    EXEC sp_executesql @sql;

    SELECT TOP 1 @StawkaDzienna = KwotaZaDzien FROM @StawkaTemp;

    IF @StawkaDzienna IS NULL
    BEGIN
        SET @KwotaCalkowita = NULL;
        RETURN;
    END

    DECLARE @LiczbaDni INT;
    SET @LiczbaDni = DATEDIFF(DAY, @DataWyp, @DataZwrotu);
    IF @LiczbaDni < 1 SET @LiczbaDni = 1;

    SET @KwotaCalkowita = @LiczbaDni * @StawkaDzienna;
END;

--DECLARE @kwota DECIMAL(18,2);
--EXEC ObliczKwoteWypozyczenia @IDSprzet = 1001, @DataWyp = '2025-05-01', @DataZwrotu = '2025-05-05', @KwotaCalkowita = @kwota OUTPUT;
--PRINT 'Kwota ca³kowita: ' + CAST(@kwota AS VARCHAR(20));

--###################################################################################################################
--procedura do sprawdzania kwoty wypozyczneia
--###################################################################################################################
go
CREATE OR ALTER PROCEDURE DodajWypozyczenie
    @IDKlient INT,
    @IDSprzet INT,
    @DataWypozyczenia DATE,
    @DataZwrotu DATE,
    @KodStatus INT OUTPUT,
    @Komunikat NVARCHAR(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ID INT;
    DECLARE @Kwota DECIMAL(10,2);
    DECLARE @Count INT;
    DECLARE @Data DATE;
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @CountZajety INT;
    DECLARE @KodStatusLimit INT;
    DECLARE @KomunikatLimit NVARCHAR(4000);
    DECLARE @CzyMaUprawnienia BIT;
	DECLARE @IDSprzetstr NVARCHAR(20) = CAST(@IDSprzet AS NVARCHAR(20));

    -- 1. Sprawdzenie czy klient istnieje
    IF NOT EXISTS (SELECT 1 FROM Klienci WHERE IDKlient = @IDKlient)
    BEGIN
        SET @KodStatus = 1;
        SET @Komunikat = 'Klient nie istnieje.';
        RETURN;
    END

    -- 2. Sprawdzenie czy sprzêt istnieje (Oracle)
    SET @sql = N'
        SELECT COUNT(*) 
        FROM OPENQUERY(OracleProjekt, 
            ''SELECT 1 FROM V_SprzetBudowlany WHERE IDSprzet = ' + CAST(@IDSprzet AS NVARCHAR(20)) + ''')';

    DECLARE @tmp TABLE (Cnt INT);
    INSERT INTO @tmp EXEC (@sql);
    SELECT @Count = Cnt FROM @tmp;

    IF @Count = 0
    BEGIN
        SET @KodStatus = 2;
        SET @Komunikat = 'Sprzêt nie istnieje w Oracle.';
        RETURN;
    END

    -- 3. Sprawdzenie limitu wypo¿yczenia
    EXEC dbo.CzyLimitCzasuWypozyczeniaPrzekroczony 
        @IDKlient = @IDKlient,
        @DataZwrotu = @DataZwrotu,
        @DataWypozyczenia = @DataWypozyczenia,
        @KodStatus = @KodStatusLimit OUTPUT,
        @Komunikat = @KomunikatLimit OUTPUT;

    IF @KodStatusLimit <> 0
    BEGIN
        SET @KodStatus = @KodStatusLimit;
        SET @Komunikat = @KomunikatLimit;
        RETURN;
    END

    -- 4. Sprawdzenie dostêpnoœci sprzêtu w danym okresie
	SET @sql = N'
		SELECT IDZajeteDni, Data, IDSprzet
		FROM OPENQUERY(OracleProjekt,
			''
			SELECT IDZajeteDni, Data, IDSprzet
			FROM VW_ZajeteDniSprzetu
			WHERE IDSprzet = ' + CAST(@IDSprzet AS NVARCHAR(20)) + '
			''
		)
	';

	CREATE TABLE #TmpZajeteDniSprzetu
	(
		ID INT,
		Data DATETIME,
		IDSprzet INT
	);

	INSERT INTO #TmpZajeteDniSprzetu (ID, Data, IDSprzet)
	EXEC (@sql);

	--SELECT COUNT(*) AS LiczbaZajetychDni
	--FROM #TmpZajeteDniSprzetu
	--WHERE Data >= @DataWypozyczenia
	--  AND Data <= @DataZwrotu;


	SET @CountZajety = (SELECT COUNT(*) FROM #TmpZajeteDniSprzetu WHERE Data >= @DataWypozyczenia
	  AND Data <= @DataZwrotu);

	DROP TABLE #TmpZajeteDniSprzetu;
	
	-- 4. Sprawdzenie wyniku i ewentualne przerwanie
	IF @CountZajety > 0
	BEGIN
		SET @KodStatus = 5;
		SET @Komunikat = 'Sprzêt zajêty w podanym okresie.';
		RETURN;
	END


    -- 5. Sprawdzenie uprawnieñ klienta
    EXEC dbo.SprawdzUprawnieniaKlienta
        @IDKlient = @IDKlient,
        @IDSprzet = @IDSprzet,
        @CzyMaUprawnienia = @CzyMaUprawnienia OUTPUT;

    IF @CzyMaUprawnienia = 0
    BEGIN
        SET @KodStatus = 6;
        SET @Komunikat = 'Klient nie ma wymaganych uprawnieñ.';
        RETURN;
    END

    -- 6. Obliczenie kwoty
    EXEC dbo.ObliczKwoteWypozyczenia
        @IDSprzet = @IDSprzet,
        @DataWyp = @DataWypozyczenia,
        @DataZwrotu = @DataZwrotu,
        @KwotaCalkowita = @Kwota OUTPUT;

    IF @Kwota IS NULL
    BEGIN
        SET @KodStatus = 7;
        SET @Komunikat = 'Nie mo¿na obliczyæ kwoty wypo¿yczenia.';
        RETURN;
    END

    -- 7. Wstawienie rekordu wypo¿yczenia

    INSERT INTO Wypozyczenia (IDKlient, IDSprzet, DataWypozyczenia, DataZwrotu, Kwota, Zaliczka)
    VALUES (@IDKlient, @IDSprzet, @DataWypozyczenia, @DataZwrotu, @Kwota, @Kwota * 0.3);

    -- 8. Zajêcie dni w Oracle
    SET @Data = @DataWypozyczenia;

    WHILE @Data <= @DataZwrotu
    BEGIN
        SET @sql = '
            BEGIN
                PAKIETZAJETEDNI.DodajZajetyDzien(
                    p_IDZajeteDni => NULL,
                    p_Data => TO_DATE(''' + CONVERT(VARCHAR(10), @Data, 120) + ''', ''YYYY-MM-DD''),
                    p_IDSprzet => ' + CAST(@IDSprzet AS NVARCHAR(20)) + '
                );
            END;';

        EXEC (@sql) AT OracleProjekt;
        SET @Data = DATEADD(DAY, 1, @Data);
    END

    SET @KodStatus = 0;
    SET @Komunikat = 'Wypo¿yczenie dodane pomyœlnie. ';
END;

go

--DECLARE @KodStatus INT;
--DECLARE @Komunikat NVARCHAR(200);

--EXEC DodajWypozyczenie
--    @IDKlient = 1,
--    @IDSprzet = 1001,
--    @DataWypozyczenia = '2025-06-01',
--    @DataZwrotu = '2025-06-05',
--    @KodStatus = @KodStatus OUTPUT,
--    @Komunikat = @Komunikat OUTPUT;

---- Sprawdzenie wyniku
--PRINT 'Kod statusu: ' + CAST(@KodStatus AS NVARCHAR);
--PRINT 'Komunikat: ' + @Komunikat;

--###################################################################################################################
----UsunWypozyczenie
--###################################################################################################################
go
CREATE OR ALTER PROCEDURE UsunWypozyczenie
    @IDWypozyczenie INT,
    @KodStatus INT OUTPUT,
    @Komunikat NVARCHAR(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IDSprzet INT;
    DECLARE @DataWypozyczenia DATE;
    DECLARE @DataZwrotu DATE;
    DECLARE @sql NVARCHAR(MAX);

    BEGIN TRY
        -- 1. Pobranie danych wypo¿yczenia
        SELECT @IDSprzet = IDSprzet,
               @DataWypozyczenia = DataWypozyczenia,
               @DataZwrotu = DataZwrotu
        FROM Wypozyczenia
        WHERE IDWypozyczenie = @IDWypozyczenie;

        IF @IDSprzet IS NULL
        BEGIN
            SET @KodStatus = 1;
            SET @Komunikat = 'Nie znaleziono wypo¿yczenia o podanym ID.';
            RETURN;
        END

        -- 2. Usuniêcie wypo¿yczenia z lokalnej tabeli
        DELETE FROM Wypozyczenia WHERE IDWypozyczenie = @IDWypozyczenie;

        -- 3. Pobranie zajêtych dni z Oracle dla tego sprzêtu i zakresu dat
		SET @sql = N'
			SELECT IDZajeteDni
			FROM OPENQUERY(OracleProjekt, 
				''
				SELECT IDZajeteDni
				FROM VW_ZajeteDniSprzetu
				WHERE IDSprzet = ' + CAST(@IDSprzet AS NVARCHAR(20)) + '
					AND Data BETWEEN TO_DATE(''''' + CONVERT(VARCHAR(10), @DataWypozyczenia, 23) + ''''', ''''YYYY-MM-DD'''')
								AND TO_DATE(''''' + CONVERT(VARCHAR(10), @DataZwrotu, 23) + ''''', ''''YYYY-MM-DD'''')
				''
			)';


        -- Tymczasowa tabela na IDZajeteDni
        CREATE TABLE #TmpZajeteDniSprzetu (IDZajeteDni INT);

        INSERT INTO #TmpZajeteDniSprzetu (IDZajeteDni)
        EXEC (@sql);
		--select *from #TmpZajeteDniSprzetu
        -- 4. Usuwanie zajêtych dni w Oracle po kolei
        DECLARE @IDZajetyDzien INT;

        DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT IDZajeteDni FROM #TmpZajeteDniSprzetu;

        OPEN cur;
        FETCH NEXT FROM cur INTO @IDZajetyDzien;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @sql = N'
                BEGIN
                    PAKIETZAJETEDNI.UsunZajetyDzien(' + CAST(@IDZajetyDzien AS NVARCHAR(20)) + ');
                END;';

            EXEC (@sql) AT OracleProjekt;

            FETCH NEXT FROM cur INTO @IDZajetyDzien;
        END

        CLOSE cur;
        DEALLOCATE cur;

        DROP TABLE #TmpZajeteDniSprzetu;

        SET @KodStatus = 0;
        SET @Komunikat = 'Wypo¿yczenie i zajête dni zosta³y usuniête. ID: ' + CAST(@IDWypozyczenie AS NVARCHAR);

    END TRY
    BEGIN CATCH
        SET @KodStatus = ERROR_NUMBER();
        SET @Komunikat = ERROR_MESSAGE();
    END CATCH
END;

go

--select * from Wypozyczenia

--DECLARE @KodStatus INT;
--DECLARE @Komunikat NVARCHAR(200);

--EXEC UsunWypozyczenie
--    @IDWypozyczenie = 35,
--    @KodStatus = @KodStatus OUTPUT,
--    @Komunikat = @Komunikat OUTPUT;

--PRINT 'Kod statusu: ' + CAST(@KodStatus AS NVARCHAR);
--PRINT 'Komunikat: ' + @Komunikat;

--###################################################################################################################
----Wyœwietl  Wypozyczenie
--###################################################################################################################
go

CREATE OR ALTER PROCEDURE PokazWypozyczenia
    @IDKlient INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        W.IDWypozyczenie,
        W.IDKlient,
        CASE 
            WHEN K.IDFirma IS NOT NULL THEN F.NazwaFirmy
            ELSE OP.Imie + ' ' + OP.Nazwisko
        END AS Klient,
        W.IDSprzet,
        W.DataWypozyczenia,
        W.DataZwrotu,
        W.Kwota,
        W.Zaliczka
    FROM 
        Wypozyczenia W
    JOIN 
        Klienci K ON W.IDKlient = K.IDKlient
    LEFT JOIN 
        Firmy F ON K.IDFirma = F.IDFirma
    LEFT JOIN 
        OsobyPrywatne OP ON K.IDOsoba = OP.IDOsoba
    WHERE 
        @IDKlient IS NULL OR W.IDKlient = @IDKlient
    ORDER BY 
        W.DataWypozyczenia DESC;
END;

--EXEC PokazWypozyczenia @IDKlient=1;



--###################################################################################################################
----Dodaj rezerwacje
--###################################################################################################################
go
CREATE OR ALTER PROCEDURE DodajRezerwacje
    @IDKlient INT,
    @IDSprzet INT,
    @DataRezerwacji DATE,
    @DataZwrotu DATE,
    @KodStatus INT OUTPUT,
    @Komunikat NVARCHAR(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ID INT;
    DECLARE @Kwota DECIMAL(10,2);
    DECLARE @Count INT;
    DECLARE @Data DATE;
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @CountZajety INT;
    DECLARE @KodStatusLimit INT;
    DECLARE @KomunikatLimit NVARCHAR(4000);
    DECLARE @CzyMaUprawnienia BIT;
	DECLARE @IDSprzetstr NVARCHAR(20) = CAST(@IDSprzet AS NVARCHAR(20));

    -- 1. Sprawdzenie czy klient istnieje
    IF NOT EXISTS (SELECT 1 FROM Klienci WHERE IDKlient = @IDKlient)
    BEGIN
        SET @KodStatus = 1;
        SET @Komunikat = 'Klient nie istnieje.';
        RETURN;
    END

    -- 2. Sprawdzenie czy sprzêt istnieje (Oracle)
    SET @sql = N'
        SELECT COUNT(*) 
        FROM OPENQUERY(OracleProjekt, 
            ''SELECT 1 FROM V_SprzetBudowlany WHERE IDSprzet = ' + CAST(@IDSprzet AS NVARCHAR(20)) + ''')';

    DECLARE @tmp TABLE (Cnt INT);
    INSERT INTO @tmp EXEC (@sql);
    SELECT @Count = Cnt FROM @tmp;

    IF @Count = 0
    BEGIN
        SET @KodStatus = 2;
        SET @Komunikat = 'Sprzêt nie istnieje w Oracle.';
        RETURN;
    END

    -- 3. Sprawdzenie limitu Rezerwacji
    EXEC dbo.CzyLimitCzasuWypozyczeniaPrzekroczony 
        @IDKlient = @IDKlient,
        @DataZwrotu = @DataZwrotu,
        @DataWypozyczenia = @DataRezerwacji,
        @KodStatus = @KodStatusLimit OUTPUT,
        @Komunikat = @KomunikatLimit OUTPUT;

    IF @KodStatusLimit <> 0
    BEGIN
        SET @KodStatus = @KodStatusLimit;
        SET @Komunikat = @KomunikatLimit;
        RETURN;
    END

    -- 4. Sprawdzenie dostêpnoœci sprzêtu w danym okresie
	SET @sql = N'
		SELECT IDZajeteDni, Data, IDSprzet
		FROM OPENQUERY(OracleProjekt,
			''
			SELECT IDZajeteDni, Data, IDSprzet
			FROM VW_ZajeteDniSprzetu
			WHERE IDSprzet = ' + CAST(@IDSprzet AS NVARCHAR(20)) + '
			''
		)
	';

	CREATE TABLE #TmpZajeteDniSprzetu
	(
		ID INT,
		Data DATETIME,
		IDSprzet INT
	);

	INSERT INTO #TmpZajeteDniSprzetu (ID, Data, IDSprzet)
	EXEC (@sql);

	--SELECT COUNT(*) AS LiczbaZajetychDni
	--FROM #TmpZajeteDniSprzetu
	--WHERE Data >= @DataRezerwacji
	--  AND Data <= @DataZwrotu;


	SET @CountZajety = (SELECT COUNT(*) FROM #TmpZajeteDniSprzetu WHERE Data >= @DataRezerwacji
	  AND Data <= @DataZwrotu);

	DROP TABLE #TmpZajeteDniSprzetu;
	
	-- 4. Sprawdzenie wyniku i ewentualne przerwanie
	IF @CountZajety > 0
	BEGIN
		SET @KodStatus = 5;
		SET @Komunikat = 'Sprzêt zajêty w podanym okresie.';
		RETURN;
	END


    -- 5. Sprawdzenie uprawnieñ klienta
    EXEC dbo.SprawdzUprawnieniaKlienta
        @IDKlient = @IDKlient,
        @IDSprzet = @IDSprzet,
        @CzyMaUprawnienia = @CzyMaUprawnienia OUTPUT;

    IF @CzyMaUprawnienia = 0
    BEGIN
        SET @KodStatus = 6;
        SET @Komunikat = 'Klient nie ma wymaganych uprawnieñ.';
        RETURN;
    END

    -- 7. Wstawienie rekordu Rezerwacji

    INSERT INTO Rezerwacje(IDKlient, IDSprzet, data_rezerwacji, data_startu, data_konca)
    VALUES (@IDKlient, @IDSprzet, GETDATE(), @DataRezerwacji, @DataZwrotu);

    -- 8. Zajêcie dni w Oracle
    SET @Data = @DataRezerwacji;

    WHILE @Data <= @DataZwrotu
    BEGIN
        SET @sql = '
            BEGIN
                PAKIETZAJETEDNI.DodajZajetyDzien(
                    p_IDZajeteDni => NULL,
                    p_Data => TO_DATE(''' + CONVERT(VARCHAR(10), @Data, 120) + ''', ''YYYY-MM-DD''),
                    p_IDSprzet => ' + CAST(@IDSprzet AS NVARCHAR(20)) + '
                );
            END;';

        EXEC (@sql) AT OracleProjekt;
        SET @Data = DATEADD(DAY, 1, @Data);
    END

    SET @KodStatus = 0;
    SET @Komunikat = 'Wypo¿yczenie dodane pomyœlnie. ';
END;

go

--DECLARE @KodStatus INT;
--DECLARE @Komunikat NVARCHAR(200);

--EXEC DodajRezerwacje
--    @IDKlient = 1,
--    @IDSprzet = 3002,
--    @DataRezerwacji = '2025-06-07',
--    @DataZwrotu = '2025-06-11',
--    @KodStatus = @KodStatus OUTPUT,
--    @Komunikat = @Komunikat OUTPUT;

---- Sprawdzenie wyniku
--PRINT 'Kod statusu: ' + CAST(@KodStatus AS NVARCHAR);
--PRINT 'Komunikat: ' + @Komunikat;
--###################################################################################################################
----Usun rezerwacje
--###################################################################################################################

go
CREATE OR ALTER PROCEDURE UsunRezerwacje
    @IDRezerwacji INT,
    @KodStatus INT OUTPUT,
    @Komunikat NVARCHAR(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IDSprzet INT;
    DECLARE @DataRezerwacji DATE;
    DECLARE @DataZwrotu DATE;
    DECLARE @sql NVARCHAR(MAX);

    BEGIN TRY
        -- 1. Pobranie danych wypo¿yczenia
        SELECT @IDSprzet = IDSprzet,
               @DataRezerwacji = data_rezerwacji,
               @DataZwrotu = data_konca
        FROM Rezerwacje
        WHERE IDRezerwacja = @IDRezerwacji;

        IF @IDSprzet IS NULL
        BEGIN
            SET @KodStatus = 1;
            SET @Komunikat = 'Nie znaleziono wypo¿yczenia o podanym ID.';
            RETURN;
        END

        -- 2. Usuniêcie wypo¿yczenia z lokalnej tabeli
        DELETE FROM Rezerwacje WHERE IDRezerwacja = @IDRezerwacji;

        -- 3. Pobranie zajêtych dni z Oracle dla tego sprzêtu i zakresu dat
		SET @sql = N'
			SELECT IDZajeteDni
			FROM OPENQUERY(OracleProjekt, 
				''
				SELECT IDZajeteDni
				FROM VW_ZajeteDniSprzetu
				WHERE IDSprzet = ' + CAST(@IDSprzet AS NVARCHAR(20)) + '
					AND Data BETWEEN TO_DATE(''''' + CONVERT(VARCHAR(10), @DataRezerwacji, 23) + ''''', ''''YYYY-MM-DD'''')
								AND TO_DATE(''''' + CONVERT(VARCHAR(10), @DataZwrotu, 23) + ''''', ''''YYYY-MM-DD'''')
				''
			)';

        CREATE TABLE #TmpZajeteDniSprzetu (IDZajeteDni INT);

        INSERT INTO #TmpZajeteDniSprzetu (IDZajeteDni)
        EXEC (@sql);
		--select *from #TmpZajeteDniSprzetu
        -- 4. Usuwanie zajêtych dni w Oracle po kolei
        DECLARE @IDZajetyDzien INT;

        DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT IDZajeteDni FROM #TmpZajeteDniSprzetu;

        OPEN cur;
        FETCH NEXT FROM cur INTO @IDZajetyDzien;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @sql = N'
                BEGIN
                    PAKIETZAJETEDNI.UsunZajetyDzien(' + CAST(@IDZajetyDzien AS NVARCHAR(20)) + ');
                END;';

            EXEC (@sql) AT OracleProjekt;

            FETCH NEXT FROM cur INTO @IDZajetyDzien;
        END

        CLOSE cur;
        DEALLOCATE cur;

        DROP TABLE #TmpZajeteDniSprzetu;

        SET @KodStatus = 0;
        SET @Komunikat = 'Rezerwacje i zajête dni zosta³y usuniête. ID: ' + CAST(@IDRezerwacji AS NVARCHAR);

    END TRY
    BEGIN CATCH
        SET @KodStatus = ERROR_NUMBER();
        SET @Komunikat = ERROR_MESSAGE();
    END CATCH
END;

go

--select * from Rezerwacje

--DECLARE @KodStatus INT;
--DECLARE @Komunikat NVARCHAR(200);

--EXEC UsunRezerwacje
--    @IDRezerwacji = 21,
--    @KodStatus = @KodStatus OUTPUT,
--    @Komunikat = @Komunikat OUTPUT;

--PRINT 'Kod statusu: ' + CAST(@KodStatus AS NVARCHAR);
--PRINT 'Komunikat: ' + @Komunikat;

--###################################################################################################################
----Wyswietl rezerwacje
--###################################################################################################################

go

CREATE OR ALTER  PROCEDURE PokazRezerwacje
    @IDKlient INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        R.IDRezerwacja,
        R.IDKlient,
        CASE 
            WHEN K.IDFirma IS NOT NULL THEN F.NazwaFirmy
            ELSE OP.Imie + ' ' + OP.Nazwisko
        END AS Klient,
        R.IDSprzet,
        R.data_rezerwacji,
        R.data_startu,
        R.data_konca
    FROM 
        Rezerwacje R
    JOIN 
        Klienci K ON R.IDKlient = K.IDKlient
    LEFT JOIN 
        Firmy F ON K.IDFirma = F.IDFirma
    LEFT JOIN 
        OsobyPrywatne OP ON K.IDOsoba = OP.IDOsoba
    WHERE 
        @IDKlient IS NULL OR R.IDKlient = @IDKlient
    ORDER BY 
        R.data_rezerwacji DESC;
END;

EXEC PokazRezerwacje;


--###################################################################################################################
----Wyswietlanie wolnych terminów danej maszyny
--###################################################################################################################

go

CREATE OR ALTER  PROCEDURE PokazWolneTerminy
    @IDSprzet INT
AS
BEGIN
    SET NOCOUNT ON;

    WITH DatyKalendarza AS (
        SELECT CAST(GETDATE() AS DATE) AS Dzien
        UNION ALL
        SELECT DATEADD(DAY, 1, Dzien)
        FROM DatyKalendarza
        WHERE Dzien < DATEADD(MONTH, 3, GETDATE())
    )

    SELECT 
        D.Dzien AS WolnyDzien
    FROM 
        DatyKalendarza D
    LEFT JOIN 
        OPENQUERY(OracleProjekt, 
            'SELECT IDSprzet, Data FROM VW_ZajeteDniSprzetu'
        ) AS Z
        ON D.Dzien = CAST(Z.Data AS DATE) AND Z.IDSprzet = @IDSprzet
    WHERE 
        Z.Data IS NULL
    ORDER BY 
        D.Dzien

    OPTION (MAXRECURSION 1000);
END;

--Exec PokazWolneTerminy  @IDSprzet=1001;

--#####################################################################################
--Dodawanie Dodatkowe koszta
--#####################################################################################
go
CREATE OR ALTER PROCEDURE DodajDodatkowyKoszt
    @Nazwa VARCHAR(100),
    @Opis VARCHAR(500),
    @Kwota DECIMAL(10,2),
    @IDWypozyczenie INT
AS
BEGIN
    BEGIN TRY
        IF NOT EXISTS (
            SELECT 1 FROM Wypozyczenia WHERE IDWypozyczenie = @IDWypozyczenie
        )
        BEGIN
            PRINT 'B³¹d: Wypo¿yczenie o podanym ID nie istnieje.';
            RETURN;
        END

        INSERT INTO DodatkoweKoszta (Nazwa, Opis, Kwota, IDWypozyczenie)
        VALUES (@Nazwa, @Opis, @Kwota, @IDWypozyczenie);
    END TRY
    BEGIN CATCH
        PRINT 'B³¹d podczas dodawania kosztu: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;

GO
--#####################################################################################
--Usuwanie Dodatkowe koszta
--#####################################################################################
CREATE OR ALTER PROCEDURE UsunDodatkowyKoszt
    @IDKoszt INT
AS
BEGIN
    BEGIN TRY
        DELETE FROM DodatkoweKoszta
        WHERE IDKoszt = @IDKoszt;

        IF @@ROWCOUNT = 0
        BEGIN
            PRINT 'Nie znaleziono rekordu o podanym IDKoszt.';
        END
    END TRY
    BEGIN CATCH
        PRINT 'B³¹d podczas usuwania kosztu: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;

GO

--#####################################################################################
--Wyswietlanie po Id Dodatkowe koszta
--#####################################################################################
CREATE OR ALTER PROCEDURE PobierzDodatkowyKoszt
    @IDWypozyczenie INT
AS
BEGIN
    BEGIN TRY
    IF NOT EXISTS (
            SELECT 1 FROM Wypozyczenia WHERE IDWypozyczenie = @IDWypozyczenie
        )
        BEGIN
            PRINT 'B³¹d: Wypo¿yczenie o podanym ID nie istnieje.';
            RETURN;
        END
        SELECT IDKoszt, Nazwa, Opis, Kwota, IDWypozyczenie
        FROM DodatkoweKoszta
        WHERE IDWypozyczenie = @IDWypozyczenie;

        IF @@ROWCOUNT = 0
        BEGIN
            PRINT 'Nie znaleziono rekordu o podanym IDKoszt.';
        END
    END TRY
    BEGIN CATCH
        PRINT 'B³¹d podczas pobierania kosztu: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;

--EXEC DodajDodatkowyKoszt
--    @Nazwa = 'Op³ata za mycie',
--    @Opis = 'Sprzet byl bardzo brudny',
--    @Kwota = 50.00,
--    @IDWypozyczenie = 1024;


--#####################################################################################
--Wyswietlanie po Id Dodatkowe koszta
--#####################################################################################
go
CREATE OR ALTER PROCEDURE DoZaplaty
    @IDWypozyczenia INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @KwotaWypozyczenia DECIMAL(10, 2),
        @Zaliczka DECIMAL(10, 2),
        @DodatkoweKoszty DECIMAL(10, 2),
        @KwotaDoZaplaty DECIMAL(10, 2);

    BEGIN TRY
        SELECT 
            @KwotaWypozyczenia = Kwota,
            @Zaliczka = Zaliczka
        FROM 
            Wypozyczenia
        WHERE 
            IDWypozyczenie = @IDWypozyczenia;

        IF @KwotaWypozyczenia IS NULL
        BEGIN
            PRINT 'Nie znaleziono wypo¿yczenia o podanym ID: ' + CAST(@IDWypozyczenia AS VARCHAR);
            RETURN;
        END

        SELECT 
            @DodatkoweKoszty = ISNULL(SUM(Kwota), 0)
        FROM 
            DodatkoweKoszta
        WHERE 
            IDWypozyczenie = @IDWypozyczenia;

        SET @KwotaDoZaplaty = @KwotaWypozyczenia - @Zaliczka + @DodatkoweKoszty;

        PRINT 'Kwota do zap³aty dla wypo¿yczenia o ID ' + CAST(@IDWypozyczenia AS VARCHAR) + ' wynosi: ' + CAST(@KwotaDoZaplaty AS VARCHAR);
    END TRY
    BEGIN CATCH
        PRINT 'Wyst¹pi³ b³¹d: ' + ERROR_MESSAGE();
    END CATCH
END;
go
--EXEC DoZaplaty @IDWypozyczenia=1024;

--#####################################################################################
--Wyswietlanie Przegladów i napraw
--#####################################################################################
go
CREATE OR ALTER PROCEDURE PokazPrzegladyNaprawy
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM OPENQUERY(OracleProjekt, 'SELECT IDNaprawa, IDSprzet, Sprzet, Data, Koszt, Typ, Opis FROM V_PrzegladyNaprawy');
END;

--EXEC PokazPrzegladyNaprawy;

--EXEC('
--    BEGIN
--        PakietPrzegladyNaprawy.DodajNaprawe(
--            NULL,
--            1001,
--            ''koparka'',
--            TO_DATE(''2025-06-20'', ''YYYY-MM-DD''),
--            500,
--            ''p_Typ'',
--            ''p_Opis''
--        );
--    END;
--') AT OracleProjekt;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Tworznie procedur  Klienci 
go
GO
CREATE OR ALTER PROCEDURE DodajKlientaFirma
    @NazwaFirmy VARCHAR(100),
    @NIP VARCHAR(20),
    @KRS VARCHAR(20),
    @Telefon VARCHAR(20),
    @Email VARCHAR(50),
    @AdresFirmy VARCHAR(200),
    @KodStatus INT OUTPUT,
    @Komunikat NVARCHAR(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF EXISTS (
            SELECT 1 
            FROM Firmy 
            WHERE NIP = @NIP OR KRS = @KRS OR Email = @Email
        )
        BEGIN
            SET @KodStatus = 1;
            SET @Komunikat = 'Firma o podanym NIP, KRS lub Email ju¿ istnieje.';
            RETURN;
        END;

        DECLARE @NowaFirmaID INT;

        INSERT INTO Firmy (NazwaFirmy, NIP, KRS, Telefon, Email, AdresFirmy)
        VALUES (@NazwaFirmy, @NIP, @KRS, @Telefon, @Email, @AdresFirmy);

        SET @NowaFirmaID = SCOPE_IDENTITY();

        INSERT INTO Klienci (IDFirma, IDOsoba)
        VALUES (@NowaFirmaID, NULL);

        SET @KodStatus = 0;
        SET @Komunikat = 'Firma zosta³a dodana pomyœlnie. ID: ' + CAST(@NowaFirmaID AS NVARCHAR);
    END TRY
    BEGIN CATCH
        SET @KodStatus = ERROR_NUMBER();
        SET @Komunikat = ERROR_MESSAGE();
    END CATCH
END;

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



GO
CREATE OR ALTER PROCEDURE DodajKlientaOsoba
    @Imie VARCHAR(50),
    @Nazwisko VARCHAR(50),
    @Uprawnienia TINYINT,
    @AdresZamieszkania VARCHAR(200),
    @Telefon VARCHAR(20),
    @KodStatus INT OUTPUT,
    @Komunikat NVARCHAR(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF EXISTS (
            SELECT 1 
            FROM OsobyPrywatne 
            WHERE Imie = @Imie AND Nazwisko = @Nazwisko
        )
        BEGIN
            SET @KodStatus = 1;
            SET @Komunikat = 'Osoba o podanym imieniu i nazwisku ju¿ istnieje.';
            RETURN;
        END;

        DECLARE @NowaOsobaID INT;

        INSERT INTO OsobyPrywatne (Imie, Nazwisko, Uprawnienia, AdresZamieszkania, Telefon)
        VALUES (@Imie, @Nazwisko, @Uprawnienia, @AdresZamieszkania, @Telefon);

        SET @NowaOsobaID = SCOPE_IDENTITY();

        INSERT INTO Klienci (IDFirma, IDOsoba)
        VALUES (NULL, @NowaOsobaID);

        SET @KodStatus = 0;
        SET @Komunikat = 'Osoba prywatna zosta³a dodana pomyœlnie. ID: ' + CAST(@NowaOsobaID AS NVARCHAR);
    END TRY
    BEGIN CATCH
        SET @KodStatus = ERROR_NUMBER();
        SET @Komunikat = ERROR_MESSAGE();
    END CATCH
END;

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

go
CREATE  OR ALTER PROCEDURE AktualizujFirme
    @IDFirma INT,
    @NazwaFirmy VARCHAR(100),
    @NIP VARCHAR(20),
    @KRS VARCHAR(20),
    @Telefon VARCHAR(20),
    @Email VARCHAR(50),
    @AdresFirmy VARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Firmy
    SET
        NazwaFirmy = @NazwaFirmy,
        NIP = @NIP,
        KRS = @KRS,
        Telefon = @Telefon,
        Email = @Email,
        AdresFirmy = @AdresFirmy
    WHERE IDFirma = @IDFirma;
END;

go
CREATE OR ALTER PROCEDURE AktualizujOsobe
    @IDOsoba INT,
    @Imie VARCHAR(50),
    @Nazwisko VARCHAR(50),
    @Uprawnienia TINYINT,
    @AdresZamieszkania VARCHAR(200),
    @Telefon VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE OsobyPrywatne
    SET
        Imie = @Imie,
        Nazwisko = @Nazwisko,
        Uprawnienia = @Uprawnienia,
        AdresZamieszkania = @AdresZamieszkania,
        Telefon = @Telefon
    WHERE IDOsoba = @IDOsoba;
END;

--EXEC AktualizujFirme
--    @IDFirma = 1,
--    @NazwaFirmy = 'TechSpó³ka Zmieniona',
--    @NIP = '9999999999',
--    @KRS = '0000999999',
--    @Telefon = '111111111',
--    @Email = 'nowy@firma.pl',
--    @AdresFirmy = 'ul. Nowa 10';

--EXEC AktualizujOsobe
--    @IDOsoba = 1,
--    @Imie = 'Janusz',
--    @Nazwisko = 'Nowak',
--    @Uprawnienia = 2,
--    @AdresZamieszkania = 'ul. Nowa 2',
--    @Telefon = '123123123';
	
go

CREATE OR ALTER PROCEDURE UsunFirme
    @IDFirma INT
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM Firmy
    WHERE IDFirma = @IDFirma;
END;
go

CREATE OR ALTER PROCEDURE UsunOsobe
    @IDOsoba INT
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM OsobyPrywatne
    WHERE IDOsoba = @IDOsoba;
END;
go

CREATE OR ALTER PROCEDURE UsunKlienta
    @IDKlient INT
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM Klienci
    WHERE IDKlient = @IDKlient;
END;


--#####################################################################################
--Dodawanie kategori 
--#####################################################################################
go
CREATE OR ALTER PROCEDURE DodajKategorie
    @ID INT,
    @Nazwa NVARCHAR(100),
    @Opis NVARCHAR(400)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OraclePLSQL NVARCHAR(MAX);

    SET @OraclePLSQL = 
        'BEGIN PAKIETKATEGORIE.DodajKategorie(' 
        + CAST(@ID AS NVARCHAR(10)) + ', '''
        + REPLACE(@Nazwa, '''', '''''') + ''', '''
        + REPLACE(@Opis, '''', '''''') + '''); END;';

    EXEC (@OraclePLSQL) AT OracleProjekt;
END
GO


--EXEC dbo.DodajKategorie
--    @ID = 101, 
--    @Nazwa = N'Materialy budowlane', 
--    @Opis = N'Kategorie materialow wykorzystywanych przy budowie domow';


--#####################################################################################
--Aktualizacja kategori 
--#####################################################################################

CREATE OR ALTER PROCEDURE AktualizujKategorie
    @ID INT,
    @Nazwa NVARCHAR(100),
    @Opis NVARCHAR(400)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OraclePLSQL NVARCHAR(MAX);

    SET @OraclePLSQL = 
        'BEGIN PAKIETKATEGORIE.AktualizujKategorie(' 
        + CAST(@ID AS NVARCHAR(10)) + ', '''
        + REPLACE(@Nazwa, '''', '''''') + ''', '''
        + REPLACE(@Opis, '''', '''''') + '''); END;';

    EXEC (@OraclePLSQL) AT OracleProjekt;
END
GO

-- Przyk³ad u¿ycia:
--EXEC AktualizujKategorie @ID = 101, @Nazwa = N'AGD', @Opis = N'Zaktualizowana kategoria AGD';

--#####################################################################################
--Usuwanie kategori 
--#####################################################################################
go
CREATE OR ALTER PROCEDURE UsunKategorie
    @ID INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OraclePLSQL NVARCHAR(MAX);

    SET @OraclePLSQL = 
        'BEGIN PAKIETKATEGORIE.UsunKategorie(' 
        + CAST(@ID AS NVARCHAR(10)) + '); END;';

    EXEC (@OraclePLSQL) AT OracleProjekt;
END
GO

-- Przyk³ad u¿ycia:
--EXEC UsunKategorie @ID = 101;


--#####################################################################################
--wyswietlania kategori 
--#####################################################################################
go
CREATE OR ALTER PROCEDURE WyswietlKategorie
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX);

    SET @sql = 'SELECT * FROM V_kategorie';

    EXEC('
        SELECT * FROM OPENQUERY(OracleProjekt, ''' + @sql + ''')
    ');
END
GO

-- Przyk³ad u¿ycia:
--EXEC WyswietlKategorie ;

--#####################################################################################
--dodawanie napraw
--#####################################################################################
go
CREATE OR ALTER PROCEDURE DodajNaprawe
    @IDNaprawa INT,
    @IDSprzet INT,
    @Sprzet NVARCHAR(100),
    @Data DATETIME,
    @Koszt DECIMAL(18,2),
    @Typ NVARCHAR(100),
    @Opis NVARCHAR(400)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX);

    SET @sql = 'BEGIN PakietPrzegladyNaprawy.DodajNaprawe(' +
        CAST(@IDNaprawa AS NVARCHAR(10)) + ', ' +
        CAST(@IDSprzet AS NVARCHAR(10)) + ', ''' +
        REPLACE(@Sprzet, '''', '''''') + ''', TO_DATE(''' +
        CONVERT(VARCHAR(20), @Data, 120) + ''', ''YYYY-MM-DD HH24:MI:SS''), ' +
        CAST(@Koszt AS NVARCHAR(20)) + ', ''' +
        REPLACE(@Typ, '''', '''''') + ''', ''' +
        REPLACE(@Opis, '''', '''''') + '''); END;';

    EXEC (@sql) AT OracleProjekt;
END
GO

-- Przyk³ad u¿ycia:
EXEC DodajNaprawe 1, 1001, N'SprzetA', '2025-06-02 14:30:00', 500.00, N'Naprawa', N'Opis naprawy';

--#####################################################################################
--aktualizowanie napraw
--#####################################################################################
go
CREATE OR ALTER PROCEDURE AktualizujNaprawe
    @IDNaprawa INT,
    @IDSprzet INT,
    @Sprzet NVARCHAR(100),
    @Data DATETIME,
    @Koszt DECIMAL(18,2),
    @Typ NVARCHAR(100),
    @Opis NVARCHAR(400)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX);

    DECLARE @DataStr NVARCHAR(30) = FORMAT(@Data, 'yyyy-MM-dd HH:mm:ss');

    SET @sql = 'BEGIN PakietPrzegladyNaprawy.AktualizujNaprawe(' +
        CAST(@IDNaprawa AS NVARCHAR(10)) + ', ' +
        CAST(@IDSprzet AS NVARCHAR(10)) + ', ''' +
        REPLACE(@Sprzet, '''', '''''') + ''', TO_DATE(''' +
        @DataStr + ''', ''YYYY-MM-DD HH24:MI:SS''), ' +
        CAST(@Koszt AS NVARCHAR(20)) + ', ''' +
        REPLACE(@Typ, '''', '''''') + ''', ''' +
        REPLACE(@Opis, '''', '''''') + '''); END;';

    EXEC (@sql) AT OracleProjekt;
END
GO


-- Przyk³ad u¿ycia:
 --EXEC AktualizujNaprawe 1, 1001, N'SprzetA', '2025-06-03 10:00:00', 550.00, N'Naprawa', N'Zmiana opisu';

 --#####################################################################################
--usuwanie napraw
--#####################################################################################
go
 CREATE OR ALTER PROCEDURE UsunNaprawe
    @IDNaprawa INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX);

    SET @sql = 'BEGIN PakietPrzegladyNaprawy.UsunNaprawe(' + CAST(@IDNaprawa AS NVARCHAR(10)) + '); END;';

    EXEC (@sql) AT OracleProjekt;
END
GO

-- Przyk³ad u¿ycia:
--EXEC UsunNaprawe 1;


 --#####################################################################################
--wyswietlanie napraw
--#####################################################################################
go
CREATE OR ALTER PROCEDURE WyswietlNaprawy
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX);

    SET @sql = 'SELECT * FROM V_PrzegladyNaprawy';

    EXEC('
        SELECT * FROM OPENQUERY(OracleProjekt, ''' + @sql + ''')
    ');
END
GO

-- Przyk³ad u¿ycia:
-- EXEC WyswietlNaprawy;




--OpenRowSet dla excela


--SELECT *
--FROM OPENQUERY(ExcelWypozyczeniaArch, 'SELECT * FROM [Wypozyczenia_Archiwalne$]');

--INSERT INTO OPENQUERY(ExcelWypozyczeniaArch, 'SELECT * FROM [Wypozyczenia_Archiwalne$]')
--(IDWypozyczenie, IDKlient, IDSprzet, DataWypozyczenia, DataZwrotu, Kwota, Zaliczka)
--VALUES (1, 1001, 501, '2023-01-10', '2023-01-10', 150, 50);

--OpenRowSet dla excela

--SELECT *
--FROM OPENQUERY(ExcelRezerwacjeArch, 'SELECT * FROM [Rezerwacje_Archiwalne$]');

--INSERT INTO OPENQUERY(ExcelRezerwacjeArch, 'SELECT * FROM [Rezerwacje_Archiwalne$]')
--(IDRezerwacja, IDKlient, IDSprzet, data_rezerwacji, data_startu, data_konca, status)
--VALUES (1, 1001, 501, '2023-04-01', '2023-04-05', '2023-04-10', 'Zakoñczona');

go


--##pomocnicza Procedura, która wyeksportowywuje wypozyczenia i rezerwacje do dwoch oddzielnych skoroszytów excel (w rezerwacjach status jest na zrealizowano)

go
CREATE OR ALTER PROCEDURE wyeksportowanieWypozyczenRezerwacjiDoExcel
AS
BEGIN
    SET NOCOUNT ON;
	--wstawnienie do wypozyczen arch
    INSERT INTO OPENQUERY(ExcelWypozyczeniaArch, 'SELECT * FROM [Wypozyczenia_Archiwalne$]')
    (
        IDWypozyczenie,
        IDKlient,
        IDSprzet,
        DataWypozyczenia,
        DataZwrotu,
        Kwota,
        Zaliczka
    )
    SELECT
        IDWypozyczenie,
        IDKlient,
        IDSprzet,
        CONVERT(varchar, DataWypozyczenia, 23),
        CONVERT(varchar, DataZwrotu, 23),
        Kwota,
        Zaliczka
    FROM Wypozyczenia
    WHERE DataZwrotu IS NOT NULL
      AND DataZwrotu < CAST(GETDATE() AS DATE);

	  --wstawnienie do rezerwacji arch
	 INSERT INTO OPENQUERY(ExcelRezerwacjeArch, 'SELECT * FROM [Rezerwacje_Archiwalne$]')
    (
        IDRezerwacja,
        IDKlient,
        IDSprzet,
        data_rezerwacji,
        data_startu,
        data_konca,
        status
    )
    SELECT
        IDRezerwacja,
        IDKlient,
        IDSprzet,
        CONVERT(varchar, data_rezerwacji, 23),
        CONVERT(varchar, data_startu, 23),
        CONVERT(varchar, data_konca, 23),
        'Zrealizowano'
    FROM Rezerwacje
    WHERE data_konca < CAST(GETDATE() AS DATE);
END;
GO

--EXEC dbo.wyeksportowanieWypozyczenRezerwacjiDoExcel;

go
--Procedura w której usuwam masowo przeterminowane w rezerwacje i wypozyczenia, i przezylam do excela 
CREATE OR ALTER PROCEDURE dbo.usunieciePrzeterminowychDanychIEksportDoExecl
AS
BEGIN
    SET NOCOUNT ON;
	EXEC dbo.wyeksportowanieWypozyczenRezerwacjiDoExcel;

    BEGIN TRANSACTION;

    BEGIN TRY
        -- Usuwanie przeterminowanych wypo¿yczeñ
        DELETE FROM Wypozyczenia
        WHERE DataZwrotu IS NOT NULL
          AND DataZwrotu < CAST(GETDATE() AS DATE);

        -- Usuwanie przeterminowanych rezerwacji
        DELETE FROM Rezerwacje
        WHERE data_konca < CAST(GETDATE() AS DATE);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

--EXEC dbo.usunieciePrzeterminowychDanychIEksportDoExecl;

go
--##pomocnicza procedura do wyeksporotwania konkretnych danych z wypozyczen za pomoca ID
CREATE OR ALTER PROCEDURE wyeksportowanieKonkretnychWypozyczenDoExcel_ByID
    @IDWypozyczenie INT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO OPENQUERY(ExcelWypozyczeniaArch, 'SELECT * FROM [Wypozyczenia_Archiwalne$]')
    (
        IDWypozyczenie,
        IDKlient,
        IDSprzet,
        DataWypozyczenia,
        DataZwrotu,
        Kwota,
        Zaliczka
    )
    SELECT
        IDWypozyczenie,
        IDKlient,
        IDSprzet,
        CONVERT(varchar, DataWypozyczenia, 23),
        CONVERT(varchar, DataZwrotu, 23),
        Kwota,
        Zaliczka
    FROM Wypozyczenia
    WHERE IDWypozyczenie = @IDWypozyczenie;
END;
GO

--EXEC dbo.wyeksportowanieKonkretnychWypozyczenDoExcel_ByID @IDWypozyczenie = 123;

go
--procedura usuwaj¹ca konkrete dane z wypozyczen, i jednoczeœnie wyeksportowywuje konkretnych dane do excela 
CREATE OR ALTER PROCEDURE usunWypozyczenieID
    @ID INT
AS
BEGIN
    SET NOCOUNT ON;
	EXEC dbo.wyeksportowanieKonkretnychWypozyczenDoExcel_ByID @IDWypozyczenie =  @ID;

    DELETE FROM Wypozyczenia
    WHERE IDWypozyczenie =  @ID;
END;
GO

--select * from Wypozyczenia

--EXEC dbo.usunWypozyczenieID @ID = 20

go
--##pomocnicza procedura do wyeksporotwania konkretnych danych z rezerwacji za pomoca ID ustwia status na anulowane
CREATE OR ALTER PROCEDURE wyeksportowanieKonkretnychRezerwacjiDoExcel_ByID
    @IDRezerwacja INT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO OPENQUERY(ExcelRezerwacjeArch, 'SELECT * FROM [Rezerwacje_Archiwalne$]')
    (
        IDRezerwacja,
        IDKlient,
        IDSprzet,
        data_rezerwacji,
        data_startu,
        data_konca,
        status
    )
    SELECT
        IDRezerwacja,
        IDKlient,
        IDSprzet,
        CONVERT(varchar, data_rezerwacji, 23),
        CONVERT(varchar, data_startu, 23),
        CONVERT(varchar, data_konca, 23),
        'Anulowana'
    FROM Rezerwacje
    WHERE IDRezerwacja = @IDRezerwacja;
END;
GO

--procedura usuwaj¹ca konkrete dane z rezerwacji, i jednoczeœnie wyeksportowywuje konkretnych dane do excela 
CREATE OR ALTER PROCEDURE usunRezerwacjeID
    @ID INT
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.wyeksportowanieKonkretnychRezerwacjiDoExcel_ByID @IDRezerwacja = @ID;

    DELETE FROM Rezerwacje
    WHERE IDRezerwacja = @ID;
END;
GO

CREATE OR ALTER PROCEDURE UsunRezerwacjeIWyeksportuj
    @IDRezerwacja INT,
    @KodStatus INT OUTPUT,
    @Komunikat NVARCHAR(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Rezerwacje WHERE IDRezerwacja = @IDRezerwacja)
    BEGIN
        SET @KodStatus = 1;
        SET @Komunikat = 'Rezerwacja o podanym ID nie istnieje.';
        RETURN;
    END

    BEGIN TRY
        EXEC dbo.wyeksportowanieKonkretnychRezerwacjiDoExcel_ByID @IDRezerwacja = @IDRezerwacja;

        DELETE FROM Rezerwacje WHERE IDRezerwacja = @IDRezerwacja;

        SET @KodStatus = 0;
        SET @Komunikat = 'Rezerwacja zosta³a zarchiwizowana i usuniêta.';
    END TRY
    BEGIN CATCH
        SET @KodStatus = 2;
        SET @Komunikat = 'B³¹d podczas operacji: ' + ERROR_MESSAGE();
    END CATCH
END;

go
CREATE OR ALTER PROCEDURE UsunWypozyczenieIWyeksportuj
    @IDWypozyczenie INT,
    @KodStatus INT OUTPUT,
    @Komunikat NVARCHAR(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Wypozyczenia WHERE IDWypozyczenie = @IDWypozyczenie)
    BEGIN
        SET @KodStatus = 1;
        SET @Komunikat = 'Wypo¿yczenie o podanym ID nie istnieje.';
        RETURN;
    END

    BEGIN TRY
        EXEC dbo.wyeksportowanieKonkretnychWypozyczenDoExcel_ByID @IDWypozyczenie = @IDWypozyczenie;

        DELETE FROM Wypozyczenia WHERE IDWypozyczenie = @IDWypozyczenie;

        SET @KodStatus = 0;
        SET @Komunikat = 'Wypo¿yczenie zosta³o zarchiwizowane i usuniête.';
    END TRY
    BEGIN CATCH
        SET @KodStatus = 2;
        SET @Komunikat = 'Wyst¹pi³ b³¹d: ' + ERROR_MESSAGE();
    END CATCH
END;




--#####################################################################################
-- Procedura rozproszona
--#####################################################################################
GO
CREATE OR ALTER PROCEDURE dodajCzasNaprawyDoZajeteDni
    @N VARCHAR(100),
    @O VARCHAR(500),
    @K DECIMAL(10,2),
    @idw INT
AS
BEGIN
    SET XACT_ABORT ON;
    SET NOCOUNT ON;

    DECLARE 
        @v_WolnyDzien DATE,
        @v_id_sprzet INT,
        @sqlOracle NVARCHAR(MAX),
		@sql NVARCHAR(MAX),
        @formattedDate VARCHAR(20);

    BEGIN DISTRIBUTED TRANSACTION;

    BEGIN TRY
        -- 1. Dodanie kosztu w SQL Server
        EXEC DodajDodatkowyKoszt	
            @Nazwa = @N,
            @Opis = @O,
            @Kwota = @K,
            @IDWypozyczenie = @idw;

        SELECT @v_id_sprzet = IDSprzet 
        FROM Wypozyczenia 
        WHERE IDWypozyczenie = @idw;

		SET @sql = N'
    SELECT @v_WolnyDzien = WolnyDzien 
    FROM OPENQUERY(OracleProjekt, 
        ''SELECT WolnyDzien 
          FROM TABLE(ZnajdzWolnyDzien_F( ' +  CAST(@v_id_sprzet AS NVARCHAR(7)) +' , SYSDATE))'')';
 
	EXEC sp_executesql @sql, N'@v_WolnyDzien DATE OUTPUT', @v_WolnyDzien OUTPUT;

        -- 4. Formatowanie daty do formatu Oracle
        SET @formattedDate = CONVERT(CHAR(10), @v_WolnyDzien, 120);  -- 'YYYY-MM-DD'

        -- 5. Budowa zapytania PL/SQL jako tekstu
        SET @sqlOracle = '
			BEGIN
			PAKIETZAJETEDNI.DodajZajetyDzien(
			p_Data => TO_DATE(''' + FORMAT(@v_WolnyDzien , 'yyyy-MM-dd') + ''', ''YYYY-MM-DD''),
			p_IDSprzet => ' + CAST(@v_id_sprzet AS NVARCHAR(20)) + '
			);
			END;';

        -- 6. Dynamiczne wykonanie w Oracle
        EXEC (@sqlOracle) AT OracleProjekt;
		
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;

--test:
--EXEC dodajCzasNaprawyDoZajeteDni
--    @N = 'Naprawa mechaniczna',
--    @O = 'Zatarty silnik',
--    @K = 1500.00,
--    @idw = 26;
--######################################################




--######################################################
--przenies rezerwacje do wypozyczen
--######################################################
GO
CREATE OR ALTER PROCEDURE wyeksportowanieKonkretnychRezerwacjiDoExcel_ByID_zTekstem
    @IDRezerwacja INT,
	@jestAnulowana INT

AS
BEGIN
    SET NOCOUNT ON;

	DECLARE @wiadomosc VARCHAR(30) = '';

    IF @jestAnulowana = 1
        SET @wiadomosc = 'Odrzucona';
    ELSE
        SET @wiadomosc = 'Zaakceptowana';

		

    INSERT INTO OPENQUERY(ExcelRezerwacjeArch, 'SELECT * FROM [Rezerwacje_Archiwalne$]')
    (
        IDRezerwacja,
        IDKlient,
        IDSprzet,
        data_rezerwacji,
        data_startu,
        data_konca,
        status
    )
    SELECT
        IDRezerwacja,
        IDKlient,
        IDSprzet,
        CONVERT(varchar, data_rezerwacji, 23),
        CONVERT(varchar, data_startu, 23),
        CONVERT(varchar, data_konca, 23),
        @wiadomosc
    FROM Rezerwacje
    WHERE IDRezerwacja = @IDRezerwacja;
END;
GO


GO
CREATE OR ALTER PROCEDURE PrzetworzDzisiejszeRezerwacje
    @IDRezerwacji INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IDKlient INT,
            @IDSprzet INT,
            @DataWypozyczenia DATE,
            @DataZwrotu DATE,
            @KodStatus INT,
            @Komunikat NVARCHAR(200),
            @Log NVARCHAR(MAX) = '';

    CREATE TABLE #RezerwacjeDoPrzetworzenia (
        IDRezerwacja INT,
        IDKlient INT,
        IDSprzet INT,
        DataWypozyczenia DATE,
        DataZwrotu DATE
    );

    IF @IDRezerwacji IS NOT NULL
    BEGIN
        INSERT INTO #RezerwacjeDoPrzetworzenia
        SELECT IDRezerwacja, IDKlient, IDSprzet, data_startu, data_konca
        FROM Rezerwacje
        WHERE IDRezerwacja = @IDRezerwacji;
    END
    ELSE
    BEGIN
        INSERT INTO #RezerwacjeDoPrzetworzenia
        SELECT IDRezerwacja, IDKlient, IDSprzet, data_startu, data_konca
        FROM Rezerwacje
        WHERE data_startu = CAST(GETDATE() AS DATE);
    END

    DECLARE rezerwacje_cursor CURSOR FOR
    SELECT IDRezerwacja, IDKlient, IDSprzet, DataWypozyczenia, DataZwrotu
    FROM #RezerwacjeDoPrzetworzenia;

    OPEN rezerwacje_cursor;

    FETCH NEXT FROM rezerwacje_cursor INTO @IDRezerwacji, @IDKlient, @IDSprzet, @DataWypozyczenia, @DataZwrotu;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC dbo.wyeksportowanieKonkretnychRezerwacjiDoExcel_ByID_zTekstem 
            @IDRezerwacja = @IDRezerwacji, 
            @jestAnulowana = 0;

        EXEC UsunRezerwacje
            @IDRezerwacji = @IDRezerwacji,
            @KodStatus = @KodStatus OUTPUT,
            @Komunikat = @Komunikat OUTPUT;

        IF @KodStatus = 0
        BEGIN
            EXEC DodajWypozyczenie
                @IDKlient = @IDKlient,
                @IDSprzet = @IDSprzet,
                @DataWypozyczenia = @DataWypozyczenia,
                @DataZwrotu = @DataZwrotu,
                @KodStatus = @KodStatus OUTPUT,
                @Komunikat = @Komunikat OUTPUT;

            IF @KodStatus = 0
            BEGIN
                SET @Log += 'Rezerwacja ID ' + CAST(@IDRezerwacji AS NVARCHAR) + ' przeniesiona do wypo¿yczeñ. ' + @Komunikat + CHAR(13);
            END
            ELSE
            BEGIN
                SET @Log += 'B³¹d przy dodawaniu wypo¿yczenia z rezerwacji ID ' + CAST(@IDRezerwacji AS NVARCHAR) + ': ' + @Komunikat + CHAR(13);
            END
        END
        ELSE
        BEGIN
            SET @Log += 'B³¹d przy usuwaniu rezerwacji ID ' + CAST(@IDRezerwacji AS NVARCHAR) + ': ' + @Komunikat + CHAR(13);
        END

        FETCH NEXT FROM rezerwacje_cursor INTO @IDRezerwacji, @IDKlient, @IDSprzet, @DataWypozyczenia, @DataZwrotu;
    END;

    CLOSE rezerwacje_cursor;
    DEALLOCATE rezerwacje_cursor;

    DROP TABLE #RezerwacjeDoPrzetworzenia;

    PRINT @Log;
END;


go
CREATE OR ALTER PROCEDURE PobierzWolneDniSprzetu
    @IDSprzet INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DataStart DATE = CAST(GETDATE() AS DATE);
    DECLARE @DataKoniec DATE = DATEADD(MONTH, 3, @DataStart);

    DECLARE @sql NVARCHAR(MAX);
    SET @sql = N'
        SELECT IDZajeteDni, Data, IDSprzet
        FROM OPENQUERY(OracleProjekt,
            ''
            SELECT IDZajeteDni, Data, IDSprzet
            FROM VW_ZajeteDniSprzetu
            ''
        )';

    CREATE TABLE #ZajeteDniSprzetu (
        IDZajeteDni INT,
        Data DATE,
        IDSprzet INT
    );

    INSERT INTO #ZajeteDniSprzetu (IDZajeteDni, Data, IDSprzet)
    EXEC (@sql);

    CREATE TABLE #ZajeteDni (Data DATE);

    INSERT INTO #ZajeteDni (Data)
    SELECT Data
    FROM #ZajeteDniSprzetu
    WHERE IDSprzet = @IDSprzet
      AND Data BETWEEN @DataStart AND @DataKoniec;

    CREATE TABLE #WszystkieDni (Data DATE);

    DECLARE @TmpData DATE = @DataStart;
    WHILE @TmpData <= @DataKoniec
    BEGIN
        INSERT INTO #WszystkieDni (Data) VALUES (@TmpData);
        SET @TmpData = DATEADD(DAY, 1, @TmpData);
    END

    SELECT Data AS WolnyDzien
    FROM #WszystkieDni
    WHERE Data NOT IN (SELECT Data FROM #ZajeteDni)
    ORDER BY Data;

    DROP TABLE #ZajeteDniSprzetu;
    DROP TABLE #ZajeteDni;
    DROP TABLE #WszystkieDni;
END;



--EXEC PobierzWolneDniSprzetu @IDSprzet = 1001;

go

CREATE OR ALTER PROCEDURE dbo.PobierzMaszynyZZajetymiDniami
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM OPENQUERY(OracleProjekt, 'SELECT * FROM VW_Sprzet_Z_ZajetymiDniami');
END;

go
CREATE OR ALTER PROCEDURE dbo.PobierzWszystkieMaszyny
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM OPENQUERY(OracleProjekt, 'SELECT * FROM V_SprzetBudowlany');
END;

go
CREATE OR ALTER PROCEDURE dbo.PobierzMaszynyZKategoria
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM OPENQUERY(OracleProjekt, 'SELECT * FROM VW_Sprzet_Z_Kategoria');
END;

