--#######################################################################
--
--  LOGIC CORE:          para_update
--  MODULE NAME:         para_update()
--  COMPANY:
--
--
--  REVISION HISTORY:
--
--  Revision 0.1  07/15/2020    Description: Initial .
--
--  FUNCTIONAL DESCRIPTION:
--
--
--
--  Copyright (C)   Shenzhen ColorLight Tech. Inc.
--
--#######################################################################


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
--use work.PCK_subfrm_type.all;

entity para_update is
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
end entity;

architecture behav of para_update is


signal buf_pwren                        : std_logic;
signal buf_paddr                        : std_logic_vector(FRAME_W-1 downto 0);
signal buf_pdata                        : std_logic_vector(7 downto 0);
signal frame_update_en                  : std_logic;
signal frame_update_en_d1               : std_logic;

signal cmd_type                         : std_logic_vector(1 downto 0);



component dpram_32bit_64 is
port (
    data                                : in  std_logic_vector(31 downto 0) := (others => 'X'); -- datain
    q                                   : out std_logic_vector(31 downto 0);                    -- dataout
    wraddress                           : in  std_logic_vector(5 downto 0)  := (others => 'X'); -- wraddress
    rdaddress                           : in  std_logic_vector(5 downto 0)  := (others => 'X'); -- rdaddress
    wren                                : in  std_logic                     := 'X';             -- wren
    wrclock                             : in  std_logic                     := 'X';             -- clk
    rdclock                             : in  std_logic                     := 'X'              -- clk
);
end component;
signal dpram_wren                       : std_logic;
signal dpram_waddr                      : std_logic_vector( 5 downto 0);
signal dpram_wdata                      : std_logic_vector(31 downto 0);

signal cnt                              : std_logic_vector( 9 downto 0);
signal opcode                           : std_logic_vector( 7 downto 0);
signal opaddr                           : std_logic_vector(31 downto 0);
signal erase_len                        : std_logic_vector(31 downto 0);
signal crc_len                          : std_logic_vector(31 downto 0);
signal crc_value                        : std_logic_vector(31 downto 0);
signal data_buf                         : std_logic_vector(31 downto 0);
signal flash_data_en                    : std_logic;

CONSTANT OP_START_ADDR   : std_logic_vector(FLASH_ADDR_W_INBYTE-1 downto 0):='1'&X"000000";


begin


process(sysclk,nRST)
begin
    if nRST = '0' then
        buf_pwren <= '0';
        frame_update_en <= '0';
        frame_update_en_d1 <= '0';
    elsif rising_edge(sysclk) then
        if pframe_ss = '1' and paddr = 0 and pdata =X"06" then
            frame_update_en <= '1';
        elsif pframe_ss = '0' then
            frame_update_en <= '0';
        end if;
        frame_update_en_d1 <= frame_update_en;

        buf_pwren <= pwren;
        buf_paddr <= paddr;
        buf_pdata <= pdata;
    end if;

end process;

process(sysclk,nRST)
begin
    if nRST = '0' then
        cnt <= (others => '0');
        dpram_wren <= '0';
        ----
        -- flash_data_en <= '0';
        -- opcode <= (others => '0');
        -- opaddr <= (others => '0');
        -- erase_len <= (others => '0');
        -- crc_len <= (others => '0');
        -- crc_value <= (others => '0');
        -- data_buf <= (others => '0');
        -- dpram_wdata <= (others => '0');
        -- dpram_waddr <= (others => '0');
        ----
    elsif rising_edge(sysclk) then
        if frame_update_en = '1' and buf_pwren = '1' then
            if    buf_paddr = 1  then   opcode <= buf_pdata;
            end if;

            if    buf_paddr = 2  then   opaddr( 7 downto  0) <= buf_pdata;
            elsif buf_paddr = 3  then   opaddr(15 downto  8) <= buf_pdata;
            elsif buf_paddr = 4  then   opaddr(23 downto 16) <= buf_pdata;
            elsif buf_paddr = 5  then   opaddr(31 downto 24) <= buf_pdata;
            end if;

            ----0x32
            if    buf_paddr = 15 then   erase_len( 7 downto  0) <= buf_pdata;
            elsif buf_paddr = 16 then   erase_len(15 downto  8) <= buf_pdata;
            elsif buf_paddr = 17 then   erase_len(23 downto 16) <= buf_pdata;
            elsif buf_paddr = 18 then   erase_len(31 downto 24) <= buf_pdata;
            end if;

            ----0x87
            if    buf_paddr =  6 then   crc_len( 7 downto  0) <= buf_pdata;
            elsif buf_paddr =  7 then   crc_len(15 downto  8) <= buf_pdata;
            elsif buf_paddr =  8 then   crc_len(23 downto 16) <= buf_pdata;
            elsif buf_paddr =  9 then   crc_len(31 downto 24) <= buf_pdata;
            elsif buf_paddr = 10 then   crc_value( 7 downto  0) <= buf_pdata;
            elsif buf_paddr = 11 then   crc_value(15 downto  8) <= buf_pdata;
            elsif buf_paddr = 12 then   crc_value(23 downto 16) <= buf_pdata;
            elsif buf_paddr = 13 then   crc_value(31 downto 24) <= buf_pdata;
            end if;

            if flash_data_en = '1' then
                cnt <= cnt + 1;
                data_buf <= buf_pdata&data_buf(31 downto 8);
            else
                cnt <= (others => '0');
            end if;

            if cnt(1 downto 0) = "11" then
                dpram_wdata <= buf_pdata&data_buf(31 downto 8);
                dpram_wren  <= '1';
            else
                dpram_wren  <= '0';
            end if;

        else
            dpram_wren  <= '0';
        end if;


        if frame_update_en = '1' and opcode = x"86" and buf_paddr >= 5 then
            if buf_pwren = '1' then
                flash_data_en <= '1';
            end if;
        else
            flash_data_en <= '0';
        end if;

        dpram_waddr <= cnt(7 downto 2);

    end if;
end process;

process(sysclk,nRST)
begin
    if nRST = '0' then
        op_flash_req <= '0';
        ----
        -- op_flash_cmd <= (others => '0');
        -- op_flash_addr <= (others => '0');
        -- op_flash_len <= (others => '0');
        -- op_flash_crc <= (others => '0');
        -- cmd_type <= (others => '0');
        ----
    elsif rising_edge(sysclk) then
        if frame_update_en_d1 = '1' and frame_update_en = '0' then
            op_flash_req <= '1';
            op_flash_cmd <= cmd_type;
        elsif op_flash_ack = '1' then
            op_flash_req <= '0';
        end if;
        
		if DUAL_BOOT_EN = 0 then
			op_flash_addr <= opaddr(FLASH_ADDR_W_INBYTE-1 downto 0);
		else
			op_flash_addr <= opaddr(FLASH_ADDR_W_INBYTE-1 downto 0)+ OP_START_ADDR;
		end if;

        if    opcode = x"32" then   op_flash_len <= erase_len(FLASH_ADDR_W_INBYTE-1 downto 0);
        elsif opcode = x"87" then   op_flash_len <= crc_len(FLASH_ADDR_W_INBYTE-1 downto 0);
        else                        op_flash_len <= (8 => '1',others => '0');
        end if;

        op_flash_crc <= crc_value;

        if    opcode = x"32" then   cmd_type <= "01";
        elsif opcode = x"86" then   cmd_type <= "10";
        elsif opcode = x"56" then   cmd_type <= "11";
        elsif opcode = x"87" then   cmd_type <= "00";
        else                        cmd_type <= "00";
        end if;

    end if;

end process;


dpram_32bit_64_inst: dpram_32bit_64
port map(
    data                                => dpram_wdata      ,
    q                                   => op_flash_q       ,
    wraddress                           => dpram_waddr      ,
    rdaddress                           => op_flash_raddr   ,
    wren                                => dpram_wren       ,
    wrclock                             => sysclk           ,
    rdclock                             => sysclk
);


end behav;
