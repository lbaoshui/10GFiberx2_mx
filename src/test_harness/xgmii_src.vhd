library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity xgmii_src is
port(
    xgmii_tx_clk            : in  std_logic;
    reset                   : in  std_logic;
    
    tx_enh_data_valid       : out  std_logic;                      -- tx_enh_fifo_full
    tx_enh_fifo_full        : in  std_logic ;                      -- tx_enh_fifo_full
    tx_enh_fifo_pfull       : in  std_logic ;                      -- tx_enh_fifo_pfull
    tx_enh_fifo_empty       : in  std_logic ;                      -- tx_enh_fifo_empty
    tx_enh_fifo_pempty      : in  std_logic ;                      -- tx_enh_fifo_pempty

    frame_req               : in  std_logic;
    frame_ack               : out std_logic;
    frame_done              : out std_logic;
    frame_free              : out std_logic;
    frame_length            : in  std_logic_vector(13 downto 0);        --not 0
    frame_type              : in  std_logic_vector(3 downto 0);

    xgmii_tx_d              : out std_logic_vector(64-1 downto 0);
    xgmii_tx_c              : out std_logic_vector(8-1 downto 0)
    
);
end entity;

architecture behav of xgmii_src is

constant BYTE_NUM                                   : integer:= 8;

constant XGMII_IDLE_C               : std_logic_vector(BYTE_NUM-1 downto 0):= x"FF";
constant XGMII_PREAMABLE_C          : std_logic_vector(BYTE_NUM-1 downto 0):= x"01";
constant XGMII_DATA_C               : std_logic_vector(BYTE_NUM-1 downto 0):= x"00";
constant XGMII_EFD_C                : std_logic_vector(BYTE_NUM-1 downto 0):= x"FF";
constant XGMII_IDLE_D               : std_logic_vector(BYTE_NUM*8-1 downto 0):= x"0707070707070707";
constant XGMII_PREAMABLE_D          : std_logic_vector(BYTE_NUM*8-1 downto 0):= x"D5555555555555FB";
constant XGMII_EFD_D                : std_logic_vector(BYTE_NUM*8-1 downto 0):= x"07070707070707FD";

type state is (
    FRAME_IDLE,
    FRAME_PREAMABLE,
    FRAME_DATA,
    FRAME_TURN,
    FRAME_EFD
);
signal pstate                                       : state:= FRAME_IDLE;

signal data_c                                       : std_logic_vector(BYTE_NUM-1 downto 0):= XGMII_IDLE_C;
signal data_d                                       : std_logic_vector(BYTE_NUM*8-1 downto 0):= XGMII_IDLE_D;

signal frame_length_buf                             : std_logic_vector(13 downto 0):= (others => '1');
signal frame_cnt                                    : std_logic_vector(13 downto 0):= (others => '0');

signal data_buf                                     : std_logic_vector(BYTE_NUM*8-1 downto 0):= (others => '0');

signal trans_begin                                  : std_logic :='0';
signal nxt_w                                        : std_logic ;
begin

tx_enh_data_valid <= '1'; ---(not tx_enh_fifo_pfull) and trans_begin;
nxt_w             <= '1'; ----not tx_enh_fifo_pfull;       

--pstate
process(xgmii_tx_clk,reset)
begin
    if reset = '1' then
        pstate <= FRAME_IDLE;
        data_c <= XGMII_IDLE_C;
        data_d <= XGMII_IDLE_D;
        frame_ack <= '0';
        frame_done <= '0';
        frame_free <= '0';
        
        frame_length_buf <= (others => '1');
        frame_cnt <= (others => '0');
        
        data_buf <= (others => '0');
        trans_begin <= '0';

    elsif rising_edge(xgmii_tx_clk) then
      
        case pstate is 
            when FRAME_IDLE =>
                    if frame_req = '1' then
                        pstate <= FRAME_PREAMABLE;
                        frame_ack <= '1';
                        frame_free <= '0';
                        trans_begin <= '1';
                    else
                        pstate <= FRAME_IDLE;
                        frame_ack <= '0';
                        frame_free <= '1';
                        trans_begin <= '0';
                    end if;
                    
                    data_c <= XGMII_IDLE_C;
                    data_d <= XGMII_IDLE_D;
                    frame_done <= '0';
                    frame_length_buf <= frame_length - '1';
                    frame_cnt <= (others => '0');
            
            when FRAME_PREAMABLE =>
                   if nxt_w  = '1' then   
                        pstate <= FRAME_DATA;
                   end if;
                    frame_ack <= '0';
                    
                    data_c <= XGMII_PREAMABLE_C;
                    data_d <= XGMII_PREAMABLE_D;
            
            when FRAME_DATA =>
                    if nxt_w = '1' then 
                        if frame_cnt >= frame_length_buf then
                            pstate <= FRAME_EFD;
                            frame_cnt <= (others => '0');
                        else
                            pstate <= FRAME_DATA;
                            frame_cnt <= frame_cnt + '1';
                        end if;
                    end if;
                    
                    data_c <= XGMII_DATA_C;
                    data_d <= data_buf;
                    
                    data_buf <= data_buf + '1';
            
            when FRAME_EFD =>
                    if nxt_w = '1' then 
                        pstate <= FRAME_TURN;
                        trans_begin <= '0';
                    end if;
                    data_c <= XGMII_EFD_C;
                    data_d <= XGMII_EFD_D;
                    frame_done <= '1';
            
            when FRAME_TURN =>
                    pstate      <= FRAME_IDLE;
                    trans_begin <= '0';
                    data_c      <= XGMII_IDLE_C;
                    data_d      <= XGMII_IDLE_D;
                    
            when others =>
                    trans_begin <= '0';
                    pstate <= FRAME_IDLE;
                    data_c <= XGMII_IDLE_C;
                    data_d <= XGMII_IDLE_D;
                    
                    frame_ack <= '0';
                    frame_done <= '0';
                    frame_free <= '0';
                    
                    frame_length_buf <= (others => '1');
                    frame_cnt <= (others => '0');

        end case;   
    end if;
end process;
 
xgmii_tx_c<= data_c;
xgmii_tx_d<= data_d;

end behav;

