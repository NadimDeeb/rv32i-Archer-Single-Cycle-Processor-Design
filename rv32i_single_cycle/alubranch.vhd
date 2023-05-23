library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.archer_pkg.all;

entity branch_alu is
    port (
        inputA : in std_logic_vector (XLEN-1 downto 0);
        inputB : in std_logic_vector (XLEN-1 downto 0);
        result : out std_logic_vector (XLEN-1 downto 0)
    );
end branch_alu;

architecture rtl of branch_alu is
begin
    result <= std_logic_vector(signed(inputA) + signed(inputB));
end architecture;
