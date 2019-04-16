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

`timescale 1 ns / 1 ps

module testbench;
   reg clk;
   always #5 clk = (clk === 1'b0);

   integer i;

   initial begin
      $dumpfile("testbench.vcd");
      $dumpvars(0, testbench);
      for (i = 0; i < 16; i = i + 1) begin
//	 cdp.memory.mem[i] = i & 255;
	 $dumpvars(1, cdp.memory.mem[i]);
      end

      repeat (4) begin
	 repeat (50000) @(posedge clk);
	 $display("+50000 cycles");
      end
      $finish;
   end

   integer cycle_cnt = 0;

   always @(posedge clk) begin
      cycle_cnt <= cycle_cnt + 1;
   end

   wire [7:0] leds;

   always @(leds) begin
      #1 $display("%b", leds);
   end

   wire xclk;
   wire nwait;
   wire clr;
   reg nmwr;
   reg nmrd;
   reg tpa;
   reg tpb;
   reg ma0, ma1, ma2, ma3, ma4, ma5, ma6, ma7;
   wire db0, db1, db2, db3, db4, db5, db6, db7;

   hardware cdp (
		 .clk_16mhz (clk      ),
		 .pin_1   (xclk   ),
		 .pin_2   (nwait   ),
		 .pin_3   (clr   ),
		 .pin_4   (nmwr   ),
		 .pin_5   (nmrd   ),
		 .pin_6   (tpa   ),
		 .pin_7   (tpb   ),
		 .pin_15  (ma0   ),
		 .pin_14  (ma1   ),
		 .pin_13  (ma2   ),
		 .pin_12  (ma3   ),
		 .pin_11  (ma4   ),
		 .pin_10  (ma5   ),
		 .pin_9   (ma6   ),
		 .pin_8   (ma7   ),
		 .pin_16  (db0   ),
		 .pin_17  (db1   ),
		 .pin_18  (db2   ),
		 .pin_19  (db3   ),
		 .pin_20  (db4   ),
		 .pin_21  (db5   ),
		 .pin_22  (db6   ),
		 .pin_23  (db7   )
		 );

   reg [2:0] cpu_cycle_cnt = 0;
   reg [8:0] count = 0;
   reg [7:0] rdata = 0;
   reg [7:0] wdata = 0;

   assign db0 = (!nmwr) ? wdata[0] : 1'bz;
   assign db1 = (!nmwr) ? wdata[1] : 1'bz;
   assign db2 = (!nmwr) ? wdata[2] : 1'bz;
   assign db3 = (!nmwr) ? wdata[3] : 1'bz;
   assign db4 = (!nmwr) ? wdata[4] : 1'bz;
   assign db5 = (!nmwr) ? wdata[5] : 1'bz;
   assign db6 = (!nmwr) ? wdata[6] : 1'bz;
   assign db7 = (!nmwr) ? wdata[7] : 1'bz;

   always @(negedge xclk)
     begin
	tpa <= #10 (cpu_cycle_cnt == 0) ? 1 : 0;
	tpb <= #10 (cpu_cycle_cnt == 6) ? 1 : 0;

 	if (cpu_cycle_cnt == 0 || cpu_cycle_cnt == 1)
	  begin
/*
	     ma0 <= #20 0;
	     ma1 <= #20 0;
	     ma2 <= #20 0;
	     ma3 <= #20 0;
	     ma4 <= #20 0;
	     ma5 <= #20 0;
	     ma6 <= #20 0;
	     ma7 <= #20 0;
 */
	     ma0 <= #20 0;
	     ma1 <= #20 0;
	     ma2 <= #20 0;
	     ma3 <= #20 0;
	     ma4 <= #20 1;
	     ma5 <= #20 1;
	     ma6 <= #20 1;
	     ma7 <= #20 1;
	  end // if (cpu_cycle_cnt == 0 || cpu_cycle_cnt == 1)
	else
	  begin
/*
	     ma0 <= #20 count[1];
	     ma1 <= #20 count[2];
	     ma2 <= #20 count[3];
	     ma3 <= #20 count[4];
	     ma4 <= #20 count[5];
	     ma5 <= #20 count[6];
	     ma6 <= #20 count[7];
	     ma7 <= #20 count[8];
 */
	     ma0 <= #20 count[1];
	     ma1 <= #20 count[2];
	     ma2 <= #20 count[3];
	     ma3 <= #20 count[4];
	     ma4 <= #20 0;
	     ma5 <= #20 0;
	     ma6 <= #20 0;
	     ma7 <= #20 0;
	  end
	if (count[0] == 0 && cpu_cycle_cnt == 7)
	  begin
	     rdata <= {db7, db6, db5, db4, db3, db2, db1, db0};
	  end
 	else if (count[0] && cpu_cycle_cnt == 3)
	  begin
	     wdata <= 8'b11000101+{ma2,ma1,ma0}; //rdata + 2;
	  end
	nmrd <= !(count[0] == 0 && cpu_cycle_cnt != 0 && cpu_cycle_cnt != 1);
//	nmwr <= 1;
   	nmwr <= !(count[0]
		 && (cpu_cycle_cnt == 4
		     || cpu_cycle_cnt == 5
		     || cpu_cycle_cnt == 6));
	count <= count + &cpu_cycle_cnt;
	cpu_cycle_cnt <= cpu_cycle_cnt + 1;
     end // always begin
endmodule
