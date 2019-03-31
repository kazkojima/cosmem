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

module hardware (
    input  clk_16mhz,

    // onboard USB interface
    output pin_pu,
    output pin_usbp,
    output pin_usbn,

    // XCLK
    output pin_1,
    // NWAIT
    output pin_2,
    // CLR
    output pin_3,
    // NMWR
    input  pin_4,
    // NMRD
    input  pin_5,
    // TPA
    input  pin_6,
    // TPB
    input  pin_7,
    // MA0-MA7 (reversed order)
    input  pin_8,
    input  pin_9,
    input  pin_10,
    input  pin_11,
    input  pin_12,
    input  pin_13,
    input  pin_14,
    input  pin_15,
    // DB0-DB7
    inout  pin_16,
    inout  pin_17,
    inout  pin_18,
    inout  pin_19,
    inout  pin_20,
    inout  pin_21,
    inout  pin_22,
    inout  pin_23,
    // CE
    output pin_24,
		 
    // onboard LED
    output user_led,

    // onboard SPI flash interface
    output flash_csb,
    output flash_clk,
    inout  flash_io0,
    inout  flash_io1,
    inout  flash_io2,
    inout  flash_io3
);
    assign pin_pu = 1'b1;
    assign pin_usbp = 1'b0;
    assign pin_usbn = 1'b0;

    wire clk = clk_16mhz;
  
    // Power-on Reset
    reg [5:0] reset_cnt = 0;
    wire resetn = &reset_cnt;

    // Data bus
    wire  db0_oe, db1_oe, db2_oe, db3_oe, db4_oe, db5_oe, db6_oe, db7_oe;
    wire  db0_do, db1_do, db2_do, db3_do, db4_do, db5_do, db6_do, db7_do;
    wire  db0_di, db1_di, db2_di, db3_di, db4_di, db5_di, db6_di, db7_di;
   
    SB_IO #(
        .PIN_TYPE(6'b 1010_01),
        .PULLUP(1'b 0)
    ) data_bus [7:0] (
        .PACKAGE_PIN({pin_16, pin_17, pin_18, pin_19,
		      pin_20, pin_21, pin_22, pin_23}),
        .OUTPUT_ENABLE({db0_oe, db1_oe, db2_oe, db3_oe,
			db4_oe, db5_oe, db6_oe, db7_oe}),
        .D_OUT_0({db0_do, db1_do, db2_do, db3_do,
		  db4_do, db5_do, db6_do, db7_do}),
        .D_IN_0({db0_di, db1_di, db2_di, db3_di,
		 db4_di, db5_di, db6_di, db7_di})
    );

    // SPI Flash Interface
    wire flash_io0_oe, flash_io0_do, flash_io0_di;
    wire flash_io1_oe, flash_io1_do, flash_io1_di;
    wire flash_io2_oe, flash_io2_do, flash_io2_di;
    wire flash_io3_oe, flash_io3_do, flash_io3_di;

    SB_IO #(
        .PIN_TYPE(6'b 1010_01),
        .PULLUP(1'b 0)
    ) flash_io_buf [3:0] (
        .PACKAGE_PIN({flash_io3, flash_io2, flash_io1, flash_io0}),
        .OUTPUT_ENABLE({flash_io3_oe, flash_io2_oe, flash_io1_oe, flash_io0_oe}),
        .D_OUT_0({flash_io3_do, flash_io2_do, flash_io1_do, flash_io0_do}),
        .D_IN_0({flash_io3_di, flash_io2_di, flash_io1_di, flash_io0_di})
    );

    always @(posedge clk) begin
        reset_cnt <= reset_cnt + !resetn;
    end

    cosmem #(
        .MEM_WORDS(8192),	// use 8KBytes of block RAM by default
	.XCLK_DIV(8)		// use 16/8=2MHz xclk by default
    ) memory (
        .clk          (clk         ),
	.resetn       (resetn      ),

        .xclk         (pin_1       ),
        .nwait        (pin_2       ),
	.clr          (pin_3       ),
	.nmwr         (pin_4       ),
	.nmrd         (pin_5       ),
	.tpa          (pin_6       ),
	.tpb          (pin_7       ),
	.ma0          (pin_15      ),
	.ma1          (pin_14      ),
	.ma2          (pin_13      ),
	.ma3          (pin_12      ),
	.ma4          (pin_11      ),
	.ma5          (pin_10      ),
	.ma6          (pin_9       ),
	.ma7          (pin_8       ),
	.db0_oe       (db0_oe      ),
	.db1_oe       (db1_oe      ),
	.db2_oe       (db2_oe      ),
	.db3_oe       (db3_oe      ),
	.db4_oe       (db4_oe      ),
	.db5_oe       (db5_oe      ),
	.db6_oe       (db6_oe      ),
	.db7_oe       (db7_oe      ),
	.db0_do       (db0_do      ),
	.db1_do       (db1_do      ),
	.db2_do       (db2_do      ),
	.db3_do       (db3_do      ),
	.db4_do       (db4_do      ),
	.db5_do       (db5_do      ),
	.db6_do       (db6_do      ),
	.db7_do       (db7_do      ),
	.db0_di       (db0_di      ),
	.db1_di       (db1_di      ),
	.db2_di       (db2_di      ),
	.db3_di       (db3_di      ),
	.db4_di       (db4_di      ),
	.db5_di       (db5_di      ),
	.db6_di       (db6_di      ),
	.db7_di       (db7_di      ),
	.ce           (pin_24      ),

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

	.probe        (user_led    )
    );
endmodule
