library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.archer_pkg.all;

entity Forwarding is
    port (
        clk : in std_logic;
        rs1 : in std_logic_vector (4 downto 0);
        rs2 : in std_logic_vector (4 downto 0);
        rs1EX : in std_logic_vector (4 downto 0);
        rs2EX : in std_logic_vector (4 downto 0);
        rs1EXM : in std_logic_vector (4 downto 0);
        rs2EXM : in std_logic_vector (4 downto 0);
        regWEX : in std_logic;
        LOAD : in std_logic;
        LOADEX: in std_logic;
        BRANCH : in std_logic;
        rdEX : in std_logic_vector (4 downto 0);
        regWMEM : in std_logic;
        rd : in std_logic_vector (4 downto 0);
        rdMEM : in std_logic_vector (4 downto 0);
        fex1 : out std_logic;
        fmem1 : out std_logic;
        fex2 : out std_logic;
        fmem2 : out std_logic;
        fex1M : out std_logic;
        fmem1M : out std_logic;
        fex2M : out std_logic;
        fmem2M : out std_logic;
        fex1B : out std_logic;
        fmem1B : out std_logic;
        fex2B : out std_logic;
        fmem2B : out std_logic;

        stall : out std_logic
    );
end Forwarding;

architecture arch of Forwarding is
signal count : std_logic;
begin
    process is
    begin
        if rising_edge(clk) then
        wait for 0.0001 ns;
        fex1 <= '0';
        fmem1 <= '0';
        fex2 <= '0';
        fmem2 <= '0';
        fex1M <= '0';
        fmem1M <= '0';
        fex2M <= '0';
        fmem2M <= '0';
        fex1B <= '0';
        fmem1B <= '0';
        fex2B <= '0';
        fmem2B <= '0';
        if BRANCH = '1' and (rs1 = rd or rs1 = rd or rs2 = rd) and count = '0' then
            stall <= '1';
            count <= '1';
        elsif LOAD = '1' and (rs1 = rd or rs2 = rd) then
            stall <= '1';
        else
            count <= '0';
            stall <= '0';
        end if;
            if rs1EX = rdEX and rdEX /= "00000" and regWEX = '1' then
                fex1 <= '1';
            else
                fex1 <= '0';
            end if;

            if rs1EX = rdMEM and rdMEM /= "00000" and regWMEM = '1' then
                fmem1 <= '1';
            else
                fmem1 <= '0';
            end if;

            if rs2EX = rdEX and rdEX /= "00000" and regWEX = '1' then
                fex2 <= '1';
            else
                fex2 <= '0';
            end if;

            if rs2EX = rdMEM and rdMEM /= "00000" and regWMEM = '1' then
                fmem2 <= '1';
            else
                fmem2 <= '0';
            end if;

            -- BRANCH
            if BRANCH = '1' then
                if rs1 = rdEX and rdEX /= "00000" and regWEX = '1' then
                    if LOADEX = '1' then
                        stall <= '1';
                    else
                        fex1B <= '1';
                    end if;
                else
                    fex1B <= '0';
                end if;

                if rs1 = rdMEM and rdMEM /= "00000" and regWMEM = '1' then
                    fmem1B <= '1';
                else
                    fmem1B <= '0';
                end if;

                if rs2 = rdEX and rdEX /= "00000" and regWEX = '1' then
                    if LOADEX = '1' then
                        stall <= '1';
                    else
                        fex2B <= '1';
                    end if;
                else
                    fex2B <= '0';
                end if;

                if rs2 = rdMEM and rdMEM /= "00000" and regWMEM = '1' then
                    fmem2B <= '1';
                else
                    fmem2B <= '0';
                end if;
            end if;
            -- MULTIPLY
            if rs1EXM = rdEX and rdEX /= "00000" and regWEX = '1' then
                fex1M <= '1';
            else
                fex1M <= '0';
            end if;

            if rs1EXM = rdMEM and rdMEM /= "00000" and regWMEM = '1' then
                fmem1M <= '1';
            else
                fmem1M <= '0';
            end if;

            if rs2EXM = rdEX and rdEX /= "00000" and regWEX = '1' then
                fex2M <= '1';
            else
                fex2M <= '0';
            end if;

            if rs2EXM = rdMEM and rdMEM /= "00000" and regWMEM = '1' then
                fmem2M <= '1';
            else
                fmem2M <= '0';
            end if;
            end if;
        wait on clk;

    end process;
end arch;