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
-- Program Counter (PC) Register

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.archer_pkg.all;

entity pc is
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
end pc;

architecture rtl of pc is
begin
    process (clk, rst_n) is
        variable pcval : std_logic_vector(XLEN-1 downto 0);
    begin
        if (stalldiv /= '1' and stallmult /= '1' and stallload /= '1') or (mult = '1' and stallmult = '1') or (div = '1' and stalldiv = '1') then
            if rst_n = '0' then
                pcval := (others=>'0');
            elsif rising_edge(clk) then
                pcval := datain;
            end if;
        end if;
        dataout <= pcval;
    end process;
end architecture;