library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;



entity ddr3_check is
generic
(
  DDRB_RSTALL_EN  :  std_logic := '0';
  READ_RST_ONLY   :   STD_LOGIC ;
  ASYNC_MODE      :  STD_LOGIC := '0'; --DDR3 IS async mode or not , '1': async ,'0: sync
  READ_HIGH_PRIO  :  STD_LOGIC := '0';
  WRC_W           : integer := 48; --WRite command FIFO width
  RRC_W           : integer := 48 ;  --READ command  FIFO width  ;
  DDRA_W          : INTEGER := 23 ;
  DDRD_W          : INTEGER := 320;
  BURST_W         : INTEGER := 7;
  RD_TWO_BURST_SUPPROT: STD_LOGIC :='0'  ---NOT SUPPROTED YET
);
port
(
	ddr3_nRST		: in		std_logic;
	ddr3_clk		: in		std_logic;
	
	local_cal_success_flag		: in	std_logic;
	pll_locked_flag				: in	std_logic;
	ddr_verify_nrst				: in	std_logic;
	
	ddr3_pll_locked				: in	std_logic;
    local_cal_success			: in	std_logic; ----,   //           status.local_cal_success, When high, indicates that PHY calibration was successful
    local_cal_fail				: in	std_logic; ----,      //                 .local_cal_fail,    When high, indicates that PHY calibration failed
    amm_ready_0					: in	std_logic; ---- '1' : ready, '0': not ready,         //       ctrl_amm_0.waitrequest_n,     Wait-request is asserted when controller is busy
    amm_read_0_checker			: out	std_logic; ---- active high ,          //                 .read,              Read request signal
    amm_write_0_checker			: out	std_logic; ---- active high,         //                 .write,             Write request signal
    amm_address_0_checker		: out	std_logic_vector(DDRA_W-1 downto 0); --[22:0]    ; ----   ,       //                 .address,           Address for the read/write request
    check_amm_readdata_0		: in	std_logic_vector(DDRD_W-1 downto 0); --[319:0]   ; ----   ,      //                 .readdata,          Read data
    amm_writedata_0_checker		: out	std_logic_vector(DDRD_W-1 downto 0); -- [319:0]  ; ----   ,     //                 .writedata,         Write data
    amm_burstcount_0_checker	: out	std_logic_vector(BURST_W-1 DOWNTO 0); -- [6:0]    ; ----       ,    //                 .burstcount,        Number of transfers in each read/write burst
    amm_byteenable_0_checker	: out	std_logic_vector((DDRD_W/8)-1 Downto 0); -- [39:0]   ; ----       ,    //                 .byteenable,        Byte-enable for write data
    check_amm_readdatavalid_0	: in	std_logic;
	
	ddr_verify_end				: out	std_logic;
	ddr_verify_success			: out	std_logic;
	ddr3_check_done				: out	std_logic;
	verify_data_error_buf		: out	std_logic_vector(DDRD_W/8-1 downto 0);
	verify_data_error			: out	std_logic;
	step_error					: out	std_logic_vector(4 downto 0)
);

end ddr3_check;

architecture behav of ddr3_check is

constant pattern_0			: std_logic_vector(DDRD_W/8-1 downto 0)			:= (others => '0');
constant pattern_1			: std_logic_vector(DDRD_W/8-1 downto 0)			:= (others => '1');
constant pattern_3			: std_logic_vector(DDRD_W/8-1 downto 0)			:= X"3333333333";
constant pattern_5			: std_logic_vector(DDRD_W/8-1 downto 0)			:= X"5555555555";
constant pattern_a			: std_logic_vector(DDRD_W/8-1 downto 0)			:= X"aaaaaaaaaa";
constant pattern_c			: std_logic_vector(DDRD_W/8-1 downto 0)			:= X"cccccccccc";
constant pattern_f0			: std_logic_vector(DDRD_W/8-1 downto 0)			:= X"f0f0f0f0f0";
constant pattern_0f			: std_logic_vector(DDRD_W/8-1 downto 0)			:= X"0f0f0f0f0f";
constant pattern_ff00		: std_logic_vector(DDRD_W/8-1 downto 0)			:= X"00ff00ff00";
constant pattern_00ff		: std_logic_vector(DDRD_W/8-1 downto 0)			:= X"ff00ff00ff";
constant pattern_ffff0000	: std_logic_vector(DDRD_W/8-1 downto 0)			:= X"00ffff0000";
constant pattern_0000ffff	: std_logic_vector(DDRD_W/8-1 downto 0)			:= X"ff0000ffff";
constant pattern_ff00000000	: std_logic_vector(DDRD_W/8-1 downto 0)			:= X"ff00000000";
constant pattern_00ffffffff	: std_logic_vector(DDRD_W/8-1 downto 0)			:= X"00ffffffff";
constant pattern_half_0		: std_logic_vector(DDRD_W/8-1 downto 0)			:= X"fffff00000";
constant pattern_half_1		: std_logic_vector(DDRD_W/8-1 downto 0)			:= X"00000fffff";

type check_state is
(
	verify_b,
	verify_wr,
	verify_rd,
	verify_a
);

signal verify_data_temp		: std_logic_vector(DDRD_W-1 downto 0)		:=(others => '0');
signal verify_addr_temp		: std_logic_vector(DDRA_W-1 downto 0)		:=(others => '0');

signal pstate				: check_state	:= verify_b;
signal ddr_wr_vld_pre		: std_logic						:='0';
-- signal ddr_verify_end		: std_logic						:='0';
-- signal ddr_verify_success	: std_logic						:='0';
-- signal ddr3_check_done		: std_logic						:='0';

signal addr_cnt							: std_logic_vector(5 downto 0)		:=(others => '0');
signal burst_cnt						: std_logic_vector(BURST_W-1 downto 0)		:=(others => '0');
signal step_cnt							: std_logic_vector(3 downto 0)				:=(others => '0');
-- signal verify_data_buf					: std_logic_vector(7 downto 0)				:=(others => '0');
signal verify_data_error_buf1			: std_logic_vector(DDRD_W/8-1 downto 0)	:=(others => '0');
signal verify_data_error1				: std_logic			:='0';
-- signal step_error						: std_logic_vector(4 downto 0)		:=(others => '0');

signal burst_cnt_int	: integer;
signal addr_cnt_int		: integer;
signal step_cnt_int		: integer;

--ddr init
signal ddr_verify_nrst_buf				: std_logic_vector(3 downto 0);
signal ddr_verify_nrst_test					: std_logic;
-- signal local_cal_success_flag			: std_logic;
signal local_cal_fail_flag				: std_logic;
signal pll_locked_buf					: std_logic_vector(5 downto 0);
signal local_cal_success_buf			: std_logic_vector(5 downto 0);
signal local_cal_fail_buf				: std_logic_vector(5 downto 0);
-- signal pll_locked_flag					: std_logic;


signal write_flag			: std_logic			:='0';

-- fifo320
signal fifo_data						: std_logic_vector(319 downto 0)			:=(others => '0');
signal fifo_wrreq						: std_logic			:='0';
signal fifo_rdreq						: std_logic			:='0';
signal fifo_aclr						: std_logic			:='0';
signal fifo_full						: std_logic			:='0';
signal fifo_empty						: std_logic			:='0';
signal fifo_q							: std_logic_vector(319 downto 0)			:=(others => '0');



component fifo320 is
	port (
		data  : in  std_logic_vector(319 downto 0) := (others => 'X'); -- datain
		wrreq : in  std_logic                      := 'X';             -- wrreq
		rdreq : in  std_logic                      := 'X';             -- rdreq
		clock : in  std_logic                      := 'X';             -- clk
		aclr  : in  std_logic                      := 'X';             -- aclr
		q     : out std_logic_vector(319 downto 0);                    -- dataout
		full  : out std_logic;                                         -- full
		empty : out std_logic                                          -- empty
	);
end component fifo320;


-----------------------------------------------------------------------------------------------
begin

burst_cnt_int <= conv_integer(burst_cnt);
addr_cnt_int <= conv_integer(addr_cnt);
step_cnt_int <= conv_integer(step_cnt);


amm_writedata_0_checker <= verify_data_temp;
amm_address_0_checker <= verify_addr_temp;


process(ddr3_clk, ddr3_nRST)
begin
	if ddr3_nRST = '0' then
		pstate <= verify_b;
		ddr_verify_end <= '0';
		ddr_verify_success <= '0';
        ddr3_check_done <= '0';
		-- amm_writedata_0_checker <=(others=>'0');
        amm_write_0_checker <= '0';
		amm_read_0_checker <='0';
        -- amm_address_0_checker <=(others=>'0');
		amm_burstcount_0_checker <=(others=>'0');
        amm_byteenable_0_checker <=(others=>'0');
		verify_data_error_buf <= (others => '0');
		verify_data_error_buf1 <= (others => '0');
		verify_data_error <= '0';
		verify_data_error1 <= '0';
		burst_cnt <= (others => '0');
		addr_cnt <= (others => '0');
		step_cnt <= (others => '0');
		step_error <= (others => '0');
		ddr_wr_vld_pre <= '1';
		write_flag <= '0';
		fifo_aclr <= '0';
		
	elsif rising_edge(ddr3_clk) then

		amm_byteenable_0_checker <= (others => '1');
		-- amm_writedata_0_checker <= verify_data_temp;
		-- amm_address_0_checker <= verify_addr_temp;
		
		if ddr_verify_nrst = '0' then
		-- if ddr_verify_nrst_test = '0' then
			verify_data_error_buf <= (others => '0');
			verify_data_error_buf1 <= (others => '0');
		else
			if check_amm_readdatavalid_0 = '1' then
				for i in 0 to DDRD_W/8-1 loop
					if check_amm_readdata_0(i*8+7 downto i*8) = fifo_q(i*8+7 downto i*8) then
						verify_data_error_buf(i) <= '0';
						verify_data_error_buf1(i) <= '0';
					else
						verify_data_error_buf(i) <= '1';
						verify_data_error_buf1(i) <= '1';
					end if;
				end loop;
			else
				verify_data_error_buf <= (others => '0');
				verify_data_error_buf1 <= (others => '0');
			end if;		
		end if;
		

		if ddr_verify_nrst = '0' then
		-- if ddr_verify_nrst_test = '0' then
			pstate <= verify_b;
			ddr_verify_end <= '0';
			ddr_verify_success <= '0';
			verify_data_error <= '0';
			verify_data_error1 <= '0';
			ddr3_check_done <= '0';
			amm_write_0_checker <= '0';
			write_flag <= '0';
		    amm_read_0_checker <='0';
            -- amm_address_0_checker <=(others=>'0');
			burst_cnt <= (others => '0');
			step_cnt <= (others => '0');
			ddr_wr_vld_pre <= '1';
			step_error <= (others => '0');
			fifo_aclr <= '1';
			
		else
			fifo_aclr <= '0';
			
			case pstate is
				when verify_b =>
					if local_cal_success_flag = '1' and pll_locked_flag = '1' then
						pstate <= verify_wr;
						amm_write_0_checker <= '1';
						write_flag <= '1';
						burst_cnt <= burst_cnt + '1';
						-- step_cnt <= step_cnt + '1';
						ddr_wr_vld_pre <= '0';
					else
						pstate <= verify_b;
						amm_write_0_checker <= '0';
						write_flag <= '0';
						burst_cnt <= (others => '0');
						-- step_cnt <= (others => '0');
						ddr_wr_vld_pre <= '1';
					end if;
					 
					amm_read_0_checker <='0';
					amm_burstcount_0_checker <= conv_std_logic_vector(64,BURST_W);
					-- verify_data_buf <= conv_std_logic_vector(0,8-BURST_W)&burst_cnt;
					ddr_verify_end <= '0';
					ddr_verify_success <= '0';
					ddr3_check_done <= '0';
					-- burst_cnt <= (others => '0');
					step_cnt <= (others => '0');
				
				when verify_wr =>
					if burst_cnt(BURST_W-1) = '1' and amm_ready_0 = '1' then
						pstate <= verify_rd;
						burst_cnt <= (others => '0');
						amm_write_0_checker <= '0';
						write_flag <= '0';
						amm_read_0_checker <= '1';
					else
						pstate <= verify_wr;
						amm_write_0_checker <= '1';
						write_flag <= '1';
						amm_read_0_checker <= '0';
						if amm_ready_0 = '1' then
							burst_cnt <= burst_cnt + '1';
						end if;
						
					end if;
					
				when verify_rd =>
					if burst_cnt(BURST_W-1) = '1' then
						burst_cnt <= (others => '0');
						amm_read_0_checker <= '0';
					else
						
						if check_amm_readdatavalid_0 = '1' then
							burst_cnt <= burst_cnt + '1';
						end if;
						
						if amm_ready_0 = '1' then
							amm_read_0_checker <= '0';
						end if;
					end if;
					
					if step_cnt >= 4 then
						if addr_cnt >= DDRA_W-1 then
							pstate <= verify_a;
							step_cnt <= (others => '0');
							addr_cnt <= (others => '0');
						else 
							step_cnt <= step_cnt;
							if burst_cnt(BURST_W-1) = '1' then
								pstate <= verify_wr;
								addr_cnt <= addr_cnt + '1';
							else
								pstate <= verify_rd;
								addr_cnt <= addr_cnt;							
							end if;
						end if;
						
					else
						if burst_cnt(BURST_W-1) = '1' then
							pstate <= verify_wr;
							step_cnt <= step_cnt + '1';
						else
							pstate <= verify_rd;
							step_cnt <= step_cnt;
						end if;
						
					end if;
					
					if verify_data_error_buf1 > 0 then
						step_error(step_cnt_int) <= '1';
					end if;
					
					if verify_data_error_buf1 > 0 then
						verify_data_error <= '1';
						verify_data_error1 <= '1';
					end if;
				
				when verify_a =>
					pstate <= verify_a;
					ddr_verify_end <= '1';
					ddr_verify_success <= not verify_data_error1;
				    ddr3_check_done <= not verify_data_error1;
					
				when others =>
					pstate <= verify_a;
				
			end case;
		
		end if;
	
	end if;
	
end process;


fifo_wrreq <= '1' when write_flag = '1' and amm_ready_0 = '1' and fifo_full = '0' else '0';
fifo_rdreq <= '1' when check_amm_readdatavalid_0 = '1' and fifo_empty = '0' else '0';

fifo320_inst : fifo320
	port map (
		data  	=> verify_data_temp,
		wrreq 	=> fifo_wrreq,
		rdreq 	=> fifo_rdreq,
		clock 	=> ddr3_clk,
		aclr  	=> fifo_aclr,
		q     	=> fifo_q,
		full  	=> fifo_full,
		empty 	=> fifo_empty
	);




-- process(step_cnt, burst_cnt_int, burst_cnt, addr_cnt, verify_data_temp, verify_addr_temp)
process(ddr3_clk, ddr3_nRST)
begin
if ddr3_nRST = '0' then
	verify_addr_temp <= (others => '0');
	verify_data_temp <= (others => '0');
elsif rising_edge(ddr3_clk) then


	if step_cnt = 0 then
		verify_addr_temp <= (others => '0');
		verify_data_temp <= (others => '0');
		for i in 0 to DDRD_W/8-1 loop
			verify_data_temp(i*8+7 downto i*8) <= '0'&burst_cnt;
		end loop;

	elsif step_cnt = 1 then
		verify_addr_temp <= (others => '0');
		verify_data_temp <= (others => '0');
		for i in 0 to DDRD_W/8-1 loop
			verify_data_temp(i*8+7 downto i*8) <= not ('0'&burst_cnt);
		end loop;

	elsif step_cnt = 2 then
		verify_addr_temp <= (others => '0');
		verify_data_temp <= (others => '0');
		case burst_cnt_int is
			when 0|16|32|48 =>
				for i in 0 to DDRD_W/40-1 loop
					verify_data_temp(i*40+39 downto i*40) <= pattern_0;
				end loop;
				
			when 1|17|33|49 =>
				for i in 0 to DDRD_W/40-1 loop
					verify_data_temp(i*40+39 downto i*40) <= pattern_1;
				end loop;
				
			when 2|18|34|50 =>
				for i in 0 to DDRD_W/40-1 loop
					verify_data_temp(i*40+39 downto i*40) <= pattern_a;
				end loop;
				
			when 3|19|35|51 =>
				for i in 0 to DDRD_W/40-1 loop
					verify_data_temp(i*40+39 downto i*40) <= pattern_c;
				end loop;
				
			when 4|20|36|52 =>
				for i in 0 to DDRD_W/40-1 loop
					verify_data_temp(i*40+39 downto i*40) <= pattern_f0;
				end loop;
				
			when 5|21|37|53 =>
				for i in 0 to DDRD_W/40-1 loop
					verify_data_temp(i*40+39 downto i*40) <= pattern_ff00;
				end loop;
				
			when 6|22|38|54 =>
				for i in 0 to DDRD_W/40-1 loop
					verify_data_temp(i*40+39 downto i*40) <= pattern_ffff0000;
				end loop;
				
			when 7|23|39|55 =>
				for i in 0 to DDRD_W/40-1 loop
					verify_data_temp(i*40+39 downto i*40) <= pattern_ff00000000;
				end loop;
				
			when 8|24|40|56 =>
				for i in 0 to DDRD_W/40-1 loop
					verify_data_temp(i*40+39 downto i*40) <= pattern_5;
				end loop;
				
			when 9|25|41|57 =>
				for i in 0 to DDRD_W/40-1 loop
					verify_data_temp(i*40+39 downto i*40) <= pattern_3;
				end loop;
				
			when 10|26|42|58 =>
				for i in 0 to DDRD_W/40-1 loop
					verify_data_temp(i*40+39 downto i*40) <= pattern_0f;
				end loop;
				
			when 11|27|43|59 =>
				for i in 0 to DDRD_W/40-1 loop
					verify_data_temp(i*40+39 downto i*40) <= pattern_00ff;
				end loop;
				
			when 12|28|44|60 =>
				for i in 0 to DDRD_W/40-1 loop
					verify_data_temp(i*40+39 downto i*40) <= pattern_0000ffff;
				end loop;
				
			when 13|29|45|61 =>
				for i in 0 to DDRD_W/40-1 loop
					verify_data_temp(i*40+39 downto i*40) <= pattern_00ffffffff;
				end loop;
				
			when 14|30|46|62 => 
				for i in 0 to DDRD_W/40-1 loop
					verify_data_temp(i*40+39 downto i*40) <= pattern_half_0;
				end loop;
				
			when 15|31|47|63 => 
				for i in 0 to DDRD_W/40-1 loop
					verify_data_temp(i*40+39 downto i*40) <= pattern_half_1;
				end loop;

			when others => verify_data_temp <= (others => '0');
		end case;

	elsif step_cnt = 3 then
		verify_addr_temp <= (others => '0');
		verify_data_temp <= (others => '0');
		case burst_cnt_int is
			when 0|32 => 
				verify_data_temp(1*40-1 downto 0*40) <= pattern_0;
				verify_data_temp(2*40-1 downto 1*40) <= pattern_1;
				verify_data_temp(3*40-1 downto 2*40) <= pattern_a;
				verify_data_temp(4*40-1 downto 3*40) <= pattern_c;
				verify_data_temp(5*40-1 downto 4*40) <= pattern_f0;
				verify_data_temp(6*40-1 downto 5*40) <= pattern_ff00;
				verify_data_temp(7*40-1 downto 6*40) <= pattern_ffff0000;
				verify_data_temp(8*40-1 downto 7*40) <= pattern_ff00000000;
				
			when 1|33 => 
				verify_data_temp(1*40-1 downto 0*40) <= pattern_5;
				verify_data_temp(2*40-1 downto 1*40) <= pattern_3;
				verify_data_temp(3*40-1 downto 2*40) <= pattern_0f;
				verify_data_temp(4*40-1 downto 3*40) <= pattern_00ff;
				verify_data_temp(5*40-1 downto 4*40) <= pattern_0000ffff;
				verify_data_temp(6*40-1 downto 5*40) <= pattern_00ffffffff;
				verify_data_temp(7*40-1 downto 6*40) <= pattern_half_0;
				verify_data_temp(8*40-1 downto 7*40) <= pattern_half_1;
				
			when 2|34 =>
				verify_data_temp(1*40-1 downto 0*40) <= pattern_ff00000000;
				verify_data_temp(2*40-1 downto 1*40) <= pattern_ffff0000;
				verify_data_temp(3*40-1 downto 2*40) <= pattern_ff00;
				verify_data_temp(4*40-1 downto 3*40) <= pattern_f0;
				verify_data_temp(5*40-1 downto 4*40) <= pattern_c;
				verify_data_temp(6*40-1 downto 5*40) <= pattern_a;
				verify_data_temp(7*40-1 downto 6*40) <= pattern_1;
				verify_data_temp(8*40-1 downto 7*40) <= pattern_0;
				
			when 3|35 =>
				verify_data_temp(1*40-1 downto 0*40) <= pattern_half_1;
				verify_data_temp(2*40-1 downto 1*40) <= pattern_half_0;
				verify_data_temp(3*40-1 downto 2*40) <= pattern_00ffffffff;
				verify_data_temp(4*40-1 downto 3*40) <= pattern_0000ffff;
				verify_data_temp(5*40-1 downto 4*40) <= pattern_00ff;
				verify_data_temp(6*40-1 downto 5*40) <= pattern_0f;
				verify_data_temp(7*40-1 downto 6*40) <= pattern_3;
				verify_data_temp(8*40-1 downto 7*40) <= pattern_5;
				
			when 4|36 =>
				verify_data_temp(1*40-1 downto 0*40) <= pattern_0;
				verify_data_temp(2*40-1 downto 1*40) <= pattern_1;
				verify_data_temp(3*40-1 downto 2*40) <= pattern_a;
				verify_data_temp(4*40-1 downto 3*40) <= pattern_c;
				verify_data_temp(5*40-1 downto 4*40) <= pattern_0;
				verify_data_temp(6*40-1 downto 5*40) <= pattern_1;
				verify_data_temp(7*40-1 downto 6*40) <= pattern_a;
				verify_data_temp(8*40-1 downto 7*40) <= pattern_c;
				
			when 5|37 =>
				verify_data_temp(1*40-1 downto 0*40) <= pattern_f0;
				verify_data_temp(2*40-1 downto 1*40) <= pattern_ff00;
				verify_data_temp(3*40-1 downto 2*40) <= pattern_ffff0000;
				verify_data_temp(4*40-1 downto 3*40) <= pattern_ff00000000;
				verify_data_temp(5*40-1 downto 4*40) <= pattern_f0;
				verify_data_temp(6*40-1 downto 5*40) <= pattern_ff00;
				verify_data_temp(7*40-1 downto 6*40) <= pattern_ffff0000;
		        verify_data_temp(8*40-1 downto 7*40) <= pattern_ff00000000;
				
			when 6|38 =>
				verify_data_temp(1*40-1 downto 0*40) <= pattern_5;
				verify_data_temp(2*40-1 downto 1*40) <= pattern_3;
				verify_data_temp(3*40-1 downto 2*40) <= pattern_0f;
				verify_data_temp(4*40-1 downto 3*40) <= pattern_00ff;
				verify_data_temp(5*40-1 downto 4*40) <= pattern_5;
				verify_data_temp(6*40-1 downto 5*40) <= pattern_3;
				verify_data_temp(7*40-1 downto 6*40) <= pattern_0f;
		        verify_data_temp(8*40-1 downto 7*40) <= pattern_00ff;
				
			when 7|39 =>
				verify_data_temp(1*40-1 downto 0*40) <= pattern_0000ffff;
				verify_data_temp(2*40-1 downto 1*40) <= pattern_00ffffffff;
				verify_data_temp(3*40-1 downto 2*40) <= pattern_half_0;
				verify_data_temp(4*40-1 downto 3*40) <= pattern_half_1;
				verify_data_temp(5*40-1 downto 4*40) <= pattern_0000ffff;
				verify_data_temp(6*40-1 downto 5*40) <= pattern_00ffffffff;
				verify_data_temp(7*40-1 downto 6*40) <= pattern_half_0;
		        verify_data_temp(8*40-1 downto 7*40) <= pattern_half_1;
				
			when 8|40 =>
				verify_data_temp(1*40-1 downto 0*40) <= pattern_0;
				verify_data_temp(2*40-1 downto 1*40) <= pattern_1;
				verify_data_temp(3*40-1 downto 2*40) <= pattern_5;
				verify_data_temp(4*40-1 downto 3*40) <= pattern_3;
				verify_data_temp(5*40-1 downto 4*40) <= pattern_0;
				verify_data_temp(6*40-1 downto 5*40) <= pattern_1;
				verify_data_temp(7*40-1 downto 6*40) <= pattern_5;
		        verify_data_temp(8*40-1 downto 7*40) <= pattern_3;
				
			when 9|41 =>
				verify_data_temp(1*40-1 downto 0*40) <= pattern_a;
				verify_data_temp(2*40-1 downto 1*40) <= pattern_c;
				verify_data_temp(3*40-1 downto 2*40) <= pattern_0f;
				verify_data_temp(4*40-1 downto 3*40) <= pattern_00ff;
				verify_data_temp(5*40-1 downto 4*40) <= pattern_a;
				verify_data_temp(6*40-1 downto 5*40) <= pattern_c;
				verify_data_temp(7*40-1 downto 6*40) <= pattern_0f;
		        verify_data_temp(8*40-1 downto 7*40) <= pattern_00ff;
				
			when 10|42 =>
				verify_data_temp(1*40-1 downto 0*40) <= pattern_f0;
				verify_data_temp(2*40-1 downto 1*40) <= pattern_ff00;
				verify_data_temp(3*40-1 downto 2*40) <= pattern_0000ffff;
				verify_data_temp(4*40-1 downto 3*40) <= pattern_00ffffffff;
				verify_data_temp(5*40-1 downto 4*40) <= pattern_f0;
				verify_data_temp(6*40-1 downto 5*40) <= pattern_ff00;
				verify_data_temp(7*40-1 downto 6*40) <= pattern_0000ffff;
		        verify_data_temp(8*40-1 downto 7*40) <= pattern_00ffffffff;
				
			when 11|43 =>
				verify_data_temp(1*40-1 downto 0*40) <= pattern_ffff0000;
				verify_data_temp(2*40-1 downto 1*40) <= pattern_ff00000000;
				verify_data_temp(3*40-1 downto 2*40) <= pattern_half_0;
				verify_data_temp(4*40-1 downto 3*40) <= pattern_half_1;
				verify_data_temp(5*40-1 downto 4*40) <= pattern_ffff0000;
				verify_data_temp(6*40-1 downto 5*40) <= pattern_ff00000000;
				verify_data_temp(7*40-1 downto 6*40) <= pattern_half_0;
		        verify_data_temp(8*40-1 downto 7*40) <= pattern_half_1;
				
			when 12|44 =>
				verify_data_temp(1*40-1 downto 0*40) <= pattern_0;
				verify_data_temp(2*40-1 downto 1*40) <= pattern_f0;
				verify_data_temp(3*40-1 downto 2*40) <= pattern_5;
				verify_data_temp(4*40-1 downto 3*40) <= pattern_0000ffff;
				verify_data_temp(5*40-1 downto 4*40) <= pattern_0;
				verify_data_temp(6*40-1 downto 5*40) <= pattern_f0;
				verify_data_temp(7*40-1 downto 6*40) <= pattern_5;
				verify_data_temp(8*40-1 downto 7*40) <= pattern_0000ffff;
				
			when 13|45 =>
				verify_data_temp(1*40-1 downto 0*40) <= pattern_1;
				verify_data_temp(2*40-1 downto 1*40) <= pattern_f0;
				verify_data_temp(3*40-1 downto 2*40) <= pattern_3;
				verify_data_temp(4*40-1 downto 3*40) <= pattern_00ffffffff;
				verify_data_temp(5*40-1 downto 4*40) <= pattern_0;
				verify_data_temp(6*40-1 downto 5*40) <= pattern_f0;
				verify_data_temp(7*40-1 downto 6*40) <= pattern_3;
				verify_data_temp(8*40-1 downto 7*40) <= pattern_00ffffffff;
				
			when 14|46 =>
				verify_data_temp(1*40-1 downto 0*40) <= pattern_a;
				verify_data_temp(2*40-1 downto 1*40) <= pattern_ffff0000;
				verify_data_temp(3*40-1 downto 2*40) <= pattern_0f;
				verify_data_temp(4*40-1 downto 3*40) <= pattern_half_0;
				verify_data_temp(5*40-1 downto 4*40) <= pattern_0;
				verify_data_temp(6*40-1 downto 5*40) <= pattern_ffff0000;
				verify_data_temp(7*40-1 downto 6*40) <= pattern_0f;
				verify_data_temp(8*40-1 downto 7*40) <= pattern_half_0;
				
			when 15|47 =>
				verify_data_temp(1*40-1 downto 0*40) <= pattern_c;
				verify_data_temp(2*40-1 downto 1*40) <= pattern_ff00000000;
				verify_data_temp(3*40-1 downto 2*40) <= pattern_00ff;
				verify_data_temp(4*40-1 downto 3*40) <= pattern_half_1;
				verify_data_temp(5*40-1 downto 4*40) <= pattern_c;
				verify_data_temp(6*40-1 downto 5*40) <= pattern_ff00000000;
				verify_data_temp(7*40-1 downto 6*40) <= pattern_00ff;
				verify_data_temp(8*40-1 downto 7*40) <= pattern_half_1;
				
				
			when 16|48 =>
				for i in 0 to DDRD_W/40-1 loop
					verify_data_temp(i*40+39 downto i*40) <= pattern_0;
				end loop;
				
			when 17|49 =>
				for i in 0 to DDRD_W/40-1 loop
					verify_data_temp(i*40+39 downto i*40) <= pattern_1;
				end loop;
				
			when 18|50 => 
				for i in 0 to DDRD_W/40-1 loop
					verify_data_temp(i*40+39 downto i*40) <= pattern_a;
				end loop;
				
			when 19|51 =>
				for i in 0 to DDRD_W/40-1 loop
					verify_data_temp(i*40+39 downto i*40) <= pattern_c;
				end loop;
				
			when 20|52 =>
				for i in 0 to DDRD_W/40-1 loop
					verify_data_temp(i*40+39 downto i*40) <= pattern_f0;
				end loop;
				
			when 21|53 =>
				for i in 0 to DDRD_W/40-1 loop
					verify_data_temp(i*40+39 downto i*40) <= pattern_ff00;
				end loop;
				
			when 22|54 =>
				for i in 0 to DDRD_W/40-1 loop
					verify_data_temp(i*40+39 downto i*40) <= pattern_ffff0000;
				end loop;
				
			when 23|55 =>
				for i in 0 to DDRD_W/40-1 loop
					verify_data_temp(i*40+39 downto i*40) <= pattern_ff00000000;
				end loop;
				
			when 24|56 =>
				for i in 0 to DDRD_W/40-1 loop
					verify_data_temp(i*40+39 downto i*40) <= pattern_5;
				end loop;
				
			when 25|57 =>
				for i in 0 to DDRD_W/40-1 loop
					verify_data_temp(i*40+39 downto i*40) <= pattern_3;
				end loop;
				
			when 26|58 =>
				for i in 0 to DDRD_W/40-1 loop
					verify_data_temp(i*40+39 downto i*40) <= pattern_0f;
				end loop;
				
			when 27|59 =>
				for i in 0 to DDRD_W/40-1 loop
					verify_data_temp(i*40+39 downto i*40) <= pattern_00ff;
				end loop;
				
			when 28|60 =>
				for i in 0 to DDRD_W/40-1 loop
					verify_data_temp(i*40+39 downto i*40) <= pattern_0000ffff;
				end loop;
			
			when 29|61 =>
				for i in 0 to DDRD_W/40-1 loop
					verify_data_temp(i*40+39 downto i*40) <= pattern_00ffffffff;
				end loop;
				
			when 30|62 =>
				for i in 0 to DDRD_W/40-1 loop
					verify_data_temp(i*40+39 downto i*40) <= pattern_half_0;
				end loop;
				
			when 31|63 =>
				for i in 0 to DDRD_W/40-1 loop
					verify_data_temp(i*40+39 downto i*40) <= pattern_half_1;
				end loop;
				
			when others =>
				verify_data_temp <= (others => '0');
		end case;

	elsif step_cnt = 4 then
		if addr_cnt <= DDRA_W-1 then
			verify_data_temp <= (others => '0');
			verify_addr_temp <= (others => '0');
			verify_addr_temp(addr_cnt_int) <= '1';
			if burst_cnt <= 64-1 then
				verify_data_temp(1*40-1 downto 0*40) <= (verify_addr_temp + 1)&conv_std_logic_vector(0,40-DDRA_W);
				verify_data_temp(2*40-1 downto 1*40) <= (verify_addr_temp + 2)&conv_std_logic_vector(0,40-DDRA_W);
				verify_data_temp(3*40-1 downto 2*40) <= (verify_addr_temp + 3)&conv_std_logic_vector(0,40-DDRA_W);
				verify_data_temp(4*40-1 downto 3*40) <= (verify_addr_temp + 4)&conv_std_logic_vector(0,40-DDRA_W);
				verify_data_temp(5*40-1 downto 4*40) <= (verify_addr_temp + 5)&conv_std_logic_vector(0,40-DDRA_W);
				verify_data_temp(6*40-1 downto 5*40) <= (verify_addr_temp + 6)&conv_std_logic_vector(0,40-DDRA_W);
				verify_data_temp(7*40-1 downto 6*40) <= (verify_addr_temp + 7)&conv_std_logic_vector(0,40-DDRA_W);
				verify_data_temp(8*40-1 downto 7*40) <= (verify_addr_temp + 8)&conv_std_logic_vector(0,40-DDRA_W);
			else
				verify_data_temp <= (others => '0');
			end if;
		
		else
			verify_addr_temp <= (others => '0');
			verify_data_temp <= (others => '0');
		end if;
		
	end if;

end if;

end process;




-----------------------------------------------------------------------------------------------

end behav;