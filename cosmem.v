module cosmem #(parameter integer MEM_WORDS = 1024,
		parameter integer XCLK_DIV = 8)
   (
    input  clk, // 16MHz clock
    input  resetn,

    output xclk,
    output nwait,
    output clr,
    input  nmwr,
    input  nmrd,
    input  tpa,
    input  tpb,
    input  ma0,
    input  ma1,
    input  ma2,
    input  ma3,
    input  ma4,
    input  ma5,
    input  ma6,
    input  ma7,
    output db0_oe,
    output db1_oe,
    output db2_oe,
    output db3_oe,
    output db4_oe,
    output db5_oe,
    output db6_oe,
    output db7_oe,
    output db0_do,
    output db1_do,
    output db2_do,
    output db3_do,
    output db4_do,
    output db5_do,
    output db6_do,
    output db7_do,
    input  db0_di,
    input  db1_di,
    input  db2_di,
    input  db3_di,
    input  db4_di,
    input  db5_di,
    input  db6_di,
    input  db7_di,
    output ce,
    output probe
   );

   reg 	   xclk, nwait, clr;
   
   reg [7:0] mem [0:MEM_WORDS-1];

   wire [15:0]  mem_addr;
   reg [7:0] 	mem_loaddr, mem_hiaddr;
   reg [7:0]  mem_rdata;
   reg [7:0]  mem_wdata;
   reg [2:0]  clk_cnt;
   reg [2:0]  xclk_cycle;
   reg 	      mem_wreq;
   reg 	      mem_rreq;
   reg 	      init_cycle;
   reg 	      tpa_sync;

   reg [15:0] load_addr;
   reg [7:0]  load_data;
   reg 	      lclk;
   reg 	      load;

   assign mem_addr = { mem_hiaddr, mem_loaddr };

   assign db0_oe = !nmrd;
   assign db1_oe = !nmrd;
   assign db2_oe = !nmrd;
   assign db3_oe = !nmrd;
   assign db4_oe = !nmrd;
   assign db5_oe = !nmrd;
   assign db6_oe = !nmrd;
   assign db7_oe = !nmrd;
   assign db0_do = mem_rdata[0];
   assign db1_do = mem_rdata[1];
   assign db2_do = mem_rdata[2];
   assign db3_do = mem_rdata[3];
   assign db4_do = mem_rdata[4];
   assign db5_do = mem_rdata[5];
   assign db6_do = mem_rdata[6];
   assign db7_do = mem_rdata[7];

   function [7:0] flash_mem;
      input reg [15:0] addr;
 
      case(addr)
	0: flash_mem = 8'hE1; // SEX 1
	1: flash_mem = 8'h7B; // SEQ
	2: flash_mem = 8'hC4; // NOP
	3: flash_mem = 8'h7A; // REQ
	4: flash_mem = 8'h30; // BR 1
	5: flash_mem = 8'h01; //     ;to 1
	default: flash_mem = 8'h00;
      endcase // case (addr)
   endfunction // flash_mem

   always @(posedge clk) begin
      if (!resetn)
	begin
	   clk_cnt <= 0;
	   xclk <= 0;
	   xclk_cycle <= 0;
	   mem_wreq <= 0;
	   mem_rreq <= 0;
	   // Reset /CLR=L, /WAIT=H at least 200ns
	   nwait <= 1;
	   clr <= 0;
	   mem_hiaddr <= 0;
	   mem_loaddr <= 0;
	   tpa_sync <= 0;
	   init_cycle <= 0;
	   // Initialize loader
	   load <= 1;
	   lclk <= 0;
	   load_addr <= 0;
	end // if (!resetn)
      else if (load)
	begin
	   clk_cnt <= clk_cnt + 1;
	   load_data <= flash_mem(load_addr);
	   if (lclk && !clk_cnt[2]) // lclk falling
	     begin
		mem[load_addr] <= load_data;
		load_addr <= load_addr + 1;
	     end
	   if (load_addr == 8)
	     load <= 0;
	   lclk <= clk_cnt[2];
	end
      else
	begin
	   clr <= 1;
	   clk_cnt <= clk_cnt + 1;
	   if (clk_cnt == XCLK_DIV - 1)
	     begin
		xclk_cycle <= xclk_cycle + 1;
	     end
	   tpa_sync <= tpa;
	   if (!xclk && clk_cnt[2]) // xclk rising
	     begin
		if (tpb)
		  begin
		     xclk_cycle <= 7;
		     mem_wreq <= 0;
		     init_cycle <= 0;
		  end
		if (!init_cycle && xclk_cycle == 3)
		  begin
		     mem_loaddr <= {ma7, ma6, ma5, ma4, ma3, ma2, ma1, ma0};
		     if (nmrd == 0)
		       begin
			  mem_rreq <= 1;
		       end
		  end
	     end
	   if (!init_cycle && xclk && !clk_cnt[2]) // xclk falling
	     begin
		// cycle count is updated already at the falling edge
		// i.e. xclk_cycle N means the start of cycle N.
		if (nmwr == 0 && xclk_cycle == 6)
		  begin
		     mem_wreq <= 1;
		  end
		if (mem_wreq)
		  begin
		     mem_wreq <= 0;
		     mem[mem_addr] <= {db7_di, db6_di, db5_di, db4_di,
				       db3_di, db2_di, db1_di, db0_di};
		  end
		if (xclk_cycle == 0)
		  begin
		     mem_rreq <= 0;
		  end
	     end // if (xclk && !clk_cnt[2])
	   if (tpa_sync && !tpa) // tpa falling
	     begin
		mem_hiaddr <= {ma7, ma6, ma5, ma4, ma3, ma2, ma1, ma0};
	     end
	   if (mem_rreq)
	     begin
		mem_rdata <= mem[mem_addr];
		//mem[mem_addr] = 8'b11111111;
	     end

	   xclk <= clk_cnt[2];
	end
   end

endmodule // cosmem
   
