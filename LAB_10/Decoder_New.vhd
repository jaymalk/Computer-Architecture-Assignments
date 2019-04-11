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
                -- MUL
                MUL when (instruction(31 downto 24) = "11100000" and instruction(7 downto 4) = "1001") else
                -- DP
                DP when (class = "00" and (I='1' or (I='0' and (INR='0' or (INR='1' and R='0'))))) else
                -- DT
                DT when (class = "01" or (class = "00" and I = '0' and INR = '1' and R = '1')) else
                -- Branch
                branch when (class = "10" and instruction(25 downto 24) = "10") else
                -- Unknown
                unknown;

    command <=  -- MUL
                mul when (cond = "1110" and instruction(27 downto 22) = "000000" and instruction(7 downto 4) = "1001" and instruction(21) = '0' and command_class = MUL) else
                mla when (cond = "1110" and instruction(27 downto 22) = "000000" and instruction(7 downto 4) = "1001" and instruction(21) = '1' and command_class = MUL) else
              umull when (cond = "1110" and instruction(27 downto 23) = "00001"  and instruction(7 downto 4) = "1001" and instruction(22 downto 21) = "10" and command_class = MUL) else
              umlal when (cond = "1110" and instruction(27 downto 23) = "00001"  and instruction(7 downto 4) = "1001" and instruction(22 downto 21) = "11" and command_class = MUL) else
              smull when (cond = "1110" and instruction(27 downto 23) = "00001"  and instruction(7 downto 4) = "1001" and instruction(22 downto 21) = "00" and command_class = MUL) else
              smlal when (cond = "1110" and instruction(27 downto 23) = "00001"  and instruction(7 downto 4) = "1001" and instruction(22 downto 21) = "01" and command_class = MUL) else
                -- DP
           not_nand when (cond = "1110" and opcode = "0000" and command_class = DP) else
                eor when (cond = "1110" and opcode = "0001" and command_class = DP) else
                sub when (cond = "1110" and opcode = "0010" and command_class = DP) else
                rsb when (cond = "1110" and opcode = "0011" and command_class = DP) else
                add when (cond = "1110" and opcode = "0100" and command_class = DP) else
                adc when (cond = "1110" and opcode = "0101" and command_class = DP) else
                sbc when (cond = "1110" and opcode = "0110" and command_class = DP) else
                rsc when (cond = "1110" and opcode = "0111" and command_class = DP) else
                tst when (cond = "1110" and opcode = "1000" and command_class = DP) else
                teq when (cond = "1110" and opcode = "1001" and command_class = DP) else
                cmp when (cond = "1110" and opcode = "1010" and command_class = DP) else
                cmn when (cond = "1110" and opcode = "1011" and command_class = DP) else
                orr when (cond = "1110" and opcode = "1100" and command_class = DP) else
                mov when (cond = "1110" and opcode = "1101" and command_class = DP) else
                bic when (cond = "1110" and opcode = "1110" and command_class = DP) else
                mvn when (cond = "1110" and opcode = "1111" and command_class = DP) else
                -- DT (Class = "00")
                ldrsh when (cond = "1110" and SH = "11" and L = '1' and (B = '0' or (B = '1' and instruction(11 downto 8) = "0000")) and command_class = DT) else
                ldrh  when (cond = "1110" and SH = "01" and L = '1' and (B = '0' or (B = '1' and instruction(11 downto 8) = "0000")) and command_class = DT) else
                strh  when (cond = "1110" and SH = "01" and L = '0' and (B = '0' or (B = '1' and instruction(11 downto 8) = "0000")) and command_class = DT) else
                ldrsb when (cond = "1110" and SH = "10" and L = '1' and (B = '0' or (B = '1' and instruction(11 downto 8) = "0000")) and command_class = DT) else
                -- DT (Class = "01")
                ldr  when (cond = "1110" and L = '1' and B = '0' and command_class = DT) else
                str  when (cond = "1110" and L = '0' and B = '0' and command_class = DT) else
                ldrb when (cond = "1110" and L = '1' and B = '1' and command_class = DT) else
                strb when (cond = "1110" and L = '0' and B = '1' and command_class = DT) else
                -- Branching
                beq when (cond = "0000" and command_class = branch) else
                bne when (cond = "0001" and command_class = branch) else
                bal when (cond = "1110" and command_class = branch) else
                -- Error
                unknown;

end architecture architecture_decoder;
