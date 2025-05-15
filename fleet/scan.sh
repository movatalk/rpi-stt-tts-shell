#!/bin/bash
# Skaner Raspberry Pi i Radxa w sieci lokalnej z ulepszonym wykrywaniem
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
BASE_OUTPUT_FILE="devicesC_base.csv"

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

# Funkcja próbująca pobrać podstawowe informacje bez SSH
try_basic_detection() {
    local ip="$1"
    local hostname="$2"
    local result=""

    # Próba ping
    if ping -c 1 -W 1 "$ip" >/dev/null 2>&1; then
        result="${result}Respond to ping: yes\n"
        debug "$ip odpowiada na ping"
    else
        result="${result}Respond to ping: no\n"
        debug "$ip nie odpowiada na ping"
    fi

    # Sprawdzenie różnych popularnych portów
    for port in 80 443 8080 8443 9100; do
        if nc -z -w 1 "$ip" "$port" >/dev/null 2>&1; then
            result="${result}Port $port: open\n"
            debug "$ip ma otwarty port $port"
        fi
    done

    echo "$result"
}

# Funkcja sprawdzająca konkretne urządzenie
check_device() {
    local ip="$1"
    local users="$2"
    local commands="$3"
    local markers="$4"
    local hostname="$5"

    # Zmienna przechowująca informacje o urządzeniu
    local device_info=""
    local successful_user=""
    local successful_command=""
    local ssh_works="false"

    # Próba połączenia z każdym użytkownikiem
    for user in $users; do
        debug "Próba połączenia z $ip jako użytkownik $user"

        # Sprawdź czy możemy się zalogować - najpierw bez BatchMode aby pozwolić na hasła
        if ssh -o ConnectTimeout=$SSH_CONNECT_TIMEOUT -o StrictHostKeyChecking=no -o PasswordAuthentication=no "${user}@${ip}" "echo test_connection" &>/dev/null; then
            debug "Udane połączenie z $ip jako $user (SSH kluczem)"
            successful_user="$user"
            ssh_works="true"

            # Uruchom każdą komendę
            for cmd in $commands; do
                debug "Wykonywanie komendy: $cmd"
                local cmd_output=$(ssh -o ConnectTimeout=$SSH_CONNECT_TIMEOUT -o StrictHostKeyChecking=no "${user}@${ip}" "$cmd" 2>/dev/null)

                if [ -n "$cmd_output" ]; then
                    device_info="${device_info}\n${cmd_output}"
                    successful_command="$cmd"
                    debug "Komenda zwróciła dane: ${#cmd_output} bajtów"
                fi
            done

            # Jeśli uzyskaliśmy jakiekolwiek informacje, przerwij
            if [ -n "$device_info" ]; then
                break
            fi
        fi
    done

    # Jeśli SSH działa ale nie mamy informacji, spróbuj zdobyć podstawowe dane
    if [ "$ssh_works" = "true" ] && [ -z "$device_info" ]; then
        debug "SSH działa, ale nie udało się uzyskać informacji przez komendy"
        device_info="SSH accessible: yes\nDetails not available\n"
    fi

    # Jeśli nie działa SSH, spróbuj wykryć bez SSH
    if [ "$ssh_works" = "false" ]; then
        debug "SSH nie działa dla $ip, próba wykrycia bez SSH"
        basic_info=$(try_basic_detection "$ip" "$hostname")
        if [ -n "$basic_info" ]; then
            device_info="SSH accessible: no\n${basic_info}"
        fi
    fi

    # Jeśli uzyskaliśmy informacje, określ typ urządzenia
    if [ -n "$device_info" ]; then
        local device_type=$(check_device_type "$device_info" "$markers" "$hostname")
        echo "$device_type|$device_info|$successful_user|$successful_command"
        return 0
    fi

    # Jeśli nie uzyskaliśmy informacji, zwróć pusty ciąg
    echo ""
    return 1
}

# Funkcja wydobywająca informacje o systemie
extract_system_info() {
    local info="$1"
    local type="$2"

    # Domyślne wartości
    local os_info="unknown"
    local model="unknown"

    # Spróbuj wydobyć informacje o systemie
    if echo "$info" | grep -q "PRETTY_NAME"; then
        os_info=$(echo "$info" | grep "PRETTY_NAME" | head -n1 | cut -d'"' -f2)
    elif echo "$info" | grep -q "DISTRIB_DESCRIPTION"; then
        os_info=$(echo "$info" | grep "DISTRIB_DESCRIPTION" | head -n1 | cut -d'=' -f2 | tr -d '"')
    elif echo "$info" | grep -q "^ID="; then
        local id=$(echo "$info" | grep "^ID=" | head -n1 | cut -d'=' -f2 | tr -d '"')
        local version=$(echo "$info" | grep "^VERSION=" | head -n1 | cut -d'=' -f2 | tr -d '"')
        os_info="${id} ${version}"
    elif echo "$info" | grep -q "Raspbian\|Debian\|Ubuntu\|Linux"; then
        os_info=$(echo "$info" | grep -E "Raspbian|Debian|Ubuntu|Linux" | head -n1)
    elif echo "$info" | grep -q "SSH accessible"; then
        os_info="SSH detection only"
    fi

    # Wydobądź model urządzenia
    if echo "$info" | grep -q "Model"; then
        model=$(echo "$info" | grep "Model" | head -n1 | cut -d':' -f2 | xargs)
    elif echo "$info" | grep -q "Hardware"; then
        model=$(echo "$info" | grep "Hardware" | head -n1 | cut -d':' -f2 | xargs)
    elif echo "$info" | grep -q "model name"; then
        model=$(echo "$info" | grep "model name" | head -n1 | cut -d':' -f2 | xargs)
    elif echo "$info" | grep -q "Raspberry Pi\|Radxa"; then
        model=$(echo "$info" | grep -E "Raspberry Pi|Radxa" | head -n1)
    fi

    # Jeśli model nadal jest nieznany a typ jest określony, użyj typu jako modelu
    if [ "$model" = "unknown" ] && [ "$type" != "unknown" ]; then
        model="Probable $type device"
    fi

    # Zwróć połączone informacje
    echo "${os_info}|${model}"
}

# Główna funkcja skanowania
scan_devices() {
    local range=$1
    local temp_file=$(mktemp)
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    echo -e "${YELLOW}Skanowanie sieci ${BOLD}$range${NC}${YELLOW} w poszukiwaniu urządzeń...${NC}"
    echo -e "To może potrwać kilka chwil."

    # Stwórz lub wyczyść plik wyjściowy CSV i dodaj nagłówki
    echo "ip,hostname,device_type,os_info,model,scan_date,username" > "$OUTPUT_FILE"
    echo "ip,hostname,device_type,os_info,model,scan_date,username" > "$BASE_OUTPUT_FILE"

    # Skanowanie z nmap - szukamy otwartych portów SSH
    echo -e "${BLUE}Skanowanie portów SSH w sieci...${NC}"
    nmap -p 22 --open "$range" -oG "$temp_file"

    # Wczytaj użytkowników, komendy i markery
    local users_list=$(load_array_from_file "$USERS_FILE")
    local commands_list=$(load_array_from_file "$COMMANDS_FILE")
    local markers_list=$(load_markers_from_file "$MARKERS_FILE")

    # Liczniki znalezionych urządzeń
    local counter_rpi=0
    local counter_radxa=0
    local counter_openwrt=0
    local counter_other=0

    # Przetwarzanie wyników
    grep "22/open" "$temp_file" | while read -r line; do
        local ip=$(echo "$line" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
        if [ -n "$ip" ]; then
            # Próba nazwy hosta
            local hostname=$(host "$ip" 2>/dev/null | grep "domain name pointer" | cut -d' ' -f5 | sed 's/\.$//')
            hostname=${hostname:-"unknown"}

            log "INFO" "Sprawdzanie urządzenia $ip ($hostname)..."

            # Dodaj do bazowego pliku od razu wszystkie znalezione urządzenia
            echo "$ip,$hostname,unknown,unknown,unknown,$timestamp,unknown" >> "$BASE_OUTPUT_FILE"

            # Sprawdź urządzenie
            local check_result=$(check_device "$ip" "$users_list" "$commands_list" "$markers_list" "$hostname")

            if [ -n "$check_result" ]; then
                # Podziel wynik na części
                local device_type=$(echo "$check_result" | cut -d'|' -f1)
                local device_info=$(echo "$check_result" | cut -d'|' -f2)
                local user=$(echo "$check_result" | cut -d'|' -f3)

                # Wydobądź informacje o systemie
                local system_info=$(extract_system_info "$device_info" "$device_type")
                local os_info=$(echo "$system_info" | cut -d'|' -f1)
                local model=$(echo "$system_info" | cut -d'|' -f2)

                # Usuń potencjalne przecinki z pól
                hostname=$(echo "$hostname" | tr ',' ' ')
                os_info=$(echo "$os_info" | tr ',' ' ')
                model=$(echo "$model" | tr ',' ' ')

                # Aktualizuj liczniki
                if [[ "$device_type" == *raspberry* ]]; then
                    counter_rpi=$((counter_rpi + 1))
                    log "SUCCESS" "Wykryto Raspberry Pi: $ip ($hostname) - $model"
                elif [[ "$device_type" == *radxa* ]]; then
                    counter_radxa=$((counter_radxa + 1))
                    log "SUCCESS" "Wykryto Radxa: $ip ($hostname) - $model"
                elif [[ "$device_type" == *openwrt* ]]; then
                    counter_openwrt=$((counter_openwrt + 1))
                    log "SUCCESS" "Wykryto OpenWRT: $ip ($hostname)"
                else
                    counter_other=$((counter_other + 1))
                    log "INFO" "Wykryto inne urządzenie: $ip ($hostname) - $device_type"
                fi

                # Aktualizuj bazowy plik z nowymi informacjami
                sed -i "s|$ip,$hostname,unknown,unknown,unknown,$timestamp,unknown|$ip,$hostname,$device_type,$os_info,$model,$timestamp,$user|" "$BASE_OUTPUT_FILE"

                # Zapisz do pliku CSV
                echo "$ip,$hostname,$device_type,$os_info,$model,$timestamp,$user" >> "$OUTPUT_FILE"
            else
                # Sprawdź, czy nazwa hosta sugeruje typ urządzenia
                if [[ $hostname == *raspberry* || $hostname == *pi* || $hostname == *rpi* ]]; then
                    log "INFO" "Wykryto prawdopodobne Raspberry Pi na podstawie nazwy hosta: $ip ($hostname)"
                    echo "$ip,$hostname,probable_raspberry_pi,unknown,unknown,$timestamp,unknown" >> "$OUTPUT_FILE"
                    # Aktualizuj bazowy plik
                    sed -i "s|$ip,$hostname,unknown,unknown,unknown,$timestamp,unknown|$ip,$hostname,probable_raspberry_pi,unknown,unknown,$timestamp,unknown|" "$BASE_OUTPUT_FILE"
                    counter_rpi=$((counter_rpi + 1))
                elif [[ $hostname == *radxa* || $hostname == *rock* ]]; then
                    log "INFO" "Wykryto prawdopodobne Radxa na podstawie nazwy hosta: $ip ($hostname)"
                    echo "$ip,$hostname,probable_radxa,unknown,unknown,$timestamp,unknown" >> "$OUTPUT_FILE"
                    # Aktualizuj bazowy plik
                    sed -i "s|$ip,$hostname,unknown,unknown,unknown,$timestamp,unknown|$ip,$hostname,probable_radxa,unknown,unknown,$timestamp,unknown|" "$BASE_OUTPUT_FILE"
                    counter_radxa=$((counter_radxa + 1))
                elif [[ $hostname == *openwrt* || $hostname == *lede* ]]; then
                    log "INFO" "Wykryto prawdopodobne OpenWRT na podstawie nazwy hosta: $ip ($hostname)"
                    echo "$ip,$hostname,openwrt,unknown,unknown,$timestamp,unknown" >> "$OUTPUT_FILE"
                    # Aktualizuj bazowy plik
                    sed -i "s|$ip,$hostname,unknown,unknown,unknown,$timestamp,unknown|$ip,$hostname,openwrt,unknown,unknown,$timestamp,unknown|" "$BASE_OUTPUT_FILE"
                    counter_openwrt=$((counter_openwrt + 1))
                else
                    debug "Nie wykryto żadnych markerów dla $ip ($hostname)"
                fi
            fi
        fi
    done

    # Usuń plik tymczasowy
    rm "$temp_file"

    # Wyświetl podsumowanie
    local found_rpi=$counter_rpi
    local found_radxa=$counter_radxa
    local found_openwrt=$counter_openwrt
    local found_other=$counter_other
    local found_total=$((found_rpi + found_radxa + found_openwrt + found_other))

    echo -e "\n${GREEN}Skanowanie zakończone:${NC}"
    echo -e "- Wykryto ${BOLD}${found_total}${NC} urządzeń:"
    echo -e "  - Raspberry Pi: ${BOLD}${found_rpi}${NC}"
    echo -e "  - Radxa: ${BOLD}${found_radxa}${NC}"
    echo -e "  - OpenWRT: ${BOLD}${found_openwrt}${NC}"
    echo -e "  - Inne: ${BOLD}${found_other}${NC}"
    echo -e "- Wyniki zapisano do plików: ${BOLD}${OUTPUT_FILE}${NC} i ${BOLD}${BASE_OUTPUT_FILE}${NC}"

    return 0
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