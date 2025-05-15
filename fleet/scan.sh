#!/bin/bash
# scan.sh - Skrypt do skanowania sieci w poszukiwaniu urządzeń Raspberry Pi i Radxa
# Autor: Tom Sapletta
# Data: 15 maja 2025

# Konfiguracja plików źródłowych
CONFIG_DIR="${HOME}/hosts"
USERS_FILE="$CONFIG_DIR/users.txt"
COMMANDS_FILE="$CONFIG_DIR/commands.txt"
MARKERS_FILE="$CONFIG_DIR/markers.txt"

# Ustaw kodowanie kolorów
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Nazwa pliku wyjściowego CSV
OUTPUT_FILE="devices.csv"
# Nazwa pliku bazowego dla wszystkich urządzeń
BASE_OUTPUT_FILE="devices_all.csv"

# Tryb debugowania (ustaw na "true" aby włączyć)
DEBUG_MODE="false"

# Maksymalny czas na połączenie SSH w sekundach
SSH_CONNECT_TIMEOUT=5

# Funkcja debugowania
debug() {
    if [ "$DEBUG_MODE" = "true" ]; then
        echo -e "${BLUE}[DEBUG] $1${NC}"
    fi
}

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

# Funkcja tworzenia domyślnych plików konfiguracyjnych
create_default_config_files() {
    # Upewnij się, że katalog istnieje
    mkdir -p "$CONFIG_DIR"

    # Domyślni użytkownicy
    if [ ! -f "$USERS_FILE" ]; then
        cat > "$USERS_FILE" << EOF
# Lista użytkowników do próby połączenia SSH
# Jeden użytkownik na linię, komentarze zaczynają się od #
pi
tom
movatalk
admin
osmc
root
ubuntu
debian
EOF
        log "INFO" "Utworzono domyślny plik użytkowników: $USERS_FILE"
    fi

    # Domyślne komendy detekcyjne
    if [ ! -f "$COMMANDS_FILE" ]; then
        cat > "$COMMANDS_FILE" << EOF
# Komendy do sprawdzenia Raspberry Pi/Radxa
# Jedna komenda na linię, komentarze zaczynają się od #
cat /etc/os-release
cat /proc/cpuinfo
cat /proc/device-tree/model 2>/dev/null || echo "No model info"
uname -a
cat /etc/issue
hostname
lsb_release -a 2>/dev/null || echo "No LSB info"
EOF
        log "INFO" "Utworzono domyślny plik komend: $COMMANDS_FILE"
    fi

    # Markery identyfikujące
    if [ ! -f "$MARKERS_FILE" ]; then
        cat > "$MARKERS_FILE" << EOF
# Markery identyfikujące różne typy urządzeń
# Format: typ_urządzenia:marker1,marker2,marker3
# Komentarze zaczynają się od #
raspberry_pi:raspberry,raspbian,raspberry pi,bcm2835,bcm2708,bcm2709,bcm2710,bcm2711,raspberrypi,pi
radxa:radxa,rockchip,rk3566,rk3568,rk3588,rk3399,rock
openwrt:openwrt,lede,barrier breaker,chaos calmer
hardkernel:odroid,hardkernel,exynos,amlogic
orange_pi:orange pi,h2+,h3,h5,h6,allwinner
libre:libre computer,tritium,all-h3-cc
banana_pi:banana pi,bananapi
beaglebone:beaglebone,am335x
EOF
        log "INFO" "Utworzono domyślny plik markerów: $MARKERS_FILE"
    fi
}

# Funkcja ładująca tablicę z pliku
load_array_from_file() {
    local file="$1"

    # Sprawdź, czy plik istnieje
    if [ ! -f "$file" ]; then
        log "ERROR" "Plik $file nie istnieje"
        return 1
    fi

    # Wczytaj linie z pliku, pomijając komentarze i puste linie
    grep -v '^\s*#' "$file" | grep -v '^\s*$'
}

# Funkcja ładująca markery z pliku
load_markers_from_file() {
    local file="$1"

    # Sprawdź, czy plik istnieje
    if [ ! -f "$file" ]; then
        log "ERROR" "Plik markerów $file nie istnieje"
        return 1
    fi

    # Wczytaj linie z pliku, pomijając komentarze i puste linie
    grep -v '^\s*#' "$file" | grep -v '^\s*$'
}

# Funkcja sprawdzająca typ urządzenia na podstawie informacji
check_device_type() {
    local info="$1"
    local markers="$2"
    local hostname="$3"

    # Przekształć info na małe litery dla lepszego dopasowania
    local info_lower=$(echo "$info" | tr '[:upper:]' '[:lower:]')
    local hostname_lower=$(echo "$hostname" | tr '[:upper:]' '[:lower:]')

    # Dodaj hostname do informacji do sprawdzenia
    info_lower="${info_lower} ${hostname_lower}"

    # Każdy wiersz markerów ma format: typ_urządzenia:marker1,marker2,marker3
    IFS=$'\n'
    for marker_line in $markers; do
        # Podziel linię na typ i markery
        local device_type=$(echo "$marker_line" | cut -d':' -f1)
        local device_markers=$(echo "$marker_line" | cut -d':' -f2)

        # Sprawdź każdy marker
        IFS=',' read -ra MARKER_ARRAY <<< "$device_markers"
        for marker in "${MARKER_ARRAY[@]}"; do
            if echo "$info_lower" | grep -q "$marker"; then
                debug "Znaleziono marker '$marker' dla typu '$device_type'"
                echo "$device_type"
                return 0
            fi
        done
    done

    # Jeśli nie znaleziono markerów, sprawdź nazwę hosta
    if [[ $hostname_lower == *raspberry* || $hostname_lower == *rpi* || $hostname_lower == *pi* ]]; then
        debug "Znaleziono prawdopodobne Raspberry Pi na podstawie nazwy hosta: $hostname"
        echo "probable_raspberry_pi"
        return 0
    elif [[ $hostname_lower == *radxa* || $hostname_lower == *rock* ]]; then
        debug "Znaleziono prawdopodobne Radxa na podstawie nazwy hosta: $hostname"
        echo "probable_radxa"
        return 0
    elif [[ $hostname_lower == *open* && $hostname_lower == *wrt* ]]; then
        debug "Znaleziono prawdopodobne OpenWRT na podstawie nazwy hosta: $hostname"
        echo "openwrt"
        return 0
    fi

    # Jeśli nadal nie znaleźliśmy typu, sprawdź dodatkowe wskazówki w danych
    if echo "$info_lower" | grep -q "linux"; then
        debug "Znaleziono ogólny system Linux"
        echo "linux"
        return 0
    fi

    # Jeśli nie znaleziono markerów, zwróć "unknown"
    echo "unknown"
    return 1
}

# Funkcja określająca domyślny interfejs sieciowy
get_default_interface() {
    # Różne metody dla różnych systemów
    if [ "$(uname)" == "Linux" ]; then
        # Linux - sprawdź trasę domyślną
        route -n | grep '^0.0.0.0' | grep -o '[^ ]*$' | head -n1
    elif [ "$(uname)" == "Darwin" ]; then
        # macOS
        route -n get default | grep interface | awk '{print $2}'
    else
        # Jeśli nie można ustalić, używamy pierwszego interfejsu
        ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -n1
    fi
}

# Funkcja pobierająca zakres sieci na podstawie adresu IP i maski
get_network_range() {
    local interface=$1
    local ip
    local network

    if [ "$(uname)" == "Linux" ]; then
        # Linux
        ip=$(ip -o -4 addr show dev "$interface" | awk '{print $4}' | cut -d/ -f1)

        # Jeśli nie znaleziono adresu IP, zwróć domyślny zakres
        if [ -z "$ip" ]; then
            echo "192.168.1.0/24"
            return
        fi

        # Wydobądź trzy pierwsze oktety adresu IP
        IFS=. read -r i1 i2 i3 i4 <<< "$ip"
        network="$i1.$i2.$i3.0/24"
    elif [ "$(uname)" == "Darwin" ]; then
        # macOS
        ip=$(ifconfig "$interface" | grep "inet " | awk '{print $2}')

        # Jeśli nie znaleziono adresu IP, zwróć domyślny zakres
        if [ -z "$ip" ]; then
            echo "192.168.1.0/24"
            return
        fi

        # Wydobądź trzy pierwsze oktety adresu IP
        first_three=$(echo "$ip" | cut -d. -f1-3)
        network="$first_three.0/24"
    else
        # Domyślny zakres dla nieznanych systemów
        network="192.168.1.0/24"
    fi

    echo "$network"
}

# Funkcja wyświetlająca pomoc
show_help() {
    echo -e "${BOLD}Skaner urządzeń Raspberry Pi i Radxa w sieci${NC}"
    echo "Użycie: $0 [OPCJE]"
    echo ""
    echo "Opcje:"
    echo "  -r, --range RANGE    Skanuj podany zakres sieci (np. 192.168.1.0/24)"
    echo "  -o, --output FILE    Zapisz wyniki do podanego pliku CSV (domyślnie: $OUTPUT_FILE)"
    echo "  -b, --base FILE      Zapisz wszystkie znalezione urządzenia do tego pliku (domyślnie: $BASE_OUTPUT_FILE)"
    echo "  -d, --debug          Włącz tryb debugowania"
    echo "  -h, --help           Wyświetl tę pomoc"
    echo ""
    echo "Pliki konfiguracyjne:"
    echo "  $USERS_FILE      - Lista użytkowników do próby logowania"
    echo "  $COMMANDS_FILE   - Lista komend do identyfikacji urządzeń"
    echo "  $MARKERS_FILE    - Lista markerów dla różnych typów urządzeń"
    echo ""
    echo "Przykłady:"
    echo "  $0 -r 192.168.0.0/24"
    echo "  $0 --output moje_urzadzenia.csv"
    echo "  $0 -d -r 10.0.0.0/24"
    echo ""
}

# Główna funkcja
main() {
    # Zmienne
    local network_range=""

    # Parsowanie argumentów wiersza poleceń
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -r|--range)
                network_range="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            -b|--base)
                BASE_OUTPUT_FILE="$2"
                shift 2
                ;;
            -d|--debug)
                DEBUG_MODE="true"
                log "INFO" "Tryb debugowania włączony"
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

    # Utwórz domyślne pliki konfiguracyjne, jeśli nie istnieją
    create_default_config_files

    # Jeśli nie podano zakresu sieci, wykryj go automatycznie
    if [ -z "$network_range" ]; then
        local default_interface
        default_interface=$(get_default_interface)

        if [ -n "$default_interface" ]; then
            network_range=$(get_network_range "$default_interface")
            echo -e "${BLUE}Automatycznie wykryty zakres sieci: ${BOLD}$network_range${NC}"
        else
            network_range="192.168.1.0/24"
            echo -e "${YELLOW}Nie można wykryć zakresu sieci, używam domyślnego: ${BOLD}$network_range${NC}"
        fi
    fi

    # Uruchom skanowanie
    scan_devices "$network_range"

    exit 0
}

# Uruchomienie programu
main "$@"