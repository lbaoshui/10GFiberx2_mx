
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.PCK_param_sched.all;

----only for downparam_tx module 
entity rcvparam_store is 
generic(
	DET_RCV_MAN_EN  : integer 

);
port  
(
    nRST : in  std_logic ;
    clk  : in  std_logic ;
    --pbus 
    p_Frame_en_i          : in std_logic ;
    p_Wren_i              : in std_logic ;
    p_Data_i              : in std_logic_vector(7 downto 0);
    p_Addr_i              : in std_logic_vector(10 downto 0); 
    cur_slot_num            : in std_logic_vector(15 downto 0);  

	
    rd_done               : in   std_logic ; --need one cycle for the status to switch 
    rd_addr               : in   std_logic_vector(10 downto 0);
    rd_q                  : out  std_logic_vector(7  downto 0);
    rd_len                : out  std_logic_vector(10 downto 0);
    rd_empty              : out  std_logic ;
	abort_detect_rcv      : out  std_logic;
	abort_07_flag         : out  std_logic
);
end rcvparam_store ;


architecture beha of rcvparam_store is
signal rcv_dur      : std_logic := '0';
signal pack_cnt_pre : std_logic_vector(2 downto 0):=(others=>'0');
signal submit_en    : std_logic := '0';
signal frmcc_hit      : std_logic := '0';
signal frm_type     : std_logic_vector(7 downto 0);
signal frm07_hit  : std_logic;
signal wr_point     : std_logic_vector(1 downto 0);
signal rd_point     : std_logic_vector(1 downto 0);

signal   dpram_wren        : std_logic ;
signal   dpram_waddr       : std_logic_vector(11 downto 0);
signal   dpram_wdata       : std_logic_vector(7  downto 0);
signal   dpram_raddr       : std_logic_vector(11 downto 0);
signal   dpram_q           : std_logic_vector(7  downto 0);
signal   p_Frame_en_d      :  std_logic ;
signal   p_Wren_d          :  std_logic ;
signal   p_Data_d          :  std_logic_vector(7 downto 0);
signal   p_Addr_d          :  std_logic_vector(10 downto 0); 

signal   p_Frame_en_buf      :  std_logic_vector(6 downto 0) ;
signal   p_Wren_buf          :  std_logic_vector(6 downto 0) ;
signal   p_Data_buf          :  std_logic_vector(7*8-1 downto 0);
signal   p_Addr_buf          :  std_logic_vector(7*11-1 downto 0); 

component param_ram4096x8_buf is 
 port (
        data      : in  std_logic_vector(7 downto 0)  := (others => 'X'); -- datain
        q         : out std_logic_vector(7 downto 0);                     -- dataout
        wraddress : in  std_logic_vector(11 downto 0) := (others => 'X'); -- wraddress
        rdaddress : in  std_logic_vector(11 downto 0) := (others => 'X'); -- rdaddress
        wren      : in  std_logic                     := 'X';             -- wren
        clock     : in  std_logic                     := 'X'              -- clk
    );
end COMPONENT  ;

signal frm_len0      : std_logic_vector(11 downto 0);
signal frm_len1      : std_logic_vector(11 downto 0);
signal data_len      : std_logic_vector(11 downto 0);
signal shut_hit       : STD_LOGIC := '0';
signal frameCC_07_en  : STD_LOGIC := '0';
signal abort_07_flag_buf : std_logic_vector(1 downto 0);
signal abort_arrive      : std_logic;


begin
   
abort_detect_rcv  <=  abort_arrive   ;
    process(nRST,clk)
    begin 
        if nRST ='0' then
            p_Frame_en_d   <= '0';  
            p_Wren_d       <= '0';    
        elsif rising_edge(clk) then
            p_Frame_en_buf <=     p_Frame_en_buf(5 downto 0)&p_Frame_en_i    ;
            p_Wren_buf     <=     p_Wren_buf(5 downto 0)&p_Wren_i        ;
            p_Data_buf     <=     p_Data_buf(6*8-1 downto 0)&p_Data_i        ;
            p_Addr_buf     <=     p_Addr_buf(6*11-1 downto 0)&p_Addr_i        ; 		
			
		
            p_Frame_en_d   <=     p_Frame_en_buf(6)    ;
            p_Wren_d       <=     p_Wren_buf(6)        ;
            p_Data_d       <=     p_Data_buf(7*8-1 downto 6*8)        ;
            p_Addr_d       <=     p_Addr_buf(7*11-1 downto 6*11)         ; 
        end if;
    end process;
     
     dpram_raddr <= rd_point(0) &rd_addr;----2048 ping-pong here ;; 
     rd_q        <= dpram_q ;
     
     ---------------------------------     
    process(nRST,clk)
    begin 
        if nRST ='0' then
            frmcc_hit  <= '0';
			frm07_hit  <= '0';
			abort_arrive <= '0';
        elsif rising_edge(clk) then 
            if p_Frame_en_i = '1' then  
                if  p_Wren_i = '1' and p_Addr_i = 0 then                   
					if p_Data_i = FT_FORWARD_PARAM  then ----or p_Data_i = FT_RT_SHUTTER then 
                        frmcc_hit <= '1';
                    else 
                        frmcc_hit <= '0';
                    end if;  
				elsif p_Wren_i = '1' and p_Addr_i = 7 then
					if p_Data_i = RFT_DETECT_RCV then   ---- frame 07
						frm07_hit <= '1';
					else
						frm07_hit <= '0';
					end if;
                end if; 

            end if;  


            if p_Frame_en_i = '1' then  
                if  p_Wren_i = '1' and p_Addr_i = 0 then 
					if p_Data_i = FR_ABORT_DETECT_RCV  then ----or p_Data_i = FT_RT_SHUTTER then 
                        abort_arrive <= '1';
                    else 
                        abort_arrive <= '0';
                    end if;  
				else
					abort_arrive <= '0';
					
                end if; 
			else
				abort_arrive <= '0';
            end if;  

			
        end if;     
    end process;  




    process(nRST,clk)
    begin 
        if nRST = '0' then
            rd_len <= (others=>'0');  
			abort_07_flag_buf	<= (others=>'0');  		
        elsif rising_edge(clk) then 
             --if rd_pre = '1' then 
            if rd_point(0) = '0' then 
                rd_len <= frm_len0(10 downto 0);
            else 
                rd_len <= frm_len1(10 downto 0);
            end if;
			
            if rd_point(0) = '0' then 
                abort_07_flag <= abort_07_flag_buf(0);
            else 
                abort_07_flag <= abort_07_flag_buf(1);
            end if;			
			
			if rd_done = '1' then
				if rd_point(0)='0' then
					abort_07_flag_buf(0) <= '0';
				else
					abort_07_flag_buf(1) <= '0';
				end if;
			elsif abort_arrive = '1' then
				if rcv_dur = '1' or submit_en = '1' then ---
					if wr_point(0)='0' then
						abort_07_flag_buf(0) <= '1';	
					else
						abort_07_flag_buf(1) <= '1';	
					end if;
				else
					if wr_point(0)='0' then
						abort_07_flag_buf(1) <= '1';	
					else
						abort_07_flag_buf(0) <= '1';	
					end if;
				end if;
			
			end if;	
			
			
        end if;
    end process;             
     
    process(nRST,clk)
    begin 
        if nRST = '0' then
            dpram_wren <= '0';
            dpram_waddr <= (others=>'0');
            rcv_dur   <= '0';  
            submit_en <= '0';
            data_len  <= (others=>'0');             
        elsif rising_edge(clk) then  
            rcv_dur   <= '0';  
            submit_en <= '0'; 
                
            dpram_wren   <= '0';   
            dpram_waddr  <= wr_point(0)&p_Addr_d;
            dpram_wdata  <= p_Data_d;
            if DET_RCV_MAN_EN = 1 and p_Frame_en_d = '1' and frmcc_hit = '1' and frm07_hit = '1' then 
                dpram_wren <= p_Wren_d; 
                rcv_dur  <= '1';
                if p_Wren_d = '1' then 
                   data_len <= data_len + 1;
                end if;
			elsif DET_RCV_MAN_EN = 0 and p_Frame_en_d = '1' and frmcc_hit = '1' and frm07_hit = '0' then 
                dpram_wren <= p_Wren_d; 
                rcv_dur  <= '1';
                if p_Wren_d = '1' then 
                   data_len <= data_len + 1;
                end if;			
            else 
               data_len   <= (others=>'0');
               dpram_wren <= '0'; 
               rcv_dur   <= '0';
                if rcv_dur = '1' then 
                    if wr_point(0) = '0' then 
						frm_len0 <= data_len ;  ---fifo 
                    else 
						frm_len1 <= data_len;
                    end if;
                end if;
                if rcv_dur = '1' then --submit  
                    submit_en <= '1';  --one packet are submit 
                else  
                    submit_en <= '0';
                end if;
            end if;
        end if;
    end process;
    
    rd_empty <= '1' when pack_cnt_pre = 0 else '0';
    
    process(nRST,clk)
    begin 
        if nRST = '0' then
            pack_cnt_pre <= (others=>'0');
            wr_point     <= (others=>'0');
            rd_point     <= (others=>'0');             
        elsif rising_edge(clk) then 
           
            if submit_en = '1' and rd_done = '1' then 
                pack_cnt_pre <= pack_cnt_pre ;
                wr_point <= wr_point + 1 ;
                rd_point <= rd_point + 1 ;
            elsif submit_en = '1' then 
                if pack_cnt_pre < 2 then --to avoid overflow  
                    pack_cnt_pre <= pack_cnt_pre + 1 ;
                    wr_point     <= wr_point +  1;
                end if;
            elsif rd_done = '1' then 
                if pack_cnt_pre /= 0 then 
                   pack_cnt_pre <= pack_cnt_pre - 1 ;
                   rd_point     <= rd_point + 1;
                end if;
           end if;
        end if;
   end process;
   
   
   ram_i: param_ram4096x8_buf  
   port map ( 
        
        data      => dpram_wdata , -- datain
        q         => dpram_q    ,                    -- dataout
        wraddress => dpram_waddr , -- wraddress
        rdaddress => dpram_raddr , -- rdaddress
        wren      => dpram_wren  ,           -- wren
        clock     => clk              -- clk
    );
 



end beha;