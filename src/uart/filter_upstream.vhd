library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

--=============================================================================================================
-- This module is to pack 10 GMII channels to one single XGMII channel in a time division multiplexing way.
-- Encapsulation protocol is consistent with H16F.
--=============================================================================================================

entity filter_upstream is
generic(

	PORTNUM_EVERY_FIBER : integer := 10
);
   
port(

   nRST                          : in std_logic;
   ddr3cmd_nRST                  : in std_logic;
   ddr3cmd_clk                   : in std_logic;
    
   serd_rx_clk                   : in  std_logic;
   adjust_rx_k		             : in  std_logic_vector(7 downto 0);  
   adjust_rx_data                : in  std_logic_vector(63 downto 0);


   filt_adjust_rx_k              : out std_logic_vector(7 downto 0);
   filt_adjust_rx_data           : out std_logic_vector(63 downto 0);
   
   eth_status_sys                : out std_logic_vector(PORTNUM_EVERY_FIBER-1 downto 0);
   err_num_fiber_sys             : out std_logic_vector(31 downto 0);
   fiber_status_flag_serdrx      : out std_logic;
   
--    subfrm_type_08_cnt_o          : out std_logic_vector(32-1 downto 0);

   autolight_outen_ddr3cmd               : out std_logic_vector(PORTNUM_EVERY_FIBER-1 downto 0);
   autolight_outval_ddr3cmd              : out std_logic_vector(PORTNUM_EVERY_FIBER*8-1 downto 0)
);
end entity;

architecture behav of filter_upstream is

signal is_h10fn_frmFB_upload      : std_logic;
signal is_h10fn_frmFB_upload_d1      : std_logic;
signal is_h10fn_frmFB_upload_d2      : std_logic;
signal is_h10fn_frmFB_upload_d3      : std_logic;
signal HEADER               : std_logic_vector(63 downto 0);
signal HEAD_CTRL            : std_logic_vector(7 downto 0);
signal serd_rx_clk_i                   :   std_logic;

signal IDLER               : std_logic_vector(63 downto 0);
signal IDLE_CTRL            : std_logic_vector(7 downto 0);

signal head_det : std_logic:='0';
signal head_det_d1 : std_logic:='0';
signal head_det_d2 : std_logic:='0';
signal adjust_rx_k_d1    : std_logic_vector(7 downto 0):=(others=>'0');
signal adjust_rx_data_d1 : std_logic_vector(63 downto 0):=(others=>'0');
signal adjust_rx_k_d2    : std_logic_vector(7 downto 0):=(others=>'0');
signal adjust_rx_data_d2 : std_logic_vector(63 downto 0):=(others=>'0');
signal adjust_rx_k_d3    : std_logic_vector(7 downto 0):=(others=>'0');
signal adjust_rx_data_d3 : std_logic_vector(63 downto 0):=(others=>'0');
signal adjust_rx_k_d4    : std_logic_vector(7 downto 0):=(others=>'0');
signal adjust_rx_data_d4 : std_logic_vector(63 downto 0):=(others=>'0');
signal frame_type : std_logic_vector(7 downto 0):=(others=>'0');
signal frame_type_d1 : std_logic_vector(7 downto 0):=(others=>'0');
signal frame_type_d2 : std_logic_vector(7 downto 0):=(others=>'0');
signal subfrm_type   : std_logic_vector(7 downto 0):=(others=>'0');
signal frame_end  : std_logic:='0';
signal cnt        : std_logic_vector(12 downto 0):=(others=>'0');
signal clear_en   : std_logic:='0';
signal clear_en_d1: std_logic:='0';
signal clear_en_d2: std_logic:='0';
signal clear_en_d3: std_logic:='0';
signal record_autolight_en : std_logic:='0';
signal filter_en   : std_logic:='0';
signal eth_status_serdrx  :  std_logic_vector(PORTNUM_EVERY_FIBER-1 downto 0);
signal eth_status_serdrx_d1  :  std_logic_vector(PORTNUM_EVERY_FIBER-1 downto 0);
signal eth_status_serdrx_d2  :  std_logic_vector(PORTNUM_EVERY_FIBER-1 downto 0);

component cross_domain is 
	generic (
	   DATA_WIDTH: integer:=8 
	);
	port 
	(   clk0      : in std_logic;
		nRst0     : in std_logic;		
		datain    : in std_logic_vector(DATA_WIDTH-1 downto 0);
		datain_req: in std_logic;
		
		clk1: in std_logic;
		nRst1: in std_logic;
		data_out: out std_logic_vector(DATA_WIDTH-1 downto 0);
		dataout_valid:out std_logic  ---just pulse only
	);
end component ;
signal autolight_outen              :  std_logic_vector(PORTNUM_EVERY_FIBER-1 downto 0);
signal autolight_outval             :  std_logic_vector(PORTNUM_EVERY_FIBER*8-1 downto 0);
signal autolight                    :  std_logic_vector(7 downto 0):=(others=>'0');
signal autolight_outen_buf          :  std_logic_vector(PORTNUM_EVERY_FIBER-1 downto 0);
signal CHL_NUM                      :  std_logic_vector(7 downto 0):=(others=>'0');
signal target_mac                   :  std_logic_vector(7 downto 0):=(others=>'0');
signal autolight_outen_d1           :  std_logic_vector(PORTNUM_EVERY_FIBER-1 downto 0);
signal target_mac_d1                   :  std_logic_vector(7 downto 0):=(others=>'0');
signal target_mac_d2                   :  std_logic_vector(7 downto 0):=(others=>'0');
signal err_num_fiber_rx                : std_logic_vector(31 downto 0);
      
signal autolight_outen_level        : std_logic_vector(PORTNUM_EVERY_FIBER-1 downto 0);
signal autolight_outen_level_out    : std_logic_vector(PORTNUM_EVERY_FIBER-1 downto 0);
signal autolight_outen_cnt          : std_logic_vector(3*PORTNUM_EVERY_FIBER-1 downto 0);
signal autolight_outen_level_edge   : std_logic_vector(5*PORTNUM_EVERY_FIBER-1 downto 0); -- 

/*
type ARRAY_4x39  is array (0 to 9)  of std_logic_vector(3 downto 0);
type ARRAY_8x39  is array (0 to 9)  of std_logic_vector(7 downto 0);

signal vld_cnt              : ARRAY_4x39;
signal timeout_cnt          : ARRAY_8x39;
signal is_connected         : std_logic_vector(10-1 downto 0);
-- signal cnt_5s               : std_logic_vector(15 downto 0); 
signal cnt_100ms            : std_logic_vector(7 downto 0); 
-- signal time_5s_en           : std_logic;
signal time_100ms_en        : std_logic;
signal time_ms_en           : std_logic:='0';
signal time_ms_cnt          : std_logic_vector(17 downto 0):=(others => '0');   

signal subfrm_type_08_cnt           : std_logic_vector(16*10-1 downto 0):=(others=>'0');
signal subfrm0805_type              : std_logic_vector(7  downto 0):=(others=>'0');
signal eth_num                      : std_logic_vector(8-1  downto 0):=(others=>'0');

attribute keep : string;
attribute keep of subfrm_type_08_cnt : signal is "true";
attribute keep of subfrm0805_type : signal is "true";
attribute keep of eth_num : signal is "true";
attribute keep of is_connected : signal is "true";
*/
--=============================================================================================================================
begin 
--=============================================================================================================================
HEADER <= X"D5555555555555FB";
HEAD_CTRL <= X"01";

IDLER <= X"0707070707070707";
IDLE_CTRL <= X"FF";

-- subfrm_type_08_cnt_o <= subfrm_type_08_cnt;

serd_rx_clk_i <= serd_rx_clk;
frame_type <= adjust_rx_data(39 downto 32);
target_mac <= adjust_rx_data(7 downto 0);
subfrm_type<= adjust_rx_data(39 downto 32);
-- subfrm0805_type <= adjust_rx_data(47 downto 40);
-- eth_num         <= adjust_rx_data(23 downto 16);
--------------for fiber and eth status upload,h10fn upload FRAME D4 every 4s if fiber is link-------------   -- 
process(nRST,serd_rx_clk)
begin
	if nRST = '0' then
		is_h10fn_frmFB_upload <='0';
		eth_status_serdrx <=(others =>'0');

	elsif rising_edge(serd_rx_clk)then
	
	    fiber_status_flag_serdrx <= is_h10fn_frmFB_upload or is_h10fn_frmFB_upload_d1 or is_h10fn_frmFB_upload_d2 or is_h10fn_frmFB_upload_d3 ;
		is_h10fn_frmFB_upload_d1 <= is_h10fn_frmFB_upload;
		is_h10fn_frmFB_upload_d2 <= is_h10fn_frmFB_upload_d1;
		is_h10fn_frmFB_upload_d3 <= is_h10fn_frmFB_upload_d2;
								
		if adjust_rx_k = HEAD_CTRL and adjust_rx_data(7 downto 0) = X"FB" and adjust_rx_data(55 downto 40) = HEADER(55 downto 40) then
            head_det <= '1';
        else
            head_det <= '0';
        end if;

		--------------- frame D4 subframe FB,is H10FN upload frame,contain eth status
		if adjust_rx_k_d2 = X"00" and frame_type_d2 = X"D4" and head_det_d2 = '1' and subfrm_type = X"FB"then
			is_h10fn_frmFB_upload <='1';
		else
			is_h10fn_frmFB_upload <='0';
		end if;
		
        if is_h10fn_frmFB_upload = '1' then
			---eth_status_serdrx <= adjust_rx_data(25 downto 16);---eth0 is bit16
			eth_status_serdrx <= adjust_rx_data(16+PORTNUM_EVERY_FIBER-1 downto 16);---eth0 is bit16
		end if;
		
		if  is_h10fn_frmFB_upload_d1 = '1' then			
			err_num_fiber_rx <= adjust_rx_data(63 downto 32);
        end if;			
			
	end if;
end process;
----------------------------------------------------------------------------------------------
----------------autolight--------------------------------------
process(ddr3cmd_clk)
begin
	if rising_edge(ddr3cmd_clk) then
		-- autolight_outen_d1 <= autolight_outen;
		-- autolight_outen_ddr3cmd <= autolight_outen_d1;
		for i in 0 to PORTNUM_EVERY_FIBER-1 loop
			autolight_outen_level_edge(5*i+4 downto 5*i) <= autolight_outen_level_edge(i*5+3 downto i*5) & autolight_outen_level(i);
			if autolight_outen_level_edge(5*i+3) = '1' and autolight_outen_level_edge(5*i+4) = '0' then   -- rising_edge
				autolight_outen_level_out(i) <= '1';
			else
				autolight_outen_level_out(i) <= '0';
			end if;
		end loop;

		autolight_outen_d1 <= autolight_outen_level_out;
		autolight_outen_ddr3cmd <= autolight_outen_d1;
	end if;
end process;

-- process(nRST,serd_rx_clk)
-- begin
-- 	if(nRST = '0') then 
--         time_ms_en <= '0';
--         -- time_ms_en_o <= '0';
--         -- ms_en_flipflop_sys <= '0';
--         time_ms_cnt <= (others => '0');
--     elsif rising_edge(serd_rx_clk) then
-- 		if time_ms_cnt = 149999 then    --125000 * 8ns = 1ms,
-- 			time_ms_en <= '1';
-- 			time_ms_cnt <= (others => '0');
-- 		else
-- 			time_ms_en <= '0';
-- 			time_ms_cnt <= time_ms_cnt + '1';
-- 		end if;  

-- 		-- if time_ms_en = '1' then
--         --     if cnt_5s = 4999 then
--         --         cnt_5s <= (others => '0');
--         --         time_5s_en <= '1';
--         --     else
--         --         cnt_5s <= cnt_5s + '1';
--         --         time_5s_en <= '0';
--         --     end if;
--         -- else
--         --     time_5s_en <= '0';
--         -- end if;
        
--         if time_ms_en = '1' then
--             if cnt_100ms = 99 then
--                 cnt_100ms <= (others => '0');
--                 time_100ms_en <= '1';
--             else
--                 cnt_100ms <= cnt_100ms + '1';
--                 time_100ms_en <= '0';
--             end if;
--         else
--             time_100ms_en <= '0';
--         end if;

-- 		for i in 0 to 10-1 loop
--             if autolight_outen(i) = '1' then --PULSE ONLY 
--                 timeout_cnt(i) <= (others => '0');
--             elsif time_100ms_en = '1' and timeout_cnt(i)(6) = '0' then   -- 64x100ms
--                 timeout_cnt(i) <= timeout_cnt(i) + '1';
--             end if;
            
--             if timeout_cnt(i)(6) = '0' then
--                 is_connected(i) <= '1';  --AUTO CONNECTED 
--             else
--                 is_connected(i) <= '0';
--             end if;
--         end loop;    

--     end if;
-- end process;

----------------eth_link--------------------------------------
process(ddr3cmd_clk)
begin
	if rising_edge(ddr3cmd_clk) then
		eth_status_serdrx_d1 <= eth_status_serdrx;
		eth_status_serdrx_d2 <= eth_status_serdrx_d1;
		eth_status_sys <= eth_status_serdrx_d2;
	end if;
end process;
------------------------------------------------------------------------
process(nRST, serd_rx_clk)
begin
	if nRST = '0' then
		autolight_outen_level <= (others => '0');
		autolight_outen_cnt   <= (others => '0');
	elsif rising_edge(serd_rx_clk) then
		for i in 0 to PORTNUM_EVERY_FIBER-1 loop
			if autolight_outen(i) = '1' then
				autolight_outen_cnt(3*i+2 downto 3*i) <= (others => '0');
				autolight_outen_level(i) <= '1';
			elsif autolight_outen_cnt(3*i+2) = '1' then
				autolight_outen_level(i) <= '0';
				-- autolight_outen_cnt(3*i+2 downto 3*i) <= (others => '0');
			else
				autolight_outen_cnt(3*i+2 downto 3*i) <= autolight_outen_cnt(3*i+2 downto 3*i) + '1';
			end if;
			

			-- if autolight_outen_cnt(3*i+2) = '1' then
			-- 	autolight_outen_level(i) <= '0';
			-- 	autolight_outen_cnt(3*i+2 downto 3*i) <= (others => '0');
			-- else
			-- 	autolight_outen_cnt(3*i+2 downto 3*i) <= autolight_outen_cnt(3*i+2 downto 3*i) + '1';
			-- end if;
		end loop;
	end if;
end process;
----------------------------------------------------------------------------
process(nRST,serd_rx_clk)
begin
	if nRST = '0' then
		cnt <=(others=>'0');
		autolight_outen     <= (others=>'0');
		record_autolight_en <= '0';
		autolight           <= X"FF";
	elsif rising_edge(serd_rx_clk)then
		
		if clear_en = '1' then
			record_autolight_en <= '0';
			if record_autolight_en = '1' then
				autolight_outen <= autolight_outen_buf; --one pulse only 
			else
				autolight_outen <= (others=>'0');
			end if;
		
		elsif adjust_rx_k = X"00" and adjust_rx_data(39 downto 32)=X"F9" and head_det = '1' then
			record_autolight_en <= '1';
			CHL_NUM <= adjust_rx_data(23 downto 16);
			autolight_outen <= (others=>'0');
		else
			autolight_outen <= (others=>'0');

		end if;
		
	
		if record_autolight_en = '1' then
			cnt <= cnt + 1;
			if cnt = 96 then
				autolight <= adjust_rx_data(31 downto 24);
			end if;			
			
        else
			cnt <=(others=>'0');
		end if;
		
        for i in 0 to  PORTNUM_EVERY_FIBER-1 loop
			
			if CHL_NUM = i then
				autolight_outen_buf(i) <= '1';
				autolight_outval(8*(i+1)-1 downto 8*i) <= autolight;
			else
				autolight_outen_buf(i) <= '0';
			end if;
        end loop;	
    end if;
end process;	



process(nRST,serd_rx_clk)
begin
	if nRST = '0' then
		filter_en <= '0';
		clear_en <= '0';
		
	elsif rising_edge(serd_rx_clk)then
		clear_en_d1 <= clear_en ;
		clear_en_d2 <= clear_en_d1;
		clear_en_d3 <= clear_en_d2;
		
		
		head_det_d1 <= head_det;    -- xgmii数据包头标志
		head_det_d2 <= head_det_d1;
		
		adjust_rx_data_d1 <= adjust_rx_data;
		adjust_rx_data_d2 <= adjust_rx_data_d1;
		adjust_rx_data_d3 <= adjust_rx_data_d2;
		adjust_rx_data_d4 <= adjust_rx_data_d3;
		
		adjust_rx_k_d1 <= adjust_rx_k;
		adjust_rx_k_d2 <= adjust_rx_k_d1;		
		adjust_rx_k_d3 <= adjust_rx_k_d2;
		adjust_rx_k_d4 <= adjust_rx_k_d3;

		
		
		target_mac_d1  <= target_mac;
		target_mac_d2  <= target_mac_d1;
		
		frame_type_d1 <= frame_type;
		frame_type_d2 <= frame_type_d1;
		
		
		-- if clear_en_d3 = '1' then
			-- filter_en <= '0';	
        if  head_det_d2 = '1'  then
			if frame_type_d2 = X"D1" or frame_type_d2 = X"D0" or frame_type_d2 = X"60" or frame_type_d2 =X"55"or frame_type_d2 =X"54" or frame_type_d2 =X"53" or frame_type_d2 = X"01"or frame_type_d2 = X"F9"or frame_type_d2 =X"D3" then
				filter_en <= '1';
			elsif target_mac_d2 = X"FF" then
				if frame_type_d2 = X"D4" then
					if subfrm_type = X"08" then
						filter_en <= '0';
					else
						filter_en <= '1';
					end if;
				else
					filter_en <= '0';
				end if;
			else
				filter_en <= '1';
			end if;
		elsif clear_en_d3 = '1' then
			filter_en <= '0';	
		end if;

		
		if adjust_rx_k_d1 = X"00" and adjust_rx_k /= X"00" then
			clear_en <= '1';
		else
			clear_en <= '0';
		end if;
		
    end if;
end process;

-- process(nRST, serd_rx_clk)
-- begin
-- 	if nRST = '0' then
-- 		subfrm_type_08_cnt <= (others => '0');
-- 	elsif rising_edge(serd_rx_clk) then
-- 		for i in 0 to 9 loop
-- 			if head_det = '1'  then
-- 				if target_mac = X"FF" and eth_num = i then
-- 					if subfrm_type = X"08" and subfrm0805_type = X"05" then
-- 						subfrm_type_08_cnt(16*i+15 downto i*16) <= subfrm_type_08_cnt(16*i+15 downto i*16) + 1;
-- 					end if;
-- 				end if;
-- 			end if;
-- 		end loop;
-- 	end if;
-- end process;

process(nRST,serd_rx_clk)
begin
	if nRST = '0' then
		filt_adjust_rx_k    <= IDLE_CTRL;
		filt_adjust_rx_data <= IDLER;
	elsif rising_edge(serd_rx_clk)then
		if filter_en = '1' then
			filt_adjust_rx_k    <= IDLE_CTRL;
			filt_adjust_rx_data <= IDLER;
		else
			filt_adjust_rx_k    <= adjust_rx_k_d4;
			filt_adjust_rx_data <= adjust_rx_data_d4;
		end if;
	end if;
end process;

autolight_i: for i in 0 to PORTNUM_EVERY_FIBER-1 generate
     autolight_set_inst: cross_domain   
     	generic map(
     	   DATA_WIDTH => 8 
     	) 
     	port map
     	(   clk0       => serd_rx_clk_i   ,   
     		nRst0      => nRST ,   		
     		datain     =>  autolight_outval((i+1)*8-1 downto i*8),     
     		datain_req =>  '1' , 
     		
     		clk1    => ddr3cmd_clk    ,
     		nRst1   => ddr3cmd_nRST  , 
     		data_out      =>   autolight_outval_ddr3cmd((i+1)*8-1 downto i*8) ,  
     		dataout_valid =>   open  
     	); 
end generate autolight_i;

     err_num_inst: cross_domain   
     	generic map(
     	   DATA_WIDTH => 32
     	) 
     	port map
     	(   clk0       => serd_rx_clk_i   ,   
     		nRst0      => nRST ,   		
     		datain     => err_num_fiber_rx,     
     		datain_req =>  '1' , 
     		
     		clk1    => ddr3cmd_clk    ,
     		nRst1   => ddr3cmd_nRST  , 
     		data_out      =>   err_num_fiber_sys ,  
     		dataout_valid =>   open  
     	); 
		
end behav ;




