library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.PCK_param_sched.all;


entity shutter_sync_rcv is 
generic 
(  
	GRP_INDEX     : integer := 2;
	GRP_SIZE      : integer := 10;
	IS_5G         : std_logic := '0' ;
	IS_BACK       : std_logic := '0' ;
	
	D_AW        : INTEGER := 9 ;
	D_DW        : INTEGER := 64;
	TAB_AW      : INTEGER := 10 ;
	TAB_DW      : INTEGER := 16 ;
	POS_AW      : INTEGER := 10 ;
	POS_DW      : INTEGER := 64  
);
port  
(
    nRST                  :  in  std_logic ;
    clk                   :  in  std_logic ;

   --pbus 
    p_Frame_en_i          : in std_logic ;
    p_Wren_i              : in std_logic ;
    p_Data_i              : in std_logic_vector(7 downto 0);
    p_Addr_i              : in std_logic_vector(10 downto 0); 
    
    shutter_enabe_o       : out  std_logic ;
    sched_SEGNUM_o        : out  std_logic_vector(GRP_SIZE*16-1 downto 0);
	
	pos_wren              : out  std_logic;
    pos_waddr             : out  std_logic_vector(POS_AW-1 downto 0);
    pos_data              : out  std_logic_vector(POS_DW-1 downto 0);
	
	tab_wren              : out  std_logic_vector(GRP_SIZE-1 downto 0);
    tab_data              : out  std_logic_vector(TAB_DW-1 downto 0);
    tab_waddr             : out  std_logic_vector(TAB_AW-1 downto 0);
	
	d_wren                : out   std_logic;
    d_waddr               : out   std_logic_vector( D_AW-1  downto 0);
    d_data                : out   std_logic_vector( D_DW-1  downto 0) ;
	d_byte_offset         : out   std_logic_vector(31 downto 0);
	d_byte_length         : out   std_logic_vector(15 downto 0);
	d_rcv_end             : out   std_logic;
	
	real_eth_num_conv     : in    std_logic_vector(3 downto 0)
);
end shutter_sync_rcv ;

architecture beha of shutter_sync_rcv is 

	
  --bigger block ram 
constant SHUTTER_SUBFT_ENABLE  : STD_LOGIC_VECTOR(7 DOWNTO 0):= X"00";
constant SHUTTER_SUBFT_DATA    : STD_LOGIC_VECTOR(7 DOWNTO 0):= X"01";
constant SHUTTER_SUBFT_SCHED   : STD_LOGIC_VECTOR(7 DOWNTO 0):= X"02";
constant SHUTTER_SUBFT_POS     : STD_LOGIC_VECTOR(7 DOWNTO 0):= X"03"; 

signal  hit_shutter     : std_logic := '0';
signal  shutter_enable  : std_logic := '0';
signal  d_enable        : std_logic := '0';

CONSTANT POS_OFF  : INTEGER := 30 ; 
CONSTANT TAB_OFF  : INTEGER := 30 ; 
CONSTANT DATA_OFF : INTEGER := 26 ; 

signal byte_cnt                  : integer range 0 to 7 ;

signal hit_data   : std_logic ;
signal hit_pos    : std_logic ;
signal hit_table  : std_logic ;

signal last_byte  : std_logic ;
signal data_offset: std_logic_vector(31 downto 0);
signal data_len   : std_logic_vector(15 downto 0);
signal subFrm_idx : std_logic_vector(15 downto 0);
signal subFrm_total: std_logic_vector(15 downto 0); 
signal subFrm_type : std_logic_vector( 7 downto 0); 
signal sched_SEGNUM: std_logic_vector(GRP_SIZE*16-1 downto 0); 
signal wr_addr_buf : std_logic_vector(9-1 downto 0);
signal eth_num     : std_logic_vector(7 downto 0);
signal cur_eth_num_buf     : std_logic_vector(7 downto 0);
signal hit_table_eth   : std_logic;
signal brdcast_en      : std_logic;



  
begin 

	d_rcv_end       <= last_byte and hit_data;
    d_byte_offset   <= data_offset;   
	d_byte_length   <= data_len-8	;
	shutter_enabe_o <= shutter_enable ;
	sched_SEGNUM_o  <= sched_SEGNUM ;
	
	process(nRST,clk)
    begin 
        if nRST = '0' then 
           cur_eth_num_buf <= (others=>'0');
        elsif rising_edge(clk) then 

			if hit_table_eth = '1' then
				if eth_num = X"FF" then
					cur_eth_num_buf <= (others=>'0');---FF start from eth 0
				elsif IS_5G ='0' then
                    if GRP_INDEX = 0 then --four fibers
						if IS_BACK = '0' then   --main 0-9
							cur_eth_num_buf <= eth_num;
						else 					--backup 20-29
							cur_eth_num_buf <= eth_num-20;
						end if;
				    else
						if IS_BACK = '0' then   --main 10-19
							cur_eth_num_buf <= eth_num-real_eth_num_conv;
						else 					--backup 30-39
							cur_eth_num_buf <= eth_num-30;
						end if;
                    end if;
                ELSE --5G
                    --SHOULD BE ZERO ------
                     if GRP_INDEX = 0 then
					    cur_eth_num_buf <= eth_num;
				    elsIF GRP_INDEX = 1 THEN
                        cur_eth_num_buf <= eth_num-1;
                    ELSIF GRP_INDEX = 2 THEN
                        cur_eth_num_buf <= eth_num-2;
                    ELSE
                        cur_eth_num_buf <= eth_num-3;
                    END IF;
				end if;
			end if;
       end if;
    end process;
	

	process(nRST,clk)
	begin 
		if nRST = '0' then
			shutter_enable <= '0';  ---enable : 1 
			d_enable       <= '0';
			last_byte      <= '0';
			sched_SEGNUM   <= (others=>'0');
			hit_shutter    <= '0';
			hit_table_eth  <= '0';
			brdcast_en     <= '0';
		elsif rising_edge(clk) then 

			d_enable  <= shutter_enable ;

            last_byte <= '0';
            if p_Frame_en_i = '1' then 
				if p_Wren_i = '1' and p_Addr_i = 0 and p_Data_i = FT_RT_SHUTTER then 
					hit_shutter <= '1';                     
				end if; 
                 
				if p_Wren_i = '1' and hit_shutter = '1' then
                    case (conv_integer(p_Addr_i) ) is 
						when   6 =>  
							eth_num                      <= p_Data_i;
							if (p_Data_i >= GRP_INDEX*conv_integer(real_eth_num_conv) and p_Data_i <(GRP_INDEX+1)*conv_integer(real_eth_num_conv) ) or p_Data_i = X"FF" then
								hit_table_eth <= '1';									
							end if;
							if p_Data_i = X"FF" then
								brdcast_en <= '1';
							else
								brdcast_en <= '0';
							end if;
                        when   7 =>   subFrm_type                  <= p_Data_i; 
                        when   8 =>   subFrm_total (7 downto 0)    <= p_Data_i; 
                        when   9 =>   subFrm_total (15 downto 8)   <= p_Data_i;
                        when  10 =>   subFrm_idx   (7  downto 0)   <= p_Data_i ;
                        when  11 =>   subFrm_idx   (15 downto 8)   <= p_Data_i ;
                        when  16 =>   data_len     ( 7  downto 0)  <= p_Data_i;
                        when  17 =>   data_len     (15 downto 8)   <= p_Data_i;
                        when  22 =>   data_offset  ( 7  downto 0)  <= p_Data_i ;  --data offset is aligned to 32 at least 
                        when  23 =>   data_offset  (15  downto 8)  <= p_Data_i ;
                        when  24 =>   data_offset  (23  downto 16) <= p_Data_i ;
                        when  25 =>   data_offset  (31  downto 24) <= p_Data_i ;

                        when  28 => 
									if(hit_table = '1'and hit_table_eth ='1') then 
										if brdcast_en = '0' then
											sched_SEGNUM(conv_integer(cur_eth_num_buf)*16+7 downto conv_integer(cur_eth_num_buf)*16) <= p_Data_i ; 
										else
											for i in 0 to GRP_SIZE-1 loop
												sched_SEGNUM(i*16+7 downto i*16) <= p_Data_i;
											end loop;
										end if;
									end if;
                        when  29 =>
									if(hit_table = '1'and hit_table_eth ='1') then 
										if brdcast_en = '0' then
											sched_SEGNUM(conv_integer(cur_eth_num_buf)*16+15 downto conv_integer(cur_eth_num_buf)*16+8) <= p_Data_i ; 
										else
											for i in 0 to GRP_SIZE-1 loop
												sched_SEGNUM(i*16+15 downto i*16+8) <= p_Data_i;
											end loop;											
										end if;  
									end if;
                        when others=>null;
                    end case;
                end if;
                if p_Wren_i = '1' and p_Addr_i = (data_len +18 - 2) and p_Addr_i >= 22 then 
                    last_byte <= '1';
                else 
                    last_byte <= '0';
                end if;
				
				
                          
                if p_Wren_i = '1' and p_Addr_i = 26 and hit_shutter = '1' then
                    if subFrm_type = SHUTTER_SUBFT_ENABLE then 
                        shutter_enable <= p_Data_i(0);
                    end if;
                end if;   
			else
				hit_shutter <= '0';
				hit_table_eth <= '0';
				subFrm_type <= X"FF";
            end if; 
			if hit_shutter = '1' and subFrm_type = SHUTTER_SUBFT_DATA   then hit_data  <= '1' ; else hit_data   <= '0'; end if;
			if hit_shutter = '1' and subFrm_type = SHUTTER_SUBFT_POS    then hit_pos   <= '1' ; else hit_pos    <= '0'; end if;
			if hit_shutter = '1' and subFrm_type = SHUTTER_SUBFT_SCHED  then hit_table <= '1' ; else hit_table  <= '0'; end if;
		end if;
	end process;


	


   drecv: process(nRST,clk)
   begin 
       if nRST = '0' then
            d_wren    <= '0';
            
			wr_addr_buf   <= (others=>'0');
       elsif rising_edge(clk) then 
            d_waddr   <= wr_addr_buf;
			pos_waddr <= data_offset(3+POS_AW-1 downto 3)+wr_addr_buf;
			if p_Frame_en_i = '1' and p_Wren_i = '1' and hit_data = '1' then
				if p_Addr_i <DATA_OFF then
					byte_cnt <= 0;
				elsif p_Wren_i = '1' then
					if byte_cnt = 7 then
						byte_cnt <= 0;
					else
						byte_cnt <= byte_cnt +1;
					end if;
					d_data((byte_cnt+1)*8-1 downto byte_cnt*8) <= p_Data_i;
				end if;		
				
				if byte_cnt = 7 or last_byte ='1' then
					d_wren     <= '1';
					wr_addr_buf   <= wr_addr_buf + 1;
				else
					d_wren <= '0';
				end if;
				
			elsif p_Frame_en_i = '1' and p_Wren_i = '1' and hit_pos = '1' then
				if p_Addr_i <POS_OFF then
					byte_cnt <= 0;
				elsif p_Wren_i = '1' then
					if byte_cnt = 7 then
						byte_cnt <= 0;
					else
						byte_cnt <= byte_cnt +1;
					end if;
					pos_data((byte_cnt+1)*8-1 downto byte_cnt*8) <= p_Data_i;
				end if;		
				
				if byte_cnt = 7 or last_byte ='1' then
					pos_wren      <= '1';
					wr_addr_buf   <= wr_addr_buf + 1;
				else
					pos_wren <= '0';
				end if;				
				
				
				
			else
				d_wren    <= '0';
				pos_wren  <= '0';
				byte_cnt  <= 0;
				wr_addr_buf   <= (others=>'0');
			end if;
		

       end if;
  end process;
  
	process(nRST,clk)
	begin 
		if nRST = '0' then
            tab_wren    <= (others=>'0');
            tab_waddr   <= (others=>'0'); 
		elsif rising_edge(clk) then 
			-- tab_waddr(TAB_AW-1) <= cur_eth_num_buf(0);
            tab_waddr(TAB_AW-1 downto 0) <= data_offset(TAB_AW downto 1) + p_Addr_i(9 downto 1) - (TAB_OFF/2); --- data from 26 offset f 
            IF p_Frame_en_i = '1'    and p_Wren_i = '1' and hit_table = '1' then 
                if p_Addr_i(0) = '0' then 
                    tab_data(7 downto 0)  <= p_Data_i;
                else 
                    tab_data(15 downto 8) <= p_Data_i;
                end if;
            end if;
            if p_Frame_en_i = '1'    and p_Wren_i = '1' and hit_table = '1' and (p_Addr_i >= TAB_OFF )and hit_table_eth = '1' then 
				if brdcast_en = '0' then
					if  (p_Addr_i(0) = '1') or last_byte = '1' then 
						tab_wren(conv_integer(cur_eth_num_buf(3 downto 0)))    <= '1'; 
					else 
						tab_wren(conv_integer(cur_eth_num_buf(3 downto 0)))    <= '0'; 
					end if;
				else
					if  (p_Addr_i(0) = '1') or last_byte = '1' then 
						tab_wren <= (others=>'1');
					else
						tab_wren <= (others=>'0');
					end if;
				end if;
            else 
				tab_wren    <= (others=>'0');
            end if;
		end if;
	end process;
  


end beha ;