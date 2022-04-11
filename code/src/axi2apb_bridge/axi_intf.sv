`timescale 1ns / 1ps
//import axi_vip_pkg::*;
interface axi_intf(input logic aclk, aresetn);

	typedef axi_vip_master_pkg::axi_vip_master_mst_t axi_mst_agent_t;

	localparam ADDR_W   = axi_vip_master_pkg::axi_vip_master_VIP_ADDR_WIDTH;
	localparam DATA_W   = axi_vip_master_pkg::axi_vip_master_VIP_DATA_WIDTH;
	
	typedef logic [ADDR_W-1:0]   axi_addr_t;
	typedef logic [DATA_W-1:0]   axi_data_t;


	typedef enum logic [1:0] {
		AXI_RESP_OKAY   = 2'b00,
		AXI_RESP_EXOKAY = 2'b01,
		AXI_RESP_SLVERR = 2'b10,
		AXI_RESP_DECERR = 2'b11
	} axi_resp_t;


	axi_addr_t   axi_awaddr;
	logic        axi_awvalid;
	logic        axi_awready;
	axi_data_t   axi_wdata;
	logic        axi_wvalid;
	logic        axi_wready;
	axi_resp_t   axi_bresp;
	logic        axi_bvalid;
	logic        axi_bready;
	axi_addr_t   axi_araddr;
	logic        axi_arvalid;
	logic        axi_arready;
	axi_data_t   axi_rdata;
	axi_resp_t   axi_rresp;
	logic        axi_rvalid;
	logic        axi_rready;


  clocking axi_master_cb @(posedge aclk);
	default input #1step output #1ns;
    output axi_awaddr;
    output axi_awvalid; 
	input axi_awready;
    output axi_wdata, axi_wvalid; 
	input axi_wready;
    input  axi_bresp, axi_bvalid; 
	output axi_bready;
    output axi_araddr;
    output axi_arvalid; 
	input axi_arready;
    input  axi_rdata, axi_rresp, axi_rvalid; 
	output axi_rready;
  endclocking


  clocking axi_monitor_cb @(posedge aclk);
	default input #1step output #1ns;
    input  axi_awaddr;
    input  axi_awvalid, axi_awready;
    input  axi_wdata, axi_wvalid, axi_wready;
    input  axi_bresp, axi_bvalid, axi_bready;
    input  axi_araddr;
    input  axi_arvalid, axi_arready;
    input  axi_rdata, axi_rresp, axi_rvalid, axi_rready;
  endclocking

///////////// SVA //////////// 

/////******************************************************************************\\\\\
 //assert property (@(posedge aclk) ( !axi_wvalid &&  axi_wready |=> (axi_wdata != 32'h0) && axi_wvalid));
 WDATA_CHECK: cover property (@(posedge aclk) ( !axi_wvalid &&  axi_wready |=> (axi_wdata != 32'h0) && axi_wvalid));

 //assert property (@(posedge aclk) (axi_awvalid && !axi_awready |=> $stable(axi_awaddr)));
 AWADDR_CHECK: cover property (@(posedge aclk) (axi_awvalid && !axi_awready |=> $stable(axi_awaddr)));
 
 //assert property (@(posedge aclk) ( !axi_bvalid &&  axi_bready |=> axi_bvalid));
 BVALID_CHECK: cover property (@(posedge aclk) ( !axi_bvalid &&  axi_bready |=> axi_bvalid));
 
 //assert property (@(posedge aclk) ( !axi_rvalid &&  axi_rready |=> axi_rvalid));
 RVALID_CHECK: cover property (@(posedge aclk) ( !axi_rvalid &&  axi_rready |=> axi_rvalid));
 
 //assert property (@(posedge aclk) ($onehot(axi_arvalid) && (axi_arready || !axi_arready) |=> $stable(axi_araddr) ##1 !$stable(axi_araddr)));
 ARADDR_CHECK:cover property (@(posedge aclk) ($onehot(axi_arvalid) && (axi_arready || !axi_arready) |=> $stable(axi_araddr) ##1 !$stable(axi_araddr)));
 
 //assert property (@(posedge aclk) ( !axi_rvalid && axi_rready |=> $stable(axi_rdata) ##1 !$stable(axi_rdata)));
 RDATA_CHECK: cover property (@(posedge aclk) ( !axi_rvalid && axi_rready |=> $stable(axi_rdata) ##1 !$stable(axi_rdata)));


// Check whether ready and valid signals are registered when reset high
	property IS_VALID(signal);
		@(posedge aclk)
			aresetn -> !$isunknown(signal);
	endproperty: IS_VALID
	
ARVALID_CHECK: 	   assert property (IS_VALID(axi_arvalid));	
cov_ARVALID_CHECK: cover property (IS_VALID(axi_arvalid));	
AWVALID_CHECK: 	   assert property (IS_VALID(axi_awvalid));	
cov_AWVALID_CHECK: cover property (IS_VALID(axi_awvalid));
ARREADY_CHECK: 	   assert property (IS_VALID(axi_arready));	
cov_ARREADY_CHECK: cover property (IS_VALID(axi_arready));
AWREADY_CHECK: 	   assert property (IS_VALID(axi_awready));	
cov_AWREADY_CHECK: cover property (IS_VALID(axi_awready));
	
	
/////******************************************************************************\\\\\
// Check whether the necesseary signals are assrted before write and read transactions
// ( wready=wvalid=1 -> sel=en=write=1 -> bvalid=bready=1 ) and (arready=arvalid=1 -> sel=en=1 write=0  -> rvalid=rready=1)
  sequence wdata_received;
   $onehot(axi_wready) and $onehot(axi_wvalid);
  endsequence 
  
  sequence wenable_received;
   $onehot(tb.dut.M_APB_PSEL) and $onehot(tb.dut.M_APB_PENABLE) and $onehot(tb.dut.M_APB_PWRITE);
  endsequence 
  
  sequence rdata_received;
   $onehot(axi_arready) and $onehot(axi_arvalid);
  endsequence 
  
  sequence renable_received;
   $onehot(tb.dut.M_APB_PSEL) and $onehot(tb.dut.M_APB_PENABLE) and $onehot(!tb.dut.M_APB_PWRITE);
  endsequence 
  

   property axiapb_read_write(setup_r_w, access_r_w, valid, ready);
	@(posedge aclk) disable iff (aresetn) 
	setup_r_w |-> ##[1:$] access_r_w ##1 valid and ready;
   endproperty: axiapb_read_write
   
//WRITE_CHECK:     assert property(axiapb_read_write(wdata_received, wenable_received, axi_bvalid, axi_bready));
cov_WRITE_CHECK: cover property (axiapb_read_write(wdata_received, wenable_received, axi_bvalid, axi_bready));

//READ_CHECK:     assert property(axiapb_read_write(rdata_received, renable_received, axi_rvalid, axi_rready));
cov_READ_CHECK: cover property (axiapb_read_write(rdata_received, renable_received, axi_rvalid, axi_rready));



/////******************************************************************************\\\\\
// Check when valid is high, the read or write address is registered
   property axiapb_valid_check(valid, addr);
	@(posedge aclk) disable iff (aresetn) 
	$onehot(valid) |-> !$stable(addr) and addr != 32'h00000000 ;
   endproperty: axiapb_valid_check
   
//WRITE_ADDR_CHECK:    	 assert property(axiapb_valid_check(axi_awvalid, axi_awaddr ));
cov_WRITE_ADDR_CHECK:    cover property(axiapb_valid_check(axi_awvalid, axi_awaddr ));

//READ_ADDR_CHECK:    	 assert property(axiapb_valid_check(axi_arvalid, axi_araddr ));
cov_READ_ADDR_CHECK:    cover property(axiapb_valid_check(axi_arvalid, axi_araddr ));


/*
/////******************************************************************************\\\\\
 //address 2**32 olduğu için görmek çok zor
// check whether awaddr = apbaddr 
   property awaddr_apbaddr_check(idx);
	@(posedge aclk) disable iff (!aresetn) 
	$rose(axi_awvalid) && axi_awaddr inside{idx}|-> ##[1:$]  (axi_awaddr inside{idx} == tb.dut.M_APB_PADDR inside{idx}) && 
		$rose(tb.dut.M_APB_PWRITE);// |-> ##[1:$] $rose(tb.dut.M_APB_PREADY);// ##1 $fell(tb.dut.M_APB_PREADY)  ;
   endproperty: awaddr_apbaddr_check   
   
 // check whether araddr = apbaddr   
   property araddr_apbaddr_check(idx);
	@(posedge aclk) disable iff (!aresetn) 
	$rose(axi_arvalid) && axi_araddr inside{idx}|-> ##[1:$]  (axi_araddr inside{idx} == tb.dut.M_APB_PADDR inside{idx}) && 
		$rose(!tb.dut.M_APB_PWRITE);// |-> ##[1:$] $rose(tb.dut.M_APB_PREADY);// ##1 $fell(tb.dut.M_APB_PREADY)  ;
   endproperty: araddr_apbaddr_check 
   
   // check whether apb_prdata = axi_rdata   
   property prdata_rdata_check(idx);
	@(posedge aclk) disable iff (!aresetn) 
	$rose(tb.dut.M_APB_PREADY) && tb.dut.M_APB_PRDATA inside{idx} |-> ##[1:$]  (tb.dut.M_APB_PRDATA inside{idx} == axi_rdata inside{idx}) && 
		$rose(axi_rvalid) && $rose(!tb.dut.M_APB_PREADY);
   endproperty: prdata_rdata_check   
   
   // check whether wdata = apb_pwdata   
   property wdata_apb_pwdata_check(idx);
	@(posedge aclk) disable iff (!aresetn) 
	$rose(axi_wvalid) && axi_wdata inside{idx} |-> ##[1:$]  (tb.dut.M_APB_PWDATA inside{idx} == axi_wdata inside{idx}) && 
		$rose(tb.dut.M_APB_PWRITE) && $rose(tb.dut.M_APB_PSEL);
   endproperty: wdata_apb_pwdata_check
   

    generate 
		for (genvar i=1; i<2**10; i++) 
			begin 
			cov_awaddr_apbaddr_CHECK:   cover property(awaddr_apbaddr_check(i)); 
			i_awaddr_apbaddr_CHECK:       assert property(awaddr_apbaddr_check(i)); 			
			cov_araddr_apbaddr_CHECK:   cover property(araddr_apbaddr_check(i)); 
			i_araddr_apbaddr_CHECK:       assert property(araddr_apbaddr_check(i)); 			
			cov_prdata_rdata_CHECK:     cover property(prdata_rdata_check(i)); 
			i_prdata_rdata_CHECK:    		assert property(prdata_rdata_check(i));			
			cov_wdata_apb_pwdata_CHECK: cover property(wdata_apb_pwdata_check(i)); 
			i_wdata_apb_pwdata_CHECK:     assert property(wdata_apb_pwdata_check(i)); 
			end 
	  
	endgenerate

*/

endinterface