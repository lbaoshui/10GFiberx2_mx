library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity serdes_datain is
generic
(
    BKHSSI_NUM : integer := 2
);
port
(
    reconfclk                   : in std_logic;
    refclk                      : in std_logic;
    rx_serial_data              : in std_logic_vector(BKHSSI_NUM-1 downto 0)  := (others => 'X');

    rx_clk                      : out std_logic_vector(BKHSSI_NUM-1 downto 0);
    rx_parallel_data            : out std_logic_vector(BKHSSI_NUM*64-1 downto 0);
    rx_control                  : out std_logic_vector(BKHSSI_NUM*8-1 downto 0);

    rx_enh_data_valid           : out std_logic_vector(BKHSSI_NUM-1 downto 0);
    rx_enh_fifo_full            : out std_logic_vector(BKHSSI_NUM-1 downto 0);
    rx_enh_fifo_empty           : out std_logic_vector(BKHSSI_NUM-1 downto 0);
    rx_enh_fifo_del             : out std_logic_vector(BKHSSI_NUM-1 downto 0);
    rx_enh_fifo_insert          : out std_logic_vector(BKHSSI_NUM-1 downto 0);
    rx_enh_highber              : out std_logic_vector(BKHSSI_NUM-1 downto 0);
    rx_enh_blk_lock             : out std_logic_vector(BKHSSI_NUM-1 downto 0);

    phy_reset                   : in std_logic;
	
	serdes_rxlock               : out std_logic_vector(BKHSSI_NUM-1 downto 0)
);
end serdes_datain;

architecture behaviour of serdes_datain is

component trans_phy is
port (
	rx_analogreset          : in  std_logic_vector(BKHSSI_NUM-1 downto 0)   := (others => 'X'); -- rx_analogreset
	rx_digitalreset         : in  std_logic_vector(BKHSSI_NUM-1 downto 0)   := (others => 'X'); -- rx_digitalreset
	rx_cal_busy             : out std_logic_vector(BKHSSI_NUM-1 downto 0);                      -- rx_cal_busy
	rx_cdr_refclk0          : in  std_logic                      := 'X';             -- clk
	rx_serial_data          : in  std_logic_vector(BKHSSI_NUM-1 downto 0)   := (others => 'X'); -- rx_serial_data
	rx_is_lockedtoref       : out std_logic_vector(BKHSSI_NUM-1 downto 0);                      -- rx_is_lockedtoref
	rx_is_lockedtodata      : out std_logic_vector(BKHSSI_NUM-1 downto 0);                      -- rx_is_lockedtodata
	rx_coreclkin            : in  std_logic_vector(BKHSSI_NUM-1 downto 0)   := (others => 'X'); -- clk
	rx_clkout               : out std_logic_vector(BKHSSI_NUM-1 downto 0);                      -- clk
	rx_pma_div_clkout       : out std_logic_vector(BKHSSI_NUM-1 downto 0);                      -- clk
	rx_parallel_data        : out std_logic_vector(BKHSSI_NUM*64-1 downto 0);                    -- rx_parallel_data
	rx_control              : out std_logic_vector(BKHSSI_NUM*8-1 downto 0);                     -- rx_control
	unused_rx_parallel_data : out std_logic_vector(255 downto 0);                    -- unused_rx_parallel_data
	unused_rx_control       : out std_logic_vector(47  downto 0);                     -- unused_rx_control
	rx_enh_data_valid       : out std_logic_vector(BKHSSI_NUM-1 downto 0);                      -- rx_enh_data_valid
	rx_enh_fifo_full        : out std_logic_vector(BKHSSI_NUM-1 downto 0);                      -- rx_enh_fifo_full
	rx_enh_fifo_empty       : out std_logic_vector(BKHSSI_NUM-1 downto 0);                      -- rx_enh_fifo_empty
	rx_enh_fifo_del         : out std_logic_vector(BKHSSI_NUM-1 downto 0);                      -- rx_enh_fifo_del
	rx_enh_fifo_insert      : out std_logic_vector(BKHSSI_NUM-1 downto 0);                      -- rx_enh_fifo_insert
	rx_enh_highber          : out std_logic_vector(BKHSSI_NUM-1 downto 0);                      -- rx_enh_highber
	rx_enh_blk_lock         : out std_logic_vector(BKHSSI_NUM-1 downto 0)                      -- rx_enh_blk_lock
	--reconfig_clk            : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- clk
	--reconfig_reset          : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- reset
	--reconfig_write          : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- write
	--reconfig_read           : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- read
	-- reconfig_address        : in  std_logic_vector(12 downto 0)  := (others => 'X'); -- address
	--reconfig_writedata      : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- writedata
	--reconfig_readdata       : out std_logic_vector(31 downto 0);                     -- readdata
	--reconfig_waitrequest    : out std_logic_vector(0 downto 0)                       -- waitrequest
);
end component trans_phy;

signal rx_coreclkin            :    std_logic_vector(BKHSSI_NUM-1 downto 0)   := (others => 'X'); -- clk
signal rx_clkout               :    std_logic_vector(BKHSSI_NUM-1 downto 0);                      -- clk
signal rx_is_lockedtoref       :    std_logic_vector(BKHSSI_NUM-1 downto 0);
signal rx_pma_clkout           : std_logic_vector(BKHSSI_NUM-1 downto 0);

signal reconfig_clk            : std_logic_vector(0 downto 0)   := (others => 'X'); -- clk
signal reconfig_reset          : std_logic_vector(0 downto 0)   := (others => 'X'); -- reset
signal reconfig_write          : std_logic_vector(0 downto 0)   := (others => 'X'); -- write
signal reconfig_read           : std_logic_vector(0 downto 0)   := (others => 'X'); -- read
signal reconfig_address        : std_logic_vector(12 downto 0)  := (others => 'X'); -- address
signal reconfig_writedata      : std_logic_vector(31 downto 0)  := (others => 'X'); -- writedata
signal reconfig_readdata       : std_logic_vector(31 downto 0);                     -- readdata
signal reconfig_waitrequest    : std_logic_vector(0 downto 0);

component phyreset is
port (
	clock              : in  std_logic                    := 'X';             -- clk
	reset              : in  std_logic                    := 'X';             -- reset
	rx_analogreset     : out std_logic_vector(BKHSSI_NUM-1 downto 0);                    -- rx_analogreset
	rx_digitalreset    : out std_logic_vector(BKHSSI_NUM-1 downto 0);                    -- rx_digitalreset
	rx_ready           : out std_logic_vector(BKHSSI_NUM-1 downto 0);                    -- rx_ready
	rx_is_lockedtodata : in  std_logic_vector(BKHSSI_NUM-1 downto 0) := (others => 'X'); -- rx_is_lockedtodata
	rx_cal_busy        : in  std_logic_vector(BKHSSI_NUM-1 downto 0) := (others => 'X')  -- rx_cal_busy
);
end component phyreset;

signal rx_analogreset     : std_logic_vector(BKHSSI_NUM-1 downto 0);                    -- rx_analogreset
signal rx_digitalreset    : std_logic_vector(BKHSSI_NUM-1 downto 0);                    -- rx_digitalreset
signal rx_ready           : std_logic_vector(BKHSSI_NUM-1 downto 0);                    -- rx_ready
signal rx_is_lockedtodata : std_logic_vector(BKHSSI_NUM-1 downto 0) := (others => 'X'); -- rx_is_lockedtodata
signal rx_cal_busy        : std_logic_vector(BKHSSI_NUM-1 downto 0) := (others => 'X'); -- rx_cal_busy

begin

serdes_rst : phyreset
port map
(
	clock              => reconfclk,        -- clk
	reset              => phy_reset,        -- reset
	rx_analogreset     => rx_analogreset,        -- rx_analogreset
	rx_digitalreset    => rx_digitalreset,        -- rx_digitalreset
	rx_ready           => rx_ready,        -- rx_ready
	rx_is_lockedtodata => rx_is_lockedtodata,        -- rx_is_lockedtodata
	rx_cal_busy        => rx_cal_busy        -- rx_cal_busy
);

rx_clk <= rx_coreclkin;
rx_coreclkin <= rx_pma_clkout;

serdes_rxlock <= rx_is_lockedtodata;

serdes_phy : trans_phy
port map
(
	rx_analogreset          => rx_analogreset,        -- rx_analogreset
	rx_digitalreset         => rx_digitalreset,        -- rx_digitalreset
	rx_cal_busy             => rx_cal_busy,        -- rx_cal_busy
	rx_cdr_refclk0          => refclk,        -- clk
	rx_serial_data          => rx_serial_data,        -- rx_serial_data
	rx_is_lockedtoref       => rx_is_lockedtoref,        -- rx_is_lockedtoref
	rx_is_lockedtodata      => rx_is_lockedtodata,        -- rx_is_lockedtodata
	rx_coreclkin            => rx_coreclkin,        -- clk
	rx_clkout               => rx_clkout,        -- clk
	rx_pma_div_clkout       => rx_pma_clkout,        -- clk
	rx_parallel_data        => rx_parallel_data,        -- rx_parallel_data
	rx_control              => rx_control,        -- rx_control
	unused_rx_parallel_data => open,        -- unused_rx_parallel_data
	unused_rx_control       => open,         -- unused_rx_control

    rx_enh_data_valid       => rx_enh_data_valid,        -- rx_enh_data_valid
	rx_enh_fifo_full        => rx_enh_fifo_full,        -- rx_enh_fifo_full
	rx_enh_fifo_empty       => rx_enh_fifo_empty,        -- rx_enh_fifo_empty
	rx_enh_fifo_del         => rx_enh_fifo_del,        -- rx_enh_fifo_del
	rx_enh_fifo_insert      => rx_enh_fifo_insert,        -- rx_enh_fifo_insert
	rx_enh_highber          => rx_enh_highber,        -- rx_enh_highber
	rx_enh_blk_lock         => rx_enh_blk_lock        -- rx_enh_blk_lock

 --   reconfig_clk            => reconfig_clk,        -- clk
	--reconfig_reset          => reconfig_reset,        -- reset
	--reconfig_write          => (others=>'0'),        -- write
	--reconfig_read           => (others=>'0'),        -- read
	--reconfig_address        => reconfig_address,        -- address
	--reconfig_writedata      => reconfig_writedata,        -- writedata
	--reconfig_readdata       => reconfig_readdata,        -- readdata
	--reconfig_waitrequest    => reconfig_waitrequest        -- waitrequest
);

reconfig_clk(0) <= reconfclk;
reconfig_reset(0) <= phy_reset;

end;