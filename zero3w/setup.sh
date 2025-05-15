#!/bin/bash
# Skrypt instalacyjny Poetry dla Raspberry Pi Zero v2 i Raspberry Pi 4
# Author: Tom Sapletta
# Data: 15 maja 2025

set -e  # Zatrzymaj skrypt przy błędzie

# Sprawdź model Raspberry Pi
PI_MODEL=$(cat /proc/device-tree/model | tr -d '\0' || echo "Nieznany model")
echo "Wykryty model: $PI_MODEL"

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

# Dla Pi Zero v2 może być potrzebny dodatkowy swap
if [[ $PI_MODEL == *"Zero"* ]] && [[ $MEMORY -lt 1024 ]]; then
    info "Wykryto Raspberry Pi Zero. Zwiększenie przestrzeni swap"
    
    # Sprawdź czy już mamy wystarczający swap
    if [[ $SWAP -lt 1024 ]]; then
        sudo dphys-swapfile swapoff
        sudo sed -i 's/CONF_SWAPSIZE=.*/CONF_SWAPSIZE=1024/' /etc/dphys-swapfile
        sudo dphys-swapfile setup
        sudo dphys-swapfile swapon
        info "Przestrzeń swap zwiększona do 1024 MB"
    else
        info "Obecna przestrzeń swap jest wystarczająca"
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
info "Tworzenie przykładowego projektu"
mkdir -p ~/projekty/przyklad-poetry
cd ~/projekty/przyklad-poetry

poetry init --no-interaction --name "przyklad-poetry" --description "Przykładowy projekt Poetry dla Raspberry Pi" --author "User <user@example.com>" --python ">=3.7"

# Dodawanie zależności odpowiednich dla Raspberry Pi
info "Dodawanie przykładowych zależności"
poetry add rpi.gpio adafruit-blinka

# Tworzenie przykładowego skryptu
cat > main.py << 'EOF'
#!/usr/bin/env python3
"""
Przykładowy skrypt dla Raspberry Pi wykorzystujący Poetry
"""
import sys
import time
from pathlib import Path

print(f"Python {sys.version}")
print(f"Uruchomiono z: {Path(__file__).absolute()}")
print("Środowisko zarządzane przez Poetry")

try:
    # Import bibliotek Raspberry Pi
    import board
    import digitalio
    print("\nBiblioteki Adafruit Blinka załadowane pomyślnie!")
    print(f"Wykryty model płytki: {board.board_id}")
    
    # Informacje o dostępnych pinach GPIO
    print("\nDostępne piny GPIO:")
    for pin in dir(board):
        if pin.startswith('D') or pin.startswith('GP'):
            print(f"  - {pin}")
            
    import RPi.GPIO as GPIO
    GPIO.setmode(GPIO.BCM)
    print("\nBiblioteka RPi.GPIO załadowana pomyślnie!")
    print(f"RPi.GPIO wersja: {GPIO.VERSION}")
    
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
echo "cd ~/projekty/przyklad-poetry"
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
