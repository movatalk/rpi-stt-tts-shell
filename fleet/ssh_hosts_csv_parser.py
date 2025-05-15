#!/usr/bin/env python3

import csv
import os
import sys
import subprocess


def normalize_host(host):
    """Normalize host identifier."""
    return ''.join(c if c.isalnum() or c in '-_' else '_' for c in host).lower()


def create_host_config(ip, hostname, is_raspberry_pi, os_info, model, scan_date):
    """Create host configuration files."""
    # Normalize host identifier
    normalized_host = normalize_host(ip)

    # Prepare paths
    home_dir = os.path.expanduser('~')
    hosts_dir = os.path.join(home_dir, 'hosts')
    host_dir = os.path.join(hosts_dir, ip)

    # Ensure host directory exists
    os.makedirs(host_dir, exist_ok=True)

    # Default values
    hostname = hostname or '-'
    is_raspberry_pi = is_raspberry_pi or 'false'
    os_info = os_info or '-'
    model = model or '-'
    scan_date = scan_date or subprocess.check_output(['date', '+%Y-%m-%d']).decode().strip()

    # Create .env file
    env_file = os.path.join(host_dir, '.env')
    with open(env_file, 'w') as f:
        f.write(f'''# SSH Host Configuration

# Connection Details
HOST={ip}
USER=tom

# Network Configuration
PORT=22
KEY={home_dir}/.ssh/id_rsa_{normalized_host}

# Host Metadata
HOSTNAME='{hostname}'
IS_RASPBERRY_PI='{is_raspberry_pi}'
OS_INFO='{os_info}'
MODEL='{model}'
SCAN_DATE='{scan_date}'
''')

    # Create SSH config snippet
    ssh_config = os.path.join(host_dir, 'ssh_config')
    with open(ssh_config, 'w') as f:
        f.write(f'''Host {ip}
    HostName {ip}
    User tom
    Port 22
    IdentityFile ~/.ssh/id_rsa_{normalized_host}
    # Additional custom SSH options can be added here
''')

    # Create README
    readme = os.path.join(host_dir, 'README.md')
    with open(readme, 'w') as f:
        f.write(f'''# Host: {ip}

## Connection Details
- **IP**: {ip}
- **Hostname**: {hostname}
- **User**: tom

## System Information
- **Raspberry Pi**: {is_raspberry_pi}
- **OS**: {os_info}
- **Model**: {model}
- **Scanned**: {scan_date}

## SSH Configuration
SSH configuration available in `ssh_config`
Connection key: `~/.ssh/id_rsa_{normalized_host}`
''')

    # Set correct permissions
    os.chmod(host_dir, 0o700)
    os.chmod(env_file, 0o600)
    os.chmod(ssh_config, 0o600)
    os.chmod(readme, 0o644)

    print(f"Created configuration for host {ip} in {host_dir}")


def process_csv(csv_file):
    """Process CSV and create host configurations."""
    # Ensure hosts directory exists
    hosts_dir = os.path.join(os.path.expanduser('~'), 'hosts')
    os.makedirs(hosts_dir, exist_ok=True)
    os.chmod(hosts_dir, 0o700)

    # Read and process CSV
    with open(csv_file, 'r') as f:
        reader = csv.reader(f)
        # Skip header
        next(reader, None)

        for row in reader:
            # Pad row to ensure 6 fields
            row += [''] * (6 - len(row))

            # Call create_host_config with cleaned data
            create_host_config(
                row[0].strip(),  # ip
                row[1].strip(),  # hostname
                row[2].strip(),  # is_raspberry_pi
                row[3].strip(),  # os_info
                row[4].strip(),  # model
                row[5].strip()  # scan_date
            )


def main():
    # Get CSV file from command line or use default
    csv_file = sys.argv[1] if len(sys.argv) > 1 else 'devices.csv'

    try:
        process_csv(csv_file)
        print(f"Host configuration generation complete. Configurations stored in ~/hosts/")
    except FileNotFoundError:
        print(f"Error: CSV file not found - {csv_file}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error processing CSV: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()