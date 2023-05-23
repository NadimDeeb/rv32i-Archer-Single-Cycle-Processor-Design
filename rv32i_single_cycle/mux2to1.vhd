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
-- 2-to-1 XLEN-bit multiplexer

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.archer_pkg.all;

entity mux2to1 is
    port (
        sel : in std_logic;
        input0 : in std_logic_vector (XLEN-1 downto 0);
        input1 : in std_logic_vector (XLEN-1 downto 0);
        output : out std_logic_vector (XLEN-1 downto 0)
    );
end mux2to1;

architecture rtl of mux2to1 is
begin
    output <=   input0 when sel = '0' else
                input1 when sel = '1' else
                (others=>'0');
end architecture;