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
    (add, sub, cmp, mov, ldr, str, beq, bne, b, unknown);

end package data_type;

-- To use the package: "use work.Data_Type.all;"