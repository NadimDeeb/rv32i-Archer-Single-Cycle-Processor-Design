library ieee ;
use ieee.std_logic_1164.all ;
use ieee.numeric_std.all ;
use work.archer_pkg.all;

entity idex is
  port (
    clk : in std_logic;

    instin : in std_logic_vector (XLEN-1 downto 0);
    instout : out std_logic_vector (XLEN-1 downto 0);
    inJump : in std_logic;
    inLui : in std_logic;
    inRegWrite : in std_logic;
    inALUSrc1 : in std_logic;
    inALUSrc2 : in std_logic;
    inALUOp : in std_logic_vector (4 downto 0);
    inMemWrite : in std_logic;
    inCSR : in std_logic;
    inNOP : in std_logic;
    inMemRead : in std_logic;
    inMemToReg : in std_logic;
    inMULT : in std_logic;
    inDIV : in std_logic;

    inregA : in std_logic_vector (XLEN-1 downto 0);
    inregB : in std_logic_vector (XLEN-1 downto 0);
    outregA : out std_logic_vector (XLEN-1 downto 0);
    outregB : out std_logic_vector (XLEN-1 downto 0);
    inpc : in std_logic_vector (XLEN-1 downto 0);
    outpc : out std_logic_vector (XLEN-1 downto 0);

    inimm: in std_logic_vector (XLEN-1 downto 0);
    infunct3: in std_logic_vector (2 downto 0);
    inrs1: in std_logic_vector (4 downto 0);
    inrs2: in std_logic_vector (4 downto 0);
    inrd: in std_logic_vector (4 downto 0);

    outJump : out std_logic;
    outLui : out std_logic;
    outRegWrite : out std_logic;
    outALUSrc1 : out std_logic;
    outALUSrc2 : out std_logic;
    outALUOp : out std_logic_vector (4 downto 0);
    outMemWrite : out std_logic;
    outCSR : out std_logic;
    outNOP : out std_logic;
    outMemRead : out std_logic;
    outMemToReg : out std_logic;
    outMULT : out std_logic;
    outDIV : out std_logic;

    outimm: out std_logic_vector (XLEN-1 downto 0);
    outfunct3: out std_logic_vector (2 downto 0);
    outrs1: out std_logic_vector (4 downto 0);
    outrs2: out std_logic_vector (4 downto 0);
    outrd: out std_logic_vector (4 downto 0);

    mult : in std_logic;
    div : in std_logic;
    nop : in std_logic;
    stallmult : in std_logic;
    stallload : in std_logic;
    stalldiv : in std_logic
  ) ;
end idex ;

architecture arch of idex is
begin
  process(clk)
  begin
  if nop = '1'  and rising_edge(clk) and ((mult /= stallmult) or (div /= stalldiv) or stallload = '1') then
      instout <= x"00000013";
      outJump <= '0';
      outLui <= '0';
      outRegWrite <= '0';
      outALUSrc1 <= '0';
      outALUSrc2 <= '0';
      outALUOp <= "00000";
      outMemWrite <= '0';
      outCSR <= '0';
      outNOP <= '1';
      outMemRead <= '0';
      outMemToReg <= '0';
      outimm  <= x"00000000";
      outfunct3 <= "000";
      outregA <= x"00000000";
      outregB <= x"00000000";
      outpc <= x"00000000";
      outrs1  <= "00000";
      outrs2 <= "00000";
      outrd  <= "00000";
      outDIV <= '0';
      outMULT <= '0';
  elsif (stalldiv /= '1' and stallmult /= '1' and stallload /= '1') or (mult = '1' and stallmult = '1') or (div = '1' and stalldiv = '1') then
  if rising_edge(clk) then
    instout <= instin;
    outJump <= inJump;
    outLui <= inLui;
    outRegWrite <= inRegWrite;
    outALUSrc1 <= inALUSrc1;
    outALUSrc2 <= inALUSrc2;
    outALUOp <= inALUOp;
    outMemWrite <= inMemWrite;
    outCSR <= inCSR;
    outNOP <= inNOP;
    outMemRead <= inMemRead;
    outMemToReg <= inMemToReg;
    outimm  <= inimm;
    outfunct3 <= infunct3;
    outregA <= inregA;
    outregB <= inregB;
    outpc <= inpc;
    outrs1  <= inrs1;
    outrs2 <= inrs2;
    outrd  <= inrd;
    outDIV <= inDIV;
    outMULT <= inMULT;
    end if;
  end if;
  end process;


end architecture ;