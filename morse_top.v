module morse_top (
    input         CLOCK_50,
    input  [1:0]  KEY,
    input         PASS,
    input  [10:7] SW,

    output       LCD_RS,
    output       LCD_RW,
    output       LCD_EN,
    output [7:0] LCD_DATA,
    output       LCD_ON,
    output       LCD_BLON,
    output       LEDG0
);

    wire reset_n = KEY[0];
    wire key_raw = ~KEY[1];

    wire key_stable;

    wire dot_valid;
    wire dash_valid;
    wire char_end;
    wire word_end;

    wire [7:0] decoded_char;
    wire       decoded_valid;

    wire [7:0] lcd_char;
    wire       lcd_char_valid;

    wire lcd_ready;

    reg [7:0] pending_char;
    reg       pending_valid;

    reg [7:0] buffer_char;
    reg       buffer_char_valid;

    assign LCD_ON = 1'b1;
    assign LCD_BLON = 1'b1;

    key_debounce u_debounce (
        .clk(CLOCK_50),
        .reset_n(reset_n),
        .key_in(key_raw),
        .key_out(key_stable)
    );

    input_timer u_input_timer (
        .clk(CLOCK_50),
        .reset_n(reset_n),
        .key_in(key_stable),

        .dot_valid(dot_valid),
        .dash_valid(dash_valid),
        .char_end(char_end),
        .word_end(word_end)
    );

    morse_interpreter u_interpreter (
        .clk(CLOCK_50),
        .reset_n(reset_n),

        .dot_valid(dot_valid),
        .dash_valid(dash_valid),
        .char_end(char_end),
        .word_end(word_end),

        .decoded_char(decoded_char),
        .decoded_valid(decoded_valid)
    );

    always @(posedge CLOCK_50 or negedge reset_n) begin
        if (!reset_n) begin
            pending_char      <= 8'd0;
            pending_valid     <= 1'b0;
            buffer_char       <= 8'd0;
            buffer_char_valid <= 1'b0;
        end else begin
            buffer_char_valid <= 1'b0;

            if (decoded_valid) begin
                pending_char  <= decoded_char;
                pending_valid <= 1'b1;
            end

            if (pending_valid) begin
                buffer_char       <= pending_char;
                buffer_char_valid <= 1'b1;
                pending_valid     <= 1'b0;
            end
        end
    end

    display_buffer u_buffer (
        .clk(CLOCK_50),
        .reset_n(reset_n),

        .char_in(buffer_char),
        .char_valid(buffer_char_valid),

        .lcd_char(lcd_char),
        .lcd_char_valid(lcd_char_valid)
    );

    lcd_output u_lcd (
        .clk(CLOCK_50),
        .reset_n(reset_n),

        .char_in(lcd_char),
        .char_valid(lcd_char_valid),

        .lcd_ready(lcd_ready),

        .LCD_RS(LCD_RS),
        .LCD_RW(LCD_RW),
        .LCD_EN(LCD_EN),
        .LCD_DATA(LCD_DATA)
    );

    morse_led_tx u_led_tx (
        .clk(CLOCK_50),
        .reset_n(reset_n),
        .char_in(decoded_char),
        .char_valid(decoded_valid),
        .play_sw(PASS),
        .enc_key(SW[10:7]),
        .LEDG0(LEDG0)
    );

endmodule