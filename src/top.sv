`default_nettype none

`define SYNC_RESET

module top #(
  parameter FREQ         = 50000000,
  parameter FILTER_WIDTH = 8,
  parameter WAITSTATES   = 50
) (
  input wire  clk,        // E2
  input wire  rst,        // H11
  // input wire  uart_rx,    // B3
  output wire uart_tx,    // C10
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

  filter #(.WIDTH(FILTER_WIDTH)) u_clk (.clk (clk), .rstn(rstn), .i(~I_CLK), .o(w_clk));
  filter #(.WIDTH(FILTER_WIDTH)) u_c0 (.clk (clk), .rstn(rstn), .i(~I_C0), .o(w_bus[0]));
  filter #(.WIDTH(FILTER_WIDTH)) u_c1 (.clk (clk), .rstn(rstn), .i(~I_C1), .o(w_bus[1]));
  filter #(.WIDTH(FILTER_WIDTH)) u_c2 (.clk (clk), .rstn(rstn), .i(~I_C2), .o(w_bus[2]));
  filter #(.WIDTH(FILTER_WIDTH)) u_err_dr1 (.clk (clk), .rstn(rstn), .i(~I_ERR_DR_1), .o(w_err_dr[1]));
  filter #(.WIDTH(FILTER_WIDTH)) u_err_dr2 (.clk (clk), .rstn(rstn), .i(~I_ERR_DR_2), .o(w_err_dr[2]));
  filter #(.WIDTH(FILTER_WIDTH)) u_err_dr3 (.clk (clk), .rstn(rstn), .i(~I_ERR_DR_3), .o(w_err_dr[3]));
  filter #(.WIDTH(FILTER_WIDTH)) u_err_dr4 (.clk (clk), .rstn(rstn), .i(~I_ERR_DR_4), .o(w_err_dr[4]));
  filter #(.WIDTH(FILTER_WIDTH)) u_err_u (.clk (clk), .rstn(rstn), .i(~I_ERR_U), .o(w_err_u));
  filter #(.WIDTH(FILTER_WIDTH)) u_err_i (.clk (clk), .rstn(rstn), .i(~I_ERR_I), .o(w_err_i));
  filter #(.WIDTH(FILTER_WIDTH)) u_bt (.clk (clk), .rstn(rstn), .i(I_BT), .o(w_bt));
  filter #(.WIDTH(FILTER_WIDTH)) u_stop_k (.clk (clk), .rstn(rstn), .i(~I_STOP_K), .o(w_stop_k));

  localparam     TIMEOUT_15S     = (FREQ * 15) - 1;
  localparam     TIMEOUT_1S      = (FREQ * 1) - 1;
  localparam     TIMEOUT_2S      = (FREQ * 2) - 1;
  localparam     TIMER_WIDTH     = $clog2(TIMEOUT_15S + 1);

  localparam     LED_NORMAL      = (FREQ) - 1;
  localparam     LED_ERROR       = (FREQ/8) - 1;
  localparam     LED_TIMER_WIDTH = $clog2(LED_NORMAL + 1);

  localparam     PWM_WIDTH       = 19;

  localparam     PWM_ALL         = 262144;
  localparam     PWM_1           = PWM_ALL/2; //5%
  localparam     PWM_2           = PWM_ALL/2; //10%
  localparam     PWM_3           = PWM_ALL/2;
  localparam     PWM_4           = PWM_ALL/2;
  localparam     PWM_5           = PWM_ALL;
  localparam     PWM_6           = PWM_ALL;
  localparam     PWM_7           = PWM_ALL;
  localparam     PWM_8           = PWM_ALL;
  localparam     PWM_9           = PWM_ALL+PWM_ALL/2;
  localparam     PWM_10          = PWM_ALL+PWM_ALL/2;
  localparam     PWM_11          = PWM_ALL+PWM_ALL/2;
  localparam     PWM_12          = PWM_ALL*2-1;
  localparam     PWM_13          = PWM_ALL*2-1;
  localparam     PWM_14          = PWM_ALL*2-1;
  localparam     PWM_15          = PWM_ALL*2-1;

  typedef enum bit [7:0] {
    START_IDLE   = 0,
    START_PWM_1  = 1,
    START_PWM_2  = 2,
    START_PWM_3  = 3,
    START_PWM_4  = 4,
    START_PWM_5  = 5,
    START_PWM_6  = 6,
    START_PWM_7  = 7,
    START_PWM_8  = 8,
    START_PWM_9  = 9,
    START_PWM_10 = 10,
    START_PWM_11 = 11,
    START_PWM_12 = 12,
    START_PWM_13 = 13,
    START_PWM_14 = 14,
    START_PWM_15 = 15,
    START_WAIT1S = 16
  } start_state_t;

  typedef enum bit [3:0] {
    ST_IDLE           = 0,
    ST_CMD_PAUSE      = 1,
    ST_CMD_START      = 2,
    ST_CMD_DISCHARGE0 = 3,
    ST_CMD_DISCHARGE1 = 4,
    ST_CMD_DISCHARGE2 = 5,
    ST_ERROR          = 6
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
    bit [TIMER_WIDTH-1:0] timer;
    bit [LED_TIMER_WIDTH-1:0] led_timer;
    bit                       led_ready;
    bit [11:0]                ws;
    bit [4:1]                 nxt_top;
    bit [4:1]                 nxt_bot;
    bit                       nxt_plus;
    bit                       nxt_minus;
    bit                       nxt_pause_p;
    bit                       nxt_pause_n;
    bit                       update_outputs;
    bit                       device_ready;
    bit [PWM_WIDTH-1:0]       pwm_counter;
    bit [PWM_WIDTH-1:0]       pwm_value;
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
    timer: {TIMER_WIDTH{1'b0}},
    led_timer: {LED_TIMER_WIDTH{1'b0}},
    led_ready: 1'b0,
    ws : 12'h0,
    nxt_top: 4'b0000,
    nxt_bot: 4'b0000,
    nxt_plus: 1'b0,
    nxt_minus: 1'b0,
    nxt_pause_p: 1'b0,
    nxt_pause_n: 1'b0,
    update_outputs: 1'b0,
    device_ready: 1'b0,
    pwm_counter: {PWM_WIDTH{1'b0}},
    pwm_value: {PWM_WIDTH{1'b0}}
  };

  state_t r = RES_state;
  state_t rin;

  // synthesis translate_off
  typedef struct  {
    string msg;
    bit    send;
  } mailbox_t;

  mailbox_t rm;
  mailbox_t rmin;
  // synthesis translate_on

  /* verilator lint_off MULTIDRIVEN */
  task sendmsg (input string msg);
    begin
      // synthesis translate_off
      rmin.send = 1'b1;
      rmin.msg  = msg;
      // synthesis translate_on
    end
  endtask

`define X_PAUSE(v)         \
begin                      \
    v.o_top     = 4'b0000; \
    v.o_bot     = 4'b0000; \
    v.o_plus    = 1'b0;    \
    v.o_minus   = 1'b0;    \
    v.o_pause_p = 1'b0;    \
    v.o_pause_n = 1'b0;    \
end

  always_comb begin : x_comb
    automatic state_t v = r;

    automatic bit is_start;

    v.w_clk   = w_clk;

    // synthesis translate_off
    rmin.send = 1'b0;
    rmin.msg  = "";
    // synthesis translate_on

    v.pwm_counter = r.pwm_counter + 1;

    if (r.timer > 0) begin
      v.timer = r.timer - 1;
    end

    is_start = (r.start_state != START_IDLE);
    case (r.start_state)
      START_IDLE:;
      START_PWM_1: begin
        if (|r.timer == 1'b0) begin
          v.pwm_value   = PWM_2;
          v.timer       = TIMEOUT_2S;
          v.start_state = START_PWM_2;
        end
      end
      START_PWM_2: begin
        if (|r.timer == 1'b0) begin
          v.pwm_value   = PWM_3;
          v.timer       = TIMEOUT_2S;
          v.start_state = START_PWM_3;
        end
      end
      START_PWM_3: begin
        if (|r.timer == 1'b0) begin
          v.pwm_value   = PWM_4;
          v.timer       = TIMEOUT_2S;
          v.start_state = START_PWM_4;
        end
      end
      START_PWM_4: begin
        if (|r.timer == 1'b0) begin
          v.pwm_value   = PWM_5;
          v.timer       = TIMEOUT_2S;
          v.start_state = START_PWM_5;
        end
      end
      START_PWM_5: begin
        if (|r.timer == 1'b0) begin
          v.pwm_value   = PWM_6;
          v.timer       = TIMEOUT_2S;
          v.start_state = START_PWM_6;
        end
      end
      START_PWM_6: begin
        if (|r.timer == 1'b0) begin
          v.pwm_value   = PWM_7;
          v.timer       = TIMEOUT_2S;
          v.start_state = START_PWM_7;
        end
      end
      START_PWM_7: begin
        if (|r.timer == 1'b0) begin
          v.pwm_value   = PWM_8;
          v.timer       = TIMEOUT_2S;
          v.start_state = START_PWM_8;
        end
      end
      START_PWM_8: begin
        if (|r.timer == 1'b0) begin
          v.pwm_value   = PWM_9;
          v.timer       = TIMEOUT_2S;
          v.start_state = START_PWM_9;
        end
      end
      START_PWM_9: begin
        if (|r.timer == 1'b0) begin
          v.pwm_value   = PWM_10;
          v.timer       = TIMEOUT_2S;
          v.start_state = START_PWM_10;
        end
      end
      START_PWM_10: begin
        if (|r.timer == 1'b0) begin
          v.pwm_value   = PWM_11;
          v.timer       = TIMEOUT_2S;
          v.start_state = START_PWM_11;
        end
      end
      START_PWM_11: begin
        if (|r.timer == 1'b0) begin
          v.pwm_value   = PWM_12;
          v.timer       = TIMEOUT_2S;
          v.start_state = START_PWM_12;
        end
      end
      START_PWM_12: begin
        if (|r.timer == 1'b0) begin
          v.pwm_value   = PWM_13;
          v.timer       = TIMEOUT_2S;
          v.start_state = START_PWM_13;
        end
      end
      START_PWM_13: begin
        if (|r.timer == 1'b0) begin
          v.pwm_value   = PWM_14;
          v.timer       = TIMEOUT_2S;
          v.start_state = START_PWM_14;
        end
      end
      START_PWM_14: begin
        if (|r.timer == 1'b0) begin
          v.pwm_value   = PWM_15;
          v.timer       = TIMEOUT_2S;
          v.start_state = START_PWM_15;
        end
      end
      START_PWM_15: begin
        if (|r.timer == 1'b0) begin
          v.o_st        = 1'b1;
          v.timer       = TIMEOUT_2S;
          v.start_state = START_WAIT1S;
        end
      end
      START_WAIT1S: begin
        if (|r.timer == 1'b0) begin
          v.o_ch         = 1'b0;
          v.pwm_value    = {PWM_WIDTH{1'b0}};
          v.device_ready = 1'b1;
          v.start_state  = START_IDLE;
        end
      end
      default:;
    endcase

    if (|r.ws) begin
      v.ws = r.ws - 1;
    end else if (r.update_outputs) begin
      v.update_outputs = 1'b0;
      v.o_top     = r.nxt_top;
      v.o_bot     = r.nxt_bot;
      v.o_plus    = r.nxt_plus;
      v.o_minus   = r.nxt_minus;
      v.o_pause_p = r.nxt_pause_p;
      v.o_pause_n = r.nxt_pause_n;
    end

    if ({r.w_clk, w_clk} == 2'b10) begin
      case (r.rx_state)
        ST_IDLE: begin
          if (~r.update_outputs) begin
            case (w_bus)
              3'h0: begin // ST_CMD_PAUSE
                if (~is_start) begin
                  sendmsg("CMD_PAUSE");
                  `X_PAUSE(v);
                end
                v.rx_state  = ST_IDLE;
              end
              3'h1: begin // ST_CMD_PLUS
                if (~is_start && r.device_ready) begin
                  sendmsg("CMD_PLUS");
                  v.nxt_top     = 4'b0001; // O.TOP1 в HIGH
                  v.nxt_bot     = 4'b0010; // O.BOT2 в HIGH
                  v.nxt_plus    = 1'b1;
                  v.nxt_minus   = 1'b0;
                  v.nxt_pause_p = 1'b0;
                  v.nxt_pause_n = 1'b0;
                  `X_PAUSE(v);
                  v.ws = WAITSTATES;
                  v.update_outputs = 1'b1;
                end
                v.rx_state = ST_IDLE;
              end
              3'h2: begin // ST_CMD_MINUS
                if (~is_start && r.device_ready) begin
                  // O.TOP2 в HIGH, O.BOT1 в HIGH, все остальные O.TOP и O.BOT в LOW
                  sendmsg("CMD_MINUS");
                  v.nxt_top     = 4'b0010;
                  v.nxt_bot     = 4'b0001;
                  v.nxt_plus    = 1'b0;
                  v.nxt_minus   = 1'b1;
                  v.nxt_pause_p = 1'b0;
                  v.nxt_pause_n = 1'b0;
                  `X_PAUSE(v);
                  v.ws = WAITSTATES;
                  v.update_outputs = 1'b1;
                end
                v.rx_state = ST_IDLE;
              end
              3'h3: begin // ST_CMD_BALLAST_P
                if (~is_start && r.device_ready) begin
                  // O.TOP3 в HIGH, O.BOT4 в HIGH, все остальные O.TOP и O.BOT в LOW
                  sendmsg("CMD_BALLAST_P");
                  v.nxt_top     = 4'b0100;
                  v.nxt_bot     = 4'b1000;
                  v.nxt_plus    = 1'b0;
                  v.nxt_minus   = 1'b0;
                  v.nxt_pause_p = 1'b1;
                  v.nxt_pause_n = 1'b0;
                  `X_PAUSE(v);
                  v.ws = WAITSTATES;
                  v.update_outputs = 1'b1;
                end
                v.rx_state = ST_IDLE;
              end
              3'h4: begin // ST_CMD_BALLAST_N
                if (~is_start && r.device_ready) begin
                  // O.TOP4 в HIGH, O.BOT3 в HIGH, все остальные O.TOP и O.BOT в LOW
                  sendmsg("CMD_BALLAST_N");
                  v.nxt_top     = 4'b1000;
                  v.nxt_bot     = 4'b0100;
                  v.nxt_plus    = 1'b0;
                  v.nxt_minus   = 1'b0;
                  v.nxt_pause_p = 1'b0;
                  v.nxt_pause_n = 1'b1;
                  `X_PAUSE(v);
                  v.ws = WAITSTATES;
                  v.update_outputs = 1'b1;
                end
                v.rx_state = ST_IDLE;
              end
              3'h5: begin
                v.rx_state = is_start ? ST_IDLE : ST_CMD_START;
              end
              3'h6: begin // ST_CMD_SHUTDOWN
                v.start_state = START_IDLE;
                v.timer       = {TIMER_WIDTH{1'b0}};
                // O.ST в LOW, O.СH в LOW, O.BOT1-4 и O.TOP1-4 в LOW, O.FAN  в LOW
                sendmsg("CMD_SHUTDOWN");
                `X_PAUSE(v);
                v.o_st         = 1'b0;
                v.o_ch         = 1'b0;
                v.pwm_value    = {PWM_WIDTH{1'b0}};
                v.o_fan        = 1'b0;
                v.device_ready = 1'b0;
                v.rx_state     = ST_IDLE;
              end
              3'h7: begin
                v.rx_state = is_start ? ST_IDLE : ST_CMD_DISCHARGE0;
              end
              default: begin
                sendmsg("CMD_UNKNOWN");
                v.rx_state = ST_IDLE;
              end
            endcase // case (w_bus)
          end // if (~r.update_outputs)
        end // case: ST_IDLE
        ST_CMD_START: begin
          if (w_bus == 3'h0) begin
            sendmsg("CMD_START");
            `X_PAUSE(v);
            // O.FAN  в HIGH, O.ST в LOW, O.СH в HIGH
            v.o_fan       = 1'b1;
            v.o_st        = 1'b0;
            v.o_ch        = 1'b1;
            v.pwm_value   = PWM_1;
            v.start_state = START_PWM_1;
            v.timer       = TIMEOUT_2S;
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
          if (w_bus == 3'h0) begin
            v.device_ready = 1'b1;
          end
          v.rx_state = ST_IDLE;
        end
        ST_ERROR:;
        default:;
      endcase
    end

    // I.ERR_DR_1-4, I.ERR_U, I.ERR_I, I.BT, I.STOP_K
    if (|{w_err_dr[4:1], w_err_u, w_err_i, w_bt, w_stop_k}) begin
      // O.FAN в HIGH, O.BOT1-4 и O.TOP1-4 в LOW, O.ST в LOW, O.СH в LOW
      v          = RES_state;
      v.rx_state = ST_ERROR;
      v.o_fan    = 1'b1;
      v.o_break  = 1'b1;
    end

    v.o_stop = w_stop_k ? 1'b1: r.o_stop;
    v.o_avv  = w_err_u  ? 1'b1: r.o_avv;
    v.o_avi  = w_err_i  ? 1'b1: r.o_avi;
    v.o_td   = w_bt     ? 1'b1: r.o_td;
    for (int i = 1; i < 5; i = i + 1)
      v.o_erbd[i] = w_err_dr[i] ? 1'b1: r.o_erbd[i];

`ifdef SYNC_RESET
    if (~rstn) begin
      v = RES_state;
    end
`endif                          // `SYNC_RESET

    // led_timer работает без сброса
    if (|r.led_timer) begin
      v.led_timer = r.led_timer - 1;
    end else begin
      v.led_ready = ~r.led_ready;
      v.led_timer = (r.rx_state == ST_ERROR) ? LED_ERROR : LED_NORMAL;
    end

    rin = v;
  end

`ifdef SYNC_RESET
  always_ff @(posedge clk) begin : x_sync_reset
      r <= rin;
  end
`else                           // ~`SYNC_RESET
  always_ff @(posedge clk or negedge rstn) begin : x_async_reset
    if (~rstn) begin
      r <= RES_state;
    end else begin
      r <= rin;
    end
  end
`endif                          // `SYNC_RESET

  // synthesis translate_off
  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) begin
      rm.msg <= "";
      rm.send <= 1'b0;
    end else begin
      rm <= rmin;
      if (rm.send)
        $display("%t :: %s", $time, rm.msg);
    end
  end
  // synthesis translate_on

  assign O_BOT_1   = r.o_bot[1];
  assign O_BOT_2   = r.o_bot[2];
  assign O_BOT_3   = r.o_bot[3];
  assign O_BOT_4   = r.o_bot[4];

  assign O_TOP_1   = r.o_top[1];
  assign O_TOP_2   = r.o_top[2];
  assign O_TOP_3   = r.o_top[3];
  assign O_TOP_4   = r.o_top[4];

  assign O_AVI     = r.o_avi;
  assign O_AVV     = r.o_avv;
  assign O_TD      = r.o_td;

  assign O_ERBD1   = r.o_erbd[1];
  assign O_ERBD2   = r.o_erbd[2];
  assign O_ERBD3   = r.o_erbd[3];
  assign O_ERBD4   = r.o_erbd[4];

  assign O_BREAK   = r.o_break;
  assign O_MINUS   = r.o_minus;
  assign O_PLUS    = r.o_plus;
  assign O_PAUSE_P = r.o_pause_p;
  assign O_PAUSE_N = r.o_pause_n;
  assign O_CHARGE  = r.o_ch;
  assign O_CH      = r.o_ch & ((r.pwm_counter < r.pwm_value) | (&r.pwm_value == 1'b1));

  assign O_FAN     = r.o_fan;
  assign O_STOP    = r.o_stop;
  assign O_START   = r.o_st;
  assign O_ST      = r.o_st;

  assign led_ready = r.led_ready;


  reg [25:0] dbg_cnt;
  always @(posedge clk) begin : dbg_led
    dbg_cnt <= dbg_cnt + 1;
  end
  assign led_done  = dbg_cnt[25];

  typedef struct packed {
    bit [15:0] prescaler;
    bit [15:0] holdreg;
    bit        tick;
    bit [3:0]  state;
    bit [5:0]  char_state;
    state_t c;
    bit [31:0] timer;
    bit [31:0] led_timer;
    bit [31:0] pwm_counter;
    bit [31:0] pwm_value;
  } uart_t;

  localparam uart_t RES_uart = '{
    prescaler: 16'h0,
    holdreg: {16{1'b1}},
    tick: 1'b0,
    state: 4'h0,
    char_state: 6'h0,
    c: RES_state,
    timer: 32'h0,
    led_timer: 32'h0,
    pwm_counter: 32'h0,
    pwm_value: 32'h0
  };

  uart_t ru = RES_uart;
  uart_t ru_in;

  always_comb begin
    automatic uart_t v = ru;
    v.tick = 1'b0;
    if (ru.prescaler > 0) begin
      v.prescaler = ru.prescaler - 'd1;
    end else begin
      v.prescaler = 16'd433;
      v.tick      = 1'b1;
      v.state     = ru.state + 'd1;
      if (ru.state == 0) begin
        case (ru.char_state)
          'h00: begin
            v.holdreg     = {{7{1'b1}}, "S", 1'b0};
            v.c           = r;
            v.timer       = r.timer;
            v.led_timer   = r.led_timer;
            v.pwm_counter = r.pwm_counter;
            v.pwm_value   = r.pwm_value;
          end
          'h01: v.holdreg = {{7{1'b1}}, {4'h0, ru.c.rx_state}, 1'b0};
          'h02: v.holdreg = {{7{1'b1}}, {ru.c.start_state}, 1'b0};
          'h03: v.holdreg = {{7{1'b1}}, {4'h0, ru.c.o_top}, 1'b0};
          'h04: v.holdreg = {{7{1'b1}}, {4'h0, ru.c.o_bot}, 1'b0};
          'h05: v.holdreg = {{7{1'b1}}, {1'b0, ru.c.o_st, ru.c.o_ch, ru.c.o_fan, ru.c.o_break, ru.c.o_avi, ru.c.o_avv, ru.c.o_td}, 1'b0};
          'h06: v.holdreg = {{7{1'b1}}, {4'h0, ru.c.o_erbd}, 1'b0};
          'h07: v.holdreg = {{7{1'b1}}, {4'b0, ru.c.o_plus, ru.c.o_minus, ru.c.o_pause_p, ru.c.o_pause_n}, 1'b0};
          'h08: v.holdreg = {{7{1'b1}}, {7'b0, ru.c.o_stop}, 1'b0};
          'h09: v.holdreg = {{7{1'b1}}, {ru.timer[31:24]}, 1'b0};
          'h0a: v.holdreg = {{7{1'b1}}, {ru.timer[23:16]}, 1'b0};
          'h0b: v.holdreg = {{7{1'b1}}, {ru.timer[15:8]}, 1'b0};
          'h0c: v.holdreg = {{7{1'b1}}, {ru.timer[7:0]}, 1'b0};
          'h0d: v.holdreg = {{7{1'b1}}, {ru.led_timer[31:24]}, 1'b0};
          'h0e: v.holdreg = {{7{1'b1}}, {ru.led_timer[23:16]}, 1'b0};
          'h0f: v.holdreg = {{7{1'b1}}, {ru.led_timer[15:8]}, 1'b0};
          'h10: v.holdreg = {{7{1'b1}}, {ru.led_timer[7:0]}, 1'b0};
          'h11: v.holdreg = {{7{1'b1}}, {7'b0, ru.c.led_ready}, 1'b0};
          'h12: v.holdreg = {{7{1'b1}}, {4'b0, ru.c.ws[11:8]}, 1'b0};
          'h13: v.holdreg = {{7{1'b1}}, {ru.c.ws[7:0]}, 1'b0};
          'h14: v.holdreg = {{7{1'b1}}, {4'b0, ru.c.nxt_top}, 1'b0};
          'h15: v.holdreg = {{7{1'b1}}, {4'b0, ru.c.nxt_bot}, 1'b0};
          'h16: v.holdreg = {{7{1'b1}}, {4'b0, ru.c.nxt_plus, ru.c.nxt_minus, ru.c.nxt_pause_p, ru.c.nxt_pause_n}, 1'b0};
          'h17: v.holdreg = {{7{1'b1}}, {6'b0, ru.c.update_outputs, ru.c.device_ready}, 1'b0};
          'h18: v.holdreg = {{7{1'b1}}, {6'b0, ru.c.update_outputs, ru.c.device_ready}, 1'b0};
          'h19: v.holdreg = {{7{1'b1}}, {ru.pwm_counter[31:24]}, 1'b0};
          'h1a: v.holdreg = {{7{1'b1}}, {ru.pwm_counter[23:16]}, 1'b0};
          'h1b: v.holdreg = {{7{1'b1}}, {ru.pwm_counter[15:8]}, 1'b0};
          'h1c: v.holdreg = {{7{1'b1}}, {ru.pwm_counter[7:0]}, 1'b0};
          'h1d: v.holdreg = {{7{1'b1}}, {ru.pwm_value[31:24]}, 1'b0};
          'h1e: v.holdreg = {{7{1'b1}}, {ru.pwm_value[23:16]}, 1'b0};
          'h1f: v.holdreg = {{7{1'b1}}, {ru.pwm_value[15:8]}, 1'b0};
          'h20: v.holdreg = {{7{1'b1}}, {ru.pwm_value[7:0]}, 1'b0};
          'h21: v.holdreg = {{7{1'b1}}, "s", 1'b0};
        endcase // case (r.char_state)
        if (ru.char_state == 'h21) begin
          v.char_state = 'h0;
        end else begin
          v.char_state = ru.char_state + 'd1;
        end
      end else begin
        v.holdreg = {1'b1, ru.holdreg[15:1]};
      end
    end
    ru_in = v;
  end

  always_ff @(posedge clk) begin
    ru <= ru_in;
  end

  // wire uart_tx;
  assign uart_tx = ru.holdreg[0];

endmodule
`default_nettype wire
