#!/bin/bash
# respeaker.sh - Skrypt konfiguracyjny dla ReSpeaker 2-Mic Pi HAT na Radxa ZERO 3W/3E
# Autor: Tom Sapletta
# Data: 15 maja 2025

# Ustaw kodowanie kolorów
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Katalogi
CONFIG_DIR="/boot"
OVERLAY_CONFIG="uEnv.txt"
ASOUND_CONFIG="/etc/asound.conf"
SEEED_DIR="/usr/local/seeed"
GPIO_GROUP="gpio"

# Funkcja logowania
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    case $level in
        INFO)
            echo -e "${GREEN}[INFO]${NC} $timestamp - $message"
            ;;
        WARN)
            echo -e "${YELLOW}[WARN]${NC} $timestamp - $message" >&2
            ;;
        ERROR)
            echo -e "${RED}[ERROR]${NC} $timestamp - $message" >&2
            ;;
        SUCCESS)
            echo -e "${CYAN}[SUCCESS]${NC} $timestamp - $message"
            ;;
        *)
            echo "$message"
            ;;
    esac
}

# Sprawdź, czy skrypt jest uruchomiony z uprawnieniami root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log "ERROR" "Ten skrypt wymaga uprawnień administratora. Uruchom go używając sudo."
        exit 1
    fi
}

# Wykryj model Radxa
detect_radxa_model() {
    local model

    if [ -f /proc/device-tree/model ]; then
        model=$(cat /proc/device-tree/model)
    elif [ -f /sys/firmware/devicetree/base/model ]; then
        model=$(cat /sys/firmware/devicetree/base/model)
    else
        model="Unknown"
    fi

    if [[ "$model" == *"ZERO 3"* ]]; then
        log "INFO" "Wykryto model: Radxa ZERO 3"
        return 0
    else
        log "WARN" "Nie wykryto modelu Radxa ZERO 3. Ten skrypt jest przeznaczony dla Radxa ZERO 3W/3E."
        log "WARN" "Wykryty model: $model"
        return 1
    fi
}

# Zainstaluj wymagane pakiety
install_dependencies() {
    log "INFO" "Instalowanie wymaganych pakietów..."

    apt-get update
    apt-get install -y git i2c-tools python3-pip python3-dev python3-smbus \
        sox alsa-utils libsox-fmt-all libatlas-base-dev libportaudio2 \
        libilmbase-dev libopenexr-dev libgstreamer1.0-dev libjpeg-dev zlib1g-dev libwebp-dev \
        libtiff5-dev libsndfile1-dev libavcodec-dev libavformat-dev libswscale-dev

    # Sprawdź, czy wszystkie pakiety zostały zainstalowane
    if [ $? -ne 0 ]; then
        log "ERROR" "Błąd podczas instalacji pakietów. Sprawdź połączenie z internetem i dostępność pakietów."
        exit 1
    fi

    log "SUCCESS" "Pakiety zainstalowane pomyślnie."
}

# Włącz interfejsy I2C i I2S
enable_interfaces() {
    log "INFO" "Włączanie interfejsów I2C i I2S..."

    # Sprawdź, który plik konfiguracyjny jest używany
    local config_file="${CONFIG_DIR}/${OVERLAY_CONFIG}"
    local alt_config_file="${CONFIG_DIR}/config.txt"

    if [ -f "$config_file" ]; then
        log "INFO" "Znaleziono plik konfiguracyjny: $config_file"

        # Włącz I2C
        if ! grep -q "^overlays=.*i2c" "$config_file"; then
            if grep -q "^overlays=" "$config_file"; then
                # Dodaj do istniejącej linii overlays
                sed -i 's/^overlays=/&i2c,/' "$config_file"
            else
                # Utwórz nową linię overlays
                echo "overlays=i2c" >> "$config_file"
            fi
        fi

        # Włącz I2S
        if ! grep -q "^overlays=.*i2s" "$config_file"; then
            sed -i 's/^overlays=/&i2s,/' "$config_file"
        fi
    elif [ -f "$alt_config_file" ]; then
        log "INFO" "Używanie alternatywnego pliku konfiguracyjnego: $alt_config_file"

        # Włącz I2C
        if ! grep -q "^dtparam=i2c_arm=on" "$alt_config_file"; then
            echo "dtparam=i2c_arm=on" >> "$alt_config_file"
        fi

        # Włącz I2S
        if ! grep -q "^dtparam=i2s=on" "$alt_config_file"; then
            echo "dtparam=i2s=on" >> "$alt_config_file"
        fi
    else
        log "ERROR" "Nie znaleziono pliku konfiguracyjnego. Nie można włączyć interfejsów."
        exit 1
    fi

    # Załaduj moduły I2C
    modprobe i2c-dev

    # Dodaj moduły do autoładowania
    if ! grep -q "i2c-dev" /etc/modules; then
        echo "i2c-dev" >> /etc/modules
    fi

    log "SUCCESS" "Interfejsy I2C i I2S zostały włączone."
}

# Skonfiguruj ALSA dla ReSpeaker
configure_alsa() {
    log "INFO" "Konfigurowanie ALSA dla ReSpeaker..."

    # Utwórz plik konfiguracyjny ALSA
    cat > "$ASOUND_CONFIG" << EOL
pcm.!default {
    type asym
    capture.pcm "mic"
    playback.pcm "speaker"
}

pcm.mic {
    type plug
    slave {
        pcm "hw:1,0"
    }
}

pcm.speaker {
    type plug
    slave {
        pcm "hw:0,0"
    }
}
EOL

    log "SUCCESS" "Konfiguracja ALSA została zaktualizowana."

    # Uruchom ponownie usługę ALSA
    systemctl restart alsa-utils || log "WARN" "Nie można zrestartować usługi alsa-utils"
}

# Zainstaluj sterowniki ReSpeaker
install_respeaker_drivers() {
    log "INFO" "Instalowanie sterowników ReSpeaker..."

    # Utwórz katalog dla sterowników Seeed
    mkdir -p "$SEEED_DIR"

    # Sklonuj repozytorium sterowników ReSpeaker (wersja dla Radxa)
    cd /tmp
    if [ -d "seeed-voicecard" ]; then
        log "INFO" "Usuwanie istniejącego katalogu seeed-voicecard..."
        rm -rf seeed-voicecard
    fi

    git clone https://github.com/respeaker/seeed-voicecard.git

    if [ $? -ne 0 ]; then
        log "ERROR" "Nie można sklonować repozytorium sterowników ReSpeaker."
        exit 1
    fi

    # Instalacja sterowników (z modyfikacją dla Radxa)
    cd seeed-voicecard

    # Modyfikuj pliki instalacyjne, aby obsługiwały Radxa
    log "INFO" "Dostosowywanie sterowników dla Radxa..."

    # Zaktualizuj skrypt instalacyjny, aby obsługiwał Radxa
    sed -i 's/PLATFORM=/PLATFORM="radxa"/' install.sh

    # Uruchom instalację
    log "INFO" "Instalowanie sterowników ReSpeaker. To może potrwać kilka minut..."
    ./install.sh

    if [ $? -ne 0 ]; then
        log "ERROR" "Błąd podczas instalacji sterowników ReSpeaker."
        exit 1
    fi

    log "SUCCESS" "Sterowniki ReSpeaker zostały zainstalowane."
}

# Zainstaluj biblioteki Python dla ReSpeaker
install_python_libraries() {
    log "INFO" "Instalowanie bibliotek Python dla ReSpeaker..."

    # Instaluj biblioteki Python
    pip3 install -U spidev gpiod RPi.GPIO
    pip3 install pyaudio
    pip3 install respeaker

    if [ $? -ne 0 ]; then
        log "ERROR" "Błąd podczas instalacji bibliotek Python."
        exit 1
    fi

    # Utwórz przykładowy skrypt testowy dla LED Ring
    local test_script_dir="/usr/local/bin"
    local test_script="$test_script_dir/test_respeaker_leds.py"

    mkdir -p "$test_script_dir"

    cat > "$test_script" << EOL
#!/usr/bin/env python3
# Test script for ReSpeaker 2-Mic Pi HAT LED Ring on Radxa

import time
import gpiod
import apa102

# Kontroler GPIO dla Radxa
chip = gpiod.Chip('gpiochip1')  # Dla Radxa, może być gpiochip0, gpiochip1, itp.

# Konfiguracja LED Ring
NUM_LED = 12
led = apa102.APA102(num_led=NUM_LED)

# Test LED Ring
try:
    # Wszystkie diody na czerwono
    for i in range(NUM_LED):
        led.set_pixel(i, 0xFF, 0, 0)
    led.show()
    time.sleep(1)

    # Wszystkie diody na zielono
    for i in range(NUM_LED):
        led.set_pixel(i, 0, 0xFF, 0)
    led.show()
    time.sleep(1)

    # Wszystkie diody na niebiesko
    for i in range(NUM_LED):
        led.set_pixel(i, 0, 0, 0xFF)
    led.show()
    time.sleep(1)

    # Animacja tęczy
    for _ in range(3):
        for i in range(NUM_LED):
            led.set_pixel(i, 0, 0, 0)
        led.show()
        time.sleep(0.2)

        for i in range(NUM_LED):
            led.set_pixel(i, 0xFF, 0xFF, 0xFF)
        led.show()
        time.sleep(0.2)

    # Wyłącz wszystkie diody
    for i in range(NUM_LED):
        led.set_pixel(i, 0, 0, 0)
    led.show()

    print("Test ReSpeaker LED Ring zakończony pomyślnie!")

except Exception as e:
    print(f"Błąd: {e}")
    # Wyłącz wszystkie diody w przypadku błędu
    for i in range(NUM_LED):
        led.set_pixel(i, 0, 0, 0)
    led.show()
EOL

    chmod +x "$test_script"
    log "SUCCESS" "Biblioteki Python zostały zainstalowane."
    log "INFO" "Utworzono skrypt testowy dla LED Ring: $test_script"
}

# Popraw uprawnienia dostępu do GPIO
fix_gpio_permissions() {
    log "INFO" "Poprawianie uprawnień dostępu do GPIO..."

    # Sprawdź, czy grupa gpio istnieje
    if ! getent group "$GPIO_GROUP" > /dev/null; then
        groupadd "$GPIO_GROUP"
    fi

    # Dodaj bieżącego użytkownika do grupy gpio
    current_user=${SUDO_USER:-$USER}
    usermod -a -G "$GPIO_GROUP" "$current_user"

    # Utwórz regułę udev dla uprawnień GPIO
    cat > /etc/udev/rules.d/99-gpio.rules << EOL
SUBSYSTEM=="gpio", KERNEL=="gpiochip*", ACTION=="add", PROGRAM="/bin/sh -c 'chown root:${GPIO_GROUP} /dev/\$name && chmod 660 /dev/\$name'"
EOL

    # Uruchom ponownie usługę udev
    udevadm control --reload-rules
    udevadm trigger

    log "SUCCESS" "Uprawnienia GPIO zostały zaktualizowane."
}

# Testuj konfigurację
test_configuration() {
    log "INFO" "Testowanie konfiguracji ReSpeaker..."

    # Sprawdź, czy urządzenia I2C są widoczne
    log "INFO" "Sprawdzanie urządzeń I2C..."
    i2cdetect -y 1

    # Sprawdź, czy urządzenia audio są widoczne
    log "INFO" "Sprawdzanie urządzeń audio..."
    arecord -l
    aplay -l

    # Sprawdź, czy moduły I2S są załadowane
    log "INFO" "Sprawdzanie modułów I2S..."
    lsmod | grep snd

    log "SUCCESS" "Testy zakończone. Sprawdź wyniki powyżej."
}

# Wyświetl instrukcje po instalacji
show_post_install_instructions() {
    echo -e "\n${CYAN}${BOLD}======================= INSTRUKCJE PO INSTALACJI =======================${NC}"
    echo -e "${GREEN}Konfiguracja ReSpeaker dla Radxa ZERO 3W/3E została zakończona pomyślnie!${NC}"
    echo -e "\nAby przetestować LED Ring ReSpeaker, wykonaj:"
    echo -e "${YELLOW}sudo python3 /usr/local/bin/test_respeaker_leds.py${NC}"
    echo -e "\nAby nagrać dźwięk z mikrofonu, wykonaj:"
    echo -e "${YELLOW}arecord -f S16_LE -r 16000 -c 2 -d 5 test.wav${NC}"
    echo -e "\nAby odtworzyć nagranie, wykonaj:"
    echo -e "${YELLOW}aplay test.wav${NC}"
    echo -e "\nAby użyć ReSpeaker z asystentem głosowym, wykonaj:"
    echo -e "${YELLOW}cd rpi-stt-tts-shell && python3 -m rpi_stt_tts_shell${NC}"
    echo -e "\n${CYAN}${BOLD}======================================================================${NC}\n"
}

# Główna funkcja
main() {
    echo -e "${CYAN}${BOLD}======================================================${NC}"
    echo -e "${CYAN}${BOLD}    KONFIGURACJA RESPEAKER DLA RADXA ZERO 3W/3E      ${NC}"
    echo -e "${CYAN}${BOLD}======================================================${NC}\n"

    # Sprawdź uprawnienia
    check_root

    # Wykryj model Radxa
    detect_radxa_model

    echo -e "\n${YELLOW}Ten skrypt skonfiguruje ReSpeaker 2-Mic Pi HAT dla Radxa ZERO 3W/3E.${NC}"
    echo -e "${YELLOW}Kontynuować? [t/N]${NC}"
    read -r confirm

    if [[ ! "$confirm" =~ ^[tT]$ ]]; then
        log "INFO" "Instalacja przerwana przez użytkownika."
        exit 0
    fi

    # Instaluj wymagane pakiety
    install_dependencies

    # Włącz interfejsy
    enable_interfaces

    # Skonfiguruj ALSA
    configure_alsa

    # Zainstaluj sterowniki ReSpeaker
    install_respeaker_drivers

    # Zainstaluj biblioteki Python
    install_python_libraries

    # Popraw uprawnienia GPIO
    fix_gpio_permissions

    # Testuj konfigurację
    test_configuration

    # Wyświetl instrukcje po instalacji
    show_post_install_instructions

    log "SUCCESS" "Konfiguracja ReSpeaker dla Radxa ZERO 3W/3E została zakończona."

    # Sugestia ponownego uruchomienia
    echo -e "\n${YELLOW}Zalecane jest ponowne uruchomienie systemu, aby zmiany zostały w pełni zastosowane.${NC}"
    echo -e "${YELLOW}Czy chcesz teraz ponownie uruchomić system? [t/N]${NC}"
    read -r reboot_confirm

    if [[ "$reboot_confirm" =~ ^[tT]$ ]]; then
        log "INFO" "Ponowne uruchamianie systemu..."
        reboot
    else
        log "INFO" "Pomiń ponowne uruchomienie. Pamiętaj, aby zrobić to później."
    fi
}

# Uruchom główną funkcję
main