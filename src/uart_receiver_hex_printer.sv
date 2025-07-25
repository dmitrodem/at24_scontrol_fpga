`default_nettype none
module uart_receiver_hex_printer (
   input logic clk,    // System clock
   input logic rst_n,  // Active-low reset
   input logic uart_rx // UART receive line
);

  // Parameters for 115200 baud at given clock frequency
  parameter CLK_FREQ = 50_000_000;  // Default 50 MHz, adjust according to your system
  parameter BAUD_RATE = 115200;
  parameter BAUD_PERIOD = CLK_FREQ / BAUD_RATE - 1;

  // UART receiver states
  typedef enum logic [2:0] {
    IDLE,
    START_BIT,
    DATA_BITS,
    STOP_BIT
  } uart_state_t;

  // Internal signals
  uart_state_t state;
  logic [7:0] rx_data;
  logic [2:0] bit_count;
  logic [31:0] baud_counter;
  logic        sample_point;
  logic        data_valid;

  // UART receiver state machine
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      rx_data <= 8'h00;
      bit_count <= 'd0;
      baud_counter <= 'd0;
      data_valid <= 1'b0;
    end else begin
      // Default assignments
      data_valid <= 1'b0;
      sample_point <= 1'b0;

      // Baud counter logic
      if (baud_counter == BAUD_PERIOD) begin
        baud_counter <= 'd0;
        sample_point <= 1'b1;
      end else begin
        baud_counter <= baud_counter + 'd1;
      end

      // State machine
      case (state)
        IDLE: begin
          if (!uart_rx) begin  // Start bit detected (falling edge)
            state <= START_BIT;
            baud_counter <= 'd0;
          end
        end

        START_BIT: begin
          if (sample_point) begin
            // Sample start bit in the middle
            if (!uart_rx) begin
              state <= DATA_BITS;
              bit_count <= 'd0;
            end else begin
              state <= IDLE;  // False start
            end
          end
        end

        DATA_BITS: begin
          if (sample_point) begin
            // Sample data bits (LSB first)
            rx_data[bit_count] <= uart_rx;
            if (bit_count == 'd7) begin
              state <= STOP_BIT;
            end else begin
              bit_count <= bit_count + 'd1;
            end
          end
        end

        STOP_BIT: begin
          if (sample_point) begin
            // Sample stop bit (should be high)
            if (uart_rx) begin
              data_valid <= 1'b1;
            end
            state <= IDLE;
          end
        end

        default: state <= IDLE;
      endcase
    end
  end

  // Print received bytes as hex to console
  always_ff @(posedge clk) begin
    if (data_valid) begin
      $display("Received byte: 0x%h", rx_data);
    end
  end

endmodule
`default_nettype wire
