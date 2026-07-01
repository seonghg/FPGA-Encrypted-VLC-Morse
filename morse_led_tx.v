module morse_led_tx (
    input clk,
    input reset_n,
    input [7:0] char_in,
    input       char_valid,
    input       play_sw,
    input [3:0] enc_key,
    output reg  LEDG0
);

    parameter DOT_TIME   = 10_000_000; 
    parameter DASH_TIME  = 30_000_000; 
    parameter SYMBOL_GAP = 10_000_000; 
    parameter CHAR_GAP   = 30_000_000; 

    reg [7:0] memory [0:63];
    reg [5:0] wr_ptr;

    wire [7:0] shift = enc_key % 26;
    wire [7:0] enc_char = (char_in >= 8'h41 && char_in <= 8'h5A) ? 
                          8'h41 + ((char_in - 8'h41 + shift) % 26) : char_in;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            wr_ptr <= 0;
        end else begin
            if (char_valid && char_in >= 8'h41 && char_in <= 8'h5A && wr_ptr < 64) begin
                memory[wr_ptr] <= enc_char;
                wr_ptr <= wr_ptr + 1;
            end
        end
    end

    reg [5:0]  rd_ptr;
    reg [31:0] delay_count;
    reg [2:0]  state;
    reg [9:0]  shift_reg;

    localparam IDLE      = 0;
    localparam PLAY      = 1;
    localparam PLAY_WAIT = 2;
    localparam GAP       = 3;
    localparam NEXT_CHAR = 4;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            rd_ptr <= 0;
            state <= IDLE;
            delay_count <= 0;
            LEDG0 <= 0;
            shift_reg <= 0;
        end else begin
            if (!play_sw) begin
                state <= IDLE;
                rd_ptr <= 0;
                LEDG0 <= 0;
            end else begin
                case (state)
                    IDLE: begin
                        LEDG0 <= 0;
                        if (rd_ptr < wr_ptr) begin
                            shift_reg <= get_morse_pattern(memory[rd_ptr]);
                            state <= PLAY;
                        end
                    end

                    PLAY: begin
                        if (shift_reg[1:0] == 2'b01) begin
                            LEDG0 <= 1;
                            delay_count <= DOT_TIME;
                            state <= PLAY_WAIT;
                        end else if (shift_reg[1:0] == 2'b10) begin
                            LEDG0 <= 1;
                            delay_count <= DASH_TIME;
                            state <= PLAY_WAIT;
                        end else begin
                            LEDG0 <= 0;
                            delay_count <= CHAR_GAP;
                            state <= NEXT_CHAR; 
                        end
                    end

                    PLAY_WAIT: begin
                        if (delay_count > 1) begin
                            delay_count <= delay_count - 1;
                        end else begin
                            LEDG0 <= 0;
                            delay_count <= SYMBOL_GAP;
                            shift_reg <= shift_reg >> 2;
                            state <= GAP;
                        end
                    end

                    GAP: begin
                        if (delay_count > 1) begin
                            delay_count <= delay_count - 1;
                        end else begin
                            state <= PLAY;
                        end
                    end

                    NEXT_CHAR: begin
                        if (delay_count > 1) begin
                            delay_count <= delay_count - 1;
                        end else begin
                            rd_ptr <= rd_ptr + 1;
                            state <= IDLE;
                        end
                    end
                    
                    default: state <= IDLE;
                endcase
            end
        end
    end

    function [9:0] get_morse_pattern;
        input [7:0] ascii_char;
        begin
            case (ascii_char)
                "A": get_morse_pattern = 10'b00_00_00_10_01;
                "B": get_morse_pattern = 10'b00_01_01_01_10;
                "C": get_morse_pattern = 10'b00_01_10_01_10;
                "D": get_morse_pattern = 10'b00_00_01_01_10;
                "E": get_morse_pattern = 10'b00_00_00_00_01;
                "F": get_morse_pattern = 10'b00_01_10_01_01;
                "G": get_morse_pattern = 10'b00_00_01_10_10;
                "H": get_morse_pattern = 10'b00_01_01_01_01;
                "I": get_morse_pattern = 10'b00_00_00_01_01;
                "J": get_morse_pattern = 10'b00_10_10_10_01;
                "K": get_morse_pattern = 10'b00_00_10_01_10;
                "L": get_morse_pattern = 10'b00_01_01_10_01;
                "M": get_morse_pattern = 10'b00_00_00_10_10;
                "N": get_morse_pattern = 10'b00_00_00_01_10;
                "O": get_morse_pattern = 10'b00_00_10_10_10;
                "P": get_morse_pattern = 10'b00_01_10_10_01;
                "Q": get_morse_pattern = 10'b00_10_01_10_10;
                "R": get_morse_pattern = 10'b00_00_01_10_01;
                "S": get_morse_pattern = 10'b00_00_01_01_01;
                "T": get_morse_pattern = 10'b00_00_00_00_10;
                "U": get_morse_pattern = 10'b00_00_10_01_01;
                "V": get_morse_pattern = 10'b00_10_01_01_01;
                "W": get_morse_pattern = 10'b00_00_10_10_01;
                "X": get_morse_pattern = 10'b00_10_01_01_10;
                "Y": get_morse_pattern = 10'b00_10_10_01_10;
                "Z": get_morse_pattern = 10'b00_01_01_10_10;
                default: get_morse_pattern = 10'b00_00_00_00_00;
            endcase
        end
    endfunction

endmodule