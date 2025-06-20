# Rozproszona Baza Danych: Integracja Oracle, SQL Server i Excel

## Opis projektu

Projekt ma na celu integrację różnych systemów bazodanowych: Oracle, SQL Server oraz plików Excel, w celu umożliwienia wymiany danych między nimi w sposób rozproszony. Celem jest stworzenie rozwiązania, które pozwoli na synchronizację danych pomiędzy tymi trzema źródłami, a także umożliwi użytkownikom łatwy dostęp i manipulację danymi z poziomu aplikacji.

## Technologie

- **Oracle Database**: Baza danych obiektowo-relacyjna, wykorzystywana do przechowywania danych o zaawansowanej strukturze.
- **SQL Server**: Relacyjna baza danych Microsoft, używana do przechowywania danych w bardziej tradycyjnej formie.
- **Excel**: Pliki arkuszy kalkulacyjnych używane do prostszej analizy i wizualizacji danych.

## Wymagania

1. **Oracle Database** – Zainstalowana i skonfigurowana baza danych Oracle.
2. **SQL Server** – Zainstalowana i skonfigurowana baza danych Microsoft SQL Server.
3. **Microsoft Excel** – Zainstalowany Excel w wersji obsługującej pliki XLSX.
4. **JDK 11 lub wyższe** – Potrzebne do uruchomienia aplikacji i integracji baz.
5. **Zalecane narzędzia**:
   - SQL Server Management Studio (SSMS)
   - Oracle SQL Developer
   - Microsoft Excel (dowolna wersja)

## Konfiguracja projektu

### 1. Konfiguracja Oracle

Aby połączyć się z bazą danych Oracle, należy skonfigurować plik `tnsnames.ora` lub użyć połączeń bezpośrednich. Upewnij się, że masz dostęp do odpowiednich danych logowania i adresu serwera bazy.

**Przykład konfiguracji połączenia Oracle**:

```properties
oracle.jdbc.driver.OracleDriver
jdbc:oracle:thin:@//<host>:<port>/<service_name>
<username>
<password>
```
