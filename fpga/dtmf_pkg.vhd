library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package dtmf_pkg is
    -- System Clock Frequency (Standard AX309)
    constant CLK_FREQ : integer := 50_000_000;
    
    -- Phase Accumulator Width
    constant PH_ACC_WIDTH : integer := 32;
    
    -- DTMF Frequencies (Hz)
    type freq_array_t is array (0 to 3) of integer;
    constant ROW_FREQS : freq_array_t := (697, 770, 852, 941);
    constant COL_FREQS : freq_array_t := (1209, 1336, 1477, 1633);
    
    -- Calculate Phase Increment: Inc = (Fout * 2^PH_ACC_WIDTH) / Fclk
    function calc_phase_inc(freq : integer) return integer;
    
end package dtmf_pkg;

package body dtmf_pkg is
    function calc_phase_inc(freq : integer) return integer is
        variable num : unsigned(127 downto 0);
    begin
        -- Helper to calculate accurate increment
        -- Multiply two 64-bit numbers results in 128-bit number
        num := to_unsigned(freq, 64) * shift_left(to_unsigned(1, 64), PH_ACC_WIDTH);
        return to_integer(num / CLK_FREQ);
    end function;
end package body dtmf_pkg;
