---------------------------------------------------------------------------------
-- Company: Computer science and Engineering Department
-- Engineer: Aruna Jayasena (aruna.15@cse.mrt.ac.lk)
-- 
-- Create Date: 08/12/2019 04:50:30 PM
-- Design Name: DepthMap 
-- Module Name: disparity_generator - Behavioral
-- Project Name: Obstacle aviodance using stereo vision
-- Target Devices: Basys 3
-- Tool Versions: Vivado 2019.1
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity disparity_generator is
generic (window:positive:=5;
         WIDTH:positive:=320;
         HEIGHT:positive:=240;
         maxoffset:positive:=60; --Maximum extent where to look for the same pixel
         minoffset:positive:=1;  ----minimum extent where to look for the same pixel
         fetchBlock:positive:=15); 
  Port (
    HCLK         : in  STD_LOGIC;
    CLK_MAIN         : in  STD_LOGIC;
	left_in      : in  STD_LOGIC_vector(3 downto 0);
	right_in     : in  STD_LOGIC_vector(3 downto 0);
	avg_out     : out  STD_LOGIC_vector(3 downto 0);	
	dOUT         : out  STD_LOGIC_vector(7 downto 0);
    dOUT_addr    : out  STD_LOGIC_vector(16 downto 0);
    left_right_addr: out  STD_LOGIC_vector(16 downto 0);
    avg_reg_en    : out  STD_LOGIC;
    wr_en  : out  STD_LOGIC
    		 );
end disparity_generator;

architecture Behavioral of disparity_generator is

type CacheArray is array(0 to WIDTH*fetchBlock+1) of std_logic_vector(3 downto 0);
signal org_L : CacheArray; --temporary storage for Left image
signal org_R : CacheArray; --temporary storage for Right image

signal row,row_fetch :std_logic_vector(8 downto 0); --row index of the image
signal col,col_fetch :std_logic_vector(8 downto 0); --column index of the Left image

signal offset,best_offset :std_logic_vector(7 downto 0);
signal offsetping,offsetfound  : std_logic ;

signal ssd,prev_ssd :std_logic_vector(20 downto 0); --sum of squared difference

signal data_count,readreg :std_logic_vector(16 downto 0); --data counting for entire pixels of the image
signal doneFetch: std_logic;

--signal cacheManager  :std_logic_vector(2 downto 0);
signal cacheManager  :std_logic_vector(3 downto 0);
signal SSD_calc : std_logic;

begin


with cacheManager select 
    left_right_addr <= readreg when "0000",
                readreg + std_logic_vector(to_unsigned(WIDTH*fetchBlock-WIDTH, readreg'length)) when "0001",
                readreg + std_logic_vector(to_unsigned(WIDTH*fetchBlock*2-WIDTH, readreg'length))   when "0010",
                readreg + std_logic_vector(to_unsigned(WIDTH*fetchBlock*3-WIDTH, readreg'length))   when "0011",
                readreg + std_logic_vector(to_unsigned(WIDTH*fetchBlock*4-WIDTH, readreg'length)) when "0100",
                readreg + std_logic_vector(to_unsigned(WIDTH*fetchBlock*5-WIDTH, readreg'length))   when "0101",
                readreg + std_logic_vector(to_unsigned(WIDTH*fetchBlock*6-WIDTH, readreg'length))   when "0110",
                readreg + std_logic_vector(to_unsigned(WIDTH*fetchBlock*7-WIDTH, readreg'length)) when "0111",
                readreg + std_logic_vector(to_unsigned(WIDTH*fetchBlock*8-WIDTH, readreg'length))   when "1000",
                readreg + std_logic_vector(to_unsigned(WIDTH*fetchBlock*9-WIDTH, readreg'length))   when "1001",
                readreg + std_logic_vector(to_unsigned(WIDTH*fetchBlock*10-WIDTH, readreg'length)) when "1010",
                readreg + std_logic_vector(to_unsigned(WIDTH*fetchBlock*11-WIDTH, readreg'length))   when "1011",
                readreg + std_logic_vector(to_unsigned(WIDTH*fetchBlock*12-WIDTH, readreg'length))   when "1100",
                readreg + std_logic_vector(to_unsigned(WIDTH*fetchBlock*13-WIDTH, readreg'length))   when "1101",
                readreg + std_logic_vector(to_unsigned(WIDTH*fetchBlock*14-WIDTH, readreg'length))   when "1110",
                readreg + std_logic_vector(to_unsigned(WIDTH*fetchBlock*15-WIDTH, readreg'length))   when "1111";

with cacheManager select 
    dOUT_addr <= std_logic_vector(to_unsigned((to_integer(unsigned(row))) * WIDTH + to_integer(unsigned(col))-to_integer(unsigned(best_offset)), dOUT_addr'length)) when "000",
                std_logic_vector(to_unsigned((to_integer(unsigned(row))) * WIDTH + to_integer(unsigned(col))-to_integer(unsigned(best_offset)), dOUT_addr'length)) + std_logic_vector(to_unsigned(WIDTH*fetchBlock, dOUT_addr'length))  when "0001",
                std_logic_vector(to_unsigned((to_integer(unsigned(row))) * WIDTH + to_integer(unsigned(col))-to_integer(unsigned(best_offset)), dOUT_addr'length)) + std_logic_vector(to_unsigned(WIDTH*fetchBlock*2, dOUT_addr'length))   when "0010",
                std_logic_vector(to_unsigned((to_integer(unsigned(row))) * WIDTH + to_integer(unsigned(col))-to_integer(unsigned(best_offset)), dOUT_addr'length)) + std_logic_vector(to_unsigned(WIDTH*fetchBlock*3, dOUT_addr'length))   when "0011",
                std_logic_vector(to_unsigned((to_integer(unsigned(row))) * WIDTH + to_integer(unsigned(col))-to_integer(unsigned(best_offset)), dOUT_addr'length)) + std_logic_vector(to_unsigned(WIDTH*fetchBlock*4, dOUT_addr'length)) when "0100",
                std_logic_vector(to_unsigned((to_integer(unsigned(row))) * WIDTH + to_integer(unsigned(col))-to_integer(unsigned(best_offset)), dOUT_addr'length)) + std_logic_vector(to_unsigned(WIDTH*fetchBlock*5, dOUT_addr'length))   when "0101",
                std_logic_vector(to_unsigned((to_integer(unsigned(row))) * WIDTH + to_integer(unsigned(col))-to_integer(unsigned(best_offset)), dOUT_addr'length)) + std_logic_vector(to_unsigned(WIDTH*fetchBlock*6, dOUT_addr'length))   when "0110",
                std_logic_vector(to_unsigned((to_integer(unsigned(row))) * WIDTH + to_integer(unsigned(col))-to_integer(unsigned(best_offset)), dOUT_addr'length)) + std_logic_vector(to_unsigned(WIDTH*fetchBlock*7, dOUT_addr'length)) when "0111",
                std_logic_vector(to_unsigned((to_integer(unsigned(row))) * WIDTH + to_integer(unsigned(col))-to_integer(unsigned(best_offset)), dOUT_addr'length)) + std_logic_vector(to_unsigned(WIDTH*fetchBlock*8, dOUT_addr'length))   when "1000",
                std_logic_vector(to_unsigned((to_integer(unsigned(row))) * WIDTH + to_integer(unsigned(col))-to_integer(unsigned(best_offset)), dOUT_addr'length)) + std_logic_vector(to_unsigned(WIDTH*fetchBlock*9, dOUT_addr'length))   when "1001",
                std_logic_vector(to_unsigned((to_integer(unsigned(row))) * WIDTH + to_integer(unsigned(col))-to_integer(unsigned(best_offset)), dOUT_addr'length)) + std_logic_vector(to_unsigned(WIDTH*fetchBlock*10, dOUT_addr'length)) when "1010",
                std_logic_vector(to_unsigned((to_integer(unsigned(row))) * WIDTH + to_integer(unsigned(col))-to_integer(unsigned(best_offset)), dOUT_addr'length)) + std_logic_vector(to_unsigned(WIDTH*fetchBlock*11, dOUT_addr'length))   when "1011",
                std_logic_vector(to_unsigned((to_integer(unsigned(row))) * WIDTH + to_integer(unsigned(col))-to_integer(unsigned(best_offset)), dOUT_addr'length)) + std_logic_vector(to_unsigned(WIDTH*fetchBlock*12, dOUT_addr'length))   when "1100",
                std_logic_vector(to_unsigned((to_integer(unsigned(row))) * WIDTH + to_integer(unsigned(col))-to_integer(unsigned(best_offset)), dOUT_addr'length)) + std_logic_vector(to_unsigned(WIDTH*fetchBlock*13, dOUT_addr'length))   when "1101",
                std_logic_vector(to_unsigned((to_integer(unsigned(row))) * WIDTH + to_integer(unsigned(col))-to_integer(unsigned(best_offset)), dOUT_addr'length)) + std_logic_vector(to_unsigned(WIDTH*fetchBlock*14, dOUT_addr'length))   when "1110",
                std_logic_vector(to_unsigned((to_integer(unsigned(row))) * WIDTH + to_integer(unsigned(col))-to_integer(unsigned(best_offset)), dOUT_addr'length)) + std_logic_vector(to_unsigned(WIDTH*fetchBlock*15, dOUT_addr'length))   when "1111";

--with cacheManager select 
--    left_right_addr <= readreg when "00",
--                readreg + std_logic_vector(to_unsigned(WIDTH*fetchBlock, readreg'length)) when "01",
--                readreg + std_logic_vector(to_unsigned(WIDTH*fetchBlock*2, readreg'length))   when "10",
--                readreg + std_logic_vector(to_unsigned(WIDTH*fetchBlock*3, readreg'length))   when "11";
                

--with cacheManager select 
--    dOUT_addr <= std_logic_vector(to_unsigned((to_integer(unsigned(row))) * WIDTH + to_integer(unsigned(col)), dOUT_addr'length)) when "00",
--                std_logic_vector(to_unsigned((to_integer(unsigned(row))) * WIDTH + to_integer(unsigned(col)), dOUT_addr'length)) + std_logic_vector(to_unsigned(WIDTH*fetchBlock, dOUT_addr'length)) when "01",
--                std_logic_vector(to_unsigned((to_integer(unsigned(row))) * WIDTH + to_integer(unsigned(col)), dOUT_addr'length)) + std_logic_vector(to_unsigned(WIDTH*fetchBlock*2, dOUT_addr'length))   when "10",
--                std_logic_vector(to_unsigned((to_integer(unsigned(row))) * WIDTH + to_integer(unsigned(col)), dOUT_addr'length)) + std_logic_vector(to_unsigned(WIDTH*fetchBlock*3, dOUT_addr'length))   when "11";
                
avg_reg_en <= not doneFetch;




caching_process: process (HCLK) begin
    if rising_edge(HCLK) then
        if doneFetch='0' then
            if unsigned(readreg)<WIDTH*fetchBlock+2*WIDTH then -- replace fetchBlock with height if fetchBlock concept is removed
               org_L(to_integer(unsigned(readreg)))<= left_in;
               org_R(to_integer(unsigned(readreg)))<= right_in-std_logic_vector(to_unsigned(2,4));
               avg_out<=std_logic_vector(unsigned(left_in)/2 + unsigned(right_in-std_logic_vector(to_unsigned(2,4)))/2);
               readreg<=readreg+"1";
            else
               readreg <= (others => '0');  
            end if;
        end if;
    end if;
end process;


Image_process: process (CLK_MAIN) begin
    if rising_edge(CLK_MAIN) then
        if unsigned(readreg)=WIDTH*fetchBlock then -- replace fetchBlock with height if fetchBlock concept is removed
            doneFetch <='1';
        end if;
        if doneFetch='1' then
            if unsigned(data_count)<WIDTH*fetchBlock+WIDTH then -- replace fetchBlock with height if fetchBlock concept is removed                  
                if (offsetfound='1') then
                    if(col = WIDTH - 1) then
                        col <= (others => '0');  	
                        row <= row + 1;                            
                    else  
                        col <= col + 1;                           
                    end if;
                    data_count<=data_count+"1";
                    offsetfound <= '0';
                    best_offset <= (others => '0');  
                    prev_ssd <= (others => '1');
                    offset <= std_logic_vector(to_unsigned(minoffset,offset'length));  
                else 
                    if(offset=maxoffset) then
                        offsetfound <= '1';
                    else
                        offset<=offset+1;
                    end if;
                    offsetping<='1';    
                end if;
                
                if (ssd < prev_ssd and SSD_calc='1') then
                  prev_ssd <= ssd;
                  best_offset <= offset;
                end if;
                if SSD_calc='1' then
                    offsetping<='0';
                end if;     
--                end if;         
            else
                cacheManager<=cacheManager+"1"; --Comment this if remove fetchBlock concept
                data_count <= std_logic_vector(to_unsigned(WIDTH,data_count'length));
                doneFetch <='0';
                row<=std_logic_vector(to_unsigned(1,row'length));
            end if;
           
        end if;

    end if;
end process;

SSD_calc_process: process (CLK_MAIN) begin
    if rising_edge(CLK_MAIN) then
        SSD_calc<='0';
        if (offsetping='1') then
            ssd <=  std_logic_vector(to_unsigned(
                        (to_integer(unsigned(org_L((to_integer(unsigned(row))  -1 ) * WIDTH + to_integer(unsigned(col))  -1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))  -1 ) * WIDTH + to_integer(unsigned(col))  -1 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row))   -1 ) * WIDTH + to_integer(unsigned(col))  -1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))   -1 ) * WIDTH + to_integer(unsigned(col))  -1 -to_integer(unsigned(offset))))))
                        +(to_integer(unsigned(org_L((to_integer(unsigned(row))  -1 ) * WIDTH + to_integer(unsigned(col)) + 0   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))  -1 ) * WIDTH + to_integer(unsigned(col)) + 0 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row))   -1 ) * WIDTH + to_integer(unsigned(col)) + 0   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))   -1 ) * WIDTH + to_integer(unsigned(col)) + 0 -to_integer(unsigned(offset))))))
                        +(to_integer(unsigned(org_L((to_integer(unsigned(row))  -1 ) * WIDTH + to_integer(unsigned(col)) + 1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))  -1 ) * WIDTH + to_integer(unsigned(col)) + 1 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row))   -1 ) * WIDTH + to_integer(unsigned(col)) + 1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))   -1 ) * WIDTH + to_integer(unsigned(col)) + 1 -to_integer(unsigned(offset))))))
                        +(to_integer(unsigned(org_L((to_integer(unsigned(row)) + 0 ) * WIDTH + to_integer(unsigned(col))  -1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + 0 ) * WIDTH + to_integer(unsigned(col))  -1 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) +  0 ) * WIDTH + to_integer(unsigned(col))  -1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +  0 ) * WIDTH + to_integer(unsigned(col))  -1 -to_integer(unsigned(offset))))))
                        +(to_integer(unsigned(org_L((to_integer(unsigned(row)) + 0 ) * WIDTH + to_integer(unsigned(col)) + 0   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + 0 ) * WIDTH + to_integer(unsigned(col)) + 0 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) +  0 ) * WIDTH + to_integer(unsigned(col)) + 0   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +  0 ) * WIDTH + to_integer(unsigned(col)) + 0 -to_integer(unsigned(offset))))))
                        +(to_integer(unsigned(org_L((to_integer(unsigned(row)) + 0 ) * WIDTH + to_integer(unsigned(col)) + 1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + 0 ) * WIDTH + to_integer(unsigned(col)) + 1 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) +  0 ) * WIDTH + to_integer(unsigned(col)) + 1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +  0 ) * WIDTH + to_integer(unsigned(col)) + 1 -to_integer(unsigned(offset))))))
                        +(to_integer(unsigned(org_L((to_integer(unsigned(row)) + 1 ) * WIDTH + to_integer(unsigned(col))  -1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + 1 ) * WIDTH + to_integer(unsigned(col))  -1 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) +  1 ) * WIDTH + to_integer(unsigned(col))  -1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +  1 ) * WIDTH + to_integer(unsigned(col))  -1 -to_integer(unsigned(offset))))))
                        +(to_integer(unsigned(org_L((to_integer(unsigned(row)) + 1 ) * WIDTH + to_integer(unsigned(col)) + 0   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + 1 ) * WIDTH + to_integer(unsigned(col)) + 0 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) +  1 ) * WIDTH + to_integer(unsigned(col)) + 0   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +  1 ) * WIDTH + to_integer(unsigned(col)) + 0 -to_integer(unsigned(offset))))))
--                      +(to_integer(unsigned(org_L((to_integer(unsigned(row)) + 1 ) * WIDTH + to_integer(unsigned(col)) + 1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + 1 ) * WIDTH + to_integer(unsigned(col)) + 1 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) +  1 ) * WIDTH + to_integer(unsigned(col)) + 1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +  1 ) * WIDTH + to_integer(unsigned(col)) + 1 -to_integer(unsigned(offset))))))
                        ,ssd'length));
           SSD_calc<='1';

        else
            ssd<=(others => '0');
        end if;
    end if;
end process;

Image_write_process: process (offsetfound,HCLK) begin
    if rising_edge(offsetfound) or rising_edge(HCLK) then
        if (offsetfound='1') then
            wr_en<='1';
--            dOUT<=std_logic_vector(to_unsigned(to_integer((unsigned(best_offset)-minoffset)*4),dOUT'length));
--            dOUT<=std_logic_vector(to_unsigned(to_integer(unsigned(best_offset)),dOUT'length));
--            if to_integer(unsigned(best_offset)) > 10 then
            dOUT<=(std_logic_vector(to_unsigned(to_integer((unsigned(best_offset))-minoffset)*(4),dOUT'length)));
--            else
--                dOUT<= "00000000";
--            end if;
--        dOUT<=std_logic_vector(unsigned(org_L((to_integer(unsigned(row))) * WIDTH + to_integer(unsigned(col))))+unsigned(org_R((to_integer(unsigned(row))  -1 ) * WIDTH + to_integer(unsigned(col))))/2);
        else
            wr_en<='0';
        end if;
    end if;
end process;

end Behavioral;