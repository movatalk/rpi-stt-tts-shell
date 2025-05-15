# rpi-stt-tts-shell: Asystent Głosowy dla Raspberry Pi i Radxa

<p align="center">
  <img src="https://via.placeholder.com/150x150.png?text=RPI+STT" alt="Logo projektu" width="150"/>
</p>

<p align="center">
  <a href="#funkcje"><img src="https://img.shields.io/badge/Funkcje-green.svg" alt="Funkcje"></a>
  <a href="#instalacja"><img src="https://img.shields.io/badge/Instalacja-blue.svg" alt="Instalacja"></a>
  <a href="#konfiguracja"><img src="https://img.shields.io/badge/Konfiguracja-orange.svg" alt="Konfiguracja"></a>
  <a href="#użycie"><img src="https://img.shields.io/badge/Użycie-red.svg" alt="Użycie"></a>
  <a href="#dokumentacja"><img src="https://img.shields.io/badge/Dokumentacja-purple.svg" alt="Dokumentacja"></a>
</p>

<p align="center">
  <a href="https://github.com/movatalk/rpi-stt-tts-shell/blob/main/LICENSE"><img src="https://img.shields.io/badge/Licencja-Apache_2.0-yellow.svg" alt="Licencja"></a>
  <a href="https://python-poetry.org"><img src="https://img.shields.io/badge/Zarządzanie_pakietami-Poetry-cyan.svg" alt="Poetry"></a>
  <a href="https://github.com/movatalk/rpi-stt-tts-shell/releases"><img src="https://img.shields.io/badge/Wersja-0.1.0-brightgreen.svg" alt="Version"></a>
</p>

## 📋 Menu

- [Wprowadzenie](#-wprowadzenie)
- [Funkcje](#-funkcje)
- [Wspierane urządzenia](#-wspierane-urządzenia)
  - [Porównanie Radxa ZERO 3W i Raspberry Pi Zero 2W](#porównanie-radxa-zero-3w-i-raspberry-pi-zero-2w)
  - [Wsparcie dla nakładek audio](#wsparcie-dla-nakładek-audio)
- [Instalacja](#-instalacja)
  - [Instalacja na Raspberry Pi](#instalacja-na-raspberry-pi)
  - [Instalacja na Radxa](#instalacja-na-radxa)
  - [Wdrożenie na wielu urządzeniach](#wdrożenie-na-wielu-urządzeniach)
- [Konfiguracja](#-konfiguracja)
  - [Konfiguracja ReSpeaker](#konfiguracja-respeaker)
  - [Konfiguracja Interfejsów](#konfiguracja-interfejsów)
  - [Plik konfiguracyjny](#plik-konfiguracyjny)
- [Użycie](#-użycie)
  - [Podstawowa obsługa](#podstawowa-obsługa)
  - [Interfejs programistyczny (API)](#interfejs-programistyczny-api)
  - [Przykłady użycia](#przykłady-użycia)
- [Architektura pakietu](#-architektura-pakietu)
  - [Struktura projektu](#struktura-projektu)
  - [Obsługiwane silniki STT i TTS](#obsługiwane-silniki-stt-i-tts)
  - [Komendy głosowe](#komendy-głosowe)
- [Narzędzia](#-narzędzia)
  - [scan.sh - Skaner urządzeń](#scansh---skaner-urządzeń)
  - [deploy.sh - Wdrażanie projektu](#deploysh---wdrażanie-projektu)
  - [test_script.sh - Testowanie](#test_scriptsh---testowanie)
- [Rozwiązywanie problemów](#-rozwiązywanie-problemów)
  - [Problemy z mikrofonem](#problemy-z-mikrofonem)
  - [Problemy z ReSpeaker](#problemy-z-respeaker)
  - [Problemy z GPIO](#problemy-z-gpio)
  - [Problemy z wdrażaniem](#problemy-z-wdrażaniem)
- [Rozwój](#-rozwój)
  - [Tworzenie własnych wtyczek](#tworzenie-własnych-wtyczek)
  - [Integracja z systemami domowymi](#integracja-z-systemami-domowymi)
- [Licencja](#-licencja)

## 🌟 Wprowadzenie

`rpi-stt-tts-shell` to wszechstronny pakiet oferujący funkcje rozpoznawania mowy (STT - Speech to Text) i syntezowania mowy (TTS - Text to Speech) specjalnie zaprojektowany dla urządzeń Raspberry Pi i Radxa. Pakiet umożliwia stworzenie interaktywnego asystenta głosowego zdolnego do sterowania urządzeniami IoT, odczytywania danych z czujników oraz reagowania na polecenia głosowe użytkownika.

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

### Porównanie Radxa ZERO 3W i Raspberry Pi Zero 2W

| Feature | Radxa ZERO 3W | Raspberry Pi Zero 2 W |
|---------|--------------|----------------------|
| **SoC** | Rockchip RK3566 | Broadcom BCM2710A1 |
| **CPU** | Quad-core Cortex-A55, up to 1.6GHz | Quad-core Cortex-A53, up to 1.0GHz |
| **GPU** | Arm Mali™‑G52‑2EE | Broadcom VideoCore IV |
| **GPU Support** | OpenGL® ES1.1/2.0/3.2, Vulkan® 1.1, OpenCL™ 2.0 | OpenGL ES 2.0 |
| **RAM** | 1/2/4/8 GB LPDDR4 | 512MB LPDDR2 |
| **Storage** | eMMC on Board: 0/8/16/32/64 GB <br> microSD Card | microSD Card |
| **Display** | Micro HDMI Interface: Supports 1080p60 output | Mini HDMI Interface |
| **Ethernet** | Gigabit Ethernet, Supports POE (POE requires additional optional HAT) | No built-in Ethernet |
| **Wireless** | Wi-Fi 6 (802.11 b/g/n) <br> BT 5.0 with BLE | Wi-Fi 4 (802.11 b/g/n) <br> BT 4.2 with BLE |
| **USB** | - USB 2.0 Type-C OTG x1 <br> - USB 3.0 Type-C HOST x1 | Micro USB 2.0 OTG |
| **Camera** | 1x4 lane MIPI CSI | CSI connector |
| **Size** | 65mm x 30mm | 65mm x 30mm |

### Wsparcie dla nakładek audio
- ReSpeaker 2-Mic Pi HAT
- ReSpeaker 4-Mic Array
- ReSpeaker Mic Array v2.0
- Standardowe mikrofony USB

## 📥 Instalacja

### Instalacja na Raspberry Pi

#### Standardowa instalacja:
```bash
curl -sSL https://raw.githubusercontent.com/movatalk/rpi-stt-tts-shell/main/setup.sh | bash
```

#### Szybka instalacja:
```bash
curl -sSL https://raw.githubusercontent.com/movatalk/rpi-stt-tts-shell/main/quick.sh | bash
```

#### Z użyciem pip:
```bash
pip install rpi-stt-tts-shell
```

#### Z użyciem Poetry:
```bash
poetry add rpi-stt-tts-shell
```

### Instalacja na Radxa

#### Standardowa instalacja:
```bash
curl -sSL https://raw.githubusercontent.com/movatalk/rpi-stt-tts-shell/main/setup-radxa-poetry.sh | bash
```

#### Szybka instalacja:
```bash
curl -sSL https://raw.githubusercontent.com/movatalk/rpi-stt-tts-shell/main/quick-radxa.sh | bash
```

### Wdrożenie na wielu urządzeniach

Pakiet zawiera narzędzia do automatycznego wdrażania na wielu urządzeniach:

1. Sklonuj repozytorium:
```bash
git clone https://github.com/movatalk/rpi-stt-tts-shell.git
cd rpi-stt-tts-shell
```

2. Skanuj sieć w poszukiwaniu urządzeń:
```bash
make scan
```

3. Wdróż projekt na wszystkie znalezione urządzenia:
```bash
make deploy
```

## ⚙️ Konfiguracja

### Konfiguracja ReSpeaker

Dla urządzeń z nakładką ReSpeaker 2-Mic Pi HAT:

#### Raspberry Pi:
```bash
curl -sSL https://raw.githubusercontent.com/movatalk/rpi-stt-tts-shell/main/setup_respeaker.sh | sudo bash
```

#### Radxa:
```bash
curl -sSL https://raw.githubusercontent.com/movatalk/rpi-stt-tts-shell/main/setup_radxa_respeaker.sh | sudo bash
```

### Konfiguracja Interfejsów

#### Raspberry Pi:
```bash
curl -sSL https://raw.githubusercontent.com/movatalk/rpi-stt-tts-shell/main/config.sh | bash
```

#### Radxa:
```bash
curl -sSL https://raw.githubusercontent.com/movatalk/rpi-stt-tts-shell/main/config-radxa.sh | bash
```

### Plik konfiguracyjny

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

### Podstawowa obsługa

#### Jako moduł Python:
```python
from rpi_stt_tts_shell import VoiceAssistant

assistant = VoiceAssistant()
assistant.start()  # Uruchamia interaktywną pętlę nasłuchiwania
```

#### Jako aplikacja konsolowa:
```bash
# Po instalacji pakietu
rpi-stt-tts-shell

# Z uprawnieniami administratora (do obsługi GPIO)
sudo rpi-stt-tts-shell
```

### Interfejs programistyczny (API)

#### Inicjalizacja asystenta

```python
from rpi_stt_tts_shell import VoiceAssistant

# Inicjalizacja z domyślną konfiguracją
assistant = VoiceAssistant()

# Inicjalizacja z własną konfiguracją
assistant = VoiceAssistant(config_path='my_config.json')

# Uruchomienie asystenta
assistant.start()
```

#### Dodawanie własnych komend

```python
from rpi_stt_tts_shell import VoiceAssistant, Command

assistant = VoiceAssistant()

# Dodawanie prostej komendy
@assistant.command("powiedz cześć")
def say_hello(assistant):
    assistant.speak("Cześć, miło Cię poznać!")

# Dodawanie komendy z parametrami
@assistant.command("ustaw minutnik na {minutes} minut")
def set_timer(assistant, minutes):
    # Konwersja na liczbę
    mins = int(minutes)
    assistant.speak(f"Ustawiam minutnik na {mins} minut")
    # Logika minutnika...

# Uruchomienie asystenta
assistant.start()
```

### Przykłady użycia

#### Obsługa GPIO

```python
from rpi_stt_tts_shell import VoiceAssistant, GPIOController

assistant = VoiceAssistant()
gpio = GPIOController()

# Konfiguracja pinów
gpio.setup(17, gpio.OUT)  # LED
gpio.setup(18, gpio.OUT)  # Wentylator

@assistant.command("włącz światło")
def light_on(assistant):
    gpio.output(17, gpio.HIGH)
    assistant.speak("Światło włączone")

@assistant.command("wyłącz światło")
def light_off(assistant):
    gpio.output(17, gpio.LOW)
    assistant.speak("Światło wyłączone")

assistant.start()
```

#### Obsługa czujników

```python
from rpi_stt_tts_shell import VoiceAssistant, DHT22Sensor

assistant = VoiceAssistant()
sensor = DHT22Sensor(pin=4)

@assistant.command("jaka jest temperatura")
def get_temperature(assistant):
    temp = sensor.get_temperature()
    assistant.speak(f"Aktualna temperatura wynosi {temp:.1f} stopni Celsjusza")

@assistant.command("jaka jest wilgotność")
def get_humidity(assistant):
    humidity = sensor.get_humidity()
    assistant.speak(f"Aktualna wilgotność wynosi {humidity:.1f} procent")

assistant.start()
```

## 📁 Architektura pakietu

### Struktura projektu

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
├── tests/                     # Testy jednostkowe
├── docs/                      # Dokumentacja
├── examples/                  # Przykłady użycia
├── scripts/                   # Skrypty pomocnicze
│   ├── setup.sh               # Instalacja na Raspberry Pi
│   ├── setup-radxa-poetry.sh  # Instalacja na Radxa
│   ├── quick.sh               # Szybka instalacja na Raspberry Pi
│   ├── quick-radxa.sh         # Szybka instalacja na Radxa
│   ├── config.sh              # Konfiguracja Raspberry Pi
│   ├── config-radxa.sh        # Konfiguracja Radxa
│   ├── setup_respeaker.sh     # Konfiguracja ReSpeaker dla Raspberry Pi
│   └── setup_radxa_respeaker.sh  # Konfiguracja ReSpeaker dla Radxa
├── scan.sh                    # Skrypt skanujący sieć
├── deploy.sh                  # Skrypt wdrożeniowy
├── test_script.sh             # Skrypt testowy
├── Makefile                   # Zadania automatyzacji
├── pyproject.toml             # Konfiguracja Poetry
└── README.md                  # Ten plik
```

### Obsługiwane silniki STT i TTS

#### Silniki STT (Speech to Text)
- **PocketSphinx** (offline, lekki, niższa dokładność)
- **Vosk** (offline, średnia dokładność)
- **Whisper** (offline, wysoka dokładność, wymaga mocniejszego Raspberry Pi)
- **Google Speech Recognition** (online, wysoka dokładność)

#### Silniki TTS (Text to Speech)
- **eSpeak/eSpeak-NG** (offline, szybki, mniej naturalny głos)
- **Piper TTS** (offline, naturalny głos, wymaga mocniejszego Raspberry Pi)
- **Festival** (offline, średnia jakość)
- **Google TTS** (online, wysoka jakość)

### Komendy głosowe

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

## 🛠️ Narzędzia

### scan.sh - Skaner urządzeń

Skrypt `scan.sh` skanuje sieć lokalną, wykrywa urządzenia Raspberry Pi i Radxa i zapisuje informacje o nich do pliku CSV.

#### Opcje:
- `-r, --range RANGE` - skanuj podany zakres sieci (np. 192.168.1.0/24)
- `-o, --output FILE` - zapisz wyniki do podanego pliku CSV (domyślnie: raspberry_pi_devices.csv)
- `-h, --help` - wyświetl pomoc

#### Przykłady użycia:
```bash
# Standardowe użycie (automatyczne wykrywanie sieci)
./scan.sh

# Skanowanie konkretnego zakresu sieci
./scan.sh -r 10.0.0.0/24

# Zapisanie wyników do niestandardowego pliku
./scan.sh -o moje_urzadzenia.csv
```

### deploy.sh - Wdrażanie projektu

Skrypt `deploy.sh` służy do automatycznego wdrażania, testowania i logowania projektu na urządzeniach wykrytych przez skrypt `scan.sh`.

#### Opcje:
- `-f, --file FILE` - użyj podanego pliku CSV z urządzeniami (domyślnie: raspberry_pi_devices.csv)
- `-u, --user USER` - użyj podanej nazwy użytkownika SSH (domyślnie: pi)
- `-p, --password PASS` - użyj podanego hasła SSH (domyślnie: raspberry)
- `-d, --dir DIR` - użyj podanego katalogu projektu (domyślnie: project_files)
- `-r, --remote-dir DIR` - użyj podanego katalogu zdalnego (domyślnie: /home/pi/deployed_project)
- `-i, --ip IP` - wdróż tylko na konkretne urządzenie o podanym IP
- `-h, --help` - wyświetl pomoc

#### Przykłady użycia:
```bash
# Standardowe użycie (wdrożenie na wszystkie urządzenia z pliku CSV)
./deploy.sh

# Wdrożenie z niestandardowymi parametrami
./deploy.sh -u admin -p tajnehaslo -d ~/moj_projekt -r /opt/aplikacja

# Wdrożenie tylko na jedno urządzenie
./deploy.sh -i 192.168.1.100
```

### test_script.sh - Testowanie

Skrypt `test_script.sh` jest uruchamiany na zdalnych urządzeniach po wdrożeniu projektu i wykonuje serię testów:

- Testy systemowe (wersja OS, model, połączenie internetowe)
- Testy zależności systemowych (Python, biblioteki)
- Testy struktury projektu (obecność plików i katalogów)
- Testy portów i usług
- Testy specyficzne dla projektu

## 🔧 Rozwiązywanie problemów

### Problemy z mikrofonem
- Upewnij się, że mikrofon jest prawidłowo podłączony
- Sprawdź poziom głośności mikrofonu w systemie: `alsamixer`
- Przetestuj mikrofon: `arecord -d 5 test.wav && aplay test.wav`
- Spróbuj inny silnik STT w konfiguracji

### Problemy z ReSpeaker
- Zweryfikuj połączenia sprzętowe
- Uruchom ponownie konfigurację: `sudo ./setup_radxa_respeaker.sh` (dla Radxa) lub `sudo ./setup_respeaker.sh` (dla Raspberry Pi)
- Sprawdź wyjście audio: `speaker-test -t wav`

### Problemy z GPIO
- Upewnij się, że używasz właściwej biblioteki (RPi.GPIO dla Raspberry Pi, gpiod dla Radxa)
- Uruchom aplikację z uprawnieniami administratora: `sudo rpi-stt-tts-shell`
- Sprawdź, czy piny są prawidłowo skonfigurowane w pliku config.json
- Użyj `gpio readall` (Raspberry Pi) lub `gpioinfo` (Radxa) do sprawdzenia stanu pinów

### Problemy z wdrażaniem
- Upewnij się, że urządzenia docelowe są dostępne w sieci
- Sprawdź, czy dane logowania SSH są poprawne
- Przejrzyj logi wdrożenia w katalogu `deployment_logs/`

### Problemy z pamięcią na słabszych urządzeniach

Jeśli występują problemy z pamięcią podczas instalacji dużych pakietów:

```bash
# Zwiększenie przestrzeni swap
sudo dphys-swapfile swapoff
sudo sed -i 's/CONF_SWAPSIZE=.*/CONF_SWAPSIZE=1024/' /etc/dphys-swapfile
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
```

## 📈 Rozwój

### Tworzenie własnych wtyczek

Asystent może być rozszerzony o dodatkowe funkcje poprzez system wtyczek:

```python
# plugins/weather.py
from rpi_stt_tts_shell import Plugin

class WeatherPlugin(Plugin):
    def __init__(self, assistant):
        super().__init__(assistant)
        self.name = "weather"
        self.register_commands()
    
    def register_commands(self):
        self.register_command("jaka jest pogoda", self.get_weather)
        self.register_command("jaka będzie pogoda jutro", self.get_forecast)
    
    def get_weather(self, _):
        # Implementacja sprawdzania pogody
        self.assistant.speak("Obecnie jest słonecznie, 22 stopnie Celsjusza")
    
    def get_forecast(self, _):
        # Implementacja prognozy
        self.assistant.speak("Jutro będzie pochmurno z przejaśnieniami, 19 stopni Celsjusza")

# Rejestracja wtyczki w głównym pliku
from rpi_stt_tts_shell import VoiceAssistant
from plugins.weather import WeatherPlugin

assistant = VoiceAssistant()
assistant.register_plugin(WeatherPlugin(assistant))
assistant.start()
```

### Integracja z systemami domowymi

Asystent może być zintegrowany z popularnymi systemami automatyki domowej:

```python
# Integracja z MQTT (np. dla Home Assistant)
from rpi_stt_tts_shell import VoiceAssistant
import paho.mqtt.client as mqtt

assistant = VoiceAssistant()
mqtt_client = mqtt.Client()
mqtt_client.connect("192.168.1.10", 1883, 60)
mqtt_client.loop_start()

@assistant.command("włącz światło w salonie")
def living_room_light_on(assistant):
    mqtt_client.publish("home/livingroom/light", "ON")
    assistant.speak("Włączam światło w salonie")

@assistant.command("wyłącz światło w salonie")
def living_room_light_off(assistant):
    mqtt_client.publish("home/livingroom/light", "OFF")
    assistant.speak("Wyłączam światło w salonie")

assistant.start()
```

## 📄 Licencja

Ten projekt jest dostępny na licencji Apache 2. Zobacz plik [LICENSE](LICENSE) dla szczegółów.

---

<p align="center">
  Stworzono z ❤️ przez <a href="https://github.com/movatalk">Movatalk</a>
</p>