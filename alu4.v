// 4-bit unsigned ALU for Digital Circuits Design I, Assignment 1
// Pure combinational Verilog-2001. R is magnitude (0..31); subtraction is absolute difference.
module alu4 (
    input  wire [3:0] A,
    input  wire [3:0] B,
    input  wire       M,
    input  wire       S1,
    input  wire       S0,
    output reg  [3:0] L,
    output reg  [4:0] R,
    output reg        N,
    output wire [3:0] BCD_TENS,
    output wire [3:0] BCD_ONES,
    output wire [6:0] SEG_TENS_N,
    output wire [6:0] SEG_ONES_N
);
    reg [4:0] raw_sum;
    reg [4:0] bcd_ones_work;
    reg [3:0] bcd_tens_work;

    always @* begin
        L = 4'b0000;
        R = 5'b00000;
        N = 1'b0;
        raw_sum = 5'b00000;
        if (M == 1'b0) begin
            case ({S1,S0})
                2'b00: L = A & B;
                2'b01: L = A ^ B;
                2'b10: L = ~(A & B);
                2'b11: L = ~(A ^ B);
                default: L = 4'b0000;
            endcase
        end else begin
            case ({S1,S0})
                2'b00: begin raw_sum = {1'b0,A} + {1'b0,B}; R = raw_sum; end
                2'b01: begin
                    if (A < B) begin R = {1'b0,(B-A)}; N = 1'b1; end
                    else       begin R = {1'b0,(A-B)}; N = 1'b0; end
                end
                2'b10: begin raw_sum = {1'b0,A} + {1'b0,B} + 5'd1; R = raw_sum; end
                2'b11: begin R = {A,1'b0}; end // 2A; B intentionally unused
                default: begin R = 5'b00000; N = 1'b0; end
            endcase
        end
    end

    // Exact 0..31 binary-to-decimal conversion; the remainder fits in one BCD digit.
    always @* begin
        if (R >= 5'd30) begin bcd_tens_work=4'd3; bcd_ones_work=R-5'd30; end
        else if (R >= 5'd20) begin bcd_tens_work=4'd2; bcd_ones_work=R-5'd20; end
        else if (R >= 5'd10) begin bcd_tens_work=4'd1; bcd_ones_work=R-5'd10; end
        else begin bcd_tens_work=4'd0; bcd_ones_work=R; end
    end
    assign BCD_TENS = bcd_tens_work;
    assign BCD_ONES = bcd_ones_work;

    // Seven-segment outputs are active-low, ordered {a,b,c,d,e,f,g}; common-anode convention.
    function [6:0] sevenseg_n;
        input [3:0] digit;
        begin
            case (digit)
                4'd0: sevenseg_n=7'b0000001; 4'd1: sevenseg_n=7'b1001111;
                4'd2: sevenseg_n=7'b0010010; 4'd3: sevenseg_n=7'b0000110;
                4'd4: sevenseg_n=7'b1001100; 4'd5: sevenseg_n=7'b0100100;
                4'd6: sevenseg_n=7'b0100000; 4'd7: sevenseg_n=7'b0001111;
                4'd8: sevenseg_n=7'b0000000; 4'd9: sevenseg_n=7'b0000100;
                default: sevenseg_n=7'b1111111; // blank invalid BCD digit
            endcase
        end
    endfunction
    assign SEG_TENS_N = sevenseg_n(BCD_TENS);
    assign SEG_ONES_N = sevenseg_n(BCD_ONES);
endmodule
