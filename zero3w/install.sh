#!/bin/bash
# setup_radxa_respeaker.sh - Skrypt instalacyjny dla Radxa 3W/3E z ReSpeaker 2-Mic Pi HAT
# Author: Tom Sapletta
# Data: 15 maja 2025

# Kolory dla czytelności
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

echo -e "${BOLD}${GREEN}==================================================="
echo -e "  KONFIGURACJA RADXA ZERO 3W/3E + ReSpeaker 2-Mic Pi HAT"
echo -e "===================================================${NC}"

# Sprawdź czy skrypt jest uruchomiony jako root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Ten skrypt wymaga uprawnień administratora. Uruchom z sudo.${NC}"
  exit 1
fi

# Wykryj model Radxa
detect_model() {
    echo -e "${BLUE}Wykrywanie modelu Radxa...${NC}"

    if grep -q "ZERO 3W" /proc/device-tree/model 2>/dev/null; then
        MODEL="Radxa ZERO 3W"
    elif grep -q "ZERO 3E" /proc/device-tree/model 2>/dev/null; then
        MODEL="Radxa ZERO 3E"
    elif grep -q "Radxa" /proc/device-tree/model 2>/dev/null; then
        MODEL=$(cat /proc/device-tree/model | tr -d '\0')
    else
        MODEL="Nieznany model Radxa"
    fi

    echo -e "${GREEN}Wykryto: ${BOLD}$MODEL${NC}"
}

# Aktualizacja systemu
update_system() {
    echo -e "\n${BLUE}Aktualizacja systemu...${NC}"
    apt-get update
    apt-get upgrade -y
    echo -e "${GREEN}System zaktualizowany${NC}"
}

# Instalacja wymaganych pakietów
install_dependencies() {
    echo -e "\n${BLUE}Instalacja wymaganych pakietów...${NC}"
    apt-get install -y git python3 python3-pip python3-setuptools python3-dev build-essential libatlas-base-dev i2c-tools alsa-utils swig portaudio19-dev libportaudio2 python3-pyaudio

    # Czyszczenie pamięci podręcznej APT
    apt-get clean
    echo -e "${GREEN}Pakiety zainstalowane${NC}"
}

# Konfiguracja audio
configure_audio() {
    echo -e "\n${BLUE}Konfiguracja audio...${NC}"

    # Tworzenie pliku asound.conf
    cat > /etc/asound.conf << EOF
pcm.!default {
  type asym
  capture.pcm "mic"
  playback.pcm "speaker"
}

pcm.mic {
  type plug
  slave {
    pcm "hw:1,0"
  }
}

pcm.speaker {
  type plug
  slave {
    pcm "hw:0,0"
  }
}
EOF

    # Upewnienie się, że moduły I2S i I2C są włączone
    if ! grep -q "dtparam=i2c_arm=on" /boot/config.txt 2>/dev/null; then
        echo "dtparam=i2c_arm=on" >> /boot/config.txt
    fi

    if ! grep -q "dtparam=i2s=on" /boot/config.txt 2>/dev/null; then
        echo "dtparam=i2s=on" >> /boot/config.txt
    fi

    # Włączenie sterownika ReSpeaker
    if ! grep -q "dtoverlay=seeed-2mic-voicecard" /boot/config.txt 2>/dev/null; then
        echo "dtoverlay=seeed-2mic-voicecard" >> /boot/config.txt
    fi

    echo -e "${GREEN}Konfiguracja audio zakończona${NC}"
}

# Instalacja sterowników ReSpeaker
install_respeaker_drivers() {
    echo -e "\n${BLUE}Instalacja sterowników ReSpeaker...${NC}"

    # Katalog tymczasowy
    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR"

    # Pobranie sterowników
    git clone https://github.com/respeaker/seeed-voicecard.git
    cd seeed-voicecard

    # Instalacja sterowników
    ./install.sh

    # Czyszczenie
    cd
    rm -rf "$TMP_DIR"

    echo -e "${GREEN}Sterowniki ReSpeaker zainstalowane${NC}"
}

# Konfiguracja GPIO dla Radxa
configure_gpio() {
    echo -e "\n${BLUE}Konfiguracja GPIO dla Radxa...${NC}"

    # Instalacja bibliotek GPIO Python
    pip3 install spidev RPi.GPIO

    # Instalacja biblioteki WiringPi dla Radxa (kompatybilna z Raspberry Pi)
    apt-get install -y wiringpi || {
        # Jeśli nie ma w repozytoriach, skompiluj z kodu źródłowego
        TMP_DIR=$(mktemp -d)
        cd "$TMP_DIR"
        git clone https://github.com/WiringPi/WiringPi.git
        cd WiringPi
        ./build
        cd
        rm -rf "$TMP_DIR"
    }

    echo -e "${GREEN}Konfiguracja GPIO zakończona${NC}"
}

# Instalacja bibliotek Python dla ReSpeaker
install_python_libraries() {
    echo -e "\n${BLUE}Instalacja bibliotek Python dla ReSpeaker...${NC}"

    # Instalacja bibliotek audio
    pip3 install pyaudio wave

    # Instalacja bibliotek specyficznych dla ReSpeaker
    pip3 install respeaker

    # Instalacja narzędzi do przetwarzania mowy
    pip3 install pocketsphinx SpeechRecognition gpiozero

    echo -e "${GREEN}Biblioteki Python zainstalowane${NC}"
}

# Instalacja LED kontrolera
install_led_controller() {
    echo -e "\n${BLUE}Instalacja kontrolera LED dla ReSpeaker...${NC}"

    # Instalacja biblioteki Pixel Ring dla ReSpeaker 2-Mic
    pip3 install pixel-ring

    # Testowy kod Python dla Pixel Ring
    cat > /home/pi/test_led.py << 'EOF'
from pixel_ring import pixel_ring
import time

# Test LED ringa
pixel_ring.set_brightness(10)  # Jasność (0-100)

# Przykładowe animacje
for _ in range(3):
    # Kręcąca się animacja
    for i in range(12):
        pixel_ring.set_direction(i * 30)
        time.sleep(0.1)

# Różne kolory
pixel_ring.set_color(r=255, g=0, b=0)  # Czerwony
time.sleep(1)
pixel_ring.set_color(r=0, g=255, b=0)  # Zielony
time.sleep(1)
pixel_ring.set_color(r=0, g=0, b=255)  # Niebieski
time.sleep(1)

# Animacja nasłuchiwania
print("Symulacja nasłuchiwania (10 sekund)...")
pixel_ring.listen()
time.sleep(5)
print("Symulacja mówienia...")
pixel_ring.speak()
time.sleep(5)

# Wyłączenie LED
pixel_ring.off()
print("Test LED zakończony")
EOF

    chmod +x /home/pi/test_led.py

    echo -e "${GREEN}Kontroler LED zainstalowany${NC}"
    echo -e "${YELLOW}Możesz przetestować LED wykonując: python3 /home/pi/test_led.py${NC}"
}

# Instalacja przykładowego asystenta głosowego
install_voice_assistant() {
    echo -e "\n${BLUE}Instalacja przykładowego asystenta głosowego...${NC}"

    # Instalacja wymaganych bibliotek
    pip3 install pyttsx3 pyaudio

    # Tworzenie przykładowego kodu asystenta
    cat > /home/pi/voice_assistant.py << 'EOF'
#!/usr/bin/env python3
"""
Przykładowy asystent głosowy dla Radxa z ReSpeaker 2-Mic Pi HAT
"""

import time
import speech_recognition as sr
import pyttsx3
from pixel_ring import pixel_ring
import os

# Inicjalizacja syntezy mowy
engine = pyttsx3.init()
voices = engine.getProperty('voices')
engine.setProperty('voice', voices[0].id)  # Domyślny głos

# Inicjalizacja pierścienia LED
pixel_ring.set_brightness(10)

def speak(text):
    """Funkcja do odczytywania tekstu"""
    print(f"Asystent: {text}")
    pixel_ring.speak()
    engine.say(text)
    engine.runAndWait()
    pixel_ring.off()

def listen():
    """Funkcja do nasłuchiwania komend głosowych"""
    r = sr.Recognizer()
    with sr.Microphone() as source:
        print("Nasłuchuję...")
        pixel_ring.listen()
        r.adjust_for_ambient_noise(source)
        audio = r.listen(source)
        pixel_ring.off()

    try:
        command = r.recognize_google(audio)
        print(f"Zrozumiałem: {command}")
        return command.lower()
    except sr.UnknownValueError:
        print("Nie rozpoznano mowy")
        return ""
    except sr.RequestError:
        print("Błąd usługi rozpoznawania mowy; sprawdź połączenie internetowe")
        return ""

def process_command(command):
    """Przetwarzanie komend głosowych"""
    if "cześć" in command or "witaj" in command:
        speak("Cześć! Jak mogę pomóc?")
    elif "data" in command or "dzień" in command:
        from datetime import datetime
        now = datetime.now()
        speak(f"Dzisiaj jest {now.strftime('%d %B %Y')}")
    elif "czas" in command or "godzina" in command:
        from datetime import datetime
        now = datetime.now()
        speak(f"Aktualna godzina to {now.strftime('%H:%M')}")
    elif "włącz światło" in command or "zapal światło" in command:
        speak("Włączam światło")
        # Tu można dodać kod do kontrolowania GPIO
    elif "wyłącz światło" in command or "zgaś światło" in command:
        speak("Wyłączam światło")
        # Tu można dodać kod do kontrolowania GPIO
    elif "koniec" in command or "do widzenia" in command or "żegnaj" in command:
        speak("Do widzenia!")
        return False
    elif "pomoc" in command:
        speak("Mogę podać aktualną datę, czas, włączyć lub wyłączyć światło. Powiedz koniec, aby zakończyć.")
    else:
        speak("Przepraszam, nie rozumiem komendy. Powiedz pomoc, aby poznać dostępne polecenia.")

    return True

def main():
    """Główna funkcja asystenta"""
    speak("Witaj! Jestem twoim asystentem głosowym. Jak mogę pomóc?")

    running = True
    while running:
        command = listen()
        if command:
            running = process_command(command)
        time.sleep(0.5)

    pixel_ring.off()

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("Przerwano przez użytkownika")
        pixel_ring.off()
EOF

    chmod +x /home/pi/voice_assistant.py

    # Tworzenie skryptu uruchamiającego asystenta
    cat > /home/pi/start_assistant.sh << 'EOF'
#!/bin/bash
cd /home/pi
python3 voice_assistant.py
EOF

    chmod +x /home/pi/start_assistant.sh

    echo -e "${GREEN}Przykładowy asystent głosowy zainstalowany${NC}"
    echo -e "${YELLOW}Możesz uruchomić asystenta wykonując: /home/pi/start_assistant.sh${NC}"
}

# Główna funkcja wykonująca konfigurację
main() {
    detect_model
    update_system
    install_dependencies
    configure_audio
    install_respeaker_drivers
    configure_gpio
    install_python_libraries
    install_led_controller
    install_voice_assistant

    echo -e "\n${GREEN}${BOLD}Konfiguracja Radxa z ReSpeaker 2-Mic Pi HAT zakończona pomyślnie!${NC}"
    echo -e "${YELLOW}Zalecane jest ponowne uruchomienie systemu, aby zastosować wszystkie zmiany.${NC}"
    echo -e "Aby ponownie uruchomić system, wpisz: ${BOLD}sudo reboot${NC}"

    # Pytanie o restart
    read -p "Czy chcesz teraz ponownie uruchomić system? (t/n): " answer
    if [[ "$answer" == "t" || "$answer" == "T" ]]; then
        echo "System zostanie ponownie uruchomiony..."
        reboot
    fi
}

# Uruchomienie głównej funkcji
main