-- Import IEEE standard logic libraries
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- Entity for 2-digit 7-segment display multiplexer
-- Alternates between two 7-segment inputs using a clock-driven toggle
entity segment7_mux is
	port (
		clk		: in std_logic := '0';				-- Clock input
		DIN2	: in std_logic_vector(6 downto 0);	-- 7-segment input for digit 2
		DIN1	: in std_logic_vector(6 downto 0);	-- 7-segment input for digit 1
		DOUT	: out std_logic_vector(6 downto 0);	-- Multiplexed 7-segment output
		DIG2	: out std_logic;					-- Enable signal for digit 2
		DIG1	: out std_logic						-- Enable signal for digit 1
   );
end entity segment7_mux;

-- Architecture toggles between DIN1 and DIN2 to drive shared 7-segment lines
architecture syn of segment7_mux is
	signal toggle 			: std_logic;
	signal DOUT_TEMP		: std_logic_vector(6 downto 0);
   
begin
	-- Toggle signal changes based on counter overflow
  	clk_proc:process(CLK)
	variable COUNT	: unsigned(10 downto 0) := "00000000000";
  	
	begin
		if (rising_edge(CLK)) then
  			COUNT := COUNT + 1;
  		end if;
 		toggle <= COUNT(10);
 	end process clk_proc;

	-- Output enable for each digit based on toggle state
	DIG1 <= NOT toggle;
	DIG2 <= toggle;
	
	-- Mux between DIN1 and DIN2 based on toggle
	DOUT_TEMP(0) <= (DIN2(0)) WHEN (toggle = '1')	ELSE (DIN1(0));
	DOUT_TEMP(1) <= (DIN2(1)) WHEN (toggle = '1')	ELSE (DIN1(1));
	DOUT_TEMP(2) <= (DIN2(2)) WHEN (toggle = '1')	ELSE (DIN1(2));
	DOUT_TEMP(3) <= (DIN2(3)) WHEN (toggle = '1')	ELSE (DIN1(3));
	DOUT_TEMP(4) <= (DIN2(4)) WHEN (toggle = '1')	ELSE (DIN1(4));
	DOUT_TEMP(5) <= (DIN2(5)) WHEN (toggle = '1')	ELSE (DIN1(5));
	DOUT_TEMP(6) <= (DIN2(6)) WHEN (toggle = '1')	ELSE (DIN1(6));
--	DOUT_TEMP(7) <= (DIN2(7)) WHEN (toggle = '1')	ELSE (DIN1(7));

	-- Drive output with optional open-drain segments
	DOUT(0) <= '0' WHEN (DOUT_TEMP(0) = '0')	ELSE '1';
	DOUT(1) <= '0' WHEN (DOUT_TEMP(1) = '0')	ELSE 'Z';	--open drain
	DOUT(2) <= '0' WHEN (DOUT_TEMP(2) = '0')	ELSE '1';
	DOUT(3) <= '0' WHEN (DOUT_TEMP(3) = '0')	ELSE '1';
	DOUT(4) <= '0' WHEN (DOUT_TEMP(4) = '0')	ELSE '1';
	DOUT(5) <= '0' WHEN (DOUT_TEMP(5) = '0')	ELSE 'Z';	--open drain
	DOUT(6) <= '0' WHEN (DOUT_TEMP(6) = '0')	ELSE 'Z';	--open drain
--	DOUT(7) <= '0' WHEN (DOUT_TEMP(7) = '0')	ELSE '1';

end architecture syn;