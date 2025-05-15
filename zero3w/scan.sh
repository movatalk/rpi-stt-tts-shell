#!/bin/bash
# scan.sh - Skaner Raspberry Pi w sieci lokalnej zapisujący wyniki do pliku CSV
# Author: Tom Sapletta
# Data: 15 maja 2025

# Ustaw kodowanie kolorów
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Nazwa pliku wyjściowego CSV
OUTPUT_FILE="devices.csv"

# Sprawdź wymagane narzędzia
for cmd in nmap grep awk; do
    if ! command -v "$cmd" &> /dev/null; then
        echo -e "${RED}Błąd: Narzędzie '$cmd' nie jest zainstalowane.${NC}"
        echo -e "Zainstaluj je za pomocą:"

        if [ -f /etc/debian_version ]; then
            echo -e "  sudo apt-get install $cmd"
        elif [ -f /etc/redhat-release ]; then
            echo -e "  sudo dnf install $cmd"
        elif [ -f /etc/arch-release ]; then
            echo -e "  sudo pacman -S $cmd"
        else
            echo -e "  Zainstaluj '$cmd' używając menedżera pakietów swojego systemu"
        fi

        exit 1
    fi
done

# Funkcja określająca domyślny interfejs sieciowy
get_default_interface() {
    # Różne metody dla różnych systemów
    if [ "$(uname)" == "Linux" ]; then
        # Linux - sprawdź trasę domyślną
        route -n | grep '^0.0.0.0' | grep -o '[^ ]*

# Uruchomienie programu
main "$@"
 | head -n1
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

        # Wydobądź trzy pierwsze oktety adresu IP
        IFS=. read -r i1 i2 i3 i4 <<< "$ip"
        network="$i1.$i2.$i3.0/24"
    elif [ "$(uname)" == "Darwin" ]; then
        # macOS
        ip=$(ifconfig "$interface" | grep "inet " | awk '{print $2}')

        # Wydobądź trzy pierwsze oktety adresu IP
        first_three=$(echo "$ip" | cut -d. -f1-3)
        network="$first_three.0/24"
    else
        # Domyślny zakres dla nieznanych systemów
        network="192.168.1.0/24"
    fi

    echo "$network"
}

# Funkcja wykrywająca urządzenia Raspberry Pi
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

    # Licznik znalezionych urządzeń Raspberry Pi
    counter=0

    # Przetwarzanie wyników
    grep "22/open" "$temp_file" | while read -r line; do
        ip=$(echo "$line" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
        if [ -n "$ip" ]; then
            # Próba określenia czy to Raspberry Pi
            hostname=$(host "$ip" 2>/dev/null | grep "domain name pointer" | cut -d' ' -f5 | sed 's/\.$//')

            # Jeśli nie znaleziono nazwy, użyj "unknown"
            hostname=${hostname:-"unknown"}

            # Domyślne wartości
            is_raspberry_pi="false"
            os_info="unknown"
            model="unknown"

            # Sprawdź czy nazwa sugeruje Pi
            if [[ $hostname == *raspberry* || $hostname == *pi* ]]; then
                is_raspberry_pi="probable"
            fi

            # Próba pobrania informacji z urządzenia bez logowania
            # Najpierw próbujemy użytkownika 'pi' (domyślny dla Raspberry Pi)
            ssh_output=$(ssh -o BatchMode=yes -o ConnectTimeout=2 -o StrictHostKeyChecking=no "pi@$ip" "cat /etc/os-release 2>/dev/null || cat /etc/issue; cat /proc/cpuinfo | grep 'Model'" 2>/dev/null)

            # Jeśli się nie udało, spróbuj z użytkownikiem 'root'
            if [ -z "$ssh_output" ]; then
                ssh_output=$(ssh -o BatchMode=yes -o ConnectTimeout=2 -o StrictHostKeyChecking=no "root@$ip" "cat /etc/os-release 2>/dev/null || cat /etc/issue; cat /proc/cpuinfo | grep 'Model'" 2>/dev/null)
            fi

            # Jeśli udało się uzyskać jakiekolwiek dane przez SSH
            if [ -n "$ssh_output" ]; then
                # Sprawdź, czy to Raspberry Pi na podstawie zwróconych danych
                if [[ $ssh_output == *raspberry* || $ssh_output == *raspbian* ]]; then
                    is_raspberry_pi="true"

                    # Wyciągnij informacje o systemie operacyjnym
                    if [[ $ssh_output == *PRETTY_NAME* ]]; then
                        os_info=$(echo "$ssh_output" | grep "PRETTY_NAME" | cut -d'"' -f2)
                    elif [[ $ssh_output == *Raspbian* ]]; then
                        os_info=$(echo "$ssh_output" | grep "Raspbian" | head -n1 | tr -d '\n\r')
                    else
                        os_info="Raspberry Pi OS (unknown version)"
                    fi

                    # Wyciągnij model Raspberry Pi
                    if [[ $ssh_output == *"Model"* ]]; then
                        model=$(echo "$ssh_output" | grep "Model" | cut -d':' -f2 | tr -d '\n\r' | sed -e 's/^[[:space:]]*//')
                    fi

                    # Zwiększ licznik
                    counter=$((counter + 1))
                fi
            fi

            # Tylko jeśli to Raspberry Pi lub prawdopodobne Raspberry Pi, zapisz do CSV
            if [[ "$is_raspberry_pi" == "true" || "$is_raspberry_pi" == "probable" ]]; then
                # Usuń potencjalne przecinki z pól, które mogłyby zepsuć format CSV
                hostname=$(echo "$hostname" | tr ',' ' ')
                os_info=$(echo "$os_info" | tr ',' ' ')
                model=$(echo "$model" | tr ',' ' ')

                # Zapisz do pliku CSV
                echo "$ip,$hostname,$is_raspberry_pi,$os_info,$model,$timestamp" >> "$OUTPUT_FILE"
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

# Uruchomienie programu
main "$@"