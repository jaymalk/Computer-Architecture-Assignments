library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Package Containing Principle Data Types
package data_type is

    -- Data type for Register File
    type register_file_datatype is
        array(0 to 15) of std_logic_vector(31 downto 0);

    -- Data type for Instruction Type
    type instruction_class is
        (DP, DT, branch, unknown);

    -- Data type for decoded instruction in ALU
    type instruction_type is
    (
        -- DP
        not_nand, eor, sub, rsb, add, adc, sbc, rsc, tst, teq, cmp, cmn, orr, mov, bic, mvn,
        -- DT
        ldr, str,
        -- Branching
        beq, bne, bal,
        -- For error and default
        unknown
    );

end package data_type;

-- To use the package: "use work.Data_Type.all;"
