library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity xgmii_sink is
port(
    xgmii_rx_clk            : in  std_logic;
    reset                   : in  std_logic;
    
    rx_enh_data_valid       : in  std_logic ;                      -- rx_enh_data_valid
    rx_enh_fifo_full        : in  std_logic ;                      -- rx_enh_fifo_full
    rx_enh_fifo_empty       : in  std_logic ;                      -- rx_enh_fifo_empty
    rx_enh_fifo_del         : in  std_logic ;                      -- rx_enh_fifo_del
    rx_enh_fifo_insert      : in  std_logic ;                      -- rx_enh_fifo_insert
    rx_enh_highber          : in  std_logic ;                      -- rx_enh_highber
    rx_enh_blk_lock         : in  std_logic ;     
   
    xgmii_rx_d              : in  std_logic_vector(63 downto 0);
    xgmii_rx_c              : in  std_logic_vector(7  downto 0);
    status                  : out std_logic_vector(4 downto 0)  
    
);
end entity;

architecture behav of xgmii_sink is

constant BYTE_NUM                    : integer:= 8;

-- constant XGMII_IDLE_C             : std_logic_vector(BYTE_NUM-1 downto 0):= x"FF";
-- constant XGMII_PREAMABLE_C        : std_logic_vector(BYTE_NUM-1 downto 0):= x"01";
-- constant XGMII_DATA_C             : std_logic_vector(BYTE_NUM-1 downto 0):= x"00";
-- constant XGMII_EFD_C              : std_logic_vector(BYTE_NUM-1 downto 0):= x"FF";
-- constant XGMII_IDLE_D             : std_logic_vector(BYTE_NUM*8-1 downto 0):= x"0707070707070707";
-- constant XGMII_PREAMABLE_D        : std_logic_vector(BYTE_NUM*8-1 downto 0):= x"ABAAAAAAAAAAAAFB";
-- constant XGMII_EFD_D              : std_logic_vector(BYTE_NUM*8-1 downto 0):= x"07070707070707FD";
constant XGMII_IDLE_C               : std_logic_vector(BYTE_NUM-1 downto 0):= x"FF";
constant XGMII_PREAMABLE_C          : std_logic_vector(BYTE_NUM-1 downto 0):= x"01";
constant XGMII_DATA_C               : std_logic_vector(BYTE_NUM-1 downto 0):= x"00";
constant XGMII_EFD_C                : std_logic_vector(BYTE_NUM-1 downto 0):= x"FF";
constant XGMII_IDLE_D               : std_logic_vector(BYTE_NUM*8-1 downto 0):= x"0707070707070707";
constant XGMII_PREAMABLE_D          : std_logic_vector(BYTE_NUM*8-1 downto 0):= x"D5555555555555FB";
constant XGMII_EFD_D                : std_logic_vector(BYTE_NUM*8-1 downto 0):= x"07070707070707FD";

signal data_c                       : std_logic_vector(BYTE_NUM-1 downto 0);
signal data_d                       : std_logic_vector(BYTE_NUM*8-1 downto 0);
signal buf1_data_c                  : std_logic_vector(BYTE_NUM-1 downto 0);
signal buf_data_c                   : std_logic_vector(BYTE_NUM-1 downto 0);
signal buf_data_d                   : std_logic_vector(BYTE_NUM*8-1 downto 0);
signal buf1_data_d                  : std_logic_vector(BYTE_NUM*8-1 downto 0);

signal idle_en                      : std_logic:= '0';
signal head_en                      : std_logic:= '0';
signal data_en                      : std_logic:= '0';
signal efd_en                       : std_logic:= '0';

signal data_buffer                  : std_logic_vector(BYTE_NUM*8-1 downto 0);
signal data_plug                    : std_logic:= '0';
signal data_err                     : std_logic:= '0';
signal align                        : std_logic_vector(7 downto 0):=(others=>'0');
signal xgmii_rx_d_d1                : std_logic_vector(63 downto 0):=(others=>'0');
signal data_align                   : std_logic_vector(63 downto 0):=(others=>'0');
signal xgmii_rx_c_d1                : std_logic_vector(7 downto 0):=(others=>'0');
signal data_c_align                 : std_logic_vector(7 downto 0):=(others=>'0');

begin

DATA_RCV: for i in 0 to BYTE_NUM-1 generate

data_c(i) <= data_c_align(i);
data_d(i*8+7 downto i*8) <= data_align (8*i+7 downto 8*i);

end generate DATA_RCV;

process(xgmii_rx_clk,reset)
begin   
if reset = '1' then
elsif rising_Edge(xgmii_rx_clk) then
	xgmii_rx_c_d1 <= xgmii_rx_c;
	xgmii_rx_d_d1 <= xgmii_rx_d;
	if xgmii_rx_c(0) = '1' and xgmii_rx_d(0*8 + 7 downto 0*8) = x"FB" then
		align <= (0=>'1',others=> '0');
	elsif xgmii_rx_c(1) = '1' and xgmii_rx_d(1*8 + 7 downto 1*8) = x"FB" then
		align <= (1=>'1',others=> '0');
	elsif xgmii_rx_c(2) = '1' and xgmii_rx_d(2*8 + 7 downto 2*8) = x"FB" then
		align <= (2=>'1',others=> '0');
	elsif xgmii_rx_c(3) = '1' and xgmii_rx_d(3*8 + 7 downto 3*8) = x"FB" then
		align <= (3=>'1',others=> '0');
	elsif xgmii_rx_c(4) = '1' and xgmii_rx_d(4*8 + 7 downto 4*8) = x"FB" then
		align <= (4=>'1',others=> '0');
	elsif xgmii_rx_c(5) = '1' and xgmii_rx_d(5*8 + 7 downto 5*8) = x"FB" then
		align <= (5=>'1',others=> '0');
	elsif xgmii_rx_c(6) = '1' and xgmii_rx_d(6*8 + 7 downto 6*8) = x"FB" then
		align <= (6=>'1',others=> '0');
	elsif xgmii_rx_c(7) = '1' and xgmii_rx_d(7*8 + 7 downto 7*8) = x"FB" then
		align <= (7=>'1',others=> '0');
	end if;
	
	case align is
		when x"01" => 
			data_align   <= xgmii_rx_d_d1;
			data_c_align <= xgmii_rx_c_d1;
		when x"02" =>
			data_align   <= xgmii_rx_d(7 downto 0)&xgmii_rx_d_d1(63 downto 8);
			data_c_align <= xgmii_rx_c(0)& xgmii_rx_c_d1(7 downto 1);
		when x"04" =>
			data_align <= xgmii_rx_d(15 downto 0)&xgmii_rx_d_d1(63 downto 16);
			data_c_align <= xgmii_rx_c(1 downto 0)& xgmii_rx_c_d1(7 downto 2);
		when x"08" =>
			data_align <= xgmii_rx_d(23 downto 0)&xgmii_rx_d_d1(63 downto 24);
			data_c_align <= xgmii_rx_c(2 downto 0)& xgmii_rx_c_d1(7 downto 3);
		when x"10" =>
			data_align <= xgmii_rx_d(31 downto 0)&xgmii_rx_d_d1(63 downto 32);
			data_c_align <=xgmii_rx_c(3 downto 0)& xgmii_rx_c_d1(7 downto 4);
		when x"20" =>
			data_align <= xgmii_rx_d(39 downto 0)&xgmii_rx_d_d1(63 downto 40);
			data_c_align <=xgmii_rx_c(4 downto 0)& xgmii_rx_c_d1(7 downto 5);
		when x"40" =>
			data_align <= xgmii_rx_d(47 downto 0)&xgmii_rx_d_d1(63 downto 48);
			data_c_align <=xgmii_rx_c(5 downto 0)& xgmii_rx_c_d1(7 downto 6);
		when x"80" =>
			data_align <= xgmii_rx_d(55 downto 0)&xgmii_rx_d_d1(63 downto 56);
			data_c_align <=xgmii_rx_c(6 downto 0)& xgmii_rx_c_d1(7);
		when others=>
			data_align   <= xgmii_rx_d_d1;
			data_c_align <= xgmii_rx_c_d1;
	end case;
end if;
end process;

--check symbol
process(xgmii_rx_clk,reset)
begin   
    if reset = '1' then
        buf1_data_c <= (others => '0');
        buf_data_c <= (others => '0');
        buf_data_d <= (others => '0');
        buf1_data_d <= (others => '0');
        data_buffer <= (others => '0');
        
        data_plug <= '0';
        data_err <= '0';
        
    elsif rising_Edge(xgmii_rx_clk) then
        buf_data_c <= data_c;
        buf1_data_c <= buf_data_c;
        buf_data_d <= data_d;
        buf1_data_d <= buf_data_d;
        
        if (data_c = XGMII_DATA_C) and (buf_data_c = XGMII_DATA_C) and (buf1_data_c = XGMII_DATA_C) then
            data_plug <= '1';
        else
            data_plug <= '0';
        end if;
        
        data_buffer <= buf1_data_d + '1';
        if data_plug = '1' then            
            if data_buffer = buf1_data_d then
                data_err <= '0';
            else
                data_err <= '1';
            end if;
        end if;
    
    end if;
end process;

status <= data_err&efd_en&data_en&head_en&idle_en;

end behav;

