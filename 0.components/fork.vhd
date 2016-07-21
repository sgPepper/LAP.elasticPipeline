---------------------------------------------------------------  fork
---------------------------------------------------------------------
-- forks signals from one register controller to two other register
-- controllers
-- contains both implementations from "Cortadella elastic systems", 
-- paper 2, p3
library ieee;
use ieee.std_logic_1164.all;

entity fork is
port(	clk, reset,		-- the eager implementation uses registers
		p_valid,
		n_ready0, n_ready1 : in std_logic;
		ready, valid0, valid1 : out std_logic);
end fork;



architecture lazy of fork is
begin

	valid0 <= p_valid and n_ready0 and n_ready1;
	valid1 <= p_valid and n_ready0 and n_ready1;
	
	ready <= n_ready0 and n_ready1;
	
end lazy;



architecture eager of fork is
	signal fork_stop, block_stop0, block_stop1, n_stop0, n_stop1, temp : std_logic;
begin

	--can't combine the signals directly in the port map
	temp <=  p_valid and fork_stop;
	n_stop0 <= not n_ready0;
	n_stop1 <= not n_ready1;

	regBlock0 : entity work.eagerFork_RegisterBLock 
					port map(clk, reset, p_valid, n_stop0, temp, valid0, block_stop0);

	regBlock1 : entity work.eagerFork_RegisterBLock 
					port map(clk, reset, p_valid, n_stop0, temp, valid1, block_stop1);
					
	ready <= not (block_stop0 or block_stop1);
end eager;




--------------------------------------------  eagerFork_RegisterBLock
---------------------------------------------------------------------
-- this block contains the register and the combinatorial logic 
-- around it, as in the design in cortadella elastis systems (paper 2)
-- page 3
library ieee;
use ieee.std_logic_1164.all;

entity eagerFork_RegisterBLock is
port(	clk, reset, 
		p_valid, n_stop, 
		p_valid_and_fork_stop : in std_logic;
		valid, 	block_stop : out std_logic);
end eagerFork_RegisterBLock;

architecture eagerFork_RegisterBLock1 of eagerFork_RegisterBLock is
	signal reg_value, reg_in, block_stop_internal : std_logic;
begin
	
	block_stop_internal <= n_stop and reg_value;
	
	block_stop <= block_stop_internal;
	
	reg_in <= block_stop_internal or not p_valid_and_fork_stop;
	
	valid <= reg_value and p_valid; 
	
	reg : process(clk, reset)
	begin
		if(reset='1') then
			reg_value <= '0';
		else
			if(rising_edge(clk))then
				reg_value <= reg_in;
			end if;
		end if;
	end process reg;
	
end eagerFork_RegisterBLock1;