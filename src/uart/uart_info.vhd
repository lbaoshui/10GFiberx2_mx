

library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_arith.all ;
use ieee.std_logic_unsigned.all ;
use work.PCK_bk_serdes.all; 
use work.PCK_version_FPGA_def.all; 

entity uart_info is
generic
(
    CONS_VER_HIGH       : std_logic_vector(7  downto 0);
    CONS_VER_LOW        : std_logic_vector(7  downto 0);
    TXSUBCARD_TYPE      : std_logic_vector(7  downto 0);
    FIBERPORT_NUM       : integer; --FIBER PORT NUM 
    ETHPORT_NUM         : integer; --ETH PORT PER FIBER  
    SERDES_SPEED_MSB    : integer;
    SERDES_SPEED_LSB    : integer;
    BAUD_DIV            : std_logic_vector(15 downto 0);
    -- TEST_USE_FIBER      : std_logic := '1'  --- '0':  return 5G , '1':REUTRN 10G 
    TEST_USE_FIBER      : std_logic := '1'  ;--- '0':  return 5G , '1':REUTRN 10G 
	DDR_NUM             : integer
);
port
(
    nRST                : in std_logic ;
    sysclk              : in std_logic ;
	time_ms_en_sys      : in std_logic ;
    txd_info_top        : out std_logic ; ---to top pad
    eth_link            : in std_logic_vector(FIBERPORT_NUM*ETHPORT_NUM-1 downto 0);
    fiber_link          : in std_logic_vector(FIBERPORT_NUM-1 downto 0);
   
    autobright_en       : in std_logic_vector(FIBERPORT_NUM*ETHPORT_NUM-1 downto 0);
    autobright_val      : in std_logic_vector(FIBERPORT_NUM*ETHPORT_NUM*8-1 downto 0);
	
	get_curr_temp_phy_sys : in std_logic_vector(FIBERPORT_NUM*16-1 downto 0);
  
    err_num_fiber       : in std_logic_vector(63 downto 0);
    err_num             : in std_logic_vector(63 downto 0);
    crc_info            : in std_logic_vector(7 downto 0) ;
	
	backup_flag_sys         : in std_logic_vector(3 downto 0);
	error_check_num_sys     : in std_logic_vector(4*16-1 downto 0);
	subbrdin_packet_cnt_sys : in std_logic_vector(4*32-1 downto 0);
	error_fe_num_sys        : in std_logic_vector(4*16-1 downto 0);
	serdes_rxlock           : in std_logic_vector(3 downto 0);
	real_eth_num_sys		: in std_logic_vector(3 downto 0);
	ddr_verify_end_sys       : in std_logic_vector(DDR_NUM-1 downto 0);
	ddr_verify_success_sys   : in std_logic_vector(DDR_NUM-1 downto 0)
);
end uart_info ;

architecture beha of uart_info IS

component temperature is
    port (
        corectl : in  std_logic                    := 'X'; -- corectl
        reset   : in  std_logic                    := 'X';
        tempout : out std_logic_vector(9 downto 0);        -- tempout
        eoc     : out std_logic                            -- eoc
    );
end component temperature;
signal temper : std_logic_vector(9 downto 0);
signal temper_d1 : std_logic_vector(9 downto 0);
signal temper_d2 : std_logic_vector(9 downto 0);
signal temper_out : std_logic_vector(9 downto 0);
signal temper_eoc_falling : std_logic;
signal temper_eoc_d1 : std_logic;
signal temper_eoc_d2 : std_logic;
signal temper_eoc_d3 : std_logic;
signal temper_eoc_d4 : std_logic;
signal temper_eoc : std_logic;
signal tem_rst : std_logic;

signal tx_uart_busy    : std_logic;
signal txd_en          : std_logic;
signal txd_data        : std_logic_vector(7 downto 0);

signal rxd_data        : std_logic_vector(7 downto 0);
signal rxd_en          : std_logic;

signal fwd_cnt         : std_logic_vector(11 downto 0);
signal tx_cnt             : std_logic_vector(3 downto 0);

signal uart_rdaddr     : std_logic_vector(11 downto 0);
signal uart_q          : std_logic_vector(7 downto 0);

-- component txmit is
-- generic
-- (
    -- BAUD       : std_logic_vector(15 downto 0):=X"000B"
-- );
-- port (
    -- nRST        : in std_logic ;
    -- sysclk      : in std_logic;

    -- uart_busy   : out std_logic;
    -- wr_uart_en  : in std_logic ;
    -- din         : in std_logic_vector(7 downto 0) ;
    -- txd         : out std_logic ---to FPGA pin
-- ) ;
-- end component ;

component uart_tx is
generic(
	BAUD						: std_logic_vector(7 downto 0):= x"20"
);
port(
	nRST						: in  std_logic;
	sysclk						: in  std_logic;
	
	uart_txd					: out std_logic;
	
	busy_en						: out std_logic;
	tx_data_vld					: in  std_logic;
	tx_data						: in  std_logic_vector(7 downto 0)
);
end component;


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

signal err_num_d1 : std_logic_vector(63 downto 0);
signal err_num_d2 : std_logic_vector(63 downto 0);
signal err_num_d3 : std_logic_vector(63 downto 0);
signal err_num_fiber_d1 : std_logic_vector(63 downto 0);
signal err_num_fiber_d2 : std_logic_vector(63 downto 0);
signal err_num_fiber_d3 : std_logic_vector(63 downto 0);
signal eth_link_d1 : std_logic_vector(FIBERPORT_NUM*ETHPORT_NUM-1 downto 0);
signal eth_link_d2 : std_logic_vector(FIBERPORT_NUM*ETHPORT_NUM-1 downto 0);
signal eth_link_d3 : std_logic_vector(FIBERPORT_NUM*ETHPORT_NUM-1 downto 0);
signal slv_fwd_req : std_logic := '0';
signal slv_fwd_len : std_logic_vector(11 downto 0);
signal CODE_SIZE : std_logic_vector(15 downto 0);
signal CODE_START_ADDR : std_logic_vector(15 downto 0);
signal CODE_SIZE_ADD : std_logic_vector(7 downto 0);
signal time_out : std_logic_vector(12 downto 0);
signal FRAME_TIME_GAP : std_logic_vector(12 downto 0);
signal clr_status     : std_logic_vector(FIBERPORT_NUM-1 downto 0):=(others=>'0');
signal eth_status     : std_logic_vector(FIBERPORT_NUM*ETHPORT_NUM-1 downto 0):=(others=>'0');
signal timeout        : std_logic_vector(FIBERPORT_NUM*4-1 downto 0):=(others=>'0');
signal fiber_status_upload : std_logic_vector(FIBERPORT_NUM-1 downto 0):=(others=>'0');
signal time_1s_en          : std_logic :='0';
signal time1s_cnt          : std_logic_vector(10 downto 0):=(others=>'0');
signal fiber_status_d1     : std_logic_vector(FIBERPORT_NUM-1 downto 0):=(others=>'0');
signal fiber_status_d2     : std_logic_vector(FIBERPORT_NUM-1 downto 0):=(others=>'0');

signal serdes_rxlock_d1     : std_logic_vector(3 downto 0):=(others=>'0');
signal serdes_rxlock_sys    : std_logic_vector(3 downto 0):=(others=>'0');
signal temper_buf0 : std_logic_vector(9 downto 0);
signal temper_buf1 : std_logic_vector(19 downto 0);
signal temper_buf2 : std_logic_vector(9 downto 0);
signal checksum    : std_logic_vector(7 downto 0);
signal FPGA_ALTERA         : std_logic_vector(7 downto 0); 



begin

CODE_SIZE     <= conv_std_logic_vector(253,16);
CODE_START_ADDR <= conv_std_logic_vector(0,16);

CODE_SIZE_ADD <=
			-- fiber pcb1.0 FPGA027, MT flash
				 conv_std_logic_vector(32,8)  when (MX_FLASH_EN = 0 and FPGA032_EN= 0 and TXSUBCARD_TYPE = SUBCARD_1G_FIBER )			--X"80",	10G fiber*2
            else conv_std_logic_vector( 4,8)  when (MX_FLASH_EN = 0 and FPGA032_EN= 0 and TXSUBCARD_TYPE = SUBCARD_FIBERx4 )			--X"87",	10G fiber*4
            else conv_std_logic_vector(0,8)   when (MX_FLASH_EN = 0 and FPGA032_EN= 0 and TXSUBCARD_TYPE = SUBCARD_5G_TX )				--X"83",	5G ETH*4
			-- fiber pcb1.0 FPGA032, MT flash
			else conv_std_logic_vector(45,8)  when (MX_FLASH_EN = 0 and FPGA032_EN= 1 and TXSUBCARD_TYPE = SUBCARD_1G_FIBER )			--X"80",	10G fiber*2
			else conv_std_logic_vector(46,8)  when (MX_FLASH_EN = 0 and FPGA032_EN= 1 and TXSUBCARD_TYPE = SUBCARD_5G_TX )				--X"83",	5G ETH*4
			else conv_std_logic_vector(48,8)  when (MX_FLASH_EN = 0 and FPGA032_EN= 1 and TXSUBCARD_TYPE = SUBCARD_FIBERx4)				--X"87",	10G fiber*4
			-- fiber pcb3.0 FPGA032, MX flash
			else conv_std_logic_vector(1,8)  when (MX_FLASH_EN = 1 and FPGA032_EN= 1 and TXSUBCARD_TYPE = SUBCARD_1G_FIBER)				--X"80",	10G fiber*2
			else conv_std_logic_vector(2,8)  when (MX_FLASH_EN = 1 and FPGA032_EN= 1 and TXSUBCARD_TYPE = SUBCARD_5G_TX)				--X"83",	5G ETH*4
			else conv_std_logic_vector(3,8)  when (MX_FLASH_EN = 1 and FPGA032_EN= 1 and TXSUBCARD_TYPE = SUBCARD_5G_FIBERx4)			--X"85",	5G fiber*4
			else conv_std_logic_vector(8,8)  when (MX_FLASH_EN = 1 and FPGA032_EN= 1 and TXSUBCARD_TYPE = SUBCARD_FIBERx4)				--X"87",	10G fiber*4
			else conv_std_logic_vector(5,8)  when (MX_FLASH_EN = 1 and FPGA032_EN= 1 and TXSUBCARD_TYPE = SUBCARD_FIBERx2_to_ETHx8orx4)	--X"86",	10G_fiber*2_to_eth*8
			else conv_std_logic_vector(32,8) ;

FPGA_ALTERA     <= ALTERA_027 when FPGA032_EN=0 else ALTERA_032;

------------------------------------------------------------------
process(nRST,sysclk)
begin
	if nRST = '0' then
		time_1s_en <='0';
		time1s_cnt <=(others=>'0');
	elsif rising_edge(sysclk) then--1024ms
		if time1s_cnt(10) = '1' then
			time1s_cnt <=(others =>'0');
		elsif time_ms_en_sys = '1' then
			time1s_cnt <= time1s_cnt + 1;
		end if;
		
		if time1s_cnt(10)= '1' then
			time_1s_en <='1';
		else
			time_1s_en <= '0';
		end if;
	end if;
end process;

process(sysclk)
begin
if rising_edge(sysclk) then
    err_num_d1 <= err_num;
    err_num_d2 <= err_num_d1;
    err_num_d3 <= err_num_d2;
    err_num_fiber_d1 <= err_num_fiber;
    err_num_fiber_d2 <= err_num_fiber_d1;
    err_num_fiber_d3 <= err_num_fiber_d2;
    eth_link_d1 <= eth_link;
    eth_link_d2 <= eth_link_d1;
	fiber_status_d1 <= fiber_link;
	fiber_status_d2 <= fiber_status_d1;
	
	serdes_rxlock_d1  <= serdes_rxlock;
	serdes_rxlock_sys <= serdes_rxlock_d1;
	
			
	for i in 0 to FIBERPORT_NUM-1 loop
		if clr_status(i)= '1' then
			eth_status((i+1)*ETHPORT_NUM-1 downto i*ETHPORT_NUM) <=(others=>'0');
		else
			eth_status((i+1)*ETHPORT_NUM-1 downto i*ETHPORT_NUM) <= eth_link_d2((i+1)*ETHPORT_NUM-1 downto i*ETHPORT_NUM);
		end if;
	end loop;	
	
	for i in 0 to FIBERPORT_NUM-1 loop

		if fiber_status_d2(i) = '1' then
			fiber_status_upload (i)<='1';
		elsif clr_status(i) = '1' then
			fiber_status_upload (i)<='0';
		end if;
		
		if fiber_status_d2(i) = '1' then
			timeout((i+1)*4-1 downto i*4) <=(others =>'0');
			clr_status(i) <='0';
		elsif time_1s_en = '1' then
			if timeout((i+1)*4-1 downto i*4) = 9 then
				clr_status(i) <='1';
			else
				timeout((i+1)*4-1 downto i*4) <=timeout((i+1)*4-1 downto i*4)+1;
				clr_status(i) <='0';
			end if;
		end if;
	end loop;

	if uart_rdaddr < 63 then
    case uart_rdaddr(7 downto 0) is
        -- sharing info
        when X"00" => uart_q <= slv_fwd_len(7 downto 0);
        when X"01" => uart_q <=X"0"&slv_fwd_len(11 downto 8);
        when X"04" => uart_q <= X"01";
        when X"06" => uart_q <= ALTERA_FPGA;
        when X"07" => uart_q <= FPGA_ALTERA;
		
        when X"08" => uart_q <= TXSUBCARD_TYPE;
        when X"0A" => uart_q <= CONS_VER_LOW;
        when X"0B" => uart_q <= CONS_VER_HIGH;
        when X"0c" => uart_q <= CODE_SIZE(7 downto 0);
        when X"0d" => uart_q <= CODE_SIZE(15 downto 8);
        when X"0e" => uart_q <= CODE_SIZE_ADD;
        when X"0F" => uart_q <= CODE_START_ADDR(7 downto 0);
        when X"10" => uart_q <= CODE_START_ADDR(15 downto 8);
        when X"11" =>
				uart_q(5 downto 0) <= crc_info(5 downto 0);
				if MX_FLASH_EN = 1 then
					uart_q(7 downto 6) <=  "01";				-- MX_Flash
				else
					uart_q(7 downto 6) <=  "00";				-- MT_Flash
				end if;
				
        when X"12" => uart_q <= temper_out(7 downto 0);
        when X"13" => uart_q <= "100000"&temper_out(9 downto 8);
		when X"14" =>
		            if FPGA032_EN = 0 then
						uart_q <= conv_std_logic_vector(0,8);
					else
						if MX_FLASH_EN = 1 then
							uart_q <= conv_std_logic_vector(2,8);		-- pcb3.0
						else
							uart_q <= conv_std_logic_vector(1,8);		-- pcb2.0
						end if;
					end if;
		
		when X"1D" => 
					if DDR_NUM = 1 then
						uart_q(7)          <= ddr_verify_end_sys(0);
						uart_q(6 downto 1) <= (others=>'0');
						uart_q(0)          <=ddr_verify_success_sys(0);
					elsif DDR_NUM = 2 then
						if ddr_verify_end_sys(1 downto 0)="11" then
							uart_q(7)  <= '1';
						else
							uart_q(7)  <= '0';
						end if;
						uart_q(6 downto 2) <= (others=>'0');
						uart_q(1 downto 0)          <=ddr_verify_success_sys(1 downto 0);
					else---DDR_NUM = 3
						if ddr_verify_end_sys(2 downto 0)="111" then
							uart_q(7)  <= '1';
						else
							uart_q(7)  <= '0';
						end if;
						uart_q(6 downto 3) <= (others=>'0');
						uart_q(2 downto 0)          <=ddr_verify_success_sys(2 downto 0);	
					end if;
        -- own info
	
        when X"20" => 
			if TEST_USE_FIBER = '1' THEN 
				uart_q <= conv_std_logic_vector(2 ,8);
			else 
				uart_q <= conv_std_logic_vector(FIBERPORT_NUM,8);
			end if;
        when X"21" =>  uart_q <= X"0"&real_eth_num_sys; 
        when X"22" =>  
			uart_q <= (others=>'0');  
			uart_q(1) <= '1';  ----param serdes
			uart_q(0) <= '1';-----support rcv card area not eth area
        when X"23" =>
				uart_q(7) <= '0';---reserved
				uart_q(6) <= '1';---support single eth 0~5G
				uart_q(5) <= '0';----support single eth fix 5G
				uart_q(4) <= '1';----support single eth fix 1G
				uart_q(3) <= '0';---support physical backup_flag_sys
				if real_eth_num_sys = 10 then
					uart_q(2 downto 0) <= "000";
				elsif real_eth_num_sys = 4 then
					uart_q(2 downto 0) <= "100";
				else
					uart_q(2 downto 0) <= "000";
				end if;
			   
        when X"24" => uart_q <= conv_std_logic_vector(SERDES_SPEED_LSB,8);
        when X"25" => uart_q <= conv_std_logic_vector(SERDES_SPEED_MSB,8);
        when X"26" => uart_q <= "000000"&fiber_status_upload;
        when X"28" => uart_q <= eth_status(7 downto 0);
        when X"29" => uart_q <= "000000"&eth_status(ETHPORT_NUM-1 downto 8);
        when X"2A" => uart_q <= eth_status(17 downto ETHPORT_NUM);
        when X"2B" => uart_q <= "000000"&eth_status(ETHPORT_NUM*FIBERPORT_NUM-1 downto 18);	
		when X"30" => uart_q <= X"10";						-- min gap 16us
		when X"31" =>
				uart_q(7) <= '1';							-- download calib coef enable
				uart_q(6 downto 0) <= (others => '0');
		when X"32" => uart_q <= (others => '0');
		when X"33" => uart_q <= (others => '0');			-- read back calib coef disable
		when X"3D" => uart_q <= (0=>'1',others=>'0');
		when X"3E" => uart_q <= X"04";----bk to every subbordout serdes num
        when others=> uart_q <= (others=>'0');
		end case;
	elsif uart_rdaddr > 62 and uart_rdaddr < 99 then
		for i in 0 to 3 loop
			if uart_rdaddr = 63+i*9 then
				uart_q <= "0000000"&serdes_rxlock_sys(i);
			elsif uart_rdaddr = 64+i*9 then
				uart_q <= subbrdin_packet_cnt_sys((i+1)*32-24-1 downto i*32);
			elsif uart_rdaddr = 65+i*9 then
				uart_q <= subbrdin_packet_cnt_sys((i+1)*32-16-1 downto i*32+8);
			elsif uart_rdaddr = 66+i*9 then
				uart_q <= subbrdin_packet_cnt_sys((i+1)*32-8-1 downto i*32+16);
			elsif uart_rdaddr = 67+i*9 then
				uart_q <= subbrdin_packet_cnt_sys((i+1)*32-1 downto i*32+24);
			elsif uart_rdaddr = 68+i*9 then
				uart_q <= error_fe_num_sys((i+1)*16-8-1 downto i*16);
			elsif uart_rdaddr = 69+i*9 then
				uart_q <= error_fe_num_sys((i+1)*16-1 downto i*16+8);
			elsif uart_rdaddr = 70+i*9 then
				uart_q <= error_check_num_sys((i+1)*16-8-1 downto i*16);
			elsif uart_rdaddr = 71+i*9 then
				uart_q <= error_check_num_sys((i+1)*16-1 downto i*16+8);
			end if;
		end loop;
    
    elsif uart_rdaddr >=99 and uart_rdaddr < 99 + 40*2 then ---autobright uploading ---
        if uart_rdaddr < 99 + FIBERPORT_NUM*ETHPORT_NUM*2 then 
                for i in 0 to FIBERPORT_NUM*ETHPORT_NUM-1 loop
                    if uart_rdaddr = 99 + i*2 then
                            uart_q <= "0000000"&autobright_en(i);               
                    elsif uart_rdaddr = 99 + i*2 +1 then 
                            uart_q <= autobright_val( (i +1)*8-1 downto i*8); 
                    end if;
                end loop;
        else 
              uart_q <= (others=>'0');
        end if;
	elsif uart_rdaddr = 99 + 40 *2  then
		uart_q <= checksum;
	end if;
end if;
end process;
slv_fwd_len <= x"064"+40*2; --additional 80 bytes for autobright uploading 
FRAME_TIME_GAP  <= BAUD_DIV(7 downto 0)&"00000";
process(nRST,SYSCLK)
begin
    if nRST = '0' then
        pstate       <= idle;
        fwd_cnt      <= (others => '0');
        tx_cnt       <= (others => '0');
        txd_en       <= '0';
        txd_data     <= (others => '0');
        time_out <= (others => '0');
		checksum     <= (others => '0');
    elsif rising_edge(SYSCLK) then
        case pstate is
            when idle =>
                if time_out = FRAME_TIME_GAP then
                    pstate <= uart_fwd;
                    time_out <= (others=>'0');
                else
                    time_out <= time_out + '1';
                end if;
                fwd_cnt      <= (others => '0');
                txd_data     <= (others => '0');
                tx_cnt       <= (others => '0');
                txd_en       <= '0';
				checksum     <= (others => '0');

            when uart_fwd =>
                fwd_cnt <= fwd_cnt + '1';
                uart_rdaddr <= fwd_cnt;----(7 downto 0) ;-----+ 5;
                if fwd_cnt >= slv_fwd_len then
                    pstate <= idle;
                else
                    pstate <= get_data_w1;
                end if;
                tx_cnt <= (others => '0');
            when get_data_w1 =>
                pstate      <= get_data_w2;
            when get_data_w2 =>
                pstate <= get_data;
            when get_data =>
                pstate   <= tx_busy_w;
                txd_en   <= '1';
                txd_data <= uart_q;
				checksum <= checksum + uart_q;
            when tx_busy_w =>
                txd_en <= '0';
                if tx_cnt(3) = '0' then
                    tx_cnt <= tx_cnt + '1';
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

-- uart_info_inst: txmit
-- generic map(
    -- BAUD         => BAUD_DIV
-- )
-- PORT map(
    -- nRST        => nRST,
    -- sysclk      => SYSCLK,

    -- uart_busy   => tx_uart_busy,
    -- wr_uart_en  => txd_en,
    -- din         => txd_data,
    -- txd         => txd_info_top
-- );

uart_info_inst : uart_tx
generic map(
	BAUD				=> BAUD_DIV(7 DOWNTO 0)
)
port map(
	nRST						=> nRST,
	sysclk						=> SYSCLK,
	                            
	uart_txd					=> txd_info_top,
	                            
	busy_en						=> tx_uart_busy,
	tx_data_vld					=> txd_en,
	tx_data						=> txd_data
);

tem_rst <= not nRST;
temperature_inst : temperature
    port map (
        corectl => '1', -- corectl.corectl
        reset   => tem_rst,
        tempout => temper, -- tempout.tempout
        eoc     => temper_eoc      --     eoc.eoc
    );
    
    


process(SYSCLK)
begin
if rising_Edge(SYSCLK) then
    temper_eoc_d1 <= temper_eoc;
    temper_eoc_d2 <= temper_eoc_d1;
    temper_eoc_d3 <= temper_eoc_d2;
    temper_eoc_d4 <= temper_eoc_d3;
    temper_d1 <= temper;
    temper_d2 <= temper_d1;
    if temper_eoc_d3 = '0' and temper_eoc_d4 = '1' then
        temper_eoc_falling <= '1';
    else
        temper_eoc_falling <= '0';
    end if;
    if temper_eoc_falling = '1' then
        temper_out <= temper_d2;
    end if;
	-- temper_buf1<= conv_std_logic_vector(CONV_INTEGER(temper_buf0)*693,20);  
	
	-- if temper_buf1(9 downto 0)=0 then 
		-- temper_out<=temper_buf1(19 downto 10)-265;
	-- else
		-- temper_out<=temper_buf1(19 downto 10)-265+1;
	-- end if ;	
	
	
end if;
end process;

end beha;
