library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
package data_type is
    type register_file_type is array(0 to 15) of std_logic_vector(31 downto 0);
    type program_memory_type is array(0 to 63) of std_logic_vector(31 downto 0);
    type data_memory_type is array(0 to 255) of std_logic_vector(31 downto 0);
    type instr_class_type is (DP, DT, branch, unknown);
    type i_decoded_type is (add, sub, cmp, mov, ldr, str, beq, bne, b, unknown);
end package data_type;

--include using "use work.data_type.all;"