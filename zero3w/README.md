# Konfiguracja i instalacja dla Radxa ZERO 3W/3E
Ten katalog zawiera skrypty do konfiguracji i instalacji oprogramowania na urządzeniach Radxa ZERO 3W/3E,
z uwzględnieniem specyfiki tych urządzeń.

+ [ZERO 3 - Radxa Docs](https://docs.radxa.com/zero/zero3)


[ZERO 3 | Radxa Docs](https://docs.radxa.com/en/zero/zero3)

Product Description

-   The Radxa ZERO 3W/3E is an ultra-small, high-performance single board computer based on the Rockchip RK3566, with a compact form factor and rich interfaces.
-   Tailored for a diverse user base including manufacturers, IoT developers, hobbyists, and PC DIY enthusiasts, the Radxa ZERO 3W/3E is an ultra-small, versatile platform that can be used for a wide variety of applications, including IoT devices, machine learning edge computing, home automation, education, and entertainment.
-   The ZERO 3W and ZERO 3E are basically the samae size and model, but differ only in storage and network interfaces. For details, please refer to the Features section of this article.

### Physical Photos

-   ZERO 3W
-   ZERO 3E

-   **Radxa ZERO 3W** ![ZERO 3W Overview](https://docs.radxa.com/en/assets/images/radxa_zero_3w-84a1e0f01c8381ff1a202d4322f9ed17.webp)

-   **Radxa ZERO 3E**
    
    ![ZERO 3E Overview](https://docs.radxa.com/en/assets/images/radxa_zero_3e-5dd80fbef63346e2ccb826313afd5683.webp)
    

### Chip Block Diagram

![RK3566 block diagram](https://docs.radxa.com/en/assets/images/rk3566_block_diagram-de2389bba93c061b1646c4607be41c95.webp)

### Features
[ZERO 3 | Radxa Docs](https://docs.radxa.com/en/zero/zero3)

| Feature | Radxa ZERO 3W | Radxa ZERO 3E |
|---------|--------------|--------------|
| **SoC** | Rockchip RK3566 | Rockchip RK3566 |
| **CPU** | Quad-core Cortex-A55, up to 1.6GHz | Quad-core Cortex-A55, up to 1.6GHz |
| **GPU** | Arm Mali™‑G52‑2EE | Arm Mali™‑G52‑2EE |
| **GPU Support** | OpenGL® ES1.1/2.0/3.2, Vulkan® 1.1, OpenCL™ 2.0 | OpenGL® ES1.1/2.0/3.2, Vulkan® 1.1, OpenCL™ 2.0 |
| **RAM** | 1/2/4/8 GB LPDDR4 | 1/2/4/8 GB LPDDR4 |
| **Storage** | eMMC on Board: 0/8/16/32/64 GB <br> microSD Card | eMMC on Board: 0/8/16/32/64 GB <br> microSD Card |
| **Display** | Micro HDMI Interface: Supports 1080p60 output | Micro HDMI Interface: Supports 1080p60 output |
| **Ethernet** | Gigabit Ethernet, Supports POE (POE requires additional optional HAT) | Gigabit Ethernet, Supports POE (POE requires additional optional HAT) |
| **Wireless** | Wi-Fi 6 (802.11 b/g/n) <br> BT 5.0 with BLE | Wi-Fi 6 (802.11 b/g/n) <br> BT 5.0 with BLE |
| **USB** | - USB 2.0 Type-C OTG x1 <br> - USB 3.0 Type-C HOST x1 | - USB 2.0 Type-C OTG x1 <br> - USB 3.0 Type-C HOST x1 |
| **Camera** | 1x4 lane MIPI CSI | 1x4 lane MIPI CSI |
| **Other Interfaces** | 40 Pin extends Header | 40 Pin extends Header |
| **Power** | Requires 5V/2A power adapter | Requires 5V/2A power adapter |
| **Size** | 65mm x 30mm | 65mm x 30mm |

- Czterordzeniowy procesor Cortex-A55 (do 1.6GHz)
- 1/2/4/8 GB pamięci RAM LPDDR4
- Pamięć eMMC (0/8/16/32/64 GB) i slot na kartę microSD
- WiFi 6 (802.11 b/g/n) i Bluetooth 5.0
- Interfejs HDMI micro (wyjście 1080p60)
- Port Gigabit Ethernet (z obsługą PoE przy użyciu dodatkowego HAT)
- Interfejsy USB: 1x USB 2.0 Type-C OTG, 1x USB 3.0 Type-C HOST
- 40-pinowe złącze rozszerzeń (kompatybilne z Raspberry Pi)

## Główne różnice między Radxa ZERO 3W/3E a Raspberry Pi

1. **Układ SoC**: 
   - Radxa: Rockchip RK3566
   - Raspberry Pi: Broadcom BCM2710/2711

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

### Obsługa czujników

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

## Narzędzia wdrożeniowe

### scan.sh - Skaner Raspberry Pi

Skrypt `scan.sh` skanuje sieć lokalną, wykrywa urządzenia Raspberry Pi i zapisuje informacje o nich do pliku CSV.

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

Skrypt `deploy.sh` służy do automatycznego wdrażania, testowania i logowania projektu na urządzeniach Raspberry Pi wykrytych przez skrypt `scan.sh`.

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

### test_script.sh - Testowanie projektu

Skrypt `test_script.sh` jest uruchamiany na zdalnych urządzeniach po wdrożeniu projektu i wykonuje serię testów, aby upewnić się, że wszystko działa prawidłowo.

#### Funkcje testowe:
- Testy systemowe (wersja Raspberry Pi OS, model, połączenie internetowe)
- Testy zależności systemowych (Python, biblioteki)
- Testy struktury projektu (obecność plików i katalogów)
- Testy portów i usług
- Testy specyficzne dla projektu

### Makefile - Automatyzacja zadań

Plik `Makefile` zawiera zestaw zadań automatyzujących typowe operacje związane z rozwojem i wdrażaniem projektu.

#### Główne cele:
- `install` - instalacja projektu lokalnie
- `scan` - skanowanie sieci w poszukiwaniu urządzeń Raspberry Pi
- `deploy` - wdrażanie projektu na wykryte urządzenia
- `test` - uruchamianie testów lokalnie
- `docs` - generowanie dokumentacji
- `run` - uruchamianie aplikacji
- `clean` - czyszczenie plików tymczasowych
- `help` - wyświetlenie dostępnych celów

## Rozwiązywanie problemów

### Problem z rozpoznawaniem mowy
- Upewnij się, że mikrofon jest prawidłowo podłączony
- Sprawdź poziom głośności mikrofonu w systemie: `alsamixer`
- Przetestuj mikrofon: `arecord -d 5 test.wav && aplay test.wav`
- Spróbuj inny silnik STT w konfiguracji

### Czujnik DHT nie działa
- Sprawdź podłączenie przewodów
- Upewnij się, że biblioteka ma wymagane uprawnienia (uruchom z sudo)
- Zainstaluj wymagane pakiety: `sudo apt-get install libgpiod2`

### Błędy związane z GPIO
- Uruchom aplikację z uprawnieniami administratora: `sudo rpi-stt-tts-shell`
- Sprawdź, czy piny są prawidłowo skonfigurowane w pliku config.json
- Użyj `gpio readall` do sprawdzenia stanu pinów

### Problemy z syntezą mowy
- Sprawdź, czy głośnik jest podłączony i działa: `speaker-test -t wav`
- Upewnij się, że zainstalowano wymagane pakiety: `sudo apt-get install espeak`
- Dostosuj głośność w pliku konfiguracyjnym

### Problemy z wdrażaniem
- Upewnij się, że urządzenia docelowe są dostępne w sieci
- Sprawdź, czy dane logowania SSH są poprawne
- Przejrzyj logi wdrożenia w katalogu `deployment_logs/`

## Funkcje zaawansowane

### System wtyczek

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

## Przykłady użycia

### Prosty asystent głosowy

```python
# Minimalny przykład asystenta głosowego
from rpi_stt_tts_shell import VoiceAssistant

assistant = VoiceAssistant()

@assistant.command("która godzina")
def tell_time(assistant):
    from datetime import datetime
    current_time = datetime.now().strftime("%H:%M")
    assistant.speak(f"Aktualna godzina to {current_time}")

@assistant.command("dzisiejsza data")
def tell_date(assistant):
    from datetime import datetime
    current_date = datetime.now().strftime("%d %B %Y")
    assistant.speak(f"Dzisiejsza data to {current_date}")

assistant.start()
```

### Sterowanie oświetleniem

```python
# Sterowanie oświetleniem przez GPIO
from rpi_stt_tts_shell import VoiceAssistant, GPIOController

assistant = VoiceAssistant()
gpio = GPIOController()

# Konfiguracja pinów dla różnych świateł
LIGHTS = {
    "salon": 17,
    "kuchnia": 18,
    "sypialnia": 27,
    "łazienka": 22
}

# Inicjalizacja pinów
for pin in LIGHTS.values():
    gpio.setup(pin, gpio.OUT)
    gpio.output(pin, gpio.LOW)  # Wyłącz wszystkie światła na początku

# Dynamiczne tworzenie komend dla każdego światła
for room, pin in LIGHTS.items():
    @assistant.command(f"włącz światło w {room}")
    def light_on(assistant, room=room, pin=pin):
        gpio.output(pin, gpio.HIGH)
        assistant.speak(f"Włączam światło w {room}")
    
    @assistant.command(f"wyłącz światło w {room}")
    def light_off(assistant, room=room, pin=pin):
        gpio.output(pin, gpio.LOW)
        assistant.speak(f"Wyłączam światło w {room}")

# Komenda do wyłączenia wszystkich świateł
@assistant.command("wyłącz wszystkie światła")
def all_lights_off(assistant):
    for pin in LIGHTS.values():
        gpio.output(pin, gpio.LOW)
    assistant.speak("Wyłączam wszystkie światła")

assistant.start()
```

## Zasoby dodatkowe

### Dokumentacja API
Pełna dokumentacja API jest dostępna w katalogu `docs/` projektu.

### Przykłady
Przykłady użycia znajdują się w katalogu `examples/` projektu.

### Wsparcie i zgłaszanie problemów
Problemy można zgłaszać przez system Issue Tracker na GitHub.

### Licencja
Ten projekt jest dostępny na licencji MIT.
# Dokumentacja skryptów scan.sh i deploy.sh

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



Zaktualizowałem skrypty instalacyjne i konfiguracyjne dla płytki Radxa Zero 3W/3E, uwzględniając specyfikę tego urządzenia i integrację z ReSpeaker 2-Mic Pi HAT.

## 1. Skrypt instalacyjny Poetry dla Radxa Zero 3W/3E

```bash
# setup-radxa-poetry.sh
```

Ten skrypt zawiera:
- Automatyczne wykrywanie modelu Radxa
- Konfigurację pamięci swap dostosowaną do Radxa Zero
- Instalację Poetry
- Tworzenie przykładowego projektu z bibliotekami specyficznymi dla Radxa (gpiod zamiast RPi.GPIO)
- Szczegółowe instrukcje użycia wraz z dodatkowymi informacjami dla Radxa Zero 3W/3E

## 2. Szybki instalator Poetry dla Radxa

```bash
# quick-radxa.sh
```

Jest to uproszczona wersja głównego skryptu instalacyjnego:
- Szybka instalacja Poetry
- Testowy projekt wykorzystujący biblioteki specyficzne dla Radxa
- Wykrywanie chipów GPIO dostępnych w systemie
- Informacja o możliwości konfiguracji ReSpeaker

## 3. Skrypt konfiguracyjny interfejsów dla Radxa Zero 3W/3E

```bash
# config-radxa.sh
```

### Funkcje

## 4. Skrypt konfiguracyjny dla ReSpeaker 2-Mic Pi HAT

```bash
# setup_radxa_respeaker.sh
```

Dedykowany skrypt do konfiguracji nakładki ReSpeaker 2-Mic Pi HAT na Radxa Zero 3W/3E:
- Automatyczne wykrywanie modelu Radxa
- Instalacja wymaganych pakietów
- Konfiguracja audio dla ReSpeaker (asound.conf)
- Włączenie niezbędnych interfejsów (I2C, I2S)
- Instalacja sterowników i bibliotek dla ReSpeaker
- Konfiguracja GPIO
- Testowy skrypt dla LED Ring
- Przykładowy asystent głosowy


### Główne różnice w porównaniu do Raspberry Pi

- Wykorzystuje `gpiod` zamiast `RPi.GPIO`
- Dostosowuje wielkość pamięci swap do modelu Radxa
- Specyficzne biblioteki Python dla Rockchip RK3566
- 
- Specyficzna konfiguracja `asound.conf` dla Radxa
- Wykorzystanie innych numerów pinów GPIO
- Dostosowane sterowniki dla układu Rockchip RK3566

1. **Sterowniki GPIO**:
   - Wykorzystanie biblioteki `gpiod` zamiast `RPi.GPIO`
   - Dostęp do GPIO przez interfejs `/dev/gpiochipX`

2. **Konfiguracja interfejsów**:
   - Wykorzystanie systemu overlays w `/boot/uEnv.txt` (lub `/boot/config.txt` jako alternatywa)
   - Inne nazewnictwo overlays dla Radxa

3. **Sterowniki audio**:
   - Konfiguracja asound.conf dostosowana do Radxa
   - Instalacja sterowników ReSpeaker z repozytorium dostosowanego do Radxa

4. **Zarządzanie pamięcią**:
   - Specyficzna konfiguracja swap dla Radxa, uwzględniająca jego potrzeby

## respeaker.sh

Skrypt `respeaker.sh` konfiguruje nakładkę ReSpeaker 2-Mic Pi HAT na Radxa ZERO 3W/3E.


## Przykład użycia

```bash
# Włączenie interfejsów
sudo ./config.sh -i

# Instalacja Poetry
./poetry.sh

# Konfiguracja ReSpeaker
sudo ./respeaker.sh
```

## Uwagi

- Skrypty zostały dostosowane specjalnie dla Radxa ZERO 3W/3E
- Mogą wymagać uprawnień administratora (sudo)
- Zalecane jest wykonanie kopii zapasowej systemu przed modyfikacjami
- Wspierane są tylko modele Radxa ZERO 3W/3E z systemem Debian/Ubuntu