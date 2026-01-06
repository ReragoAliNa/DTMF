library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.dtmf_pkg.ALL;

entity dataset_tb is
end dataset_tb;

architecture Behavioral of dataset_tb is

    -- Component Declaration for the Unit Under Test (UUT)
    COMPONENT ax309_top
    PORT(
         sys_clk : IN  std_logic;
         rst_n_key : IN  std_logic;
         key_in : IN  std_logic_vector(3 downto 0);
         led_out : OUT  std_logic_vector(3 downto 0);
         audio_pwm : OUT  std_logic
        );
    END COMPONENT;
    

    -- Inputs
    signal sys_clk : std_logic := '0';
    signal rst_n_key : std_logic := '0';
    signal key_in : std_logic_vector(3 downto 0) := (others => '1'); -- Active low

    -- Outputs
    signal led_out : std_logic_vector(3 downto 0);
    signal audio_pwm : std_logic;

    -- Clock period definitions
    constant sys_clk_period : time := 20 ns; -- 50MHz
 
BEGIN
 
    -- Instantiate the Unit Under Test (UUT)
    uut: ax309_top PORT MAP (
          sys_clk => sys_clk,
          rst_n_key => rst_n_key,
          key_in => key_in,
          led_out => led_out,
          audio_pwm => audio_pwm
        );

    -- Clock process definitions
    sys_clk_process :process
    begin
        sys_clk <= '0';
        wait for sys_clk_period/2;
        sys_clk <= '1';
        wait for sys_clk_period/2;
    end process;
 

    -- Stimulus process
    stim_proc: process
    begin       
        -- hold reset state for 100 ns.
        rst_n_key <= '0';
        wait for 100 ns;    
        rst_n_key <= '1';
        wait for sys_clk_period*10;

        -- Test Case 1: Press Key 0 (Tone '1')
        report "Pressing Key 0 (Tone 1)";
        key_in <= "1110"; -- Key 0 pressed
        wait for 20 ms; -- Wait for debounce (20ms) + some tone generation
        wait for 10 ms;
        
        -- Release
        key_in <= "1111";
        wait for 10 ms;

        -- Test Case 2: Press Key 3 (Tone '4')
        report "Pressing Key 3 (Tone 4)";
        key_in <= "0111"; 
        wait for 30 ms;
        
        key_in <= "1111";
        
        -- End Simulation
        wait;
    end process;

END;
