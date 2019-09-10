----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/07/2019 10:25:48 AM
-- Design Name: 
-- Module Name: Image_Rectification - Behavioral
-- Project Name: 
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

entity Image_Rectification is
  Port (address_in 	: in STD_LOGIC_VECTOR (16 downto 0);
        plus : in  STD_LOGIC;
        minus : in  STD_LOGIC;
        plus_col : in  STD_LOGIC;
        minus_col : in  STD_LOGIC;
        CLK : in  STD_LOGIC;
	    exposure       : out STD_LOGIC_VECTOR (15 downto 0);
        address_left 	: out STD_LOGIC_VECTOR (16 downto 0);
        address_right 	: out STD_LOGIC_VECTOR (16 downto 0));
end Image_Rectification;

architecture Behavioral of Image_Rectification is

signal adjust: STD_LOGIC_VECTOR (3 downto 0) := "1000";
signal adjust_vert: STD_LOGIC_VECTOR (7 downto 0) := "00010100";

signal counter: STD_LOGIC_VECTOR (15 downto 0);

begin
address_left <= address_in;
address_right <= std_logic_vector(unsigned(address_in) + (to_integer(unsigned(adjust))*320) + to_integer(unsigned(adjust_vert)));

--exposure<=adjust_exposure;

caliberate_alignment_process: process (CLK) begin
    if rising_edge(CLK) then
        counter <= counter + '1';
        if plus = '1' and counter = x"ffff" then
            adjust <= adjust + '1';
        end if;
        if minus = '1' and counter = x"ffff" then
            adjust <= adjust - '1';
        end if;      
    end if;
end process;
caliberate_exposure_process: process (CLK) begin
    if rising_edge(CLK) then
        if plus_col = '1' and counter = x"ffff" then
            adjust_vert <= adjust_vert + '1';
        end if;
        if minus_col = '1' and counter = x"ffff" then
            adjust_vert <= adjust_vert - '1';
        end if;      
    end if;
end process;


end Behavioral;
