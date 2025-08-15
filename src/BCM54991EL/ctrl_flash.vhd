library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity ctrl_flash is
port(
    nRST				 : in std_logic;
    sysclk				 : in std_logic;

	flash_dpram_data     : out std_logic_vector(7 downto 0);
	flash_dpram_wraddr   : out std_logic_vector(8 downto 0);
	flash_dpram_wren     : out std_logic;

	config_rdreq	     : in std_logic;
	config_rdaddr		 : in std_logic_vector(24 downto 0);
	config_rdlen		 : in std_logic_vector(12 downto 0);
    config_rdack	     : out std_logic;

    spi_cmd_idle         : in std_logic;
    spi_cmd_en           : out std_logic;
    spi_cmd              : out std_logic_vector(2 downto 0);

	spi_addr             : out std_logic_vector(24 downto 0);
    spi_rdnum            : out std_logic_vector(12 downto 0);
    spi_data_valid       : in std_logic;
    spi_flash2host       : in std_logic_vector(7 downto 0)
);
end entity;

architecture behav of ctrl_flash is

signal flash_cnt			: std_logic_vector(8 downto 0);
signal spi_rdnum_buf		: std_logic_vector(12 downto 0);

signal spi_valid_detect 	: std_logic_vector(1 downto 0):="00";
signal config_rdreq_buf  	: std_logic:='0';
signal config_rdack_buf		: std_logic:='0';

signal cnt_wait				: std_logic_vector(3 downto 0);
signal cnt         		    : std_logic_vector( 11 downto 0):= (others => '0');
signal flash_op_done		: std_logic;

type state is(idle,read_once,wait_ns);
signal pstate: state :=idle;

begin
config_rdack <= config_rdack_buf;
process(sysclk,nRST)
begin
	if nRST ='0' then
		config_rdreq_buf <= '0';
	elsif rising_edge (sysclk) then
		if config_rdack_buf = '1' then
			config_rdreq_buf <= '0';
		elsif config_rdreq = '1' then
			config_rdreq_buf <= '1';
		end if;
	end if;
end process;

spi_rdnum <= spi_rdnum_buf;

process(sysclk,nRST)
begin
	if nRST='0' then
		flash_cnt <= (others=>'0');

		spi_addr<=(others=>'0');
		spi_valid_detect <= "00";
		spi_cmd <= (others=>'0');
		spi_cmd_en<='0';
		cnt_wait <= (others =>'0');
		flash_op_done <= '0';
		pstate <= idle;

	elsif rising_edge (sysclk) then

		case pstate is

			when idle =>
				spi_cmd_en <= '0';
				spi_cmd <= (others=>'0');
				config_rdack_buf <= '0';
				flash_dpram_wren <= '0';
				cnt <= cnt + '1';

				if cnt > X"FF0" then
					if(config_rdreq_buf = '1')then
						pstate <= read_once;
					else
						pstate <= idle;
					end if;
				else
					pstate <= idle;
				end if;

			when read_once =>
				spi_valid_detect <= spi_valid_detect(0)&spi_data_valid;
				spi_addr<=config_rdaddr;
				spi_rdnum_buf <= config_rdlen;  --512
				if spi_cmd_idle ='1' then
					spi_cmd_en <= '1';
					spi_cmd<="011";
					flash_cnt<=(others=>'0');
				else
					spi_cmd_en<='0';
					spi_cmd<="000";
					if spi_valid_detect = "01" then
						flash_cnt<=flash_cnt + '1';
						flash_dpram_wren <= '1';
						if flash_cnt = spi_rdnum_buf-1 then --511
							flash_op_done <= '1';
							config_rdack_buf<= '1';
						else
							flash_op_done <= '0';
						end if;
					else
						flash_dpram_wren<='0';
					end if;
				end if;
				flash_dpram_wraddr <= flash_cnt(8 downto 0);
				flash_dpram_data <= spi_flash2host;
				if flash_op_done = '0' then
					pstate <= read_once;
				else
					pstate <= wait_ns;
					flash_dpram_wren <= '0';
					flash_op_done <= '0';
				end if;

		    when  wait_ns =>
				if cnt_wait(3) = '1' then
					cnt_wait <= (others=>'0');
					pstate <= idle;
				else
					cnt_wait <= cnt_wait + '1';
					pstate <= wait_ns;
				end if;

			when others => pstate <= idle;
		end case;
    end if;
end process;


end behav;
