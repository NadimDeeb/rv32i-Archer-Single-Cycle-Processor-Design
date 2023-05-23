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
-- Local memory bus interface
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.archer_pkg.all;

entity lmb is
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
end lmb;

architecture rtl of lmb is
    signal lsab : std_logic_vector (1 downto 0); -- least significant address bits
begin
    mem_addr <= proc_addr (ADDRLEN-1 downto 0);
    mem_datain <= proc_data_send;
    mem_wen <= '1' when proc_mem_write = '1' and proc_mem_read = '0' else '0';

    lsab <= proc_addr (1 downto 0);

    set_mem_ben: process (lsab, proc_byte_mask) is
    begin
        mem_ben <= "0000";
        case proc_byte_mask is
            when "00" =>
                case lsab is
                    when "00" => mem_ben <= "0001";
                    when "01" => mem_ben <= "0010";
                    when "10" => mem_ben <= "0100";
                    when "11" => mem_ben <= "1000";
                    when others => null;
                end case;
            when "01" =>
                case lsab is
                    when "00" | "01" => mem_ben <= "0011";
                    when "10" | "11" => mem_ben <= "1100";
                    when others => null;
                end case;
            when "10" =>
                mem_ben <= "1111";
            when others =>
                null;
        end case;
    end process;

    set_proc_data_receive: process (lsab, proc_byte_mask, proc_sign_ext_n, proc_mem_write, proc_mem_read, mem_dataout) is
        variable MSB : std_logic := '0';
        variable data_byte : std_logic_vector (7 downto 0) := X"00";
        variable data_half_word : std_logic_vector (15 downto 0) := X"0000";
    begin
        proc_data_receive <= (others => '0');
        data_byte := X"00";
        data_half_word := X"0000";

        if proc_mem_write = '0' and proc_mem_read = '1' then
            proc_data_receive <= mem_dataout;
            case proc_byte_mask is

                when "00" =>
                    case lsab is
                        when "00" => data_byte := mem_dataout(7 downto 0);
                        when "01" => data_byte := mem_dataout(15 downto 8);
                        when "10" => data_byte := mem_dataout(23 downto 16);
                        when "11" => data_byte := mem_dataout(31 downto 24);
                        when others => data_byte := X"00";
                    end case;

                    if proc_sign_ext_n = '0' then
                        MSB := data_byte(7);
                    else
                        MSB := '0';
                    end if;

                    proc_data_receive <= (XLEN-1 downto 8 => MSB) & data_byte;
                     
                when "01" =>
                    case lsab is
                        when "00" | "01" => data_half_word := mem_dataout (15 downto 0);
                        when "10" | "11" => data_half_word := mem_dataout (31 downto 16);
                        when others => data_half_word := X"0000";
                    end case;

                    if proc_sign_ext_n = '0' then
                        MSB := data_half_word(15);
                    else
                        MSB := '0';
                    end if;

                    proc_data_receive <= (XLEN-1 downto 16 => MSB) & data_half_word;

                when others => null;
            
            end case;
        end if;
    end process;

end architecture;
