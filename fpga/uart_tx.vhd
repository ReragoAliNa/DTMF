library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Logic for sending serial data via UART
-- Fixed parameters: 8 data bits, no parity, 1 stop bit
entity uart_tx is
    Generic (
        CLK_FREQ  : integer := 50_000_000; -- 50MHz System Clock
        BAUD_RATE : integer := 115200       -- Baud Rate
    );
    Port (
        clk       : in  STD_LOGIC;
        rst_n     : in  STD_LOGIC;
        tx_data   : in  STD_LOGIC_VECTOR (7 downto 0); -- Byte to send
        tx_start  : in  STD_LOGIC;                     -- Trigger high pulse
        tx_busy   : out STD_LOGIC;                     -- High when sending
        tx_pin    : out STD_LOGIC                      -- Physical UART TX pin
    );
end uart_tx;

architecture Behavioral of uart_tx is

    constant BIT_PERIOD : integer := CLK_FREQ / BAUD_RATE;
    
    type state_type is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
    signal state : state_type := IDLE;
    
    signal clk_cnt : integer range 0 to BIT_PERIOD;
    signal bit_idx : integer range 0 to 7;
    signal tx_reg  : std_logic_vector(7 downto 0);

begin

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            state <= IDLE;
            tx_pin <= '1'; -- UART Idle is High
            tx_busy <= '0';
            clk_cnt <= 0;
            bit_idx <= 0;
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    tx_pin <= '1';
                    tx_busy <= '0';
                    clk_cnt <= 0;
                    if tx_start = '1' then
                        state <= START_BIT;
                        tx_reg <= tx_data;
                        tx_busy <= '1';
                    end if;
                    
                when START_BIT =>
                    tx_pin <= '0'; -- Start bit is Low
                    if clk_cnt < BIT_PERIOD - 1 then
                        clk_cnt <= clk_cnt + 1;
                    else
                        clk_cnt <= 0;
                        state <= DATA_BITS;
                        bit_idx <= 0;
                    end if;
                    
                when DATA_BITS =>
                    tx_pin <= tx_reg(bit_idx); -- LSB first
                    if clk_cnt < BIT_PERIOD - 1 then
                        clk_cnt <= clk_cnt + 1;
                    else
                        clk_cnt <= 0;
                        if bit_idx < 7 then
                            bit_idx <= bit_idx + 1;
                        else
                            state <= STOP_BIT;
                        end if;
                    end if;
                    
                when STOP_BIT =>
                    tx_pin <= '1'; -- Stop bit is High
                    if clk_cnt < BIT_PERIOD - 1 then
                        clk_cnt <= clk_cnt + 1;
                    else
                        clk_cnt <= 0;
                        state <= IDLE;
                    end if;
            end case;
        end if;
    end process;

end Behavioral;
