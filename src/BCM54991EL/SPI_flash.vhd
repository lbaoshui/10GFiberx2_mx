--#######################################################################
--
--  LOGIC CORE:          spi_flash							
--  MODULE NAME:         spi_flash()
--  COMPANY:             
--                       		
--
--  REVISION HISTOY:  
--
--  Revision 0.1  11/25/2008	Description: Initial .
--
--  FUNCTIONAL DESCRIPTION:
--
--
--  Copyright (C)   
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity spi_flash is
port(   
    nRST        		: in std_logic;
    SYSCLK      		: in STD_LOGIC;   
    
    cmd_idle 			: out std_logic; 
    cmd_en   			: in std_logic; 
    cmd      			: in std_logic_vector(2 downto 0); -----1 downto 0); 
    
    cmd_timeout			: out std_logic;
    cmd_finished		: out std_logic;
    
    addr        		: in std_logic_vector(23 downto 0);
    rdnum       		: in std_logic_vector(12 downto 0);
    data_empty  		: out std_logic;
    data_en     		: in std_logic;
    host2flash  		: in std_logic_vector(7 downto 0);
    data_valid  		: out std_logic;
    flash2host  		: out std_logic_vector(7 downto 0); 
	 
	prog_cs				: out std_logic;
	prog_dclk			: out std_logic;
	prog_mosi			: out std_logic;
	prog_miso			: in  std_logic;
    
    spi_ready 			: out std_logic
   ); 
END spi_flash;
	
architecture behav of spi_flash is
 
type state is (idle,block64K_erase,page_wr,page_rd,delay_wait,delay_wait1,
  read_statusreg,
  write_statusreg,
  turna_statusreg
  );
signal pstate: state := idle;

signal div_cnt			: std_logic_vector(2 downto 0):=(others => '0');
signal bit_cnt			: std_logic_vector(2 downto 0):=(others => '0');
 
signal polling_cnt		: std_logic_vector(24 downto 0):=(others => '0');  
signal polling_first	: std_logic := '0';  
signal delay_wait1_cnt	: std_logic_vector(15 downto 0):=(others => '0'); 

signal rdpage_dec_cnt	: std_logic_vector(12 downto 0):=(others => '0'); 
signal wrpage_inc_cnt	: std_logic_vector(8 downto 0):=(others => '0'); 
signal rdpage_inc_cnt	: std_logic_vector(3 downto 0):=(others => '0'); 
signal reg_cnt			: std_logic_vector(5 downto 0):= (others => '0');
signal erase_cnt		: std_logic_vector(3 downto 0):= (others => '0');

signal local_addr		: std_logic_vector(23 downto 0):=(others => '0'); 
signal cmd_buf			: std_logic_vector(7 downto 0):=(others => '0');  

signal wr_buf			: std_logic_vector(7 downto 0):=(others => '0');
signal rd_buf			: std_logic_vector(7 downto 0):=(others => '0'); 

signal rdID_cnt			: std_logic_vector(9 downto 0); 

signal UID_serial		: std_logic_vector(7 downto 0);

signal UID_cnt			: std_logic_vector(2 downto 0);
signal cur_cmd			: std_logic_vector(2 downto 0);

signal status_data		: std_logic_vector(7 downto 0):=(others=>'0');
signal prog0_cs			: std_logic;
signal prog0_dclk		: std_logic;
signal prog0_mosi		: std_logic;

signal rdnum_plus6 		: std_logic_vector(12 downto 0);
signal rd_done     		: std_logic;
signal div_cnt2en     	: std_logic;
signal div_cnt3en     	: std_logic;
signal div_cnt5en     	: std_logic;
signal div_cnt7en     	: std_logic;

begin

rdnum_plus6  <= rdnum + 6;
process(nRST,SYSCLK)
begin
	if nRST = '0' then
		cmd_idle <= '1';      
		prog_cs <= '1'; 
		prog_dclk <= '0';                  
		div_cnt <= (others => '0');
		bit_cnt <= (others => '0');
		polling_cnt <= (others => '0');
		polling_first <= '0';
		rdpage_dec_cnt <= (others => '0');
		rdpage_inc_cnt <= (others => '0');
		wrpage_inc_cnt <= (others => '0');
		reg_cnt <= (others => '0');
		erase_cnt <= (others => '0');       
		data_empty <= '0'; 
		data_valid <= '0';           
		cmd_timeout <= '0';
		cmd_finished<= '0';     
        pstate <= idle;
        spi_ready <= '0';
        prog0_cs <= '1';
        prog0_dclk <= '0';
        prog0_mosi <= '0';
        rd_done <= '0';
	elsif rising_edge(SYSCLK) then
           
		case pstate is			 
				
			when idle =>
				spi_ready <= '1';
				cmd_idle <= '1';
				div_cnt <= (others => '1');              
				bit_cnt <= (others => '1');             
				polling_cnt <= (others => '0');
				rdpage_inc_cnt <= (others => '0');  
				wrpage_inc_cnt <= (others => '0');  
				erase_cnt <= (others => '0');  
				reg_cnt <= (others => '0');  
				polling_first <= '0';
				delay_wait1_cnt <= (others => '0');                                        
				data_empty <= '0';
				data_valid <= '0';              
				cmd_timeout <= '0';
				cmd_finished<= '0';                       
				local_addr <= addr; 
				cur_cmd <= cmd;
				prog0_cs    <= '1';
				prog0_dclk  <= '0';
				prog0_mosi  <= '0';
				prog_dclk <= '0';
				rdpage_dec_cnt <= rdnum + 5 ;
				rd_done    <= '0';
				if cmd_en = '1' then  
					prog_cs <= '0'; 
					prog0_cs <= '0';              
					case cmd is
                    when "001" =>  
                       cmd_buf  <= "00000110";
                       pstate <= block64K_erase;
                    when "010" => 
                       pstate <= page_wr;
                       cmd_buf <= "00000110";
                    when "011" =>  
                       pstate <= page_rd;  
                       cmd_buf <= "00001011"; ---page read
                    when "100" => ---4k erase
                        cmd_buf    <= "00000110"; ----0x6 write enable
                        pstate <= block64K_erase; 
                    when "101" => --write status register: enable pretection, ---protect all
                        cmd_buf    <= "00000110"; ----0x6 write enable
                        pstate <= write_statusreg;------write_statusreg;  
                        status_data <= host2flash ;
                    when "110" => ---read status register
                        cmd_buf <= "00000101"; ---first read status reg, then write status reg                   
                        pstate <= read_statusreg;
                        status_data <= host2flash ;                         
                    when others =>  pstate <= idle;  ---null;   
                  end case;          
				else
                   pstate <= idle; 
                   prog_cs <= '1';                               
				end if;  
         
			when read_statusreg => ---first read status reg
                cmd_idle <= '0';
				if div_cnt7en = '1' then
					div_cnt <= (others => '0');
					bit_cnt <= bit_cnt - '1';
					if bit_cnt = "000" then                 
						reg_cnt <= reg_cnt + '1';
					end if;                   
				else
					div_cnt <= div_cnt + '1';
				end if;                           
				if reg_cnt(5 downto 0) = 0 then -----and rdpage_cnt < 5 then ---fast read
					pstate <= read_statusreg;  
					prog_cs <= '0';
				elsif reg_cnt(5 downto 0) = 1 then -----and wrpage_cnt < 5 then ---fast read
					pstate <= read_statusreg;                    
					prog_cs <= '0';
					prog_mosi <= cmd_buf(conv_integer(bit_cnt)); 
					if div_cnt3en = '1' then
						prog_dclk <= '1';                    
					elsif div_cnt7en = '1' then
						prog_dclk <= '0';
					end if;
				elsif reg_cnt(5 downto 0) = 2 then ------ rdnum + 6 then
					if div_cnt3en = '1' then
						prog_dclk <= '1';                    
					elsif div_cnt7en = '1' then
						prog_dclk <= '0';
					end if;
						pstate <= read_statusreg; 
						if div_cnt = 6 then
							rd_buf(conv_integer(bit_cnt)) <= prog_miso;
						elsif div_cnt3en = '1' then
							if bit_cnt = 0 then
							else     
							end if;
						end if;  
				elsif  reg_cnt(5 downto 0) = 3  then ----delay a while 
                    pstate <= read_statusreg; 
				elsif reg_cnt(5) = '0' then ----delay a while 
					prog_dclk <= '0'; 
					pstate <= read_statusreg; 
					prog_cs <= '1';
				else
					prog_dclk <= '0'; 
					cmd_buf    <= "00000110"; ----0x6 write enable "local_addr(23 downto 16);
					prog_cs <= '1';
					status_data(7) <= rd_buf(7);
					status_data(6) <= rd_buf(6);
					status_data(1) <= rd_buf(1);
					status_data(0) <= rd_buf(0);
					if status_data(5 downto 2) = rd_buf(5 downto 2) then ---20140829 wangac
						cmd_finished<= '1'; 
						pstate <= delay_wait1 ;
					else
						pstate  <=turna_statusreg; ----20151112  write_statusreg; ------idle;                       
					end if;
				end if;      

               
         
			when turna_statusreg  =>
                cmd_idle   <= '0';
                div_cnt    <= (others=>'0')  ;
                bit_cnt    <= (others=>'1') ;
                reg_cnt <= (others=>'0') ;
                rd_done    <= '0';
                pstate     <= write_statusreg;                 
              
			when write_statusreg =>
                cmd_idle <= '0';
				if div_cnt7en ='1'then
					div_cnt <= (others => '0');
					bit_cnt <= bit_cnt - '1';
					if bit_cnt = "000" then
						reg_cnt <= reg_cnt + '1';
					end if;                   
				else
					div_cnt <= div_cnt + '1';
				end if;                
				if reg_cnt(5 downto 0) = 0 then ----write enable 
					pstate <= write_statusreg; 
					prog_cs <= '0';
				elsif reg_cnt = 1 then ----write enable 
					pstate <= write_statusreg; 
					prog_cs <= '0';
					if div_cnt3en = '1' then
						prog_dclk <= '1';                    
					elsif div_cnt7en = '1' then
						prog_dclk <= '0';
					end if;  					
					prog_mosi <= cmd_buf(conv_integer(bit_cnt)); 
				elsif reg_cnt(5 downto 0) >= 2 and reg_cnt(5 downto 0)<= 5 then
					prog_cs <= '1';
					prog_dclk <= '0';                     
					pstate <= write_statusreg; 
					cmd_buf <="00000001"; ----write status register next_cmd; -----"11011000"; ---D8 block erase 64k
				elsif reg_cnt(5 downto 0) >= 6 and reg_cnt(5 downto 0) <= 7  then 
					pstate <= write_statusreg; 
					prog_cs <= '0';
					if div_cnt3en = '1' then
						prog_dclk <= '1';                    
					elsif div_cnt7en = '1' then
						prog_dclk <= '0';
					end if;                       
					if bit_cnt = 0 and div_cnt7en = '1' then                      
						cmd_buf <= status_data; -----host2flash   ; ---protect all 
					end if; 
					prog_mosi <= cmd_buf(conv_integer(bit_cnt)); 					
				elsif reg_cnt(5 downto 0) =8 then 
					pstate <= write_statusreg;                    
				elsif reg_cnt(5 downto 0) >= 9  and reg_cnt(5 downto 0) < 14 then
					pstate <= write_statusreg; 
					prog_cs <= '1';
					prog_dclk <= '0';  								
				else 
					prog_cs <= '0';
					pstate <= delay_wait; 
					cmd_buf <= "00000101";   ----0x05 read status register , used at present ;
				end if;  
				polling_cnt <= (others => '0');
				polling_first <= '0';
				
           when block64K_erase =>  
				cmd_idle <= '0';   
				if div_cnt5en = '1' then
					div_cnt <= (others => '0');
					bit_cnt <= bit_cnt - '1';
					if bit_cnt = "000" then
						erase_cnt <= erase_cnt + '1';
					end if;                   
				else
					div_cnt <= div_cnt + '1';
				end if;                				
				if erase_cnt(3 downto 0) = 0 then
					pstate <= block64K_erase; 
					prog_cs <= '0';
					if div_cnt2en = '1' then
						prog_dclk <= '1';                    
					elsif div_cnt5en = '1' then
						prog_dclk <= '0';
					end if;  					
				prog_mosi <= cmd_buf(conv_integer(bit_cnt)); 					
				elsif erase_cnt(3 downto 0) = 1 then
					prog_cs <= '1';
					prog_dclk <= '0';                     
					pstate <= block64K_erase; 
					if cur_cmd(2) = '0' then ---64K erase
						cmd_buf <= "11011000"; -----"11011000"; ---D8 block erase 64k
					else  --4k erase
						cmd_buf <= "00100000"; --0x20 --next_cmd; 
					end if;
				elsif erase_cnt(3 downto 0) >= 2 and erase_cnt(3 downto 0) < 6 then
					pstate <= block64K_erase; 
					prog_cs <= '0';
					if div_cnt2en = '1' then
						prog_dclk <= '1';                    
					elsif div_cnt5en = '1' then
						prog_dclk <= '0';
					end if; 
					if bit_cnt = 0 and div_cnt5en = '1' then
						cmd_buf <= local_addr(23 downto 16);
						local_addr <= local_addr(15 downto 0)&(X"00");
					end if; 					
					prog_mosi <= cmd_buf(conv_integer(bit_cnt));                				
				elsif erase_cnt(3 downto 0) = 6 then
					pstate <= block64K_erase; 
					prog_cs <= '1';
					prog_dclk <= '0';  
				elsif erase_cnt(3 downto 0) = 7 then 
					pstate <= block64K_erase;                   
					prog_cs <= '1';      
				elsif erase_cnt(3 downto 0) = 8 then 
					pstate <= block64K_erase;                   
					prog_cs <= '0';       
				else
					pstate <= delay_wait; 
					cmd_buf <= "00000101";   ----0x05 read status register , used at present ;
				end if; 				
				polling_cnt  <= (others => '0');
				polling_first <= '0';

            when delay_wait =>
				if div_cnt5en = '1' then
					div_cnt <= (others => '0');
					bit_cnt <= bit_cnt - '1';
					if bit_cnt = "000" then
						polling_cnt <= polling_cnt + '1';
						polling_first <= '1';
					end if;                   
				else
					div_cnt <= div_cnt + '1';
				end if;                 
					if div_cnt2en = '1' then
						prog_dclk <= '1';                    
					elsif div_cnt5en = '1' then
						prog_dclk <= '0';
					end if;   
					if polling_first ='0' then                    
					pstate <= delay_wait; 
					prog_cs <= '0';
					prog_mosi <= cmd_buf(conv_integer(bit_cnt));				
				elsif polling_cnt(24)='0' then ----- < X"FFFFFF" then
						if bit_cnt = 0 and div_cnt2en = '1' then
						if prog_miso = '0' then 
							pstate  <= delay_wait1;
							cmd_finished<= '1';                             
						else
							pstate <= delay_wait;  
						end if;
						else
							pstate <= delay_wait; 
						end if; 
				else
					pstate  <= idle;   
					cmd_timeout <= '1';
				end if;  
			
			when delay_wait1 => 
				prog_cs <= '1';
				prog_dclk <= '0';               
				delay_wait1_cnt <= delay_wait1_cnt + '1';					
				cmd_timeout <= '0';
				cmd_finished<= '0'; 			      
				if delay_wait1_cnt(10) = '1' then -------- = 1024 then
					pstate  <= idle;    
				else
					pstate  <= delay_wait1;
				end if;           	
				
			when page_wr =>   
				prog_cs   <= prog0_cs;
				prog_dclk <= prog0_dclk ;
				prog_mosi <= prog0_mosi ;
				cmd_idle <= '0';
				if div_cnt5en = '1' then
					div_cnt <= (others => '0');
					bit_cnt <= bit_cnt - '1';
					if bit_cnt = "000" then
						wrpage_inc_cnt <= wrpage_inc_cnt + '1';
					end if;                   
				else
					div_cnt <= div_cnt + '1';
				end if;  
				
				if wrpage_inc_cnt(8 downto 0) = 0 then
					pstate <= page_wr; 
					prog0_cs <= '0';
					if div_cnt2en = '1' then
						prog0_dclk <= '1';                    
					elsif div_cnt5en = '1' then
						prog0_dclk <= '0';
					end if;  					
					prog0_mosi <= cmd_buf(conv_integer(bit_cnt)); 					
				elsif wrpage_inc_cnt(8 downto 0)  < 4 then
					prog0_cs <= '1';
					prog0_dclk <= '0';                     
					pstate <= page_wr; 
					cmd_buf <= "00000010"; 
				elsif wrpage_inc_cnt(8 downto 0) < 8 then   
					if div_cnt2en = '1' then
						prog0_dclk <= '1';                    
					elsif div_cnt5en = '1' then
						prog0_dclk <= '0';
					end if;                				
					pstate <= page_wr; 					
					prog0_cs <= '0';
					prog0_mosi <= cmd_buf(conv_integer(bit_cnt)); 
					if bit_cnt = 0 and div_cnt5en = '1' then
						cmd_buf <= local_addr(23 downto 16);
						local_addr <= local_addr(15 downto 0)&(X"00");
					end if;					
					if wrpage_inc_cnt(8 downto 0) = 4 and bit_cnt = 0 and div_cnt5en = '1' then
							data_empty <= '1';
					elsif data_en = '1' then
						data_empty <= '0';
						wr_buf <= host2flash;
					end if;  					
				elsif wrpage_inc_cnt(8 downto 0) < 264 then
					if div_cnt2en = '1' then
						prog0_dclk <= '1';                    
					elsif div_cnt5en = '1' then
						prog0_dclk <= '0';
					end if;  									
					pstate <= page_wr;                   					
					prog0_cs <= '0';
					prog0_mosi <= wr_buf(conv_integer(bit_cnt)); 	
					if bit_cnt = 0 and div_cnt > 1 then
						if data_en = '1' then
							wr_buf <= host2flash;
						end if;  
						data_empty <= '1';
					else
						data_empty <= '0';   
					end if;
				elsif wrpage_inc_cnt(8 downto 0) < 270 then
					pstate <= page_wr; 
					prog0_cs <= '1';
					prog0_dclk <= '0';  
				else                    
					pstate <= delay_wait; 
					prog0_cs <= '0';
					cmd_buf <= "00000101";
				end if; 
				polling_cnt <= (others => '0');  
				polling_first <= '0';

			when page_rd =>  
				cmd_idle <= '0';
				if div_cnt5en = '1' then
					div_cnt <= (others => '0');
					bit_cnt <= bit_cnt - '1';
					if bit_cnt = "000" then                 
						rdpage_inc_cnt <= rdpage_inc_cnt + '1';
						rdpage_dec_cnt <= rdpage_dec_cnt - '1';
						if rdpage_dec_cnt = 1 then 
							rd_done    <= '1'; ---done 20150715 wangac
						end if;
						if rdpage_inc_cnt = 4 then
							polling_first <= '1';
						end if;
					end if;                   
				else
					div_cnt <= div_cnt + '1';
				end if;  

				if div_cnt2en = '1' then
					prog_dclk <= '1';                    
				elsif div_cnt5en = '1' then
					prog_dclk <= '0';
				end if;

				if bit_cnt = 0 and div_cnt5en = '1' then
						cmd_buf <= local_addr(23 downto 16);
						local_addr <= local_addr(15 downto 0)&(X"00");
				end if;  

				if polling_first = '0' then 
					prog_cs <= '0';
					prog_mosi <= cmd_buf(conv_integer(bit_cnt));  
				elsif rd_done ='0' then 
					if div_cnt3en = '1' then
						if bit_cnt = 0 then
							flash2host <= rd_buf;
							data_valid <= '1';
						else     
							data_valid <= '0';
						end if;
						end if; 
				else
					prog_cs <= '1';  ---20140827 wangac
				end if;
				if div_cnt2en = '1' then
					rd_buf(conv_integer(bit_cnt)) <= prog_miso;
				end if;
				if rd_done= '1' then --------20150715 wangac--rdpage_dec_cnt = 0 then                   
					pstate  <= idle;   
				else
					pstate <= page_rd;              
				end if;  				
				
			when others => null;               
		end case;      
	end if;
   
end process;

process(nRST,SYSCLK)
begin
if nRST = '0' then
    div_cnt2en <= '0';
    div_cnt3en <= '0';
    div_cnt7en <= '0';
    div_cnt5en <= '0';
elsif rising_edge(SYSCLK) then
    if div_cnt = 1 then
        div_cnt2en <= '1';
    else
        div_cnt2en <= '0';
    end if;
    
    if div_cnt = 4 then
        div_cnt5en <= '1';
    else
        div_cnt5en <= '0';
    end if;
    
    if div_cnt = 2 then
        div_cnt3en <= '1';
    else
        div_cnt3en <= '0';
    end if;
    
    if div_cnt = 6 then
        div_cnt7en <= '1';
    else
        div_cnt7en <= '0';
    end if;
    
end if;
end process;


end behav;  
