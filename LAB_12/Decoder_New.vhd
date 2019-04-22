library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use work.Data_Type.all;

-- PLEASE READ
-- This decoder provides the following
--  = The command type from decoded instruction.
--  = Also, the class as now it is not a simple function of F_bits

-- The entity for describing a decoder in an extensive fashion for instruction decoding
entity Decoder_New is
  Port (
        -- Input parameters
        instruction : in std_logic_vector(31 downto 0);
        -- Output parameter
        command : out instruction_type;
        command_class_out : out instruction_class
       );
end Decoder_New;

-- Architecture for the entity decoder_new
architecture architecture_decoder of Decoder_New is

-- Signals for general parameters
    -- Class (General)
    signal class : std_logic_vector(1 downto 0);
    -- Opcode (for DP)
    signal opcode : std_logic_vector(3 downto 0);
    -- Condition field (General)
    signal cond : std_logic_vector(3 downto 0);
    -- Parameters (for DT)
    signal I, P, U, B, W, L : std_logic;
    -- Signal separation for special class (DT F = "00")
    signal INR, R : std_logic;
    signal SH : std_logic_vector(1 downto 0);
    signal command_class: instruction_class;
begin

-- Assigning the general parameters their value
    -- Class
    class <= instruction(27 downto 26);
    -- Condition
    cond <= instruction(31 downto 28);
    -- Opcode
    opcode <=  instruction(24 downto 21);
    -- IPUBWL for DT instruction
    I <= instruction(25);
    P <= instruction(24);
    U <= instruction(23);
    B <= instruction(22);
    W <= instruction(21);
    L <= instruction(20);
    -- Special (DT with F = "00")
    SH <= instruction(6 downto 5);
    INR <= instruction(4);
    R <= instruction(7);

-- Main Decoding Part

    command_class_out <= command_class;

    command_class <= 
                -- PSR
                PSR when (instruction(27 downto 23) = "00010" and (instruction(21 downto 4) = "101001111100000000" or (instruction(21 downto 16) = "001111" and instruction(11 downto 0) = "000000000000"))) else
                -- SWI
                SWI when (instruction(27 downto 24) = "1111") else
                -- MUL
                MUL when (instruction(27 downto 24) = "0000" and instruction(7 downto 4) = "1001") else
                -- DP
                DP when (class = "00" and (I='1' or (I='0' and (INR='0' or (INR='1' and R='0'))))) else
                -- DT
                DT when (class = "01" or (class = "00" and I = '0' and INR = '1' and R = '1')) else
                -- Branch
                branch when (class = "10" and instruction(25) = '1') else
                -- Unknown
                unknown;

    command <=  
                -- PSR
                mrs when (command_class = PSR and instruction(21) = '0') else
                msr when (command_class = PSR and instruction(21) = '1') else
                -- SWI
                swi when (command_class = SWI) else
                -- MUL
                mul when (instruction(27 downto 22) = "000000" and instruction(7 downto 4) = "1001" and instruction(21) = '0' and command_class = MUL) else
                mla when (instruction(27 downto 22) = "000000" and instruction(7 downto 4) = "1001" and instruction(21) = '1' and command_class = MUL) else
              umull when (instruction(27 downto 23) = "00001"  and instruction(7 downto 4) = "1001" and instruction(22 downto 21) = "00" and command_class = MUL) else
              umlal when (instruction(27 downto 23) = "00001"  and instruction(7 downto 4) = "1001" and instruction(22 downto 21) = "01" and command_class = MUL) else
              smull when (instruction(27 downto 23) = "00001"  and instruction(7 downto 4) = "1001" and instruction(22 downto 21) = "10" and command_class = MUL) else
              smlal when (instruction(27 downto 23) = "00001"  and instruction(7 downto 4) = "1001" and instruction(22 downto 21) = "11" and command_class = MUL) else
                -- DP
           not_nand when (opcode = "0000" and command_class = DP) else
                eor when (opcode = "0001" and command_class = DP) else
                sub when (opcode = "0010" and command_class = DP) else
                rsb when (opcode = "0011" and command_class = DP) else
                add when (opcode = "0100" and command_class = DP) else
                adc when (opcode = "0101" and command_class = DP) else
                sbc when (opcode = "0110" and command_class = DP) else
                rsc when (opcode = "0111" and command_class = DP) else
                tst when (opcode = "1000" and command_class = DP) else
                teq when (opcode = "1001" and command_class = DP) else
                cmp when (opcode = "1010" and command_class = DP) else
                cmn when (opcode = "1011" and command_class = DP) else
                orr when (opcode = "1100" and command_class = DP) else
                mov when (opcode = "1101" and command_class = DP) else
                bic when (opcode = "1110" and command_class = DP) else
                mvn when (opcode = "1111" and command_class = DP) else
                -- DT (Class = "00")
                ldrsh when (SH = "11" and L = '1' and (B = '0' or (B = '1' and instruction(11 downto 8) = "0000")) and command_class = DT) else
                ldrh  when (SH = "01" and L = '1' and (B = '0' or (B = '1' and instruction(11 downto 8) = "0000")) and command_class = DT) else
                strh  when (SH = "01" and L = '0' and (B = '0' or (B = '1' and instruction(11 downto 8) = "0000")) and command_class = DT) else
                ldrsb when (SH = "10" and L = '1' and (B = '0' or (B = '1' and instruction(11 downto 8) = "0000")) and command_class = DT) else
                -- DT (Class = "01")
                ldr  when (L = '1' and B = '0' and command_class = DT) else
                str  when (L = '0' and B = '0' and command_class = DT) else
                ldrb when (L = '1' and B = '1' and command_class = DT) else
                strb when (L = '0' and B = '1' and command_class = DT) else
                -- Branching
                bl when (command_class = branch and instruction(24) = '1') else                
                bal when (command_class = branch) else
                -- Error
                unknown;

end architecture architecture_decoder;
