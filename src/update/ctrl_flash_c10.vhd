--#######################################################################
--
--  LOGIC CORE:          ctrl_flash_c10
--  MODULE NAME:         ctrl_flash_c10()
--  COMPANY:
--
--
--  REVISION HISTORY:
--
--  Revision 0.1  07/20/2007    Description: Initial .
--
--  FUNCTIONAL DESCRIPTION:
--
--  this module is to operate the spi-flash
--
--  Copyright (C)   Shenzhen ColorLight Tech. Inc.
--
--#######################################################################


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.PCK_CRC32_D8.all;



entity ctrl_flash_c10 is
generic(
    FLASH_PROTECT_EN                    : std_logic:= '1';
	FLASH_PROTECT_ALL                   : std_logic:= '0';---'1':protect all, '0':protect half,only protect backup
    ADDR_W_INBYTE                       : integer:= 25;
    DATA_W                              : integer:= 32
);
port(
    nRST                                : in  std_logic;
    sysclk                              : in  std_logic;
    time_ms_en                          : in  std_logic;
    --user
    op_flash_req                        : in  std_logic;
    op_flash_ack                        : out std_logic;
    op_flash_end                        : out std_logic;
    op_flash_cmd                        : in  std_logic_vector(1 downto 0); --"00":crc      "01":erase sector   "10":page wr    "11":page rd
    op_flash_addr                       : in  std_logic_vector(ADDR_W_INBYTE-1 downto 0);
    op_flash_len                        : in  std_logic_vector(ADDR_W_INBYTE-1 downto 0);
    op_flash_crc                        : in  std_logic_vector(31 downto 0);
    op_flash_raddr                      : out std_logic_vector(8-2-1 downto 0);         --2clk
    op_flash_q                          : in  std_logic_vector(DATA_W-1 downto 0);
    op_flash_wren                       : out std_logic;
    op_flash_waddr                      : out std_logic_vector(8 downto 0);
    op_flash_data                       : out std_logic_vector(DATA_W-1 downto 0);
    --54991
    config_rdreq                        : in  std_logic;
    config_rdack                        : out std_logic;
    config_rdaddr                       : in  std_logic_vector(ADDR_W_INBYTE-1 downto 0);
    config_rdlen                        : in  std_logic_vector(12 downto 0);
    --info
    update_crc_right                    : out std_logic;
    update_prog_done                    : out std_logic;--It is not used in the slow upgrade, so don't care.
    update_crc_done                     : out std_logic;
    update_erase_done                   : out std_logic;

    --flash
    spi_init_done                       : in  std_logic;
    spi_cmd_req                         : out std_logic;
    spi_cmd_ack                         : in  std_logic;
    spi_cmd_end                         : in  std_logic;
    spi_cmd_type                        : out std_logic_vector(1 downto 0); --"00":wr protect   "01":erase sector   "10":page wr    "11":page rd
    spi_addr                            : out std_logic_vector(ADDR_W_INBYTE-1 downto 0);
    spi_length                          : out std_logic_vector(8 downto 0); --no more than 256
    spi_protect_flag                    : out std_logic;        --  '0': only protect half  '1':protect all
    spi_host2flash_rden                 : in  std_logic;
    spi_host2flash_en                   : out std_logic;
    spi_host2flash                      : out std_logic_vector(DATA_W-1 downto 0);
    spi_flash2host_en                   : in  std_logic;
    spi_flash2host                      : in  std_logic_vector(DATA_W-1 downto 0)
);
end entity;

architecture behav of ctrl_flash_c10 is


constant FLASH_PROTECT_W                : integer:= 18;
signal timeout_req                      : std_logic;
signal timeout_cnt                      : std_logic_vector(12 downto 0);
signal timeout_en                       : std_logic;
signal config_rdack_buf                 : std_logic;

type state is(
    init,
    idle,
    rcv_cmd,
    flash_protect,
    flash_protect_a,
    page_wr,
    page_wr_a,
    page_rd,
    page_rd_a,
    erase_sector,
    erase_sector_a,
    erase_sector_loop,
    flash_crc_check,
    flash_crc_check_a,
    flash_crc_check_loop,
    flash_crc_check_loop_a
);
signal pstate                           : state := init;
signal cmd_type                         : std_logic_vector(1 downto 0);
signal flash_addr                       : std_logic_vector(ADDR_W_INBYTE-1 downto 0);
signal flash_cnt                        : std_logic_vector(5 downto 0);
signal flash_crc                        : std_logic_vector(31 downto 0);
signal flash_loop_cnt                   : std_logic_vector(ADDR_W_INBYTE-8-1 downto 0);
signal flash_crc_loop_end               : std_logic;
signal crc_en                           : std_logic;
signal crc_en_buf                       : std_logic;
signal crc_tail_en                      : std_logic;
signal crc_loop                         : std_logic_vector(2 downto 0);
signal crc_buf                          : std_logic_vector(31 downto 0);
signal forwardcrc                       : std_logic_vector(31 downto 0);
signal flash_protect_status             : std_logic;        --'0':no protect '1':protect
signal flash_protect_req                : std_logic;
signal flash_protect_ack                : std_logic;
signal flash_protect_timeout_cnt        : std_logic_vector(FLASH_PROTECT_W-1 downto 0);

signal buf_op_flash_raddr               : std_logic_vector(8-2-1 downto 0);
signal buf_op_flash_waddr               : std_logic_vector(8 downto 0);
signal flash_protect_notify                 : std_logic;




begin

config_rdack <= config_rdack_buf;
process(sysclk,nRST)
begin
    if nRST = '0' then
        pstate <= init;

        op_flash_ack <= '0';
        op_flash_end <= '0';
        op_flash_wren <= '0';
        spi_cmd_req <= '0';
        spi_host2flash_en <= '0';

        crc_en <= '0';
        crc_tail_en <= '0';
        update_crc_done <= '1';
        update_prog_done <= '1';
        update_erase_done <= '1';
        flash_protect_status <= '0';

        timeout_req <= '0';
        config_rdack_buf <= '0';
		flash_protect_notify <= '0';

    elsif rising_edge(sysclk) then
        case pstate is
            when init =>
                    if spi_init_done = '1' then
                        pstate <= idle;
                    else
                        pstate <= init;
                    end if;


            when idle =>
                    if config_rdreq = '1' and config_rdack_buf = '0' then
                        pstate <= page_rd;
                    elsif op_flash_req = '1' then
                        pstate <= rcv_cmd;
                        op_flash_ack <= '1';
                    elsif flash_protect_req = '1' and flash_protect_status = '0' and FLASH_PROTECT_EN = '1' then
                        pstate <= flash_protect;
                    else
                        pstate <= idle;
                        op_flash_ack <= '0';
                    end if;


                    if config_rdreq = '1' then
                        flash_addr <= config_rdaddr;
                        cmd_type <= "11";
                    else
                        flash_addr <= op_flash_addr;
                        cmd_type <= op_flash_cmd;
                    end if;
                    -- flash_len <= op_flash_len;
                    if config_rdreq = '1' then
                        flash_loop_cnt(ADDR_W_INBYTE-8-1 downto 5) <= (others => '0');
                        flash_loop_cnt(4 downto 0) <= config_rdlen(12 downto 8) - '1';
                    elsif op_flash_cmd = "01" then --erase
                        flash_loop_cnt(ADDR_W_INBYTE-8-1 downto ADDR_W_INBYTE-16) <= (others => '0');
                        flash_loop_cnt(ADDR_W_INBYTE-16-1 downto 0) <= op_flash_len(ADDR_W_INBYTE-1 downto 16) - '1';
                    else--if op_flash_cmd = "00" then   --crc
                        flash_loop_cnt <= op_flash_len(ADDR_W_INBYTE-1 downto 8) - '1';
                    end if;
                    flash_crc <= op_flash_crc;

                    op_flash_end <= '0';
                    op_flash_wren <= '0';
                    spi_cmd_req <= '0';
                    spi_host2flash_en <= '0';
                    buf_op_flash_raddr <= (others => '0');
                    buf_op_flash_waddr <= (others => '0');

                    crc_en <= '0';
                    crc_tail_en <= '0';
                    update_crc_done <= '1';
                    update_erase_done <= '1';

                    timeout_req <= '0';
                    config_rdack_buf <= '0';
					flash_protect_notify <= '0';


            when rcv_cmd =>
                    if cmd_type = "00" then
                        pstate <= flash_crc_check;
                    elsif cmd_type = "01" then
                        if flash_protect_status = '1' and FLASH_PROTECT_EN = '1' and FLASH_PROTECT_ALL = '1' then
                            pstate <= flash_protect;
                        else
                            pstate <= erase_sector;
                        end if;
                    elsif cmd_type = "10" then
                        if flash_protect_status = '1' and FLASH_PROTECT_EN = '1' and FLASH_PROTECT_ALL = '1' then
                            pstate <= flash_protect;
                        else
                            pstate <= page_wr;
                        end if;
                    -- elsif cmd_type = "11" then   pstate <= page_rd;
                    else
                        pstate <= page_rd;
                    end if;

                    op_flash_ack <= '0';
                    timeout_req <= '0';


            when flash_protect =>
                    pstate <= flash_protect_a;

                    spi_cmd_req <= '1';
                    spi_cmd_type <= "00";
					if FLASH_PROTECT_ALL = '1' then
						spi_protect_flag <= not flash_protect_status;
					else
						spi_protect_flag <= '0';
					end if;

                    timeout_req <= '1';


            when flash_protect_a =>
                    if spi_cmd_end = '1' or timeout_en = '1' then
                        if flash_protect_status = '0' then
                            pstate <= idle;
                        else
                            if cmd_type = "01" then
                                pstate <= erase_sector;
                            else--if cmd_type = "10" then
                                pstate <= page_wr;
                            end if;
                        end if;

                        spi_cmd_req <= '0';
                        timeout_req <= '0';

                        if spi_cmd_end = '1' then
                            flash_protect_status <= not flash_protect_status;
                        end if;
                    else
                        pstate <= flash_protect_a;
                        if spi_cmd_ack = '1' then
                            spi_cmd_req <= '0';
                        end if;
                    end if;


            when erase_sector =>
                    pstate <= erase_sector_a;

                    spi_cmd_req <= '1';
                    spi_cmd_type <= cmd_type;
                    spi_addr <= flash_addr;

                    timeout_req <= '1';
                    update_erase_done <= '0';
                    update_prog_done <= '0';

            when erase_sector_a =>
                    if spi_cmd_end = '1' or timeout_en = '1' then
                        pstate <= erase_sector_loop;
                        spi_cmd_req <= '0';
                        timeout_req <= '0';
                    else
                        pstate <= erase_sector_a;
                        if spi_cmd_ack = '1' then
                            spi_cmd_req <= '0';
                        end if;
                    end if;


            when erase_sector_loop =>
                    if flash_crc_loop_end = '1' then
                        pstate <= idle;
                        op_flash_end <= '1';
                        flash_loop_cnt <= (others => '0');
                    else
                        pstate <= erase_sector;
                        flash_loop_cnt <= flash_loop_cnt - '1';
                    end if;
                    flash_addr(ADDR_W_INBYTE-1 downto 16) <= flash_addr(ADDR_W_INBYTE-1 downto 16) + '1';


            when page_wr =>
                    pstate <= page_wr_a;

                    spi_cmd_req <= '1';
                    spi_cmd_type <= cmd_type;
                    spi_addr <= flash_addr;

                    timeout_req <= '1';


            when page_wr_a =>
                    if spi_cmd_end = '1' or timeout_en = '1' then
                        pstate <= idle;
                        spi_cmd_req <= '0';
                        timeout_req <= '0';
                        op_flash_end <= '1';
                        update_prog_done <= '1';
                    else
                        pstate <= page_wr_a;
                        if spi_cmd_ack = '1' then
                            spi_cmd_req <= '0';
                        end if;
                    end if;

                    spi_host2flash_en <= spi_host2flash_rden;
                    if spi_host2flash_rden = '1' then
                        buf_op_flash_raddr <= buf_op_flash_raddr + '1';
                    end if;


            when page_rd =>

                    pstate <= page_rd_a;

                    spi_cmd_req <= '1';
                    spi_cmd_type <= cmd_type;
                    spi_addr <= flash_addr;

                    timeout_req <= '1';


            when page_rd_a =>
                    if timeout_en = '1' then
                        pstate <= idle;
                        spi_cmd_req <= '0';
                        timeout_req <= '0';
                        op_flash_end <= '1';
                    elsif spi_cmd_end = '1' then
                        timeout_req <= '0';
                        if flash_crc_loop_end = '1' then
                            pstate <= idle;
                            spi_cmd_req <= '0';
                            op_flash_end <= '1';
                            config_rdack_buf <= '1';
                        else
                            flash_loop_cnt(4 downto 0) <= flash_loop_cnt(4 downto 0) - '1';
                            pstate <= page_rd;
                            flash_addr(ADDR_W_INBYTE-1 downto 8) <= flash_addr(ADDR_W_INBYTE-1 downto 8) + '1';
                        end if;
                    else
                        pstate <= page_rd_a;
                        if spi_cmd_ack = '1' then
                            spi_cmd_req <= '0';
                        end if;
                    end if;

                    op_flash_wren <= spi_flash2host_en;
                    if spi_flash2host_en = '1' then
                        buf_op_flash_waddr <= buf_op_flash_waddr + '1';
                    end if;
                    op_flash_waddr <= buf_op_flash_waddr;

            when flash_crc_check =>
                    pstate <= flash_crc_check_a;

                    spi_cmd_req <= '1';
                    spi_cmd_type <= "11";
                    spi_addr <= flash_addr;

                    update_crc_done <= '0';
                    timeout_req <= '1';
                    crc_en <= '1';


            when flash_crc_check_a =>
                    if spi_cmd_end = '1' or timeout_en = '1' then
                        pstate <= flash_crc_check_loop;
                        spi_cmd_req <= '0';
                        timeout_req <= '0';
                    else
                        pstate <= flash_crc_check_a;
                        if spi_cmd_ack = '1' then
                            spi_cmd_req <= '0';
                        end if;
                    end if;


            when flash_crc_check_loop =>
                    if flash_crc_loop_end = '1' then
                        pstate <= flash_crc_check_loop_a;
                        flash_loop_cnt <= (others => '0');
                    else
                        pstate <= flash_crc_check;
                        flash_loop_cnt <= flash_loop_cnt - '1';
                    end if;
                    flash_addr(ADDR_W_INBYTE-1 downto 8) <= flash_addr(ADDR_W_INBYTE-1 downto 8) + '1';


            when flash_crc_check_loop_a =>
                    if flash_loop_cnt(3) = '1' then
                        pstate <= idle;
                        op_flash_end <= '1';
						flash_protect_notify <= '1';
                    else
                        pstate <= flash_crc_check_loop_a;
                    end if;
                    flash_loop_cnt(3 downto 0) <= flash_loop_cnt(3 downto 0) + '1';

                    if flash_loop_cnt(3 downto 0) = "0011" then
                        crc_tail_en <= '1';
                    else
                        crc_tail_en <= '0';
                    end if;


            when others =>
                    pstate <= idle;


        end case;

        op_flash_data <= spi_flash2host;
    end if;
end process;
spi_length <= "100000000";
op_flash_raddr <= buf_op_flash_raddr;
spi_host2flash <= op_flash_q;



process(sysclk,nRST)
begin
    if nRST = '0' then
        crc_en_buf <= '0';
        crc_loop <= (others => '1');

        update_crc_right <= '0';

    elsif rising_edge(sysclk) then
        crc_en_buf <= crc_en;

        if spi_flash2host_en = '1' then
            crc_loop <= (others => '0');
            crc_buf <= spi_flash2host;
        elsif crc_tail_en = '1' then
            crc_loop <= (others => '0');
            crc_buf <= flash_crc;
        else
            if crc_loop(2) = '0' then
                crc_loop <= crc_loop + '1';
            end if;

            crc_buf(23 downto 0) <= crc_buf(31 downto 8);
        end if;

        if crc_en = '0' then
            forwardcrc <= (others => '1');
        else
            if crc_loop(2) = '0' then
                forwardcrc <= nextCRC32_D8(crc_buf(7 downto 0),forwardcrc);
            end if;
        end if;

        if crc_en = '0' and crc_en_buf = '1' then
            if forwardcrc = X"C704DD7B" then
                update_crc_right <= '1';
            else
                update_crc_right <= '0';
            end if;
        end if;
    end if;
end process;



process(sysclk,nRST)
begin
    if nRST = '0' then
        timeout_cnt <= (others => '0');
        timeout_en <= '0';

        flash_crc_loop_end <= '0';

        flash_protect_req <= '1';


    elsif rising_edge(sysclk) then
        if timeout_req = '0' then
            timeout_cnt <= (others => '0');
            timeout_en <= '0';
        else
            if time_ms_en = '1' and timeout_cnt(12) = '0' then
                timeout_cnt <= timeout_cnt + '1';
            end if;
            timeout_en <= timeout_cnt(12);
        end if;

        if flash_loop_cnt = 0 then
            flash_crc_loop_end <= '1';
        else
            flash_crc_loop_end <= '0';
        end if;

        if flash_protect_status = '1' or op_flash_req = '1' then
            flash_protect_timeout_cnt <= (others => '0');
            flash_protect_req <= '0';
        else
            if flash_protect_timeout_cnt(FLASH_PROTECT_W-1) = '0' and time_ms_en = '1' then
                flash_protect_timeout_cnt <= flash_protect_timeout_cnt + '1';
            end if;

            if flash_protect_timeout_cnt(FLASH_PROTECT_W-1) = '1' or flash_protect_notify = '1' then
                flash_protect_req <= '1';
            end if;
        end if;

    end if;
end process;




end behav;
