library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity ddr_wrmask_dpram_pack is 
generic 
(D_W : integer := 320/8
);
port 
(
        WrAddress   : in  std_logic_vector(8 downto 0); 
        RdAddress   : in  std_logic_vector(8 downto 0); 
        Data        : in  std_logic_vector(D_W-1 downto 0); 
        WE          : in  std_logic; 
        RdClock     : in  std_logic; 
        RdEn        : in  std_logic;  
        
        rdaddr_stall     : in     std_logic ;
        rdoutclk_en      : in     std_logic ;
        rdinclk_en       : in     std_logic ;
        Reset           : in  std_logic; 
        WrClock         : in  std_logic; 
        WrClockEn       : in  std_logic; 
        Q               : out  std_logic_vector(D_W-1 downto 0)

);
end ddr_wrmask_dpram_pack ;


architecture beha of ddr_wrmask_dpram_pack is 

	component ddr_wrmask_dpram is
		port (
			data            : in  std_logic_vector(39 downto 0) := (others => 'X'); -- datain
			q               : out std_logic_vector(39 downto 0);                    -- dataout
			wraddress       : in  std_logic_vector(8 downto 0)  := (others => 'X'); -- wraddress
			rdaddress       : in  std_logic_vector(8 downto 0)  := (others => 'X'); -- rdaddress
			wren            : in  std_logic                     := 'X';             -- wren
			wrclock         : in  std_logic                     := 'X';             -- clk
			rdclock         : in  std_logic                     := 'X';             -- clk
			rden            : in  std_logic                     := 'X';             -- rden
			rd_addressstall : in  std_logic                     := 'X';             -- rd_addressstall
			rdinclocken     : in  std_logic                     := 'X';             -- rdinclocken
			rdoutclocken    : in  std_logic                     := 'X'              -- rdoutclocken
		);
	end component ddr_wrmask_dpram;
    
    
begin 

	u0 :  ddr_wrmask_dpram
		port map (
			data            => Data          ,            --            data.datain
			q               => Q            ,               --               q.dataout
			wraddress       => WrAddress    ,       --       wraddress.wraddress
			rdaddress       => RdAddress    ,       --       rdaddress.rdaddress
			wren            => WE           ,            --            wren.wren
			wrclock         => WrClock      ,         --         wrclock.clk
			rdclock         => RdClock             ,         --         rdclock.clk
			rden            => RdEn           ,            --            rden.rden
			rd_addressstall => rdaddr_stall   , -- rd_addressstall.rd_addressstall
			rdinclocken     => rdinclk_en        ,     --     rdinclocken.rdinclocken
			rdoutclocken    => rdoutclk_en               --    rdoutclocken.rdoutclocken
		);
end beha;