library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity eth_Man is    
port
(      
   nRST    			: in std_logic;   
   SYSCLK  			: in std_logic; 
   
   PHY_PHYADDR		: in std_logic_vector(4 downto 0);
   PHY_REQ 			: IN std_logic;
   PHY_ACK 			: out std_logic;
   PHY_RDWREN		: in std_logic; -- '0' : read , '1': write
   PHY_WADDREN		: in std_logic; --add for clause 45
   
   PHY_DEVADDR		: IN std_logic_vector(4 downto 0);
   PHY_RDATA		: out std_logic_vector(15 downto 0);
   PHY_RVLD			: out std_logic;   
   PHY_WDATA		: in std_logic_vector(15 downto 0);
   
   PHY_MDC			: out std_logic;
   PHY_MDIn			: in  std_logic;
   PHY_MDOUT		: out std_logic;
   PHY_MDir 		: out std_logic  --'0' : in , '1' : out

);
end eth_Man;

architecture beha of eth_Man is
 
type state is (st_idle, st_preamble, st_turn); ----st_start, st_op, st_phyaddr, st_regaddr, st_wr, st_rd , st_wspace);
signal pstate : state := st_idle;

signal cur_req		: std_logic:='0';
signal cur_addr_req	:std_logic:='0';
signal rdata		: std_logic_vector(15 downto 0);
signal wdata		: std_logic_vector(15 downto 0);
signal addr			: std_logic_vector(9 downto 0);

signal cnt 			:std_logic_vector(7 downto 0);
constant DIV_WIDTH	:integer:=5;
signal divcnt		:std_logic_vector(DIV_WIDTH-1 downto 0);
constant divmax		:std_logic_vector(DIV_WIDTH-1 downto 0):=(others=>'1');
constant divmaxhalf	:std_logic_vector(DIV_WIDTH-1 downto 0):= (DIV_WIDTH-1 =>'0', others=>'1'); ----- downto 0):=(others=>'1');

begin  
   
process(nRST ,SYSCLK) 
begin
    if nRST = '0' then 
        pstate <= st_idle ;
        PHY_ACK <= '0';
        PHY_MDir <= '0'; --'0': read , '1': out 
        PHY_MDOUT <= '1';
        PHY_MDC  <= '0';
    elsif rising_edge(SYSCLK) then
		case pstate is 
	  
        when st_idle => 
            cur_req <= PHY_RDWREN; --'0': read , '1' write
			cur_addr_req<= PHY_WADDREN;--'1':write addr,'0':write data;
            addr   <= phy_PHYADDR&PHY_DEVADDR;
            wdata  <= PHY_WDATA;
            divcnt <= (others=>'0');
            rdata  <= (others => '0');
            PHY_MDC  <= '0';
            PHY_ACK <= '0';
            phy_RVLD <= '0';                   
            if PHY_REQ = '1' then 
                pstate <= st_preamble;
            else
                pstate <= st_idle ;
            end if;
            cnt <= (others=>'0');
            PHY_MDir <= '0';
            PHY_MDOUT <= '1'; 
		
        when st_preamble =>
            PHY_ACK <= '0';
            divcnt <= divcnt + '1' ;
            if divcnt = divmax then --31 
                if cnt < (32 + 2 +2 + 5 + 5 + 2 + 16 + 1  ) then
                    cnt <= cnt + '1';
                    pstate <= st_preamble;
                else
                    pstate <= st_turn;
                end if;
            end if;
            
            if divcnt = divmaxhalf and cnt(6) = '0' then 
				PHY_MDC  <= '1';
            ELSIF divcnt = divmax then
				PHY_MDC <= '0';
            end if;              
                         
            if cnt < 32 then 
				PHY_MDOUT <= '1' ;---32 preamble 
				PHY_MDir  <= '1';
            elsif cnt = 32 then  ---start code
				PHY_MDOUT <= '0';
				PHY_MDir <= '1';
            elsif cnt = 33 then  ---start code
				PHY_MDOUT <= '0';
				PHY_Mdir <= '1';
            elsif cnt = 34 then  --op 
				if cur_req = '0' then ---'0': read, '1':write, read 
					PHY_MDOUT <= '1';
				else
					PHY_MDOUT <= '0' ;
				end if;                    
				PHY_Mdir <= '1';
            elsif cnt = 35 then  --op 
                if cur_req = '0' then ---read 
                    PHY_MDOUT <= '1';
				elsif cur_req ='1'then
					if cur_addr_req='1' then
						PHY_MDOUT <= '0' ;
					else
						PHY_MDOUT<= '1';
					end if; 
				end if;					
                PHY_Mdir <= '1';
            elsif cnt < 46 then 
                PHY_MDOUT <= addr(9);
                if divcnt = divmax then 
                    addr <= addr(8 downto 0)&'0';
                end if;
                PHY_Mdir <= '1';
            elsif cnt = 46 then 
                if cur_req = '0' then ---'0' read-'0': read , '1' write
                    PHY_Mdir <= '0'; ---'0' : in , '1' : out
                    PHY_MDOUT<= '0';  --DONT'CARE
                else---WRITE 
                    PHY_MDIR <= '1'; ---'0' : in , '1' : out
                    PHY_MDOUT<= '1';
                END IF;
            elsif cnt = 47 then 
                if cur_req = '0' then ---'0' read-'0': read , '1' write
                    PHY_Mdir <= '0'; ---'0' : in , '1' : out
                    PHY_MDOUT<= '0';
                else
                    PHY_MDIR <= '1';
                    PHY_MDOUT<= '0';
                END IF;  
                if cur_req = '0' then ---'0' read-'0': read , '1' write
                    PHY_Mdir <= '0'; ---'0' : in , '1' : out
                    PHY_MDOUT<= '0';
                    if divcnt = divmax then 
                        rdata <= rdata(14 downto 0)&PHY_MDin ;
                    end if;
                end if;
            elsif cnt < 48+16 then 
            
                if cur_req = '0' then ---'0' read-'0': read , '1' write
                    PHY_Mdir <= '0'; ---'0' : in , '1' : out
                    PHY_MDOUT<= '0';
                    if cnt < 48 + 15 then 
                        if divcnt = divmax then 
                            rdata <= rdata(14 downto 0)&PHY_MDin ;
                        end if;
                    end if;
                else
                    PHY_MDIR <= '1';
                    PHY_MDOUT<= wdata(15);
                    if divcnt = divmax then  
                        wdata <= wdata(14 downto 0)&'0';
                    end if;
                END IF;   
            else
            
            end if;
                 
        when st_turn =>
            PHY_RDATA <= rdata;
            PHY_ACK <= '1'; ---next data is go on
            if cur_req = '0' then 
                PHY_RVLD  <= '1';
            else
                phy_RVLD <= '0';
            END IF;
            PHY_MDOUT <= '1';  ---hang up ,release the bus
            PHY_MDC  <= '0';
            pstate <= st_idle ;
        when others=> pstate <= st_idle;            
		end case;
              
        -- when st_preamble =>
            -- if cnt < 16 then 
                -- pstate <= st_preamble ;
                -- cnt <= cnt + '1';
            -- else
                -- pstate <= st_start;
                -- cnt <= (others=>'0');
            -- end if;
        -- when st_start =>
            -- if cnt < 2 then 
                -- cnt <= cnt + '1';
                -- pstate <= st_start;
            -- else
                -- pstate <= st_op;
                -- cnt <= (others=>'0');
            -- end if;
        -- when st_op =>
            -- if cnt < 2 then 
                -- pstate <= st_op;
                -- cnt <= cnt + '1';
            -- else
                -- cnt <= (others=>'0');
                -- pstate <= st_phyaddr;
            -- end if;
        -- when st_phyaddr =>
            -- if cnt < 5 then 
                -- cnt <= cnt + '1';
                -- pstate <= st_phyaddr;
            -- else
                -- cnt <= (others=>'0');
                -- pstate <= st_regaddr;
            -- end if;
        -- when st_regaddr=>
            -- if cnt< 5 then 
                -- cnt <= cnt + '1' ;
            -- else
                -- cnt <= (others=>'0');
                -- pstate <= st_turn;
            -- end if;
        -- when st_turn =>
            -- if cnt < 2 then 
                -- cnt <= cnt + '1' ;
            -- else
                -- cnt <= (others=>'0');
            -- end if;
        -- when st_data =>
            -- if cnt< 16 then 
                -- cnt <= cnt + '1' ;
            -- else
                -- cnt <= (others=>'0');
            -- end if;                                               
        -- end case;
              
    end if;
end process;
   

end beha;


