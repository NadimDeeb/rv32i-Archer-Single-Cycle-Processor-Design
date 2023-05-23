library ieee ;
use ieee.std_logic_1164.all ;
use ieee.numeric_std.all ;
use work.archer_pkg.all;

entity ifid is
  port (
  clk : in std_logic;
  
  inpc : in std_logic_vector (XLEN-1 downto 0);
  outpc : out std_logic_vector (XLEN-1 downto 0);
  instin : in std_logic_vector(XLEN -1 downto 0);
  instout : out std_logic_vector(XLEN -1 downto 0);
  funct3: out std_logic_vector (2 downto 0);
  rs1 : out std_logic_vector (4 downto 0);
  rs2 : out std_logic_vector (4 downto 0);
  rd : out std_logic_vector (4 downto 0);

  mult : in std_logic;
  div : in std_logic;
  flush : in std_logic;
  stallmult : in std_logic;
  stallload : in std_logic;
  stalldiv : in std_logic
  ) ;
end ifid ;

architecture arch of ifid is
begin
  process(clk)
  begin
    if (stalldiv /= '1' and stallmult /= '1' and stallload /= '1') or (mult = '1' and stallmult = '1') or (div = '1' and stalldiv = '1') then
    if rising_edge(clk) then
      if flush = '1' then
        instout <= x"00000013";
        outpc <= x"00000000";
        rs1 <= "00000";
        rs2 <= "00000";
        rd <= "00000";
        funct3 <= "000";
      else
        instout <= instin;
        outpc <= inpc;
        rs1 <= instin (LOG2_XRF_SIZE+14 downto 15);
        rs2 <= instin (LOG2_XRF_SIZE+19 downto 20);
        rd <= instin (LOG2_XRF_SIZE+6 downto 7);
        funct3 <= instin (14 downto 12);
    end if;
    end if;
    end if;
  end process;


end architecture ;