# Dokumentacja projektu

Ten katalog zawiera kompleksową dokumentację projektu rpi-stt-tts-shell, w tym opisy interfejsów API, instrukcje obsługi skryptów oraz przykłady użycia.

## Pliki w tym katalogu

- `README.md` - Ten plik, indeks dokumentacji
- `scripts.md` - Dokumentacja skryptów dostępnych w projekcie
- `api.md` - Dokumentacja API projektu

## Dokumentacja skryptów

Plik `scripts.md` zawiera szczegółową dokumentację wszystkich skryptów dostępnych w projekcie, w tym:

- Opis celu i funkcji skryptów
- Parametry i opcje
- Przykłady użycia
- Rozwiązywanie problemów

## Dokumentacja API

Plik `api.md` zawiera dokumentację interfejsu programistycznego (API) projektu, w tym:

- Opis klas i metod
- Przykłady użycia
- Integracja z innymi systemami
- Tworzenie własnych rozszerzeń

## Struktura projektu

Projekt jest zorganizowany w następujące katalogi:

- `bin/` - Skrypty wykonywalne, w tym główne menu
- `fleet/` - Narzędzia do zarządzania flotą urządzeń
- `ssh/` - Narzędzia do zarządzania konfiguracjami SSH
- `rpi/` - Skrypty specyficzne dla Raspberry Pi
- `zero3w/` - Skrypty specyficzne dla Radxa Zero 3W
- `docs/` - Dokumentacja projektu (ten katalog)
- `src/` - Kod źródłowy asystenta głosowego

Każdy katalog zawiera własny plik README.md z dokumentacją specyficzną dla tego komponentu.

## Wymagania systemowe

### Sprzęt
- Raspberry Pi (3B+, 4, Zero 2W) lub Radxa Zero 3W
- Mikrofon USB lub HAT mikrofonowy (np. ReSpeaker)
- Głośnik (wyjście audio 3.5mm, HDMI, USB lub Bluetooth)
- Opcjonalnie: czujniki (DHT22, BME280), diody LED, przekaźniki

### Oprogramowanie
- Raspberry Pi OS / Debian / Ubuntu
- Python 3.7+
- Pakiety: portaudio, alsa-utils, espeak/espeak-ng

## Szybki start

1. Sklonuj repozytorium:
```bash
git clone https://github.com/movatalk/rpi-stt-tts-shell.git
cd rpi-stt-tts-shell
```

2. Uruchom menu główne:
```bash
./bin/menu.sh
```

3. Wybierz opcję, aby:
   - Skanować sieć w poszukiwaniu urządzeń
   - Wdrożyć projekt na znalezione urządzenia
   - Skonfigurować urządzenia
   - Połączyć się z urządzeniami przez SSH

## Funkcje asystenta głosowego

Asystent głosowy oferuje następujące funkcje:

1. **Rozpoznawanie mowy (STT)** z wykorzystaniem różnych silników:
   - PocketSphinx (offline, lekki)
   - Vosk (offline, średnia dokładność)
   - Whisper (offline, wysoka dokładność)
   - Google Speech Recognition (online, wysoka dokładność)

2. **Synteza mowy (TTS)** z obsługą wielu języków:
   - eSpeak/eSpeak-NG (offline, szybki)
   - Piper TTS (offline, naturalny głos)
   - Festival (offline, średnia jakość)
   - Google TTS (online, wysoka jakość)

3. **Kontrola urządzeń** poprzez GPIO:
   - Sterowanie oświetleniem
   - Kontrola wentylatorów
   - Obsługa przekaźników

4. **Odczyt danych z czujników**:
   - Temperatura i wilgotność (DHT22, BME280)
   - Ciśnienie atmosferyczne
   - Jakość powietrza

5. **Obsługa komend głosowych** takich jak:
   - "Włącz światło" / "Wyłącz światło"
   - "Jaka jest temperatura" / "Jaka jest wilgotność"
   - "Która godzina" / "Dzisiejsza data"

## Przykłady użycia

Przykłady użycia API i skryptów znajdują się w odpowiednich sekcjach dokumentacji.

## Rozwiązywanie problemów

Sekcje dotyczące rozwiązywania problemów znajdują się w dokumentacji poszczególnych komponentów.

## Wsparcie i zgłaszanie problemów

Problemy można zgłaszać przez system Issue Tracker na GitHub.

## Licencja

Ten projekt jest dostępny na licencji MIT.