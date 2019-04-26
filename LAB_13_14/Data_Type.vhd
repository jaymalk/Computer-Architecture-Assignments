library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Package Containing Principle Data Types
package data_type is

    -- Data type for Register File
    type general_file is array(natural range<>) of std_logic_vector(31 downto 0);
    subtype complete_file is general_file(19 downto 0);
    subtype register_file is general_file(15 downto 0);

    -- Data type for Instruction Type
    type instruction_class is
        (PSR, SWI, DP, DT, MUL, branch, unknown);

    -- Data type for decoded instruction in ALU
    type instruction_type is
    (
        -- PSR
        msr, mrs,
        -- SWI
        swi,
        -- DP
        not_nand, eor, sub, rsb, add, adc, sbc, rsc, tst, teq, cmp, cmn, orr, mov, bic, mvn,
        -- MUL
        mul, mla, smull, smlal, umull, umlal,
        -- DT
        ldr, str, ldrh, strh, ldrb, strb, ldrsh, ldrsb,
        -- A unified branching instruction, since predication is handeled irrespective of (decoded type)
        bal, bl,
        -- For error and default
        unknown
    );

end package data_type;

-- To use the package: "use work.Data_Type.all;"
