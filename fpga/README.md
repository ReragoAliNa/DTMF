# FPGA VHDL DTMF Project

This directory contains the VHDL source code for implementing a DTMF Generator on the AX309 (Xilinx Spartan-6) FPGA board.

## Directory Structure

*   `dtmf_pkg.vhd`: Package defining DTMF frequencies and constants.
*   `sine_lut.vhd`: Sine wave Look-Up Table (256 samples).
*   `dtmf_generator.vhd`: Core logic to synthesize dual tones using DDS (Direct Digital Synthesis).
*   `pwm_audio.vhd`: 10-bit PWM generator for audio output.
*   `key_debounce.vhd`: Button debouncing logic.
*   `ax309_top.vhd`: Top-level entity mapping keys to tones.
*   `ax309.ucf`: Constraints file (Pin assigments - **Verified for AX309**).
*   `dataset_tb.vhd`: Testbench for simulation.

## How to use with Xilinx ISE 14.7

1.  **Create Project**: Open ISE, create a new project targeting `XC6SLX9-2FTG256` (Spartan-6).
2.  **Add Source**: Add all `.vhd` files from this directory.
3.  **Add Constraints**: Add `ax309.ucf`.
4.  **Verify Pins**: The `ax309.ucf` is now pre-configured for the onboard peripherals:
    *   **Clock**: T8 (50MHz)
    *   **Reset**: L3 (RST key)
    *   **Keys**: C3, D3, E4, E3
    *   **LEDs**: P4, N5, P5, M6
    *   **Audio**: J11 (Onboard Buzzer) - **No external circuit needed!**
5.  **Synthesize & Generate Bitstream**: Run the flow.
6.  **Program**: Use impact or Alinx tool to download `ax309_top.bit` to the board.

## Functional Description

*   **Key 1** (C3) -> Generates DTMF Tone '1'
*   **Key 2** (D3) -> Generates DTMF Tone '2'
*   **Key 3** (E4) -> Generates DTMF Tone '3'
*   **Key 4** (E3) -> Generates DTMF Tone '4'

The onboard buzzer (J11) will emit the generated tones. You will hear the distinct dual-tone sounds for each key.
