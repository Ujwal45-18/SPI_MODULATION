module spi_slave_dummy (
    input  wire sclk,
    input  wire cs,
    input  wire mosi,   // Not used, but kept for SPI completeness
    output reg  miso
);

    reg [7:0] shift_reg;
    reg [3:0] bit_cnt;

    always @(negedge cs) begin
        // Load fixed response when CS goes LOW
        shift_reg <= 8'h3C;
        bit_cnt   <= 4'd8;
    end

    always @(negedge sclk) begin
        if (!cs && bit_cnt > 0) begin
            miso      <= shift_reg[7];
            shift_reg <= {shift_reg[6:0], 1'b0};
            bit_cnt   <= bit_cnt - 1;
        end
    end
endmodule
