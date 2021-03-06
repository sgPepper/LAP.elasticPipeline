------------------------------------------------------------  ATC_reg
---------------------------------------------------------------------
-- a single single flip-flop for the shift register we'll use 
-- in the antitoken channel
library ieee;
use ieee.std_logic_1164.all;

entity antitokenChannel_reg is 
port(	clk, reset,
		antitoken, wrenable,
		isInsertionSpot,
		d_in : in std_logic;
		d_out : out std_logic);
end antitokenChannel_reg;

architecture antitokenChannel_reg1 of antitokenChannel_reg is
	signal d_in_internal : std_logic;
begin

	-- if we're at the spot matching for $latency, we use the antitoken 
	-- as input signal. Else, we will use the previous reg's output
	d_in_internal <= d_in when isInsertionSpot='0' else antitoken;	
		
	holdValue : process(clk, reset, antitoken, isInsertionSpot, d_in, wrenable)
	begin
		if(reset='1')then
			d_out <= '0';
		else
			if(rising_edge(clk))then
				if(wrenable='1') then
					d_out <= d_in_internal;
				end if;
			end if;
		end if;
	end process;

end antitokenChannel_reg1;




--------------------------------------------------  ATC_shiftRegister
---------------------------------------------------------------------
-- a shift register composed of the register units described below
-- contains 8 registers -> up to a latency 7 antitoken
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity antitokenChannel_shiftRegister is
port(	clk, reset,
		enableShift,
		antiToken : in std_logic;
		wantedLatency : in std_logic_vector(2 downto 0);
		vector_out : out std_logic_vector(7 downto 0);									--debug
		timeout : out std_logic);
end antitokenChannel_shiftRegister;

architecture antitokenChannel_shiftRegister1 of antitokenChannel_shiftRegister is
	signal tokenInsertionSpot : std_logic_vector(7 downto 0); 
	-- we could possible add one more register with the same size for wantedLatency
	-- since having a 'latency 0' antitoken channel is useless (and mokes no sense)
	signal d_in_internal : std_logic_vector(6 downto 0);
begin

	vector_out <= tokenInsertionSpot;													--debug
	
	-- computes the tokenInsertionSport vector by translating the 3bits integer 
	-- wantedLatency into a single select bit on the channel matching the integer
	internalSignals : process(clk, reset, wantedLatency)
	begin
		if(reset='1')then
			tokenInsertionSpot <= (others => '0');
		else
			tokenInsertionSpot <= (others => '0');
			tokenInsertionSpot(conv_integer(wantedLatency)-1) <= '1';
		end if;
	end process;

	-- 8 chained registers instanciation	
	reg0 : entity work.antitokenChannel_reg port map(clk, reset, antiToken, enableShift, 
														tokenInsertionSpot(0), d_in_internal(0), timeout);
	genShiftRegister : for i in 1 to 6 generate
		internalReg : entity work.antitokenChannel_reg port map(clk, reset, antiToken, enableShift, 	
													tokenInsertionSpot(i), d_in_internal(i), d_in_internal(i-1));
	end generate genShiftRegister;
	reg7 : entity work.antitokenChannel_reg port map(clk, reset, antiToken, enableShift, 
															tokenInsertionSpot(7), '0', d_in_internal(6));
	
end antitokenChannel_shiftRegister1;




---------------------------------------------------   ATC_enableBlock
---------------------------------------------------------------------
-- computes in a simple combinatorial way when to enable the shift 
-- register (when a piece of data flows through the channel OR when
-- an antitoken timedout and the previous register has valid data)
library ieee;
use ieee.std_logic_1164.all;

entity ATC_enableBlock is
port(	timeout, p_valid, n_ready : in std_logic;
		enable : out std_logic);
end ATC_enableBlock;

architecture ATC_enableBlock1 of ATC_enableBlock is
begin
	enable <= (timeout and p_valid) or (not timeout and (p_valid and n_ready));	
end ATC_enableBlock1;





--------------------------------------------------   antiTokenChannel
---------------------------------------------------------------------
-- implements the anti-tokens functionality by discarding the p_valid 
-- signal on the channel
-- then countdown and multiple tokens is implemented as follows : 
-- 	1. each token is represented by a 1 in a shift register
--  2. $latency determines in which register new tokens are inserted
-- 	3. registers shift at each clock, discard data when '1' in last
-- NB : $latency should not be changed once the component is instanciated 
--		it only exists to implement channels with different latencies 
--
-- 				cf. paper for much easier understanding
library ieee;
use ieee.std_logic_1164.all;

entity antitokenChannel is
port( 	clk, reset,
		antiT,
		p_valid, n_ready : in std_logic;
		wantedLatency : in std_logic_vector(2 downto 0);
		valid, ready : out std_logic);
end antitokenChannel;

architecture invertedClock of antitokenChannel is 
	signal tokenTimeOut : std_logic;
	signal enableShift : std_logic;
	signal notClock : std_logic;
begin

	--an inverted clock signal so that the shift register loads/shifts on falling clk
	notClock <= not clk;

	-- computes Wether we will shift or not a this clock cycle
	enabler : entity work.ATC_enableBlock(ATC_enableBlock1) 
		port map(tokenTimeOut, p_valid, n_ready, enableShift);
	
	-- shift register that permits latency countdown and multiple tokens 
	--shiftReg : entity work.antitokenChannel_shiftRegister port map(clk, reset, enableShift, antiT, wantedLatency, tokenTimeout);		--debug	
	shiftReg : entity work.antitokenChannel_shiftRegister 
		port map(notClock, reset, enableShift, antiT, wantedLatency,open, tokenTimeout);		--debug	
	
	-- signals mapping (cf paper doc)
	valid <= '0' when tokenTimeOut='1' else p_valid;	
	ready <= '1' when tokenTimeOut='1' else n_ready;

	-- reset via signal mapping to shift register
end invertedClock;

architecture antitokenChannel1 of antitokenChannel is 
	signal tokenTimeOut : std_logic;
	signal enableShift : std_logic;
begin

	-- computes Wether we will shift or not a this clock cycle
	enabler : entity work.ATC_enableBlock(ATC_enableBlock1) 
		port map(tokenTimeOut, p_valid, n_ready, enableShift);
	
	-- shift register that permits latency countdown and multiple tokens 
	--shiftReg : entity work.antitokenChannel_shiftRegister port map(clk, reset, enableShift, antiT, wantedLatency, tokenTimeout);		--debug	
	shiftReg : entity work.antitokenChannel_shiftRegister 
		port map(clk, reset, enableShift, antiT, wantedLatency,open, tokenTimeout);		--debug	
	
	-- signals mapping (cf paper doc)
	valid <= '0' when tokenTimeOut='1' else p_valid;	
	ready <= '1' when tokenTimeOut='1' else n_ready;

	-- reset via signal mapping to shift register
end antitokenChannel1;
