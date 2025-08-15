library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

--=============================================================================================================
-- This module is to pack 8 GMII channels to one single XGMII channel in a time division multiplexing way.
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
      

--=============================================================================================================================
begin 
--=============================================================================================================================
HEADER <= X"D5555555555555FB";
HEAD_CTRL <= X"01";

IDLER <= X"0707070707070707";
IDLE_CTRL <= X"FF";


serd_rx_clk_i <= serd_rx_clk;
frame_type <= adjust_rx_data(39 downto 32);
target_mac <= adjust_rx_data(7 downto 0);
subfrm_type<= adjust_rx_data(39 downto 32);
--------------for fiber and eth status upload,h10fn upload FRAME D4 every 4s if fiber is link-------------
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
		autolight_outen_d1 <= autolight_outen;
		autolight_outen_ddr3cmd <= autolight_outen_d1;
	end if;
end process;

----------------eth_link--------------------------------------
process(ddr3cmd_clk)
begin
	if rising_edge(ddr3cmd_clk) then
		eth_status_serdrx_d1 <= eth_status_serdrx;
		eth_status_serdrx_d2 <= eth_status_serdrx_d1;
		eth_status_sys <= eth_status_serdrx_d2;
	end if;
end process;


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
		
		
		head_det_d1 <= head_det;
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




