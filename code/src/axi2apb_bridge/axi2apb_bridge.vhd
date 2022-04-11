library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity axi2apb_bridge is
  generic (
    ADDR_WIDTH    : integer:= 32;
    DATA_WIDTH    : integer:= 32
    );
  port (
  -- AXI Signals
    CLK       		 : in  std_logic; --CLK
    RST    			 : in  std_logic; --RST -> senkron active high
    
    S_AXI_ARADDR     : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    S_AXI_ARVALID    : in  std_logic;
    S_AXI_ARREADY    : out std_logic;
    
    S_AXI_RDATA      : out std_logic_vector(DATA_WIDTH-1 downto 0);
    S_AXI_RRESP      : out std_logic_vector(1 downto 0);
    S_AXI_RVALID     : out std_logic;
    S_AXI_RREADY     : in  std_logic;
    
    S_AXI_AWADDR     : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    S_AXI_AWVALID    : in  std_logic;
    S_AXI_AWREADY    : out std_logic;
   
    S_AXI_WDATA      : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    S_AXI_WVALID     : in  std_logic;
    S_AXI_WREADY     : out std_logic;
    
    S_AXI_BRESP      : out std_logic_vector(1 downto 0);
    S_AXI_BVALID     : out std_logic;
    S_AXI_BREADY     : in  std_logic;
	
  -- APB Signals 
    M_APB_PADDR      : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    M_APB_PSEL       : out std_logic;
    M_APB_PENABLE    : out std_logic;
    M_APB_PWRITE     : out std_logic;
    M_APB_PWDATA     : out std_logic_vector(DATA_WIDTH-1 downto 0);
    M_APB_PREADY     : in std_logic;
    M_APB_PRDATA     : in std_logic_vector(DATA_WIDTH-1 downto 0);
    M_APB_PSLVERR    : in std_logic
  
   );
end axi2apb_bridge;

architecture RTL of axi2apb_bridge is


	type fsm_state is (
					  IDLE_STATE                  ,    
					  WRITE_ADDRESS_RECEIVED_STATE,    
					  WRITE_DATA_RECEIVED_STATE   ,    
					  PENABLE_WRITE_SIGNAL        ,    
					  WDATA_TRANSFERRED_STATE     ,    
					  READ_ADDRESS_RECEIVED_STATE ,    
					  PENABLE_READ_SIGNAL         ,    
					  RDATA_TRANSFERRED_STATE          
		  
		  );
	signal present_state    : fsm_state;
	signal next_state       : fsm_state;

										
	--sampled address and datas
	signal sampled_address :std_logic_vector(31 downto 0);                                                       
	signal sampled_wdata   :std_logic_vector(31 downto 0);



begin

	--State transition
	process(CLK)
	begin
		if ( rising_edge(CLK)) then
		  if(RST = '1') then
			present_state         <= IDLE_STATE;
		  else 
			present_state         <= next_state;
		  end if;
		end if;
	end process;


	process(present_state, S_AXI_ARVALID, S_AXI_AWVALID, S_AXI_WVALID, S_AXI_RREADY, S_AXI_BREADY, M_APB_PREADY)
	begin

	  case present_state is
		when IDLE_STATE =>
			if (S_AXI_ARVALID = '1' and S_AXI_AWVALID = '0' ) then
				next_state <= READ_ADDRESS_RECEIVED_STATE;
			elsif (S_AXI_ARVALID = '0' and S_AXI_AWVALID = '1' ) then
				 next_state <= WRITE_ADDRESS_RECEIVED_STATE;
			elsif (S_AXI_ARVALID = '1' and S_AXI_AWVALID = '1' ) then  --give priority to read cycle
				next_state <= READ_ADDRESS_RECEIVED_STATE;
			else 
				 next_state <= IDLE_STATE;
			end if;
		

		when WRITE_ADDRESS_RECEIVED_STATE =>	
			if (S_AXI_WVALID = '0') then
				next_state <= WRITE_ADDRESS_RECEIVED_STATE;
			else
				next_state <= WRITE_DATA_RECEIVED_STATE;
			end if;

		
		when WRITE_DATA_RECEIVED_STATE =>
			next_state <= PENABLE_WRITE_SIGNAL;
	 
		
		when PENABLE_WRITE_SIGNAL =>
			if (M_APB_PREADY = '1') then
				next_state <= WDATA_TRANSFERRED_STATE;
			else
				next_state <= PENABLE_WRITE_SIGNAL;
			end if; 

		
		when WDATA_TRANSFERRED_STATE =>
			if (S_AXI_BREADY = '1') then
				next_state <= IDLE_STATE;
			else
				next_state <= WDATA_TRANSFERRED_STATE;
			end if;

		
		when READ_ADDRESS_RECEIVED_STATE =>
			next_state <= PENABLE_READ_SIGNAL; 
		

		when PENABLE_READ_SIGNAL =>
			if (M_APB_PREADY = '1') then
				next_state <= RDATA_TRANSFERRED_STATE;
			else
				next_state <= PENABLE_READ_SIGNAL;
			end if;
		
		
		when RDATA_TRANSFERRED_STATE => 
			if (S_AXI_RREADY = '1') then
				next_state <= IDLE_STATE;
			else
				next_state <= RDATA_TRANSFERRED_STATE;
			end if;
			
		end case;
	 end process;
	 
	 
	 
	 
	process(present_state, S_AXI_ARVALID, S_AXI_AWVALID, S_AXI_WVALID, S_AXI_RREADY, S_AXI_BREADY, M_APB_PREADY)
	begin
		 S_AXI_ARREADY <= '0';
		 S_AXI_AWREADY <= '0';
		 S_AXI_RVALID  <= '0';
		 S_AXI_WREADY  <= '0';
		 S_AXI_BVALID  <= '0';
		 --APB outputs
		 M_APB_PSEL    <= '0';
		 M_APB_PENABLE <= '0';
		 M_APB_PWRITE  <= '0';

		 
		 case present_state is
			when IDLE_STATE =>
				S_AXI_ARREADY <= '0';
				S_AXI_AWREADY <= '0';
				S_AXI_RVALID  <= '0';
				S_AXI_WREADY  <= '0';
				S_AXI_BVALID  <= '0';
				--APB outputs
				M_APB_PSEL    <= '0';
				M_APB_PENABLE <= '0';
				M_APB_PWRITE  <= '0';
					
			when WRITE_ADDRESS_RECEIVED_STATE =>
				S_AXI_ARREADY <= '0';
				S_AXI_AWREADY <= '1';
				S_AXI_RVALID  <= '0';
				S_AXI_WREADY  <= '1';
				S_AXI_BVALID  <= '0';
				--APB outputs
				M_APB_PSEL    <= '0';
				M_APB_PENABLE <= '0';
				M_APB_PWRITE  <= '0'; 
				
			 when WRITE_DATA_RECEIVED_STATE =>
				S_AXI_ARREADY <= '0';
				S_AXI_AWREADY <= '0';
				S_AXI_RVALID  <= '0';
				S_AXI_WREADY  <= '0';
				S_AXI_BVALID  <= '0';
				--APB outputs
				M_APB_PSEL    <= '1';
				M_APB_PENABLE <= '0';
				M_APB_PWRITE  <= '1';
				
			 when PENABLE_WRITE_SIGNAL =>
				S_AXI_ARREADY <= '0';
				S_AXI_AWREADY <= '0';
				S_AXI_RVALID  <= '0';
				S_AXI_WREADY  <= '0';
				S_AXI_BVALID  <= '0';
				--APB outputs
				M_APB_PSEL    <= '1';
				M_APB_PENABLE <= '1';
				M_APB_PWRITE  <= '1';
				
			 when WDATA_TRANSFERRED_STATE =>----
				S_AXI_ARREADY <= '0';
				S_AXI_AWREADY <= '0';
				S_AXI_RVALID  <= '0';
				S_AXI_WREADY  <= '0';
				S_AXI_BVALID  <= '1';
				--APB outputs
				M_APB_PSEL    <= '0';
				M_APB_PENABLE <= '0';
				M_APB_PWRITE  <= '0';
				
			 when READ_ADDRESS_RECEIVED_STATE =>
				S_AXI_ARREADY <= '1';
				S_AXI_AWREADY <= '0';
				S_AXI_RVALID  <= '0';
				S_AXI_WREADY  <= '0';
				S_AXI_BVALID  <= '0';
				--APB outputs
				M_APB_PSEL    <= '1';
				M_APB_PENABLE <= '0';
				M_APB_PWRITE  <= '0';
				
			 when PENABLE_READ_SIGNAL =>
				S_AXI_ARREADY <= '0';
				S_AXI_AWREADY <= '0';
				S_AXI_RVALID  <= '0';
				S_AXI_WREADY  <= '0';
				S_AXI_BVALID  <= '0';
				--APB outputs
				M_APB_PSEL    <= '1';
				M_APB_PENABLE <= '1';
				M_APB_PWRITE  <= '0';
				
			 when RDATA_TRANSFERRED_STATE =>
				S_AXI_ARREADY <= '0';
				S_AXI_AWREADY <= '0';
				S_AXI_RVALID  <= '1';
				S_AXI_WREADY  <= '0';
				S_AXI_BVALID  <= '0';
				--APB outputs
				M_APB_PSEL    <= '0';
				M_APB_PENABLE <= '0';
				M_APB_PWRITE  <= '0'; 
		
		  end case;
	 end process;
		
		
	 process(CLK)
	 begin
		if(rising_edge(CLK)) then
			if(RST = '1') then
				sampled_address <= (others => '0');
			else 
				if( present_state = IDLE_STATE and S_AXI_ARVALID = '1') then
					sampled_address <= S_AXI_ARADDR;
				elsif( present_state = IDLE_STATE and S_AXI_AWVALID = '1') then
					sampled_address <= S_AXI_AWADDR;        
				else
					sampled_address <= sampled_address;
				end if;
			end if;
	   end if;
	 end process;
	  
	  
	process(CLK)
	 begin
		if(rising_edge(CLK)) then
			if(RST = '1') then
				sampled_wdata <= (others => '0');
			else 
				if((present_state = WRITE_ADDRESS_RECEIVED_STATE and S_AXI_WVALID = '1') or (present_state = WDATA_TRANSFERRED_STATE and S_AXI_WVALID = '1')) then
					sampled_wdata <= S_AXI_WDATA;
				else
					sampled_wdata<=sampled_wdata;
				end if;
			end if;
		end if;
	end process;     
		
	   
		
	process(CLK)
	 begin
		if(rising_edge(CLK)) then 
			if (RST = '1') then
				M_APB_PWDATA <= (others => '0');
				M_APB_PADDR  <= (others => '0');
			else
				if((present_state = WRITE_ADDRESS_RECEIVED_STATE and S_AXI_WVALID = '1') or (present_state = WDATA_TRANSFERRED_STATE and S_AXI_WVALID = '1')) then
					M_APB_PADDR <= sampled_address;
					M_APB_PWDATA <= S_AXI_WDATA;               
				elsif (present_state = IDLE_STATE and S_AXI_ARVALID = '1') then
					M_APB_PADDR <= S_AXI_ARADDR;
				elsif (present_state = RDATA_TRANSFERRED_STATE and  S_AXI_RREADY = '1') then
					M_APB_PADDR <= sampled_address;
				end if;
			end if;
		end if;     
	 end process;


	--error handling
	process(CLK)
	 begin
		if(rising_edge(CLK)) then
			if(RST = '1') then
				S_AXI_BRESP <= "00";
			else
				if( present_state = PENABLE_WRITE_SIGNAL and M_APB_PREADY = '1' ) then 
					if( M_APB_PSLVERR = '0') then
						S_AXI_BRESP <= "00";
					else
						S_AXI_BRESP <= "11";
					end if;
				end if;
			end if;
		end if;
	end process;
			
		
	process(CLK)
	 begin
		if(rising_edge(CLK)) then    
			if(RST = '1') then
				S_AXI_RDATA <= (others => '0');
			else 
				if(present_state = PENABLE_READ_SIGNAL and M_APB_PREADY = '1' and  M_APB_PSLVERR = '0' ) then
					S_AXI_RDATA <= M_APB_PRDATA;
				else
					S_AXI_RDATA <= (others => '0');
				end if;
			end if;
		end if;
		
	end process;


	process(CLK)
	 begin
		if(rising_edge(CLK)) then  
			if(RST = '1') then
			   S_AXI_RRESP <= "00";
			else
				if( present_state = PENABLE_READ_SIGNAL and M_APB_PREADY = '1' ) then
					if( M_APB_PSLVERR = '0' ) then
						S_AXI_RRESP <= "00";
					else
						S_AXI_RRESP <= "11";
					end if;
				end if;
			end if;
		end if;
	 end process;           
 

end RTL;
