#!/bin/bash
# Instalator szybki dla Poetry na Raspberry Pi (dla niecierpliwych)
# Skrypt do szybkiego testowania
# Autor: Tom Sapletta
# Data: 15 maja 2025

set -e  # Zatrzymaj skrypt przy błędzie

echo "=== Szybka instalacja Poetry dla Raspberry Pi ==="

# Wyświetl model RPi
PI_MODEL=$(cat /proc/device-tree/model | tr -d '\0' || echo "Nieznany model")
echo "Model: $PI_MODEL"

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
mkdir -p ~/rpi-test
cd ~/rpi-test

cat > pyproject.toml << 'EOF'
[tool.poetry]
name = "rpi-test"
version = "0.1.0"
description = "Szybki test Poetry na Raspberry Pi"
authors = ["Test <test@example.com>"]

[tool.poetry.dependencies]
python = "^3.7"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
EOF

cat > test.py << 'EOF'
print("Poetry działa na Raspberry Pi!")
EOF

# Instalacja i uruchomienie
echo "Testowanie projektu..."
poetry install
poetry run python test.py

echo "=== Instalacja zakończona! ==="
