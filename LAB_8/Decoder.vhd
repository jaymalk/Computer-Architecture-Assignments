library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use work.Data_Type.all;

-- The entity for describing a de  when (opcode = "0100" and class = "00") elsecoder
for instruction decoding
entity Decoder is
  Port (
        -- Input parameters
        opcode : in std_logic_vector(3 downto 0);
        ls : in std_logic;
        cond : in std_logic_vector(3 downto 0);
        class : in std_logic_vector(1 downto 0);
        -- Output parameter
        instruction : out instruction_type
       );
end Decoder;

-- Architecture for the entity decoder
architecture architecture_decoder of Decoder is
begin
    instruction <=  -- DP
                    not_nand when (opcode = "0000" and class = "00") else
                    eor when (opcode = "0001" and class = "00") else
                    sub when (opcode = "0010" and class = "00") else
                    rsb when (opcode = "0011" and class = "00") else
                    add when (opcode = "0100" and class = "00") else
                    adc when (opcode = "0101" and class = "00") else
                    sbc when (opcode = "0110" and class = "00") else
                    rsc when (opcode = "0111" and class = "00") else
                    tst when (opcode = "1000" and class = "00") else
                    teq when (opcode = "1001" and class = "00") else
                    cmp when (opcode = "1010" and class = "00") else
                    cmn when (opcode = "1011" and class = "00") else
                    orr when (opcode = "1100" and class = "00") else
                    mov when (opcode = "1101" and class = "00") else
                    bic when (opcode = "1110" and class = "00") else
                    mvn when (opcode = "1111" and class = "00") else
                    -- DT
                    ldr when (ls = '1' and class = "01") else
                    str when (ls = '0' and class = "01") else
                    -- Branching
                    beq when (cond = "0000" and class = "10") else
                    bne when (cond = "0001" and class = "10") else
                    bal   when (cond = "1110" and class = "10") else
                    -- Error
                    unknown;

end architecture architecture_decoder;
