---U1 Codigo que controla la inicializacion del LCD 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity INI is
Port (
    clk: in STD_LOGIC;
	puertos,leds: OUT std_logic_vector (1 to 4); --leds testigos y salida al puerto para el motor, representa el encdedido de las bobinas
    -- signals from the pmod
    A : in STD_LOGIC;
    B : in STD_LOGIC;
    -- position of the shaft
    -- direction indicator
    LED: out STD_LOGIC_VECTOR (1 downto 0)
);
end INI;