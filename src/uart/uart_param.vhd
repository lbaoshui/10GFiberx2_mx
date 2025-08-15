

library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_arith.all ;
use ieee.std_logic_unsigned.all ;

entity uart_param is
generic
(
    TXSUBCARD_TYPE      : std_logic_vector(7  downto 0);
    BAUD_DIV            : std_logic_vector(15 downto 0):=X"043C";
    --2.5M       div_cnt=49   50x8ns=400ns 1bit
    --2M         div_cnt=61 --->3D
    --115200bps div_cnt=1084 --->43C
    --9600bps   div_cnt=13019
    -- BAUD= 1/(baud rate)/8  X 10e9 -1, sysclk is 125M
    HSSI_NUM            : integer:= 2
);
port
(
    ---to reduce the clock domain in HDMI region 
    nRST_cmd        : in std_logic ;
    cmd_clk         : in std_logic;    

	serdes_frame_ss		: in std_logic;
	serdes_rx_vld		: in std_logic;
	serdes_rx_data		: in std_logic_vector(7 downto 0);
	para_serdes_lock	: in std_logic;

    p_Frame_en_cmd    : out std_logic ;
    p_Wren_cmd        : out std_logic ;
    p_Data_cmd        : out std_logic_vector(7 downto 0);
    p_Addr_cmd        : out std_logic_vector(10 downto 0); 
    cur_slot_num_cmd  : out std_logic_vector(15 downto 0);    
    ------------------------------------------
    nRST            : in std_logic ;
    sysclk          : in std_logic;
	time_ms_en		: in std_logic ;
    ---uart: 2 pins of uart
    rxd_top         : in  std_logic ;  --from top pad
    txd_top         : out std_logic ; ---to top pad

    p_Frame_en_o    : out std_logic ;
    p_Wren_o        : out std_logic ;
    p_Data_o        : out std_logic_vector(7 downto 0);
    p_Addr_o        : out std_logic_vector(10 downto 0);
    cur_slot_num    : out std_logic_vector(15 downto 0);

	Up_cmd_fifo_empty  : in std_logic_vector(HSSI_NUM-1 downto 0); 
	Up_cmd_fifo_rden   : out  std_logic_vector(HSSI_NUM-1 downto 0); 
	Up_cmd_fifo_q      : in std_logic_vector(HSSI_NUM*29-1 downto 0);
    Up_ReadAddr        : out  std_logic_vector(11 downto 0);
    Up_ReadData        : in std_logic_vector(HSSI_NUM*8-1 downto 0)  ---latency is 2 ,after Up_ReadAddr_o;

);
end uart_param ;

architecture beha of uart_param IS
signal tx_uart_busy       : std_logic;
signal txd_en          : std_logic;
signal txd_data        : std_logic_vector(7 downto 0);

signal rxd_data        : std_logic_vector(7 downto 0);
signal rxd_en          : std_logic;
signal serdes_lock_4s	: std_logic			:='0';
signal time_4s_cnt		: std_logic_vector(12 downto 0)			:=(others => '0');

signal rxd_data_uart        : std_logic_vector(7 downto 0);
signal rxd_en_uart          : std_logic;

signal fwd_cnt         : std_logic_vector(15 downto 0);
signal tx_cnt             : std_logic_vector(3 downto 0);

signal uart_rdaddr     : std_logic_vector(10 downto 0);
signal uart_q          : std_logic_vector(7 downto 0);



component uart is
generic(
	BAUD						: std_logic_vector(7 downto 0):= x"20"
);
port(
	nRST						: in  std_logic;
	sysclk						: in  std_logic;
	
	uart_rxd					: in  std_logic;
	uart_txd					: out std_logic;
	--rx
	frame_ss					: out std_logic;
	rx_data_vld					: out std_logic;
	rx_data						: out std_logic_vector(7 downto 0);
	--tx
	busy_en						: out std_logic;
	tx_data_vld					: in  std_logic;
	tx_data						: in  std_logic_vector(7 downto 0)
);
end component ;


type state is (
    idle         ,
    uart_fwd     ,
    tx_turnaround,
    get_data_w1  ,
    get_data_w2  ,
    get_data     ,
    tx_busy_w
);
signal pstate: state := idle;

signal rx_timeout     : std_logic_vector(16 downto 0);
signal rx_timeout_flg    : std_logic;
signal rx_timeout_TH     : std_logic_vector(16 downto 0);
signal up_cnt            : std_logic_vector(11 downto 0);
signal rx_frm_type       : std_logic_vector(7 downto 0);

type  rx_stATE_DEF is  (
    RX_IDLE,
    RX_TYPEPARSE,
    RX_UPLOAD   ,
    RX_WAIT_ZZZZ
);
SIGNAL rx_st : rx_stATE_DEF := RX_IDLE;

signal fwd_len_lock: std_logic_vector(10 downto 0);
component uart_rx_dpram is
    port (
        data      : in  std_logic_vector(7 downto 0)  := (others => 'X'); -- datain
        q         : out std_logic_vector(7 downto 0);                     -- dataout
        wraddress : in  std_logic_vector(10 downto 0) := (others => 'X'); -- wraddress
        rdaddress : in  std_logic_vector(10 downto 0) := (others => 'X'); -- rdaddress
        wren      : in  std_logic                     := 'X';             -- wren
        clock     : in  std_logic                     := 'X'              -- clk
    );
end component uart_rx_dpram;
signal uart_rx_data : std_logic_vector(7 downto 0);
signal uart_rx_q : std_logic_vector(7 downto 0);
signal uart_rx_wraddr : std_logic_vector(10 downto 0);
signal uart_rx_wraddr_buf : std_logic_vector(10 downto 0);
signal uart_rx_rdaddr : std_logic_vector(10 downto 0);
signal uart_rx_wren : std_logic:='0';
signal uart_rx_wren_buf : std_logic:='0';
signal frame_right : std_logic:='0';
signal valid_frame : std_logic:='0';
signal finish_head : std_logic:='0';
signal rx_head_cnt : std_logic_vector(3 downto 0);
signal frame_length : std_logic_vector(10 downto 0);
signal frame_len_lock : std_logic_vector(10 downto 0);
signal target_slot_num : std_logic_vector(15 downto 0);
signal source_slot_num : std_logic_vector(15 downto 0);
signal rxsubcard_type : std_logic_vector(7 downto 0);
signal uart_rx_rdaddr_buf : std_logic_vector(10 downto 0);
signal uart_rx_rdaddr_buf_d1 : std_logic_vector(10 downto 0);
signal length_lock : std_logic_vector(10 downto 0);
signal read_dur_en : std_logic;
signal read_dur_en_d1 : std_logic;
type state1 is (rd_idle,rd_dur);
signal pstate_rd : state1 := rd_idle;

component uart_cmd_cross is 
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
end component ;

signal up_sel       : integer range 0 to HSSI_NUM-1 := 0;
signal  Up_req_buf        : std_logic_vector(4-1 DOWNTO 0)     :=(others=>'0');
signal  Up_ack_buf        : std_logic_vector(4-1 DOWNTO 0)     :=(others=>'0');
signal  Up_end_buf        : std_logic_vector(4-1 DOWNTO 0)     :=(others=>'0'); 
signal  Up_ReadLength_buf : std_logic_vector(4*11-1 downto 0)  :=(others=>'0');
signal  Up_ReadData_buf   : std_logic_vector(4*8-1 downto 0)   :=(others=>'0');

signal up_cmd_fifo_busy : std_logic_vector(HSSI_NUM-1 downto 0);
signal cnt           : std_logic_vector(HSSI_NUM*2-1 downto 0);
signal upcmdfifo_req    : std_logic_vector(HSSI_NUM-1 downto 0);
signal upcmdfifo_ack    : std_logic_vector(HSSI_NUM-1 downto 0);
signal rd_point    : std_logic_vector(HSSI_NUM-1 downto 0);
signal rd_point_sel : std_logic;
component altera_std_synchronizer is  
  port   
     (
		clk : in std_logic ;
		reset_n : in std_logic ; 
		din     : in std_logic ;
		dout    : out std_logic
				);  
end component; 
signal para_serdes_lock_sys  : std_logic;

signal rxd_en_d1  : std_logic;



begin



lock_crs: altera_std_synchronizer    
    port   map
    (
		clk      => sysclk,
		reset_n  => nRST,
		din      => para_serdes_lock,
		dout     => para_serdes_lock_sys
	); 	

process(nRST, sysclk)
begin
	if nRST = '0' then
		serdes_lock_4s <= '0';
		time_4s_cnt <= (others => '0');
		rxd_en <= '0';
		rxd_data <= (others => '0');
	elsif rising_edge(sysclk) then
		if para_serdes_lock_sys = '1' then
			if time_ms_en = '1' then
				if time_4s_cnt(12) = '1' then			-- 4s
					time_4s_cnt <= (others => '0');
					serdes_lock_4s <= '1';
				else
					time_4s_cnt <= time_4s_cnt + '1';
				end if;
			end if;
			
		else
			time_4s_cnt <= (others => '0');
			serdes_lock_4s <= '0';
		end if;
		
		if serdes_lock_4s = '1'  then
			rxd_en   <= serdes_rx_vld;
			rxd_data <= serdes_rx_data;
		else
			rxd_en <= rxd_en_uart;
			rxd_data <= rxd_data_uart;
		end if;
	end if;
end process;



cur_slot_num <= source_slot_num;

uart_rx_dpram_inst : uart_rx_dpram
port map (
    data      => uart_rx_data,
    q         => uart_rx_q,
    wraddress => uart_rx_wraddr,
    rdaddress => uart_rx_rdaddr,
    wren      => uart_rx_wren,
    clock     => sysclk
);

------------------------------------------------------------------
-- Up_ReadEn_o <= txd_en;

 
 -- Up_ack  <= Up_ack_buf (HSSI_NUM-1 DOWNTO 0);
 -- Up_end  <= Up_end_buf (HSSI_NUM-1 DOWNTO 0); 
 -- Up_req_buf (HSSI_NUM-1 DOWNTO 0)  <= Up_req;
 -- Up_ReadLength_buf(HSSI_NUM*11-1 downto 0) <= Up_ReadLength_i;
 Up_ReadData_buf(HSSI_NUM*8-1 downto 0)    <= Up_ReadData;
 
 process(nRST,SYSCLK)
begin
	if nRST = '0' then
		upcmdfifo_req    <= (others=>'0');
		Up_cmd_fifo_rden <= (others=>'0');
		cnt <= (others=>'0');
		up_cmd_fifo_busy <= (others=>'0');
		rd_point         <= (others=>'0');
	
	elsif rising_edge(SYSCLK) then
		for i in 0 to HSSI_NUM-1 loop
			if up_cmd_fifo_busy(i) = '1' then
				Up_cmd_fifo_rden(i) <= '0';
				if cnt(i*2+1)='1' then
					cnt((i+1)*2-1 downto i*2) <= (others=>'0');
					up_cmd_fifo_busy(i)  <= '0';
					upcmdfifo_req(i)  <= '1';
					Up_ReadLength_buf((i+1)*11-1 downto i*11) <= Up_cmd_fifo_q(i*29+10 downto i*29);
					rd_point(i) <= Up_cmd_fifo_q(i*29+11);
				else
					cnt((i+1)*2-1 downto i*2) <= cnt((i+1)*2-1 downto i*2)+1;
				end if;
			elsif upcmdfifo_req(i) = '1' then
				if upcmdfifo_ack(i) = '1' then
					upcmdfifo_req(i) <= '0';
				end if;
				cnt((i+1)*2-1 downto i*2) <= (others=>'0');
				Up_cmd_fifo_rden(i) <= '0';
			elsif Up_cmd_fifo_empty(i) = '0' then
				upcmdfifo_req(i)    <= '0';
				Up_cmd_fifo_rden(i) <= '1';
				up_cmd_fifo_busy(i) <= '1';
				cnt((i+1)*2-1 downto i*2) <= (others=>'0');
			else
				upcmdfifo_req(i)    <= '0';
				Up_cmd_fifo_rden(i) <= '0';
			end if;
		end loop;
	end if;
end process;
 
       
process(nRST,SYSCLK)
begin
    if nRST = '0' then
        pstate       <= idle;
        fwd_cnt      <= (others => '0');
        tx_cnt       <= (others => '0');
        txd_en       <= '0';
        txd_data     <= (others => '0');
        fwd_len_lock <= (others => '0');
        up_sel       <= 0;
        Up_ack_buf <= (others => '0');
       Up_end_buf <= (others=>'0');
    elsif rising_edge(SYSCLK) then 
       Up_ack_buf <= (others => '0');
       Up_end_buf <= (others=>'0');
        case pstate is
            when idle =>

                if upcmdfifo_req(0) = '1' then
                    pstate       <= uart_fwd;
                    upcmdfifo_ack(0)    <= '1';
                    up_sel       <= 0;
                    fwd_len_lock <= Up_ReadLength_buf(11*1-1 DOWNTO 0);
					rd_point_sel <= rd_point(0);
                elsif upcmdfifo_req(1) = '1' then
                    pstate       <= uart_fwd;
                    upcmdfifo_ack(1)    <= '1';
                    up_sel       <= 1;
                    fwd_len_lock <= Up_ReadLength_buf(11*2-1 downto 11*1);
					rd_point_sel <= rd_point(1);
                -- ELSIF  Up_req_buf(2) = '1' then
                    -- pstate       <= uart_fwd;
                    -- Up_ack_buf(2)    <= '1';
                    -- up_sel       <= 2;
                    -- fwd_len_lock <= Up_ReadLength_buf(11*3-1 downto 11*2);
                -- ELSIF Up_req_buf(3) = '1' then
                    -- pstate       <= uart_fwd;
                    -- Up_ack_buf(3)    <= '1';
                    -- up_sel       <= 3;
                    -- fwd_len_lock <= Up_ReadLength_buf(11*4-1 downto 11*3);
                else
                    up_sel       <= 0;
                    upcmdfifo_ack   <= (others => '0');
                    pstate      <= idle;
                end if;

                fwd_cnt <= (others => '0');
                tx_cnt <= (others => '0');
                txd_en <= '0';
                txd_data <= (others => '0');

            WHEN tx_turnaround =>
                  if tx_cnt = 0 then 
                      Up_end_buf                       <= (others=>'0');
                      Up_end_buf(conv_integer(up_sel)) <= '1';
                  end if;
                  if tx_cnt(3) = '0' then
                       tx_cnt <= tx_cnt + 1;
                  end if;
                  if tx_cnt(3) = '1' then
                      pstate <= idle;
                  end if;
                  txd_en <= '0';

            when uart_fwd =>
			
                upcmdfifo_ack <= (others => '0');
                fwd_cnt <= fwd_cnt + '1';
                Up_ReadAddr <= rd_point_sel&fwd_cnt(10 downto 0);
                if fwd_cnt >= fwd_len_lock then
                    pstate <= tx_turnaround;
                else
                    pstate <= get_data_w1;
                end if;
                tx_cnt <= (others => '0');

            when get_data_w1 =>

                if tx_cnt(2) = '0' then
                    tx_cnt <= tx_cnt + '1';
                    pstate <= get_data_w1;
                else
                    tx_cnt <= (others => '0');
                    pstate <= get_data_w2;
                end if;
            when get_data_w2 =>
                pstate <= get_data;
            when get_data =>
                pstate   <= tx_busy_w;
                txd_en   <= '1';
                txd_data <= Up_ReadData_buf( (up_sel+1)*8-1 downto up_sel*8);

            when tx_busy_w =>
                txd_en <= '0';
                if tx_cnt(3) = '0' then
                    tx_cnt <= tx_cnt + 1;
                end if;

                if tx_cnt(3) = '0' then
                    pstate <= tx_busy_w;
                elsif tx_uart_busy = '1' then
                    pstate <= tx_busy_w;
                else
                    pstate <= uart_fwd;
                end if;

            when others => pstate <= idle;
        end case;
    end if;
end process;

uart_rx_wraddr <= uart_rx_wraddr_buf;
uart_rx_wren <= uart_rx_wren_buf;
process(nRST,SYSCLK)
begin
if nRST = '0' then
    rx_st    <= RX_IDLE;
    up_cnt    <= (others=>'0');
    uart_rx_wraddr_buf     <= (others=>'0');
    rx_head_cnt     <= (others=>'0');
    uart_rx_wren_buf     <= '0';
    finish_head     <= '0';
elsif rising_edge(SYSCLK) then
    uart_rx_data <= rxd_data;
	rxd_en_d1    <= rxd_en;
    case(rx_st) is
        when RX_IDLE =>
            rx_head_cnt           <= (others=>'0');
            up_cnt           <= (others=>'0');
            uart_rx_wraddr_buf     <= (others=>'0');
            if rxd_en ='1' then
                if rxd_data = x"01" then  --downlink
                    rx_st            <= RX_UPLOAD;
                else
                    rx_st <= RX_WAIT_ZZZZ;
                end if;
            else
                rx_st            <= RX_IDLE;
                uart_rx_wren_buf     <= '0';
            end if;
            valid_frame <= '0';
            frame_right <= '0';
            finish_head <= '0';

        when RX_UPLOAD =>
			if serdes_lock_4s = '1' and rxd_en_d1='0'  then -----serdes param
				if uart_rx_wraddr_buf = frame_len_lock then
					frame_right <= '1';
				else
					frame_right <= '0';
				end if;		
				rx_st           <= RX_IDLE;
				uart_rx_wren_buf<= '0';					
            elsif rx_timeout_flg ='1' then
                rx_st            <= RX_IDLE;
                uart_rx_wren_buf     <= '0';
                if uart_rx_wraddr_buf = frame_len_lock then
                    frame_right <= '1';
                else
                    frame_right <= '0';
                end if;
            else
                if finish_head = '1' and valid_frame = '0' then
                    rx_st <= RX_WAIT_ZZZZ;
                else
                    rx_st <= RX_UPLOAD;
                    if valid_frame = '1' then
                        if rxd_en = '1' then
                            uart_rx_wren_buf  <= '1';
                        else
                            uart_rx_wren_buf  <= '0';
                        end if;
                    else
                        uart_rx_wren_buf <= '0';
                    end if;
                end if;
            end if;
            if uart_rx_wren_buf = '1' then
                uart_rx_wraddr_buf <= uart_rx_wraddr_buf + '1';
            end if;

            if rxd_en = '1' then
                up_cnt <= up_cnt + '1';
                if rx_head_cnt < x"F" then
                    rx_head_cnt <= rx_head_cnt + '1';
                end if;
            end if;
			if rxd_en = '1' then
				if rx_head_cnt = x"E" and ((target_slot_num = source_slot_num) or (target_slot_num = x"FFFF" and TXSUBCARD_TYPE = rxsubcard_type)) then
					valid_frame <= '1';
				end if;
				if rx_head_cnt = x"E" then
					finish_head <= '1';
				end if;
			end if;
			if rx_head_cnt = X"F" then
				frame_len_lock <= frame_length;
			end if;

            if rxd_en = '1' then
                case rx_head_cnt is
                when x"0" => target_slot_num(7 downto 0) <= rxd_data;
                when x"1" => target_slot_num(15 downto 8) <= rxd_data;
                when x"5" => rxsubcard_type(7 downto 0) <= rxd_data;
                when x"b" => source_slot_num(7 downto 0) <= rxd_data;
                when x"c" => source_slot_num(15 downto 8) <= rxd_data;
                when x"D" => frame_length(7 downto 0) <= rxd_data;
                when x"E" => frame_length(10 downto 8) <= rxd_data(2 downto 0);
                when others => null;
                end case;
            end if;
        when RX_WAIT_ZZZZ =>
            if rx_timeout_flg = '1' then
                rx_st <= RX_IDLE;
            else
                rx_st <= RX_WAIT_ZZZZ;
            end if;
            uart_rx_wren_buf     <= '0';
        when others =>
                uart_rx_wren_buf     <= '0';
                rx_st            <= RX_IDLE;
    end case;
end if;
end process;
uart_rx_rdaddr <= uart_rx_rdaddr_buf;
process(sysclk)
begin
if rising_edge(sysclk) then
    read_dur_en_d1 <= read_dur_en;
    uart_rx_rdaddr_buf_d1   <= uart_rx_rdaddr_buf;
    p_Addr_o                <= uart_rx_rdaddr_buf_d1;
    case pstate_rd is
        when rd_idle =>
            if frame_right = '1' then
                length_lock <= frame_length;
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
    p_Frame_en_o    <= read_dur_en;
    p_Wren_o        <= read_dur_en;

end if;
end process;
    p_Data_o        <= uart_rx_q;
    
    cmd2hdmi_i: uart_cmd_cross   
        port map(
            nRST             => nRST   ,
            sysclk           => sysclk ,
            uart_rx_wdata    => uart_rx_data ,
            uart_rx_wraddr   => uart_rx_wraddr, 
            uart_rx_wren     => uart_rx_wren  ,
            frm_len_i        => frame_length  ,
            done_notify_i    => frame_right   ,
        
        ---to reduce the clock domain in HDMI region 
            nRST_cmd         => nRST_cmd ,
            cmd_clk          => cmd_clk  ,   
            
            p_Frame_en_cmd    =>  p_Frame_en_cmd,
            p_Wren_cmd        =>  p_Wren_cmd    ,
            p_Data_cmd        =>  p_Data_cmd    ,
            p_Addr_cmd        =>  p_Addr_cmd   
            
        );
    
    
    ---2M 0X7A0
    --115200  32768= 0X8000  262us
    --
    -- rx_timeout_TH <= ("0"&X"07A0") when BAUD_DIV = X"003D" else ("0"&X"8000");
    rx_timeout_TH <= BAUD_DIV(12 downto 0)&"0000"; --4 * BAUD_DIV

process(nRST,SYSCLK)
begin
if nRST = '0' then
    rx_timeout <= (others=>'0');
    rx_timeout_flg <= '0';
elsif rising_edge(SYSCLK) then
    if rx_st = RX_IDLE then
         rx_timeout <= (others=>'0');
    elsif rxd_en = '1' then
         rx_timeout <= (others=>'0');
    else
        ---115200
        ---=8.6805555555555555555555555555556e-6
        ----8.6us*8=70us
        -- 100us for one word if baud = 115200
        ---256us 32768*8ns= 262,144
        if rx_timeout(16) ='0' then --8ns *65536=524,288ns=0.5ms
            rx_timeout <= rx_timeout + 1;
        end if;
    end if;

    if rx_timeout  > rx_timeout_TH then
        rx_timeout_flg <= '1';
    else
        rx_timeout_flg <= '0';
    end if;
end if;
end process;



uart_sdi_inst :  uart 
generic map(
	BAUD				=> BAUD_DIV(7 DOWNTO 0)
)
port map(
	nRST				=> nRST,
	sysclk				=> sysclk,
	                   
	uart_rxd			=> rxd_top,
	uart_txd			=> txd_top,
	         
	frame_ss			=> open,
	rx_data_vld			=> rxd_en_uart,
	rx_data				=> rxd_data_uart,
	             
	busy_en				=> tx_uart_busy,
	tx_data_vld			=> txd_en,
	tx_data				=> txd_data
);

end beha;