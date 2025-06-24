-- Import standard logic and numeric libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Entity for a 16-state traffic light controller with pedestrian crossing
-- Handles walk requests and blinking signals for both NS and EW directions
entity traffic_light_controller is
	port (
		clk, reset				 	: in std_logic;						-- Clock and reset inputs
		CLKSM, blink			 	: in std_logic;						-- Clock enable and blinking clock
		NS_pending, EW_pending		: in std_logic;						-- Walk request inputs for NS and EW
		NS_A, NS_G, NS_D			: out std_logic;					-- NS Amber, Green, Don't Walk LEDs
		EW_A, EW_G, EW_D			: out std_logic;					-- EW Amber, Green, Don't Walk LEDs
		NS_crossing, EW_crossing	: out std_logic;					-- Crossing allowed indicators
		NS_clear, EW_clear			: out std_logic;					-- Pending signal clear indicators
		STATE						: out std_logic_vector(7 downto 4)	-- Binary-encoded state number
	);
end entity;

-- Architecture implementing the traffic light controller FSM
architecture SM of traffic_light_controller is
	-- Define all state names
	type STATE_NAMES is (S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15);
	signal current_state, next_state : STATE_NAMES;	-- FSM state signals

begin
	-- FSM register: updates current state based on CLKSM
	Register_Section: process (clk)
	begin
		if (rising_edge(clk)) then
			if (reset = '1') then
				current_state <= S0;
			elsif (CLKSM = '1') then
				current_state <= next_State;
			end if;
		end if;
	end process;

	-- FSM transition logic: determines next state based on current state and pending requests
	Transition_Section: process (current_state, NS_pending, EW_pending) 
	begin
		case current_state is
        	when S0 =>		
				if (NS_pending = '0' and EW_pending = '1') then
					next_state <= S6;
				else
					next_state <= S1;
				end if;
			
			when S1 =>		
				if (NS_pending = '0' and EW_pending = '1') then
					next_state <= S6;
				else
					next_state <= S2;
				end if;

			when S2 => next_state <= S3;
			when S3 => next_state <= S4;
			when S4 => next_state <= S5;
			when S5 => next_state <= S6;
			when S6 => next_state <= S7;
			when S7 => next_state <= S8;
			
			when S8 =>
				if (NS_pending = '1' and EW_pending = '0') then
					next_state <= S14;
				else
					next_state <= S9;
				end if;
					
			when s9 =>
				if (NS_pending = '1' and EW_pending = '0') then
					next_state <= S14;
				else
					next_state <= S10;
				end if;

			when S10 => next_state <= S11;
			when S11 => next_state <= S12;
			when S12 => next_state <= S13;
			when S13 => next_state <= S14;
			when S14 => next_state <= S15;
			when others => next_state <= S0;
		end case;
	end process;

	-- FSM output decoder: sets light and crossing signals based on current state
	Decoder_Section: process (current_state) 
	begin
		case current_state is
			-- NS walk flashing, EW red
			when S0 | S1 =>
				NS_A <= '0'; NS_G <= '0'; NS_D <= blink;
				EW_A <= '1'; EW_G <= '0'; EW_D <= '0';
				NS_crossing <= '0'; EW_crossing <= '0';
				NS_clear <= '0'; EW_clear <= '0';
				STATE <= "000" & std_logic(to_integer(current_state) mod 2);

			-- NS walk solid, EW red
			when S2 | S3 | S4 | S5 =>
				NS_A <= '0'; NS_G <= '0'; NS_D <= '1';
				EW_A <= '1'; EW_G <= '0'; EW_D <= '0';
				NS_crossing <= '1'; EW_crossing <= '0';
				NS_clear <= '0'; EW_clear <= '0';
				STATE <= std_logic_vector(to_unsigned(to_integer(current_state), 4));

			-- NS green, EW red
			when S6 | S7 =>
				NS_A <= '0'; NS_G <= '1'; NS_D <= '0';
				EW_A <= '1'; EW_G <= '0'; EW_D <= '0';
				NS_crossing <= '0'; EW_crossing <= '0';
				NS_clear <= '1' when current_state = S6 else '0';
				EW_clear <= '0';
				STATE <= std_logic_vector(to_unsigned(to_integer(current_state), 4));

			-- NS amber, EW flashing
			when S8 | S9 =>
				NS_A <= '1'; NS_G <= '0'; NS_D <= '0';
				EW_A <= '0'; EW_G <= '0'; EW_D <= blink;
				NS_crossing <= '0'; EW_crossing <= '0';
				NS_clear <= '0'; EW_clear <= '0';
				STATE <= std_logic_vector(to_unsigned(to_integer(current_state), 4));

			-- NS amber, EW solid walk
			when S10 | S11 | S12 | S13 =>
				NS_A <= '1'; NS_G <= '0'; NS_D <= '0';
				EW_A <= '0'; EW_G <= '0'; EW_D <= '1';
				NS_crossing <= '0'; EW_crossing <= '1';
				NS_clear <= '0'; EW_clear <= '0';
				STATE <= std_logic_vector(to_unsigned(to_integer(current_state), 4));

			-- NS amber, EW green
			when S14 =>
				NS_A <= '1'; NS_G <= '0'; NS_D <= '0';
				EW_A <= '0'; EW_G <= '1'; EW_D <= '0';
				NS_crossing <= '0'; EW_crossing <= '0';
				NS_clear <= '0'; EW_clear <= '1';
				STATE <= "1110";

			-- NS amber, EW green hold
			when S15 =>
				NS_A <= '1'; NS_G <= '0'; NS_D <= '0';
				EW_A <= '0'; EW_G <= '1'; EW_D <= '0';
				NS_crossing <= '0'; EW_crossing <= '0';
				NS_clear <= '0'; EW_clear <= '0';
				STATE <= "1111";
		end case;
	end process;
end architecture SM;