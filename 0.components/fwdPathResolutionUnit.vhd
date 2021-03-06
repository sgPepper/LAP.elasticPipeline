-----------------------------------------  fwd path resolution unit
---------------------------------------------------------------------
-- the Dependancy Resolution Unit solves data hasards by selecting 
-- the correct memory bypass , receiving the read address and all 
-- the previous pending write addresses.
-- Uses a valid signal to make sur the received addresses are valid, 
-- but sends no ready signal, since it should not be allowed to 
-- stall the execution
-- DATASIZE is the width of data buses used
-- INPUT_NB  is the number of data sources to select from, including 
-- the 2 registerFile outputs, the forwarding paths + mem bypass
--
-- NB : the forwarding paths only have a 'valid' control signal

library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;

entity forwardingUnit is
GENERIC ( 	DATASIZE 			: integer; 
			INPUT_NB 			: integer );
port(	readAdrB, readAdrA 		: in std_logic_vector(31 downto 0);
		wAdrArray 				: in vectorArray_t(INPUT_NB-1 downto 2)(31 downto 0);			-- (oldest(mem bypass) -> newest write addresses)
		adrValidArray			: in bitArray_t(INPUT_NB-1 downto 0);							-- (oldest(mem bypass) -> newest write addresses, readAdrB, readAdrA)
			
		inputArray 				: in vectorArray_t(INPUT_NB-1 DOWNTO 0)(DATASIZE-1 downto 0);	-- (oldest(mem bypass) -> newest instruction's results, operandB(RF), operandA(RF))
		inputValidArray 		: in bitArray_t(INPUT_NB-1 downto 0);							-- (oldest(mem bypass) -> newest instruction's results, operandB, operandA)
		outputArray				: out vectorArray_t(1 downto 0)(DATASIZE-1 downto 0);			-- (operandB, operandA)
		
		nReadyArray				: in bitArray_t(1 downto 0);									-- (operandB, operandA)
		validArray, readyArray	: out bitArray_t(1 downto 0)									-- (operandB, operandA)
);
end forwardingUnit;

architecture vanilla of forwardingUnit is
begin

	process(readAdrA, readAdrB, wAdrArray, adrValidArray, inputArray, inputValidArray, nReadyArray)
	begin
	-- By default, we forward the control signals, unless we resolve an adress where the fwd path has invalid data (cf later)
	readyArray(0) <= nReadyArray(0);
	readyArray(1) <= nReadyArray(1);
	
	-- by default, we pick the data from the register file for operandA and operandB
	outputArray(0) <= inputArray(0);
	validArray(0) <= inputValidArray(0);
	outputArray(1) <= inputArray(1);
	validArray(1) <= inputValidArray(1);
	
	-- but if any more recent result matches, we'll use it instead									
	-- order of exploration : oldest (mem bypass) to newest instructions			
	-- input(0) and input(1) are register file's operandA and operandB
	for i in INPUT_NB-1 downto 2 loop
		-- if A's address matches
		if readAdrA = X"00000000" then
			outputArray(0) <= inputArray(0);
			validArray(0) <= inputValidArray(0);
		elsif (readAdrA = wAdrArray(i) and adrValidArray(i)='1') then
			-- select the correct input   -   we select only if the adress is valid
			outputArray(0) <= inputArray(i);	
			-- forward its 'valid0' control signal
			validArray(0) <= inputValidArray(i) and adrValidArray(i);
			-- change the ready control signal if the fwd path doesn't provide valid data 	(fix for circuit problem)
			if (inputValidArray(i) and adrValidArray(i)) = '0' then
				readyArray(0) <= '0';
			end if;
		end if;
		-- if B's address matches
		if readAdrB = X"00000000" then
			outputArray(1) <= inputArray(1);
			validArray(1) <= inputValidArray(1);
		elsif (readAdrB=wAdrArray(i) and adrValidArray(i)='1') then
			-- select the correct input   -   we select only if the adress is valid
			outputArray(1) <= inputArray(i);	
			-- forward its 'valid0' control signal
			validArray(1) <= inputValidArray(i) and adrValidArray(i);
			-- change the ready control signal if the fwd path doesn't provide valid data 	(fix for circuit problem, hopefully)
			if (inputValidArray(i) and adrValidArray(i)) = '0' then
				readyArray(1) <= '0';
			end if;
		end if;
	end loop;
	end process;

end vanilla;  
