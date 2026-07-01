module input_timer (
    input clk,
    input reset_n,
    input key_in,

    output reg dot_valid,
    output reg dash_valid,
    output reg char_end,
    output reg word_end
);

    parameter DOT_TIME  = 25_000_000;    // 0.5 sec
    parameter CHAR_GAP  = 75_000_000;    // 1.5 sec
    parameter WORD_GAP  = 175_000_000;   // 3.5 sec

    reg key_prev;
    reg [31:0] press_count;
    reg [31:0] gap_count;

    reg has_symbol;
    reg char_done;
    reg word_done;

    wire key_rise = key_in && !key_prev;
    wire key_fall = !key_in && key_prev;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            key_prev <= 0;
        end else begin
            key_prev <= key_in;
        end
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            press_count <= 0;
            gap_count <= 0;

            dot_valid <= 0;
            dash_valid <= 0;
            char_end <= 0;
            word_end <= 0;

            has_symbol <= 0;
            char_done <= 0;
            word_done <= 0;
        end else begin
            dot_valid <= 0;
            dash_valid <= 0;
            char_end <= 0;
            word_end <= 0;

            if (key_in) begin
                press_count <= press_count + 1;
                gap_count <= 0;
            end else begin
                press_count <= 0;

                if (has_symbol)
                    gap_count <= gap_count + 1;
            end

            if (key_fall) begin
                has_symbol <= 1;
                char_done <= 0;
                word_done <= 0;
                gap_count <= 0;

                if (press_count < DOT_TIME)
                    dot_valid <= 1;
                else
                    dash_valid <= 1;
            end

            if (has_symbol && !char_done && gap_count >= CHAR_GAP) begin
                char_end <= 1;
                char_done <= 1;
            end

            if (has_symbol && !word_done && gap_count >= WORD_GAP) begin
                word_end <= 1;
                word_done <= 1;
                has_symbol <= 0;
                gap_count <= 0;
            end

            if (key_rise) begin
                gap_count <= 0;
            end
        end
    end

endmodule