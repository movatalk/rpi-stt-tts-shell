#!/bin/bash

# ReSpeaker 2-Mic Pi HAT Setup Script for Radxa ZERO 3W
# Warning: This script is experimental and may require adjustments

# Exit on any error
set -e

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

# Update system packages
echo "Updating system packages..."
apt update && apt upgrade -y

# Install essential development tools
echo "Installing development tools..."
apt install -y \
    git \
    build-essential \
    python3-pip \
    python3-dev \
    raspberrypi-kernel-headers \
    dkms \
    alsa-utils \
    libasound2-dev

# Clone ReSpeaker Linux Kernel Driver
echo "Cloning ReSpeaker Kernel Driver..."
mkdir -p /opt/respeaker
cd /opt/respeaker

git clone https://github.com/respeaker/seeed-linux-dtoverlay.git
cd seeed-linux-dtoverlay

# Prepare Device Tree Overlay
echo "Preparing Device Tree Overlay..."
cp sun8i-h3-i2s0.dtbo /boot/dtbs/rockchip/
cp sun8i-h3-i2s0.dts /boot/dtbs/rockchip/

# Create ReSpeaker Configuration
echo "Creating ReSpeaker Configuration..."
cat << EOF > /etc/asound.conf
pcm.respeaker {
    type hw
    card ReSpeakerPiHAT
}

ctl.respeaker {
    type hw
    card ReSpeakerPiHAT
}

pcm.!default {
    type asym
    playback.pcm {
        type plug
        slave.pcm "respeaker"
    }
    capture.pcm {
        type plug
        slave.pcm "respeaker"
    }
}
EOF

# Install Python Libraries
echo "Installing Python Libraries for ReSpeaker..."
pip3 install \
    setuptools \
    wheel \
    sounddevice \
    numpy \
    pyaudio

# Clone ReSpeaker Python Library
git clone https://github.com/respeaker/usb_4_mic_array.git
cd usb_4_mic_array
python3 setup.py install

# Update Boot Configuration
echo "Updating Boot Configuration..."
# Note: You may need to adjust this based on your specific Radxa device tree
cat << EOF >> /boot/config.txt
# ReSpeaker 2-Mic Pi HAT Configuration
dtoverlay=sun8i-h3-i2s0
audio=on
EOF

# Enable I2C and SPI
raspi-config nonint do_i2c 0
raspi-config nonint do_spi 0

# Test Audio
echo "Testing Audio Configuration..."
arecord -l
aplay -l

# Provide User Instructions
cat << EOF

ReSpeaker 2-Mic Pi HAT Setup Complete!

Next steps:
1. Reboot your system: sudo reboot
2. Verify audio setup:
   - Run 'arecord -l' to list recording devices
   - Run 'aplay -l' to list playback devices
3. Test microphone:
   - Record: arecord -d 5 test.wav
   - Playback: aplay test.wav

Troubleshooting:
- Check /var/log/syslog for any driver-related messages
- Ensure HAT is properly seated on GPIO pins
- Verify kernel module loading with 'lsmod | grep i2s'

EOF

# Optional: Offer to reboot
read -p "Would you like to reboot now? (y/n) " choice
case "$choice" in
    y|Y ) reboot;;
    * ) echo "Please reboot manually when ready.";;
esac