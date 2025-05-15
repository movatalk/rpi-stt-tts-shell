#!/bin/bash
# Szybki instalator Poetry dla Radxa Zero 3W/3E
# Author: Tom Sapletta
# Data: 15 maja 2025

set -e  # Zatrzymaj skrypt przy błędzie

echo "=== Szybka instalacja Poetry dla Radxa Zero 3W/3E ==="

# Wyświetl model urządzenia
DEVICE_MODEL=$(cat /proc/device-tree/model | tr -d '\0' || echo "Nieznany model")
echo "Model: $DEVICE_MODEL"

# Sprawdź czy to rzeczywiście Radxa Zero 3W/3E
if [[ $DEVICE_MODEL != *"Radxa ZERO 3"* ]]; then
    echo "OSTRZEŻENIE: Nie wykryto Radxa Zero 3W/3E. Ten skrypt jest zoptymalizowany dla tych modeli."
    echo "Kontynuować? (t/n)"
    read -r response
    if [[ "$response" != "t" ]]; then
        echo "Instalacja przerwana."
        exit 1
    fi
fi

# Zainstaluj zależności
echo "Instalacja podstawowych pakietów..."
sudo apt-get update && sudo apt-get install -y python3 python3-pip python3-venv curl

# Zainstaluj Poetry
echo "Instalacja Poetry..."
curl -sSL https://install.python-poetry.org | python3 -

# Dodaj do PATH
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# Konfiguracja
echo "Konfiguracja Poetry..."
poetry config virtualenvs.in-project true

# Test instalacji
POETRY_VERSION=$(poetry --version)
echo "Poetry zainstalowane: $POETRY_VERSION"

# Szybki projekt testowy
echo "Tworzenie projektu testowego..."
mkdir -p ~/radxa-test
cd ~/radxa-test

cat > pyproject.toml << 'EOF'
[tool.poetry]
name = "radxa-test"
version = "0.1.0"
description = "Szybki test Poetry na Radxa Zero 3W/3E"
authors = ["Test <test@example.com>"]

[tool.poetry.dependencies]
python = "^3.7"
gpiod = "^1.5.0"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
EOF

cat > test.py << 'EOF'
#!/usr/bin/env python3
"""
Test działania Poetry na Radxa Zero 3W/3E
"""
import platform
import os

print(f"System: {platform.system()} {platform.release()}")
print(f"Python: {platform.python_version()}")
print(f"Urządzenie: {platform.machine()}")

try:
    import gpiod
    print("Moduł gpiod załadowany pomyślnie!")

    # Wyświetl dostępne chipy GPIO
    print("\nDostępne chipy GPIO:")
    for chip_name in os.listdir("/dev/"):
        if chip_name.startswith("gpiochip"):
            print(f"  - /dev/{chip_name}")
except ImportError as e:
    print(f"Błąd importu modułu gpiod: {e}")

print("\nPoetry działa na Radxa Zero 3W/3E!")
EOF

# Instalacja i uruchomienie
echo "Testowanie projektu..."
poetry install
poetry run python test.py

# Informacja o ReSpeaker
echo ""
echo "=== Dodatkowe informacje ==="
echo "Aby skonfigurować ReSpeaker 2-Mic Pi HAT dla Radxa Zero 3W/3E,"
echo "uruchom skrypt setup_radxa_respeaker.sh po zakończeniu instalacji Poetry."
echo ""

echo "=== Instalacja zakończona! ==="