library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;


-- SUMMARY
-- This divider, provides a clock which is '$2*split' times slower
-- than the original (native) clock of the system.
-- Using this buttons have a better chance of being recognised in
-- correct way, without any fluctuations.

-- Entity for a clock divider, for giving lower frequncy clocks.
entity clock_divider is
    port(
        -- Input Parameters
        in_clock, reset: in std_logic;
        split: in integer;
        -- Output Parameters
        slow_clock: out std_logic := '1'
        );
end entity;

-- Architecture for the clock divider.
architecture architecture_divider of clock_divider is

  signal counter: integer :=1;
begin

    process(in_clock)
    begin  
        if(in_clock = '1' and in_clock'event) then
            if(counter = split) then
                slow_clock <= '1';
		        counter <= counter+1;
            elsif(counter = 2*split) then
                slow_clock <= '0';
                counter <= 1;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;    
end architecture architecture_divider;
