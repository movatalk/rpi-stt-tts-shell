#!/bin/bash

# SSH Host Configuration Generator Wrapper

# Directory of the script
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# CSV file (use first argument or default to devices.csv)
CSV_FILE="${1:-devices.csv}"

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

# Main script execution
main() {
    # Check if Python3 is available
    if ! command -v python3 > /dev/null 2>&1; then
        log "ERROR" "Python3 is not installed"
        return 1
    fi

    # Check if CSV file exists
    if [ ! -f "$CSV_FILE" ]; then
        log "ERROR" "CSV file not found: $CSV_FILE"
        return 1
    fi

    # Run Python script
    python3 "$SCRIPT_DIR/ssh_hosts_csv_parser.py" "$CSV_FILE"
}

# Run main function
main