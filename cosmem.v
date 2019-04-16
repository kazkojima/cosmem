/*
 *  Cosmem - A simple example memory/controller chip for COSMAC
 *
 *  Copyright (C) 2019  Kaz Kojima <kkojima@rr.iij4u.or.jp>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

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

    output flash_csb,
    output flash_clk,

    output flash_io0_oe,
    output flash_io1_oe,
    output flash_io2_oe,
    output flash_io3_oe,

    output flash_io0_do,
    output flash_io1_do,
    output flash_io2_do,
    output flash_io3_do,

    input  flash_io0_di,
    input  flash_io1_di,
    input  flash_io2_di,
    input  flash_io3_di,
    
    output probe,

    output mbox_sclk,
    output mbox_mosi,
    input mbox_miso,
    input mbox_ready,
    output mbox_cs
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
   reg 	      tpa_sync;

   reg [15:0] load_addr;
   reg [7:0]  load_data;
   reg 	      lclk;
   reg 	      load;

   reg        spimem_valid = 1;
   reg [23:0] spimem_addr;
   wire       spimem_ready;
   wire [31:0] spimem_rdata;
   wire [31:0] spimemio_cfgreg_di;
   wire [31:0] spimemio_cfgreg_do;

   reg [2:0]   mbox_rindex;
   reg [2:0]   mbox_windex;
   wire [7:0]  mbox_rdata;
   reg [7:0]   mbox_wdata;
   wire        mbox_valid;
   reg 	       mbox_wstrb;
   wire        mbox_test;

   assign probe = mbox_wdata[0];
        
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

   spimemio spimemio
     (
      .clk    (clk),
      .resetn (resetn),
      .valid  (spimem_valid),
      .ready  (spimem_ready),
      .addr   (spimem_addr),
      .rdata  (spimem_rdata),

      .flash_csb    (flash_csb   ),
      .flash_clk    (flash_clk   ),

      .flash_io0_oe (flash_io0_oe),
      .flash_io1_oe (flash_io1_oe),
      .flash_io2_oe (flash_io2_oe),
      .flash_io3_oe (flash_io3_oe),

      .flash_io0_do (flash_io0_do),
      .flash_io1_do (flash_io1_do),
      .flash_io2_do (flash_io2_do),
      .flash_io3_do (flash_io3_do),

      .flash_io0_di (flash_io0_di),
      .flash_io1_di (flash_io1_di),
      .flash_io2_di (flash_io2_di),
      .flash_io3_di (flash_io3_di),

      .cfgreg_we(4'b0000),
      .cfgreg_di(spimemio_cfgreg_di),
      .cfgreg_do(spimemio_cfgreg_do)
      );

   spimbox spimbox
     (
      .clk    (clk),
      .resetn (resetn),

      .sclk   (mbox_sclk),
      .mosi   (mbox_mosi),
      .miso   (mbox_miso),
      .ready  (mbox_ready),
      .cs     (mbox_cs),

      .rindex (mbox_rindex),
      .windex (mbox_windex),
      .rdata  (mbox_rdata),
      .wdata  (mbox_wdata),
      .valid  (mbox_valid),
      .wstrb  (mbox_wstrb)
     );
   
/*
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
*/

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
	   // Initialize loader
	   load <= 1;
	   lclk <= 0;
	   load_addr <= 0;
	   // Mbox
	   mbox_wstrb <= 0;
	end // if (!resetn)
      else if (load)
	begin
	   clk_cnt <= clk_cnt + 1;
	   spimem_addr <= { 8'h05, load_addr[15:2], 2'b00 };
	   //load_data <= flash_mem(load_addr);
	   if (spimem_ready && lclk && !clk_cnt[2]) // lclk falling
	     begin
		case(load_addr & 3)
		  // little endian
		  0: mem[load_addr] <= spimem_rdata[7:0];
		  1: mem[load_addr] <= spimem_rdata[15:8];
		  2: mem[load_addr] <= spimem_rdata[23:16];
		  3: mem[load_addr] <= spimem_rdata[31:24];
		endcase
		load_addr <= load_addr + 1;
	     end
	   if (load_addr == MEM_WORDS)
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
		  end
		if (xclk_cycle == 3)
		  begin
		     mem_loaddr <= {ma7, ma6, ma5, ma4, ma3, ma2, ma1, ma0};
		     if (nmrd == 0)
		       begin
			  mem_rreq <= 1;
			  mbox_rindex <= {ma2, ma1, ma0};
		       end
		  end
	     end
	   if (xclk && !clk_cnt[2]) // xclk falling
	     begin
		// cycle count is updated already at the falling edge
		// i.e. xclk_cycle N means the start of cycle N.
		if (nmwr == 0 && xclk_cycle == 6)
		  begin
		     if (mem_addr < MEM_WORDS)
		       begin
			  mem_wreq <= 1;
		       end
		     else if (mem_addr >= 16'hf000)
		       begin
			  mbox_wstrb <= 1;
			  mbox_windex <= mem_addr[2:0];
			  mbox_wdata <= {db7_di, db6_di, db5_di, db4_di,
					 db3_di, db2_di, db1_di, db0_di};
		       end
		  end
		if (mem_wreq)
		  begin
		     mem_wreq <= 0;
		     mem[mem_addr] <= {db7_di, db6_di, db5_di, db4_di,
				       db3_di, db2_di, db1_di, db0_di};
		  end
		if (mbox_wstrb)
		  begin
		     mbox_wstrb <= 0;
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
		if (mem_addr < MEM_WORDS)
		  begin
		     mem_rdata <= mem[mem_addr];
		  end
		else if (mem_addr == 16'hf008)
		  begin
		     mem_rdata[0] <= mbox_valid;
		     mem_rdata[1] <= mbox_ready;
		     mem_rdata[7:2] <= 6'b000000;
		  end
		else if (mem_addr >= 16'hf000 && mbox_valid)
		  begin
		     mem_rdata <= mbox_rdata;
		  end
		else
		  begin
		     mem_rdata <= 8'b00000000;
		  end
	     end

	   xclk <= clk_cnt[2];
	end
   end

endmodule // cosmem
