#!/bin/bash

# Raspberry Pi Configuration Utility

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

# Check if running on Raspberry Pi
check_raspberry_pi() {
    if [ ! -f /proc/device-tree/model ]; then
        log "ERROR" "Not running on a Raspberry Pi"
        return 1
    fi

    # Display Pi model
    cat /proc/device-tree/model
    return 0
}

# Enable SSH
enable_ssh() {
    if systemctl is-active ssh > /dev/null 2>&1; then
        log "INFO" "SSH is already enabled and running"
        return 0
    fi

    log "INFO" "Enabling SSH..."

    # Raspberry Pi OS method
    if command -v raspi-config > /dev/null 2>&1; then
        sudo raspi-config nonint do_ssh 0
    else
        # Alternative method
        sudo systemctl enable ssh
        sudo systemctl start ssh
    fi

    # Verify SSH is enabled
    if systemctl is-active ssh > /dev/null 2>&1; then
        log "INFO" "SSH enabled successfully"
    else
        log "ERROR" "Failed to enable SSH"
        return 1
    fi
}

# Enable SPI
enable_spi() {
    log "INFO" "Configuring SPI..."

    # Check if already enabled
    if grep -q "^dtparam=spi=on" /boot/config.txt; then
        log "INFO" "SPI is already enabled"
        return 0
    fi

    # Enable SPI
    if [ -f /boot/config.txt ]; then
        sudo sed -i 's/^#dtparam=spi=on/dtparam=spi=on/' /boot/config.txt
        if ! grep -q "^dtparam=spi=on" /boot/config.txt; then
            echo "dtparam=spi=on" | sudo tee -a /boot/config.txt > /dev/null
        fi
        log "INFO" "SPI enabled. Reboot required to apply changes."
    else
        log "ERROR" "Cannot find /boot/config.txt"
        return 1
    fi
}

# Enable I2C
enable_i2c() {
    log "INFO" "Configuring I2C..."

    # Check if already enabled
    if grep -q "^dtparam=i2c_arm=on" /boot/config.txt; then
        log "INFO" "I2C is already enabled"
        return 0
    fi

    # Enable I2C
    if [ -f /boot/config.txt ]; then
        sudo sed -i 's/^#dtparam=i2c_arm=on/dtparam=i2c_arm=on/' /boot/config.txt
        if ! grep -q "^dtparam=i2c_arm=on" /boot/config.txt; then
            echo "dtparam=i2c_arm=on" | sudo tee -a /boot/config.txt > /dev/null
        fi

        # Ensure I2C tools are installed
        sudo apt-get update
        sudo apt-get install -y i2c-tools

        log "INFO" "I2C enabled. Reboot required to apply changes."
    else
        log "ERROR" "Cannot find /boot/config.txt"
        return 1
    fi
}

# Enable Serial
enable_serial() {
    log "INFO" "Configuring Serial..."

    # Check if already enabled
    if grep -q "^enable_uart=1" /boot/config.txt; then
        log "INFO" "Serial is already enabled"
        return 0
    fi

    # Enable Serial
    if [ -f /boot/config.txt ]; then
        sudo sed -i 's/^#enable_uart=1/enable_uart=1/' /boot/config.txt
        if ! grep -q "^enable_uart=1" /boot/config.txt; then
            echo "enable_uart=1" | sudo tee -a /boot/config.txt > /dev/null
        fi
        log "INFO" "Serial enabled. Reboot required to apply changes."
    else
        log "ERROR" "Cannot find /boot/config.txt"
        return 1
    fi
}

# Configure 1-Wire
enable_1wire() {
    log "INFO" "Configuring 1-Wire..."

    # Check if already enabled
    if grep -q "^dtoverlay=w1-gpio" /boot/config.txt; then
        log "INFO" "1-Wire is already enabled"
        return 0
    fi

    # Enable 1-Wire
    if [ -f /boot/config.txt ]; then
        echo "dtoverlay=w1-gpio" | sudo tee -a /boot/config.txt > /dev/null
        log "INFO" "1-Wire enabled. Reboot required to apply changes."
    else
        log "ERROR" "Cannot find /boot/config.txt"
        return 1
    fi
}

# Full configuration
configure_raspberry_pi() {
    # Ensure running as non-root user
    if [ "$EUID" -eq 0 ]; then
        log "ERROR" "Do not run this script as root. Use sudo if needed."
        return 1
    fi

    # Check if running on Raspberry Pi
    check_raspberry_pi || return 1

    # Perform configurations
    enable_ssh
    enable_spi
    enable_i2c
    enable_serial
    enable_1wire

    # Suggest reboot
    log "WARN" "Reboot recommended to apply all changes"
    echo "Suggested reboot command: sudo reboot"
}

# Display help
display_help() {
    echo "Raspberry Pi Configuration Utility"
    echo "Usage:"
    echo "  $0 [option]"
    echo ""
    echo "Options:"
    echo "  ssh     - Enable SSH"
    echo "  spi     - Enable SPI"
    echo "  i2c     - Enable I2C"
    echo "  serial  - Enable Serial"
    echo "  1wire   - Enable 1-Wire"
    echo "  all     - Configure all interfaces (default)"
    echo "  help    - Display this help message"
}

# Main script execution
main() {
    # Determine action
    local action="${1:-all}"

    case "$action" in
        "ssh")
            check_raspberry_pi && enable_ssh
            ;;
        "spi")
            check_raspberry_pi && enable_spi
            ;;
        "i2c")
            check_raspberry_pi && enable_i2c
            ;;
        "serial")
            check_raspberry_pi && enable_serial
            ;;
        "1wire")
            check_raspberry_pi && enable_1wire
            ;;
        "all")
            configure_raspberry_pi
            ;;
        "help")
            display_help
            ;;
        *)
            log "ERROR" "Invalid option"
            display_help
            return 1
            ;;
    esac
}

# Run main with all arguments
main "$@"