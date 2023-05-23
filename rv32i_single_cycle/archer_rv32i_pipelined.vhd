library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.archer_pkg.all;

entity archer_rv32i_pipelined is
    port (
        clk : in std_logic;
        rst_n : in std_logic;
        -- local instruction memory bus interface
        imem_addr : out std_logic_vector (ADDRLEN-1 downto 0);
        imem_datain : out std_logic_vector (XLEN-1 downto 0);
        imem_dataout : in std_logic_vector (XLEN-1 downto 0);
        imem_wen : out std_logic; -- write enable signal
        imem_ben : out std_logic_vector (3 downto 0); -- byte enable signals
        -- local data memory bus interface
        dmem_addr : out std_logic_vector (ADDRLEN-1 downto 0);
        dmem_datain : out std_logic_vector (XLEN-1 downto 0);
        dmem_dataout : in std_logic_vector (XLEN-1 downto 0);
        dmem_wen : out std_logic; -- write enable signal
        dmem_ben : out std_logic_vector (3 downto 0) -- byte enable signals
    );
end archer_rv32i_pipelined;

architecture rtl of archer_rv32i_pipelined is
    component add4
        port (
            datain : in std_logic_vector (XLEN-1 downto 0);
            result : out std_logic_vector (XLEN-1 downto 0)
        );
    end component;

    component alu
        port (
            inputA : in std_logic_vector (XLEN-1 downto 0);
            inputB : in std_logic_vector (XLEN-1 downto 0);
            ALUop : in std_logic_vector (4 downto 0);
            result : out std_logic_vector (XLEN-1 downto 0)
        );
    end component;

    component branch_cmp
        port (
            inputA : in std_logic_vector(XLEN-1 downto 0);
            inputB : in std_logic_vector(XLEN-1 downto 0);
            cond : in std_logic_vector(2 downto 0);
            result : out std_logic
        );
    end component;

    component control
        port (
            instruction : in std_logic_vector (XLEN-1 downto 0);
            BranchCond : in std_logic; -- BR. COND. SATISFIED = 1; NOT SATISFIED = 0
            Jump : out std_logic;
            Lui : out std_logic;
            PCSrc : out std_logic;
            RegWrite : out std_logic;
            ALUSrc1 : out std_logic;
            ALUSrc2 : out std_logic;
            ALUOp : out std_logic_vector (4 downto 0);
            MemWrite : out std_logic;
            CSR : out std_logic;
            NOP : out std_logic;
            MULT : out std_logic;
            DIV : out std_logic;
            BRANCH : out std_logic;
            MemRead : out std_logic;
            MemToReg : out std_logic
        ) ;
      end component; 

    component lmb
        port (
            proc_addr : in std_logic_vector (XLEN-1 downto 0);
            proc_data_send : in std_logic_vector (XLEN-1 downto 0);
            proc_data_receive : out std_logic_vector (XLEN-1 downto 0);
            proc_byte_mask : in std_logic_vector (1 downto 0); -- "00" = byte; "01" = half-word; "10" = word
            proc_sign_ext_n : in std_logic;
            proc_mem_write : in std_logic;
            proc_mem_read : in std_logic;
            mem_addr : out std_logic_vector (ADDRLEN-1 downto 0);
            mem_datain : out std_logic_vector (XLEN-1 downto 0);
            mem_dataout : in std_logic_vector (XLEN-1 downto 0);
            mem_wen : out std_logic; -- write enable signal
            mem_ben : out std_logic_vector (3 downto 0) -- byte enable signals
        );
    end component;

    component immgen
        port (
            instruction : in std_logic_vector (XLEN-1 downto 0);
            immediate : out std_logic_vector (XLEN-1 downto 0)
        );
    end component;

    component imem
        port (
            address : in std_logic_vector (ADDRLEN-1 downto 0);
            dataout : out std_logic_vector (XLEN-1 downto 0)
        );
    end component;

    component mux2to1
        port (
            sel : in std_logic;
            input0 : in std_logic_vector (XLEN-1 downto 0);
            input1 : in std_logic_vector (XLEN-1 downto 0);
            output : out std_logic_vector (XLEN-1 downto 0)
        );
    end component;
    
    component pc
        port (
            clk : in std_logic;
            rst_n : in std_logic;
            datain : in std_logic_vector(XLEN-1 downto 0);
            dataout : out std_logic_vector(XLEN-1 downto 0);

            mult : in std_logic;
            div : in std_logic;
            stallmult : in std_logic;
            stallload : in std_logic;
            stalldiv : in std_logic
        );
    end component;

    component regfile
        port (
            clk : in std_logic;
            rst_n : in std_logic;
            RegWrite : in std_logic;
            rs1 : in std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
            rs2 : in std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
            rd : in std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
            datain : in std_logic_vector (XLEN-1 downto 0);
            regA : out std_logic_vector (XLEN-1 downto 0);
            regB : out std_logic_vector (XLEN-1 downto 0)
        );
    end component;

    component CSR
        port (
            clk : in std_logic;
            rst_n : in std_logic;
            instruction : in std_logic_vector (XLEN-1 downto 0);
            NOP : in std_logic;
            csrIn : in std_logic_vector (XLEN-1  downto 0);
            rs1 : in std_logic_vector (4 downto 0);
            csrInstR : in std_logic;
            csrInstW : in std_logic;
            csrAdrR : in std_logic_vector (XLEN-1  downto 0);
            csrAdrW : in std_logic_vector (XLEN-1  downto 0);
            csrOut : out std_logic_vector (XLEN-1  downto 0)
        );
    end component;

    component ifid is
        port (
            clk : in std_logic;
  
            inpc : in std_logic_vector (XLEN-1 downto 0);
            outpc : out std_logic_vector (XLEN-1 downto 0);
            instin : in std_logic_vector(XLEN -1 downto 0);
            instout : out std_logic_vector(XLEN -1 downto 0);
            funct3: out std_logic_vector (2 downto 0);
            rs1 : out std_logic_vector (4 downto 0);
            rs2 : out std_logic_vector (4 downto 0);
            rd : out std_logic_vector (4 downto 0);

            mult : in std_logic;
            div : in std_logic;
            flush : in std_logic;
            stallmult : in std_logic;
            stallload : in std_logic;
            stalldiv : in std_logic
        ) ;
    end component ;

    component idex is
        port (
            clk : in std_logic;

            instin : in std_logic_vector (XLEN-1 downto 0);
            instout : out std_logic_vector (XLEN-1 downto 0);
            inJump : in std_logic;
            inLui : in std_logic;
            inRegWrite : in std_logic;
            inALUSrc1 : in std_logic;
            inALUSrc2 : in std_logic;
            inALUOp : in std_logic_vector (4 downto 0);
            inMemWrite : in std_logic;
            inCSR : in std_logic;
            inNOP : in std_logic;
            inMemRead : in std_logic;
            inMemToReg : in std_logic;
            inMULT : in std_logic;
            inDIV : in std_logic;
        
            inregA : in std_logic_vector (XLEN-1 downto 0);
            inregB : in std_logic_vector (XLEN-1 downto 0);
            outregA : out std_logic_vector (XLEN-1 downto 0);
            outregB : out std_logic_vector (XLEN-1 downto 0);
            inpc : in std_logic_vector (XLEN-1 downto 0);
            outpc : out std_logic_vector (XLEN-1 downto 0);
        
            inimm: in std_logic_vector (XLEN-1 downto 0);
            infunct3: in std_logic_vector (2 downto 0);
            inrs1: in std_logic_vector (4 downto 0);
            inrs2: in std_logic_vector (4 downto 0);
            inrd: in std_logic_vector (4 downto 0);
        
            outJump : out std_logic;
            outLui : out std_logic;
            outRegWrite : out std_logic;
            outALUSrc1 : out std_logic;
            outALUSrc2 : out std_logic;
            outALUOp : out std_logic_vector (4 downto 0);
            outMemWrite : out std_logic;
            outCSR : out std_logic;
            outNOP : out std_logic;
            outMemRead : out std_logic;
            outMemToReg : out std_logic;
            outMULT : out std_logic;
            outDIV : out std_logic;
        
            outimm: out std_logic_vector (XLEN-1 downto 0);
            outfunct3: out std_logic_vector (2 downto 0);
            outrs1: out std_logic_vector (4 downto 0);
            outrs2: out std_logic_vector (4 downto 0);
            outrd: out std_logic_vector (4 downto 0);
        
            mult : in std_logic;
            div : in std_logic;
            nop : in std_logic;
            stallmult : in std_logic;
            stallload : in std_logic;
            stalldiv : in std_logic
        );
    end component ;

    component exmem is
        port (
            clk : in std_logic;

            instin : in std_logic_vector (XLEN-1 downto 0);
            instout : out std_logic_vector (XLEN-1 downto 0);
            byte_mask : out std_logic_vector (1 downto 0);
            sign_ext_n : out std_logic;
            funct3: in std_logic_vector (2 downto 0);
            inpc : in std_logic_vector (XLEN-1 downto 0);
            outpc : out std_logic_vector (XLEN-1 downto 0);
        
            inalu : in std_logic_vector (XLEN-1 downto 0);
            outalu : out std_logic_vector (XLEN-1 downto 0);
            inregB : in std_logic_vector (XLEN-1 downto 0);
            outregB : out std_logic_vector (XLEN-1 downto 0);
        
            inJump : in std_logic;
            inRegWrite : in std_logic;
            inMemWrite : in std_logic;
            inNOP : in std_logic;
            inMemRead : in std_logic;
            inMemToReg : in std_logic;
        
            inrd: in std_logic_vector (4 downto 0);
        
            outJump : out std_logic;
            outRegWrite : out std_logic;
            outMemWrite : out std_logic;
            outNOP : out std_logic;
            outMemRead : out std_logic;
            outMemToReg : out std_logic;
        
            outrd: out std_logic_vector (4 downto 0);
        
            nop : in std_logic;
            stall: in std_logic
        ) ;
    end component ;

    component memwb is
        port (
            clk : in std_logic;

        instin : in std_logic_vector (XLEN-1 downto 0);
        instout : out std_logic_vector (XLEN-1 downto 0);
        inpc : in std_logic_vector (XLEN-1 downto 0);
        outpc : out std_logic_vector (XLEN-1 downto 0);

        inalu : in std_logic_vector (XLEN-1 downto 0);
        outalu : out std_logic_vector (XLEN-1 downto 0);
        inmem: in std_logic_vector (XLEN-1 downto 0);
        outmem: out std_logic_vector (XLEN-1 downto 0);

        inJump : in std_logic;
        inRegWrite : in std_logic;
        inMemToReg : in std_logic;
        inNOP : in std_logic;
        inrd: in std_logic_vector (4 downto 0);

        outJump : out std_logic;
        outRegWrite : out std_logic;
        outMemToReg : out std_logic;
        outNOP : out std_logic;
        outrd: out std_logic_vector (4 downto 0);

        stall: in std_logic
        ) ;
    end component ;

    component branch_alu is
        port (
            inputA : in std_logic_vector (XLEN-1 downto 0);
            inputB : in std_logic_vector (XLEN-1 downto 0);
            result : out std_logic_vector (XLEN-1 downto 0)
        );
    end component;

    component Forwarding is
        port (
            clk : in std_logic;
            rs1 : in std_logic_vector (4 downto 0);
            rs2 : in std_logic_vector (4 downto 0);
            rs1EX : in std_logic_vector (4 downto 0);
            rs2EX : in std_logic_vector (4 downto 0);
            rs1EXM : in std_logic_vector (4 downto 0);
            rs2EXM : in std_logic_vector (4 downto 0);
            regWEX : in std_logic;
            LOAD : in std_logic;
            LOADEX: in std_logic;
            BRANCH : in std_logic;
            rdEX : in std_logic_vector (4 downto 0);
            regWMEM : in std_logic;
            rd : in std_logic_vector (4 downto 0);
            rdMEM : in std_logic_vector (4 downto 0);
            fex1 : out std_logic;
            fmem1 : out std_logic;
            fex2 : out std_logic;
            fmem2 : out std_logic;
            fex1M : out std_logic;
            fmem1M : out std_logic;
            fex2M : out std_logic;
            fmem2M : out std_logic;
            fex1B : out std_logic;
            fmem1B : out std_logic;
            fex2B : out std_logic;
            fmem2B : out std_logic;

            stall : out std_logic
        ) ;
    end component ;

    -- pc signals
    signal d_pc_in : std_logic_vector (XLEN-1 downto 0);
    signal d_pc_out : std_logic_vector (XLEN-1 downto 0);
    signal d_pc_outID : std_logic_vector (XLEN-1 downto 0);
    signal d_pc_outEX : std_logic_vector (XLEN-1 downto 0);
    signal d_pc_outEX1 : std_logic_vector (XLEN-1 downto 0);
    signal d_pc_outEX2 : std_logic_vector (XLEN-1 downto 0);
    signal d_pc_outEX3 : std_logic_vector (XLEN-1 downto 0);
    signal d_pc_outEX4 : std_logic_vector (XLEN-1 downto 0);
    signal d_pc_outEX5 : std_logic_vector (XLEN-1 downto 0);
    signal d_pc_outMEM : std_logic_vector (XLEN-1 downto 0);
    signal d_pc_outWB : std_logic_vector (XLEN-1 downto 0);

    -- imem signals
    signal d_imem_addr : std_logic_vector (ADDRLEN-1 downto 0);
    signal d_instr_word : std_logic_vector (XLEN-1 downto 0);
    signal d_instr_wordID : std_logic_vector (XLEN-1 downto 0);
    signal d_instr_wordEX : std_logic_vector (XLEN-1 downto 0);
    signal d_instr_wordEX1 : std_logic_vector (XLEN-1 downto 0);
    signal d_instr_wordEX2 : std_logic_vector (XLEN-1 downto 0);
    signal d_instr_wordEX3 : std_logic_vector (XLEN-1 downto 0);
    signal d_instr_wordEX4 : std_logic_vector (XLEN-1 downto 0);
    signal d_instr_wordEX5 : std_logic_vector (XLEN-1 downto 0);
    signal d_instr_wordMEM : std_logic_vector (XLEN-1 downto 0);
    signal d_instr_wordWB : std_logic_vector (XLEN-1 downto 0);

    -- add4 signals
    signal d_pcplus4 : std_logic_vector (XLEN-1 downto 0);
    signal d_pcplus4WB : std_logic_vector (XLEN-1 downto 0);

    -- control signals
    signal c_branch_out : std_logic;
    signal c_jump : std_logic;
    signal c_jumpEX : std_logic;
    signal c_jumpEX1 : std_logic;
    signal c_jumpEX2 : std_logic;
    signal c_jumpEX3 : std_logic;
    signal c_jumpEX4 : std_logic;
    signal c_jumpEX5 : std_logic;
    signal c_jumpMEM : std_logic;
    signal c_jumpWB : std_logic;
    signal c_lui : std_logic;
    signal c_luiEX : std_logic;
    signal c_luiEX1 : std_logic;
    signal c_luiEX2 : std_logic;
    signal c_luiEX3 : std_logic;
    signal c_luiEX4 : std_logic;
    signal c_PCSrc : std_logic;
    signal c_reg_write : std_logic;
    signal c_reg_writeEX : std_logic;
    signal c_reg_writeEX1 : std_logic;
    signal c_reg_writeEX2 : std_logic;
    signal c_reg_writeEX3 : std_logic;
    signal c_reg_writeEX4 : std_logic;
    signal c_reg_writeEX5 : std_logic;
    signal c_reg_writeMEM : std_logic;
    signal c_reg_writeWB : std_logic;
    signal c_alu_src1 : std_logic;
    signal c_alu_src1EX : std_logic;
    signal c_alu_src1EX1 : std_logic;
    signal c_alu_src1EX2 : std_logic;
    signal c_alu_src1EX3 : std_logic;
    signal c_alu_src1EX4 : std_logic;
    signal c_alu_src2 : std_logic;
    signal c_alu_src2EX : std_logic;
    signal c_alu_src2EX1 : std_logic;
    signal c_alu_src2EX2 : std_logic;
    signal c_alu_src2EX3 : std_logic;
    signal c_alu_src2EX4 : std_logic;
    signal c_alu_op : std_logic_vector (4 downto 0);
    signal c_alu_opEX : std_logic_vector (4 downto 0);
    signal c_alu_opEX1 : std_logic_vector (4 downto 0);
    signal c_alu_opEX2 : std_logic_vector (4 downto 0);
    signal c_alu_opEX3 : std_logic_vector (4 downto 0);
    signal c_alu_opEX4 : std_logic_vector (4 downto 0);
    signal c_csr : std_logic;
    signal c_csrEX : std_logic;
    signal c_csrEX1 : std_logic;
    signal c_csrEX2 : std_logic;
    signal c_csrEX3 : std_logic;
    signal c_csrEX4 : std_logic;
    signal c_csrMEM : std_logic;
    signal c_csrWB : std_logic;
    signal c_nop : std_logic;
    signal c_nopEX : std_logic;
    signal c_nopEX1 : std_logic;
    signal c_nopEX2 : std_logic;
    signal c_nopEX3 : std_logic;
    signal c_nopEX4 : std_logic;
    signal c_nopEX5 : std_logic;
    signal c_nopMEM : std_logic;
    signal c_nopWB : std_logic;
    signal c_mem_write : std_logic;
    signal c_mem_writeEX : std_logic;
    signal c_mem_writeEX1 : std_logic;
    signal c_mem_writeEX2 : std_logic;
    signal c_mem_writeEX3 : std_logic;
    signal c_mem_writeEX4 : std_logic;
    signal c_mem_writeEX5 : std_logic;
    signal c_mem_writeMEM : std_logic;
    signal c_mem_read : std_logic;
    signal c_mem_readEX : std_logic;
    signal c_mem_readEX1 : std_logic;
    signal c_mem_readEX2 : std_logic;
    signal c_mem_readEX3 : std_logic;
    signal c_mem_readEX4 : std_logic;
    signal c_mem_readEX5 : std_logic;
    signal c_mem_readMEM : std_logic;
    signal c_mem_to_reg : std_logic;
    signal c_mem_to_regEX : std_logic;
    signal c_mem_to_regEX1 : std_logic;
    signal c_mem_to_regEX2 : std_logic;
    signal c_mem_to_regEX3 : std_logic;
    signal c_mem_to_regEX4 : std_logic;
    signal c_mem_to_regEX5 : std_logic;
    signal c_mem_to_regMEM : std_logic;
    signal c_mem_to_regWB : std_logic;
    signal c_mult : std_logic;
    signal c_multEX : std_logic;
    signal c_multEX1 : std_logic;
    signal c_multEX2 : std_logic;
    signal c_multEX3 : std_logic;
    signal c_multEX4 : std_logic;
    signal c_div : std_logic;
    signal c_divEX : std_logic;
    signal c_divEX1 : std_logic;
    signal c_divEX2 : std_logic;
    signal c_divEX3 : std_logic;
    signal c_divEX4 : std_logic;
    signal c_branch : std_logic;

    -- register file signals

    signal d_reg_file_datain : std_logic_vector (XLEN-1 downto 0);
    signal d_regA : std_logic_vector (XLEN-1 downto 0);
    signal d_regAEX : std_logic_vector (XLEN-1 downto 0);
    signal d_regAEX1 : std_logic_vector (XLEN-1 downto 0);
    signal d_regAEX2 : std_logic_vector (XLEN-1 downto 0);
    signal d_regAEX3 : std_logic_vector (XLEN-1 downto 0);
    signal d_regAEX4 : std_logic_vector (XLEN-1 downto 0);
    signal d_regB : std_logic_vector (XLEN-1 downto 0);
    signal d_regBEX : std_logic_vector (XLEN-1 downto 0);
    signal d_regBEX1 : std_logic_vector (XLEN-1 downto 0);
    signal d_regBEX2 : std_logic_vector (XLEN-1 downto 0);
    signal d_regBEX3 : std_logic_vector (XLEN-1 downto 0);
    signal d_regBEX4 : std_logic_vector (XLEN-1 downto 0);
    signal d_regBEX5 : std_logic_vector (XLEN-1 downto 0);
    signal d_regBMEM : std_logic_vector (XLEN-1 downto 0);

    -- immgen signals

    signal d_immediate : std_logic_vector (XLEN-1 downto 0);
    signal d_immediateEX : std_logic_vector (XLEN-1 downto 0);
    signal d_immediateEX1 : std_logic_vector (XLEN-1 downto 0);
    signal d_immediateEX2 : std_logic_vector (XLEN-1 downto 0);
    signal d_immediateEX3 : std_logic_vector (XLEN-1 downto 0);
    signal d_immediateEX4 : std_logic_vector (XLEN-1 downto 0);
    signal d_immediateMEM : std_logic_vector (XLEN-1 downto 0);
    signal d_immediateWB : std_logic_vector (XLEN-1 downto 0);

    -- lui_mux signals

    signal d_zero : std_logic_vector (XLEN-1 downto 0);
    signal d_lui_mux_out : std_logic_vector (XLEN-1 downto 0);

    -- alu_src1_mux signals 

    signal d_alu_src1E : std_logic_vector (XLEN-1 downto 0);
    signal d_alu_src1M : std_logic_vector (XLEN-1 downto 0);
    signal d_alu_src1EM : std_logic_vector (XLEN-1 downto 0);
    signal d_alu_src1MM : std_logic_vector (XLEN-1 downto 0);
    signal d_alu_src1 : std_logic_vector (XLEN-1 downto 0);

    -- alu_src2_mux signals 

    signal d_alu_src2E : std_logic_vector (XLEN-1 downto 0);
    signal d_alu_src2M : std_logic_vector (XLEN-1 downto 0);
    signal d_alu_src2EM : std_logic_vector (XLEN-1 downto 0);
    signal d_alu_src2MM : std_logic_vector (XLEN-1 downto 0);
    signal d_alu_src21 : std_logic_vector (XLEN-1 downto 0);
    signal d_alu_src2 : std_logic_vector (XLEN-1 downto 0);

    -- alu signals

    signal d_alu_out : std_logic_vector (XLEN-1 downto 0);
    signal d_alu_outEX4 : std_logic_vector (XLEN-1 downto 0);
    signal d_alu_outEX5 : std_logic_vector (XLEN-1 downto 0);
    signal d_alu_outMEM : std_logic_vector (XLEN-1 downto 0);
    signal d_alu_outWB : std_logic_vector (XLEN-1 downto 0);
    signal d_bralu_out : std_logic_vector (XLEN-1 downto 0);


    --branch alu

    signal d_branchalu_out : std_logic_vector (XLEN-1 downto 0);

    -- mem_mux signals

    signal d_mem_mux_out : std_logic_vector (XLEN-1 downto 0);

    -- lmb signals

    signal d_byte_mask : std_logic_vector (1 downto 0);
    signal d_sign_ext_n : std_logic;
    signal d_data_mem_out : std_logic_vector (XLEN-1 downto 0);
    signal d_data_mem_outWB : std_logic_vector (XLEN-1 downto 0);

    -- CSR
    signal d_csrOut : std_logic_vector (31 downto 0);

    -- instruction word fields

    signal d_rs1 : std_logic_vector (4 downto 0);
    signal d_rs1EX : std_logic_vector (4 downto 0);
    signal d_rs1EX1 : std_logic_vector (4 downto 0);
    signal d_rs1EX2 : std_logic_vector (4 downto 0);
    signal d_rs1EX3 : std_logic_vector (4 downto 0);
    signal d_rs1EX4 : std_logic_vector (4 downto 0);
    signal d_rs1MEM : std_logic_vector (4 downto 0);
    signal d_rs1WB : std_logic_vector (4 downto 0);
    signal d_rs2 : std_logic_vector (4 downto 0);
    signal d_rs2EX : std_logic_vector (4 downto 0);
    signal d_rs2EX1 : std_logic_vector (4 downto 0);
    signal d_rs2EX2 : std_logic_vector (4 downto 0);
    signal d_rs2EX3 : std_logic_vector (4 downto 0);
    signal d_rs2EX4 : std_logic_vector (4 downto 0);
    signal d_rd : std_logic_vector (4 downto 0);
    signal d_rdEX : std_logic_vector (4 downto 0);
    signal d_rdEX1 : std_logic_vector (4 downto 0);
    signal d_rdEX2 : std_logic_vector (4 downto 0);
    signal d_rdEX3 : std_logic_vector (4 downto 0);
    signal d_rdEX4 : std_logic_vector (4 downto 0);
    signal d_rdEX5 : std_logic_vector (4 downto 0);
    signal d_rdMEM : std_logic_vector (4 downto 0);
    signal d_rdWB : std_logic_vector (4 downto 0);
    signal d_funct3 : std_logic_vector (2 downto 0);
    signal d_funct3EX : std_logic_vector (2 downto 0);
    signal d_funct3EX1 : std_logic_vector (2 downto 0);
    signal d_funct3EX2 : std_logic_vector (2 downto 0);
    signal d_funct3EX3 : std_logic_vector (2 downto 0);
    signal d_funct3EX4 : std_logic_vector (2 downto 0);
    signal d_funct3MEM : std_logic_vector (2 downto 0);
    signal d_loadstall : std_logic;
    signal d_multstall : std_logic;
    signal d_multstall2 : std_logic;
    signal d_divstall : std_logic;
    signal d_divstall2 : std_logic;
    signal d_nop : std_logic;
    signal d_nopLOAD : std_logic;
    signal d_nopEXMD : std_logic;
    signal c_instrmux : std_logic;

    -- Forwarding
    signal f_mem1 : std_logic;
    signal f_ex1 : std_logic;
    signal f_mem2 : std_logic;
    signal f_ex2 : std_logic;

    signal f_mem1M : std_logic;
    signal f_ex1M : std_logic;
    signal f_mem2M : std_logic;
    signal f_ex2M : std_logic;

    signal f_mem1B : std_logic;
    signal f_ex1B : std_logic;
    signal f_mem2B : std_logic;
    signal f_ex2B : std_logic;

    signal d_outmux1E : std_logic_vector (XLEN-1 downto 0);
    signal d_outmux1M : std_logic_vector (XLEN-1 downto 0);
    signal d_outmux2E : std_logic_vector (XLEN-1 downto 0);
    signal d_outmux2M : std_logic_vector (XLEN-1 downto 0);
    
    signal d_REGPC_mux_out : std_logic_vector (XLEN-1 downto 0);

begin

    pc_inst : pc port map (clk => clk, rst_n => rst_n, datain => d_pc_in, dataout => d_pc_out, stallmult => d_multstall, stalldiv => d_divstall, stallload => d_loadstall, mult => c_mult, div => '0');

    limb_inst : lmb port map (proc_addr => d_pc_out, proc_data_send => (others=>'0'), proc_data_receive => d_instr_word,
                              proc_byte_mask => "10", proc_sign_ext_n => '1', proc_mem_write => '0',
                              proc_mem_read => '1', mem_addr => imem_addr, mem_datain => imem_datain,
                              mem_dataout => imem_dataout, mem_wen => imem_wen, mem_ben => imem_ben);

    add4_inst : add4 port map (datain => d_pc_out, result => d_pcplus4);
    pc_mux : mux2to1 port map (sel => c_PCSrc, input0 => d_pcplus4, input1 => d_bralu_out, output => d_pc_in);

    ifid_inst : ifid port map (clk => clk, inpc => d_pc_out, outpc => d_pc_outID, instin => d_instr_word, flush => c_PCSrc, stallmult => d_multstall, stalldiv => d_divstall, stallload => d_loadstall,
                                funct3 => d_funct3, rs1 => d_rs1, rs2 => d_rs2, rd => d_rd, instout => d_instr_wordID, mult => c_mult, div => '0');

    control_inst : control port map (instruction => d_instr_wordID, BranchCond => c_branch_out,
                                    Jump => c_jump, Lui => c_lui, PCSrc => c_PCSrc, RegWrite => c_reg_write,
                                    ALUSrc1 => c_alu_src1, ALUSrc2 => c_alu_src2, ALUOp => c_alu_op,CSR => c_csr, NOP => c_nop, MemWrite => c_mem_write,
                                    MemRead => c_mem_read, MemToReg => c_mem_to_reg, MULT => c_mult, DIV => c_div, BRANCH => c_branch);
    RF_inst : regfile port map (clk => clk, rst_n => rst_n, RegWrite => c_reg_writeWB, rs1 => d_rs1, rs2 => d_rs2,
                                rd => d_rdWB, datain => d_reg_file_datain, regA => d_regA, regB => d_regB);
    
    REGPC_mux : mux2to1 port map (sel => c_alu_src1, input0 => d_outmux1E, input1 => d_pc_outID, output => d_REGPC_mux_out);
    bralu_inst : branch_alu port map (inputA => d_immediate, inputB => d_REGPC_mux_out, result =>d_bralu_out);

    BRFor1M_mux : mux2to1 port map (sel => f_mem1B, input0 => d_regA, input1 => d_reg_file_datain, output => d_outmux1M);
    BRFor1E_mux : mux2to1 port map (sel => f_ex1B, input0 => d_outmux1M, input1 => d_alu_outMEM, output => d_outmux1E);

    BRFor2M_mux : mux2to1 port map (sel => f_mem2B, input0 => d_regB, input1 => d_reg_file_datain, output => d_outmux2M);
    BRFor2E_mux : mux2to1 port map (sel => f_ex2B, input0 => d_outmux2M, input1 => d_alu_outMEM, output => d_outmux2E);


    brcmp_inst : branch_cmp port map (inputA => d_outmux1E, inputB => d_outmux2E, cond => d_funct3, result => c_branch_out);

    immgen_inst : immgen port map (instruction => d_instr_wordid, immediate => d_immediate);

    idex_inst : idex port map(clk => clk, instin =>d_instr_wordID, instout => d_instr_wordEX,inJump => c_jump, inLui => c_lui, inRegWrite => c_reg_write,
                            inALUSrc1 => c_alu_src1, inALUSrc2 => c_alu_src2, inALUOp => c_alu_op, inMemWrite => c_mem_write,inCSR => c_csr,inNOP => c_nop,inMemRead => c_mem_read, inMemToReg => c_mem_to_reg,
                            inregA => d_regA, inregB => d_regB, outregA => d_regAEX, outregB => d_regBEX, inpc => d_pc_outID, outpc => d_pc_outEX, inimm => d_immediate,
                            infunct3 => d_funct3, inrs1 => d_rs1, inrs2 => d_rs2, inrd => d_rd, outJump => c_jumpEX, outLui => c_luiEX, outRegWrite => c_reg_writeEX, outALUSrc1 => c_alu_src1EX, 
                            outALUSrc2 => c_alu_src2EX, outALUOp => c_alu_opEX, outMemWrite => c_mem_writeEX, outCSR => c_csrEX, outNOP => c_nopEX, outMemRead => c_mem_readEX, outMemToReg => c_mem_to_regEX,
                            outimm => d_immediateEX, outfunct3 => d_funct3EX, outrs1 => d_rs1EX, outrs2 => d_rs2EX, outrd => d_rdEX, nop => d_nopLOAD,stallmult => d_multstall, stalldiv => d_divstall, stallload => d_loadstall, inMULT => c_mult, outMult => c_multEX, inDIV => c_div, outDIV => c_divEX, 
                            mult => c_mult, div => '0');

                            idex1_inst : idex port map(clk => clk, instin =>d_instr_wordEX, instout => d_instr_wordEX1,inJump => c_jumpEX, inLui => c_luiEX, inRegWrite => c_reg_writeEX,
                                                        inALUSrc1 => c_alu_src1EX, inALUSrc2 => c_alu_src2EX, inALUOp => c_alu_opEX, inMemWrite => c_mem_writeEX,inCSR => c_csrEX,inNOP => c_nopEX,inMemRead => c_mem_readEX, inMemToReg => c_mem_to_regEX,
                                                        inregA => d_alu_src1E, inregB => d_alu_src2E, outregA => d_regAEX1, outregB => d_regBEX1, inpc => d_pc_outEX, outpc => d_pc_outEX1, inimm => d_immediateEX,
                                                        infunct3 => d_funct3EX, inrs1 => d_rs1EX, inrs2 => d_rs2EX, inrd => d_rdEX, outJump => c_jumpEX1, outLui => c_luiEX1, outRegWrite => c_reg_writeEX1, outALUSrc1 => c_alu_src1EX1, 
                                                        outALUSrc2 => c_alu_src2EX1, outALUOp => c_alu_opEX1, outMemWrite => c_mem_writeEX1, outCSR => c_csrEX1, outNOP => c_nopEX1, outMemRead => c_mem_readEX1, outMemToReg => c_mem_to_regEX1,
                                                        outimm => d_immediateEX1, outfunct3 => d_funct3EX1, outrs1 => d_rs1EX1, outrs2 => d_rs2EX1, outrd => d_rdEX1, nop => d_nopExMD,stallmult => '0', stalldiv => '0', stallload => '0', inMULT => c_multEX, outMult => c_multEX1, inDIV => c_divEX, outDIV => c_divEX1, 
                                                        mult => '1', div => '1');

                            idex2_inst : idex port map(clk => clk, instin =>d_instr_wordEX1, instout => d_instr_wordEX2,inJump => c_jumpEX1, inLui => c_luiEX1, inRegWrite => c_reg_writeEX1,
                                                        inALUSrc1 => c_alu_src1EX1, inALUSrc2 => c_alu_src2EX1, inALUOp => c_alu_opEX1, inMemWrite => c_mem_writeEX1,inCSR => c_csrEX1,inNOP => c_nopEX1,inMemRead => c_mem_readEX1, inMemToReg => c_mem_to_regEX1,
                                                        inregA => d_regAEX1, inregB => d_regBEX1, outregA => d_regAEX2, outregB => d_regBEX2, inpc => d_pc_outEX1, outpc => d_pc_outEX2, inimm => d_immediateEX1,
                                                        infunct3 => d_funct3EX1, inrs1 => d_rs1EX1, inrs2 => d_rs2EX1, inrd => d_rdEX1, outJump => c_jumpEX2, outLui => c_luiEX2, outRegWrite => c_reg_writeEX2, outALUSrc1 => c_alu_src1EX2, 
                                                        outALUSrc2 => c_alu_src2EX2, outALUOp => c_alu_opEX2, outMemWrite => c_mem_writeEX2, outCSR => c_csrEX2, outNOP => c_nopEX2, outMemRead => c_mem_readEX2, outMemToReg => c_mem_to_regEX2,
                                                        outimm => d_immediateEX2, outfunct3 => d_funct3EX2, outrs1 => d_rs1EX2, outrs2 => d_rs2EX2, outrd => d_rdEX2, nop => d_nopExMD,stallmult => '0', stalldiv => '0', stallload => '0', inMULT => c_multEX1, outMult => c_multEX2, inDIV => c_divEX1, outDIV => c_divEX2, 
                                                        mult => '1', div => '1');

                            idex3_inst : idex port map(clk => clk, instin =>d_instr_wordEX2, instout => d_instr_wordEX3,inJump => c_jumpEX2, inLui => c_luiEX2, inRegWrite => c_reg_writeEX2,
                                                        inALUSrc1 => c_alu_src1EX2, inALUSrc2 => c_alu_src2EX2, inALUOp => c_alu_opEX2, inMemWrite => c_mem_writeEX2,inCSR => c_csrEX2,inNOP => c_nopEX2,inMemRead => c_mem_readEX2, inMemToReg => c_mem_to_regEX2,
                                                        inregA => d_regAEX2, inregB => d_regBEX2, outregA => d_regAEX3, outregB => d_regBEX3, inpc => d_pc_outEX2, outpc => d_pc_outEX3, inimm => d_immediateEX2,
                                                        infunct3 => d_funct3EX2, inrs1 => d_rs1EX2, inrs2 => d_rs2EX2, inrd => d_rdEX2, outJump => c_jumpEX3, outLui => c_luiEX3, outRegWrite => c_reg_writeEX3, outALUSrc1 => c_alu_src1EX3, 
                                                        outALUSrc2 => c_alu_src2EX3, outALUOp => c_alu_opEX3, outMemWrite => c_mem_writeEX3, outCSR => c_csrEX3, outNOP => c_nopEX3, outMemRead => c_mem_readEX3, outMemToReg => c_mem_to_regEX3,
                                                        outimm => d_immediateEX3, outfunct3 => d_funct3EX3, outrs1 => d_rs1EX3, outrs2 => d_rs2EX3, outrd => d_rdEX3,nop => d_nopExMD,stallmult => '0', stalldiv => '0', stallload => '0', inMULT => c_multEX2, outMult => c_multEX3, inDIV => c_divEX2, outDIV => c_divEX3, 
                                                        mult => '1', div => '1');

                            idex4_inst : idex port map(clk => clk, instin =>d_instr_wordEX3, instout => d_instr_wordEX4,inJump => c_jumpEX3, inLui => c_luiEX3, inRegWrite => c_reg_writeEX3,
                                                        inALUSrc1 => c_alu_src1EX3, inALUSrc2 => c_alu_src2EX3, inALUOp => c_alu_opEX3, inMemWrite => c_mem_writeEX3, inCSR => c_csrEX3, inNOP => c_nopEX3, inMemRead => c_mem_readEX3, inMemToReg => c_mem_to_regEX3,
                                                        inregA => d_regAEX3, inregB => d_regBEX3, outregA => d_regAEX4, outregB => d_regBEX4, inpc => d_pc_outEX3, outpc => d_pc_outEX4, inimm => d_immediateEX3,
                                                        infunct3 => d_funct3EX3, inrs1 => d_rs1EX3, inrs2 => d_rs2EX3, inrd => d_rdEX3, outJump => c_jumpEX4, outLui => c_luiEX4, outRegWrite => c_reg_writeEX4, outALUSrc1 => c_alu_src1EX4, 
                                                        outALUSrc2 => c_alu_src2EX4, outALUOp => c_alu_opEX4, outMemWrite => c_mem_writeEX4, outCSR => c_csrEX4, outNOP => c_nopEX4, outMemRead => c_mem_readEX4, outMemToReg => c_mem_to_regEX4,
                                                        outimm => d_immediateEX4, outfunct3 => d_funct3EX4, outrs1 => d_rs1EX4, outrs2 => d_rs2EX4, outrd => d_rdEX4, nop => '0',stallmult => '0', stalldiv => '0', stallload => '0', inMULT => c_multEX3, outMult => c_multEX4, inDIV => c_divEX3, outDIV => c_divEX4, 
                                                        mult => '1', div => '1');

                            MulFor1M_mux : mux2to1 port map (sel => f_mem1M, input0 => d_regAEX4, input1 => d_reg_file_datain, output => d_alu_src1MM);
                            MulFor1E_mux : mux2to1 port map (sel => f_ex1M, input0 => d_alu_src1MM, input1 => d_alu_outMEM, output => d_alu_src1EM);

                            MulFor2M_mux : mux2to1 port map (sel => f_mem2M, input0 => d_regBEX4, input1 => d_reg_file_datain, output => d_alu_src2MM);
                            MulFor2E_mux : mux2to1 port map (sel => f_ex2M, input0 => d_alu_src2MM, input1 => d_alu_outMEM, output => d_alu_src2EM);

                            mdalu_inst : alu port map (inputA => d_alu_src1EM, inputB => d_alu_src2EM, ALUop => c_alu_opEX4, result => d_alu_outEX4);

    lui_mux : mux2to1 port map (sel => c_luiEX, input0 => d_pc_outEX, input1 => d_zero, output => d_lui_mux_out);

    ForwardingUnit_inst : Forwarding port map (clk => clk, rs1EX => d_rs1EX, rs2EX => d_rs2EX, rdEX => d_rdMEM, rdMEM => d_rdWB, fex1 => f_ex1, fmem1 => f_mem1, fex2 => f_ex2, fmem2 => f_mem2,
                                                 rs1EXM => d_rs1EX4, rs2EXM => d_rs2EX4, fex1M => f_ex1M, fmem1M => f_mem1M, fex2M => f_ex2M, fmem2M => f_mem2M,
                                                 regWEX => c_reg_writeMEM, regWMEM => c_reg_writeWB, stall => d_loadstall, LOAD => c_mem_readEX, rs1 => d_rs1, rs2 => d_rs2, rd => d_rdEX,
                                                 fex1B => f_ex1B, fmem1B => f_mem1B, fex2B => f_ex2B, fmem2B => f_mem2B, BRANCH => c_branch, LOADEX => c_mem_readMEM);

    
    For1M_mux : mux2to1 port map (sel => f_mem1, input0 => d_regAEX, input1 => d_reg_file_datain, output => d_alu_src1M);
    For1E_mux : mux2to1 port map (sel => f_ex1, input0 => d_alu_src1M, input1 => d_alu_outMEM, output => d_alu_src1E);

    For2M_mux : mux2to1 port map (sel => f_mem2, input0 => d_regBEX, input1 => d_reg_file_datain, output => d_alu_src2M);
    For2E_mux : mux2to1 port map (sel => f_ex2, input0 => d_alu_src2M, input1 => d_alu_outMEM, output => d_alu_src2E);

    alu_src1_mux : mux2to1 port map (sel => c_alu_src1EX, input0 => d_alu_src1E, input1 => d_lui_mux_out, output => d_alu_src1);
    alu_src2_mux : mux2to1 port map (sel => c_alu_src2EX, input0 => d_alu_src2E, input1 => d_immediateEX, output => d_alu_src21);
    
    csr_mux : mux2to1 port map (sel => c_csrEX, input0 => d_alu_src21, input1 => d_csrOut, output => d_alu_src2);

    alu_inst : alu port map (inputA => d_alu_src1, inputB => d_alu_src2, ALUop => c_alu_opEX, result => d_alu_out);

    instr_mux : mux2to1 port map (sel => c_instrmux, input0 => d_instr_wordEX, input1 => d_instr_wordEX4, output => d_instr_wordEX5);
    aluout_mux : mux2to1 port map (sel => c_instrmux, input0 => d_alu_out, input1 => d_alu_outEX4, output => d_alu_outEX5);
    regB_mux : mux2to1 port map (sel => c_instrmux, input0 => d_alu_src2, input1 => d_regBEX4, output => d_regBEX5);
    
    d_rdEX5 <= d_rdEX when c_instrmux = '0' else
            d_rdEX4;
    c_jumpEX5 <= c_jumpEX or c_jumpEX4;
    c_reg_writeEX5 <= c_reg_writeEX or c_reg_writeEX4;
    c_mem_writeEX5 <= c_mem_writeEX or c_mem_writeEX4;
    c_nopEX5 <= c_nopEX and c_nopEX4;
    c_mem_readEX5 <= c_mem_readEX or c_mem_readEX4;
    c_mem_to_regEX5 <= c_mem_to_regEX or c_mem_to_regEX4;


    exmem_inst : exmem port map (clk => clk, instin => d_instr_wordEX5, instout => d_instr_wordMEM, byte_mask => d_byte_mask, sign_ext_n => d_sign_ext_n, funct3 => d_funct3EX, inpc => d_pc_outEX, outpc => d_pc_outMEM, inalu => d_alu_outEX5,
                                outalu => d_alu_outMEM, inregB => d_alu_src2E, outregB => d_regBMEM, inJump => c_jumpEX5, inRegWrite => c_reg_writeEX5, inMemWrite => c_mem_writeEX5, inNOP => c_nopEX5, inMemRead => c_mem_readEX5, 
                                inMemToReg => c_mem_to_regEX5, inrd => d_rdEX5, outJump => c_jumpMEM, outRegWrite => c_reg_writeMEM, outMemWrite => c_mem_writeMEM, outNOP => c_nopMEM, outMemRead => c_mem_readMEM, outMemToReg => c_mem_to_regMEM,
                                outrd => d_rdMEM, stall => '0', nop => d_nop);


    ldmb_inst : lmb port map (proc_addr => d_alu_outMEM, proc_data_send => d_regBMEM,
                               proc_data_receive => d_data_mem_out, proc_byte_mask => d_byte_mask,
                               proc_sign_ext_n => d_sign_ext_n, proc_mem_write => c_mem_writeMEM, proc_mem_read => c_mem_readMEM,
                               mem_addr => dmem_addr, mem_datain => dmem_datain, mem_dataout => dmem_dataout,
                               mem_wen => dmem_wen, mem_ben => dmem_ben);

    memwb_inst : memwb port map (clk => clk, instin => d_instr_wordMEM, instout => d_instr_wordWB, inpc => d_pc_outMEM, outpc => d_pc_outWB, inalu => d_alu_outMEM, outalu => d_alu_outWB, inmem => d_data_mem_out, outmem => d_data_mem_outWB, 
                                inJump => c_jumpMEM, inRegWrite => c_reg_writeMEM, inMemToReg => c_mem_to_regMEM,inNOP => c_nopMEM, inrd => d_rdMEM, outJump => c_jumpWB, outRegWrite => c_reg_writeWB, outMemToReg => c_mem_to_regWB,outNOP => c_nopWB, outrd => d_rdWB, stall => '0'); 

    mem_mux : mux2to1 port map (sel => c_mem_to_regWB, input0 => d_alu_outWB, input1 => d_data_mem_outWB, output => d_mem_mux_out);



    CSRCOMP: CSR port map (clk => clk, rst_n => rst_n, instruction => d_instr_wordEX, NOP => c_nopWB, csrIn => d_alu_out, rs1 => d_rs1EX, csrInstR=> c_csrEX, csrInstW=> c_csrEX, csrAdrR => d_immediateEX, csrAdrW => d_immediateEX, csrOut => d_csrOut);

    write_back_mux : mux2to1 port map (sel => c_jumpWB, input0 => d_mem_mux_out, input1 => d_pcplus4WB , output => d_reg_file_datain);

    d_pcplus4WB <= std_logic_vector(unsigned(d_pc_outWB) + 4);
    d_zero <= (others=>'0');

    d_multstall <= c_multEX or c_multEX1 or c_multEX2 or c_multEX3;
    d_divstall <= c_divEX or c_divEX1 or c_divEX2 or c_divEX3;

    d_multstall <= c_multEX or c_multEX1 or c_multEX2 or c_multEX3;
    d_divstall <= c_divEX or c_divEX1 or c_divEX2 or c_divEX3;

    d_multstall2 <= not d_multstall;
    d_divstall2 <= not d_divstall;

    c_instrmux <= c_multEX4 or c_divEX4;

    d_nop <= c_divEX or c_multEX;

    d_nopLOAD <= d_nop or d_loadstall;

    d_nopEXMD <= '0' when (d_multstall = '1' or d_divstall = '1') else
                '1';

end architecture;