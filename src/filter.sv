`default_nettype none
module filter #(
    parameter WIDTH = 16
) (
  input wire  clk,
  input wire  rstn,
  input wire  i,
  output wire o);

  reg [WIDTH-1:0] r = {WIDTH{1'b0}};
  reg             v = 1'b0;

  always @(posedge clk or negedge rstn) begin
    if (~rstn) begin
      r <= {WIDTH{1'b0}};
      v <= 1'b0;
    end else begin
      r <= {r[WIDTH-2:0], i};
      if (r == {WIDTH{1'b0}})
        v <= 1'b0;
      else if (r == {WIDTH{1'b1}})
        v <= 1'b1;
    end
  end

  assign o = v;
endmodule
`default_nettype wire
