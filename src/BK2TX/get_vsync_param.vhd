


entity get_vsync_param is 
generic ( ETHPORT_IDX : integer;  ---INDEX 
          ETHPORT_NUM : INTEGER;
          
port 
(
  nRST            : in std_logic ;
  sysclk          : in std_logic ;
  p_Frame_en_i    : in std_logic ;
  p_Wren_i        : in std_logic ;
  p_Data_i        : in std_logic_vector(7 downto 0);
  p_Addr_i        : in std_logic_vector(10 downto 0);
  cur_slot_num    : in std_logic_vector(15 downto 0);
   
   rcv_led               : in std_logic_vector(1 downto 0);
    autolight_outen      : in std_logic_vector(ETHPORT_NUM-1   downto 0) ;
    autolight_outval     : in std_logic_vector(ETHPORT_NUM*8-1 downto 0); 
    brightness_manual_en : in std_logic_vector(ETHPORT_NUM-1   downto 0) ;
    brightness_manual    : in std_logic_vector(ETHPORT_NUM*8-1 downto 0);

 
  
    hdr_en              :OUT std_logic:= '0';
    hdr_type            :OUT std_logic_vector(3 downto 0):= (others => '0');
    hdr_rr              :OUT std_logic_vector(15 downto 0):= (others => '0');
    hdr_rg              :OUT std_logic_vector(15 downto 0):= (others => '0');
    hdr_rb              :OUT std_logic_vector(15 downto 0):= (others => '0');
    hdr_gr              :OUT std_logic_vector(15 downto 0):= (others => '0');
    hdr_gg              :OUT std_logic_vector(15 downto 0):= (others => '0');
    hdr_gb              :OUT std_logic_vector(15 downto 0):= (others => '0');
    hdr_br              :OUT std_logic_vector(15 downto 0):= (others => '0');
    hdr_bg              :OUT std_logic_vector(15 downto 0):= (others => '0');
    hdr_bb              :OUT std_logic_vector(15 downto 0):= (others => '0');
    hdr_coef            :OUT std_logic_vector(5 downto 0):= (others => '0');
    hlg_type            :OUT std_logic_vector(7 downto 0):= (others => '0'); 



eth_port           : in  std_logic ;
req_f9_upload_buf  : out std_logic ;
rcv_led_flick      : out std_logic ;
brighttemp_set_buf : out std_logic_vector(8*ETHPORT_NUM-1 downto 0);
bright_coeff       : out std_logic_vector(8*ETHPORT_NUM-1 downto 0);

colort_R           : out std_logic_vector(8*ETHPORT_NUM-1 downto 0);
colort_G           : out std_logic_vector(8*ETHPORT_NUM-1 downto 0);
colort_B           : out std_logic_vector(8*ETHPORT_NUM-1 downto 0);
);
end get_vsync_param ;

architecture beha of get_vsync_param is 
signal ptype_d1     : std_logic_vector(7 downto 0);
signal pwren_d1     : std_logic;
signal paddr_buff   : std_logic_vector(10 downto 0);
signal paddr_d1     : std_logic_vector(10 downto 0);
signal pdata_d1     : std_logic_vector(7 downto 0); 
constant OFF_PADD   : integer := 1 ;
signal offset_X80   : std_logic_vector(10 downto 0);
signal offset_X22   : std_logic_vector(10 downto 0);
signal ptype_hdr_en         : std_logic:= '0';

signal hdr_en               : std_logic:= '0';
signal hdr_type             : std_logic_vector(3 downto 0):= (others => '0');
signal hdr_rr               : std_logic_vector(15 downto 0):= (others => '0');
signal hdr_rg               : std_logic_vector(15 downto 0):= (others => '0');
signal hdr_rb               : std_logic_vector(15 downto 0):= (others => '0');
signal hdr_gr               : std_logic_vector(15 downto 0):= (others => '0');
signal hdr_gg               : std_logic_vector(15 downto 0):= (others => '0');
signal hdr_gb               : std_logic_vector(15 downto 0):= (others => '0');
signal hdr_br               : std_logic_vector(15 downto 0):= (others => '0');
signal hdr_bg               : std_logic_vector(15 downto 0):= (others => '0');
signal hdr_bb               : std_logic_vector(15 downto 0):= (others => '0');
signal hdr_coef             : std_logic_vector(5 downto 0):= (others => '0');
signal hlg_type             : std_logic_vector(7 downto 0):= (others => '0'); 

signal eport_cnt     : integer range 0 to ETHPORT_NUM-1 := 0;
signal eport_dly_cnt : integer range 0 to ETHPORT_NUM-1 := 0;
signal eport_inc     : std_logic := '0';
signal chrome_r_mult_in     : std_logic_vector(9 downto 0); 
signal chrome_g_mult_in     : std_logic_vector(9 downto 0);
signal chrome_b_mult_in     : std_logic_vector(9 downto 0);
signal chrome_x_mult_in     : std_logic_vector(9 downto 0); 
signal chrome_x_mult_out    : std_logic_vector(18 downto 0); 
signal chrome_x_mult_out_buf: std_logic_vector(18 downto 0); 
signal chrXbri_r_buf        : std_logic_vector(7 downto 0); 
signal chrXbri_g_buf        : std_logic_vector(7 downto 0);
signal chrXbri_b_buf        : std_logic_vector(7 downto 0);
signal chrXbri_r            : std_logic_vector(8*ETHPORT_NUM-1 downto 0); 
signal chrXbri_g            : std_logic_vector(8*ETHPORT_NUM-1 downto 0);
signal chrXbri_b            : std_logic_vector(8*ETHPORT_NUM-1 downto 0);
signal chrom_sel            : std_logic_vector(1 downto 0);

begin 

process(nRST,SYSCLK)
begin 
    if nRST = '0' then
        ptype_d1 <= (others => '0'); 
        pwren_d1 <= '0';
        paddr_d1 <= (others => '0'); 
        pdata_d1 <= (others => '0');  
    elsif rising_edge(SYSCLK) then
        IF p_Frame_en_i= '1' and p_Wren_i = '1' and p_Addr_i = 0 then 
            ptype_d1 <= p_Data_i;
        end if;
        if p_Frame_en_i= '1' and p_Wren_i = '1' and p_Addr_i > 0 then 
            pwren_d1 <= p_Wren_i;
        else 
            pwren_d1 <= '0';
        end if;
        paddr_buf <= p_Addr_i ; 
        pdata_d1 <= p_Data_i ;  
    end if;
end process; 
paddr_d1 <= paddr_buf- OFF_PADD;----- PADD;



offset_X22 <= paddr_d1 - 13;
process(nRST,SYSCLK)
begin
    if nRST = '0' then
        backup_flg <= '0';
        rcv_led_buf <= '0';
    elsif rising_edge(sysclk) then
        if ptype_d1 = X"36" and pwren_d1 = '1' then 
            if offset_X22 = portnum_tmp(10 downto 3) then
                backup_flg <= pdata_d1(conv_integer(portnum_tmp(2 downto 0)));
            end if;    
        end if; 
        if backup_flg = '0' then
            rcv_led_buf <= rcv_led(0);
        else
            rcv_led_buf <= rcv_led(1);
        end if;     
    end if;
end process; 

offset_X80 <= paddr_d1 - 5 ;
process(nRST,SYSCLK)
begin
    if nRST = '0' then
        bright_local <= (others => '1');
        brighttemp_set <= (others => '0');
        chroma_r <= (others => '1');
        chroma_g <= (others => '1');
        chroma_b <= (others => '1');
    elsif rising_edge(sysclk) then
        if ptype_d1 = X"80" and pwren_d1 = '1' then 
           for i in 0 to ETHPORT_NUM-1 LOOP        
                if offset_X80(10 downto 3) = ETHPORT_IDX+i then
                    case (conv_integer(offset_X80(2 downto 0))) is 
                        when 0 => bright_local( (i+1)*8-1 downto i*8) <= pdata_d1;
                        when 1 => chroma_r    ( (i+1)*8-1 downto i*8) <= pdata_d1;
                        when 2 => chroma_g    ( (i+1)*8-1 downto i*8) <= pdata_d1;
                        when 3 => chroma_b    ( (i+1)*8-1 downto i*8) <= pdata_d1;
                        when 4 => brighttemp_set( (i+1)*8-1 downto i*8) <= pdata_d1;
                        when others => null;
                    end case;    
                end if;   
            end loop;                
        end if;    
    end if;
end process; 



process(nRST,sysclk)
begin
    if nRST = '0' then
        chrome_x_mult_in <= (others => '0');
        chrom_sel        <= "00";
        eport_cnt        <= 0   ;
        eport_inc        <= '0';
    elsif rising_edge(sysclk) then
         if chrom_sel = "00" then
            chrom_sel <= "01";
            eport_inc <= '0';
        elsif chrom_sel = "01" then
            chrom_sel <= "10";
            eport_inc <= '0';
        else
            chrom_sel <= "00";
            if eport_cnt >= ETHPORT_NUM-1 loop
                 eport_cnt <= 0 ;
                 eport_inc <= '1';
            else 
                 eport_cnt <= eport_cnt + 1;
                 eport_inc <= '0';
            end if;
        end if;
        dly_ept_inc <= dly_ept_inc(5 downto 0)&eport_inc;
       
       chroma_sel_r <= "00" & chroma_r( (eport_cnt+1)*8-1 downto eport_cnt*8);
       chroma_sel_g <= "00" & chroma_g( (eport_cnt+1)*8-1 downto eport_cnt*8);
       chroma_sel_b <= "00" & chroma_b( (eport_cnt+1)*8-1 downto eport_cnt*8);
       chrome_r_mult_in <= chroma_sel_r; -----"00" & chroma_r( (eport_cnt+1)*8-1 downto eport_cnt*8);
       chrome_g_mult_in <= chroma_sel_g; -----"00" & chroma_g( (eport_cnt+1)*8-1 downto eport_cnt*8);
       chrome_b_mult_in <= chroma_sel_b; -----"00" & chroma_b( (eport_cnt+1)*8-1 downto eport_cnt*8);

        case chrom_sel is
            when "00" => chrome_x_mult_in <= chrome_r_mult_in;  chrXbri_g_buf <= chrome_x_mult_out_buf(15 downto 8);
            when "01" => chrome_x_mult_in <= chrome_g_mult_in;  chrXbri_b_buf <= chrome_x_mult_out_buf(15 downto 8);
            when "10" => chrome_x_mult_in <= chrome_b_mult_in;  chrXbri_r_buf <= chrome_x_mult_out_buf(15 downto 8);
            when others => null;
        end case;
       if dly_ept_inc(5) = '1' then 
            if eport_dly_cnt >= ETHPORT_NUM-1 then 
               eport_dly_cnt <= 0;
            else 
               eport_dly_cnt <= eport_dly_cnt + 1; 
            end if;
        end if;
      ---final value 
      chrXbri_g ( eport_dly_cnt+1)*8-1 downto eport_dly_cnt*8) <= chrXbri_g_buf ;
      chrXbri_b ( eport_dly_cnt+1)*8-1 downto eport_dly_cnt*8) <= chrXbri_b_buf ;
      chrXbri_r ( eport_dly_cnt+1)*8-1 downto eport_dly_cnt*8) <= chrXbri_r_buf ;
    end if;
end process;

process(nRST,sysclk)
begin
    if nRST = '0' then
        bright_coeff <= "100000000";
        -- timeout_cnt <= (others => '0');
        chrome_x_mult_out_buf <= (others => '0');
    elsif rising_edge(sysclk) then
        -- if brightness_manual_en = '1' then
            -- timeout_cnt <= (others => '0');
        -- elsif timeout_cnt(7) = '0' then
            -- if time_ms_en = '1' then
                -- timeout_cnt <= timeout_cnt + '1';
            -- end if;
        -- end if;  
        
        if vsync_neg_buf(31) = '1' then
            for i in 0 to ETHPORT_NUM-1 loop 
                if brightness_manual_en(i) = '1' then
                    bright_coeff( (i+1)*8-1 downto i*8) <= ('0'&brightness_manual ( (i+1)*8-1 downto i*8) + '1';
                else
                    bright_coeff( (i+1)*8-1 downto i*8) <= ('0'&bright_local( (i+1)*8-1 downto i*8)) + '1';
                end if;
            end loop;
        end if;    
        chrome_x_mult_out_buf <= chrome_x_mult_out;
    end if;
end process;

chrome_x_mult_out <= chrome_x_mult_in * bright_coeff;

locl_brg_g:for i in 0 to ETHPORT_NUM-1 generate 
 calc_brg_l:process(nRST,sysclk)
      begin
          if nRST = '0' then
              bright_coeff_local((i+1)*9-1 downto i*9) <= "100000000";
          elsif rising_edge(sysclk) then
          
              if black_en = '1' then
                  bright_coeff_local((i+1)*9-1 downto i*9) <= (others => '0');
              elsif brighttemp_set_buf(0) = '1' then
                  bright_coeff_local((i+1)*9-1 downto i*9) <= "100000000";
              else
                  case comp_cnt_dly is
                      when "00" => bright_coeff_local((i+1)*9-1 downto i*9) <= ('0'&chrXbri_b((i+1)*8-1 downto i*8)) + '1';
                      when "01" => bright_coeff_local((i+1)*9-1 downto i*9) <= ('0'&chrXbri_g((i+1)*8-1 downto i*8)) + '1';
                      when "10" => bright_coeff_local((i+1)*9-1 downto i*9) <= ('0'&chrXbri_r((i+1)*8-1 downto i*8)) + '1';
                      when others => null;
                  end case;
              end if;    
          end if;
      end process;
end generate locl_brg_g;

process(sysclk,nRST)
begin
    if nRST = '0' then
        ptype_hdr_en <= '0';
        hdr_en <= '0';
    elsif rising_Edge(sysclk) then
        if ptype = x"5c" then
            ptype_hdr_en <= '1';
        else
            ptype_hdr_en <= '0';
        end if;
        
        if ptype_hdr_en = '1' and pwren_d1 = '1' then
            case  conv_integer(paddr_d1) is
                when 3  => hdr_en <= pdata_d1(0);
                when 4  => hdr_type <= pdata_d1(3 downto 0);
                when 5  => hdr_rr(15 downto 8) <= pdata_d1(7 downto 0);
                when 6  => hdr_rr( 7 downto 0) <= pdata_d1(7 downto 0);
                when 7  => hdr_rg(15 downto 8) <= pdata_d1(7 downto 0);
                when 8  => hdr_rg( 7 downto 0) <= pdata_d1(7 downto 0);
                when 9  => hdr_rb(15 downto 8) <= pdata_d1(7 downto 0);
                when 10  => hdr_rb( 7 downto 0) <= pdata_d1(7 downto 0);
                when 11  => hdr_gr(15 downto 8) <= pdata_d1(7 downto 0);
                when 12  => hdr_gr( 7 downto 0) <= pdata_d1(7 downto 0);
                when 13  => hdr_gg(15 downto 8) <= pdata_d1(7 downto 0);
                when 14  => hdr_gg( 7 downto 0) <= pdata_d1(7 downto 0);
                when 15  => hdr_gb(15 downto 8) <= pdata_d1(7 downto 0);
                when 16  => hdr_gb( 7 downto 0) <= pdata_d1(7 downto 0);
                when 17  => hdr_br(15 downto 8) <= pdata_d1(7 downto 0);
                when 18  => hdr_br( 7 downto 0) <= pdata_d1(7 downto 0);
                when 19  => hdr_bg(15 downto 8) <= pdata_d1(7 downto 0);
                when 20  => hdr_bg( 7 downto 0) <= pdata_d1(7 downto 0);
                when 21  => hdr_bb(15 downto 8) <= pdata_d1(7 downto 0);
                when 22  => hdr_bb( 7 downto 0) <= pdata_d1(7 downto 0);
                when 23  => hdr_coef(5 downto 0) <= pdata_d1(5 downto 0);
                when 24  => hlg_type(7 downto 0) <= pdata_d1(7 downto 0);
                when others => null;
            end case;
        end if;                       
    end if;                           
end process;


end beha ;