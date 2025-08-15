--#######################################################################
--
--  LOGIC CORE:          ctrl_flash
--  MODULE NAME:         ctrl_flash()
--  COMPANY:
--
--
--  REVISION HISTOY:
--
--  Revision 0.1  11/25/2008  Description: Initial .
--
--  FUNCTIONAL DESCRIPTION:
--
--  Copyright (C)
------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.PCK_CRC32_D8.all;


entity ctrl_flash is
generic(
		DUALBOOT_EN : STD_LOGIC := '1' ;
		F_PROTECT_ENABLE :std_logic := '1'
    );
port(
    nRST                 : in std_logic;
    sysclk               : in std_logic;
    time_ms_en           : in std_logic;

    flash_dl_req         : in std_logic;
    flash_dl_ack         : out std_logic;

    flash_dl_dpram_rdaddr: out std_logic_vector(8 downto 0);
    flash_dl_dpram_q     : in std_logic_vector(7 downto 0);

    flash_ul_rdreq       : out std_logic;
    flash_ul_rdack       : in std_logic;
    flash_ul_len         : out std_logic_vector(10 downto 0);

    flash_ul_dpram_data  : out std_logic_vector(7 downto 0);
    flash_ul_dpram_wraddr: out std_logic_vector(8 downto 0);
    flash_ul_dpram_wren  : out std_logic;

    --op_flash
    op_flash_req            : in  std_logic;
    op_flash_ack            : out std_logic;
    op_flash_end            : out std_logic;
    op_flash_cmd            : in  std_logic_vector(1 downto 0); --00:erase 01:write 10: read 11:crc
    op_flash_addr           : in  std_logic_vector(23 downto 0);
    op_flash_len            : in  std_logic_vector(10 downto 0);
    op_flash_crc            : in  std_logic_vector(31 downto 0);
    op_flash_crc_length     : in  std_logic_vector(23 downto 0);
    op_flash_rdaddr         : out std_logic_vector(10 downto 0);
    op_flash_q              : in  std_logic_vector(7 downto 0);
    op_flash_wren           : out std_logic;
    op_flash_wraddr         : out std_logic_vector(10 downto 0);
    op_flash_data           : out std_logic_vector(7 downto 0);

    update_crc_error     : out std_logic ;

    flash_timeout        : out std_logic;
    flash_finished       : out std_logic;

    spi_cmd_idle         : in std_logic;
    spi_cmd_en           : out std_logic;
    spi_cmd              : out std_logic_vector(2 downto 0);

    spi_cmd_timeout      : in std_logic;
    spi_cmd_finished     : in std_logic;

    spi_addr             : out std_logic_vector(23 downto 0);
    spi_rdnum            : out std_logic_vector(12 downto 0);
    spi_data_empty       : in std_logic;
    spi_data_en          : out std_logic;
    spi_host2flash       : out std_logic_vector(7 downto 0);
    spi_data_valid       : in std_logic;
    spi_flash2host       : in std_logic_vector(7 downto 0)
 );
 end entity;

architecture behav of ctrl_flash is

constant FLS_IDLE_CMD : std_logic_vector(1 downto 0):= "00";
constant FLS_ERASE_CMD: std_logic_vector(1 downto 0):= "01";
constant FLS_WRITE_CMD: std_logic_vector(1 downto 0):= "10";
constant FLS_OPR_CMD : std_logic_vector(1 downto 0):= "11";
signal next_state : std_logic_vector(1 downto 0):= FLS_IDLE_CMD;


constant PROT_TIM_WIDTH: integer := 18;
constant PROTECT_ALL   :  std_logic_vector(7 downto 0):=X"1C";
constant PROTECT_UPPER_HALF :  std_logic_vector(7 downto 0):=X"14";
signal prot_timeout             : std_logic_vector(PROT_TIM_WIDTH-1 downto 0):=(others=>'0'); ---about 5 minutes
signal prot_last_msb            : std_logic :='0';
signal rst_prot_timeo           : std_logic:='0';
signal flash_isnot_protected    : std_logic:='1';
signal flash_notfirst_eraseop   : std_logic:='0';
signal flash_prot_req           : std_logic:='0';
signal flash_prot_ack           : std_logic:='0';
signal flash_is_done            : std_logic:='0';
signal stop_prot_timeo          : std_logic:='0';
signal disable_prot_timeo       : std_logic:='0';


type state is (init,idle,
 op_flash_prepair,
 op_flash_prepair_a,
 flash_op_prepair,
 flash_erase,
 flash_write,
 flash_write_a,
 flash_write_a1,
 flash_read,
 flash_read_crc_b, flash_read_crc, flash_read_crc_wait,
 enable_writeprotect,disable_writeprotect,
 wait_result2
 );
signal pstate: state := init;

signal init_cnt                 : std_logic_vector( 11 downto 0):= (others => '0');
signal flash_cnt                : std_logic_vector(12 downto 0):=(others => '0');
signal flash_op_type            : std_logic_vector(7 downto 0):=(others => '0');
signal flash_addr               : std_logic_vector(23 downto 0):=(others => '0');

signal spi_empty_detect         : std_logic_vector(1 downto 0):="00";
signal cmd_idle_detect          : std_logic_vector(1 downto 0):="00";
signal spi_valid_detect         : std_logic_vector(1 downto 0):="00";
signal spi_valid_neg            : std_logic ;

----crc verify
signal crc_flash_addr           : std_logic_vector( 23 downto 0);
signal crc_length               : std_logic_vector( 23 downto 0);
signal crc_begin                : std_logic ;
signal forwardcrc               : std_logic_vector(31 downto 0):=(others => '0'); --spi flash data CRC
signal cnt_wait                 : std_logic_vector( 11 downto 0);
signal cnt_crc                  : std_logic_vector( 3 downto 0);
signal cnt_crc2                 : std_logic_vector( 23 downto 0);

signal crc_1                    : std_logic_vector(7 downto 0):=(others=>'0');
signal crc_2                    : std_logic_vector(7 downto 0):=(others=>'0');
signal crc_3                    : std_logic_vector(7 downto 0):=(others=>'0');
signal crc_4                    : std_logic_vector(7 downto 0):=(others=>'0');

---------------------
signal flash_dl_req_buf         : std_logic:= '0';
signal flash_dl_ack_buf         : std_logic:= '0';
signal flash_ul_rdreq_buf       : std_logic:= '0';
signal upgrade_addr             : std_logic_vector(23 downto 0):= x"010000";
signal flash_op_done            : std_logic ;
signal spi_rdnum_buf            : std_logic_vector(12 downto 0);

signal op_flash_doing           : std_logic:= '0';
signal op_flash_req_buf         : std_logic:= '0';
signal op_flash_ack_buf         : std_logic:= '0';
signal op_flash_cmd_buf         : std_logic_vector(1 downto 0):=(others=>'0');  --00:erase 01:write 10: read 11:crc
signal op_flash_addr_buf        : std_logic_vector(23 downto 0):=(others=>'0');
signal op_flash_len_buf         : std_logic_vector(10 downto 0):=(others=>'0');
signal op_flash_loop_cnt        : std_logic_vector(2 downto 0):=(others=>'0');
signal op_flash_loop_max        : std_logic_vector(2 downto 0):=(others=>'0');
signal op_flash_crc_buf         : std_logic_vector(31 downto 0):=(others=>'0');
signal op_flash_crc_length_buf  : std_logic_vector(23 downto 0):=(others=>'0');
begin
process(sysclk,nRST)
begin
    if nRST = '0' then
        op_flash_req_buf <= '0';

    elsif rising_edge(sysclk) then
        if op_flash_ack_buf = '1' then
            op_flash_req_buf <= '0';
        elsif op_flash_req = '1' then
            op_flash_req_buf <= '1';
        end if;

    end if;
end process;
op_flash_ack <= op_flash_ack_buf;


process(sysclk,nRST)
begin
    if nRST = '0' then
        op_flash_cmd_buf <= (others => '0');
        op_flash_addr_buf <= (others => '0');
        op_flash_len_buf <= (others => '0');
        op_flash_crc_buf <= (others => '0');
        op_flash_crc_length_buf <= (others => '0');

    elsif rising_edge(sysclk) then
        if op_flash_req_buf = '1' then
            op_flash_cmd_buf <= op_flash_cmd;
            op_flash_addr_buf <= op_flash_addr;
            op_flash_len_buf <= op_flash_len;
            op_flash_crc_buf <= op_flash_crc;
            op_flash_crc_length_buf <= op_flash_crc_length;
        end if;

    end if;
end process;



process(nRST,SYSCLK)
begin
    if nRST = '0' then
        prot_timeout  <= (PROT_TIM_WIDTH-1=>'0' ,(PROT_TIM_WIDTH-6) downto 0 =>'0',  others=>'1');
        prot_last_msb <= '0';

    elsif rising_edge(SYSCLK) then
        if rst_prot_timeo = '1' or flash_isnot_protected ='0' then
            prot_timeout  <= (others=>'0');
            prot_last_msb <= '0';
        else
            if prot_timeout(PROT_TIM_WIDTH-1) ='0' and time_ms_en = '1' and stop_prot_timeo = '0' and disable_prot_timeo ='0'  then
                prot_timeout <= prot_timeout + '1';
            end if;
            prot_last_msb <= prot_timeout(PROT_TIM_WIDTH-1);
        end if;

        if rst_prot_timeo = '1' or flash_isnot_protected ='0' then
            flash_prot_req <= '0';
        elsif prot_timeout(PROT_TIM_WIDTH-1) = '1' and prot_last_msb = '0' and disable_prot_timeo ='0'  then
            flash_prot_req <= '1';
        elsif flash_prot_ack = '1' then
            flash_prot_req <= '0';
        end if;
    end if;
end process;
disable_prot_timeo <= '0';




------------------------------
upgrade_addr <= x"010000";

flash_dl_ack <= flash_dl_ack_buf;
process(nRST,sysclk)
begin
    if nRST = '0' then
        flash_dl_req_buf   <= '0' ;
    elsif rising_edge(sysclk) then
        if( flash_dl_ack_buf = '1' )then
            flash_dl_req_buf <= '0' ;
        elsif( flash_dl_req = '1')then
            flash_dl_req_buf <= '1' ;
        end if;
    end if;
end process;

process(nRST,sysclk)
begin
    if nRST = '0' then
        flash_ul_rdreq   <= '0' ;
    elsif rising_edge(sysclk) then
        if( flash_ul_rdack = '1' )then
            flash_ul_rdreq <= '0' ;
        elsif( flash_ul_rdreq_buf = '1')then
            flash_ul_rdreq <= '1' ;
        end if;
    end if;
end process;


spi_rdnum <= spi_rdnum_buf;

process(nRST,SYSCLK)
begin
    if nRST = '0' then
    pstate <= init;

    init_cnt <= (others => '0');

    flash_addr <= (others => '0');

    spi_data_en <= '0';
    spi_cmd_en <= '0';
    spi_cmd <= (others=>'0');
    spi_addr <= (others => '0');

    spi_empty_detect <= "11";
    cmd_idle_detect <= "11";
    spi_valid_detect <= "00";
    spi_host2flash <= (others => '0');

    flash_cnt <= (others => '0');

    crc_length <= ( others => '0' );
    crc_flash_addr <= ( others => '0' );

    crc_begin <= '0' ;
    cnt_wait <= ( others => '0' );
    cnt_crc <= ( others => '0' );
    cnt_crc2 <= ( others => '0' );

    crc_1 <= (others => '0');
    crc_2 <= (others => '0');
    crc_3 <= (others => '0');
    crc_4 <= (others => '0');

    forwardcrc <= ( others => '1' );
    update_crc_error <= '1' ;
    spi_valid_neg <= '0' ;
    flash_ul_len <= (others => '0');

    rst_prot_timeo <= '0';
    stop_prot_timeo <= '1';
    flash_prot_ack <= '0';
    flash_is_done <= '0';
    flash_notfirst_eraseop <= '0';
    flash_op_done <= '0';
    op_flash_loop_max <= (others => '0');
    op_flash_loop_cnt <= (others => '0');


elsif rising_edge(SYSCLK) then

    flash_timeout <= spi_cmd_timeout;
    flash_finished <= spi_cmd_finished;

    case pstate is


        when init =>
                spi_cmd_en <= '0';
                spi_cmd <= (others=>'0');
                spi_data_en <= '0';
                spi_host2flash <= (others => '0');

                init_cnt <= init_cnt + '1';

                if init_cnt > X"FF0" then
                    pstate <= idle;
                else
                    pstate <= init;
                end if;


        when idle =>

                spi_cmd_en <= '0';
                spi_cmd <= (others=>'0');
                spi_data_en <= '0';
                flash_cnt <= (others => '0');

                forwardcrc <= ( others => '1' );

                crc_1 <= (others => '0');
                crc_2 <= (others => '0');
                crc_3 <= (others => '0');
                crc_4 <= (others => '0');

                cnt_crc <= ( others => '0' );
                cnt_crc2 <= ( others => '0' );

                flash_ul_dpram_wren <= '0';
                flash_ul_rdreq_buf <= '0';

                rst_prot_timeo <= '0';
                stop_prot_timeo <= '0';
                flash_is_done <= '0';
                next_state <= FLS_IDLE_CMD;
                flash_op_done <= '0';
                op_flash_doing <= '0';
                op_flash_end <= '0';
                op_flash_wren <= '0';
                op_flash_loop_max <= (others => '0');
                op_flash_loop_cnt <= (others => '0');

                if flash_dl_req_buf = '1' then
                    pstate <= flash_op_prepair;
                    flash_dl_ack_buf <= '1';

                    flash_prot_ack <= '0';
                elsif op_flash_req_buf = '1' then
                    pstate <= op_flash_prepair;
                    op_flash_ack_buf <= '1';

                elsif flash_prot_req = '1' and spi_cmd_idle = '1' and F_PROTECT_ENABLE = '1' then
                    pstate <= enable_writeprotect;
                    flash_prot_ack <= '1';

                    flash_dl_ack_buf <= '0';
                else
                    pstate <= idle;

                    flash_dl_ack_buf <= '0';
                    flash_prot_ack <= '0';
                end if;


        when enable_writeprotect =>

                    flash_is_done <= '0';
                    flash_isnot_protected <= '0';
                    flash_prot_ack <= '0';
                    if F_PROTECT_ENABLE ='0' then
                        pstate <= wait_result2;
                    else
                        -- spi_host2flash <= PROTECT_ALL;
                        spi_host2flash <=  (others => '0');
                        --spi_addr <= flash_addr;

                        if spi_cmd_idle = '1' then
                            spi_cmd_en <= '1';
                            spi_cmd <= "110" ;
                            flash_cnt <= flash_cnt + '1';
                        else
                            spi_cmd_en <= '0';
                            spi_cmd <= "000";
                            flash_cnt <= flash_cnt + '1';
                            -- if flash_cnt(9 downto 0) = 2 then
                                  pstate <= wait_result2;
                            -- else
                                 -- pstate <= enable_writeprotect;
                            -- end if;
                        end if;
                    end if;


        when disable_writeprotect =>

                flash_is_done <= '0';
                flash_notfirst_eraseop <= '1';
                flash_isnot_protected <= '1';
                if F_PROTECT_ENABLE ='0' then
                    pstate <= wait_result2;
                else
                    -- spi_host2flash <=  PROTECT_UPPER_HALF;
                    spi_host2flash <=  (others => '0');
                    --spi_addr <= flash_addr;

                    if spi_cmd_idle = '1' then
                        spi_cmd_en <= '1';
                        spi_cmd <= "110" ;
                        pstate <= disable_writeprotect;
                    else
                        spi_cmd_en <= '0';
                        spi_cmd <= "000";
                        flash_cnt <= flash_cnt + '1';
                        if flash_cnt(9 downto 0) = 2 then
                            pstate <= wait_result2;
                        else
                            pstate <= disable_writeprotect;
                        end if;
                    end if;
                end if;


        when    wait_result2 =>

                        flash_cnt <= (others=>'0');

                        if F_PROTECT_ENABLE ='0' then
                            case(next_state) is
                                when FLS_ERASE_CMD => pstate <= flash_erase;
                                --when FLS_WRITE_CMD => pstate <= flash_write;
                                when others=>   pstate <= idle;
                            end case;
                        else
                            if flash_is_done = '1'  then
                                if  spi_cmd_idle ='1' then
                                    case(next_state) is
                                       when FLS_ERASE_CMD => pstate <= flash_erase;
                                      -- when FLS_WRITE_CMD => pstate <= flash_write;
                                       when others=>   pstate <= idle;
                                    end case;
                                    flash_is_done <= '0';
                                else
                                     pstate <= wait_result2;
                                end if;
                            elsif spi_cmd_finished = '1' or spi_cmd_timeout = '1' then
                                flash_is_done <= '1';
                                pstate <= wait_result2;
                            else
                                pstate <= wait_result2;
                            end if;
                       end if;


        when  op_flash_prepair =>

                if op_flash_cmd_buf = "00" then
                    if flash_isnot_protected = '0' then
                        pstate <= disable_writeprotect;
                    else
                        pstate <= flash_erase;
                    end if;
                    flash_op_type <= X"32";
                    rst_prot_timeo <= '1';
                    next_state <= FLS_ERASE_CMD;
                elsif op_flash_cmd_buf = "01" then
                    pstate <= flash_write;
                    flash_op_type <= X"86";
                    rst_prot_timeo <= '1';
                elsif op_flash_cmd_buf = "10" then
                    pstate <= flash_read;
                    flash_op_type <= X"56";
                    stop_prot_timeo <= '1';
                elsif op_flash_cmd_buf = "11" then
                    pstate <= flash_read_crc_b;
                    flash_op_type <= X"87";
                else
                    pstate <= idle;
                end if;

                op_flash_ack_buf <= '0';
                op_flash_doing <= '1';
                spi_empty_detect <= "00";
                cmd_idle_detect <= "00";
                spi_data_en <= '0';
                op_flash_wren <= '0';
                flash_op_done <= '0';
                flash_addr <= op_flash_addr_buf;
                crc_flash_addr <= op_flash_addr_buf;
                crc_length <= op_flash_crc_length_buf;
                crc_1 <= op_flash_crc_buf(7 downto 0);
                crc_2 <= op_flash_crc_buf(15 downto 8);
                crc_3 <= op_flash_crc_buf(23 downto 16);
                crc_4 <= op_flash_crc_buf(31 downto 24);
                update_crc_error <= '0' ;
                op_flash_loop_max <= op_flash_len_buf(10 downto 8);
                op_flash_loop_cnt <= (others => '0');


        when op_flash_prepair_a =>
                --if spi_cmd_finished = '1' or spi_cmd_timeout = '1' then
                if spi_cmd_idle = '1' then
                    pstate <= idle;
                    op_flash_end <= '1';
                else
                    pstate <= op_flash_prepair_a;
                end if;


        when  flash_op_prepair =>

                if flash_cnt = 8 then
                    flash_cnt <= (others => '0');
                    if flash_op_type = X"32" then
                        if flash_isnot_protected = '0' or flash_notfirst_eraseop = '0' then
                            pstate <= disable_writeprotect;
                        else
                            pstate <= flash_erase;
                        end if;
                        rst_prot_timeo <= '1';
                        next_state <= FLS_ERASE_CMD;
                    elsif flash_op_type = X"86" then
                        pstate <= flash_write;
                        rst_prot_timeo <= '1';
                    elsif flash_op_type = X"56" then
                        pstate <= flash_read;
                        stop_prot_timeo <= '1';
                    elsif flash_op_type = X"87" then
                        pstate <= flash_read_crc;
                    else
                        pstate <= idle;
                    end if;
                else
                    flash_cnt <= flash_cnt + '1';
                    pstate <= flash_op_prepair;
                end if;

                flash_dl_ack_buf <= '0';
                spi_empty_detect <= "00";
                cmd_idle_detect <= "00";
                spi_data_en <= '0';
                flash_op_done <= '0';

                flash_dl_dpram_rdaddr <= flash_cnt(8 downto 0);

                if flash_cnt = 3 then
                    flash_op_type <= flash_dl_dpram_q;
                elsif flash_cnt = 4 then
                    flash_addr( 23 downto 16 ) <= flash_dl_dpram_q;
                elsif flash_cnt = 5 then
                    flash_addr(15 downto 8) <= flash_dl_dpram_q;
                elsif flash_cnt = 6 then
                    flash_addr(7 downto 0) <= flash_dl_dpram_q;
                else
                    flash_addr <= flash_addr ;
                end if;


        when  flash_erase =>

                spi_addr <= flash_addr ;

                if flash_cnt = 0 then
                    if spi_cmd_idle = '1' then
                        spi_cmd_en <= '1';
                        spi_cmd <= "001";
                        flash_cnt <= flash_cnt + '1';
                    end if;
                    pstate <= flash_erase;
                elsif flash_cnt = 1 then
                    spi_cmd_en <= '0';
                    spi_cmd <= "000";
                    flash_cnt <= flash_cnt + '1';
                    pstate <= flash_erase;
                elsif flash_cnt = 2 then
                    if op_flash_doing = '0' then
                        pstate <= idle;
                    else
                        pstate <= op_flash_prepair_a;
                    end if;
                    flash_cnt <= (others => '0');
                end if;

                flash_is_done <= '0';

        when flash_write =>

                spi_empty_detect <= spi_empty_detect(0)&spi_data_empty;
                cmd_idle_detect <= cmd_idle_detect(0)&spi_cmd_idle;
                spi_addr <= flash_addr ;
                -- if op_flash_doing = '0' then
                    spi_rdnum_buf <= '0'&X"100";
                -- else
                    -- spi_rdnum_buf <= "00"&op_flash_len_buf;
                -- end if;

                if spi_cmd_idle = '1' then
                    spi_cmd_en <= '1';
                    spi_cmd <= "010";
                    spi_data_en <= '0';
                else
                    spi_cmd_en <= '0';
                    spi_cmd <= "000";

                    if spi_empty_detect = "01" then
                        spi_data_en <= '1';
                        flash_cnt <= flash_cnt + '1';
                        if flash_cnt = spi_rdnum_buf -1 then
                            flash_op_done <= '1';
                        end if;
                    else
                        spi_data_en <= '0';
                    end if;
                end if;

                flash_dl_dpram_rdaddr <= flash_cnt(8 downto 0) + 4;
                op_flash_rdaddr <= op_flash_loop_cnt&flash_cnt(7 downto 0);
                if op_flash_doing = '0' then
                    spi_host2flash <= flash_dl_dpram_q;
                else
                    spi_host2flash <= op_flash_q;
                end if;

                if flash_op_done = '0' then
                    pstate <= flash_write;
                else
                    if op_flash_doing = '0' then
                        pstate <= idle;
                    else
                        pstate <= flash_write_a;
                    end if;
                end if;

                flash_is_done <= '0';


        when flash_write_a =>
                if op_flash_loop_cnt >= op_flash_loop_max - '1' then
                    pstate <= op_flash_prepair_a;
                    op_flash_loop_cnt <= (others => '0');
                else
                    pstate <= flash_write_a1;
                    op_flash_loop_cnt <= op_flash_loop_cnt + '1';
                end if;
                flash_cnt <= (others => '0');
                flash_addr <= flash_addr + x"000100";
                flash_op_done <= '0';


        when flash_write_a1 =>
                if spi_cmd_idle = '1' then
                    pstate <= flash_write;
                else
                    pstate <= flash_write_a1;
                end if;

        when flash_read =>

                spi_valid_detect <= spi_valid_detect(0)&spi_data_valid;
                spi_addr <= flash_addr ;
                if op_flash_doing = '0' then
                    spi_rdnum_buf <= "00001"&(X"00");
                else
                    spi_rdnum_buf <= "00"&op_flash_len_buf;
                end if;

                if spi_cmd_idle = '1' then
                    spi_cmd_en <= '1';
                    spi_cmd <= "011";
                    flash_cnt <= (others => '0');
                else
                    spi_cmd_en <= '0';
                    spi_cmd <= "000";

                    if spi_valid_detect = "01" then
                       flash_cnt <= flash_cnt + '1';
                       if op_flash_doing = '0' then
                            flash_ul_dpram_wren <= '1';
                            op_flash_wren <= '0';
                        else
                            flash_ul_dpram_wren <= '0';
                            op_flash_wren <= '1';
                        end if;
                        if flash_cnt = spi_rdnum_buf -1 then
                            flash_op_done <= '1';
                        end if;
                    else
                       flash_ul_dpram_wren <= '0';
                       op_flash_wren <= '0';
                    end if;
                end if;

                flash_ul_dpram_wraddr <= flash_cnt(8 downto 0);
                flash_ul_dpram_data <= spi_flash2host;
                op_flash_wraddr <= flash_cnt(10 downto 0);
                op_flash_data <= spi_flash2host;

                if( spi_valid_detect = "10")then
                    spi_valid_neg <= '1' ;
                else
                    spi_valid_neg <= '0' ;
                end if;

                -- if( spi_valid_neg = '1' )then
                    -- if( flash_cnt < 256 )then
                        -- pstate <= flash_read;
                        -- flash_ul_rdreq_buf <= '0';
                    -- else
                        -- pstate <= idle;
                        -- flash_ul_rdreq_buf <= '1';
                    -- end if;
                -- else
                    -- pstate <= flash_read;
                    -- flash_ul_rdreq_buf <= '0';
                -- end if;
                if flash_op_done = '0' then
                    pstate <= flash_read;
                    flash_ul_rdreq_buf <= '0';
                else
                    if op_flash_doing = '0' then
                        pstate <= idle;
                        flash_ul_rdreq_buf <= '1';
                    else
                        pstate <= op_flash_prepair_a;
                        flash_ul_rdreq_buf <= '0';
                    end if;
                end if;

                flash_ul_len <= "001"&x"00";

        when flash_read_crc_b =>

                spi_empty_detect <= "00";
                cmd_idle_detect <= "00";
                spi_data_en <= '0';

                update_crc_error <= '0' ;
    ---            crc_flash_addr <= upgrade_addr ;
                flash_dl_dpram_rdaddr <= flash_cnt(8 downto 0);
                IF DUALBOOT_EN ='0' then
                  crc_flash_addr <= (others=>'0')  ;   --- when DUALBOOT_EN = '0' else  upgrade_addr ;  --20170706
                else
                  crc_flash_addr <= upgrade_addr ;

                end if;
                if( flash_cnt >= 16)then
                    pstate <= flash_read_crc ;
                    flash_cnt <= ( others => '0' );
                else
                    pstate <= flash_read_crc_b ;
                    flash_cnt <= flash_cnt + '1' ;
                end if;

                if op_flash_doing = '0' then
                    if flash_cnt = 7 then
                        crc_length(23 downto 16) <= flash_dl_dpram_q;
                    elsif flash_cnt = 8 then
                        crc_length(15 downto 8) <= flash_dl_dpram_q;
                    elsif flash_cnt = 9 then
                        crc_length(7 downto 0) <= flash_dl_dpram_q;
                    elsif flash_cnt = 10 then
                        crc_1 <= flash_dl_dpram_q;
                    elsif flash_cnt = 11 then
                        crc_2 <= flash_dl_dpram_q;
                    elsif flash_cnt = 12 then
                        crc_3 <= flash_dl_dpram_q;
                    elsif flash_cnt = 13 then
                        crc_4 <= flash_dl_dpram_q;
                    end if;
                end if;

        when flash_read_crc =>

                spi_valid_detect <= spi_valid_detect(0)&spi_data_valid;
                spi_rdnum_buf <= "00100"&(X"00");
                spi_addr <= crc_flash_addr ;
                if spi_cmd_idle = '1' then
                    spi_cmd_en <= '1';
                    spi_cmd <= "011";
                    flash_cnt <= (others => '0');
                else
                    spi_cmd_en <= '0';
                    spi_cmd <= "000";

                    if spi_valid_detect = "01" then
                        flash_cnt <= flash_cnt + '1';

                        if( crc_begin = '1' )then
                            cnt_crc2 <= cnt_crc2 + '1' ;
                        end if;

                        if flash_cnt = spi_rdnum_buf -1 then
                            flash_op_done <= '1';
                        end if;
                    end if;
                end if;

                if( spi_valid_detect = "10")then
                    spi_valid_neg <= '1' ;
                else
                    spi_valid_neg <= '0' ;
                end if;

                if crc_begin = '1' and spi_valid_detect = "01" then
                    forwardcrc <= nextCRC32_D8(spi_flash2host,forwardcrc);
                else
                    if cnt_crc = 1 then
                        forwardcrc <= nextCRC32_D8(crc_1,forwardcrc);
                    elsif cnt_crc = 2 then
                        forwardcrc <= nextCRC32_D8(crc_2,forwardcrc);
                    elsif cnt_crc = 3 then
                        forwardcrc <= nextCRC32_D8(crc_3,forwardcrc);
                    elsif cnt_crc = 4 then
                        forwardcrc <= nextCRC32_D8(crc_4,forwardcrc);
                    end if;
                end if;


                -- if( spi_valid_neg = '1' )then
                    -- if( flash_cnt = 1024 )then
                        -- if( cnt_crc2 >= crc_length )then
                            -- if( cnt_crc >= 6 )then
                                -- pstate <= idle;
                            -- else
                                -- pstate <= flash_read_crc;
                            -- end if;
                        -- else
                            -- pstate <= flash_read_crc_wait;
                        -- end if;
                    -- else
                        -- pstate <= flash_read_crc;
                    -- end if;
                -- else
                    -- pstate <= flash_read_crc;
                -- end if;

                if flash_op_done = '1' then
                    if( cnt_crc2 >= crc_length )then
                        if( cnt_crc >= 6 )then
                            if op_flash_doing = '0' then
                                pstate <= idle;
                            else
                                pstate <= op_flash_prepair_a;
                            end if;
                        else
                            pstate <= flash_read_crc;
                        end if;
                    else
                        pstate <= flash_read_crc_wait;
                    end if;
                else
                    pstate <= flash_read_crc;
                end if;


                if cnt_crc2 = crc_length then
                    crc_begin <= '0';
                    if cnt_crc = 7 then
                        cnt_crc <= x"7" ;
                    else
                        cnt_crc <= cnt_crc + '1';
                    end if;


                    if cnt_crc = 5 then
                        if forwardcrc = X"C704DD7B" then
                            update_crc_error <='1' ;
                        else
                            update_crc_error <= '0' ;
                        end if;
                    end if ;

                elsif( spi_valid_neg = '1' )then
                    if( flash_cnt = 1024 )then
                        crc_begin <= '0';
                    end if;
                else
                    if flash_cnt = 0 then
                        crc_begin <= '1';
                    end if;
                end if;

        when flash_read_crc_wait =>

                flash_cnt <= (others => '0');
                flash_op_done <= '0';

                if cnt_wait = 1023 then
                    cnt_wait  <= (others => '0');
                    pstate <= flash_read_crc;
                elsif cnt_wait = 1022 then
                    crc_flash_addr <= crc_flash_addr + X"400";
                    cnt_wait <= cnt_wait + '1';
                    pstate <= flash_read_crc_wait;
                else
                    pstate <= flash_read_crc_wait;
                    cnt_wait <= cnt_wait + '1';
                end if;
                spi_valid_detect  <= (others => '0');
        when others => null;

    end case;

end if;
end process;


end behav;
