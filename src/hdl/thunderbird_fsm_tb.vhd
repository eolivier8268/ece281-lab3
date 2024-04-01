--+----------------------------------------------------------------------------
--| 
--| COPYRIGHT 2017 United States Air Force Academy All rights reserved.
--| 
--| United States Air Force Academy     __  _______ ___    _________ 
--| Dept of Electrical &               / / / / ___//   |  / ____/   |
--| Computer Engineering              / / / /\__ \/ /| | / /_  / /| |
--| 2354 Fairchild Drive Ste 2F6     / /_/ /___/ / ___ |/ __/ / ___ |
--| USAF Academy, CO 80840           \____//____/_/  |_/_/   /_/  |_|
--| 
--| ---------------------------------------------------------------------------
--|
--| FILENAME      : thunderbird_fsm_tb.vhd (TEST BENCH)
--| AUTHOR(S)     : Capt Phillip Warner
--| CREATED       : 03/2017
--| DESCRIPTION   : This file tests the thunderbird_fsm modules.
--|
--|
--+----------------------------------------------------------------------------
--|
--| REQUIRED FILES :
--|
--|    Libraries : ieee
--|    Packages  : std_logic_1164, numeric_std
--|    Files     : thunderbird_fsm_enumerated.vhd, thunderbird_fsm_binary.vhd, 
--|				   or thunderbird_fsm_onehot.vhd
--|
--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  
entity thunderbird_fsm_tb is
end thunderbird_fsm_tb;

architecture test_bench of thunderbird_fsm_tb is 
	
	component thunderbird_fsm is 
	  port(
          i_clk, i_reset  : in    std_logic;
          i_left, i_right : in    std_logic;
          o_lights_L      : out   std_logic_vector(2 downto 0);
          o_lights_R      : out   std_logic_vector(2 downto 0)		
	  );
	end component thunderbird_fsm;

	-- test I/O signals
	signal w_left  : std_logic := '0';
	signal w_right : std_logic := '0';
	signal w_reset : std_logic := '0';
	signal w_clk : std_logic := '0';
	signal w_taillights : std_logic_vector(5 downto 0) := "000000";
	
	-- constants
	constant k_clk_period : time := 10 ns;
	
begin
	-- PORT MAPS ----------------------------------------
	uut: thunderbird_fsm port map (
	   i_clk => w_clk,
       i_reset => w_reset,
       i_left => w_left,
       i_right => w_right,
       o_lights_L(2) => w_taillights(5),
       o_lights_L(1) => w_taillights(4),
       o_lights_L(0) => w_taillights(3),
       o_lights_R(2) => w_taillights(2),
       o_lights_R(1) => w_taillights(1),
       o_lights_R(0) => w_taillights(0)
       
	);
	-----------------------------------------------------
	
	-- PROCESSES ----------------------------------------	
    -- Clock process ------------------------------------
	clk_proc : process
    begin
        w_clk <= '0';
        wait for k_clk_period/2;
        w_clk <= '1';
        wait for k_clk_period/2;
    end process;    
	-----------------------------------------------------
	
	-- Test Plan Process --------------------------------
	sim_proc: process
    begin
        -- test that on reset, all the lights turn off
        w_reset <= '1';
        wait for k_clk_period;
            assert w_taillights ="000000" report "bad reset" severity failure;
        -- switch off the reset input, and wait for one clock cycle
        w_reset <= '0';
        wait for k_clk_period; 
        
        -- test hazards: enable and test for four clock cycles
        -- should be on -> off -> on -> off
        w_reset <= '1'; wait for k_clk_period; w_reset <= '0' ;
        w_left <= '1'; w_right <= '1'; wait for k_clk_period;
            assert w_taillights = "111111" report "lights should be on one cycle after enabling hazards" severity failure;
        wait for k_clk_period;
            assert w_taillights = "000000" report "lights should be off two cycles after enabling hazards" severity failure;
        wait for k_clk_period;
            assert w_taillights = "111111" report "lights should be on three cycles after enabling hazards" severity failure;
        wait for k_clk_period;
            assert w_taillights = "000000" report "lights should be off four cycles after enabling hazards" severity failure;
        -- disable hazards and ensure lights stay off
        w_left <= '0'; w_right <= '0'; wait for k_clk_period;
            assert w_taillights = "000000" report "lights should be off after disabling hazards" severity failure;
        
        -- enable hazards, stop when on, ensure lights turn off, and ensure stay off
        w_reset <= '1'; wait for k_clk_period; w_reset <= '0' ;
        w_left <= '1'; w_right <= '1'; wait for k_clk_period;
        w_left <= '0'; w_right <= '0'; wait for k_clk_period;
            assert w_taillights = "000000" report "lights should turn off after disabling hazards" severity failure;
        wait for k_clk_period;
            assert w_taillights = "000000" report "lights should turn off after disabling hazards" severity failure;
        
        -- test each state for the left blinker
        w_reset <= '1'; wait for k_clk_period; w_reset <= '0' ;
        w_left <= '1'; wait for k_clk_period;
            assert w_taillights = "001000" report "state L1 is incorrect" severity failure;
        wait for k_clk_period;
            assert w_taillights = "011000" report "state L2 is incorrect" severity failure;
        wait for k_clk_period;
            assert w_taillights = "111000" report "state L3 is incorrect" severity failure;
        wait for k_clk_period;
            assert w_taillights = "000000" report "taillights don't turn off after 3 cycles" severity failure;
        w_left <= '0';
        
        -- test each state for the right blinker
        w_reset <= '1'; wait for k_clk_period; w_reset <= '0' ;
        w_right <= '1'; wait for k_clk_period;
            assert w_taillights = "000100" report "state R1 is incorrect" severity failure;
        wait for k_clk_period;
            assert w_taillights = "000110" report "state R2 is incorrect" severity failure;
        wait for k_clk_period;
            assert w_taillights = "000111" report "state R3 is incorrect" severity failure;
        wait for k_clk_period;
            assert w_taillights = "000000" report "taillights don't turn off after 3 cycles" severity failure;
        w_right <= '0';
        
        -- test that the left blinker cycles is left on
        w_reset <= '1'; wait for k_clk_period; w_reset <= '0' ;
        w_left <= '1'; wait for  5*k_clk_period;
            assert w_taillights = "001000" report "left taillights do not cycle if kept enabled" severity failure;
        wait for k_clk_period;
            assert w_taillights = "011000" report "left taillights do not cycle if kept enabled" severity failure;
        wait for k_clk_period;
            assert w_taillights = "111000" report "left taillights do not cycle if kept enabled" severity failure;
        w_left <= '0'; wait for k_clk_period;
            assert w_taillights = "000000" report "left taillights do not cycle if kept enabled" severity failure;
        
        -- test that the right blinker cycles if left on
        w_reset <= '1'; wait for k_clk_period; w_reset <= '0' ;
        w_right <= '1'; wait for  5*k_clk_period;
            assert w_taillights = "000100" report "right taillights do not cycle if kept enabled" severity failure;
        wait for k_clk_period;
            assert w_taillights = "000110" report "right taillights do not cycle if kept enabled" severity failure;
        wait for k_clk_period;
            assert w_taillights = "000111" report "right taillights do not cycle if kept enabled" severity failure;
        w_right <= '0'; wait for k_clk_period;
            assert w_taillights = "000000" report "right taillights do not cycle if kept enabled" severity failure;          
        
        -- test the reset from each state
        -- State 6: ON/hazards
        w_left <= '1'; w_right <= '1'; wait for k_clk_period;
            w_reset <= '1'; wait for k_clk_period;
            assert w_taillights = "000000" report "reset does not work on hazards" severity failure;
            w_left <= '0'; w_right <= '0'; w_reset <= '0';
        -- State 2: L1/one left blinker
        w_left <= '1'; wait for k_clk_period;
            w_reset <= '1'; wait for k_clk_period;
            assert w_taillights = "000000" report "reset does not work on L1" severity failure;
            w_left <= '0'; w_reset <= '0';
        -- State 1: L2/two left blinkers
        w_left <= '1'; wait for 2*k_clk_period;
            w_reset <= '1'; wait for k_clk_period;
            assert w_taillights = "000000" report "reset does not work on L2" severity failure;
            w_left <= '0'; w_reset <= '0';
        -- State 0: L3/three left blinkers
        w_left <= '1'; wait for 3*k_clk_period;
            w_reset <= '1'; wait for k_clk_period;
            assert w_taillights = "000000" report "reset does not work on L3" severity failure;
            w_left <= '0'; wait for k_clk_period; 
            w_reset <= '0';
        -- State 5: R1/one right blinker
        w_right <= '1'; wait for k_clk_period;
            w_reset <= '1'; wait for k_clk_period;
            assert w_taillights = "000000" report "reset does not work on R1" severity failure;
            w_right <= '0'; w_reset <= '0';
        -- State 4: R2/two right blinkers
        w_right <= '1'; wait for 2*k_clk_period;
            w_reset <= '1'; wait for k_clk_period;
            assert w_taillights = "000000" report "reset does not work on R2" severity failure;
            w_right <= '0'; w_reset <= '0';
        -- State 3: R2/three right blinkers
        w_right <= '1'; wait for 3*k_clk_period;
            w_reset <= '1'; wait for k_clk_period;
            assert w_taillights = "000000" report "reset does not work on R2" severity failure;
            w_right <= '0'; w_reset <= '0';

        -- test edge case: left blinker toggled off while still running
        w_reset <= '1'; wait for k_clk_period; w_reset <= '0' ;
        w_left <= '1'; wait for k_clk_period;
            assert w_taillights = "001000" report "state L1 is incorrect" severity failure;
        w_left <= '0'; wait for k_clk_period;
            assert w_taillights = "011000" report "state L2 is incorrect for interrupted signal" severity failure;
        wait for k_clk_period;
            assert w_taillights = "111000" report "state L3 is incorrect for interrupted signal" severity failure;
        wait for k_clk_period;
            assert w_taillights = "000000" report "blinker does not turn off interrupted signal" severity failure;
        
        -- test edge case: right blinker toggled off while still running
        w_reset <= '1'; wait for k_clk_period; w_reset <= '0' ;
        w_right <= '1'; wait for k_clk_period;
            assert w_taillights = "000100" report "state R1 is incorrect" severity failure;
        w_right <= '0'; wait for k_clk_period;
            assert w_taillights = "000110" report "state R2 is incorrect for interrupted signal" severity failure;
        wait for k_clk_period;
            assert w_taillights = "000111" report "state R3 is incorrect for interrupted signal" severity failure;
        wait for k_clk_period;
            assert w_taillights = "000000" report "blinker does not turn off interrupted signal" severity failure;
            
        -- test edge case: second blinker toggled on while the first is running
        w_reset <= '1'; wait for k_clk_period; w_reset <= '0' ;
        w_left <= '1'; wait for k_clk_period;
            assert w_taillights = "001000" report "state L1 is incorrect" severity failure;
        w_right <= '1'; wait for k_clk_period;
            assert w_taillights = "011000" report "state L2 is incorrect for interrupted signal" severity failure;
        wait for k_clk_period;
            assert w_taillights = "111000" report "state L3 is incorrect for interrupted signal" severity failure;
        wait for k_clk_period;
            assert w_taillights = "000000" report "blinker does not turn off for interrupted signal" severity failure;
        wait for k_clk_period;
            assert w_taillights = "111111" report "hazards do not work for interrupted signal" severity failure;
                    
        -- test edge case: one blinker is toggled when in hazard/on state
        w_reset <= '1'; w_left <= '0'; w_right <= '0'; wait for k_clk_period; 
        w_reset <= '0';
        w_left <= '1'; w_right <= '1'; 
            wait for k_clk_period;
        w_left <= '0'; wait for k_clk_period;
            assert w_taillights = "000000" report "hazards do not toggle off" severity failure;
        wait for k_clk_period;
            assert w_taillights = "000100" report "right blinkers do not toggle after hazards" severity failure;
        wait for 3*k_clk_period;
            assert w_taillights = "000000" report "right blinkers do not toggle after hazards" severity failure;
            w_right <= '0';
        
        -- test edge case: blinkers are "flipped"
        w_reset <= '1'; wait for k_clk_period; w_reset <= '0' ;
        w_left <= '1'; wait for k_clk_period;
            assert w_taillights = "001000" report "state L1 is incorrect" severity failure;
        w_right <= '1'; w_left <= '0'; wait for k_clk_period;
            assert w_taillights = "011000" report "state L2 is incorrect for interrupted signal" severity failure;
        wait for 2*k_clk_period;
            assert w_taillights = "000000" report "blinker does not turn off for interrupted signal" severity failure;
        wait for k_clk_period;
            assert w_taillights = "000100" report "blinker does not flip for interrupted signal" severity failure;
        wait for 2*k_clk_period;
            assert w_taillights = "000111" report "blinker does not flip for interrupted signal" severity failure;
        
        w_reset <= '1'; w_right <= '0'; wait for k_clk_period; 
        w_reset <= '0' ;
        
        wait;
    end process;
	-----------------------------------------------------	
	
end test_bench;
