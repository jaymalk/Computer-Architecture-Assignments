library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use work.Data_Type.all;

-- The entity for describing a predicator for condition checking and passage
entity Predicator is
  Port (
        -- Input parameters
        condition : in std_logic_vector(3 downto 0);
        Z : in std_logic;
        C : in std_logic; 
        N : in std_logic; 
        V : in std_logic;
        -- Output parameter
        pass : out boolean
       );
end Predicator;

-- Architecture for the predicator
architecture decider of Predicator is
begin
    pass <=  -- DP
                    Z = '1' when (condition = "0000") else
                    Z = '0' when (condition = "0001") else
                    C = '1' when (condition = "0010") else
                    C = '0' when (condition = "0011") else
                    N = '1' when (condition = "0100") else
                    N = '0' when (condition = "0101") else
                    V = '1' when (condition = "0110") else
                    V = '0' when (condition = "0111") else
                    (C = '1' and Z = '0') when (condition = "1000") else
                    (C = '0' and Z = '1') when (condition = "1001") else
                    (N = V) when (condition = "1010") else
                    (N!= V) when (condition = "1011") else
                    (Z = '0' and N = V) when (condition = "1100") else
                    (Z = '1' and N!= V) when (condition = "1101") else
                    true when (condition = "1110") else
                    -- Unknown Condition Field
                    true;

end architecture decider;
