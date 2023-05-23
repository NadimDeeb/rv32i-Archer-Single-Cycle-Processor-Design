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
-- Instruction Memory (program initialized ROM)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.archer_pkg.all;

entity rom is
    port (
        addr : in std_logic_vector (ADDRLEN-1 downto 0);
        dataout : out std_logic_vector (XLEN-1 downto 0)
    );
end rom;

architecture rtl of rom is
    type memory is array (0 to 2**(ADDRLEN)-1) of std_logic_vector (7 downto 0); -- memory is byte addressable
    
begin

    process (addr) is
        variable rom_array : memory := (
            X"B3", X"02", X"00", X"00", X"13", X"03", X"B0", X"00", 
            X"97", X"03", X"00", X"10", X"93", X"83", X"83", X"FF", 
            X"63", X"DE", X"62", X"00", X"13", X"85", X"02", X"00", 
            X"EF", X"00", X"C0", X"01", X"23", X"A0", X"A3", X"00", 
            X"93", X"83", X"43", X"00", X"93", X"82", X"12", X"00", 
            X"6F", X"F0", X"9F", X"FE", X"13", X"05", X"A0", X"00", 
            X"73", X"00", X"00", X"00", X"13", X"01", X"41", X"FF", 
            X"23", X"20", X"11", X"00", X"23", X"22", X"A1", X"00", 
            X"13", X"0E", X"10", X"00", X"63", X"44", X"AE", X"00", 
            X"6F", X"00", X"40", X"02", X"13", X"05", X"F5", X"FF", 
            X"EF", X"F0", X"5F", X"FE", X"23", X"24", X"A1", X"00", 
            X"03", X"25", X"41", X"00", X"13", X"05", X"E5", X"FF", 
            X"EF", X"F0", X"5F", X"FD", X"83", X"25", X"81", X"00", 
            X"33", X"05", X"B5", X"00", X"83", X"20", X"01", X"00", 
            X"13", X"01", X"C1", X"00", X"67", X"80", X"00", X"00",
        others => (others=>'0'));
        variable word_addr : std_logic_vector (ADDRLEN-1 downto 0) := (others=>'0');
    begin
        word_addr := addr(ADDRLEN-1 downto 2) & "00";
        dataout <= rom_array(to_integer(unsigned(word_addr))+3) & rom_array(to_integer(unsigned(word_addr))+2) & rom_array(to_integer(unsigned(word_addr))+1) & rom_array(to_integer(unsigned(word_addr)));
    end process;

end architecture;
