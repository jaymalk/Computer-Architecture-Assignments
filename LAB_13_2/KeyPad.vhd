library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;

-- Entity for decoding keypad inputs.
entity keypad is
    port(
        -- Input Parameters
            -- Clock
        slow_clock: in std_logic;
            -- Column
        col : in std_logic_vector(3 downto 0);
            -- Row
        row : in std_logic_vector(3 downto 0);
        -- Output Parameters
            -- Decoded Key
        key_pressed: out std_logic_vector(3 downto 0)
    );
end entity;

-- Architecture for the decoder.
architecture input of keypad is

    -- Decoded Value
signal result : std_logic_vector(3 downto 0); -- Default : 0

begin
    -- Assigning the key value
    key_pressed <= result;

    process(slow_clock)
        begin
            if(slow_clock = '1' and slow_clock'event) then
                
                if (col = "0111") then
                    -- Checking for rows (in C1)
                    -- Row-1
                    if row = "0111" then
                        result <= "0001";	--1
                    -- Row-2
                    elsif row = "1011" then
                        result <= "0100";   --4
                    -- Row-3
                    elsif row = "1101" then
                        result <= "0111";   --7
                    -- Row-4
                    elsif row = "1110" then
                        result <= "0000";   --0
                    end if;
                    
                elsif (col = "1011") then
                    -- Checking for rows (in C2)
                    -- Row-1
                    if row = "0111" then
                        result <= "0010";	--2
                    -- Row-2
                    elsif row = "1011" then
                        result <= "0101";   --5
                    -- Row-3
                    elsif row = "1101" then
                        result <= "1000";   --8
                    -- Row-4
                    elsif row = "1110" then
                        result <= "1111";   --F
                    end if;
                    
                elsif (col = "1101") then
                    -- Checking for rows (in C3)
                    -- Row-1
                    if row = "0111" then
                        result <= "0011";	--3
                    -- Row-2
                    elsif row = "1011" then
                        result <= "0110";   --6
                    -- Row-3
                    elsif row = "1101" then
                        result <= "1001";   --9
                    -- Row-4
                    elsif row = "1110" then
                        result <= "1110";   --E
                    end if;
                    
                elsif (col = "1110") then
                    -- Checking for rows (in C4)
                    -- Row-1
                    if row = "0111" then
                        result <= "1010";	--A
                    -- Row-2
                    elsif row = "1011" then
                        result <= "1011";   --B
                    -- Row-3
                    elsif row = "1101" then
                        result <= "1100";   --C
                    -- Row-4
                    elsif row = "1110" then
                        result <= "1101";   --D
                    end if;
                end if;

            end if;
    end process;
end architecture input;
