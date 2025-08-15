library ieee;
use ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.ALL;
USE ieee.std_logic_arith.ALL;

use work.PCK_CRC32_D8_NEW.all;
use work.PCK_CRC32_D16_NEW.all;
use work.PCK_CRC32_D24_NEW.all;
use work.PCK_CRC32_D32_NEW.all;
use work.PCK_CRC32_D40_NEW.all;
use work.PCK_CRC32_D48_NEW.all;
use work.PCK_CRC32_D56_NEW.all;
use work.PCK_CRC32_D64_NEW.all;

---XGMII is LSB bytes first -----
---CRC is MSB BYTE FIRST ....

---notice : the new CRC32_D8 ,the bit order of every byte is inversed .
---
---

entity crc64_top is 
generic 
( 
 
 B_W : integer := 4 ; --at most 8 bytes
 D_W : integer := 64;
 D_LSB_F: integer := 1; ---'1': data is lsb BYTE first, '0': data is msb first (first out)
 CRC_W: integer:= 32 ;
 INV_BYTE_BIT: integer:=1   -- 1 : bit7 bit0 swap FOR NEW,  '0': no swap for OLD (2003 VERSION)
);
port 
(
   nRST       : in  std_logic; 
   clr_i      : in  std_logic ;
   clk_i      : in  std_logic ;
   frm_en_i   : in  std_logic ;
   ctrl_i     : in  std_logic_vector((D_W/8)-1 DOWNTO 0);
   data_i     : in  std_logic_vector(D_W-1 downto 0);
   bnum_i     : in  std_logic_vector(B_W-1 downto 0);
   din_en_i   : in  std_logic ;
   last_en_i  : in  std_logic ;
   first_en_i : in  std_logic ;
   
   --delayed one-clock version of the inputs
   den_o      : out  std_logic ;
   laste_o    : out  std_logic ;
   frm_en_o   : out  std_logic ;
   ctrl_o     : out  std_logic_vector((D_W/8)-1 DOWNTO 0);
 
   firsten_o  : out std_logic ;
   bnum_o     : out std_logic_vector(B_W-1   downto 0);
   total_bnum : out std_logic_vector(14 downto 0);
   data_o     : out std_logic_vector(D_W-1   downto 0);
   crc_o      : out std_logic_vector(CRC_W-1 downto 0)   
);
end crc64_top ;

architecture beha_crc64_top of crc64_top is 
signal bnum_lock1     :   std_logic_vector(B_W-1   downto 0);
signal bnum_lock2     :   std_logic_vector(B_W-1   downto 0);
signal b8_lock1       : std_logic_vector(B_W-1 downto 0);
signal d64_lock1      : std_logic_vector(D_W-1 downto 0);
signal data_crc1      : std_logic_vector(D_W-1 downto 0);
signal data_crc2      : std_logic_vector(D_W-1 downto 0);
signal d64_msb_lock1   : std_logic_vector(D_W-1 downto 0);
signal d64_msb_lock2   : std_logic_vector(D_W-1 downto 0);
signal den_lock1      : std_logic ;
signal lasten_lock1   : std_logic ;
signal firsten_lock1  : std_logic ;

signal b8_lock2       : std_logic_vector(B_W-1 downto 0);
signal d64_lock2      : std_logic_vector(D_W-1 downto 0);
-- signal data_crc      : std_logic_vector(D_W-1 downto 0);
-- signal d64_msb_lock2  : std_logic_vector(D_W-1 downto 0);
signal den_lock2      : std_logic ;
signal lasten_lock2   : std_logic ;
signal firsten_lock2  : std_logic ;

signal crc64_v       : std_logic_vector(CRC_W-1 downto 0):=(others=>'1');
signal crc08_v       : std_logic_vector(CRC_W-1 downto 0):=(others=>'1');
signal crc16_v       : std_logic_vector(CRC_W-1 downto 0):=(others=>'1');
signal crc24_v       : std_logic_vector(CRC_W-1 downto 0):=(others=>'1');
signal crc32_v       : std_logic_vector(CRC_W-1 downto 0):=(others=>'1');
signal crc40_v       : std_logic_vector(CRC_W-1 downto 0):=(others=>'1');
signal crc48_v       : std_logic_vector(CRC_W-1 downto 0):=(others=>'1');
signal crc56_v       : std_logic_vector(CRC_W-1 downto 0):=(others=>'1');

signal crc_final     : std_logic_vector(CRC_W-1 downto 0):=(others=>'1'); 
--------------------------------------------------------------------
signal d08_last      : std_logic_vector(0*8+7 downto 0);
signal d16_last      : std_logic_vector(1*8+7 downto 0);
signal d24_last      : std_logic_vector(2*8+7 downto 0);
signal d32_last      : std_logic_vector(3*8+7 downto 0);
signal d40_last      : std_logic_vector(4*8+7 downto 0);
signal d48_last      : std_logic_vector(5*8+7 downto 0);
signal d56_last      : std_logic_vector(6*8+7 downto 0);
 
 signal frm_en_lock1  : std_logic := '0';
 signal ctrl_lock1    : std_logic_vector((D_W/8)-1 downto 0):=(others=>'1');
 
 signal frm_en_lock2  : std_logic := '0';
 signal ctrl_lock2    : std_logic_vector((D_W/8)-1 downto 0):=(others=>'1');
 
 signal total_bcnt   : std_logic_vector(14 downto 0);

begin 
    
    total_bnum <= total_bcnt;

    process(nRST ,clk_i)
    begin 
        if nRST = '0' then 
            b8_lock1     <= (others=>'1'); 
            d64_lock1    <= (others=>'0');
            frm_en_lock1 <= '0' ;
            ctrl_lock1   <= (others=>'1') ;
            den_lock1    <= '0';
            lasten_lock1 <= '0';
            firsten_lock1 <= '0';
            bnum_lock1      <= conv_std_logic_vector(1, B_W) ;
            
            b8_lock2     <= (others=>'1'); 
            d64_lock2    <= (others=>'0');
            frm_en_lock2 <= '0' ;
            ctrl_lock2   <= (others=>'1') ;
            den_lock2    <= '0';
            lasten_lock2 <= '0';
            firsten_lock2<= '0';
            bnum_lock2      <= conv_std_logic_vector(1, B_W) ;
            
        elsif rising_edge(clk_i) then 
            b8_lock1     <= bnum_i   ;
            bnum_lock1   <= bnum_i ;
            d64_lock1    <= data_i   ;
            frm_en_lock1 <= frm_en_i ;
            ctrl_lock1   <= ctrl_i ;
            den_lock1    <= din_en_i ;
            lasten_lock1 <= last_en_i;
            firsten_lock1<= first_en_i; ---- last_en_i;  
            
            b8_lock2     <= b8_lock1;
            bnum_lock2   <= bnum_lock1     ;
            d64_lock2    <= d64_lock1      ;
            frm_en_lock2 <= frm_en_lock1   ;
            ctrl_lock2   <= ctrl_lock1     ;
            den_lock2    <= den_lock1      ;
            lasten_lock2 <= lasten_lock1   ;
            firsten_lock2<= firsten_lock1  ;
            
            

            -- bnum_o      <= bnum_i ;
            -- d64_lock    <= data_i   ;
            -- frm_en_lock <= frm_en_i ;
            -- ctrl_lock   <= ctrl_i ;
            -- den_lock    <= din_en_i ;
            -- lasten_lock <= last_en_i;
            -- firsten_lock<= last_en_i;              
        end if;
    end process;
    
 
    
    process(nRST ,clk_i)
    begin 
        if nRST = '0' then 
            crc64_v <= (others=>'1'); 
            total_bcnt    <= (others=>'0');
        elsif rising_edge(clk_i) then 
            
            if clr_i = '1' then 
                crc64_v <= (others=>'1');
                total_bcnt    <= (others=>'0');
            elsif din_en_i = '1' then 
                total_bcnt <= total_bcnt + bnum_i;
                if bnum_i >= 8 then 
                    crc64_v <= nextCRC32_D64_NEW(data_crc2,crc64_v);
                end if;
            end if;
        end if;
    end process;
    process(data_i)
    begin 
        if D_LSB_F = 0 THEN --msb byte FIRTS to match CRC CALC
             data_crc1 <= data_i;
        else 
            for i in 0 to 7 loop 
                data_crc1(8*(i+1)-1 downto i*8)<=  data_i(63-i*8 downto 64-(i+1)*8);
            end loop;
        end if;
    end process;
    process(data_crc1)
    begin 
        if INV_BYTE_BIT = 0 then 
                data_crc2 <= data_crc1 ;
        else 
              for i in 0 to 7 loop
                 for j in 0 to 7 loop
                    data_crc2(i*8+j)<=data_crc1(i*8+7-j);
                 end loop;
              end loop;
        end if;
    end process;
    
    process(d64_lock1)
    begin 
        if D_LSB_F = 0 THEN --msb FIRTS
            d64_msb_lock1 <= d64_lock1;
        else --convert LSB-first to MSB-First...
            for j in 0 to 7 loop
              d64_msb_lock1(8*(j+1)-1 downto j*8)<=  d64_lock1(63-j*8 downto 64-(j+1)*8);
            end loop;
        end if;
    end process;
    
        process(d64_msb_lock1)
    begin 
        if INV_BYTE_BIT = 0 then 
                d64_msb_lock2 <= d64_msb_lock1 ;
        else 
              for i in 0 to 7 loop
                 for j in 0 to 7 loop
                    d64_msb_lock2(i*8+j)<=d64_msb_lock1(i*8+7-j);
                 end loop;
              end loop;
        end if;
    end process;
    
    
    process(d64_msb_lock2) --MSB first 
    begin  
        -------------------------------------------------------------  
        --data is MSB first     
        d08_last ( 0*8+7 downto 0*8)<=  d64_msb_lock2( 63-(0*8) downto 64-(1*8) ) ;
        d16_last ( 1*8+7 downto 0*8)<=  d64_msb_lock2( 63-(0*8) downto 64-(2*8) ) ; --
        d24_last ( 2*8+7 downto 0*8)<=  d64_msb_lock2( 63-(0*8) downto 64-(3*8) ) ; --
        d32_last ( 3*8+7 downto 0*8)<=  d64_msb_lock2( 63-(0*8) downto 64-(4*8) ) ; --
        d40_last ( 4*8+7 downto 0*8)<=  d64_msb_lock2( 63-(0*8) downto 64-(5*8) ) ; --  
        d48_last ( 5*8+7 downto 0*8)<=  d64_msb_lock2( 63-(0*8) downto 64-(6*8) ) ; --
        d56_last ( 6*8+7 downto 0*8)<=  d64_msb_lock2( 63-(0*8) downto 64-(7*8) ) ; --
       
   end process;
    
  crc08_v  <=  nextCRC32_D8_NEW (d08_last,crc64_v);    
  crc16_v  <=  nextCRC32_D16_NEW(d16_last,crc64_v);    
  crc24_v  <=  nextCRC32_D24_NEW(d24_last,crc64_v);    
  crc32_v  <=  nextCRC32_D32_NEW(d32_last,crc64_v);    
  crc40_v  <=  nextCRC32_D40_NEW(d40_last,crc64_v);    
  crc48_v  <=  nextCRC32_D48_NEW(d48_last,crc64_v);    
  crc56_v  <=  nextCRC32_D56_NEW(d56_last,crc64_v);    
 
    process(nRST,clk_i)
    begin 
        if nRST = '0' then 
            crc_final <= (others=>'1');
        elsif rising_edge(clk_i) then 
            if clr_i = '1' then 
                crc_final <= (others=>'1'); 
            elsif den_lock1 = '1' and lasten_lock1 = '1' then 
                case( conv_integer(b8_lock1) ) is 
                    when  1     => crc_final <= crc08_v;  
                    when  2     => crc_final <= crc16_v;
                    when  3     => crc_final <= crc24_v;
                    when  4     => crc_final <= crc32_v;
                    when  5     => crc_final <= crc40_v;
                    when  6     => crc_final <= crc48_v;
                    when  7     => crc_final <= crc56_v;
                    when  others=> crc_final <= crc64_v;
                end case;
            end if;
        end if;
    end process;
    
    bnum_o    <= bnum_lock2 ;
    data_o    <= d64_lock2    ;
    crc_o     <= crc_final   ;
    den_o     <= den_lock2    ;
    laste_o   <= lasten_lock2 ;
    firsten_o <= firsten_lock2;
    frm_en_o  <= frm_en_lock2  ;
    ctrl_o    <= ctrl_lock2    ;  

end beha_crc64_top;
