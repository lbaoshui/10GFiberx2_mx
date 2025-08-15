library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity cross_domain is 
	generic (
	   DATA_WIDTH: integer:=8 
	);
	port 
	(   clk0      : in std_logic;
		nRst0     : in std_logic;		
		datain    : in std_logic_vector(DATA_WIDTH-1 downto 0);
		datain_req: in std_logic;
		
		clk1: in std_logic;
		nRst1: in std_logic;
		data_out: out std_logic_vector(DATA_WIDTH-1 downto 0);
		dataout_valid:out std_logic  ---just pulse only
	);
end cross_domain;

architecture beha of cross_domain is 
signal datain_ack: std_logic:='0';
signal datain_hold: std_logic:='0';

signal datain_buf: std_logic_vector(DATA_WIDTH-1 downto 0);

SIGNAL dout_hold             			: std_logic:='0';
-- signal din1_hold, 
signal din2_hold  			: std_logic:='0';
signal din1_hold             			: std_logic_vector(2 downto 0):=(others=>'0');
signal dout1_hold           			: std_logic_vector(2 downto 0):=(others=>'0');
signal dout2_hold            			: std_logic:='0';
signal dout_valid            			: std_logic:='0';
--20170816 wangac
attribute syn_keep : boolean;
attribute syn_srlstyle : string;
---20170816 wangac
-- attribute syn_keep of dout_hold,dout0_hold,dout1_hold, dout2_hold : signal is true;
-- attribute syn_keep of din0_hold,din1_hold ,din2_hold: signal is true;
-- attribute syn_keep of datain_hold: signal is true;
-- attribute syn_keep of datain_ack: signal is true;


  attribute ASYNC_REG         : string;
  attribute shreg_extract     : string;
  attribute ASYNC_REG     of din1_hold         : signal is "TRUE";
  attribute shreg_extract of din1_hold         : signal is "no";
  attribute ASYNC_REG     of dout1_hold         : signal is "TRUE";
  attribute shreg_extract of dout1_hold         : signal is "no";

attribute altera_attribute : string;

--attribute altera_attribute of dout_hold : signal is "-name ADV_NETLIST_OPT_ALLOWED NEVER_ALLOW; -name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS; -name DONT_MERGE_REGISTER ON; -name PRESERVE_REGISTER ON"  ;
---attribute altera_attribute of dout0_hold : signal is "-name ADV_NETLIST_OPT_ALLOWED NEVER_ALLOW; -name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS; -name DONT_MERGE_REGISTER ON; -name PRESERVE_REGISTER ON" ;
attribute altera_attribute of dout1_hold : signal is "-name ADV_NETLIST_OPT_ALLOWED NEVER_ALLOW; -name DONT_MERGE_REGISTER ON; -name PRESERVE_REGISTER ON" ;
--attribute altera_attribute of dout2_hold : signal is "-name ADV_NETLIST_OPT_ALLOWED NEVER_ALLOW; -name DONT_MERGE_REGISTER ON; -name PRESERVE_REGISTER ON" ;
--attribute altera_attribute of din0_hold : signal is "-name ADV_NETLIST_OPT_ALLOWED NEVER_ALLOW; -name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS;-name DONT_MERGE_REGISTER ON; -name PRESERVE_REGISTER ON" ;
attribute altera_attribute of din1_hold : signal is "-name ADV_NETLIST_OPT_ALLOWED NEVER_ALLOW; -name DONT_MERGE_REGISTER ON; -name PRESERVE_REGISTER ON" ;
--attribute altera_attribute of din2_hold : signal is "-name ADV_NETLIST_OPT_ALLOWED NEVER_ALLOW; -name DONT_MERGE_REGISTER ON; -name PRESERVE_REGISTER ON" ;
--attribute altera_attribute of datain_ack : signal is "-name ADV_NETLIST_OPT_ALLOWED NEVER_ALLOW; -name DONT_MERGE_REGISTER ON; -name PRESERVE_REGISTER ON";
 



begin 


process(clk0)
begin
	if rising_edge(clk0) THEN
		dout1_hold <= dout1_hold(1 downto 0) & dout_hold; ---- dout1_hold;
        dout2_hold <= dout1_hold(2);
		 --- dout1_hold <= dout0_hold;
		-- dout0_hold <= dout_hold;
		if datain_req = '1' and datain_hold = dout2_hold  then  ---empty 
			datain_hold <= not  datain_hold; ---notify to get the data
			datain_buf  <= 	datain;    	  	  
		end if;
	end if;
end process;

dataout_valid <= dout_valid;
process(clk1)
begin
	if rising_edge(clk1) THEN
		---din0_hold <= datain_hold ;
		---din1_hold <= din0_hold ;
		din1_hold <= din1_hold(1 downto 0)&datain_hold;
        din2_hold <= din1_hold(2);
		if dout_valid = '1' then 
			dout_valid <= '0';
		elsif din2_hold /= dout_hold then 
			dout_valid <= '1';
		end if;

		if din2_hold /= dout_hold then -----data arrived
			dout_hold <= not dout_hold;
			data_out  <= datain_buf;
		end if;
	end if;
end process;
	
end beha; 
		
		

