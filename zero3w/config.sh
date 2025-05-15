#!/bin/bash
# config.sh - Skrypt konfiguracyjny dla interfejsów Radxa ZERO 3W/3E
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

# Katalogi i pliki konfiguracyjne
CONFIG_DIR="/boot"
OVERLAY_CONFIG="uEnv.txt"
ALT_OVERLAY_CONFIG="config.txt"
MODULES_FILE="/etc/modules"
ASOUND_CONFIG="/etc/asound.conf"

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

    echo -e "${BLUE}Wykryty model: ${BOLD}$model${NC}"

    if [[ "$model" == *"ZERO 3"* ]]; then
        log "INFO" "Wykryto model: Radxa ZERO 3"
        return 0
    else
        log "WARN" "Nie wykryto modelu Radxa ZERO 3. Ten skrypt jest przeznaczony dla Radxa ZERO 3W/3E."
        log "WARN" "Wykryty model: $model"
        echo -e "${YELLOW}Czy chcesz kontynuować mimo to? [t/N]${NC}"
        read -r continue_anyway

        if [[ "$continue_anyway" =~ ^[tT]$ ]]; then
            return 0
        else
            return 1
        fi
    fi
}

# Wykryj plik konfiguracyjny
detect_config_file() {
    local config_file="${CONFIG_DIR}/${OVERLAY_CONFIG}"
    local alt_config_file="${CONFIG_DIR}/${ALT_OVERLAY_CONFIG}"

    if [ -f "$config_file" ]; then
        log "INFO" "Znaleziono plik konfiguracyjny: $config_file"
        echo "$config_file"
    elif [ -f "$alt_config_file" ]; then
        log "INFO" "Znaleziono alternatywny plik konfiguracyjny: $alt_config_file"
        echo "$alt_config_file"
    else
        log "ERROR" "Nie znaleziono pliku konfiguracyjnego."
        return 1
    fi
}

# Włącz SSH
enable_ssh() {
    log "INFO" "Włączanie SSH..."

    # Włącz usługę SSH
    systemctl enable ssh
    systemctl start ssh

    log "SUCCESS" "SSH zostało włączone."
}

# Włącz SPI
enable_spi() {
    log "INFO" "Włączanie SPI..."

    local config_file=$(detect_config_file)

    if [ -z "$config_file" ]; then
        log "ERROR" "Nie można włączyć SPI. Brak pliku konfiguracyjnego."
        return 1
    fi

    # Włącz SPI w zależności od typu pliku konfiguracyjnego
    if [[ "$config_file" == *"uEnv.txt"* ]]; then
        # Dla uEnv.txt
        if ! grep -q "^overlays=.*spi" "$config_file"; then
            if grep -q "^overlays=" "$config_file"; then
                # Dodaj do istniejącej linii overlays
                sed -i 's/^overlays=/&spi,/' "$config_file"
            else
                # Utwórz nową linię overlays
                echo "overlays=spi" >> "$config_file"
            fi
        fi
    else
        # Dla config.txt (podobnie jak dla Raspberry Pi)
        if ! grep -q "^dtparam=spi=on" "$config_file"; then
            echo "dtparam=spi=on" >> "$config_file"
        fi
    fi

    # Załaduj moduł SPI
    modprobe spidev

    # Dodaj moduł do autoładowania
    if ! grep -q "spidev" "$MODULES_FILE"; then
        echo "spidev" >> "$MODULES_FILE"
    fi

    log "SUCCESS" "SPI zostało włączone."
}

# Włącz I2C
enable_i2c() {
    log "INFO" "Włączanie I2C..."

    local config_file=$(detect_config_file)

    if [ -z "$config_file" ]; then
        log "ERROR" "Nie można włączyć I2C. Brak pliku konfiguracyjnego."
        return 1
    fi

    # Włącz I2C w zależności od typu pliku konfiguracyjnego
    if [[ "$config_file" == *"uEnv.txt"* ]]; then
        # Dla uEnv.txt
        if ! grep -q "^overlays=.*i2c" "$config_file"; then
            if grep -q "^overlays=" "$config_file"; then
                # Dodaj do istniejącej linii overlays
                sed -i 's/^overlays=/&i2c,/' "$config_file"
            else
                # Utwórz nową linię overlays
                echo "overlays=i2c" >> "$config_file"
            fi
        fi
    else
        # Dla config.txt (podobnie jak dla Raspberry Pi)
        if ! grep -q "^dtparam=i2c_arm=on" "$config_file"; then
            echo "dtparam=i2c_arm=on" >> "$config_file"
        fi
    fi

    # Załaduj moduły I2C
    modprobe i2c-dev

    # Dodaj moduły do autoładowania
    if ! grep -q "i2c-dev" "$MODULES_FILE"; then
        echo "i2c-dev" >> "$MODULES_FILE"
    fi

    # Zainstaluj narzędzia I2C jeśli nie są zainstalowane
    if ! command -v i2cdetect &> /dev/null; then
        apt-get update
        apt-get install -y i2c-tools
    fi

    log "SUCCESS" "I2C zostało włączone. Aby przetestować, użyj: i2cdetect -y 1"
}

# Włącz UART
enable_uart() {
    log "INFO" "Włączanie UART..."

    local config_file=$(detect_config_file)

    if [ -z "$config_file" ]; then
        log "ERROR" "Nie można włączyć UART. Brak pliku konfiguracyjnego."
        return 1
    fi

    # Włącz UART w zależności od typu pliku konfiguracyjnego
    if [[ "$config_file" == *"uEnv.txt"* ]]; then
        # Dla uEnv.txt
        if ! grep -q "^overlays=.*uart" "$config_file"; then
            if grep -q "^overlays=" "$config_file"; then
                # Dodaj do istniejącej linii overlays
                sed -i 's/^overlays=/&uart,/' "$config_file"
            else
                # Utwórz nową linię overlays
                echo "overlays=uart" >> "$config_file"
            fi
        fi
    else
        # Dla config.txt (podobnie jak dla Raspberry Pi)
        if ! grep -q "^enable_uart=1" "$config_file"; then
            echo "enable_uart=1" >> "$config_file"
        fi
    fi

    log "SUCCESS" "UART zostało włączone."
}

# Włącz I2S (dla audio)
enable_i2s() {
    log "INFO" "Włączanie I2S dla audio..."

    local config_file=$(detect_config_file)

    if [ -z "$config_file" ]; then
        log "ERROR" "Nie można włączyć I2S. Brak pliku konfiguracyjnego."
        return 1
    fi

    # Włącz I2S w zależności od typu pliku konfiguracyjnego
    if [[ "$config_file" == *"uEnv.txt"* ]]; then
        # Dla uEnv.txt
        if ! grep -q "^overlays=.*i2s" "$config_file"; then
            if grep -q "^overlays=" "$config_file"; then
                # Dodaj do istniejącej linii overlays
                sed -i 's/^overlays=/&i2s,/' "$config_file"
            else
                # Utwórz nową linię overlays
                echo "overlays=i2s" >> "$config_file"
            fi
        fi
    else
        # Dla config.txt (podobnie jak dla Raspberry Pi)
        if ! grep -q "^dtparam=i2s=on" "$config_file"; then
            echo "dtparam=i2s=on" >> "$config_file"
        fi
    fi

    # Zainstaluj narzędzia audio
    apt-get update
    apt-get install -y alsa-utils

    log "SUCCESS" "I2S zostało włączone."
}

# Konfiguracja audio
configure_audio() {
    log "INFO" "Konfigurowanie audio..."

    # Zainstaluj narzędzia audio
    apt-get update
    apt-get install -y alsa-utils pulseaudio

    # Utwórz podstawową konfigurację ALSA
    cat > "$ASOUND_CONFIG" << EOL
pcm.!default {
    type hw
    card 0
}

ctl.!default {
    type hw
    card 0
}
EOL

    # Uruchom ponownie usługi audio
    systemctl --user restart pulseaudio || log "WARN" "Nie można zrestartować pulseaudio"

    log "SUCCESS" "Audio zostało skonfigurowane."
}

# Konfiguracja sieci
configure_network() {
    log "INFO" "Konfigurowanie sieci..."

    # Zainstaluj narzędzia sieciowe
    apt-get update
    apt-get install -y network-manager

    # Włącz i uruchom Network Manager
    systemctl enable NetworkManager
    systemctl start NetworkManager

    log "SUCCESS" "Sieć została skonfigurowana."
}

# Optymalizacja wydajności
optimize_performance() {
    log "INFO" "Optymalizacja wydajności..."

    # Konfiguracja swap
    local mem_total=$(free -m | awk '/^Mem:/{print $2}')
    local swap_size=1024

    # Dostosuj rozmiar swap w zależności od ilości RAM
    if [ $mem_total -lt 2048 ]; then
        swap_size=2048
    elif [ $mem_total -lt 4096 ]; then
        swap_size=1536
    else
        swap_size=1024
    fi

    log "INFO" "Konfiguracja swap: $swap_size MB"

    # Sprawdź, czy plik swap już istnieje
    if [ -f /swapfile ]; then
        # Wyłącz istniejący swap
        swapoff /swapfile
        rm /swapfile
    fi

    # Utwórz nowy plik swap
    dd if=/dev/zero of=/swapfile bs=1M count=$swap_size
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile

    # Dodaj swap do fstab jeśli jeszcze go tam nie ma
    if ! grep -q "/swapfile" /etc/fstab; then
        echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
    fi

    # Optymalizacja jądra
    cat > /etc/sysctl.d/99-radxa-performance.conf << EOL
# Optymalizacja pamięci
vm.swappiness = 10
vm.vfs_cache_pressure = 50

# Optymalizacja sieci
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
EOL

    # Zastosuj zmiany
    sysctl -p /etc/sysctl.d/99-radxa-performance.conf

    log "SUCCESS" "Wydajność została zoptymalizowana."
}

# Wyświetl informacje o systemie
show_system_info() {
    echo -e "\n${CYAN}${BOLD}============= INFORMACJE O SYSTEMIE =============${NC}"

    # Model i wersja systemu
    echo -e "${BLUE}Model:${NC}"
    cat /proc/device-tree/model 2>/dev/null || echo "Nie można odczytać modelu"

    echo -e "\n${BLUE}System operacyjny:${NC}"
    cat /etc/os-release | grep "PRETTY_NAME" | cut -d'"' -f2

    echo -e "\n${BLUE}Wersja jądra:${NC}"
    uname -r

    echo -e "\n${BLUE}Procesor:${NC}"
    lscpu | grep "Model name"

    echo -e "\n${BLUE}Pamięć:${NC}"
    free -h

    echo -e "\n${BLUE}Przestrzeń dyskowa:${NC}"
    df -h | grep -E "Filesystem|/$"

    echo -e "\n${BLUE}Interfejsy sieciowe:${NC}"
    ip a | grep -E "^[0-9]" | awk '{print $2}' | sed 's/://'

    echo -e "\n${BLUE}Interfejsy I2C:${NC}"
    ls -l /dev/i2c* 2>/dev/null || echo "Brak interfejsów I2C"

    echo -e "\n${BLUE}Interfejsy SPI:${NC}"
    ls -l /dev/spi* 2>/dev/null || echo "Brak interfejsów SPI"

    echo -e "\n${BLUE}Interfejsy UART:${NC}"
    ls -l /dev/ttyS* 2>/dev/null || echo "Brak interfejsów UART"

    echo -e "\n${BLUE}Urządzenia audio:${NC}"
    aplay -l 2>/dev/null || echo "Brak urządzeń audio"

    echo -e "\n${CYAN}${BOLD}=================================================${NC}\n"
}

# Wyświetl pomoc
show_help() {
    echo -e "${CYAN}${BOLD}Skrypt konfiguracyjny dla Radxa ZERO 3W/3E${NC}"
    echo -e "Użycie: $0 [OPCJE]"
    echo -e ""
    echo -e "Opcje:"
    echo -e "  -i, --interfaces    Konfiguracja interfejsów (SSH, SPI, I2C, UART, I2S)"
    echo -e "  -a, --audio         Konfiguracja audio"
    echo -e "  -n, --network       Konfiguracja sieci"
    echo -e "  -p, --performance   Optymalizacja wydajności"
    echo -e "  -s, --system-info   Wyświetl informacje o systemie"
    echo -e "  -h, --help          Wyświetl tę pomoc"
    echo -e ""
    echo -e "Przykłady:"
    echo -e "  $0 -i               # Konfiguracja wszystkich interfejsów"
    echo -e "  $0 -i -a            # Konfiguracja interfejsów i audio"
    echo -e "  $0 -s               # Wyświetl informacje o systemie"
    echo -e ""
}

# Główna funkcja
main() {
    # Sprawdź uprawnienia
    check_root

    # Domyślne opcje
    local configure_interfaces=false
    local configure_audio_option=false
    local configure_network_option=false
    local optimize_performance_option=false
    local show_system_info_option=false

    # Parsowanie argumentów
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -i|--interfaces)
                configure_interfaces=true
                shift
                ;;
            -a|--audio)
                configure_audio_option=true
                shift
                ;;
            -n|--network)
                configure_network_option=true
                shift
                ;;
            -p|--performance)
                optimize_performance_option=true
                shift
                ;;
            -s|--system-info)
                show_system_info_option=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo -e "${RED}Nieznana opcja: $1${NC}" >&2
                show_help
                exit 1
                ;;
        esac
    done

    # Jeśli nie podano żadnych opcji, wyświetl menu
    if ! $configure_interfaces && ! $configure_audio_option && ! $configure_network_option && ! $optimize_performance_option && ! $show_system_info_option; then
        echo -e "${CYAN}${BOLD}===== KONFIGURACJA RADXA ZERO 3W/3E =====${NC}"
        echo -e ""
        echo -e "1) Konfiguracja interfejsów (SSH, SPI, I2C, UART, I2S)"
        echo -e "2) Konfiguracja audio"
        echo -e "3) Konfiguracja sieci"
        echo -e "4) Optymalizacja wydajności"
        echo -e "5) Wyświetl informacje o systemie"
        echo -e "6) Wyjście"
        echo -e ""
        echo -ne "${YELLOW}Wybierz opcję (1-6): ${NC}"
        read -r option

        case $option in
            1)
                configure_interfaces=true
                ;;
            2)
                configure_audio_option=true
                ;;
            3)
                configure_network_option=true
                ;;
            4)
                optimize_performance_option=true
                ;;
            5)
                show_system_info_option=true
                ;;
            6)
                echo -e "${GREEN}Do widzenia!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Nieprawidłowa opcja.${NC}"
                exit 1
                ;;
        esac
    fi

    # Wykryj model Radxa
    detect_radxa_model || exit 1

    # Wykonaj wybrane opcje
    if $configure_interfaces; then
        echo -e "\n${CYAN}${BOLD}=== KONFIGURACJA INTERFEJSÓW ===${NC}"
        enable_ssh
        enable_spi
        enable_i2c
        enable_uart
        enable_i2s
        echo -e "${GREEN}Konfiguracja interfejsów zakończona.${NC}"
    fi

    if $configure_audio_option; then
        echo -e "\n${CYAN}${BOLD}=== KONFIGURACJA AUDIO ===${NC}"
        enable_i2s # Upewnij się, że I2S jest włączone
        configure_audio
        echo -e "${GREEN}Konfiguracja audio zakończona.${NC}"
    fi

    if $configure_network_option; then
        echo -e "\n${CYAN}${BOLD}=== KONFIGURACJA SIECI ===${NC}"
        configure_network
        echo -e "${GREEN}Konfiguracja sieci zakończona.${NC}"
    fi

    if $optimize_performance_option; then
        echo -e "\n${CYAN}${BOLD}=== OPTYMALIZACJA WYDAJNOŚCI ===${NC}"
        optimize_performance
        echo -e "${GREEN}Optymalizacja wydajności zakończona.${NC}"
    fi

    if $show_system_info_option; then
        show_system_info
    fi

    echo -e "\n${GREEN}${BOLD}Konfiguracja Radxa ZERO 3W/3E zakończona pomyślnie!${NC}"
    echo -e "${YELLOW}Zalecane jest ponowne uruchomienie systemu, aby zmiany zostały w pełni zastosowane.${NC}"
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
main "$@"