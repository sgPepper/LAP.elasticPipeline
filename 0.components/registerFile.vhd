---------------------------------------------------------- Register File
------------------------------------------------------------------------
-- the register file used in the circuit. 
-- Few notes on how it works :
--	- control signals for read adresses and read data are directly 
--		forwarded through the register since both reads are independant 
-- 		from one another. join is done in the OPunit, if/where both 
--		arguments are required
--	- control signals for adrW, wrData use a join (and no output)
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.customTypes.all;

entity registerFile is port(
	clk, reset : in std_logic;
	adrB, adrA, adrW, wrData : in std_logic_vector(31 downto 0);
	pValidArray : in bitArray_t(3 downto 0); -- adrB, adrA, adrW, wrData
	nReadyArray : in bitArray_t(1 downto 0); -- b, a
	
	a, b  : out std_logic_vector(31 downto 0);	
	readyArray : out bitArray_t(3 downto 0); -- adrB, adrA, adrW, wrData
	validArray : out bitArray_t(1 downto 0)	 -- b, a
);
end registerFile;








------------------------------------------------------------------------
-- version with basic elastic control signals
------------------------------------------------------------------------
-- NB : we assume the buffer is always ready, hence the "1" into 
-- the wrJoin, since we use synchronous buffers
------------------------------------------------------------------------
architecture elastic of registerFile is 
		-- array initialized to '0' vectors
	signal reg : register_t := (others => (others => '0'));
		-- signals needed for the writes' join
	signal wrJoin_ready : std_logic; -- out of the join
begin
	
	-- reads and their control signals
	a <= reg(to_integer(unsigned(adrA)));
	b <= reg(to_integer(unsigned(adrB)));
	validArray(1) <= pValidArray(3); -- we suppose the reads happen instantly, so we just forward the control signals
	validArray(0) <= pValidArray(2);
	readyArray(3) <= nReadyArray(1);
	readyArray(2) <= nReadyArray(0);
	
	-- joins the write adress' and the write data's elastic control signals
	wrJoin : entity work.joinN(vanilla) generic map(2) 
			port map(	pValidArray(1 downto 0), 
						'1', -- we can write once per clock cycle
						wrJoin_ready,
						readyArray(1 downto 0));
	
	-- writes and resets
	writes : process(reset, clk, adrW, pValidArray)
	begin
		if(reset='1')then
			reg <= (others => (others => '0'));
		else
			if(rising_edge(clk))then
				if(wrJoin_ready='1')then
					reg(to_integer(unsigned(adrW))) <= wrData;
				end if;
			end if;
		end if;
	end process writes;

end elastic;
