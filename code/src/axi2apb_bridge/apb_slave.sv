`timescale 1ns / 1ps
`define apb_DRIV_IF apb_vif.apb_slave_cb
`define axi_sig tb.i_intf_axi
import axi_trans::*;

class apb_slave;
  virtual apb_intf apb_vif;
    
  mailbox axitoapb;
   
  //constructor
  function new(virtual apb_intf apb_vif);
    this.apb_vif = apb_vif;
  endfunction
  
	
	task run;		
		bit [31:0] addr_temp;
		bit [31:0] wdata_temp;
		bit [31:0] rdata_temp;
		int delay;		
		axi_trans tr;
		bit [2:0] count;
		
		`apb_DRIV_IF.pslverr <= 0;
		//`apb_DRIV_IF.pready  <= 0;
		//`apb_DRIV_IF.prdata  <= 32'h00000000;	
		forever begin
			axitoapb.get(tr);  
			delay = $urandom_range(1,5);

			`apb_DRIV_IF.pslverr <= ((`axi_sig.axi_bvalid & `axi_sig.axi_bready) | (`axi_sig.axi_rvalid & `axi_sig.axi_rready));

			while(`apb_DRIV_IF.psel == 0) begin
				@(`apb_DRIV_IF);  
			end
			
			if(tr.write_sel) begin
				addr_temp  = `apb_DRIV_IF.paddr;
				wdata_temp = `apb_DRIV_IF.pwdata;

				for(int i = 1; i < delay+1; i++) begin
					@(`apb_DRIV_IF);
					assert (`apb_DRIV_IF.psel == 1);
					assert (`apb_DRIV_IF.penable == 1);
					assert (`apb_DRIV_IF.pwrite == 1);
					assert (addr_temp  == `apb_DRIV_IF.paddr);
					assert (wdata_temp == `apb_DRIV_IF.pwdata);	
						if (i == delay) begin
							`apb_DRIV_IF.pready <= 1; 
							
							if(count%5 == 0) tb.i_intf_apb.pslverr = '1;
							else tb.i_intf_apb.pslverr = ((`axi_sig.axi_bvalid & `axi_sig.axi_bready) | (`axi_sig.axi_rvalid & `axi_sig.axi_rready));
							
							count++;
							@(`apb_DRIV_IF);
							`apb_DRIV_IF.pready <= 0;
							@(`apb_DRIV_IF);
						end
				end
					tr.addr         = `apb_DRIV_IF.paddr;
					tr.wdata        = `apb_DRIV_IF.pwdata;

			end 
			else begin 
				addr_temp = `apb_DRIV_IF.paddr;
				for(int j = 1; j < delay+1; j++) begin
					@(`apb_DRIV_IF);
					assert (`apb_DRIV_IF.psel == 1);
					assert (`apb_DRIV_IF.penable == 1);
					assert (`apb_DRIV_IF.pwrite == 0);
					assert (addr_temp  == `apb_DRIV_IF.paddr);
						if (j == delay) begin
							@(`apb_DRIV_IF);
							`apb_DRIV_IF.pready <= 1; 
							`apb_DRIV_IF.prdata <= tr.rdata;
							
							if(count%5 == 0) tb.i_intf_apb.pslverr = '1;
							else tb.i_intf_apb.pslverr = ((`axi_sig.axi_bvalid & `axi_sig.axi_bready) | (`axi_sig.axi_rvalid & `axi_sig.axi_rready));
							@(`apb_DRIV_IF);
							`apb_DRIV_IF.pready <= 0; 
							`apb_DRIV_IF.prdata <= 32'h00000000;
							@(`apb_DRIV_IF);
						end		
				end
					tr.addr         = `apb_DRIV_IF.paddr;
			end
		end
	endtask
		
endclass