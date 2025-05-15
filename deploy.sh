# Uruchomienie programu
main "$@"#!/bin/bash
# deploy.sh - Skrypt do wdrażania, testowania i logowania projektu na urządzeniach Raspberry Pi
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

# Konfiguracja
CSV_FILE="devices.csv"
LOG_DIR="deployment_logs"
TIMESTAMP=$(date "+%Y%m%d_%H%M%S")
LOG_FILE="${LOG_DIR}/deployment_${TIMESTAMP}.log"
PROJECT_DIR="project_files"  # Katalog z plikami projektu do wdrożenia
SSH_USER="pi"                # Domyślny użytkownik SSH dla Raspberry Pi
SSH_PASSWORD="raspberry"     # Domyślne hasło (używane tylko jeśli sshpass jest dostępny)
REMOTE_DIR="/home/pi/deployed_project"  # Katalog docelowy na Raspberry Pi
TEST_SCRIPT="test_script.sh"  # Skrypt testowy do uruchomienia po wdrożeniu

# Sprawdź wymagane narzędzia
for cmd in ssh scp grep; do
    if ! command -v "$cmd" &> /dev/null; then
        echo -e "${RED}Błąd: Narzędzie '$cmd' nie jest zainstalowane.${NC}"
        echo -e "Zainstaluj je za pomocą swojego menedżera pakietów."
        exit 1
    fi
done

# Funkcja do logowania
log() {
    local level=$1
    local message=$2
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    # Utworzenie katalogu logów, jeśli nie istnieje
    mkdir -p "$(dirname "$LOG_FILE")"

    # Zapisz do pliku log
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"

    # Wyświetl także na konsoli z kolorami
    case $level in
        INFO)
            echo -e "${BLUE}[$timestamp] [INFO] $message${NC}"
            ;;
        SUCCESS)
            echo -e "${GREEN}[$timestamp] [SUCCESS] $message${NC}"
            ;;
        WARNING)
            echo -e "${YELLOW}[$timestamp] [WARNING] $message${NC}"
            ;;
        ERROR)
            echo -e "${RED}[$timestamp] [ERROR] $message${NC}"
            ;;
        *)
            echo -e "[$timestamp] [$level] $message"
            ;;
    esac
}

# Sprawdź czy plik CSV istnieje
check_csv_file() {
    if [ ! -f "$CSV_FILE" ]; then
        log "ERROR" "Plik $CSV_FILE nie istnieje. Najpierw uruchom scan.sh, aby wykryć urządzenia Raspberry Pi."
        exit 1
    fi

    # Sprawdź czy plik CSV zawiera jakiekolwiek urządzenia (pomijając nagłówek)
    if [ $(wc -l < "$CSV_FILE") -le 1 ]; then
        log "ERROR" "Plik $CSV_FILE nie zawiera żadnych urządzeń. Uruchom scan.sh ponownie."
        exit 1
    fi

    log "INFO" "Znaleziono plik $CSV_FILE z listą urządzeń Raspberry Pi."
}

# Przygotuj katalogi
prepare_directories() {
    # Utwórz katalog logów, jeśli nie istnieje
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR"
        log "INFO" "Utworzono katalog logów: $LOG_DIR"
    fi

    # Sprawdź czy katalog z projektem istnieje
    if [ ! -d "$PROJECT_DIR" ]; then
        log "ERROR" "Katalog projektu $PROJECT_DIR nie istnieje. Utwórz go i umieść w nim pliki projektu."
        exit 1
    fi

    # Sprawdź czy skrypt testowy istnieje
    if [ ! -f "${PROJECT_DIR}/${TEST_SCRIPT}" ]; then
        log "WARNING" "Skrypt testowy ${PROJECT_DIR}/${TEST_SCRIPT} nie istnieje. Testy nie będą uruchamiane."
    else
        # Upewnij się, że skrypt testowy ma uprawnienia do wykonywania
        chmod +x "${PROJECT_DIR}/${TEST_SCRIPT}"
    fi
}

# Funkcja do wdrażania projektu na pojedynczym urządzeniu
deploy_to_device() {
    local ip=$1
    local hostname=$2
    local is_rpi=$3
    local device_log="${LOG_DIR}/device_${ip}_${TIMESTAMP}.log"

    log "INFO" "Rozpoczynam wdrażanie na urządzeniu $ip ($hostname)"

    # Sprawdź połączenie SSH
    if ! ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no "${SSH_USER}@${ip}" "echo 'SSH connection test'" &> /dev/null; then
        # Jeśli nie udało się połączyć przy użyciu kluczy SSH, spróbuj z hasłem (jeśli sshpass jest dostępny)
        if command -v sshpass &> /dev/null; then
            if ! sshpass -p "$SSH_PASSWORD" ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "${SSH_USER}@${ip}" "echo 'SSH connection test'" &> /dev/null; then
                log "ERROR" "Nie można połączyć się z $ip. Sprawdź dostępność urządzenia i dane logowania."
                return 1
            fi
            # Jeśli udało się z sshpass, ustaw flagi do użycia sshpass
            use_sshpass=true
        else
            log "ERROR" "Nie można połączyć się z $ip. Sprawdź dostępność urządzenia i dane logowania."
            return 1
        fi
    else
        use_sshpass=false
    fi

    log "INFO" "Połączenie SSH z $ip nawiązane pomyślnie."

    # Utwórz katalog docelowy na zdalnym urządzeniu
    if $use_sshpass; then
        sshpass -p "$SSH_PASSWORD" ssh -o StrictHostKeyChecking=no "${SSH_USER}@${ip}" "mkdir -p ${REMOTE_DIR}" &>> "$device_log"
    else
        ssh -o StrictHostKeyChecking=no "${SSH_USER}@${ip}" "mkdir -p ${REMOTE_DIR}" &>> "$device_log"
    fi

    if [ $? -ne 0 ]; then
        log "ERROR" "Nie można utworzyć katalogu ${REMOTE_DIR} na $ip"
        return 1
    fi

    # Kopiuj pliki projektu na zdalne urządzenie
    log "INFO" "Kopiuję pliki projektu na $ip..."

    if $use_sshpass; then
        sshpass -p "$SSH_PASSWORD" scp -r -o StrictHostKeyChecking=no "${PROJECT_DIR}/"* "${SSH_USER}@${ip}:${REMOTE_DIR}/" &>> "$device_log"
    else
        scp -r -o StrictHostKeyChecking=no "${PROJECT_DIR}/"* "${SSH_USER}@${ip}:${REMOTE_DIR}/" &>> "$device_log"
    fi

    if [ $? -ne 0 ]; then
        log "ERROR" "Nie można skopiować plików projektu na $ip"
        return 1
    fi

    log "SUCCESS" "Pliki projektu zostały skopiowane na $ip"

    # Jeśli istnieje skrypt testowy, uruchom go na zdalnym urządzeniu
    if [ -f "${PROJECT_DIR}/${TEST_SCRIPT}" ]; then
        log "INFO" "Uruchamiam testy na $ip..."

        if $use_sshpass; then
            sshpass -p "$SSH_PASSWORD" ssh -o StrictHostKeyChecking=no "${SSH_USER}@${ip}" "cd ${REMOTE_DIR} && chmod +x ${TEST_SCRIPT} && ./${TEST_SCRIPT}" &>> "$device_log"
        else
            ssh -o StrictHostKeyChecking=no "${SSH_USER}@${ip}" "cd ${REMOTE_DIR} && chmod +x ${TEST_SCRIPT} && ./${TEST_SCRIPT}" &>> "$device_log"
        fi

        if [ $? -eq 0 ]; then
            log "SUCCESS" "Testy na $ip zakończone powodzeniem"
        else
            log "WARNING" "Testy na $ip zakończone niepowodzeniem. Sprawdź logi dla szczegółów."
        fi
    fi

    # Pobierz informacje o systemie dla celów logowania
    log "INFO" "Pobieranie informacji systemowych z $ip..."
    if $use_sshpass; then
        sshpass -p "$SSH_PASSWORD" ssh -o StrictHostKeyChecking=no "${SSH_USER}@${ip}" "uname -a; uptime; free -h; df -h; cat /etc/os-release" &>> "$device_log"
    else
        ssh -o StrictHostKeyChecking=no "${SSH_USER}@${ip}" "uname -a; uptime; free -h; df -h; cat /etc/os-release" &>> "$device_log"
    fi

    log "SUCCESS" "Wdrażanie na $ip zakończone powodzeniem"

    return 0
}

# Funkcja do wdrażania projektu na wszystkich urządzeniach z pliku CSV
deploy_to_all_devices() {
    local success_count=0
    local failure_count=0
    local total_count=0

    # Pobierz liczbę urządzeń (pomijając nagłówek)
    total_count=$(($(wc -l < "$CSV_FILE") - 1))

    log "INFO" "Rozpoczynam wdrażanie na $total_count urządzeniach..."

    # Pomijając pierwszy wiersz (nagłówek), iteruj przez każde urządzenie w pliku CSV
    tail -n +2 "$CSV_FILE" | while IFS=',' read -r ip hostname is_rpi os_info model timestamp; do
        # Sprawdź czy to jest faktycznie Raspberry Pi
        if [[ "$is_rpi" == "true" || "$is_rpi" == "probable" ]]; then
            # Wdrożenie na urządzeniu
            if deploy_to_device "$ip" "$hostname" "$is_rpi"; then
                ((success_count++))
            else
                ((failure_count++))
            fi
        else
            log "WARNING" "Pomijam urządzenie $ip ($hostname) - nie jest to Raspberry Pi"
        fi
    done

    # Podsumowanie
    log "INFO" "===== PODSUMOWANIE WDROŻENIA ====="
    log "INFO" "Łącznie urządzeń: $total_count"
    log "SUCCESS" "Udanych wdrożeń: $success_count"
    log "WARNING" "Nieudanych wdrożeń: $failure_count"

    if [ $failure_count -eq 0 ]; then
        log "SUCCESS" "Wdrażanie zakończone pełnym sukcesem!"
    else
        log "WARNING" "Wdrażanie zakończone częściowym sukcesem. Niektóre urządzenia mogą wymagać ręcznego wdrożenia."
    fi
}

# Funkcja do generowania raportu HTML
generate_html_report() {
    local report_file="${LOG_DIR}/deployment_report_${TIMESTAMP}.html"

    log "INFO" "Generowanie raportu HTML..."

    # Utwórz plik raportu HTML
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html lang="pl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Raport wdrożenia na Raspberry Pi</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        header {
            background-color: #f4f4f4;
            padding: 20px;
            margin-bottom: 20px;
            border-radius: 5px;
        }
        h1, h2, h3 {
            color: #444;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        table, th, td {
            border: 1px solid #ddd;
        }
        th, td {
            padding: 12px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        .success {
            color: green;
        }
        .warning {
            color: orange;
        }
        .error {
            color: red;
        }
        .info {
            color: blue;
        }
        .log-entry {
            margin-bottom: 5px;
            padding: 5px;
            border-bottom: 1px solid #eee;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>Raport wdrożenia na Raspberry Pi</h1>
            <p>Data wdrożenia: $(date '+%Y-%m-%d %H:%M:%S')</p>
        </header>

        <section>
            <h2>Podsumowanie</h2>
            <p>Plik źródłowy CSV: <strong>$CSV_FILE</strong></p>
            <p>Katalog projektu: <strong>$PROJECT_DIR</strong></p>
            <p>Katalog logów: <strong>$LOG_DIR</strong></p>
        </section>

        <section>
            <h2>Urządzenia</h2>
            <table>
                <thead>
                    <tr>
                        <th>IP</th>
                        <th>Nazwa hosta</th>
                        <th>Model</th>
                        <th>System</th>
                        <th>Status wdrożenia</th>
                    </tr>
                </thead>
                <tbody>
EOF

    # Dodaj informacje o każdym urządzeniu
    tail -n +2 "$CSV_FILE" | while IFS=',' read -r ip hostname is_rpi os_info model timestamp; do
        # Sprawdź status wdrożenia dla tego urządzenia
        device_log="${LOG_DIR}/device_${ip}_${TIMESTAMP}.log"
        if [ -f "$device_log" ]; then
            if grep -q "ERROR" "$device_log"; then
                status="<span class='error'>Niepowodzenie</span>"
            else
                status="<span class='success'>Sukces</span>"
            fi
        else
            status="<span class='warning'>Pominięte</span>"
        fi

        # Dodaj wiersz do tabeli
        cat >> "$report_file" << EOF
                    <tr>
                        <td>$ip</td>
                        <td>$hostname</td>
                        <td>$model</td>
                        <td>$os_info</td>
                        <td>$status</td>
                    </tr>
EOF
    done

    # Dodaj resztę dokumentu HTML
    cat >> "$report_file" << EOF
                </tbody>
            </table>
        </section>

        <section>
            <h2>Log główny</h2>
            <div class="log-container">
EOF

    # Dodaj zawartość głównego pliku log
    if [ -f "$LOG_FILE" ]; then
        while IFS= read -r line; do
            # Określ klasę CSS na podstawie poziomu logu
            if [[ $line == *"[ERROR]"* ]]; then
                class="error"
            elif [[ $line == *"[WARNING]"* ]]; then
                class="warning"
            elif [[ $line == *"[SUCCESS]"* ]]; then
                class="success"
            elif [[ $line == *"[INFO]"* ]]; then
                class="info"
            else
                class=""
            fi

            echo "                <div class=\"log-entry ${class}\">${line}</div>" >> "$report_file"
        done < "$LOG_FILE"
    else
        echo "                <p>Brak dostępnych logów.</p>" >> "$report_file"
    fi

    # Zakończ plik HTML
    cat >> "$report_file" << EOF
            </div>
        </section>
    </div>
</body>
</html>
EOF

    log "SUCCESS" "Raport HTML wygenerowany: $report_file"
}

# Główna funkcja
main() {
    local ip_to_deploy=""

    # Parsowanie argumentów wiersza poleceń
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -f|--file)
                CSV_FILE="$2"
                shift 2
                ;;
            -u|--user)
                SSH_USER="$2"
                shift 2
                ;;
            -p|--password)
                SSH_PASSWORD="$2"
                shift 2
                ;;
            -d|--dir)
                PROJECT_DIR="$2"
                shift 2
                ;;
            -r|--remote-dir)
                REMOTE_DIR="$2"
                shift 2
                ;;
            -i|--ip)
                ip_to_deploy="$2"
                shift 2
                ;;
            -h|--help)
                echo -e "${BOLD}Skrypt wdrażania projektu na Raspberry Pi${NC}"
                echo "Użycie: $0 [OPCJE]"
                echo ""
                echo "Opcje:"
                echo "  -f, --file FILE       Użyj podanego pliku CSV z urządzeniami (domyślnie: $CSV_FILE)"
                echo "  -u, --user USER       Użyj podanej nazwy użytkownika SSH (domyślnie: $SSH_USER)"
                echo "  -p, --password PASS   Użyj podanego hasła SSH (domyślnie: $SSH_PASSWORD)"
                echo "  -d, --dir DIR         Użyj podanego katalogu projektu (domyślnie: $PROJECT_DIR)"
                echo "  -r, --remote-dir DIR  Użyj podanego katalogu zdalnego (domyślnie: $REMOTE_DIR)"
                echo "  -i, --ip IP           Wdróż tylko na konkretne urządzenie o podanym IP"
                echo "  -h, --help            Wyświetl tę pomoc"
                echo ""
                echo "Przykłady:"
                echo "  $0 -f moje_urzadzenia.csv -u admin"
                echo "  $0 -d ~/moj_projekt -r /opt/aplikacja"
                echo "  $0 -i 192.168.1.100"
                echo ""
                exit 0
                ;;
            *)
                echo -e "${RED}Nieznana opcja: $1${NC}" >&2
                exit 1
                ;;
        esac
    done

    log "INFO" "===================== ROZPOCZĘCIE WDRAŻANIA ====================="
    log "INFO" "Użytkownik: $SSH_USER, Katalog projektu: $PROJECT_DIR, Katalog zdalny: $REMOTE_DIR"

    # Sprawdź czy plik CSV istnieje
    check_csv_file

    # Przygotuj katalogi
    prepare_directories

    # Jeśli podano konkretny adres IP, wdróż tylko tam
    if [ -n "$ip_to_deploy" ]; then
        log "INFO" "Wdrażanie tylko na urządzenie o adresie IP: $ip_to_deploy"

        # Znajdź odpowiedni wiersz w pliku CSV
        while IFS=',' read -r ip hostname is_rpi os_info model timestamp; do
            if [ "$ip" == "$ip_to_deploy" ]; then
                deploy_to_device "$ip" "$hostname" "$is_rpi"
                break
            fi
        done < <(tail -n +2 "$CSV_FILE")
    else
        # W przeciwnym razie wdróż na wszystkie urządzenia
        deploy_to_all_devices
    fi

    # Wygeneruj raport HTML
    generate_html_report

    log "INFO" "===================== WDRAŻANIE ZAKOŃCZONE ====================="
}

# Uruchomienie programu
main "$@"