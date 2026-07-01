module morse_interpreter (
    input clk,
    input reset_n,

    input dot_valid,
    input dash_valid,
    input char_end,
    input word_end,

    output reg [7:0] decoded_char,
    output reg       decoded_valid
);

    reg [4:0] morse_code;
    reg [2:0] morse_len;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            morse_code <= 0;
            morse_len <= 0;
            decoded_char <= 8'h20;
            decoded_valid <= 0;
        end else begin
            decoded_valid <= 0;

            if (dot_valid && morse_len < 5) begin
                morse_code <= {morse_code[3:0], 1'b0};
                morse_len <= morse_len + 1;
            end

            if (dash_valid && morse_len < 5) begin
                morse_code <= {morse_code[3:0], 1'b1};
                morse_len <= morse_len + 1;
            end

            if (char_end && morse_len != 0) begin
                decoded_char <= decode_morse(morse_code, morse_len);
                decoded_valid <= 1;

                morse_code <= 0;
                morse_len <= 0;
            end

            if (word_end) begin
                if (morse_len != 0) begin
                    decoded_char <= decode_morse(morse_code, morse_len);
                    decoded_valid <= 1;
                end else begin
                    decoded_char <= 8'h20; // space
                    decoded_valid <= 1;
                end

                morse_code <= 0;
                morse_len <= 0;
            end
        end
    end

    function [7:0] decode_morse;
        input [4:0] code;
        input [2:0] len;
        begin
            case ({len, code})
                {3'd1, 5'b00000}: decode_morse = "E"; // .
                {3'd1, 5'b00001}: decode_morse = "T"; // -

                {3'd2, 5'b00000}: decode_morse = "I"; // ..
                {3'd2, 5'b00001}: decode_morse = "A"; // .-
                {3'd2, 5'b00010}: decode_morse = "N"; // -.
                {3'd2, 5'b00011}: decode_morse = "M"; // --

                {3'd3, 5'b00000}: decode_morse = "S"; // ...
                {3'd3, 5'b00001}: decode_morse = "U"; // ..-
                {3'd3, 5'b00010}: decode_morse = "R"; // .-.
                {3'd3, 5'b00011}: decode_morse = "W"; // .--
                {3'd3, 5'b00100}: decode_morse = "D"; // -..
                {3'd3, 5'b00101}: decode_morse = "K"; // -.-
                {3'd3, 5'b00110}: decode_morse = "G"; // --.
                {3'd3, 5'b00111}: decode_morse = "O"; // ---

                {3'd4, 5'b00000}: decode_morse = "H"; // ....
                {3'd4, 5'b00001}: decode_morse = "V"; // ...-
                {3'd4, 5'b00010}: decode_morse = "F"; // ..-.
                {3'd4, 5'b00100}: decode_morse = "L"; // .-..
                {3'd4, 5'b00110}: decode_morse = "P"; // .--.
                {3'd4, 5'b00111}: decode_morse = "J"; // .---
                {3'd4, 5'b01000}: decode_morse = "B"; // -...
                {3'd4, 5'b01001}: decode_morse = "X"; // -..-
                {3'd4, 5'b01010}: decode_morse = "C"; // -.-.
                {3'd4, 5'b01011}: decode_morse = "Y"; // -.--
                {3'd4, 5'b01100}: decode_morse = "Z"; // --..
                {3'd4, 5'b01101}: decode_morse = "Q"; // --.-

                default: decode_morse = "?";
            endcase
        end
    endfunction

endmodule