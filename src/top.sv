`default_nettype none
module top #(
  parameter FREQ = 50000000
) (
  input wire  clk,        // E2
  input wire  rst,        // H11
  // input wire  uart_rx,    // B3
  // output wire uart_tx,    // C3
  output wire led_ready,  // E8
  output wire led_done,   // D7

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

  wire rstn;
  wire w_clk;
  wire [2:0] w_bus;
  wire [4:1] w_err_dr;
  wire       w_err_u;
  wire       w_err_i;
  wire       w_bt;
  wire       w_stop_k;

  assign rstn = ~rst;

  filter #(.WIDTH(16)) u_clk (.clk (clk), .rstn(rstn), .i(I_CLK), .o(w_clk));
  filter #(.WIDTH(16)) u_c0 (.clk (clk), .rstn(rstn), .i(I_C0), .o(w_bus[0]));
  filter #(.WIDTH(16)) u_c1 (.clk (clk), .rstn(rstn), .i(I_C1), .o(w_bus[1]));
  filter #(.WIDTH(16)) u_c2 (.clk (clk), .rstn(rstn), .i(I_C2), .o(w_bus[2]));
  filter #(.WIDTH(16)) u_err_dr1 (.clk (clk), .rstn(rstn), .i(~I_ERR_DR_1), .o(w_err_dr[1]));
  filter #(.WIDTH(16)) u_err_dr2 (.clk (clk), .rstn(rstn), .i(~I_ERR_DR_2), .o(w_err_dr[2]));
  filter #(.WIDTH(16)) u_err_dr3 (.clk (clk), .rstn(rstn), .i(~I_ERR_DR_3), .o(w_err_dr[3]));
  filter #(.WIDTH(16)) u_err_dr4 (.clk (clk), .rstn(rstn), .i(~I_ERR_DR_4), .o(w_err_dr[4]));
  filter #(.WIDTH(16)) u_err_u (.clk (clk), .rstn(rstn), .i(I_ERR_U), .o(w_err_u));
  filter #(.WIDTH(16)) u_err_i (.clk (clk), .rstn(rstn), .i(I_ERR_I), .o(w_err_i));
  filter #(.WIDTH(16)) u_bt (.clk (clk), .rstn(rstn), .i(~I_BT), .o(w_bt));
  filter #(.WIDTH(16)) u_stop_k (.clk (clk), .rstn(rstn), .i(~I_STOP_K), .o(w_stop_k));

  typedef enum bit [1:0] {
    START_IDLE    = 0,
    START_WAIT15S = 1,
    START_WAIT1S  = 2
  } start_state_t;

  typedef enum bit [2:0] {
    ST_IDLE           = 0,
    ST_CMD_PAUSE      = 1,
    ST_CMD_START      = 2,
    ST_CMD_DISCHARGE0 = 3,
    ST_CMD_DISCHARGE1 = 4,
    ST_CMD_DISCHARGE2 = 5,
    ST_CMD_DISCHARGE3 = 6,
    ST_ERROR          = 7
  } rx_cmd_state_t;

  typedef struct packed {
    bit w_clk;
    rx_cmd_state_t rx_state;
    start_state_t  start_state;
    bit [4:1] o_top;
    bit [4:1] o_bot;
    bit       o_st;
    bit       o_ch;
    bit       o_fan;
    bit       o_break;
    bit       o_avi;
    bit       o_avv;
    bit       o_td;
    bit [4:1] o_erbd;
    bit       o_plus;
    bit       o_minus;
    bit       o_pause_p;
    bit       o_pause_n;
    bit       o_stop;
    bit [31:0] timer;
    bit [31:0] led_timer;
    bit        led_ready;
  } state_t;

  localparam     state_t RES_state = '{
    w_clk: 1'b0,
    rx_state: ST_IDLE,
    start_state: START_IDLE,
    o_top: 4'b0000,
    o_bot: 4'b0000,
    o_st: 1'b0,
    o_ch: 1'b0,
    o_fan: 1'b0,
    o_break: 1'b0,
    o_avi: 1'b0,
    o_avv: 1'b0,
    o_td: 1'b0,
    o_erbd: 4'b0000,
    o_plus: 1'b0,
    o_minus: 1'b0,
    o_pause_p: 1'b0,
    o_pause_n: 1'b0,
    o_stop: 1'b0,
    timer: 32'h00000000,
    led_timer: 32'h00000000,
    led_ready: 1'b0
  };

  localparam     TIMEOUT_15S = FREQ * 15;
  localparam     TIMEOUT_1S  = FREQ * 1;

  localparam     LED_NORMAL  = FREQ;
  localparam     LED_ERROR   = FREQ/8;

  state_t r                  = RES_state;
  state_t rin;

  always_comb begin
    automatic state_t v = r;
    automatic bit is_start;

    v.w_clk = w_clk;

    if (r.led_timer > 0) begin
      v.led_timer = r.led_timer - 1;
    end else begin
      v.led_ready = ~r.led_ready;
      v.led_timer = (r.rx_state == ST_ERROR) ? LED_ERROR : LED_NORMAL;
    end

    if (r.timer > 0) begin
      v.timer = r.timer - 1;
    end

    is_start = (r.start_state != START_IDLE);
    case (r.start_state)
      START_IDLE:;
      START_WAIT15S: begin
        if (r.timer == 32'h00000000) begin
          v.o_st        = 1'b1;
          v.timer       = TIMEOUT_1S;
          v.start_state = START_WAIT1S;
        end
      end
      START_WAIT1S: begin
        if (r.timer == 32'h00000000) begin
          v.o_ch        = 1'b0;
          v.start_state = START_IDLE;
        end
      end
      default:;
    endcase

    if ({r.w_clk, w_clk} == 2'b10) begin
      case (r.rx_state)
        ST_IDLE: begin
          case (w_bus)
            3'h0: begin
              v.rx_state = is_start ? ST_IDLE : ST_CMD_PAUSE;
            end
            3'h1: begin // ST_CMD_PLUS
              if (~is_start && (r.o_st == 1'b1) && (r.o_ch == 1'b0)) begin
                v.o_top     = 4'b0001; // O.TOP1 в HIGH
                v.o_bot     = 4'b0010; // O.BOT2 в HIGH
                v.o_plus    = 1'b1;
                v.o_minus   = 1'b0;
                v.o_pause_p = 1'b0;
                v.o_pause_n = 1'b0;
              end
              v.rx_state = ST_IDLE;
            end
            3'h2: begin // ST_CMD_MINUS
              if (~is_start && (r.o_st == 1'b1) && (r.o_ch == 1'b0)) begin
                // O.TOP2 в HIGH, O.BOT1 в HIGH, все остальные O.TOP и O.BOT в LOW
                v.o_top     = 4'b0010;
                v.o_bot     = 4'b0001;
                v.o_plus    = 1'b0;
                v.o_minus   = 1'b1;
                v.o_pause_p = 1'b0;
                v.o_pause_n = 1'b0;
              end
              v.rx_state = ST_IDLE;
            end
            3'h3: begin // ST_CMD_BALLAST_P
              if (~is_start && (r.o_st == 1'b1) && (r.o_ch == 1'b0)) begin
                // O.TOP3 в HIGH, O.BOT4 в HIGH, все остальные O.TOP и O.BOT в LOW
                v.o_top     = 4'b0100;
                v.o_bot     = 4'b1000;
                v.o_plus    = 1'b0;
                v.o_minus   = 1'b0;
                v.o_pause_p = 1'b1;
                v.o_pause_n = 1'b0;
              end
              v.rx_state = ST_IDLE;
            end
            3'h4: begin // ST_CMD_BALLAST_N
              if (~is_start && (r.o_st == 1'b1) && (r.o_ch == 1'b0)) begin
                // O.TOP4 в HIGH, O.BOT3 в HIGH, все остальные O.TOP и O.BOT в LOW
                v.o_top     = 4'b1000;
                v.o_bot     = 4'b0100;
                v.o_plus    = 1'b0;
                v.o_minus   = 1'b0;
                v.o_pause_p = 1'b0;
                v.o_pause_n = 1'b1;
              end
              v.rx_state = ST_IDLE;
            end
            3'h5: begin
              v.rx_state = is_start ? ST_IDLE : ST_CMD_START;
            end
            3'h6: begin // ST_CMD_SHUTDOWN
              v.start_state = START_IDLE;
              v.timer       = 32'h00000000;
              // O.ST в LOW, O.СH в LOW, O.BOT1-4 и O.TOP1-4 в LOW, O.FAN  в LOW
              v.o_top     = 4'b0000;
              v.o_bot     = 4'b0000;
              v.o_plus    = 1'b0;
              v.o_minus   = 1'b0;
              v.o_pause_p = 1'b0;
              v.o_pause_n = 1'b0;
              v.o_st      = 1'b0;
              v.o_ch      = 1'b0;
              v.o_fan     = 1'b0;
              v.rx_state  = ST_IDLE;
            end
            3'h7: begin
              v.rx_state = is_start ? ST_IDLE : ST_CMD_DISCHARGE0;
            end
            default: begin
              v.rx_state = ST_IDLE;
            end
          endcase // case (w_bus)
        end // case: ST_IDLE
        ST_CMD_PAUSE: begin
          if (w_bus == 3'h0) begin
            v.o_top     = 4'b0000;
            v.o_bot     = 4'b0000;
            v.o_plus    = 1'b0;
            v.o_minus   = 1'b0;
            v.o_pause_p = 1'b0;
            v.o_pause_n = 1'b0;
          end
          v.rx_state = ST_IDLE;
        end // case: ST_CMD_PAUSE
        ST_CMD_START: begin
          if (w_bus == 3'h0) begin
            v.o_top       = 4'b0000;
            v.o_bot       = 4'b0000;
            v.o_plus      = 1'b0;
            v.o_minus     = 1'b0;
            v.o_pause_p   = 1'b0;
            v.o_pause_n   = 1'b0;
            // O.FAN  в HIGH, O.ST в LOW, O.СH в HIGH
            v.o_fan       = 1'b1;
            v.o_st        = 1'b0;
            v.o_ch        = 1'b1;
            v.start_state = START_WAIT15S;
            v.timer       = TIMEOUT_15S;
          end
          v.rx_state    = ST_IDLE;
        end // case: ST_CMD_START
        ST_CMD_DISCHARGE0: begin
          v.rx_state = (w_bus == 3'h0) ? ST_CMD_DISCHARGE1 : ST_IDLE;
        end
        ST_CMD_DISCHARGE1: begin
          v.rx_state = (w_bus == 3'h7) ? ST_CMD_DISCHARGE2 : ST_IDLE;
        end
        ST_CMD_DISCHARGE2: begin
          v.rx_state = (w_bus == 3'h0) ? ST_CMD_DISCHARGE3 : ST_IDLE;
        end
        ST_CMD_DISCHARGE3: begin
          if ((r.o_st == 1'b0) && (r.o_ch == 1'b0)) begin
            case (w_bus)
              3'h1: begin // команда 70701
                // O.TOP1 в HIGH, O.BOT2 в HIGH, все остальные O.TOP и O.BOT в LOW
                v.o_top     = 4'b0001;
                v.o_bot     = 4'b0010;
                v.o_plus    = 1'b1;
                v.o_minus   = 1'b0;
                v.o_pause_p = 1'b0;
                v.o_pause_n = 1'b0;
              end
              3'h3: begin // команда 70703
                // O.TOP3 в HIGH, O.BOT4 в HIGH, все остальные O.TOP и O.BOT в LOW
                v.o_top     = 4'b0100;
                v.o_bot     = 4'b1000;
                v.o_plus    = 1'b1;
                v.o_minus   = 1'b0;
                v.o_pause_p = 1'b0;
                v.o_pause_n = 1'b0;
              end
              default:;
            endcase
          end
          v.rx_state = ST_IDLE;
        end // case: ST_CMD_DISCHARGE3
        ST_ERROR:;
        default:;
      endcase
    end

    // I.ERR_DR_1-4, I.ERR_U, I.ERR_I, I.BT, I.STOP_K
    if (|{w_err_dr[4:1], w_err_u, w_err_i, w_bt, w_stop_k}) begin
      // O.FAN в HIGH, O.BOT1-4 и O.TOP1-4 в LOW, O.ST в LOW, O.СH в LOW
      v.o_fan     = 1'b1;
      v.o_bot     = 4'b0000;
      v.o_top     = 4'b0000;
      v.o_st      = 1'b0;
      v.o_ch      = 1'b0;
      v.o_break   = 1'b1;
      v.o_plus    = 1'b0;
      v.o_minus   = 1'b0;
      v.o_pause_p = 1'b0;
      v.o_pause_n = 1'b0;
      v.rx_state  = ST_ERROR;
    end

    if (w_stop_k) begin
      v.o_stop = 1'b1;
    end

    rin = v;
  end

  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) begin
      r <= RES_state;
    end else begin
      r <= rin;
    end
  end

  assign O_BOT_1   = r.o_bot[1];
  assign O_BOT_2   = r.o_bot[2];
  assign O_BOT_3   = r.o_bot[3];
  assign O_BOT_4   = r.o_bot[4];

  assign O_TOP_1   = r.o_top[1];
  assign O_TOP_2   = r.o_top[2];
  assign O_TOP_3   = r.o_top[3];
  assign O_TOP_4   = r.o_top[4];

  assign O_AVI     = w_err_i;
  assign O_AVV     = w_err_u;
  assign O_TD      = w_bt;

  assign O_ERBD1   = w_err_dr[1];
  assign O_ERBD2   = w_err_dr[2];
  assign O_ERBD3   = w_err_dr[3];
  assign O_ERBD4   = w_err_dr[4];

  assign O_BREAK   = r.o_break;
  assign O_MINUS   = r.o_minus;
  assign O_PLUS    = r.o_plus;
  assign O_PAUSE_P = r.o_pause_p;
  assign O_PAUSE_N = r.o_pause_n;
  assign O_CHARGE  = r.o_ch;
  assign O_CH      = r.o_ch;

  assign O_FAN     = r.o_fan;
  assign O_STOP    = r.o_stop;
  assign O_START   = r.o_st;
  assign O_ST      = r.o_st;

  assign led_ready = r.led_ready;
  assign led_done  = (r.rx_state == ST_IDLE);

endmodule
`default_nettype wire
