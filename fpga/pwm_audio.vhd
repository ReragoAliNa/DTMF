library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pwm_audio is
    Port ( 
        clk : in  STD_LOGIC;
        rst_n : in  STD_LOGIC;
        pcm_in : in  signed(15 downto 0);
        pwm_out : out  STD_LOGIC
    );
end pwm_audio;

architecture Behavioral of pwm_audio is
    -- 10-bit PWM for ~48kHz carrier at 50MHz clock
    constant PWM_WIDTH : integer := 10;
    signal counter : unsigned(PWM_WIDTH-1 downto 0) := (others => '0');
    signal duty : unsigned(PWM_WIDTH-1 downto 0);
    
begin
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            counter <= (others => '0');
            pwm_out <= '0';
        elsif rising_edge(clk) then
            counter <= counter + 1;
            
            -- Convert signed PCM to unsigned duty cycle
            -- PCM is 16-bit (-32768 to 32767).
            -- We want 10-bit unsigned (0 to 1023).
            -- 1. Flip MSB to make unsigned (0 to 65535)
            -- 2. Take top 10 bits.
            
            -- pcm_in(15) is sign bit.
            -- If pcm_in(15)='0' (positive), we want upper range (e.g. 512 to 1023)
            -- If pcm_in(15)='1' (negative), we want lower range (e.g. 0 to 511)
            -- Actually, simpler: pcm_in + 32768 maps -32768 to 0.
            -- Adding 32768 is equivalent to inverting the toggle bit.
            -- So `unsigned(not pcm_in(15) & pcm_in(14 downto 0))` gives 0..65535
            
            -- Take top 10 bits:
            duty <= unsigned(not pcm_in(15) & pcm_in(14 downto 15-PWM_WIDTH+1));
            
            if counter < duty then
                pwm_out <= '1';
            else
                pwm_out <= '0';
            end if;
        end if;
    end process;

end Behavioral;
