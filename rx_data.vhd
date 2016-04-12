----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:45:45 04/11/2016 
-- Design Name: 
-- Module Name:    rx_data - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity rx_data is
    Port ( clk16      : in   STD_LOGIC;
	        reset      : in   STD_LOGIC;
           rx         : in   STD_LOGIC;
           paritybit  : in   STD_LOGIC_VECTOR (1 downto 0); -- "00" = none; "01" = odd; "10" = even
           stopbits   : in   STD_LOGIC; -- '0' = 1 stop bit; '1' = 2 stop bits
           databits   : in   STD_LOGIC_VECTOR (1 downto 0); -- "00"=5 bits;"01"=6 bits;"10"=7 bits;"11"=8 bits;
           rxdata     : out  STD_LOGIC_VECTOR (7 downto 0);
           rxrdy      : out  STD_LOGIC;
           err_parity : out  STD_LOGIC;
           err_frame  : out  STD_LOGIC);
end rx_data;

architecture Behavioral of rx_data is
	type state_t is (idle, start, data, parity, stop);
	shared variable state	:	state_t := idle;
begin
	process(clk16,reset,rx,paritybit,stopbits,databits)
		variable clkcnt:  integer := 0;
		variable rxcnt :  integer := 0;
		variable datalen: integer := 0;
		variable parityclc: std_logic := '0';
		variable recv_data: std_logic_vector(7 downto 0);
	begin
		-- сбрасываем все состояния
		if reset='1' then
			state := idle;
			rxrdy <= '0';
			rxdata <= (others => '0');
			err_frame  <= '0';
			err_parity <= '0';
			rxdata<= (others => '0');
			recv_data:= (others => '0');
	   -- по переднему фронту ведем прием данных
		elsif (clk16'event and clk16='1') then
			-- выбор отображения битов на выходной регистр, в зависимости от выставленного значения databits
			case databits is 
				when "00" =>
					datalen := 5;
					rxdata  <= "000" & recv_data(7 downto 3);
				when "01" =>
					datalen := 6;
					rxdata  <= "00" & recv_data(7 downto 2);
				when "10" =>
					datalen := 7;
					rxdata  <= "0" & recv_data(7 downto 1);
				when others =>
					datalen := 8;
					rxdata  <= recv_data;
			end case;
			-- машина состояний обработки приема
			-- обработка ошибок от start бита (не верно начт)
			case state is
				when idle =>
					rxrdy <= '0';
					clkcnt:=0;
					rxcnt :=0;
					err_frame <= '0';
					rxdata <= (others => '0');
					err_parity <= '0';
					parityclc:='0';
					if rx='0' then
						state:=start;
					end if;
				when start =>
					if rx='0' then
					else
						clkcnt := 0;
						state  := idle;
					end if;
					-- отсчет середины uart бита, от start бита
					if(clkcnt=7) then
						-- проверяем на помеху
						if rx='1' then
							-- уходим ждать
							-- err_frame <= '1';
							state := idle;
						end if;
						state := data;
						clkcnt := 0;
					else
						clkcnt := clkcnt + 1;
					end if;
				when data =>
					-- ожидаем следующую середину бита
					if(clkcnt=15) then
						clkcnt:=0;
						rxcnt := rxcnt + 1;
						-- записываем в сдвиговый регистр
						recv_data  := rx & recv_data(7 downto 1);
						-- считаем четность
						parityclc:=parityclc xor rx;
					else
						clkcnt := clkcnt + 1;
					end if;
					-- данные все считаны?
					if(rxcnt=datalen) then
						clkcnt:=0;
						rxcnt := 0;
						if paritybit="00" then
							-- контроля четности нет
							state := stop;
						else
							-- контроль четности есть
							state := parity;
						end if;
					end if;
				when parity =>
					if(clkcnt=15) then
						clkcnt := 0;
						-- проверяем бит четности на правильность
						case paritybit is 
							when "00" => err_parity <= '0';
							when "01" => err_parity <= rx xor not parityclc;-- odd
							when "10" => err_parity <= rx xor parityclc;-- even
							when others => err_parity <= '0';
						end case;
						state := stop;
					else
						clkcnt := clkcnt + 1;
					end if;
				when stop =>
					-- читаем и проверяем stop биты (1 или 2 таких бита)
					if(clkcnt=15) then
						clkcnt:= 0;
						rxcnt:=rxcnt+1;
						if rx='0' then
							err_frame <= '1';
						end if;
						if stopbits='0' then
							state := idle;
							rxrdy <= '1';
						elsif rxcnt=2 and stopbits='1' then
							state := idle;
							rxrdy <= '1';
						end if;
					else
						clkcnt := clkcnt + 1;
					end if;
					
				when others =>
					-- неопределенное поведение фиксируем и переводим в ожидание
					state := idle;
					clkcnt:= 0;
			end case;
		end if; 
	end process;

end Behavioral;

