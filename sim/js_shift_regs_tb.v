`timescale 1ns/1ps

module js_shift_regs_tb;
  reg clk = 0;
  always #5 clk = ~clk;

  reg osr_penable = 1;
  reg osr_reset = 0;
  reg osr_stalled = 0;
  reg [15:0] osr_din = 0;
  reg [4:0] osr_shift = 0;
  reg osr_dir = 0;
  reg osr_set = 0;
  reg osr_do_shift = 0;
  wire [15:0] osr_dout;
  wire [4:0] osr_shift_count;

  reg isr_penable = 1;
  reg isr_reset = 0;
  reg isr_stalled = 0;
  reg [15:0] isr_din = 0;
  reg [4:0] isr_shift = 0;
  reg isr_dir = 0;
  reg isr_set = 0;
  reg isr_do_shift = 0;
  reg [4:0] isr_bit_count = 0;
  wire [15:0] isr_dout;
  wire [4:0] isr_shift_count;

  osr #(.DATA_WIDTH(16), .COUNT_WIDTH(5)) dut_osr (
    .clk(clk),
    .penable(osr_penable),
    .reset(osr_reset),
    .stalled(osr_stalled),
    .din(osr_din),
    .shift(osr_shift),
    .dir(osr_dir),
    .set(osr_set),
    .do_shift(osr_do_shift),
    .dout(osr_dout),
    .shift_count(osr_shift_count)
  );

  isr #(.DATA_WIDTH(16), .COUNT_WIDTH(5)) dut_isr (
    .clk(clk),
    .penable(isr_penable),
    .reset(isr_reset),
    .stalled(isr_stalled),
    .din(isr_din),
    .shift(isr_shift),
    .dir(isr_dir),
    .set(isr_set),
    .do_shift(isr_do_shift),
    .bit_count(isr_bit_count),
    .dout(isr_dout),
    .shift_count(isr_shift_count)
  );

  task tick;
    begin
      @(posedge clk);
      #1;
    end
  endtask

  initial begin
    osr_reset = 1;
    isr_reset = 1;
    tick;
    osr_reset = 0;
    isr_reset = 0;

    if (osr_shift_count !== 16) $fatal(1, "OSR reset did not mark the register empty");
    if (isr_shift_count !== 0) $fatal(1, "ISR reset did not mark the register empty");

    osr_set = 1;
    osr_din = 16'hA5A5;
    tick;
    osr_set = 0;
    if (osr_dout !== 16'hA5A5 || osr_shift_count !== 0) $fatal(1, "OSR load failed");

    osr_dir = 0;
    osr_shift = 4;
    osr_do_shift = 1;
    #1;
    if (osr_dout !== 16'hA) $fatal(1, "OSR left shifted-out value failed");
    tick;
    osr_do_shift = 0;
    if (osr_shift_count !== 4) $fatal(1, "OSR left shift count failed");

    osr_set = 1;
    osr_din = 16'hA5A5;
    tick;
    osr_set = 0;
    osr_dir = 1;
    osr_shift = 4;
    osr_do_shift = 1;
    #1;
    if (osr_dout !== 16'h5) $fatal(1, "OSR right shifted-out value failed");
    tick;
    osr_do_shift = 0;
    if (osr_shift_count !== 4) $fatal(1, "OSR right shift count failed");

    osr_set = 1;
    osr_din = 16'h1234;
    tick;
    osr_set = 0;
    osr_shift = 0;
    osr_dir = 0;
    osr_do_shift = 1;
    tick;
    osr_do_shift = 0;
    if (osr_shift_count !== 16) $fatal(1, "OSR zero did not mean 16");

    isr_set = 1;
    isr_din = 16'hA500;
    isr_bit_count = 8;
    tick;
    isr_set = 0;
    if (isr_dout !== 16'hA500 || isr_shift_count !== 8) $fatal(1, "ISR direct load failed");

    isr_dir = 0;
    isr_shift = 2;
    isr_din = 16'h0003;
    isr_do_shift = 1;
    tick;
    isr_do_shift = 0;
    if (isr_dout !== 16'h9403 || isr_shift_count !== 10) $fatal(1, "ISR left shift failed");

    isr_set = 1;
    isr_din = 0;
    isr_bit_count = 0;
    tick;
    isr_set = 0;
    isr_dir = 1;
    isr_shift = 2;
    isr_din = 16'h0003;
    isr_do_shift = 1;
    tick;
    isr_do_shift = 0;
    if (isr_dout !== 16'hC000 || isr_shift_count !== 2) $fatal(1, "ISR right shift failed");

    isr_set = 1;
    isr_din = 0;
    isr_bit_count = 0;
    tick;
    isr_set = 0;
    isr_shift = 0;
    isr_dir = 0;
    isr_din = 16'hBEEF;
    isr_do_shift = 1;
    tick;
    isr_do_shift = 0;
    if (isr_shift_count !== 16) $fatal(1, "ISR zero did not mean 16");

    $display("PASS: JS 16-bit OSR/ISR shift-register tests");
    $finish;
  end
endmodule
