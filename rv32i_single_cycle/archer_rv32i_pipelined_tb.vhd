library ieee ;
use ieee.std_logic_1164.all ;
use ieee.numeric_std.all ;
use work.archer_pkg.all;

entity archer_rv32i_pipelined_tb is
end archer_rv32i_pipelined_tb ; 

architecture arch of archer_rv32i_pipelined_tb is
    component archer_rv32i_pipelined
        port (
            clk : in std_logic;
            rst_n : in std_logic;

            imem_addr : out std_logic_vector (ADDRLEN-1 downto 0);
            imem_datain : out std_logic_vector (XLEN-1 downto 0);
            imem_dataout : in std_logic_vector (XLEN-1 downto 0);
            imem_wen : out std_logic; -- write enable signal
            imem_ben : out std_logic_vector (3 downto 0); -- byte enable signals

            dmem_addr : out std_logic_vector (ADDRLEN-1 downto 0);
            dmem_datain : out std_logic_vector (XLEN-1 downto 0);
            dmem_dataout : in std_logic_vector (XLEN-1 downto 0);
            dmem_wen : out std_logic; -- write enable signal
            dmem_ben : out std_logic_vector (3 downto 0) -- byte enable signals
        );
    end component;

    component sram
    port (
        clk : in std_logic;
        addr : in std_logic_vector (ADDRLEN-1 downto 0);
        datain : in std_logic_vector (XLEN-1 downto 0);
        dataout : out std_logic_vector (XLEN-1 downto 0);
        wen : in std_logic;
        ben : in std_logic_vector (3 downto 0)
    );
    end component;  

    component rom
        port (
            addr : in std_logic_vector (ADDRLEN-1 downto 0);
            dataout : out std_logic_vector (XLEN-1 downto 0)
        );
    end component;


    signal tb_clk : std_logic := '0';
    signal tb_rst_n : std_logic := '1';

    signal tb_imem_addr : std_logic_vector (ADDRLEN-1 downto 0);
    signal tb_imem_dataout : std_logic_vector (XLEN-1 downto 0);

    signal tb_dmem_addr : std_logic_vector (ADDRLEN-1 downto 0);
    signal tb_dmem_datain : std_logic_vector (XLEN-1 downto 0);
    signal tb_dmem_dataout : std_logic_vector (XLEN-1 downto 0);
    signal tb_dmem_wen : std_logic;
    signal tb_dmem_ben : std_logic_vector (3 downto 0);

begin
    archer: archer_rv32i_pipelined port map (clk => tb_clk, rst_n => tb_rst_n, imem_addr => tb_imem_addr,
                             imem_datain => open, imem_dataout => tb_imem_dataout,
                             imem_wen => open, imem_ben => open, dmem_addr => tb_dmem_addr,
                              dmem_datain => tb_dmem_datain, dmem_dataout => tb_dmem_dataout,
                              dmem_wen => tb_dmem_wen, dmem_ben => tb_dmem_ben);

    dmem: sram port map (clk => tb_clk, addr => tb_dmem_addr, datain => tb_dmem_datain,
                         dataout => tb_dmem_dataout, wen => tb_dmem_wen, ben => tb_dmem_ben);

    imem: rom port map (addr => tb_imem_addr, dataout => tb_imem_dataout);


    tb_rst_n <= '0' after 5 ns, '1' after 10 ns;

    process is
    begin
        wait for 20 ns;
        for i in 1 to 10000 loop
            tb_clk <= '1';
            wait for 10 ns;
            tb_clk <= '0';
            wait for 10 ns;
        end loop;
        wait;
    end process;
end architecture ;