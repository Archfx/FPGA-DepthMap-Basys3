library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.numeric_std.all;



entity RGB is
    Port ( Din 	: in	STD_LOGIC_VECTOR (7 downto 0);	
		   Nblank : in	STD_LOGIC;								
           R,G,B 	: out	STD_LOGIC_VECTOR (7 downto 0));		
end RGB;

architecture Behavioral of RGB is


begin

		R <= (Din) when Nblank='1' and 139<(unsigned(Din)) else "00000000";
		G <= (Din)  when Nblank='1' and 59<(unsigned(Din)) and 230>(unsigned(Din)) else "00000000";
		B <= (Din)  when Nblank='1' and 90>(unsigned(Din)) else "00000000";

end Behavioral;
