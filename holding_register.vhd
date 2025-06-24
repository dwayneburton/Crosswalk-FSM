-- Import standard logic library
library ieee;
use ieee.std_logic_1164.all;

-- Entity for a 1-bit holding register
-- Captures and holds input signal 'din' until cleared by 'reset' or 'register_clr'
entity holding_register is
	port (
		clk				: in std_logic;	-- Clock input
		reset			: in std_logic;	-- Active-high synchronous reset
		register_clr	: in std_logic;	-- Active-high clear for register contents
		din				: in std_logic;	-- Data input
		dout			: out std_logic	-- Registered output
	);
end holding_register;

-- Architecture implementing a basic gated D flip-flop with clear
architecture circuit of holding_register is
	signal sreg		: std_logic;	-- Internal storage register
	signal sync_in	: std_logic;	-- Next state logic input to the register

begin
	-- Holding register process: stores a '1' when din = '1', cleared by reset or register_clr
	holding_register_section: process(clk, reset)
	begin
		-- Compute next state of register
		sync_in <= (sreg OR din) AND (register_clr NOR reset);

		-- Register behavior on rising clock edge
		if(rising_edge(clk)) then
			-- Store computed value
			if(reset ='0') then
				sreg <= sync_in;
			-- Reset condition
			else
				sreg <= '0';
			end if;
		end if;

		-- Drive output with register value
		dout <= sreg;
	end process;
end circuit;