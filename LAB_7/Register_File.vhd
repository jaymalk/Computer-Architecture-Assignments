library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;
use work.Data_Type.all;



-- Entity for a register file interaction interface
entity register_file is
    port(
        clock : in std_logic;
        address : in integer;
        write_enable : in std_logic;
        output : out std_logic_vector(31 downto 0)
        );
end entity;

-- Architecture for the interface.
architecture architecture_RF of register_file is
    signal RF : register_file_datatype;
begin
    process(clock)
    begin
        -- To complete after discussion
    end process;
end architecture architecture_RF;
