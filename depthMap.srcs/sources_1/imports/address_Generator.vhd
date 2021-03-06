
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Address_Generator is
    Port ( 	CLK,enable : in  STD_LOGIC;								-- horloge de 25 MHz et signal d'activation respectivement
            rez_160x120  : IN std_logic;
            rez_320x240  : IN std_logic;
            vsync        : in  STD_LOGIC;
            avg_en       : in  STD_LOGIC;
			address 	: out STD_LOGIC_VECTOR (16 downto 0));	-- adresse g�n�r�
end Address_Generator;

architecture Behavioral of Address_Generator is
   signal val: STD_LOGIC_VECTOR(address'range):= (others => '0');		-- signal intermidiaire
   signal val_avg: STD_LOGIC_VECTOR(address'range):= (others => '0');
begin
    with avg_en select 
    	address <= val when '0',
    	           val_avg when '1';																-- adresse g�n�r�

	process(CLK)
		begin
         if rising_edge(CLK) then
            if (enable='1' and avg_en='0') then													-- si enable = 0 on arrete la g�n�ration d'adresses
               if rez_160x120 = '1' then
                  if (val < 160*120) then										-- si l'espace m�moire est balay� compl�tement				
                     val <= val + 1 ;
                  end if;
               elsif rez_320x240 = '1' then
                  if (val < 320*240) then										-- si l'espace m�moire est balay� compl�tement				
                     val <= val + 1 ;
                  end if;
               else
                  if (val < 640*480) then										-- si l'espace m�moire est balay� compl�tement				
                     val <= val + 1 ;
                  end if;
               end if;
				end if;
            if vsync = '0' then 
               val <= (others => '0');
            end if;
            if (enable='1' and avg_en='1') then													-- si enable = 0 on arrete la g�n�ration d'adresses
               if rez_160x120 = '1' then
                  if (val_avg < 160*120) then										-- si l'espace m�moire est balay� compl�tement				
                     val_avg <= val_avg + 1 ;
                  end if;
               elsif rez_320x240 = '1' then
                  if (val_avg < 320*240) then										-- si l'espace m�moire est balay� compl�tement				
                     val_avg <= val_avg + 1 ;
                  end if;
               else
                  if (val_avg < 640*480) then										-- si l'espace m�moire est balay� compl�tement				
                     val_avg <= val_avg + 1 ;
                  end if;
               end if;
				end if;
            if vsync = '0' then 
               val_avg <= (others => '0');
            end if;
			end if;	
		end process;
end Behavioral;

