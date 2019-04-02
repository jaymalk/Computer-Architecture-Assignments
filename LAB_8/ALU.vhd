library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Data_Type.all;

-- ALU entity for Arithmetic and Logical Operations
entity ALU is
    Port (
            -- Input Parameters
            work, C: in std_logic;    -- Logic for allowing use
            A_ALU, B_ALU : in std_logic_vector(31 downto 0); -- Input Values
            input_instruction : in instruction_type; -- Instruction to follow

            -- Output Parameters
            result : out std_logic_vector(31 downto 0); -- Result of ALU calculation
            Z_Flag : out std_logic -- Zero flag
            C_Flag : out std_logic -- Carry flag
            V_Flag : out std_logic -- Overflow flag
            N_Flag : out std_logic -- Negative flag
          );
end ALU;

-- Architecture, currently supports only DP & DT instructions
architecture Behavioral of ALU is

    begin

        process(work)
        begin
            if(work = '1') then
                -- DP instructions

                if (input_instruction = not_nand) then
                    -- Taking AND of the values and putting in result.
                    result <= A_ALU AND B_ALU;
                elsif (input_instruction = eor) then
                    -- Taking XOR of the values and putting in result.
                    result <= A_ALU XOR B_ALU;
                elsif (input_instruction = orr) then
                    -- Taking OR of the values and putting in result.
                    result <= A_ALU OR B_ALU;
                elsif (input_instruction = bic) then
                    -- Taking BIC of the values and putting in result.
                    result <= A_ALU AND NOT B_ALU;

                elsif (input_instruction = sub) then
                    -- Subtracting the values and putting in result.
                    result <= std_logic_vector(unsigned(A_ALU) + unsigned(NOT B_ALU) + unsigned("00000000000000000000000000000001"));
                elsif (input_instruction = rsb) then
                    -- Reverse subtracting the values and putting in result.
                    result <= std_logic_vector(unsigned(B_ALU) + unsigned(NOT A_ALU) + unsigned("00000000000000000000000000000001"));
                elsif(input_instruction = add) then
                    -- Adding the values and putting in result.
                    result <= std_logic_vector(unsigned(A_ALU) + unsigned(B_ALU));
                elsif (input_instruction = adc) then
                    -- Adding with carry the values and putting in result.
                    result <= std_logic_vector(unsigned(A_ALU) + unsigned(B_ALU) + C);
                elsif (input_instruction = sbc) then
                    -- Subtracting with carry the values and putting in result.
                    result <= std_logic_vector(unsigned(A_ALU) + unsigned(NOT B_ALU) + C);
                elsif (input_instruction = rsc) then
                    -- Reverse subtracting with carry the values and putting in result.
                    result <= std_logic_vector(unsigned(B_ALU) + unsigned(NOT A_ALU) + C);

                elsif (input_instruction = mov) then
                    -- Simple mov operation, value in B_ALU is the moved value.
                    result <= B_ALU;
                elsif (input_instruction = mvn) then
                    -- Simple mvn operation, value in B_ALU with negation is the moved value.
                    result <= NOT B_ALU;

                elsif (input_instruction = cmp) then
                    -- Compare operation, Z flag changed here.
                    result <= std_logic_vector(unsigned(A_ALU) + unsigned(NOT B_ALU) + unsigned("00000000000000000000000000000001"));
                    -- Setting the Zero Flag
                    if(A_ALU = B_ALU) then
                        Z_Flag <= '1';
                    else
                        Z_Flag <= '0';
                    end if;
                elsif (input_instruction = cmn) then
                    -- Compare negative operation, Z flag changed here.
                    result <= std_logic_vector(unsigned(A_ALU) + unsigned(B_ALU));
                    -- Setting the Zero Flag
                    if(A_ALU = NOT B_ALU) then
                        Z_Flag <= '1';
                    else
                        Z_Flag <= '0';
                    end if;
                elsif (input_instruction = tst) then
                    -- Testing operation, Z flag changed here.
                    result <= A_ALU AND B_ALU;
                    -- Setting the Zero Flag
                    if(A_ALU = B_ALU) then
                        Z_Flag <= '1';
                    else
                        Z_Flag <= '0';
                    end if;
                elsif (input_instruction = teq) then
                    -- Compare operation, Z flag changed here.
                    result <= A_ALU XOR B_ALU;
                    -- Setting the Zero Flag
                    if(A_ALU = B_ALU) then
                        Z_Flag <= '1';
                    else
                        Z_Flag <= '0';
                    end if;
                -- DT instructions
                elsif (input_instruction = str or input_instruction = ldr) then
                    -- Returning address value as
                    result <= std_logic_vector(signed(A_ALU) + signed(B_ALU));
                else
                    -- Should not be reached.
                end if;
            end if;
        end process;

end Behavioral;
