--#######################################################################
--
--  LOGIC CORE:          top_update
--  MODULE NAME:         top_update()
--  COMPANY:
--
--
--  REVISION HISTORY:
--
--  Revision 0.1  07/20/2007    Description: Initial .
--
--  FUNCTIONAL DESCRIPTION:
--
--  this module is the update module
--
--  Copyright (C)   Shenzhen ColorLight Tech. Inc.
--
--#######################################################################


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity top_update is
generic(
    FLASH_PROTECT_EN                    : std_logic:= '1';
	FLASH_PROTECT_ALL                   : std_logic:= '0';---'1':protect all, '0':protect half,only protect backup

    FRAME_W                             : integer:= 12;
    FLASH_ADDR_W_INBYTE                 : integer:= 25;
    FLASH_DATA_W                        : integer:= 32;
	
	DUAL_BOOT_EN                        : integer := 1;
	FLASH_TYPE                          : integer := 0    ------0:MT25QU256, 1:MT25QU01G
);
port(
    nRST                                : in  std_logic;
    sysclk                              : in  std_logic;
    time_ms_en                          : in  std_logic;
    --para
    pframe_ss                           : in  std_logic;
    pwren                               : in  std_logic;
    paddr                               : in  std_logic_vector(FRAME_W-1 downto 0);
    pdata                               : in  std_logic_vector(7 downto 0);

    config_rdack                        : out std_logic;
    config_rdreq                        : in  std_logic;
    config_rdaddr                       : in  std_logic_vector(24 downto 0);
    config_rdlen                        : in  std_logic_vector(12 downto 0);
    flash_dpram_data                    : out std_logic_vector(31 downto 0);
    flash_dpram_wraddr                  : out std_logic_vector(8 downto 0);
    flash_dpram_wren                    : out std_logic;

    update_crc_right                    : out std_logic;
    update_prog_done                    : out std_logic;
    update_crc_done                     : out std_logic;
    update_erase_done                   : out std_logic

);
end entity;

architecture behav of top_update is


component para_update is
generic(
    FRAME_W                             : integer:= 12;
    FLASH_ADDR_W_INBYTE                 : integer:= 25;
    FLASH_DATA_W                        : integer:= 32;
	DUAL_BOOT_EN                        : integer := 1
);
port(
    nRST                                : in  std_logic;
    sysclk                              : in  std_logic;
    time_ms_en                          : in  std_logic;
    --para
    pframe_ss                           : in  std_logic;
    pwren                               : in  std_logic;
    paddr                               : in  std_logic_vector(FRAME_W-1 downto 0);
    pdata                               : in  std_logic_vector(7 downto 0);
    --flash
    op_flash_req                        : out std_logic;
    op_flash_ack                        : in  std_logic;
    op_flash_end                        : in  std_logic;
    op_flash_cmd                        : out std_logic_vector(1 downto 0); --"00":crc      "01":erase sector   "10":page wr    "11":page rd
    op_flash_addr                       : out std_logic_vector(FLASH_ADDR_W_INBYTE-1 downto 0);
    op_flash_len                        : out std_logic_vector(FLASH_ADDR_W_INBYTE-1 downto 0);
    op_flash_crc                        : out std_logic_vector(31 downto 0);
    op_flash_raddr                      : in  std_logic_vector(8-2-1 downto 0);
    op_flash_q                          : out std_logic_vector(FLASH_DATA_W-1 downto 0)
);
end component;
signal op_flash_req                     : std_logic;
signal op_flash_ack                     : std_logic;
signal op_flash_end                     : std_logic;
signal op_flash_cmd                     : std_logic_vector(1 downto 0); --"00":crc      "01":erase sector   "10":page wr    "11":page rd
signal op_flash_addr                    : std_logic_vector(FLASH_ADDR_W_INBYTE-1 downto 0);
signal op_flash_len                     : std_logic_vector(FLASH_ADDR_W_INBYTE-1 downto 0);
signal op_flash_crc                     : std_logic_vector(31 downto 0);
signal op_flash_raddr                   : std_logic_vector(8-2-1 downto 0);
signal op_flash_q                       : std_logic_vector(FLASH_DATA_W-1 downto 0);


component ctrl_flash_c10 is
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
    spi_protect_flag                    : out std_logic;          --  '0': only protect half  '1':protect all
    spi_host2flash_rden                 : in  std_logic;
    spi_host2flash_en                   : out std_logic;
    spi_host2flash                      : out std_logic_vector(DATA_W-1 downto 0);
    spi_flash2host_en                   : in  std_logic;
    spi_flash2host                      : in  std_logic_vector(DATA_W-1 downto 0)
);
end component;
signal spi_init_done                    : std_logic;
signal spi_cmd_req                      : std_logic;
signal spi_cmd_ack                      : std_logic;
signal spi_cmd_end                      : std_logic;
signal spi_cmd_type                     : std_logic_vector(1 downto 0); --"00":wr protect   "01":erase sector   "10":page wr    "11":page rd
signal spi_addr                         : std_logic_vector(FLASH_ADDR_W_INBYTE-1 downto 0);
signal spi_length                       : std_logic_vector(8 downto 0); --no more than 256
signal spi_protect_flag                 : std_logic;        --  '0':no protect  '1':protect
signal spi_host2flash_rden              : std_logic;
signal spi_host2flash_en                : std_logic;
signal spi_host2flash                   : std_logic_vector(FLASH_DATA_W-1 downto 0);
signal spi_flash2host_en                : std_logic;
signal spi_flash2host                   : std_logic_vector(FLASH_DATA_W-1 downto 0);


component spi_flash_a10 is
generic(
    ADDR_W_INBYTE                       : integer:= 25;
    DATA_W                              : integer:= 32;
	FLASH_TYPE                          : integer := 0
);
port(
    nRST                                : in  std_logic;
    sysclk                              : in  std_logic;
    time_ms_en                          : in  std_logic;

    spi_init_done                       : out std_logic;
    spi_cmd_req                         : in  std_logic;
    spi_cmd_ack                         : out std_logic;
    spi_cmd_end                         : out std_logic;
    spi_cmd_type                        : in  std_logic_vector(1 downto 0); --"00":wr protect   "01":erase sector   "10":page wr    "11":page rd
    spi_addr                            : in  std_logic_vector(ADDR_W_INBYTE-1 downto 0);
    spi_length                          : in  std_logic_vector(8 downto 0); --no more than 256
    spi_protect_flag                    : in  std_logic;          --  '0': only protect half  '1':protect all
    spi_host2flash_rden                 : out std_logic;
    spi_host2flash_en                   : in  std_logic;
    spi_host2flash                      : in  std_logic_vector(DATA_W-1 downto 0);
    spi_flash2host_en                   : out std_logic;
    spi_flash2host                      : out std_logic_vector(DATA_W-1 downto 0)
);
end component;




begin


para_update_inst: para_update
generic map(
    FRAME_W                             => FRAME_W              ,
    FLASH_ADDR_W_INBYTE                 => FLASH_ADDR_W_INBYTE  ,
    FLASH_DATA_W                        => FLASH_DATA_W ,
	DUAL_BOOT_EN                        => DUAL_BOOT_EN 
)
port map(
    nRST                                => nRST                 ,
    sysclk                              => sysclk               ,
    time_ms_en                          => time_ms_en           ,

    pframe_ss                           => pframe_ss            ,
    pwren                               => pwren                ,
    paddr                               => paddr                ,
    pdata                               => pdata                ,

    op_flash_req                        => op_flash_req         ,
    op_flash_ack                        => op_flash_ack         ,
    op_flash_end                        => op_flash_end         ,
    op_flash_cmd                        => op_flash_cmd         ,
    op_flash_addr                       => op_flash_addr        ,
    op_flash_len                        => op_flash_len         ,
    op_flash_crc                        => op_flash_crc         ,
    op_flash_raddr                      => op_flash_raddr       ,
    op_flash_q                          => op_flash_q
);

ctrl_flash_c10_inst: ctrl_flash_c10
generic map(
    FLASH_PROTECT_EN                    => FLASH_PROTECT_EN     ,
	FLASH_PROTECT_ALL                   => FLASH_PROTECT_ALL ,
    ADDR_W_INBYTE                       => FLASH_ADDR_W_INBYTE  ,
    DATA_W                              => FLASH_DATA_W
)
port map(
    nRST                                => nRST                 ,
    sysclk                              => sysclk               ,
    time_ms_en                          => time_ms_en           ,
    --user
    op_flash_req                        => op_flash_req         ,
    op_flash_ack                        => op_flash_ack         ,
    op_flash_end                        => op_flash_end         ,
    op_flash_cmd                        => op_flash_cmd         ,
    op_flash_addr                       => op_flash_addr        ,
    op_flash_len                        => op_flash_len         ,
    op_flash_crc                        => op_flash_crc         ,
    op_flash_raddr                      => op_flash_raddr       ,
    op_flash_q                          => op_flash_q           ,
    op_flash_wren                       => flash_dpram_wren     ,
    op_flash_waddr                      => flash_dpram_wraddr   ,
    op_flash_data                       => flash_dpram_data     ,

    config_rdreq                        => config_rdreq,
    config_rdack                        => config_rdack,
    config_rdaddr                       => config_rdaddr,
    config_rdlen                        => config_rdlen,

    update_crc_right                    => update_crc_right     ,
    update_prog_done                    => update_prog_done     ,
    update_crc_done                     => update_crc_done      ,
    update_erase_done                   => update_erase_done    ,

    --flash
    spi_init_done                       => spi_init_done        ,
    spi_cmd_req                         => spi_cmd_req          ,
    spi_cmd_ack                         => spi_cmd_ack          ,
    spi_cmd_end                         => spi_cmd_end          ,
    spi_cmd_type                        => spi_cmd_type         ,
    spi_addr                            => spi_addr             ,
    spi_length                          => spi_length           ,
    spi_protect_flag                    => spi_protect_flag     ,
    spi_host2flash_rden                 => spi_host2flash_rden  ,
    spi_host2flash_en                   => spi_host2flash_en    ,
    spi_host2flash                      => spi_host2flash       ,
    spi_flash2host_en                   => spi_flash2host_en    ,
    spi_flash2host                      => spi_flash2host
);

spi_flash_a10_inst: spi_flash_a10
generic map(
    ADDR_W_INBYTE                       => FLASH_ADDR_W_INBYTE  ,
    DATA_W                              => FLASH_DATA_W    ,
	FLASH_TYPE                          => FLASH_TYPE
)
port map(
    nRST                                => nRST                 ,
    sysclk                              => sysclk               ,
    time_ms_en                          => time_ms_en           ,

    spi_init_done                       => spi_init_done        ,
    spi_cmd_req                         => spi_cmd_req          ,
    spi_cmd_ack                         => spi_cmd_ack          ,
    spi_cmd_end                         => spi_cmd_end          ,
    spi_cmd_type                        => spi_cmd_type         ,
    spi_addr                            => spi_addr             ,
    spi_length                          => spi_length           ,
    spi_protect_flag                    => spi_protect_flag     ,
    spi_host2flash_rden                 => spi_host2flash_rden  ,
    spi_host2flash_en                   => spi_host2flash_en    ,
    spi_host2flash                      => spi_host2flash       ,
    spi_flash2host_en                   => spi_flash2host_en    ,
    spi_flash2host                      => spi_flash2host
);




end behav;
