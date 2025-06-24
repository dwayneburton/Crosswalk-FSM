-- Import standard logic library
library ieee;
use ieee.std_logic_1164.all;

-- Entity for 2-stage input synchronizer
-- Synchronizes an asynchronous input signal to the system clock to prevent metastability
entity synchronizer is
	port (
		clk		: in std_logic;	-- System clock input
		reset	: in std_logic;	-- Active-high synchronous reset
		din		: in std_logic;	-- Asynchronous input signal
		dout	: out std_logic	-- Synchronized output
	);
end synchronizer;
 
-- Architecture implements a 2-stage flip-flop chain
architecture circuit of synchronizer is
	signal sreg : std_logic_vector(1 downto 0);	-- Flip-flop stages for synchronization
begin
	-- Synchronization process: captures input over 2 clock cycles
	synchronizer_section: process (clk, reset)
	begin
		if(rising_edge(clk)) then
			if(reset = '0') then
				sreg(0) <= din;		-- First stage captures input
				sreg(1) <= sreg(0);	-- Second stage provides stable output
			else
				sreg <= "00";		-- Clear flip-flops on reset
			end if;
		end if;
	
	-- Output synchronized value
	dout <= sreg(1);
	end process;
end circuit;