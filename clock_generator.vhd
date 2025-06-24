-- Import standard logic and numeric libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Entity for configurable clock generator
-- Outputs 1Hz clock enable and 4Hz blink signal for state machine control and indicators
entity Clock_generator is
	port(
		sim_mode	: in boolean;		-- TRUE for simulation mode, FALSE for FPGA operation
		reset		: in std_logic;		-- Synchronous reset
		clkin		: in std_logic;		-- 50 MHz base clock input
		sm_clken	: out std_logic;	-- 1Hz clock enable output for state machine
		blink		: out std_logic		-- 4Hz blink clock output
	);
end entity;

-- Architecture generates slower clocks by dividing down from 50MHz input
architecture rtl of Clock_generator is
	signal digital_counter				: std_logic_vector(24 downto 0);	-- Internal counter
	signal clk_1hz, clk_4hz				: std_logic;						-- 1Hz and 4Hz clocks for hardware
	signal sim_clk_blink, sim_clk_enbl	: std_logic;						-- Simulated blink clock and clock enable
	signal clk_reg_extend				: std_logic_vector(1 downto 0);		-- 2-stage pipeline to create one-cycle pulse
	signal blink_sig					: std_logic;						-- Blink signal to output

begin
	-- Clock divider: counts 50MHz input clock to generate slower clocks
	clk_divider: process (clkin)
		variable counter : unsigned(24 downto 0);
	begin
		if (rising_edge(clkin))  then
			if(reset ='1') then
				counter := "0000000000000000000000000";
			else
				 counter :=  counter + 1;
			end if;
		end if;
		-- Update counter output
		digital_counter <= std_logic_vector(counter);		
	end process;

	-- Assign derived clocks based on counter bits
	clk_1hz			<= digital_counter(24);	-- Approximate 1Hz clock
	clk_4hz			<= digital_counter(22);	-- Approximate 4Hz clock
	sim_clk_enbl	<= digital_counter(4);	-- Faster clock enable for simulation
	sim_clk_blink	<= digital_counter(2);	-- Faster blink signal for simulation

	-- Clock extender: generates single-cycle enable pulses and blink control
	clk_extender: process (clkin)
	begin
		if (rising_edge(clkin))  then
			-- Reset mode
			if(reset ='1') then
				clk_reg_extend(1 downto 0) <= "00";
				blink_sig <= '0';

			-- Simulated mode: use faster clocks
			elsif(sim_mode) then
				clk_reg_extend(1 downto 0) 	<= clk_reg_extend(0) & sim_clk_enbl;
				blink_sig <= sim_clk_blink;
			
			-- Real mode: use slower hardware clocks
			else 
				clk_reg_extend(1 downto 0) 	<= clk_reg_extend(0) & clk_1hz ;
				blink_sig <= clk_4hz;
				END IF;
			end if;
	end process;

	-- Output assignments
	sm_clken <= clk_reg_extend(0) AND (NOT(clk_reg_extend(1)));	-- Pulse when clock rising edge occurs
	blink <= blink_sig;											-- Output blink signal
end rtl;