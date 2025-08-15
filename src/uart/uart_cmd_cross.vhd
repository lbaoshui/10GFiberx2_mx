
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_arith.all ;
use ieee.std_logic_unsigned.all ;

entity uart_cmd_cross is 
port (
    nRST            : in std_logic ;
    sysclk          : in std_logic;
    uart_rx_wdata   : in std_logic_vector(7  downto 0);
    uart_rx_wraddr  : in std_logic_vector(10 downto 0); 
    uart_rx_wren    : in std_logic ;
    frm_len_i       : in std_logic_vector(10 downto 0);
    done_notify_i   : in std_logic;

---to reduce the clock domain in HDMI region 
    nRST_cmd        : in std_logic ;
    cmd_clk         : in std_logic;    
    
    p_Frame_en_cmd    : out std_logic  := '0';
    p_Wren_cmd        : out std_logic  := '0';
    p_Data_cmd        : out std_logic_vector(7 downto 0);
    p_Addr_cmd        : out std_logic_vector(10 downto 0) 
    
);
end uart_cmd_cross;

architecture beha of uart_cmd_cross is 

signal uart_rx_rdaddr_buf    : std_logic_vector(10 downto 0);
signal uart_rx_rdaddr_buf_d1 : std_logic_vector(10 downto 0);
signal uart_rx_rdaddr : std_logic_vector(10 downto 0);
signal uart_rx_q      : std_logic_vector(7  downto 0);

signal p_Frame_en_o    :   std_logic  := '0';
signal p_Wren_o        :   std_logic  := '0';
signal p_Data_o        :   std_logic_vector(7 downto 0);
signal p_Addr_o        :   std_logic_vector(10 downto 0) ;


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


component uart_crossrx_dpram is
        port (
            data      : in  std_logic_vector(7 downto 0)  := (others => 'X'); -- datain
            q         : out std_logic_vector(7 downto 0);                     -- dataout
            wraddress : in  std_logic_vector(10 downto 0) := (others => 'X'); -- wraddress
            rdaddress : in  std_logic_vector(10 downto 0) := (others => 'X'); -- rdaddress
            wren      : in  std_logic                     := 'X';             -- wren
            wrclock   : in  std_logic                     := 'X';             -- clk
            rdclock   : in  std_logic                     := 'X'              -- clk
        );
    end component uart_crossrx_dpram;
    signal length_lock : std_logic_vector(10 downto 0);
    signal frm_len_cmd : std_logic_vector(10 downto 0);
    signal notify_cmd  : std_logic := '0'; 
    signal read_dur_en     : std_logic := '0'; 
    signal read_dur_en_d1  : std_logic := '0'; 
    
    type state1 is (rd_idle,rd_dur);
    signal pstate_rd : state1 := rd_idle;

begin 
     


     uart_rx_dpram_inst : uart_crossrx_dpram
     port map (
         data      => uart_rx_wdata,
         q         => uart_rx_q,
         wraddress => uart_rx_wraddr,
         rdaddress => uart_rx_rdaddr,
         wren      => uart_rx_wren,
         wrclock   => sysclk     ,
         rdclock   => cmd_clk
     );
     
    frmlen_crs: cross_domain   
    generic map(
       DATA_WIDTH => 11
    )
    port  map
    (   clk0       => sysclk        ,
        nRst0      => nRSt          , 
        datain     => frm_len_i     ,
        datain_req => done_notify_i ,
        
        clk1       => cmd_clk   ,
        nRst1      => nRST_cmd  ,
        data_out   => frm_len_cmd ,
        dataout_valid => notify_cmd  ---just pulse only
    );
  

     
    uart_rx_rdaddr <= uart_rx_rdaddr_buf;
    process(cmd_clk,nRST_cmd)
    begin 
        if nRST_cmd = '0' then 
        elsif rising_edge(cmd_clk) then  
        end if;
    end process;
     
     
    process(cmd_clk,nRST_cmd)
    begin 
     if nRST_cmd = '0' then 
         read_dur_en  <= '0';
         pstate_rd    <= rd_idle;
         p_Frame_en_o <= '0';
         p_Wren_o     <= '0';
     
     elsif rising_edge(cmd_clk) then  
         read_dur_en_d1          <= read_dur_en;
         uart_rx_rdaddr_buf_d1   <= uart_rx_rdaddr_buf;
         p_Addr_o              <= uart_rx_rdaddr_buf_d1;
         p_Frame_en_o          <= read_dur_en;
         p_Wren_o              <= read_dur_en;
         
         case pstate_rd is
           when rd_idle =>
               if notify_cmd = '1' then -----frame_right = '1' then
                   length_lock <= frm_len_cmd;
                   pstate_rd <= rd_dur;
               else
                   pstate_rd <= rd_idle;
               end if;
               read_dur_en <= ('0');
               uart_rx_rdaddr_buf <= (others=>'0');
               
           when rd_dur =>
               if uart_rx_rdaddr_buf < length_lock then
                   uart_rx_rdaddr_buf <= uart_rx_rdaddr_buf + '1';
                   read_dur_en <= '1';
                   pstate_rd <= rd_dur;
               else
                   pstate_rd <= rd_idle;
                   read_dur_en <= '0';
               end if;
               
           when others=> pstate_rd <= rd_idle;
        end case;
      end if;
   end process;
   p_Data_o        <= uart_rx_q; 
    
   p_Frame_en_cmd  <= p_Frame_en_o ;
   p_Wren_cmd      <= p_Wren_o     ;
   p_Data_cmd      <= p_Data_o     ;
   p_Addr_cmd      <= p_Addr_o     ;

end beha ;
    