

library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_arith.all ;
use ieee.std_logic_unsigned.all ;

entity xgmii_rx is
generic
(
    ETHPORT_NUM         : integer:= 10 ; ----PER FIBER 
    port_num            : integer:= 0 ; --FIBER PORT INDEX 
	TXSUBCARD_TYPE      : std_logic_vector(7  downto 0)
);
port
(

---------------rxclk -------------			
    nRST_rxclk             : in  std_logic;
    rxclk                  : in  std_logic;
    xgmii_rx_updata        : in  std_logic_vector(63 downto 0);
    xgmii_rx_upctrl        : in  std_logic_vector(7 downto 0);
	real_eth_num           : in  std_logic_vector(3 downto 0);

--------------convclk -----------	
	nRST_convclk           :  in  std_logic; 
	convclk_i              :  in  std_logic; 
	cmd_fifo_empty_conv    :  out std_logic;
	cmd_fifo_rden_conv     :  in  std_logic;
	cmd_fifo_q_conv        :  out std_logic_vector(28 downto 0);
	
	rx_data_conv           :  out std_logic_vector(7 downto 0);
	rx_data_raddr_conv     :  in  std_logic_vector(11 downto 0)


	          
);
end xgmii_rx;

architecture beha of xgmii_rx IS

signal wr_point            : std_logic:='0';
signal rx_dpram_waddr_buf  : std_logic_vector(7 downto 0);
signal rx_dpram_waddr      : std_logic_vector(8 downto 0);
signal rx_cmd_fifo_wren    : std_logic:='0';
signal rx_data_wren        : std_logic;
signal frame_type          : std_logic_vector(7 downto 0);
signal frame_length        : std_logic_vector(10 downto 0);
signal rx_data_wren_d1     : std_logic;
signal CHLNUM              : std_logic_vector(7 downto 0);
signal rx_cmd_data         : std_logic_vector(28 downto 0);
signal last_bnum           : std_logic_vector(3 downto 0); 


component uart_conv_dpram is
    port (
        data_a    : in  std_logic_vector(63 downto 0) := (others => 'X'); -- datain_a
        q_a       : out std_logic_vector(63 downto 0);                    -- dataout_a
        data_b    : in  std_logic_vector(7 downto 0)  := (others => 'X'); -- datain_b
        q_b       : out std_logic_vector(7 downto 0);                     -- dataout_b
        address_a : in  std_logic_vector(8 downto 0)  := (others => 'X'); -- address_a
        address_b : in  std_logic_vector(11 downto 0) := (others => 'X'); -- address_b
        wren_a    : in  std_logic                     := 'X';             -- wren_a
        wren_b    : in  std_logic                     := 'X';             -- wren_b
        clock_a   : in  std_logic                     := 'X';             -- clk
        clock_b   : in  std_logic                     := 'X'              -- clk
    );
end component uart_conv_dpram;


component xgmiirx_cmd_fifo is
port(
	data       : in std_logic_vector(28 downto 0);
	wrreq      : in std_logic;
	rdreq      : in std_logic;
	wrclk      : in std_logic;
	rdclk      : in std_logic;
	aclr       : in std_logic;
	q		   : out std_logic_vector(28 downto 0);
	rdempty    : out std_logic;
	wrfull     : out std_logic
);
end component;
signal fifo_aclr    : std_logic;




begin


-------------rxclk ---------
process(nRST_rxclk,rxclk)
begin
	if nRST_rxclk = '0' then
		wr_point <= '0';
		-- rx_dpram_waddr_buf <= (others=>'0');
		rx_cmd_fifo_wren   <= '0';
		rx_data_wren       <= '0';
		frame_type         <= (others=>'0');
		frame_length       <= (others=>'0');
	elsif rising_edge(rxclk) then

		if xgmii_rx_upctrl(7)='1' then
			rx_data_wren <= '0';
			if rx_data_wren = '1' then
				wr_point     <= not wr_point;
			end if;
		elsif xgmii_rx_upctrl = X"01" and xgmii_rx_updata(63 downto 16)= X"D55555555555" and xgmii_rx_updata(7 downto 0) = X"FB" then
			rx_data_wren <= '1';
		end if;
		
		rx_dpram_waddr(8) <= wr_point;
		if rx_data_wren = '1' then
			rx_dpram_waddr(7 downto 0) <= rx_dpram_waddr(7 downto 0)+1;
		else
			rx_dpram_waddr(7 downto 0) <= (others=>'0');
		end if;
			
		rx_data_wren_d1 <= rx_data_wren;
		
		if rx_data_wren = '1' and rx_data_wren_d1 = '0' and xgmii_rx_upctrl(7) ='0' then
            frame_type <= xgmii_rx_updata(39 downto 32);
            if port_num = 0 then --first 10 eth 
                CHLNUM <= xgmii_rx_updata(23 downto 16);
            else                 --second 10 eth 
                -- CHLNUM <= xgmii_rx_updata(23 downto 16) + conv_std_logic_vector(ETHPORT_NUM,8);
                CHLNUM <= xgmii_rx_updata(23 downto 16) + real_eth_num;
            end if;

		end if;
		
        if xgmii_rx_upctrl = X"01" and xgmii_rx_updata(63 downto 16)= X"D55555555555" and xgmii_rx_updata(7 downto 0) = X"FB" then
            frame_length <= conv_std_logic_vector(0,11);
        elsif xgmii_rx_upctrl(0) = '0' then ---
            frame_length <= frame_length + last_bnum;
        end if;
		
		if rx_data_wren_d1 = '1' and rx_data_wren = '0' then
			rx_cmd_fifo_wren <= '1';
			if frame_type = X"08" then
				rx_cmd_data(28) <= '1';
			else
				rx_cmd_data(28) <= '0';
			end if;
			rx_cmd_data(27 downto 17) <= frame_length;
			rx_cmd_data(16 downto 9)  <= CHLNUM;
			rx_cmd_data(8)            <= not wr_point;
			rx_cmd_data(7 downto 0)   <= (others=>'0');----reserved
		else
			rx_cmd_fifo_wren <= '0';
		end if;
	end if;
end process;
		
	
process(xgmii_rx_upctrl)
begin
    case xgmii_rx_upctrl is
        when "00000000" => last_bnum <= conv_std_logic_vector(8,4);
        when "10000000" => last_bnum <= conv_std_logic_vector(7,4);
        when "11000000" => last_bnum <= conv_std_logic_vector(6,4);
        when "11100000" => last_bnum <= conv_std_logic_vector(5,4);
        when "11110000" => last_bnum <= conv_std_logic_vector(4,4);
        when "11111000" => last_bnum <= conv_std_logic_vector(3,4);
        when "11111100" => last_bnum <= conv_std_logic_vector(2,4);
        when "11111110" => last_bnum <= conv_std_logic_vector(1,4);
        when others =>     last_bnum <= conv_std_logic_vector(0,4);
    end case;
end process;



rx_data_dpram: uart_conv_dpram 
    port map (
        data_a       => xgmii_rx_updata,
        q_a          => open,
        data_b       => (others=>'0'),
        q_b          => rx_data_conv,
        address_a    => rx_dpram_waddr,
        address_b    => rx_data_raddr_conv,
        wren_a       => rx_data_wren,
        wren_b       => '0',
        clock_a      => rxclk,
        clock_b      => convclk_i
    );

	
fifo_aclr <= not nRST_rxclk;

rx_cmdfifo: xgmiirx_cmd_fifo 
port map(
	data        => rx_cmd_data,
	wrreq       => rx_cmd_fifo_wren,
	rdreq       => cmd_fifo_rden_conv,
	wrclk       => rxclk,
	rdclk       => convclk_i,
	aclr        => fifo_aclr,
	q		    => cmd_fifo_q_conv,
	rdempty     => cmd_fifo_empty_conv,
	wrfull      => open
);





end beha;