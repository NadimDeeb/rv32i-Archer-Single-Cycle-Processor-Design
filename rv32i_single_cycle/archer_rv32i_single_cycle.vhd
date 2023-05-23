--
-- SPDX-License-Identifier: CERN-OHL-P-2.0+
--
-- Copyright (C) 2021 Embedded and Reconfigurable Computing Lab, American University of Beirut
-- Contributed by:
-- Mazen A. R. Saghir <mazen@aub.edu.lb>
--
-- This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY,
-- INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR
-- A PARTICULAR PURPOSE. Please see the CERN-OHL-P v2 for applicable
-- conditions.
-- Source location: https://github.com/ERCL-AUB/archer/rv32i_single_cycle
--
-- Archer RV32I single-cycle datapath wrapper (top-level entity)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.archer_pkg.all;

entity archer_rv32i_single_cycle is
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
end archer_rv32i_single_cycle;

architecture rtl of archer_rv32i_single_cycle is
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
            dataout : out std_logic_vector(XLEN-1 downto 0)
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
            csrIn : in std_logic_vector (XLEN-1 downto 0);
            rs1 : in std_logic_vector (4 downto 0);
            csrInst : in std_logic;
            csrAdr : in std_logic_vector (XLEN-1 downto 0);
            csrOut : out std_logic_vector (XLEN-1 downto 0)
        );
    end component;

    -- pc signals
    signal d_pc_in : std_logic_vector (XLEN-1 downto 0);
    signal d_pc_out : std_logic_vector (XLEN-1 downto 0);

    -- imem signals
    signal d_imem_addr : std_logic_vector (ADDRLEN-1 downto 0);
    signal d_instr_word : std_logic_vector (XLEN-1 downto 0);

    -- add4 signals
    signal d_pcplus4 : std_logic_vector (XLEN-1 downto 0);

    -- control signals
    signal c_branch_out : std_logic;
    signal c_jump : std_logic;
    signal c_lui : std_logic;
    signal c_PCSrc : std_logic;
    signal c_reg_write : std_logic;
    signal c_alu_src1 : std_logic;
    signal c_alu_src2 : std_logic;
    signal c_alu_op : std_logic_vector (4 downto 0);
    signal c_csr : std_logic;
    signal c_nop : std_logic;
    signal c_mem_write : std_logic;
    signal c_mem_read : std_logic;
    signal c_mem_to_reg : std_logic;

    -- register file signals

    signal d_reg_file_datain : std_logic_vector (XLEN-1 downto 0);
    signal d_regA : std_logic_vector (XLEN-1 downto 0);
    signal d_regB : std_logic_vector (XLEN-1 downto 0);

    -- immgen signals

    signal d_immediate : std_logic_vector (XLEN-1 downto 0);

    -- lui_mux signals

    signal d_zero : std_logic_vector (XLEN-1 downto 0);
    signal d_lui_mux_out : std_logic_vector (XLEN-1 downto 0);

    -- alu_src1_mux signals 

    signal d_alu_src1 : std_logic_vector (XLEN-1 downto 0);

    -- alu_src2_mux signals 

    signal d_alu_src21 : std_logic_vector (XLEN-1 downto 0);
    signal d_alu_src2 : std_logic_vector (XLEN-1 downto 0);

    -- alu signals

    signal d_alu_out : std_logic_vector (XLEN-1 downto 0);

    -- mem_mux signals

    signal d_mem_mux_out : std_logic_vector (XLEN-1 downto 0);

    -- lmb signals

    signal d_byte_mask : std_logic_vector (1 downto 0);
    signal d_sign_ext_n : std_logic;
    signal d_data_mem_out : std_logic_vector (XLEN-1 downto 0);

    -- CSR
    signal d_csrOut : std_logic_vector (31 downto 0);

    -- instruction word fields

    signal d_rs1 : std_logic_vector (4 downto 0);
    signal d_rs2 : std_logic_vector (4 downto 0);
    signal d_rd : std_logic_vector (4 downto 0);
    signal d_funct3 : std_logic_vector (2 downto 0);
    signal d_funct7 : std_logic_vector (6 downto 0);

begin

    pc_inst : pc port map (clk => clk, rst_n => rst_n, datain => d_pc_in, dataout => d_pc_out);

    limb_inst : lmb port map (proc_addr => d_pc_out, proc_data_send => (others=>'0'), proc_data_receive => d_instr_word,
                              proc_byte_mask => "10", proc_sign_ext_n => '1', proc_mem_write => '0',
                              proc_mem_read => '1', mem_addr => imem_addr, mem_datain => imem_datain, 
                              mem_dataout => imem_dataout, mem_wen => imem_wen, mem_ben => imem_ben);

    add4_inst : add4 port map (datain => d_pc_out, result => d_pcplus4);
    pc_mux : mux2to1 port map (sel => c_PCSrc, input0 => d_pcplus4, input1 => d_alu_out, output => d_pc_in);
    control_inst : control port map (instruction => d_instr_word, BranchCond => c_branch_out, 
                                    Jump => c_jump, Lui => c_lui, PCSrc => c_PCSrc, RegWrite => c_reg_write,
                                    ALUSrc1 => c_alu_src1, ALUSrc2 => c_alu_src2, ALUOp => c_alu_op,CSR => c_csr, NOP => c_nop, MemWrite => c_mem_write,
                                    MemRead => c_mem_read, MemToReg => c_mem_to_reg);
    write_back_mux : mux2to1 port map (sel => c_jump, input0 => d_mem_mux_out, input1 => d_pcplus4, output => d_reg_file_datain);

    RF_inst : regfile port map (clk => clk, rst_n => rst_n, RegWrite => c_reg_write, rs1 => d_rs1, rs2 => d_rs2, 
                                rd => d_rd, datain => d_reg_file_datain, regA => d_regA, regB => d_regB);

    brcmp_inst : branch_cmp port map (inputA => d_regA, inputB => d_regB, cond => d_funct3, result => c_branch_out);

    immgen_inst : immgen port map (instruction => d_instr_word, immediate => d_immediate);


    lui_mux : mux2to1 port map (sel => c_lui, input0 => d_pc_out, input1 => d_zero, output => d_lui_mux_out);

    alu_src1_mux : mux2to1 port map (sel => c_alu_src1, input0 => d_regA, input1 => d_lui_mux_out, output => d_alu_src1);
    alu_src2_mux : mux2to1 port map (sel => c_alu_src2, input0 => d_regB, input1 => d_immediate, output => d_alu_src21);
    csr_mux : mux2to1 port map (sel => c_csr, input0 => d_alu_src21, input1 => d_csrOut, output => d_alu_src2);

    alu_inst : alu port map (inputA => d_alu_src1, inputB => d_alu_src2, ALUop => c_alu_op, result => d_alu_out);

    ldmb_inst : lmb port map (proc_addr => d_alu_out, proc_data_send => d_regB,
                               proc_data_receive => d_data_mem_out, proc_byte_mask => d_byte_mask,
                               proc_sign_ext_n => d_sign_ext_n, proc_mem_write => c_mem_write, proc_mem_read => c_mem_read,
                               mem_addr => dmem_addr, mem_datain => dmem_datain, mem_dataout => dmem_dataout,
                               mem_wen => dmem_wen, mem_ben => dmem_ben);

    mem_mux : mux2to1 port map (sel => c_mem_to_reg, input0 => d_alu_out, input1 => d_data_mem_out, output => d_mem_mux_out);

    CSRCOMP: CSR port map (clk => clk, rst_n => rst_n, instruction => d_instr_word, NOP => c_nop,csrIn => d_alu_out, rs1 => d_rs1, csrInst=> c_csr, csrAdr => d_immediate, csrOut => d_csrOut);


    d_rs1 <= d_instr_word (LOG2_XRF_SIZE+14 downto 15);
    d_rs2 <= d_instr_word (LOG2_XRF_SIZE+19 downto 20);
    d_rd <= d_instr_word (LOG2_XRF_SIZE+6 downto 7);
    d_funct3 <= d_instr_word (14 downto 12);
    d_funct7 <= d_instr_word (31 downto 25);

    d_zero <= (others=>'0');

    d_byte_mask <= d_funct3(1 downto 0);
    d_sign_ext_n <= d_funct3(2);

end architecture;