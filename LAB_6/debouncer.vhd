library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity debouncer is
  Port (input, clk: in std_logic;
        output: out std_logic 
       );
end debouncer;

architecture arch_debouncer of debouncer is
begin
    process(clk)
    begin
        if rising_edge(clk) then
            output <= input
        end if;
    end process;
end architecture arch_debouncer;