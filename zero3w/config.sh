#!/bin/bash
# Konfiguracja interfejsów dla Radxa Zero 3W/3E
# Author: Tom Sapletta
# Data: 15 maja 2025

# Logging function
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    if [ "$level" = "INFO" ]; then
        echo -e "\033[0;34m[INFO]\033[0m $timestamp - $message"
    elif [ "$level" = "WARN" ]; then
        echo -e "\033[1;33m[WARN]\033[0m $timestamp - $message" >&2
    elif [ "$level" = "ERROR" ]; then
        echo -e "\033[0;31m[ERROR]\033[0m $timestamp - $message" >&2
    elif [ "$level" = "SUCCESS" ]; then
        echo -e "\033[0;32m[SUCCESS]\033[0m $timestamp - $message"
    else
        echo "$message"
    fi
}

# Check if running on Radxa
check_radxa() {
    if [ ! -f /proc/device-tree/model ]; then
        log "ERROR" "Nie można odczytać modelu urządzenia"
        return 1
    fi

    local model=$(cat /proc/device-tree/model | tr -d '\0')

    if [[ "$model" == *"Radxa ZERO 3"* ]]; then
        log "INFO" "Wykryto model: $model"
        return 0
    else
        log "WARN" "Wykryty model: $model"
        log "WARN" "Ten skrypt jest zoptymalizowany dla Radxa Zero 3W/3E"
        echo "Kontynuować? (t/n)"
        read -r response
        if [[ "$response" != "t" ]]; then
            log "INFO" "Instalacja przerwana."
            exit 1
        fi
        return 0
    fi
}

# Enable SSH
enable_ssh() {
    if systemctl is-active ssh > /dev/null 2>&1; then
        log "INFO" "SSH jest już włączone i działa"
        return 0
    fi

    log "INFO" "Włączanie SSH..."

    # Typowa metoda dla systemów Debian-based
    sudo systemctl enable ssh
    sudo systemctl start ssh

    # Weryfikacja
    if systemctl is-active ssh > /dev/null 2>&1; then
        log "SUCCESS" "SSH włączone pomyślnie"
    else
        log "ERROR" "Nie udało się włączyć SSH"
        return 1
    fi
}

# Enable SPI
enable_spi() {
    log "INFO" "Konfiguracja SPI..."

    # Konfiguracja przez overlays (metoda dla Radxa)
    local config_file="/boot/uEnv.txt"

    if [ ! -f "$config_file" ]; then
        log "WARN" "Plik $config_file nie istnieje. Spróbuję użyć /boot/config.txt"
        config_file="/boot/config.txt"
    fi

    if [ -f "$config_file" ]; then
        # Sprawdź czy SPI jest już włączone
        if grep -q "overlays=.*spi" "$config_file"; then
            log "INFO" "SPI jest już włączone"
        else
            # Dwie możliwe metody, zależne od struktury pliku konfiguracyjnego
            if grep -q "^overlays=" "$config_file"; then
                # Dodaj SPI do istniejącej linii overlays
                sudo sed -i 's/^overlays=\(.*\)/overlays=\1 spi/' "$config_file"
            else
                # Dodaj nową linię dla overlays
                echo "overlays=spi" | sudo tee -a "$config_file" > /dev/null
            fi
            log "SUCCESS" "SPI włączone. Wymagany restart, aby zastosować zmiany."
        fi
    else
        log "ERROR" "Nie znaleziono odpowiedniego pliku konfiguracyjnego dla SPI"
        return 1
    fi
}

# Enable I2C
enable_i2c() {
    log "INFO" "Konfiguracja I2C..."

    # Konfiguracja przez overlays (metoda dla Radxa)
    local config_file="/boot/uEnv.txt"

    if [ ! -f "$config_file" ]; then
        log "WARN" "Plik $config_file nie istnieje. Spróbuję użyć /boot/config.txt"
        config_file="/boot/config.txt"
    fi

    if [ -f "$config_file" ]; then
        # Sprawdź czy I2C jest już włączone
        if grep -q "overlays=.*i2c" "$config_file"; then
            log "INFO" "I2C jest już włączone"
        else
            # Dwie możliwe metody, zależne od struktury pliku konfiguracyjnego
            if grep -q "^overlays=" "$config_file"; then
                # Dodaj I2C do istniejącej linii overlays
                sudo sed -i 's/^overlays=\(.*\)/overlays=\1 i2c/' "$config_file"
            else
                # Dodaj nową linię dla overlays
                echo "overlays=i2c" | sudo tee -a "$config_file" > /dev/null
            fi
            log "SUCCESS" "I2C włączone. Wymagany restart, aby zastosować zmiany."
        fi

        # Zainstaluj narzędzia I2C
        log "INFO" "Instalacja narzędzi I2C..."
        sudo apt-get update
        sudo apt-get install -y i2c-tools
        log "SUCCESS" "Narzędzia I2C zainstalowane"
    else
        log "ERROR" "Nie znaleziono odpowiedniego pliku konfiguracyjnego dla I2C"
        return 1
    fi
}

# Enable UART/Serial
enable_serial() {
    log "INFO" "Konfiguracja UART/Serial..."

    # Konfiguracja przez overlays (metoda dla Radxa)
    local config_file="/boot/uEnv.txt"

    if [ ! -f "$config_file" ]; then
        log "WARN" "Plik $config_file nie istnieje. Spróbuję użyć /boot/config.txt"
        config_file="/boot/config.txt"
    fi

    if [ -f "$config_file" ]; then
        # Sprawdź czy UART jest już włączone
        if grep -q "overlays=.*uart" "$config_file"; then
            log "INFO" "UART jest już włączone"
        else
            # Dwie możliwe metody, zależne od struktury pliku konfiguracyjnego
            if grep -q "^overlays=" "$config_file"; then
                # Dodaj UART do istniejącej linii overlays
                sudo sed -i 's/^overlays=\(.*\)/overlays=\1 uart/' "$config_file"
            else
                # Dodaj nową linię dla overlays
                echo "overlays=uart" | sudo tee -a "$config_file" > /dev/null
            fi
            log "SUCCESS" "UART włączone. Wymagany restart, aby zastosować zmiany."
        fi
    else
        log "ERROR" "Nie znaleziono odpowiedniego pliku konfiguracyjnego dla UART"
        return 1
    fi
}

# Enable audio (I2S)
enable_i2s_audio() {
    log "INFO" "Konfiguracja I2S dla audio..."

    # Konfiguracja przez overlays (metoda dla Radxa)
    local config_file="/boot/uEnv.txt"

    if [ ! -f "$config_file" ]; then
        log "WARN" "Plik $config_file nie istnieje. Spróbuję użyć /boot/config.txt"
        config_file="/boot/config.txt"
    fi

    if [ -f "$config_file" ]; then
        # Sprawdź czy I2S jest już włączone
        if grep -q "overlays=.*i2s" "$config_file"; then
            log "INFO" "I2S jest już włączone"
        else
            # Dwie możliwe metody, zależne od struktury pliku konfiguracyjnego
            if grep -q "^overlays=" "$config_file"; then
                # Dodaj I2S do istniejącej linii overlays
                sudo sed -i 's/^overlays=\(.*\)/overlays=\1 i2s/' "$config_file"
            else
                # Dodaj nową linię dla overlays
                echo "overlays=i2s" | sudo tee -a "$config_file" > /dev/null
            fi
            log "SUCCESS" "I2S włączone. Wymagany restart, aby zastosować zmiany."
        fi

        # Zainstaluj narzędzia audio
        log "INFO" "Instalacja narzędzi audio..."
        sudo apt-get update
        sudo apt-get install -y alsa-utils
        log "SUCCESS" "Narzędzia audio zainstalowane"
    else
        log "ERROR" "Nie znaleziono odpowiedniego pliku konfiguracyjnego dla I2S"
        return 1
    fi
}

# Pełna konfiguracja
configure_radxa() {
    # Upewnij się, że nie jest uruchomiony jako root
    if [ "$EUID" -eq 0 ]; then
        log "ERROR" "Nie uruchamiaj tego skryptu jako root. Użyj sudo, gdy będzie potrzebne."
        return 1
    fi

    # Sprawdź czy uruchomiony na Radxa
    check_radxa || return 1

    # Wykonaj konfiguracje
    enable_ssh
    enable_spi
    enable_i2c
    enable_serial
    enable_i2s_audio

    # Sugestia restartu
    log "WARN" "Zalecany restart, aby zastosować wszystkie zmiany"
    echo "Sugerowana komenda restartu: sudo reboot"
}

# Wyświetl pomoc
display_help() {
    echo "Radxa Zero 3W/3E - Narzędzie konfiguracyjne"
    echo "Użycie:"
    echo "  $0 [opcja]"
    echo ""
    echo "Opcje:"
    echo "  ssh     - Włącz SSH"
    echo "  spi     - Włącz SPI"
    echo "  i2c     - Włącz I2C"
    echo "  serial  - Włącz UART/Serial"
    echo "  i2s     - Włącz I2S audio"
    echo "  all     - Skonfiguruj wszystkie interfejsy (domyślnie)"
    echo "  help    - Wyświetl tę pomoc"
}

# Główna funkcja
main() {
    # Określ akcję
    local action="${1:-all}"

    case "$action" in
        "ssh")
            check_radxa && enable_ssh
            ;;
        "spi")
            check_radxa && enable_spi
            ;;
        "i2c")
            check_radxa && enable_i2c
            ;;
        "serial")
            check_radxa && enable_serial
            ;;
        "i2s")
            check_radxa && enable_i2s_audio
            ;;
        "all")
            configure_radxa
            ;;
        "help")
            display_help
            ;;
        *)
            log "ERROR" "Nieprawidłowa opcja"
            display_help
            return 1
            ;;
    esac
}

# Uruchom główną funkcję z wszystkimi argumentami
main "$@"