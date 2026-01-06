# FPGA VHDL DTMF Project

This directory contains the VHDL source code for implementing a DTMF Generator on the AX309 (Xilinx Spartan-6) FPGA board.

## Directory Structure

*   `dtmf_pkg.vhd`: Package defining DTMF frequencies and constants.
*   `sine_lut.vhd`: Sine wave Look-Up Table (256 samples).
*   `dtmf_generator.vhd`: Core logic to synthesize dual tones using DDS (Direct Digital Synthesis).
*   `pwm_audio.vhd`: 10-bit PWM generator for audio output.
*   `key_debounce.vhd`: Button debouncing logic.
*   `seg_display.vhd`: **NEW** 7-Segment Display driver (Visual feedback for key presses).
*   `ax309_top.vhd`: Top-level entity integrating DTMF generation, Audio PWM, and visual displays.
*   `ax309.ucf`: Constraints file (Pin assigments - **Verified for AX309**).

*(Testbenches `dataset_tb.vhd` and `dtmf_tb.vhd` are provided for simulation)*

## How to use with Xilinx ISE 14.7

1.  **Create Project**: Open ISE, create a new project targeting `XC6SLX9-2FTG256` (Spartan-6).
2.  **Add Source**: Add all `.vhd` files from this directory to the project.
3.  **Add Constraints**: Add `ax309.ucf`.
4.  **Set Top Module**: Right-click `ax309_top` and select **Set as Top Module**.
5.  **Verify Pins**: The `ax309.ucf` is pre-configured for the AX309 peripherals:
    *   **Clock**: T8 (50MHz)
    *   **Reset**: L3 (RST key), Active Low.
    *   **Keys**: C3, D3, E4, E3 (Keys 1-4)
    *   **LEDs**: P4, N5, P5, M6 (Confirm key press)
    *   **Audio**: J11 (Onboard Buzzer) - **No external circuit needed!**
    *   **7-Segment**: C7..C6 (Data), D9..D8 (Sel) - Displays Key Number.
6.  **Synthesize & Generate Bitstream**: Run the flow.
7.  **Program**: Use iMPACT or Alinx tool to download `ax309_top.bit` to the board.

## Functional Description

*   **Key 1** (C3) -> Generates DTMF Tone '1', LED1 Lights, Segment displays '1'
*   **Key 2** (D3) -> Generates DTMF Tone '2', LED2 Lights, Segment displays '2'
*   **Key 3** (E4) -> Generates DTMF Tone '3', LED3 Lights, Segment displays '3'
*   **Key 4** (E3) -> Generates DTMF Tone '4', LED4 Lights, Segment displays '4'

The onboard buzzer (J11) will emit the distinct dual-tone sounds for each key, while the 7-segment display provides immediate visual confirmation of the pressed digit.
