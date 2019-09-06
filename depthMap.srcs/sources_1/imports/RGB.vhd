library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.numeric_std.all;



entity RGB is
    Port ( Din 	: in	STD_LOGIC_VECTOR (7 downto 0);
           Din_avg 	: in	STD_LOGIC_VECTOR (3 downto 0);	
		   Nblank : in	STD_LOGIC;								
           R,G,B 	: out	STD_LOGIC_VECTOR (7 downto 0);
           avg_en : in	STD_LOGIC );		
end RGB;

architecture Behavioral of RGB is
signal vga_out : STD_LOGIC_VECTOR(7 downto 0);

begin
    with avg_en select 
        vga_out <= Din when '0',
                   Din_avg & Din_avg when '1';
                   
--		R <= (Din) when Nblank='1' and 200<(unsigned(Din)) and avg_en='0' else "00000000";
--		G <= (Din)  when Nblank='1' and 150<(unsigned(Din)) and 220>(unsigned(Din)) and avg_en='0' else "00000000";
--		B <= (Din)  when Nblank='1' and 160>(unsigned(Din)) and avg_en='0' else "00000000";
		
		R <= (vga_out) when Nblank='1' else "00000000";
		G <= (vga_out)  when Nblank='1' else "00000000";
		B <= (vga_out)  when Nblank='1' else "00000000";

end Behavioral;
