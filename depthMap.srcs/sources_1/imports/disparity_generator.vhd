----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Aruna Jayasena (aruna.15@cse.mrt.ac.lk)
-- 
-- Create Date: 08/12/2019 04:50:30 PM
-- Design Name: DepthMap 
-- Module Name: disparity_generator - Behavioral
-- Project Name: Obstacle aviodance using stereo vision
-- Target Devices: 
-- Tool Versions: 
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
         WIDTH:positive:=160;
         HEIGHT:positive:=120;
         maxoffset:positive:=40; --Maximum extent where to look for the same pixel
         minoffset:positive:=1;  ----minimum extent where to look for the same pixel
         fetchBlock:positive:=14); 
  Port (
    HCLK         : in  STD_LOGIC;
    HCLK450         : in  STD_LOGIC;
	left_in      : in  STD_LOGIC_vector(3 downto 0);
	right_in     : in  STD_LOGIC_vector(3 downto 0);	
	dOUT         : out  STD_LOGIC_vector(3 downto 0);
    dOUT_addr    : out  STD_LOGIC_vector(14 downto 0);
    left_right_addr: out  STD_LOGIC_vector(14 downto 0);
    ctrl_done    : inout  STD_LOGIC;
    offsetfound  : inout  STD_LOGIC
    		 );
end disparity_generator;

architecture Behavioral of disparity_generator is

signal ctrl_data_run : std_logic;		--control signal for data processing

type CacheArray is array(0 to WIDTH*HEIGHT-1) of std_logic_vector(3 downto 0);
signal org_L : CacheArray; --temporary storage for Left image
signal org_R : CacheArray; --temporary storage for Right image

signal row :std_logic_vector(8 downto 0); --row index of the image
signal col :std_logic_vector(8 downto 0); --column index of the Left image

signal offset,best_offset :std_logic_vector(5 downto 0);
signal offsetping,compare  : std_logic ;

signal ssd,prev_ssd :std_logic_vector(20 downto 0); --sum of squared difference

signal data_count,readreg :std_logic_vector(14 downto 0); --data counting for entire pixels of the image
signal doneFetch: std_logic;

signal cacheManager  :std_logic_vector(1 downto 0);

signal x  :std_logic_vector(3 downto 0):= (others => '0');
signal y  :std_logic_vector(3 downto 0):= (others => '0');
signal SSD_calc : std_logic;

begin
dOUT_addr<= data_count;
left_right_addr<=readreg;


--with cacheManager select 
--    left_right_addr <= readreg when "00",
--                readreg + std_logic_vector(to_unsigned(WIDTH*fetchBlock, readreg'length)) when "01",
--                readreg + std_logic_vector(to_unsigned(WIDTH*fetchBlock*2, readreg'length))   when "10",
--                readreg + std_logic_vector(to_unsigned(WIDTH*fetchBlock*3, readreg'length))   when "11";

--with cacheManager select 
--    dOUT_addr <= data_count when "00",
--                data_count + std_logic_vector(to_unsigned(WIDTH*fetchBlock, data_count'length)) when "01",
--                data_count + std_logic_vector(to_unsigned(WIDTH*fetchBlock*2, data_count'length))   when "10",
--                data_count + std_logic_vector(to_unsigned(WIDTH*fetchBlock*3, data_count'length))   when "11";




caching_process: process (HCLK) begin
    if rising_edge(HCLK) then
        if doneFetch='0' then
            if unsigned(readreg)<WIDTH*fetchBlock then -- replace fetchBlock with height if fetchBlock concept is removed
               org_L(to_integer(unsigned(readreg)))<= left_in;
               org_R(to_integer(unsigned(readreg)))<= right_in;
               readreg<=readreg+"1";
            else
               readreg <= (others => '0');  
            end if;
        end if;
    end if;
end process;


Image_process: process (HCLK450) begin
    if rising_edge(HCLK450) then
        if unsigned(readreg)=WIDTH*fetchBlock then -- replace fetchBlock with height if fetchBlock concept is removed
            doneFetch <='1';
        end if;
        if doneFetch='1' then
            if unsigned(data_count)<WIDTH*fetchBlock then -- replace fetchBlock with height if fetchBlock concept is removed
                   
                    if (offsetfound='1'and offsetping='0') then
                        if(col = WIDTH - 1) then
                            col <= (others => '0');  	
                            row <= row + 1;
                            
                        else  
                            col <= col + 1;
                            data_count<=data_count+"1";
                        end if;
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
                        --ssd<=(others => '0');  
                        offsetping<='1';
                        
                        
                    end if;
--                end if;
                
            else
                cacheManager<=cacheManager+"1"; --Comment this if remove fetchBlock concept
                offsetfound <= '0';
                data_count <= (others => '0');
                doneFetch <='0';
            end if;
        if (ssd < prev_ssd and SSD_calc='1') then
          prev_ssd <= ssd;
          best_offset <= offset;
        end if;
        if SSD_calc='1' then
            offsetping<='0';
        end if;    
        end if;

    end if;
end process;

SSD_calc_process: process (HCLK450) begin
    if rising_edge(HCLK450) then
        SSD_calc<='0';
        if (offsetping='1') then
--            if ((unsigned(x))<window) then --to_integer
--                if ((unsigned(y))<window) then --to_integer
--                    ssd <= ssd + std_logic_vector
--                         (to_unsigned(
--                         (to_integer(
--                         unsigned(org_L((to_integer(unsigned(row)) + to_integer(unsigned(x)) -2 ) * WIDTH + to_integer(unsigned(col)) +to_integer(unsigned(y)) -2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +to_integer(unsigned(x))  -2 ) * WIDTH + to_integer(unsigned(col))+to_integer(unsigned(y))  -2 - to_integer(unsigned(offset))))))
--                         *(to_integer(unsigned(org_L((to_integer(unsigned(row)) +to_integer(unsigned(x))  -2 ) * WIDTH + to_integer(unsigned(col)) +to_integer(unsigned(y)) -2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +to_integer(unsigned(x))  -2 ) * WIDTH + to_integer(unsigned(col)) +to_integer(unsigned(y)) -2 -to_integer(unsigned(offset))))))
--                         ,ssd'length));
--                    y<=y+"1";
--                else 
--                    y<=(others => '0');
--                end if;
--                if ((unsigned(y))=window) then
--						x<=x+"1";
--			    end if;
--           else
--               if ((unsigned(x))=window) then 
--                x<=(others => '0');
ssd <= ssd + std_logic_vector
			         (to_unsigned(
--			         (to_integer(unsigned(org_L((to_integer(unsigned(row))  -2 ) * WIDTH + to_integer(unsigned(col))  -2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))  -2 ) * WIDTH + to_integer(unsigned(col))  -2 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row))   -2 ) * WIDTH + to_integer(unsigned(col))  -2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))   -2 ) * WIDTH + to_integer(unsigned(col))  -2 -to_integer(unsigned(offset))))))
--                    +(to_integer(unsigned(org_L((to_integer(unsigned(row))  -2 ) * WIDTH + to_integer(unsigned(col))  -1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))  -2 ) * WIDTH + to_integer(unsigned(col))  -1 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row))   -2 ) * WIDTH + to_integer(unsigned(col))  -1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))   -2 ) * WIDTH + to_integer(unsigned(col))  -1 -to_integer(unsigned(offset))))))
--                    +(to_integer(unsigned(org_L((to_integer(unsigned(row))  -2 ) * WIDTH + to_integer(unsigned(col)) + 0   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))  -2 ) * WIDTH + to_integer(unsigned(col)) + 0 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row))   -2 ) * WIDTH + to_integer(unsigned(col)) + 0   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))   -2 ) * WIDTH + to_integer(unsigned(col)) + 0 -to_integer(unsigned(offset))))))
--                    +(to_integer(unsigned(org_L((to_integer(unsigned(row))  -2 ) * WIDTH + to_integer(unsigned(col)) + 1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))  -2 ) * WIDTH + to_integer(unsigned(col)) + 1 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row))   -2 ) * WIDTH + to_integer(unsigned(col)) + 1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))   -2 ) * WIDTH + to_integer(unsigned(col)) + 1 -to_integer(unsigned(offset))))))
--                    +(to_integer(unsigned(org_L((to_integer(unsigned(row))  -2 ) * WIDTH + to_integer(unsigned(col)) + 2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))  -2 ) * WIDTH + to_integer(unsigned(col)) + 2 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row))   -2 ) * WIDTH + to_integer(unsigned(col)) + 2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))   -2 ) * WIDTH + to_integer(unsigned(col)) + 2 -to_integer(unsigned(offset))))))
                    (to_integer(unsigned(org_L((to_integer(unsigned(row))  -1 ) * WIDTH + to_integer(unsigned(col))  -2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))  -1 ) * WIDTH + to_integer(unsigned(col))  -2 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row))   -1 ) * WIDTH + to_integer(unsigned(col))  -2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))   -1 ) * WIDTH + to_integer(unsigned(col))  -2 -to_integer(unsigned(offset))))))
                    +(to_integer(unsigned(org_L((to_integer(unsigned(row))  -1 ) * WIDTH + to_integer(unsigned(col))  -1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))  -1 ) * WIDTH + to_integer(unsigned(col))  -1 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row))   -1 ) * WIDTH + to_integer(unsigned(col))  -1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))   -1 ) * WIDTH + to_integer(unsigned(col))  -1 -to_integer(unsigned(offset))))))
                    +(to_integer(unsigned(org_L((to_integer(unsigned(row))  -1 ) * WIDTH + to_integer(unsigned(col)) + 0   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))  -1 ) * WIDTH + to_integer(unsigned(col)) + 0 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row))   -1 ) * WIDTH + to_integer(unsigned(col)) + 0   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))   -1 ) * WIDTH + to_integer(unsigned(col)) + 0 -to_integer(unsigned(offset))))))
--                    +(to_integer(unsigned(org_L((to_integer(unsigned(row))  -1 ) * WIDTH + to_integer(unsigned(col)) + 1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))  -1 ) * WIDTH + to_integer(unsigned(col)) + 1 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row))   -1 ) * WIDTH + to_integer(unsigned(col)) + 1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))   -1 ) * WIDTH + to_integer(unsigned(col)) + 1 -to_integer(unsigned(offset))))))
--                    +(to_integer(unsigned(org_L((to_integer(unsigned(row))  -1 ) * WIDTH + to_integer(unsigned(col)) + 2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))  -1 ) * WIDTH + to_integer(unsigned(col)) + 2 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row))   -1 ) * WIDTH + to_integer(unsigned(col)) + 2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))   -1 ) * WIDTH + to_integer(unsigned(col)) + 2 -to_integer(unsigned(offset))))))
--                    +(to_integer(unsigned(org_L((to_integer(unsigned(row)) + 0 ) * WIDTH + to_integer(unsigned(col))  -2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + 0 ) * WIDTH + to_integer(unsigned(col))  -2 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) +  0 ) * WIDTH + to_integer(unsigned(col))  -2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +  0 ) * WIDTH + to_integer(unsigned(col))  -2 -to_integer(unsigned(offset))))))
                    +(to_integer(unsigned(org_L((to_integer(unsigned(row)) + 0 ) * WIDTH + to_integer(unsigned(col))  -1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + 0 ) * WIDTH + to_integer(unsigned(col))  -1 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) +  0 ) * WIDTH + to_integer(unsigned(col))  -1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +  0 ) * WIDTH + to_integer(unsigned(col))  -1 -to_integer(unsigned(offset))))))
                    +(to_integer(unsigned(org_L((to_integer(unsigned(row)) + 0 ) * WIDTH + to_integer(unsigned(col)) + 0   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + 0 ) * WIDTH + to_integer(unsigned(col)) + 0 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) +  0 ) * WIDTH + to_integer(unsigned(col)) + 0   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +  0 ) * WIDTH + to_integer(unsigned(col)) + 0 -to_integer(unsigned(offset))))))
                    +(to_integer(unsigned(org_L((to_integer(unsigned(row)) + 0 ) * WIDTH + to_integer(unsigned(col)) + 1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + 0 ) * WIDTH + to_integer(unsigned(col)) + 1 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) +  0 ) * WIDTH + to_integer(unsigned(col)) + 1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +  0 ) * WIDTH + to_integer(unsigned(col)) + 1 -to_integer(unsigned(offset))))))
--                    +(to_integer(unsigned(org_L((to_integer(unsigned(row)) + 0 ) * WIDTH + to_integer(unsigned(col)) + 2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + 0 ) * WIDTH + to_integer(unsigned(col)) + 2 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) +  0 ) * WIDTH + to_integer(unsigned(col)) + 2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +  0 ) * WIDTH + to_integer(unsigned(col)) + 2 -to_integer(unsigned(offset))))))
--                    +(to_integer(unsigned(org_L((to_integer(unsigned(row)) + 1 ) * WIDTH + to_integer(unsigned(col))  -2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + 1 ) * WIDTH + to_integer(unsigned(col))  -2 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) +  1 ) * WIDTH + to_integer(unsigned(col))  -2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +  1 ) * WIDTH + to_integer(unsigned(col))  -2 -to_integer(unsigned(offset))))))
                    +(to_integer(unsigned(org_L((to_integer(unsigned(row)) + 1 ) * WIDTH + to_integer(unsigned(col))  -1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + 1 ) * WIDTH + to_integer(unsigned(col))  -1 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) +  1 ) * WIDTH + to_integer(unsigned(col))  -1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +  1 ) * WIDTH + to_integer(unsigned(col))  -1 -to_integer(unsigned(offset))))))
                    +(to_integer(unsigned(org_L((to_integer(unsigned(row)) + 1 ) * WIDTH + to_integer(unsigned(col)) + 0   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + 1 ) * WIDTH + to_integer(unsigned(col)) + 0 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) +  1 ) * WIDTH + to_integer(unsigned(col)) + 0   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +  1 ) * WIDTH + to_integer(unsigned(col)) + 0 -to_integer(unsigned(offset))))))
                    +(to_integer(unsigned(org_L((to_integer(unsigned(row)) + 1 ) * WIDTH + to_integer(unsigned(col)) + 1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + 1 ) * WIDTH + to_integer(unsigned(col)) + 1 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) +  1 ) * WIDTH + to_integer(unsigned(col)) + 1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +  1 ) * WIDTH + to_integer(unsigned(col)) + 1 -to_integer(unsigned(offset))))))
--                    +(to_integer(unsigned(org_L((to_integer(unsigned(row)) + 1 ) * WIDTH + to_integer(unsigned(col)) + 2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + 1 ) * WIDTH + to_integer(unsigned(col)) + 2 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) +  1 ) * WIDTH + to_integer(unsigned(col)) + 2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +  1 ) * WIDTH + to_integer(unsigned(col)) + 2 -to_integer(unsigned(offset))))))
--                    +(to_integer(unsigned(org_L((to_integer(unsigned(row)) + 2 ) * WIDTH + to_integer(unsigned(col))  -2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + 2 ) * WIDTH + to_integer(unsigned(col))  -2 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) +  2 ) * WIDTH + to_integer(unsigned(col))  -2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +  2 ) * WIDTH + to_integer(unsigned(col))  -2 -to_integer(unsigned(offset))))))
--                    +(to_integer(unsigned(org_L((to_integer(unsigned(row)) + 2 ) * WIDTH + to_integer(unsigned(col))  -1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + 2 ) * WIDTH + to_integer(unsigned(col))  -1 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) +  2 ) * WIDTH + to_integer(unsigned(col))  -1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +  2 ) * WIDTH + to_integer(unsigned(col))  -1 -to_integer(unsigned(offset))))))
--                    +(to_integer(unsigned(org_L((to_integer(unsigned(row)) + 2 ) * WIDTH + to_integer(unsigned(col)) + 0   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + 2 ) * WIDTH + to_integer(unsigned(col)) + 0 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) +  2 ) * WIDTH + to_integer(unsigned(col)) + 0   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +  2 ) * WIDTH + to_integer(unsigned(col)) + 0 -to_integer(unsigned(offset))))))
--                    +(to_integer(unsigned(org_L((to_integer(unsigned(row)) + 2 ) * WIDTH + to_integer(unsigned(col)) + 1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + 2 ) * WIDTH + to_integer(unsigned(col)) + 1 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) +  2 ) * WIDTH + to_integer(unsigned(col)) + 1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +  2 ) * WIDTH + to_integer(unsigned(col)) + 1 -to_integer(unsigned(offset))))))
--                    +(to_integer(unsigned(org_L((to_integer(unsigned(row)) + 2 ) * WIDTH + to_integer(unsigned(col)) + 2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + 2 ) * WIDTH + to_integer(unsigned(col)) + 2 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) +  2 ) * WIDTH + to_integer(unsigned(col)) + 2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +  2 ) * WIDTH + to_integer(unsigned(col)) + 2 -to_integer(unsigned(offset))))))
			        ,ssd'length));
                SSD_calc<='1';
--               end if;
--           end if;
        else
            ssd<=(others => '0');
        end if;
    end if;
end process;


Image_write_process: process (offsetfound) begin
    if rising_edge(offsetfound) then
--        dOUT<=best_offset;--*(255/maxoffset);
        dOUT<=std_logic_vector(to_unsigned(to_integer(unsigned(best_offset))*15/(maxoffset-minoffset),dOUT'length));
--        dOUT<=std_logic_vector(unsigned(org_L(to_integer(unsigned(data_count))))+unsigned(org_R(to_integer(unsigned(data_count))))/2);
    end if;
end process;

end Behavioral;
