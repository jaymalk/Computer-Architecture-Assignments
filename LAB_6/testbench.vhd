library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.data_type.all;

entity TestBench is
    port (
    tclk : in std_logic;
    selectProgram : in std_logic_vector(2 downto 0);
    resetButton, stepButton, goButton : in std_logic;
    lur : in std_logic; --LoadUpperRegisterForOutput
    regNo: in std_logic_vector(3 downto 0);
    LEDoutput : out std_logic_vector(15 downto 0)
    );
end TestBench;

architecture test of TestBench is
    signal reset : std_logic;
    signal step, go : std_logic := '0';
    signal hundredHzClock : std_logic;
    signal we : std_logic;
    signal pc, addr_data_memory : integer;
    signal dt_addr, pr_addr : std_logic_vector(7 downto 0);
    signal instr, data_memory_in, data_memory_out : std_logic_vector(31 downto 0);
    signal dummyRF: register_file_type;
    signal PCinitializer: integer := 0;
    COMPONENT DataMemory
      PORT (
        a : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        d : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        clk : IN STD_LOGIC;
        we : IN STD_LOGIC;
        spo : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
      );
    END COMPONENT;
    
    COMPONENT ProgramMemory
      PORT (
        a : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        spo : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
      );
    END COMPONENT;
    
    COMPONENT cpu
      Port (tclk, reset: in std_logic;
        PCinitializer: in integer;
        instruction, data_in: in std_logic_vector(31 downto 0);
        step, go: in std_logic;
        addr_prMemory, addr_data_memory: out integer;
        data_out: out std_logic_vector(31 downto 0);
        wr_enb: out std_logic;
        dummyRF: out register_file_type
    );
    end COMPONENT;
        
    COMPONENT clockDivider
        Port (clk : in std_logic;
              reset : in std_logic;
            output : out std_logic);
    END COMPONENT;

begin
    
    with lur select LEDoutput <=
        dummyRF(to_integer(unsigned(regNo)))(31 downto 16) when '1',
        dummyRF(to_integer(unsigned(regNo)))(15 downto 0) when others;
        
    hundredHzclk: clockDivider
       PORT MAP(
       clk => tclk,
       reset => reset,
       output => hundredHzClock
       );

    resetComponent: entity  work.debouncer(arch_debouncer) port map(resetButton, hundredHzClock, reset);
    stepComponent: entity  work.debouncer(arch_debouncer) port map(stepButton, hundredHzClock, step);
    goComponent: entity  work.debouncer(arch_debouncer) port map(goButton, hundredHzClock, go);
    
    pr_addr <= std_logic_vector(to_unsigned(pc, 8));
    
    pmem : ProgramMemory
    PORT MAP (
        a => pr_addr,
        spo => instr
    );
    
    PCinitializer <= ((32) * to_integer(unsigned(selectProgram)));

    ourCPU: cpu
        PORT MAP(
        tclk => tclk,
        reset => reset,
        PCinitializer => PCinitializer,
        instruction => instr,
        data_in => data_memory_out,
        step => step,
        go => go,
        addr_prMemory => pc,
        addr_data_memory => addr_data_memory,
        data_out => data_memory_in,
        wr_enb => we,
        dummyRF => dummyRF
        );
    
    dt_addr <= std_logic_vector(to_unsigned(addr_data_memory, 8));

    
    dmem : DataMemory
    PORT MAP (
        a => dt_addr,
        d => data_memory_in,
        clk => tclk,
        we => we,
        spo => data_memory_out
    );
    

end test ;
