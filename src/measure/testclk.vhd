library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity measure_clk_check is 
port 
(
    nRST                    : in std_logic ;
    dur_en                  : in std_logic ;
    measured_clk_in         : in std_logic ;
    
    capture_clk_in          : in std_logic;
    cnt_val                 : out std_logic_vector(31 downto 0);

    done_val                : out std_logic
    
);
end measure_clk_check;

architecture beha_testclk of measure_clk_check is 

signal dly_dur_en : std_logic_vector(7 downto 0):=(others=>'0');
signal cnt        : std_logic_vector(31 downto 0):=(others=>'0');
signal cnt_cap    : std_logic_vector(31 downto 0):=(others=>'0');
signal cnt_val0   : std_logic_vector(31 downto 0):=(others=>'0');
signal cnt_val1   : std_logic_vector(31 downto 0):=(others=>'0');
signal cnt_val2   : std_logic_vector(31 downto 0):=(others=>'0');
signal done_tt    : std_logic := '0' ;
signal done_val0  : std_logic:='0';
signal done_val1  : std_logic:='0';
signal done_val2  : std_logic:='0';
signal done_val3  : std_logic:='0';
signal done_cnt   : std_logic_vector(5 downto 0):=(others=>'0');

begin 

process(measured_clk_in)
begin 
    if rising_edge(measured_clk_in) then 
        dly_dur_en <=dly_dur_en(6 downto 0)&dur_en ;
    end if;
end process;

process(measured_clk_in)
begin 
    if rising_edge(measured_clk_in) then 
        if dly_dur_en(7) = '1' then 
             cnt <= cnt + 1 ;
        else 
             cnt <= (others=>'0');
        end if;
        if dly_dur_en(7) = '1' and dly_dur_en(6)= '0' then --falling edge 
            cnt_cap <= cnt ; 
        end if;
        
        if dly_dur_en(7) = '1' and dly_dur_en(6)= '0' then --falling edge
           -- done_tt <= '1';
            done_cnt <= (others=>'1');
        elsif done_cnt /= 0 then 
            done_cnt <= done_cnt - 1 ;
        end if;
        
        if done_cnt >0 and done_cnt <16 then 
            done_tt <= '1';
        else 
            done_tt <= '0';
        end if;
    end if;
end process;

cnt_val  <= cnt_val2;
done_val <= done_val3;
process(capture_clk_in)
begin 
    if rising_edge(capture_clk_in) then 
        if done_val3 = '1' and done_val2 = '0' then --falling edge 
            cnt_val0  <= cnt_cap;
        end if;
        cnt_val1   <= cnt_val0; 
        cnt_val2   <= cnt_val1; 
        done_val0 <= done_tt;
        done_val1  <= done_val0;
        done_val2  <= done_val1;
        done_val3  <= done_val2;
    end if;
end process;

end beha_testclk;