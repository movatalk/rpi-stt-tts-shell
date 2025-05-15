#!/usr/bin/env python3
# hosts_csv_parser.py - Parser CSV dla konfiguracji hostów SSH
# Autor: Tom Sapletta
# Data: 15 maja 2025

import csv
import os
import sys
import subprocess
from datetime import datetime


def normalize_host(host):
    """Normalizuje identyfikator hosta do bezpiecznej formy."""
    return ''.join(c if c.isalnum() or c in '-_' else '_' for c in host).lower()


def create_host_config(ip, hostname, device_type, os_info, model, scan_date, username):
    """Tworzy pliki konfiguracyjne dla hosta."""
    # Normalizuj identyfikator hosta
    normalized_host = normalize_host(ip)

    # Przygotuj ścieżki
    home_dir = os.path.expanduser('~')
    hosts_dir = os.path.join(home_dir, 'hosts')
    host_dir = os.path.join(hosts_dir, ip)

    # Upewnij się, że katalog hosta istnieje
    os.makedirs(host_dir, exist_ok=True)

    # Ustaw domyślne wartości dla brakujących pól
    hostname = hostname or 'unknown'
    device_type = device_type or 'unknown'
    os_info = os_info or 'unknown'
    model = model or 'unknown'
    scan_date = scan_date or datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    username = username or 'pi'  # Domyślna nazwa użytkownika dla Raspberry Pi

    # Utwórz plik .env
    env_file = os.path.join(host_dir, '.env')
    with open(env_file, 'w') as f:
        f.write(f'''# SSH Host Configuration

# Connection Details
HOST={ip}
USER={username}

# Network Configuration
PORT=22
KEY={home_dir}/.ssh/id_rsa_{normalized_host}

# Host Metadata
HOSTNAME='{hostname}'
DEVICE_TYPE='{device_type}'
OS_INFO='{os_info}'
MODEL='{model}'
SCAN_DATE='{scan_date}'
''')

    # Utwórz fragment konfiguracji SSH
    ssh_config = os.path.join(host_dir, 'ssh_config')
    with open(ssh_config, 'w') as f:
        f.write(f'''Host {ip}
    HostName {ip}
    User {username}
    Port 22
    IdentityFile ~/.ssh/id_rsa_{normalized_host}
    # StrictHostKeyChecking no
    # UserKnownHostsFile /dev/null
''')

    # Utwórz plik README.md
    readme = os.path.join(host_dir, 'README.md')
    with open(readme, 'w') as f:
        f.write(f'''# Host: {ip}

## Informacje o urządzeniu
- **IP:** {ip}
- **Nazwa hosta:** {hostname}
- **Użytkownik:** {username}
- **Typ urządzenia:** {device_type}
- **System:** {os_info}
- **Model:** {model}
- **Data skanowania:** {scan_date}

## Konfiguracja SSH
Konfiguracja SSH znajduje się w pliku `ssh_config`.
Klucz połączenia: `~/.ssh/id_rsa_{normalized_host}`

## Połączenie
```bash
ssh {username}@{ip}
```

lub z użyciem konfiguracji:

```bash
ssh -F ssh_config {ip}
```

## Generowanie klucza SSH
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_{normalized_host}
ssh-copy-id -i ~/.ssh/id_rsa_{normalized_host}.pub {username}@{ip}
```
''')

    # Ustaw odpowiednie uprawnienia
    os.chmod(host_dir, 0o700)
    os.chmod(env_file, 0o600)
    os.chmod(ssh_config, 0o600)
    os.chmod(readme, 0o644)

    print(f"Utworzono konfigurację dla hosta {ip} w {host_dir}")


def process_csv(csv_file):
    """Przetwarza plik CSV i tworzy konfiguracje hostów."""
    # Upewnij się, że katalog hostów istnieje
    hosts_dir = os.path.join(os.path.expanduser('~'), 'hosts')
    os.makedirs(hosts_dir, exist_ok=True)
    os.chmod(hosts_dir, 0o700)

    # Liczniki
    total_count = 0
    success_count = 0

    # Czytaj i przetwarzaj CSV
    with open(csv_file, 'r') as f:
        reader = csv.reader(f)
        # Pomiń nagłówek
        headers = next(reader, None)

        # Sprawdź nagłówki - powinna być co najmniej kolumna 'ip'
        if not headers or 'ip' not in headers:
            print(f"Uwaga: Plik CSV może nie mieć prawidłowego formatu. Oczekiwano kolumny 'ip'.")
            # Spróbuj użyć indeksów zamiast nazw kolumn
            ip_idx, hostname_idx, device_type_idx, os_info_idx, model_idx, scan_date_idx, username_idx = 0, 1, 2, 3, 4, 5, 6
        else:
            # Znajdź indeksy kolumn
            ip_idx = headers.index('ip') if 'ip' in headers else 0
            hostname_idx = headers.index('hostname') if 'hostname' in headers else 1
            device_type_idx = headers.index('device_type') if 'device_type' in headers else 2
            os_info_idx = headers.index('os_info') if 'os_info' in headers else 3
            model_idx = headers.index('model') if 'model' in headers else 4
            scan_date_idx = headers.index('scan_date') if 'scan_date' in headers else 5
            username_idx = headers.index('username') if 'username' in headers else 6

        # Przetwarzaj wiersze
        for row in reader:
            total_count += 1

            # Upewnij się, że wiersz ma wystarczającą liczbę kolumn
            while len(row) <= max(ip_idx, hostname_idx, device_type_idx, os_info_idx, model_idx, scan_date_idx,
                                  username_idx):
                row.append('')

            try:
                # Wyodrębnij dane
                ip = row[ip_idx].strip()
                hostname = row[hostname_idx].strip() if len(row) > hostname_idx else ''
                device_type = row[device_type_idx].strip() if len(row) > device_type_idx else ''
                os_info = row[os_info_idx].strip() if len(row) > os_info_idx else ''
                model = row[model_idx].strip() if len(row) > model_idx else ''
                scan_date = row[scan_date_idx].strip() if len(row) > scan_date_idx else ''
                username = row[username_idx].strip() if len(row) > username_idx else ''

                # Pomiń wiersze bez IP
                if not ip:
                    print(f"Pominięto wiersz bez adresu IP: {row}")
                    continue

                # Utwórz konfigurację hosta
                create_host_config(ip, hostname, device_type, os_info, model, scan_date, username)
                success_count += 1

            except Exception as e:
                print(f"Błąd podczas przetwarzania wiersza {row}: {e}")

    print(f"Przetworzono {total_count} urządzeń, utworzono {success_count} konfiguracji.")
    return success_count


def main():
    # Pobierz plik CSV z wiersza poleceń lub użyj domyślnego
    csv_file = sys.argv[1] if len(sys.argv) > 1 else 'devices.csv'

    try:
        success_count = process_csv(csv_file)
        print(f"Generowanie konfiguracji hostów zakończone. Utworzono {success_count} konfiguracji w ~/hosts/")
        return 0 if success_count > 0 else 1
    except FileNotFoundError:
        print(f"Błąd: Nie znaleziono pliku CSV - {csv_file}", file=sys.stderr)
        return 1
    except Exception as e:
        print(f"Błąd przetwarzania CSV: {e}", file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())