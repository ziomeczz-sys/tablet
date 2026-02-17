# qb-tablet-ios (QBCore)

Prototyp tabletu pod FiveM/QBCore z:

- ekranem blokady w stylu iOS (NUI),
- pierwszą konfiguracją (język PL/EN + PIN),
- aplikacją **Moja Frakcja**,
- aplikacją **Moja Rodzina**,
- podstawowym zarządzaniem saldem frakcji i logami,
- komendą leadera `/lealspd ID`,
- komendą ogłoszeń `/gnews ...`.

## Instalacja

1. Wrzuć resource do `resources/[qb]/qb-tablet-ios`.
2. Dodaj do `server.cfg`:
   ```cfg
   ensure qb-tablet-ios
   ```
3. Otwórz tablet komendą:
   ```
   /tablet
   ```

## Co jest gotowe

- Setup dla nowego gracza (język + PIN zapisane w metadata gracza).
- Blokada PIN przy każdym otwarciu.
- Aplikacja rodziny (utworzenie nazwy rodziny).
- Aplikacja frakcji (dla jobów `police` / `lspd`) z listą członków online.
- Podstawowe operacje salda frakcji: wpłata/wypłata + logi.
- Auto-wpłata na saldo co 30 min (`15000 PLN`) + log "Urząd Miasta".
- Warny i czarna lista po stronie serwera (callback API).

## Konfiguracja

W pliku `config.lua`:

- `Config.FactionJobs` – jakie joby mają dostęp do "Moja Frakcja",
- `Config.FactionAutoIncomeMs`, `Config.FactionAutoIncomeAmount`,
- `Config.TransportPoints` – punkty dostawy aut,
- `Config.DefaultRankPermissions` – domyślne uprawnienia rang.

## Uwaga

To jest **działający szkielet MVP** pod dalszą rozbudowę ekranów i flow (szczególnie szczegółowe widoki członków, baza danych obywateli, mandaty, aresztowania, pełny system rang/permisji UI).
