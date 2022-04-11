`timescale 1ns / 1ps

interface apb_intf(input logic aclk, aresetn);
  //output DUT
  bit   			         pready;  
  bit [31:0] 				 prdata;
  bit	            	     pslverr;
  //input DUT 
  logic 	                 penable;
  logic [31:0]               paddr;
  logic [31:0]               pwdata;
  logic                      psel;
  logic                      pwrite;
  
  
  //apb slave driver clocking block
  clocking apb_slave_cb @(posedge aclk);
    default input #1step output #1ns;
    input paddr;
    input pwdata;
    input psel;
	input penable;
	input pwrite;
	output prdata;
    output pready;
	output pslverr;
  endclocking
  
  //apb slave monitor clocking block  
  clocking apb_monitor_cb @(posedge aclk);
    default input #1step output #1ns;
    input paddr;
    input pwdata;
    input prdata;
    input psel;
	input penable;
	input pwrite;
    input pready;  
    input pslverr;  
  endclocking
   
  
 endinterface