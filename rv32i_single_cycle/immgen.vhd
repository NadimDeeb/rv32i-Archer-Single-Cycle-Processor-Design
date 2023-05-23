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
-- Immediate generator

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.archer_pkg.all;

entity immgen is
    port (
        instruction : in std_logic_vector (XLEN-1 downto 0);
        immediate : out std_logic_vector (XLEN-1 downto 0)
    );
end immgen;

architecture rtl of immgen is
    signal opcode : std_logic_vector (6 downto 0);
    signal i_type_immed : std_logic_vector (XLEN-1 downto 0);
    signal s_type_immed : std_logic_vector (XLEN-1 downto 0);
    signal b_type_immed : std_logic_vector (XLEN-1 downto 0);
    signal j_type_immed : std_logic_vector (XLEN-1 downto 0);
    signal u_type_immed : std_logic_vector (XLEN-1 downto 0);
    signal y_type_immed : std_logic_vector (XLEN-1 downto 0);
begin

    opcode <= instruction(6 downto 0);

    i_type_immed <= (XLEN-1 downto 12 => instruction(31)) & instruction(31 downto 20);
    y_type_immed <= (XLEN-1 downto 12 => '0') &instruction(31 downto 20);
    s_type_immed <= (XLEN-1 downto 12 => instruction(31)) & instruction(31 downto 25) & instruction(11 downto 7);
    b_type_immed <= (XLEN-1 downto 13 =>instruction(31)) & instruction(31) & instruction(7) & instruction(30 downto 25) & instruction(11 downto 8) & '0';
    j_type_immed <= (XLEN-1 downto 21 =>instruction(31)) & instruction(31) & instruction(19 downto 12) & instruction(20) & instruction(30 downto 21) & '0';
    u_type_immed <= instruction(31 downto 12) & X"000";

    with opcode select
        immediate <=    i_type_immed when OPCODE_IMM | OPCODE_LOAD | OPCODE_JALR, -- arithmetic immed/logic immed/shift; load; jalr
                        s_type_immed when OPCODE_STORE, -- store
                        b_type_immed when OPCODE_BRANCH, -- branch
                        j_type_immed when OPCODE_JAL, -- jal
                        u_type_immed when OPCODE_LUI | OPCODE_AUIPC, -- lui or auipc
                        y_type_immed when OPCODE_SYSTEM, -- jal
                        (others=>'0') when others;

end architecture;