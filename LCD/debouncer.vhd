----------------------------------------------------------------------------------------------------------------------------------
-- Module Name: debouncer - Behavioral (Debouncer.vhd), component C0
-- Project Name: PmodENC
-- Target Devices: Nexys 3
-- This file defines a debouncer for eliminating the logic noise presented when the shaft is rotated.
----------------------------------------------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Debouncer is
Port ( 
	clock : in STD_LOGIC;
	-- signals from the pmod
	Ain : in STD_LOGIC; 
	Bin : in STD_LOGIC;
	-- debounced signals
	Aout: out STD_LOGIC;
	Bout: out STD_LOGIC
);
end Debouncer;

architecture Behavioral of Debouncer is
-- signals
signal sclk: std_logic_vector (6 downto 0);
signal sampledA, sampledB : std_logic;
begin

process(clock)
begin

if clock'event and clock = '1' then
sampledA <= Ain;
sampledB <= Bin;
-- clock is divided to 1MHz
-- samples every 1uS to check if the input is the same as the sample
-- if the signal is stable, the debouncer should output the signal
if sclk = "1100100" then
-- A
if sampledA = Ain then
Aout <= Ain;
end if;
-- B
if sampledB = Bin then
Bout <= Bin;
end if;
sclk <="0000000";
else
sclk <= sclk +1;
end if;
end if;
end process;
end Behavioral;