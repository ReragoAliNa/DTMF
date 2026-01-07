#!/bin/bash

# VHDL Simulation Script for GHDL + GTKWave
# Exit on error
set -e

WORK_DIR="sim_build"
mkdir -p $WORK_DIR

echo "--- [1/3] Analyzing VHDL files ---"
# 1. Package must be first
ghdl -a --std=08 --workdir=$WORK_DIR fpga/dtmf_pkg.vhd
# 2. Components
ghdl -a --std=08 --workdir=$WORK_DIR fpga/sine_lut.vhd
ghdl -a --std=08 --workdir=$WORK_DIR fpga/dtmf_generator.vhd
ghdl -a --std=08 --workdir=$WORK_DIR fpga/pwm_audio.vhd
ghdl -a --std=08 --workdir=$WORK_DIR fpga/key_debounce.vhd
ghdl -a --std=08 --workdir=$WORK_DIR fpga/uart_tx.vhd
ghdl -a --std=08 --workdir=$WORK_DIR fpga/ax309_top.vhd
# 3. Testbenches
ghdl -a --std=08 --workdir=$WORK_DIR fpga/dtmf_tb.vhd
ghdl -a --std=08 --workdir=$WORK_DIR fpga/dataset_tb.vhd

echo "--- [2/3] Elaborating testbenches ---"
ghdl -e --std=08 --workdir=$WORK_DIR dtmf_tb
ghdl -e --std=08 --workdir=$WORK_DIR dataset_tb

echo "--- [3/3] Running simulations ---"
# 1. Run Algorithm Simulation (dtmf_tb)
echo "   > Running dtmf_tb..."
ghdl -r --std=08 --workdir=$WORK_DIR dtmf_tb --stop-time=5ms --wave=dtmf_wave.ghw

# 2. Run System Integration Simulation (dataset_tb)
echo "   > Running dataset_tb..."
# dataset_tb involves 20ms debounce, so we simulate for 40ms
ghdl -r --std=08 --workdir=$WORK_DIR dataset_tb --stop-time=40ms --wave=top_wave.ghw

echo ""
echo "=========================================================="
echo "SUCCESS: Both simulations finished."
echo "1. Algorithm Waveform:  gtkwave dtmf_wave.ghw"
echo "2. System/PWM Waveform: gtkwave top_wave.ghw"
echo "=========================================================="
