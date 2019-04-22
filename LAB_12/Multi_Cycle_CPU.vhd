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
                -- External Exception Handle (IRQ and RESET)
            irq_in, rst_in : in std_logic;

            -- Output Parameters
                -- Address to be sent to instruction memory to get Instruction (PC is sent)
            Address_To_IM: out integer;
                -- Address to be sent to data memory to get data, used by ldr
            Address_To_DM: out integer;
                -- Data to be sent to data memory, used be str
            Data_To_DM: out std_logic_vector(31 downto 0);
                -- Deciding for write and fetch from data memory
            Write_Enable_0, Write_Enable_1, Write_Enable_2, Write_Enable_3: out std_logic;
                -- dummy RF to be used outside
            RF_For_Display: out register_file
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
    signal RD, RN, RS, RM: std_logic_vector(4 downto 0);

    -- Value associated with the third operand (RM or llM)
    signal RM_val, shift_val: std_logic_vector(31 downto 0);

    -- Values held by RM and RN (which may be used by ALU)
    signal A, B : std_logic_vector(31 downto 0);

    -- Register File Data Type (0-15 usr, 16 - CPSR, 17 - R13_svc, 18 - R14_svc, 19 SPSR_svc)
    signal RF: complete_file := (others => (others => '0'));
    alias CPSR      : std_logic_vector(31 downto 0) is RF(16);
    alias R13_svc   : std_logic_vector(31 downto 0) is RF(17);
    alias R14_svc   : std_logic_vector(31 downto 0) is RF(18);
    alias SPSR_svc  : std_logic_vector(31 downto 0) is RF(19);

    -- Signal represting the program counter (PC)
    signal PC: integer := 0;

    -- Signals for preprocessing Shifter parameters
    signal shift_amnt : std_logic_vector(4 downto 0); -- Shift Amount
    signal shift_tp : std_logic_vector(1 downto 0); -- Type of shift
    signal C_Shift : std_logic := '0'; -- C bit from the shifter

    -- Signal for keeping in check the flags
    signal Set_Flag: std_logic := '0';
    
    -- Setting alias with respect to CPSR register
    alias Zero_Flag  : std_logic is CPSR(30);
    alias Carry_Flag : std_logic is CPSR(29);
    alias Neg_Flag   : std_logic is CPSR(31);
    alias Over_Flag  : std_logic is CPSR(28);
    alias IRQ_disable: std_logic is CPSR(7);
    alias mode : std_logic_vector(4 downto 0) is CPSR(4 downto 0);

    -- Signals for new flags from ALU
    signal Zero_Flag_ALU, Carry_Flag_ALU, Neg_Flag_ALU, Over_Flag_ALU: std_logic;

    -- State signal and types for the CPU tester FSM
    type flow_type is (initial, cont, onestep, oneinstr, done);
    signal flow: flow_type := initial;

    -- State signal and types for CPU controller FSM (cycle stage)
    type stage_type is (exception_handle, common_first, common_second, shift_stage, third, fourth, fifth_ldr);
    signal stage : stage_type := common_first ;

    -- Data in and out from Memory
    signal Data_To_DM_0, Data_To_DM_1, Data_To_DM_2, Data_To_DM_3: std_logic_vector(7 downto 0);
    signal Data_From_DM_0, Data_From_DM_1, Data_From_DM_2, Data_From_DM_3: std_logic_vector(7 downto 0);

    -- Signal for keeping the check of predication
    signal check : boolean := false;

    -- New Decoder module
    component Decoder_New
        Port (
            -- Input parameters
            instruction : in std_logic_vector(31 downto 0);
            -- Output parameter
            command : out instruction_type;
            command_class_out : out instruction_class
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

    -- Multiplier component from Multiplier module
    component Multiplier is
        Port (
                -- Input Parameters
                Rd_multiplier, Rn_multiplier, Rs_multiplier, Rm_multiplier : in std_logic_vector(31 downto 0); -- Input Values
                input_instruction : in instruction_type; -- Instruction to follow
    
                -- Output Parameters
                Result_Hi, Result_Lo : out std_logic_vector(31 downto 0); -- Results of Multiplier calculation
                Z_Flag : out std_logic; -- Zero flag
                N_Flag : out std_logic -- Negative flag
              );
    end component;

    -- Predicator component from the predicator module
    component Predicator is
        Port (
              -- Input parameters
              condition : in std_logic_vector(3 downto 0);
              Z : in std_logic;
              C : in std_logic; 
              N : in std_logic; 
              V : in std_logic;
              -- Output parameter
              pass : out boolean
             );
      end component;

    -- Signal for handeling working and result from multiplier
    signal C,D: std_logic_vector(31 downto 0); --input to multiplier
    signal result_hi_from_multiplier, result_lo_from_multiplier: std_logic_vector(31 downto 0);
    signal Zero_Flag_Multiplier, Neg_Flag_Multiplier: std_logic;

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

    -- EXCEPTIONS (Datatypes and signals for working with exceptions)
    type state_access is (usr, svc, unknown);
    signal state : state_access := unknown;
    type exception_type is (rstexn, undexn, swiexn, irqexn, noexn);
    signal exception : exception_type := noexn;
    signal irq, rst : std_logic := '0';

begin

    -- Concurrent assignment of the signals from positions in the instruction (preserved one) --

    -- Setting irq and rst, from input parameters
    irq <= '0' when irq_in = 'U' else
            irq_in;
    rst <= '0' when rst_in = 'U' else
            rst_in;
    
    -- Setting state w.r.t mode bits
    state <= usr when mode = "10000" else
             svc when mode = "10011" else
             unknown;
    
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

    -- RN, RM and RD (register addresses)
    RN <= "10001" when instruction(19 downto 16) = "1110" and state = svc else
          "10010" when instruction(19 downto 16) = "1101" and state = svc else
          '0' & instruction(19 downto 16);
    RD <= "10001" when instruction(15 downto 12) = "1110" and state = svc else
          "10010" when instruction(15 downto 12) = "1101" and state = svc else
          '0' & instruction(15 downto 12);
    RM <= "10001" when instruction(3 downto 0) = "1110" and state = svc else
          "10010" when instruction(3 downto 0) = "1101" and state = svc else
          '0' & instruction(3 downto 0);
    RS <= '0' & instruction(11 downto 8);

    -- Shift specification and opcodes
    Shift <= instruction(11 downto 4);
    Opcode <= instruction(24 downto 21);

    -- Setting SET_FLAG from instruction
    Set_Flag <= instruction(20);

    -- Mapping the decoder with signals
    Decoder : Decoder_New
        Port Map (
            -- Input parameters
            instruction => instruction,
            -- Output parameter
            command => current_ins,
            command_class_out => class
        );

    -- Providing the value to the last operand, without shift (Depending on the situation) --
    RM_val <=
            -- DP instruction
                -- Third operand is Register
                RF(to_integer(unsigned(RM)))   when (class = DP and Immediate='0') else
                -- Third operand is a vector offset
                "000000000000000000000000" & instruction(7 downto 0)    when (class = DP and Immediate='1') else
            -- DT instruction (F = "00") (PLEASE REVIEW U=0)
                -- Offset is complete and added
                "000000000000000000000000" & instruction(11 downto 8) & RM(3 downto 0) when (class = DT and F_Class = "00" and Byte = '1' and Up_Down = '1') else
                -- Offset is complete and subtracted
                std_logic_vector(unsigned(not ("00000000000000000000" & instruction(11 downto 8) & RM(3 downto 0))) + unsigned(std_logic_vector(to_unsigned(1, 32)))) when (class = DT and F_Class = "00" and Byte = '1' and Up_Down = '0') else
                -- Offset is register based and added
                RF(to_integer(unsigned(RM))) when (class = DT and F_Class = "00" and Byte = '0' and Up_Down = '1') else
                -- Offset is register based and subtracted (review below)
                std_logic_vector(unsigned(NOT RF(to_integer(unsigned(RM)))) + unsigned(std_logic_vector(to_unsigned(1, 32)))) when (class = DT and F_Class = "00" and Byte = '0' and Up_Down = '0') else
            -- DT instruction (original)
                -- Offset is complete and added
                "00000000000000000000" & instruction(11 downto 0) when (F_Class = "01" and Up_Down='1' and Immediate = '0') else
                -- Offset is complete and subtracted
                std_logic_vector(unsigned(not ("00000000000000000000" & instruction(11 downto 0))) + unsigned(std_logic_vector(to_unsigned(1, 32)))) when (F_Class = "01" and Up_Down='0' and Immediate = '0') else
                -- Offset is register based and added
                RF(to_integer(unsigned(RM))) when (F_Class = "01" and Up_Down='1' and Immediate = '1') else
                -- Offset is register based and subtracted (review below)
                std_logic_vector(unsigned(NOT RF(to_integer(unsigned(RM)))) + unsigned(std_logic_vector(to_unsigned(1, 32)))) when (F_Class = "01" and Up_Down='0' and Immediate = '1') else
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
        -- DP
            -- Immediate Flag Set (ROR only)
            "11" when (F_Class = "00" and Immediate='1') else
            -- Immediate Flag not set
            instruction(6 downto 5) when  (F_Class = "00" and Immediate='0') else
        -- DT
            instruction(6 downto 5) when  (F_Class = "01" and Immediate='1');

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

    -- Mapping the multiplier with parameters
    Multiplier_ref : Multiplier
    Port Map(
        -- Input Parameters
        Rd_multiplier => A,
        Rn_multiplier => B,
        Rs_multiplier => C,
        Rm_multiplier => D,
        input_instruction => current_ins, -- Instruction to follow
    
        -- Output Parameters
        Result_Hi => result_hi_from_multiplier,
        Result_Lo => result_lo_from_multiplier, -- Results of Multiplier calculation
        Z_Flag => Zero_Flag_Multiplier,
        N_Flag => Neg_Flag_Multiplier
    );
    
    -- Mapping predicator parameters
    Decider : Predicator
    Port Map(
        -- Input parameters
        condition => Condition,
        Z => Zero_Flag,
        C => Carry_Flag,
        N => Neg_Flag,
        V => Over_Flag,
        -- Output parameters
        pass => check
    );

    -- Linking signals with OUTPUT values.
    PC <= to_integer(unsigned(RF(15)));
    Address_To_IM <= PC;
    RF_For_Display <= register_file(RF(15) & RF(18 downto 17) & RF(12 downto 0)) when state = svc else
                      register_file(RF(15 downto 0));

    -- Dividing the data components byte-wise
    Data_From_DM_3 <= Data_From_DM(31 downto 24);
    Data_From_DM_2 <= Data_From_DM(23 downto 16);
    Data_From_DM_1 <= Data_From_DM(15 downto 8);
    Data_From_DM_0 <= Data_From_DM(7 downto 0);
    -- Making individual bytes into one word
    Data_To_DM <= Data_To_DM_3 & Data_To_DM_2 & Data_To_DM_1 & Data_To_DM_0 ; 

    -- BOTH FMS'S FOR STAGE && FLOW_COMMAND
        -- WORKING FSM FOR STEP(ONE/INSTR)/CONTINUOUS
        -- MAIN WORKING FOR THE CPU (ALU)
    process(main_clock)
    begin

        ------------------------------------------
        -- CPU FSM
            if(reset='1') then
                RF(15) <= std_logic_vector(to_unsigned(PC_Start, 32));
                stage <= common_first;
                flow <= initial;
    
            elsif(main_clock='1' and main_clock'event) then
                -- Deciding the current stage
                case stage is
                
                    -- Stage for Exception Handling
                    when exception_handle =>
                        -- Saving return address in R14_svc
                        R14_svc <= RF(15);
                        -- Saving CPSR in SPSR_svc
                        SPSR_svc <= CPSR;
                        -- Setting new mode
                        mode <= "10011";
                        -- Disabling IRQ_enable
                        IRQ_disable <= '1';
                        -- Setting Address
                        if (exception = rstexn) then 
                            RF(15) <= "00000000000000000000000000000000";
                        elsif (exception = undexn) then
                            RF(15) <= "00000000000000000000000000000100";
                        elsif (exception = swiexn) then
                            RF(15) <= "00000000000000000000000000001000";
                        else -- irqexn
                            RF(15) <= "00000000000000000000000000010010";
                        end if;
                        -- Starting again
                        stage <= common_first;
                        
                    -- First stage (Common in all)
                    when common_first =>
                        if(flow = onestep or flow = oneinstr or flow = cont) then
                            if(irq = '1' and not IRQ_disable = '1') then -- Instruction not exceuted and saved
                                exception <= irqexn;
                                stage <= exception_handle;
                            else
                                if(not(instruction="00000000000000000000000000000000"))then
                                    -- Increment PC
                                    RF(15) <= std_logic_vector(to_unsigned(PC+1, 32));
                                end if;
                                    -- Store instruction
                                    instruction <= Instruction_From_IM;
                                    -- Go to next stage
                                    if(rst = '1') then
                                        exception <= rstexn;
                                        stage <= exception_handle;
                                    else
                                        stage <= common_second;
                                    end if;
                                    -- Disabling Write_Enable
                                    Write_Enable_0 <= '0';
                                    Write_Enable_1 <= '0';
                                    Write_Enable_2 <= '0';
                                    Write_Enable_3 <= '0';
                           end if;
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
                            if (rst = '1') then
                                exception <= rstexn;
                                stage <= exception_handle;
                            elsif (current_ins = unknown) then
                                exception <= undexn;
                                stage <= exception_handle;
                            elsif(not check) then
                                stage <= common_first;
                                flow <= done;
                            elsif (current_ins = swi) then
                                exception <= swiexn;
                                stage <= exception_handle;
                            elsif (class = DP or ((current_ins = ldr or current_ins = str or current_ins = ldrb or current_ins = strb) and  Immediate = '1') ) then
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
                            -- Moving to next stage
                            if (rst = '1') then
                                exception <= rstexn;
                                stage <= exception_handle;
                            else
                                stage <= third;
                            end if;
                        elsif (flow = done) then
                            if(instruction = "00000000000000000000000000000000") then
                                stage <= common_first;
                            end if;
                        end if;
    
                    -- Third stage (Common in classes)
                    when third =>
                        if(flow = onestep or flow = oneinstr or flow = cont) then
                            if (rst = '1') then
                                -- RESET EXCEPTION CALLED
                                exception <= rstexn;
                                stage <= exception_handle;
                            -- DP and DT instructions
                            elsif(class = DP or class = DT) then
                                    -- DP and DT instructions go to fourth stage
                                        stage <= fourth;
                                    -- Get result from ALU (in next cycle)
                                    ALU_ON <= '1';
                            
                            elsif(class = MUL)then
                                B <= RF(to_integer(unsigned(RD)));
                                C <= RF(to_integer(unsigned(RS)));
                                D <= RF(to_integer(unsigned(RM)));
                                stage <= fourth;
    
                            -- Branch instructions
                            elsif(class = branch) then
                                -- Instruction complete, set flow to done
                                flow <= done;
                                -- Branch instructions complete here (go to common stage)
                                stage <= common_first;
                                -- If link register is to be set then, (PC) is sent to R14
                                RF(14) <= std_logic_vector(to_unsigned(PC, 32));
                                -- Branch instruction executes on predicate check only
                                RF(15) <= std_logic_vector(to_unsigned(PC + 1 + (to_integer(signed(B))/4), 32));
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
                            if (rst = '1') then
                                -- RESET EXCEPTION CALLED
                                exception <= rstexn;
                                stage <= exception_handle;
                            elsif(class = DP) then
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
                                    -- Setting Z & N irrespective of type of DP
                                    Zero_FLag <= Zero_FLag_ALU;
                                    Neg_Flag <= Neg_Flag_ALU;
                                    -- Setting V & C w.r.t. to constraints on setting
                                    if(current_ins = sub or current_ins = rsb or current_ins = add or current_ins = adc or current_ins = sbc or current_ins = rsc or current_ins = cmp or current_ins = cmn) then
                                        Over_Flag <= Over_Flag_ALU;
                                        Carry_Flag <= Carry_Flag_ALU;
                                    else
                                        if(not shift_amnt = "00000") then
                                            Carry_Flag <= C_Shift;
                                        end if;
                                    end if;
                                end if;
                            
                            elsif(class = MUL) then
                                stage <= common_first;
                                flow <= done;

                                if(current_ins = mul or current_ins = mla) then
                                    RF(to_integer(unsigned(RN))) <= result_lo_from_multiplier;
                                elsif(current_ins = smull or current_ins = smlal or current_ins = umull or current_ins = umlal) then
                                    RF(to_integer(unsigned(RN))) <= result_hi_from_multiplier;
                                    RF(to_integer(unsigned(RD))) <= result_lo_from_multiplier;
                                end if;
                                -- If set flag is on, then set the flags to flags from Multiplier
                                if(Set_Flag = '1') then
                                    -- Setting Z & N irrespective of type of MUL
                                    Zero_FLag <= Zero_FLag_Multiplier;
                                    Neg_Flag <= Neg_Flag_Multiplier;
                                end if;
                                
                            elsif(class = DT)then
                            
                                if((current_ins = ldr) or (current_ins = ldrh) or (current_ins = ldrb) or (current_ins = ldrsb) or (current_ins = ldrsh)) then
                                    -- 'ldr' instruction goes to stage five
                                    stage <= fifth_ldr;
                                    Address_To_DM <= to_integer(unsigned((result_from_ALU(31 downto 2))))*4;
                        
                                elsif(current_ins = str) then
                                    -- 'str' instruction complete here
                                    stage <= common_first;
                                    -- Instruction complete, set flow to done
                                    flow <= done;
                                    -- Enabling Write_Back in Data Memory
                                    Write_Enable_0 <= '1';
                                    Write_Enable_1 <= '1';
                                    Write_Enable_2 <= '1';
                                    Write_Enable_3 <= '1';
                                    -- 'str' related operations
                                    --Data_To_DM <= RF(to_integer(unsigned(RD)));
                                    Data_To_DM_3 <= RF(to_integer(unsigned(RD)))(31 downto 24);
                                    Data_To_DM_2 <= RF(to_integer(unsigned(RD)))(23 downto 16);
                                    Data_To_DM_1 <= RF(to_integer(unsigned(RD)))(15 downto 8);
                                    Data_To_DM_0 <= RF(to_integer(unsigned(RD)))(7 downto 0);
                                    Address_To_DM <= to_integer(unsigned(result_from_ALU(31 downto 2)))*4;

                                elsif(current_ins = strh) then
                                    -- 'str' instruction complete here
                                    stage <= common_first;
                                    -- Instruction complete, set flow to done
                                    flow <= done;
                                    Address_To_DM <= to_integer(unsigned(result_from_ALU(31 downto 2)))*4;
                                    if(result_from_ALU(1 downto 0) = "00") then
                                        -- Write Enable (The first two bytes)
                                        Write_Enable_0 <= '1';
                                        Write_Enable_1 <= '1';
                                        -- Send data to 
                                        Data_To_DM_0 <= RF(to_integer(unsigned(RD)))(7 downto 0);
                                        Data_To_DM_1 <= RF(to_integer(unsigned(RD)))(15 downto 8);
                                    elsif (result_from_ALU(1 downto 0) = "10")  then
                                        -- Write Enable (The first two bytes)
                                        Write_Enable_3 <= '1';
                                        Write_Enable_2 <= '1';
                                        -- Send data to 
                                        Data_To_DM_2 <= RF(to_integer(unsigned(RD)))(7 downto 0);
                                        Data_To_DM_3 <= RF(to_integer(unsigned(RD)))(15 downto 8);
                                    end if;

                                elsif(current_ins = strb) then
                                    -- 'str' instruction complete here
                                    stage <= common_first;
                                    -- Instruction complete, set flow to done
                                    flow <= done;
                                    if(result_from_ALU(1 downto 0) = "00") then
                                        Write_Enable_0 <= '1';
                                        Data_To_DM_0 <= RF(to_integer(unsigned(RD)))(7 downto 0);
                                    elsif(result_from_ALU(1 downto 0) = "01") then
                                        Write_Enable_1 <= '1';
                                        Data_To_DM_1 <= RF(to_integer(unsigned(RD)))(7 downto 0);
                                    elsif(result_from_ALU(1 downto 0) = "10") then
                                        Write_Enable_2 <= '1';
                                        Data_To_DM_2 <= RF(to_integer(unsigned(RD)))(7 downto 0);
                                    elsif(result_from_ALU(1 downto 0) = "11") then
                                        Write_Enable_3 <= '1';
                                        Data_To_DM_3 <= RF(to_integer(unsigned(RD)))(7 downto 0);
                                    end if;
                                    Address_To_DM <= to_integer(unsigned(result_from_ALU(31 downto 2)))*4;
                                
                                end if;

                            end if;
    
                        end if;
    
                    -- Fifth stage (only for ldr instruction)
                    when fifth_ldr =>
                        -- Capturing the loaded data from DM and putting it to destination
                        if(current_ins = ldr) then
                            RF(to_integer(unsigned(RD))) <= Data_From_DM;
                        
                        elsif(current_ins = ldrh) then
                            if(result_from_ALU(1 downto 0) = "00") then
                                RF(to_integer(unsigned(RD))) <= "0000000000000000" & Data_From_DM_1 & Data_From_DM_0;
                            elsif (result_from_ALU(1 downto 0) = "10")  then
                                RF(to_integer(unsigned(RD))) <= "0000000000000000" & Data_From_DM_3 & Data_From_DM_2;
                            end if;

                        elsif(current_ins = ldrb) then
                            if(result_from_ALU(1 downto 0) = "00") then
                                RF(to_integer(unsigned(RD))) <= "000000000000000000000000" & Data_From_DM_0;
                            elsif (result_from_ALU(1 downto 0) = "01")  then
                                RF(to_integer(unsigned(RD))) <= "000000000000000000000000" & Data_From_DM_1;
                            elsif(result_from_ALU(1 downto 0) = "10") then
                                RF(to_integer(unsigned(RD))) <= "000000000000000000000000" & Data_From_DM_2;
                            elsif (result_from_ALU(1 downto 0) = "11")  then
                                RF(to_integer(unsigned(RD))) <= "000000000000000000000000" & Data_From_DM_3;
                            end if;
                        
                        elsif(current_ins = ldrsh) then
                            if(result_from_ALU(1 downto 0) = "00") then
                                if(Data_From_DM_1(7) = '0') then
                                    RF(to_integer(unsigned(RD))) <= ("0000000000000000" & Data_From_DM_1 & Data_From_DM_0);
                                else
                                    RF(to_integer(unsigned(RD))) <= ("1111111111111111" & Data_From_DM_1 & Data_From_DM_0);
                                end if;
                            elsif(result_from_ALU(1 downto 0) = "10")  then
                                if(Data_From_DM_3(7) = '0') then
                                    RF(to_integer(unsigned(RD))) <= ("0000000000000000" & Data_From_DM_3 & Data_From_DM_2);
                                else
                                    RF(to_integer(unsigned(RD))) <= ("1111111111111111" & Data_From_DM_3 & Data_From_DM_2);
                                end if;
                            end if;

                        elsif(current_ins = ldrsb) then
                            if(result_from_ALU(1 downto 0) = "00") then
                                if(Data_From_DM_0(7) = '0') then
                                    RF(to_integer(unsigned(RD))) <= ("000000000000000000000000" & Data_From_DM_0);
                                else
                                    RF(to_integer(unsigned(RD))) <= ("111111111111111111111111" & Data_From_DM_0);
                                end if;
                            elsif (result_from_ALU(1 downto 0) = "01")  then
                                if(Data_From_DM_1(7) = '0') then
                                    RF(to_integer(unsigned(RD))) <= ("000000000000000000000000" & Data_From_DM_1);
                                else
                                    RF(to_integer(unsigned(RD))) <= ("111111111111111111111111" & Data_From_DM_1);
                                end if;
                            elsif(result_from_ALU(1 downto 0) = "10") then
                                if(Data_From_DM_2(7) = '0') then
                                    RF(to_integer(unsigned(RD))) <= ("000000000000000000000000" & Data_From_DM_2);
                                else
                                    RF(to_integer(unsigned(RD))) <= ("111111111111111111111111" & Data_From_DM_2);
                                end if;
                            elsif (result_from_ALU(1 downto 0) = "11")  then
                                if(Data_From_DM_3(7) = '0') then
                                    RF(to_integer(unsigned(RD))) <= ("000000000000000000000000" & Data_From_DM_3);
                                else
                                    RF(to_integer(unsigned(RD))) <= ("111111111111111111111111" & Data_From_DM_3);
                                end if;
                            end if;

                        end if;
                        -- 'ldr' instruction complete here
                        if (rst = '1') then
                            -- RESET EXCEPTION CALLED
                            exception <= rstexn;
                            stage <= exception_handle;
                        else
                            stage <= common_first;
                            -- Instruction complete, set flow to done
                            flow <= done;
                        end if;
                   
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
                
                    when oneinstr => if(reset='1') then
                                        flow<= initial;
                                     end if;
                
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
