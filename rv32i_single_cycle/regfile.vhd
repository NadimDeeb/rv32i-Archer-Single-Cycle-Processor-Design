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
-- 32 x XLEN-bit General-Purpose Register File

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.archer_pkg.all;

entity regfile is
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
end regfile;

architecture rtl of regfile is
    type reg_file is array (0 to 2**LOG2_XRF_SIZE-1) of std_logic_vector (XLEN-1 downto 0);
    signal test : std_logic;
begin

    process (clk, rst_n, RegWrite, rs1, rs2, rd, datain) is
        variable RF : reg_file := (X"00000000", X"00000000", X"00000400", others => (others=>'0'));
    begin
        if rst_n = '0' then
            RF := (X"00000000", X"00000000", X"00000400", others => (others=>'0'));  -- initializes sp (x2) to data memory address 1024
        elsif falling_edge(clk) and RegWrite = '1' and rd /= "00000" then
            RF(to_integer(unsigned(rd))) := datain;
            if rd = "00000" then
                test <= '1';
            end if;
        end if;

        regA <= RF(to_integer(unsigned(rs1)));
        regB <= RF(to_integer(unsigned(rs2)));

    end process;

end architecture;