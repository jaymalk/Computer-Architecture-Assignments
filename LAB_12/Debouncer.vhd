library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- The entity for describing a debouncer, for use with buttons
entity debouncer is
  Port (
        input_value, slow_clock: in std_logic;
        output_value: out std_logic := '0' 
       );
end debouncer;

-- Architecture for the entity debouncer
architecture architecture_debouncer of debouncer is
begin
    process(slow_clock)
    begin
        if rising_edge(slow_clock) then
            output_value <= input_value;
        end if;
    end process;
end architecture architecture_debouncer;