# rpi-stt-tts-shell: Interaktywny Asystent Głosowy dla Raspberry Pi

[![Python 3.7+](https://img.shields.io/badge/python-3.7+-blue.svg)](https://www.python.org/downloads/)
[![License: Apache-2.0](https://img.shields.io/badge/License-Apache%202.0-yellow.svg)](https://opensource.org/licenses/Apache-2.0)
[![Poetry](https://img.shields.io/badge/packaging-poetry-cyan.svg)](https://python-poetry.org/)

Kompleksowe rozwiązanie dla Raspberry Pi oferujące funkcje rozpoznawania mowy (STT - Speech to Text) i syntezowania mowy (TTS - Text to Speech), zaprojektowane jako interaktywna powłoka głosowa do kontroli urządzeń IoT.

## Funkcje

- 🎤 **Rozpoznawanie mowy** - przetwarzanie poleceń głosowych na tekst
- 🔊 **Synteza mowy** - odczytywanie odpowiedzi i powiadomień
- 🔄 **Tryb interaktywny** - ciągłe nasłuchiwanie i reagowanie na polecenia
- 📡 **Sterowanie GPIO** - kontrola urządzeń podłączonych do Raspberry Pi
- 🌡️ **Odczyt czujników** - integracja z czujnikami (np. DHT22, BME280)
- 📊 **Logowanie danych** - zapisywanie historii poleceń i odczytów czujników
- 🔌 **Plug-in API** - możliwość rozszerzania o własne moduły

## Wymagania systemowe

### Sprzęt
- Raspberry Pi (testowano na Raspberry Pi 3B+, 4 i Zero 2W)
- Mikrofon USB lub HAT mikrofonowy (np. ReSpeaker)
- Głośnik (wyjście audio 3.5mm, HDMI, USB lub Bluetooth)
- Opcjonalnie: czujniki, diody LED, przekaźniki, itp.

### Oprogramowanie
- Raspberry Pi OS (Bullseye lub nowszy)
- Python 3.7+
- Pakiety systemowe: portaudio, alsa-utils, espeak/espeak-ng

## Instalacja

### 1. Instalacja przy użyciu pip

```bash
pip install rpi-stt-tts-shell
```

### 2. Instalacja przy użyciu Poetry

```bash
poetry add rpi-stt-tts-shell
```

### 3. Instalacja z repozytorium

```bash
git clone https://github.com/user/rpi-stt-tts-shell.git
cd rpi-stt-tts-shell
make install  # lub: poetry install
```

### 4. Wdrożenie na wielu urządzeniach

Pakiet zawiera narzędzia do automatycznego wdrażania na wielu urządzeniach Raspberry Pi w sieci:

```bash
# Skanowanie sieci w poszukiwaniu urządzeń Raspberry Pi
make scan

# Wdrożenie na wszystkie znalezione urządzenia
make deploy
```

## Szybki start

### Podstawowe użycie

```python
from rpi_stt_tts_shell import VoiceAssistant

assistant = VoiceAssistant()
assistant.start()  # Uruchamia interaktywną pętlę nasłuchiwania
```

### Jako aplikacja konsolowa

```bash
# Po instalacji pakietu
rpi-stt-tts-shell

# Z uprawnieniami administratora (do obsługi GPIO)
sudo rpi-stt-tts-shell
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

## Obsługiwane silniki STT i TTS

### Silniki STT (Speech to Text)
- PocketSphinx (offline, lekki, niższa dokładność)
- Vosk (offline, średnia dokładność)
- Whisper (offline, wysoka dokładność, wymaga mocniejszego Raspberry Pi)
- Google Speech Recognition (online, wysoka dokładność)

### Silniki TTS (Text to Speech)
- eSpeak/eSpeak-NG (offline, szybki, mniej naturalny głos)
- Piper TTS (offline, naturalny głos, wymaga mocniejszego Raspberry Pi)
- Festival (offline, średnia jakość)
- Google TTS (online, wysoka jakość)

## Podstawowe komendy głosowe

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

Asystent można rozszerzyć o własne komendy poprzez system wtyczek.

## Podłączenie sprzętu

### Wymagane komponenty
- Raspberry Pi
- Czujnik temperatury i wilgotności DHT22 (podłączony do pinu GPIO4)
- LED (podłączony do pinu GPIO17)
- Opcjonalnie: przekaźnik dla wentylatora (podłączony do pinu GPIO18)
- Mikrofon USB (do rozpoznawania mowy)
- Głośnik (podłączony przez wyjście audio lub Bluetooth)

### Schemat podłączenia
``` 
Raspberry Pi:
- GPIO4 -> DHT22 (dane)
- GPIO17 -> LED (przez rezystor 220Ω)
- GPIO18 -> Przekaźnik (opcjonalnie)
- 3.3V -> DHT22 (zasilanie)
- GND -> DHT22 (masa)
- GND -> LED (masa)
- GND -> Przekaźnik (masa, opcjonalnie)
```

## Struktura projektu

```
rpi-stt-tts-shell/
├── rpi_stt_tts_shell/         # Pakiet główny
│   ├── __init__.py
│   ├── assistant.py           # Główny moduł asystenta
│   ├── stt/                   # Moduły rozpoznawania mowy
│   ├── tts/                   # Moduły syntezy mowy
│   ├── gpio_controller.py     # Kontroler GPIO
│   ├── sensors.py             # Obsługa czujników
│   └── plugins/               # Wtyczki rozszerzające funkcjonalność
├── tests/                     # Testy jednostkowe
├── docs/                      # Dokumentacja
├── examples/          # rpi-stt-tts-shell: Interaktywny Asystent Głosowy dla Raspberry Pi

[![Python 3.7+](https://img.shields.io/badge/python-3.7+-blue.svg)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Poetry](https://img.shields.io/badge/packaging-poetry-cyan.svg)](https://python-poetry.org/)

Kompleksowe rozwiązanie dla Raspberry Pi oferujące funkcje rozpoznawania mowy (STT - Speech to Text) i syntezowania mowy (TTS - Text to Speech), zaprojektowane jako interaktywna powłoka głosowa do kontroli urządzeń IoT.

## Funkcje

- 🎤 **Rozpoznawanie mowy** - przetwarzanie poleceń głosowych na tekst
- 🔊 **Synteza mowy** - odczytywanie odpowiedzi i powiadomień
- 🔄 **Tryb interaktywny** - ciągłe nasłuchiwanie i reagowanie na polecenia
- 📡 **Sterowanie GPIO** - kontrola urządzeń podłączonych do Raspberry Pi
- 🌡️ **Odczyt czujników** - integracja z czujnikami (np. DHT22, BME280)
- 📊 **Logowanie danych** - zapisywanie historii poleceń i odczytów czujników
- 🔌 **Plug-in API** - możliwość rozszerzania o własne moduły

## Wymagania systemowe

### Sprzęt
- Raspberry Pi (testowano na Raspberry Pi 3B+, 4 i Zero 2W)
- Mikrofon USB lub HAT mikrofonowy (np. ReSpeaker)
- Głośnik (wyjście audio 3.5mm, HDMI, USB lub Bluetooth)
- Opcjonalnie: czujniki, diody LED, przekaźniki, itp.

### Oprogramowanie
- Raspberry Pi OS (Bullseye lub nowszy)
- Python 3.7+
- Pakiety systemowe: portaudio, alsa-utils, espeak/espeak-ng

## Instalacja

### 1. Instalacja przy użyciu pip

```bash
pip install rpi-stt-tts-shell
```

### 2. Instalacja przy użyciu Poetry

```bash
poetry add rpi-stt-tts-shell
```

### 3. Instalacja z repozytorium

```bash
git clone https://github.com/user/rpi-stt-tts-shell.git
cd rpi-stt-tts-shell
make install  # lub: poetry install
```

### 4. Wdrożenie na wielu urządzeniach

Pakiet zawiera narzędzia do automatycznego wdrażania na wielu urządzeniach Raspberry Pi w sieci:

```bash
# Skanowanie sieci w poszukiwaniu urządzeń Raspberry Pi
make scan

# Wdrożenie na wszystkie znalezione urządzenia
make deploy
```

## Szybki start

### Podstawowe użycie

```python
from rpi_stt_tts_shell import VoiceAssistant

assistant = VoiceAssistant()
assistant.start()  # Uruchamia interaktywną pętlę nasłuchiwania
```

### Jako aplikacja konsolowa

```bash
# Po instalacji pakietu
rpi-stt-tts-shell

# Z uprawnieniami administratora (do obsługi GPIO)
sudo rpi-stt-tts-shell
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

## Obsługiwane silniki STT i TTS

### Silniki STT (Speech to Text)
- PocketSphinx (offline, lekki, niższa dokładność)
- Vosk (offline, średnia dokładność)
- Whisper (offline, wysoka dokładność, wymaga mocniejszego Raspberry Pi)
- Google Speech Recognition (online, wysoka dokładność)

### Silniki TTS (Text to Speech)
- eSpeak/eSpeak-NG (offline, szybki, mniej naturalny głos)
- Piper TTS (offline, naturalny głos, wymaga mocniejszego Raspberry Pi)
- Festival (offline, średnia jakość)
- Google TTS (online, wysoka jakość)

## Podstawowe komendy głosowe

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

Asystent można rozszerzyć o własne komendy poprzez system wtyczek.

## Podłączenie sprzętu

### Wymagane komponenty
- Raspberry Pi
- Czujnik temperatury i wilgotności DHT22 (podłączony do pinu GPIO4)
- LED (podłączony do pinu GPIO17)
- Opcjonalnie: przekaźnik dla wentylatora (podłączony do pinu GPIO18)
- Mikrofon USB (do rozpoznawania mowy)
- Głośnik (podłączony przez wyjście audio lub Bluetooth)

### Schemat podłączenia
``` 
Raspberry Pi:
- GPIO4 -> DHT22 (dane)
- GPIO17 -> LED (przez rezystor 220Ω)
- GPIO18 -> Przekaźnik (opcjonalnie)
- 3.3V -> DHT22 (zasilanie)
- GND -> DHT22 (masa)
- GND -> LED (masa)
- GND -> Przekaźnik (masa, opcjonalnie)
```

## Struktura projektu

```
rpi-stt-tts-shell/
├── rpi_stt_tts_shell/         # Pakiet główny
│   ├── __init__.py
│   ├── assistant.py           # Główny moduł asystenta
│   ├── stt/                   # Moduły rozpoznawania mowy
│   ├── tts/                   # Moduły syntezy mowy
│   ├── gpio_controller.py     # Kontroler GPIO
│   ├── sensors.py             # Obsługa czujników
│   └── plugins/               # Wtyczki rozszerzające funkcjonalność
├── tests/                     # Testy jednostkowe
├── docs/                      # Dokumentacja
├── examples/                  # Przykłady użycia
├── scan.sh                    # Skrypt skanujący sieć
├── deploy.sh                  # Skrypt wdrażający
├── test_script.sh             # Skrypt testowy
├── Makefile                   # Makefile z zadaniami automatyzacji
├── pyproject.toml             # Konfiguracja Poetry
├── README.md                  # Ten plik
└── LICENSE                    # Licencja projektu
```

## Narzędzia deweloperskie

Projekt zawiera narzędzia ułatwiające rozwój i wdrażanie:

- **scan.sh** - Skanuje sieć lokalną w poszukiwaniu urządzeń Raspberry Pi
- **deploy.sh** - Wdraża projekt na wykryte urządzenia Raspberry Pi
- **test_script.sh** - Testuje wdrożony projekt na zdalnych urządzeniach
- **Makefile** - Automatyzuje typowe zadania developerskie i wdrożeniowe

### Użycie Makefile

```bash
# Instalacja projektu lokalnie
make install

# Skanowanie sieci
make scan

# Wdrożenie projektu
make deploy

# Uruchomienie aplikacji
make run

# Generowanie dokumentacji
make docs

# Wyświetlenie wszystkich dostępnych celów
make help
```

## Rozwiązywanie problemów

### Popularne problemy

1. **Problem z rozpoznawaniem mowy**
    - Upewnij się, że mikrofon jest prawidłowo podłączony
    - Sprawdź poziom głośności mikrofonu w systemie: `alsamixer`
    - Przetestuj mikrofon: `arecord -d 5 test.wav && aplay test.wav`
    - Spróbuj inny silnik STT w konfiguracji

2. **Czujnik DHT nie działa**
    - Sprawdź podłączenie przewodów
    - Upewnij się, że biblioteka ma wymagane uprawnienia (uruchom z sudo)
    - Zainstaluj wymagane pakiety: `sudo apt-get install libgpiod2`

3. **Błędy związane z GPIO**
    - Uruchom aplikację z uprawnieniami administratora: `sudo rpi-stt-tts-shell`
    - Sprawdź, czy piny są prawidłowo skonfigurowane w pliku config.json
    - Użyj `gpio readall` do sprawdzenia stanu pinów

4. **Problemy z syntezą mowy**
    - Sprawdź, czy głośnik jest podłączony i działa: `speaker-test -t wav`
    - Upewnij się, że zainstalowano wymagane pakiety: `sudo apt-get install espeak`
    - Dostosuj głośność w pliku konfiguracyjnym

5. **Problemy z wdrażaniem**
    - Upewnij się, że urządzenia docelowe są dostępne w sieci
    - Sprawdź, czy dane logowania SSH są poprawne
    - Przejrzyj logi wdrożenia w katalogu `deployment_logs/`

## Integracja z innymi systemami

Asystent może być zintegrowany z popularnymi systemami automatyki domowej:

- **Home Assistant** - przez MQTT lub REST API
- **Node-RED** - przez MQTT lub websockets
- **Domoticz** - przez MQTT

Przykłady integracji znajdują się w katalogu `examples/integrations/`.

## Licencja

Ten projekt jest dostępny na licencji Apache 2.
Zobacz plik [LICENSE](LICENSE), aby uzyskać więcej informacji.


## Współtworzenie

Wkłady w projekt są mile widziane. Proszę zapoznać się z wytycznymi dotyczącymi współtworzenia w pliku CONTRIBUTING.md.

## Autorzy

- Tom Sapletta

<!--
Author: tom-sapletta-com
Purpose: development setup instructions for the project.
-->