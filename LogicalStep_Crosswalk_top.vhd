-- Import standard logic and numeric libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Top-level module for the LogicalStep Lab 4 project
-- Integrates push-button filtering, clock generation, traffic control, and 7-segment display output
entity LogicalStep_Crosswalk_top is
	port (
		clkin_50	: in std_logic;						-- 50 MHz base clock input
		rst_n		: in std_logic;						-- Active-low asynchronous reset
		pb_n		: in std_logic_vector(3 downto 0);	-- Active-low push button inputs
		sw			: in std_logic_vector(7 downto 0);	-- Slide switch inputs (unused here)
		leds		: out std_logic_vector(7 downto 0);	-- LED outputs for status and debug
		seg7_data	: out std_logic_vector(6 downto 0);	-- 7-segment segment control
		seg7_char1	: out std_logic;					-- Digit select for first 7-segment
		seg7_char2	: out std_logic						-- Digit select for second 7-segment
	);
end entity;

-- Architecture connecting clock, logic, and display subsystems
architecture SimpleCircuit of LogicalStep_Crosswalk_top is
	-- Component: 2-digit 7-segment display multiplexer
	component segment7_mux
		port (
			clk		: in std_logic := '0';
			DIN2	: in std_logic_vector(6 downto 0);
			DIN1	: in std_logic_vector(6 downto 0);
			DOUT	: out std_logic_vector(6 downto 0);
			DIG2	: out std_logic;
			DIG1	: out std_logic
		);
	end component;

	-- Component: Configurable clock generator (1 Hz + 4 Hz)
	component clock_generator
		port (
			sim_mode	: in boolean;
			reset		: in std_logic;
			clkin		: in std_logic;
			sm_clken	: out std_logic;
			blink		: out std_logic
		);
	end component;

	-- Component: Push button input filter
	component PB_filters
		port (
			clkin				: in std_logic;
			rst_n				: in std_logic;
			rst_n_filtered		: out std_logic;
			pb_n				: in std_logic_vector(3 downto 0);
			pb_n_filtered		: out std_logic_vector(3 downto 0)
		);
	end component;

	-- Component: Inverts active-low buttons/reset
	component pb_inverters
		port (
			rst_n			: in std_logic;
			rst				: out std_logic;
			pb_n_filtered	: in std_logic_vector(3 downto 0);
			pb				: out std_logic_vector(3 downto 0)
		);
	end component;

	-- Component: Input synchronizer (2-stage flip-flop)
	component synchronizer
		port (
			clk		: in std_logic;
			reset	: in std_logic;
			din		: in std_logic;
			dout	: out std_logic
		);
	end component;

	-- Component: Edge-sensitive holding register (latches request until cleared)
	component holding_register
		port (
			clk			 : in std_logic;
			reset		 : in std_logic;
			register_clr : in std_logic;
			din			 : in std_logic;
			dout		 : out std_logic
		);
	end component;

	-- Component: 16-state traffic light controller FSM
	component traffic_light_controller
		port (
			clk, reset							: in std_logic;
			CLKSM, blink						: in std_logic;
			NS_pending, EW_pending				: in std_logic;
			NS_A, NS_G, NS_D, EW_A, EW_G, EW_D	: out std_logic;
			NS_crossing, EW_crossing			: out std_logic;
			NS_clear, EW_clear					: out std_logic;
			STATE								: out std_logic_vector(7 downto 4)
		);
	end component;

	-- Internal Signals
	constant sim_mode 							: boolean := FALSE;	-- Set TRUE for simulation, FALSE for board use
	signal rst, rst_n_filtered, synch_rst		: std_logic;
	signal sm_clken, blink_sig					: std_logic;
	signal pb, pb_n_filtered					: std_logic_vector(3 downto 0);
	signal NS_synchronized, EW_synchronized		: std_logic;
	signal NS_traffic_light, EW_traffic_light	: std_logic_vector(6 downto 0);
	signal NS_A, NS_G, NS_D						: std_logic;
	signal EW_A, EW_G, EW_D						: std_logic;
	signal NS_clear, EW_clear					: std_logic;
	signal NS_pending, EW_pending				: std_logic;

begin
	-- Map pending requests to LEDs
	leds(1) <= NS_pending;
	leds(3) <= EW_pending;

	-- Encode traffic light states into 7-segment format
	NS_traffic_light <= NS_G & "00" & NS_D & "00" & NS_A;
	EW_traffic_light <= EW_G & "00" & EW_D & "00" & EW_A;

	-- Component Instantiations
	INST0: PB_filters port map (clkin_50, rst_n, rst_n_filtered, pb_n, pb_n_filtered);	-- Debounce push buttons and reset
	INST1: pb_inverters port map (rst_n_filtered, rst, pb_n_filtered, pb);				-- Invert active-low inputs

	-- Synchronize asynchronous reset and buttons
	INST2: synchronizer port map (clkin_50, synch_rst, rst, synch_rst);
	INST3: synchronizer port map (clkin_50, synch_rst, pb(0), NS_synchronized);
	INST4: synchronizer port map (clkin_50, synch_rst, pb(1), EW_synchronized);

	INST5: clock_generator port map (sim_mode, synch_rst, clkin_50, sm_clken, blink_sig);																														-- Generate enable and blink clocks
	INST6: holding_register port map (clkin_50, synch_rst, NS_clear, NS_synchronized, NS_pending);																												-- Latch pending walk requests until acknowledged
	INST7: holding_register port map (clkin_50, synch_rst, EW_clear, EW_synchronized, EW_pending);
	INST8: traffic_light_controller port map (clkin_50, synch_rst, sm_clken, blink_sig, NS_pending, EW_pending, NS_A, NS_G, NS_D, EW_A, EW_G, EW_D, leds(0), leds(2), NS_clear, EW_clear, leds(7 downto 4));	-- Traffic light FSM
	INST9: segment7_mux port map (clkin_50, NS_traffic_light, EW_traffic_light, seg7_data, seg7_char2, seg7_char1);																								-- 7-segment multiplexer display for NS/EW lights
end architecture;
