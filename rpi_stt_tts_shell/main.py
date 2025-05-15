#!/usr/bin/env python3
"""
Przykładowy projekt Python z Poetry dla Raspberry Pi
Plik: rpi_stt_tts_shell/main.py

Ten skrypt demonstruje integrację kilku typowych bibliotek IoT
używanych na Raspberry Pi, zarządzanych przez Poetry.
"""
# Author: Tom Sapletta
# Data: 15 maja 2025

import sys
import time
import threading
from pathlib import Path

# Informacje o systemie
print(f"Python {sys.version}")
print(f"Uruchomiono z: {Path(__file__).absolute()}")
print("Środowisko zarządzane przez Poetry\n")

# Globalne flagi
running = True

# Funkcja odpowiedzialna za wykrywanie modeli Raspberry Pi
def detect_hardware():
    """Wykrywa model Raspberry Pi i dostępne interfejsy."""
    print("Wykrywanie sprzętu...")
    
    # Sprawdzanie modelu Raspberry Pi
    try:
        with open('/proc/device-tree/model', 'r') as f:
            model = f.read().strip('\0')
            print(f"Model: {model}")
    except Exception as e:
        print(f"Nie można określić modelu: {e}")
        model = "Nieznany"
    
    # Próba importu typowych bibliotek RPi
    hardware_features = {
        "gpio": False,
        "i2c": False,
        "spi": False,
        "camera": False,
        "adafruit": False
    }
    
    # Sprawdzenie GPIO
    try:
        import RPi.GPIO as GPIO
        GPIO.setmode(GPIO.BCM)
        hardware_features["gpio"] = True
        print(f"RPi.GPIO dostępne (wersja {GPIO.VERSION})")
    except ImportError:
        print("RPi.GPIO niedostępne")
    
    # Sprawdzenie Adafruit Blinka (CircuitPython kompatybilność)
    try:
        import board
        import digitalio
        hardware_features["adafruit"] = True
        print(f"Adafruit Blinka dostępna (płytka: {board.board_id})")
        
        # Sprawdzenie I2C
        try:
            import busio
            i2c = busio.I2C(board.SCL, board.SDA)
            hardware_features["i2c"] = True
            print("I2C dostępne")
        except Exception:
            print("I2C niedostępne")
        
        # Sprawdzenie SPI
        try:
            spi = busio.SPI(board.SCK, MOSI=board.MOSI, MISO=board.MISO)
            hardware_features["spi"] = True
            print("SPI dostępne")
        except Exception:
            print("SPI niedostępne")
            
    except ImportError as e:
        print(f"Adafruit Blinka niedostępna: {e}")
    
    # Sprawdzenie modułu kamery
    try:
        import picamera
        hardware_features["camera"] = True
        print("Moduł kamery dostępny")
    except ImportError:
        print("Moduł kamery niedostępny")
        
    return model, hardware_features

# Symulowana funkcja czujnika - zastąp rzeczywistym kodem czujnika
def sensor_simulator():
    """Symuluje odczyty czujnika temperatury i wilgotności."""
    import random
    
    while running:
        temperature = round(20 + random.uniform(-5, 5), 1)
        humidity = round(50 + random.uniform(-10, 10), 1)
        
        print(f"Temperatura: {temperature}°C, Wilgotność: {humidity}%")
        
        # Przykładowy zapis do pliku
        try:
            with open('sensor_data.csv', 'a') as f:
                f.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')},{temperature},{humidity}\n")
        except Exception as e:
            print(f"Błąd zapisu danych: {e}")
            
        time.sleep(2)

# Główna funkcja programu
def main():
    """Główna funkcja programu."""
    global running
    
    print("=== Przykładowa aplikacja Raspberry Pi z Poetry ===")
    
    # Wykrywanie sprzętu
    model, features = detect_hardware()
    
    # Utworzenie pliku danych (jeśli nie istnieje)
    try:
        with open('sensor_data.csv', 'a') as f:
            if f.tell() == 0:  # Plik jest pusty
                f.write("timestamp,temperature,humidity\n")
    except Exception as e:
        print(f"Błąd inicjalizacji pliku danych: {e}")
    
    # Uruchomienie wątku czujnika w tle
    print("\nUruchamianie symulowanego czujnika...")
    sensor_thread = threading.Thread(target=sensor_simulator)
    sensor_thread.daemon = True
    sensor_thread.start()
    
    # Instrukcje dla użytkownika
    print("\nAplikacja uruchomiona!")
    print("Naciśnij Ctrl+C, aby zakończyć.")
    
    try:
        # Pętla główna
        while True:
            # Tutaj można dodać główną logikę programu
            time.sleep(1)
            
    except KeyboardInterrupt:
        print("\nPrzerwanie przez użytkownika")
    finally:
        # Zatrzymanie wątków i czyszczenie
        running = False
        sensor_thread.join(timeout=1.0)
        print("Aplikacja zakończona.")

# Uruchomienie głównej funkcji
if __name__ == "__main__":
    main()
