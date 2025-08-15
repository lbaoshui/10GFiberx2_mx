--#######################################################################
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity ddr_rdresp_cmdfifo_pack is 
generic 
(
  A_W :integer := 5  ;
  D_W :integer := 42
);
port (
        Data: in  std_logic_vector(D_W-1 downto 0); 
        Clock: in  std_logic; 
        WrEn: in  std_logic; 
        RdEn: in  std_logic; 
        Reset: in  std_logic; 
        Q: out  std_logic_vector(D_W-1 downto 0); 
        WCNT: out  std_logic_vector(4 downto 0); 
        Empty: out  std_logic; 
        Full: out  std_logic);
end ddr_rdresp_cmdfifo_pack;

architecture beha of ddr_rdresp_cmdfifo_pack is 
    	component ddr_rdresp_cmdfifo is
		port (
			data  : in  std_logic_vector(D_W-1 downto 0) := (others => 'X'); -- datain
			wrreq : in  std_logic                     := 'X';             -- wrreq
			rdreq : in  std_logic                     := 'X';             -- rdreq
			clock : in  std_logic                     := 'X';             -- clk
			sclr  : in  std_logic                     := 'X';             -- sclr
			q     : out std_logic_vector(D_W-1 downto 0);                    -- dataout
			usedw : out std_logic_vector(3 downto 0);                     -- usedw
			full  : out std_logic;                                        -- full
			empty : out std_logic                                         -- empty
		);
	end component ddr_rdresp_cmdfifo;
 signal WCNT_tmp : std_logic_vector(3 downto 0);
 signal Full_tmp : std_logic ;
 
begin 
u0 :   ddr_rdresp_cmdfifo
		port map (
			data    => Data     ,    --  fifo_input.datain
			wrreq   => WrEn     ,   --            .wrreq
			rdreq   => RdEn     ,   --            .rdreq
			clock   => Clock        ,   --            .wrclk
			---rdclk   => RdClock        ,   --            .rdclk
			sclr    => Reset          ,    --            .aclr
			q       => Q              ,       -- fifo_output.dataout
			---rdusedw => RCNT           , --            .rdusedw
			usedw => WCNT_tmp           , --            .wrusedw
			empty => Empty          , --            .rdempty
			full  => Full_tmp          --            .wrfull
		);
    --only synchronization ...
    process(Full_tmp,WCNT_tmp)
    begin 
        if Full_tmp ='1' then 
            WCNT <= (4 =>'1' , OTHERS=>'0');
        else 
            WCNT <= Full_tmp&WCNT_tmp;
        end if;
    end process;
    Full <= Full_tmp;
        
end beha;