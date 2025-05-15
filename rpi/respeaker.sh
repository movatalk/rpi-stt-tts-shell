#!/bin/bash

echo "=== ReSpeaker Voice Assistant Setup for Pi Zero 2 - Updated ==="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

# 1. Backup config file
echo "Step 1: Backing up config file..."
CONFIG_PATH="/boot/firmware/config.txt"
if [ -f "$CONFIG_PATH" ]; then
  cp "$CONFIG_PATH" "$CONFIG_PATH.backup"
  echo "Backed up config to $CONFIG_PATH.backup"
else
  echo "Error: $CONFIG_PATH not found. Please check your boot configuration."
  exit 1
fi

# 2. Add or update ReSpeaker configuration in config.txt
echo "Step 2: Updating boot configuration..."
if ! grep -q "dtparam=i2s=on" "$CONFIG_PATH"; then
  echo "dtparam=i2s=on" >> "$CONFIG_PATH"
  echo "Added i2s parameter to config"
fi

# Configure for ReSpeaker 2-mic or 4-mic
echo "Which ReSpeaker device are you using?"
echo "1) ReSpeaker 2-Mic Pi HAT"
echo "2) ReSpeaker 4-Mic Array"
echo "3) ReSpeaker USB Microphone"
echo "4) Other USB Microphone"
read -p "Enter choice [1-4]: " respeaker_choice

if [ "$respeaker_choice" == "1" ]; then
  # ReSpeaker 2-Mic Pi HAT
  if ! grep -q "dtoverlay=seeed-2mic-voicecard" "$CONFIG_PATH"; then
    echo "dtoverlay=seeed-2mic-voicecard" >> "$CONFIG_PATH"
    echo "Added ReSpeaker 2-mic overlay to config"
  fi
elif [ "$respeaker_choice" == "2" ]; then
  # ReSpeaker 4-Mic Array
  if ! grep -q "dtoverlay=seeed-4mic-voicecard" "$CONFIG_PATH"; then
    echo "dtoverlay=seeed-4mic-voicecard" >> "$CONFIG_PATH"
    echo "Added ReSpeaker 4-mic overlay to config"
  fi
elif [ "$respeaker_choice" == "3" ] || [ "$respeaker_choice" == "4" ]; then
  # USB microphone - no overlay needed
  echo "No specific overlay needed for USB microphone"
else
  echo "Invalid choice. Please run the script again."
  exit 1
fi

# 3. Install USB sound drivers if using USB microphone
if [ "$respeaker_choice" == "3" ] || [ "$respeaker_choice" == "4" ]; then
  echo "Step 3: Installing USB audio support..."
  apt-get update
  apt-get install -y --no-install-recommends \
    alsa-utils \
    pulseaudio \
    pulseaudio-utils
fi

# 4. Configure ALSA for the appropriate device
echo "Step 4: Configuring ALSA..."

if [ "$respeaker_choice" == "1" ]; then
  # ReSpeaker 2-mic Pi HAT configuration
  cat > /etc/asound.conf << 'EOF'
pcm.!default {
  type asym
  capture.pcm "mic"
  playback.pcm "speaker"
}

pcm.mic {
  type plug
  slave {
    pcm "hw:seeed2micvoicec"
    channels 1
  }
}

pcm.speaker {
  type plug
  slave {
    pcm "hw:0"
  }
}
EOF
  echo "Created asound.conf for ReSpeaker 2-mic"

elif [ "$respeaker_choice" == "2" ]; then
  # ReSpeaker 4-mic Array configuration
  cat > /etc/asound.conf << 'EOF'
pcm.!default {
  type asym
  capture.pcm "mic"
  playback.pcm "speaker"
}

pcm.mic {
  type plug
  slave {
    pcm "hw:seeed4micvoicec"
    channels 1
  }
}

pcm.speaker {
  type plug
  slave {
    pcm "hw:0"
  }
}
EOF
  echo "Created asound.conf for ReSpeaker 4-mic"

elif [ "$respeaker_choice" == "3" ] || [ "$respeaker_choice" == "4" ]; then
  # USB microphone configuration - we'll need to find the card
  cat > /etc/asound.conf << 'EOF'
pcm.!default {
  type asym
  capture.pcm "mic"
  playback.pcm "speaker"
}

pcm.mic {
  type plug
  slave {
    pcm "hw:1,0"  # USB audio typically shows up as card 1, device 0
    channels 1
  }
}

pcm.speaker {
  type plug
  slave {
    pcm "hw:0"  # Built-in audio
  }
}
EOF
  echo "Created asound.conf for USB microphone"
fi

# 5. Create a simple test script
echo "Step 5: Creating test script..."
cat > ~//test_audio.py << 'EOF'
#!/usr/bin/env python3
import os
import pyaudio
import wave
import time
import subprocess

# Configuration
FORMAT = pyaudio.paInt16
CHANNELS = 1
RATE = 16000
CHUNK = 1024
RECORD_SECONDS = 5
WAVE_OUTPUT_FILENAME = "test_recording.wav"

def test_audio_devices():
    """List all audio devices and record from first input device"""
    # List all audio devices
    print("\n=== Audio Device Information ===")
    print("ALSA devices:")
    os.system("arecord -l")
    print("\nPulseAudio devices:")
    os.system("pactl list sources 2>/dev/null || echo 'PulseAudio not installed'")

    # Initialize PyAudio
    audio = pyaudio.PyAudio()

    # Print detailed device info
    print("\n=== PyAudio Device Information ===")
    for i in range(audio.get_device_count()):
        try:
            dev_info = audio.get_device_info_by_index(i)
            print(f"Device {i}: {dev_info['name']}")
            print(f"  Input channels: {dev_info['maxInputChannels']}")
            print(f"  Output channels: {dev_info['maxOutputChannels']}")
            print(f"  Default Sample Rate: {dev_info['defaultSampleRate']}")
        except Exception as e:
            print(f"Error getting device {i} info: {e}")

    # Find first input device
    input_device = None
    for i in range(audio.get_device_count()):
        try:
            if audio.get_device_info_by_index(i)['maxInputChannels'] > 0:
                input_device = i
                print(f"\nSelected input device {i}: {audio.get_device_info_by_index(i)['name']}")
                break
        except:
            pass

    if input_device is None:
        print("ERROR: No input device found!")
        audio.terminate()
        return False

    # Record audio
    try:
        print(f"\nRecording {RECORD_SECONDS} seconds of audio...")
        stream = audio.open(
            format=FORMAT,
            channels=CHANNELS,
            rate=RATE,
            input=True,
            input_device_index=input_device,
            frames_per_buffer=CHUNK
        )

        frames = []
        for i in range(0, int(RATE / CHUNK * RECORD_SECONDS)):
            data = stream.read(CHUNK, exception_on_overflow=False)
            frames.append(data)
            # Print progress
            if i % 10 == 0:
                print(".", end="", flush=True)

        print("\nFinished recording")

        # Clean up
        stream.stop_stream()
        stream.close()

        # Save recording
        wf = wave.open(WAVE_OUTPUT_FILENAME, 'wb')
        wf.setnchannels(CHANNELS)
        wf.setsampwidth(audio.get_sample_size(FORMAT))
        wf.setframerate(RATE)
        wf.writeframes(b''.join(frames))
        wf.close()

        audio.terminate()

        print(f"Saved recording to {WAVE_OUTPUT_FILENAME}")
        print("Playing back recording...")
        subprocess.run(["aplay", WAVE_OUTPUT_FILENAME])

        return True
    except Exception as e:
        print(f"Error: {e}")
        audio.terminate()
        return False

def test_tts():
    """Test text-to-speech functionality"""
    print("\n=== Testing Text-to-Speech ===")
    try:
        text = "This is a test of the speech system."
        print(f"Speaking: '{text}'")
        subprocess.run(["espeak-ng", "-s", "150", text])
        return True
    except Exception as e:
        print(f"Error testing TTS: {e}")
        return False

if __name__ == "__main__":
    print("=== Audio Testing Utility ===")
    print("This script will help diagnose audio input/output issues")

    audio_result = test_audio_devices()
    tts_result = test_tts()

    print("\n=== Test Results ===")
    print(f"Audio recording/playback: {'SUCCESS' if audio_result else 'FAILED'}")
    print(f"Text-to-speech: {'SUCCESS' if tts_result else 'FAILED'}")

    if not audio_result:
        print("\nTroubleshooting tips for audio recording:")
        print("1. Check if your microphone is properly connected")
        print("2. Make sure the correct sound card is set in /etc/asound.conf")
        print("3. Try adjusting recording volume with 'alsamixer'")
        print("4. For USB microphones, try a different USB port")
        print("5. Add your user to the 'audio' group: sudo usermod -a -G audio tom")

    if not tts_result:
        print("\nTroubleshooting tips for speech output:")
        print("1. Make sure espeak-ng is installed: sudo apt install espeak-ng")
        print("2. Check if audio output is working with: aplay /usr/share/sounds/alsa/*")
        print("3. Try setting a different audio output device")
EOF

# Make the test script executable and set ownership
chmod +x ~//test_audio.py
chown tom:tom ~//test_audio.py

# 6. Restart sound system
echo "Step 6: Restarting sound system..."
systemctl --user restart pulseaudio 2>/dev/null || true
alsactl kill rescan

# 7. Final instructions
echo -e "\n=== Setup Complete! ==="
echo "A reboot is strongly recommended now. After rebooting:"
echo "1. Connect your microphone (if using USB microphone)"
echo "2. Run the test script: python3 ~//test_audio.py"
echo "3. If the test is successful, try the voice assistant"
echo ""
echo "If you're using a ReSpeaker HAT, make sure it's properly connected to the GPIO pins"
echo "If you're using a USB microphone, make sure it's properly plugged in"
echo ""
echo "Would you like to reboot now? (y/n)"
read -p "> " reboot_choice
if [ "$reboot_choice" == "y" ] || [ "$reboot_choice" == "Y" ]; then
  echo "Rebooting in 5 seconds..."
  sleep 5
  reboot
else
  echo "Please remember to reboot manually to apply all changes."
fi