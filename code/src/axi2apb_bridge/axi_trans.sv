`timescale 1ns / 1ps
package axi_trans;

class axi_trans; 

	randc bit write_sel;
	randc bit[31:0] addr;
	randc bit[31:0] wdata;
    randc bit[31:0] rdata;
	/*
	constraint c1{addr  >0;  addr<5;};
	constraint c2{rdata >0; rdata<250;};
	constraint c3{wdata >0; wdata<250;};
	*/
	//deep copy
	function axi_trans do_copy();
		axi_trans trans;
		trans = new();
		trans.write_sel  = this.write_sel;
		trans.addr 		 = this.addr;
		trans.wdata 	 = this.wdata;
		trans.rdata 	 = this.rdata;
		return trans;
	endfunction

endclass 	
	
endpackage	