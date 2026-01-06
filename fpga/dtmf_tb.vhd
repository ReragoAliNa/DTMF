library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.dtmf_pkg.ALL;

entity dtmf_tb is
end dtmf_tb;

architecture Behavioral of dtmf_tb is
    -- Component Declaration
    COMPONENT dtmf_generator
    PORT(
        clk : IN  std_logic;
        rst_n : IN  std_logic;
        key_idx : IN  integer range 0 to 15;
        key_valid : IN  std_logic;
        audio_out : OUT signed(15 downto 0)
    );
    END COMPONENT;

    -- Signals
    signal clk : std_logic := '0';
    signal rst_n : std_logic := '0';
    signal key_idx : integer range 0 to 15 := 0;
    signal key_valid : std_logic := '0';
    signal audio_out : signed(15 downto 0);

    -- Clock constant (50MHz)
    constant CLK_PERIOD : time := 20 ns;

begin

    -- Instantiate the UUT
    uut: dtmf_generator PORT MAP (
        clk => clk,
        rst_n => rst_n,
        key_idx => key_idx,
        key_valid => key_valid,
        audio_out => audio_out
    );

    -- Clock generation
    clk_process :process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        -- 1. Reset
        rst_n <= '0';
        wait for 100 ns;
        rst_n <= '1';
        wait for 100 ns;

        -- 2. Test Key '1' (697Hz + 1209Hz)
        -- Key Index 1 corresponds to '1'
        report "Pressing Key '1' (697 + 1209 Hz)";
        key_idx <= 1;
        key_valid <= '1';
        wait for 2 ms; -- Wait enough time to see a few cycles (697Hz period is ~1.4ms)

        -- 3. Release
        report "Releasing Key";
        key_valid <= '0';
        wait for 200 us;

        -- 4. Test Key '9' (852Hz + 1477Hz)
        -- Key Index 9 corresponds to '9'
        report "Pressing Key '9' (852 + 1477 Hz)";
        key_idx <= 9;
        key_valid <= '1';
        wait for 2 ms;

        -- 5. Release
        key_valid <= '0';
        wait for 100 us;

        -- End simulation
        report "Simulation Finished";
        wait;
    end process;

end Behavioral;
