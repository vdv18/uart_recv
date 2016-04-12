----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    04:31:11 04/12/2016 
-- Design Name: 
-- Module Name:    main_hw_test_0 - Behavioral 
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

entity main_hw_test_0 is
    Port ( rxd : in  STD_LOGIC;
           clk : in  STD_LOGIC;
			  outclk : out std_logic;
			  reset: in std_logic;
			  errp : out std_logic;
			  errf : out std_logic;
			  dataready: out std_logic;
           data : out  STD_LOGIC_VECTOR (7 downto 0));
end main_hw_test_0;

architecture Behavioral of main_hw_test_0 is
  component rx_data
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
  end component;
  CONSTANT paritybit: std_logic_vector := "00";
  CONSTANT stopbits: std_logic := '0';
  CONSTANT databits: std_logic_vector := "11";
  CONSTANT max: INTEGER := 40960000/(9600*16);
  CONSTANT half: INTEGER := max/2;
  SIGNAL count: INTEGER RANGE 0 TO max;
  signal clkdiv:	std_logic;
  signal datardy: std_logic;
  signal dataout : STD_LOGIC_VECTOR (7 downto 0);
begin
	outclk <= clkdiv;
	dataready <= datardy;
	--data <= dataout;
	uart_rx: rx_data port map (
				clk16=>clkdiv,
				reset=>reset,
				rx=>rxd,
				paritybit=>paritybit,
				stopbits=>stopbits,
				databits=>databits,
				rxdata=>dataout,
				rxrdy=>datardy,
				err_parity=>errp,
				err_frame=>errf
	);
	process(clk,datardy)
	begin
		if datardy'event and datardy='1' then
			data <= dataout;
		end if;
	end process;
	
	process(clk,count,clkdiv)
	begin
		if clk'event and clk='1' then
			if count < max then
				count <= count + 1;
			else
				count <= 0;
			end if;
			
			if count < half then
				clkdiv <= '0';
			else
				clkdiv <= '1';
			end if;
			
		end if;
	end process;
	
end Behavioral;

