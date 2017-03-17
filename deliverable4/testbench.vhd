library ieee;
use ieee.std_logic_1164.all;

entity testbench is
end testbench;

architecture behaviour of testbench is

	component ifprocess is
		generic(
			ram_size : integer := 4096;
             		clock_period : time : 1 ns
		);
   		port (
			clock : in std_logic;
          		reset : in std_logic := '0';
          		insert_stall : in std_logic := '0';
          		BranchAddr : in std_logic_vector (31 downto 0);
          		Branch_taken : in std_logic := '0';
          		next_addr : out std_logic_vector (31 downto 0);
          		inst : out std_logic_vector (31 downto 0)
		);
  	end component;
  
  	component ID is
    		generic(
			register_size : integer := 32
		);
   		port (
			clk: in  std_logic;
          		--hazard_detect: in std_logic;   -- stall the instruction when hazard_detect is 1 
          		instruction_addr: in  std_logic_vector(31 downto 0);
          		IR_in: in  std_logic_vector(31 downto 0);
          		writeback_register_address: in  std_Logic_vector(4 downto 0);
          		writeback_register_content: in  std_logic_vector(31 downto 0);
          		ex_state_buffer: in std_logic_vector(10 downto 0);
          		instruction_addr_out: out std_logic_vector(31 downto 0);
          		jump_addr: out std_logic_vector(25 downto 0);
          		rs:  out std_logic_vector(31 downto 0);
          		rt:  out  std_logic_vector(31 downto 0);
          		--rd_addr: out std_logic_vector(4 downto 0);
          		des_addr: out std_logic_vector(4 downto 0);
          		signExtImm: out  std_logic_vector(31 downto 0);
          		insert_stall: out std_logic;
          		EX_control_buffer: out std_logic_vector(10 downto 0);
          		MEM_control_buffer: out std_logic_vector(5 downto 0);
          		WB_control_buffer: out std_logic_vector(5 downto 0);
          		funct_out: out std_logic_vector(5 downto 0);
          		opcode_out: out  std_logic_vector(5 downto 0);
          		write_reg_txt: in std_logic:='0'
		);

	component EX is
		PORT( 
              		clk: in  std_logic;
              		-- from id stage 
              		instruction_addr_in: in std_logic_vector(31 downto 0);
              		jump_addr : in std_logic_vector( 25 downto 0);
              		rs:  in std_logic_vector(31 downto 0);
              		rt:  in  std_logic_vector(31 downto 0);  
              		des_addr: in std_logic_vector(4 downto 0);
              		signExtImm: in  std_logic_vector(31 downto 0);
              		EX_control_buffer: in std_logic_vector(10 downto 0); --  for ex stage provide information for forward and harzard detect, first bit for mem_read, 9-5 for rt, 4-0 for rs
              		MEM_control_buffer: in std_logic_vector(5 downto 0); --  for mem stage, provide info for forward and hazard detect, first bit for wb_signal, 4-0 for des_adr
              		WB_control_buffer: in std_logic_vector(5 downto 0); --  for mem stage, provide info for forward and hazard detect, first bit for wb_signal, 4-0 for des_adr
              		opcode_in: in  std_logic_vector(5 downto 0);
              		funct_in: in std_logic_vector(5 downto 0) ;
              
             		-- from mem stage
             		MEM_control_buffer_before: in std_logic_vector(5 downto 0); --control buffer from last instruction which is in mem stage now
             		-- MEM_result: in std_logic_vector(31 downto 0); -- if last inst is load word, its data from mem
             		-- last_opcode : in std_logic_vector(5 downto 0);  -- opcode of last instruction
           
              		-- from wb stage
              		WB_control_buffer_before: in std_logic_vector(5 downto 0); --control buffer from the one before last instruction which is in wb stage now
              		writeback_data: in std_logic_vector(31 downto 0); -- data for forwarding of last last instruction
       
              		-- for mem stage 
	      		branch_addr: out std_logic_vector(31 downto 0);
              		bran_taken: out std_logic;
              		opcode_out: out std_logic_vector(5 downto 0);
              		des_addr_out: out std_logic_vector(4 downto 0);
              		ALU_result: out std_logic_vector(31 downto 0);
              		rt_data: out std_logic_vector(31 downto 0);
              		MEM_control_buffer_out: out std_logic_vector(5 downto 0); --  for mem stage, provide info for forward and hazard detect, first bit for wb_signal, 4-0 for des_adr
              		WB_control_buffer_out: out std_logic_vector(5 downto 0); --  for mem stage, provide info for forward and hazard detect, first bit for wb_signal, 4-0 for des_adr
             		-- for id stage 
	      		EX_control_buffer_out: out std_logic_vector(10 downto 0) --  for ex stage provide information for forward and harzard detect, first bit for mem_read, 9-5 for rt, 4-0 for rs
		);
	end component;

  	component ALU is
    		port (
			clk : in std_logic;
          		ALU_opcode : in std_logic_vector(3 downto 0);
          		data0, data1 : in std_logic_vector(31 downto 0);
          		result: out std_logic_vector(31 downto 0); 
          		HI : out std_logic_vector(31 downto 0);
          		LO : out std_logic_vector(31 downto 0);
          		zero : out std_logic);
  	end component;
  
  	component ALU_control is
    		port(
			opCode : in std_logic_vector(5 downto 0);
         		funct : in std_logic_vector(5 downto 0);
         		ALU_out : out std_logic_vector(3 downto 0));
  	end component;



---------------------------------------------------------------------------------
	signal clock : std_logic;
 	signal reset : std_logic;
	signal insert_stall : std_logic := '0';
	signal branch_addr : std_logic_vector (31 downto 0);
	signal branch_taken : std_logic := '0';
	signal inst_addr : std_logic_vector (31 downto 0);
        signal inst : std_logic_vector (31 downto 0);

	signal opcode: std_logic_vector(5 downto 0);
	signal rs: std_logic_vector(31 downto 0);
	signal rt: std_logic_vector(31 downto 0);
	signal des_addr: std_logic_vector(4 downto 0);
	signal funct: std_logic_vector(5 downto 0);
	signal signExtImm: std_logic_vector(31 downto 0);
	signal jump_addr: std_logic_vector (25 downto 0);

	signal EX_control_buffer: std_logic_vector(10 downto 0);
	signal MEM_control_buffer: std_logic_vector(5 downto 0);
	signal WB_control_buffer: std_logic_vector(5 downto 0);
	signal ALU_result: std_logic_vector(31 downto 0);
	--signal rt_data: std_logic_vector(31 downto 0);

	signal writeback_register_address: std_Logic_vector(4 downto 0); -- is des_addr??
	signal writeback_data: std_logic_vector(31 downto 0);



	signal programend: std_logic := '0';

--------------------------------------------------------------------
begin
  
fetch : ifprocess
generic map (
	ram_size => 4096,
        clock_period => 1 ns
	)
port map (
	clock => clock,
        reset => reset,
        insert_stall => insert_stall,
        BranchAddr => branch_addr,
        Branch_taken => branch_taken,
        next_addr => inst_addr,
        inst =>  inst
	);
    
decode : ID
generic map (
	register_size => 32
	) 
port map (
	clk => clock,
        instruction _addr => inst_addr,
        IR_in => inst,
        	writeback_register_address => ,
       	writeback_register_content => writeback_data, -- in
              	ex_state_buffer => ,
	instruction_addr_out => inst_addr,
        jump_addr => jump_addr,
        rs => rs,
        rt => rt,
        des_addr => des_addr,
        signExtImm => signExtImm,
        insert_stall => insert_stall,  
        EX_control_buffer => EX_control_buffer,
        MEM_control_buffer => MEM_control_buffer,
        WB_control_buffer => WB_control_buffer,
        funct_out => funct,
        opcode_out => opcode,
        write_reg_txt => programend,
              );
execute: EX
port map (
	clk => clock,
	instruction_addr_in => inst_addr,
	jump_addr => jump_addr,
	rs => rs,
	rt => rt,
	des_addr => des_addr,
	signExtImm => signExtImm,
	EX_control_buffer => EX_control_buffer,
	MEM_control_buffer => MEM_control_buffer,
	WB_control_buffer => WB_control_buffer,
	opcode_in => opcode,
	funct_in => funct,
		MEM_control_buffer_before => , --in
		WB_control_buffer_before => , --in
	writeback_data => writeback_data, --in
	branch_addr => branch_addr, -- ??
	bran_taken => branch_taken,
	opcode_out => opcode,
	des_addr_out => des_addr,
	ALU_result => ALU_result,
		rt_data => ,
		MEM_control_buffer_out =>
		WB_control_buffer_out =>
		EX_control_buffer_out => EX_control_buffer,
	
	
	
	
);

memory: DataMem
port map (
	
);



end behaviour;
