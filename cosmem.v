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
    output ce
   );

   reg 	   xclk, nwait, clr;
   
   reg [7:0] mem [0:MEM_WORDS-1];

   reg [15:0] mem_addr;
   reg [7:0]  mem_rdata;
   reg [7:0]  mem_wdata;
   reg [2:0]  clk_cnt;
   reg [2:0]  xclk_cycle;
   reg 	      mem_wreq;
   reg 	      mem_rreq;
   reg 	      init_cycle;

   //reg [7:0]  pata = 8'b10101010;
   //reg [7:0]  patb = 8'b01010101;
   //reg 	      patcnt = 0;

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
	   mem_addr <= 0;
	   init_cycle <= 1;

	   //patcnt <= patcnt + 1;
	   //mem[patcnt] <= patcnt ? patb : pata;
	end // if (!resetn)
      else
	begin
	   clr <= 1;
	   clk_cnt <= clk_cnt + 1;
	   if (clk_cnt == XCLK_DIV - 1)
	     begin
		xclk_cycle <= xclk_cycle + 1;
	     end
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
		     mem_addr[7:0] <= {ma7, ma6, ma5, ma4, ma3, ma2, ma1, ma0};
		     if (nmrd == 0)
		       begin
			  mem_rreq <= 1;
		       end
		  end
		if (!init_cycle && xclk_cycle == 4)
		  begin
		     if (mem_rreq)
		       begin
			  mem_rdata <= mem[mem_addr];
		       end
		  end
	     end
	   if (!init_cycle && xclk && !clk_cnt[2]) // xclk falling
	     begin
		if (tpa)
		  begin
		     xclk_cycle <= 2;
		     mem_addr[15:8] <= {ma7, ma6, ma5, ma4, ma3, ma2, ma1, ma0};
		  end
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

	   xclk <= clk_cnt[2];
	end
   end

endmodule
