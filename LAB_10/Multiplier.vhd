library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.ALL;
use work.Data_Type.all;

-- ALU entity for Arithmetic and Logical Operations
entity Multiplier is
    Port (
            -- Input Parameters
            Rd_multiplier, Rn_multiplier, Rs_multiplier, Rm_multiplier : in std_logic_vector(31 downto 0); -- Input Values
            input_instruction : in instruction_type; -- Instruction to follow

            -- Output Parameters
            Result_Hi, Result_Lo : out std_logic_vector(31 downto 0); -- Results of Multiplier calculation
            Z_Flag : out std_logic; -- Zero flag
            N_Flag : out std_logic -- Negative flag
          );
end Multiplier;

architecture Behavioral of Multiplier is
    signal result_signed_acc, result_signed_mul: signed(65 downto 0);
    signal temp_rd: std_logic_vector(65 downto 0);
    signal RS, RM, RN : std_logic_vector(32 downto 0);
    signal result: std_logic_vector(63 downto 0);
    signal xs, xm, xd, xn : std_logic;
    
    begin 
    
    xd <= Rd_multiplier(31) when (input_instruction = smull or input_instruction = smlal) else '0';
    
    xn <= Rn_multiplier(31) when (input_instruction = smull or input_instruction = smlal) else '0';

    temp_rd <= (xd & xd & Rd_multiplier & Rn_multiplier) when (input_instruction = smlal or input_instruction = umlal) else
               ("0000000000000000000000000000000000" & Rn_multiplier) when (xn = '0') else
               ("1111111111111111111111111111111111" & Rn_multiplier) when (xn = '1');

    xs <= Rs_multiplier(31) when (input_instruction = smull or input_instruction = smlal) else '0';
               
    RS <= xs & Rs_multiplier;
    
    xm <= Rm_multiplier(31) when (input_instruction = smull or input_instruction = smlal) else '0';
          
    RM <= xm & Rm_multiplier;

    result_signed_mul <= signed(RS) * signed(RM);
    
    result_signed_acc <= signed(result_signed_mul) + signed(temp_rd);

    
        result <= std_logic_vector(result_signed_mul(63 downto 0)) when (input_instruction = mul or input_instruction = umull or input_instruction = smull) else
                  std_logic_vector(result_signed_acc(63 downto 0)) when (input_instruction = mla or input_instruction = umlal or input_instruction = smlal);
        
        Result_Hi <= result(63 downto 32);
        Result_Lo <= result(31 downto 0);
    
        N_Flag <= result(31) when (input_instruction = mul or input_instruction = mla) else
                  result(63);

        Z_Flag <= '1' when (result(31 downto 0) = "00000000000000000000000000000000" and (input_instruction = mul or input_instruction = mla)) else
                  '1' when (result = "0000000000000000000000000000000000000000000000000000000000000000" and (input_instruction = smull or input_instruction = smlal or input_instruction = umull or input_instruction = umlal)) else
                  '0';
                  
end Behavioral;