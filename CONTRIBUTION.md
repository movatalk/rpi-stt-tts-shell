# Contributing to rpi-stt-tts-shell

This document provides guidelines and instructions for developers who want to contribute to this project.


## O Poetry

Poetry rozwiązuje wiele problemów związanych z zarządzaniem zależnościami w Pythonie:

- **Izolacja zależności** - każdy projekt ma własne środowisko wirtualne
- **Spójność wersji pakietów** - blokowanie konkretnych wersji w pliku `poetry.lock`
- **Łatwe publikowanie pakietów** - uproszczony proces przygotowania i publikowania
- **Niezawodność** - deterministyczne rozwiązywanie zależności

## Różnice między Raspberry Pi Zero v2 a Raspberry Pi 4

| Parametr | Raspberry Pi Zero v2 | Raspberry Pi 4 |
|----------|----------------------|----------------|
| CPU | ARM Cortex-A53 (1GHz, 1 rdzeń) | ARM Cortex-A72 (1.5GHz, 4 rdzenie) |
| RAM | 512MB | 2GB/4GB/8GB |
| Wydajność | Ograniczona | Wysoka |

**Implikacje dla Poetry:**

- **Pi Zero v2**: Instalacja Poetry i zarządzanie dużymi projektami może być powolne. Wymagane zwiększenie przestrzeni swap.
- **Pi 4**: Pracuje płynnie z większością projektów, pozwala na bardziej złożone zależności i szybszą kompilację pakietów natywnych.




## Instalacja Poetry

Skrypt `setup.sh` automatycznie instaluje Poetry oraz przygotowuje system:
1. Zaktualizuj system
2. Zainstaluj wymagane zależności
3. Dla Pi Zero v2 zwiększa przestrzeń swap (jeśli potrzeba)
4. Instaluje Poetry z oficjalnego źródła
5. Konfiguruje środowisko
6. Tworzy przykładowy projekt

## Podstawowe operacje

### Tworzenie projektu
```bash
poetry init
```

### Instalacja zależności
```bash
poetry add requests  # Dodanie pakietu
poetry add rpi.gpio  # Typowa biblioteka dla Raspberry Pi
poetry add adafruit-blinka  # Dla obsługi czujników i modułów
```

### Uruchamianie skryptów
```bash
poetry run python main.py
```

### Aktywacja środowiska wirtualnego
```bash
poetry shell
```

### Eksport zależności
```bash
poetry export -f requirements.txt --output requirements.txt
```

## Tworzenie projektu

```bash
poetry install --only main,sensors
```

### Wersjonowanie

Poetry stosuje składnię [semver](https://semver.org/):

- `^1.2.3` - zgodność z 1.x.x (≥1.2.3, <2.0.0)
- `~1.2.3` - zgodność z 1.2.x (≥1.2.3, <1.3.0)
- `1.2.3` - dokładnie ta wersja

## Publikowanie projektów

Poetry upraszcza publikowanie pakietów na PyPI:

```bash
poetry build  # Budowanie pakietu
poetry publish  # Publikacja na PyPI
```

Dla pakietów prywatnych można skonfigurować własne repozytoria:

```bash
poetry config repositories.moje-repo https://moj-serwer/simple/
poetry publish -r moje-repo
```


## Development Setup

### Prerequisites

- Python 3.7 or higher
- Poetry for dependency management
- Raspberry Pi hardware (for full testing)

### Setting up the Development Environment

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/rpi-stt-tts-shell.git
   cd rpi-stt-tts-shell
   ```

2. Install dependencies with Poetry:
   ```bash
   poetry install
   ```

3. Install development dependencies:
   ```bash
   poetry install --with dev
   ```

4. (Optional) Install camera support:
   ```bash
   poetry install --extras camera
   ```

## Development Workflow

### Code Style

This project uses:
- Black for code formatting (line length: 88)
- isort for import sorting
- mypy for type checking

Run the formatters:
```bash
poetry run black .
poetry run isort .
```