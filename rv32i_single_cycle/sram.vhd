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
-- Data Memory (SRAM module)
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.archer_pkg.all;

entity sram is
    port (
        clk : in std_logic;
        addr : in std_logic_vector (ADDRLEN-1 downto 0);
        datain : in std_logic_vector (XLEN-1 downto 0);
        dataout : out std_logic_vector (XLEN-1 downto 0);
        wen : in std_logic;
        ben : in std_logic_vector (3 downto 0)
    );
end sram;

architecture rtl of sram is
    type memory is array (0 to 2**(ADDRLEN)-1) of std_logic_vector (7 downto 0); -- memory is byte addressable
    signal ram : memory := (others => (others => '0'));
begin

    read_proc: process (addr, ram) is
        variable word_addr : std_logic_vector (ADDRLEN-1 downto 0) := (others => '0');
    begin
        word_addr := addr(ADDRLEN-1 downto 2) & "00";
        dataout <= ram(to_integer(unsigned(word_addr))+3) & ram(to_integer(unsigned(word_addr))+2) & ram(to_integer(unsigned(word_addr))+1) & ram(to_integer(unsigned(word_addr)));
    end process;

    write_proc: process (clk, addr, datain, wen, ben) is
        variable word_addr : std_logic_vector (ADDRLEN-1 downto 0) := (others => '0');
    begin
        word_addr := addr(ADDRLEN-1 downto 2) & "00";
        if rising_edge(clk) and wen = '1' then
            case ben is
                when "0001" => 
                    ram(to_integer(unsigned(word_addr))) <= datain(7 downto 0);
                when "0010" => 
                    ram(to_integer(unsigned(word_addr))+1) <= datain(7 downto 0);
                when "0100" => 
                    ram(to_integer(unsigned(word_addr))+2) <= datain(7 downto 0);
                when "1000" => 
                    ram(to_integer(unsigned(word_addr))+3) <= datain(7 downto 0);
                when "0011" => 
                    ram(to_integer(unsigned(word_addr))) <= datain(7 downto 0);
                    ram(to_integer(unsigned(word_addr))+1) <= datain(15 downto 8);
                when "1100" =>
                    ram(to_integer(unsigned(word_addr))+2) <= datain(7 downto 0);
                    ram(to_integer(unsigned(word_addr))+3) <= datain(15 downto 8);
                when "1111" =>
                    ram(to_integer(unsigned(word_addr))) <= datain(7 downto 0);
                    ram(to_integer(unsigned(word_addr))+1) <= datain(15 downto 8);
                    ram(to_integer(unsigned(word_addr))+2) <= datain(23 downto 16);
                    ram(to_integer(unsigned(word_addr))+3) <= datain(31 downto 24);
                when others =>
                    null;
            end case;
        end if;
    end process;
end architecture;