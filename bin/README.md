# Skrypty wykonywalne

Ten katalog zawiera główne skrypty wykonywalne projektu, w tym menu główne aplikacji.

## Pliki w tym katalogu

- `menu.sh` - Interaktywne menu do zarządzania urządzeniami Raspberry Pi i Radxa

## menu.sh

Skrypt `menu.sh` to interaktywne menu konsolowe, które umożliwia zarządzanie urządzeniami Raspberry Pi i Radxa. Menu zawiera opcje do skanowania sieci, wdrażania projektu, konfiguracji urządzeń oraz nawiązywania połączeń SSH.

### Funkcje

- Skanowanie sieci w poszukiwaniu urządzeń
- Wdrażanie projektu na wykryte urządzenia
- Konfiguracja interfejsów i komponentów urządzeń
- Wyświetlanie listy wykrytych urządzeń
- Nawiązywanie połączeń SSH z urządzeniami
- Wyświetlanie informacji o projekcie

### Użycie

```bash
./menu.sh
```

### Struktura menu

- **Menu główne**
  1. Skanuj sieć w poszukiwaniu urządzeń
  2. Wdróż projekt na urządzenia
  3. Konfiguruj urządzenia
  4. Wyświetl wykryte urządzenia
  5. Połącz się przez SSH
  6. Informacje o projekcie
  7. Wyjście

- **Podmenu "Konfiguruj urządzenia"**
  - **Raspberry Pi**
    1. Konfiguracja interfejsów (SSH, SPI, I2C, itd.)
    2. Konfiguracja ReSpeaker
    3. Instalacja Poetry
    4. Powrót do poprzedniego menu
  
  - **Radxa**
    1. Konfiguracja interfejsów (SSH, SPI, I2C, itd.)
    2. Konfiguracja ReSpeaker
    3. Instalacja Poetry
    4. Powrót do poprzedniego menu

### Zależności

Skrypt wykorzystuje następujące zewnętrzne skrypty:
- `../fleet/scan.sh` - do skanowania sieci
- `../fleet/deploy.sh` - do wdrażania projektu
- `../rpi/config.sh`, `../rpi/respeaker.sh`, `../rpi/setup.sh` - do konfiguracji Raspberry Pi
- `../zero3w/config.sh`, `../zero3w/respeaker.sh`, `../zero3w/poetry.sh` - do konfiguracji Radxa

### Kolory i formatowanie

Skrypt wykorzystuje kody ANSI do kolorowania i formatowania tekstu:
- `RED` - komunikaty błędów
- `GREEN` - komunikaty sukcesu
- `YELLOW` - pytania i ostrzeżenia
- `BLUE` - informacje
- `CYAN` - nagłówki sekcji
- `MAGENTA` - podświetlanie ważnych informacji
- `BOLD` - wyróżnianie tekstu

### Jak dodać nową opcję do menu

Aby dodać nową opcję do menu głównego:

1. Dodaj nowy wpis w funkcji `main_menu()`:
   ```bash
   echo "8) Nowa opcja"
   ```

2. Dodaj obsługę nowej opcji w instrukcji `case`:
   ```bash
   case $option in
       # Istniejące opcje...
       8)
           nowa_funkcja
           ;;
   esac
   ```

3. Zdefiniuj nową funkcję:
   ```bash
   nowa_funkcja() {
       clear_screen
       show_banner
       
       echo -e "${CYAN}${BOLD}TYTUŁ NOWEJ FUNKCJI${NC}"
       echo "Opis nowej funkcji"
       echo ""
       
       # Kod funkcji...
       
       echo ""
       read -p "Naciśnij Enter, aby wrócić do menu głównego..."
   }
   ```

### Przykłady użycia

```bash
# Uruchomienie menu
./menu.sh

# Nawiązanie połączenia SSH z konkretnym urządzeniem
# (Po wybraniu opcji 5 i podaniu ID urządzenia)
```