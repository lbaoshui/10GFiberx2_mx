library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity multi_measure is 
generic 
(  
    CLK_NUM : integer := 10 
);
port 
(
    sysclk     : in  std_logic ;  --125M 
    nRST_sys   : in  std_logic ;
    clk_set    : in  std_logic_vector(CLK_NUM-1 downto 0);
    mask_out   : out std_logic := '0';
    clk_cnt    : out std_logic_vector(CLK_NUM*32-1 downto 0) 
 
);
end multi_measure;

architecture beha of multi_measure is 

component measure_clk_check is 
port 
(
    nRST                : in std_logic ;
    dur_en              : in std_logic ;
    measured_clk_in     : in std_logic ;
    
    capture_clk_in      : in std_logic;
    cnt_val             : out std_logic_vector(31 downto 0);
    
    done_val            : out std_logic
    
);
end component ;

signal done_val         : std_logic_vector(CLK_NUM-1 downto 0);
signal clk_cnt_buf      : std_logic_vector(CLK_NUM*32-1 downto 0); 
signal test_dur_en      : std_logic := '0';
signal mmcnt            : std_logic_vector(31 downto 0) :=(others=>'0');

signal cnt_a            : std_logic_vector(5*8-1 downto 0);
constant START_CYCLES   : integer := 10000;
constant DUR_CYCLES     : integer := 100000*125; ----8,ms000,000ns *125=1000ms=1s

begin 

mm: for i in 0 to CLK_NUM-1 generate 
mc: measure_clk_check  
port  map
(
    nRST                => nRST_sys  ,
    dur_en              => test_dur_en ,
    measured_clk_in     => clk_set(i) , 
    
    capture_clk_in      => sysclk ,
    cnt_val             => clk_cnt_buf(31+32*i downto 32*i),
    
    done_val            => done_val(i)
    
);
end generate mm;

process(nRST_sys,sysclk)
begin 
    if rising_edge(sysclk) then 
         if clk_cnt_buf = 0 then 
             mask_out <= '0';
         else 
             mask_out <= '1';
         end if;
         if mmcnt >= (START_CYCLES+DUR_CYCLES)*2+10 then 
             mmcnt <= (others=>'0');
         else 
             mmcnt <= mmcnt + 1 ;
         end if;
         if mmcnt >=START_CYCLES  AND mmcnt <START_CYCLES+DUR_CYCLES then 
             test_dur_en <= '1' ;
         else 
             test_dur_en <= '0';
         end if;
    end if;
end process;

end beha;