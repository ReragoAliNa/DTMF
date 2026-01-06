library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity seg_display is
    Port ( 
        clk : in STD_LOGIC;
        rst_n : in STD_LOGIC;
        display_val : in integer range 0 to 15;
        seg_data : out STD_LOGIC_VECTOR(7 downto 0);
        seg_sel : out STD_LOGIC_VECTOR(5 downto 0)
    );
end seg_display;

architecture Behavioral of seg_display is
    signal seg_code : std_logic_vector(7 downto 0);
begin
    
    -- 【极简模式】
    -- 1. 选中所有数码管 (位选全为0)
    -- 2. 显示同一个数字
    seg_sel <= "000000"; 

    -- 段码译码 (DP G F E D C B A) 0亮1灭
    process(display_val)
    begin
        case display_val is
            when 1 => seg_code <= "11111001"; -- 1
            when 2 => seg_code <= "10100100"; -- 2
            when 3 => seg_code <= "10110000"; -- 3
            when 4 => seg_code <= "10011001"; -- 4
            when others => seg_code <= "11111111"; -- Blank/Off when 0 or others
        end case;
    end process;

    seg_data <= seg_code;

end Behavioral;
