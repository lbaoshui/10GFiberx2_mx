--#######################################################################
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity ddr_rddata_fifo_pack is 
generic 
(
  A_W :integer := 10 ;
  D_W :integer := 320
 
);
port (
        Data: in  std_logic_vector(D_W-1 downto 0); 
        WrClock: in  std_logic; 
        RdClock: in  std_logic; 
        WrEn: in  std_logic; 
        RdEn: in  std_logic; 
        Reset: in  std_logic; 
        RPReset: in  std_logic; 
        Q: out  std_logic_vector(D_W-1 downto 0); 
        WCNT: out  std_logic_vector(A_W-1 downto 0); 
        RCNT: out  std_logic_vector(A_W-1 downto 0); 
        Empty: out  std_logic; 
        Full: out  std_logic);
end ddr_rddata_fifo_pack;

architecture beha of ddr_rddata_fifo_pack is 
   component ddr_rddata_fifo is
		port (
			data    : in  std_logic_vector(319 downto 0) := (others => 'X'); -- datain
			wrreq   : in  std_logic                      := 'X';             -- wrreq
			rdreq   : in  std_logic                      := 'X';             -- rdreq
			wrclk   : in  std_logic                      := 'X';             -- wrclk
			rdclk   : in  std_logic                      := 'X';             -- rdclk
			aclr    : in  std_logic                      := 'X';             -- aclr
			q       : out std_logic_vector(319 downto 0);                    -- dataout
			rdusedw : out std_logic_vector(9 downto 0);                      -- rdusedw
			wrusedw : out std_logic_vector(9 downto 0);                      -- wrusedw
			rdempty : out std_logic;                                         -- rdempty
			wrfull  : out std_logic                                          -- wrfull
		);
	end component ddr_rddata_fifo;

begin 
u0 :   ddr_rddata_fifo
		port map (
			data    => Data     ,    --  fifo_input.datain
			wrreq   => WrEn     ,   --            .wrreq
			rdreq   => RdEn     ,   --            .rdreq
			wrclk   => WrClock        ,   --            .wrclk
			rdclk   => RdClock        ,   --            .rdclk
			aclr    => Reset          ,    --            .aclr
			q       => Q              ,       -- fifo_output.dataout
			rdusedw => RCNT           , --            .rdusedw
			wrusedw => WCNT           , --            .wrusedw
			rdempty => Empty          , --            .rdempty
			wrfull  => Full          --            .wrfull
		);
        
end beha;