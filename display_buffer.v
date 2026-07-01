module display_buffer (
    input clk,
    input reset_n,

    input [7:0] char_in,
    input       char_valid,

    output reg [7:0] lcd_char,
    output reg       lcd_char_valid
);

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            lcd_char <= 8'h20;
            lcd_char_valid <= 0;
        end else begin
            lcd_char_valid <= 0;

            if (char_valid) begin
                lcd_char <= char_in;
                lcd_char_valid <= 1;
            end
        end
    end

endmodule