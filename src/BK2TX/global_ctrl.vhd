library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.PCK_bk_serdes.all;


entity global_ctrl is
generic
(  SIM               : std_logic := '0';
   SERDES_5G_EN      : std_logic := '0';
   FIBER_NUM         : integer :=2  ;
   ETHPORT_NUM       : integer   := 10   -- PER FIBER
);
port
(

    nRST_conv             : in  std_logic    ; ---
    convclk_i             : in  std_logic    ; --200M almost

    vsync_neg             : in std_logic  ;
    p_Frame_en_conv       : in std_logic ;
    p_Wren_conv           : in std_logic ;
    p_Data_conv           : in std_logic_vector(7 downto 0);
    p_Addr_conv           : in std_logic_vector(10 downto 0);
    time_ms_en_conv    :  in std_logic ;
	rcv_led_out		   : out std_logic_vector(1 downto 0);
	backup_flag        : out std_logic_vector(FIBER_NUM*ETHPORT_NUM-1 downto 0);
    req_f9_upload      : out std_logic ;
	HDR_enable         : out std_logic;
	HDR_type           : out std_logic_vector(7 downto 0);
	HDR_rr             : out std_logic_vector(15 downto 0);
	HDR_rg             : out std_logic_vector(15 downto 0);
	HDR_rb             : out std_logic_vector(15 downto 0);
	HDR_gr             : out std_logic_vector(15 downto 0);
	HDR_gg             : out std_logic_vector(15 downto 0);
	HDR_gb             : out std_logic_vector(15 downto 0);
	HDR_br             : out std_logic_vector(15 downto 0);
	HDR_bg             : out std_logic_vector(15 downto 0);
	HDR_bb             : out std_logic_vector(15 downto 0);
	HDR_coef           : out std_logic_vector(5 downto 0);
	HLG_type           : out std_logic_vector(7 downto 0);
	secret_data        : out std_logic_vector(47 downto 0);
    virtual_pix_en     : out std_logic_vector(1 downto 0);
    virtual_direction  : out std_logic_vector(1 downto 0);

	eth_bright_value   : out std_logic_vector(FIBER_NUM*ETHPORT_NUM*8-1 downto 0);
	eth_color_R        : out std_logic_vector(FIBER_NUM*ETHPORT_NUM*8-1 downto 0);
	eth_color_G        : out std_logic_vector(FIBER_NUM*ETHPORT_NUM*8-1 downto 0);
	eth_color_B        : out std_logic_vector(FIBER_NUM*ETHPORT_NUM*8-1 downto 0);
	low_bright_en      : out std_logic;

	eth_forbid_en_convclk     : out std_logic_vector(FIBER_NUM*ETHPORT_NUM-1 downto 0);
	eth_mask_en_convclk		  : out std_logic_vector(FIBER_NUM*ETHPORT_NUM-1 downto 0);
	clr_serdesinfo_convclk    : out std_logic;

	colorspace_buf         : out std_logic_vector(2  downto 0);
	PN_frame_type_buf      : out std_logic_vector(19 downto 0);
	bright_weight_buf      : out std_logic_vector(89 downto 0);
	invert_dissolve_level_buf      : out std_logic_vector(10*4-1 downto 0);
	vsync_param_update_en  : in  std_logic_vector(FIBER_NUM-1 downto 0);
	function_enable        : out std_logic_vector(15 downto 0)
);

end global_ctrl;

architecture beha of global_ctrl is 

signal    eth80_bright_value   :   std_logic_vector(FIBER_NUM*ETHPORT_NUM*8-1 downto 0);
signal    eth80_color_R        :   std_logic_vector(FIBER_NUM*ETHPORT_NUM*8-1 downto 0);  
signal    eth80_color_G        :   std_logic_vector(FIBER_NUM*ETHPORT_NUM*8-1 downto 0);  
signal    eth80_color_B        :   std_logic_vector(FIBER_NUM*ETHPORT_NUM*8-1 downto 0);  
signal    low80_bright_en      :   std_logic;



SIGNAL backup_flag_buf  : STD_LOGIC_VECTOR(20-1 DOWNTO 0);
signal master_max		: std_logic_vector(7 downto 0);
signal master_set		: std_logic_vector(7 downto 0):= X"26";
signal slv_max			: std_logic_vector(7 downto 0):= X"26";
signal slv_set			: std_logic_vector(7 downto 0):= X"13";
signal master_cnt		: std_logic_vector(7 downto 0):= (others => '0');
signal slv_cnt			: std_logic_vector(7 downto 0):= (others => '0');
signal frame2a_en       : std_logic:='0';
signal frame36_en       : std_logic:='0';
signal frame5c_en       : std_logic:='0';
signal frame80_en       : std_logic:='0';
signal eth_light_adjust_en : std_logic:='0';
signal frame38_en       : std_logic:='0';
signal frame1b_en       : std_logic:='0';
signal frame44_arrive  : std_logic := '0';
signal frame4b_arrive  : std_logic := '0';
signal frame44_en      : std_logic := '0';  --real time bright
signal frame4b_en      : std_logic := '0';  --real time gamut 
signal net44_idx       : std_logic_vector(7 downto 0);
signal net44_port      : std_logic_vector(7 downto 0);
signal net4B_idx       : std_logic_vector(7 downto 0);
signal net4B_port      : std_logic_vector(7 downto 0);
signal hit4B_port      : std_logic;

signal    HDR4B_rr             :   std_logic_vector(15 downto 0);
signal    HDR4B_rg             :   std_logic_vector(15 downto 0);
signal    HDR4B_rb             :   std_logic_vector(15 downto 0);
signal    HDR4B_gr             :   std_logic_vector(15 downto 0);
signal    HDR4B_gg             :   std_logic_vector(15 downto 0);
signal    HDR4B_gb             :   std_logic_vector(15 downto 0);
signal    HDR4B_br             :   std_logic_vector(15 downto 0);
signal    HDR4B_bg             :   std_logic_vector(15 downto 0);
signal    HDR4B_bb             :   std_logic_vector(15 downto 0);
signal    HDR4B_coef           :   std_logic_vector(5 downto 0);
signal    HLG4B_type           :   std_logic_vector(7 downto 0);
signal    HDR4B_enable         :   std_logic;

signal    HDR5C_rr             :   std_logic_vector(15 downto 0);
signal    HDR5C_rg             :   std_logic_vector(15 downto 0);
signal    HDR5C_rb             :   std_logic_vector(15 downto 0);
signal    HDR5C_gr             :   std_logic_vector(15 downto 0);
signal    HDR5C_gg             :   std_logic_vector(15 downto 0);
signal    HDR5C_gb             :   std_logic_vector(15 downto 0);
signal    HDR5C_br             :   std_logic_vector(15 downto 0);
signal    HDR5C_bg             :   std_logic_vector(15 downto 0);
signal    HDR5C_bb             :   std_logic_vector(15 downto 0);
signal    HDR5C_coef           :   std_logic_vector(5 downto 0);
signal    HLG5C_type           :   std_logic_vector(7 downto 0);
signal    HDR5C_enable         :   std_logic;


    
SIGNAL R44_coef : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL G44_coef : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL B44_coef : STD_LOGIC_VECTOR(15 DOWNTO 0);

SIGNAL hit4B_first_card : STD_LOGIC := '0';
SIGNAL hit44_first_card : STD_LOGIC := '0';
signal hit4B_data       : std_logic :='0';
  
--vsync flag setting frame
signal frame01_en	 : std_logic := '0';
signal subframe01_en : std_logic := '0';
signal subframe07_en : std_logic := '0';
signal subframe08_en : std_logic := '0';
signal subframe09_en : std_logic := '0';
signal PN_frame_en   : std_logic := '0';
signal colorspace    : std_logic_vector(2  downto 0);
signal PN_frame_type : std_logic_vector(19 downto 0);
signal invert_dissolve_level : std_logic_vector(10*4-1 downto 0);
signal bright_weight : std_logic_vector(89 downto 0);
signal  cnt_4s       : std_logic_vector(12  downto 0);

signal frame57_en		: std_logic		:='0';
signal eth_mask_type	: std_logic		:='0';			-- 0: mask all eth		1:
signal eth_mask_en_buf	: std_logic_vector(FIBER_NUM*ETHPORT_NUM-1 downto 0)		:=(others => '0');			-- '1': mask output			'0': dont mask

signal eth_mask_en_convclk_buf		  : std_logic_vector(FIBER_NUM*ETHPORT_NUM-1 downto 0);

-- attribute altera_attribute : string;

-- attribute altera_attribute of eth_mask_type : signal is "-name ADV_NETLIST_OPT_ALLOWED NEVER_ALLOW; -name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS; -name DONT_MERGE_REGISTER ON; -name PRESERVE_REGISTER ON"  ;
-- attribute altera_attribute of eth_mask_en_buf : signal is "-name ADV_NETLIST_OPT_ALLOWED NEVER_ALLOW; -name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS; -name DONT_MERGE_REGISTER ON; -name PRESERVE_REGISTER ON"  ;


begin


process(convclk_i,nRST_conv) --pulse generator to trigger autouploading 
begin
    if nRST_conv = '0' then
        req_f9_upload <= '0';	
        cnt_4s        <= (others => '0');		
    elsif rising_edge(convclk_i) then
        if time_ms_en_conv = '1'  then
            -- if cnt_4s = 4000 then
            if cnt_4s(12) = '1' then
                cnt_4s <= (others => '0');
                req_f9_upload <= '1';	
            else
                cnt_4s <= cnt_4s + '1';
                req_f9_upload <= '0';
            end if;
        else
            req_f9_upload <= '0';
        end if;
    end if;
end process;


process(convclk_i,nRST_conv)
begin
    if nRST_conv = '0' then
        frame44_arrive <= '0';
        frame44_en     <= '0';
    elsif rising_edge(convclk_i) then 
        if p_Frame_en_conv = '1' then
            if p_Wren_conv = '1' and p_Addr_conv = 0 then
                if p_Data_conv = x"44" then
                    frame44_en <= '1';
                    frame44_arrive <= '1';
                else
                    frame44_en <= '0';
                end if;
            end if;
            
            if frame44_en = '1' and p_Wren_conv = '1' then
                if    p_Addr_conv = 1 then   
                       net44_port(7 downto 0) <= p_Data_conv;  --
                elsif p_Addr_conv = 2 then
                elsif p_Addr_conv = 3 then  
                       net44_idx(7 downto 0) <= p_Data_conv;
                elsif p_Addr_conv = 4 then  
                           if net44_port=0 and net44_idx = 0 then  
                                      hit44_first_card <= '1' ; 
                           else 
                                      hit44_first_card <= '0'; 
                           end if;
                end if;
                
                if hit44_first_card = '1' then  
                    case(conv_integer( p_Addr_conv )) is 
                        when 17 => R44_coef(7 downto 0)  <= p_Data_conv;
                        when 18 => R44_coef(15 downto 8) <= p_Data_conv;
                        when 19 => G44_coef(7 downto 0)  <= p_Data_conv;
                        when 20 => G44_coef(15 downto 8) <= p_Data_conv;
                        when 21 => B44_coef(7 downto 0)  <= p_Data_conv;
                        when 22 => B44_coef(15 downto 8) <= p_Data_conv;
							   when others=> null;	
                    end case;
                end if;
            end if;
        end if;          
    end if;
end process;

process(convclk_i) --for compatibility
begin 
    if rising_edge(convclk_i) then 
        if frame44_arrive = '1' then 
            for i in 0 to FIBER_NUM*ETHPORT_NUM-1 loop 
				eth_bright_value  ( (i+1)*8-1 downto i*8) <= (others=>'1');
				if R44_coef(15 downto 12) /= 0 then    
					eth_color_R  ( (i+1)*8-1 downto i*8) <= (others=>'1'); 
				else 
					eth_color_R ( (i+1)*8-1 downto i*8) <=  R44_coef(11 downto 4);
				end if;
				if G44_coef(15 downto 12) /= 0 then               
					eth_color_G  ( (i+1)*8-1 downto i*8) <= (others=>'1'); 
				else 
					eth_color_G ( (i+1)*8-1 downto i*8) <= G44_coef(11 downto 4); 
				end if;
				if B44_coef(15 downto 12) /= 0 then 
					eth_color_B ( (i+1)*8-1 downto i*8) <= (others=>'1');  
				else 
					eth_color_B ( (i+1)*8-1 downto i*8) <= B44_coef(11 downto 4) ;  
				end if;
			end loop;
			low_bright_en   <= '1';
 
        else 
			eth_bright_value  <=  eth80_bright_value ;
			eth_color_R       <=  eth80_color_R      ; 
			eth_color_G       <=  eth80_color_G      ; 
			eth_color_B       <=  eth80_color_B      ; 
			low_bright_en     <=  low80_bright_en    ;
 
		end if;
    end if;
end process;

process(convclk_i,nRST_conv)
begin
    if nRST_conv = '0' then
         frame4b_arrive <= '0';
         frame4B_en     <= '0';
		 hit4B_port <= '0';
		 hit4B_data <= '0';
    elsif rising_edge(convclk_i) then 
         if p_Frame_en_conv = '1' then
            if p_Wren_conv = '1' and p_Addr_conv = 0 then
                if p_Data_conv = x"4B" then   --real time gamut 
                    frame4B_en <= '1';
                    frame4B_arrive <= '1';
                else
                    frame4B_en <= '0';
                end if;
            end if;
            
            if frame4B_en = '1' and p_Wren_conv = '1' then
                    if    p_Addr_conv = 1 then 
						net4B_port(7 downto 0) <= p_Data_conv;  --
						if p_Data_conv = 0 or p_Data_conv = X"FF" then
							hit4B_port <= '1';
						else
							hit4B_port <= '0';
						end if;
                    elsif p_Addr_conv = 3 then net4B_idx (7 downto 0) <= p_Data_conv; ---subn
                    elsif p_Addr_conv = 4 then 
                            -- if (net4B_port = 0 OR net4B_port = X"FF") and  net4B_idx = 0 then 
							if hit4B_port = '1' and  net4B_idx = 0 then 
                                hit4B_first_card <= '1';
                            else 
                                hit4B_first_card <= '0';
                            end if;
					elsif p_Addr_conv = 7 then 
						if p_Data_conv = X"02" then
							hit4B_data <= '1';
						else
							hit4B_data <= '0';
						end if;
                    end if;
                    if hit4B_first_card = '1' and hit4B_data = '1'  THEN        
                             case(conv_integer(p_Addr_conv)) is 
                                    --first card 

								   when (17+0 )=>  HDR4B_enable<= p_Data_conv(0);HLG4B_type<= "000"&p_Data_conv(5 DOWNTO 1);
                                   when (17+1 )=>  HDR4B_rr(15 downto 8)<= p_Data_conv;
                                   when (17+2 )=>  HDR4B_rr(7 downto 0) <= p_Data_conv;
                                   when (17+3 )=>  HDR4B_gg(15 downto 8)<= p_Data_conv;
                                   when (17+4 )=>  HDR4B_gg(7 downto 0) <= p_Data_conv;
                                   when (17+5) => HDR4B_bb(15 downto 8)<= p_Data_conv;
                                   when (17+6) => HDR4B_bb(7 downto 0) <= p_Data_conv;                
                                   when (17+7) => HDR4B_rg(15 downto 8)<= p_Data_conv;
                                   when (17+8) => HDR4B_rg(7 downto 0) <= p_Data_conv;    
                                   when (17+9) => HDR4B_rb(15 downto 8)<= p_Data_conv;
                                   when (17+10) => HDR4B_rb(7 downto 0) <= p_Data_conv;
                                   when (17+11) => HDR4B_gr(15 downto 8)<= p_Data_conv;
                                   when (17+12) => HDR4B_gr(7 downto 0) <= p_Data_conv;    
                                   when (17+13) => HDR4B_gb(15 downto 8)<= p_Data_conv;
                                   when (17+14) => HDR4B_gb(7 downto 0) <= p_Data_conv;    
                                   when (17+15) => HDR4B_br(15 downto 8)<= p_Data_conv;
                                   when (17+16) => HDR4B_br(7 downto 0) <= p_Data_conv;    
                                   when (17+17) => HDR4B_bg(15 downto 8)<= p_Data_conv;
                                   when (17+18) => HDR4B_bg(7 downto 0) <= p_Data_conv;        
                                   when (17+19) => HDR4B_coef           <= p_Data_conv(5 downto 0);    

                                   WHEN OTHERS => NULL;
                            
                          END CASE;                
                  end if;
           end if;
      end if;
                     
    end if;
end process;
process(convclk_i,nRST_conv)
begin
    if nRST_conv = '0' then   
    
    elsif rising_edge(convclk_i) then 
       if frame4b_arrive = '1' then 
            HDR_rr              <= HDR4B_rr     ;
            HDR_rg              <= HDR4B_rg     ;
            HDR_rb              <= HDR4B_rb     ;
            HDR_gr              <= HDR4B_gr     ;
            HDR_gg              <= HDR4B_gg     ;
            HDR_gb              <= HDR4B_gb     ;
            HDR_br              <= HDR4B_br     ;
            HDR_bg              <= HDR4B_bg     ;
            HDR_bb              <= HDR4B_bb     ;
			HDR_coef            <= HDR4B_coef   ;  
            HDR_enable          <= HDR4B_enable	;
			HLG_type            <= HLG4B_type ;
      ELSE 
            HDR_rr              <= HDR5C_rr     ;
            HDR_rg              <= HDR5C_rg     ;
            HDR_rb              <= HDR5C_rb     ;
            HDR_gr              <= HDR5C_gr     ;
            HDR_gg              <= HDR5C_gg     ;
            HDR_gb              <= HDR5C_gb     ;
            HDR_br              <= HDR5C_br     ;
            HDR_bg              <= HDR5C_bg     ;
            HDR_bb              <= HDR5C_bb     ;
			HDR_coef            <= HDR5C_coef;  
            HDR_enable          <= HDR5C_enable	;	
			HLG_type            <= HLG5C_type ;			
      END IF;
    end if;
end process;
---------frame 36-----
process(convclk_i,nRST_conv)
begin
	if nRST_conv = '0' then
		master_max	<= x"3C";
		master_set	<= X"26";
		slv_max		<= X"26";
		slv_set		<= X"13";

	elsif rising_edge(convclk_i) then
		if p_Frame_en_conv = '1' then
			if p_Wren_conv = '1' and p_Addr_conv = 0 then
				if p_Data_conv = x"36" then
					frame36_en <= '1';
				else
					frame36_en <= '0';
				end if;
			end if;

			if frame36_en = '1' and p_Wren_conv = '1' then
				if p_Addr_conv = 4 then
					master_max <= p_Data_conv;
				elsif p_Addr_conv = 5 then
					master_set <= p_Data_conv;
				elsif p_Addr_conv = 6 then
				    slv_max <= p_Data_conv;
				elsif p_Addr_conv = 7 then
					slv_set <= p_Data_conv;

				elsif p_Addr_conv = 14 then
					backup_flag_buf(7 downto 0)  <= p_Data_conv;
				elsif p_Addr_conv = 15 then
					backup_flag_buf(15 downto 8) <= p_Data_conv;
				elsif p_Addr_conv = 16 then
					backup_flag_buf(20-1 downto 16) <= p_Data_conv(3 downto 0);

				end if;
			end if;
		end if;
	end if;
end process;

backup_flag <= backup_flag_buf;
process(convclk_i,nRST_conv)
begin
	if nRST_conv = '0' then
		clr_serdesinfo_convclk <= '0';

	elsif rising_edge(convclk_i) then
		if p_Frame_en_conv = '1' then
			if p_Wren_conv = '1' and p_Addr_conv = 0 then
				if p_Data_conv = x"3C" then
					clr_serdesinfo_convclk <= '1';---several cycles
				else
					clr_serdesinfo_convclk <= '0';
				end if;
			end if;
		else
			clr_serdesinfo_convclk <= '0';
		end if;

	end if;
end process;

process(convclk_i,nRST_conv)
begin
	if nRST_conv = '0' then
		master_cnt <= (others => '0');
		slv_cnt <= (others => '0');
		rcv_led_out <= (others => '0');
	elsif rising_edge(convclk_i) then
		if vsync_neg = '1' then
			if master_cnt < master_max - '1' then
				master_cnt <= master_cnt + '1';
			else
				master_cnt <= (others => '0');
			end if;

			if master_cnt = 0 then
				rcv_led_out(0) <= '1';
			elsif master_cnt = master_set then
				rcv_led_out(0) <= '0';
			end if;

			if slv_cnt < slv_max - '1' then
				slv_cnt <= slv_cnt + '1';
			else
				slv_cnt <= (others => '0');
			end if;

			if slv_cnt = 0 then
				rcv_led_out(1) <= '1';
			elsif slv_cnt = slv_set then
				rcv_led_out(1) <= '0';
			end if;
		end if;
	end if;
end process;

----------hdr param------------
process(nRST_conv,convclk_i)
begin
    if nRST_conv = '0' then
        HDR5c_enable <= '0';
        HDR_type <=(others=>'0');
        HDR5c_rr <=(others=>'0');
        HDR5c_rg <=(others=>'0');
        HDR5c_rb <=(others=>'0');
        HDR5c_gr <=(others=>'0');
        HDR5c_gg <=(others=>'0');
        HDR5c_gb <=(others=>'0');
        HDR5c_br <=(others=>'0');
        HDR5c_bg <=(others=>'0');
        HDR5c_bb <=(others=>'0');
        HDR5c_coef <=(others=>'0');
        HLG5C_type <=(others=>'0');
        
    elsif rising_edge(convclk_i)then
    
        if p_Frame_en_conv = '1' then
            if p_Wren_conv = '1' and p_Addr_conv = 0 then
                if p_Data_conv = X"5c" then
                    frame5c_en <= '1';
                else
                    frame5c_en <= '0';
                end if;
            end if;
            
            if frame5c_en = '1' and p_Wren_conv = '1' then
                case(conv_integer(p_Addr_conv)) is                  
                    when 4 => HDR5c_enable <= p_Data_conv(0);
                    when 5 => HDR_type   <= p_Data_conv;
                    when 6 => HDR5c_rr(15 downto 8)<= p_Data_conv;
                    when 7 => HDR5c_rr(7 downto 0) <= p_Data_conv;
                    when 8 => HDR5c_gg(15 downto 8)<= p_Data_conv;
                    when 9 => HDR5c_gg(7 downto 0) <= p_Data_conv;
                    when 10 => HDR5c_bb(15 downto 8)<= p_Data_conv;
                    when 11 => HDR5c_bb(7 downto 0) <= p_Data_conv;               
                    when 12 => HDR5c_rg(15 downto 8)<= p_Data_conv;
                    when 13 => HDR5c_rg(7 downto 0) <= p_Data_conv;   
                    when 14 => HDR5c_rb(15 downto 8)<= p_Data_conv;
                    when 15 => HDR5c_rb(7 downto 0) <= p_Data_conv;
                    when 16 => HDR5c_gr(15 downto 8)<= p_Data_conv;
                    when 17 => HDR5c_gr(7 downto 0) <= p_Data_conv;   
                    when 18 => HDR5c_gb(15 downto 8)<= p_Data_conv;
                    when 19 => HDR5c_gb(7 downto 0) <= p_Data_conv;   
                    when 20 => HDR5c_br(15 downto 8)<= p_Data_conv;
                    when 21 => HDR5c_br(7 downto 0) <= p_Data_conv;   
                    when 22 => HDR5c_bg(15 downto 8)<= p_Data_conv;
                    when 23 => HDR5c_bg(7 downto 0) <= p_Data_conv;       
                    when 24 => HDR5C_coef           <= p_Data_conv(5 downto 0);   
                    when 25 => HLG5C_type           <= p_Data_conv;   
                    when others => null;
                end case;
            end if;
        end if;
    end if;
end process;

--===============================secret_data=================================--

process(convclk_i,nRST_conv)
begin
	if nRST_conv = '0' then
		secret_data <= (others => '0');
	elsif rising_edge(convclk_i) then
		if p_Frame_en_conv = '1' then
			if p_Wren_conv = '1' and p_Addr_conv = 0 then
				if p_Data_conv = X"2A" then
					frame2a_en <= '1';
				else
					frame2a_en <= '0';
				end if;
			end if;

			if frame2a_en = '1' and p_Wren_conv = '1' then
				case (conv_integer(p_Addr_conv)) is
					when 1 => secret_data(8*0+7 downto 0*8) <= p_Data_conv(7 downto 0);----secret sign
					when 2 => secret_data(8*1+7 downto 1*8) <= p_Data_conv(7 downto 0);---timeout sign
					when 3 => secret_data(8*2+7 downto 2*8) <= p_Data_conv(7 downto 0);---UID LSB_FIRST
					when 4 => secret_data(8*3+7 downto 3*8) <= p_Data_conv(7 downto 0);
					when 5 => secret_data(8*4+7 downto 4*8) <= p_Data_conv(7 downto 0);
					when 6 => secret_data(8*5+7 downto 5*8) <= p_Data_conv(7 downto 0);
					when others => null;
				end case;
	        end if;
		end if;
	end if;
end process;

-------------------------bright---------------------

process(convclk_i,nRST_conv)
begin
	if nRST_conv = '0' then
        eth80_bright_value <= (others => '1');
        eth80_color_R      <= (others => '1');
        eth80_color_G      <= (others => '1');
        eth80_color_B      <= (others => '1');
        low80_bright_en    <= '0';
	elsif rising_edge(convclk_i) then
		if p_Frame_en_conv = '1' then
			if p_Wren_conv = '1' and p_Addr_conv = 0 then
				if p_Data_conv = X"80" then
					frame80_en <= '1';
				else
					frame80_en <= '0';
				end if;
			end if;

			if frame80_en = '1' then
				if p_Wren_conv = '1'and p_Addr_conv = 1 then
					if p_Data_conv = X"01" then---eth light adjust
						eth_light_adjust_en <= '1';
					else
						eth_light_adjust_en <= '0';
					end if;
				end if;
			else
				eth_light_adjust_en <= '0';
			end if;

			if eth_light_adjust_en = '1' and p_Wren_conv = '1' then
				case (conv_integer(p_Addr_conv)) is
                    when 6  => eth80_bright_value(1*8-1 downto 0*8) <= p_Data_conv;
                    when 7  => eth80_color_R(1*8-1 downto 0*8)      <= p_Data_conv;
                    when 8  => eth80_color_G(1*8-1 downto 0*8)      <= p_Data_conv;
                    when 9  => eth80_color_B(1*8-1 downto 0*8)      <= p_Data_conv;
                    when 10 => low80_bright_en                      <= p_Data_conv(0);
                    
                    when 14  => eth80_bright_value(2*8-1 downto 1*8) <= p_Data_conv;
                    when 15  => eth80_color_R(2*8-1 downto 1*8)      <= p_Data_conv;
                    when 16  => eth80_color_G(2*8-1 downto 1*8)      <= p_Data_conv;
                    when 17  => eth80_color_B(2*8-1 downto 1*8)      <= p_Data_conv;
                    
                    when 22  => eth80_bright_value(3*8-1 downto 2*8) <= p_Data_conv;
                    when 23  => eth80_color_R(3*8-1 downto 2*8)      <= p_Data_conv;
                    when 24  => eth80_color_G(3*8-1 downto 2*8)      <= p_Data_conv;
                    when 25  => eth80_color_B(3*8-1 downto 2*8)      <= p_Data_conv;                  
                    
                    
                    when 30  => eth80_bright_value(4*8-1 downto 3*8) <= p_Data_conv;
                    when 31  => eth80_color_R(4*8-1 downto 3*8)      <= p_Data_conv;
                    when 32  => eth80_color_G(4*8-1 downto 3*8)      <= p_Data_conv;
                    when 33  => eth80_color_B(4*8-1 downto 3*8)      <= p_Data_conv;


					when 38  => eth80_bright_value(5*8-1 downto 4*8) <= p_Data_conv;
					when 39  => eth80_color_R(5*8-1 downto 4*8)      <= p_Data_conv;
					when 40  => eth80_color_G(5*8-1 downto 4*8)      <= p_Data_conv;
					when 41  => eth80_color_B(5*8-1 downto 4*8)      <= p_Data_conv;

					when 46  => eth80_bright_value(6*8-1 downto 5*8) <= p_Data_conv;
					when 47  => eth80_color_R(6*8-1 downto 5*8)      <= p_Data_conv;
					when 48  => eth80_color_G(6*8-1 downto 5*8)      <= p_Data_conv;
					when 49  => eth80_color_B(6*8-1 downto 5*8)      <= p_Data_conv;


					when 54  => eth80_bright_value(7*8-1 downto 6*8) <= p_Data_conv;
					when 55  => eth80_color_R(7*8-1 downto 6*8)      <= p_Data_conv;
					when 56  => eth80_color_G(7*8-1 downto 6*8)      <= p_Data_conv;
					when 57  => eth80_color_B(7*8-1 downto 6*8)      <= p_Data_conv;

					when 62  => eth80_bright_value(8*8-1 downto 7*8) <= p_Data_conv;
					when 63  => eth80_color_R(8*8-1 downto 7*8)      <= p_Data_conv;
					when 64  => eth80_color_G(8*8-1 downto 7*8)      <= p_Data_conv;
					when 65  => eth80_color_B(8*8-1 downto 7*8)      <= p_Data_conv;

					when 70  => eth80_bright_value(9*8-1 downto 8*8) <= p_Data_conv;
					when 71  => eth80_color_R(9*8-1 downto 8*8)      <= p_Data_conv;
					when 72  => eth80_color_G(9*8-1 downto 8*8)      <= p_Data_conv;
					when 73  => eth80_color_B(9*8-1 downto 8*8)      <= p_Data_conv;


					when 78  => eth80_bright_value(10*8-1 downto 9*8) <= p_Data_conv;
					when 79  => eth80_color_R(10*8-1 downto 9*8)      <= p_Data_conv;
					when 80  => eth80_color_G(10*8-1 downto 9*8)      <= p_Data_conv;
					when 81  => eth80_color_B(10*8-1 downto 9*8)      <= p_Data_conv;

					when 86  => eth80_bright_value(11*8-1 downto 10*8) <= p_Data_conv;
					when 87  => eth80_color_R(11*8-1 downto 10*8)      <= p_Data_conv;
					when 88  => eth80_color_G(11*8-1 downto 10*8)      <= p_Data_conv;
					when 89  => eth80_color_B(11*8-1 downto 10*8)      <= p_Data_conv;

					when 94  => eth80_bright_value(12*8-1 downto 11*8) <= p_Data_conv;
					when 95  => eth80_color_R(12*8-1 downto 11*8)      <= p_Data_conv;
					when 96  => eth80_color_G(12*8-1 downto 11*8)      <= p_Data_conv;
					when 97  => eth80_color_B(12*8-1 downto 11*8)      <= p_Data_conv;

					when 102  => eth80_bright_value(13*8-1 downto 12*8) <= p_Data_conv;
					when 103  => eth80_color_R(13*8-1 downto 12*8)      <= p_Data_conv;
					when 104  => eth80_color_G(13*8-1 downto 12*8)      <= p_Data_conv;
					when 105  => eth80_color_B(13*8-1 downto 12*8)      <= p_Data_conv;

					when 110  => eth80_bright_value(14*8-1 downto 13*8) <= p_Data_conv;
					when 111  => eth80_color_R(14*8-1 downto 13*8)      <= p_Data_conv;
					when 112  => eth80_color_G(14*8-1 downto 13*8)      <= p_Data_conv;
					when 113  => eth80_color_B(14*8-1 downto 13*8)      <= p_Data_conv;

					when 118  => eth80_bright_value(15*8-1 downto 14*8) <= p_Data_conv;
					when 119  => eth80_color_R(15*8-1 downto 14*8)      <= p_Data_conv;
					when 120  => eth80_color_G(15*8-1 downto 14*8)      <= p_Data_conv;
					when 121  => eth80_color_B(15*8-1 downto 14*8)      <= p_Data_conv;

					when 126  => eth80_bright_value(16*8-1 downto 15*8) <= p_Data_conv;
					when 127  => eth80_color_R(16*8-1 downto 15*8)      <= p_Data_conv;
					when 128  => eth80_color_G(16*8-1 downto 15*8)      <= p_Data_conv;
					when 129  => eth80_color_B(16*8-1 downto 15*8)      <= p_Data_conv;

					when 134  => eth80_bright_value(17*8-1 downto 16*8) <= p_Data_conv;
					when 135  => eth80_color_R(17*8-1 downto 16*8)      <= p_Data_conv;
					when 136  => eth80_color_G(17*8-1 downto 16*8)      <= p_Data_conv;
					when 137  => eth80_color_B(17*8-1 downto 16*8)      <= p_Data_conv;

					when 142  => eth80_bright_value(18*8-1 downto 17*8) <= p_Data_conv;
					when 143  => eth80_color_R(18*8-1 downto 17*8)      <= p_Data_conv;
					when 144  => eth80_color_G(18*8-1 downto 17*8)      <= p_Data_conv;
					when 145  => eth80_color_B(18*8-1 downto 17*8)      <= p_Data_conv;

					when 150  => eth80_bright_value(19*8-1 downto 18*8) <= p_Data_conv;
					when 151  => eth80_color_R(19*8-1 downto 18*8)      <= p_Data_conv;
					when 152  => eth80_color_G(19*8-1 downto 18*8)      <= p_Data_conv;
					when 153  => eth80_color_B(19*8-1 downto 18*8)      <= p_Data_conv;

					when 158  => eth80_bright_value(20*8-1 downto 19*8) <= p_Data_conv;
					when 159  => eth80_color_R(20*8-1 downto 19*8)      <= p_Data_conv;
					when 160  => eth80_color_G(20*8-1 downto 19*8)      <= p_Data_conv;
					when 161  => eth80_color_B(20*8-1 downto 19*8)      <= p_Data_conv;

					when others => null;
				end case;
	        end if;
		end if;
	end if;
end process;

-----forbid eth output-----------

process(convclk_i,nRST_conv)
begin
	if nRST_conv = '0' then
		eth_forbid_en_convclk <= (others => '0');
	elsif rising_edge(convclk_i) then
		if p_Frame_en_conv = '1' then
			if p_Wren_conv = '1' and p_Addr_conv = 0 then
				if p_Data_conv = X"38" then
					frame38_en <= '1';
				else
					frame38_en <= '0';
				end if;
			end if;

			if frame38_en = '1' and p_Wren_conv = '1' then
				if p_Addr_conv = 5 then
					eth_forbid_en_convclk(7 downto 0) <= p_Data_conv(7 downto 0);
				elsif p_Addr_conv = 6 then
					eth_forbid_en_convclk(15 downto 8)<= p_Data_conv(7 downto 0);
				elsif p_Addr_conv = 7 then
					eth_forbid_en_convclk(19 downto 16)<= p_Data_conv(3 downto 0);
				end if;
	        end if;
		end if;
	end if;
end process;

-- eth_mask_en_convclk <= (others => '1') when eth_mask_type = '0' else eth_mask_en_buf;
process(convclk_i, nRST_conv)
begin
	if nRST_conv = '0' then
		frame57_en <= '0';
		eth_mask_type <= '0';
		eth_mask_en_buf <= (others => '0');
		eth_mask_en_convclk <= (others => '0');
	elsif rising_edge(convclk_i) then
		if p_Frame_en_conv <= '1' then
			if p_Wren_conv = '1' and p_Addr_conv = 0 then
				if p_Data_conv = X"57" then
					frame57_en <= '1';
				else
					frame57_en <= '0';
				end if;
			end if;
				
			if frame57_en = '1' and p_Wren_conv = '1' then
				if p_Addr_conv = 9 then
					eth_mask_type <= p_Data_conv(0);						-- 0: mask all eth	1:
				elsif p_Addr_conv = 10 then
					eth_mask_en_buf(7 downto 0) <= p_Data_conv;				-- '1': mask output		'0': dont mask
				elsif p_Addr_conv = 11 then
					eth_mask_en_buf(15 downto 8) <= p_Data_conv;
				elsif p_Addr_conv = 12 then
					eth_mask_en_buf(19 downto 16) <= p_Data_conv(3 downto 0);
				end if;
			end if;
			
			if frame57_en = '1' and p_Addr_conv = 13 then
				if eth_mask_type = '0' then
					for i in 0 to FIBER_NUM*ETHPORT_NUM-1 loop
						-- eth_mask_en_convclk(i) <= eth_mask_en_buf(0);
						eth_mask_en_convclk_buf(i) <= eth_mask_en_buf(0);
					end loop;
				else
					-- eth_mask_en_convclk <= eth_mask_en_buf(FIBER_NUM*ETHPORT_NUM-1 downto 0);
					eth_mask_en_convclk_buf <= eth_mask_en_buf(FIBER_NUM*ETHPORT_NUM-1 downto 0);
				end if;
			end if;

		end if;

		if vsync_neg = '1' then
			eth_mask_en_convclk <= eth_mask_en_convclk_buf;
		end if;

	end if;

end process;

----------virtual pixel param------------
process(nRST_conv,convclk_i)
begin
    if nRST_conv = '0' then
        frame1b_en        <= '0';
        virtual_pix_en    <=(others=>'0');
        virtual_direction <=(others=>'0');
    elsif rising_edge(convclk_i)then
        if p_Frame_en_conv = '1' then
            if p_Wren_conv = '1' and p_Addr_conv = 0 then
                if p_Data_conv = X"1B" then
                    frame1b_en <= '1';
                else
                    frame1b_en <= '0';
                end if;
            end if;

            if frame1b_en = '1' and p_Wren_conv = '1' then
                case(conv_integer(p_Addr_conv)) is
                    when 8 => virtual_pix_en <= p_Data_conv(1 downto 0);
                    when 9 => virtual_direction <= p_Data_conv(1 downto 0);
                    when others => null;
                end case;
            end if;
        end if;
    end if;
end process;

--------------   vsync flag setting-------------------

process(convclk_i,nRST_conv)
begin
	if nRST_conv = '0' then
		frame01_en <= '0';
		subframe01_en <= '0';
		subframe07_en <= '0';
		subframe08_en <= '0';
		PN_frame_en   <= '0';
		colorspace    <= (others => '0');
		PN_frame_type <= (others => '0');
		invert_dissolve_level <= (others => '0');
		bright_weight <= (others => '0');
		PN_frame_type_buf <= (others => '0');
		invert_dissolve_level_buf <= (others => '0');
		colorspace_buf    <= (others => '0');
		PN_frame_type_buf <= (others => '0');
		bright_weight_buf <= (others => '0');
		for i in 0 to 9 loop
			bright_weight((i+1)*9-1 downto i*9) <= '0'&X"19";
			bright_weight_buf((i+1)*9-1 downto i*9) <= '0'&X"19";
		end loop; 
		function_enable <= (others => '0');
	elsif rising_edge(convclk_i) then
		if vsync_param_update_en = "11" and frame01_en = '0' then
			colorspace_buf    <= colorspace   ;
			PN_frame_type_buf <= PN_frame_type;
			bright_weight_buf <= bright_weight;
			invert_dissolve_level_buf <= invert_dissolve_level;
		end if;
		if p_Frame_en_conv = '1' then
			if p_Wren_conv = '1' and p_Addr_conv = 0 then
				if p_Data_conv = X"01" then
					frame01_en <= '1';
				else
					frame01_en <= '0';
				end if;
			end if;

			if frame01_en = '1' then
				if p_Wren_conv = '1'and p_Addr_conv = 5 then
					subframe01_en <= '0';
					subframe07_en <= '0';
					subframe08_en <= '0';
					subframe09_en <= '0';
					if    p_Data_conv = X"01" then---set colorspace
						subframe01_en <= '1';
					elsif p_Data_conv = X"07" then---enable PN frame(Positive and Negative)
						subframe07_en <= '1';
					elsif p_Data_conv = X"08" then---set PN frame param
						subframe08_en <= '1';
					elsif p_Data_conv = X"09" then
						subframe09_en <= '1';
					end if;
				end if;
			else
				subframe01_en <= '0';
				subframe07_en <= '0';
				subframe08_en <= '0';
				subframe09_en <= '0';
			end if;

			if p_Wren_conv = '1' then
				if subframe01_en = '1' then
					if p_Addr_conv = 11 then
						colorspace <= p_Data_conv(2 downto 0);
					end if;
				elsif subframe07_en = '1' then
					if p_Addr_conv = 11 then
						PN_frame_en <= p_Data_conv(0);
						-- if p_Data_conv(0) = '0' then
						-- 	PN_frame_type <= (others => '0');
						-- 	bright_weight <= (others => '0');
						-- 	for i in 0 to 9 loop
						-- 		bright_weight((i+1)*9-1) <= '1';
						-- 	end loop;
						-- end if;
					end if;
				elsif subframe08_en = '1' then
				-- elsif subframe08_en = '1' and PN_frame_en = '1' then
					case(conv_integer(p_Addr_conv)) is
						--frame_remapping idx0
						when 16 => 	PN_frame_type(1*2-1 downto 0*2) <= p_Data_conv(1 downto 0);---00:normal, 01:Positive frame, 10:Negative frame
									invert_dissolve_level (1*4-1 downto 0*4) <= p_Data_conv(5 downto 2);
						when 17 => 	bright_weight(1*9-2 downto 0*9) <= p_Data_conv;---0 to 256, use 9bit for every idx, LSB
						when 18 => 	bright_weight(1*9-1) <= p_Data_conv(0);
						--frame_remapping idx1
						when 20 => 	PN_frame_type(2*2-1 downto 1*2) <= p_Data_conv(1 downto 0);
									invert_dissolve_level (2*4-1 downto 1*4) <= p_Data_conv(5 downto 2);
						when 21 => 	bright_weight(2*9-2 downto 1*9) <= p_Data_conv;
						when 22 => 	bright_weight(2*9-1) <= p_Data_conv(0);
						--frame_remapping idx2
						when 24 => 	PN_frame_type(3*2-1 downto 2*2) <= p_Data_conv(1 downto 0);
									invert_dissolve_level (3*4-1 downto 2*4) <= p_Data_conv(5 downto 2);
						when 25 => 	bright_weight(3*9-2 downto 2*9) <= p_Data_conv;
						when 26 => 	bright_weight(3*9-1) <= p_Data_conv(0);
						--frame_remapping idx3
						when 28 => 	PN_frame_type(4*2-1 downto 3*2) <= p_Data_conv(1 downto 0);
									invert_dissolve_level (4*4-1 downto 3*4) <= p_Data_conv(5 downto 2);
						when 29 => 	bright_weight(4*9-2 downto 3*9) <= p_Data_conv;
						when 30 =>	bright_weight(4*9-1) <= p_Data_conv(0);
						--frame_remapping idx4
						when 32 => 	PN_frame_type(5*2-1 downto 4*2) <= p_Data_conv(1 downto 0);
									invert_dissolve_level (5*4-1 downto 4*4) <= p_Data_conv(5 downto 2);
						when 33 => 	bright_weight(5*9-2 downto 4*9) <= p_Data_conv;
						when 34 => 	bright_weight(5*9-1) <= p_Data_conv(0);
						--frame_remapping idx5
						when 36 => 	PN_frame_type(6*2-1 downto 5*2) <= p_Data_conv(1 downto 0);
									invert_dissolve_level (6*4-1 downto 5*4) <= p_Data_conv(5 downto 2);
						when 37 => 	bright_weight(6*9-2 downto 5*9) <= p_Data_conv;
						when 38 => 	bright_weight(6*9-1) <= p_Data_conv(0);
						--frame_remapping idx6
						when 40 => 	PN_frame_type(7*2-1 downto 6*2) <= p_Data_conv(1 downto 0);
									invert_dissolve_level (7*4-1 downto 6*4) <= p_Data_conv(5 downto 2);
						when 41 => 	bright_weight(7*9-2 downto 6*9) <= p_Data_conv;
						when 42 => 	bright_weight(7*9-1) <= p_Data_conv(0);
						--frame_remapping idx7
						when 44 => 	PN_frame_type(8*2-1 downto 7*2) <= p_Data_conv(1 downto 0);
									invert_dissolve_level (8*4-1 downto 7*4) <= p_Data_conv(5 downto 2);
						when 45 => 	bright_weight(8*9-2 downto 7*9) <= p_Data_conv;
						when 46 => 	bright_weight(8*9-1) <= p_Data_conv(0);
						--frame_remapping idx8
						when 48 => 	PN_frame_type(9*2-1 downto 8*2) <= p_Data_conv(1 downto 0);
									invert_dissolve_level (9*4-1 downto 8*4) <= p_Data_conv(5 downto 2);
						when 49 => 	bright_weight(9*9-2 downto 8*9) <= p_Data_conv;
						when 50 => 	bright_weight(9*9-1) <= p_Data_conv(0);
						--frame_remapping idx9
						when 52 => 	PN_frame_type(10*2-1 downto 9*2) <= p_Data_conv(1 downto 0);
									invert_dissolve_level (10*4-1 downto 9*4) <= p_Data_conv(5 downto 2);
						when 53 => 	bright_weight(10*9-2 downto 9*9) <= p_Data_conv;
						when 54 => 	bright_weight(10*9-1) <= p_Data_conv(0);

						when others => null;
					end case;
				elsif subframe09_en = '1' then
					if p_Addr_conv = 11 then
						function_enable(7 downto 0) <= p_Data_conv;
					elsif p_Addr_conv = 12 then
						function_enable(15 downto 8) <= p_Data_conv;
					end if;
					
				end if;
	        end if;
		else
			frame01_en <= '0';
		end if;
	end if;
end process;
end beha;



