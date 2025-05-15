# Narzędzia do zarządzania flotą urządzeń

Ten katalog zawiera skrypty służące do wykrywania, wdrażania i testowania aplikacji na urządzeniach Raspberry Pi i Radxa w sieci lokalnej.

## Pliki w tym katalogu

- `scan.sh` - Skrypt do skanowania sieci w poszukiwaniu urządzeń Raspberry Pi i Radxa
- `deploy.sh` - Skrypt do wdrażania projektu na wykryte urządzenia
- `test.sh` - Skrypt testowy uruchamiany na urządzeniach docelowych po wdrożeniu

## scan.sh

Skrypt `scan.sh` automatycznie wykrywa urządzenia Raspberry Pi i Radxa w sieci lokalnej, identyfikuje ich parametry i zapisuje wyniki do pliku CSV.

### Funkcje

- Automatyczne wykrywanie zakresu sieci
- Identyfikacja urządzeń Raspberry Pi i Radxa na podstawie różnych markerów
- Zbieranie informacji o systemie operacyjnym, modelu i innych parametrach
- Zapisywanie wyników do pliku CSV do dalszego wykorzystania

### Użycie

```bash
./scan.sh [OPCJE]
```

### Opcje

- `-r, --range RANGE` - skanuj podany zakres sieci (np. 192.168.1.0/24)
- `-o, --output FILE` - zapisz wyniki do podanego pliku CSV (domyślnie: devices.csv)
- `-d, --debug` - włącz tryb debugowania
- `-h, --help` - wyświetl pomoc

### Przykłady

```bash
# Standardowe użycie (automatyczne wykrywanie sieci)
./scan.sh

# Skanowanie konkretnego zakresu sieci
./scan.sh -r 10.0.0.0/24

# Zapisanie wyników do niestandardowego pliku
./scan.sh -o moje_urzadzenia.csv
```

## deploy.sh

Skrypt `deploy.sh` służy do automatycznego wdrażania, testowania i logowania projektu na wykrytych urządzeniach.

### Funkcje

- Wdrażanie projektu na wielu urządzeniach jednocześnie
- Testowanie wdrożonego projektu
- Zbieranie informacji o systemie
- Generowanie raportów z wdrożenia
- Obsługa różnych metod uwierzytelniania SSH

### Użycie

```bash
./deploy.sh [OPCJE]
```

### Opcje

- `-f, --file FILE` - użyj podanego pliku CSV z urządzeniami (domyślnie: devices.csv)
- `-u, --user USER` - użyj podanej nazwy użytkownika SSH (domyślnie: pi)
- `-p, --password PASS` - użyj podanego hasła SSH (domyślnie: raspberry)
- `-d, --dir DIR` - użyj podanego katalogu projektu (domyślnie: ./)
- `-r, --remote-dir DIR` - użyj podanego katalogu zdalnego (domyślnie: /home/pi/deployed_project)
- `-i, --ip IP` - wdróż tylko na konkretne urządzenie o podanym IP
- `-h, --help` - wyświetl pomoc

### Przykłady

```bash
# Standardowe użycie (wdrożenie na wszystkie urządzenia z pliku CSV)
./deploy.sh

# Wdrożenie z niestandardowymi parametrami
./deploy.sh -u admin -p tajnehaslo -d ~/moj_projekt -r /opt/aplikacja

# Wdrożenie tylko na jedno urządzenie
./deploy.sh -i 192.168.1.100
```

## test.sh

Skrypt `test.sh` jest uruchamiany na zdalnych urządzeniach po wdrożeniu, aby sprawdzić czy wszystko działa poprawnie.

### Funkcje

- Testy systemowe (wersja systemu, model urządzenia)
- Testy zależności systemowych
- Testy konfiguracji projektu
- Testy działania komponentów

### Jak to działa

Skrypt jest kopiowany na urządzenie docelowe wraz z plikami projektu i uruchamiany automatycznie przez `deploy.sh`. Wyniki testów są zapisywane w logach wdrożenia.

## Typowy przepływ pracy

1. Skanowanie sieci w poszukiwaniu urządzeń:
   ```bash
   ./scan.sh
   ```

2. Wdrożenie projektu na wykryte urządzenia:
   ```bash
   ./deploy.sh
   ```

3. Sprawdzenie raportów wdrożenia w katalogu `deployment_logs/`

## Zależności

- `nmap` - do skanowania sieci
- `ssh` i `scp` - do łączenia się z urządzeniami i kopiowania plików
- `sshpass` - opcjonalnie, do logowania z hasłem