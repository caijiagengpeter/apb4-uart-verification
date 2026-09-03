//=============================================================================
// Module Name: uart_receiver
//=============================================================================
// Description: UART receiver with configurable baud rate, data width,
//              stop bits, and parity checking support.
//
// Features:
// - Configurable baud rate detection
// - Configurable data width (5-8 bits)
// - Configurable stop bits (1-2 bits)
// - Optional parity checking (even/odd)
// - Error detection (parity, framing)
// - Busy status indication
// - Automatic reception timing
//
// Author: shivaram@vyges.com
// License: Apache-2.0
//=============================================================================

module uart_receiver #(
    parameter int CLOCK_FREQUENCY = 50_000_000,
    parameter int BAUD_RATE       = 115_200,
    parameter int DATA_WIDTH      = 8,
    parameter int STOP_BITS       = 1,
    parameter bit PARITY_ENABLE   = 1'b0,
    parameter string PARITY_TYPE  = "even"
) (
    //-------------------------------------------------------------------------
    // Clock and Reset
    //-------------------------------------------------------------------------
    input  logic                    clk_i,
    input  logic                    reset_n_i,

    //-------------------------------------------------------------------------
    // Control Interface
    //-------------------------------------------------------------------------
    input  logic                    enable_i,

    //-------------------------------------------------------------------------
    // UART Interface
    //-------------------------------------------------------------------------
    input  logic                    rx_i,
    output logic [DATA_WIDTH-1:0]   data_o,
    output logic                    done_o,
    output logic                    busy_o,
    output logic                    parity_err_o,
    output logic                    frame_err_o
);

    //-------------------------------------------------------------------------
    // Local parameters
    //-------------------------------------------------------------------------
    localparam int BAUD_DIVIDER =
        CLOCK_FREQUENCY / BAUD_RATE;

    localparam int BIT_COUNTER_WIDTH =
        $clog2(BAUD_DIVIDER);

    localparam int SAMPLE_POINT =
        BAUD_DIVIDER / 2;

    localparam int FRAME_BITS =
        DATA_WIDTH + STOP_BITS + (PARITY_ENABLE ? 1 : 0);

    localparam int FRAME_COUNTER_WIDTH =
        $clog2(FRAME_BITS);

    //-------------------------------------------------------------------------
    // State machine states
    //-------------------------------------------------------------------------
    typedef enum logic [2:0] {
        IDLE,
        START_BIT,
        DATA_BITS,
        PARITY_BIT,
        STOP_STATE
    } rx_state_t;

    //-------------------------------------------------------------------------
    // Internal signals
    //-------------------------------------------------------------------------
    rx_state_t rx_state;
    rx_state_t rx_next_state;

    logic [BIT_COUNTER_WIDTH-1:0]   bit_counter;
    logic [FRAME_COUNTER_WIDTH-1:0] frame_counter;

    logic [DATA_WIDTH-1:0] rx_data_reg;
    logic [DATA_WIDTH-1:0] rx_data_out;

    logic bit_tick;
    logic sample_tick;

    // Synchronization signals
    logic rx_sync;
    logic rx_prev;

    // Parity signals
    logic parity_bit;
    logic expected_parity;

    // Frame validation
    logic frame_valid;

    // Done pulse
    logic done_pulse;

    //-------------------------------------------------------------------------
    // Output assignments
    //-------------------------------------------------------------------------
    assign busy_o = (rx_state != IDLE);
    assign data_o = rx_data_out;
    assign done_o = done_pulse;

    //-------------------------------------------------------------------------
    // Input synchronization
    //
    // rx_i is asynchronous with respect to clk_i.
    // Use two flip-flops to synchronize RXD into the system clock domain.
    //-------------------------------------------------------------------------
    always_ff @(posedge clk_i or negedge reset_n_i) begin
        if (!reset_n_i) begin
            rx_sync <= 1'b1;
            rx_prev <= 1'b1;
        end
        else begin
            rx_sync <= rx_i;
            rx_prev <= rx_sync;
        end
    end

    //-------------------------------------------------------------------------
    // Baud rate counter
    //
    // BAUD_DIVIDER:
    //     CLOCK_FREQUENCY / BAUD_RATE
    //
    // For 50 MHz / 115200:
    //     BAUD_DIVIDER ≈ 434
    //
    // sample_tick:
    //     generated approximately at the middle of a UART bit.
    //
    // bit_tick:
    //     generated at the end of one UART bit period.
    //-------------------------------------------------------------------------
    always_ff @(posedge clk_i or negedge reset_n_i) begin
        if (!reset_n_i) begin
            bit_counter <= '0;
            bit_tick    <= 1'b0;
            sample_tick <= 1'b0;
        end
        else begin

            if (rx_state == IDLE) begin
                bit_counter <= '0;
                bit_tick    <= 1'b0;
                sample_tick <= 1'b0;
            end
            else begin

                if (bit_counter == BAUD_DIVIDER - 1) begin
                    bit_counter <= '0;
                    bit_tick    <= 1'b1;
                    sample_tick <= 1'b0;
                end

                else if (bit_counter == SAMPLE_POINT - 1) begin
                    bit_counter <= bit_counter + 1'b1;
                    bit_tick    <= 1'b0;
                    sample_tick <= 1'b1;
                end

                else begin
                    bit_counter <= bit_counter + 1'b1;
                    bit_tick    <= 1'b0;
                    sample_tick <= 1'b0;
                end

            end
        end
    end

    //-------------------------------------------------------------------------
    // Frame counter
    //
    // Counts UART frame bit periods.
    //-------------------------------------------------------------------------
    always_ff @(posedge clk_i or negedge reset_n_i) begin
        if (!reset_n_i) begin
            frame_counter <= '0;
        end
        else begin

            if (rx_state == IDLE) begin
                frame_counter <= '0;
            end

            else if (bit_tick) begin

                if (frame_counter == FRAME_BITS - 1) begin
                    frame_counter <= '0;
                end

                else begin
                    frame_counter <= frame_counter + 1'b1;
                end

            end
        end
    end

    //-------------------------------------------------------------------------
    // Data reception
    //
    // UART data is received serially, one bit at a time.
    //
    // rx_sync:
    //     current synchronized RXD value
    //
    // Data is shifted into rx_data_reg.
    //-------------------------------------------------------------------------
    always_ff @(posedge clk_i or negedge reset_n_i) begin
        if (!reset_n_i) begin
            rx_data_reg <= '0;
        end
        else begin

            if (sample_tick && (rx_state == DATA_BITS)) begin
                rx_data_reg <= {
                    rx_sync,
                    rx_data_reg[DATA_WIDTH-1:1]
                };
            end

        end
    end

    //-------------------------------------------------------------------------
    // Parity checking
    //-------------------------------------------------------------------------
    always_ff @(posedge clk_i or negedge reset_n_i) begin
        if (!reset_n_i) begin
            parity_bit    <= 1'b0;
            expected_parity <= 1'b0;
        end
        else begin

            // Sample parity bit
            if (sample_tick && (rx_state == PARITY_BIT)) begin
                parity_bit <= rx_sync;
            end

            // Calculate expected parity
            if (rx_state == DATA_BITS &&
                frame_counter == DATA_WIDTH - 1) begin

                if (PARITY_TYPE == "even") begin
                    expected_parity <= ^rx_data_reg;
                end
                else begin
                    expected_parity <= ~^rx_data_reg;
                end

            end
        end
    end

    //-------------------------------------------------------------------------
    // Frame validation
    //
    // UART stop bit must be HIGH.
    //-------------------------------------------------------------------------
    always_ff @(posedge clk_i or negedge reset_n_i) begin
        if (!reset_n_i) begin
            frame_valid <= 1'b0;
        end
        else begin

            if (rx_state == STOP_STATE && sample_tick) begin
                frame_valid <= rx_sync;
            end

            else if (rx_state == IDLE) begin
                frame_valid <= 1'b0;
            end

        end
    end

    //-------------------------------------------------------------------------
    // Output data and done pulse
    //-------------------------------------------------------------------------
    always_ff @(posedge clk_i or negedge reset_n_i) begin
        if (!reset_n_i) begin
            rx_data_out <= '0;
            done_pulse  <= 1'b0;
        end
        else begin

            if (rx_state == STOP_STATE &&
                bit_tick &&
                (frame_counter == FRAME_BITS - 1)) begin

                if (frame_valid) begin
                    rx_data_out <= rx_data_reg;
                    done_pulse  <= 1'b1;
                end

                else begin
                    done_pulse <= 1'b0;
                end

            end

            else begin
                done_pulse <= 1'b0;
            end

        end
    end

    //-------------------------------------------------------------------------
    // Error detection
    //-------------------------------------------------------------------------
    always_ff @(posedge clk_i or negedge reset_n_i) begin
        if (!reset_n_i) begin
            parity_err_o <= 1'b0;
            frame_err_o  <= 1'b0;
        end
        else begin

            if (rx_state == STOP_STATE &&
                bit_tick &&
                (frame_counter == FRAME_BITS - 1)) begin

                // Parity error
                if (PARITY_ENABLE) begin
                    parity_err_o <=
                        (parity_bit != expected_parity);
                end
                else begin
                    parity_err_o <= 1'b0;
                end

                // Frame error
                frame_err_o <= !frame_valid;
            end

            else if (rx_state == IDLE) begin
                parity_err_o <= 1'b0;
                frame_err_o  <= 1'b0;
            end

        end
    end

    //-------------------------------------------------------------------------
    // State machine register
    //-------------------------------------------------------------------------
    always_ff @(posedge clk_i or negedge reset_n_i) begin
        if (!reset_n_i) begin
            rx_state <= IDLE;
        end
        else begin
            rx_state <= rx_next_state;
        end
    end

    //-------------------------------------------------------------------------
    // Next state logic
    //-------------------------------------------------------------------------
    always_comb begin

        rx_next_state = rx_state;

        case (rx_state)

            //=================================================================
            // IDLE
            //
            // UART line normally stays HIGH.
            //
            // Detect:
            //     HIGH -> LOW
            //
            // This indicates the beginning of a START bit.
            //=================================================================
            IDLE: begin

                if (enable_i &&
                    !rx_sync &&
                    rx_prev) begin

                    rx_next_state = START_BIT;

                end

            end

            //=================================================================
            // START_BIT
            //
            // Wait one UART bit period.
            //=================================================================
            START_BIT: begin

                if (bit_tick) begin
                    rx_next_state = DATA_BITS;
                end

            end

            //=================================================================
            // DATA_BITS
            //
            // Receive DATA_WIDTH bits.
            //=================================================================
            DATA_BITS: begin

                if (bit_tick &&
                    (frame_counter == DATA_WIDTH - 1)) begin

                    if (PARITY_ENABLE) begin
                        rx_next_state = PARITY_BIT;
                    end
                    else begin
                        rx_next_state = STOP_STATE;
                    end

                end

            end

            //=================================================================
            // PARITY_BIT
            //
            // Receive one parity bit.
            //=================================================================
            PARITY_BIT: begin

                if (bit_tick) begin
                    rx_next_state = STOP_STATE;
                end

            end

            //=================================================================
            // STOP_STATE
            //
            // Check STOP bit(s).
            //=================================================================
            STOP_STATE: begin

                if (bit_tick &&
                    (frame_counter == FRAME_BITS - 1)) begin

                    rx_next_state = IDLE;

                end

            end

            //=================================================================
            // Default
            //=================================================================
            default: begin
                rx_next_state = IDLE;
            end

        endcase

    end

endmodule