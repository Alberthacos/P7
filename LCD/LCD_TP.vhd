--CODIGO PARA CONTROLAR UN LCD CON LA TARJETA AMIBA 2 CON 8 BITS
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

ENTITY LCD IS 
	
GENERIC(
	 CONSTANT FPGA_CLK 	: INTEGER := 50_000_000				  --Frecuencia de amiba 2 50MHz

);

PORT(
	  direccion1,E_direccion	: IN STD_LOGIC;
	  REINI 					: in STD_LOGIC; --boton de reinicio a BTN0
	 -- LED		 			: INOUT STD_LOGIC;
	  CLOCK		 		   : IN STD_LOGIC;							--RELOJ 50MHZ de amiba 2
	  LCD_RS 			   : OUT STD_LOGIC;							--	Comando, escritura
	  LCD_RW				   : OUT STD_LOGIC;							-- LECTURA/ESCRITURA
	  LCD_E 				   : OUT STD_LOGIC;							-- ENABLE
	  DATA 				   : OUT STD_LOGIC_VECTOR(7 DOWNTO 0):="00000000"  -- PINES DATOS
	);
END LCD;

  architecture Principal of LCD is

	type STATE_TYPE is (
	RST,ST0,ST1,ST2,SET_DEFI,SHOW1,SHOW2,CLEAR,ENTRY,A,L,B,E,R,T,desplazamiento,Vacio);
	
	signal State,Next_State : STATE_TYPE;
	signal CONT1 : STD_LOGIC_VECTOR(23 downto 0) := X"000000"; -- 16,777,216 = 0.33554432 s MAX
	signal CONT2 : STD_LOGIC_VECTOR(4 downto 0) :="00000"; -- 32 = 0.64us
	signal RESET : STD_LOGIC :='0';
	signal READY : STD_LOGIC :='0';
	signal listo : STD_LOGIC:='0';
	signal direccion: STD_LOGIC;
	signal unidades, decenas: integer range 0 to 9  :=0;
	
--	constant 0 : STD_LOGIC_VECTOR(7 downto 0):="00110000";
--	constant 1 : STD_LOGIC_VECTOR(7 downto 0):="00110001";
--	constant 2 : STD_LOGIC_VECTOR(7 downto 0):="00110010";
--	constant 3 : STD_LOGIC_VECTOR(7 downto 0):="00110011";
--	constant 4 : STD_LOGIC_VECTOR(7 downto 0):="00110100";
--	constant 5 : STD_LOGIC_VECTOR(7 downto 0):="00110101";
--	constant 6 : STD_LOGIC_VECTOR(7 downto 0):="00110110";
--	constant 7 : STD_LOGIC_VECTOR(7 downto 0):="00110111";
--	constant 8 : STD_LOGIC_VECTOR(7 downto 0):="00111000";
--	constant 9 : STD_LOGIC_VECTOR(7 downto 0):="00111001";
------------------------------------------------------------------
begin 
-------------------------------------------------------------------
--Contador de Retardos CONT1--
process(CLOCK,RESET)
begin
	if RESET='1' then CONT1 <= (others => '0');
	elsif CLOCK'event and CLOCK='1' then CONT1 <= CONT1 + 1;
	end if;
end process;
-------------------------------------------------------------------
--Contador para Secuencias CONT2--
process(CLOCK,READY)
begin
	if CLOCK='1' and CLOCK'event then
		if READY='1' then CONT2 <= CONT2 + 1;
		else CONT2 <= "00000";
		end if;
	end if;
end process;
-------------------------------------------------------------------
--Actualización de estados--
process (CLOCK, Next_State)
begin
	if CLOCK='1' and CLOCK'event then State <= Next_State;
end if;
end process;
------------------------------------------------------------------
process(CONT1,CONT2,State,CLOCK,REINI)
begin
if listo = '1' then 	--se puede habilitar el movimiento solo si ya se escribio la palabra 
	if E_direccion = '0' then  --interruptor habilita o deshabilita el movimiento con 0 no hay movimiento 
			Next_State <= Vacio; 
	else 								--con 1 hay movimiento
		Next_State <= desplazamiento;
		if direccion1 = '1' then direccion <='1'; --derecha
		else  direccion <='0'; --izquierda
		end if;
	end if;
end if;
if REINI = '1' THEN Next_State <= RST;
elsif CLOCK='0' and CLOCK'event then

	case State is

		when RST => -- Estado de reset
			if CONT1=X"000000"then --0s
				LCD_RS<='0';
				LCD_RW<='0';
				LCD_E<='0';
				DATA<=X"00";
				Next_State<=ST0;
				listo<='0';
			else
				Next_State<=ST0;
			end if;
			
		when ST0 => --Primer estado de espera por 25ms (20ms=0F4240=1000000)(15ms=0B71B0=750000)
		---SET 1
			if CONT1=X"2625A0" then -- 2,500,000=50ms
				READY<='1';
				DATA<="00110000"; -- FUNCTION SET 8BITS, 2 LINE, 5X7
				Next_State<=ST0;
			elsif CONT2>"00001" and CONT2<"01110" then--rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';
				Next_State<=ST1;
			else
				Next_State<=ST0;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0

		when ST1 => --Segundo estado de espera por 5ms
		----SET2
			if CONT1=X"3D090" then -- 250,000 = 5ms
				READY<='1';
				DATA<="00110000"; -- FUNCTION SET
				Next_State<=ST1;
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';
				Next_State<=ST2;
			else
				Next_State<=ST1;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0


		when ST2 => --Tercer estado de espera por 100us
		-----SET 3
			if CONT1=X"0035E8" then -- 5000 = 100us  = x35E8)
				READY<='1';
				DATA<="00110000"; -- FUNCTION SET
				Next_State<=ST2;
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';
				Next_State<=SET_DEFI;
			else
				Next_State<=ST2;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0
				
		when SET_DEFI => --Cuarto paso, se asignan lineas logicas, modo de bits (8) y #caracteres(5x8)
		-----SET DEFINITIVO
			if CONT1=X"0009C4" then --espera por 50us 20ns*2500=50us 2500=9C4
				READY<='1';
				DATA<="00111000"; -- FUNCTION SET(lineas,caracteres,bits)
				Next_State<=SET_DEFI;
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';
				Next_State<=SHOW1;
			else
				Next_State<=SET_DEFI;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0


		when SHOW1 => --Quinto paso, se apaga el display por unica ocasion
		-----SHOW _ APAGAR DISPLAY
			if CONT1=X"0009C4" then --espera por 50us 20ns*2500=50us 2500=9C4
				READY<='1';
				DATA<="00001000"; -- SHOW, APAGAR DISPLAY POR UNICA OCASION 
				Next_State<=SHOW1;
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';
				Next_State<=CLEAR;
			else
				Next_State<=SHOW1;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0
				
		when CLEAR => --SEXTO PASO, SE LIMPIA EL DISPLAY POR PRIMERA VEZ
		-----CLEAR, LIMPIAR DISPLAY
			if CONT1=X"0009C4" then --espera por 50us 20ns*2500=50us 2500=9C4
				READY<='1';
				DATA<="00000001"; -- CLEAR
				Next_State<=CLEAR;
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';
				Next_State<=ENTRY;
			else
				Next_State<=CLEAR;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0
				
		when ENTRY => --SEPTIMO PASO, CONFIGURAR MODO DE ENTRADA
		-----ENTRY MODE
			if CONT1=X"3D090" then --espera por 5ms 250,000
				READY<='1';
				DATA<="00000110"; -- ENTRY MODE, se mueve a la derecha(escritura), no se desplaza(barrido)
				Next_State<=ENTRY;
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';
				Next_State<=SHOW2;
			else
				Next_State<=ENTRY;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0
				
		when SHOW2 => --OCTAVO PASO, ENCENDER LA LCD Y CONFIGURAR CURSOR, PARPADEO
		-----SHOW DEFINITIVO
			if CONT1=X"0009C4" then --espera por 50us 20ns*2500=50us 2500=9C4
				READY<='1';
				DATA<="00001111"; -- SHOW DEFINITIVO, SE ENCIENDE DISPLAY Y CONFIURA CURSOR
				Next_State<=SHOW2;
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';
				Next_State<=A;
			else
				Next_State<=SHOW2;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0
				----------------------------------------------------------------------
				----------------------------------------
		when A => --LETRA A MAYUSCULA
			if CONT1=X"0009C4" then --espera por 50us 20ns*2500=50us 2500=9C4
				READY<='1';
				DATA<="01000001"; -- A
				Next_State<=A;
				LCD_RS<='1';
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';
				Next_State<=L;
			else
--				Next_State<=A;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0
				
				
		when L => --L MAYUSCULA
			if CONT1=X"0009C4" then --espera por 50us 20ns*2500=50us 2500=9C4
				READY<='1';
				DATA<="01001100"; -- SHOW DEFINITIVO, SE ENCIENDE DISPLAY Y CONFIURA CURSOR
				Next_State<=L;
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';
				Next_State<=B;
			else
				Next_State<=L;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0
				
		when B => --B MAYUSCULA
			if CONT1=X"0009C4" then --espera por 50us 20ns*2500=50us 2500=9C4
				READY<='1';
				DATA<="01000010"; -- SHOW DEFINITIVO, SE ENCIENDE DISPLAY Y CONFIURA CURSOR
				Next_State<=B;
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';
				Next_State<=E;
			else
				Next_State<=B;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0
				
		when E => --E MAYUSCULA
			if CONT1=X"0009C4" then --espera por 50us 20ns*2500=50us 2500=9C4
				READY<='1';
				DATA<="01000101"; -- SHOW DEFINITIVO, SE ENCIENDE DISPLAY Y CONFIURA CURSOR
				Next_State<=E;
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';
				Next_State<=R;
			else
				Next_State<=E;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0


		when R => --R MAYUSCULA
			if CONT1=X"0009C4" then --espera por 50us 20ns*2500=50us 2500=9C4
				READY<='1';
				DATA<="01010010"; -- SHOW DEFINITIVO, SE ENCIENDE DISPLAY Y CONFIURA CURSOR
				Next_State<=R;
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';
				Next_State<=T;
			else
				Next_State<=R;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0


		when T => --T MAYUSCULA
			if CONT1=X"0009C4" then --espera por 50us 20ns*2500=50us 2500=9C4
				READY<='1';
				DATA<="01010100"; -- SHOW DEFINITIVO, SE ENCIENDE DISPLAY Y CONFIURA CURSOR
				Next_State<=T;
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';
				LCD_RS<='0';
				Next_State<=desplazamiento;
				listo<='1';
			else
				Next_State<=T;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0
		
				
		when desplazamiento => --T MAYUSCULA
			if CONT1=X"E4E1C0" then --espera por 500ms 20ns*25,000,000=50ms 2500=9C4
				READY<='1';
				DATA<="00011"&direccion&"00"; -- SHOW DEFINITIVO, SE ENCIENDE DISPLAY Y CONFIURA CURSOR
				Next_State<=desplazamiento;
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
				LCD_E<='1';
			elsif CONT2="1111" then
				READY<='0';
				LCD_E<='0';
				LCD_RS<='0';
				Next_State<=desplazamiento;
			else
				Next_State<=desplazamiento;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0
				
				
		when Vacio => --Sin ordenes
			if CONT1=X"E4E1C0" then --espera por 500ms 20ns*25,000,000=50ms 2500=9C4
--				READY<='1';
--				DATA<="00011"&direccion&'00'; -- SHOW DEFINITIVO, SE ENCIENDE DISPLAY Y CONFIURA CURSOR
--				Next_State<=desplazamiento;
			elsif CONT2>"00001" and CONT2<"01110" then --rango de 12*20ns=240ns
--				LCD_E<='1';
			elsif CONT2="1111" then
--				READY<='0';
--				LCD_E<='0';
--				LCD_RS<='0';
--				Next_State<=desplazamiento;
			else
--				Next_State<=desplazamiento;
			end if;
				RESET<= CONT2(0)and CONT2(1)and CONT2(2)and CONT2(3); -- CONT1 = 0
				
		when others => READY<='0';
				LCD_E<='0';
				LCD_RS<='0';
						
		end case;
end if;


----------------------------------
-----------------------------------
if EncOut<=9 then 
	decenas <= 0;
	unidades<=EncOut;
	
else decenas<=EncOut/10;
		unidades<=EncOut-(decenas*10);
end if;
------------------------------------
--------------------------------------

end process;	
	
	end Principal;