# qb-tablet-pro

Profesjonalny tablet pod QBCore/FiveM (styl iPad 2026):

- duży, kolorowy interfejs NUI,
- ekran blokady + pierwszy setup (PL/EN i PIN),
- aplikacje: **Moja Frakcja** i **Moja Rodzina**,
- pełny panel zakładek we **Frakcji**:
  - Członkowie,
  - Baza Danych,
  - Magazyn,
  - Zarządzanie saldem,
  - Dostawa transportu,
  - Ustawienia,
  - Premie,
  - Wezwania,
  - Czarna Lista,
- modalne akcje członka:
  - Awansuj / Degraduj,
  - Wydaj WARN / Zdejmij WARN,
  - Zwolnij (z opcją blacklisty),
  - Wydaj premię,
  - Uwięź (zasilenie salda +5000),
- auto-zasilanie salda frakcji co 30 min,
- komendy:
  - `/tablet`
  - `/lealspd ID`
  - `/gnews treść` (niebieski globalny komunikat),
- baza danych: SQL schema + warstwa `oxmysql` (fallback JSON gdy brak DB).

## Struktura projektu

- `client/`
  - `main.lua`
  - `nui.lua`
- `server/`
  - `main.lua`
  - `db.lua`
  - `tablet_service.lua`
  - `faction_service.lua`
  - `commands.lua`
- `html/`
  - `index.html`
  - `styles/`
  - `js/`
- `shared/`
  - `constants.lua`
  - `locales/`
- `sql/tablet.sql`

## Instalacja

1. Skopiuj resource do `resources/[qb]/qb-tablet-pro`.
2. (Opcjonalnie) uruchom SQL z pliku `sql/tablet.sql`.
3. Dodaj do `server.cfg`:
   ```cfg
   ensure qb-tablet-pro
   ```

## Konfiguracja

Edytuj `config.lua`:
- joby frakcyjne,
- pojazdy transportu,
- auto-income,
- domyślne rangi i permisje.

## Uwagi

To jest duży krok względem poprzedniej wersji MVP: rozbita architektura, nowy wygląd iPad, więcej zakładek, więcej realnych akcji i podpięcie pod DB/fallback.
