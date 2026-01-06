library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity key_debounce is
    Generic ( CLK_FREQ : integer := 50_000_000 );
    Port ( 
        clk : in  STD_LOGIC;
        rst_n : in  STD_LOGIC;
        key_in : in  STD_LOGIC;
        key_out : out  STD_LOGIC
    );
end key_debounce;

architecture Behavioral of key_debounce is
    constant DELAY : integer := 20 * (CLK_FREQ / 1000); -- 20ms
    signal count : integer range 0 to DELAY := 0;
    signal key_reg : std_logic := '1';
begin
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            count <= 0;
            key_reg <= '1';
            key_out <= '1'; -- Default high (active low keys usually)
        elsif rising_edge(clk) then
            if key_in /= key_reg then
                count <= 0;
                key_reg <= key_in;
            else
                if count < DELAY then
                    count <= count + 1;
                else
                    key_out <= key_reg;
                end if;
            end if;
        end if;
    end process;
end Behavioral;
