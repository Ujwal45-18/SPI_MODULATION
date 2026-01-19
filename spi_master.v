module spi_master (
    input  wire clk,        // FPGA clock
    input  wire rst,
    input  wire start,
    input  wire miso,
    output reg  sclk,
    output reg  cs,
    output reg  mosi,
    output reg  done,
    output reg [7:0] rx_data
);

    reg [7:0] tx_data = 8'hA5;
    reg [7:0] rx_shift;
    reg [7:0] tx_shift;
    reg [3:0] bit_cnt;
    reg busy;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cs       <= 1'b1;
            sclk     <= 1'b0;
            mosi     <= 1'b0;
            done     <= 1'b0;
            busy     <= 1'b0;
            bit_cnt  <= 4'd0;
            rx_data  <= 8'd0;
        end else begin
            done <= 1'b0;

            if (start && !busy) begin
                // Start SPI
                busy     <= 1'b1;
                cs       <= 1'b0;
                tx_shift <= tx_data;
                rx_shift <= 8'd0;
                bit_cnt  <= 4'd8;
            end

            if (busy) begin
                // Toggle clock
                sclk <= ~sclk;

                if (sclk == 1'b0) begin
                    // Falling edge: output MOSI
                    mosi     <= tx_shift[7];
                    tx_shift <= {tx_shift[6:0], 1'b0};
                end else begin
                    // Rising edge: sample MISO
                    rx_shift <= {rx_shift[6:0], miso};
                    bit_cnt  <= bit_cnt - 1;

                    if (bit_cnt == 1) begin
                        busy    <= 1'b0;
                        cs      <= 1'b1;
                        rx_data <= rx_shift;
                        done    <= 1'b1;
                        sclk    <= 1'b0;
                    end
                end
            end
        end
    end
endmodule
