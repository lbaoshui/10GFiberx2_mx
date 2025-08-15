library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_arith.all ;
use ieee.std_logic_unsigned.all ;

entity bright_lpm is
generic
(
    DDR3_NUM            : integer
);
port
(
    nRST                : in  std_logic;
    sysclk              : in  std_logic;
    p_type              : in  std_logic_vector(7 downto 0);
    p_Wren              : in  std_logic;
    p_Data              : in  std_logic_vector(7 downto 0);
    p_Addr              : in  std_logic_vector(10 downto 0);
	
	output_color_depth_emifclk : in std_logic_vector(DDR3_NUM*2-1 downto 0);

    nRST_ddr3           : in  std_logic_vector(DDR3_NUM-1 downto 0);
    clk_ddr3            : in  std_logic_vector(DDR3_NUM-1 downto 0);

    data_en             : in  std_logic_vector(DDR3_NUM-1 downto 0);
    data_in             : in  std_logic_vector(320*DDR3_NUM-1 DOWNTO 0);

    data_en_O           : out std_logic_vector(DDR3_NUM-1 downto 0);
    data_O              : out std_logic_vector(320*DDR3_NUM-1 DOWNTO 0)
);
end bright_lpm;

architecture beha of bright_lpm IS

component LPM_9x10 is
    port (
        dataa  : in  std_logic_vector(9 downto 0)  := (others => 'X'); -- dataa
        result : out std_logic_vector(18 downto 0);                    -- result
        datab  : in  std_logic_vector(8 downto 0)  := (others => 'X'); -- datab
        clock  : in  std_logic                     := 'X'              -- clk
    );
end component LPM_9x10;

type    RGB_9x3         is array (0 to 2)  of std_logic_vector(8 downto 0);

signal  color_RGB_sys   :   RGB_9x3;
signal  bright_flag     :   std_logic_vector(1 downto 0);
signal  bright_sys      :   std_logic_vector(28 downto 0);
-------------------------------------------------------
signal  bright_flag_d1  :   std_logic_vector(1 downto 0);
signal  bright_flag_d2  :   std_logic_vector(1 downto 0);
signal  bright_flag_d3  :   std_logic_vector(1 downto 0);

---type    RGB_9x3         is array (0 to 2)  of std_logic_vector(8 downto 0);
signal  color_RGB_ddr_b1   :   std_logic_vector(3*9*DDR3_NUM-1 downto 0);
signal  color_RGB_ddr      :   std_logic_vector(3*9*DDR3_NUM-1 downto 0);
-- signal  bright_flg_ddr  :   std_logic_vector(DDR3_NUM-1 downto 0):=(others=>'0');
signal  result_color    :   std_logic_vector(570*DDR3_NUM-1 downto 0);
signal  bright_ddr3     :   std_logic_vector(29*DDR3_NUM-1 downto 0);

attribute syn_keep : boolean;
attribute syn_srlstyle : string;
attribute syn_keep of bright_flag_d1 : signal is true; 
attribute syn_keep of bright_flag_d2 : signal is true; 
--2021
attribute altera_attribute : string;
attribute altera_attribute of bright_flag_d1 : signal is "-name ADV_NETLIST_OPT_ALLOWED NEVER_ALLOW; -name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS; -name DONT_MERGE_REGISTER ON; -name PRESERVE_REGISTER ON";

component cross_domain is 
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
end component ;
signal color_max : std_logic_vector(8 downto 0);

begin


process(nRST,sysclk)
begin
    if(nRST = '0') then
        bright_flag <= (others => '0');
    elsif rising_edge(sysclk) then
        if p_type = X"80" and p_Wren = '1' then
            if p_Addr = 0 and p_Data = X"FF" then
                bright_flag(0) <= '1';
            elsif p_Addr = 12 then
                bright_flag(0) <= '0';
            end if;
            if bright_flag(0) = '1' then
                if p_Addr = 6 then
                    if p_Data /= 0 then
                        color_RGB_sys(2)  <= ('0'&p_Data) + '1';
                    else
                        color_RGB_sys(2)  <= (others => '0');
                    end if;
                end if;
                if p_Addr = 7 then
                    if p_Data /= 0 then
                        color_RGB_sys(1)  <= ('0'&p_Data) + '1';
                    else
                        color_RGB_sys(1)  <= (others => '0');
                    end if;
                end if;
                if p_Addr = 8 then
                    if p_Data /= 0 then
                        color_RGB_sys(0)  <= ('0'&p_Data) + '1';
                    else
                        color_RGB_sys(0)  <= (others => '0');
                    end if;
                end if;
                if p_Addr = 9 then
                    bright_flag(1) <= p_Data(0);
                end if;
            end if;
        end if;
    end if;
end process;

 bright_sys  <= bright_flag &color_RGB_sys(2)&color_RGB_sys(1)&color_RGB_sys(0);
 color_max   <= (8 => '1',others => '0'); 

crs_bright: for i in 0 to DDR3_NUM-1 generate 
   crs_i:cross_domain   
	generic map(
	   DATA_WIDTH  => 29 
	) 
	port map
	(   clk0      => sysclk ,
		nRst0     => nRST   ,		
		datain    => bright_sys ,
		datain_req=> '1',
		
		clk1  => clk_ddr3(i), 
		nRst1 => nRST_ddr3(i),
		data_out => bright_ddr3(i*29+28 downto i*29),
		dataout_valid =>open  ---just pulse only
	);


  parse_clr: process(nRST_ddr3(i),clk_ddr3(i ) ) ---bright_ddr3)
   begin 
      if rising_edge(clk_ddr3(i)) then  
         if bright_ddr3(28+i*29) = '0' then 
             color_RGB_ddr_b1   (i*27+26 downto i*27) <= bright_ddr3(i*29+26 downto i*29) ;
              --- bright_flg_ddr  (i) <= bright_ddr3(27+i*28);
   	     else 
   	         color_RGB_ddr_b1   (i*27+26 downto i*27) <= color_max & color_max & color_max;
   	     end if;
		 
		 color_RGB_ddr    (i*27+26 downto i*27) <= color_RGB_ddr_b1   (i*27+26 downto i*27);
      end if;
   end process;


end generate crs_bright;


-- process(nRST_ddr3(0),clk_ddr3(0))
-- begin
    -- if nRST_ddr3(0) = '0' then
        -- bright_flag_d1  <= (others => '0');
        -- bright_flag_d2  <= (others => '0');
        -- bright_flag_d3  <= (others => '0');
        -- color_RGB(0)    <= (8 => '1',others => '0');
        -- color_RGB(1)    <= (8 => '1',others => '0');
        -- color_RGB(2)    <= (8 => '1',others => '0');
    -- elsif rising_edge(clk_ddr3(0)) then
        -- bright_flag_d1 <= bright_flag;
        -- bright_flag_d2 <= bright_flag_d1;
        -- bright_flag_d3 <= bright_flag_d2;
        -- if bright_flag_d2(0) < bright_flag_d3(0) then
            -- if bright_flag_d3(1) = '0' then
                -- color_RGB(0) <= color_RGB_sys(0);
                -- color_RGB(1) <= color_RGB_sys(1);
                -- color_RGB(2) <= color_RGB_sys(2);
            -- else
                -- color_RGB(0) <= (8 => '1',others => '0');
                -- color_RGB(1) <= (8 => '1',others => '0');
                -- color_RGB(2) <= (8 => '1',others => '0');
            -- end if;
        -- end if;
    -- end if;
-- end process;


LMP_color_i:    for i in 0 to DDR3_NUM-1 generate
    process(clk_ddr3(i))
    begin
        if rising_edge(clk_ddr3(i)) then
            data_en_O(i)                <= data_en(i);
			if output_color_depth_emifclk ((i+1)*2-1)='0' then  ---8bit 10bit
			    LMP_color_j:    for j in 0 to 9 LOOP                  
			       --for 10bit/8bit only 
			       --data_O((i+1)*320-1  downto i*320 )<= data_in((i+1)*320-1  downto i*320 ); --20210123
				    data_O(i*320+j*32+7 downto i*320+j*32+0)   <=  data_in(i*320+j*32+9 downto i*320+j*32+2)  ;----blue
				    data_O(i*320+j*32+15 downto i*320+j*32+8)  <=  data_in(i*320+j*32+19 downto i*320+j*32+12) ;----green
				    data_O(i*320+j*32+23 downto i*320+j*32+16) <=  data_in(i*320+j*32+29 downto i*320+j*32+22);----red
				    data_O(i*320+j*32+29 downto i*320+j*32+28) <=  data_in(i*320+j*32+1  downto i*320+j*32+0);---blue 1~0
				    data_O(i*320+j*32+27 downto i*320+j*32+26) <=  data_in(i*320+j*32+11 downto i*320+j*32+10);---green 1~0
				    data_O(i*320+j*32+25 downto i*320+j*32+24) <=  data_in(i*320+j*32+21 downto i*320+j*32+20);---red 1~0
				    data_O(i*320+j*32+31 downto i*320+j*32+30) <=  (others=>'0') ;
			    END loop LMP_color_j;		
		    else
				data_O((i+1)*320-1  downto i*320 )<= data_in((i+1)*320-1  downto i*320 );
			end if;
        end if;
    end process;
    --  LMP_color_j:    for j in 0 to 9 generate
    --      LMP_color_k:    for k in 0 to 2 generate
    --          color_R: LPM_9x10
    --          port map
    --          (
    --              dataa       => data_in(i*320+j*32+k*10+9 downto i*320+j*32+k*10),
    --              result      => result_color(i*570+j*57+k*19+18 downto i*570+j*57+k*19),
    --              datab       => color_RGB_ddr   (i*27+k*9+8 downto i*27+k*9) , ---color_RGB(k),
    --              clock       => clk_ddr3(i)
    --          );
    --          --data_O(i*320+j*32+k*10+9 downto i*320+j*32+k*10) <= result_color(i*570+j*57+k*19+17 downto i*570+j*57+k*19+8);
    --      end generate LMP_color_k;
    --      data_O(i*320+j*32+7 downto i*320+j*32+0) <= result_color(i*570+j*57+0*19+17 downto i*570+j*57+0*19+10);
    --      data_O(i*320+j*32+15 downto i*320+j*32+8) <= result_color(i*570+j*57+1*19+17 downto i*570+j*57+1*19+10);
    --      data_O(i*320+j*32+23 downto i*320+j*32+16) <= result_color(i*570+j*57+2*19+17 downto i*570+j*57+2*19+10);
    --      data_O(i*320+j*32+29 downto i*320+j*32+28) <= result_color(i*570+j*57+0*19+9 downto i*570+j*57+0*19+8);
    --      data_O(i*320+j*32+27 downto i*320+j*32+26) <= result_color(i*570+j*57+1*19+9 downto i*570+j*57+1*19+8);
    --      data_O(i*320+j*32+25 downto i*320+j*32+24) <= result_color(i*570+j*57+2*19+9 downto i*570+j*57+2*19+8);
    --      data_O(i*320+j*32+31 downto i*320+j*32+30) <= "00";
    --  end generate LMP_color_j;
end generate LMP_color_i;


end beha;