`timescale 1ns / 1ps
`define axi_DRIV_IF axi_vif.axi_master_cb
`define axi_mst_INST tb.axi_mst.inst.IF
`define axi_cvg tb.i_intf_axi
//import axi_vip_pkg::*;
import axi_trans::*;

class axi_master;

	typedef axi_vip_master_pkg::axi_vip_master_mst_t axi_mst_agent_t;

	localparam ADDR_W   = axi_vip_master_pkg::axi_vip_master_VIP_ADDR_WIDTH;
	localparam DATA_W   = axi_vip_master_pkg::axi_vip_master_VIP_DATA_WIDTH;

	typedef logic [ADDR_W-1:0]   axi_addr_t;
	typedef logic [DATA_W-1:0]   axi_data_t;

	axi_mst_agent_t axi_mst_agent;

	mailbox axitoapb;
	virtual axi_intf axi_vif; 


	//////////  COVERGROUP /////////  
	  covergroup cg_axiapb @(`axi_DRIV_IF);
		awaddr:  coverpoint `axi_cvg.axi_awaddr;// { bins ada[]= {[1:1024]}; bins others = default; };									  
		araddr:  coverpoint `axi_cvg.axi_araddr;
		awvalid: coverpoint `axi_cvg.axi_awvalid;
		awready: coverpoint `axi_cvg.axi_awready;
		wready:  coverpoint `axi_cvg.axi_wready;
		wvalid:  coverpoint `axi_cvg.axi_wvalid;
		arvalid: coverpoint `axi_cvg.axi_arvalid;
		arready: coverpoint `axi_cvg.axi_arready;
		bvalid:  coverpoint `axi_cvg.axi_bvalid;
		bready:  coverpoint `axi_cvg.axi_bready;
		rvalid:  coverpoint `axi_cvg.axi_rvalid;
		rready:  coverpoint `axi_cvg.axi_rready;
		cross_arvalidXarready:  cross arvalid, arready;
		cross_awvalidXawready:  cross awvalid, awready;
		cross_wvalidXwready:    cross wready,  wvalid;
		cross_rvalidXrready: 	cross rvalid,  rready;
		cross_bvalidXbready: 	cross bvalid,  bready;
	  endgroup
	  
	  
	//constructor
	function new(virtual axi_intf axi_vif);//axi_mst_agent_t axi_mst_agent, 
		this.axi_vif = axi_vif;
		cg_axiapb = new();
	endfunction


	task init_agent();
		axi_mst_agent = new("axi_mst_agent", `axi_mst_INST);
		//axi_mst_agent.set_verbosity(400); //kind of optional
		axi_mst_agent.start_master();
	endtask
	

	task axi_write (
		input  axi_addr_t  addr,
		input  axi_data_t  data );
		
		axi_vip_pkg::xil_axi_resp_t wresp;
		
		axi_mst_agent.AXI4LITE_WRITE_BURST(
			.addr   (axi_vip_pkg::xil_axi_ulong'(addr)),
			.prot   (0),
			.data   (data),
			.resp   (wresp)
		);
	endtask

	task axi_read (
		input  axi_addr_t  addr,
		output axi_data_t  data );
		axi_vip_pkg::xil_axi_resp_t rresp; 
		
		axi_mst_agent.AXI4LITE_READ_BURST(
			.addr   (axi_vip_pkg::xil_axi_ulong'(addr)),
			.prot   (0),
			.data   (data),
			.resp   (rresp)
		);
	endtask
	
	
	axi_vip_pkg::xil_axi_resp_t resp; 
	task run();
		axi_trans trans = new;
		axi_trans tr = new;
				
		repeat(10) @(`axi_DRIV_IF);
		
		forever begin					
			//trans.randomize(); 
			assert(trans.randomize());
			tr = trans.do_copy();
			axitoapb.put(tr);
			@(`axi_DRIV_IF); 
			cg_axiapb.sample();
			
			@(`axi_DRIV_IF);
			if(trans.write_sel == 1) begin
				axi_write(trans.addr, trans.wdata);
				axi_mst_agent.wait_drivers_idle();  //Determine if there are outstanding transactions
				/*
				@(`axi_DRIV_IF);	
				tb.i_intf_apb.pslverr = '1;
				@(`axi_DRIV_IF);
				tb.i_intf_apb.pslverr = '0;*/
			end else begin
				axi_read(trans.addr, trans.rdata);
				axi_mst_agent.wait_drivers_idle();
			end
			/*
			@(`axi_DRIV_IF);
			if(tb.dut.next_state == WDATA_TRANSFERRED_STATE) begin
				$display("inside if");
				`axi_cvg.axi_bready = 0;		
			end*/

		end
	endtask	 
	
endclass