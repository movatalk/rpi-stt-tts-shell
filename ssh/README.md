# Narzędzia do zarządzania konfiguracjami SSH

Ten katalog zawiera skrypty służące do zarządzania konfiguracjami SSH dla urządzeń Raspberry Pi i Radxa.

## Pliki w tym katalogu

- `manager.sh` - Skrypt do zarządzania konfiguracjami SSH
- `hosts_from_csv.sh` - Skrypt do generowania konfiguracji hostów z pliku CSV
- `hosts_csv_parser.py` - Skrypt Python parsujący plik CSV i generujący katalogi konfiguracyjne

## manager.sh

Skrypt `manager.sh` służy do zarządzania konfiguracjami SSH dla zidentyfikowanych urządzeń. Umożliwia wyświetlanie listy dostępnych hostów, konfigurację połączeń SSH, generowanie i kopiowanie kluczy SSH.

### Funkcje

- Wyświetlanie listy skonfigurowanych hostów
- Konfiguracja połączeń SSH dla konkretnych hostów
- Generowanie i kopiowanie kluczy SSH
- Testowanie połączeń z hostami

### Użycie

```bash
./manager.sh [HOST|KOMENDA]
```

Jeśli nie podano argumentów lub podano "list", skrypt wyświetli listę dostępnych hostów. Jeśli podano nazwę hosta, skrypt skonfiguruje ten host.

### Przykłady

```bash
# Wyświetlenie listy hostów
./manager.sh list

# Lub po prostu
./manager.sh

# Konfiguracja konkretnego hosta
./manager.sh 192.168.1.100
```

## hosts_from_csv.sh

Skrypt `hosts_from_csv.sh` generuje konfiguracje hostów SSH na podstawie pliku CSV (zazwyczaj wygenerowanego przez `scan.sh`).

### Funkcje

- Przetwarzanie pliku CSV z informacjami o urządzeniach
- Generowanie katalogów konfiguracyjnych dla każdego hosta w `~/hosts/`
- Tworzenie plików konfiguracyjnych (.env, ssh_config, README.md) dla każdego hosta

### Użycie

```bash
./hosts_from_csv.sh [PLIK_CSV]
```

Jeśli nie podano pliku CSV, skrypt domyślnie użyje `devices.csv`.

### Przykłady

```bash
# Użycie domyślnego pliku CSV (devices.csv)
./hosts_from_csv.sh

# Użycie niestandardowego pliku CSV
./hosts_from_csv.sh moje_urzadzenia.csv
```

## hosts_csv_parser.py

Skrypt Python `hosts_csv_parser.py` parsuje plik CSV i generuje katalogi konfiguracyjne dla każdego hosta. Jest używany przez `hosts_from_csv.sh`.

### Funkcje

- Parsowanie pliku CSV z informacjami o urządzeniach
- Tworzenie katalogów konfiguracyjnych w `~/hosts/`
- Generowanie plików konfiguracyjnych:
  - `.env` - plik z zmiennymi środowiskowymi
  - `ssh_config` - fragment konfiguracji SSH
  - `README.md` - dokumentacja hosta

### Struktura wygenerowanych katalogów

```
~/hosts/
├── 192.168.1.100/
│   ├── .env
│   ├── ssh_config
│   └── README.md
├── 192.168.1.101/
│   ├── .env
│   ├── ssh_config
│   └── README.md
...
```

### Format pliku .env

```
# SSH Host Configuration

# Connection Details
HOST=192.168.1.100
USER=pi

# Network Configuration
PORT=22
KEY=~/.ssh/id_rsa_192_168_1_100

# Host Metadata
HOSTNAME='raspberrypi'
IS_RASPBERRY_PI='true'
OS_INFO='Raspberry Pi OS (bullseye)'
MODEL='Raspberry Pi 4 Model B Rev 1.2'
SCAN_DATE='2025-05-15 12:34:56'
```

## Integracja z innymi narzędziami

Narzędzia SSH są zintegrowane z innymi komponentami projektu:

1. `scan.sh` generuje plik CSV z informacjami o urządzeniach
2. `hosts_from_csv.sh` przetwarza ten plik i tworzy konfiguracje SSH
3. `manager.sh` umożliwia zarządzanie utworzonymi konfiguracjami
4. `deploy.sh` wykorzystuje te konfiguracje do wdrażania projektu

## Uwagi bezpieczeństwa

- Skrypty domyślnie tworzą katalogi z uprawnieniami 0700 (dostęp tylko dla właściciela)
- Pliki konfiguracyjne są tworzone z uprawnieniami 0600 (dostęp tylko dla właściciela)
- Zalecane jest używanie kluczy SSH zamiast haseł
- W środowisku produkcyjnym należy zastosować silne hasła i odpowiednio zabezpieczyć klucze SSH