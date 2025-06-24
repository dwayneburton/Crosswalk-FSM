-- Import standard logic library
library ieee;
use ieee.std_logic_1164.all;

-- Entity for push-button and reset signal filtering
-- Implements a basic 3-cycle synchronizer/debouncer for active-low inputs
entity PB_filters is
	port (
		clkin			: in std_logic;						-- 50 MHz clock input
		rst_n			: in std_logic;						-- Active-low asynchronous reset input
		rst_n_filtered	: out std_logic;					-- Filtered reset signal
		pb_n			: in std_logic_vector (3 downto 0);	-- Active-low push button inputs
		pb_n_filtered	: out std_logic_vector(3 downto 0)	-- Filtered push button outputs					 
	); 
end PB_filters;

-- Architecture implements 3-cycle synchronizer chains for each input
architecture ckt of PB_filters is
	signal sreg0, sreg1, sreg2, sreg3, sreg4	: std_logic_vector(3 downto 0);	-- Shift registers for filtering

begin
	-- Filter process: samples button/reset inputs over time to debounce and synchronize
	process (clkin) is
	begin
		-- Shift in new values each clock cycle
		if (rising_edge(clkin)) then
			sreg4(3 downto 0) <= sreg4(2 downto 0) & rst_n;		-- Reset synchronizer
			sreg3(3 downto 0) <= sreg3(2 downto 0) & pb_n(3);	-- PB3 synchronizer
			sreg2(3 downto 0) <= sreg2(2 downto 0) & pb_n(2);	-- PB2 synchronizer
			sreg1(3 downto 0) <= sreg1(2 downto 0) & pb_n(1);	-- PB1 synchronizer
			sreg0(3 downto 0) <= sreg0(2 downto 0) & pb_n(0);	-- PB0 synchronizer
		end if;

		-- Output filtered signals based on majority of recent samples (OR used for active-low inputs)
		rst_n_filtered <= sreg4(3) OR sreg4(2) OR sreg4(1);
		pb_n_filtered(3) <= sreg3(3) OR sreg3(2) OR sreg3(1);
		pb_n_filtered(2) <= sreg2(3) OR sreg2(2) OR sreg2(1);
		pb_n_filtered(1) <= sreg1(3) OR sreg1(2) OR sreg1(1);
		pb_n_filtered(0) <= sreg0(3) OR sreg0(2) OR sreg0(1);
	end process;
end ckt;