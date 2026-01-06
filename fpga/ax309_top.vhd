library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ax309_top is
    Port (
        sys_clk : in STD_LOGIC;         -- 50MHz
        rst_n_key : in STD_LOGIC;       -- Use a key as reset or global reset
        key_in : in STD_LOGIC_VECTOR(3 downto 0); -- 4 Push buttons
        led_out : out STD_LOGIC_VECTOR(3 downto 0); -- 4 LEDs
        audio_pwm : out STD_LOGIC;      -- PWM Output Pin
        seg_data : out STD_LOGIC_VECTOR(7 downto 0); -- Segments
        seg_sel : out STD_LOGIC_VECTOR(5 downto 0)   -- Digit Select
    );
end ax309_top;

architecture Behavioral of ax309_top is
    -- Internal Signals
    signal key_db : std_logic_vector(3 downto 0);
    signal key_idx : integer range 0 to 15;
    signal key_active : std_logic;
    signal audio_pcm : signed(15 downto 0);
    
    COMPONENT key_debounce
    Generic ( CLK_FREQ : integer := 50_000_000 );
    PORT(
        clk : IN std_logic;
        rst_n : IN std_logic;
        key_in : IN std_logic;
        key_out : OUT std_logic
        );
    END COMPONENT;

    COMPONENT dtmf_generator
    PORT(
        clk : IN std_logic;
        rst_n : IN std_logic;
        key_idx : IN integer range 0 to 15;
        key_valid : IN std_logic;
        audio_out : OUT signed(15 downto 0)
        );
    END COMPONENT;
    
    COMPONENT pwm_audio
    PORT(
        clk : IN std_logic;
        rst_n : IN std_logic;
        pcm_in : IN signed(15 downto 0);
        pwm_out : OUT std_logic
        );
    END COMPONENT;

    COMPONENT seg_display
    PORT(
        clk : IN std_logic;
        rst_n : IN std_logic;
        display_val : IN integer range 0 to 15;
        seg_data : OUT std_logic_vector(7 downto 0);
        seg_sel : OUT std_logic_vector(5 downto 0)
        );
    END COMPONENT;

begin

    -- Debounce all 4 keys
    GEN_DB: for i in 0 to 3 generate
        DB_Inst: key_debounce PORT MAP(
            clk => sys_clk,
            rst_n => rst_n_key,
            key_in => key_in(i),
            key_out => key_db(i)
        );
    end generate;

    -- Key Mapping Logic
    -- AX309 Keys: Usually Active Low (Press = 0).
    -- We'll assume active low and invert for internal logic or handle it here.
    -- Let's map:
    -- Key0 -> DTMF '1' (Idx 1)
    -- Key1 -> DTMF '2' (Idx 2)
    -- Key2 -> DTMF '3' (Idx 3)
    -- Key3 -> DTMF '4' (Idx 4)
    
    process(key_db)
    begin
        key_active <= '0';
        key_idx <= 0;
        
        -- Priority Encoder (Reverse logic if active low: '0' means pressed)
        if key_db(0) = '0' then
            key_idx <= 1; -- Tone '1'
            key_active <= '1';
        elsif key_db(1) = '0' then
            key_idx <= 2; -- Tone '2'
            key_active <= '1';
        elsif key_db(2) = '0' then
            key_idx <= 3; -- Tone '3'
            key_active <= '1';
        elsif key_db(3) = '0' then
            key_idx <= 4; -- Tone '4'
            key_active <= '1';
        end if;
    end process;
    
    -- Visual Feedback
    led_out <= not key_db; -- Light up LED when key pressed (assuming Active Low LEDs)

    -- DTMF Generator
    Inst_DTMF: dtmf_generator PORT MAP(
        clk => sys_clk,
        rst_n => rst_n_key,
        key_idx => key_idx,
        key_valid => key_active,
        audio_out => audio_pcm
    );
    
    -- PWM Output
    Inst_PWM: pwm_audio PORT MAP(
        clk => sys_clk,
        rst_n => rst_n_key,
        pcm_in => audio_pcm,
        pwm_out => audio_pwm
    );

    -- 7-Segment Display
    Inst_Seg: seg_display PORT MAP(
        clk => sys_clk,
        rst_n => rst_n_key,
        display_val => key_idx,
        seg_data => seg_data,
        seg_sel => seg_sel
    );

end Behavioral;
