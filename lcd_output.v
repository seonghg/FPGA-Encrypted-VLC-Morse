module lcd_output (
    input clk,
    input reset_n,

    input [7:0] char_in,
    input       char_valid,

    output reg  lcd_ready,

    output reg       LCD_RS,
    output           LCD_RW,
    output reg       LCD_EN,
    output reg [7:0] LCD_DATA
);

    assign LCD_RW = 1'b0;

    reg [31:0] delay_count;
    reg [4:0] state;
    reg [7:0] saved_char;

    localparam POWER_WAIT   = 0;
    
    localparam FUNC_SETUP   = 1;
    localparam FUNC_PULSE   = 2;
    localparam FUNC_HOLD    = 3;
    
    localparam DISP_SETUP   = 4;
    localparam DISP_PULSE   = 5;
    localparam DISP_HOLD    = 6;
    
    localparam CLEAR_SETUP  = 7;
    localparam CLEAR_PULSE  = 8;
    localparam CLEAR_HOLD   = 9;
    
    localparam ENTRY_SETUP  = 10;
    localparam ENTRY_PULSE  = 11;
    localparam ENTRY_HOLD   = 12;
    
    localparam IDLE         = 13;
    
    localparam WRITE_SETUP  = 14;
    localparam WRITE_PULSE  = 15;
    localparam WRITE_HOLD   = 16;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= POWER_WAIT;
            delay_count <= 0;
            saved_char <= 8'h20;

            LCD_RS <= 0;
            LCD_EN <= 0;
            LCD_DATA <= 8'h00;
            lcd_ready <= 0;
        end else begin

            lcd_ready <= 1'b0;

            case (state)

                POWER_WAIT: begin
                    LCD_EN <= 0;
                    LCD_RS <= 0;
                    LCD_DATA <= 8'h00;

                    if (delay_count < 32'd1_000_000)
                        delay_count <= delay_count + 1;
                    else begin
                        delay_count <= 0;
                        state <= FUNC_SETUP;
                    end
                end

                FUNC_SETUP: begin
                    LCD_RS <= 0;
                    LCD_DATA <= 8'h38;
                    LCD_EN <= 0;
                    
                    if (delay_count < 32'd50)
                        delay_count <= delay_count + 1;
                    else begin
                        delay_count <= 0;
                        state <= FUNC_PULSE;
                    end
                end
                FUNC_PULSE: begin
                    LCD_EN <= 1;
                    
                    if (delay_count < 32'd50)
                        delay_count <= delay_count + 1;
                    else begin
                        delay_count <= 0;
                        state <= FUNC_HOLD;
                    end
                end
                FUNC_HOLD: begin
                    LCD_EN <= 0;
                    
                    if (delay_count < 32'd250_000)
                        delay_count <= delay_count + 1;
                    else begin
                        delay_count <= 0;
                        state <= DISP_SETUP;
                    end
                end

                DISP_SETUP: begin
                    LCD_RS <= 0;
                    LCD_DATA <= 8'h0C;
                    LCD_EN <= 0;
                    
                    if (delay_count < 32'd50)
                        delay_count <= delay_count + 1;
                    else begin
                        delay_count <= 0;
                        state <= DISP_PULSE;
                    end
                end
                DISP_PULSE: begin
                    LCD_EN <= 1;
                    
                    if (delay_count < 32'd50)
                        delay_count <= delay_count + 1;
                    else begin
                        delay_count <= 0;
                        state <= DISP_HOLD;
                    end
                end
                DISP_HOLD: begin
                    LCD_EN <= 0;
                    
                    if (delay_count < 32'd250_000)
                        delay_count <= delay_count + 1;
                    else begin
                        delay_count <= 0;
                        state <= CLEAR_SETUP;
                    end
                end

                CLEAR_SETUP: begin
                    LCD_RS <= 0;
                    LCD_DATA <= 8'h01;
                    LCD_EN <= 0;
                    
                    if (delay_count < 32'd50)
                        delay_count <= delay_count + 1;
                    else begin
                        delay_count <= 0;
                        state <= CLEAR_PULSE;
                    end
                end
                CLEAR_PULSE: begin
                    LCD_EN <= 1;
                    
                    if (delay_count < 32'd50)
                        delay_count <= delay_count + 1;
                    else begin
                        delay_count <= 0;
                        state <= CLEAR_HOLD;
                    end
                end
                CLEAR_HOLD: begin
                    LCD_EN <= 0;
                    
                    if (delay_count < 32'd2_000_000)
                        delay_count <= delay_count + 1;
                    else begin
                        delay_count <= 0;
                        state <= ENTRY_SETUP;
                    end
                end

                ENTRY_SETUP: begin
                    LCD_RS <= 0;
                    LCD_DATA <= 8'h06;
                    LCD_EN <= 0;
                    
                    if (delay_count < 32'd50)
                        delay_count <= delay_count + 1;
                    else begin
                        delay_count <= 0;
                        state <= ENTRY_PULSE;
                    end
                end
                ENTRY_PULSE: begin
                    LCD_EN <= 1;
                    
                    if (delay_count < 32'd50)
                        delay_count <= delay_count + 1;
                    else begin
                        delay_count <= 0;
                        state <= ENTRY_HOLD;
                    end
                end
                ENTRY_HOLD: begin
                    LCD_EN <= 0;
                    
                    if (delay_count < 32'd250_000)
                        delay_count <= delay_count + 1;
                    else begin
                        delay_count <= 0;
                        state <= IDLE;
                    end
                end

                IDLE: begin
                    LCD_EN <= 0;
                    lcd_ready <= 1'b1;

                    if (char_valid) begin
                        saved_char <= char_in;
                        lcd_ready <= 1'b0;
                        state <= WRITE_SETUP;
                    end
                end

                WRITE_SETUP: begin
                    LCD_RS <= 1;
                    LCD_DATA <= saved_char;
                    LCD_EN <= 0;
                    
                    if (delay_count < 32'd50)
                        delay_count <= delay_count + 1;
                    else begin
                        delay_count <= 0;
                        state <= WRITE_PULSE;
                    end
                end
                WRITE_PULSE: begin
                    LCD_EN <= 1;
                    
                    if (delay_count < 32'd50)
                        delay_count <= delay_count + 1;
                    else begin
                        delay_count <= 0;
                        state <= WRITE_HOLD;
                    end
                end
                WRITE_HOLD: begin
                    LCD_EN <= 0;
                    
                    if (delay_count < 32'd250_000)
                        delay_count <= delay_count + 1;
                    else begin
                        delay_count <= 0;
                        state <= IDLE;
                    end
                end

                default: begin
                    state <= POWER_WAIT;
                    delay_count <= 0;
                    LCD_EN <= 0;
                    lcd_ready <= 0;
                end

            endcase
        end
    end

endmodule
