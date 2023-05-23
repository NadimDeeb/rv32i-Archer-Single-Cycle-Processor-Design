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
-- Branch comparator

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.archer_pkg.all;

entity branch_cmp is
    port (
        inputA : in std_logic_vector(XLEN-1 downto 0);
        inputB : in std_logic_vector(XLEN-1 downto 0);
        cond : in std_logic_vector(2 downto 0);
        result : out std_logic
    );
end branch_cmp;

architecture rtl of branch_cmp is
  signal res_eq : std_logic; -- equal
  signal res_ne : std_logic; -- not equal
  signal res_lt : std_logic; -- less than
  signal res_ge : std_logic; -- greater than or equal
  signal res_ltu : std_logic; -- less than unsigned
  signal res_geu : std_logic; -- greater than or equal unsigned
begin
    res_eq <= '1' when inputA = inputB else '0';
    res_ne <= '1' when inputA /= inputB else '0';
    res_lt <= '1' when signed(inputA) < signed(inputB) else '0';
    res_ge <= '1' when signed(inputA) >= signed(inputB) else '0';
    res_ltu <= '1' when unsigned(inputA) < unsigned(inputB) else '0';
    res_geu <= '1' when unsigned(inputA) >= unsigned(inputB) else '0';

    -- cond values match func3 field values for corresponding RV32I branch instructions
    with cond select
        result <=   res_eq when BR_COND_EQ,
                    res_ne when BR_COND_NE,
                    res_lt when BR_COND_LT,
                    res_ge when BR_COND_GE,
                    res_ltu when BR_COND_LTU,
                    res_geu when BR_COND_GEU,
                    '0' when others;

end architecture;