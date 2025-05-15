#!/bin/bash
# manager.sh - Utility do zarządzania konfiguracjami SSH
# Autor: Tom Sapletta
# Data: 15 maja 2025

# Ścieżki
HOME_HOSTS_DIR="${HOME}/hosts"

# Ustaw kodowanie kolorów
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
BOLD='\033[1m'

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

# Funkcja znajdująca katalog hosta
find_host_dir() {
    local host="$1"
    local normalized_host
    normalized_host=$(echo "$host" | sed 's/[^a-zA-Z0-9_-]/_/g' | tr '[:upper:]' '[:lower:]')

    local possible_dirs=(
        "$HOME_HOSTS_DIR/$host"
        "$HOME_HOSTS_DIR/$normalized_host"
    )

    for dir in "${possible_dirs[@]}"; do
        if [ -d "$dir" ]; then
            echo "$dir"
            return 0
        fi
    done

    return 1
}

# Funkcja ładująca konfigurację hosta
load_host_config() {
    local host_dir="$1"
    local env_file="$host_dir/.env"

    if [ ! -f "$env_file" ]; then
        log "ERROR" "Nie znaleziono pliku środowiskowego w $host_dir"
        return 1
    fi

    # Załaduj zmienne środowiskowe bezpiecznie
    HOST=""
    USER=""
    PORT=""
    KEY=""

    # Odczytaj zmienne linia po linii
    while IFS='=' read -r name value; do
        # Przytnij białe znaki i usuń cudzysłowy
        name=$(echo "$name" | xargs)
        value=$(echo "$value" | xargs | sed "s/^['\"]//; s/['\"]$//")

        # Ustaw zmienne
        case "$name" in
            HOST) HOST="$value" ;;
            USER) USER="$value" ;;
            PORT) PORT="$value" ;;
            KEY) KEY="$value" ;;
        esac
    done < <(grep -E '^(HOST|USER|PORT|KEY)=' "$env_file")

    # Sprawdź wymagane zmienne
    if [ -z "$HOST" ] || [ -z "$USER" ]; then
        log "ERROR" "Brakuje wymaganej konfiguracji w $env_file"
        return 1
    fi

    # Ustaw domyślne wartości
    PORT="${PORT:-22}"
    KEY="${KEY:-$HOME/.ssh/id_rsa}"

    return 0
}

# Funkcja upewniająca się, że klucz SSH istnieje
ensure_ssh_key() {
    local key_path="$1"

    if [ ! -f "$key_path" ]; then
        log "WARN" "Generowanie klucza SSH: $key_path"
        ssh-keygen -t rsa -b 4096 -f "$key_path" -N ""
    fi

    # Upewnij się, że uprawnienia są poprawne
    chmod 600 "$key_path"
    chmod 644 "${key_path}.pub"
}

# Funkcja kopiująca klucz publiczny SSH do zdalnego hosta
copy_ssh_key() {
    local host="$1"
    local user="$2"
    local port="$3"
    local key_path="$4"

    log "INFO" "Kopiowanie klucza publicznego SSH do $host"
    ssh-copy-id -i "${key_path}.pub" -p "$port" "$user@$host"
}

# Funkcja testująca połączenie SSH
test_connection() {
    local host="$1"
    local user="$2"
    local port="$3"

    log "INFO" "Testowanie połączenia SSH do $host"
    ssh -vv -p "$port" "$user@$host" exit
}

# Funkcja konfigurująca konkretnego hosta
configure_host() {
    local host="$1"
    local host_dir

    # Znajdź katalog hosta
    if ! host_dir=$(find_host_dir "$host"); then
        log "ERROR" "Nie znaleziono konfiguracji dla hosta $host"
        return 1
    fi

    # Załaduj konfigurację hosta
    if ! load_host_config "$host_dir"; then
        log "ERROR" "Nie udało się załadować konfiguracji dla $host"
        return 1
    fi

    # Upewnij się, że klucz SSH istnieje
    ensure_ssh_key "$KEY"

    # Kopiuj klucz SSH (interaktywnie)
    copy_ssh_key "$HOST" "$USER" "$PORT" "$KEY"

    # Testuj połączenie
    test_connection "$HOST" "$USER" "$PORT"

    log "SUCCESS" "Konfiguracja hosta $host zakończona"
}

# Funkcja wyświetlająca dostępne hosty
list_hosts() {
    log "INFO" "Dostępne hosty:"
    if [ ! -d "$HOME_HOSTS_DIR" ]; then
        log "WARN" "Nie znaleziono katalogu hostów"
        return 1
    fi

    local found=0
    for host_dir in "$HOME_HOSTS_DIR"/*; do
        if [ -d "$host_dir" ] && [ -f "$host_dir/.env" ]; then
            host=$(basename "$host_dir")
            # Odczytaj nazwę hosta z pliku .env
            hostname=$(grep "HOSTNAME=" "$host_dir/.env" | head -n 1 | cut -d'=' -f2 | xargs)
            # Odczytaj typ urządzenia z pliku .env
            device_type=$(grep "DEVICE_TYPE=" "$host_dir/.env" | head -n 1 | cut -d'=' -f2 | xargs)
            # Odczytaj model z pliku .env
            model=$(grep "MODEL=" "$host_dir/.env" | head -n 1 | cut -d'=' -f2 | xargs)

            echo -e "- ${BOLD}$host${NC} (${hostname:-Nieznana nazwa hosta})"
            echo -e "  Typ: ${device_type:-Nieznany}, Model: ${model:-Nieznany}"
            found=$((found + 1))
        fi
    done

    if [ "$found" -eq 0 ]; then
        log "WARN" "Brak skonfigurowanych hostów"
        return 1
    fi
}

# Funkcja wyświetlająca pomoc
show_help() {
    echo -e "${BOLD}Utility do zarządzania konfiguracjami SSH${NC}"
    echo "Użycie: $0 [HOST|KOMENDA]"
    echo ""
    echo "Argumenty:"
    echo "  HOST      Nazwa lub adres IP hosta do skonfigurowania"
    echo "  KOMENDA   Jedna z poniższych komend:"
    echo "    list    Wyświetla listę dostępnych hostów"
    echo "    help    Wyświetla tę pomoc"
    echo ""
    echo "Opis:"
    echo "  Skrypt zarządza konfiguracjami SSH dla zdefiniowanych hostów."
    echo "  Jeśli nie podano argumentów, wyświetla listę dostępnych hostów."
    echo "  Jeśli podano nazwę hosta, konfiguruje ten host (generuje klucz, kopiuje go, testuje połączenie)."
    echo ""
    echo "Przykłady:"
    echo "  $0                # Wyświetla listę hostów"
    echo "  $0 list           # Wyświetla listę hostów"
    echo "  $0 192.168.1.100  # Konfiguruje hosta o adresie 192.168.1.100"
    echo ""
}

# Główna funkcja
main() {
    # Wyświetl pomoc jeśli podano argument -h lub --help
    if [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ "$1" = "help" ]; then
        show_help
        return 0
    fi

    # Sprawdź czy katalog hostów istnieje
    if [ ! -d "$HOME_HOSTS_DIR" ]; then
        log "ERROR" "Nie skonfigurowano żadnych hostów. Najpierw uruchom skrypt importu CSV."
        return 1
    fi

    # Obsługa różnych akcji
    if [ $# -eq 0 ]; then
        list_hosts
    elif [ "$1" = "list" ]; then
        list_hosts
    else
        configure_host "$1"
    fi
}

# Uruchom główną funkcję z wszystkimi argumentami
main "$@"