library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Data_Type.all;

-- ALU entity for Arithmetic and Logical Operations
entity ALU is
    Port (
            -- Input Parameters
            work: in std_logic;   -- Logic for allowing use
            A_ALU, B_ALU : in std_logic_vector(31 downto 0); -- Input Values
            input_instruction : in instruction_type; -- Instruction to follow

            -- Output Parameters
            result : out std_logic_vector(31 downto 0); -- Result of ALU calculation
            Z_Flag : out std_logic -- Zero flag 
          );
end ALU;

-- Architecture, currently supports only DP & DT instructions
architecture Behavioral of ALU is

    begin

        process(work)
        begin
            if(work = '1') then
                -- DP instructions
                if(input_instruction = add) then
                    -- Adding the values and putting in result.
                    result <= std_logic_vector(unsigned(A_ALU) + unsigned(B_ALU));
                elsif (input_instruction = sub) then
                    -- Subtracting the values and puttinh in result.
                    result <= std_logic_vector(unsigned(A_ALU) - unsigned(B_ALU));
                elsif (input_instruction = mov) then
                    -- Simple mov operation, value in B_ALU is the moved value.
                    result <= B_ALU;
                elsif (input_instruction = cmp) then
                    -- Compare operation, Z flag changed here.
                    result <= std_logic_vector(unsigned(A_ALU) - unsigned(B_ALU));
                    -- Setting the Zero Flag
                    if(A_ALU = B_ALU) then
                        Z_Flag <= '1';
                    else
                        Z_Flag <= '0';
                    end if;
                -- DT instructions
                elsif (input_instruction = str) then
                    -- Returning address value as 
                    result <= std_logic_vector(signed(A_ALU) + signed(B_ALU));
                else
                    -- Should not be reached.
                end if;
            end if;
        end process;

end Behavioral;
