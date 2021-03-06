--------------------------------------------------  OP unit's operations
------------------------------------------------------------------------
-- regroups all operations used in the OP unit, as well as 
-- simpler blocks used in said operations


-----------------------------------------------------------   Multiplier 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity multiplier is 
	port(
		a : in std_logic_vector(31 downto 0);
		b : in std_logic_vector(31 downto 0);
		res : out std_logic_vector(31 downto 0);
		overflow : out std_logic);
end multiplier;

architecture multiplier1 of multiplier is	
	signal res_temp : std_logic_vector (63 downto 0);
begin
	res_temp <= std_logic_vector(unsigned(a) * unsigned(b));
	res <= res_temp(31 downto 0);
	overflow <= '0' when res_temp(63 downto 32) = X"00000000" else '1';	
end multiplier1;

----------------------------------------------------------------   Adder
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity adder is
	port (
		a : in std_logic_vector(31 downto 0);
		b : in std_logic_vector(31 downto 0);
		res : out std_logic_vector(31 downto 0);
		carry : out std_logic);
end adder;

architecture adder1 of adder is
	signal temp_res : std_logic_vector(32 downto 0);
begin
	
	temp_res <= ('0' & a) + ('0' & b);
	
	res <= temp_res(31 downto 0);
	carry <= temp_res(32);
	
end adder1;




------------------------------------------------------------------------
-- this is the "immediate addition" operation
-- implemented as an "operation" block with elastic control signals
-- integrates the "join" block for its arguments
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;

entity op0 is 
port(
	clk, reset : in std_logic;
	a, b : in std_logic_vector(31 downto 0);
	res : out std_logic_vector(31 downto 0);
	pValid, nReady : in std_logic;
	ready, valid : out std_logic);
end op0;

------------------------------------------------------------------------
-- simple version with no buffers - ctl signals are forwarded through
-- joining arguments' control signals is now done in the OP unit, once 
-- for all operations
------------------------------------------------------------------------
architecture forwarding of op0 is
begin

	-- control signals are forwarded
	ready <= nReady;
	valid <= pValid;
	
	addArgs : entity work.adder 
			port map (a, b, res, open); --leave the carry open

end forwarding;

------------------------------------------------------------------------
-- delay added artificially : result now goes through 1 elastic buffer
-- joining arguments' control signals is now done in the OP unit, once 
-- for all operations
------------------------------------------------------------------------
architecture delay1 of op0 is
	signal tempResult : std_logic_vector(31 downto 0);
begin

	addArgs : entity work.adder 
			port map (a, b, tempResult, open); --leave the carry open
			
	eb : entity work.elasticBuffer(vanilla) generic map(32)
			port map(	clk, reset,
						tempResult, res,
						pValid, nReady,
						ready, valid);						
end delay1;

------------------------------------------------------------------------
-- delay added artificially : result now goes through 3 buffers
-- (delay channel of size 3)
-- joining arguments' control signals is now done in the OP unit, once 
-- for all operations
------------------------------------------------------------------------
architecture delay3 of op0 is
	signal tempResult : std_logic_vector(31 downto 0);
	signal channelOut : vectorArray_t(3 downto 0)(31 downto 0);
	signal channelValidArray : bitArray_t(3 downto 0);
begin

	addArgs : entity work.adder 
			port map (a, b, tempResult, open); --leave the carry open
	
	-- control signals are transmitted via the delayChannel		
	dc3 : entity work.delayChannel(vanilla) generic map(32, 3)
			port map(	clk, reset,
						tempResult,
						channelOut,
						channelValidArray,
						pValid, nReady,
						ready);
	
	res <= channelOut(3);
	valid <= channelValidArray(3);
						
end delay3;




------------------------------------------------------------------------
-- another "operation" block with elastic control signals
-- integrates the "join" block for its arguments
-- this a   (a,b) -> a*(a+b)
-- joining arguments' control signals is now done in the OP unit, once 
-- for all operations
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;

entity op1 is 
port(
	clk, reset : in std_logic;
	a, b : in std_logic_vector(31 downto 0);
	result : out std_logic_vector(31 downto 0);
	pValid, nReady : in std_logic;
	ready, valid : out std_logic);
end op1;

------------------------------------------------------------------------
-- simple version with no buffers - ctl signals are forwarded through
------------------------------------------------------------------------
architecture forwarding of op1 is
	signal tempRes : std_logic_vector(31 downto 0);
begin

	-- forwarding control signals
	ready <= nReady;
	valid <= pValid;
			
	-- calculating result
	addArgs : entity work.adder 
			port map(a, b, tempRes, open);
	multArgs : entity work.multiplier	
			port map(a, tempRes, result, open);
	
end forwarding;
