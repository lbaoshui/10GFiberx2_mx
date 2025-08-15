--#######################################################################
--
--  LOGIC CORE:          spi_flash_a10                            
--  MODULE NAME:         spi_flash_a10()
--  COMPANY:             
--                              
--
--  REVISION HISTORY:  
--
--  Revision 0.1  07/20/2007    Description: Initial .
--
--  FUNCTIONAL DESCRIPTION:
--
--  this module is the drive of ARRIA10 FLASH operation
--
--  Copyright (C)   Shenzhen ColorLight Tech. Inc.
--
--#######################################################################


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.PCK_version_FPGA_def.all;



entity spi_flash_a10 is
generic(
    ADDR_W_INBYTE                       : integer:= 25;
    DATA_W                              : integer:= 32;
	FLASH_TYPE                          : integer := 0    ------0:MT25QU256, 1:MT25QU01G
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
    spi_protect_flag                    : in  std_logic;         --  '0': only protect half  '1':protect all
    spi_host2flash_rden                 : out std_logic;
    spi_host2flash_en                   : in  std_logic;
    spi_host2flash                      : in  std_logic_vector(DATA_W-1 downto 0);
    spi_flash2host_en                   : out std_logic;
    spi_flash2host                      : out std_logic_vector(DATA_W-1 downto 0)
);
end entity;

architecture behav of spi_flash_a10 is


component generic_spi_flash is
port (
    avl_csr_address                     : in  std_logic_vector(5 downto 0)  := (others => 'X'); -- address
    avl_csr_read                        : in  std_logic                     := 'X';             -- read
    avl_csr_readdata                    : out std_logic_vector(31 downto 0);                    -- readdata
    avl_csr_write                       : in  std_logic                     := 'X';             -- write
    avl_csr_writedata                   : in  std_logic_vector(31 downto 0) := (others => 'X'); -- writedata
    avl_csr_waitrequest                 : out std_logic;                                        -- waitrequest
    avl_csr_readdatavalid               : out std_logic;                                        -- readdatavalid
    avl_mem_write                       : in  std_logic                     := 'X';             -- write
    avl_mem_burstcount                  : in  std_logic_vector(6 downto 0)  := (others => 'X'); -- burstcount
    avl_mem_waitrequest                 : out std_logic;                                        -- waitrequest
    avl_mem_read                        : in  std_logic                     := 'X';             -- read
    avl_mem_address                     : in  std_logic_vector(22 downto 0) := (others => 'X'); -- address
    avl_mem_writedata                   : in  std_logic_vector(31 downto 0) := (others => 'X'); -- writedata
    avl_mem_readdata                    : out std_logic_vector(31 downto 0);                    -- readdata
    avl_mem_readdatavalid               : out std_logic;                                        -- readdatavalid
    avl_mem_byteenable                  : in  std_logic_vector(3 downto 0)  := (others => 'X'); -- byteenable
    clk_clk                             : in  std_logic                     := 'X';             -- clk
    reset_reset                         : in  std_logic                     := 'X'              -- reset
);
end component;
signal rst                              : std_logic;
signal csr_addr                         : std_logic_vector(5 downto 0);
signal csr_addr_buf                     : std_logic_vector(3 downto 0);
signal csr_rden                         : std_logic;
signal csr_rdvld                        : std_logic;
signal csr_rddata                       : std_logic_vector(DATA_W-1 downto 0);
signal csr_wren                         : std_logic;
signal csr_wrdata                       : std_logic_vector(DATA_W-1 downto 0);
signal csr_waitrequest                  : std_logic;
signal mem_burst                        : std_logic_vector(6 downto 0);
signal mem_wren                         : std_logic;
signal mem_waitrequest                  : std_logic;
signal mem_waitrequest_d1               : std_logic;
signal mem_rden                         : std_logic;
signal mem_addr                         : std_logic_vector(ADDR_W_INBYTE-2-1 downto 0);
signal mem_wrdata                       : std_logic_vector(DATA_W-1 downto 0);
signal mem_rddata                       : std_logic_vector(DATA_W-1 downto 0);
signal mem_rdvld                        : std_logic;
signal mem_byteen                       : std_logic_vector(3 downto 0);


type state is(
    init,
    idle,
    page_wr,
    page_wr_a,
    page_rd,
    erase_sector,
    flash_protect,
    delay_wait_b,
    delay_wait,
    delay_wait_a
);
signal pstate                           : state:= init;
signal next_pstate                      : state:= idle;

signal mem_cnt                          : std_logic_vector(6 downto 0);
signal timeout_cnt                      : std_logic_vector(13 downto 0);


--csr
type csr_state is(
    csr_delay,
    csr_init,
    csr_idle,
    csr_erasesector,
    csr_wrreg,
    csr_rdreg,
    csr_wait
);
signal csr_pstate                       : csr_state:= csr_delay;
signal csr_next_pstate                  : csr_state:= csr_idle;

signal csr_init_done                    : std_logic;
signal csr_timeout_cnt                  : std_logic_vector(10 downto 0);
signal csr_req                          : std_logic;
signal csr_ack                          : std_logic;
signal csr_end                          : std_logic;
signal csr_rd_fail                      : std_logic;
signal csr_flash_addr                   : std_logic_vector(ADDR_W_INBYTE-1 downto 0);
signal csr_reg_rddata                   : std_logic_vector(DATA_W-1 downto 0);
signal csr_reg_wrdata                   : std_logic_vector(DATA_W-1 downto 0);
signal rd_config_reg_en                 : std_logic;
constant CSR_ERASE_SECTOR               : std_logic_vector(1 downto 0):= "01";
constant CSR_WRITE_REG                  : std_logic_vector(1 downto 0):= "10";
constant CSR_READ_REG                   : std_logic_vector(1 downto 0):= "11";
signal csr_cmd                          : std_logic_vector(1 downto 0); 
signal csr_loop_cnt                     : std_logic_vector(3 downto 0);
signal csr_loop_max                     : std_logic_vector(3 downto 0);
signal csr_loop_end                     : std_logic;

signal set_bp_info                      : std_logic_vector(4 downto 0);
signal mx_bp_info                       : std_logic_vector(3 downto 0);
signal flash_protect_cnt                : std_logic_vector(3 downto 0);
signal check_flash_protect              : std_logic;
signal rdback_bp_info                     : std_logic_vector(4 downto 0);


constant Control_Register                       : std_logic_vector(3 downto 0):= X"0";
constant SPI_Clock_Baud_rate_Register           : std_logic_vector(3 downto 0):= X"1";
constant CS_Delay_setting_register              : std_logic_vector(3 downto 0):= X"2";
constant Read_Capturing_Register                : std_logic_vector(3 downto 0):= X"3";
constant Operating_Protocols_Setting_Register   : std_logic_vector(3 downto 0):= X"4";
constant Read_Instruction_Register              : std_logic_vector(3 downto 0):= X"5";
constant Write_Instruction_Register             : std_logic_vector(3 downto 0):= X"6";
constant Flash_Command_Setting_Register         : std_logic_vector(3 downto 0):= X"7";
constant Flash_Command_Control_Register         : std_logic_vector(3 downto 0):= X"8";
constant Flash_Command_Address_Register         : std_logic_vector(3 downto 0):= X"9";
constant Flash_Command_Write_Data0              : std_logic_vector(3 downto 0):= X"A";
constant Flash_Command_Write_Data1              : std_logic_vector(3 downto 0):= X"B";
constant Flash_Command_Read_Data0               : std_logic_vector(3 downto 0):= X"C";
constant Flash_Command_Read_Data1               : std_logic_vector(3 downto 0):= X"D";


------bit 4 BP3 ,bit3:Top or bottom , bit2~bit0:BP2~BP0
constant PROTECT_ALL                            : std_logic_vector(4 downto 0):="11111";
constant PROTECT_HALF_256                       : std_logic_vector(4 downto 0):="11001";
constant PROTECT_HALF_1G                        : std_logic_vector(4 downto 0):="11011";

-----MX FLASH, output driver strength 
constant MX_ODS                                 : std_logic_vector(2 downto 0):= "111";---24 ohms,default
constant MX_PBE                                 : std_logic := '0'; ----preamble bit enable,'0' default
constant MX_DC                                  : std_logic_vector(1 downto 0):= "00";---dummy cycle ,"00" default ,numbers of dummy clock is 0x0A
constant MX_QUAD_ENABLE                         : std_logic := '1';----quad enable,non-volatile bit

begin


generic_spi_flash_inst: generic_spi_flash
port map(
    avl_csr_address                     => csr_addr         ,       
    avl_csr_read                        => csr_rden         ,
    avl_csr_readdata                    => csr_rddata       ,                   
    avl_csr_write                       => csr_wren         ,                   
    avl_csr_writedata                   => csr_wrdata       ,                   
    avl_csr_waitrequest                 => csr_waitrequest  ,                       
    avl_csr_readdatavalid               => csr_rdvld        ,               
    avl_mem_write                       => mem_wren         ,                   
    avl_mem_burstcount                  => mem_burst        ,                       
    avl_mem_waitrequest                 => mem_waitrequest  ,                       
    avl_mem_read                        => mem_rden         ,                       
    avl_mem_address                     => mem_addr         ,                       
    avl_mem_writedata                   => mem_wrdata       ,                   
    avl_mem_readdata                    => mem_rddata       ,                   
    avl_mem_readdatavalid               => mem_rdvld        ,                   
    avl_mem_byteenable                  => mem_byteen       ,                   
    clk_clk                             => sysclk           ,
    reset_reset                         => rst
);
rst <= not nRST;




--mem
mem_burst <= conv_std_logic_vector(64,7);
mem_byteen <= (others => '1');
spi_init_done <= csr_init_done;
process(sysclk,nRST)
begin
    if nRST = '0' then
        pstate <= init;
        
        mem_wren <= '0';
        mem_rden <= '0';
        csr_req <= '0';
        
        spi_cmd_ack <= '0';
        spi_cmd_end <= '0';
        spi_host2flash_rden <= '0';
        spi_flash2host_en   <= '0';
		csr_reg_wrdata      <= (others => '0');
		flash_protect_cnt   <= (others => '0');
		check_flash_protect <= '0';
		rd_config_reg_en    <= '0';
    
    
    elsif rising_edge(sysclk) then
        mem_waitrequest_d1 <= mem_waitrequest;
        for i in 0 to DATA_W/8-1 loop
            for j in 0 to 7 loop
                mem_wrdata(i*8+j) <= spi_host2flash(i*8+7-j);
                spi_flash2host(i*8+j) <= mem_rddata(i*8+7-j);
            end loop;
        end loop;
    
        case pstate is
            when init =>
                    if csr_init_done = '1' then
                        pstate <= idle;
                    else
                        pstate <= init;
                    end if;
                
                
            when idle => 
                    if spi_cmd_req = '1' then
                        if spi_cmd_type = "00" then  
                            pstate <= flash_protect;
							spi_host2flash_rden <= '0';
							mem_rden <= '0';
							csr_req <= '1';
							csr_cmd <= CSR_WRITE_REG;
							csr_reg_wrdata   <= (others => '0');
							if MX_FLASH_EN = 0 then ----- MT flash
							if spi_protect_flag = '0' then---protect half,still protect backup
								if FLASH_TYPE = 0 then---256
									---------protect sector 0~255,
										csr_reg_wrdata(6 downto 2)<= PROTECT_HALF_256;
										set_bp_info               <= PROTECT_HALF_256;
																		
								else          
										-----1G,protect sector 0~1023
										csr_reg_wrdata(6 downto 2)<= PROTECT_HALF_1G;
										set_bp_info               <= PROTECT_HALF_1G;									
								end if;
								else        -------  protect ALL
								csr_reg_wrdata(6 downto 2) <= PROTECT_ALL;
								end if;
							else -------- MX Flash_Command_Address_Register
								-----status regsiter
								csr_reg_wrdata(6)<= MX_QUAD_ENABLE;
								if spi_protect_flag = '0' then -----protect half,still protect backup
									if FLASH_TYPE = 0 then ---256M 
										csr_reg_wrdata(5 downto 2) <= PROTECT_HALF_256(4)&PROTECT_HALF_256(2 downto 0);
									else
										csr_reg_wrdata(5 downto 2) <= PROTECT_HALF_1G(4)&PROTECT_HALF_1G(2 downto 0);
									end if;
									set_bp_info                    <= PROTECT_HALF_256;
								else     ---protect all
									csr_reg_wrdata(5 downto 2) <= PROTECT_ALL(4)&PROTECT_ALL(2 downto 0);
									set_bp_info                    <= PROTECT_HALF_256;
								end if;
								
								---configuration reg
								csr_reg_wrdata(15 downto 14) <= MX_DC;
								csr_reg_wrdata(12)           <= MX_PBE;
								
								
								if spi_protect_flag = '0' then		-- protect half
									if FLASH_TYPE = 0 then
										csr_reg_wrdata(11) <=PROTECT_HALF_256(3);---TB
									else
										csr_reg_wrdata(11) <=PROTECT_HALF_1G(3);
									end if;
								else								-- protect all
									csr_reg_wrdata(11)     <=PROTECT_ALL(3);
								end if;
								csr_reg_wrdata(10 downto 8)			 <= MX_ODS;
							end if;
							
                        elsif spi_cmd_type = "01" then
                            pstate <= erase_sector;
                            spi_host2flash_rden <= '0';
                            mem_rden <= '0';
                            csr_req <= '1';
                            csr_cmd <= CSR_ERASE_SECTOR;
                        elsif spi_cmd_type = "10" then
                            pstate <= page_wr;
                            spi_host2flash_rden <= '1';
                            mem_rden <= '0';
                            csr_req <= '0';
                        else--if spi_cmd_type = "11" then
                            pstate <= page_rd;
                            spi_host2flash_rden <= '0';
                            mem_rden <= '1';
                            csr_req <= '0';
                        end if;
                        spi_cmd_ack <= '1';
                    else
                        pstate <= idle;
                        spi_cmd_ack <= '0';
                        spi_host2flash_rden <= '0';
                        mem_rden <= '0';
                        csr_req <= '0';
                    end if;
                    spi_cmd_end <= '0';
                    spi_flash2host_en <= '0';
                    
                    mem_cnt <= (others => '0'); 
                    timeout_cnt <= (others => '0'); 
                    
                    mem_wren <= '0';
                    mem_addr <= spi_addr(ADDR_W_INBYTE-1 downto 2);
                    
                    
                    csr_flash_addr <=  spi_addr;
					check_flash_protect <= '0';
					flash_protect_cnt   <= (others=>'0');
					rd_config_reg_en    <= '0';


            when flash_protect =>
			   
                if csr_end = '1' then
                    pstate <= delay_wait_b;
                    csr_req <= '0';
                else
                    pstate <= flash_protect;
                    if csr_ack = '1' then
                        csr_req <= '0';						
                    end if;
                end if;
                spi_cmd_ack <= '0';
				csr_cmd     <= CSR_WRITE_REG;
				check_flash_protect <= '1';
            
            
            when erase_sector =>
                    if csr_end = '1' then
                        pstate <= delay_wait_b;
                        csr_req <= '0';
                    else
                        pstate <= erase_sector;
                        if csr_ack = '1' then
                            csr_req <= '0';
                        end if;
                    end if;
                    spi_cmd_ack <= '0';

            
            when page_wr =>
                    if mem_cnt(6) = '1' then
                        pstate <= page_wr_a;
                        mem_cnt <= (others => '0');
                    else
                        pstate <= page_wr;
                        if mem_wren = '1' and mem_waitrequest = '0' then
                            mem_cnt <= mem_cnt + '1';
                        end if;
                    end if;
                    spi_cmd_ack <= '0';             

                    if spi_host2flash_en = '1' then
                        mem_wren <= '1';
                    elsif mem_wren = '1' and mem_waitrequest = '0' then
                        mem_wren <= '0';
                    end if;
                    
                    if mem_wren = '1' and mem_waitrequest = '0' and mem_cnt < 63 then
                        spi_host2flash_rden <= '1';
                    else
                        spi_host2flash_rden <= '0';
                    end if;
                    
                    
            when page_wr_a =>
                    if (mem_waitrequest_d1 = '1' and mem_waitrequest = '0') or timeout_cnt(10) = '1' then
                        pstate <= delay_wait_b;
                        timeout_cnt <= (others => '0');
                    else
                        pstate <= page_wr_a;
                        if time_ms_en = '1' then
                            timeout_cnt <= timeout_cnt + '1';
                        end if;
                    end if;
                    
                    mem_wren <= '0';
                    spi_host2flash_rden <= '0';
                    spi_flash2host_en <= '0';
                    
                    
            when page_rd =>
                    if mem_cnt(6) = '1' then
                        pstate <= delay_wait_b;
                        mem_cnt <= (others => '0');
                    else
                        pstate <= page_rd;
                        if mem_rdvld = '1' then
                            mem_cnt <= mem_cnt + '1';
                        end if;
                    end if;
                    spi_cmd_ack <= '0';
                    
                    if mem_cnt = 63 and mem_rdvld = '1' then
                        mem_rden <= '0';
                    end if;
                    
                    spi_flash2host_en <= mem_rdvld;
                    

            when delay_wait_b =>
                    if timeout_cnt(13) = '1' then   
                        pstate <= delay_wait;
                        csr_req <= '1';
                        timeout_cnt <= (others => '0');
                    else
                        pstate <= delay_wait_b;
                        csr_req <= '0';
                        timeout_cnt <= timeout_cnt + '1';
                    end if;
                    csr_cmd <= CSR_READ_REG;
                    mem_rden <= '0';
                    
                    
            when delay_wait =>
                    if csr_end = '1' then
						if check_flash_protect = '0' then
							if csr_rd_fail = '0' and csr_reg_rddata(0) = '0' then
								pstate <= delay_wait_a;
							else
								pstate <= delay_wait_b;
							end if;
							csr_req <= '0';	
						else
							if MX_FLASH_EN = 0 then
							if flash_protect_cnt = 3 then
								pstate  <= delay_wait_a;
								csr_req <= '0';	
							elsif csr_rd_fail = '0' and csr_reg_rddata(0) = '0' then
									if rdback_bp_info= set_bp_info then
									pstate  <= delay_wait_a;
									csr_req <= '0';	
								else
									pstate <= flash_protect;
									flash_protect_cnt <= flash_protect_cnt +1;
									csr_req <= '1';
									csr_cmd <= CSR_WRITE_REG;
								end if;
							else
								pstate <= delay_wait_b;
								csr_req <= '0';	
							end if;
							else
								if flash_protect_cnt = 3 then
									pstate  <= delay_wait_a;
									csr_req <= '0';	
									rd_config_reg_en <= '0';									
								elsif csr_rd_fail = '0' and csr_reg_rddata(0) = '0' and rd_config_reg_en = '0' then
									pstate  <= delay_wait_b;
									csr_req <= '0';	
									rd_config_reg_en <= '1';
									mx_bp_info       <= csr_reg_rddata(5 downto 2);--status reg, BP3~BP0
								elsif  csr_rd_fail = '0' and rd_config_reg_en = '1'then
									rd_config_reg_en <= '0';
									if rdback_bp_info = set_bp_info then
										pstate  <= delay_wait_a;
										csr_req <= '0';											
									else
										pstate <= flash_protect;
										flash_protect_cnt <= flash_protect_cnt +1;
										csr_req <= '1';
										csr_cmd <= CSR_WRITE_REG;		
									end if;
								else
									pstate  <= delay_wait_b;
									csr_req <= '0';										
									
								end if;
							end if;										
						end if;
														
                       
                    else
                        pstate <= delay_wait;
                        if csr_ack = '1' then
                            csr_req <= '0';
                        end if;
                    end if;
                    
                    
            when delay_wait_a =>
                    if timeout_cnt(10) = '1' then
                        pstate <= idle;
                        timeout_cnt <= (others => '0');
                        spi_cmd_end <= '1';
                    else
                        pstate <= delay_wait_a;
                        timeout_cnt <= timeout_cnt + '1';
                        spi_cmd_end <= '0';
                    end if;
                    
                    
            when others => 
                    pstate <= init;
                    
                    
        end case;
    end if;
end process;


rdback_bp_info <= (mx_bp_info(3)&csr_reg_rddata(3)&mx_bp_info(2 downto 0)) when MX_FLASH_EN = 1 else csr_reg_rddata(6 downto 2);

--csr
process(sysclk,nRST)
begin
    if nRST = '0' then
        csr_pstate <= csr_delay;
        csr_init_done <= '0';
        csr_timeout_cnt <= (others => '0');
        csr_ack <= '0';
        csr_end <= '0';
        csr_wren <= '0';
        csr_rden <= '0';

        
    elsif rising_edge(sysclk) then
        case csr_pstate is
            when csr_delay =>
                    if csr_timeout_cnt(10) = '1' and csr_waitrequest = '0' then
                        csr_pstate <= csr_init;
                        csr_timeout_cnt <= (others => '0');
                    else
                        csr_pstate <= csr_delay;
                        if time_ms_en = '1' and csr_timeout_cnt(10) = '0' then
                            csr_timeout_cnt <= csr_timeout_cnt + '1';
                        end if;
                    end if;
                    
                    csr_init_done <= '0';
                    csr_ack <= '0';
                    csr_end <= '0';
                    csr_wren <= '0';
                    csr_rden <= '0';
                    csr_loop_cnt <= (others => '0');
                    csr_loop_max <= conv_std_logic_vector(10-1,4);
                    
                    
            when csr_init =>
                    csr_pstate <= csr_wait;
                    csr_next_pstate <= csr_init;

                    csr_wren <= '1';
                    csr_rden <= '0';
                    
                    if csr_loop_cnt = 0 then    
                        csr_addr_buf <= SPI_Clock_Baud_rate_Register;
                        -- csr_wrdata <= x"00000002";                                       --spi_clk = ip_clk/4;
                        csr_wrdata <= x"00000004";                                      --spi_clk = ip_clk/8;
                    elsif csr_loop_cnt = 1 then
                        csr_addr_buf <= CS_Delay_setting_register;
                        csr_wrdata <= (others => '0');
                    elsif csr_loop_cnt = 2 then
                        csr_addr_buf <= Read_Capturing_Register;
                        csr_wrdata <= (others => '0');
                    elsif csr_loop_cnt = 3 then
                        csr_addr_buf <= Operating_Protocols_Setting_Register;
                        csr_wrdata <= (others => '0');                                  --extended mode;
                        -- csr_wrdata <= (16 => '1',12 => '1',0 => '1',others => '0');    -- dual mode
                        -- csr_wrdata <= (17 => '1',13 => '1',1 => '1',others => '0');    -- quad mode
                    elsif csr_loop_cnt = 4 then
                        csr_addr_buf <= Read_Instruction_Register;
						if MX_FLASH_EN = 0 then ----MT
							csr_wrdata <= x"00000A0C";
						else
							if MX_DC = "00" then
								csr_wrdata <= x"00000AEB";---dummy10
							elsif MX_DC = "10" then
								csr_wrdata <= x"000006EB";---dummy 6
							else
								csr_wrdata <= x"000008EB";---dummy 8
							end if;
						end if;
								
                    elsif csr_loop_cnt = 5 then
                        csr_addr_buf <= Write_Instruction_Register;
						if MX_FLASH_EN = 0 then
							csr_wrdata <= x"00000512";
						else
							csr_wrdata <= x"00000502";
						end if;
                    elsif csr_loop_cnt = 6 then
                        csr_addr_buf <= Flash_Command_Setting_Register;
                        csr_wrdata <= x"00000035";
                    elsif csr_loop_cnt = 7 then
                        csr_addr_buf <= Flash_Command_Control_Register;
                        csr_wrdata <= x"00000001";
                    elsif csr_loop_cnt = 8 then
                        csr_addr_buf <= Operating_Protocols_Setting_Register;
                        -- csr_wrdata <= (others => '0');                               -- extended mode
                        -- csr_wrdata <= (16 => '1',12 => '1',0 => '1',others => '0');  -- dual mode
                        csr_wrdata <= (17 => '1',13 => '1',9 => '1',5 => '1',1 => '1',others => '0');    -- quad mode
                    else--if csr_loop_cnt = 9 then
                        csr_addr_buf <= Control_Register;
                        csr_wrdata <= (8 => '1',0 => '1',others => '0');                --4-byte addr mode
                    end if;
                    
                    
            when csr_idle =>
                    if csr_req = '1' and csr_waitrequest = '0' then
                        if csr_cmd = CSR_ERASE_SECTOR then
                            csr_pstate <= csr_erasesector;
                            csr_loop_max <= conv_std_logic_vector(5-1,4);
                        elsif csr_cmd = CSR_WRITE_REG then
                            csr_pstate <= csr_wrreg;
                            csr_loop_max <= conv_std_logic_vector(5-1,4);
                        else--if csr_cmd = CSR_READ_REG then
                            csr_pstate <= csr_rdreg;
                            csr_loop_max <= conv_std_logic_vector(3-1,4);
                        end if;
                        csr_ack <= '1';
                    else
                        csr_pstate <= csr_idle;
                        csr_ack <= '0';
                    end if;
                    
                    csr_init_done <= '1';
                    csr_end <= '0';
                    csr_wren <= '0';
                    csr_rden <= '0';
                    csr_timeout_cnt <= (others => '0');
                    
                    
            when csr_erasesector =>
                    csr_pstate <= csr_wait;
                    csr_next_pstate <= csr_erasesector;
                    
                    csr_ack <= '0';
                    csr_wren <= '1';
                    csr_rden <= '0';
                    
                    if csr_loop_cnt = 0 then    
                        csr_addr_buf <= Flash_Command_Setting_Register;
                        csr_wrdata <= x"00000006";
                    elsif csr_loop_cnt = 1 then
                        csr_addr_buf <= Flash_Command_Control_Register;
                        csr_wrdata <= x"00000001";
                    elsif csr_loop_cnt = 2 then
                        csr_addr_buf <= Flash_Command_Setting_Register;
						if MX_FLASH_EN = 0 then
							csr_wrdata <= x"000004DC";                                      --64K
						else
							csr_wrdata <= x"000004D8"; 
						end if;
                        -- csr_wrdata <= x"00000421";                                       --4K
                    elsif csr_loop_cnt = 3 then
                        csr_addr_buf <= Flash_Command_Address_Register;
                        csr_wrdata(ADDR_W_INBYTE-1 downto 0) <= csr_flash_addr;                     
                        csr_wrdata(31 downto ADDR_W_INBYTE) <= (others => '0');                                 
                    else--if csr_loop_cnt = 4 then
                        csr_addr_buf <= Flash_Command_Control_Register;
                        csr_wrdata <= x"00000001";              
                    end if;
                    
                    
            when csr_wrreg =>
                    csr_pstate <= csr_wait;
                    csr_next_pstate <= csr_wrreg;
                    
                    csr_ack <= '0';
                    csr_wren <= '1';
                    csr_rden <= '0';
                    
                    if csr_loop_cnt = 0 then    
                        csr_addr_buf <= Flash_Command_Setting_Register;
                        csr_wrdata <= x"00000006";---write enable
                    elsif csr_loop_cnt = 1 then
                        csr_addr_buf <= Flash_Command_Control_Register;
                        csr_wrdata <= x"00000001";
                    
                    elsif csr_loop_cnt = 2 then    
                        csr_addr_buf <= Flash_Command_Setting_Register;
						if MX_FLASH_EN = 0 then
							csr_wrdata <= x"00001001";-----write status register
						else
							csr_wrdata <= x"00002001";-----write status register and configuration reg
						end if;
                    elsif csr_loop_cnt = 3 then
                        csr_addr_buf <= Flash_Command_Write_Data0;
                        csr_wrdata   <= csr_reg_wrdata;
                    else---if csr_loop_cnt = 4 then
                        csr_addr_buf <= Flash_Command_Control_Register;
                        csr_wrdata <= x"00000001";              
                    end if;
                    

            when csr_rdreg =>
                    csr_pstate <= csr_wait;
                    csr_next_pstate <= csr_rdreg;
                    
                    csr_ack <= '0';
                    if csr_loop_cnt < 2 then    csr_wren <= '1';
                    else                        csr_wren <= '0';
                    end if;
                    
                    if csr_loop_cnt = 2 then    csr_rden <= '1';
                    else                        csr_rden <= '0';
                    end if;
                    
                    if csr_loop_cnt = 0 then    
                        csr_addr_buf <= Flash_Command_Setting_Register;
						if MX_FLASH_EN = 0 then
							csr_wrdata <= x"00001805";
						else
							if rd_config_reg_en = '1' then----read configuration register
								csr_wrdata <= x"00001815";
							else                          -----read status register
								csr_wrdata <= x"00001805";
							end if;
						end if;
                    elsif csr_loop_cnt = 1 then
                        csr_addr_buf <= Flash_Command_Control_Register;
                        csr_wrdata <= x"00000001";
                    else--if csr_loop_cnt = 2 then
                        csr_addr_buf <= Flash_Command_Read_Data0;
                    end if;


            when csr_wait =>
                    -- if csr_timeout_cnt(10) = '1' or (csr_waitrequest_negedge = '1' and csr_wren = '1') or (csr_rden = '1' and csr_rdvld = '1') then
                    -- if csr_timeout_cnt(10) = '1' or (csr_waitrequest = '0' and csr_wren = '1') or (csr_rden = '1' and csr_rdvld = '1') then
                    if csr_timeout_cnt(10) = '1' or (csr_waitrequest = '0' and csr_wren = '1') or csr_rdvld = '1' then
                        if csr_loop_end = '1' then
                            csr_pstate <= csr_idle;
                            if csr_init_done = '1' then
                                csr_end <= '1';
                            else
                                csr_end <= '0';
                            end if;
                            csr_loop_cnt <= (others => '0');
                        else
                            csr_pstate <= csr_next_pstate;
                            csr_end <= '0';
                            csr_loop_cnt <= csr_loop_cnt + '1';
                        end if;
                        csr_timeout_cnt <= (others => '0');
                        
                        csr_wren <= '0';
                        if csr_waitrequest = '0' then
                            csr_rden <= '0';
                        end if;
                    else
                        csr_pstate <= csr_wait;
                        if time_ms_en = '1' and csr_timeout_cnt(10) = '0' then
                            csr_timeout_cnt <= csr_timeout_cnt + '1';
                        end if;
                        csr_end <= '0';
                    end if;
                    
                    if csr_rdvld = '1' then
                        csr_rd_fail <= '0';
                    else
                        csr_rd_fail <= '1';
                    end if;

                    
            when others =>
                    csr_pstate <= csr_delay;
                    csr_timeout_cnt <= (others => '0');
                    
                    
        end case;
    end if;
end process;
csr_addr <= "00"&csr_addr_buf;


process(sysclk,nRST)
begin
    if nRST = '0' then
        csr_loop_end <= '0';
    
    elsif rising_edge(sysclk) then
        if csr_rdvld = '1' then
            csr_reg_rddata <= csr_rddata;
        end if;

        if csr_loop_cnt = csr_loop_max then
            csr_loop_end <= '1';
        else
            csr_loop_end <= '0';
        end if;
    
    end if;
end process;




end behav;  
