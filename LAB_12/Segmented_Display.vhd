library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- The entity for describing a display, for use with 7-segmented display
entity display is
  Port (
      -- Input Parameters
        clock: in std_logic;
        value: in std_logic_vector(15 downto 0);
      -- Output Parameters
        outp: out std_logic_vector(6 downto 0) := "0000000";
        anode: out std_logic_vector(3 downto 0) := "0000"
       );
end display;

-- Architecture for the visual
architecture visual of display is
    -- Signal for deciding which anode to be closed
    signal anodes : std_logic_vector(3 downto 0) := "1111";
    -- Signal for setting anodes according to state
    signal state : integer := 0;
    -- Signal for assigning value to each digit-display
    type digits is array(3 downto 0) of std_logic_vector(3 downto 0);
    signal digit : digits := (others => (others => '0'));
    signal main : std_logic_vector(3 downto 0) := "0000";
begin

    
    
    -- Value associated with each part
    digit(3) <= value(15 downto 12);
    digit(2) <= value(11 downto 8);
    digit(1) <= value(7  downto 4);
    digit(0) <= value(3  downto 0);

    process(clock)
    begin
        if(clock'event and clock = '1') then
            case main is
                when "0000" => outp <=  "0000001";
                when "0001" => outp <=  "1001111";
                when "0010" => outp <=  "0010010";
                when "0011" => outp <=  "0000110";
                when "0100" => outp <=  "1001100";
                when "0101" => outp <=  "0100100";
                when "0110" => outp <=  "0100000";
                when "0111" => outp <=  "0001111";
                when "1000" => outp <=  "0000000";
                when "1001" => outp <=  "0000100";
                when "1010" => outp <=  "0000010";
                when "1011" => outp <=  "1100000";
                when "1100" => outp <=  "0110001";
                when "1101" => outp <=  "1000010";
                when "1110" => outp <=  "0110000";
                when "1111" => outp <=  "0111000";
                when others => outp <=  "1111111";
            end case;
            state <= ((state+1) rem 4);
            -- Assigning values to anode
            case state is
                when 0 => anodes <= "1110";
                when 1 => anodes <= "1101";
                when 2 => anodes <= "1011";
                when 3 => anodes <= "0111";
                when others => anodes <= "1111";
            end case;
            -- Assigning the orignial anode
            anode <= anodes;

            -- Setting the correct register output for display
            main <= digit(state);
        end if;
    end process;
end architecture visual;