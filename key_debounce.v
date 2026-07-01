module key_debounce (
    input  clk,
    input  reset_n,
    input  key_in,
    output reg key_out
);

    reg [19:0] count;
    reg key_sync_0, key_sync_1;
    reg key_prev;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            key_sync_0 <= 0;
            key_sync_1 <= 0;
        end else begin
            key_sync_0 <= key_in;
            key_sync_1 <= key_sync_0;
        end
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            count <= 0;
            key_out <= 0;
            key_prev <= 0;
        end else begin
            if (key_sync_1 != key_prev) begin
                count <= 0;
                key_prev <= key_sync_1;
            end else begin
                if (count < 20'd500000) begin
                    count <= count + 1;
                end else begin
                    key_out <= key_sync_1;
                end
            end
        end
    end

endmodule