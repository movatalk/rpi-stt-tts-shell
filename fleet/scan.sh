#!/bin/bash
# Skaner Raspberry Pi z konfiguracją z plików

# Konfiguracja plików źródłowych
CONFIG_DIR="${HOME}/hosts"
USERS_FILE="$CONFIG_DIR/users.txt"
COMMANDS_FILE="$CONFIG_DIR/commands.txt"

# Ustaw kodowanie kolorów
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Nazwa pliku wyjściowego CSV
OUTPUT_FILE="devices.csv"

# Funkcja logowania
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    if [ "$level" = "INFO" ]; then
        echo "[INFO] $timestamp - $message"
    elif [ "$level" = "WARN" ]; then
        echo "[WARN] $timestamp - $message" >&2
    elif [ "$level" = "ERROR" ]; then
        echo "[ERROR] $timestamp - $message" >&2
    else
        echo "$message"
    fi
}

# Funkcja tworzenia domyślnych plików konfiguracyjnych
create_default_config_files() {
    # Upewnij się, że katalog istnieje
    mkdir -p "$CONFIG_DIR"

    # Domyślni użytkownicy
    if [ ! -f "$USERS_FILE" ]; then
        cat > "$USERS_FILE" << EOF
# Lista użytkowników do próby połączenia SSH
pi
raspberry
admin
root
EOF
        log "INFO" "Utworzono domyślny plik użytkowników: $USERS_FILE"
    fi

    # Domyślne komendy detekcyjne
    if [ ! -f "$COMMANDS_FILE" ]; then
        cat > "$COMMANDS_FILE" << EOF
# Komendy do sprawdzenia Raspberry Pi
cat /etc/os-release
cat /proc/cpuinfo
uname -a
cat /etc/issue
vcgencmd version
EOF
        log "INFO" "Utworzono domyślny plik komend: $COMMANDS_FILE"
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

# Główna funkcja skanowania
scan_raspberry_pi() {
    local range=$1
    local temp_file=$(mktemp)
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    echo -e "${YELLOW}Skanowanie sieci ${BOLD}$range${NC}${YELLOW} w poszukiwaniu urządzeń Raspberry Pi...${NC}"
    echo -e "To może potrwać kilka chwil."

    # Stwórz lub wyczyść plik wyjściowy CSV i dodaj nagłówki
    echo "ip,hostname,is_raspberry_pi,os_info,model,scan_date" > "$OUTPUT_FILE"

    # Skanowanie z nmap - szukamy otwartych portów SSH
    nmap -p 22 --open "$range" -oG "$temp_file"

    # Wczytaj użytkowników i komendy
    local users_list=$(load_array_from_file "$USERS_FILE")
    local commands_list=$(load_array_from_file "$COMMANDS_FILE")

    # Licznik znalezionych urządzeń Raspberry Pi
    local counter=0

    # Przetwarzanie wyników
    grep "22/open" "$temp_file" | while read -r line; do
        local ip=$(echo "$line" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
        if [ -n "$ip" ]; then
            # Próba nazwy hosta
            local hostname=$(host "$ip" 2>/dev/null | grep "domain name pointer" | cut -d' ' -f5 | sed 's/\.$//')
            hostname=${hostname:-"unknown"}

            # Domyślne wartości
            local is_raspberry_pi="false"
            local os_info="unknown"
            local model="unknown"

            # Próba detekcji Raspberry Pi dla każdego użytkownika
            for user in $users_list; do
                for cmd in $commands_list; do
                    # Próba wykonania komendy SSH
                    local pi_info=$(ssh -o BatchMode=yes -o ConnectTimeout=3 -o StrictHostKeyChecking=no "${user}@${ip}" "$cmd" 2>/dev/null)

                    if [ -n "$pi_info" ]; then
                        # Sprawdź, czy to Raspberry Pi
                        if echo "$pi_info" | grep -iE "raspberry|raspbian|raspberry pi|bcm" > /dev/null; then
                            is_raspberry_pi="true"

                            # Wyciągnij informacje o systemie
                            if echo "$pi_info" | grep -q "PRETTY_NAME"; then
                                os_info=$(echo "$pi_info" | grep "PRETTY_NAME" | cut -d'"' -f2)
                            else
                                os_info=$(echo "$pi_info" | head -n1)
                            fi

                            # Wyciągnij model
                            if echo "$pi_info" | grep -q "Model"; then
                                model=$(echo "$pi_info" | grep "Model" | cut -d':' -f2 | xargs)
                            elif echo "$pi_info" | grep -q "Revision"; then
                                model=$(echo "$pi_info" | grep "Revision" | cut -d':' -f2 | xargs)
                            fi

                            break 2  # Wyjdź z obu pętli po znalezieniu
                        fi
                    fi
                done
            done

            # Jeśli nie znaleziono, ale nazwa hosta sugeruje RPi
            if [ "$is_raspberry_pi" = "false" ] && [[ $hostname == *raspberry* || $hostname == *pi* ]]; then
                is_raspberry_pi="probable"
            fi

            # Zapisz do pliku, jeśli znaleziono RPi
            if [[ "$is_raspberry_pi" == "true" || "$is_raspberry_pi" == "probable" ]]; then
                # Usuń potencjalne przecinki
                hostname=$(echo "$hostname" | tr ',' ' ')
                os_info=$(echo "$os_info" | tr ',' ' ')
                model=$(echo "$model" | tr ',' ' ')

                echo "$ip,$hostname,$is_raspberry_pi,$os_info,$model,$timestamp" >> "$OUTPUT_FILE"
                counter=$((counter + 1))
            fi
        fi
    done

    # Usuń plik tymczasowy
    rm "$temp_file"

    # Wyświetl podsumowanie
    local found=$(grep -v "^ip,hostname" "$OUTPUT_FILE" | wc -l)

    echo -e "\n${GREEN}Skanowanie zakończone:${NC}"
    echo -e "- Wykryto ${BOLD}${found}${NC} urządzeń Raspberry Pi"
    echo -e "- Wyniki zapisano do pliku: ${BOLD}${OUTPUT_FILE}${NC}"

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
    local network

    if [ "$(uname)" == "Linux" ]; then
        # Linux
        network=$(ip -o -4 addr show dev "$interface" | awk '{print $4}')
    elif [ "$(uname)" == "Darwin" ]; then
        # macOS
        network=$(ifconfig "$interface" | grep "inet " | awk '{print $4}')
    else
        # Domyślny zakres dla nieznanych systemów
        network="192.168.1.0/24"
    fi

    # Jeśli nie udało się wydobyć zakresu, użyj domyślnego
    if [ -z "$network" ]; then
        network="192.168.1.0/24"
    fi

    echo "$network"
}

# Funkcja wyświetlająca pomoc
show_help() {
    echo -e "${BOLD}Skaner Raspberry Pi w sieci${NC}"
    echo "Użycie: $0 [OPCJE]"
    echo ""
    echo "Opcje:"
    echo "  -r, --range RANGE    Skanuj podany zakres sieci (np. 192.168.1.0/24)"
    echo "  -o, --output FILE    Zapisz wyniki do podanego pliku CSV (domyślnie: $OUTPUT_FILE)"
    echo "  -h, --help           Wyświetl tę pomoc"
    echo ""
    echo "Przykłady:"
    echo "  $0 -r 192.168.0.0/24"
    echo "  $0 --output moje_urzadzenia.csv"
    echo ""
}

# Główna funkcja
main() {
    # Utwórz domyślne pliki konfiguracyjne, jeśli nie istnieją
    create_default_config_files

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
    scan_raspberry_pi "$network_range"

    exit 0
}

# Uruchomienie programu
main "$@"