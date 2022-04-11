`timescale 1ns / 1ps

`include "axi_intf.sv"
`include "apb_intf.sv"
`include "apb_slave.sv"
`include "axi_master.sv"
import axi_trans::*;
typedef axi_vip_master_pkg::axi_vip_master_mst_t axi_mst_agent_t;

module tb();

	localparam ADDR_W   = axi_vip_master_pkg::axi_vip_master_VIP_ADDR_WIDTH;
	localparam DATA_W   = axi_vip_master_pkg::axi_vip_master_VIP_DATA_WIDTH;


	// AXI clock, reset and interface signals
	bit aclk;
	always #5ns aclk = ~aclk;

	bit aresetn;
	initial begin
				repeat (20) #10;
				#2ns;
				aresetn <= 1'b0;
				#1ns;
				aresetn <= 1'b1;
	end

	axi_intf i_intf_axi(aclk,aresetn);
	apb_intf i_intf_apb(aclk,aresetn);
	
	
	//////AXI VIP Master/////
	axi_vip_master axi_mst (
		.aclk           (aclk),
		.aresetn        (aresetn),
		.m_axi_awaddr   (i_intf_axi.axi_awaddr),
		.m_axi_awvalid  (i_intf_axi.axi_awvalid),
		.m_axi_awready  (i_intf_axi.axi_awready),
		.m_axi_wdata    (i_intf_axi.axi_wdata),
		.m_axi_wvalid   (i_intf_axi.axi_wvalid),
		.m_axi_wready   (i_intf_axi.axi_wready),
		.m_axi_bresp    (i_intf_axi.axi_bresp),
		.m_axi_bvalid   (i_intf_axi.axi_bvalid),
		.m_axi_bready   (i_intf_axi.axi_bready),
		.m_axi_araddr   (i_intf_axi.axi_araddr),
		.m_axi_arvalid  (i_intf_axi.axi_arvalid),
		.m_axi_arready  (i_intf_axi.axi_arready),
		.m_axi_rdata    (i_intf_axi.axi_rdata),
		.m_axi_rresp    (i_intf_axi.axi_rresp),
		.m_axi_rvalid   (i_intf_axi.axi_rvalid),
		.m_axi_rready   (i_intf_axi.axi_rready)
		
	);


	//////DUT////////
	axi2apb_bridge #(
		.DATA_WIDTH (DATA_W),
		.ADDR_WIDTH (ADDR_W)
	) dut (
		.S_AXI_ACLK     (aclk),
		.S_AXI_ARESETN  (aresetn),
		
		.S_AXI_AWADDR   (i_intf_axi.axi_awaddr[ADDR_W-1:0]),
		.S_AXI_AWVALID  (i_intf_axi.axi_awvalid),
		.S_AXI_AWREADY  (i_intf_axi.axi_awready),
		
		.S_AXI_WDATA    (i_intf_axi.axi_wdata[DATA_W-1:0]),
		.S_AXI_WVALID   (i_intf_axi.axi_wvalid),
		.S_AXI_WREADY   (i_intf_axi.axi_wready),
		
		.S_AXI_BRESP    (i_intf_axi.axi_bresp[1:0]),
		.S_AXI_BVALID   (i_intf_axi.axi_bvalid),
		.S_AXI_BREADY   (i_intf_axi.axi_bready),
		
		.S_AXI_ARADDR   (i_intf_axi.axi_araddr[ADDR_W-1:0]),
		.S_AXI_ARVALID  (i_intf_axi.axi_arvalid),
		.S_AXI_ARREADY  (i_intf_axi.axi_arready),
		
		.S_AXI_RDATA    (i_intf_axi.axi_rdata[DATA_W-1:0]),
		.S_AXI_RRESP    (i_intf_axi.axi_rresp[1:0]),    
		.S_AXI_RVALID   (i_intf_axi.axi_rvalid),
		.S_AXI_RREADY   (i_intf_axi.axi_rready),
		
		.M_APB_PADDR    (i_intf_apb.paddr[ADDR_W-1:0]),  
		.M_APB_PSEL     (i_intf_apb.psel),   
		.M_APB_PENABLE  (i_intf_apb.penable),
		.M_APB_PWRITE   (i_intf_apb.pwrite), 
		.M_APB_PWDATA   (i_intf_apb.pwdata[DATA_W-1:0]), 
		.M_APB_PREADY   (i_intf_apb.pready), 			
		.M_APB_PRDATA   (i_intf_apb.prdata[DATA_W-1:0]), 
		.M_APB_PSLVERR  (i_intf_apb.pslverr) 			
			
	);

	axi_mst_agent_t axi_mst_agent;

	mailbox axitoapb = new();
	
	axi_master mst;
	apb_slave_driver slv;

	initial begin
		
		mst   = new(i_intf_axi);
		slv   = new(i_intf_apb);
				
		mst.axitoapb = axitoapb;
		slv.axitoapb = axitoapb;
		
		mst.init_agent();
		
		@(posedge aclk); 
			fork
				mst.run();
				slv.run();
				
			join

	end

endmodule
