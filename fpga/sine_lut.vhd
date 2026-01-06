library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sine_lut is
    port (
        clk  : in  std_logic;
        addr : in  std_logic_vector(7 downto 0); -- 256 samples
        data : out signed(15 downto 0)           -- 16-bit output
    );
end sine_lut;

architecture Behavioral of sine_lut is
    type rom_type is array (0 to 255) of signed(15 downto 0);
    
    -- Pre-calculated Sine Wave (Amplitude +/- 32000 approx)
    -- Generated for full cycle 0 to 2*PI
    constant SINE_ROM : rom_type := (
        to_signed(0, 16), to_signed(804, 16), to_signed(1607, 16), to_signed(2410, 16), 
        to_signed(3211, 16), to_signed(4011, 16), to_signed(4807, 16), to_signed(5601, 16), 
        to_signed(6392, 16), to_signed(7179, 16), to_signed(7961, 16), to_signed(8739, 16), 
        to_signed(9511, 16), to_signed(10278, 16), to_signed(11038, 16), to_signed(11792, 16), 
        to_signed(12539, 16), to_signed(13278, 16), to_signed(14009, 16), to_signed(14732, 16), 
        to_signed(15446, 16), to_signed(16150, 16), to_signed(16845, 16), to_signed(17530, 16), 
        to_signed(18204, 16), to_signed(18867, 16), to_signed(19519, 16), to_signed(20159, 16), 
        to_signed(20787, 16), to_signed(21402, 16), to_signed(22004, 16), to_signed(22594, 16), 
        to_signed(23169, 16), to_signed(23731, 16), to_signed(24278, 16), to_signed(24811, 16), 
        to_signed(25329, 16), to_signed(25831, 16), to_signed(26318, 16), to_signed(26789, 16), 
        to_signed(27244, 16), to_signed(27683, 16), to_signed(28105, 16), to_signed(28510, 16), 
        to_signed(28897, 16), to_signed(29268, 16), to_signed(29621, 16), to_signed(29955, 16), 
        to_signed(30272, 16), to_signed(30571, 16), to_signed(30851, 16), to_signed(31113, 16), 
        to_signed(31356, 16), to_signed(31580, 16), to_signed(31785, 16), to_signed(31970, 16), 
        to_signed(32137, 16), to_signed(32284, 16), to_signed(32412, 16), to_signed(32520, 16), 
        to_signed(32609, 16), to_signed(32678, 16), to_signed(32727, 16), to_signed(32757, 16), 
        to_signed(32767, 16), to_signed(32757, 16), to_signed(32727, 16), to_signed(32678, 16), 
        to_signed(32609, 16), to_signed(32520, 16), to_signed(32412, 16), to_signed(32284, 16), 
        to_signed(32137, 16), to_signed(31970, 16), to_signed(31785, 16), to_signed(31580, 16), 
        to_signed(31356, 16), to_signed(31113, 16), to_signed(30851, 16), to_signed(30571, 16), 
        to_signed(30272, 16), to_signed(29955, 16), to_signed(29621, 16), to_signed(29268, 16), 
        to_signed(28897, 16), to_signed(28510, 16), to_signed(28105, 16), to_signed(27683, 16), 
        to_signed(27244, 16), to_signed(26789, 16), to_signed(26318, 16), to_signed(25831, 16), 
        to_signed(25329, 16), to_signed(24811, 16), to_signed(24278, 16), to_signed(23731, 16), 
        to_signed(23169, 16), to_signed(22594, 16), to_signed(22004, 16), to_signed(21402, 16), 
        to_signed(20787, 16), to_signed(20159, 16), to_signed(19519, 16), to_signed(18867, 16), 
        to_signed(18204, 16), to_signed(17530, 16), to_signed(16845, 16), to_signed(16150, 16), 
        to_signed(15446, 16), to_signed(14732, 16), to_signed(14009, 16), to_signed(13278, 16), 
        to_signed(12539, 16), to_signed(11792, 16), to_signed(11038, 16), to_signed(10278, 16), 
        to_signed(9511, 16), to_signed(8739, 16), to_signed(7961, 16), to_signed(7179, 16), 
        to_signed(6392, 16), to_signed(5601, 16), to_signed(4807, 16), to_signed(4011, 16), 
        to_signed(3211, 16), to_signed(2410, 16), to_signed(1607, 16), to_signed(804, 16), 
        to_signed(0, 16), to_signed(-804, 16), to_signed(-1607, 16), to_signed(-2410, 16), 
        to_signed(-3211, 16), to_signed(-4011, 16), to_signed(-4807, 16), to_signed(-5601, 16), 
        to_signed(-6392, 16), to_signed(-7179, 16), to_signed(-7961, 16), to_signed(-8739, 16), 
        to_signed(-9511, 16), to_signed(-10278, 16), to_signed(-11038, 16), to_signed(-11792, 16), 
        to_signed(-12539, 16), to_signed(-13278, 16), to_signed(-14009, 16), to_signed(-14732, 16), 
        to_signed(-15446, 16), to_signed(-16150, 16), to_signed(-16845, 16), to_signed(-17530, 16), 
        to_signed(-18204, 16), to_signed(-18867, 16), to_signed(-19519, 16), to_signed(-20159, 16), 
        to_signed(-20787, 16), to_signed(-21402, 16), to_signed(-22004, 16), to_signed(-22594, 16), 
        to_signed(-23169, 16), to_signed(-23731, 16), to_signed(-24278, 16), to_signed(-24811, 16), 
        to_signed(-25329, 16), to_signed(-25831, 16), to_signed(-26318, 16), to_signed(-26789, 16), 
        to_signed(-27244, 16), to_signed(-27683, 16), to_signed(-28105, 16), to_signed(-28510, 16), 
        to_signed(-28897, 16), to_signed(-29268, 16), to_signed(-29621, 16), to_signed(-29955, 16), 
        to_signed(-30272, 16), to_signed(-30571, 16), to_signed(-30851, 16), to_signed(-31113, 16), 
        to_signed(-31356, 16), to_signed(-31580, 16), to_signed(-31785, 16), to_signed(-31970, 16), 
        to_signed(-32137, 16), to_signed(-32284, 16), to_signed(-32412, 16), to_signed(-32520, 16), 
        to_signed(-32609, 16), to_signed(-32678, 16), to_signed(-32727, 16), to_signed(-32757, 16), 
        to_signed(-32767, 16), to_signed(-32757, 16), to_signed(-32727, 16), to_signed(-32678, 16), 
        to_signed(-32609, 16), to_signed(-32520, 16), to_signed(-32412, 16), to_signed(-32284, 16), 
        to_signed(-32137, 16), to_signed(-31970, 16), to_signed(-31785, 16), to_signed(-31580, 16), 
        to_signed(-31356, 16), to_signed(-31113, 16), to_signed(-30851, 16), to_signed(-30571, 16), 
        to_signed(-30272, 16), to_signed(-29955, 16), to_signed(-29621, 16), to_signed(-29268, 16), 
        to_signed(-28897, 16), to_signed(-28510, 16), to_signed(-28105, 16), to_signed(-27683, 16), 
        to_signed(-27244, 16), to_signed(-26789, 16), to_signed(-26318, 16), to_signed(-25831, 16), 
        to_signed(-25329, 16), to_signed(-24811, 16), to_signed(-24278, 16), to_signed(-23731, 16), 
        to_signed(-23169, 16), to_signed(-22594, 16), to_signed(-22004, 16), to_signed(-21402, 16), 
        to_signed(-20787, 16), to_signed(-20159, 16), to_signed(-19519, 16), to_signed(-18867, 16), 
        to_signed(-18204, 16), to_signed(-17530, 16), to_signed(-16845, 16), to_signed(-16150, 16), 
        to_signed(-15446, 16), to_signed(-14732, 16), to_signed(-14009, 16), to_signed(-13278, 16), 
        to_signed(-12539, 16), to_signed(-11792, 16), to_signed(-11038, 16), to_signed(-10278, 16), 
        to_signed(-9511, 16), to_signed(-8739, 16), to_signed(-7961, 16), to_signed(-7179, 16), 
        to_signed(-6392, 16), to_signed(-5601, 16), to_signed(-4807, 16), to_signed(-4011, 16), 
        to_signed(-3211, 16), to_signed(-2410, 16), to_signed(-1607, 16), to_signed(-804, 16)
    );

begin
    process(clk)
    begin
        if rising_edge(clk) then
            data <= SINE_ROM(to_integer(unsigned(addr)));
        end if;
    end process;
end Behavioral;
