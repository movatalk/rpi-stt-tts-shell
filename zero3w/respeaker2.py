#!/usr/bin/env python3

import sounddevice as sd
import numpy as np
import time


def list_audio_devices():
    """List all available audio input and output devices."""
    print("Input Devices:")
    print(sd.query_devices())

    # Find ReSpeaker specific device
    respeaker_inputs = [
        dev for dev in sd.query_devices()
        if 'ReSpeaker' in str(dev) or 'seeed' in str(dev).lower()
    ]

    if respeaker_inputs:
        print("\nReSpeaker Devices Found:")
        for dev in respeaker_inputs:
            print(dev)
    else:
        print("\nNo ReSpeaker devices detected.")


def record_audio(duration=5, sample_rate=16000):
    """Record audio from ReSpeaker for specified duration."""
    print(f"Recording {duration} seconds of audio...")

    # Try to find ReSpeaker device
    devices = sd.query_devices()
    respeaker_input = None

    for i, device in enumerate(devices):
        if 'ReSpeaker' in str(device) or 'seeed' in str(device).lower():
            respeaker_input = i
            break

    if respeaker_input is None:
        print("No ReSpeaker device found. Using default input.")
        respeaker_input = None

    # Record audio
    recording = sd.rec(
        int(duration * sample_rate),
        samplerate=sample_rate,
        channels=2,  # ReSpeaker 2-Mic typically has 2 channels
        dtype='float32',
        device=respeaker_input
    )
    sd.wait()

    # Save recorded audio
    output_file = f'respeaker_recording_{int(time.time())}.wav'
    sd.write(output_file, recording, sample_rate)
    print(f"Audio saved to {output_file}")


def test_audio_levels():
    """Monitor audio input levels from ReSpeaker."""

    def audio_callback(indata, frames, time, status):
        volume_norm = np.linalg.norm(indata) * 10
        print(f"Volume: {volume_norm}")

    print("Monitoring audio levels. Press Ctrl+C to stop.")
    try:
        with sd.InputStream(callback=audio_callback):
            sd.sleep(10000)  # 10 seconds of monitoring
    except KeyboardInterrupt:
        print("\nAudio level monitoring stopped.")


def main():
    print("ReSpeaker 2-Mic Pi HAT Diagnostic Tool")

    while True:
        print("\nMenu:")
        print("1. List Audio Devices")
        print("2. Record Audio")
        print("3. Monitor Audio Levels")
        print("4. Exit")

        choice = input("Enter your choice (1-4): ")

        if choice == '1':
            list_audio_devices()
        elif choice == '2':
            record_audio()
        elif choice == '3':
            test_audio_levels()
        elif choice == '4':
            break
        else:
            print("Invalid choice. Please try again.")


if __name__ == '__main__':
    main()