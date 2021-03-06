library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.data_type.all;

-- Entity for testbench, for testing the CPU

entity TestBench is
    port 
        (
        -- Input parameters
            test_clock : in std_logic;
            -- Buttons for control
            Step_Button, Go_Button, Instr_Button, RST_Button, Halt_Button: in std_logic := '0';
            -- Register Status
            lur, lenc : in std_logic := '0'; --Load Upper Register (or Load Encoding) For Output
            -- Specifying the reister number
            register_number: in std_logic_vector(3 downto 0) := "0000";
            
            --==== TEMP ====--
            --== Set key for checking if keyboard works ==--
            sets : in std_logic := '0';
            
        -- Input/Output (mix)
            ports: inout std_logic_vector(7 downto 0);
        -- Output
            -- LED outputs
            LED_Output : out std_logic_vector(15 downto 0) := "0000000000000000";
            -- Segmented Display outputs
                -- Values
            seg : out std_logic_vector(6 downto 0) := "0000000";
                -- Anode sets
            an : out std_logic_vector(3 downto 0) := "0000"
        );
end TestBench;

-- Architectuer for the testbench

architecture Behavioral of TestBench is

    -- Signal for step, go, instr response, for the testing FSM
    signal step, go, instr, halt, irq, rst : std_logic := '0';

    -- Slower clocks for debouncing, display and cpu
    signal slow_clock, second_clock, cpu_clock : std_logic;

    -- Write enable (For data memory)
    signal Write_Enable_0, Write_Enable_1, Write_Enable_2, Write_Enable_3 : std_logic;

    -- CPU signals (for mapping)
    signal Address_To_IM, Address_To_DM : integer;
        -- Desired words, to be sent to CPU
    signal Instruction_From_IM, Data_To_DM, Data_From_DM : std_logic_vector(31 downto 0);
        -- Data to DM, bytes
    signal Data_To_DM_0, Data_To_DM_1, Data_To_DM_2, Data_To_DM_3: std_logic_vector(7 downto 0);
        -- Data from DM, bytes
    signal Data_From_DM_0, Data_From_DM_1, Data_From_DM_2, Data_From_DM_3: std_logic_vector(7 downto 0);
        -- Instruction fetched, bytes
    signal Instruction_From_IM_0, Instruction_From_IM_1, Instruction_From_IM_2, Instruction_From_IM_3: std_logic_vector(7 downto 0);

    -- Address to program and data memory
    signal DM_Address, IM_Address : std_logic_vector(9 downto 0);

    -- For display
    signal RF_For_Display: register_file;

    -- Mediator signals for LED_Output
    signal LED_Select : std_logic_vector(15 downto 0) := "0000000000000000";

    -- Signal for catching the key from the key board
    signal key, last_key : std_logic_vector(3 downto 0);
    signal irq_check, refresh_check : integer := 1;
    signal is_pressed: std_logic;
    -- Data from CPU to be viewed on Segmented Display
    signal cpu_display : std_logic_vector(15 downto 0);

    -- Component representing the data memory 
        -- Needs 4 different copies for working with different COE's
    component Memory_0
      PORT (
        a : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        d : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        dpra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        clk : IN STD_LOGIC;
        we : IN STD_LOGIC;
        spo : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        dpo : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
      );
    end component;
    component Memory_1
      PORT (
        a : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        d : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        dpra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        clk : IN STD_LOGIC;
        we : IN STD_LOGIC;
        spo : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        dpo : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
      );
    end component;
    component Memory_2
      PORT (
        a : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        d : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        dpra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        clk : IN STD_LOGIC;
        we : IN STD_LOGIC;
        spo : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        dpo : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
      );
    end component;
    component Memory_3
      PORT (
        a : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        d : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        dpra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        clk : IN STD_LOGIC;
        we : IN STD_LOGIC;
        spo : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        dpo : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
      );
    end component;

    -- Seven segment display for showing the values of registers on diplay (in HEX)
    component display is
        Port (
            -- Input Parameters
              clock: in std_logic;
              value: in std_logic_vector(15 downto 0);
            -- Output Parameters
              outp: out std_logic_vector(6 downto 0);
              anode: out std_logic_vector(3 downto 0)
             );
      end component;

    -- Component for interfacing with keypad
    component keypad is
        port(
            -- Input Parameters
                -- Clock
            slow_clock: in std_logic;
                -- Ports read from JA
                -- (rows : in) || (columns : out)
            ports : inout std_logic_vector(7 downto 0);
            -- Output Parameters
                -- Decoded Key
            key_pressed: out std_logic_vector(3 downto 0);
            pressed: out std_logic
        );
    end component;

    -- Componenet representing the multi-cycle CPU
    component CPU_MULTI is
        Port (
            -- Input Parameters
            main_clock: in std_logic;
                -- Instruction from instruction memory
            Instruction_From_IM: in std_logic_vector(31 downto 0);
                -- Data from data memory, to be used by str
            Data_From_DM: in std_logic_vector(31 downto 0);
                -- Variables which handle user input for testing FSM
            step, go, instr, halt: in std_logic;
                -- External Exception Handle (IRQ and RESET)
            irq_in, rst_in : in std_logic;
                -- Input Key Value (from keypad)
            in_key : in std_logic_vector(3 downto 0);

            -- Output Parameters
                -- Address to be sent to instruction memory to get Instruction (PC is sent)
            Address_To_IM: out integer;
                -- Address to be sent to data memory to get data, used by ldr
            Address_To_DM: out integer;
                -- Data to be sent to data memory, used be str
            Data_To_DM: out std_logic_vector(31 downto 0);
                -- Vector for showing display from CPU
            Display_From_CPU: out std_logic_vector(15 downto 0);
                -- Deciding for write and fetch from data memory
            Write_Enable_0, Write_Enable_1, Write_Enable_2, Write_Enable_3: out std_logic;
                -- dummy RF to be used outside
            RF_For_Display: out register_file
          );
    end component;
    
    -- Component representing the clock divider, giving clock for debouncer
    component clock_divider is
        port(
        -- Input Parameters
        in_clock, reset: in std_logic;
        split: in integer;
        -- Output Parameters
        slow_clock: out std_logic
        );
    end component;

begin
    -- Selecting visible output
    LED_Select <=
        "000000000000"&key when sets = '1' else
        RF_For_Display(to_integer(unsigned(register_number)))(31 downto 16) when (lur ='1' and lenc = '0') else
        RF_For_Display(to_integer(unsigned(register_number)))(15 downto 0)  when (lur ='0' and lenc = '0') else
        Instruction_From_IM(31 downto 16) when (lur ='1' and lenc = '1') else
        Instruction_From_IM(15 downto 0)  when (lur ='0' and lenc = '1');
    -- Assigning from holder
    LED_Output <= LED_Select;

------------------------------------------------------------
    -- Mapping the segmented-display register
    Register_Value : display
        Port map (
            -- Input Parameters
              clock => slow_clock,
              value => cpu_display,
            -- Output Parameters
              outp => seg,
              anode => an
             );

------------------------------------------------------------
    -- Keypad entry
    Keypad_Module : keypad
        Port map (
            -- Input
            slow_clock => slow_clock,
            -- Output
            ports => ports,
            key_pressed => key,
            pressed => is_pressed
        );

------------------------------------------------------------
---- A simple process for determining 'IRQ' status w.r.t to key pressed.
process(cpu_clock, key)
    begin
        if(cpu_clock = '1' and cpu_clock'event) then
            irq_check <= ((irq_check+1) mod 10);
            if (irq_check = 0) then
                if (not (key = last_key)) then
                    irq <= '1';
                    last_key <= key;
                else    
                    irq <= '0';
                end if;
            end if;
        end if;
    end process;
------------------------------------------------------------
    -- Mapping the parameters of Clock divider
        -- Getting the clock for buttons and segmented display
    SLOW: clock_divider
       port map
        (
        -- Input parameters
            in_clock => test_clock,
            reset => rst,
            split => 50000,
        -- Output parameters
            slow_clock => slow_clock
        );
        -- Getting the clock for CPU
    CPU_CLK: clock_divider
        port map
         (
         -- Input parameters
             in_clock => test_clock,
             reset => rst,
             split => 1,
         -- Output parameters
             slow_clock => cpu_clock
         );

------------------------------------------------------------
-- BUTTONS

    -- Assigning the buttons their respective positions
        -- Step button
        Step_Component: entity  work.debouncer(architecture_debouncer) port map(Step_Button, slow_clock, step);
        -- Go button
        Go_Component: entity  work.debouncer(architecture_debouncer) port map(Go_Button, slow_clock, go);
        -- Instr button
        Instr_Component: entity  work.debouncer(architecture_debouncer) port map(Instr_Button, slow_clock, instr);
        -- Halt Button
        Halt_Component: entity  work.debouncer(architecture_debouncer) port map(Halt_Button, slow_clock, halt);
        -- RST button
        RST_Component: entity  work.debouncer(architecture_debouncer) port map(RST_Button, slow_clock, rst);

------------------------------------------------------------
-- CPU COMPONENTS 
    -- Mapping the parameters of CPU
    TheCPU: CPU_MULTI
        port map
        (
        -- Input Parameters
            -- clock and reset
            main_clock => cpu_clock,
            -- Instruction from IM
            Instruction_From_IM => Instruction_From_IM,
            -- Data from DM
            Data_From_DM => Data_From_DM,
            -- Buttons
            step => step,
            go => go,
            instr => instr,
            halt => halt,
            -- Exceptions
            irq_in => irq,
            rst_in => rst,
            -- Input Key
            in_key => key,
        -- Output Parameters
            -- Address to IM
            Address_To_IM => Address_To_IM,
            -- Address to DM
            Address_To_DM => Address_To_DM,
            -- Data to DM
            Data_To_DM => Data_To_DM,
            -- Display From CPU
            Display_From_CPU => cpu_display,
            -- Write enable for DM
            Write_Enable_0 => Write_Enable_0,
            Write_Enable_1 => Write_Enable_1,
            Write_Enable_2 => Write_Enable_2,
            Write_Enable_3 => Write_Enable_3,
            -- Dummy RF for display
            RF_For_Display => RF_For_Display
        );
    
------------------------------------------------------------
-- MEMORY COMPONENTS

    -- (BREAKING AND MERGING)

        -- DATA RELATED COMPONENTS
    -- Concurrent assignement of DM_Address(8 bit vector), from Address_To_DM (integer)
    DM_Address <= std_logic_vector(to_unsigned((Address_To_DM/4), 10));
    -- Getting indiviual bytes from main data
    Data_To_DM_3 <= Data_To_DM(31 downto 24);
    Data_To_DM_2 <= Data_To_DM(23 downto 16);
    Data_To_DM_1 <= Data_To_DM(15 downto 8);
    Data_To_DM_0 <= Data_To_DM(7 downto 0);
    -- Settng data memory component from individual bytes
    Data_From_DM <= Data_From_DM_3 & Data_From_DM_2 & Data_From_DM_1 & Data_From_DM_0 ; 

        -- INSTRUCTION RELATED COMPONENTS
    -- Concurrent assignement of IM_Address(8 bit vector), from Address_To_IM (integer)
    IM_Address <= std_logic_vector(to_unsigned(Address_To_IM, 10));
    -- Settng data memory component from individual bytes
    Instruction_From_IM <= Instruction_From_IM_3 & Instruction_From_IM_2 & Instruction_From_IM_1 & Instruction_From_IM_0 ; 

    -- MEMORY MAPPING
    DM_0 : Memory_0
    port map (
        a => DM_Address,
        d => Data_To_DM_0,
        dpra => IM_Address,
        clk => test_clock,
        we => Write_Enable_0,
        spo => Data_From_DM_0,
        dpo => Instruction_From_IM_0
    );

    DM_1 : Memory_1
    port map (
        a => DM_Address,
        d => Data_To_DM_1,
        dpra => IM_Address, 
        clk => test_clock,
        we => Write_Enable_1,
        spo => Data_From_DM_1,
        dpo => Instruction_From_IM_1
    );

    DM_2 : Memory_2
    port map (
        a => DM_Address,
        d => Data_To_DM_2,
        dpra => IM_Address,
        clk => test_clock,
        we => Write_Enable_2,
        spo => Data_From_DM_2,
        dpo => Instruction_From_IM_2
    );

    DM_3 : Memory_3
    port map (
        a => DM_Address,
        d => Data_To_DM_3,
        dpra => IM_Address,
        clk => test_clock,
        we => Write_Enable_3,
        spo => Data_From_DM_3,
        dpo => Instruction_From_IM_3
    );
------------------------------------------------------------ 

end Behavioral ;
