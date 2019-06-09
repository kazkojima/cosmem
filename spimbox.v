/*
 *  Spimbox - A simple mailbox with SPI
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

module spimbox
   (
    input 	 clk, // 16MHz clock
    input 	 resetn,

    output 	 sclk,
    output 	 mosi,
    input 	 miso,
    input 	 ready,
    output       cs,	 

    input [2:0]  rindex,
    input [2:0]  windex,
    output [7:0] rdata,
    input [7:0]  wdata,

    output 	 valid,
    input 	 wstrb
    );

   reg 		 sclk;
   reg [63:0] 	 shift_reg;
   reg [63:0] 	 so;
   reg [63:0] 	 si;
   reg [6:0] 	 bit_cnt;
   reg 		 in_transfer;
   reg 		 internal_mosi;
   reg 		 wstrb_sync;
   reg 		 update;
   reg 		 rd_valid;
   reg [7:0] 	 rd_data;

   assign valid = rd_valid;
   assign rdata = rd_data;
   //assign mosi = internal_mosi;
   bufif1 (mosi, internal_mosi, in_transfer);
   assign cs = !in_transfer;

   always @(posedge clk) begin
      if (!resetn)
	begin
	   sclk <= 1;
	   bit_cnt <= 0;
	   shift_reg <= 0;
	   so <= 0;
	   si <= 0;
	   in_transfer <= 0;
	   internal_mosi <= 0;
	   rd_valid <= 0;
	   wstrb_sync <= 0;
	   update <= 0;
	end
      else
	begin
	   wstrb_sync <= wstrb;
	   if (ready && update && !in_transfer && !bit_cnt) // && ready
	     begin
		shift_reg <= so;
		update <= 0;
		bit_cnt <= 64;
		in_transfer <= 1;
		rd_valid <= 0;
	     end
	   else if (in_transfer && bit_cnt)
	     begin
		if (sclk) // sclk falling
		  begin
		     internal_mosi <= shift_reg[63];
		     sclk <= 0;
		  end
		else
		  begin
                     shift_reg <= { shift_reg[62:0], miso };
 		     bit_cnt <= bit_cnt - 1;
		     sclk <= 1;
		  end
	     end // if (in_transfer && bit_cnt)
	   else if (in_transfer && !bit_cnt)
	     begin
		in_transfer <= 0;
		internal_mosi <= 0;
		si <= shift_reg;
		rd_valid <= 1;
	     end
	   if (wstrb_sync && !wstrb) // wstrb falling
	     begin
		case(windex)
		  3'b000: so[63:56] <= wdata;
		  3'b001: so[55:48] <= wdata;
		  3'b010: so[47:40] <= wdata;
		  3'b011: so[39:32] <= wdata;
		  3'b100: so[31:24] <= wdata;
		  3'b101: so[23:16] <= wdata;
		  3'b110: so[15:8] <= wdata;
		  3'b111: so[7:0] <= wdata;
		endcase // case (windex)
		if (windex == 3'b111) // when the last byte is written
		  begin
		     update <= 1;
		  end
	     end // if (wstrb_sync && !wstrb)
	   if (rd_valid)
	     begin
		case(rindex)
		  3'b000: rd_data <= si[63:56];
		  3'b001: rd_data <= si[55:48];
		  3'b010: rd_data <= si[47:40];
		  3'b011: rd_data <= si[39:32];
		  3'b100: rd_data <= si[31:24];
		  3'b101: rd_data <= si[23:16];
		  3'b110: rd_data <= si[15:8];
		  3'b111: rd_data <= si[7:0];
		endcase // case (rindex)
	     end
	end // else: !if(!resetn)
   end // always @ (posedge clk)
endmodule // spimbox
