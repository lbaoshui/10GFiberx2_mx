--#######################################################################
--
--  LOGIC CORE:          ddr_rst_ctrl                            
--  MODULE NAME:         ddr_rst_ctrl()
--  COMPANY:             
--                              
--
--  REVISION HISTORY:  
--
--  Revision 0.1  07/20/2007    Description: Initial .
--
--  FUNCTIONAL DESCRIPTION:
--
--  this module is to ctrl the reset for DDR3 controller
--
--  Copyright (C)   Shenzhen ColorLight Tech. Inc.
--
--#######################################################################



library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity ddr_rst_ctrl is
generic(
	DDR_GROUP_NUM						: integer:= 2
);
port(
	nRST								: in  std_logic;
	sysclk								: in  std_logic;
	time_ms_en							: in  std_logic;
	--input	
	ddr_verify_end						: in  std_logic_vector(DDR_GROUP_NUM-1 downto 0);
	ddr_verify_success					: in  std_logic_vector(DDR_GROUP_NUM-1 downto 0);
	--output
	sys_ddr_ip_nrst						: out std_logic;
	sys_ddr_core_nrst					: out std_logic                         
);
end entity;

architecture behav of ddr_rst_ctrl is


constant ALL_1							: std_logic_vector(DDR_GROUP_NUM-1 downto 0):= (others => '1');
signal rst_cnt							: std_logic_vector(3 downto 0):=(others=>'0');
signal verify_timeout_cnt				: std_logic_vector(13 downto 0);
signal verify_end_buf					: std_logic_vector(DDR_GROUP_NUM-1 downto 0);	
signal verify_end_ch					: std_logic_vector(DDR_GROUP_NUM-1 downto 0);	
signal verify_success_buf				: std_logic_vector(DDR_GROUP_NUM-1 downto 0);
signal verify_success_ch				: std_logic_vector(DDR_GROUP_NUM-1 downto 0);
signal verify_end						: std_logic;
signal verify_success					: std_logic;				

component altera_std_synchronizer is 
  generic (depth : integer := 3);
  port   
     (
				    clk : in std_logic ;
				reset_n : in std_logic ; 
				din     : in std_logic ;
				dout    : out std_logic
				);  
 end component;

begin

 sync_i: for i in 0  to DDR_GROUP_NUM-1 generate 
   end_inst: altera_std_synchronizer generic map (depth =>8) port map 
      (clk     => sysclk ,
       reset_n => nRST ,
       din     => ddr_verify_end(i),
       dout    => verify_end_buf(i)
     );
   suc_inst: altera_std_synchronizer generic map(depth =>4) port map 
      (clk     => sysclk ,
       reset_n => nRST ,
       din     => ddr_verify_success(i),
       dout    => verify_success_buf(i)
     );
 end generate sync_i;

process(sysclk,nRST)
begin
	if nRST = '0' then
		rst_cnt <= (others => '0');
		sys_ddr_ip_nrst <= '0';
		sys_ddr_core_nrst <= '0';
		verify_timeout_cnt <= (others => '0');
		--verify_end_buf <= (others => '0');
		verify_end_ch <= (others => '0');
		--verify_success_buf <= (others => '0');
		verify_success_ch <= (others => '0');
		verify_end <= '0';
		verify_success <= '0';

		
	elsif rising_edge(sysclk) then
		if rst_cnt(2) = '0' then
			if time_ms_en = '1' then
				rst_cnt <= rst_cnt + '1';
			end if;
			
			verify_timeout_cnt <= (others => '0');
		----	verify_end_buf <= (others => '0');
			verify_end_ch <= (others => '0');
		---	verify_success_buf <= (others => '0');
			verify_success_ch <= (others => '0');
			verify_end <= '0';
			verify_success <= '0';
		else
			for i in 0 to DDR_GROUP_NUM-1 loop
				
				-- verify_end_ch(i) <= verify_end_buf(i*8);
				verify_end_ch(i) <= verify_end_buf(i);
				-- verify_success_ch(i) <= verify_success_buf(i*4);
				verify_success_ch(i) <= verify_success_buf(i);
			end loop;
			
			if verify_end_ch = ALL_1 then		verify_end <= '1';
			else								verify_end <= '0';
			end if;
			
			if verify_success_ch = ALL_1 then	verify_success <= '1';
			else								verify_success <= '0';
			end if;
			
			if verify_end = '0' then
				if verify_timeout_cnt(13) = '0' and time_ms_en = '1' then
					verify_timeout_cnt <= verify_timeout_cnt + '1';
				end if;
			end if;
			
			if (verify_end = '1' and verify_success = '0') or verify_timeout_cnt(13) = '1' then
				rst_cnt <= (others => '0');
			end if;
		end if;
		
		if rst_cnt(2 downto 1) > 0 then
			sys_ddr_ip_nrst <= '1';
		else
			sys_ddr_ip_nrst <= '0';
		end if;
		
		sys_ddr_core_nrst <= rst_cnt(2);	
	end if;
end process;




end behav;

