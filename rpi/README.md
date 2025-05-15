# Skrypty dla Raspberry Pi

Ten katalog zawiera skrypty specyficzne dla urządzeń Raspberry Pi, służące do konfiguracji, instalacji zależności i ustawienia komponentów sprzętowych.

## Pliki w tym katalogu

- `config.sh` - Skrypt do konfiguracji interfejsów i usług Raspberry Pi
- `setup.sh` - Skrypt instalacyjny dla zależności projektu
- `respeaker.sh` - Skrypt do konfiguracji mikrofonu ReSpeaker na Raspberry Pi

## config.sh

Skrypt `config.sh` służy do konfiguracji interfejsów i usług na Raspberry Pi, takich jak SSH, SPI, I2C, kamera, itp.

### Funkcje

- Włączanie/wyłączanie interfejsów (SSH, SPI, I2C, 1-Wire, itp.)
- Konfiguracja kamery
- Ustawienia audio
- Konfiguracja sieci
- Ustawienia lokalizacji i czasu

### Użycie

```bash
./config.sh [OPCJE]
```

### Opcje

- `-i, --interfaces` - konfiguracja interfejsów
- `-a, --audio` - konfiguracja audio
- `-n, --network` - konfiguracja sieci
- `-l, --locale` - konfiguracja lokalizacji i czasu
- `-h, --help` - wyświetl pomoc

### Przykłady

```bash
# Pełna konfiguracja
./config.sh

# Tylko konfiguracja interfejsów
./config.sh -i

# Konfiguracja audio i sieci
./config.sh -a -n
```

## setup.sh

Skrypt `setup.sh` instaluje wszystkie zależności potrzebne do działania projektu na Raspberry Pi, w tym Poetry do zarządzania pakietami Pythona.

### Funkcje

- Aktualizacja systemu
- Instalacja wymaganych pakietów systemowych
- Instalacja Poetry
- Konfiguracja środowiska wirtualnego
- Instalacja zależności Pythona

### Użycie

```bash
./setup.sh [OPCJE]
```

### Opcje

- `-u, --update` - aktualizacja systemu przed instalacją
- `-p, --packages` - instalacja tylko pakietów systemowych
- `-y, --yes` - automatyczne potwierdzanie wszystkich pytań
- `-h, --help` - wyświetl pomoc

### Przykłady

```bash
# Standardowa instalacja
./setup.sh

# Instalacja z aktualizacją systemu
./setup.sh -u

# Automatyczne potwierdzanie wszystkich pytań
./setup.sh -y
```

## respeaker.sh

Skrypt `respeaker.sh` konfiguruje mikrofon ReSpeaker na Raspberry Pi, co obejmuje instalację sterowników i narzędzi.

### Funkcje

- Instalacja sterowników dla ReSpeaker
- Konfiguracja ALSA
- Testy działania mikrofonu
- Optymalizacja parametrów

### Użycie

```bash
sudo ./respeaker.sh [OPCJE]
```

### Opcje

- `-i, --install` - tylko instalacja sterowników
- `-c, --configure` - tylko konfiguracja
- `-t, --test` - test działania mikrofonu
- `-h, --help` - wyświetl pomoc

### Przykłady

```bash
# Pełna instalacja i konfiguracja
sudo ./respeaker.sh

# Tylko instalacja sterowników
sudo ./respeaker.sh -i

# Test działania mikrofonu
sudo ./respeaker.sh -t
```

### Uwaga

Skrypt wymaga uprawnień administratora (sudo) do działania.

## Wspierane modele Raspberry Pi

- Raspberry Pi 3 Model B
- Raspberry Pi 3 Model B+
- Raspberry Pi 4 Model B
- Raspberry Pi Zero 2 W

## Wspierane modele ReSpeaker

- ReSpeaker 2-Mic Pi HAT
- ReSpeaker 4-Mic Array
- ReSpeaker 6-Mic Circular Array

## Uwagi

- Skrypty są przeznaczone do pracy z Raspberry Pi OS (dawniej Raspbian)
- Zalecana jest najnowsza wersja systemu (Bullseye lub nowsza)
- W przypadku problemów z dźwiękiem, zalecane jest użycie skryptu `respeaker.sh`


I can see that you're working to set up a voice assistant with a ReSpeaker on a Raspberry Pi Zero v2, but encountering several issues. The key problems are:

1. No microphone is being detected
2. PyAudio installation is failing
3. The ReSpeaker drivers may not be properly installed yet


## How to Use the Script:

1. Save this script as `respeaker.sh`
2. Make it executable:
   ```bash
   chmod +x respeaker.sh
   ```
3. Run it as root:
   ```bash
   sudo ./respeaker.sh
   ```
4. **REBOOT your Raspberry Pi after installation**
5. After rebooting, test your microphone:
   ```bash
   source voice_env/bin/activate
   python test_microphone.py
   ```
6. If the microphone test works, try the assistant:
   ```bash
   source voice_env/bin/activate
   python voice_assistant.py
   ```

## Troubleshooting Tips:

1. If no microphone is detected after installation and reboot:
   - Check physical connections
   - Run `arecord -l` to see if Linux detects the microphone
   - Run `lsusb` to check if a USB microphone is detected

2. If you get a "No module named 'pyaudio'" error:
   - Make sure you activated the virtual environment with `source voice_env/bin/activate`
   - Try reinstalling PyAudio with `pip install --upgrade pyaudio`

3. For ReSpeaker HAT issues:
   - Check if ReSpeaker is properly seated on the GPIO pins
   - Verify that the right overlay is enabled in `/boot/config.txt`

Based on your logs and system information, I can see that the installation script has run successfully, but there are still some issues to address:

1. The ReSpeaker card is not being detected
2. You have a USB port but no USB microphone connected 
3. Your Raspberry Pi is using a different boot configuration path (`/boot/firmware/config.txt` instead of `/boot/config.txt`)

Let's modify the approach to fix these issues:

## First, let's check the actual configuration file location:

```bash
cat /boot/firmware/config.txt
```


## Instructions for using this script:

1. Copy and paste this script into a file (e.g., `respeaker.sh`)
2. Make it executable: `chmod +x respeaker.sh`
3. Run it with sudo: `sudo ./respeaker.sh`
4. When prompted, select the type of microphone you're using
5. After the script finishes, reboot your Raspberry Pi
6. After rebooting, run the test script: `python3 ~//test_audio.py`

## Troubleshooting if audio still doesn't work after running the script:

1. **For ReSpeaker HAT issues:**
   - Check the physical connection to the GPIO pins
   - Ensure the overlay is properly loaded: `dmesg | grep seeed`
   - Try manually modifying `/boot/firmware/config.txt` and `/etc/asound.conf`

2. **For USB microphone issues:**
   - Check if the USB microphone is detected: `lsusb`
   - Verify ALSA can see it: `arecord -l`
   - Try using a different USB port

3. **General audio troubleshooting:**
   - Check if your user is in the 'audio' group: `groups`
   - If not, add yourself: `sudo usermod -a -G audio tom`
   - Check audio levels with alsamixer: `alsamixer`

