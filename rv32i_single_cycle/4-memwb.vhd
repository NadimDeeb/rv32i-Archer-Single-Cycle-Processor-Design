library ieee ;
use ieee.std_logic_1164.all ;
use ieee.numeric_std.all ;
use work.archer_pkg.all;

entity memwb is
  port (
    clk : in std_logic;

    instin : in std_logic_vector (XLEN-1 downto 0);
    instout : out std_logic_vector (XLEN-1 downto 0);
    inpc : in std_logic_vector (XLEN-1 downto 0);
    outpc : out std_logic_vector (XLEN-1 downto 0);

    inalu : in std_logic_vector (XLEN-1 downto 0);
    outalu : out std_logic_vector (XLEN-1 downto 0);
    inmem: in std_logic_vector (XLEN-1 downto 0);
    outmem: out std_logic_vector (XLEN-1 downto 0);

    inJump : in std_logic;
    inRegWrite : in std_logic;
    inMemToReg : in std_logic;
    inNOP : in std_logic;
    inrd: in std_logic_vector (4 downto 0);

    outJump : out std_logic;
    outRegWrite : out std_logic;
    outMemToReg : out std_logic;
    outNOP : out std_logic;
    outrd: out std_logic_vector (4 downto 0);

    stall: in std_logic
  ) ;
end memwb ;

architecture arch of memwb is
begin
  process(clk)
  begin
  if rising_edge(clk) then
    instout <= instin;
    outpc <= inpc;
    outalu <= inalu;
    outmem <= inmem;

    outJump <= inJump;
    outRegWrite <= inRegWrite;
    outMemToReg <= inMemtoReg;
    outNOP <= inNOP;
    outrd  <= inrd;
  end if;
  end process;


end architecture ;