library ieee ;
use ieee.std_logic_1164.all ;
use ieee.numeric_std.all ;
use work.archer_pkg.all;

entity exmem is
  port (
    clk : in std_logic;

    instin : in std_logic_vector (XLEN-1 downto 0);
    instout : out std_logic_vector (XLEN-1 downto 0);
    byte_mask : out std_logic_vector (1 downto 0);
    sign_ext_n : out std_logic;
    funct3: in std_logic_vector (2 downto 0);
    inpc : in std_logic_vector (XLEN-1 downto 0);
    outpc : out std_logic_vector (XLEN-1 downto 0);

    inalu : in std_logic_vector (XLEN-1 downto 0);
    outalu : out std_logic_vector (XLEN-1 downto 0);
    inregB : in std_logic_vector (XLEN-1 downto 0);
    outregB : out std_logic_vector (XLEN-1 downto 0);

    inJump : in std_logic;
    inRegWrite : in std_logic;
    inMemWrite : in std_logic;
    inNOP : in std_logic;
    inMemRead : in std_logic;
    inMemToReg : in std_logic;

    inrd: in std_logic_vector (4 downto 0);

    outJump : out std_logic;
    outRegWrite : out std_logic;
    outMemWrite : out std_logic;
    outNOP : out std_logic;
    outMemRead : out std_logic;
    outMemToReg : out std_logic;

    outrd: out std_logic_vector (4 downto 0);

    nop: in std_logic;
    stall: in std_logic
  ) ;
end exmem ;

architecture arch of exmem is
  signal funct3T : std_logic_vector (2 downto 0);
begin
  funct3T <= instin (14 downto 12);
  process(clk)
  begin
  if nop = '1' and rising_edge(clk) then
    instout <= X"00000013";
    outpc <= X"00000000";
    outalu <= X"00000000";
    outregB <= X"00000000";

    outJump <= '0';
    outRegWrite <= '0';
    outMemWrite <= '0';
    outNOP <= '1';
    outMemRead <= '0';
    outMemToReg <= '0';
    outrd  <= "00000";
    byte_mask <= "00";
    sign_ext_n <= '0';
    
  elsif rising_edge(clk) then
    instout <= instin;
    outpc <= inpc;
    outalu <= inalu;
    outregB <= inregB;

    outJump <= inJump;
    outRegWrite <= inRegWrite;
    outMemWrite <= inMemWrite;
    outNOP <= inNOP;
    outMemRead <= inMemRead;
    outMemToReg <= inMemToReg;
    outrd  <= inrd;
    byte_mask <= funct3T(1 downto 0);
    sign_ext_n <= funct3T(2);
  end if;
  end process;


end architecture ;