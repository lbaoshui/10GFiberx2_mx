
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all; 

entity time_ms_gen is 
generic 
(
 IS_156M: integer := 0   --0: 125M 1 : 156M
);
port ( nRST         : in  std_logic  ;
       clk          : in std_logic ;
       time_ms_en_o : out std_logic ;
       --conv domain
       nRST_conv      : in  std_logic ;
       conv_clk       : in  std_logic ; 
       time_ms_en_conv: out std_logic 
     );
end time_ms_gen ;

architecture beha of time_ms_gen is 
signal ms_en_flipflop_sys   : std_logic ;
signal ms_en_flipflop_conv  : std_logic ;
signal dly_ms_en_ff_conv    : std_logic ;
signal time_ms_cnt          : std_logic_vector(17 downto 0):=(others => '0');   
signal time_ms_en           : std_logic:='0';
component altera_std_synchronizer is 
  generic (depth : integer := 3);
  port   
     (
				    clk : in std_logic ;
				reset_n : in std_logic ; 
				din     : in std_logic ;
				dout    : out std_logic
				);  
 end component;
begin 


process(nRST , clk)
begin
    if(nRST = '0') then 
        time_ms_en <= '0';
        time_ms_en_o <= '0';
        ms_en_flipflop_sys <= '0';
        time_ms_cnt <= (others => '0');
    elsif rising_edge(clk) then
         time_ms_en_o <= time_ms_en ;
         if time_ms_en = '1' then 
             ms_en_flipflop_sys <= not ms_en_flipflop_sys ;
         end if;
         if IS_156M = 0  then 
            if time_ms_cnt = 124999 then    --125000 * 8ns = 1ms,
                time_ms_en <= '1';
                time_ms_cnt <= (others => '0');
            else
                time_ms_en <= '0';
                time_ms_cnt <= time_ms_cnt + '1';
            end if;  
         else  --18bit
            if time_ms_cnt = 156249 then    -- 125000 * 8ns = 1ms,
                time_ms_en <= '1';
                time_ms_cnt <= (others => '0');
            else
                time_ms_en <= '0';
                time_ms_cnt <= time_ms_cnt + '1';
            end if;  
        end if;
    end if;
end process;


 c2conv_en: altera_std_synchronizer   
  port   map 
     (
				    clk  => conv_clk,
				reset_n  => nRST_conv,
				din      => ms_en_flipflop_sys,
				dout     => ms_en_flipflop_conv
				);  

  process(conv_clk)
  begin 
    if rising_edge(conv_clk) then 
        dly_ms_en_ff_conv   <= ms_en_flipflop_conv;
        if dly_ms_en_ff_conv /= ms_en_flipflop_conv then 
            time_ms_en_conv <= '1';
        else 
            time_ms_en_conv <= '0';
        end if;
    end if;
  end process;

end beha ;