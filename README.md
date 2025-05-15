# rpi-stt-tts-shell


Przykładowy projekt dla Raspberry Pi zarządzany przez Poetry, oferujący funkcje rozpoznawania i syntezowania mowy.

## Instalacja

### Wymagania systemowe

- Raspberry Pi (testowano na Raspberry Pi 3B+ i 4)
- Python 3.7 lub nowszy
- pip lub Poetry

### Instalacja przy użyciu pip

```bash
pip install rpi-stt-tts-shell
```


### Podstawowe komendy głosowe
- "Włącz światło" - aktywuje GPIO do włączenia światła
- "Wyłącz światło" - dezaktywuje GPIO
- "Jaka jest temperatura" - odczytuje aktualną temperaturę z czujnika DHT

## Podłączenie sprzętu
### Wymagane komponenty
- Raspberry Pi
- Czujnik temperatury DHT22 (podłączony do pinu GPIO4)
- LED (podłączony do pinu GPIO17)
- Mikrofon USB (do rozpoznawania mowy)
- Głośnik (podłączony przez wyjście audio lub Bluetooth)

### Schemat podłączenia
``` 
Raspberry Pi:
- GPIO4 -> DHT22 (dane)
- GPIO17 -> LED (przez rezystor 220Ω)
- 3.3V -> DHT22 (zasilanie)
- GND -> DHT22 (masa)
- GND -> LED (masa)
```
## Rozwiązywanie problemów
### Popularne problemy
1. **Problem z rozpoznawaniem mowy**
    - Upewnij się, że mikrofon jest prawidłowo podłączony
    - Sprawdź poziom głośności mikrofonu w systemie

2. **Czujnik DHT nie działa**
    - Sprawdź podłączenie przewodów
    - Upewnij się, że biblioteka ma wymagane uprawnienia

3. **Błędy związane z GPIO**
    - Uruchom aplikację z uprawnieniami administratora: `sudo rpi-example`
