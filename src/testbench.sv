`default_nettype none
module testbench;
  reg clk            = 1'b0;
  reg rst            = 1'b1;
  reg I_BT           = 1'b0;
  reg I_CLK          = 1'b0;
  reg [2:0] I_C      = 3'b000;
  reg [4:1] I_ERR_DR = 4'b0000;
  reg       I_ERR_I  = 1'b0;
  reg       I_ERR_U  = 1'b0;
  reg       I_STOP_K = 1'b0;

  wire      O_AVI;
  wire      O_AVV;
  wire [4:1] O_BOT;
  wire [4:1] O_TOP;
  wire [4:1] O_ERBD;
  wire       O_BREAK;
  wire       O_CH;
  wire       O_CHARGE;
  wire       O_FAN;
  wire       O_PLUS;
  wire       O_MINUS;
  wire       O_PAUSE_P;
  wire       O_PAUSE_N;
  wire       O_ST;
  wire       O_START;
  wire       O_STOP;
  wire       O_TD;

  top #(
    .FREQ(50000)
  ) u0 (
    .clk (clk),
    .rst (rst),

    // inputs
    .I_BT (I_BT),
    .I_CLK (I_CLK),
    .I_C0 (I_C[0]),
    .I_C1 (I_C[1]),
    .I_C2 (I_C[2]),
    .I_ERR_DR_1 (I_ERR_DR[1]),
    .I_ERR_DR_2 (I_ERR_DR[2]),
    .I_ERR_DR_3 (I_ERR_DR[3]),
    .I_ERR_DR_4 (I_ERR_DR[4]),
    .I_ERR_I (I_ERR_I),
    .I_ERR_U (I_ERR_U),
    .I_STOP_K (I_STOP_K),

    // outputs
    .O_AVI (O_AVI),
    .O_AVV (O_AVV),
    .O_BOT_1 (O_BOT[1]),
    .O_BOT_2 (O_BOT[2]),
    .O_BOT_3 (O_BOT[3]),
    .O_BOT_4 (O_BOT[4]),
    .O_BREAK (O_BREAK),
    .O_CH (O_CH),
    .O_CHARGE (O_CHARGE),
    .O_ERBD1 (O_ERBD[1]),
    .O_ERBD2 (O_ERBD[2]),
    .O_ERBD3 (O_ERBD[3]),
    .O_ERBD4 (O_ERBD[4]),
    .O_FAN (O_FAN),
    .O_PLUS (O_PLUS),
    .O_MINUS (O_MINUS),
    .O_PAUSE_P (O_PAUSE_P),
    .O_PAUSE_N (O_PAUSE_N),
    .O_ST (O_ST),
    .O_START (O_START),
    .O_STOP (O_STOP),
    .O_TOP_1 (O_TOP[1]),
    .O_TOP_2 (O_TOP[2]),
    .O_TOP_3 (O_TOP[3]),
    .O_TOP_4 (O_TOP[4]),
    .O_TD (O_TD));

  initial forever #(10ns) clk = ~clk;
  initial begin
    rst = 1'b1;
    #(100ns);
    @(posedge clk);
    rst = 1'b0;
  end

  task run_cmd (
    input bit [2:0] cmd);
    begin
      I_C   = cmd;
      I_CLK = 1'b1;
      #(1us);
      I_CLK = 1'b0;
      #(1us);

      I_C   = 3'h0;
      I_CLK = 1'b1;
      #(1us);
      I_CLK = 1'b0;
      #(1us);
    end
  endtask

  task run_discharge;
    begin
      I_C   = 3'h7;
      I_CLK = 1'b1;
      #(1us);
      I_CLK = 1'b0;
      #(1us);

      I_C   = 3'h0;
      I_CLK = 1'b1;
      #(1us);
      I_CLK = 1'b0;
      #(1us);

      I_C   = 3'h7;
      I_CLK = 1'b1;
      #(1us);
      I_CLK = 1'b0;
      #(1us);

      I_C   = 3'h0;
      I_CLK = 1'b1;
      #(1us);
      I_CLK = 1'b0;
      #(1us);

      I_C   = 3'h1;
      I_CLK = 1'b1;
      #(1us);
      I_CLK = 1'b0;
      #(1us);

    end
  endtask

  initial begin;
    $dumpfile("waveform.vcd");
    $dumpvars();
    run_cmd(3'h5);
    #(1us);
    wait (O_CHARGE == 1'b0);
    #(1us);
    run_cmd(3'h1);
    run_cmd(3'h2);
    run_cmd(3'h3);
    run_cmd(3'h4);
    run_cmd(3'h0);
    run_cmd(3'h0);
    run_cmd(3'h1);
    @(posedge clk);
    I_STOP_K = 1'b1;
    #(100ns);
    @(posedge clk);
    run_cmd(3'h2);
    run_cmd(3'h3);
    run_cmd(3'h4);
    run_cmd(3'h6);
    run_discharge();
    #(1us);
    $stop();
  end

endmodule
`default_nettype wire
