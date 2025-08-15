library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity tb_calib is 

end tb_calib;

architecture beha of tb_calib is 

component fpll_recalib is 
port 
(
   reset                : in std_logic ;
   clk                  : in std_logic ;
   tx_pll_cal_busy      : in std_logic ;
 --// TX PLL reconfig controller interface
   txpll_mgmt_address    :out std_logic_vector(9 downto 0) ;---output wire [9:0] ,
   txpll_mgmt_writedata  :out std_logic_vector(31 downto 0) ;---output wire [31:0],
   txpll_mgmt_readdata   :in  std_logic_vector(31 downto 0) ;---input  wire [31:0],
   txpll_mgmt_write      :out std_logic  ;---output wire       ,
   txpll_mgmt_read       :out std_logic  ;---output wire       ,
   txpll_mgmt_waitrequest: in std_logic   ----input  wire       
  );
end component;

signal   reset                :   std_logic := '1' ;
signal   clk                  :   std_logic := '1' ;
signal   tx_pll_cal_busy      :   std_logic := '1' ;
  --// TX PLL reconfig controller interface
signal   txpll_mgmt_address    :  std_logic_vector(9 downto 0) ;---output wire [9:0] ,
signal   txpll_mgmt_writedata  :  std_logic_vector(31 downto 0) ;---output wire [31:0],
signal   xcnt   :  std_logic_vector(31 downto 0) ;---output wire [31:0],
signal   ycnt   :  std_logic_vector(31 downto 0) ;---output wire [31:0],
signal   txpll_mgmt_readdata   :  std_logic_vector(31 downto 0) ;---input  wire [31:0],
signal   txpll_mgmt_write      :  std_logic  ;---output wire       ,
signal   txpll_mgmt_read       :  std_logic  ;---output wire       ,
signal   txpll_mgmt_waitrequest:   std_logic ;  ----input  wire     
begin 

reset <= '0' after 21 ns;
clk   <= not clk after 5 ns;
tx_pll_cal_busy <= '0';
process(reset,clk)
begin 
    if reset = '1' then 
        xcnt <= (others=>'0');
        ycnt <= (others=>'0');
    elsif rising_edge(clk) then 
        if xcnt = 2048 then 
            if ycnt = 1024 then 
                ycnt <= (others=>'0');
            else 
                ycnt <= ycnt + 1;
            end if;
        else 
            xcnt <= xcnt + 1 ;
        end if;      
    end if;
end process;

process(xcnt ,ycnt)
begin 
    if ycnt = 1 then 
    else 
    end if;

end process;

dut: fpll_recalib   
port map
(
   reset                 =>reset                  ,----
   clk                   =>clk                    ,----
   tx_pll_cal_busy       =>tx_pll_cal_busy        ,----
 --// TX PLL reconfig co =>// TX PLL reconfig co  ,----
   txpll_mgmt_address    =>txpll_mgmt_address     ,----utput wire [9:0] ,
   txpll_mgmt_writedata  =>txpll_mgmt_writedata   ,----output wire [31:0],
   txpll_mgmt_readdata   =>txpll_mgmt_readdata    ,----input  wire [31:0],
   txpll_mgmt_write      =>txpll_mgmt_write       ,----
   txpll_mgmt_read       =>txpll_mgmt_read        ,----
   txpll_mgmt_waitrequest=>txpll_mgmt_waitrequest ----
  );
  
  process(reset,clk)
  begin 
    if reset = '1' then 
        txpll_mgmt_waitrequest <= '0';
        txpll_mgmt_readdata    <= (others=>'0');
    elsif rising_edge(clk) then 
        if txpll_mgmt_waitrequest = '0' then 
            txpll_mgmt_waitrequest <= '1';
        elsif txpll_mgmt_write = '1' or txpll_mgmt_read = '1'  then 
            txpll_mgmt_waitrequest <= '0';
            txpll_mgmt_readdata    <= txpll_mgmt_readdata + 1 ;
        end if;
    end if;
 end process;    
        

end beha ;