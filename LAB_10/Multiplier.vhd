library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Data_Type.all;

-- ALU entity for Arithmetic and Logical Operations
entity Multiplier is
    Port (
            -- Input Parameters
            work: in std_logic;    -- Logic for allowing use
            Rd_multiplier, Rn_multiplier, Rs_multiplier, Rm_multiplier : in std_logic_vector(31 downto 0); -- Input Values
            input_instruction : in instruction_type; -- Instruction to follow

            -- Output Parameters
            Result_Hi, Result_Lo : out std_logic_vector(31 downto 0) -- Results of Multiplier calculation
          );
end Multiplier;

architecture Behavioral of Multiplier is
    signal temp_s, result_signed: signed(63 downto 0);
    signal temp_u, result_unsigned: unsigned(63 downto 0);
    signal result, temp_rd: std_logic_vector(63 downto 0);
    signal acc : std_logic := '0';
    
    begin 
    
    process(work, acc)
    begin
        if(work='1' and work'event)then
            
            if(input_instruction=mul)then
                result_unsigned <= unsigned(Rs_multiplier) * unsigned(Rm_multiplier);
            elsif(input_instruction=mla)then
                result_unsigned <= (unsigned(Rs_multiplier) * unsigned(Rm_multiplier)) + unsigned(Rn_multiplier);
            elsif(input_instruction=umull)then
                result_unsigned <= unsigned(Rs_multiplier) * unsigned(Rm_multiplier);
            elsif(input_instruction=umlal)then
                temp_u <= (unsigned(Rs_multiplier) * unsigned(Rm_multiplier));
                acc <= '1';
            elsif(input_instruction=smull)then
                result_signed <= signed(Rs_multiplier) * signed(Rm_multiplier);
            elsif(input_instruction=smlal)then
                temp_s <= ( signed(Rs_multiplier) * signed(Rm_multiplier));
                acc <= '1';
            end if;
        end if;
        
        if(acc = '1' and acc'event) then
            if(input_instruction=umlal)then
                 result_unsigned <= unsigned(temp_u) + unsigned(temp_rd);
            elsif(input_instruction=smlal)then
                 result_signed <= signed(temp_s) + signed(temp_rd);
            end if;             
            acc <= '0';
        end if;
    end process;
    
        result <= std_logic_vector(result_unsigned) when (input_instruction=mul or input_instruction=mla or input_instruction=umull or input_instruction=umlal) else
                  std_logic_vector(result_signed)   when (input_instruction=smull or input_instruction=smlal);
        
        Result_Hi <= result(63 downto 32);
        Result_Lo <= result(31 downto 0);
    
        temp_rd <= Rd_multiplier & Rn_multiplier; 
        
end Behavioral;