#!/bin/bash
# menu.sh - Interaktywne menu do zarządzania urządzeniami Raspberry Pi i Radxa
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
PROJECT_DIR="$(pwd)"
CONFIG_DIR="${HOME}/hosts"
SCAN_SCRIPT="${PROJECT_DIR}/fleet/scan.sh"
DEPLOY_SCRIPT="${PROJECT_DIR}/fleet/deploy.sh"
SETUP_RPI_SCRIPT="${PROJECT_DIR}/rpi/setup.sh"
SETUP_RADXA_SCRIPT="${PROJECT_DIR}/zero3w/poetry.sh"
SETUP_RESPEAKER_RPI="${PROJECT_DIR}/rpi/respeaker.sh"
SETUP_RESPEAKER_RADXA="${PROJECT_DIR}/zero3w/respeaker.sh"
CONFIG_RPI="${PROJECT_DIR}/rpi/config.sh"
CONFIG_RADXA="${PROJECT_DIR}/zero3w/config.sh"
CSV_FILE="devices.csv"

# Funkcja czyszcząca ekran
clear_screen() {
    clear
}

# Funkcja wyświetlająca baner
show_banner() {
    echo -e "${GREEN}${BOLD}=================================================="
    echo -e "   ZARZĄDZANIE URZĄDZENIAMI RASPBERRY PI I RADXA"
    echo -e "==================================================${NC}"
    echo ""
    echo -e "${BLUE}Narzędzie do wykrywania, konfiguracji i zarządzania"
    echo -e "urządzeniami Raspberry Pi i Radxa w sieci lokalnej${NC}"
    echo ""
}

# Funkcja sprawdzająca czy skrypt istnieje
check_script() {
    local script_path="$1"
    local script_name="$2"

    if [ ! -f "$script_path" ]; then
        echo -e "${YELLOW}Ostrzeżenie: Skrypt $script_name ($script_path) nie istnieje.${NC}"
        return 1
    fi

    return 0
}

# Funkcja uruchamiająca skaner
run_scanner() {
    clear_screen
    show_banner

    echo -e "${CYAN}${BOLD}SKANOWANIE SIECI${NC}"
    echo "Wykrywanie urządzeń Raspberry Pi i Radxa w sieci lokalnej"
    echo ""

    check_script "$SCAN_SCRIPT" "skanera" || return 1

    echo -e "${YELLOW}Czy chcesz określić własny zakres sieci? [t/N]${NC}"
    read -r custom_range

    if [[ "$custom_range" == "t" || "$custom_range" == "T" ]]; then
        echo -e "${YELLOW}Podaj zakres sieci (np. 192.168.1.0/24):${NC}"
        read -r range
        chmod +x "$SCAN_SCRIPT"
        "$SCAN_SCRIPT" -r "$range"
    else
        chmod +x "$SCAN_SCRIPT"
        "$SCAN_SCRIPT"
    fi

    echo ""
    read -p "Naciśnij Enter, aby wrócić do menu głównego..."
}

# Funkcja uruchamiająca wdrażanie
run_deployment() {
    clear_screen
    show_banner

    echo -e "${CYAN}${BOLD}WDRAŻANIE PROJEKTU${NC}"
    echo "Wdrażanie projektu na wykryte urządzenia"
    echo ""

    if [ ! -f "$CSV_FILE" ]; then
        echo -e "${RED}Błąd: Nie znaleziono pliku $CSV_FILE. Najpierw uruchom skaner.${NC}"
        echo ""
        read -p "Naciśnij Enter, aby wrócić do menu głównego..."
        return 1
    fi

    check_script "$DEPLOY_SCRIPT" "wdrażania" || return 1

    echo -e "${YELLOW}Wybierz tryb wdrażania:${NC}"
    echo "1) Wdróż na wszystkie wykryte urządzenia"
    echo "2) Wdróż na określone urządzenie (podaj IP)"
    echo "3) Wdróż z niestandardowymi parametrami"
    echo "4) Powrót do menu głównego"
    echo ""
    echo -ne "${YELLOW}Wybierz opcję (1-4): ${NC}"
    read -r deploy_option

    case $deploy_option in
        1)
            chmod +x "$DEPLOY_SCRIPT"
            "$DEPLOY_SCRIPT"
            ;;
        2)
            echo -e "${YELLOW}Podaj adres IP urządzenia do wdrożenia:${NC}"
            read -r target_ip
            chmod +x "$DEPLOY_SCRIPT"
            "$DEPLOY_SCRIPT" -i "$target_ip"
            ;;
        3)
            echo -e "${YELLOW}Podaj nazwę użytkownika SSH [pi]:${NC}"
            read -r user
            user=${user:-pi}

            echo -e "${YELLOW}Podaj hasło SSH [raspberry]:${NC}"
            read -r -s password
            password=${password:-raspberry}

            echo -e "${YELLOW}Podaj katalog zdalny [/home/$user/rpi-stt-tts-shell]:${NC}"
            read -r remote_dir
            remote_dir=${remote_dir:-/home/$user/rpi-stt-tts-shell}

            chmod +x "$DEPLOY_SCRIPT"
            "$DEPLOY_SCRIPT" -u "$user" -p "$password" -r "$remote_dir"
            ;;
        4)
            return 0
            ;;
        *)
            echo -e "${RED}Nieprawidłowa opcja.${NC}"
            ;;
    esac

    echo ""
    read -p "Naciśnij Enter, aby wrócić do menu głównego..."
}

# Funkcja konfigurująca urządzenia
configure_devices() {
    clear_screen
    show_banner

    echo -e "${CYAN}${BOLD}KONFIGURACJA URZĄDZEŃ${NC}"
    echo "Konfiguracja interfejsów i komponentów"
    echo ""

    echo -e "${YELLOW}Wybierz typ urządzenia do konfiguracji:${NC}"
    echo "1) Raspberry Pi"
    echo "2) Radxa"
    echo "3) Powrót do menu głównego"
    echo ""
    echo -ne "${YELLOW}Wybierz opcję (1-3): ${NC}"
    read -r device_type

    case $device_type in
        1)
            configure_raspberry_pi
            ;;
        2)
            configure_radxa
            ;;
        3)
            return 0
            ;;
        *)
            echo -e "${RED}Nieprawidłowa opcja.${NC}"
            ;;
    esac

    echo ""
    read -p "Naciśnij Enter, aby wrócić do menu głównego..."
}

# Funkcja konfigurująca Raspberry Pi
configure_raspberry_pi() {
    clear_screen
    show_banner

    echo -e "${CYAN}${BOLD}KONFIGURACJA RASPBERRY PI${NC}"
    echo "Wybierz opcję konfiguracji:"
    echo ""

    echo "1) Konfiguracja interfejsów (SSH, SPI, I2C, itd.)"
    echo "2) Konfiguracja ReSpeaker"
    echo "3) Instalacja Poetry"
    echo "4) Powrót do poprzedniego menu"
    echo ""
    echo -ne "${YELLOW}Wybierz opcję (1-4): ${NC}"
    read -r rpi_option

    case $rpi_option in
        1)
            if check_script "$CONFIG_RPI" "konfiguracji Raspberry Pi"; then
                chmod +x "$CONFIG_RPI"
                "$CONFIG_RPI"
            fi
            ;;
        2)
            if check_script "$SETUP_RESPEAKER_RPI" "konfiguracji ReSpeaker"; then
                echo -e "${YELLOW}Uwaga: Ten skrypt wymaga uprawnień administratora (sudo).${NC}"
                echo -ne "${YELLOW}Czy chcesz kontynuować? [t/N]: ${NC}"
                read -r confirm

                if [[ "$confirm" == "t" || "$confirm" == "T" ]]; then
                    chmod +x "$SETUP_RESPEAKER_RPI"
                    sudo "$SETUP_RESPEAKER_RPI"
                fi
            fi
            ;;
        3)
            if check_script "$SETUP_RPI_SCRIPT" "instalacji Poetry"; then
                chmod +x "$SETUP_RPI_SCRIPT"
                "$SETUP_RPI_SCRIPT"
            fi
            ;;
        4)
            return 0
            ;;
        *)
            echo -e "${RED}Nieprawidłowa opcja.${NC}"
            ;;
    esac
}

# Funkcja konfigurująca Radxa
configure_radxa() {
    clear_screen
    show_banner

    echo -e "${CYAN}${BOLD}KONFIGURACJA RADXA${NC}"
    echo "Wybierz opcję konfiguracji:"
    echo ""

    echo "1) Konfiguracja interfejsów (SSH, SPI, I2C, itd.)"
    echo "2) Konfiguracja ReSpeaker"
    echo "3) Instalacja Poetry"
    echo "4) Powrót do poprzedniego menu"
    echo ""
    echo -ne "${YELLOW}Wybierz opcję (1-4): ${NC}"
    read -r radxa_option

    case $radxa_option in
        1)
            if check_script "$CONFIG_RADXA" "konfiguracji Radxa"; then
                chmod +x "$CONFIG_RADXA"
                "$CONFIG_RADXA"
            fi
            ;;
        2)
            if check_script "$SETUP_RESPEAKER_RADXA" "konfiguracji ReSpeaker dla Radxa"; then
                echo -e "${YELLOW}Uwaga: Ten skrypt wymaga uprawnień administratora (sudo).${NC}"
                echo -ne "${YELLOW}Czy chcesz kontynuować? [t/N]: ${NC}"
                read -r confirm

                if [[ "$confirm" == "t" || "$confirm" == "T" ]]; then
                    chmod +x "$SETUP_RESPEAKER_RADXA"
                    sudo "$SETUP_RESPEAKER_RADXA"
                fi
            fi
            ;;
        3)
            if check_script "$SETUP_RADXA_SCRIPT" "instalacji Poetry dla Radxa"; then
                chmod +x "$SETUP_RADXA_SCRIPT"
                "$SETUP_RADXA_SCRIPT"
            fi
            ;;
        4)
            return 0
            ;;
        *)
            echo -e "${RED}Nieprawidłowa opcja.${NC}"
            ;;
    esac
}

# Funkcja wyświetlająca wykryte urządzenia
show_devices() {
    clear_screen
    show_banner

    echo -e "${CYAN}${BOLD}WYKRYTE URZĄDZENIA${NC}"
    echo "Lista wykrytych urządzeń Raspberry Pi i Radxa"
    echo ""

    if [ ! -f "$CSV_FILE" ]; then
        echo -e "${RED}Nie znaleziono pliku $CSV_FILE. Najpierw uruchom skaner.${NC}"
    else
        # Liczba wykrytych urządzeń (pomijając nagłówek)
        local device_count=$(( $(wc -l < "$CSV_FILE") - 1 ))

        if [ $device_count -eq 0 ]; then
            echo -e "${YELLOW}Nie wykryto żadnych urządzeń. Uruchom skaner.${NC}"
        else
            echo -e "${GREEN}Wykryto $device_count urządzeń:${NC}"
            echo ""

            # Wyświetl nagłówek
            head -n 1 "$CSV_FILE" | awk -F',' '{printf "%-4s | %-15s | %-15s | %-25s | %-20s | %-20s\n", "ID", $1, $3, $4, $5, $6}'
            echo "-----------------------------------------------------------------------------------------------------"

            # Wyświetl urządzenia
            awk -F',' 'NR>1 {printf "%-4s | %-15s | %-15s | %-25s | %-20s | %-20s\n", NR-1, $1, $3, $4, $5, $6}' "$CSV_FILE"
        fi
    fi

    echo ""
    read -p "Naciśnij Enter, aby wrócić do menu głównego..."
}

# Funkcja uruchamiająca połączenie SSH
ssh_connect() {
    clear_screen
    show_banner

    echo -e "${CYAN}${BOLD}POŁĄCZENIE SSH${NC}"
    echo "Połącz się z wybranym urządzeniem przez SSH"
    echo ""

    if [ ! -f "$CSV_FILE" ]; then
        echo -e "${RED}Nie znaleziono pliku $CSV_FILE. Najpierw uruchom skaner.${NC}"
        echo ""
        read -p "Naciśnij Enter, aby wrócić do menu głównego..."
        return 1
    fi

    # Liczba wykrytych urządzeń (pomijając nagłówek)
    local device_count=$(( $(wc -l < "$CSV_FILE") - 1 ))

    if [ $device_count -eq 0 ]; then
        echo -e "${YELLOW}Nie wykryto żadnych urządzeń. Uruchom skaner.${NC}"
        echo ""
        read -p "Naciśnij Enter, aby wrócić do menu głównego..."
        return 1
    fi

    # Wybór urządzenia
    echo -e "${GREEN}Wykryte urządzenia:${NC}"
    echo ""

    # Wyświetl nagłówek
    head -n 1 "$CSV_FILE" | awk -F',' '{printf "%-4s | %-15s | %-15s | %-25s | %-20s\n", "ID", $1, $2, $3, $7}'
    echo "---------------------------------------------------------------------------------"

    # Wyświetl urządzenia
    awk -F',' 'NR>1 {printf "%-4s | %-15s | %-15s | %-25s | %-20s\n", NR-1, $1, $2, $3, $7}' "$CSV_FILE"

    echo ""
    echo -e "${YELLOW}Wybierz urządzenie (podaj ID) lub 0, aby wrócić do menu:${NC}"
    read -r device_id

    if [ "$device_id" = "0" ]; then
        return 0
    fi

    if ! [[ "$device_id" =~ ^[0-9]+$ ]] || [ "$device_id" -lt 1 ] || [ "$device_id" -gt $device_count ]; then
        echo -e "${RED}Nieprawidłowe ID urządzenia.${NC}"
        echo ""
        read -p "Naciśnij Enter, aby wrócić do menu głównego..."
        return 1
    fi

    # Pobierz dane urządzenia
    local device_line=$(( device_id + 1 ))
    local device_ip=$(awk -F',' "NR==$device_line {print \$1}" "$CSV_FILE")
    local device_user=$(awk -F',' "NR==$device_line {print \$7}" "$CSV_FILE")

    # Jeśli użytkownik jest "unknown", pytaj o użytkownika
    if [ "$device_user" = "unknown" ]; then
        echo -e "${YELLOW}Podaj nazwę użytkownika SSH [pi]:${NC}"
        read -r ssh_user
        device_user=${ssh_user:-pi}
    fi

    # Połącz się z urządzeniem
    echo -e "${GREEN}Łączenie z $device_ip jako użytkownik $device_user...${NC}"
    ssh "${device_user}@${device_ip}"

    echo ""
    read -p "Naciśnij Enter, aby wrócić do menu głównego..."
}

# Funkcja wyświetlająca informacje o projekcie
show_about() {
    clear_screen
    show_banner

    echo -e "${CYAN}${BOLD}INFORMACJE O PROJEKCIE${NC}"
    echo ""
    echo -e "${GREEN}rpi-stt-tts-shell${NC} - Kompleksowe rozwiązanie dla Raspberry Pi i Radxa"
    echo "oferujące funkcje rozpoznawania mowy (STT) i syntezowania mowy (TTS)."
    echo ""
    echo -e "${BOLD}Autor:${NC} Tom Sapletta"
    echo -e "${BOLD}Wersja:${NC} 0.1.0"
    echo -e "${BOLD}Data:${NC} 15 maja 2025"
    echo ""
    echo -e "${BOLD}Funkcje:${NC}"
    echo "- Wykrywanie urządzeń Raspberry Pi i Radxa w sieci lokalnej"
    echo "- Wdrażanie projektu na wykryte urządzenia"
    echo "- Konfiguracja interfejsów i komponentów"
    echo "- Instalacja Poetry i zarządzanie pakietami"
    echo "- Konfiguracja ReSpeaker 2-Mic Pi HAT"
    echo "- Interaktywny asystent głosowy"
    echo ""
    echo -e "${BOLD}Dokumentacja:${NC} https://github.com/username/rpi-stt-tts-shell"
    echo ""
    read -p "Naciśnij Enter, aby wrócić do menu głównego..."
}

# Główna funkcja menu
main_menu() {
    while true; do
        clear_screen
        show_banner

        echo -e "${CYAN}${BOLD}MENU GŁÓWNE${NC}"
        echo ""
        echo "1) Skanuj sieć w poszukiwaniu urządzeń"
        echo "2) Wdróż projekt na urządzenia"
        echo "3) Konfiguruj urządzenia"
        echo "4) Wyświetl wykryte urządzenia"
        echo "5) Połącz się przez SSH"
        echo "6) Informacje o projekcie"
        echo "7) Wyjście"
        echo ""
        echo -ne "${YELLOW}Wybierz opcję (1-7): ${NC}"
        read -r option

        case $option in
            1)
                run_scanner
                ;;
            2)
                run_deployment
                ;;
            3)
                configure_devices
                ;;
            4)
                show_devices
                ;;
            5)
                ssh_connect
                ;;
            6)
                show_about
                ;;
            7)
                echo -e "${GREEN}Do widzenia!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Nieprawidłowa opcja.${NC}"
                sleep 1
                ;;
        esac
    done
}

# Uruchomienie głównego menu
main_menu