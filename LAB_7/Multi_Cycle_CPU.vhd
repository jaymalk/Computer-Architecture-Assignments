library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Data_Type.all;


entity CPU_MULTI is
    Port (
            -- Input Parameters
            main_clock, reset: in std_logic;
            instruction, data_in: in std_logic_vector(31 downto 0);
            PC_Start: in integer;
            step, go: in std_logic;
            -- Output Parameters
            addr_prMemory, addr_data_memory: out integer;
            data_out: out std_logic_vector(31 downto 0);
            wr_enb: out std_logic;
            dummyRF: out register_file_type
          );
end CPU_MULTI;


architecture Behavioral of CPU_MULTI is

    -- Signal for capturing conditiona and opcode
    signal Condition, Opcode: std_logic_vector(3 downto 0);

    -- Signal for capturing F_Class (which will help decide instruction class)
    signal F_Class: std_logic_vector(1 downto 0);

    -- Signal for capturing IPUBWL (6 bit offset) in DT instructions
    signal Immediate, Load_Store, Pre_Post, Up_Down, Byte, Write_Back: std_logic;
    
    -- Signal for capturing shift specification
    signal Shift: std_logic_vector(7 downto 0);

    -- Signal for categorizing instructions in classes
    signal class: instruction_class;

    -- Signal representing the actual instruction
    signal current_ins: instruction_type := unknown;

    -- Signal, which is a helper for 'ldr' function
    signal call_ldr : std_logic := '0';

    -- Signal for current and destination registers
    signal RD, RN: std_logic_vector(3 downto 0);
    
    -- Value associated with the third operand (RM or llM)
    signal RM_val: std_logic_vector(31 downto 0);

    -- Values held by RM and RN (which may be used by ALU)
    signal A, B : std_logic_vector(31 downto 0);

    signal RF: register_file_type;

    -- Signal represting the program counter (PC)
    signal PC: integer := 0;

    -- Signal for keeping in check the Z Flag
    signal Zero_Flag: std_logic;
    
    -- State signal and types for the CPU tester FSM
    type flow_type is (initial, cont, oneinstr, onestep, done);
    signal flow: flow_type := initial;

    -- State signal and types for CPU controller FSM (cycle stage)
    type stage_type is (common_first, common_second, third, fourth, fifth_ldr, rest);
    signal stage : stage_type := rest;

begin

    -- Concurrent assignment of the signals from positions in the instruction --

    -- Conditions and F_Class
    Condition <= instruction(31 downto 28);
    F_Class <= instruction(27 downto 26);

    -- IPUBWL for DT instruction
    Immediate <= instruction(25);
    Pre_Post <= instruction(24);
    Up_Down <= instruction(23);
    Byte <= instruction(22);
    Write_Back <= instruction(21);
    Load_Store <= instruction(20);

    -- RN and RD (register address)
    RN <= instruction(19 downto 16);
    RD <= instruction(15 downto 12); 

    -- Shift specification and opcodes
    Shift <= instruction(11 downto 4);
    Opcode <= instruction(24 downto 21);

    -- Deciding instruction class from the F_Class --
    with F_Class select class <=
            DP when "00",
            DT when "01",
            branch when "10",
            unknown when others;

    -- Deciding the current instruction from the opcode and F_Class --
    current_ins <=  -- DP
                    add when (Opcode = "0100" and F_Class = "00") else
                    sub when (Opcode = "0010" and F_Class = "00") else
                    mov when (Opcode = "1101" and F_Class = "00") else
                    cmp when (Opcode = "1010" and F_Class = "00") else
                    -- DT
                    ldr when (Load_Store = '1' and F_Class = "01") else
                    str when (Load_Store = '0' and F_Class = "01") else
                    -- Branching
                    beq when (Condition = "0000" and F_Class = "10") else
                    bne when (Condition = "0001" and F_Class = "10") else
                    b   when (Condition = "1110" and F_Class = "10") else
                    -- Error
                    unknown when others;
    
    -- Providing the value to the last operand (Depending on the situation) --
    RM_val <= 
            -- DP instruction
                -- Third operand is Register
                RF(to_integer(unsigned(instruction(3 downto 0))))   when (F_Class = "00" and Immediate='0') else
                -- Third operand is a vector offset
                "000000000000000000000000" & instruction(7 downto 0)    when (F_Class = "00" and Immediate='1') else
            -- DT instruction
                -- Offset is added
                "00000000000000000000" & instruction(11 downto 0)   when (F_Class = "01" and Up_Down='1') else
                -- Offset is subtracted
                "11111111111111111111" & instruction(11 downto 0)   when (F_Class = "01" and Up_Down='0') else
            -- Branch instruction
                -- Arithmetic shift (& multiplied by 4) | Positive Jump
                "000000" & instruction(23 downto 0) & "00"  when (F_Class = "10" and instruction(23) = '0') else
                -- Arithmetic shift (& multiplied by 4) | Negative Jump
                "111111" & instruction(23 downto 0) & "00"  when (F_Class = "10" and instruction(23) = '1');

    -- Linking signals with OUTPUT values.
    addr_prMemory <= PC;
    dummyRF <= RF;
    

    -- WORKING FSM FOR STEP(ONE/INSTR)/CONTINUOUS
        -- Needs to be modified for other 'oneinstr' function, which shall work with multicycle instruction format
     process(main_clock)
     begin                
        if(main_clock'Event and main_clock = '1') then
            case flow is
                when initial => if(go='1') then flow <= cont; 
                                elsif(step='1') then flow <= onestep; 
                                elsif(reset='1' or (step='0' and go='0')) then flow <= initial;
                                end if;
                when cont =>  if(instruction="00000000000000000000000000000000") then flow<=done;
                              elsif(reset='1') then flow <= initial; 
                              else flow<=cont;
                              end if;
                when done => if(step='0' and go='0') then flow<=initial; 
                             elsif(step='1' or go='1') then flow<=done;
                             elsif(reset='1') then flow <= initial;
                             end if;
                when onestep => flow<=done;
            end case;
        end if;
     end process;
    
    -- MAIN WORKING FOR THE CPU (ALU)
                -- NEW MULTI CYCLE CODE
                -- BASIC AND CRUDE OUTER STRUCTURE ONLY
                -- FOR NOW TESTING FSM IS IGNORED (THESE CAN BE ADDED EASILY LATER ON)
        process(main_clock)
        begin
                if(reset='1')
                    PC <= PC_Start;
                
                elsif(main_clock='1' and main_clock'event) then
                    
                    case stage is

                        when common_first => 
                            PC <= PC+1;             
                            -- Some problem related to this. This might change instruction for further stages.
                            -- Need to review the working of instruction memory (IM and DM are different for now).
                            stage <= common_second;
                        
                        when common_second =>
                            -- Putting the values from RM and RD in A and B
                            A <= RF(to_integer(unsigned(RN)));
                            B <= RM_val; 
                            stage <= third;
                        
                        when third =>
                            if(class = DP) then
                                    -- All cases now on are blanks as need to discuss an RF module to be used in working.
                                    -- These will be filled with that
                            elsif(class = DT) then

                            elsif(class = branch) then

                            else    -- Should not be reached
                            end if;
                            stage <= fourth;
                        
                        when fourth =>
                            if(class = DP) then
                            
                            elsif(current_ins = str) then
                            
                            elsif(current_ins = ldr) then
                            
                            else
                            end if;
                            stage <= common_first; -- Load new instruction !
                            -- There must be a rest state as well review
                        when others =>
                            -- Should not be reached
                    end case;
                end if;
        end process;

                -- OLD SINGLE CYCLE CODE
--     process(main_clock)
--     begin
--             if (reset='1') then
--                 PC <= PC_Start;
                
--             elsif(main_clock='1' and main_clock'event) then
                
--                 if(class = DP) then
    
--                     if(current_ins = add) then
--                         RF(RD) <= std_logic_vector(unsigned(RF(RN)) + unsigned(RM_val));
--                         if(flow=cont or flow=onestep) then PC <= PC+1; end if;
                   
--                     elsif(current_ins = sub) then
--                         RF(RD) <= std_logic_vector(unsigned(RF(RN)) - unsigned(RM_val));
--                         if(flow=cont or flow=onestep) then PC <= PC+1; end if;
    
--                     elsif(current_ins = mov) then
--                         RF(RD) <= RM_val;
--                         if(flow=cont or flow=onestep) then PC <= PC+1; end if;
    
--                     elsif(current_ins = cmp) then
-- --                        RF(RD) <= std_logic_vector(unsigned(RF(RN)) - unsigned(RM_val));
                        
--                         if(RF(RN) = RM_val) then
--                             Zero_Flag <= '1';
--                         else
--                             Zero_Flag <= '0';
--                         end if;
    
--                         if(flow=cont or flow=onestep) then PC <= PC+1; end if;
--                     else
--                     end if;
    
--                 elsif(class = DT) then
--                     if(current_ins = ldr) then
--                         --RF(RD) <= data_memory(RN + to_integer(signed(RM_val)));
--                         if(call_ldr = '0') then
--                             addr_data_memory <= to_integer(signed(RF(RN))) + to_integer(signed(RM_val));
--                             call_ldr <= '1';
--                             wr_enb <= '0';
--                         else
--                             RF(RD) <= data_in;
--                             call_ldr <= '0';
--                             if(flow=cont or flow=done) then PC <= PC+1; end if;
--                         end if;
--                     elsif(current_ins = str) then
--                         wr_enb <= '1';
--                         data_out<=RF(RD);
--                         addr_data_memory <= to_integer(signed(RF(RN))) + to_integer(signed(RM_val)) ;
--                         if(flow=cont or flow=onestep) then PC <= PC+1; end if;
--                     else
--                         if(flow=cont or flow=onestep) then PC <= PC+1; end if;
--                     end if;
    
                    
--                 elsif(class = branch) then
                                    
--                     if(current_ins = b) then
--                        if(flow=cont or flow=onestep) then PC <= PC + 2 + (to_integer(signed(RM_val))/4); end if;
--                     elsif((current_ins = beq) and (Zero_Flag = '1') ) then
--                        if(flow=cont or flow=onestep) then PC <= PC + 2 + (to_integer(signed(RM_val))/4); end if;
--                     elsif((current_ins = bne) and (Zero_Flag = '0') ) then
--                        if(flow=cont or flow=onestep) then  PC <= PC + 2 + (to_integer(signed(RM_val))/4); end if;
--                     else
--                         if(flow=cont or flow=onestep) then PC <= PC+1; end if;
--                     end if;
--                 else
--                 end if;
--             end if;
--     end process;

end Behavioral;