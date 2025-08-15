library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity config_phy is
generic(
	-- config_rdaddr_init	: std_logic_vector(23 downto 0) := X"220000";--ecp5 program occupy 0 to B0000
	config_rdaddr_init	: std_logic_vector(24 downto 0) := '1'&X"FB0000";--ecp5 program occupy 0 to B0000
	config_rdlen_init	: std_logic_vector(12 downto 0) := '0'&X"200";--read 512 Byte every time
	-- phya_phyaddr		: std_logic_vector(4 downto 0) := "01100";
	-- phyb_phyaddr		: std_logic_vector(4 downto 0) := "01101"
    phya_phyaddr		: std_logic_vector(4 downto 0) := "01110";
	phyb_phyaddr		: std_logic_vector(4 downto 0) := "01111"
	);
port(
	nRST					: in std_logic;
	SYSCLK					: in std_logic;
    test                    : out std_logic;

	time_ms_en				: in std_logic ;

	config_rdack			: in std_logic;
	config_rdreq			: out std_logic;
	config_rdaddr		    : out std_logic_vector(24 downto 0);
	config_rdlen		    : out std_logic_vector(12 downto 0);

	flash_dpram_data    	: in std_logic_vector(31 downto 0);
	flash_dpram_wraddr      : in std_logic_vector(8 downto 0);
	flash_dpram_wren     	: in std_logic;

	phy_rsta_done			: in std_logic;

	phy0_mdc				: out std_logic;
	phy0_mdin				: in std_logic;
	phy0_mdout				: out std_logic;
	phy0_mdir				: out std_logic

);
end entity;

architecture behav of config_phy is

signal check_load_a				:std_logic_vector(15 downto 0);
signal check_load_b				:std_logic_vector(15 downto 0);
signal cnt_load 				: std_logic_vector(3 downto 0);

component eth_Man is
port(

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
end component;


signal phy_phyaddr		: std_logic_vector(4 downto 0);
signal phy_rdwren		: std_logic; -- '0' : read , '1': write
signal phy_waddren		: std_logic;--new
signal phy_devaddr		: std_logic_vector(4 downto 0);
signal phy_rdata		: std_logic_vector(15 downto 0);
signal phy_wdata		: std_logic_vector(15 downto 0);
signal phy_rdata_buf	: std_logic_vector(15 downto 0);
signal phy_rvld			: std_logic;
signal phy_req	 		: std_logic;
signal phy_ack	 		: std_logic;

signal rdwren			: std_logic;
signal waddren			: std_logic;

signal devaddr			: std_logic_vector(4 downto 0);
signal wdata			: std_logic_vector(15 downto 0):=(others=>'0');
signal phyaddr			: std_logic_vector(4 downto 0);
signal phy_mdout 		: std_logic;
signal phy_mdir  		: std_logic;
signal phy_mdin  		: std_logic;


component flash_config_dpram is
port (
	data      : in  std_logic_vector(31 downto 0) := (others => 'X'); -- datain
	q         : out std_logic_vector(31 downto 0);                    -- dataout
	wraddress : in  std_logic_vector(8 downto 0)  := (others => 'X'); -- wraddress
	rdaddress : in  std_logic_vector(8 downto 0)  := (others => 'X'); -- rdaddress
	wren      : in  std_logic                     := 'X';             -- wren
	clock     : in  std_logic                     := 'X'
);
end component flash_config_dpram;

signal RST				 		: std_logic;
signal flash_dpram_rdaddr		:std_logic_vector(8 downto 0);
signal flash_dpram_q	 		:std_logic_vector(31 downto 0);
signal addr_cnt			 		:std_logic_vector(1 downto 0 );

signal reset_wait_1s	 		:std_logic_vector(9 downto 0);
signal step		  				:std_logic_vector(2 downto 0);
signal config_rdreq_buf			:std_logic :='0';
signal cnt						:std_logic_vector(6 downto 0);
signal cnt_wait					:std_logic_vector(7 downto 0);
signal op_is_action				:std_logic;
signal flash_addr_cnt  			:std_logic_vector (9 downto 0);
signal dpram_addr_cnt 			:std_logic_vector(6 downto 0);
signal fw_data					:std_logic_vector(31 downto 0);
signal cnt_max					:std_logic_vector(5 downto 0);
signal cnt_max1					:std_logic_vector(6 downto 0 );
signal wr_step					:std_logic_vector(3 downto 0 );
signal check_step				:std_logic_vector(2 downto 0 );
signal timeout					:std_logic_vector(11 downto 0);
signal rd_cnt					:std_logic_vector(2 downto 0);
signal config_rdlen_buf			:std_logic_vector(12 downto 0);
signal config_rdaddr_buf		:std_logic_vector(24 downto 0);
signal fw_success				:std_logic_vector(1 downto 0);
signal load_agian				:std_logic;

type state is(idle,op_start,op_dur,wait_ms,req_rdflash,wait_rdack,rddpram,upload_fw,
check,rd_status,wr_command,wr_data,rd_data,finish,reset);
signal pstate: state := idle;

signal flash_dpram_wren_vector 	: std_logic_vector(0 downto 0);

signal crc						:std_logic_vector(7 downto 0);

signal rd_step1					: std_logic_vector(3 downto 0);
signal rd_step2					: std_logic_vector(3 downto 0);
signal wr_step1					: std_logic_vector(3 downto 0);
signal get_XFI_2P5G_mode_a		: std_logic_vector(15 downto 0);
signal get_XFI_2P5G_mode_b		: std_logic_vector(15 downto 0);
signal status					: std_logic_vector(15 downto 0);
signal cmd_status				: std_logic_vector(15 downto 0);
signal cmd_succ_or_fail			: std_logic_vector(15 downto 0);
signal select_cmd				: std_logic;
signal get_eee_mode				: std_logic_vector(15 downto 0);
signal wait_cmd					: std_logic_vector(11 downto 0);
signal read_pre					: std_logic;
signal cmd_reg					: std_logic_vector(15 downto 0);
signal get_curr_temp			: std_logic_vector(15 downto 0);
signal get_curr_vol				: std_logic_vector(15 downto 0);

signal wr_step2 				: std_logic_vector(2 downto 0);
signal set_XFI_2P5G_mode		: std_logic_vector(15 downto 0);

signal sreset_step				: std_logic_vector(7 downto 0);
signal sreset_wait				: std_logic_vector(1 downto 0);
signal dev1_value				: std_logic_vector(15 downto 0);
signal dev3_value				: std_logic_vector(15 downto 0);
signal succ1   					: std_logic;
signal succ3					: std_logic;
signal r_step					: std_logic_vector(2 downto 0);
signal wait_cmd1				: std_logic_vector(11 downto 0);
signal fi_step					: std_logic_vector(3 downto 0);
signal mac_copper_status_a		: std_logic_vector(15 downto 0);
signal mac_copper_status_b		: std_logic_vector(15 downto 0);
signal fi_wait					: std_logic_vector(7 downto 0);
signal re_step					: std_logic_vector(3 downto 0);
signal re_wait					: std_logic_vector(11 downto 0);
signal an_reg					: std_logic_vector(15 downto 0);

signal check_flg  				: std_logic;
signal reset_flg  				: std_logic;
signal cmd_flg    				: std_logic;
signal fi_flg     				: std_logic;
signal fi_flg0   				: std_logic;

signal test_buf                 : std_logic_vector(15 downto 0);

begin

flash_dpram_wren_vector(0) <= flash_dpram_wren;
process(sysclk,nRST)
begin
	if(nRST = '0') then
		config_rdreq <= '0';
	elsif rising_edge(sysclk) then
		if(config_rdack = '1') then
			config_rdreq <= '0';
		elsif(config_rdreq_buf = '1') then
			config_rdreq <= '1';
		end if;
	end if;
end process;


config_rdlen <= config_rdlen_buf;
config_rdaddr<= config_rdaddr_buf;

process(sysclk,nRST)
begin
	if(nRST = '0') then
		phy_req <= '0';
	    config_rdlen_buf <= config_rdlen_init;
		config_rdaddr_buf <= config_rdaddr_init;
		cnt <= (others => '0');
		rd_cnt <= (others => '0');
		cnt_wait <= (others=>'0');
		flash_addr_cnt <= (others => '0');
		dpram_addr_cnt <= (others => '0');
		fw_data <= (others => '0');
		wr_step <= (others => '0');
		check_step <= (others => '0');
		timeout <= (others => '0');
		pstate <= idle;
		crc <= (others => '0');
		rd_step1 <= (others => '0');
		rd_step2 <= (others => '0');
		wr_step1 <= (others => '0');
		wait_cmd <= (others => '0');
		read_pre <= '1';
	    select_cmd <= '0';  --0:cmd_set_xfi_2g5_mode,1: cmd_get_xfi_2g5_mode
		wr_step2 <= (others => '0');
		r_step <= (others => '0');
		wait_cmd1 <= (others => '0');
		fi_step <= (others => '0');
		fi_wait <= (others => '0');
		re_wait <= (others => '0');
		check_flg <= '0';
		reset_flg <= '0';
		cmd_flg <= '0';
		fi_flg <= '0';
		fi_flg0 <= '0';

	elsif rising_edge (sysclk) then
		case pstate is

			when idle =>
				if (op_is_action = '1' and load_agian ='1' ) then --for load fw again
					pstate <= op_start;
				    cnt <= (others => '0');
					flash_addr_cnt <= (others => '0');
					dpram_addr_cnt <= (others => '0');
				elsif op_is_action = '1' then
					pstate <= op_start;
				elsif(cnt = cnt_max + '1') then
					pstate <= req_rdflash;
				end if;
				phy_req <= '0';

			when op_start =>
				if cnt = cnt_max then
					pstate <= idle;
					phy_req <= '0';
				elsif cnt = cnt_max1 then
					pstate <= check;
				else
					pstate <= op_dur;
					phy_req <= '1';
				end if;
				cnt <= cnt + '1';
				phy_rdwren <= rdwren;
				phy_waddren<= waddren;
				phy_wdata <= wdata;
				phy_devaddr <= devaddr;
				phy_phyaddr <= phyaddr;

			when op_dur =>
				phy_req <= '0';
				if PHY_ACK = '1' then
					pstate <= wait_ms;
				else
					pstate <= op_dur;
				end if;

			when wait_ms =>
				if cnt_wait(7) = '1' then
					cnt_wait <= (others=>'0');
					pstate <= op_start;
				else
					cnt_wait <= cnt_wait + '1';
					pstate <= wait_ms;
				end if;

			when req_rdflash =>
				config_rdreq_buf <= '1';
				config_rdlen_buf <= config_rdlen_init;
				config_rdaddr_buf <= config_rdaddr_init + ("00" & X"0" & flash_addr_cnt & X"00" & '0');--equal to flash_addr_cnt*512
				pstate <= wait_rdack;

			when wait_rdack =>
				if(config_rdack = '1') then
					pstate <= rddpram;
					config_rdreq_buf <= '0';
				else
					pstate <= wait_rdack;
				end if;

			when rddpram =>
				--rd_cnt <= rd_cnt + '1';
				--if rd_cnt = 0 then
				--	flash_dpram_rdaddr <= dpram_addr_cnt &"00";
				--elsif rd_cnt = 1 then
				--	flash_dpram_rdaddr <= dpram_addr_cnt &"00" + '1';
				--elsif rd_cnt = 2 then
				--	flash_dpram_rdaddr <= dpram_addr_cnt &"00" + '1' +'1';
				--elsif rd_cnt = 3 then
				--	flash_dpram_rdaddr <= dpram_addr_cnt &"00"+ '1' +'1'+'1';
				--	fw_data <=   fw_data(23 downto 0) & flash_dpram_q;
				--elsif rd_cnt = 4 then
				--	fw_data <= fw_data (31 downto 16) & flash_dpram_q &fw_data(7 downto 0) ;
				--elsif rd_cnt = 5 then
				--	fw_data <= fw_data(31 downto 24) & flash_dpram_q & fw_data(15 downto 0);
				--elsif rd_cnt = 6 then
				--	fw_data <=   flash_dpram_q & fw_data(23 downto 0) ;
				--	pstate <= upload_fw;
				--	rd_cnt <= (others => '0');
				--end if;
				flash_dpram_rdaddr <= "00"&dpram_addr_cnt;
				fw_data <= flash_dpram_q;
				if rd_cnt(2) = '1' then
					rd_cnt <= (others => '0');
					pstate <= upload_fw;
				else
					rd_cnt <= rd_cnt + '1';
					pstate <= rddpram;
				end if;

			when upload_fw =>
				if wr_step = 0 then
					phy_req <= '1';
					phy_rdwren <= '1';
					phy_waddren <= '1';
					phy_wdata <= X"A81C";
					phy_devaddr <= "00001";
					phy_phyaddr <= phya_phyaddr;
					wr_step <= wr_step + '1';
				elsif wr_step = 1 then
					phy_req <= '0';
					if phy_ack = '1' then
						wr_step <= wr_step + '1';
					end if;
				elsif wr_step = 2 then
					if cnt_wait(7) = '1' then
						cnt_wait <= (others => '0');
						wr_step <= wr_step + '1';
					else
						cnt_wait <= cnt_wait + '1';
					end if;
				elsif wr_step = 3 then
					phy_req <= '1';
					phy_rdwren <= '1';
					phy_waddren <= '0';
					phy_wdata <= fw_data(31 downto 16);
					wr_step <= wr_step + '1';
				elsif wr_step = 4 then
					phy_req <= '0';
					if  phy_ack = '1' then
						wr_step <= wr_step + '1';
					end if;
				elsif wr_step = 5 then
					if cnt_wait(7) = '1' then
						cnt_wait <= (others => '0');
						wr_step <= wr_step + '1';
					else
						cnt_wait <= cnt_wait + '1';
					end if;
				elsif wr_step = 6 then
					phy_req <= '1';
					phy_rdwren <= '1';
					phy_waddren <= '1';
					phy_wdata <=X"A81B";
					wr_step <= wr_step + '1';
				elsif wr_step = 7 then
					phy_req <= '0';
					if  phy_ack = '1' then
						wr_step <= wr_step + '1';
					end if;
				elsif wr_step = 8 then
					if cnt_wait(7) = '1' then
						cnt_wait <= (others => '0');
						wr_step <= wr_step + '1';
					else
						cnt_wait <= cnt_wait + '1';
					end if;
				elsif wr_step = 9 then
					phy_req <= '1';
					phy_rdwren <= '1';
					phy_waddren <= '0';
					phy_wdata <= fw_data(15 downto 0);
					wr_step <= wr_step + '1';
				elsif wr_step = 10 then
					phy_req <= '0';
					if  phy_ack = '1' then
						-- if (config_rdaddr_buf =  X"267E00" and   flash_dpram_rdaddr =  307    )  then
						if (config_rdaddr_buf =  ('1'&X"FF7E00") and   flash_dpram_rdaddr =  76    )  then
							pstate <= op_start  ;
							cnt <= cnt + '1';
							wr_step <= (others => '0');
						elsif flash_dpram_rdaddr = 127 then
							pstate <= req_rdflash;
							wr_step <= (others => '0');
							flash_addr_cnt <= flash_addr_cnt+'1';
							dpram_addr_cnt <= (others =>'0');
						else
							pstate <= rddpram;
							wr_step <= (others => '0');
							dpram_addr_cnt <= dpram_addr_cnt +'1';
						end if;
					end if;
				end if;

			when check =>
				if check_step = 0 then
					phy_req <= '1';
					phy_rdwren <= '1';
					phy_waddren <= '1';
					phy_wdata <= X"0000";
					phy_devaddr <= "00001";
					check_step <= check_step + '1';
					if check_flg = '0' then
						phy_phyaddr <= phya_phyaddr;
					else
						phy_phyaddr <= phyb_phyaddr;
					end if;
				elsif check_step = 1 then
					phy_req <= '0';
					if  phy_ack = '1' then
						check_step <= check_step + '1';
					end if;
				elsif check_step = 2 then
					if cnt_wait(7) = '1' then
						cnt_wait <= (others => '0');
						check_step <= check_step + '1';
					else
						cnt_wait <= cnt_wait + '1';
					end if;
				elsif check_step = 3 then
					phy_req <= '1';
					phy_rdwren <= '0';
					phy_wdata <= X"0000";
					check_step <= check_step + '1';
				elsif check_step = 4 then
					phy_req <= '0';
					if  phy_ack = '1' then
						if phy_rvld = '1' then
							if check_flg = '0' then
								check_load_a <= phy_rdata;
								check_flg <= '1';
								check_step <= "000";
							else
								check_load_b <= phy_rdata;
								check_step <= check_step + '1';
								check_flg <= '0';
							end if;
						end if;
					end if;
				elsif check_step = 5 then
					if check_load_a = X"2040" then
						fw_success(1) <= '1';
					else
						fw_success(1) <= '0';
					end if;
					if check_load_b = X"2040" then
						fw_success(0) <= '1';
					else
						fw_success(0) <= '0';
					end if;

					if fw_success = "11" then
						pstate <= reset;
					elsif  timeout(11 downto 10) = "11" then
						pstate <= idle;
					else
						pstate <= check;
					end if;
					check_step <= (others => '0');
				end if;

				if (timeout(11 downto 10) = "11" and check_step = 5) then
					timeout <= (others => '0');
				elsif timeout(11 downto 10) = "11" then
					timeout(11 downto 10) <= "11";
				elsif time_ms_en = '1' then
					timeout <= timeout + '1';
				end if;

			when reset =>   ---------reset after upload fw
				if r_step =  0 then
					phy_req <= '1';
					phy_rdwren <= '1';
					phy_waddren <= '1';
					phy_wdata <= X"0000";
					phy_devaddr <= "00001";
					r_step <= r_step + '1';
					if reset_flg = '0' then
						phy_phyaddr <= phya_phyaddr;
					else
						phy_phyaddr <= phyb_phyaddr;
					end if;
				elsif r_step = 1 then
					phy_req <= '0';
					if  phy_ack = '1' then
						r_step <= r_step + '1';
					end if;
				elsif r_step = 2 then
					if cnt_wait(7) = '1' then
						cnt_wait <= (others => '0');
						r_step <= r_step + '1';
					else
						cnt_wait <= cnt_wait + '1';
				    end if;
			    elsif r_step = 3 then
					phy_req <= '1';
			        phy_rdwren <= '1';
			        phy_waddren <= '1';
			        phy_wdata <= X"8000";
			        phy_devaddr <= "00001";
			        r_step <= r_step + '1';
				elsif r_step = 4 then
			    	phy_req <= '0';
			    	if  phy_ack = '1' then
						if reset_flg = '0' then
							r_step <= "000";
							reset_flg <= '1';
						else
							r_step <= r_step + '1';
							reset_flg <= '0';
						end if;
			    	end if;
				elsif r_step = 5 then
					if wait_cmd1 =   5  then
						r_step <= (others => '0');
						pstate <= rd_status;
						wait_cmd1 <= (others => '0');
					elsif time_ms_en = '1' then
						wait_cmd1 <= wait_cmd1 + '1';
					end if;
				end if;

			-- when check_link =>
				-- -- if ch_step = 0 then
					-- -- if an_time(12) = '1' then --wait auto-negotiation for 4s
						-- -- ch_step <= ch_step + '1';
						-- -- an_time <= (others => '0');
					-- -- elsif time_ms_en = '1' then
						-- -- an_time <= an_time + '1';
					-- -- end if;
				-- if ch_step = 0 then
					-- phy_req <= '1';
					-- phy_rdwren <= '1';
					-- phy_waddren <= '1';
					-- phy_wdata <= X"400D";
					-- phy_devaddr <= "11110";
					-- ch_step <= ch_step + '1';
				-- elsif ch_step = 1 then
					-- phy_req <= '0';
					-- if  phy_ack = '1' then
						-- ch_step <= ch_step + '1';
					-- end if;
				-- elsif ch_step = 2 then
					-- if cnt_wait(7) = '1' then
					   -- cnt_wait <= (others => '0');
					   -- ch_step <= ch_step + '1';
					-- else
						-- cnt_wait <= cnt_wait + '1';
					-- end if;
				-- elsif ch_step = 3 then
					-- phy_req <= '1';
					-- phy_rdwren <= '0';
					-- phy_wdata <= X"400D";
					-- phy_devaddr <= "11110";
					-- ch_step <= ch_step + '1';
				-- elsif ch_step = 4 then
					-- phy_req <= '0';
					-- if  phy_ack = '1' then
						-- if phy_rvld = '1' then
							-- link_status <= phy_rdata;
							-- pstate <= rd_status;
						-- else
							-- pstate <= check_link;
						-- end if;
					-- ch_step <= (others => '0');
					-- end if;
				-- end if;

			when rd_status =>
				if rd_step1 = 0 then
				   phy_req <= '1';
				   phy_rdwren <= '1';
				   phy_waddren <= '1';
				   phy_wdata <= X"4037";
				   phy_devaddr <= "11110";
				   rd_step1 <= rd_step1 + '1';
				    if cmd_flg = '0' then
					 phy_phyaddr <= phya_phyaddr;
				    else
					 phy_phyaddr <= phyb_phyaddr;
				    end if;
				elsif rd_step1 = 1 then
					phy_req <= '0';
					if  phy_ack = '1' then
						rd_step1<= rd_step1 + '1';
					end if;
				elsif rd_step1 = 2 then
					if cnt_wait(7) = '1' then
						cnt_wait <= (others => '0');
						rd_step1 <= rd_step1 + '1';
					else
						cnt_wait <= cnt_wait + '1';
					end if;
				elsif rd_step1 = 3 then
				   phy_req <= '1';
				   phy_rdwren <= '0';
				   phy_wdata <= X"4037";
				   rd_step1 <= rd_step1 + '1';
				elsif rd_step1 = 4 then
					phy_req <= '0';
					if  phy_ack = '1' then
						if phy_rvld = '1' then
							status <= phy_rdata;
							rd_step1 <= rd_step1 + '1';
						end if;
					end if;
				elsif rd_step1 = 5 then
					if read_pre = '1' then
						if (status = X"0002" or status = X"BBBB") then
							pstate <= rd_status;
							cmd_status <= status;
							rd_step1 <= (others => '0');
						else
							if select_cmd = '0' then
								pstate <= wr_data;
							elsif select_cmd = '1' then
								pstate <= wr_command;
							end if;
							rd_step1 <= (others => '0');
						end if;
						read_pre <= '0';
					else
						if (status = X"0004" or status = X"0008") then
							pstate <= rd_data;
							cmd_succ_or_fail <= status;
							rd_step1 <= (others => '0');
						else
							pstate <= rd_status;
							rd_step1 <= (others => '0');
						end if;
						read_pre <= '1';
					end if;
				end if;

			when wr_command =>
				if wr_step1 = 0 then
				   phy_req <= '1';
				   phy_rdwren <= '1';
				   phy_waddren <= '1';
				   phy_wdata <= X"4005";
				   wr_step1 <= wr_step1 + '1';
				elsif wr_step1 = 1 then
					phy_req <= '0';
					if phy_ack = '1' then
						wr_step1 <= wr_step1 + '1';
					end if;
				elsif wr_step1 = 2 then
					if cnt_wait(7) = '1' then
						cnt_wait <= (others => '0');
						wr_step1 <= wr_step1 + '1';
					else
						cnt_wait <= cnt_wait + '1';
					end if;
				elsif wr_step1 = 3 then
				   phy_req <= '1';
				   phy_rdwren <= '1';
				   phy_waddren <= '0';
				   wr_step1 <= wr_step1 + '1';
				    if select_cmd = '0' then
						phy_wdata <= X"8017";--set_XFI_2PG5_mode

				    elsif select_cmd = '1' then
						phy_wdata <= X"8016";--get_XFI_2PG5_mode
				    end if;
				elsif wr_step1 = 4 then
					phy_req <= '0';
					if phy_ack = '1' then
						wr_step1 <= wr_step1 + '1';
					end if;
				elsif wr_step1 = 5 then
					  if wait_cmd(11) = '1' then
					  	wr_step1 <= (others => '0');
					  	wait_cmd <= (others => '0');
						pstate <= rd_status;

					  elsif time_ms_en = '1' then
					  	wait_cmd <= wait_cmd + '1';
						pstate <= wr_command;
					  end if;
				end if;

			when wr_data =>
				if wr_step2 = 0 then
				   phy_req <= '1';
				   phy_rdwren <= '1';
				   phy_waddren <= '1';
				   phy_wdata <= X"4039";
				   wr_step2 <= wr_step2 + '1';
				elsif wr_step2 = 1 then
					phy_req <= '0';
					if  phy_ack = '1' then
						wr_step2<= wr_step2 + '1';
					end if;
				elsif wr_step2 = 2 then
					if cnt_wait(7) = '1' then
						cnt_wait <= (others => '0');
						wr_step2 <= wr_step2 + '1';
					else
						cnt_wait <= cnt_wait + '1';
					end if;
				elsif wr_step2 = 3 then
				   phy_req <= '1';
				   phy_rdwren <= '1';
				   phy_waddren <= '0';
				   phy_wdata <= X"0002"; ---set 5000r
				   wr_step2 <= wr_step2 + '1';
				elsif wr_step2 = 4 then
					phy_req <= '0';
					if  phy_ack = '1' then
						wr_step2 <= wr_step2 +'1';
					end if;
				elsif wr_step2 = 5 then
					if cnt_wait(7) = '1' then
						cnt_wait <= (others => '0');
						pstate <= wr_command;
						wr_step2 <= (others =>'0');
					else
					    cnt_wait <= cnt_wait + '1';
						pstate <= wr_data;
					end if;
				end if;

			when rd_data =>
				if rd_step2 = 0 then
				   phy_req <= '1';
				   phy_rdwren <= '1';
				   phy_waddren <= '1';
				   phy_wdata <= X"4039";
				   rd_step2 <= rd_step2 + '1';
				elsif rd_step2 = 1 then
					phy_req <= '0';
					if  phy_ack = '1' then
						rd_step2<= rd_step2 + '1';
					end if;
				elsif rd_step2 = 2 then
					if cnt_wait(7) = '1' then
						cnt_wait <= (others => '0');
						rd_step2 <= rd_step2 + '1';
					else
						cnt_wait <= cnt_wait + '1';
					end if;
				elsif rd_step2 = 3 then
				   phy_req <= '1';
				   phy_rdwren <= '0';
				   phy_wdata <= X"4039";
				   rd_step2 <= rd_step2 + '1';
				elsif rd_step2 = 4 then
					phy_req <= '0';
					if  phy_ack = '1' then
						if phy_rvld = '1' then
							if select_cmd = '0' then
								set_XFI_2P5G_mode <= phy_rdata;
								pstate <= rd_status;
								select_cmd <= '1';
							elsif select_cmd = '1' then
								if cmd_flg = '0' then
									get_XFI_2P5G_mode_a <= phy_rdata;
									pstate <= rd_status;
									cmd_flg <= '1';
								else
									get_XFI_2P5G_mode_b <= phy_rdata;
									cmd_flg <= '0';
									pstate <= finish;
								end if;
								select_cmd <= '0';
							end if;
							rd_step2 <= (others => '0');
						end if;
					end if;
				end if;

			when finish =>
				-- if fi_step = 0 then
				   -- phy_req <= '1';
				   -- phy_rdwren <= '1';
				   -- phy_waddren <= '1';
				   -- phy_wdata <= X"0000";
				   -- phy_devaddr <= "00111";
				   -- fi_step <= fi_step + '1';

				    -- if fi_flg = '0' then
						-- phy_phyaddr <= phya_phyaddr;
				    -- else
						-- phy_phyaddr <= phyb_phyaddr;
					-- end if;

				-- elsif fi_step = 1 then
					-- phy_req <= '0';
					-- if  phy_ack = '1' then
						-- fi_step<= fi_step + '1';
					-- end if;
				-- elsif fi_step = 2 then
					-- if cnt_wait(7) = '1' then
						-- cnt_wait <= (others => '0');
						-- fi_step <= fi_step + '1';
					-- else
						-- cnt_wait <= cnt_wait + '1';
					-- end if;
				-- elsif fi_step = 3 then
				   -- phy_req <= '1';
				   -- phy_rdwren <= '0';
				   -- phy_wdata <= X"0000";
				   -- phy_devaddr <= "00111";
				   -- fi_step <= fi_step + '1';
				-- elsif fi_step = 4 then
					-- phy_req <= '0';
					-- if  phy_ack = '1' then
						-- if phy_rvld = '1' then
							-- if fi_flg = '0' then
								-- an_reg_a <= phy_rdata;
							-- else
								-- an_reg_b <= phy_rdata;
							-- end if;
							-- fi_step<= fi_step + '1';
						-- end if;
					-- end if;
				-- elsif fi_step = 5 then
					-- if cnt_wait(7) = '1' then
						-- cnt_wait <= (others => '0');
						-- fi_step <= fi_step + '1';
					-- else
						-- cnt_wait <= cnt_wait + '1';
					-- end if;

	------------------for   restart  auto-negotiation---------------

				if fi_step = 0 then
				   phy_req <= '1';
				   phy_rdwren <= '1';
				   phy_waddren <= '1';
				   phy_wdata <= X"0000";
				   phy_devaddr <= "00111";
				   fi_step <= fi_step + '1';
					if fi_flg = '0' then
						phy_phyaddr <= phya_phyaddr;
				    else
						phy_phyaddr <= phyb_phyaddr;
					end if;
				elsif fi_step = 1 then
					phy_req <= '0';
					if  phy_ack = '1' then
						fi_step<= fi_step + '1';
					end if;
				elsif fi_step = 2 then
					if cnt_wait(7) = '1' then
						cnt_wait <= (others => '0');
						fi_step <= fi_step + '1';
					else
						cnt_wait <= cnt_wait + '1';
					end if;
				elsif fi_step = 3 then
				   phy_req <= '1';
				   phy_rdwren <= '1';
				   phy_waddren <= '0';
				   phy_wdata <=  X"3200";
				   phy_devaddr <= "00111";
				   fi_step <= fi_step + '1';
				elsif fi_step = 4 then
					phy_req <= '0';
					if  phy_ack = '1' then

						if fi_flg = '0' then
							fi_step <= "0000";
							fi_flg <= '1';
						else
							fi_step<= fi_step + '1';
							fi_flg <= '0';
						end if;
					end if;
				elsif fi_step = 5 then
					if re_wait(11)  = '1'  then
						re_wait <= (others => '0');
						fi_step <= fi_step + '1';
					elsif time_ms_en = '1' then
						re_wait <= re_wait + '1';
					end if;

----------------------for read 0X400D access mac and copper link status---------------------------

				elsif fi_step = 6 then
                	phy_req <= '1';
                	phy_rdwren <= '1';
                	phy_waddren <= '1';
                	phy_wdata <= X"400D";
                	phy_devaddr <= "11110";
                	fi_step <= fi_step + '1';
					if fi_flg0 = '0' then
						phy_phyaddr <= phya_phyaddr;
					else
						phy_phyaddr <= phyb_phyaddr;
					end if;
                elsif fi_step = 7 then
                	phy_req <= '0';
                	if  phy_ack = '1' then
                		fi_step<= fi_step + '1';
                	end if;
                elsif fi_step = 8 then
                	if cnt_wait(7) = '1' then
                		cnt_wait <= (others => '0');
                		fi_step <= fi_step + '1';
                	else
                		cnt_wait <= cnt_wait + '1';
                	end if;
                elsif fi_step = 9 then
                	phy_req <= '1';
                	phy_rdwren <= '0';
                	phy_wdata <= X"400D";
					fi_step <= fi_step + '1';
				elsif fi_step = 10 then
					phy_req <= '0';
					if  phy_ack = '1' then
						if phy_rvld = '1' then
							if fi_flg0 = '0' then
								mac_copper_status_a <= phy_rdata;
								fi_step <="0110";
								fi_flg0 <= '1';
							else
								mac_copper_status_b <= phy_rdata;
								fi_flg0 <= '0';
								fi_step <= fi_step + '1';
							end if;
						end if;
					end if;
				elsif fi_step = 11 then
					if fi_wait = 200 then
						pstate <= finish;
						fi_step <= "0110";
						fi_wait <= (others => '0');
					elsif time_ms_en = '1' then
						fi_wait <= fi_wait + '1';
					end if;
				end if;

			when others => pstate <= idle;
		end case;
	end if;
end process;


process(nRST,sysclk)
begin
if(nRST='0') then
		step<=(others=>'0');
		rdwren <= '1';
		waddren<= '1';
		reset_wait_1s<=(others=>'0');
		wdata<=X"418C";
		devaddr <= "11110";
		phyaddr <= phya_phyaddr;
		load_agian <= '0';
		cnt_load <= (others => '0');

    elsif rising_edge(sysclk) then
		if step=0 then
			if (phy_rsta_done = '1' ) then
				step <= step + '1';
			end if;
		elsif step = 1 then
			if  (reset_wait_1s = 1000) then
			    reset_wait_1s<=(others=>'0');
				step <= step+'1';
			    op_is_action<='1';
			elsif time_ms_en = '1' then
			    reset_wait_1s<= reset_wait_1s+'1';
			end if;
		elsif step=2 then	  --write register before upload fw
			if cnt = 0 then
			    wdata <= X"418C";
				rdwren <= '1';
				waddren <= '1';
				devaddr <= "11110";
				phyaddr <= phya_phyaddr;
			elsif cnt = 1 then
			    wdata <= X"0000";
				waddren <= '0';
			elsif cnt = 2 then
			    wdata <= X"4188";
				waddren <= '1';
			elsif cnt = 3 then
			    wdata <= X"48F0";
				waddren <= '0';
			elsif cnt = 4 then
			    wdata <= X"418C";
				waddren <= '1';
				phyaddr <= phyb_phyaddr;
			elsif cnt = 5 then
			    wdata <= X"0000";
				waddren <= '0';
			elsif cnt = 6 then
			    wdata <= X"4188";
				waddren <= '1';
			elsif cnt = 7 then
			    wdata <= X"48F0";
				waddren <= '0';
			elsif cnt = 8 then
				wdata <= X"A81A";
				waddren <= '1';
				devaddr <= "00001";
				phyaddr <= phya_phyaddr;
			elsif cnt = 9 then
				wdata <= X"F000";
				waddren <= '0';
			elsif cnt = 10 then
				wdata <= X"A819";
				waddren <= '1';
			elsif cnt = 11 then
				wdata <= X"3000";
				waddren <= '0';
			elsif cnt = 12 then
				wdata <= X"A81C";
				waddren <= '1';
			elsif cnt = 13 then
				wdata <= X"0000";
				waddren <= '0';
			elsif cnt = 14 then
				wdata <= X"A81B";
				waddren <= '1';
			elsif cnt = 15 then
				wdata <= X"0121";
				waddren <= '0';
			elsif cnt = 16 then
				wdata <= X"A817";
				waddren <= '1';
			elsif cnt = 17 then
				wdata <= X"0009";
				waddren <= '0';
			elsif cnt = 18 then
				wdata <= X"A81A";
				waddren <= '1';
				devaddr <= "00001";
				phyaddr <= phyb_phyaddr;
			elsif cnt = 19 then
				wdata <= X"F000";
				waddren <= '0';
			elsif cnt = 20 then
				wdata <= X"A819";
				waddren <= '1';
			elsif cnt = 21 then
				wdata <= X"3000";
				waddren <= '0';
			elsif cnt = 22 then
				wdata <= X"A81C";
				waddren <= '1';
			elsif cnt = 23 then
				wdata <= X"0000";
				waddren <= '0';
			elsif cnt = 24 then
				wdata <= X"A81B";
				waddren <= '1';
			elsif cnt = 25 then
				wdata <= X"0121";
				waddren <= '0';
			elsif cnt = 26 then
				wdata <= X"A817";
				waddren <= '1';
			elsif cnt = 27 then
				wdata <= X"0009";
				waddren <= '0';
			elsif cnt = 28 then
				wdata <= X"80A6";
				waddren <= '1';
				devaddr <= "11110";
				phyaddr <= phya_phyaddr;
			elsif cnt = 29 then
				wdata <= X"0000";
				waddren <= '0';
			elsif cnt = 30 then
				wdata <= X"80A6";
				waddren <= '1';
				phyaddr <= phyb_phyaddr;
			elsif cnt = 31 then
				wdata <= X"0000";
				waddren <= '0';
			elsif cnt = 32 then
				wdata <= X"A010";
				waddren <= '1';
				devaddr <= "00001";
				phyaddr <= phya_phyaddr;
			elsif cnt = 33 then
				wdata <= X"0000";
				waddren <= '0';
			elsif cnt = 34 then
				wdata <= X"A010";
				waddren <= '1';
				phyaddr <= phyb_phyaddr;
			elsif cnt = 35 then
				wdata <= X"0000";
				waddren <= '0';
			elsif cnt = 36 then
				wdata <= X"0000";
				waddren <= '1';
				phyaddr <= phya_phyaddr;
			elsif cnt = 37 then
				wdata <= X"8000";
				waddren <= '0';
			elsif cnt = 38 then
				wdata <= X"0000";
				waddren <= '1';
				phyaddr <= phyb_phyaddr;
			elsif cnt = 39 then
				wdata <= X"8000";
				waddren <= '0';
	--------------for  enable broadcast mode------------------
			elsif cnt = 40 then
				wdata <= X"4107";
				waddren <= '1';
				devaddr <= "11110";
				phyaddr <= phyb_phyaddr;
			elsif cnt = 41 then
				-- wdata <= X"0581";----------------not certain
                wdata <= X"05C1";----------------not certain
				waddren <= '0';
			elsif cnt = 42 then
				wdata <= X"4117";
				waddren <= '1';
			elsif cnt = 43 then
				wdata <= X"F001";
				waddren <= '0';
--------------------------------------------------------------
			elsif cnt = 44 then
				wdata <= X"A81A";
				waddren <= '1';
				devaddr <= "00001";
				phyaddr <= phya_phyaddr;
			elsif cnt = 45 then
				wdata <= X"0000";
				waddren <= '0';
			elsif cnt = 46 then
				wdata <= X"A819";
				waddren <= '1';
			elsif cnt = 47 then
				wdata <= X"0000";
				waddren <= '0';
			elsif cnt = 48 then
				wdata <= X"A817";
				waddren <= '1';
			elsif cnt = 49 then
				wdata <= X"0038";
				waddren <= '0';
			elsif cnt = 50 then
				op_is_action <= '0';
				waddren <= '1';
				wdata <= X"A817";
			elsif cnt = 51 then
				step <= step + '1';
			end if;
			cnt_max <= "110010";
		elsif step = 3 then  --write register after upload fw
			if cnt= 51 then
				wdata <= X"A817";
				waddren <= '1';
				phyaddr <= phya_phyaddr;
			elsif cnt= 52 then
				wdata <= X"A817";
				waddren <= '1';
			elsif cnt = 53 then
				wdata <= X"0000";
				waddren <= '0';
-----------------for disable broadcast mode----------------
			elsif cnt = 54 then
				wdata <= X"4107";
				waddren <= '1';
				devaddr <= "11110";
				phyaddr <= phyb_phyaddr;
			elsif cnt = 55 then
				wdata <= X"0000";
				waddren <= '0';
			elsif cnt = 56 then
				wdata <= X"4117";
				waddren <= '1';
			elsif cnt = 57 then
				wdata <= X"0000";
				waddren <= '0';
-----------------------------------------------------------------
			elsif cnt = 58 then
				wdata <= X"A81A";
				waddren <= '1';
				devaddr <= "00001";
				phyaddr <= phya_phyaddr;
			elsif cnt = 59 then
				wdata <= X"F000";
				waddren <= '0';
			elsif cnt = 60 then
				wdata <= X"A819";
				waddren <= '1';
			elsif cnt = 61 then
				wdata <= X"3000";
				waddren <= '0';
			elsif cnt = 62 then
				wdata <= X"A81C";
				waddren <= '1';
			elsif cnt = 63 then
				wdata <= X"0000";
				waddren <= '0';
			elsif cnt = 64 then
				wdata <= X"A81B";
				waddren <= '1';
			elsif cnt = 65 then
				wdata <= X"0020";
				waddren <= '0';
			elsif cnt = 66 then
				wdata <= X"A817";
				waddren <= '1';
			elsif cnt = 67 then
				wdata <= X"0009";
				waddren <= '0';
			elsif cnt = 68 then
				wdata <= X"A81A";
				waddren <= '1';
				devaddr <= "00001";
				phyaddr <= phyb_phyaddr;
			elsif cnt = 69 then
				wdata <= X"F000";
				waddren <= '0';
			elsif cnt = 70 then
				wdata <= X"A819";
				waddren <= '1';
			elsif cnt = 71 then
				wdata <= X"3000";
				waddren <= '0';
			elsif cnt = 72 then
				wdata <= X"A81C";
				waddren <= '1';
			elsif cnt = 73 then
				wdata <= X"0000";
				waddren <= '0';
			elsif cnt = 74 then
				wdata <= X"A81B";
				waddren <= '1';
			elsif cnt = 75 then
				wdata <= X"0020";
				waddren <= '0';
			elsif cnt = 76 then
				wdata <= X"A817";
				waddren <= '1';
			elsif cnt = 77 then
				wdata <= X"0009";
				waddren <= '0';
			else
				rdwren <= '1';
				waddren <= '1';
				wdata <= X"0000";
			    step <= step + '1';         --for load fw again
			end if;
			cnt_max1 <= "100"& X"E";
	    elsif step = 4 then   --for load fw again
			if (timeout(11 downto 10) = "11" and check_step = 5) then
				op_is_action <= '1';
				step <= "010";
				load_agian <= '1';
				cnt_load <= cnt_load +'1';
				rdwren <= '1';
				waddren <= '1';
				wdata <= X"418C";
				devaddr <= "11110";
				phyaddr <= phya_phyaddr;
			else
				step <= "100";
			end if;
		end if;
	end if;
end process;

RST <= not nRST;

eth_Man_inst : eth_Man
port map(

   nrst    		=> nrst ,
   sysclk  	    => sysclk,

   phy_phyaddr  => phy_phyaddr,
   phy_req      => phy_req,
   phy_ack      => phy_ack,
   phy_rdwren   => phy_rdwren,
   phy_waddren  => phy_waddren,--new
   phy_devaddr  => phy_devaddr,
   phy_rdata    => phy_rdata,
   phy_rvld     => phy_rvld,
   phy_wdata    => phy_wdata,

   phy_mdc      => phy0_mdc,
   phy_mdin     => phy0_mdin,
   phy_mdout    => phy0_mdout,
   phy_mdir     => phy0_mdir
);

flash_config_dpram_inst : flash_config_dpram
port map (
	data      => flash_dpram_data,        -- datain
	q         => flash_dpram_q,        -- dataout
	wraddress => flash_dpram_wraddr,        -- wraddress
	rdaddress => flash_dpram_rdaddr,        -- rdaddress
	wren      => flash_dpram_wren_vector(0),        -- wren
	clock     => sysclk        -- clk
);

--test_buf <= check_load_a and check_load_b and set_XFI_2P5G_mode and get_XFI_2P5G_mode_a and get_XFI_2P5G_mode_b and mac_copper_status_a and mac_copper_status_b;
--test <= test_buf(15) and test_buf(14) and test_buf(13) and test_buf(12) and test_buf(11) and test_buf(10) and test_buf(9) and test_buf(8) and test_buf(7) and test_buf(6) and test_buf(5) and test_buf(4) and test_buf(3) and test_buf(2) and test_buf(1) and test_buf(0);

end behav;

