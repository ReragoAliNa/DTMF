import sys
import os
import time
import requests
import numpy as np
import sounddevice as sd

# Add project root to path to import src.core
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from src.core import dsp, config

# Configuration
JAVA_API_URL = "http://localhost:8081/api/dtmf/phone/press"
SAMPLE_RATE = config.fs  # 8000Hz
BLOCK_DURATION = 0.1     # 100ms analysis window
BLOCK_SIZE = int(SAMPLE_RATE * BLOCK_DURATION)

class DtmfBridge:
    def __init__(self):
        self.last_key = None
        self.consecutive_silence = 0
        self.is_pressed = False

    def process_block(self, indata, frames, time_info, status):
        """Callback for sounddevice input stream"""
        if status:
            print(f"Status: {status}")
            
        # Extract mono signal
        sig = indata[:, 0]
        
        # Use existing DSP logic to identify key
        # require_valid=True is crucial to avoid noise triggers
        detected_key = dsp.identify_key(sig, use_filter=True, require_valid=True)
        
        if detected_key:
            self.consecutive_silence = 0
            
            # Simple state machine to debounce
            if not self.is_pressed or (detected_key != self.last_key):
                print(f"   [Hardware Event] Detected Key: {detected_key} !!!")
                self.send_to_java(detected_key)
                self.is_pressed = True
                self.last_key = detected_key
        else:
            # Only reset state after enough silence (e.g., 2 blocks = 200ms)
            self.consecutive_silence += 1
            if self.consecutive_silence > 1:
                self.is_pressed = False
                self.last_key = None

    def send_to_java(self, key):
        """Send the detected key to the Java Backend"""
        try:
            # We use the existing 'press' endpoint which simulates/logs a key press
            payload = {
                'key': key,
                'duration': 0.2,
                'snr': 100 # High SNR because it's "real" (or at least detected as clear)
            }
            resp = requests.post(JAVA_API_URL, params=payload)
            if resp.status_code == 200:
                print(f"   -> Sent to Java: Success")
            else:
                print(f"   -> Sent to Java: Failed ({resp.status_code})")
        except Exception as e:
            print(f"   -> Sent to Java: Error connection refused (Is Java app running?)")

    def run(self):
        print(f"=== FPGA-Java Audio Bridge ===")
        print(f"1. Listening on default microphone at {SAMPLE_RATE}Hz")
        print(f"2. Analyzing blocks of {BLOCK_DURATION}s")
        print(f"3. Forwarding detected DTMF tones to {JAVA_API_URL}")
        print("-------------------------------------------------------")
        print("Please place your FPGA buzzer near the microphone...")
        print("Press Ctrl+C to stop.")

        try:
            with sd.InputStream(channels=1, samplerate=SAMPLE_RATE, blocksize=BLOCK_SIZE, callback=self.process_block):
                while True:
                    time.sleep(1)
        except KeyboardInterrupt:
            print("\nStopping...")
        except Exception as e:
            print(f"\nError: {e}")
            print("\nHint: You may need to install audio drivers or libraries:")
            print("pip install sounddevice numpy requests scipy")

if __name__ == "__main__":
    bridge = DtmfBridge()
    bridge.run()
