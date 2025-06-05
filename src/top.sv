`default_nettype none
module top (

  input wire  clk,        // E2
  input wire  rst,        // H11
  input wire  uart_rx,    // B3
  output wire uart_tx,    // C3
  output wire ready,      // E8
  output wire done,       // D7

  // First group from IO_LOC
  input wire  I_STOP_K,   // Pin 2 (K1)
  input wire  I_ERR_U,    // Pin 4 (L2)
  input wire  I_ERR_DR_2, // Pin 6 (J4)
  input wire  I_ERR_DR_1, // Pin 8 (G2)
  output wire O_BOT_4,    // Pin 10 (L4)
                          // Pin 12 (GND)
  output wire O_BOT_2,    // Pin 14 (B2)
  output wire O_BOT_3,    // Pin 16 (F2)
  output wire O_BOT_1,    // Pin 18 (E1)
  output wire O_AVI,      // Pin 20 (E3)
  output wire O_TD,       // Pin 22 (J1)
  output wire O_ERBD2,    // Pin 24 (G4)
  output wire O_ERBD4,    // Pin 26 (H1)
  output wire O_BREAK,    // Pin 28 (K7)
  output wire O_MINUS,    // Pin 30 (L7)
  output wire O_PAUSE_N,  // Pin 32 (L10)
  output wire O_CHARGE,   // Pin 34 (L9)
  output wire O_CH,       // Pin 36 (J8)
  input wire  I_C1,       // Pin 38 (F7)
  input wire  I_CLK,      // Pin 40 (J11)

  // Second group from IO_LOC
  output wire O_FAN,      // Pin 1 (K2)
  input wire  I_ERR_I,    // Pin 3 (L1)
  input wire  I_ERR_DR_4, // Pin 5 (K4)
  input wire  I_ERR_DR_3, // Pin 7 (G1)
  output wire O_TOP_4,    // Pin 9 (L3)
                          // Pin 11 (+5V)
  output wire O_TOP_2,    // Pin 13 (C2)
  output wire O_TOP_3,    // Pin 15 (F1)
  output wire O_TOP_1,    // Pin 17 (A1)
  output wire O_AVV,      // Pin 19 (D1)
  output wire O_ERBD1,    // Pin 21 (J2)
  output wire O_ERBD3,    // Pin 23 (H4)
  output wire O_STOP,     // Pin 25 (H2)
  output wire O_PLUS,     // Pin 27 (J7)
  output wire O_PAUSE_P,  // Pin 29 (L8)
  output wire O_START,    // Pin 31 (K10)
  input wire  I_BT,       // Pin 33 (K9)
  output wire O_ST,       // Pin 35 (K8)
  input wire  I_C0,       // Pin 37 (F6)
  input wire  I_C2        // Pin 39 (J10)
);

  assign O_BOT_1 = 1'b0;
  assign O_BOT_2 = 1'b0;
  assign O_BOT_3 = 1'b0;
  assign O_BOT_4 = 1'b0;

  assign O_TOP_1 = 1'b0;
  assign O_TOP_2 = 1'b0;
  assign O_TOP_3 = 1'b0;
  assign O_TOP_4 = 1'b0;

  assign O_AVI = 1'b0;
  assign O_AVV = 1'b0;
  assign O_TD = 1'b0;

  assign O_ERBD1 = 1'b0;
  assign O_ERBD2 = 1'b0;
  assign O_ERBD3 = 1'b0;
  assign O_ERBD4 = 1'b0;

  assign O_BREAK = 1'b0;
  assign O_MINUS = 1'b0;
  assign O_PLUS  = 1'b0;
  assign O_PAUSE_P = 1'b0;
  assign O_PAUSE_N = 1'b0;
  assign O_CHARGE = 1'b0;
  assign O_CH = 1'b0;

  // assign O_FAN = 1'b0;
  assign O_STOP = 1'b0;
  assign O_START = 1'b0;
  assign O_ST = 1'b0;

  typedef struct packed {
    bit [12:0] baud_cnt;
    bit [20:0] shiftreg;
    bit [25:0] cnt;
  } state_t;

  localparam     state_t RES_state = '{
    baud_cnt : 'd0,
    shiftreg: {1'b0, 8'h68, {12{1'b1}}},
    cnt: 'd0
  };

  state_t r = RES_state;
  state_t rin;

  always_comb begin
    state_t v = r;
    bit tick = 1'b0;

    if (r.baud_cnt < 'd5208) begin
      v.baud_cnt = r.baud_cnt + 1;
    end else begin
      v.baud_cnt = 'd0;
      tick = 1'b1;
    end

    if (tick)
      v.shiftreg = {r.shiftreg[19:0], r.shiftreg[20]};

    v.cnt = r.cnt + 1;

    // if (rst)
    //   v = RES_state;

    rin = v;
  end

  always_ff @(posedge clk)
    r <= rin;

  assign uart_tx = r.shiftreg[0];

  assign O_FAN = r.shiftreg[0];
  assign done = r.shiftreg[0];
  assign ready = r.cnt[25];
endmodule
`default_nettype wire
