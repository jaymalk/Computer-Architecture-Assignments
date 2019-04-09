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
            -- Program Select, 4 bit vector to decide for programs
            Program_Select : in std_logic_vector(2 downto 0);
            -- Buttons for control
            Reset_Button, Step_Button, Go_Button, Instr_Button: in std_logic;
            -- ? WTF
            lur : in std_logic; --LoadUpperRegisterForOutput
            -- Specifying the reister number
            register_number: in std_logic_vector(3 downto 0);
        -- Output
            LED_Output : out std_logic_vector(15 downto 0)
        );
end TestBench;

-- Architectuer for the testbench

architecture Behavioral of TestBench is

    -- Signal for reset, interacts with the reset button
    signal reset : std_logic;

    -- Signal for step, go, instr response, for the testing FSM
    signal step, go, instr : std_logic := '0';

    -- Slower clock for debouncing
    signal slow_clock : std_logic;

    -- Write enable (For data memory)
    signal Write_Enable_0, Write_Enable_1, Write_Enable_2, Write_Enable_3 : std_logic;

    -- CPU signals (for mapping)
    signal Address_To_IM, Address_To_DM : integer;
    signal Instruction_From_IM, Data_To_DM, Data_From_DM : std_logic_vector(31 downto 0);
    signal Data_To_DM_0, Data_To_DM_1, Data_To_DM_2, Data_To_DM_3: std_logic_vector(7 downto 0);
    signal Data_From_DM_0, Data_From_DM_1, Data_From_DM_2, Data_From_DM_3: std_logic_vector(7 downto 0);

    -- Address to program and data memory
    signal DM_Address, IM_Address : std_logic_vector(7 downto 0);

    -- For display
    signal RF_For_Display: register_file_datatype;

    -- Program selector
    signal PC_Start: integer := 0;

    -- Component representing the data memory
    component DataMemory
      port (
        a : in STD_LOGIC_VECTOR(7 downto 0);
        d : in STD_LOGIC_VECTOR(31 downto 0);
        clk : in STD_LOGIC;
        we : in STD_LOGIC;
        spo : out STD_LOGIC_VECTOR(31 downto 0)
      );
    end component;
    
    -- Component representing the instruction memory
    component ProgramMemory
      port (
        a : in STD_LOGIC_VECTOR(7 downto 0);
        spo : out STD_LOGIC_VECTOR(31 downto 0)
      );
    end component;
    
    -- Componenet representing the multi-cycle CPU
    component CPU_MULTI is
        Port (
                -- Input Parameters
                main_clock, reset: in std_logic;
                    -- Instruction from instruction memory
                Instruction_From_IM: in std_logic_vector(31 downto 0);
                    -- Data from data memory, to be used by str
                Data_From_DM: in std_logic_vector(31 downto 0);
                    -- Initialiser for PC for a program
                PC_Start: in integer;
                    -- Variables which handle user input for testing FSM
                step, go, instr: in std_logic;
    
                -- Output Parameters
                    -- Address to be sent to instruction memory to get Instruction (PC is sent)
                Address_To_IM: out integer;
                    -- Address to be sent to data memory to get data, used by ldr
                Address_To_DM: out integer;
                    -- Data to be sent to data memory, used be str
                Data_To_DM: out std_logic_vector(31 downto 0);
                    -- Deciding for write and fetch from data memory
                Write_Enable_0, Write_Enable_1, Write_Enable_2, Write_Enable_3: out std_logic;
                    -- dummy RF to be used outside
                RF_For_Display: out register_file_datatype
              );
    end component;
    
    -- Component representing the clock divider, giving clock for debouncer
    component clock_divider is
        port(in_clock, reset: in std_logic;
            slow_clock: out std_logic);
    end component;

begin
    
    with lur select LED_Output <=
        RF_For_Display(to_integer(unsigned(register_number)))(31 downto 16) when '1',
        RF_For_Display(to_integer(unsigned(register_number)))(15 downto 0) when others;
      
------------------------------------------------------------
    -- Mapping the parameters of Clock divider
    SLOW: clock_divider
       port map
        (
        -- Input parameters
            in_clock => test_clock,
            reset => reset,
        -- Output parameters
            slow_clock => slow_clock
        );

------------------------------------------------------------
    -- Assigning the buttons their respective positions
        -- Reset Button
        Reset_Component: entity  work.debouncer(architecture_debouncer) port map(Reset_Button, slow_clock, reset);
        -- Step button
        Step_Component: entity  work.debouncer(architecture_debouncer) port map(Step_Button, slow_clock, step);
        -- Go button
        Go_Component: entity  work.debouncer(architecture_debouncer) port map(Go_Button, slow_clock, go);
        -- Instr button
        Instr_Component: entity  work.debouncer(architecture_debouncer) port map(Instr_Button, slow_clock, instr);
    
------------------------------------------------------------
    -- Concurrent assignement of IM_Address(8 bit vector), from Address_To_IM (integer)
    IM_Address <= std_logic_vector(to_unsigned(Address_To_IM, 8));
    
    -- Mapping the parameters of ProgramMemory
    IM : ProgramMemory
    port map (
        a => IM_Address,
        spo => Instruction_From_IM
    );
    
------------------------------------------------------------
    -- Determining thr program to work with (if initialsing is needed.)
    PC_Start <= ((32) * to_integer(unsigned(Program_Select)));

    -- Mapping the parameters of CPU
    TheCPU: CPU_MULTI
        port map
        (
        -- Input Parameters
            -- clock and reset
            main_clock => test_clock,
            reset => reset,
            -- program select
            PC_Start => PC_Start,
            -- Instruction from IM
            Instruction_From_IM => Instruction_From_IM,
            -- Data from DM
            Data_From_DM => Data_From_DM,
            -- Buttons
            step => step,
            go => go,
            instr => instr,
        -- Output Parameters
            -- Address to IM
            Address_To_IM => Address_To_IM,
            -- Address to DM
            Address_To_DM => Address_To_DM,
            -- Data to DM
            Data_To_DM => Data_To_DM,
            -- Write enable for DM
            Write_Enable_0 => Write_Enable_0,
            Write_Enable_1 => Write_Enable_1,
            Write_Enable_2 => Write_Enable_2,
            Write_Enable_3 => Write_Enable_3,
            -- Dummy RF for display
            RF_For_Display => RF_For_Display
        );
    
------------------------------------------------------------
    -- Concurrent assignement of DM_Address(8 bit vector), from Address_To_DM (integer)
    DM_Address <= std_logic_vector(to_unsigned(Address_To_DM, 8));
    
    Data_To_DM_3 <= Data_To_DM(31 downto 24);
    Data_To_DM_2 <= Data_To_DM(23 downto 16);
    Data_To_DM_1 <= Data_To_DM(15 downto 8);
    Data_To_DM_0 <= Data_To_DM(7 downto 0);

    Data_From_DM <= Data_From_DM_3 & Data_From_DM_2 & Data_From_DM_1 & Data_From_DM_0 ; 
    -- Data Memory Components
    DM_0 : DataMemory
    port map (
        a => DM_Address,
        d => Data_To_DM_0,
        clk => test_clock,
        we => Write_Enable_0,
        spo => Data_From_DM_0
    );

    DM_1 : DataMemory
    port map (
        a => DM_Address,
        d => Data_To_DM_1,
        clk => test_clock,
        we => Write_Enable_1,
        spo => Data_From_DM_1
    );

    DM_2 : DataMemory
    port map (
        a => DM_Address,
        d => Data_To_DM_2,
        clk => test_clock,
        we => Write_Enable_2,
        spo => Data_From_DM_2
    );

    DM_3 : DataMemory
    port map (
        a => DM_Address,
        d => Data_To_DM_3,
        clk => test_clock,
        we => Write_Enable_3,
        spo => Data_From_DM_3
    );
------------------------------------------------------------ 

end Behavioral ;
