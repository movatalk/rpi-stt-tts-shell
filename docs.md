# Dokumentacja pakietu rpi-stt-tts-shell
<!--
Author: tom-sapletta-com
Purpose: development setup instructions for the project.
-->
## Wprowadzenie

`rpi-stt-tts-shell` to wszechstronny pakiet oferujący funkcje rozpoznawania mowy (STT - Speech to Text) i syntezowania mowy (TTS - Text to Speech) specjalnie zaprojektowany dla urządzeń Raspberry Pi. Pakiet umożliwia stworzenie interaktywnego asystenta głosowego zdolnego do sterowania urządzeniami IoT, odczytywania danych z czujników oraz reagowania na polecenia głosowe użytkownika.

## Zawartość pakietu

Pakiet zawiera następujące komponenty:

1. **Główna biblioteka Python** - Zestaw modułów do rozpoznawania i syntezy mowy
2. **Skrypt `scan.sh`** - Wykrywa urządzenia Raspberry Pi w sieci lokalnej
3. **Skrypt `deploy.sh`** - Wdraża projekt na wykryte urządzenia
4. **Skrypt `test_script.sh`** - Testuje wdrożony projekt na zdalnych urządzeniach
5. **Makefile** - Automatyzuje zadania developerskie i wdrożeniowe

## Wymagania systemowe

### Sprzęt
- Raspberry Pi (testowano na Raspberry Pi 3B+, 4 i Zero 2W)
- Mikrofon USB lub HAT mikrofonowy (np. ReSpeaker)
- Głośnik (wyjście audio 3.5mm, HDMI, USB lub Bluetooth)
- Opcjonalnie: czujniki (DHT22, BME280), diody LED, przekaźniki, itp.

### Oprogramowanie
- Raspberry Pi OS (Bullseye lub nowszy)
- Python 3.7+
- Pakiety systemowe: portaudio, alsa-utils, espeak/espeak-ng

## Instalacja

### 1. Przy użyciu pip
```bash
pip install rpi-stt-tts-shell
```

### 2. Przy użyciu Poetry
```bash
poetry add rpi-stt-tts-shell
```

### 3. Z repozytorium
```bash
git clone https://github.com/user/rpi-stt-tts-shell.git
cd rpi-stt-tts-shell
make install  # lub: poetry install
```

### 4. Wdrożenie na wielu urządzeniach

Pakiet zawiera narzędzia do automatycznego wdrażania na wielu urządzeniach Raspberry Pi:

```bash
# Skanowanie sieci w poszukiwaniu urządzeń Raspberry Pi
make scan

# Wdrożenie na wszystkie znalezione urządzenia
make deploy
```

## Konfiguracja

Konfiguracja znajduje się w pliku `config.json`:

```json
{
  "stt": {
    "engine": "pocketsphinx",
    "language": "pl",
    "threshold": 0.5,
    "keyword": "komputer"
  },
  "tts": {
    "engine": "espeak",
    "language": "pl",
    "rate": 150,
    "volume": 0.8
  },
  "gpio": {
    "light": 17,
    "fan": 18,
    "dht_sensor": 4
  },
  "logging": {
    "enable": true,
    "level": "INFO",
    "file": "assistant.log"
  }
}
```

## Architektura pakietu

```
rpi-stt-tts-shell/
├── rpi_stt_tts_shell/         # Pakiet główny
│   ├── __init__.py
│   ├── assistant.py           # Główny moduł asystenta
│   ├── stt/                   # Moduły rozpoznawania mowy
│   │   ├── __init__.py
│   │   ├── pocketsphinx_engine.py
│   │   ├── vosk_engine.py
│   │   ├── whisper_engine.py
│   │   └── google_engine.py
│   ├── tts/                   # Moduły syntezy mowy
│   │   ├── __init__.py
│   │   ├── espeak_engine.py
│   │   ├── piper_engine.py
│   │   ├── festival_engine.py
│   │   └── google_engine.py
│   ├── gpio_controller.py     # Kontroler GPIO
│   ├── sensors.py             # Obsługa czujników
│   └── plugins/               # Wtyczki rozszerzające funkcjonalność
│       ├── __init__.py
│       ├── weather.py
│       ├── timer.py
│       └── music.py
```

## Obsługiwane silniki STT i TTS

### Silniki STT (Speech to Text)
- **PocketSphinx** (offline, lekki, niższa dokładność)
- **Vosk** (offline, średnia dokładność)
- **Whisper** (offline, wysoka dokładność, wymaga mocniejszego Raspberry Pi)
- **Google Speech Recognition** (online, wysoka dokładność)

### Silniki TTS (Text to Speech)
- **eSpeak/eSpeak-NG** (offline, szybki, mniej naturalny głos)
- **Piper TTS** (offline, naturalny głos, wymaga mocniejszego Raspberry Pi)
- **Festival** (offline, średnia jakość)
- **Google TTS** (online, wysoka jakość)

## Komendy głosowe

Domyślnie asystent nasłuchuje słowa kluczowego (domyślnie "komputer"), po którym rozpoznaje następujące polecenia:

- "Włącz światło" - aktywuje GPIO do włączenia światła
- "Wyłącz światło" - dezaktywuje GPIO
- "Włącz wentylator" - aktywuje GPIO dla wentylatora
- "Wyłącz wentylator" - dezaktywuje GPIO dla wentylatora
- "Jaka jest temperatura" - odczytuje aktualną temperaturę z czujnika DHT
- "Jaka jest wilgotność" - odczytuje aktualną wilgotność z czujnika DHT
- "Która godzina" - odczytuje aktualny czas
- "Dzisiejsza data" - odczytuje aktualną datę
- "Pomoc" - lista dostępnych poleceń
- "Koniec" lub "Wyłącz się" - kończy działanie asystenta

## Interfejs programistyczny (API)

### Inicjalizacja asystenta

```python
from rpi_stt_tts_shell import VoiceAssistant

# Inicjalizacja z domyślną konfiguracją
assistant = VoiceAssistant()

# Inicjalizacja z własną# Dokumentacja skryptów scan.sh i deploy.sh

## Wprowadzenie

Pakiet zawiera dwa skrypty służące do automatyzacji procesu wdrażania oprogramowania na urządzeniach Raspberry Pi:

1. **scan.sh** - skrypt skanujący sieć lokalną w poszukiwaniu urządzeń Raspberry Pi i zapisujący wyniki do pliku CSV
2. **deploy.sh** - skrypt wdrażający, testujący i logujący projekt na wykrytych urządzeniach Raspberry Pi

Dodatkowo pakiet zawiera przykładowy **test_script.sh**, który służy do testowania wdrożonego projektu na urządzeniach docelowych.

## Wymagania systemowe

Skrypty zostały zaprojektowane do pracy w środowisku Linux/Unix i wymagają następujących narzędzi:

- `bash` (powłoka)
- `nmap` (skanowanie sieci)
- `ssh` i `scp` (połączenia i kopiowanie plików)
- `grep`, `awk` i inne standardowe narzędzia powłoki

Opcjonalnie, do połączeń z hasłem:
- `sshpass` (automatyczne podawanie hasła)

## 1. scan.sh - Skaner Raspberry Pi

### Cel
Skrypt `scan.sh` służy do automatycznego wykrywania urządzeń Raspberry Pi w sieci lokalnej i zapisywania informacji o nich do pliku CSV, który następnie może być wykorzystany przez skrypt `deploy.sh`.

### Składnia
```
./scan.sh [OPCJE]
```

### Opcje
- `-r, --range RANGE` - skanuj podany zakres sieci (np. 192.168.1.0/24)
- `-o, --output FILE` - zapisz wyniki do podanego pliku CSV (domyślnie: raspberry_pi_devices.csv)
- `-h, --help` - wyświetl pomoc

### Jak działa
1. Automatycznie wykrywa interfejs sieciowy i zakres sieci (można to nadpisać opcją `-r`)
2. Skanuje sieć za pomocą nmap, szukając urządzeń z otwartym portem SSH (22)
3. Dla każdego znalezionego urządzenia próbuje określić, czy jest to Raspberry Pi:
   - Na podstawie nazwy hosta
   - Próbując połączyć się przez SSH i odczytać informacje z systemu
4. Zapisuje informacje tylko o urządzeniach, które są lub prawdopodobnie są Raspberry Pi
5. Generuje plik CSV z kolumnami: IP, nazwa hosta, czy to Raspberry Pi, informacje o systemie, model, data skanowania

### Format pliku wyjściowego CSV
```
ip,hostname,is_raspberry_pi,os_info,model,scan_date
192.168.1.100,raspberrypi,true,Raspberry Pi OS (bullseye),Raspberry Pi 4 Model B Rev 1.2,2025-05-15 12:34:56
```

### Przykłady użycia
```bash
# Standardowe użycie (automatyczne wykrywanie sieci)
./scan.sh

# Skanowanie konkretnego zakresu sieci
./scan.sh -r 10.0.0.0/24

# Zapisanie wyników do niestandardowego pliku
./scan.sh -o moje_urzadzenia.csv
```

## 2. deploy.sh - Wdrażanie projektu

### Cel
Skrypt `deploy.sh` służy do automatycznego wdrażania, testowania i logowania projektu na urządzeniach Raspberry Pi wykrytych przez skrypt `scan.sh`.

### Składnia
```
./deploy.sh [OPCJE]
```

### Opcje
- `-f, --file FILE` - użyj podanego pliku CSV z urządzeniami (domyślnie: raspberry_pi_devices.csv)
- `-u, --user USER` - użyj podanej nazwy użytkownika SSH (domyślnie: pi)
- `-p, --password PASS` - użyj podanego hasła SSH (domyślnie: raspberry)
- `-d, --dir DIR` - użyj podanego katalogu projektu (domyślnie: project_files)
- `-r, --remote-dir DIR` - użyj podanego katalogu zdalnego (domyślnie: /home/pi/deployed_project)
- `-i, --ip IP` - wdróż tylko na konkretne urządzenie o podanym IP
- `-h, --help` - wyświetl pomoc

### Jak działa
1. Sprawdza, czy plik CSV z listą urządzeń istnieje i zawiera urządzenia
2. Weryfikuje, czy katalog projektu istnieje i czy zawiera wymagane pliki
3. Dla każdego urządzenia Raspberry Pi wykonuje:
   - Nawiązuje połączenie SSH
   - Tworzy katalog docelowy na zdalnym urządzeniu
   - Kopiuje pliki projektu na zdalne urządzenie
   - Uruchamia skrypt testowy (jeśli istnieje)
   - Zapisuje logi z każdego etapu
4. Generuje raport HTML z podsumowaniem wdrożenia

### Struktura katalogów
```
.
├── scan.sh                   # Skrypt skanujący
├── deploy.sh                 # Skrypt wdrażający
├── raspberry_pi_devices.csv  # Plik CSV z wykrytymi urządzeniami
├── project_files/            # Katalog z plikami projektu
│   ├── main.py               # Przykładowy plik projektu
│   ├── config.json           # Przykładowy plik konfiguracyjny
│   └── test_script.sh        # Skrypt testowy uruchamiany na zdalnych urządzeniach
└── deployment_logs/          # Katalog z logami wdrożenia
    ├── deployment_20250515_123456.log    # Główny log wdrożenia
    ├── device_192.168.1.100_20250515_123456.log  # Log dla konkretnego urządzenia
    └── deployment_report_20250515_123456.html    # Raport HTML
```

### Przykłady użycia
```bash
# Standardowe użycie (wdrożenie na wszystkie urządzenia z pliku CSV)
./deploy.sh

# Wdrożenie z niestandardowymi parametrami
./deploy.sh -u admin -p tajnehaslo -d ~/moj_projekt -r /opt/aplikacja

# Wdrożenie tylko na jedno urządzenie
./deploy.sh -i 192.168.1.100
```

## 3. test_script.sh - Testowanie projektu

### Cel
Skrypt `test_script.sh` jest przykładowym skryptem, który może być dostosowany do testowania konkretnego projektu po wdrożeniu na urządzeniu Raspberry Pi.

### Jak działa
1. Wykonuje serię testów na urządzeniu:
   - Testy systemowe (wersja OS, model, połączenie z internetem)
   - Testy zależności systemowych (Python, pip, git)
   - Testy zależności Pythona
   - Testy struktury projektu (obecność plików i katalogów)
   - Testy portów i usług
   - Testy specyficzne dla projektu
2. Wyświetla informacje o systemie
3. Prezentuje podsumowanie testów

### Konfiguracja
Skrypt testowy można dostosować do konkretnego projektu, dodając lub modyfikując testy w odpowiednich sekcjach.

## Typowy przepływ pracy

1. Uruchom `scan.sh`, aby wykryć urządzenia Raspberry Pi w sieci:
   ```bash
   ./scan.sh
   ```

2. Przygotuj pliki projektu w katalogu `project_files/` (lub innym określonym):
   ```bash
   mkdir -p project_files
   cp -r moj_projekt/* project_files/
   cp test_script.sh project_files/
   ```

3. Uruchom `deploy.sh`, aby wdrożyć projekt na wykrytych urządzeniach:
   ```bash
   ./deploy.sh
   ```

4. Sprawdź wyniki wdrożenia w pliku raportu HTML w katalogu `deployment_logs/`.

## Rozwiązywanie problemów

### Nie mogę skanować sieci
- Upewnij się, że masz zainstalowany `nmap`
- Upewnij się, że masz odpowiednie uprawnienia (może być wymagane `sudo`)
- Spróbuj ręcznie określić zakres sieci za pomocą opcji `-r`

### Nie można połączyć się z urządzeniami
- Sprawdź czy urządzenia są dostępne w sieci
- Sprawdź dane logowania (użytkownik/hasło)
- Upewnij się, że SSH jest włączony na urządzeniach docelowych

### Testy nie przechodzą
- Sprawdź logi dla konkretnego urządzenia w katalogu `deployment_logs/`
- Dostosuj testy w skrypcie `test_script.sh` do wymagań projektu
- Upewnij się, że urządzenia spełniają wszystkie wymagania systemowe projektu

## Uwagi

- Skrypty są skonfigurowane do pracy z domyślnym użytkownikiem Raspberry Pi (`pi` z hasłem `raspberry`). W środowisku produkcyjnym zalecane jest użycie kluczy SSH zamiast haseł.
- Przed wdrożeniem w środowisku produkcyjnym, zalecane jest przetestowanie skryptów w środowisku testowym.
- Raport HTML zawiera szczegółowe informacje o procesie wdrażania i może być przydatny do diagnostyki problemów.



## Rozwiązywanie problemów

### Problemy z pamięcią na Pi Zero v2

Jeśli występują problemy z pamięcią podczas instalacji dużych pakietów:

```bash
# Zwiększenie przestrzeni swap
sudo dphys-swapfile swapoff
sudo sed -i 's/CONF_SWAPSIZE=.*/CONF_SWAPSIZE=1024/' /etc/dphys-swapfile
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
```

### Problemy z kompilacją pakietów natywnych

Dla pakietów wymagających kompilacji:

```bash
sudo apt-get install -y build-essential libssl-dev libffi-dev python3-dev
```

### Synchronizacja zależności

W przypadku niespójności zależności:

```bash
poetry lock --no-update  # Regeneracja pliku lock bez aktualizacji
```

## Przykładowe projekty

### Monitoring temperatury i wilgotności

```python
#!/usr/bin/env python3
import time
import board
import adafruit_dht

# Inicjalizacja czujnika DHT22 na pinie D4
dht = adafruit_dht.DHT22(board.D4)

while True:
    try:
        # Odczyt temperatury i wilgotności
        temperatura = dht.temperature
        wilgotnosc = dht.humidity
        
        print(f"Temperatura: {temperatura}°C, Wilgotność: {wilgotnosc}%")
        
    except RuntimeError as e:
        # Błędy odczytu są dość częste, je ignorujemy
        print(f"Błąd odczytu: {e}")
    
    time.sleep(2)  # Odczyt co 2 sekundy
```

Plik `pyproject.toml` dla tego projektu:

```toml
[tool.poetry]
name = "monitor-dht"
version = "0.1.0"
description = "Monitoring czujnika DHT22"
authors = ["Twoje Imię <twoj.email@example.com>"]

[tool.poetry.dependencies]
python = "^3.7"
adafruit-blinka = "^8.19.0"
adafruit-circuitpython-dht = "^3.7.8"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
```

---

*Dokumentacja przygotowana: 15 maja 2025*
