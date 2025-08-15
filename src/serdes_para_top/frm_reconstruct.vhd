--#######################################################################
--
--  LOGIC CORE:          frm_reconstruct
--  MODULE NAME:         frm_reconstruct()
--  Engineer: Pukeur
--  COMPANY:
--  REVisION HisTORY:
--
--  Revision 0.1  09/12/2023    Description: Z8/Z8T RJ45x20 .
--
--  FUNCTIONAL DESCRIPTION:
--
--  this module is for Assembling frames that need to be downstream to the network port
--
--  Copyright (C)   Shenzhen ColorLight Tech. inc.
--
--#######################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.PCK_CRC32_D8.all;
entity frm_reconstruct is
port(
------------------------- cmdfifoempty---------------------------------------
    rx_cmd_fifo_empty      : in   std_logic;
------------------------- dpram---------------------------------------
    dpram_rdaddr           : out  std_logic_vector(11  downto 0);     
    dpram_rddata           : in   std_logic_vector(7   downto 0);                    
-------------------------- fifo---------------------------------------
    fifo_rden              : out  std_logic;
    fifo_rddata            : in   std_logic_vector(49 downto 0);  
-----------------------------------------------------------------
    output_clk_nrst        : in   std_logic;
    output_clk             : in   std_logic; 
	frame_ss               : out  std_logic;                    
    rx_data_vld            : out  std_logic;                    
    rx_data                : out  std_logic_vector(7 downto 0);
	
	clr_serdesinfo         :in  std_logic;
    err_crc_num_out        :out std_logic_vector(15  downto 0)
	
);
end entity;


architecture behav of frm_reconstruct is

-------------------------------------------------------------------------------------------------------------------------------------------------------

--
type state is(                                                                                                                                    
    idle,                                                                                                                                                
    process_uart_control_frm        

);                                                                                                                                                                 
signal pstate   : state:= idle;                                                                                                                                    

signal cmdfifo_req    : std_logic;   
signal rxcmdfifo_ack  : std_logic;  
 

signal rd_point    : std_logic_vector(1   downto 0);
signal frm_len     : std_logic_vector(15  downto 0);    
signal frm_len_lock     : std_logic_vector(15  downto 0);    
signal CRC_result  : std_logic_vector(31  downto 0);
signal rx_cnt      : std_logic_vector(2   downto 0);
signal rd_SU_CNT   : std_logic_vector(10  downto 0);

signal rx_cmd_fifo_busy  : std_logic; 
signal frame_ss_buf      : std_logic; 



signal rx_data_vld_buf      : std_logic; 
signal crc_en               : std_logic; 
signal crc_en_dff           : std_logic; 
signal forwardcrc_neg_dff1  : std_logic; 
signal forwardcrc_neg_dff2  : std_logic; 
signal forwardcrc_neg_dff3  : std_logic; 
signal forwardcrc_neg_dff4  : std_logic; 
signal forwardcrc_neg       : std_logic; 


signal forwardcrc_buf       : std_logic_vector(31  downto 0);
signal forwardcrc_buf_not   : std_logic_vector(31  downto 0);

signal err_crc_num          : std_logic_vector(15  downto 0);

signal wait_cnt             : std_logic_vector(10 downto 0):=(others=>'0');



--==================================================================================================================================================================================================================  
begin                                                                                                                                                                                          
--==================================================================================================================================================================================================================








process(output_clk_nrst,output_clk)
begin
    if output_clk_nrst = '0' then
        cmdfifo_req       <= '0';
        fifo_rden         <= '0';            
        rx_cnt            <= (others=>'0'); --
        rx_cmd_fifo_busy  <= '0';           --
		rd_point          <= (others=>'0'); 
		frm_len           <= (others=>'0'); 
		CRC_result        <= (others=>'0'); 
		wait_cnt         <= (others=>'0'); 
		
    elsif rising_edge(output_clk) then
        if wait_cnt(10) = '0' then 
            wait_cnt <= wait_cnt + 1;
        end if;
		--CMDFIFO
        if wait_cnt(10) = '0' then 
            cmdfifo_req      <= '0';
            fifo_rden        <= '0';
            rx_cnt           <= (others=>'0');
            rx_cmd_fifo_busy <= '0';
        elsif rx_cmd_fifo_busy = '1' then
		
            fifo_rden <= '0';
            if rx_cnt(0)='1' then  --FIFO
                rx_cnt           <= (others=>'0');
                rx_cmd_fifo_busy <= '0';
                cmdfifo_req      <= '1';

                rd_point         <= fifo_rddata(49 downto 48);  --FIFO
                frm_len          <= fifo_rddata(47 downto 32);  --FIFO  
                CRC_result       <= fifo_rddata(31 downto 0 );  --FIFO  
            else
                rx_cnt <= rx_cnt+1;
            end if;
			
		--	
        elsif cmdfifo_req = '1' then

            if rxcmdfifo_ack = '1' then
                cmdfifo_req  <= '0';
				frm_len_lock <= frm_len;
            end if;
            rx_cnt     <= (others=>'0');
            fifo_rden  <= '0';
			
			
		--fifo
        elsif rx_cmd_fifo_empty = '0' then       
            cmdfifo_req      <= '0';             
            fifo_rden        <= '1';             
            rx_cmd_fifo_busy <= '1';             
            rx_cnt           <= (others=>'0');
			
        else
            cmdfifo_req      <= '0';
            fifo_rden        <= '0';
            rx_cmd_fifo_busy <= '0';
            rx_cnt           <= (others=>'0');
        end if;
    end if;
end process;





process(output_clk_nrst,output_clk)
begin
	if output_clk_nrst = '0' then
		rxcmdfifo_ack   <= '0';  
		pstate          <= idle; 
		rd_SU_CNT       <= (others=>'0');
		frame_ss_buf    <= '0';
        rx_data_vld_buf <= '0'; 
        crc_en          <= '0'; 
		dpram_rdaddr    <= (others=>'0');
		frame_ss        <= '0';
		rx_data_vld     <= '0';
		rx_data         <= (others=>'0');
	elsif rising_edge(output_clk) then
    
        rxcmdfifo_ack   <= '0';  
        
        if wait_cnt(10) = '0' then 
           rxcmdfifo_ack   <= '0';  
		   pstate          <= idle; 
		   frame_ss        <= '0';	
		   rx_data_vld     <= '0';
           frame_ss_buf    <= '0';
           rx_data_vld_buf <= '0'; 
           rd_SU_CNT       <= (others=>'0');
        else
		case (pstate) is
-------------------------------------------------------idle---------------------------------------------------
			when idle =>
				if cmdfifo_req = '1' then
					rxcmdfifo_ack   <= '1';
					pstate          <= process_uart_control_frm;
				else
					pstate          <= idle;                     
					rxcmdfifo_ack   <= '0';                         
				end if;     
				frame_ss        <= '0';	
				rx_data_vld     <= '0';
                frame_ss_buf    <= '0';
                rx_data_vld_buf <= '0';
                crc_en          <= '0';
                rd_SU_CNT       <= (others=>'0');
---------------------------------------------process_uart_control_frm---------------------------------------------------
			when process_uart_control_frm =>
			
				if rd_SU_CNT >= frm_len_lock+3-1 then						-- rd_SU_CNT -> dpram_rdaddr latency 1; dpram_rdaddr -> dpram_rddata latency 2;
					pstate          <= idle;
					rd_SU_CNT       <= (others=>'0');
					frame_ss_buf    <= '0';
                    rx_data_vld_buf <= '0';  
					crc_en          <= '0';
					frame_ss        <= '0';
					
				else
					pstate       <= process_uart_control_frm;
					rd_SU_CNT    <= rd_SU_CNT+1;
					dpram_rdaddr <= rd_point(0)&rd_SU_CNT; 
					
					if rd_SU_CNT >= 2 then
						frame_ss_buf    <= '1';
						rx_data_vld_buf <= '1';  
						crc_en          <= '1';  
					end if;
					
				end if;  


				if rd_SU_CNT >= 3 then
					frame_ss     <=   frame_ss_buf   ;
					rx_data_vld  <=   rx_data_vld_buf;
					rx_data      <=   dpram_rddata   ;
				end if;

			when others => pstate <= idle;
		end case;
       end if;
	end if;
end process;






--CRC 
process(output_clk_nrst,output_clk)
begin
    if output_clk_nrst = '0' then
        forwardcrc_buf <= (others => '1' );
    elsif rising_edge(output_clk) then
        if forwardcrc_neg_dff4 = '1' then
            forwardcrc_buf <= (others => '1' );
        elsif( crc_en = '1')then
            forwardcrc_buf <= nextCRC32_D8(dpram_rddata,forwardcrc_buf);   
        end if;
    end if;
end process;


process(forwardcrc_buf)
begin
    for i in 0 to 3 loop
      for j in 0 to 7 loop
         forwardcrc_buf_not((3-i)*8+ j) <= not forwardcrc_buf(i*8+7-j);
      end loop;
    end loop;
end process;
	



forwardcrc_neg <= '1' when ( crc_en = '0' and crc_en_dff = '1' ) else '0' ; --This is for detecting the falling edge of crc_en


--
process(output_clk_nrst,output_clk)
begin
    if output_clk_nrst = '0' then
        crc_en_dff <= '0' ;
        forwardcrc_neg_dff1 <= '0';
        forwardcrc_neg_dff2 <= '0';
        forwardcrc_neg_dff3 <= '0';
        forwardcrc_neg_dff4 <= '0';

    elsif rising_edge(output_clk) then
        crc_en_dff          <= crc_en ;   
        forwardcrc_neg_dff1 <= forwardcrc_neg;       --Falling edge capture, used to locate the output of CRC data.
        forwardcrc_neg_dff2 <= forwardcrc_neg_dff1;  --Falling edge capture, used to locate the output of CRC data.
        forwardcrc_neg_dff3 <= forwardcrc_neg_dff2;  --Falling edge capture, used to locate the output of CRC data.
        forwardcrc_neg_dff4 <= forwardcrc_neg_dff3;  --Falling edge capture, used to locate the output of CRC data.
     end if;
end process;


process(output_clk_nrst,output_clk)
begin
    if output_clk_nrst = '0' then
        err_crc_num <= (others=>'0');
    elsif rising_edge(output_clk) then
	
	
		if clr_serdesinfo = '1' then
			err_crc_num <= (others=>'0');
		elsif  forwardcrc_neg = '1' and (forwardcrc_buf_not = CRC_result) then	
			err_crc_num <= err_crc_num;
		elsif forwardcrc_neg = '1' then
			err_crc_num <= err_crc_num+1;
		end if;
		
		err_crc_num_out <= err_crc_num;

	end if;
end process;



    
end behav;  


   


