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
         WIDTH:positive:=320;
         HEIGHT:positive:=240;
         maxoffset:positive:=10); --Maximum extent where to look for the same pixel
  Port (
    HCLK         : in  STD_LOGIC;
	left_in      : in  STD_LOGIC_vector(3 downto 0);
	right_in     : in  STD_LOGIC_vector(3 downto 0);	
	dOUT         : out  STD_LOGIC_vector(3 downto 0);
    dOUT_addr    : out  STD_LOGIC_vector(16 downto 0);
    left_right_addr: out  STD_LOGIC_vector(16 downto 0);
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

signal offset,best_offset :std_logic_vector(3 downto 0);
signal offsetping,compare  : std_logic;

signal ssd,prev_ssd :std_logic_vector(20 downto 0); --sum of squared difference

signal data_count,readreg :std_logic_vector(16 downto 0); --data counting for entire pixels of the image
signal doneFetch: std_logic;

signal cacheManager  :std_logic_vector(1 downto 0);

begin
--dOUT_addr<= data_count;
--left_right_addr<=readreg;


with cacheManager select 
    left_right_addr <= readreg when "00",
                readreg + std_logic_vector(to_unsigned(WIDTH*60, readreg'length)) when "01",
                readreg + std_logic_vector(to_unsigned(WIDTH*60*2, readreg'length))   when "10",
                readreg + std_logic_vector(to_unsigned(WIDTH*60*3, readreg'length))   when "11";

with cacheManager select 
    dOUT_addr <= data_count when "00",
                data_count + std_logic_vector(to_unsigned(WIDTH*60, data_count'length)) when "01",
                data_count + std_logic_vector(to_unsigned(WIDTH*60*2, data_count'length))   when "10",
                data_count + std_logic_vector(to_unsigned(WIDTH*60*3, data_count'length))   when "11";

caching_process: process (HCLK) begin
    if rising_edge(HCLK) then
        if doneFetch='0' then
            if unsigned(readreg)<WIDTH*60 then
               org_L(to_integer(unsigned(readreg)))<= left_in;
               org_R(to_integer(unsigned(readreg)))<= right_in;
               readreg<=readreg+"1";
            else
               doneFetch <='1';
               readreg <= (others => '0');  
            end if;
        else
--            if unsigned(data_count)<WIDTH*60  then
--                offsetfound<='1';
--                best_offset<=std_logic_vector(unsigned(org_L(to_integer(unsigned(data_count))))+unsigned(org_R(to_integer(unsigned(data_count))))/2);
--                data_count<=data_count+"1";
----------------------------------------------------------------------------------------------------------------------------------------------------
                if ctrl_done = '1' then
                    data_count <= (others => '0');
                    row <= (others => '0');
                    col <= (others => '0');
                    offset <= std_logic_vector(to_unsigned(4, offset'length));
                    offsetping <= '0';
                    compare <= '0';
                    ctrl_done <= '0';
                else
                    if ( offsetping = '0' and compare = '0') then
                        if offsetfound = '1' then
--                            if col=WIDTH - 1 then
--                            end if;
                            if col=WIDTH - 1 then
                                col <=(others => '0');
                                row <= row + "1";
                            else 
                               col <= col + "1";
                            end if; 
                            
                            offsetfound <= '0';
                            best_offset <= (others => '0');
                            prev_ssd <= (others => '1');
                            
                        else
                            if offset=maxoffset then
                                offsetfound <= '1';
                            else
                                offset <= offset + "1";
                            end if;
                            
                            ssd<=(others => '0');
                            offsetping <= '1';
                       end if;
                   end if;  
			    end if;
			    
			    if data_count=WIDTH*60-1 then
			         ctrl_done<='1';
			         data_count <= (others => '0');
                     doneFetch <='0';
                     offsetfound<='0';
                     cacheManager<=cacheManager+"1";
			    else 
			        ctrl_done<='0';
			        if offsetfound= '1' then
			             data_count <= data_count + "1";
			        end if;
			    end if;
			    
			    
			   if offsetfound= '1' then
			         offset <= std_logic_vector(to_unsigned(4, offset'length));
--			         best_offset<=std_logic_vector(unsigned(org_L(to_integer(unsigned(data_count))))+unsigned(org_R(to_integer(unsigned(data_count))))/2);
			         dOUT <= best_offset;
--			         best_offset<=std_logic_vector(unsigned(org_L(to_integer(unsigned(data_count))))+unsigned(org_R(to_integer(unsigned(data_count))))/2);
			   end if;
			   
			   if offsetping='1' then
			         ssd <= ssd + std_logic_vector
			         (to_unsigned(
			         (to_integer(unsigned(org_L((to_integer(unsigned(row))  -2 ) * WIDTH + to_integer(unsigned(col))  -2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))  -2 ) * WIDTH + to_integer(unsigned(col))  -2 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row))   -2 ) * WIDTH + to_integer(unsigned(col))  -2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))   -2 ) * WIDTH + to_integer(unsigned(col))  -2 -to_integer(unsigned(offset))))))
                    +(to_integer(unsigned(org_L((to_integer(unsigned(row))  -2 ) * WIDTH + to_integer(unsigned(col))  -1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))  -2 ) * WIDTH + to_integer(unsigned(col))  -1 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row))   -2 ) * WIDTH + to_integer(unsigned(col))  -1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))   -2 ) * WIDTH + to_integer(unsigned(col))  -1 -to_integer(unsigned(offset))))))
                    +(to_integer(unsigned(org_L((to_integer(unsigned(row))  -2 ) * WIDTH + to_integer(unsigned(col)) + 0   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))  -2 ) * WIDTH + to_integer(unsigned(col)) + 0 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row))   -2 ) * WIDTH + to_integer(unsigned(col)) + 0   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))   -2 ) * WIDTH + to_integer(unsigned(col)) + 0 -to_integer(unsigned(offset))))))
                    +(to_integer(unsigned(org_L((to_integer(unsigned(row))  -2 ) * WIDTH + to_integer(unsigned(col)) + 1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))  -2 ) * WIDTH + to_integer(unsigned(col)) + 1 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row))   -2 ) * WIDTH + to_integer(unsigned(col)) + 1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))   -2 ) * WIDTH + to_integer(unsigned(col)) + 1 -to_integer(unsigned(offset))))))
                    +(to_integer(unsigned(org_L((to_integer(unsigned(row))  -2 ) * WIDTH + to_integer(unsigned(col)) + 2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))  -2 ) * WIDTH + to_integer(unsigned(col)) + 2 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row))   -2 ) * WIDTH + to_integer(unsigned(col)) + 2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))   -2 ) * WIDTH + to_integer(unsigned(col)) + 2 -to_integer(unsigned(offset))))))
                    +(to_integer(unsigned(org_L((to_integer(unsigned(row))  -1 ) * WIDTH + to_integer(unsigned(col))  -2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))  -1 ) * WIDTH + to_integer(unsigned(col))  -2 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row))   -1 ) * WIDTH + to_integer(unsigned(col))  -2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))   -1 ) * WIDTH + to_integer(unsigned(col))  -2 -to_integer(unsigned(offset))))))
                    +(to_integer(unsigned(org_L((to_integer(unsigned(row))  -1 ) * WIDTH + to_integer(unsigned(col))  -1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))  -1 ) * WIDTH + to_integer(unsigned(col))  -1 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row))   -1 ) * WIDTH + to_integer(unsigned(col))  -1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))   -1 ) * WIDTH + to_integer(unsigned(col))  -1 -to_integer(unsigned(offset))))))
                    +(to_integer(unsigned(org_L((to_integer(unsigned(row))  -1 ) * WIDTH + to_integer(unsigned(col)) + 0   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))  -1 ) * WIDTH + to_integer(unsigned(col)) + 0 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row))   -1 ) * WIDTH + to_integer(unsigned(col)) + 0   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))   -1 ) * WIDTH + to_integer(unsigned(col)) + 0 -to_integer(unsigned(offset))))))
                    +(to_integer(unsigned(org_L((to_integer(unsigned(row))  -1 ) * WIDTH + to_integer(unsigned(col)) + 1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))  -1 ) * WIDTH + to_integer(unsigned(col)) + 1 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row))   -1 ) * WIDTH + to_integer(unsigned(col)) + 1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))   -1 ) * WIDTH + to_integer(unsigned(col)) + 1 -to_integer(unsigned(offset))))))
                    +(to_integer(unsigned(org_L((to_integer(unsigned(row))  -1 ) * WIDTH + to_integer(unsigned(col)) + 2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))  -1 ) * WIDTH + to_integer(unsigned(col)) + 2 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row))   -1 ) * WIDTH + to_integer(unsigned(col)) + 2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row))   -1 ) * WIDTH + to_integer(unsigned(col)) + 2 -to_integer(unsigned(offset))))))
                    +(to_integer(unsigned(org_L((to_integer(unsigned(row)) + 0 ) * WIDTH + to_integer(unsigned(col))  -2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + 0 ) * WIDTH + to_integer(unsigned(col))  -2 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) +  0 ) * WIDTH + to_integer(unsigned(col))  -2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +  0 ) * WIDTH + to_integer(unsigned(col))  -2 -to_integer(unsigned(offset))))))
                    +(to_integer(unsigned(org_L((to_integer(unsigned(row)) + 0 ) * WIDTH + to_integer(unsigned(col))  -1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + 0 ) * WIDTH + to_integer(unsigned(col))  -1 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) +  0 ) * WIDTH + to_integer(unsigned(col))  -1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +  0 ) * WIDTH + to_integer(unsigned(col))  -1 -to_integer(unsigned(offset))))))
                    +(to_integer(unsigned(org_L((to_integer(unsigned(row)) + 0 ) * WIDTH + to_integer(unsigned(col)) + 0   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + 0 ) * WIDTH + to_integer(unsigned(col)) + 0 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) +  0 ) * WIDTH + to_integer(unsigned(col)) + 0   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +  0 ) * WIDTH + to_integer(unsigned(col)) + 0 -to_integer(unsigned(offset))))))
                    +(to_integer(unsigned(org_L((to_integer(unsigned(row)) + 0 ) * WIDTH + to_integer(unsigned(col)) + 1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + 0 ) * WIDTH + to_integer(unsigned(col)) + 1 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) +  0 ) * WIDTH + to_integer(unsigned(col)) + 1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +  0 ) * WIDTH + to_integer(unsigned(col)) + 1 -to_integer(unsigned(offset))))))
                    +(to_integer(unsigned(org_L((to_integer(unsigned(row)) + 0 ) * WIDTH + to_integer(unsigned(col)) + 2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + 0 ) * WIDTH + to_integer(unsigned(col)) + 2 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) +  0 ) * WIDTH + to_integer(unsigned(col)) + 2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +  0 ) * WIDTH + to_integer(unsigned(col)) + 2 -to_integer(unsigned(offset))))))
                    +(to_integer(unsigned(org_L((to_integer(unsigned(row)) + 1 ) * WIDTH + to_integer(unsigned(col))  -2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + 1 ) * WIDTH + to_integer(unsigned(col))  -2 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) +  1 ) * WIDTH + to_integer(unsigned(col))  -2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +  1 ) * WIDTH + to_integer(unsigned(col))  -2 -to_integer(unsigned(offset))))))
                    +(to_integer(unsigned(org_L((to_integer(unsigned(row)) + 1 ) * WIDTH + to_integer(unsigned(col))  -1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + 1 ) * WIDTH + to_integer(unsigned(col))  -1 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) +  1 ) * WIDTH + to_integer(unsigned(col))  -1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +  1 ) * WIDTH + to_integer(unsigned(col))  -1 -to_integer(unsigned(offset))))))
                    +(to_integer(unsigned(org_L((to_integer(unsigned(row)) + 1 ) * WIDTH + to_integer(unsigned(col)) + 0   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + 1 ) * WIDTH + to_integer(unsigned(col)) + 0 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) +  1 ) * WIDTH + to_integer(unsigned(col)) + 0   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +  1 ) * WIDTH + to_integer(unsigned(col)) + 0 -to_integer(unsigned(offset))))))
                    +(to_integer(unsigned(org_L((to_integer(unsigned(row)) + 1 ) * WIDTH + to_integer(unsigned(col)) + 1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + 1 ) * WIDTH + to_integer(unsigned(col)) + 1 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) +  1 ) * WIDTH + to_integer(unsigned(col)) + 1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +  1 ) * WIDTH + to_integer(unsigned(col)) + 1 -to_integer(unsigned(offset))))))
                    +(to_integer(unsigned(org_L((to_integer(unsigned(row)) + 1 ) * WIDTH + to_integer(unsigned(col)) + 2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + 1 ) * WIDTH + to_integer(unsigned(col)) + 2 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) +  1 ) * WIDTH + to_integer(unsigned(col)) + 2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +  1 ) * WIDTH + to_integer(unsigned(col)) + 2 -to_integer(unsigned(offset))))))
                    +(to_integer(unsigned(org_L((to_integer(unsigned(row)) + 2 ) * WIDTH + to_integer(unsigned(col))  -2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + 2 ) * WIDTH + to_integer(unsigned(col))  -2 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) +  2 ) * WIDTH + to_integer(unsigned(col))  -2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +  2 ) * WIDTH + to_integer(unsigned(col))  -2 -to_integer(unsigned(offset))))))
                    +(to_integer(unsigned(org_L((to_integer(unsigned(row)) + 2 ) * WIDTH + to_integer(unsigned(col))  -1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + 2 ) * WIDTH + to_integer(unsigned(col))  -1 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) +  2 ) * WIDTH + to_integer(unsigned(col))  -1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +  2 ) * WIDTH + to_integer(unsigned(col))  -1 -to_integer(unsigned(offset))))))
                    +(to_integer(unsigned(org_L((to_integer(unsigned(row)) + 2 ) * WIDTH + to_integer(unsigned(col)) + 0   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + 2 ) * WIDTH + to_integer(unsigned(col)) + 0 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) +  2 ) * WIDTH + to_integer(unsigned(col)) + 0   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +  2 ) * WIDTH + to_integer(unsigned(col)) + 0 -to_integer(unsigned(offset))))))
                    +(to_integer(unsigned(org_L((to_integer(unsigned(row)) + 2 ) * WIDTH + to_integer(unsigned(col)) + 1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + 2 ) * WIDTH + to_integer(unsigned(col)) + 1 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) +  2 ) * WIDTH + to_integer(unsigned(col)) + 1   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +  2 ) * WIDTH + to_integer(unsigned(col)) + 1 -to_integer(unsigned(offset))))))
                    +(to_integer(unsigned(org_L((to_integer(unsigned(row)) + 2 ) * WIDTH + to_integer(unsigned(col)) + 2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) + 2 ) * WIDTH + to_integer(unsigned(col)) + 2 - to_integer(unsigned(offset))))))*(to_integer(unsigned(org_L((to_integer(unsigned(row)) +  2 ) * WIDTH + to_integer(unsigned(col)) + 2   )))-to_integer(unsigned(org_R((to_integer(unsigned(row)) +  2 ) * WIDTH + to_integer(unsigned(col)) + 2 -to_integer(unsigned(offset))))))
			        ,ssd'length));
                    
                    compare <= '1';
			   end if;
			   
			   if compare = '1' then
			         if ssd < prev_ssd then
			             prev_ssd<=ssd;
                         best_offset<=offset;
                     end if;
			         offsetping <= '0';
	                 compare <= '0';
			   end if;
			   
			   
			   
----------------------------------------------------------------------------------------------------------------------------------------------------
--            else
--                data_count <= (others => '0');
--                doneFetch <='0';
--                offsetfound<='0';
--                cacheManager<=cacheManager+"1";
--            end if; 
        end if;
    end if;
end process;

end Behavioral;

