`timescale 1ns/1ps
module tb_pll;

  reg clkin = 1'b0;
  reg reset = 1'b1;
  wire clkout;
  wire locked;

  pll u0 (
    .clkin(clkin),
    .reset(reset),
    .clkout(clkout),
    .locked(locked));

  initial forever #(5us) clkin = ~clkin;

  initial begin
    reset         <= 1'b1;
    #(1ms) reset <= 1'b0;
  end

endmodule
