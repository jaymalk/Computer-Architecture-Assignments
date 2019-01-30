library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.data_type.all;

entity TestBench is
    port (
    tclk : in std_logic
    );
end TestBench;

architecture test of TestBench is
    signal reset : std_logic := '1';
    signal we : std_logic;
    signal pc, addr_data_memory : integer;
    signal dt_addr, pr_addr : std_logic_vector(7 downto 0);
    signal instr, data_memory_in, data_memory_out : std_logic_vector(31 downto 0);
    signal dummyRF: register_file_type;
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
        instruction, data_in: in std_logic_vector(31 downto 0);
        addr_prMemory, addr_data_memory: out integer;
        data_out: out std_logic_vector(31 downto 0);
        wr_enb: out std_logic;
        dummyRF: out register_file_type
    );
    end COMPONENT;
        

begin
    
    pr_addr <= std_logic_vector(to_unsigned(pc, 8));
    
    pmem : ProgramMemory
    PORT MAP (
        a => pr_addr,
        spo => instr
    );
    
    ourCPU: cpu
        PORT MAP(
        tclk => tclk,
        reset => reset,
        instruction => instr,
        data_in => data_memory_out,
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
    
    process
    begin
        reset <= '1';
        wait until tclk = '1' and tclk'event;
        reset <= '0';
        for i in 1 to 10000 loop
            wait until tclk = '1' and tclk'event;
        end loop;
    end process;

end test ;
