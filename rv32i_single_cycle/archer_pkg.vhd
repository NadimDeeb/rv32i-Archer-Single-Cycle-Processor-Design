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
-- Archer package

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package archer_pkg is
    constant XLEN : natural := 32;
    constant ADDRLEN : natural := 10;
    constant LOG2_XRF_SIZE : natural := 5;

    -- ALU operations
    constant ALU_OP_ADD : std_logic_vector (4 downto 0) := "00000";
    constant ALU_OP_SUB : std_logic_vector (4 downto 0) := "01000";
    constant ALU_OP_AND : std_logic_vector (4 downto 0) := "00111";
    constant ALU_OP_OR : std_logic_vector (4 downto 0) := "00110";
    constant ALU_OP_XOR : std_logic_vector (4 downto 0) := "00100";
    constant ALU_OP_SLL : std_logic_vector (4 downto 0) := "00001";
    constant ALU_OP_SRL : std_logic_vector (4 downto 0) := "00101";
    constant ALU_OP_SRA : std_logic_vector (4 downto 0) := "01101";
    constant ALU_OP_SLT : std_logic_vector (4 downto 0) := "00010";
    constant ALU_OP_SLTU : std_logic_vector (4 downto 0) := "00011";
    constant ALU_OP_CLR : std_logic_vector (4 downto 0) := "01111";

    constant ALU_OP_MUL : std_logic_vector (4 downto 0) := "10000";
    constant ALU_OP_MULH : std_logic_vector (4 downto 0) := "10001";
    constant ALU_OP_MULHSU : std_logic_vector (4 downto 0) := "10010";
    constant ALU_OP_MULHU : std_logic_vector (4 downto 0) := "10011";

    constant ALU_OP_DIV : std_logic_vector (4 downto 0) := "10100";
    constant ALU_OP_DIVU : std_logic_vector (4 downto 0) := "10101";
    constant ALU_OP_REM : std_logic_vector (4 downto 0) := "10110";
    constant ALU_OP_REMU : std_logic_vector (4 downto 0) := "10111";    

    -- branch conditions
    constant BR_COND_EQ : std_logic_vector (2 downto 0) := "000";
    constant BR_COND_NE : std_logic_vector (2 downto 0) := "001";
    constant BR_COND_LT : std_logic_vector (2 downto 0) := "100";
    constant BR_COND_GE : std_logic_vector (2 downto 0) := "101";
    constant BR_COND_LTU : std_logic_vector (2 downto 0) := "110";
    constant BR_COND_GEU : std_logic_vector (2 downto 0) := "111";

    -- instruction opcodes
    constant OPCODE_LUI : std_logic_vector (6 downto 0) := "0110111";
    constant OPCODE_AUIPC : std_logic_vector (6 downto 0) := "0010111";
    constant OPCODE_JAL : std_logic_vector (6 downto 0) := "1101111";
    constant OPCODE_JALR : std_logic_vector (6 downto 0) := "1100111";
    constant OPCODE_BRANCH : std_logic_vector (6 downto 0) := "1100011"; -- branch instruction
    constant OPCODE_LOAD : std_logic_vector (6 downto 0) := "0000011"; -- load instruction
    constant OPCODE_STORE : std_logic_vector (6 downto 0) := "0100011"; -- store instruction
    constant OPCODE_IMM : std_logic_vector (6 downto 0) := "0010011"; -- immediate arithmetic, logic, shift, and slt instruction
    constant OPCODE_RTYPE : std_logic_vector (6 downto 0) := "0110011"; -- R-Type arithmetic, logic, shift, and slt instructions
    constant OPCODE_SYSTEM : std_logic_vector (6 downto 0) := "1110011";
end package; 