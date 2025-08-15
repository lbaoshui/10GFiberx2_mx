--#######################################################################
--
--  LOGIC CORE:          vidout_cmd_gene                            
--  MODULE NAME:         vidout_cmd_gene()
--  COMPANY:             
--                              
--
--  REVISION HISTORY:  
--
--  Revision 0.1  07/20/2007    Description: Initial .
--
--  FUNCTIONAL DESCRIPTION:
--
--  this module is to generate the para for vidout data channel
--
--  Copyright (C)   Shenzhen ColorLight Tech. Inc.
--
--#######################################################################



library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;



entity simul_eth_timing is
generic(
	VID_NUM_IN_SLOT						: integer:= 8

);
port(
	nRST								: in  std_logic;
	sysclk								: in  std_logic;
    color_depth							: in  std_logic_vector(1 downto 0);

    output_eth_type						: in	std_logic_vector(2 downto 0);			-- "000":1G,	"001":fix 5G,	"100":average 2.5G,flexible
	
    vidout_vsync_neg                    : in  std_logic;
    pack_cmd_wren                       : in  std_logic;
    pack_cmd_data                       : in  std_logic_vector(14 downto 0);
    ch_vld                              : in  std_logic_vector(VID_NUM_IN_SLOT-1 downto 0);
    ch_sel                              : in  std_logic_vector(3 downto 0);
    
	
	vidinfo_req                         : in  std_logic_vector(VID_NUM_IN_SLOT-1 downto 0);

	simul_eth_almost_empty_en           : out std_logic;
	simul_eth_empty_en                  : out std_logic;
	
	simul_eth_almost_full_o             : out std_logic_vector(VID_NUM_IN_SLOT-1 downto 0);
	simul_eth_almost_empty_o            : out std_logic_vector(VID_NUM_IN_SLOT-1 downto 0);
	simul_eth_empty_o                   : out std_logic_vector(VID_NUM_IN_SLOT-1 downto 0);
	
 

	
	packet_gap_5g                       : in  std_logic_vector(9 downto 0)
    
);
end entity;

architecture behav of simul_eth_timing is

constant SM_W                           : integer := 16;
--simul
constant FIFO1G_D_FULL					: integer:= 4096-2048;
constant FIFO1G_D_EMPTY					: integer:= 1024;

constant FIFO5G_D_FULL					: integer:= 4096-2048;
constant FIFO5G_D_EMPTY					: integer:= 1024;


constant FRAME1G_GAP					: integer:= 24;
constant FRAME5G_GAP					: integer:= 100;
constant FRAME1G_VSYNC_LEN				: integer:= FRAME1G_GAP+1050;
constant FRAME1G_DATA_EXTRA				: integer:= FRAME1G_GAP+33;
constant FRAME5G_VSYNC_LEN				: integer:= FRAME5G_GAP+1050;
constant FRAME5G_DATA_EXTRA				: integer:= FRAME5G_GAP+33;



signal simul_tune						: std_logic_vector(2 downto 0);
signal simul_tune_en					: std_logic;
signal simul_eth_cnt					: std_logic_vector(VID_NUM_IN_SLOT*SM_W-1 downto 0);
signal simul_eth_plus_vsync				: std_logic;
signal simul_eth_plus_data				: std_logic;
signal simul_eth_plus_sel				: std_logic_vector(3 downto 0);
signal simul_eth_plus_num				: std_logic_vector(10 downto 0);
signal simul_eth_almost_full			: std_logic_vector(VID_NUM_IN_SLOT-1 downto 0);
signal simul_eth_almost_empty			: std_logic_vector(VID_NUM_IN_SLOT-1 downto 0);
signal simul_eth_empty		         	: std_logic_vector(VID_NUM_IN_SLOT-1 downto 0);

signal accum_bit						: std_logic_vector(VID_NUM_IN_SLOT*24-1 downto 0);


signal TUNE_NUM							: integer;
signal simul_eth_plus_bitnum			: std_logic_vector(24-1 downto 0)		:=(others => '0');

---------------------------------------------------------------------------------

begin


TUNE_NUM <= 1   when output_eth_type = "000" 
        else 4  when output_eth_type = "100" 
		else 4  when output_eth_type = "001" 
        else 1;
simul_eth_plus_bitnum <= "000"&simul_eth_plus_num&"000"&"0000000";		-- 18b int, 7b fract

--simul
process(sysclk,nRST)
begin
	if nRST = '0' then
		simul_tune <= (others => '0');
		simul_tune_en <= '0';
		
		simul_eth_plus_vsync <= '0';
		simul_eth_plus_data <= '0';
		
		simul_eth_cnt <= (others => '0');
		simul_eth_almost_full <= (others => '1');
		simul_eth_almost_empty <= (others => '0');
	
	elsif rising_edge(sysclk) then
		if output_eth_type = "100" or output_eth_type = "001" then			
			simul_tune_en <= '1';
		else
			if simul_tune = 4 then
				simul_tune <= (others=>'0');
			else
				simul_tune <= simul_tune +1;
			end if;
			if simul_tune = 0 then				
				simul_tune_en <= '0';
			else
				simul_tune_en <= '1';
			end if;
		end if;
		
		if pack_cmd_wren = '1' and pack_cmd_data(14 downto 13) = "01" then
			simul_eth_plus_vsync <= '1';
		else
			simul_eth_plus_vsync <= '0';
		end if;
		
		if pack_cmd_wren = '1' and (pack_cmd_data(14 downto 13) = "00" or pack_cmd_data(14 downto 13) = "10") then
			simul_eth_plus_data <= '1';
		else
			simul_eth_plus_data <= '0';
		end if;
		simul_eth_plus_sel <= pack_cmd_data(12 downto 9);
        
		

        if output_eth_type = "001" or output_eth_type = "100" then --5G ETH 
			if pack_cmd_data(14 downto 13)= "10" then -----param frame
				simul_eth_plus_num <= (pack_cmd_data(7 downto 0)&"000")-5+ conv_std_logic_vector(FRAME5G_DATA_EXTRA,11);--5 is  4+1 , 1  is  FD
            elsif color_depth = 0 then
                simul_eth_plus_num <= ("00"&pack_cmd_data(8 downto 0)) + ('0'&pack_cmd_data(8 downto 0)&'0') + conv_std_logic_vector(FRAME5G_DATA_EXTRA,11);
            elsif color_depth = 1 then
                simul_eth_plus_num <= (pack_cmd_data(8 downto 0)&"00") + conv_std_logic_vector(FRAME5G_DATA_EXTRA,11);
			else----12bit
				simul_eth_plus_num <= (pack_cmd_data(8 downto 0)&"00") + ("00"&pack_cmd_data(8 downto 0)) + conv_std_logic_vector(FRAME5G_DATA_EXTRA,11);
            end if;  

        else --1G
			if pack_cmd_data(14 downto 13)= "10" then -----param frame
				simul_eth_plus_num <= (pack_cmd_data(7 downto 0)&"000")-5+ conv_std_logic_vector(FRAME1G_DATA_EXTRA,11);--5 is  4+1 , 1  is  FD
            elsif color_depth = 0 then
                simul_eth_plus_num <= ("00"&pack_cmd_data(8 downto 0)) + ('0'&pack_cmd_data(8 downto 0)&'0') + conv_std_logic_vector(FRAME1G_DATA_EXTRA,11);
            elsif color_depth = 1 then
                simul_eth_plus_num <= (pack_cmd_data(8 downto 0)&"00") + conv_std_logic_vector(FRAME1G_DATA_EXTRA,11);
			else
				simul_eth_plus_num <= (pack_cmd_data(8 downto 0)&"00") + ("00"&pack_cmd_data(8 downto 0)) + conv_std_logic_vector(FRAME1G_DATA_EXTRA,11);
            end if;    
        end if;
        
		for i in 0 to VID_NUM_IN_SLOT-1 loop
			if vidout_vsync_neg = '1' then
				simul_eth_cnt((i+1)*SM_W-1 downto i*SM_W) <= (others => '0');
				simul_eth_almost_empty(i) <= '0';
				simul_eth_almost_full(i) <= '1';
				accum_bit((i+1)*24-1 downto i*24) <= (others => '0');
			else
				if simul_tune_en = '0' then
					if simul_eth_plus_vsync = '1' and i = simul_eth_plus_sel then
                        if output_eth_type = "001" or output_eth_type = "100" then --5G ETH 
                            simul_eth_cnt((i+1)*SM_W-1 downto i*SM_W) <= simul_eth_cnt((i+1)*SM_W-1 downto i*SM_W) + conv_std_logic_vector(FRAME5G_VSYNC_LEN,SM_W);							
					    else 
						    simul_eth_cnt((i+1)*SM_W-1 downto i*SM_W) <= simul_eth_cnt((i+1)*SM_W-1 downto i*SM_W) + conv_std_logic_vector(FRAME1G_VSYNC_LEN,SM_W);
                       end if;
					elsif simul_eth_plus_data = '1' and i = simul_eth_plus_sel then
						simul_eth_cnt((i+1)*SM_W-1 downto i*SM_W) <= simul_eth_cnt((i+1)*SM_W-1 downto i*SM_W) + ("00"&simul_eth_plus_num);
					end if;
				else
					if simul_eth_plus_vsync = '1' and i = simul_eth_plus_sel then

						if output_eth_type = "001" or output_eth_type = "100" then	-- 5G
							simul_eth_cnt((i+1)*SM_W-1 downto i*SM_W) <= simul_eth_cnt((i+1)*SM_W-1 downto i*SM_W) + conv_std_logic_vector(FRAME5G_VSYNC_LEN-1,SM_W);
						else
							simul_eth_cnt((i+1)*SM_W-1 downto i*SM_W) <= simul_eth_cnt((i+1)*SM_W-1 downto i*SM_W) + conv_std_logic_vector(FRAME1G_VSYNC_LEN-1,SM_W);
						end if;
						

					elsif simul_eth_plus_data = '1' and i = simul_eth_plus_sel then
								-- 1G/5G
						if simul_eth_cnt((i+1)*SM_W-1 downto i*SM_W) + ("00"&simul_eth_plus_num) >= TUNE_NUM then
							simul_eth_cnt((i+1)*SM_W-1 downto i*SM_W) <= simul_eth_cnt((i+1)*SM_W-1 downto i*SM_W) + ("00"&simul_eth_plus_num) - TUNE_NUM;
						else
							simul_eth_cnt((i+1)*SM_W-1 downto i*SM_W) <= (others => '0');
						end if;

						
						
					else
							-- 1G/5G
						if simul_eth_cnt((i+1)*SM_W-1 downto i*SM_W) >= TUNE_NUM then
							simul_eth_cnt((i+1)*SM_W-1 downto i*SM_W) <= simul_eth_cnt((i+1)*SM_W-1 downto i*SM_W) - TUNE_NUM;
						else
							simul_eth_cnt((i+1)*SM_W-1 downto i*SM_W) <= (others => '0');
						end if;

					end if;
				end if;
				
				
					
				if output_eth_type = "001" or output_eth_type = "100" then		-- 5G ETH 
					if simul_eth_cnt((i+1)*SM_W-1 downto i*SM_W) < FIFO5G_D_FULL and ch_vld(i) = '1' then
						simul_eth_almost_full(i) <= '0';
					else
						simul_eth_almost_full(i) <= '1';
					end if;
					
					if simul_eth_cnt((i+1)*SM_W-1 downto i*SM_W) < FIFO5G_D_EMPTY and ch_vld(i) = '1' and vidinfo_req(i) = '1'  then
						simul_eth_almost_empty(i) <= '1';
					else
						simul_eth_almost_empty(i) <= '0';
					end if;
					
					if simul_eth_cnt((i+1)*SM_W-1 downto i*SM_W) = 0  and ch_vld(i) = '1' and vidinfo_req(i) = '1' then
						simul_eth_empty(i) <= '1';
					else
						simul_eth_empty(i) <= '0';
					end if;	
					
                else									-- 1G
					if simul_eth_cnt((i+1)*SM_W-1 downto i*SM_W) < FIFO1G_D_FULL and ch_vld(i) = '1' then
						simul_eth_almost_full(i) <= '0';
					else
						simul_eth_almost_full(i) <= '1';
					end if;
					
					if simul_eth_cnt((i+1)*SM_W-1 downto i*SM_W) < FIFO1G_D_EMPTY and ch_vld(i) = '1' and vidinfo_req(i) = '1' then
						simul_eth_almost_empty(i) <= '1';
					else
						simul_eth_almost_empty(i) <= '0';
					end if;
					
					if simul_eth_cnt((i+1)*SM_W-1 downto i*SM_W) = 0  and ch_vld(i) = '1' and vidinfo_req(i) = '1' then
						simul_eth_empty(i) <= '1';
					else
						simul_eth_empty(i) <= '0';
					end if;					
					
                end if;
				
				-- eth_sched_first(i)  <= simul_eth_almost_empty(i) and vidinfo_req(i);
				
			end if;
		end loop;
	end if;
end process;

simul_eth_almost_empty_o <= simul_eth_almost_empty;
simul_eth_empty_o        <= simul_eth_empty;


simul_eth_almost_empty_en <= '0' when simul_eth_almost_empty = 0 else '1';
simul_eth_almost_full_o   <= simul_eth_almost_full;

simul_eth_empty_en     <=  '0' when simul_eth_empty = 0 else '1';



end behav;

