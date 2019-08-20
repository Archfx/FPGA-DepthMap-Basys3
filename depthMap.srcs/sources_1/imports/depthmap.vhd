----------------------------------------------------------------------------------
-- Engineer: Aruna Jayasena <aruna.15@cse.mrt.ac.lk>
-- 
-- Module Name: DepthMap - Behavioral 
-- Description: Top level module For the disparity implementation using dual OV7670 camara modules on Basys 3
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity DepthMap is
    Port ( clk100          : in  STD_LOGIC;
           btnl            : in  STD_LOGIC;
           btnc            : in  STD_LOGIC;
           btnr            : in  STD_LOGIC;
           config_finished_l : out STD_LOGIC;
           config_finished_r : out STD_LOGIC;
           
           vga_hsync : out  STD_LOGIC;
           vga_vsync : out  STD_LOGIC;
           vga_r     : out  STD_LOGIC_vector(3 downto 0);
           vga_g     : out  STD_LOGIC_vector(3 downto 0);
           vga_b     : out  STD_LOGIC_vector(3 downto 0);
           
           ov7670_pclk_l  : in  STD_LOGIC;
           ov7670_xclk_l  : out STD_LOGIC;
           ov7670_vsync_l : in  STD_LOGIC;
           ov7670_href_l  : in  STD_LOGIC;
           ov7670_data_l  : in  STD_LOGIC_vector(7 downto 0);
           ov7670_sioc_l  : out STD_LOGIC;
           ov7670_siod_l  : inout STD_LOGIC;
           ov7670_pwdn_l  : out STD_LOGIC;
           ov7670_reset_l : out STD_LOGIC;
           
           ov7670_pclk_r  : in  STD_LOGIC;
           ov7670_xclk_r  : out STD_LOGIC;
           ov7670_vsync_r : in  STD_LOGIC;
           ov7670_href_r  : in  STD_LOGIC;
           ov7670_data_r  : in  STD_LOGIC_vector(7 downto 0);
           ov7670_sioc_r  : out STD_LOGIC;
           ov7670_siod_r  : inout STD_LOGIC;
           ov7670_pwdn_r  : out STD_LOGIC;
           ov7670_reset_r : out STD_LOGIC
           );
end DepthMap;

architecture Behavioral of DepthMap is

	COMPONENT VGA
	PORT(
		CLK25 : IN std_logic;    
      rez_160x120 : IN std_logic;
      rez_320x240 : IN std_logic;
		Hsync : OUT std_logic;
		Vsync : OUT std_logic;
		Nblank : OUT std_logic;      
		clkout : OUT std_logic;
		activeArea : OUT std_logic;
		Nsync : OUT std_logic
		);
	END COMPONENT;

	COMPONENT ov7670_controller
	PORT(
		clk : IN std_logic;
		resend : IN std_logic;    
		siod : INOUT std_logic;      
		config_finished : OUT std_logic;
		sioc : OUT std_logic;
		reset : OUT std_logic;
		pwdn : OUT std_logic;
		xclk : OUT std_logic
		);
	END COMPONENT;
	

	COMPONENT debounce
	PORT(
		clk : IN std_logic;
		i : IN std_logic;          
		o : OUT std_logic
		);
	END COMPONENT;

	COMPONENT frame_buffer
  PORT (
      clka : IN STD_LOGIC;
      wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      addra : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
      dina : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      clkb : IN STD_LOGIC;
      enb : IN STD_LOGIC;
      addrb : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
      doutb : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
	END COMPONENT;

	COMPONENT ov7670_capture
	PORT(
      rez_160x120 : IN std_logic;
      rez_320x240 : IN std_logic;
		pclk : IN std_logic;
		vsync : IN std_logic;
		href : IN std_logic;
		d : IN std_logic_vector(7 downto 0);          
		addr : OUT std_logic_vector(14 downto 0);
		dout : OUT std_logic_vector(11 downto 0);
		we : OUT std_logic
		);
	END COMPONENT;

	COMPONENT RGB
	PORT(
		Din : IN std_logic_vector(3 downto 0);
--		Din_r : IN std_logic_vector(3 downto 0);
		Nblank : IN std_logic;          
		R : OUT std_logic_vector(7 downto 0);
		G : OUT std_logic_vector(7 downto 0);
		B : OUT std_logic_vector(7 downto 0)
		);
	END COMPONENT;

--	component clocking
--	port (
--    CLK_100         : in     std_logic;
--    -- Clock out ports
--    CLK_50          : out    std_logic;
--    CLK_25          : out    std_logic);
--	end component;
	
	
    component clk_wiz_0 
    port (
    clk_in1         : in std_logic;
    --reset           : in std_logic;
    --locked          : out std_logic;
    -- Clock out ports
    CLK50MHZ          : out    std_logic;
    CLK25MHZ          : out    std_logic;
    CLK450MHZ       : out    std_logic);
	end component;
	
	COMPONENT vga_pll
	PORT(
		inclk0 : IN std_logic;          
		c0 : OUT std_logic;
		c1 : OUT std_logic
		);
	END COMPONENT;

	COMPONENT Address_Generator
	PORT(
		CLK       : IN  std_logic;
      rez_160x120 : IN std_logic;
      rez_320x240 : IN std_logic;
		enable      : IN  std_logic;       
      vsync       : in  STD_LOGIC;
		address     : OUT std_logic_vector(14 downto 0)
		);
	END COMPONENT;
	
	COMPONENT disparity_generator
	PORT(
--		CLK25       : IN  std_logic;
--      rez_160x120 : IN std_logic;
--      rez_320x240 : IN std_logic;
--		enable      : IN  std_logic;       
--      vsync       : in  STD_LOGIC;
--		address     : OUT std_logic_vector(16 downto 0);
		HCLK450         : in  STD_LOGIC;
		HCLK         :    IN  std_logic;
--		HRESETn       : IN  std_logic;
		left_in       :   IN std_logic_vector(3 downto 0);
		right_in      :   IN std_logic_vector(3 downto 0);
		dOUT          :   OUT std_logic_vector(3 downto 0);
		left_right_addr     :   OUT std_logic_vector(14 downto 0);
--		right_addr    :   OUT std_logic_vector(16 downto 0);
		dOUT_addr     :   OUT std_logic_vector(14 downto 0);
		ctrl_done     :   INOUT  std_logic;
		wr_en   :     OUT std_logic_vector(0 downto 0)
		
		

		
		);
	END COMPONENT;


   signal clk450     : std_logic;
   signal clk_camera : std_logic;
   signal clk_vga    : std_logic;
   signal wren_l,wren_r       : std_logic_vector(0 downto 0);
   signal resend     : std_logic;
   signal nBlank     : std_logic;
   signal vSync      : std_logic;
   signal nSync      : std_logic;
   
   signal wraddress_l  : std_logic_vector(14 downto 0);
   signal wrdata_l     : std_logic_vector(11 downto 0);
   signal wraddress_r  : std_logic_vector(14 downto 0);
   signal wrdata_r     : std_logic_vector(11 downto 0);
   
   signal rdaddress_l  : std_logic_vector(14 downto 0);
   signal rddata_l     : std_logic_vector(3 downto 0);
   signal rdaddress_r  : std_logic_vector(14 downto 0);
   signal rddata_r     : std_logic_vector(3 downto 0);
   
   signal disparity_out : std_logic_vector(3 downto 0);
   signal rdaddress_disp : std_logic_vector(14 downto 0);
   signal rddisp           : std_logic_vector(3 downto 0);
   signal wr_address_disp : std_logic_vector(14 downto 0);
   signal wr_en : std_logic_vector(0 downto 0);
   signal left_right_addr : std_logic_vector(14 downto 0);
   signal red,green,blue : std_logic_vector(7 downto 0);
   signal activeArea : std_logic;
   
   signal rez_160x120 : std_logic;
   signal rez_320x240 : std_logic;
   signal size_select: std_logic_vector(1 downto 0);
   signal rd_addr_l,wr_addr_l,rd_addr_r,wr_addr_r  : std_logic_vector(14 downto 0);
begin
   vga_r <= red(7 downto 4);
   vga_g <= green(7 downto 4);
   vga_b <= blue(7 downto 4);
   
   rez_160x120 <= '1';
   rez_320x240 <= '0';--btnr;
-- Inst_ClockDev : clocking
--     port map
--      (-- Clock in ports
--       CLK_100 => CLK100,
--       -- Clock out ports
--       CLK_50 => CLK_camera,
--       CLK_25 => CLK_vga);
 
 Inst_ClockDev : clk_wiz_0
     port map
      (-- Clock in ports
       clk_in1 => CLK100,
       --reset => '0',
       --locked => '1',
       -- Clock out ports
       CLK450MHZ =>CLK450,
       CLK50MHZ => CLK_camera,
       CLK25MHZ => CLK_vga);      
       

   vga_vsync <= vsync;
   
	Inst_VGA: VGA PORT MAP(
		CLK25      => clk_vga,
      rez_160x120 => rez_160x120,
      rez_320x240 => rez_320x240,
		clkout     => open,
		Hsync      => vga_hsync,
		Vsync      => vsync,
		Nblank     => nBlank,
		Nsync      => nsync,
      activeArea => activeArea
	);

	Inst_debounce: debounce PORT MAP(
		clk => clk_vga,
		i   => btnc,
		o   => resend
	);

	Inst_ov7670_controller_left: ov7670_controller PORT MAP(
		clk             => clk_camera,
		resend          => resend,
		config_finished => config_finished_l,
		sioc            => ov7670_sioc_l,
		siod            => ov7670_siod_l,
		reset           => ov7670_reset_l,
		pwdn            => ov7670_pwdn_l,
		xclk            => ov7670_xclk_l
	);
	
	Inst_ov7670_controller_right: ov7670_controller PORT MAP(
		clk             => clk_camera,
		resend          => resend,
		config_finished => config_finished_r,
		sioc            => ov7670_sioc_r,
		siod            => ov7670_siod_r,
		reset           => ov7670_reset_r,
		pwdn            => ov7670_pwdn_r,
		xclk            => ov7670_xclk_r
	);
	--size_select <= btnl&btnr;
	
    --with size_select select 
    rd_addr_l <= --rdaddress_l(18 downto 2) when "00",
        rdaddress_l(14 downto 0);-- when "01",
--        rdaddress_l(16 downto 0) when "10",
--        rdaddress_l(16 downto 0) when "11";
--    with size_select select
    rd_addr_r <= --rdaddress_r(18 downto 2) when "00",
        rdaddress_r(14 downto 0);-- when "01",
--        rdaddress_r(16 downto 0) when "10",
--        rdaddress_r(16 downto 0) when "11";
  -- with size_select select 
    wr_addr_r <= --wraddress_r(18 downto 2) when "00",
            wraddress_r(14 downto 0);-- when "01",
--            wraddress_r(16 downto 0) when "10",
--            wraddress_r(16 downto 0) when "11";
   --with size_select select 
    wr_addr_l <= --wraddress_l(18 downto 2) when "00",
            wraddress_l(14 downto 0);-- when "01",
--            wraddress_l(16 downto 0) when "10",
--            wraddress_l(16 downto 0) when "11";
            
	Inst_frame_buffer_l: frame_buffer PORT MAP(
		addrb => left_right_addr,
		clkb   => clk_camera,--CLK100,
		doutb  => rddata_l,
		enb    =>'1',
		clka   => ov7670_pclk_l,
		addra => wr_addr_l,
		dina      => wrdata_l(7 downto 4),
		wea      => wren_l
	);
	
	Inst_frame_buffer_r: frame_buffer PORT MAP(
		addrb => left_right_addr,
		clkb   => clk_camera, --CLK100,
		doutb        => rddata_r,
		enb    =>'1',
		clka   => ov7670_pclk_r,
		addra => wr_addr_r,
		dina      => wrdata_r(7 downto 4),
		wea      => wren_r
	);
	
	Inst_disparity_buffer: frame_buffer PORT MAP(
		addrb => rdaddress_disp,
		clkb   => clk_vga,
		doutb  => rddisp,
		enb    =>'1',
		clka   => CLK450,--CLK_camera, --CLK100,
		addra => wr_address_disp,
		dina      => disparity_out,
		wea      => wr_en
	);
	
	Inst_ov7670_capture_l: ov7670_capture PORT MAP(
		pclk  => ov7670_pclk_l,
      rez_160x120 => rez_160x120,
      rez_320x240 => rez_320x240,
		vsync => ov7670_vsync_l,
		href  => ov7670_href_l,
		d     => ov7670_data_l,
		addr  => wraddress_l,
		dout  => wrdata_l,
		we    => wren_l(0)
	);
	
	Inst_ov7670_capture_r: ov7670_capture PORT MAP(
		pclk  => ov7670_pclk_r,
      rez_160x120 => rez_160x120,
      rez_320x240 => rez_320x240,
		vsync => ov7670_vsync_r,
		href  => ov7670_href_r,
		d     => ov7670_data_r,
		addr  => wraddress_r,
		dout  => wrdata_r,
		we    => wren_r(0)
	); 

	Inst_RGB: RGB PORT MAP(
--		Din_l => rddata_l,
		Din => rddisp,
		Nblank => activeArea,
		R => red,
		G => green,
		B => blue
	);

	Inst_Address_Generator: Address_Generator PORT MAP(
		CLK => clk_vga,
      rez_160x120 => rez_160x120,
      rez_320x240 => rez_320x240,
		enable => activeArea,
      vsync  => vsync,
		address => rdaddress_disp
	);
--Inst_Address_Generator_r: Address_Generator PORT MAP(
--		CLK => clk_vga,
----      rez_160x120 => rez_160x120,
----      rez_320x240 => rez_320x240,
--		enable => activeArea,
--      vsync  => vsync,
--		address => rdaddress_r
--	);
	
--	Inst_Address_Generator_disp: Address_Generator PORT MAP(
--		CLK => clk_vga,
----      rez_160x120 => rez_160x120,
----      rez_320x240 => rez_320x240,
--		enable => activeArea,
--        vsync  => '0',
--		address => rdaddress_disp
--	);
	
	Inst_disparity_generator: disparity_generator PORT MAP(
		HCLK=> clk_camera,--CLK100,
		HCLK450=>CLK450,
--		HRESETn       : IN  std_logic;
		left_in      => rddata_l,
		right_in     => rddata_r,
		dOUT         => disparity_out,
		dOUT_addr => wr_address_disp,
		wr_en => wr_en,
		left_right_addr    =>left_right_addr
		--right_addr   =>,
--		dOUT_1        :   OUT std_logic_vector(7 downto 0);
		--ctrl_done    =>
	);
end Behavioral;

