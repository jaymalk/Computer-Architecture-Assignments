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

    -- Assigning values to anode
    anodes <= "0001" when state = 0 else
              "0010" when state = 1 else
              "0100" when state = 2 else
              "1000" when state = 3;
    anode <= anodes;

    -- Setting the correct register output for display
    main <= digit(state);

    -- Assigning the output value
    outp <= "0000001" when main = "0000" else -- 0 
        "1001111" when main = "0001" else -- 1 
        "0010010" when main = "0010" else -- 2 
        "0000110" when main = "0011" else -- 3 
        "1001100" when main = "0100" else -- 4 
        "0100100" when main = "0101" else -- 5 
        "0100000" when main = "0110" else -- 6 
        "0001111" when main = "0111" else -- 7 
        "0000000" when main = "1000" else -- 8 
        "0000100" when main = "1001" else -- 9 
        "0000010" when main = "1010" else -- a
        "1100000" when main = "1011" else -- b
        "0110001" when main = "1100" else -- C
        "1000010" when main = "1101" else -- d
        "0110000" when main = "1110" else -- E
        "0111000" when main = "1111";     -- F    

    -- Value associated with each part
    digit(3) <= value(15 downto 12);
    digit(2) <= value(11 downto 8);
    digit(1) <= value(7  downto 4);
    digit(0) <= value(3  downto 0);

    process(clock)
    begin
        state <= ((state+1) mod 4);
    end process;
end architecture visual;