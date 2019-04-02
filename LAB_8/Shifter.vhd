library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- ALU entity for Arithmetic and Logical Operations
entity Shifter is
    Port (
            -- Input Parameters
            input_vector : in std_logic_vector(31 downto 0);   -- Input Vector
            shift_amount : in std_logic_vector(4 downto 0); -- Shift Amount
            shift_type : in std_logic_vector(1 downto 0); -- Shift Type

            -- Output Parameters
            output_vector : out std_logic_vector(31 downto 0); -- Result of Shift
            C_bit : out std_logic -- Carry bit
          );
end Shifter;

architecture Behavioral of ALU is
        signal shift_by_1, shift_by_2, shift_by_4, shift_by_8, shift_by_16 : std_logic_vector(31 downto 0);
    begin

        -- 00-LSL
        -- 01-LSR
        -- 10-ASR
        -- 11-ROR
        
        shift_by_1 <= (input_vector(30 downto 0) & '0') when ((shift_amount(0) = '1') and (shift_type = "00")) else
                      ('0' & input_vector(31 downto 1)) when ((shift_amount(0) = '1') and (shift_type = "01")) else
                      ('0' & input_vector(31 downto 1)) when ((shift_amount(0) = '1') and (shift_type = "10") and (input_vector(31) = '0')) else
                      ('1' & input_vector(31 downto 1)) when ((shift_amount(0) = '1') and (shift_type = "10") and (input_vector(31) = '1')) else
                      (input_vector(0) & input_vector(31 downto 1)) when ((shift_amount(0) = '1') and (shift_type = "11")) else
                      input_vector;
        
        shift_by_2 <= (shift_by_1(29 downto 0) & "00") when ((shift_amount(1) = '1') and (shift_type = "00")) else
                      ("00" & shift_by_1(31 downto 2)) when ((shift_amount(1) = '1') and (shift_type = "01")) else
                      ("00" & shift_by_1(31 downto 2)) when ((shift_amount(1) = '1') and (shift_type = "10") and (input_vector(31) = '0')) else
                      ("11" & shift_by_1(31 downto 2)) when ((shift_amount(1) = '1') and (shift_type = "10") and (input_vector(31) = '1')) else
                      (shift_by_1(1 downto 0) & shift_by_1(31 downto 2)) when ((shift_amount(1) = '1') and (shift_type = "11")) else
                      shift_by_1;
        
        shift_by_4 <= (shift_by_2(27 downto 0) & "0000") when ((shift_amount(2) = '1') and (shift_type = "00")) else
                      ("0000" & shift_by_2(31 downto 4)) when ((shift_amount(2) = '1') and (shift_type = "01")) else
                      ("0000" & shift_by_2(31 downto 4)) when ((shift_amount(2) = '1') and (shift_type = "10") and (input_vector(31) = '0')) else
                      ("1111" & shift_by_2(31 downto 4)) when ((shift_amount(2) = '1') and (shift_type = "10") and (input_vector(31) = '1')) else
                      (shift_by_2(3 downto 0) & shift_by_2(31 downto 4)) when ((shift_amount(2) = '1') and (shift_type = "11")) else
                      shift_by_2;

        shift_by_8 <= (shift_by_4(23 downto 0) & "00000000") when ((shift_amount(3) = '1') and (shift_type = "00")) else
                      ("00000000" & shift_by_4(31 downto 8)) when ((shift_amount(3) = '1') and (shift_type = "01")) else
                      ("00000000" & shift_by_4(31 downto 8)) when ((shift_amount(3) = '1') and (shift_type = "10") and (input_vector(31) = '0')) else
                      ("11111111" & shift_by_4(31 downto 8)) when ((shift_amount(3) = '1') and (shift_type = "10") and (input_vector(31) = '1')) else
                      (shift_by_4(7 downto 0) & shift_by_4(31 downto 8)) when ((shift_amount(3) = '1') and (shift_type = "11")) else
                      shift_by_4;

        shift_by_16<= (shift_by_8(15 downto 0) & "0000000000000000") when ((shift_amount(4) = '1') and (shift_type = "00")) else
                      ("0000000000000000" & shift_by_8(31 downto 16)) when ((shift_amount(4) = '1') and (shift_type = "01")) else
                      ("0000000000000000" & shift_by_8(31 downto 16)) when ((shift_amount(4) = '1') and (shift_type = "10") and (input_vector(31) = '0')) else
                      ("1111111111111111" & shift_by_8(31 downto 16)) when ((shift_amount(4) = '1') and (shift_type = "10") and (input_vector(31) = '1')) else
                      (shift_by_8(15 downto 0) & shift_by_8(31 downto 16)) when ((shift_amount(4) = '1') and (shift_type = "11")) else
                      shift_by_8;

        output_vector <= shift_by_16;

        C_bit <= shift_by_8(16) when ((shift_amount(4) = '1') and (shift_type = "00")) else
                 shift_by_8(15) when (shift_amount(4) = '1') else
                 shift_by_4(24) when ((shift_amount(3) = '1') and (shift_type = "00")) else
                 shift_by_4(7)  when (shift_amount(3) = '1') else
                 shift_by_2(28) when ((shift_amount(2) = '1') and (shift_type = "00")) else
                 shift_by_2(3)  when (shift_amount(2) = '1') else
                 shift_by_1(30) when ((shift_amount(1) = '1') and (shift_type = "00")) else
                 shift_by_1(1)  when (shift_amount(1) = '1') else
                 input_vector(31) when ((shift_amount(0) = '1') and (shift_type = "00")) else
                 input_vector(0)  when (shift_amount(0) = '1') else
                 '0';

        
end Behavioral;
