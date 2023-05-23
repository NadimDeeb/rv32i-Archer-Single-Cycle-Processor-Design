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
-- Arithmetic and Logic Unit (ALU)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.archer_pkg.all;

entity alu is
    port (
        inputA : in std_logic_vector (XLEN-1 downto 0);
        inputB : in std_logic_vector (XLEN-1 downto 0);
        ALUop : in std_logic_vector (4 downto 0);
        result : out std_logic_vector (XLEN-1 downto 0)
    );
end alu;

architecture rtl of alu is
    signal add_result : std_logic_vector (XLEN-1 downto 0);
    signal sub_result : std_logic_vector (XLEN-1 downto 0);
    signal and_result : std_logic_vector (XLEN-1 downto 0);
    signal or_result : std_logic_vector (XLEN-1 downto 0);
    signal xor_result : std_logic_vector (XLEN-1 downto 0);
    signal sll_result : std_logic_vector (XLEN-1 downto 0);
    signal srl_result : std_logic_vector (XLEN-1 downto 0);
    signal sra_result : std_logic_vector (XLEN-1 downto 0);
    signal slt_result : std_logic_vector (XLEN-1 downto 0);
    signal sltu_result : std_logic_vector (XLEN-1 downto 0);
    signal clr_result : std_logic_vector (XLEN-1 downto 0);

    signal mulh_result : std_logic_vector (2*XLEN-1 downto 0);
    signal mulhu_result : std_logic_vector (2*XLEN-1 downto 0);
    signal mulhsu_result : std_logic_vector (2*XLEN downto 0);

    signal div_result : std_logic_vector (XLEN-1 downto 0);
    signal divu_result : std_logic_vector (XLEN-1 downto 0);
    signal rem_result : std_logic_vector (XLEN-1 downto 0);
    signal remu_result : std_logic_vector (XLEN-1 downto 0);
    
     
begin
    
    add_result <= std_logic_vector(signed(inputA) + signed(inputB));
    sub_result <= std_logic_vector(signed(inputA) - signed(inputB));
    and_result <= inputA and inputB;
    clr_result <= (X"FFFFFFFF" xor inputA) and inputB;
    or_result <= inputA or inputB;
    xor_result <= inputA xor inputB;
    sll_result <= std_logic_vector(shift_left(unsigned(inputA), to_integer(unsigned(inputB(4 downto 0)))));
    srl_result <= std_logic_vector(shift_right(unsigned(inputA), to_integer(unsigned(inputB(4 downto 0)))));
    sra_result <= std_logic_vector(shift_right(signed(inputA), to_integer(unsigned(inputB(4 downto 0)))));
    slt_result <= (XLEN-1 downto 1 =>'0')&'1' when signed(inputA) < signed(inputB) else (others=>'0');
    sltu_result <= (XLEN-1 downto 1 =>'0')&'1' when unsigned(inputA) < unsigned(inputB) else (others=>'0');

    mulh_result <= std_logic_vector(signed(inputA) * signed(inputB));
    mulhu_result <= std_logic_vector(unsigned(inputA) * unsigned(inputB));
    mulhsu_result <= std_logic_vector(signed(inputA) * signed('0' & inputB));

    with inputB select
    div_result <= x"FFFFFFFF" when X"00000000",
                std_logic_vector(signed(inputA) / signed(inputB)) when others;
    with inputB select
    divu_result <= x"FFFFFFFF" when X"00000000",
                std_logic_vector(unsigned(inputA) / unsigned(inputB))when others;
    with inputB select
    rem_result <= x"FFFFFFFF" when X"00000000",
                std_logic_vector(signed(inputA) rem signed(inputB)) when others;
    with inputB select
    remu_result <= x"FFFFFFFF" when X"00000000",
                std_logic_vector(unsigned(inputA) rem unsigned(inputB)) when others;

    with ALUop select
    result <=   add_result when ALU_OP_ADD, -- add
                sub_result when ALU_OP_SUB, -- sub
                and_result when ALU_OP_AND, -- and
                or_result when ALU_OP_OR, -- or
                xor_result when ALU_OP_XOR, -- xor
                sll_result when ALU_OP_SLL, -- sll
                srl_result when ALU_OP_SRL, -- srl
                sra_result when ALU_OP_SRA, -- sra
                slt_result when ALU_OP_SLT, -- slt
                sltu_result when ALU_OP_SLTU, -- sltu
                clr_result when ALU_OP_CLR, -- sltu
                mulh_result(XLEN-1 downto 0) when ALU_OP_MUL,
                mulh_result(2*XLEN-1 downto XLEN) when ALU_OP_MULH,
                mulhu_result(2*XLEN-1 downto XLEN) when ALU_OP_MULHU,
                mulhsu_result(2*XLEN-1 downto XLEN) when ALU_OP_MULHSU,
                div_result when ALU_OP_DIV,
                divu_result when ALU_OP_DIVU,
                rem_result when ALU_OP_REM,
                remu_result when ALU_OP_REMU,
                (others=>'0') when others;

end architecture;