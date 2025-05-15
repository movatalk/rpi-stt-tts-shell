#!/bin/bash
# poetry.sh - Skrypt instalacyjny Poetry dla Radxa ZERO 3W/3E
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
POETRY_VERSION="1.7.1"  # Wersja Poetry
PYTHON_MIN_VERSION="3.7"  # Minimalna wymagana wersja Python
SWAP_FILE="/swapfile"  # Plik swap
HOME_DIR="$HOME"  # Katalog domowy użytkownika
DEMO_PROJECT_DIR="$HOME_DIR/poetry-demo"  # Katalog z przykładowym projektem

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
        echo "radxa_zero3"
        return 0
    elif [[ "$model" == *"Radxa"* ]]; then
        log "WARN" "Wykryto inny model Radxa, nie ZERO 3"
        log "WARN" "Wykryty model: $model"
        echo "radxa_other"
        return 0
    else
        log "WARN" "Nie wykryto modelu Radxa"
        log "WARN" "Wykryty model: $model"
        echo "other"
        return 1
    fi
}

# Sprawdź wymagane narzędzia
check_requirements() {
    log "INFO" "Sprawdzanie wymagań..."

    # Sprawdź Python
    if ! command -v python3 &> /dev/null; then
        log "ERROR" "Python 3 nie jest zainstalowany."
        return 1
    fi

    # Sprawdź wersję Python
    local python_version=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')

    if ! python3 -c "import sys; sys.exit(0 if sys.version_info >= (${PYTHON_MIN_VERSION/./,}) else 1)" &> /dev/null; then
        log "ERROR" "Python $python_version jest zainstalowany, ale wymagana jest wersja $PYTHON_MIN_VERSION lub nowsza."
        return 1
    fi

    log "INFO" "Python $python_version jest zainstalowany."

    # Sprawdź pip
    if ! command -v pip3 &> /dev/null; then
        log "WARN" "pip3 nie jest zainstalowany. Próba instalacji..."

        # Instalacja pip
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y python3-pip
        else
            log "ERROR" "Nie można zainstalować pip3. Spróbuj zainstalować ręcznie: sudo apt-get install python3-pip"
            return 1
        fi
    fi

    # Sprawdź curl
    if ! command -v curl &> /dev/null; then
        log "WARN" "curl nie jest zainstalowany. Próba instalacji..."

        # Instalacja curl
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y curl
        else
            log "ERROR" "Nie można zainstalować curl. Spróbuj zainstalować ręcznie: sudo apt-get install curl"
            return 1
        fi
    fi

    # Sprawdź git
    if ! command -v git &> /dev/null; then
        log "WARN" "git nie jest zainstalowany. Próba instalacji..."

        # Instalacja git
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y git
        else
            log "ERROR" "Nie można zainstalować git. Spróbuj zainstalować ręcznie: sudo apt-get install git"
            return 1
        fi
    fi

    log "SUCCESS" "Wszystkie wymagania spełnione."
    return 0
}

# Konfiguracja pamięci swap
configure_swap() {
    log "INFO" "Konfiguracja pamięci swap..."

    # Sprawdź czy swap jest już włączony
    if free | grep -q "Swap"; then
        log "INFO" "Swap jest już skonfigurowany."
        return 0
    fi

    # Wykryj ilość pamięci RAM
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

    # Utwórz plik swap
    sudo dd if=/dev/zero of=$SWAP_FILE bs=1M count=$swap_size
    sudo chmod 600 $SWAP_FILE
    sudo mkswap $SWAP_FILE
    sudo swapon $SWAP_FILE

    # Dodaj swap do fstab
    if ! grep -q "$SWAP_FILE" /etc/fstab; then
        echo "$SWAP_FILE swap swap defaults 0 0" | sudo tee -a /etc/fstab
    fi

    log "SUCCESS" "Pamięć swap została skonfigurowana."
}

# Zainstaluj Poetry
install_poetry() {
    log "INFO" "Instalowanie Poetry w wersji $POETRY_VERSION..."

    # Usuń istniejącą instalację Poetry
    if command -v poetry &> /dev/null; then
        log "WARN" "Poetry jest już zainstalowane. Usuwanie..."
        curl -sSL https://install.python-poetry.org | POETRY_UNINSTALL=1 python3 -
    fi

    # Instaluj Poetry
    log "INFO" "Pobieranie i instalacja Poetry..."
    curl -sSL https://install.python-poetry.org | POETRY_VERSION=$POETRY_VERSION python3 -

    # Sprawdź, czy instalacja się powiodła
    if ! command -v poetry &> /dev/null; then
        # Sprawdź, czy Poetry jest w ścieżce
        if [ -f "$HOME/.local/bin/poetry" ]; then
            # Dodaj do PATH
            export PATH="$HOME/.local/bin:$PATH"

            # Dodaj do .bashrc
            if ! grep -q "PATH=\"\$HOME/.local/bin:\$PATH\"" "$HOME/.bashrc"; then
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
            fi
        else
            log "ERROR" "Instalacja Poetry nie powiodła się."
            return 1
        fi
    fi

    # Skonfiguruj Poetry
    poetry config virtualenvs.in-project true

    log "SUCCESS" "Poetry zostało zainstalowane pomyślnie."

    # Wyświetl wersję
    log "INFO" "Zainstalowana wersja Poetry: $(poetry --version)"

    return 0
}

# Zainstaluj pakiety dla Radxa
install_radxa_packages() {
    log "INFO" "Instalowanie pakietów wymaganych dla Radxa..."

    # Instaluj pakiety wymagane dla Radxa
    sudo apt-get update
    sudo apt-get install -y python3-dev python3-venv python3-setuptools python3-wheel \
        libffi-dev build-essential libssl-dev libjpeg-dev zlib1g-dev libatlas-base-dev \
        libgpiod-dev

    # Sprawdź, czy instalacja się powiodła
    if [ $? -ne 0 ]; then
        log "ERROR" "Instalacja pakietów dla Radxa nie powiodła się."
        return 1
    fi

    log "SUCCESS" "Pakiety dla Radxa zostały zainstalowane pomyślnie."
    return 0
}

# Utwórz przykładowy projekt Poetry
create_demo_project() {
    local device_type="$1"
    log "INFO" "Tworzenie przykładowego projektu Poetry dla $device_type..."

    # Usuń istniejący katalog, jeśli istnieje
    if [ -d "$DEMO_PROJECT_DIR" ]; then
        log "WARN" "Katalog $DEMO_PROJECT_DIR już istnieje. Usuwanie..."
        rm -rf "$DEMO_PROJECT_DIR"
    fi

    # Utwórz nowy katalog projektu
    mkdir -p "$DEMO_PROJECT_DIR"
    cd "$DEMO_PROJECT_DIR"

    # Inicjalizuj projekt Poetry
    poetry init --no-interaction --name "radxa-demo" --description "Przykładowy projekt Poetry dla Radxa" --author "Użytkownik <user@example.com>" --python "^3.7"

    # Dodaj wymagane pakiety
    if [ "$device_type" = "radxa_zero3" ] || [ "$device_type" = "radxa_other" ]; then
        # Pakiety dla Radxa
        poetry add gpiod pyaudio respeaker
    else
        # Pakiety dla Raspberry Pi
        poetry add RPi.GPIO PyAudio
    fi

    # Utwórz strukturę projektu
    mkdir -p "$DEMO_PROJECT_DIR/radxa_demo"

    # Utwórz plik __init__.py
    cat > "$DEMO_PROJECT_DIR/radxa_demo/__init__.py" << EOL
# radxa_demo package
__version__ = '0.1.0'
EOL

    # Utwórz przykładowy plik dla Radxa
    if [ "$device_type" = "radxa_zero3" ] || [ "$device_type" = "radxa_other" ]; then
        # Przykładowy plik dla Radxa używający gpiod
        cat > "$DEMO_PROJECT_DIR/radxa_demo/led_blink.py" << EOL
#!/usr/bin/env python3
"""
Przykładowy skrypt do mrugania diodą LED na Radxa ZERO 3W/3E
używając biblioteki gpiod zamiast RPi.GPIO.

Ten skrypt jest przykładem, jak używać GPIO na Radxa ZERO 3W/3E.
"""

import time
import gpiod
import sys

# Definicje pinów GPIO
LED_PIN = 17  # Przykładowy pin dla LED

def main():
    print("Radxa ZERO 3W/3E - Przykład mrugania diodą LED")
    print("Użycie biblioteki gpiod")
    print("Naciśnij Ctrl+C, aby zakończyć")

    try:
        # Otwórz chip GPIO
        # Na Radxa możemy mieć różne chipy GPIO (gpiochip0, gpiochip1, itp.)
        # Sprawdzamy dostępne chipy
        chip_names = []
        for i in range(5):  # Sprawdź chipy od 0 do 4
            chip_path = f"/dev/gpiochip{i}"
            try:
                chip = gpiod.Chip(chip_path)
                chip_names.append(chip_path)
                chip.close()
            except:
                pass

        if not chip_names:
            print("Nie znaleziono żadnych chipów GPIO. Upewnij się, że masz uprawnienia.")
            return

        print(f"Znalezione chipy GPIO: {', '.join(chip_names)}")
        chip_path = chip_names[0]  # Użyj pierwszego znalezionego chipa

        print(f"Używanie chipa: {chip_path}")

        # Otwórz chip
        chip = gpiod.Chip(chip_path)

        # Pobierz linię GPIO
        line = chip.get_line(LED_PIN)

        # Skonfiguruj linię jako wyjście
        line.request(consumer="led_blink", type=gpiod.LINE_REQ_DIR_OUT)

        # Mrugaj diodą
        for _ in range(20):
            line.set_value(1)  # Włącz LED
            print("LED włączona")
            time.sleep(0.5)

            line.set_value(0)  # Wyłącz LED
            print("LED wyłączona")
            time.sleep(0.5)

        # Zamknij zasoby
        line.release()
        chip.close()

        print("Zakończono")

    except KeyboardInterrupt:
        print("Przerwano przez użytkownika")
    except Exception as e:
        print(f"Wystąpił błąd: {e}")

if __name__ == "__main__":
    main()
EOL
    else
        # Przykładowy plik dla Raspberry Pi używający RPi.GPIO
        cat > "$DEMO_PROJECT_DIR/radxa_demo/led_blink.py" << EOL
#!/usr/bin/env python3
"""
Przykładowy skrypt do mrugania diodą LED na Raspberry Pi
używając biblioteki RPi.GPIO.

Ten skrypt jest przykładem, jak używać GPIO na Raspberry Pi.
"""

import time
import RPi.GPIO as GPIO

# Definicje pinów GPIO
LED_PIN = 17  # Przykładowy pin dla LED

def main():
    print("Raspberry Pi - Przykład mrugania diodą LED")
    print("Naciśnij Ctrl+C, aby zakończyć")

    try:
        # Konfiguracja GPIO
        GPIO.setmode(GPIO.BCM)
        GPIO.setup(LED_PIN, GPIO.OUT)

        # Mrugaj diodą
        for _ in range(20):
            GPIO.output(LED_PIN, GPIO.HIGH)  # Włącz LED
            print("LED włączona")
            time.sleep(0.5)

            GPIO.output(LED_PIN, GPIO.LOW)  # Wyłącz LED
            print("LED wyłączona")
            time.sleep(0.5)

        # Czyszczenie
        GPIO.cleanup()

        print("Zakończono")

    except KeyboardInterrupt:
        print("Przerwano przez użytkownika")
        GPIO.cleanup()
    except Exception as e:
        print(f"Wystąpił błąd: {e}")
        GPIO.cleanup()

if __name__ == "__main__":
    main()
EOL
    fi

    # Utwórz plik README.md
    cat > "$DEMO_PROJECT_DIR/README.md" << EOL
# Przykładowy projekt Poetry dla Radxa

Ten projekt pokazuje, jak używać Poetry z Radxa ZERO 3W/3E.

## Instalacja

```bash
# Zainstaluj zależności
poetry install
```

## Uruchomienie

```bash
# Aktywuj środowisko wirtualne
poetry shell

# Uruchom przykładowy skrypt
python -m radxa_demo.led_blink
```

## Struktura projektu

- \`radxa_demo/\`: Pakiet Python
  - \`__init__.py\`: Plik inicjalizacyjny pakietu
  - \`led_blink.py\`: Przykładowy skrypt mrugający diodą LED

## Różnice między Radxa a Raspberry Pi

Na Radxa używamy biblioteki \`gpiod\` zamiast \`RPi.GPIO\` do kontroli GPIO.

## Uwagi

- Upewnij się, że masz odpowiednie uprawnienia do dostępu do GPIO
- Można potrzebować uruchomić skrypt z uprawnieniami administratora (\`sudo\`)
EOL

    log "SUCCESS" "Przykładowy projekt Poetry został utworzony w: $DEMO_PROJECT_DIR"
    return 0
}

# Wyświetl informacje po instalacji
show_post_install_info() {
    local device_type="$1"

    echo -e "\n${CYAN}${BOLD}===================== INFORMACJE PO INSTALACJI =====================${NC}"
    echo -e "${GREEN}Instalacja Poetry dla Radxa ZERO 3W/3E została zakończona pomyślnie!${NC}"
    echo -e "\nAby aktywować środowisko Poetry w bieżącej sesji, wykonaj:"
    echo -e "${YELLOW}source $HOME/.bashrc${NC}"

    echo -e "\nUtworzono przykładowy projekt w: ${BOLD}$DEMO_PROJECT_DIR${NC}"
    echo -e "Aby go użyć, wykonaj:"
    echo -e "${YELLOW}cd $DEMO_PROJECT_DIR${NC}"
    echo -e "${YELLOW}poetry install${NC}"
    echo -e "${YELLOW}poetry shell${NC}"
    echo -e "${YELLOW}python -m radxa_demo.led_blink${NC}"

    if [ "$device_type" = "radxa_zero3" ] || [ "$device_type" = "radxa_other" ]; then
        echo -e "\n${BOLD}Uwagi dotyczące Radxa:${NC}"
        echo -e "1. Na Radxa używamy biblioteki ${YELLOW}gpiod${NC} zamiast RPi.GPIO do kontroli GPIO."
        echo -e "2. Może być konieczne uruchomienie skryptów GPIO z uprawnieniami administratora (sudo)."
        echo -e "3. W przypadku problemów z GPIO, sprawdź dostęp do urządzeń /dev/gpiochip*"
        echo -e "4. Aby używać ReSpeaker, uruchom skrypt konfiguracyjny: ${YELLOW}sudo ./respeaker.sh${NC}"
    fi

    echo -e "\n${BOLD}Przydatne komendy Poetry:${NC}"
    echo -e "- ${YELLOW}poetry new nazwa-projektu${NC} - Utwórz nowy projekt"
    echo -e "- ${YELLOW}poetry add pakiet${NC} - Dodaj pakiet do projektu"
    echo -e "- ${YELLOW}poetry shell${NC} - Aktywuj środowisko wirtualne"
    echo -e "- ${YELLOW}poetry run python skrypt.py${NC} - Uruchom skrypt w środowisku Poetry"
    echo -e "- ${YELLOW}poetry build${NC} - Zbuduj pakiet"

    echo -e "\n${CYAN}${BOLD}===================================================================${NC}\n"
}

# Funkcja wyświetlająca pomoc
show_help() {
    echo -e "${CYAN}${BOLD}Skrypt instalacyjny Poetry dla Radxa ZERO 3W/3E${NC}"
    echo -e "Użycie: $0 [OPCJE]"
    echo -e ""
    echo -e "Opcje:"
    echo -e "  -v, --version VERSION   Zainstaluj konkretną wersję Poetry (domyślnie: $POETRY_VERSION)"
    echo -e "  -n, --no-swap           Nie konfiguruj pamięci swap"
    echo -e "  -d, --demo-dir DIR      Katalog dla przykładowego projektu (domyślnie: $DEMO_PROJECT_DIR)"
    echo -e "  -h, --help              Wyświetl tę pomoc"
    echo -e ""
    echo -e "Przykłady:"
    echo -e "  $0                      # Standardowa instalacja"
    echo -e "  $0 -v 1.5.1             # Instalacja Poetry w wersji 1.5.1"
    echo -e "  $0 -n                   # Instalacja bez konfiguracji swap"
    echo -e "  $0 -d ~/moj-projekt     # Tworzenie przykładowego projektu w ~/moj-projekt"
    echo -e ""
}

# Główna funkcja
main() {
    echo -e "${CYAN}${BOLD}===============================================${NC}"
    echo -e "${CYAN}${BOLD}    INSTALACJA POETRY DLA RADXA ZERO 3W/3E    ${NC}"
    echo -e "${CYAN}${BOLD}===============================================${NC}\n"

    # Domyślne opcje
    local configure_swap_option=true

    # Parsowanie argumentów
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -v|--version)
                POETRY_VERSION="$2"
                shift 2
                ;;
            -n|--no-swap)
                configure_swap_option=false
                shift
                ;;
            -d|--demo-dir)
                DEMO_PROJECT_DIR="$2"
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

    # Wykryj model urządzenia
    local device_type=$(detect_radxa_model) || device_type="other"

    # Sprawdź wymagania
    check_requirements || exit 1

    # Konfiguracja swap
    if $configure_swap_option; then
        configure_swap || log "WARN" "Konfiguracja pamięci swap nie powiodła się, kontynuuję..."
    fi

    # Zainstaluj pakiety dla Radxa
    if [ "$device_type" = "radxa_zero3" ] || [ "$device_type" = "radxa_other" ]; then
        install_radxa_packages || log "WARN" "Instalacja pakietów dla Radxa nie powiodła się, kontynuuję..."
    fi

    # Zainstaluj Poetry
    install_poetry || exit 1

    # Utwórz przykładowy projekt
    create_demo_project "$device_type" || log "WARN" "Tworzenie przykładowego projektu nie powiodło się."

    # Wyświetl informacje po instalacji
    show_post_install_info "$device_type"

    log "SUCCESS" "Instalacja Poetry zakończona pomyślnie!"

    return 0
}

# Uruchom główną funkcję
main "$@"