library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.archer_pkg.all;

entity CSR is
    port (
        clk : in std_logic;
        rst_n : in std_logic;
        instruction : in std_logic_vector (XLEN-1 downto 0);
        NOP : in std_logic;
        csrIn : in std_logic_vector (XLEN-1  downto 0);
        rs1 : in std_logic_vector (4 downto 0);
        csrInstR : in std_logic;
        csrInstW : in std_logic;
        csrAdrR : in std_logic_vector (XLEN-1  downto 0);
        csrAdrW : in std_logic_vector (XLEN-1  downto 0);
        csrOut : out std_logic_vector (XLEN-1  downto 0)
    );
end CSR;

architecture arch of CSR is
    type memory is array (0 to 3) of std_logic_vector (XLEN-1 downto 0);
    signal CSR_comp : memory := (others => (others => '0'));
    -- signal CSRinput : std_logic_vector (XLEN-1 downto 0) := (others => '0');
    
begin
    CSR_cycle_and_instret: process is
    variable cycle : unsigned (31 downto 0) := (others => '0');
    variable inst : unsigned (31 downto 0) := (others => '0');
    variable inDone : std_logic := '0';
    begin
        if rst_n = '0' then
            CSR_comp <= (others => (others => '0'));
        else
            if to_integer(unsigned(CSR_comp(0))) = 0 and to_integer(unsigned(CSR_comp(1))) = 0 then
                inDone := '0';
                CSR_comp(0) <= std_logic_vector(unsigned(CSR_comp(0))+1);
            elsif rising_edge(clk) then
                inDone := '0';
                cycle := unsigned(CSR_comp(0))+1;
                if to_integer(cycle) = 0 then
                    cycle := unsigned(CSR_comp(1)) + 1;
                    CSR_comp(1) <= std_logic_vector(cycle);
                    cycle := (others => '0');
                end if;
                CSR_comp(0) <= std_logic_vector(cycle);
            elsif falling_edge(clk) and csrInstW = '1' and rs1 /= "00000" then
                CSR_comp(to_integer(unsigned(csrAdrW))) <= csrIn;
            end if;
            
            wait for 0.0001 ns;
            if NOP = '0' and inDone = '0' then
                inDone := '1';
                inst := unsigned(CSR_comp(2))+1;
                if to_integer(inst) = 0 then
                    inst := unsigned(CSR_comp(3)) + 1;
                    CSR_comp(3) <= std_logic_vector(inst);
                    inst := (others => '0');
                end if;
                CSR_comp(2) <= std_logic_vector(inst);
            end if;
        end if;
        wait on clk, rst_n;
    end process;

    CSR_read: process is
        begin
            wait on clk, csrAdrR, csrInstR;
            wait for 0.0001 ns;
            if csrInstR = '1' then
                csrOut <= CSR_comp(to_integer(unsigned(csrAdrR)));
            else
                csrOut <= (others => '0');
            end if;
        end process;  
end architecture;