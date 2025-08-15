library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

--use work.PCK_subfrm_type.all;

entity autobright_upload is
generic(   
    ETH_PORT_NUM : integer := 8;
    BAUD         : std_logic_vector(15 downto 0):= x"0020"    
);
port (
    sys_nRST                : in  std_logic;
    sysclk                  : in  std_logic;
    time_ms_en              : in  std_logic;
    autolight_en            : in  std_logic_vector(ETH_PORT_NUM-1 downto 0);    --PULSE ONLY
    autolight_val           : in  std_logic_vector(8*( ETH_PORT_NUM) -1  downto 0) ;
    autolight_tx            : OUT std_logic ;---uart TXD 
    tx_autolight_val        : out std_logic_vector(8*( ETH_PORT_NUM) -1  downto 0);
    tx_autolight_vld        : out std_logic_vector(  ( ETH_PORT_NUM) -1  downto 0)

);
end autobright_upload;

architecture beha of autobright_upload is 


signal ms_cnt           : std_logic_vector(15 downto 0);
signal upload_req       : std_logic;
signal upload_ack       : std_logic;


type state is(
    idle, 
    senddata
);
signal pstate : state:= idle;

type ARRAY_4x39  is array (0 to 39)  of std_logic_vector(3 downto 0);
type ARRAY_8x39  is array (0 to 39)  of std_logic_vector(7 downto 0);

signal vld_cnt              : ARRAY_4x39;
signal timeout_cnt          : ARRAY_8x39;
signal is_connected         : std_logic_vector(ETH_PORT_NUM-1 downto 0);
signal cnt_5s               : std_logic_vector(15 downto 0); 
signal cnt_100ms            : std_logic_vector(7 downto 0); 
signal time_5s_en           : std_logic;
signal time_100ms_en        : std_logic;
-- signal tx_autolight_val     : std_logic_vector(8*( ETH_PORT_NUM) -1  downto 0);



component uart_tx is
generic(
    BAUD                        : std_logic_vector(7 downto 0):= x"20"
);
port(
    nRST                        : in  std_logic;
    sysclk                      : in  std_logic;
    
    uart_txd                    : out std_logic;
    
    busy_en                     : out std_logic;
    tx_data_vld                 : in  std_logic;
    tx_data                     : in  std_logic_vector(7 downto 0)
);
end component;

signal busy_en          : std_logic;
signal txdata           : std_logic_vector(7 downto 0);
signal txdata_vld       : std_logic;
signal tx_cnt           : std_logic_vector(7 downto 0);
signal port_cnt         : std_logic_vector(7 downto 0);

constant UPLOAD_LEN     : integer := 33;

 
begin

port_cnt <= tx_cnt - 9;
process(sys_nRST,sysclk)
begin
    if sys_nRST = '0' then
        ms_cnt <= (others => '0');
        upload_req <= '0';
    elsif rising_edge(sysclk) then
        if time_ms_en = '1' then
            if ms_cnt >= 500 then
                ms_cnt <= (others => '0');
            else
                ms_cnt <= ms_cnt + '1';
            end if;
        end if;    

        if upload_ack = '1' then
            upload_req <= '0';
        elsif time_ms_en = '1' and ms_cnt >= 500 then
            upload_req <= '1';
        end if;
    end if;
end process;    


tx_autolight_vld <= is_connected;


--- process(sysclk,sys_nRST)
--- begin
---     if sys_nRST = '0' then
---         pstate <= idle;
---         upload_ack <= '0';
---         tx_cnt <= (others => '0');
---         txdata_vld <= '0';
---         txdata <= (others => '0');
---     elsif rising_edge(sysclk) then
---         case(pstate) is
---             when idle =>
---                 if upload_req = '1' then
---                     pstate <= senddata;
---                     upload_ack <= '1';
---                 else
---                     pstate <= idle;
---                     upload_ack <= '0';
---                 end if; 
---                 tx_cnt <= (others => '0');
---             when senddata =>
---                 upload_ack <= '0';
---                 if tx_cnt >= UPLOAD_LEN then
---                     pstate <= idle;
---                 else
---                     pstate <= senddata;
---                 end if;
--- 
---                 if busy_en = '0' and txdata_vld = '0' then  
---                     txdata_vld <= '1';
---                     tx_cnt <= tx_cnt + '1';
---                 else
---                     txdata_vld <= '0';
---                     tx_cnt <= tx_cnt;
---                 end if; 
--- 
---                 if tx_cnt = 0 then
---                     txdata <= X"58";
---                 elsif tx_cnt >= 1 and tx_cnt < 9 then
---                     txdata <= (others => '0');  -- reserve
---                 elsif tx_cnt >= 9 and tx_cnt < 9+ETH_PORT_NUM*2 then
---                     for i in 0 to ETH_PORT_NUM-1 loop
---                         if port_cnt(7 downto 1) = i then
---                             if port_cnt(0) = '0' then
---                                 txdata(0) <= is_connected(i);
---                             else
---                                 txdata <= tx_autolight_val(8*i+7 downto 8*i); 
---                             end if;
---                         end if;
---                     end loop;    
---                 else
---                     txdata <= (others => '0');
---                 end if;
---                     
--- 
---             when others =>
---                 pstate <= idle;
---                 
---         end case;
---     end if;
--- end process;

process(sys_nRST,SYSCLK)
begin
    if sys_nRST = '0' then
        tx_autolight_val <= (others => '0');
    elsif rising_edge(SYSCLK) then
        for i in 0 to ETH_PORT_NUM-1 loop
            if autolight_en(i) = '1' then
                tx_autolight_val(8*i+7 downto 8*i) <= autolight_val(8*i+7 downto 8*i); 
            end if;  
        end loop;    
    end if;
end process; 


process(sys_nRST,SYSCLK)
begin
    if sys_nRST = '0' then
        cnt_5s <= (others => '0');
        time_5s_en <= '0';
        cnt_100ms <= (others => '0');
        time_100ms_en <= '0';
    elsif rising_edge(SYSCLK) then
        if time_ms_en = '1' then
            if cnt_5s = 4999 then
                cnt_5s <= (others => '0');
                time_5s_en <= '1';
            else
                cnt_5s <= cnt_5s + '1';
                time_5s_en <= '0';
            end if;
        else
            time_5s_en <= '0';
        end if;
        
        if time_ms_en = '1' then
            if cnt_100ms = 99 then
                cnt_100ms <= (others => '0');
                time_100ms_en <= '1';
            else
                cnt_100ms <= cnt_100ms + '1';
                time_100ms_en <= '0';
            end if;
        else
            time_100ms_en <= '0';
        end if;
    end if;
end process; 
 

process(sys_nRST,SYSCLK)
begin
    if sys_nRST = '0' then
        is_connected <= (others => '0');
        for i in 0 to ETH_PORT_NUM-1 loop
            timeout_cnt(i) <= conv_std_logic_vector(64,8);
        end loop;    
    elsif rising_edge(SYSCLK) then
        for i in 0 to ETH_PORT_NUM-1 loop
            if autolight_en(i) = '1' then --PULSE ONLY 
                timeout_cnt(i) <= (others => '0');
            elsif time_100ms_en = '1' and timeout_cnt(i)(6) = '0' then   -- 64x100ms
                timeout_cnt(i) <= timeout_cnt(i) + '1';
            end if;
            
            if timeout_cnt(i)(6) = '0' then
                is_connected(i) <= '1';  --AUTO CONNECTED 
            else
                is_connected(i) <= '0';
            end if;
        end loop;    
    end if;
end process; 


uart_tx_autobright: uart_tx
generic map(
    BAUD                          => BAUD(7 DOWNTO 0)
)
port map(
    nRST                         => sys_nRST     ,
    sysclk                       => sysclk       ,

    uart_txd                     => autolight_tx ,

    busy_en                      => busy_en      ,
    tx_data_vld                  => txdata_vld   ,
    tx_data                      => txdata       
);




end beha;