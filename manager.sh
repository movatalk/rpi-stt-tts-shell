#!/bin/bash
# Author: tom-sapletta-com
# Purpose: SSH Host Management Utility for managing SSH configurations and connections to multiple hosts.

# SSH Host Management Utility


# Paths
HOME_HOSTS_DIR="${HOME}/hosts"

# Logging function
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    if [ "$level" = "INFO" ]; then
        echo "[INFO] $timestamp - $message"
    elif [ "$level" = "WARN" ]; then
        echo "[WARN] $timestamp - $message" >&2
    elif [ "$level" = "ERROR" ]; then
        echo "[ERROR] $timestamp - $message" >&2
    else
        echo "$message"
    fi
}

# Find host directory
find_host_dir() {
    local host="$1"
    local normalized_host
    normalized_host=$(echo "$host" | sed 's/[^a-zA-Z0-9_-]/_/g' | tr '[:upper:]' '[:lower:]')

    local possible_dirs=(
        "$HOME_HOSTS_DIR/$host"
        "$HOME_HOSTS_DIR/$normalized_host"
    )

    for dir in "${possible_dirs[@]}"; do
        if [ -d "$dir" ]; then
            echo "$dir"
            return 0
        fi
    done

    return 1
}

# Load host configuration
load_host_config() {
    local host_dir="$1"
    local env_file="$host_dir/.env"

    if [ ! -f "$env_file" ]; then
        log "ERROR" "No environment file found in $host_dir"
        return 1
    fi

    # Source environment variables safely
    HOST=""
    USER=""
    PORT=""
    KEY=""

    # Read variables line by line
    while IFS='=' read -r name value; do
        # Trim whitespace and remove quotes
        name=$(echo "$name" | xargs)
        value=$(echo "$value" | xargs | sed "s/^['\"]//; s/['\"]$//")

        # Set variables
        case "$name" in
            HOST) HOST="$value" ;;
            USER) USER="$value" ;;
            PORT) PORT="$value" ;;
            KEY) KEY="$value" ;;
        esac
    done < <(grep -E '^(HOST|USER|PORT|KEY)=' "$env_file")

    # Verify required variables
    if [ -z "$HOST" ] || [ -z "$USER" ]; then
        log "ERROR" "Missing required configuration in $env_file"
        return 1
    fi

    # Set defaults
    PORT="${PORT:-22}"
    KEY="${KEY:-$HOME/.ssh/id_rsa}"

    return 0
}

# Ensure SSH key exists
ensure_ssh_key() {
    local key_path="$1"

    if [ ! -f "$key_path" ]; then
        log "WARN" "Generating SSH key: $key_path"
        ssh-keygen -t rsa -b 4096 -f "$key_path" -N ""
    fi

    # Ensure correct permissions
    chmod 600 "$key_path"
    chmod 644 "${key_path}.pub"
}

# Copy SSH public key to remote host
copy_ssh_key() {
    local host="$1"
    local user="$2"
    local port="$3"
    local key_path="$4"

    log "INFO" "Copying SSH public key to $host"
    ssh-copy-id -i "${key_path}.pub" -p "$port" "$user@$host"
}

# Test SSH connection
test_connection() {
    local host="$1"
    local user="$2"
    local port="$3"

    log "INFO" "Testing SSH connection to $host"
    ssh -vv -p "$port" "$user@$host" exit
}

# Configure a specific host
configure_host() {
    local host="$1"
    local host_dir

    # Find host directory
    if ! host_dir=$(find_host_dir "$host"); then
        log "ERROR" "No configuration found for host $host"
        return 1
    fi

    # Load host configuration
    if ! load_host_config "$host_dir"; then
        log "ERROR" "Failed to load configuration for $host"
        return 1
    fi

    # Ensure SSH key exists
    ensure_ssh_key "$KEY"

    # Copy SSH key (interactive)
    copy_ssh_key "$HOST" "$USER" "$PORT" "$KEY"

    # Test connection
    test_connection "$HOST" "$USER" "$PORT"

    log "INFO" "Host $host configuration complete"
}

# List available hosts
list_hosts() {
    log "INFO" "Available hosts:"
    if [ ! -d "$HOME_HOSTS_DIR" ]; then
        log "WARN" "No hosts directory found"
        return 1
    fi

    local found=0
    for host_dir in "$HOME_HOSTS_DIR"/*; do
        if [ -d "$host_dir" ] && [ -f "$host_dir/.env" ]; then
            host=$(basename "$host_dir")
            # Read hostname from .env file
            hostname=$(grep "HOSTNAME=" "$host_dir/.env" | head -n 1 | cut -d'=' -f2 | xargs)
            echo "- $host (${hostname:-No hostname})"
            found=$((found + 1))
        fi
    done

    if [ "$found" -eq 0 ]; then
        log "WARN" "No hosts configured"
        return 1
    fi
}

# Main script execution
main() {
    # Check if hosts directory exists
    if [ ! -d "$HOME_HOSTS_DIR" ]; then
        log "ERROR" "No hosts configured. Run the CSV import script first."
        return 1
    fi

    # Handle different actions
    if [ $# -eq 0 ]; then
        list_hosts
    elif [ "$1" = "list" ]; then
        list_hosts
    else
        configure_host "$1"
    fi
}

# Run main with all arguments
main "$@"