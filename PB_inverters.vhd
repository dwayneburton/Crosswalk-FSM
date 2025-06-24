-- Import standard logic library
library ieee;
use ieee.std_logic_1164.all;

-- Entity for push-button and reset signal inversion
-- Converts active-low push-button and reset signals to active-high for internal logic
entity PB_inverters is
  port (
    rst_n         : in std_logic;                     -- Active-low asynchronous reset input
    rst           : out std_logic;                    -- Active-high reset output
    pb_n_filtered : in std_logic_vector(3 downto 0);  -- Filtered active-low push button inputs
    pb            : out std_logic_vector(3 downto 0)  -- Active-high push button outputs
  ); 
end PB_inverters;

-- Architecture directly inverts all active-low inputs
architecture ckt of PB_inverters is
begin
  pb <= NOT(pb_n_filtered); -- Invert push button signals
  rst <= NOT(rst_n);        -- Invert reset signal
end ckt;