#!/bin/bash
# Skrypt instalacyjny Poetry dla Radxa Zero 3W/3E
# Author: Tom Sapletta
# Data: 15 maja 2025

set -e  # Zatrzymaj skrypt przy błędzie

# Sprawdź model urządzenia
if grep -q "Radxa ZERO 3" /proc/device-tree/model 2>/dev/null; then
    DEVICE_MODEL=$(cat /proc/device-tree/model | tr -d '\0')
else
    # Sprawdź czy to inny model Radxa
    if grep -q "Radxa" /proc/device-tree/model 2>/dev/null; then
        DEVICE_MODEL=$(cat /proc/device-tree/model | tr -d '\0')
    else
        DEVICE_MODEL="Nieznany model (nie wykryto Radxa)"
        echo "UWAGA: Ten skrypt jest zoptymalizowany dla Radxa Zero 3W/3E. Kontynuowanie na własne ryzyko."
    fi
fi

echo "Wykryty model: $DEVICE_MODEL"

# Funkcja informująca o postępie
info() {
    echo -e "\n\033[1;34m==>\033[0m \033[1m$1\033[0m"
}

# Funkcja do obsługi błędów
error() {
    echo -e "\n\033[1;31m==>\033[0m \033[1m$1\033[0m" >&2
    exit 1
}

# Aktualizacja systemu
info "Aktualizacja repozytoriów"
sudo apt-get update || error "Nie można zaktualizować repozytoriów"

info "Instalacja wymaganych pakietów"
sudo apt-get install -y python3 python3-pip python3-venv curl build-essential libssl-dev libffi-dev python3-dev || error "Nie można zainstalować wymaganych pakietów"

# Sprawdź wersję Pythona
PYTHON_VERSION=$(python3 --version)
info "Zainstalowana wersja Python: $PYTHON_VERSION"

# Sprawdź dostępną pamięć
MEMORY=$(free -m | awk '/^Mem:/ {print $2}')
SWAP=$(free -m | awk '/^Swap:/ {print $2}')

info "Dostępna pamięć RAM: $MEMORY MB, Swap: $SWAP MB"

# Konfiguracja swap w razie potrzeby
if [[ $MEMORY -lt 1024 ]]; then
    info "Wykryto niską ilość pamięci RAM. Sprawdzanie przestrzeni swap"

    # Sprawdź czy już mamy wystarczający swap
    if [[ $SWAP -lt 1024 ]]; then
        # Metoda z dphys-swapfile (jeśli istnieje)
        if command -v dphys-swapfile &> /dev/null; then
            sudo dphys-swapfile swapoff
            sudo sed -i 's/CONF_SWAPSIZE=.*/CONF_SWAPSIZE=1024/' /etc/dphys-swapfile
            sudo dphys-swapfile setup
            sudo dphys-swapfile swapon
        else
            # Alternatywna metoda bezpośredniego tworzenia pliku swap
            info "Tworzenie pliku swap (1GB)"
            sudo fallocate -l 1G /swapfile
            sudo chmod 600 /swapfile
            sudo mkswap /swapfile
            sudo swapon /swapfile

            # Dodaj swap do fstab jeśli jeszcze nie jest dodany
            if ! grep -q "/swapfile" /etc/fstab; then
                echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
            fi
        fi

        # Sprawdź czy operacja powiodła się
        NEW_SWAP=$(free -m | awk '/^Swap:/ {print $2}')
        if [[ $NEW_SWAP -gt $SWAP ]]; then
            info "Przestrzeń swap zwiększona do $NEW_SWAP MB"
        else
            info "Nie udało się zwiększyć przestrzeni swap. Kontynuowanie..."
        fi
    else
        info "Obecna przestrzeń swap ($SWAP MB) jest wystarczająca"
    fi
fi

# Instalacja Poetry
info "Instalacja Poetry"
curl -sSL https://install.python-poetry.org | python3 - || error "Nie można zainstalować Poetry"

# Dodaj Poetry do PATH
if ! grep -q "export PATH=\"\$HOME/.local/bin:\$PATH\"" ~/.bashrc; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    info "Dodano Poetry do PATH w .bashrc"
fi

# Aktywacja nowych ustawień PATH
export PATH="$HOME/.local/bin:$PATH"

# Konfiguracja Poetry - utworzenie środowisk wirtualnych w projekcie
info "Konfiguracja Poetry"
poetry config virtualenvs.in-project true

# Sprawdź czy instalacja udana
if command -v poetry &> /dev/null; then
    POETRY_VERSION=$(poetry --version)
    info "Poetry zostało pomyślnie zainstalowane: $POETRY_VERSION"
else
    error "Coś poszło nie tak. Sprawdź czy ~/.local/bin jest w PATH"
fi

# Tworzenie przykładowego projektu
info "Tworzenie przykładowego projektu dla Radxa"
mkdir -p ~/projekty/radxa-poezja
cd ~/projekty/radxa-poezja

poetry init --no-interaction --name "radxa-poezja" --description "Przykładowy projekt Poetry dla Radxa" --author "User <user@example.com>" --python ">=3.7"

# Dodawanie zależności odpowiednich dla Radxa
info "Dodawanie przykładowych zależności"

# Instalacja odpowiednich pakietów w zależności od modelu
if [[ $DEVICE_MODEL == *"ZERO 3"* ]]; then
    poetry add gpiod adafruit-blinka pyaudio numpy
else
    # Domyślne pakiety dla innych modeli Radxa
    poetry add gpiod adafruit-blinka
fi

# Tworzenie przykładowego skryptu
cat > main.py << 'EOF'
#!/usr/bin/env python3
"""
Przykładowy skrypt dla Radxa Zero 3W/3E wykorzystujący Poetry
"""
import sys
import time
from pathlib import Path

print(f"Python {sys.version}")
print(f"Uruchomiono z: {Path(__file__).absolute()}")
print("Środowisko zarządzane przez Poetry")

try:
    # Import bibliotek
    import board
    import digitalio
    print("\nBiblioteki Adafruit Blinka załadowane pomyślnie!")
    print(f"Wykryty model płytki: {board.board_id}")

    # Informacje o dostępnych pinach GPIO
    print("\nDostępne piny GPIO:")
    for pin in dir(board):
        if pin.startswith('D') or pin.startswith('GP'):
            print(f"  - {pin}")

    # Import biblioteki gpiod dla Radxa
    import gpiod
    print("\nBiblioteka gpiod załadowana pomyślnie!")

    # Przykład użycia gpiod
    try:
        chip = gpiod.Chip('gpiochip0')
        print(f"Dostępny chip GPIO: {chip.name}")
        print(f"Liczba linii GPIO: {chip.num_lines}")
    except Exception as e:
        print(f"Nie można otworzyć chipu GPIO: {e}")

except ImportError as e:
    print(f"\nBłąd importu: {e}")
    print("Niektóre biblioteki mogą nie być dostępne na tym urządzeniu.")

print("\nTest zakończony pomyślnie!")
EOF

# Instrukcje
info "Instrukcje użycia"
echo -e "\n\033[1mAby aktywować Poetry w bieżącej sesji, wykonaj:\033[0m"
echo "source ~/.bashrc"

echo -e "\n\033[1mAby uruchomić przykładowy projekt:\033[0m"
echo "cd ~/projekty/radxa-poezja"
echo "poetry install"
echo "poetry run python main.py"

echo -e "\n\033[1mAby utworzyć nowy projekt:\033[0m"
echo "mkdir nazwa-projektu"
echo "cd nazwa-projektu"
echo "poetry init"
echo "poetry add <nazwy-pakietów>"

echo -e "\n\033[1mAby dodać pakiet do istniejącego projektu:\033[0m"
echo "poetry add <nazwa-pakietu>"

echo -e "\n\033[1mAby usunąć pakiet:\033[0m"
echo "poetry remove <nazwa-pakietu>"

echo -e "\n\033[1mAby zaktualizować wszystkie pakiety:\033[0m"
echo "poetry update"

echo -e "\n\033[1mAby utworzyć plik requirements.txt z projektu Poetry:\033[0m"
echo "poetry export -f requirements.txt --output requirements.txt"

info "Instalacja zakończona pomyślnie!"

# Informacja dodatkowa dla Radxa Zero 3W/3E
if [[ $DEVICE_MODEL == *"ZERO 3"* ]]; then
    echo -e "\n\033[1mDodatkowe informacje dla Radxa Zero 3W/3E:\033[0m"
    echo "- Biblioteka gpiod jest używana zamiast RPi.GPIO"
    echo "- Dla obsługi audio zalecane jest używanie nakładki ReSpeaker"
    echo "- W celu skonfigurowania ReSpeaker 2-Mic Pi HAT, użyj:"
    echo "  sudo ./setup_radxa_respeaker.sh"
fi