library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.data_type.all;


entity cpu is
    Port (tclk, reset: in std_logic;
          instruction, data_in: in std_logic_vector(31 downto 0);
         -- data_memory : in data_memory_type;
          addr_prMemory, addr_data_memory: out integer;
          data_out: out std_logic_vector(31 downto 0);
          wr_enb: out std_logic;
          dummyRF: out register_file_type
          );
end cpu;


architecture Behavioral of cpu is
    signal cond, opcode: std_logic_vector(3 downto 0);
    signal F_field, Opc: std_logic_vector(1 downto 0);
    signal I_bit, s_l_bit: std_logic;
    signal shift_spec: std_logic_vector(7 downto 0);
    signal instr_class: instr_class_type;
    signal i_decoded: i_decoded_type := unknown;
    signal call_ldr : std_logic := '0';
    
    signal rm: std_logic_vector(31 downto 0);
    signal rd, rn: integer;
    signal is_reg, is_plus_offset: std_logic :='0';
    signal p, u, b_bit, w: std_logic;

    signal RF: register_file_type;
--    signal data_memory: data_memory_type;

    signal pc: integer := 0;
    signal flag_Z: std_logic;
begin

    cond <= instruction(31 downto 28);
    F_field <= instruction(27 downto 26);
    I_bit <= instruction(25);
    p <= instruction(24);
    u <= instruction(23);
    b_bit <= instruction(22);
    w <= instruction(21);
    s_l_bit <= instruction(20);
    
    rn <= to_integer(unsigned(instruction(19 downto 16)));
    rd <= to_integer(unsigned(instruction(15 downto 12)));

    shift_spec <= instruction(11 downto 4);
    opcode <= instruction(24 downto 21);

    with F_field select instr_class <=
        DP when "00",
        DT when "01",
        branch when "10",
        unknown when others;

    i_decoded <= add when (opcode = "0100" and F_field = "00") else
                 sub when (opcode = "0010" and F_field = "00") else
                 mov when (opcode = "1101" and F_field = "00") else
                 cmp when (opcode = "1010" and F_field = "00") else
                 ldr when (s_l_bit = '1' and F_field = "01") else
                 str when (s_l_bit = '0' and F_field = "01") else
                 beq when (cond = "0000" and F_field = "10") else
                 bne when (cond = "0001" and F_field = "10") else
                 b   when (cond = "1110" and F_field = "10") else
                 unknown;

    is_reg <= (not I_bit);
    is_plus_offset <= u;
    addr_PrMemory <= pc;
    dummyRF <= RF;
    
    
    rm <= RF(to_integer(unsigned(instruction(3 downto 0))))
              when (F_field = "00" and is_reg='1') else
              "000000000000000000000000" & instruction(7 downto 0)
              when (F_field = "00" and is_reg='0') else
    
              "00000000000000000000" & instruction(11 downto 0)
              when (F_field = "01" and is_plus_offset='1') else
              "11111111111111111111" & instruction(11 downto 0)
              when (F_field = "01" and is_plus_offset='0') else
    
              "000000" & instruction(23 downto 0) & "00"
              when (F_field = "10" and instruction(23) = '0') else
              "111111" & instruction(23 downto 0) & "00"
              when (F_field = "10" and instruction(23) = '1');
              
    process(tclk)
    begin
            
            if (reset='1') then
                pc <= 0;
    
            elsif(tclk='1' and tclk'event) then
                
                if(instr_class = DP) then
    
                    if(i_decoded = add) then
                        RF(rd) <= std_logic_vector(unsigned(RF(rn)) + unsigned(rm));
                        pc <= pc+1;
                    elsif(i_decoded = sub) then
                        RF(rd) <= std_logic_vector(unsigned(RF(rn)) - unsigned(rm));
                        pc <= pc+1;
    
                    elsif(i_decoded = mov) then
                        RF(rd) <= rm;
                        pc <= pc+1;
    
                    elsif(i_decoded = cmp) then
                        RF(rd) <= std_logic_vector(unsigned(RF(rn)) - unsigned(rm));
                        
                        if(RF(rd) = "00000000000000000000000000000000") then
                            flag_Z <= '1';
                        else
                            flag_Z <= '0';
                        end if;
    
                        pc <= pc+1;
                    else
                    end if;
    
                elsif(instr_class = DT) then
                    if(i_decoded = ldr) then
                        --RF(rd) <= data_memory(rn + to_integer(signed(rm)));
                        if(call_ldr = '0') then
                            addr_data_memory <= to_integer(signed(RF(rn))) + to_integer(signed(rm));
                            call_ldr <= '1';
                        else
                            RF(rd) <= data_in;
                            call_ldr <= '0';
                            pc <= pc+1;
                        end if;
                    elsif(i_decoded = str) then
                        wr_enb <= '1';
                        data_out<=RF(rd);
                        addr_data_memory <= to_integer(signed(RF(rn))) + to_integer(signed(rm)) ;
                        pc <= pc+1;
                    else
                        pc <= pc+1;
                    end if;
    
                    
                elsif(instr_class = branch) then
                                    
                    if(i_decoded = b) then
                        pc <= pc + 2 + (to_integer(signed(rm))/4);
                    elsif((i_decoded = beq) and (flag_Z = '1') ) then
                        pc <= pc + 2 + (to_integer(signed(rm))/4);
                    elsif((i_decoded = bne) and (flag_Z = '0') ) then
                        pc <= pc + 2 + (to_integer(signed(rm))/4);
                    else
                        pc <= pc + 1;
                    end if;
                else
                end if;
            end if;
    end process;
end Behavioral;