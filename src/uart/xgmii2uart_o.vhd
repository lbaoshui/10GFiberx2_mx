

library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_arith.all ;
use ieee.std_logic_unsigned.all ;

entity xgmii2uart is
generic
(
    port_num            : integer:= 0
);
port
(
    nRST                : in  std_logic;
    sysclk              : in  std_logic;
    nRST_rxclk          : in  std_logic;
    rxclk               : in  std_logic;
    nRST_txclk          : in  std_logic;
    txclk               : in  std_logic;
    xgmii_tx_data       : in  std_logic_vector(63 downto 0);
    xgmii_tx_ctrl       : in  std_logic_vector(7 downto 0);
    xgmii_rx_updata     : in  std_logic_vector(63 downto 0);
    xgmii_rx_upctrl     : in  std_logic_vector(7 downto 0);
    cur_slot_num        : in  std_logic_vector(3 downto 0);

    eth_link            : out std_logic_vector(9 downto 0);
    err_num_fiber       : out std_logic_vector(31 downto 0);
    subframe_FB         : out std_logic;


    Up_ack              : in  std_logic;
    Up_req              : out std_logic;
    Up_ReadEn_o         : in  std_logic;
    Up_ReadLength_i     : out std_logic_vector(10 downto 0);
    Up_ReadAddr_o       : in  std_logic_vector(10 downto 0);
    Up_ReadData_i       : out std_logic_vector(7 downto 0)  ---latency is 2 ,after Up_ReadAddr_o;

);
end xgmii2uart;

architecture beha of xgmii2uart IS

signal conv_dpram_wdata     : std_logic_vector(63 downto 0);
signal conv_dpram_wdata_buf : std_logic_vector(63 downto 0);
signal conv_dpram_wren      : std_logic;
signal conv_dpram_wren_d1   : std_logic;
signal conv_dpram_addr_a    : std_logic_vector(7 downto 0);
signal conv_dpram_addr_b    : std_logic_vector(10 downto 0);
signal conv_dpram_q         : std_logic_vector(7 downto 0);

component uart_conv_dpram is
    port (
        data_a    : in  std_logic_vector(63 downto 0) := (others => 'X'); -- datain_a
        q_a       : out std_logic_vector(63 downto 0);                    -- dataout_a
        data_b    : in  std_logic_vector(7 downto 0)  := (others => 'X'); -- datain_b
        q_b       : out std_logic_vector(7 downto 0);                     -- dataout_b
        address_a : in  std_logic_vector(7 downto 0)  := (others => 'X'); -- address_a
        address_b : in  std_logic_vector(10 downto 0) := (others => 'X'); -- address_b
        wren_a    : in  std_logic                     := 'X';             -- wren_a
        wren_b    : in  std_logic                     := 'X';             -- wren_b
        clock_a   : in  std_logic                     := 'X';             -- clk
        clock_b   : in  std_logic                     := 'X'              -- clk
    );
end component uart_conv_dpram;

signal xgmii_rx_updata_d1   : std_logic_vector(63 downto 0);
signal xgmii_rx_upctrl_d1   : std_logic;
signal xgmii_rx_upctrl_d2   : std_logic;
signal CHLNUM               : std_logic_vector(7 downto 0);
signal frame_type           : std_logic_vector(7 downto 0);
signal subframe_FB_en       : std_logic;
signal frame_length0        : std_logic_vector(11-1 downto 0);
signal frame_length1        : std_logic_vector(11-1 downto 0);
signal last_bnum            : std_logic_vector(3-1 downto 0);
signal frame_wcnt           : std_logic_vector(3-1 downto 0);
signal frame_done_rxclk     : std_logic_vector(2 downto 0);
signal frame_done_d1        : std_logic;
signal frame_done_d2        : std_logic;
signal frame_done_d3        : std_logic;
--signal q_detect_valid       : std_logic;
signal wait_cnt             : std_logic_vector(20 downto 0);
signal wait_cnt_d1          : std_logic;
signal source_MAC           : std_logic_vector(7 downto 0);
signal target_MAC           : std_logic_vector(7 downto 0);
signal source_MAC1          : std_logic_vector(47 downto 0);
signal target_MAC1          : std_logic_vector(47 downto 0);

signal q_detect_wren        : std_logic;
signal q_detect_q           : std_logic_vector(7 downto 0);
signal q_detect_wraddr      : std_logic_vector(7 downto 0);
signal q_detect_rdaddr      : std_logic_vector(10 downto 0);

signal head_en              : std_logic;
signal frame_07en           : std_logic;
signal frame_07en_d1        : std_logic;
signal frame_07en_d2        : std_logic;
signal frame_07en_d3        : std_logic;
signal quick_detect_en      : std_logic;
signal q_det_length         : std_logic_vector(7 downto 0);
signal err_num_fiber_buf    : std_logic_vector(31 downto 0);
signal err_num_plus         : std_logic_vector(31 downto 0);
signal CHLNUM_qdet          : std_logic_vector(7 downto 0);

begin


process(txclk,nRST_txclk)
begin
    if nRST_txclk = '0' then
        head_en <= '0';
        frame_07en <= '0';
        quick_detect_en <= '0';
    elsif rising_edge(txclk) then
        if xgmii_tx_ctrl = X"01" then
            head_en <= '1';
        else
            head_en <= '0';
        end if;
        if head_en = '1' and xgmii_tx_data(39 downto 32) = X"07" then
            frame_07en <= '1';
        elsif xgmii_tx_ctrl /= 0 then
            frame_07en <= '0';
        end if;
        if head_en = '1' and xgmii_tx_data(39 downto 32) = X"07" then
            q_detect_wraddr <= (others => '0');
        elsif frame_07en = '1' then
            q_detect_wraddr <= q_detect_wraddr + '1';
        end if;
        if frame_07en = '1' and q_detect_wraddr = 0 then
            q_det_length <= xgmii_tx_data(31 downto 24);
        end if;
        if frame_07en = '1' and q_detect_wraddr = 0 then
            quick_detect_en <= xgmii_tx_data(16);
        elsif head_en = '1' and (xgmii_tx_data(39 downto 32) /= X"01" and xgmii_tx_data(39 downto 32) /= X"54" and xgmii_tx_data(39 downto 32) /= X"55" and xgmii_tx_data(39 downto 32) /= X"07") then
            quick_detect_en <= '0';
        end if;
        if head_en = '1' and xgmii_tx_data(39 downto 32) = X"07" then
            if port_num = 0 then
                CHLNUM_qdet <= xgmii_tx_data(23 downto 16);
            else
                CHLNUM_qdet <= xgmii_tx_data(23 downto 16) + conv_std_logic_vector(10,8);
            end if;
        end if;
    end if;
end process;

q_det_dpram_inst : uart_conv_dpram
    port map (
        data_a    => xgmii_tx_data,
        q_a       => open,
        data_b    => (others => '0'),
        q_b       => q_detect_q,
        address_a => q_detect_wraddr,
        address_b => q_detect_rdaddr,
        wren_a    => frame_07en,
        wren_b    => '0',
        clock_a   => txclk,
        clock_b   => sysclk
    );

process(rxclk)
begin
    if rising_edge(rxclk) then
        xgmii_rx_updata_d1 <= xgmii_rx_updata;
        conv_dpram_wren_d1 <= conv_dpram_wren;
        xgmii_rx_upctrl_d1 <= xgmii_rx_upctrl(7);
        xgmii_rx_upctrl_d2 <= xgmii_rx_upctrl_d1;
    end if;
end process;

conv_dpram_wdata <= (xgmii_rx_updata(31 downto 0)&xgmii_rx_updata_d1(63 downto 32)) when xgmii_rx_upctrl_d2 = '0' else conv_dpram_wdata_buf;
process(xgmii_rx_upctrl)
begin
    case xgmii_rx_upctrl is
        when "10000000" => last_bnum <= conv_std_logic_vector(7,3);
        when "11000000" => last_bnum <= conv_std_logic_vector(6,3);
        when "11100000" => last_bnum <= conv_std_logic_vector(5,3);
        when "11110000" => last_bnum <= conv_std_logic_vector(4,3);
        when "11111000" => last_bnum <= conv_std_logic_vector(3,3);
        when "11111100" => last_bnum <= conv_std_logic_vector(2,3);
        when "11111110" => last_bnum <= conv_std_logic_vector(1,3);
        when others =>     last_bnum <= conv_std_logic_vector(0,3);
    end case;
end process;
process(rxclk,nRST_rxclk)
begin
    if nRST_rxclk = '0' then
        conv_dpram_wren <= '0';
        frame_done_rxclk <= (others => '1');
        subframe_FB_en <= '0';
        --q_detect_valid <= '0';
        conv_dpram_addr_a <= conv_std_logic_vector(3,8);
    elsif rising_edge(rxclk) then
        if xgmii_rx_upctrl(7) = '1' and xgmii_rx_upctrl_d1 = '0' then
            frame_wcnt <= (others => '0');
        elsif frame_wcnt(2) = '0' then
            frame_wcnt <= frame_wcnt + '1';
        end if;
        if xgmii_rx_upctrl = X"01" or frame_wcnt < 3 then
            conv_dpram_wren <= '1';
        elsif xgmii_rx_upctrl(7) = '1' then
            conv_dpram_wren <= '0';
        end if;
        if frame_wcnt = 0 then
            conv_dpram_addr_a <= conv_std_logic_vector(0,8);
        elsif conv_dpram_wren_d1 = '1' then
            conv_dpram_addr_a <= conv_dpram_addr_a + '1';
        end if;
        if conv_dpram_wren = '1' and conv_dpram_wren_d1 = '0' and xgmii_rx_upctrl(7) = '0' then
            frame_type <= xgmii_rx_updata(39 downto 32);
            if port_num = 0 then
                CHLNUM <= xgmii_rx_updata(23 downto 16);
            else
                CHLNUM <= xgmii_rx_updata(23 downto 16) + conv_std_logic_vector(10,8);
            end if;
            source_MAC <= xgmii_rx_updata(7 downto 0);
            target_MAC <= xgmii_rx_updata(15 downto 8);
        end if;
        if source_MAC = X"FF" then
            source_MAC1 <= X"FFFFFFFFFFFF";
        elsif source_MAC = X"22" then
            source_MAC1 <= X"665544332222";
        else
            source_MAC1 <= X"665544332211";
        end if;
        if target_MAC = X"FF" then
            target_MAC1 <= X"FFFFFFFFFFFF";
        elsif target_MAC = X"22" then
            target_MAC1 <= X"665544332222";
        else
            target_MAC1 <= X"665544332211";
        end if;
        if frame_type = X"D4" and conv_dpram_addr_a = 4 and xgmii_rx_updata(39 downto 32) = X"FB" then
            subframe_FB_en <= '1';
        elsif frame_wcnt = 3 then
            subframe_FB_en <= '0';
        end if;
        if quick_detect_en = '1' then
            --frame_length0(10 downto 8) <= (others => '0');
            --frame_length0(7 downto 0) <= q_det_length + X"9";
            frame_length0 <= conv_std_logic_vector(64,11);
        elsif xgmii_rx_upctrl(7) = '1' and xgmii_rx_upctrl_d1 = '0' then
            frame_length0 <= (conv_dpram_addr_a - X"02")&"000" + X"11" + last_bnum;
        end if;
        --frame_length1 <= frame_length0 - X"8";
        case frame_wcnt is
            when "010" => conv_dpram_wdata_buf <= X"EE0"&'0'&frame_length0&X"0000000000";
            when "011" => conv_dpram_wdata_buf <= q_det_length&"000000"&quick_detect_en&'1'&X"00"&CHLNUM&"00000"&frame_length0&X"0000";
            when others => conv_dpram_wdata_buf <= X"000080000000001"&cur_slot_num;
        end case;
        if frame_wcnt = 3 and subframe_FB_en = '0' then
            frame_done_rxclk <= (others => '0');
        elsif frame_done_rxclk(2) = '0' then
            frame_done_rxclk <= frame_done_rxclk + '1';
        end if;
    end if;
end process;
subframe_FB <= subframe_FB_en ;--when err_num_plus /= X"FFFFFFFF" else '0';

process(rxclk,nRST_rxclk)
begin
    if nRST_rxclk = '0' then
        eth_link <= (others => '0');
        err_num_fiber_buf <= (others => '0');
        --err_num_plus <= (others => '0');
    elsif rising_edge(rxclk) then
        if subframe_FB_en = '1' then
            if conv_dpram_addr_a = 5 then
                eth_link <= xgmii_rx_updata(25 downto 16);
            end if;
            if conv_dpram_addr_a = 6 then
                err_num_fiber_buf <= xgmii_rx_updata(63 downto 32);
                --err_num_plus <= xgmii_rx_updata(63 downto 32) - err_num_fiber_buf;
            end if;
        end if;
    end if;
end process;
err_num_fiber <= err_num_fiber_buf;

uart_conv_dpram_inst : uart_conv_dpram
    port map (
        data_a    => conv_dpram_wdata,
        q_a       => open,
        data_b    => (others => '0'),
        q_b       => conv_dpram_q,
        address_a => conv_dpram_addr_a,
        address_b => conv_dpram_addr_b,
        wren_a    => conv_dpram_wren_d1,
        wren_b    => '0',
        clock_a   => rxclk,
        clock_b   => sysclk
    );

Up_ReadLength_i <= frame_length0 + conv_std_logic_vector(15,11);
process(sysclk,nRST)
begin
    if nRST = '0' then
        Up_req <= '0';
    elsif rising_edge(sysclk) then
        frame_done_d1 <= frame_done_rxclk(2);
        frame_done_d2 <= frame_done_d1;
        frame_done_d3 <= frame_done_d2;
        frame_07en_d1 <= frame_07en;
        frame_07en_d2 <= frame_07en_d1;
        frame_07en_d3 <= frame_07en_d2;
        if frame_done_d3 > frame_done_d2 or frame_07en_d3 = '1' then
            wait_cnt <= (others => '0');
        elsif wait_cnt(20) = '0' then
            wait_cnt <= wait_cnt + '1';
        end if;
        wait_cnt_d1 <= wait_cnt(20);
        if frame_done_d3 > frame_done_d2 or (quick_detect_en = '1' and wait_cnt(20) > wait_cnt_d1) then
            Up_req <= '1';
        elsif Up_ack = '1' then
            Up_req <= '0';
        end if;
        if frame_done_d3 > frame_done_d2 or (quick_detect_en = '1' and wait_cnt(20) > wait_cnt_d1) then
            q_detect_rdaddr <= conv_std_logic_vector(4,11);
        elsif Up_ReadEn_o = '1' and Up_ReadAddr_o > 23 then
            q_detect_rdaddr(10 downto 1) <= q_detect_rdaddr(10 downto 1) + '1';
        end if;
        if quick_detect_en = '0' then
            if Up_ReadAddr_o < 36 then
                conv_dpram_addr_b <= Up_ReadAddr_o;
            else
                conv_dpram_addr_b <= Up_ReadAddr_o - conv_std_logic_vector(12,11);
            end if;
            if Up_ReadAddr_o >= 24 and Up_ReadAddr_o < 36 then
                if Up_ReadAddr_o = 24 then
                    Up_ReadData_i <= source_MAC1(7 downto 0);
                elsif Up_ReadAddr_o = 25 then
                    Up_ReadData_i <= source_MAC1(15 downto 8);
                elsif Up_ReadAddr_o = 26 then
                    Up_ReadData_i <= source_MAC1(23 downto 16);
                elsif Up_ReadAddr_o = 27 then
                    Up_ReadData_i <= source_MAC1(31 downto 24);
                elsif Up_ReadAddr_o = 28 then
                    Up_ReadData_i <= source_MAC1(39 downto 32);
                elsif Up_ReadAddr_o = 29 then
                    Up_ReadData_i <= source_MAC1(47 downto 40);
                elsif Up_ReadAddr_o = 30 then
                    Up_ReadData_i <= target_MAC1(7 downto 0);
                elsif Up_ReadAddr_o = 31 then
                    Up_ReadData_i <= target_MAC1(15 downto 8);
                elsif Up_ReadAddr_o = 32 then
                    Up_ReadData_i <= target_MAC1(23 downto 16);
                elsif Up_ReadAddr_o = 33 then
                    Up_ReadData_i <= target_MAC1(31 downto 24);
                elsif Up_ReadAddr_o = 34 then
                    Up_ReadData_i <= target_MAC1(39 downto 32);
                else
                    Up_ReadData_i <= target_MAC1(47 downto 40);
                end if;
            else
                Up_ReadData_i <= conv_dpram_q;
            end if;
        else
            if Up_ReadAddr_o <= 23 then
                conv_dpram_addr_b <= Up_ReadAddr_o;
            else
                conv_dpram_addr_b(10 downto 8) <= (others => '0');
                conv_dpram_addr_b(7 downto 0) <= q_detect_q + X"19";
            end if;
            if wait_cnt(20) = '0' then
                Up_ReadData_i <= conv_dpram_q;
            else
                case Up_ReadAddr_o(7 downto 0) is
                    when X"00" => Up_ReadData_i <= X"1"&cur_slot_num;
                    when X"05" => Up_ReadData_i <= X"80";
                    when X"0D" => Up_ReadData_i <= frame_length0(7 downto 0);
                    when X"0E" => Up_ReadData_i <= "00000"&frame_length0(10 downto 8);
                    when X"0F" => Up_ReadData_i <= X"EE";
                    when X"12" => Up_ReadData_i <= frame_length0(7 downto 0);
                    when X"13" => Up_ReadData_i <= "00000"&frame_length0(10 downto 8);
                    when X"14" => Up_ReadData_i <= CHLNUM_qdet;
                    when X"16" => Up_ReadData_i <= X"02";
                    when X"17" => Up_ReadData_i <= q_det_length;
                    when others =>Up_ReadData_i <= X"00";
                end case;
            end if;
        end if;
    end if;
end process;

end beha;