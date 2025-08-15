
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity  write_cmd_gen is
generic (
    SIM                 : std_logic := '0';
    USE_DIV             : std_logic := '1';
    H_W                 : integer   := 16;
    W_W                 : integer   := 16;
    STRIDE_W            : integer   := 14;
    BURST_W             : integer   := 7;
    D_W                 : integer   := 320;
    A_W                 : integer   := 23;  --unit is 320bit
    C_W                 : integer   := 43;
	DDR3_INDEX          : integer;
	DDR_NUM             : integer;
	BLACK_OR_TESTMODE   : integer
);
port
(
    sys_nRST            : in  std_logic;
    sysclk              : in  std_logic;

    startx              : in  std_logic_vector(W_W-1 downto 0);
    starty              : in  std_logic_vector(H_W-1 downto 0);
    pic_width           : in  std_logic_vector(W_W-1 downto 0);
	pic_height          : in  std_logic_vector(H_W-1 downto 0);
	
    wr_baseaddr320      : in  std_logic;
	wr_baseaddr_ddrcmd  : in  std_logic_vector(A_W-1 downto 0);
    wr_discard          : in  std_logic; -- '1' : discard  , '0': no discard
    total_depthrow320   : in  std_logic_vector(STRIDE_W -1 downto 0);
    vsync_neg_sys       : in  std_logic;
	color_depth_ddrcmd  : in std_logic_vector(1 downto 0);

    wrfifo_usedw        : in  std_logic_vector(10 downto 0);
    wrfifo_rden         : out std_logic;
    wrfifo_rdata        : in  std_logic_vector(D_W-1 downto 0);

	startx_ddr3_320num  : in std_logic_vector(5 downto 0);
	startx_ddr3_index   : in std_logic_vector(1 downto 0);
	oneline_320num_curddr3 : in std_logic_vector(12-1 downto 0);
	startx_addr            : in std_logic_vector(21 downto 0);
	
	testmode_en         : in  std_logic;
	black_background_req: in  std_logic;
	black_background_ack: out  std_logic;
	-- black_background_end: out std_logic;	
		
    wr_req              : out std_logic;
    wr_ack              : in  std_logic;
    wr_cmd              : out std_logic_vector(C_W-1 downto 0);
    wr_abort            : out std_logic;
    wr_data             : out std_logic_vector(D_W-1 downto 0);
    wr_wren             : out std_logic;
	wr_point            : out std_logic_vector(1 downto 0)
);
end write_cmd_gen ;

architecture beha of write_cmd_gen is

signal wrfifo_rden_buf  : std_logic;
signal wrfifo_rden_d1   : std_logic;
signal wrfifo_rden_d2   : std_logic;
signal wrfifo_rdata_d1  : std_logic_vector(D_W-1 downto 0);

component div10 is
    port (
        numer    : in  std_logic_vector(15 downto 0) := (others => 'X'); -- numer
        denom    : in  std_logic_vector(3 downto 0)  := (others => 'X'); -- denom
        clock    : in  std_logic                     := 'X';             -- clock
        quotient : out std_logic_vector(15 downto 0);                    -- quotient
        remain   : out std_logic_vector(3 downto 0)                      -- remain
    );
end component div10;

type state_def is (ST_CHECKFIFO, ST_PUSHDATA,ST_IDLE,ST_PUSHAFTER,ST_WAITACK, ST_WAITVSYNC);
signal pstate           : state_def := ST_WAITVSYNC;
signal wait_cnt         : std_logic_vector(7 downto 0);

signal staddr_off_ddr   : std_logic_vector(H_W+STRIDE_W-1 downto 0);
signal burst_num        : std_logic_vector(BURST_W-1 downto 0);
signal burst_num_lock   : std_logic_vector(BURST_W-1 downto 0);
signal line_start_addr  : std_logic_vector(A_W-2 downto 0);
signal ddr3_cur_addr    : std_logic_vector(A_W-2 downto 0);

signal vsync_cnt        : std_logic_vector(4 downto 0);

signal wrfifo_is_enough : std_logic;
signal vsync_neg_sys_d1 : std_logic  := '0';
signal vsync_neg_sys_d2 : std_logic  := '0';


signal CUR_DDR3_INDEX : std_logic_vector(1 downto 0):= (others=>'0');
signal line_start_burst_num : std_logic_vector(BURST_W-1 downto 0);
signal start_addr           : std_logic_vector(A_W-2 downto 0):=(others=>'0');

CONSTANT   MAX_BURST_NUM  : std_logic_vector(BURST_W-1 downto 0) := "1000000";
signal 	oneline_320num :  std_logic_vector(12-1 downto 0);
signal  line_end       :  std_logic:='0';
signal  no_start_x_inone64     :  std_logic:='0';
signal black_background_end_buf : std_logic:='0';
signal black_background_ack_buf : std_logic;
signal black_background_en : std_logic :='0';
signal line_cnt         : std_logic_vector(H_W-1 downto 0);

begin

CUR_DDR3_INDEX       <= conv_std_logic_vector(DDR3_INDEX,2);
wrfifo_rden          <= wrfifo_rden_buf;
wr_data              <= wrfifo_rdata when black_background_en = '0' else (others=>'0');

process(sysclk,sys_nRST)
begin
	if sys_nRST = '0' then
		wr_abort <= '0';
	elsif rising_edge(sysclk) then
		vsync_neg_sys_d1 <= vsync_neg_sys;
		wr_abort         <= vsync_neg_sys_d1;
		wr_wren          <= wrfifo_rden_buf;

		
	end if;
end process;

no_start_x_inone64 <= '1' when startx_ddr3_320num = 0 or (CUR_DDR3_INDEX /= startx_ddr3_index) else '0';

process(sysclk,sys_nRST)
begin
    if sys_nRST = '0' then
        pstate <= ST_WAITVSYNC;
        wrfifo_rden_buf <= '0';
        wr_req <= '0';
		black_background_en      <= '0';	
    elsif rising_edge(sysclk) then
        if vsync_cnt(4) = '1' then
            pstate <= ST_IDLE;
            wait_cnt <= (others=> '0');
            wrfifo_rden_buf <= '0';
            wr_req <= '0';
            wrfifo_is_enough <= '0';
			black_background_ack_buf <= '0';
        else
            case pstate is
                when ST_WAITVSYNC =>
                    wrfifo_rden_buf <= '0';
                    wr_req <= '0';
                    wrfifo_is_enough <= '0';
					black_background_en      <= '0';	

                when ST_IDLE =>
                    wrfifo_rden_buf <= '0';
                    wr_req <= '0';
                    wrfifo_is_enough <= '0';

                    if wait_cnt(7) = '0' then
                        wait_cnt <= wait_cnt + '1';
                        pstate <= ST_IDLE;
                    elsif BLACK_OR_TESTMODE = 0 then
						if wr_discard = '1' or pic_width = 0 or oneline_320num_curddr3 = 0 then--or pic_height = 0 then
							pstate <= ST_WAITVSYNC;
						else
							pstate <= ST_CHECKFIFO;
						end if;
					else---BLACK_OR_TESTMODE = 1
						if testmode_en = '1' or black_background_req = '1' then
							pstate <= ST_CHECKFIFO;
							black_background_ack_buf <= black_background_req;
							black_background_en      <= black_background_req;							
						else
							pstate <= ST_IDLE;
						end if;
					end if;
					

					oneline_320num  <= oneline_320num_curddr3;
					ddr3_cur_addr   <= start_addr(A_W-2 downto 0);
					line_start_addr <= start_addr(A_W-2 downto 0);
					if no_start_x_inone64 = '1' then
						line_start_burst_num <= (others=>'0');
					else
						line_start_burst_num <= MAX_BURST_NUM-startx_ddr3_320num;	
					end if;
					line_cnt        <= pic_height;


                when ST_CHECKFIFO =>
                    wait_cnt <= (others=> '0');
					black_background_ack_buf <= '0';

                    wr_cmd                  <= (others=> '0');
                    -- wr_cmd(A_W-1)           <= wr_baseaddr320;
                    wr_cmd(A_W-1 downto 0)  <= wr_baseaddr_ddrcmd+('0'&ddr3_cur_addr);
                    wr_cmd(34 downto 28)    <= burst_num;
					-- wr_point                <= ddr3_cur_addr(7 downto 6);

                    if wrfifo_usedw >= burst_num and burst_num /= 0 then
                        wrfifo_is_enough <= '1';
                    else
                        wrfifo_is_enough <= '0';
                    end if;

					
					if BLACK_OR_TESTMODE = 0 then
						if wrfifo_is_enough = '1' then
							pstate <= ST_WAITACK;
							wr_req <= '1';	
						else
							wr_req <= '0';
							pstate <= ST_CHECKFIFO;
						end if;
					else
						if (wrfifo_is_enough = '1'and testmode_en = '1') or black_background_en = '1' then
							pstate <= ST_WAITACK;
							wr_req <= '1';
						else
							pstate <= ST_CHECKFIFO;
							wr_req <= '0';
						end if;
					end if;
					burst_num_lock <= burst_num;

                when ST_WAITACK =>
                    wrfifo_is_enough <= '0';
                    if wr_ack = '1' then
                        pstate <= ST_PUSHDATA;
                        wr_req <= '0';
                        wrfifo_rden_buf <= '1';
                    else
                        pstate <= ST_WAITACK;
                        wr_req <= '1';
                        wrfifo_rden_buf <= '0';
                    end if;

                when ST_PUSHDATA =>
                    if wait_cnt >= burst_num_lock - '1' then
                        wrfifo_rden_buf <= '0';
                    else
                        wrfifo_rden_buf <= '1';
                    end if;
                    if wrfifo_rden_buf = '1' then
                        wait_cnt <= wait_cnt + '1';
                        pstate   <= ST_PUSHDATA;
                    else
                        wait_cnt <= (others=> '0');
                        pstate   <= ST_PUSHAFTER;
                    end if;
					
					if wrfifo_rden_buf = '0' then
						if line_end = '1' then
							ddr3_cur_addr   <= line_start_addr+ total_depthrow320(STRIDE_W-1 downto 2);
							line_start_addr <= line_start_addr + total_depthrow320(STRIDE_W-1 downto 2);
							oneline_320num  <= oneline_320num_curddr3;
							if no_start_x_inone64 = '1' then
								line_start_burst_num <= (others=>'0');
							else
								line_start_burst_num <= MAX_BURST_NUM-startx_ddr3_320num;	
							end if;	
							line_cnt        <= line_cnt - '1';
						else
							ddr3_cur_addr   <= ddr3_cur_addr + burst_num_lock;
							oneline_320num  <= oneline_320num - burst_num_lock;
							line_start_burst_num <= (others=>'0');
						end if;
					end if;
						



                when ST_PUSHAFTER =>

					if BLACK_OR_TESTMODE = 0 then
						pstate <= ST_CHECKFIFO;
					else
						if line_cnt = 0 then
							black_background_en      <= '0';	
							pstate <= ST_WAITVSYNC;
						else
							pstate <= ST_CHECKFIFO;
						end if;
					end if;
							
					wait_cnt(1 downto 0) <= (others=> '0');


                when others => pstate <= ST_WAITVSYNC;
            end case;
        end if;
    end if;
end process;

process(sysclk,sys_nRST)
begin
    if sys_nRST = '0' then
        vsync_cnt <= (others=> '1');
		line_end  <= '0';
		burst_num <= conv_std_logic_vector(64,BURST_W);
    elsif rising_edge(sysclk) then
        if vsync_neg_sys = '1' then
            vsync_cnt <= (others=> '1');
        elsif vsync_cnt(4) = '1' then
            vsync_cnt <= vsync_cnt - '1';
        end if;


        staddr_off_ddr <= starty*total_depthrow320;
		start_addr     <= staddr_off_ddr(23 downto 2)+startx_addr;
		
		if vsync_cnt > 20 then
			line_end  <= '0';
			burst_num <= conv_std_logic_vector(64,BURST_W);
			
		else
			if  line_start_burst_num /= 0 then
				if oneline_320num > line_start_burst_num then							
					burst_num      <= line_start_burst_num;
					line_end       <= '0';					
				else
					burst_num      <= oneline_320num(BURST_W-1 downto 0);
					line_end       <= '1';					
				end if;
			elsif oneline_320num > 64 then						
				burst_num <= conv_std_logic_vector(64,BURST_W);
				line_end  <= '0';
			else
				burst_num <= oneline_320num(BURST_W-1 downto 0);
				line_end  <= '1';
			end if;			
		end if;
    end if;
end process;


--------------for testmode ------------
black_background_ack <= black_background_ack_buf;
-- black_background_end <= black_background_end_buf;





end  beha ;

