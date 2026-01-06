#!/bin/bash

# Define colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Starting GHDL Simulation...${NC}"

# Check for GHDL
if ! command -v ghdl &> /dev/null; then
    echo -e "${RED}Error: ghdl is not installed.${NC}"
    echo "Please install it via: brew install ghdl"
    exit 1
fi

# Check for GTKWave (optional but recommended for viewing)
if ! command -v gtkwave &> /dev/null; then
    echo -e "${RED}Warning: gtkwave is not installed.${NC}"
    echo "You will generate the VCD file but cannot view it automatically."
    echo "Install via: brew install --cask gtkwave"
fi

# Navigate to fpga directory
cd fpga || exit

# Clean previous build
echo "Cleaning..."
rm -f *.o *.cf *.vcd

# Analysis (Compile)
echo "Compiling VHDL files..."
ghdl -a --std=08 dtmf_pkg.vhd
ghdl -a --std=08 sine_lut.vhd
ghdl -a --std=08 dtmf_generator.vhd
ghdl -a --std=08 dtmf_tb.vhd

# Elaboration (Link)
echo "Elaborating..."
ghdl -e --std=08 dtmf_tb

# Run Simulation
echo "Running Simulation..."
ghdl -r --std=08 dtmf_tb --vcd=waveform.vcd --stop-time=5ms

# Check if VCD was created
if [ -f "waveform.vcd" ]; then
    echo -e "${GREEN}Simulation Successful! Waveform saved to fpga/waveform.vcd${NC}"
    
    # Open GTKWave if available
    if command -v gtkwave &> /dev/null; then
        echo "Opening GTKWave..."
        gtkwave waveform.vcd &
    else
        echo "Please install GTKWave to view 'waveform.vcd'."
    fi
else
    echo -e "${RED}Simulation Failed. No VCD file generated.${NC}"
fi
