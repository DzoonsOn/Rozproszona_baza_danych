--CREATE USER Pracownik IDENTIFIED BY Pracownik123;
--GRANT CREATE SESSION TO Pracownik;
--GRANT CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, CREATE SEQUENCE TO Pracownik;
--ALTER USER Pracownik DEFAULT TABLESPACE users;
--ALTER USER Pracownik TEMPORARY TABLESPACE temp;
--GRANT CREATE TYPE TO Pracownik;
--GRANT CREATE ANY TYPE TO Pracownik;
--GRANT EXECUTE ANY TYPE TO Pracownik;
--GRANT CREATE TABLE TO Pracownik;
--GRANT CREATE ANY TABLE TO Pracownik;
--GRANT UNLIMITED TABLESPACE TO Pracownik;
--GRANT RESOURCE TO Pracownik;
--GRANT CREATE TRIGGER TO Pracownik;
--GRANT UNLIMITED TABLESPACE TO Pracownik;
--GRANT CREATE SESSION TO Pracownik;

--##############################################################################################################################################################################
--##############################################################################################################################################################################
--USUWANIE ISTNIEJ�CYCH TABELI TYPOW SEKWENCJI WIDOKOW
--##############################################################################################################################################################################
--##############################################################################################################################################################################
BEGIN
  FOR cur_rec IN (SELECT object_name, object_type 
                  FROM   user_objects
                  WHERE  object_type IN ('TABLE', 'TYPE','SEQUENCE', 'VIEW')) LOOP
    BEGIN
      IF cur_rec.object_type = 'TABLE' THEN
        IF instr(cur_rec.object_name, 'STORE') = 0 then
          EXECUTE IMMEDIATE 'DROP ' || cur_rec.object_type || ' "' || cur_rec.object_name || '" CASCADE CONSTRAINTS';
        END IF;
      ELSIF cur_rec.object_type = 'TYPE' THEN
        EXECUTE IMMEDIATE 'DROP ' || cur_rec.object_type || ' "' || cur_rec.object_name || '" FORCE';
      ELSE
        EXECUTE IMMEDIATE 'DROP ' || cur_rec.object_type || ' "' || cur_rec.object_name || '"';
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.put_line('FAILED: DROP ' || cur_rec.object_type || ' "' || cur_rec.object_name || '"');
    END;
  END LOOP;
END;
/

--##############################################################################################################################################################################
--##############################################################################################################################################################################
--TWORZENIE TYPOW I TABEL
--##############################################################################################################################################################################
--##############################################################################################################################################################################

CREATE OR REPLACE TYPE TypKategoria AS OBJECT (
    IDKategoria NUMBER,
    Nazwa VARCHAR2(100),
    Opis VARCHAR2(200),
    MEMBER PROCEDURE Init(ID IN NUMBER, Nazwa IN VARCHAR2, Opis IN VARCHAR2)
);
/
CREATE OR REPLACE TYPE BODY TypKategoria AS
    MEMBER PROCEDURE Init(ID IN NUMBER, Nazwa IN VARCHAR2, Opis IN VARCHAR2) IS
    BEGIN
        Self.IDKategoria := ID;
        Self.Nazwa := Nazwa;
        Self.Opis := Opis;
    END;
END;
/

CREATE OR REPLACE TYPE TypKategoriaTable AS TABLE OF TypKategoria;
/

CREATE TABLE Kategorie OF TypKategoria (
    IDKategoria PRIMARY KEY
);
/

CREATE OR REPLACE TYPE TypSprzet AS OBJECT (
    IDSprzet NUMBER,
    NazwaSprzetu VARCHAR2(100),
    Kategoria TypKategoriaTable,
    Uprawnienia NUMBER(1),
    Status VARCHAR2(50),
    KwotaZaDzien NUMBER
);
/

CREATE TABLE SprzetBudowlany OF TypSprzet (
    IDSprzet PRIMARY KEY
) NESTED TABLE Kategoria STORE AS KategorieNestedTable;
/

CREATE OR REPLACE TYPE TypZajeteDni AS OBJECT (
    IDZajeteDni NUMBER,
    Data DATE,
    RefSprzet REF TypSprzet 
);
/

CREATE TABLE ZajeteDniSprzetu OF TypZajeteDni (
    CONSTRAINT pk_zajete_dni PRIMARY KEY (IDZajeteDni)
);
/

CREATE OR REPLACE TYPE TypPrzegladyNaprawy AS OBJECT (
    IDNaprawa NUMBER,
    RefSprzet REF TypSprzet,
    Sprzet VARCHAR2(100),
    Data DATE,
    Koszt NUMBER(10, 2),
    Typ VARCHAR2(50),
    Opis VARCHAR2(500),
    MEMBER PROCEDURE DodajNaprawe(ID IN NUMBER,IDSprzet IN REF TypSprzet,SprzetNaprawa IN VARCHAR2, DataNaprawy IN DATE, KosztNaprawy IN NUMBER, TypNaprawy IN VARCHAR2, OpisNaprawy IN VARCHAR2)
);
/

CREATE OR REPLACE TYPE BODY TypPrzegladyNaprawy AS
    MEMBER PROCEDURE DodajNaprawe(ID IN NUMBER,IDSprzet IN REF TypSprzet,SprzetNaprawa IN VARCHAR2, DataNaprawy IN DATE, KosztNaprawy IN NUMBER, TypNaprawy IN VARCHAR2, OpisNaprawy IN VARCHAR2) 
    IS
    BEGIN
        SELF.IDNaprawa := ID;
        SELF.RefSprzet := IDSprzet;
        SELF.Sprzet := SprzetNaprawa;
        SELF.Data := DataNaprawy;
        SELF.Koszt := KosztNaprawy;
        SELF.Typ := TypNaprawy;
        SELF.Opis := OpisNaprawy;
    END;
END;
/

CREATE TABLE PrzegladyNaprawy OF TypPrzegladyNaprawy (
    IDNaprawa PRIMARY KEY
);
/
--##############################################################################################################################################################################
--##############################################################################################################################################################################
--TWORZENIE SEKWENCJI
--##############################################################################################################################################################################
--##############################################################################################################################################################################

CREATE SEQUENCE SEQ_Kategorie
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;
/
CREATE SEQUENCE SEQ_SprzetBudowlany
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;
/
CREATE SEQUENCE SEQ_ZajeteDni
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;
/
CREATE SEQUENCE SEQ_PrzegladyNaprawy
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

/


--##############################################################################################################################################################################
--##############################################################################################################################################################################
--TRIGERY
--##############################################################################################################################################################################
--##############################################################################################################################################################################
----------------------------------------------------------------------------------------------------------------------
-- Tworzenie trigeru do dodawnia id  ----------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_Kategorie_ID
BEFORE INSERT ON Kategorie
FOR EACH ROW
BEGIN
  IF :NEW.IDKategoria IS NULL THEN
    SELECT SEQ_Kategorie.NEXTVAL INTO :NEW.IDKategoria FROM DUAL;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_SprzetBudowlany_ID
BEFORE INSERT ON SprzetBudowlany
FOR EACH ROW
BEGIN
  IF :NEW.IDSprzet IS NULL THEN
    SELECT SEQ_SprzetBudowlany.NEXTVAL INTO :NEW.IDSprzet FROM DUAL;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_ZajeteDni_ID
BEFORE INSERT ON ZajeteDniSprzetu
FOR EACH ROW
BEGIN
  IF :NEW.IDZajeteDni IS NULL THEN
    SELECT SEQ_ZajeteDni.NEXTVAL INTO :NEW.IDZajeteDni FROM DUAL;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_PrzegladyNaprawy_ID
BEFORE INSERT ON PrzegladyNaprawy
FOR EACH ROW
BEGIN
  IF :NEW.IDNaprawa IS NULL THEN
    SELECT SEQ_PrzegladyNaprawy.NEXTVAL INTO :NEW.IDNaprawa FROM DUAL;
  END IF;
END;
/
--#################################################
----------------------------------------------------------------------------------------------------------------------
-- Tworzenie Pakietu dla obiketow kategorie 
----------------------------------------------------------------------------------------------------------------------

create or replace PACKAGE PAKIETKATEGORIE AS 

    PROCEDURE DodajKategorie(ID IN NUMBER, Nazwa IN VARCHAR2, Opis IN VARCHAR2);
    PROCEDURE AktualizujKategorie(ID IN NUMBER, Nazwa IN VARCHAR2, Opis IN VARCHAR2);
    PROCEDURE WyswietlKategorie(ID IN NUMBER);
    PROCEDURE UsunKategorie(ID IN NUMBER);
    
END PAKIETKATEGORIE;
/
create or replace PACKAGE BODY PAKIETKATEGORIE AS 

    PROCEDURE DodajKategorie(ID IN NUMBER, Nazwa IN VARCHAR2, Opis IN VARCHAR2) IS
    BEGIN
        INSERT INTO Kategorie (IDKategoria, Nazwa, Opis) VALUES (ID, Nazwa, Opis);
        
        DBMS_OUTPUT.PUT_LINE('Dodano kategori�: ' || Nazwa);
        
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('B��d podczas dodawania kategorii: ' || SQLERRM);
    END DodajKategorie;

    PROCEDURE AktualizujKategorie(ID IN NUMBER, Nazwa IN VARCHAR2, Opis IN VARCHAR2) IS
    BEGIN
        UPDATE Kategorie SET Nazwa = Nazwa, Opis = Opis WHERE IDKategoria = ID;
        IF SQL%ROWCOUNT > 0 THEN
            DBMS_OUTPUT.PUT_LINE('Zaktualizowano kategori�: ' || Nazwa);
        ELSE 
            DBMS_OUTPUT.PUT_LINE('Nie znaleziono kategorii o ID: ' || ID);
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('B��d podczas aktualizacji kategorii: ' || SQLERRM);
    END AktualizujKategorie;

    PROCEDURE WyswietlKategorie(ID IN NUMBER) IS
        v_Nazwa VARCHAR2(100); v_Opis VARCHAR2(200);
    BEGIN
        SELECT Nazwa, Opis INTO v_Nazwa, v_Opis FROM Kategorie WHERE IDKategoria = ID;
        
        DBMS_OUTPUT.PUT_LINE('Kategoria ID ' || ID || ': ' || v_Nazwa || ' - ' || v_Opis);
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Brak kategorii o ID: ' || ID);
        WHEN OTHERS THEN 
            DBMS_OUTPUT.PUT_LINE('B��d podczas wy�wietlania kategorii: ' || SQLERRM);
    END WyswietlKategorie;

    PROCEDURE UsunKategorie(ID IN NUMBER) IS
    BEGIN
        DELETE FROM Kategorie WHERE IDKategoria = ID;
        IF SQL%ROWCOUNT > 0 THEN
            DBMS_OUTPUT.PUT_LINE('Usuni�to kategori� o ID: ' || ID);
        ELSE 
            DBMS_OUTPUT.PUT_LINE('Nie znaleziono kategorii o ID: ' || ID);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('B��d podczas usuwania kategorii: ' || SQLERRM);
    END UsunKategorie;

END PAKIETKATEGORIE;
/


--##############################################################################################################################################################################
--##############################################################################################################################################################################
--PAKIETY
--##############################################################################################################################################################################
--##############################################################################################################################################################################

----------------------------------------------------------------------------------------------------------------------
-- Tworzenie Pakietu dla obiektu sprzetu budowlanego
----------------------------------------------------------------------------------------------------------------------
create or replace PACKAGE PAKIETSPRZETBUDOWLANY AS

    PROCEDURE DodajSprzet(ID IN NUMBER, Nazwa IN VARCHAR2, Kategoria IN TypKategoriaTable, Uprawnienia IN Number, Status IN VARCHAR2, Kwota IN NUMBER);
    PROCEDURE AktualizujSprzet(ID IN NUMBER, Nazwa IN VARCHAR2, Kategoria IN TypKategoriaTable, Uprawnienia IN Number, Status IN VARCHAR2, Kwota IN NUMBER);
    PROCEDURE WyswietlSprzet(ID IN NUMBER);
    PROCEDURE WyswietlWszystkieSprzety;
    PROCEDURE UsunSprzet(ID IN NUMBER);
    
END PAKIETSPRZETBUDOWLANY;
/
create or replace PACKAGE BODY PAKIETSPRZETBUDOWLANY AS

    PROCEDURE DodajSprzet(ID IN NUMBER, Nazwa IN VARCHAR2, Kategoria IN TypKategoriaTable, Uprawnienia IN Number, Status IN VARCHAR2, Kwota IN NUMBER) IS
    BEGIN
        INSERT INTO SprzetBudowlany (IDSprzet, NazwaSprzetu, Kategoria, Uprawnienia, Status, KwotaZaDzien) 
        VALUES (ID, Nazwa, Kategoria, Uprawnienia, Status, Kwota); 
        
        DBMS_OUTPUT.PUT_LINE('Dodano sprz�t budowlany: ' || Nazwa);
        
    EXCEPTION
        WHEN OTHERS THEN 
            DBMS_OUTPUT.PUT_LINE('B��d podczas dodawania sprz�tu: ' || SQLERRM);
    END DodajSprzet;

    PROCEDURE AktualizujSprzet(ID IN NUMBER, Nazwa IN VARCHAR2, Kategoria IN TypKategoriaTable, Uprawnienia IN Number, Status IN VARCHAR2, Kwota IN NUMBER) IS
    BEGIN
        UPDATE SprzetBudowlany SET NazwaSprzetu = Nazwa, Kategoria = Kategoria, Uprawnienia = Uprawnienia, Status = Status, KwotaZaDzien = Kwota 
        WHERE IDSprzet = ID;
        IF SQL%ROWCOUNT > 0 THEN 
            DBMS_OUTPUT.PUT_LINE('Zaktualizowano sprz�t: ' || Nazwa);
        ELSE 
            DBMS_OUTPUT.PUT_LINE('Nie znaleziono sprz�tu o ID: ' || ID);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('B��d podczas aktualizacji sprz�tu: ' || SQLERRM);
    END AktualizujSprzet;

    PROCEDURE WyswietlSprzet(ID IN NUMBER) IS
        v_Nazwa VARCHAR2(100); v_Uprawnienia Number; v_Status VARCHAR2(50); v_Kwota NUMBER; v_Kategoria TypKategoriaTable;
    BEGIN
        SELECT NazwaSprzetu, Uprawnienia, Status, KwotaZaDzien, Kategoria INTO v_Nazwa, v_Uprawnienia, v_Status, v_Kwota, v_Kategoria 
        FROM SprzetBudowlany WHERE IDSprzet = ID;
        
        DBMS_OUTPUT.PUT_LINE('Sprz�t: ' || v_Nazwa || ', Uprawnienia: ' || v_Uprawnienia || ', Status: ' || v_Status || ', Kwota za dzie�: ' || v_Kwota);
        
        FOR i IN 1 .. v_Kategoria.COUNT LOOP
            DBMS_OUTPUT.PUT_LINE('Kategoria: ' || v_Kategoria(i).Nazwa);
        END LOOP;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN 
            DBMS_OUTPUT.PUT_LINE('Brak sprz�tu o ID: ' || ID);
        WHEN OTHERS THEN 
            DBMS_OUTPUT.PUT_LINE('B��d podczas wy�wietlania sprz�tu: ' || SQLERRM);
    END WyswietlSprzet;
    
    
    PROCEDURE WyswietlWszystkieSprzety IS
        CURSOR c_Sprzet IS
            SELECT IDSprzet, NazwaSprzetu, Uprawnienia, Status, KwotaZaDzien, CAST(Kategoria AS TypKategoriaTable) AS Kategoria
            FROM SprzetBudowlany;
    
        v_IDSprzet NUMBER;
        v_Nazwa VARCHAR2(100);
        v_Uprawnienia NUMBER;
        v_Status VARCHAR2(50);
        v_Kwota NUMBER;
        v_Kategoria TypKategoriaTable;
    BEGIN
        OPEN c_Sprzet;
        LOOP
            FETCH c_Sprzet INTO v_IDSprzet, v_Nazwa, v_Uprawnienia, v_Status, v_Kwota, v_Kategoria;
            EXIT WHEN c_Sprzet%NOTFOUND;
            
            DBMS_OUTPUT.PUT_LINE('IDSprz�t: ' || v_IDSprzet || 
                                 ', Sprz�t: ' || v_Nazwa || 
                                 ', Uprawnienia: ' || v_Uprawnienia || 
                                 ', Status: ' || v_Status || 
                                 ', Kwota za dzie�: ' || v_Kwota);
    
            IF v_Kategoria IS NOT NULL THEN
                FOR i IN 1 .. v_Kategoria.COUNT LOOP
                    DBMS_OUTPUT.PUT_LINE('   Kategoria: ' || v_Kategoria(i).Nazwa);
                END LOOP;
            ELSE
                DBMS_OUTPUT.PUT_LINE('   Brak kategorii dla tego sprz�tu.');
            END IF;
        END LOOP;
        CLOSE c_Sprzet;
    
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('B��d podczas wy�wietlania sprz�t�w: ' || SQLERRM);
    END WyswietlWszystkieSprzety;
    

    PROCEDURE UsunSprzet(ID IN NUMBER) IS
    BEGIN
        DELETE FROM SprzetBudowlany WHERE IDSprzet = ID;
        IF SQL%ROWCOUNT > 0 THEN 
            DBMS_OUTPUT.PUT_LINE('Usuni�to sprz�t o ID: ' || ID); 
        ELSE 
            DBMS_OUTPUT.PUT_LINE('Nie znaleziono sprz�tu o ID: ' || ID); 
        END IF;
    EXCEPTION
        WHEN OTHERS THEN 
            DBMS_OUTPUT.PUT_LINE('B��d podczas usuwania sprz�tu: ' || SQLERRM);
    END UsunSprzet;

END PAKIETSPRZETBUDOWLANY;
/

---------------------------------------------------------------------------------------------------------------------
-- Tworzenie Pakietu dla obiket�w zajetedni ----------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
create or replace PACKAGE PAKIETZAJETEDNI AS
    
    PROCEDURE DodajZajetyDzien(p_IDZajeteDni IN NUMBER,p_Data IN DATE,p_IDSprzet number);
    PROCEDURE WyswietlZajeteDni(p_IDSprzet IN NUMBER);
    PROCEDURE UsunZajetyDzien(p_IDZajeteDni IN NUMBER);
    PROCEDURE WyswietlWolneTerminy(p_IDSprzet IN NUMBER);
    
END PAKIETZAJETEDNI;
/

create or replace PACKAGE BODY PAKIETZAJETEDNI AS
    PROCEDURE DodajZajetyDzien(
        p_IDZajeteDni IN NUMBER,
        p_Data IN DATE,
        p_IDSprzet IN NUMBER
    ) AS
        v_RefSprzet REF TypSprzet;
    BEGIN
        SELECT REF(s) INTO v_RefSprzet
        FROM SprzetBudowlany s
        WHERE s.IDSprzet = p_IDSprzet;

        INSERT INTO ZajeteDniSprzetu (IDZajeteDni, Data, RefSprzet)
        VALUES (p_IDZajeteDni, p_Data, v_RefSprzet);
        COMMIT;
    END DodajZajetyDzien;

    PROCEDURE WyswietlZajeteDni(
        p_IDSprzet IN NUMBER
    ) AS
        CURSOR c_ZajeteDni IS
            SELECT IDZajeteDni, Data
            FROM ZajeteDniSprzetu z
            WHERE DEREF(z.RefSprzet).IDSprzet = p_IDSprzet;
        v_Row c_ZajeteDni%ROWTYPE;
    BEGIN
        OPEN c_ZajeteDni;
        LOOP
            FETCH c_ZajeteDni INTO v_Row;
            EXIT WHEN c_ZajeteDni%NOTFOUND;
    
            DBMS_OUTPUT.PUT_LINE('ID Zaj�te Dni: ' || v_Row.IDZajeteDni);
            DBMS_OUTPUT.PUT_LINE('Data: ' || TO_CHAR(v_Row.Data, 'DD-MM-YYYY'));
            DBMS_OUTPUT.PUT_LINE('-------------------------');
        END LOOP;
        CLOSE c_ZajeteDni;
    END WyswietlZajeteDni;
    
    PROCEDURE WyswietlWolneTerminy(
        p_IDSprzet IN NUMBER
    ) AS
        v_DzisiejszaData DATE := SYSDATE;
        v_DataKoncowa DATE := ADD_MONTHS(SYSDATE, 3); 
        v_DataIteracji DATE;
        v_Count NUMBER; 
    BEGIN
        v_DataIteracji := TRUNC(v_DzisiejszaData); 
    
        DBMS_OUTPUT.PUT_LINE('Wolne terminy dla sprz�tu ID: ' || p_IDSprzet || ' w ci�gu najbli�szych 3 miesi�cy:');
        DBMS_OUTPUT.PUT_LINE('----------------------------------------------------');
    

        WHILE v_DataIteracji <= v_DataKoncowa LOOP
            SELECT COUNT(*)
            INTO v_Count
            FROM ZajeteDniSprzetu z
            WHERE DEREF(z.RefSprzet).IDSprzet = p_IDSprzet
              AND TRUNC(z.Data) = v_DataIteracji;
    
            IF v_Count = 0 THEN
                DBMS_OUTPUT.PUT_LINE('Wolny termin: ' || TO_CHAR(v_DataIteracji, 'DD-MM-YYYY'));
            END IF;

            v_DataIteracji := v_DataIteracji + 1;
        END LOOP;
    
        DBMS_OUTPUT.PUT_LINE('----------------------------------------------------');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('B��d podczas wy�wietlania wolnych termin�w: ' || SQLERRM);
    END WyswietlWolneTerminy;

    
    PROCEDURE UsunZajetyDzien(
        p_IDZajeteDni IN NUMBER
    ) AS
    BEGIN
        DELETE FROM ZajeteDniSprzetu
        WHERE IDZajeteDni = p_IDZajeteDni;
        COMMIT;
    END UsunZajetyDzien;

END PAKIETZAJETEDNI;
/

---------------------------------------------------------------------------------------------------------------------
-- Tworzenie Pakietu dla obiektu przeglad naprawy
----------------------------------------------------------------------------------------------------------------------
create or replace PACKAGE PakietPrzegladyNaprawy AS 

    PROCEDURE DodajNaprawe(p_IDNaprawa IN NUMBER, p_IDSprzet IN NUMBER, p_Sprzet IN VARCHAR2, p_Data IN DATE, p_Koszt IN NUMBER, p_Typ IN VARCHAR2, p_Opis IN VARCHAR2);
    PROCEDURE AktualizujNaprawe(p_IDNaprawa IN NUMBER, p_IDSprzet IN NUMBER, p_Sprzet IN VARCHAR2, p_Data IN DATE, p_Koszt IN NUMBER, p_Typ IN VARCHAR2, p_Opis IN VARCHAR2);
    PROCEDURE UsunNaprawe(p_IDNaprawa IN NUMBER);
    PROCEDURE WyswietlNaprawy;

END PakietPrzegladyNaprawy;
/

create or replace PACKAGE BODY PakietPrzegladyNaprawy AS
    PROCEDURE DodajNaprawe(
        p_IDNaprawa IN NUMBER,
        p_IDSprzet IN NUMBER,
        p_Sprzet IN VARCHAR2,
        p_Data IN DATE,
        p_Koszt IN NUMBER,
        p_Typ IN VARCHAR2,
        p_Opis IN VARCHAR2
    ) IS
        v_Data DATE;
        v_Count NUMBER;
        v_RefSprzet REF TypSprzet;
    BEGIN
        SELECT REF(s)
        INTO v_RefSprzet
        FROM SprzetBudowlany s
        WHERE s.IDSprzet = p_IDSprzet;

        INSERT INTO PrzegladyNaprawy
        VALUES (TypPrzegladyNaprawy(p_IDNaprawa, v_RefSprzet, p_Sprzet, p_Data, p_Koszt, p_Typ, p_Opis));
        
        v_Data := p_Data;

        WHILE v_Data <= p_Data + 1 LOOP
            SELECT COUNT(*)
            INTO v_Count
            FROM ZajeteDniSprzetu z
            WHERE DEREF(z.RefSprzet).IDSprzet = p_IDSprzet
              AND z.Data = v_Data;
    
            IF v_Count > 0 THEN
                RAISE_APPLICATION_ERROR(-20006, 'Sprz�t o ID ' || p_IDSprzet || ' jest ju� zaj�ty w dniu: ' || TO_CHAR(v_Data, 'YYYY-MM-DD'));
            END IF;
    
            PAKIETZAJETEDNI.DodajZajetyDzien(
                p_IDZajeteDni => SEQ_ZajeteDni.NEXTVAL,
                p_Data => v_Data,
                p_IDSprzet => p_IDSprzet
            );
            

            v_Data := v_Data + 1;
        END LOOP;
    
        DBMS_OUTPUT.PUT_LINE('Naprawa zosta�a dodana i dni zosta�y oznaczone jako zaj�te.');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('B��d podczas dodawania naprawy: ' || SQLERRM);
    END DodajNaprawe;

    PROCEDURE AktualizujNaprawe(
        p_IDNaprawa IN NUMBER,
        p_IDSprzet IN NUMBER,
        p_Sprzet IN VARCHAR2,
        p_Data IN DATE,
        p_Koszt IN NUMBER,
        p_Typ IN VARCHAR2,
        p_Opis IN VARCHAR2
    ) IS
        v_RefSprzet REF TypSprzet;
    BEGIN
        SELECT REF(s)
        INTO v_RefSprzet
        FROM SprzetBudowlany s
        WHERE s.IDSprzet = p_IDSprzet;


        UPDATE PrzegladyNaprawy
        SET RefSprzet = v_RefSprzet, Sprzet = p_Sprzet, Data = p_Data, Koszt = p_Koszt, Typ = p_Typ, Opis = p_Opis
        WHERE IDNaprawa = p_IDNaprawa;

        IF SQL%ROWCOUNT = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Nie znaleziono naprawy o podanym ID.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Naprawa zosta�a zaktualizowana.');
        END IF;
    END AktualizujNaprawe;


    PROCEDURE UsunNaprawe(p_IDNaprawa IN NUMBER) IS
        v_IDSprzet NUMBER;
        v_Data DATE;
        v_DataKoniec DATE;
        v_RefSprzet REF TypSprzet;
        CURSOR c_ZajeteDni IS
            SELECT IDZajeteDni
            FROM ZajeteDniSprzetu z
            WHERE DEREF(z.RefSprzet) = DEREF(v_RefSprzet)
              AND z.Data BETWEEN v_Data AND v_DataKoniec;
        v_ZajetyDzienID NUMBER;
    BEGIN
        SELECT RefSprzet, Data, Data + 1 
        INTO v_RefSprzet, v_Data, v_DataKoniec
        FROM PrzegladyNaprawy
        WHERE IDNaprawa = p_IDNaprawa;
    
        DELETE FROM PrzegladyNaprawy
        WHERE IDNaprawa = p_IDNaprawa;
    
        IF SQL%ROWCOUNT = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Nie znaleziono naprawy o podanym ID.');
            RETURN;
        END IF;
    
        OPEN c_ZajeteDni;
        LOOP
            FETCH c_ZajeteDni INTO v_ZajetyDzienID;
            EXIT WHEN c_ZajeteDni%NOTFOUND;
    
            PAKIETZAJETEDNI.UsunZajetyDzien(v_ZajetyDzienID);
            DBMS_OUTPUT.PUT_LINE('Zaj�ty dzie� o ID ' || v_ZajetyDzienID || ' zosta� usuni�ty.');
        END LOOP;
        CLOSE c_ZajeteDni;
    
        DBMS_OUTPUT.PUT_LINE('Naprawa zosta�a usuni�ta wraz z zaj�tymi dniami.');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Nie znaleziono naprawy o podanym ID.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('B��d podczas usuwania naprawy: ' || SQLERRM);
    END UsunNaprawe;

    PROCEDURE WyswietlNaprawy IS
        CURSOR curNaprawy IS 
            SELECT IDNaprawa, DEREF(RefSprzet).IDSprzet AS IDSprzet, Sprzet, Data, Koszt, Typ, Opis 
            FROM PrzegladyNaprawy;
        recNaprawa curNaprawy%ROWTYPE;
    BEGIN
        OPEN curNaprawy;
        LOOP
            FETCH curNaprawy INTO recNaprawa;
            EXIT WHEN curNaprawy%NOTFOUND;

            DBMS_OUTPUT.PUT_LINE('ID Naprawy: ' || recNaprawa.IDNaprawa || 
                                 ', ID Sprz�tu: ' || recNaprawa.IDSprzet || 
                                 ', Sprz�t: ' || recNaprawa.Sprzet);
            DBMS_OUTPUT.PUT_LINE('Data: ' || recNaprawa.Data || 
                                 ', Koszt: ' || recNaprawa.Koszt || 
                                 ', Typ: ' || recNaprawa.Typ || 
                                 ', Opis: ' || recNaprawa.Opis);
            DBMS_OUTPUT.PUT_LINE('----------------------------------');
        END LOOP;
        CLOSE curNaprawy;
    END WyswietlNaprawy;

END PakietPrzegladyNaprawy;
/

--##############################################################################################################################################################################
--##############################################################################################################################################################################
--PRZYK�ADOWE Dane (bez polskich znakow)
--##############################################################################################################################################################################
--##############################################################################################################################################################################

BEGIN
    PAKIETKATEGORIE.DodajKategorie(1, 'Maszyny ziemne', 'Sprzet wykorzystywany do prac ziemnych, takich jak koparki, ladowarki i inne maszyny do wykopow.');
    PAKIETKATEGORIE.DodajKategorie(2, 'Maszyny do transportu', 'Sprzet wykorzystywany do transportu ciezkich materialow, np. dzwigi, wozki widlowe.');
    PAKIETKATEGORIE.DodajKategorie(3, 'Maszyny do betonu', 'Sprzet wykorzystywany do produkcji i mieszania betonu, np. betoniarki.');
    PAKIETKATEGORIE.DodajKategorie(4, 'Maszyny do prac wyburzeniowych', 'Sprzet do rozbiorki budynkow, np. moty wyburzeniowe, koparki do wyburzen.');
    PAKIETKATEGORIE.DodajKategorie(5, 'Maszyny do robot drogowych', 'Sprzet wykorzystywany do budowy drog, np. frezy drogowe, walce.');
END;
/

DECLARE
    v_Kategorie1 TypKategoriaTable := TypKategoriaTable(
        TypKategoria(1, 'Maszyny ziemne', 'Sprzet do prac ziemnych'),
        TypKategoria(3, 'Maszyny do betonu', 'Sprzet do mieszania betonu')
    );
    v_Kategorie2 TypKategoriaTable := TypKategoriaTable(
        TypKategoria(2, 'Maszyny transportowe', 'Sprzet do transportu materialow'),
        TypKategoria(5, 'Maszyny do robot drogowych', 'Sprzet do budowy drog')
    );
    v_Kategorie3 TypKategoriaTable := TypKategoriaTable(
        TypKategoria(4, 'Maszyny wyburzeniowe', 'Sprzet do wyburzen budynkow'),
        TypKategoria(1, 'Maszyny ziemne', 'Sprzet do prac ziemnych')
    );
    v_Kategorie4 TypKategoriaTable := TypKategoriaTable(
        TypKategoria(5, 'Maszyny do robot drogowych', 'Sprzet do budowy drog'),
        TypKategoria(3, 'Maszyny do betonu', 'Sprzet do mieszania betonu')
    );
    v_Kategorie5 TypKategoriaTable := TypKategoriaTable(
        TypKategoria(1, 'Maszyny ziemne', 'Sprzet do prac ziemnych'),
        TypKategoria(2, 'Maszyny transportowe', 'Sprzet do transportu materialow')
    );
BEGIN
    PAKIETSPRZETBUDOWLANY.DodajSprzet(1001, 'Koparka gasienicowa', v_Kategorie1, 1, 'Dostepny', 500);
    PAKIETSPRZETBUDOWLANY.DodajSprzet(1002, 'Koparka gasienicowa', v_Kategorie1, 1, 'Dostepny', 500);
    PAKIETSPRZETBUDOWLANY.DodajSprzet(1003, 'Koparka gasienicowa', v_Kategorie1, 1, 'Dostepny', 500);
    PAKIETSPRZETBUDOWLANY.DodajSprzet(1004, 'Koparka gasienicowa', v_Kategorie1, 1, 'Dostepny', 500);
    PAKIETSPRZETBUDOWLANY.DodajSprzet(1005, 'Koparka gasienicowa', v_Kategorie1, 1, 'Dostepny', 500);

    PAKIETSPRZETBUDOWLANY.DodajSprzet(2001, 'Betoniarka przemyslowa', v_Kategorie2, 0, 'Dostepny', 300);
    PAKIETSPRZETBUDOWLANY.DodajSprzet(2002, 'Betoniarka przemyslowa', v_Kategorie2, 0, 'Dostepny', 300);
    PAKIETSPRZETBUDOWLANY.DodajSprzet(2003, 'Betoniarka przemyslowa', v_Kategorie2, 0, 'Dostepny', 300);
    PAKIETSPRZETBUDOWLANY.DodajSprzet(2004, 'Betoniarka przemyslowa', v_Kategorie2, 0, 'Dostepny', 300);
    PAKIETSPRZETBUDOWLANY.DodajSprzet(2005, 'Betoniarka przemyslowa', v_Kategorie2, 0, 'Dostepny', 300);

    PAKIETSPRZETBUDOWLANY.DodajSprzet(3001, 'Mot wyburzeniowy', v_Kategorie3, 0, 'Dostepny', 400);
    PAKIETSPRZETBUDOWLANY.DodajSprzet(3002, 'Mot wyburzeniowy', v_Kategorie3, 0, 'Dostepny', 400);
    PAKIETSPRZETBUDOWLANY.DodajSprzet(3003, 'Mot wyburzeniowy', v_Kategorie3, 0, 'Dostepny', 400);
    PAKIETSPRZETBUDOWLANY.DodajSprzet(3004, 'Mot wyburzeniowy', v_Kategorie3, 0, 'Dostepny', 400);
    PAKIETSPRZETBUDOWLANY.DodajSprzet(3005, 'Mot wyburzeniowy', v_Kategorie3, 0, 'Dostepny', 400);

    PAKIETSPRZETBUDOWLANY.DodajSprzet(4001, 'Walec drogowy', v_Kategorie4, 1, 'Dostepny', 600);
    PAKIETSPRZETBUDOWLANY.DodajSprzet(4002, 'Walec drogowy', v_Kategorie4, 1, 'Dostepny', 600);
    PAKIETSPRZETBUDOWLANY.DodajSprzet(4003, 'Walec drogowy', v_Kategorie4, 1, 'Dostepny', 600);
    PAKIETSPRZETBUDOWLANY.DodajSprzet(4004, 'Walec drogowy', v_Kategorie4, 1, 'Dostepny', 600);
    PAKIETSPRZETBUDOWLANY.DodajSprzet(4005, 'Walec drogowy', v_Kategorie4, 1, 'Dostepny', 600);

    PAKIETSPRZETBUDOWLANY.DodajSprzet(5001, 'Wozek widlowy', v_Kategorie5, 1, 'Dostepny', 250);
    PAKIETSPRZETBUDOWLANY.DodajSprzet(5002, 'Wozek widlowy', v_Kategorie5, 1, 'Dostepny', 250);
    PAKIETSPRZETBUDOWLANY.DodajSprzet(5003, 'Wozek widlowy', v_Kategorie5, 1, 'Dostepny', 250);
    PAKIETSPRZETBUDOWLANY.DodajSprzet(5004, 'Wozek widlowy', v_Kategorie5, 1, 'Dostepny', 250);
    PAKIETSPRZETBUDOWLANY.DodajSprzet(5005, 'Wozek widlowy', v_Kategorie5, 1, 'Dostepny', 250);
END;
/

--######################################################################################################################
--ZMIANA USAWIENIA DATY NA NORAMLNY FORMAT
--######################################################################################################################

SELECT value 
FROM NLS_SESSION_PARAMETERS 
WHERE parameter = 'NLS_DATE_FORMAT';
/

ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';


--##############################################################################################################################################################################
--##############################################################################################################################################################################
--WIDOKI
--##############################################################################################################################################################################
--##############################################################################################################################################################################
-----------------------------------------------------------------------------------------------------------------------------------------------------
--WIDOK 1
-----------------------------------------------------------------------------------------------------------------------------------------------------
-- Obiekt reprezentujacy sprzet z nazwami kategorii
CREATE OR REPLACE TYPE SprzetZKategoria AS OBJECT (
    IDSprzet NUMBER,
    NazwaSprzetu VARCHAR2(100),
    Uprawnienia NUMBER,
    Status VARCHAR2(50),
    KwotaZaDzien NUMBER,
    NazwaKategorii VARCHAR2(100)
);
/
---tabela do widoku
CREATE OR REPLACE TYPE SprzetZKategoriaTable AS TABLE OF SprzetZKategoria;
/
--funkcja do splaszczania tabeli kategorie i laczenia jej z sprzetem_budowlanym i wstawiania rekordow do SprzetZKategoriaTable
CREATE OR REPLACE FUNCTION PobierzSprzetZKategoria
RETURN SprzetZKategoriaTable PIPELINED
IS
    CURSOR c_sprzet IS
        SELECT IDSprzet, NazwaSprzetu, Uprawnienia, Status, KwotaZaDzien, CAST(Kategoria AS TypKategoriaTable) AS Kategoria
        FROM SprzetBudowlany;

    v_IDSprzet NUMBER;
    v_Nazwa VARCHAR2(100);
    v_Uprawnienia NUMBER;
    v_Status VARCHAR2(50);
    v_Kwota NUMBER;
    v_Kategorie TypKategoriaTable;
BEGIN
    OPEN c_sprzet;
    LOOP
        FETCH c_sprzet INTO v_IDSprzet, v_Nazwa, v_Uprawnienia, v_Status, v_Kwota, v_Kategorie;
        EXIT WHEN c_sprzet%NOTFOUND;

        IF v_Kategorie IS NOT NULL THEN
            FOR i IN 1 .. v_Kategorie.COUNT LOOP
                PIPE ROW (
                    SprzetZKategoria(
                        v_IDSprzet,
                        v_Nazwa,
                        v_Uprawnienia,
                        v_Status,
                        v_Kwota,
                        v_Kategorie(i).Nazwa
                    )
                );
            END LOOP;
        ELSE
            PIPE ROW (
                SprzetZKategoria(
                    v_IDSprzet,
                    v_Nazwa,
                    v_Uprawnienia,
                    v_Status,
                    v_Kwota,
                    NULL
                )
            );
        END IF;
    END LOOP;
    CLOSE c_sprzet;

    RETURN;
END;
/
--stworzeniu widoku docelowego
CREATE OR REPLACE VIEW VW_Sprzet_Z_Kategoria AS
SELECT * FROM TABLE(PobierzSprzetZKategoria);
/
-----------------------------------------------------------------------------------------------------------------------------------------------------
--WIDOK 2
-----------------------------------------------------------------------------------------------------------------------------------------------------
-- Sprzet z zajetymi dniami
CREATE OR REPLACE VIEW VW_Sprzet_Z_ZajetymiDniami AS
SELECT
    s.IDSprzet,
    s.NazwaSprzetu,
    s.Uprawnienia,
    s.Status,
    s.KwotaZaDzien,
    z.Data
FROM
    SprzetBudowlany s
JOIN ZajeteDniSprzetu z
    ON s.IDSPRZET = DEREF(z.RefSprzet).IDSprzet;
/
------------------test
--SELECT * FROM VW_Sprzet_Z_ZajetymiDniami
/
-----------------------------------------------------------------------------------------------------------------------------------------------------
--WIDOK 3
-----------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_Sprzet_Z_PRZEGLADY_NAPRAWY AS
SELECT
    s.IDSprzet,
    s.NazwaSprzetu,
    s.Uprawnienia,
    s.Status,
    s.KwotaZaDzien,
    P.DATA,
    P.TYP,
    P.KOSZT
FROM
    SprzetBudowlany s
JOIN PRZEGLADYNAPRAWY P
    ON s.IDSPRZET = DEREF(P.RefSprzet).IDSprzet;
    /
----------------TEST
SELECT * FROM VW_Sprzet_Z_PRZEGLADY_NAPRAWY
/


CREATE OR REPLACE VIEW VW_ZajeteDniSprzetu AS
SELECT 
    z.IDZajeteDni,
    z.Data,
    DEREF(z.RefSprzet).IDSprzet AS IDSprzet
FROM 
    ZajeteDniSprzetu z;
/

CREATE OR REPLACE VIEW V_SprzetBudowlany AS
SELECT IDSprzet, NazwaSprzetu, Uprawnienia, Status, KwotaZaDzien
FROM SprzetBudowlany;
/

CREATE OR REPLACE VIEW V_kategorie AS
SELECT IDKategoria, Nazwa, Opis
FROM Kategorie;
/

CREATE OR REPLACE VIEW V_PrzegladyNaprawy AS
SELECT p.IDNaprawa, DEREF(p.RefSprzet).IDSprzet AS IDSprzet, p.Sprzet, p.Data, p.Koszt, p.Typ, p.Opis
FROM Przegladynaprawy p;
/


--##########################################################
--funkcja do procedury rozproszonej
--#####################################################
CREATE OR REPLACE TYPE TypWolnyDzienRow AS OBJECT (
    WolnyDzien DATE
);
/

CREATE OR REPLACE TYPE TypWolnyDzienTable AS TABLE OF TypWolnyDzienRow;
/

CREATE OR REPLACE FUNCTION ZnajdzWolnyDzien_F (
    p_IDSprzet   IN  NUMBER,
    p_DataStart  IN  DATE
) RETURN TypWolnyDzienTable PIPELINED
AS
    v_DataTest DATE := TRUNC(p_DataStart);
    v_RefSprzet REF TypSprzet;
    v_Count     NUMBER;
BEGIN
    -- Pobierz REF sprzętu
    SELECT REF(s)
    INTO v_RefSprzet
    FROM SprzetBudowlany s
    WHERE s.IDSprzet = p_IDSprzet;

    -- Szukaj pierwszego wolnego dnia
    LOOP
        SELECT COUNT(*)
        INTO v_Count
        FROM ZajeteDniSprzetu z
        WHERE z.RefSprzet = v_RefSprzet
          AND TRUNC(z.Data) = v_DataTest;

        EXIT WHEN v_Count = 0;
        v_DataTest := v_DataTest + 1;
    END LOOP;
    

    -- Zwróć jako wiersz tabeli
    PIPE ROW(TypWolnyDzienRow(v_DataTest));
    RETURN;
END;
/
