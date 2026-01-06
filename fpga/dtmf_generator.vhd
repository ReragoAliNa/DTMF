library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.dtmf_pkg.ALL;

entity dtmf_generator is
    Port ( 
        clk : in  STD_LOGIC;
        rst_n : in  STD_LOGIC;
        key_idx : in  integer range 0 to 15; -- 0-15 for 16 DTMF keys
        key_valid : in STD_LOGIC;            -- '1' when key is pressed
        audio_out : out signed(15 downto 0)  -- Mixed output
    );
end dtmf_generator;

architecture Behavioral of dtmf_generator is
    -- Phase Accumulators
    signal phase_acc_row : unsigned(PH_ACC_WIDTH-1 downto 0) := (others => '0');
    signal phase_acc_col : unsigned(PH_ACC_WIDTH-1 downto 0) := (others => '0');
    
    -- Phase Increments
    signal inc_row : integer := 0;
    signal inc_col : integer := 0;
    
    -- LUT Interface
    signal addr_row : std_logic_vector(7 downto 0);
    signal addr_col : std_logic_vector(7 downto 0);
    signal data_row : signed(15 downto 0);
    signal data_col : signed(15 downto 0);
    
    COMPONENT sine_lut
    PORT(
        clk : IN std_logic;
        addr : IN std_logic_vector(7 downto 0);          
        data : OUT signed(15 downto 0)
        );
    END COMPONENT;

begin

    -- Frequency Selection Logic
    process(key_idx)
    begin
        -- Standard DTMF Keypad Mapping
        -- 1(0,0) 2(0,1) 3(0,2) A(0,3)
        -- 4(1,0) 5(1,1) 6(1,2) B(1,3)
        -- 7(2,0) 8(2,1) 9(2,2) C(2,3)
        -- *(3,0) 0(3,1) #(3,2) D(3,3)
        -- Mapping key_idx 0..15 to Row/Col indices
        case key_idx is
            when 1 =>  -- '1'
                inc_row <= calc_phase_inc(ROW_FREQS(0)); inc_col <= calc_phase_inc(COL_FREQS(0));
            when 2 =>  -- '2'
                inc_row <= calc_phase_inc(ROW_FREQS(0)); inc_col <= calc_phase_inc(COL_FREQS(1));
            when 3 =>  -- '3'
                inc_row <= calc_phase_inc(ROW_FREQS(0)); inc_col <= calc_phase_inc(COL_FREQS(2));
            when 10 => -- 'A' (using index 10 for A)
                inc_row <= calc_phase_inc(ROW_FREQS(0)); inc_col <= calc_phase_inc(COL_FREQS(3));
                
            when 4 =>  -- '4'
                inc_row <= calc_phase_inc(ROW_FREQS(1)); inc_col <= calc_phase_inc(COL_FREQS(0));
            when 5 =>  -- '5'
                inc_row <= calc_phase_inc(ROW_FREQS(1)); inc_col <= calc_phase_inc(COL_FREQS(1));
            when 6 =>  -- '6'
                inc_row <= calc_phase_inc(ROW_FREQS(1)); inc_col <= calc_phase_inc(COL_FREQS(2));
            when 11 => -- 'B'
                inc_row <= calc_phase_inc(ROW_FREQS(1)); inc_col <= calc_phase_inc(COL_FREQS(3));
                
            when 7 =>  -- '7'
                inc_row <= calc_phase_inc(ROW_FREQS(2)); inc_col <= calc_phase_inc(COL_FREQS(0));
            when 8 =>  -- '8'
                inc_row <= calc_phase_inc(ROW_FREQS(2)); inc_col <= calc_phase_inc(COL_FREQS(1));
            when 9 =>  -- '9'
                inc_row <= calc_phase_inc(ROW_FREQS(2)); inc_col <= calc_phase_inc(COL_FREQS(2));
            when 12 => -- 'C'
                inc_row <= calc_phase_inc(ROW_FREQS(2)); inc_col <= calc_phase_inc(COL_FREQS(3));
                
            when 14 => -- '*' (using 14)
                inc_row <= calc_phase_inc(ROW_FREQS(3)); inc_col <= calc_phase_inc(COL_FREQS(0));
            when 0 =>  -- '0'
                inc_row <= calc_phase_inc(ROW_FREQS(3)); inc_col <= calc_phase_inc(COL_FREQS(1));
            when 15 => -- '#' (using 15)
                inc_row <= calc_phase_inc(ROW_FREQS(3)); inc_col <= calc_phase_inc(COL_FREQS(2));
            when 13 => -- 'D'
                inc_row <= calc_phase_inc(ROW_FREQS(3)); inc_col <= calc_phase_inc(COL_FREQS(3));
                
            when others =>
                inc_row <= 0; inc_col <= 0;
        end case;
    end process;

    -- Phase Accumulation
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            phase_acc_row <= (others => '0');
            phase_acc_col <= (others => '0');
        elsif rising_edge(clk) then
            if key_valid = '1' then
                phase_acc_row <= phase_acc_row + to_unsigned(inc_row, PH_ACC_WIDTH);
                phase_acc_col <= phase_acc_col + to_unsigned(inc_col, PH_ACC_WIDTH);
            else
                phase_acc_row <= (others => '0');
                phase_acc_col <= (others => '0');
            end if;
        end if;
    end process;
    
    -- Map top 8 bits of phase to LUT address
    addr_row <= std_logic_vector(phase_acc_row(PH_ACC_WIDTH-1 downto PH_ACC_WIDTH-8));
    addr_col <= std_logic_vector(phase_acc_col(PH_ACC_WIDTH-1 downto PH_ACC_WIDTH-8));
    
    -- Instantiate LUTs
    LUT_ROW: sine_lut PORT MAP(clk => clk, addr => addr_row, data => data_row);
    LUT_COL: sine_lut PORT MAP(clk => clk, addr => addr_col, data => data_col);
    
    -- Output Mixer (Sum and Scale)
    process(clk)
        variable sum : signed(16 downto 0);
    begin
        if rising_edge(clk) then
            if key_valid = '1' then
                -- Sum the two sines. Result is 17 bits.
                sum := resize(data_row, 17) + resize(data_col, 17);
                -- Scale down by 1 (divide by 2) to fit back into 16 bits
                audio_out <= sum(16 downto 1);
            else
                audio_out <= (others => '0');
            end if;
        end if;
    end process;

end Behavioral;
