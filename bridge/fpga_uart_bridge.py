import serial
import serial.tools.list_ports
import time
import requests
import threading
import numpy as np
import collections

# Using Flask-SocketIO to push data to frontend if needed, 
# or just forwarding analysis results to Java.
# For simplicity, this acts as a Smart Processor:
# 1. Reads Serial
# 2. Buffers Audio
# 3. Detects Tone (using dsp.py)
# 4. Sends "Press Event" to Java

import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from src.core import dsp, config

# Config
BAUD_RATE = 115200
SAMPLE_RATE = 8000
BLOCK_SIZE = 800  # 100ms
serial_buffer = collections.deque(maxlen=SAMPLE_RATE * 2) # 2 sec buffer

JAVA_URL = "http://localhost:8081/api/dtmf/phone/press"

def find_fpga_port():
    """Auto-detect USB Serial Port (CP210x usually)"""
    ports = list(serial.tools.list_ports.comports())
    for p in ports:
        if "CP210" in p.description or "USB to UART" in p.description:
            return p.device
    # Fallback
    if len(ports) > 0:
        return ports[0].device
    return None

def process_audio_stream(port_name):
    print(f"Connecting to FPGA on {port_name}...")
    try:
        ser = serial.Serial(port_name, BAUD_RATE, timeout=0.1)
    except Exception as e:
        print(f"Error opening serial: {e}")
        return

    print("Listening for waveforms...")
    
    print("   [Info] Creating buffer, waiting for stream stabilization...")
    current_block = []
    last_key = None
    silence_cnt = 0
    
    # 忽略启动后前 1 秒的数据，等待 FPGA 和串口稳定
    # Ignore startup transient noise
    start_time = time.time()
    stabilized = False

    
    while True:
        # Read byte
        if ser.in_waiting:
            chunk = ser.read(ser.in_waiting)
            # Convert unsigned byte (0-255) to float (-1.0 to 1.0)
            # FPGA sends: (audio >> 8) + 128
            # Restore roughly: (val - 128) / 128.0
            # Debug data flow
            # if len(chunk) > 0:
            #      print(f".", end="", flush=True)

            for b in chunk:
                val = (float(b) - 128.0) / 128.0
                current_block.append(val)
            # FORCE DEBUG: Print raw chunk size if > 0
            # print(f"[Debug] Rx {len(chunk)} bytes")
        
        # Process block
        if len(current_block) >= BLOCK_SIZE:
            # Check for stabilization
            if not stabilized:
                if time.time() - start_time < 1.0:
                    current_block = [] # Discard data during stabilization
                    continue
                else:
                    stabilized = True
                    print("   [Info] Stream stabilized. Ready for events.")

            # Analyze
            sig = np.array(current_block)
            key = dsp.identify_key(sig, use_filter=True, require_valid=True)
            
            if key:
                silence_cnt = 0
                if last_key != key:
                    print(f"   [UART Event] Detected Tone: {key}")
                    send_to_java(key, sig)
                    last_key = key
            else:
                silence_cnt += 1
                if silence_cnt > 2: # 200ms silence
                    last_key = None
            
            # Slide buffer (Overlap?)
            # For simplicity, just reset
            current_block = [] # Non-overlapping for now to keep up with speed
            
        time.sleep(0.001)

def send_to_java(key, waveform):
    """Send detected key AND actual waveform to Java for adaptive analysis"""
    try:
        # Send waveform as JSON array (limit to 4000 samples for efficiency)
        waveform_list = waveform[:4000].tolist() if len(waveform) > 4000 else waveform.tolist()
        
        resp = requests.post(
            JAVA_URL, 
            params={'key': key, 'duration': 0.1, 'snr': 0, 'noiseType': 'FPGA_RAW', 'source': 'hardware'},
            json={'waveform': waveform_list}
        )
        print(f"   [Bridge] Sent to Java: {resp.status_code}")
    except Exception as e:
        print(f"   [Bridge] Error sending to Java: {e}")

if __name__ == "__main__":
    port = find_fpga_port()
    if port:
        process_audio_stream(port)
    else:
        print("No serial port found. Check USB connection.")
