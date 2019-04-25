library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;

-- Entity for reading keypad inputs.
entity keypad is
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
            -- Change Parameter (for IRQ)
        change : out std_logic := '0'
    );
end entity;

-- Architecture for the reader.
architecture input of keypad is

    -- Signal for columns and rows.
signal row, col, last_row : std_logic_vector(3 downto 0) := "1111";
    -- Decoded Value
signal result : std_logic_vector(3 downto 0); -- Default : 0
    -- Stage decider
signal stage : std_logic_vector(3 downto 0) := "0000";  

begin
    -- Assigning the key value
    key_pressed <= result;
    -- Catching the row input from ports
    row <= ports(7 downto 4);
    -- Sending the column set to ports
    ports(3 downto 0) <= col;

    process(slow_clock)
        begin
            if(stage = "1111" and (last_row = row or row = "1111")) then
                change <= '0';
                last_row <= row;
            elsif (stage = "1111") then
                change <= '1';
                last_row <= row;
            end if;
            if(slow_clock = '1' and slow_clock'event) then
                stage <= stage + 1;
                if (stage = "0000") then
                    -- Setting Column-1
                    col <= "0111";
                elsif (stage = "0010") then
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
                elsif (stage = "0100") then
                    -- Setting Column-2
                    col <= "1011";
                elsif (stage = "0110") then
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
                elsif (stage = "1000") then
                    -- Setting Column-3
                    col <= "1101";
                elsif (stage = "1010") then
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
                elsif (stage = "1100") then
                    -- Setting Column-4
                    col <= "1110";
                elsif (stage = "1110") then
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
