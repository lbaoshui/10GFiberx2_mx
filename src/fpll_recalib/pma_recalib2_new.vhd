
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity pma2_recalib_new is 
generic (
         CH_NUMMAX : integer:= 4 ;
         CH_W      : integer:= 2 ;
         A_W : integer := 12;
         D_W : integer := 32
    );
port 
(
   reset                : in std_logic ;
   clk                  : in std_logic ;
   pll_powerdown_i        : in std_logic ;
   tx_cal_busy      : in std_logic_vector(CH_NUMMAX-1 downto 0) ;
   rx_cal_busy      : in std_logic_vector(CH_NUMMAX-1 downto 0) ;
 --// TX PLL reconfig controller interface
   mgmt_address      :out std_logic_vector(A_W-1 downto 0) ;---output wire [9:0] ,
   mgmt_writedata    :out std_logic_vector(D_W-1 downto 0) ;---output wire [31:0],
   mgmt_readdata     :in  std_logic_vector(D_W -1 downto 0) ;---input  wire [31:0],
   mgmt_write        :out std_logic  ;---output wire       ,
   mgmt_read         :out std_logic  ;---output wire       ,
   mgmt_waitrequest  : in std_logic  ; ----_vector(CH_NUMMAX-1 downto 0)  ;----input  wire       
   cali_done_o       : out std_logic ;
   begin_en          : in std_logic 

  );
end pma2_recalib_new;

architecture beha of pma2_recalib_new is 

signal usr_rcfg_write          : std_logic_vector(0 downto 0)   := (others => '0');
signal usr_rcfg_read           : std_logic_vector(0 downto 0)   := (others => '0');
signal usr_rcfg_address        : std_logic_vector(11 downto 0)  := (others => '0');
signal usr_rcfg_writedata      : std_logic_vector(31 downto 0)  := (others => '0');
signal saved_readdata          : std_logic_vector(31 downto 0)  := (others => '0');


signal dly_cnt                  : std_logic_vector(3 downto 0);
signal status                   : std_logic_vector(3 downto 0);
signal ch_num                   : std_logic_vector(CH_W-1 downto 0);
signal pma_cal_busy             : std_logic;
signal calib_done               : std_logic;
signal clr_i : std_logic;

signal nRST : std_logic;
begin 

   clr_i <= reset;--pll_powerdown_i;
   cali_done_o <= calib_done;
   pma_cal_busy         <= tx_cal_busy     ( conv_integer(ch_num(CH_W-1 downto 0))) ; 

   
mgmt_write     <= usr_rcfg_write(0);         
mgmt_read      <= usr_rcfg_read(0);      
mgmt_address   <= ch_num&usr_rcfg_address(9 downto 0);   
mgmt_writedata <= usr_rcfg_writedata; 


nRST <=  not reset;
process(nRST,clk)
begin
    if nRST = '0' then
        usr_rcfg_write(0) <= '0'; 
        usr_rcfg_read(0) <= '0';           
        usr_rcfg_address <= (others => '0');    
        usr_rcfg_writedata <= (others => '0'); 
        status <= (others => '0'); 
        dly_cnt <= (others => '0'); 
        ch_num <= (others => '0'); 

		calib_done <= '0'; 
    elsif rising_edge(clk) then
        
		if begin_en = '0' then
			calib_done <= '0';
			status <= "0000";
		else
			case conv_integer(status) is
			when 0 =>
				if begin_en = '1'and calib_done = '0' then
					status <= "0001";

				else
					status <= "0000";

				end if;
				usr_rcfg_write(0) <= '0'; 
				usr_rcfg_read(0) <= '0';      
				usr_rcfg_address <= (others => '0');    
				usr_rcfg_writedata <= (others => '0'); 
				dly_cnt <= (others => '0');
				
			when 1 =>
				if usr_rcfg_write(0) = '1' and mgmt_waitrequest = '0' then    
					usr_rcfg_write(0) <= '0'; 
					usr_rcfg_read(0) <= '0';      
					usr_rcfg_address <= (others => '0');    
					usr_rcfg_writedata <= (others => '0'); 
					status <= "0010";
				else
					usr_rcfg_write(0) <= '1';  
					usr_rcfg_read(0) <= '0';              
					usr_rcfg_address <= X"000";    
					usr_rcfg_writedata <= X"00000002"; 
					status <= "0001";
				end if;
				
				
			when 2 =>
				if usr_rcfg_read(0) = '1' and mgmt_waitrequest = '0' then    
					usr_rcfg_write(0) <= '0'; 
					usr_rcfg_read(0) <= '0';      
					usr_rcfg_address <= (others => '0');    
					usr_rcfg_writedata <= (others => '0'); 
					saved_readdata <= mgmt_readdata;
					status <= "0011";
				else
					usr_rcfg_write(0) <= '0';  
					usr_rcfg_read(0) <= '1';              
					usr_rcfg_address <= X"281";    
					usr_rcfg_writedata <= (others => '0'); 
					status <= "0010";
				end if;    
				
				
			when 3 => 
				-- if saved_readdata(2) = '0' then
					-- status <= "0100";
				-- else
					-- status <= "0010";
				-- end if;
				status <= "0100";
			when 4 =>  
				if usr_rcfg_read(0) = '1' and mgmt_waitrequest = '0' then    
					usr_rcfg_write(0) <= '0'; 
					usr_rcfg_read(0) <= '0';      
					usr_rcfg_address <= (others => '0');    
					usr_rcfg_writedata <= (others => '0'); 
					saved_readdata <= mgmt_readdata;
					status <= "0101";
				else
					usr_rcfg_write(0) <= '0';  
					usr_rcfg_read(0) <= '1';              
					usr_rcfg_address <= X"100";    
					usr_rcfg_writedata <= (others => '0'); 
					status <= "0100";
				end if; 
	
			when 5 =>
				if usr_rcfg_write(0) = '1' and mgmt_waitrequest = '0' then    
					usr_rcfg_write(0) <= '0'; 
					usr_rcfg_read(0) <= '0';      
					usr_rcfg_address <= (others => '0');    
					usr_rcfg_writedata <= (others => '0'); 
					status <= "0110";
				else
					usr_rcfg_write(0) <= '1';  
					usr_rcfg_read(0) <= '0';              
					usr_rcfg_address <= X"100";    
					usr_rcfg_writedata <= saved_readdata(31 downto 6)&'1'&saved_readdata(4 downto 0); 
					status <= "0101";
				end if;
	
	
			when 6 =>  
				if usr_rcfg_read(0) = '1' and mgmt_waitrequest = '0' then    
					usr_rcfg_write(0) <= '0'; 
					usr_rcfg_read(0) <= '0';      
					usr_rcfg_address <= (others => '0');    
					usr_rcfg_writedata <= (others => '0'); 
					saved_readdata <= mgmt_readdata;
					status <= "0111";
				else
					usr_rcfg_write(0) <= '0';  
					usr_rcfg_read(0) <= '1';              
					usr_rcfg_address <= X"281";    
					usr_rcfg_writedata <= (others => '0'); 
					status <= "0110";
				end if; 
	
			when 7 =>
				if usr_rcfg_write(0) = '1' and mgmt_waitrequest = '0' then    
					usr_rcfg_write(0) <= '0'; 
					usr_rcfg_read(0) <= '0';      
					usr_rcfg_address <= (others => '0');    
					usr_rcfg_writedata <= (others => '0'); 
					status <= "1000";
				else
					usr_rcfg_write(0) <= '1';  
					usr_rcfg_read(0) <= '0';              
					usr_rcfg_address <= X"281";    
					usr_rcfg_writedata <= saved_readdata(31 downto 5)&'1'&saved_readdata(3 downto 0); 
					status <= "0111";
				end if;    
		
	
			when 8 =>
				if usr_rcfg_write(0) = '1' and mgmt_waitrequest = '0' then    
					usr_rcfg_write(0) <= '0'; 
					usr_rcfg_read(0) <= '0';      
					usr_rcfg_address <= (others => '0');    
					usr_rcfg_writedata <= (others => '0'); 
					status <= "1001";
				else
					usr_rcfg_write(0) <= '1';  
					usr_rcfg_read(0) <= '0';              
					usr_rcfg_address <= X"000";    
					usr_rcfg_writedata <= X"00000001"; 
					status <= "1000";
				end if;
				
			when 9 =>
				if dly_cnt(3) = '0' then
					dly_cnt <= dly_cnt + '1';
					status <= "1001";
				elsif dly_cnt(3) = '1' and pma_cal_busy = '0' then
					status <= "1010";
					dly_cnt <= (others => '0');
					-- ch_num <= ch_num + '1';
					if ch_num = CH_NUMMAX-1 then
						ch_num <=(others=>'0');
					else
						ch_num <= ch_num +1 ;
					end if;    
				else
					status <= "1001";
				end if;
				
			when 10 =>  
				if ch_num = 0  then
					status <= "1011";
					calib_done <= '1';
				else
					status <= "0001";
					calib_done <= '0';
				end if;    
	
			when 11 =>  
				if dly_cnt(3) = '0' then
					dly_cnt <= dly_cnt + '1';
					status <= "1011";
				elsif dly_cnt(3) = '1' then
					status <= "0000";
					dly_cnt <= (others => '0');
				end if;
	
			when others =>
				usr_rcfg_write(0) <= '0'; 
				usr_rcfg_read(0) <= '0';      
				usr_rcfg_address <= (others => '0');    
				usr_rcfg_writedata <= (others => '0'); 
				status <= "0000";    
			end case;
		end if;
        
        
    end if;
end process;  

end beha ;