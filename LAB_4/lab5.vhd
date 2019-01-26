library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.data_type.all;


entity cpu is
    Port (clk, reset: in std_logic,
          instruction, data_in: in std_logic_vector(31 downto 0)

          addr_prMemory, addr_dataMemory: out integer,
          data_out: out std_logic_vector(31 down to 0),
          wr_enb: out bit
          );
end cpu;


architecture Behavioral of cpu is
    signal cond, opcode: std_logic_vector(3 downto 0);
    signal F_field, Opc: std_logic_vector(1 downto 0);
    signal I_bit, s_l_bit: std_logic;
    signal shift_spec: std_logic_vector(7 downto 0);
    signal instr_class: instr_class_type;
    signal i_decoded: i_decoded_type := unknown;
    
    signal is_reg, is_plus_offset: std_logic :='0';
    signal p, u, b, w: std_logic;

    signal RF: register_file_type;
    signal data_memory: data_memory_type;


begin

    cond <= instruction(31 downto 28);
    F_field <= instruction(27 downto 26);
    I_bit <= instruction(25);
    p <= instruction(24);
    u <= instruction(23);
    b <= instruction(22);
    w <= instruction(21);
    s_l_bit <= instruction(20);
    
    shift_spec <= instruction(11 downto 4);
    opcode <= instruction(24 downto 21);

    with F_field select instr_class <=
        DP when "00",
        DT when "01",
        branch when "10",
        unknown when others;

    process(clk)
    begin
        if (reset='1') then
            pc <= 0;

        else
            
            if (instr_class = DP) then
                
                if (opcode = "0100") then
                    i_decoded = add;
                
                elsif (opcode = "0010") then
                    i_decoded = sub;
            
                elsif (opcode = "1101") then
                    i_decoded = mov;
               
                elsif (opcode = "1010") then
                    i_decoded = cmp;

                else
                    i_decoded = unknown;
                end if;

                is_reg <= (not I_bit);
            
            elsif (instr_class = DT) then
                
                if(s_l_bit = '1') then
                    i_decoded = ldr;
                elsif(s_l_bit = '0') then
                    i_decoded = str;
                else
                    i_decode = unknown;
                end if;

                is_plus_offset <= u;

            elsif (instr_class = branch) then

                if (cond = "1110") then
                    i_decoded = add;
                
                elsif (cond = "0000") then
                    i_decoded = sub;
            
                elsif (cond = "0001") then
                    i_decoded = mov;
               
                else
                    i_decoded = unknown;
                end if;

            else
                i_decoded = unknown;
            end if;
        end if;

    end process;
end Behavioral;