library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;

entity clockDivider is
    port(clk, reset: in std_logic;
        output: out std_logic);
end entity;

architecture archClockDivider of clockDivider is
  signal counter: integer :=0;
  signal temp: std_logic := '1';
begin
    process(clk)
    begin
        if(reset = '1') then
            temp<='0';
            counter<=0;         
        elsif(clk = '1' and clk'event) then
            if(counter = 500000) then
                temp <= '0';
		        counter <= counter+1;
            elsif(counter = 1000000) then
                temp<= '1';
                counter <= 0;
            else
                counter <= counter + 1;
            end if;
            output<=temp;
        end if;
    end process;
end architecture archClockDivider;