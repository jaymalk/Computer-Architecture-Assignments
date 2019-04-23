library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;


-- SUMMARY
-- This divider, provides a clock which is 500,000 times slower
-- than the original (native) clock of the system.
-- Using this buttons have a better chance of being recognised in
-- correct way, without any fluctuations.

-- Entity for a clock divider, for giving lower frequncy clocks.
entity clock_divider is
    port(in_clock, reset: in std_logic;
        slow_clock: out std_logic);
end entity;

-- Architecture for the clock divider.
architecture architecture_divider of clock_divider is

  signal counter: integer :=0;
  signal temp: std_logic := '1';

begin

    process(in_clock)
    begin  
        if(in_clock = '1' and in_clock'event) then
            if(counter = 50000) then
                temp <= '0';
		        counter <= counter+1;
            elsif(counter = 100000) then
                temp<= '1';
                counter <= 0;
            else
                counter <= counter + 1;
            end if;
            slow_clock<=temp;
        end if;
    end process;

end architecture architecture_divider;
