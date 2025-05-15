# Zarządzanie projektami Python na Raspberry Pi przy użyciu Poetry


## Rozwiązywanie problemów

### Problemy z pamięcią na Pi Zero v2

Jeśli występują problemy z pamięcią podczas instalacji dużych pakietów:

```bash
# Zwiększenie przestrzeni swap
sudo dphys-swapfile swapoff
sudo sed -i 's/CONF_SWAPSIZE=.*/CONF_SWAPSIZE=1024/' /etc/dphys-swapfile
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
```

### Problemy z kompilacją pakietów natywnych

Dla pakietów wymagających kompilacji:

```bash
sudo apt-get install -y build-essential libssl-dev libffi-dev python3-dev
```

### Synchronizacja zależności

W przypadku niespójności zależności:

```bash
poetry lock --no-update  # Regeneracja pliku lock bez aktualizacji
```

## Przykładowe projekty

### Monitoring temperatury i wilgotności

```python
#!/usr/bin/env python3
import time
import board
import adafruit_dht

# Inicjalizacja czujnika DHT22 na pinie D4
dht = adafruit_dht.DHT22(board.D4)

while True:
    try:
        # Odczyt temperatury i wilgotności
        temperatura = dht.temperature
        wilgotnosc = dht.humidity
        
        print(f"Temperatura: {temperatura}°C, Wilgotność: {wilgotnosc}%")
        
    except RuntimeError as e:
        # Błędy odczytu są dość częste, je ignorujemy
        print(f"Błąd odczytu: {e}")
    
    time.sleep(2)  # Odczyt co 2 sekundy
```

Plik `pyproject.toml` dla tego projektu:

```toml
[tool.poetry]
name = "monitor-dht"
version = "0.1.0"
description = "Monitoring czujnika DHT22"
authors = ["Twoje Imię <twoj.email@example.com>"]

[tool.poetry.dependencies]
python = "^3.7"
adafruit-blinka = "^8.19.0"
adafruit-circuitpython-dht = "^3.7.8"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
```

---

*Dokumentacja przygotowana: 15 maja 2025*
