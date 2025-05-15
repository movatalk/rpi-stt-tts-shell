#!/bin/bash
# Author: tom-sapletta-com
# Purpose: Installs and configures development tools and libraries for Raspberry Pi development environments.

# Raspberry Pi Development Tools Installer

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
    return 0
}

# Update system
update_system() {
    log "INFO" "Updating system packages..."
    sudo apt-get update
    sudo apt-get upgrade -y
}

# Install development tools
install_dev_tools() {
    log "INFO" "Installing development tools..."

    # Core development tools
    sudo apt-get install -y \
        build-essential \
        git \
        cmake \
        curl \
        wget \
        nano \
        vim \
        htop \
        python3-pip \
        python3-venv

    # Development libraries
    sudo apt-get install -y \
        libssl-dev \
        libffi-dev \
        python3-dev
}

# Install I2C and SPI tools
install_interface_tools() {
    log "INFO" "Installing I2C and SPI tools..."

    # I2C tools
    sudo apt-get install -y \
        i2c-tools \
        libi2c-dev

    # SPI tools
    sudo apt-get install -y \
        spidev \
        python3-spidev

    # 1-Wire tools
    sudo apt-get install -y \
        owfs
}

# Install Python development packages
install_python_tools() {
    log "INFO" "Installing Python development packages..."

    # Upgrade pip
    python3 -m pip install --upgrade pip

    # Common Python development packages
    python3 -m pip install --user \
        numpy \
        pandas \
        RPi.GPIO \
        smbus2 \
        adafruit-blinka
}

# Install monitoring and performance tools
install_monitoring_tools() {
    log "INFO" "Installing monitoring tools..."

    sudo apt-get install -y \
        stress \
        netcat \
        iftop \
        iotop \
        nmap
}

# Setup development environment
setup_dev_environment() {
    # Ensure running as non-root
    if [ "$EUID" -eq 0 ]; then
        log "ERROR" "Do not run this script as root. Use sudo if needed."
        return 1
    fi

    # Check if running on Raspberry Pi
    check_raspberry_pi || return 1

    # Update system first
    update_system

    # Install tools
    install_dev_tools
    install_interface_tools
    install_python_tools
    install_monitoring_tools

    # Final system update
    sudo apt-get Authoremove -y
    sudo apt-get clean

    log "INFO" "Development environment setup complete!"
    log "WARN" "Reboot recommended to apply all changes"
    echo "Suggested reboot command: sudo reboot"
}

# Display help
display_help() {
    echo "Raspberry Pi Development Tools Installer"
    echo "Usage:"
    echo "  $0 [option]"
    echo ""
    echo "Options:"
    echo "  update     - Update system packages"
    echo "  dev        - Install development tools"
    echo "  i2c        - Install I2C and interface tools"
    echo "  python     - Install Python development packages"
    echo "  monitor    - Install monitoring tools"
    echo "  all        - Setup full development environment (default)"
    echo "  help       - Display this help message"
}

# Main script execution
main() {
    # Determine action
    local action="${1:-all}"

    case "$action" in
        "update")
            check_raspberry_pi && update_system
            ;;
        "dev")
            check_raspberry_pi && install_dev_tools
            ;;
        "i2c")
            check_raspberry_pi && install_interface_tools
            ;;
        "python")
            check_raspberry_pi && install_python_tools
            ;;
        "monitor")
            check_raspberry_pi && install_monitoring_tools
            ;;
        "all")
            setup_dev_environment
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