# rpi-stt-tts-shell: Interaktywny Asystent Głosowy dla Raspberry Pi i Radxa

[![Python 3.7+](https://img.shields.io/badge/python-3.7+-blue.svg)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Poetry](https://img.shields.io/badge/packaging-poetry-cyan.svg)](https://python-poetry.org/)

## 📋 Spis treści

- [Wprowadzenie](#-wprowadzenie)
- [Funkcje](#-funkcje)
- [Wspierane urządzenia](#-wspierane-urządzenia)
- [Instalacja](#-instalacja)
- [Konfiguracja](#-konfiguracja)
- [Użycie](#-użycie)
- [Rozwój](#-rozwój)
- [Rozwiązywanie problemów](#-rozwiązywanie-problemów)
- [Licencja](#-licencja)

## 🌟 Wprowadzenie

`rpi-stt-tts-shell` to kompleksowe narzędzie umożliwiające tworzenie interaktywnych asystentów głosowych na platformach Raspberry Pi i Radxa. Projekt dostarcza funkcje rozpoznawania mowy (STT - Speech to Text) i syntezowania mowy (TTS - Text to Speech), umożliwiając kontrolę urządzeń IoT, odczytywanie danych z czujników i interakcję poprzez komendy głosowe.

## 🎯 Funkcje

- 🎤 **Rozpoznawanie mowy** - przetwarzanie poleceń głosowych na tekst
- 🔊 **Synteza mowy** - odczytywanie odpowiedzi i powiadomień
- 🔄 **Tryb interaktywny** - ciągłe nasłuchiwanie i reagowanie na polecenia
- 📡 **Sterowanie GPIO** - kontrola urządzeń podłączonych do Raspberry Pi/Radxa
- 🌡️ **Odczyt czujników** - integracja z czujnikami (np. DHT22, BME280)
- 📊 **Logowanie danych** - zapisywanie historii poleceń i odczytów czujników
- 🔌 **Plug-in API** - możliwość rozszerzania o własne moduły
- 🌐 **Automatyczne wdrażanie** - narzędzia do skanowania i wdrażania na wielu urządzeniach

## 🖥️ Wspierane urządzenia

### Raspberry Pi
- Raspberry Pi 3B+
- Raspberry Pi 4
- Raspberry Pi Zero 2W

### Radxa
- Radxa ZERO 3W
- Radxa ZERO 3E

### Obsługiwane nakładki audio
- ReSpeaker 2-Mic Pi HAT
- ReSpeaker 4-Mic Array
- Standardowe mikrofony USB

## 📥 Instalacja

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
git clone https://github.com/movatalk/rpi-stt-tts-shell.git
cd rpi-stt-tts-shell
make install  # lub: poetry install
```

### 4. Wdrożenie na wielu urządzeniach
```bash
# Skanowanie sieci w poszukiwaniu urządzeń
make scan

# Wdrożenie na wszystkie znalezione urządzenia
make deploy
```

## ⚙️ Konfiguracja

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

## 🚀 Użycie

### Podstawowe użycie w Pythonie
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

## 🛠 Rozwój

### Struktura projektu
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
├── Makefile                   # Zadania automatyzacji
└── pyproject.toml             # Konfiguracja Poetry
```

### Tworzenie własnych wtyczek
```python
from rpi_stt_tts_shell import Plugin

class WeatherPlugin(Plugin):
    def __init__(self, assistant):
        super().__init__(assistant)
        self.name = "weather"
        self.register_commands()
    
    def register_commands(self):
        self.register_command("jaka jest pogoda", self.get_weather)
    
    def get_weather(self, _):
        self.assistant.speak("Obecnie jest słonecznie, 22 stopnie")
```

## 🔧 Rozwiązywanie problemów

### Problem z rozpoznawaniem mowy
- Upewnij się, że mikrofon jest prawidłowo podłączony
- Sprawdź poziom głośności mikrofonu: `alsamixer`
- Przetestuj mikrofon: `arecord -d 5 test.wav && aplay test.wav`

### Błędy GPIO
- Upewnij się, że używasz właściwej biblioteki (RPi.GPIO dla Raspberry Pi, gpiod dla Radxa)
- Uruchom aplikację z uprawnieniami `sudo`

## 📄 Licencja

Ten projekt jest dostępny na licencji MIT. 
Szczegóły w pliku [LICENSE](LICENSE).

---

<p align="center">
  Stworzono z ❤️ przez <a href="https://github.com/movatalk">Movatalk</a>
</p>