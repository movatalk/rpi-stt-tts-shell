import os
import subprocess
from pocketsphinx import LiveSpeech
# pip3 install pocketsphinx
# Find your device index first using:
# import sounddevice
# print(sounddevice.query_devices())
# Then specify that index:
#speech = LiveSpeech(lm=False, keyphrase='komputer', kws_threshold=1e-20, device=0)  # Try with device=0 or another index

# Funkcja TTS
def speak(text):
    print("Odpowiedź:", text)
    subprocess.run(['espeak-ng', text])

# Funkcja do wykonania polecenia shell
def execute_shell_command(cmd):
    try:
        output = subprocess.check_output(cmd, shell=True, stderr=subprocess.STDOUT, universal_newlines=True)
        return output.strip()
    except subprocess.CalledProcessError as e:
        return "Błąd: " + e.output.strip()

# Główna pętla nasłuchująca mikrofonu
print("Asystent głosowy uruchomiony. Powiedz polecenie (np. 'jaka jest data').")
speech = LiveSpeech(lm=False, keyphrase='komputer', kws_threshold=1e-20)

for phrase in speech:
    print("Wykryto słowo wywołania!")
    # Po wywołaniu czekamy na polecenie użytkownika
    speak("Słucham polecenia.")
    # Nasłuch kolejnej frazy
    command_speech = LiveSpeech()
    for command_phrase in command_speech:
        command = str(command_phrase).lower()
        print("Rozpoznano:", command)
        # Przykładowe polecenia
        if "data" in command:
            result = execute_shell_command("date")
            speak("Aktualna data to: " + result)
        elif "ip" in command:
            result = execute_shell_command("hostname -I")
            speak("Adres IP to: " + result)
        elif "koniec" in command or "wyłącz" in command:
            speak("Do widzenia!")
            exit(0)
        else:
            speak("Nie rozumiem polecenia.")
        break  # Po jednym poleceniu wracamy do nasłuchu słowa wywołania
