library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity spi_flash_AX is
port(
    nRST                : in  std_logic;
    SYSCLK              : in  std_logic;

    cmd_idle            : out std_logic;
    cmd_en              : in  std_logic;
    cmd                 : in  std_logic_vector(2 downto 0);

    cmd_timeout         : out std_logic;
    cmd_finished        : out std_logic;

    addr                : in  std_logic_vector(24 downto 0);
    rdnum               : in  std_logic_vector(12 downto 0);
    data_empty          : out std_logic;
    data_en             : in  std_logic;
    host2flash          : in  std_logic_vector(7 downto 0);
    data_valid          : out std_logic;
    flash2host          : out std_logic_vector(7 downto 0);

    spi_ready           : out std_logic:='0'
);
end entity;

architecture behav of spi_flash_AX is

constant control_register                       : std_logic_vector(3 downto 0):= X"0";
constant SPI_Clock_Baud_rate_Register           : std_logic_vector(3 downto 0):= X"1";
constant CS_Delay_setting_register              : std_logic_vector(3 downto 0):= X"2";
constant Read_Capturing_Register                : std_logic_vector(3 downto 0):= X"3";
constant Operating_Protocols_Setting_Register   : std_logic_vector(3 downto 0):= X"4";
constant Read_Instruction_Register              : std_logic_vector(3 downto 0):= X"5";
constant Write_Instruction_Register             : std_logic_vector(3 downto 0):= X"6";
constant Flash_Command_setting_register         : std_logic_vector(3 downto 0):= X"7";
constant Flash_Command_control_register         : std_logic_vector(3 downto 0):= X"8";
constant Flash_Command_Address_Register         : std_logic_vector(3 downto 0):= X"9";
constant Flash_Command_write_data0              : std_logic_vector(3 downto 0):= X"A";
constant Flash_Command_write_data1              : std_logic_vector(3 downto 0):= X"B";
constant Flash_Command_read_data0               : std_logic_vector(3 downto 0):= X"C";
constant Flash_Command_read_data1               : std_logic_vector(3 downto 0):= X"D";

signal avl_csr_read                 : std_logic                     := 'X';             -- read
signal avl_csr_waitrequest          : std_logic;                                        -- waitrequest
signal avl_csr_write                : std_logic                     := 'X';             -- write
signal avl_csr_addr                 : std_logic_vector(3 downto 0)  := (others => 'X'); -- address
signal avl_csr_address              : std_logic_vector(5 downto 0)  := (others => 'X'); -- address
signal avl_csr_wrdata               : std_logic_vector(31 downto 0) := (others => 'X'); -- writedata
signal avl_csr_rddata               : std_logic_vector(31 downto 0);                    -- readdata
signal avl_csr_rddata_valid         : std_logic;                                        -- readdatavalid
signal avl_mem_write                : std_logic                     := 'X';             -- write
signal avl_mem_burstcount           : std_logic_vector(6 downto 0)  := (others => 'X'); -- burstcount
signal avl_mem_waitrequest          : std_logic;                                        -- waitrequest
signal avl_mem_read                 : std_logic                     := 'X';             -- read
signal avl_mem_addr                 : std_logic_vector(22 downto 0) := (others => 'X'); -- address
signal avl_mem_wrdata               : std_logic_vector(31 downto 0) := (others => 'X'); -- writedata
signal avl_mem_rddata               : std_logic_vector(31 downto 0);                    -- readdata
signal avl_mem_rddata_valid         : std_logic;                                        -- readdatavalid
signal avl_mem_byteenable           : std_logic_vector(3 downto 0)  := (others => 'X'); -- byteenable
signal irq                          : std_logic;                                        -- irq
signal rst                          : std_logic := '1';

signal csr_step                     : std_logic_vector(3 downto 0)  :=(others=>'0');
signal op_done                      : std_logic := '0';
signal write_or_read                : std_logic := '0';
signal time_cnt                     : std_logic_vector(11 downto 0) :=(others=>'0');
signal avl_csr_write_I              : std_logic := '0';
signal avl_csr_read_I               : std_logic := '0';
signal avl_csr_waitrequest_d1       : std_logic := '0';
signal avl_csr_waitrequest_negedge  : std_logic := '0';
signal avl_mem_waitrequest_d1       : std_logic := '0';
signal avl_mem_waitrequest_negedge  : std_logic := '0';
signal device_id                    : std_logic_vector(31 downto 0) := (others=>'0');

signal rd_last                      : std_logic := '0';
signal rdnum_buf                    : std_logic_vector(12 downto 0) := (others=>'0');
signal rd_buf                       : std_logic_vector(31 downto 0) := (others=>'0');
signal status_data                  : std_logic_vector(7 downto 0)  := (others=>'0');
signal addr_buf                     : std_logic_vector(24 downto 0) := (others=>'0');
signal wr_loop                      : std_logic_vector(8 downto 0)  := (others=>'0');
signal rd_cnt                       : std_logic_vector(6 downto 0)  := (others=>'0');
signal data_valid_cnt               : std_logic_vector(4 downto 0)  := (others=>'0');
signal delay_wait1_cnt              : std_logic_vector(10 downto 0) := (others=>'0');
signal cur_cmd                      : std_logic_vector(2 downto 0)  := (others=>'0');
signal wr_buf                       : std_logic_vector(7 downto 0)  := (others=>'0');
signal delay_cnt					: std_logic_vector(20 downto 0)  := (others=>'0');

type csr_state is (
init,
idle,
delay_wait1,
delay_wait,
sector_earse,
write_statusreg,
read_statusreg,
page_rd,
page_rd_b1,
page_wr
);
signal csr_pstate: csr_state := init;

    component generic_spi_flash is
        port (
            avl_csr_address       : in  std_logic_vector(5 downto 0)  := (others => 'X'); -- address
            avl_csr_read          : in  std_logic                     := 'X';             -- read
            avl_csr_readdata      : out std_logic_vector(31 downto 0);                    -- readdata
            avl_csr_write         : in  std_logic                     := 'X';             -- write
            avl_csr_writedata     : in  std_logic_vector(31 downto 0) := (others => 'X'); -- writedata
            avl_csr_waitrequest   : out std_logic;                                        -- waitrequest
            avl_csr_readdatavalid : out std_logic;                                        -- readdatavalid
            avl_mem_write         : in  std_logic                     := 'X';             -- write
            avl_mem_burstcount    : in  std_logic_vector(6 downto 0)  := (others => 'X'); -- burstcount
            avl_mem_waitrequest   : out std_logic;                                        -- waitrequest
            avl_mem_read          : in  std_logic                     := 'X';             -- read
            avl_mem_address       : in  std_logic_vector(22 downto 0) := (others => 'X'); -- address
            avl_mem_writedata     : in  std_logic_vector(31 downto 0) := (others => 'X'); -- writedata
            avl_mem_readdata      : out std_logic_vector(31 downto 0);                    -- readdata
            avl_mem_readdatavalid : out std_logic;                                        -- readdatavalid
            avl_mem_byteenable    : in  std_logic_vector(3 downto 0)  := (others => 'X'); -- byteenable
            clk_clk               : in  std_logic                     := 'X';             -- clk
            reset_reset           : in  std_logic                     := 'X'              -- reset
        );
    end component generic_spi_flash;

begin
    sspi_flash_inst : generic_spi_flash
        port map (
            avl_csr_address       => avl_csr_address,       -- avl_csr.address
            avl_csr_read          => avl_csr_read_I,        --        .read
            avl_csr_readdata      => avl_csr_rddata,        --        .readdata
            avl_csr_write         => avl_csr_write_I,       --        .write
            avl_csr_writedata     => avl_csr_wrdata,        --        .writedata
            avl_csr_waitrequest   => avl_csr_waitrequest,   --        .waitrequest
            avl_csr_readdatavalid => avl_csr_rddata_valid,  --        .readdatavalid
            avl_mem_write         => avl_mem_write,         -- avl_mem.write
            avl_mem_burstcount    => avl_mem_burstcount,    --        .burstcount
            avl_mem_waitrequest   => avl_mem_waitrequest,   --        .waitrequest
            avl_mem_read          => avl_mem_read,          --        .read
            avl_mem_address       => avl_mem_addr,          --        .address
            avl_mem_writedata     => avl_mem_wrdata,        --        .writedata
            avl_mem_readdata      => avl_mem_rddata,        --        .readdata
            avl_mem_readdatavalid => avl_mem_rddata_valid,  --        .readdatavalid
            avl_mem_byteenable    => avl_mem_byteenable,    --        .byteenable
            clk_clk               => SYSCLK,                --     clk.clk
            reset_reset           => rst                    --   reset.reset
        );

avl_csr_address             <= "00"&avl_csr_addr;
avl_csr_write_I             <= avl_csr_write    when avl_csr_waitrequest = '0' else write_or_read;
avl_csr_read_I              <= avl_csr_read     when avl_csr_waitrequest = '0' else not write_or_read;
avl_csr_waitrequest_negedge <= '1'              when avl_csr_waitrequest = '0' and avl_csr_waitrequest_d1 = '1' else '0';
avl_mem_waitrequest_negedge <= '1'              when avl_mem_waitrequest = '0' and avl_mem_waitrequest_d1 = '1' else '0';
rst                         <= not nRST;
wr_buf                      <= host2flash(0)&host2flash(1)&host2flash(2)&host2flash(3)&host2flash(4)&host2flash(5)&host2flash(6)&host2flash(7);

process(sysclk,nRST)
begin
	if nRST = '0' then
		delay_cnt <= (others => '0');
    elsif rising_edge(sysclk) then
        if delay_cnt(20) = '0' then
            delay_cnt <= delay_cnt + '1';
        end if;
    end if;
end process;

process(sysclk,nRST)
begin
    if nRST = '0' then
        avl_mem_byteenable  <= (others => '0');
        avl_mem_wrdata      <= (others => '0');
        avl_mem_addr        <= (others => '0');
        avl_mem_burstcount  <= (others => '0');
        avl_mem_read        <= '0';
        avl_mem_write       <= '0';
        device_id           <= (others => '0');
        avl_csr_addr        <= (others => '0');
        avl_csr_wrdata      <= (others => '0');
        avl_csr_write       <= '0';
        avl_csr_read        <= '0';
        op_done             <= '0';
        write_or_read       <= '0';
        rd_last             <= '0';
        csr_step            <= (others => '0');
        delay_wait1_cnt     <= (others => '0');
        data_valid_cnt      <= (others => '0');
        cur_cmd             <= (others => '0');
        rd_cnt              <= (others => '0');
        wr_loop             <= (others => '0');
        addr_buf            <= (others => '0');
        rd_buf              <= (others => '0');
        status_data         <= (others => '0');
        rdnum_buf           <= (others => '0');
        time_cnt            <= (others => '0');
        spi_ready           <= '0';
        cmd_idle            <= '0';
		csr_pstate			<= init;
    elsif rising_edge(sysclk) then
        if avl_csr_write = '1' then
            write_or_read <= '1';
        elsif avl_csr_read = '1' then
            write_or_read <= '0';
        end if;

        avl_csr_waitrequest_d1 <= avl_csr_waitrequest;
        avl_mem_waitrequest_d1 <= avl_mem_waitrequest;

        case csr_pstate is
            when init =>
				if delay_cnt(20) = '1' then
					case csr_step is
						when X"0" =>
							if avl_csr_waitrequest = '0' then
								csr_step <= csr_step + '1';
							end if;
						when X"1" =>
							avl_csr_addr <= SPI_Clock_Baud_rate_Register;
							avl_csr_wrdata(31 downto 5) <= (others => '0');
							avl_csr_wrdata(4 downto 0) <= "00010";    --flash_clk = ip_clk/4
							if op_done = '1' then
								avl_csr_write <= '0';
								csr_step <= csr_step + '1';
								op_done <= '0';
							else
								op_done <= '1';
								avl_csr_write <= '1';
							end if;
						when X"2" =>
							avl_csr_addr <= CS_Delay_setting_register;
							avl_csr_wrdata <= (others => '0');
							if op_done = '1' then
								avl_csr_write <= '0';
								csr_step <= csr_step + '1';
								op_done <= '0';
							else
								op_done <= '1';
								avl_csr_write <= '1';
							end if;
						when X"3" =>
							avl_csr_addr <= Read_Capturing_Register;
							avl_csr_wrdata <= (others => '0');
							if op_done = '1' then
								avl_csr_write <= '0';
								csr_step <= csr_step + '1';
								op_done <= '0';
							else
								op_done <= '1';
								avl_csr_write <= '1';
							end if;
						when X"4" =>
							avl_csr_addr <= Operating_Protocols_Setting_Register;
							avl_csr_wrdata <= (others => '0');                                 -- extended mode
							-- avl_csr_wrdata <= (16 => '1',12 => '1',0 => '1',others => '0');    -- dual mode
							-- avl_csr_wrdata <= (17 => '1',13 => '1',1 => '1',others => '0');    -- quad mode
							if op_done = '1' then
								avl_csr_write <= '0';
								csr_step <= csr_step + X"1";
								op_done <= '0';
							else
								op_done <= '1';
								avl_csr_write <= '1';
							end if;
						when X"5" =>
							avl_csr_addr <= Read_Instruction_Register;
							avl_csr_wrdata(31 downto 12) <= (others => '0');
							avl_csr_wrdata(11 downto 8) <= X"A";
							avl_csr_wrdata(7 downto 0) <= X"0C";
							if op_done = '1' then
								avl_csr_write <= '0';
								csr_step <= csr_step + X"1";
								op_done <= '0';
							else
								op_done <= '1';
								avl_csr_write <= '1';
							end if;
						when X"6" =>
							avl_csr_addr <= Write_Instruction_Register;
							avl_csr_wrdata(31 downto 16) <= (others => '0');
							avl_csr_wrdata(15 downto 8) <= X"05";
							avl_csr_wrdata(7 downto 0) <= X"12";
							if op_done = '1' then
								avl_csr_write <= '0';
								csr_step <= csr_step + '1';
								op_done <= '0';
							else
								op_done <= '1';
								avl_csr_write <= '1';
							end if;
						when X"7" =>
							avl_csr_addr(3 downto 0) <= flash_command_setting_register;
							avl_csr_wrdata(31 downto 8) <= (others => '0');
							avl_csr_wrdata(7 downto 0) <= X"35";
							if op_done = '1' then
								avl_csr_write <= '0';
								csr_step <= csr_step + '1';
								op_done <= '0';
							else
								op_done <= '1';
								avl_csr_write <= '1';
							end if;
						when X"8" =>
							avl_csr_addr(3 downto 0) <= flash_command_control_register;
							avl_csr_wrdata <= (0 => '1',others => '0');
							if op_done = '1' then
								avl_csr_write <= '0';
							else
								op_done <= '1';
								avl_csr_write <= '1';
							end if;
							if avl_csr_waitrequest_negedge = '1' then
								csr_step <= csr_step + '1';
								op_done <= '0';
							end if;
						when X"9" =>
							avl_csr_addr <= Operating_Protocols_Setting_Register;
							-- avl_csr_wrdata <= (others => '0');                                 -- extended mode
							-- avl_csr_wrdata <= (16 => '1',12 => '1',0 => '1',others => '0');    -- dual mode
							avl_csr_wrdata <= (17 => '1',13 => '1',9 => '1',5 => '1',1 => '1',others => '0');    -- quad mode
							if op_done = '1' then
								avl_csr_write <= '0';
								csr_step <= csr_step + X"1";
								op_done <= '0';
							else
								op_done <= '1';
								avl_csr_write <= '1';
							end if;
						when X"A" =>
							avl_csr_addr <= control_register;
							avl_csr_wrdata <= (8 => '1',0 => '1',others => '0');     --4-byte addr mode
							if op_done = '1' then
								avl_csr_write <= '0';
								csr_step <= csr_step + '1';
								op_done <= '0';
							else
								op_done <= '1';
								avl_csr_write <= '1';
							end if;
						when others => csr_pstate <= idle;
					end case;
				end if;

            when idle =>
                spi_ready           <= '1';
                cmd_idle            <= '1';
                delay_wait1_cnt     <= (others => '0');
                time_cnt            <= (others => '0');
                data_empty          <= '0';
                data_valid          <= '0';

                cmd_timeout         <= '0';
                cmd_finished        <= '0';

                cur_cmd             <= cmd;

                avl_mem_byteenable  <= (others => '0');
                avl_mem_wrdata      <= (others => '0');
                avl_mem_addr        <= (others => '0');
                avl_mem_burstcount  <= (others => '0');
                avl_mem_read        <= '0';
                avl_mem_write       <= '0';
                avl_csr_addr        <= (others => '0');
                avl_csr_wrdata      <= (others => '0');
                avl_csr_write       <= '0';
                avl_csr_read        <= '0';
                csr_step            <= (others => '0');
                op_done             <= '0';
                data_valid_cnt      <= (others => '0');
                rd_cnt              <= (others => '0');
                rd_buf              <= (others => '0');
                wr_loop             <= (others => '0');
                addr_buf            <= addr;
                rd_last             <= '0';

                if cmd_en = '1' then
                    case cmd is
                        when "001" =>   csr_pstate  <= sector_earse;
                        when "010" =>   csr_pstate  <= page_wr;
                        when "011" =>   csr_pstate  <= page_rd_b1;
                                        rdnum_buf   <= rdnum;
                        when "100" =>   csr_pstate  <= sector_earse;
                        when "101" =>   csr_pstate  <= write_statusreg;
                                        status_data <= host2flash;
                        when "110" =>   csr_pstate  <= read_statusreg;
                                        status_data <= host2flash;
                        when others =>  csr_pstate  <= idle;
                    end case;
                else
                    csr_pstate <= idle;
                end if;

            when page_wr =>
                cmd_idle            <= '0';
                if data_valid_cnt = 31 then
                    data_valid_cnt      <= (others => '0');
                else
                    data_valid_cnt      <= data_valid_cnt + '1';
                end if;
                avl_mem_addr        <= addr_buf(24 downto 2);
                avl_mem_burstcount  <= CONV_STD_LOGIC_VECTOR(64,7);
                avl_mem_byteenable  <= "1111";

                if data_valid_cnt(2 downto 0) = "010" then
                    data_empty <= '1';
                else
                    data_empty <= '0';
                end if;

                if data_en = '1' then
                    wr_loop <= wr_loop + '1';
                    case wr_loop(1 downto 0) is
                        when "00" => avl_mem_wrdata(7 downto 0) <= wr_buf;
                        when "01" => avl_mem_wrdata(15 downto 8) <= wr_buf;
                        when "10" => avl_mem_wrdata(23 downto 16) <= wr_buf;
                        when "11" => avl_mem_wrdata(31 downto 24) <= wr_buf;
                                     avl_mem_write <= '1';
                        when others => avl_mem_write <= '0';
                    end case;
                else
                    avl_mem_write <= '0';
                end if;

                if wr_loop = 256 then
                    csr_pstate <= delay_wait;
                else
                    csr_pstate <= page_wr;
                end if;

            when page_rd_b1 =>
                op_done             <= '0';
                data_valid_cnt      <= (others => '0');
                cmd_idle            <= '0';
                avl_mem_addr        <= addr_buf(24 downto 2);
                if rdnum_buf <= 256 then
                    avl_mem_burstcount  <= CONV_STD_LOGIC_VECTOR(conv_integer(rdnum_buf(8 downto 2)),7);
                    rd_last             <= '1';
                else
                    rdnum_buf <= rdnum_buf - CONV_STD_LOGIC_VECTOR(256,13);        -- -256
                    addr_buf  <= addr_buf + CONV_STD_LOGIC_VECTOR(256,25);         -- +256
                    avl_mem_burstcount  <= CONV_STD_LOGIC_VECTOR(64,7);
                    rd_last <= '0';
                end if;
                csr_pstate <= page_rd;
            when page_rd =>
                cmd_idle            <= '0';

                if op_done = '0' then
                    avl_mem_read        <= '1';
                    op_done             <= '1';
                    avl_mem_byteenable  <= "1111";
                else
                    avl_mem_read        <= '0';
                    avl_mem_byteenable  <= (others => '0');
                    avl_mem_burstcount  <= (others => '0');
                    avl_mem_addr        <= (others => '0');
                end if;

                if avl_mem_rddata_valid = '1' then
                    rd_cnt              <= rd_cnt + '1';
                    rd_buf              <= avl_mem_rddata;
                    data_valid_cnt      <= (others => '1');
                elsif data_valid_cnt > 0 then
                    data_valid_cnt      <= data_valid_cnt - '1';
                end if;

                case data_valid_cnt is
                    when "11110" =>
                        flash2host <= rd_buf(0)&rd_buf(1)&rd_buf(2)&rd_buf(3)&rd_buf(4)&rd_buf(5)&rd_buf(6)&rd_buf(7);
                        data_valid <= '1';
                    when "10110" =>
                        flash2host <= rd_buf(8)&rd_buf(9)&rd_buf(10)&rd_buf(11)&rd_buf(12)&rd_buf(13)&rd_buf(14)&rd_buf(15);
                        data_valid <= '1';
                    when "01110" =>
                        flash2host <= rd_buf(16)&rd_buf(17)&rd_buf(18)&rd_buf(19)&rd_buf(20)&rd_buf(21)&rd_buf(22)&rd_buf(23);
                        data_valid <= '1';
                    when "00110" =>
                        flash2host <= rd_buf(24)&rd_buf(25)&rd_buf(26)&rd_buf(27)&rd_buf(28)&rd_buf(29)&rd_buf(30)&rd_buf(31);
                        data_valid <= '1';
                    when others =>
                        data_valid <= '0';
                end case;

                if rd_last = '0' then
                    if rd_cnt = 64 and data_valid_cnt = 0 then
                        rd_cnt <= (others => '0');
                        csr_pstate <= page_rd_b1;
                    else
                        csr_pstate <= page_rd;
                    end if;
                else
                    if rd_cnt = rdnum_buf(8 downto 2) and data_valid_cnt = 0 then
                        rd_cnt <= (others => '0');
                        csr_pstate <= idle;
                    else
                        csr_pstate <= page_rd;
                    end if;
                end if;


            when read_statusreg =>
                cmd_idle <= '0';
                case csr_step is
                    when X"0" =>
                        avl_csr_addr(3 downto 0) <= flash_command_setting_register;
                        avl_csr_wrdata(7 downto 0) <= X"05";
                        avl_csr_wrdata(10 downto 8) <= "000";
                        avl_csr_wrdata(11) <= '1';
                        avl_csr_wrdata(15 downto 12) <= X"1";
                        if op_done = '1' then
                            avl_csr_write <= '0';
                            csr_step <= csr_step + '1';
                            op_done <= '0';
                        else
                            op_done <= '1';
                            avl_csr_write <= '1';
                        end if;
                    when X"1" =>
                        avl_csr_addr(3 downto 0) <= flash_command_control_register;
                        avl_csr_wrdata <= (0 => '1',others => '0');
                        if op_done = '1' then
                            avl_csr_write <= '0';
                        else
                            op_done <= '1';
                            avl_csr_write <= '1';
                        end if;
                        if avl_csr_waitrequest_negedge = '1' then
                            csr_step <= csr_step + '1';
                            op_done <= '0';
                        end if;
                    when X"2" =>
                        avl_csr_addr(3 downto 0) <= Flash_Command_read_data0;
                        avl_csr_read <= '1';
                        csr_step <= csr_step + '1';
                    when X"3" =>
                        avl_csr_read <= '0';
                        if avl_csr_rddata_valid = '1' then
                            status_data(7) <= avl_csr_rddata(7);
                            status_data(6) <= avl_csr_rddata(6);
                            status_data(1) <= avl_csr_rddata(1);
                            status_data(0) <= avl_csr_rddata(0);
                            if status_data(5 downto 2) = avl_csr_rddata(5 downto 2) then
                                cmd_finished <= '1';
                                csr_pstate <= delay_wait1;
                            else
                                csr_pstate <= write_statusreg;
                            end if;
                            csr_step <= (others => '0');
                        end if;
                    when others =>
                        csr_step <= (others => '0');
                        csr_pstate <= idle;
                end case;

            when write_statusreg =>
                cmd_idle <= '0';
                case csr_step is
                    when X"0" =>
                        avl_csr_addr(3 downto 0) <= flash_command_setting_register;
                        avl_csr_wrdata(31 downto 8) <= (others => '0');
                        avl_csr_wrdata(7 downto 0) <= X"06";
                        if op_done = '1' then
                            avl_csr_write <= '0';
                            csr_step <= csr_step + '1';
                            op_done <= '0';
                        else
                            op_done <= '1';
                            avl_csr_write <= '1';
                        end if;
                    when X"1" =>
                        avl_csr_addr(3 downto 0) <= flash_command_control_register;
                        avl_csr_wrdata <= (0 => '1',others => '0');
                        if op_done = '1' then
                            avl_csr_write <= '0';
                        else
                            op_done <= '1';
                            avl_csr_write <= '1';
                        end if;
                        if avl_csr_waitrequest_negedge = '1' then
                            csr_step <= csr_step + '1';
                            op_done <= '0';
                        end if;
                    when X"2" =>
                        avl_csr_addr(3 downto 0) <= Flash_Command_write_data0;
                        avl_csr_wrdata(31 downto 8) <= (others => '0');
                        avl_csr_wrdata(7 downto 0) <= status_data;
                        -- avl_csr_wrdata(7 downto 0) <= (others => '0');
                        if op_done = '1' then
                            avl_csr_write <= '0';
                            csr_step <= csr_step + '1';
                            op_done <= '0';
                        else
                            op_done <= '1';
                            avl_csr_write <= '1';
                        end if;
                    when X"3" =>
                        avl_csr_addr(3 downto 0) <= flash_command_setting_register;
                        avl_csr_wrdata(7 downto 0) <= X"01";
                        avl_csr_wrdata(10 downto 8) <= "000";
                        avl_csr_wrdata(11) <= '0';
                        avl_csr_wrdata(15 downto 12) <= X"1";
                        if op_done = '1' then
                            avl_csr_write <= '0';
                            csr_step <= csr_step + '1';
                            op_done <= '0';
                        else
                            op_done <= '1';
                            avl_csr_write <= '1';
                        end if;
                    when X"4" =>
                        avl_csr_addr(3 downto 0) <= flash_command_control_register;
                        avl_csr_wrdata <= (0 => '1',others => '0');
                        if op_done = '1' then
                            avl_csr_write <= '0';
                        else
                            op_done <= '1';
                            avl_csr_write <= '1';
                        end if;
                        if avl_csr_waitrequest_negedge = '1' then
                            csr_step <= csr_step + '1';
                            op_done <= '0';
                        end if;
                    when others =>
                        csr_step <= (others => '0');
                        csr_pstate <= delay_wait;
                end case;

            when sector_earse =>
                cmd_idle <= '0';
                case csr_step is
                    when X"0" =>
                        avl_csr_addr(3 downto 0) <= flash_command_setting_register;
                        avl_csr_wrdata(31 downto 8) <= (others => '0');
                        avl_csr_wrdata(7 downto 0) <= X"06";
                        if op_done = '1' then
                            avl_csr_write <= '0';
                            csr_step <= csr_step + '1';
                            op_done <= '0';
                        else
                            op_done <= '1';
                            avl_csr_write <= '1';
                        end if;
                    when X"1" =>
                        avl_csr_addr(3 downto 0) <= flash_command_control_register;
                        avl_csr_wrdata <= (0 => '1',others => '0');
                        if op_done = '1' then
                            avl_csr_write <= '0';
                        else
                            op_done <= '1';
                            avl_csr_write <= '1';
                        end if;
                        if avl_csr_waitrequest_negedge = '1' then
                            csr_step <= csr_step + '1';
                            op_done <= '0';
                        end if;
                    when X"2" =>
                        avl_csr_addr(3 downto 0) <= flash_command_setting_register;
                        if cur_cmd(2) = '0' then
                            avl_csr_wrdata(7 downto 0) <= X"DC";       --64K earse
                        else
                            avl_csr_wrdata(7 downto 0) <= X"21";       --4K  earse
                        end if;
                        avl_csr_wrdata(10 downto 8) <= "100";
                        avl_csr_wrdata(11) <= '0';
                        avl_csr_wrdata(15 downto 12) <= X"0";
                        if op_done = '1' then
                            avl_csr_write <= '0';
                            csr_step <= csr_step + '1';
                            op_done <= '0';
                        else
                            op_done <= '1';
                            avl_csr_write <= '1';
                        end if;
                    when X"3" =>
                        avl_csr_addr(3 downto 0) <= Flash_Command_Address_Register;
                        avl_csr_wrdata(24 downto 0) <= addr_buf;
                        avl_csr_wrdata(31 downto 25) <= (others => '0');
                        if op_done = '1' then
                            avl_csr_write <= '0';
                            csr_step <= csr_step + '1';
                            op_done <= '0';
                        else
                            op_done <= '1';
                            avl_csr_write <= '1';
                        end if;
                    when X"4" =>
                        avl_csr_addr(3 downto 0) <= flash_command_control_register;
                        avl_csr_wrdata <= (0 => '1',others => '0');
                        if op_done = '1' then
                            avl_csr_write <= '0';
                        else
                            op_done <= '1';
                            avl_csr_write <= '1';
                        end if;
                        if avl_csr_waitrequest_negedge = '1' then
                            csr_step <= csr_step + '1';
                            op_done <= '0';
                        end if;
                    when others =>
                        csr_step <= (others => '0');
                        csr_pstate <= delay_wait;
                end case;

            when delay_wait =>
                wr_loop             <= (others => '0');
                avl_mem_byteenable  <= (others => '0');
                avl_mem_wrdata      <= (others => '0');
                avl_mem_addr        <= (others => '0');
                avl_mem_burstcount  <= (others => '0');
                avl_mem_read        <= '0';
                avl_mem_write       <= '0';
                if time_cnt(11) = '0' then
                    time_cnt <= time_cnt + '1';
                    avl_csr_addr        <= (others => '0');
                    avl_csr_wrdata      <= (others => '0');
                    avl_csr_write       <= '0';
                    avl_csr_read        <= '0';
                else
                    case csr_step is
                        when X"0" =>
                            avl_csr_addr(3 downto 0) <= flash_command_setting_register;
                            avl_csr_wrdata(7 downto 0) <= X"05";
                            avl_csr_wrdata(10 downto 8) <= "000";
                            avl_csr_wrdata(11) <= '1';
                            avl_csr_wrdata(15 downto 12) <= X"1";
                            if op_done = '1' then
                                avl_csr_write <= '0';
                                csr_step <= csr_step + '1';
                                op_done <= '0';
                            else
                                op_done <= '1';
                                avl_csr_write <= '1';
                            end if;
                        when X"1" =>
                            avl_csr_addr(3 downto 0) <= flash_command_control_register;
                            avl_csr_wrdata <= (0 => '1',others => '0');
                            if op_done = '1' then
                                avl_csr_write <= '0';
                            else
                                op_done <= '1';
                                avl_csr_write <= '1';
                            end if;
                            if avl_csr_waitrequest_negedge = '1' then
                                csr_step <= csr_step + '1';
                                op_done <= '0';
                            end if;
                        when X"2" =>
                            avl_csr_addr(3 downto 0) <= Flash_Command_read_data0;
                            avl_csr_read <= '1';
                            csr_step <= csr_step + '1';
                        when X"3" =>
                            avl_csr_read <= '0';
                            if avl_csr_rddata_valid = '1' then
                                if avl_csr_rddata(0) = '0' then
                                    csr_pstate <= delay_wait1;
                                    cmd_finished <= '1';
                                else
                                    csr_pstate <= delay_wait;
                                end if;
                                csr_step <= (others => '0');
                            end if;
                        when others =>
                            time_cnt <= (others => '0');
                            csr_step <= (others => '0');
                            csr_pstate <= idle;
                    end case;
                end if;
            when delay_wait1 =>
                delay_wait1_cnt <= delay_wait1_cnt + '1';
                time_cnt        <= (others => '0');
                cmd_timeout     <= '0';
                cmd_finished    <= '0';
                if delay_wait1_cnt(10) = '1' then -------- = 1024 then
                    csr_pstate  <= idle;
                else
                    csr_pstate  <= delay_wait1;
                end if;

            when others => csr_pstate <= idle;
        end case;

    end if;
end process;

end behav;