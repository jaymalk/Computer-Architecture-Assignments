library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Data_Type.all;


entity CPU_MULTI is
    Port (
            -- Input Parameters
            main_clock, reset: in std_logic;
                -- Instruction from instruction memory
            Instruction_From_IM: in std_logic_vector(31 downto 0);
                -- Data from data memory, to be used by str
            Data_From_DM: in std_logic_vector(31 downto 0);
                -- Initialiser for PC for a program
            PC_Start: in integer;
                -- Variables which handle user input for testing FSM
            step, go, instr: in std_logic;

            -- Output Parameters
                -- Address to be sent to instruction memory to get Instruction (PC is sent)
            Address_To_IM: out integer;
                -- Address to be sent to data memory to get data, used by ldr
            Address_To_DM: out integer;
                -- Data to be sent to data memory, used be str
            Data_To_DM: out std_logic_vector(31 downto 0);
                -- Deciding for write and fetch from data memory
            Write_Enable: out std_logic;
                -- dummy RF to be used outside
            RF_For_Display: out register_file_datatype
          );
end entity;


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

    -- Signal for multicycle handeling, to keep the original instruction (per cycle) preserved
    signal instruction : std_logic_vector(31 downto 0);

    -- Signal, which is a helper for 'ldr' function
    signal call_ldr : std_logic := '0';

    -- Signal for current and destination registers
    signal RD, RN: std_logic_vector(3 downto 0);

    -- Value associated with the third operand (RM or llM)
    signal RM_val, shift_val: std_logic_vector(31 downto 0);

    -- Values held by RM and RN (which may be used by ALU)
    signal A, B : std_logic_vector(31 downto 0);

    signal RF: register_file_datatype;

    -- Signal represting the program counter (PC)
    signal PC: integer := 0;

    -- Signals for preprocessing Shifter parameters
    signal shift_amnt : std_logic_vector(4 downto 0); -- Shift Amount
    signal shift_tp : std_logic_vector(1 downto 0); -- Type of shift
    signal C_Shift : std_logic := '0'; -- C bit from the shifter

    -- Signal for keeping in check the flags
    signal Zero_Flag, Carry_Flag, Neg_Flag, Over_Flag, Set_Flag: std_logic;

    -- Signals for new flags from ALU
    signal Zero_Flag_ALU, Carry_Flag_ALU, Neg_Flag_ALU, Over_Flag_ALU: std_logic;

    -- State signal and types for the CPU tester FSM
    type flow_type is (initial, cont, onestep, oneinstr, done);
    signal flow: flow_type := initial;

    -- State signal and types for CPU controller FSM (cycle stage)
    type stage_type is (common_first, common_second, shift_stage, third, fourth, fifth_ldr);
    signal stage : stage_type := common_first ;

    -- Decoder module
    -- component decoder
    --   Port (
    --         -- Input parameters
    --         opcode : in std_logic_vector(3 downto 0); -- Opcode
    --         ls : in std_logic; -- Load_Store bit
    --         cond : in std_logic_vector(3 downto 0); -- Condition
    --         class : in std_logic_vector(1 downto 0); -- (F) class
    --         -- Output parameter
    --         instruction : out instruction_type -- The output instruction
    --        );
    -- end component;

    -- New Decoder module
    component Decoder_New
        Port (
            -- Input parameters
            instruction : in std_logic_vector(31 downto 0);
            -- Output parameter
            command : out instruction_type;
            command_class : out instruction_class
           );
    end component;

    -- ALU component from the ALU module
    component ALU
        Port (
            -- Input Parameters
            work, C: in std_logic;    -- Logic for allowing use
            A_ALU, B_ALU : in std_logic_vector(31 downto 0); -- Input Values
            input_instruction : in instruction_type; -- Instruction to follow

            -- Output Parameters
            result : out std_logic_vector(31 downto 0); -- Result of ALU calculation
            Z_Flag : out std_logic; -- Zero flag
            C_Flag : out std_logic; -- Carry flag
            V_Flag : out std_logic; -- Overflow flag
            N_Flag : out std_logic -- Negative flag
          );
    end component;

    -- Shifter component from the Shifter module
    component Shifter
        Port (
                -- Input Parameters
                input_vector : in std_logic_vector(31 downto 0);   -- Input Vector
                shift_amount : in std_logic_vector(4 downto 0); -- Shift Amount
                shift_type : in std_logic_vector(1 downto 0); -- Shift Type
    
                -- Output Parameters
                output_vector : out std_logic_vector(31 downto 0); -- Result of Shift
                C_bit : out std_logic -- Carry bit
              );
    end component ;

    -- Signal for handeling working and result from ALU
    signal ALU_ON : std_logic := '0';
    signal result_from_ALU : std_logic_vector(31 downto 0);

begin

    -- Concurrent assignment of the signals from positions in the instruction (preserved one) --

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

    -- Write enable with concurrent assignment from Load_Store
    Write_Enable <= not Load_Store;

    -- RN and RD (register address)
    RN <= instruction(19 downto 16);
    RD <= instruction(15 downto 12);

    -- Shift specification and opcodes
    Shift <= instruction(11 downto 4);
    Opcode <= instruction(24 downto 21);

    -- Setting SET_FLAG from instruction
    Set_Flag <= instruction(20);

    -- NOT NEEDED, DECODER DECIDES NOW --
    -- Deciding instruction class from the F_Class --
    -- with F_Class select class <=
    --         DP when "00",
    --         DT when "01",
    --         branch when "10",
    --         unknown when others;


    -- Instruction_Decoder : Decoder
    --     Port Map (
    --         -- Input Parameters
    --         opcode => Opcode,
    --         class => F_Class,
    --         ls => Load_Store,
    --         cond => Condition,
    --         -- Output Paramter
    --         instruction => current_ins -- Assigning the current instruction
    --     );

    Decoder : Decoder_New
        Port Map (
            -- Input parameters
            instruction => instruction,
            -- Output parameter
            command => current_ins,
            command_class => class
        );

    -- Providing the value to the last operand, without shift (Depending on the situation) --
    RM_val <=
            -- DP instruction
                -- Third operand is Register
                RF(to_integer(unsigned(instruction(3 downto 0))))   when (class = DP and Immediate='0') else
                -- Third operand is a vector offset
                "000000000000000000000000" & instruction(7 downto 0)    when (class = DP and Immediate='1') else
            -- DT instruction (F = "00") (PLEASE REVIEW U=0)
                -- Offset is complete and added
                "000000000000000000000000" & instruction(11 downto 8) & instruction(3 downto 0) when (class = DT and F_Class = "00" and Byte = '0' and Up_Down = '1') else
                -- Offset is complete and subtracted
                "111111111111111111111111" & instruction(11 downto 8) & instruction(3 downto 0) when (class = DT and F_Class = "00" and Byte = '0' and Up_Down = '0') else
                -- Offset is register based and added
                RF(to_integer(unsigned(instruction(3 downto 0)))) when (class = DT and F_Class = "00" and Byte = '1' and Up_Down = '1')
                -- Offset is register based and subtracted (review below)
                NOT RF(to_integer(unsigned(instruction(3 downto 0)))) when (class = DT and F_Class = "00" and Byte = '1' and Up_Down = '0')
            -- DT instruction (original)
                -- Offset is complete and added
                "00000000000000000000" & instruction(11 downto 0) when (F_Class = "01" and Up_Down='1' and Immediate = '0') else
                -- Offset is complete and subtracted
                "11111111111111111111" & instruction(11 downto 0) when (F_Class = "01" and Up_Down='0' and Immediate = '0') else
                -- Offset is register based and added
                RF(to_integer(unsigned(instruction(3 downto 0)))) when (F_Class = "01" and Up_Down='1' and Immediate = '1') else
                -- Offset is register based and subtracted (review below)
                NOT RF(to_integer(unsigned(instruction(3 downto 0)))) when (F_Class = "01" and Up_Down='0' and Immediate = '1') else
            -- Branch instruction
                -- Arithmetic shift (& multiplied by 4) | Positive Jump
                "000000" & instruction(23 downto 0) & "00"  when (F_Class = "10" and instruction(23) = '0') else
                -- Arithmetic shift (& multiplied by 4) | Negative Jump
                "111111" & instruction(23 downto 0) & "00"  when (F_Class = "10" and instruction(23) = '1');

    -- Preprocessing the complete shift amount vector from the instruction
    shift_amnt <=
         -- DP shifts
            -- Immediate Flag Set (ROR and Immediate Shift Operand)
                instruction(11 downto 8) & '0' when (class = DP and Immediate='1') else
            -- Immediate Flag not set and Shift amount immediate
                instruction(11 downto 7) when  (class = DP and Immediate='0' and instruction(4) = '0') else
            -- Immediate Flag not set and Shift amount not immediate
                RF(to_integer(unsigned(instruction(11 downto 8))))(4 downto 0) when (class = DP and Immediate='0' and instruction(4) = '1') else
        -- DT shifts
                instruction(11 downto 7) when (class = DT and Immediate='1' and instruction(4) = '0') else
        -- No other possible case
                "00000";
    -- Preprocessing the shift type from the instruction
    shift_tp <=
            -- Immediate Flag Set (ROR only)
            "11" when (F_Class = "00" and Immediate='1') else
            -- Immediate Flag not set
            instruction(6 downto 5) when ((F_Class = "00" and Immediate='0') or (class = DT and Immediate='1'));

    -- Mapping ALU with other signals
    ALU_ref : ALU
        Port Map (
            -- Input paramters
            work => ALU_ON,
            A_ALU => A,
            B_ALU => B,
            C => Carry_Flag,
            input_instruction => current_ins,
            -- Output parameters
            result => result_from_ALU,
            Z_Flag => Zero_FLag_ALU,
            C_Flag => Carry_Flag_ALU,
            V_Flag => Over_Flag_ALU,
            N_Flag => Neg_Flag_ALU
        );

    -- Mapping Shifter with parameters
    Rajat_Shifter : Shifter
        Port Map (
            -- Input paramters
            input_vector => RM_val,
            shift_amount => shift_amnt,
            shift_type => shift_tp,
            -- Output parameters
            output_vector  => shift_val,
            C_bit => C_Shift
        );

    -- Linking signals with OUTPUT values.
    Address_To_IM <= PC;
    RF_For_Display <= RF;


    -- BOTH FMS'S FOR STAGE && FLOW_COMMAND
        -- WORKING FSM FOR STEP(ONE/INSTR)/CONTINUOUS
            -- Modified for oneinstr. Most instructions same, little modification in initial.
        -- MAIN WORKING FOR THE CPU (ALU)
            -- NEW MULTI CYCLE CODE
            -- FOR NOW TESTING FSM IS IGNORED (THESE CAN BE ADDED EASILY LATER ON)
    process(main_clock)
    begin
        ------------------------------------------
        -- CPU FSM
            if(reset='1') then
                PC <= PC_Start;
                stage <= common_first;
                flow <= initial;
    
            elsif(main_clock='1' and main_clock'event) then
                -- Deciding the current stage
                case stage is
    
                    -- First stage (Common in all)
                    when common_first =>
                        if(flow = onestep or flow = oneinstr or flow = cont) then
                            -- Increment PC
                            PC <= PC+1;
                            -- Store instruction
                            instruction <= Instruction_From_IM;
                            -- Go to next stage
                            stage <= common_second;
                        end if;
    
                    -- Second stage (Common in all)
                    when common_second =>
                        if(flow = onestep or flow = oneinstr or flow = cont) then
                            -- Putting the values from RN in A
                            A <= RF(to_integer(unsigned(RN)));
                            -- Pre proccessed (general second operand) to be put in B
                            -- Saves a lot of effort in later cases. (Different from provided ASM)
                            B <= RM_val;
                            -- Go to next stage
                            if(class = DP) then
                                stage <= shift_stage;
                            else
                                stage <= third;
                            end if;
                        end if;

                    -- Intermediate Stage for shifting
                    when shift_stage =>
                        if(flow = onestep or flow = oneinstr or flow = cont) then
                            -- Setting the Shifted value in B
                            B <= shift_val;
                            -- Setting the Shifted C_bit to C_FLag (IF SET FLAG IS SET)
                            if (Set_Flag = '1') then
                                Carry_Flag <= C_Shift;
                            end if;
                            -- Moving to next stage
                            stage <= third;
                        elsif (flow = done) then
                            if(instruction = "00000000000000000000000000000000") then
                                stage <= common_first;
                            end if;
                        end if;
    
                    -- Third stage (Common in classes)
                    when third =>
                        if(flow = onestep or flow = oneinstr or flow = cont) then
                            -- DP instructions
                            if(class = DP) then
                                    -- DP instructions go to fourth stage
                                    stage <= fourth;
                                    -- Get result from ALU (in next cycle)
                                    ALU_ON <= '1';
    
                            -- DT instructions
                            elsif(class = DT) then
                                -- DT instructions go to fourth stage
                                stage <= fourth;
                                -- str instruction
                                if(current_ins = str) then
                                    ALU_ON <= '1';
    
                                -- ldr instruction
                                elsif(current_ins = ldr) then
                                    ALU_ON <= '1';
                                end if;
    
                            -- Branch instructions
                            elsif(class = branch) then
                                -- Instruction complete, set flow to done
                                flow <= done;
                                -- Branch instructions complete here (go to common stage)
                                stage <= common_first;
    
                                if(current_ins = bal) then
                                    PC <= PC + 1 + (to_integer(signed(B))/4);
                                elsif(current_ins = beq and Zero_Flag = '1') then
                                    PC <= PC + 1 + (to_integer(signed(B))/4);
                                elsif(current_ins = bne and Zero_Flag = '0') then
                                    PC <= PC + 1 + (to_integer(signed(B))/4);
                                end if;
                            
                            -- Class is Unknown, return to Common_first
                            else 
                                stage <= common_first;
                            end if;
    
                        end if;
    
                    -- Fourth stage (specific)
                    when fourth =>
                        if(flow = onestep or flow = oneinstr or flow = cont) then
                            -- Turn off the ALU
                            ALU_ON <= '0';
    
                            if(class = DP) then
                                -- DP instructions complete here
                                stage <= common_first;
                                -- Instruction complete, set flow to done
                                flow <= done;
                                -- Save the result from ALU to the desired register
                                -- If that is allowed by the instruction (not by cmp, cmn, tst, teq)
                                if(not(current_ins = tst) and not(current_ins = teq) and not(current_ins = cmp) and not(current_ins = cmn)) then
                                    RF(to_integer(unsigned(RD))) <= result_from_ALU;
                                end if;
                                -- If set flag is on, then set the flags to flags from ALU
                                if(Set_Flag = '1') then
                                    Zero_FLag <= Zero_FLag_ALU;
                                    Carry_Flag <= Carry_Flag_ALU;
                                    Over_Flag <= Over_Flag_ALU;
                                    Neg_Flag <= Neg_Flag_ALU;
                                end if;
    
                            elsif(current_ins = str) then
                                -- 'str' instruction complete here
                                stage <= common_first;
                                -- Instruction complete, set flow to done
                                flow <= done;
                                -- 'str' related operations
                                Data_To_DM <= RF(to_integer(unsigned(RD)));
                                Address_To_DM <= to_integer(unsigned(result_from_ALU));
    
                            elsif(current_ins = ldr) then
                                -- 'ldr' instruction goes to stage five
                                stage <= fifth_ldr;
                                Address_To_DM <= to_integer(unsigned(result_from_ALU));
                            end if;
    
                        end if;
    
                    -- Fifth stage (only for ldr instruction)
                    when fifth_ldr =>
                        -- Capturing the loaded data from DM and putting it to destination
                        if(current_ins = ldr) then
                            RF(to_integer(unsigned(RD))) <= Data_From_DM;
                        end if;
                        -- Instruction complete, set flow to done
                        flow <= done;
                        -- 'ldr' instruction complete here
                        stage <= common_first;
    
                    when others =>
                        -- Should not be reached
                end case;
    ------------------------------------------
    --  FLOW FSM
                case flow is
                    when initial => if(go = '1') then
                                        flow <= cont;
                                    elsif(step = '1') then
                                        flow <= onestep;
                                    elsif(instr = '1') then
                                        flow <= oneinstr;
                                    elsif(reset = '1' or (step = '0' and go = '0' and instr = '0')) then
                                        flow <= initial;
                                    end if;
                
                    when cont =>    if(instruction = "00000000000000000000000000000000") then
                                        flow <= done;
                                    -- The above instruction is always check before the third stage is executed, thus complying with ASM
                                    elsif(reset = '1') then
                                        flow <= initial;
                                    else
                                        flow <= cont;
                                    end if;
                
                    when oneinstr => NULL;
                
                    when onestep => flow<=done;
                
                    when done =>    if(step = '0' and go = '0' and instr='0') then
                                        flow <= initial;
                                    elsif(step = '1' or go = '1' or instr = '1') then
                                        flow <= done;
                                    elsif(reset = '1') then
                                        flow <= initial;
                                    end if;
                end case;
    ------------------------------------------
            end if;
    end process;    
end Behavioral;
