module gadget_decomp import tfhe_pkg::*; #(
    parameter L = 2,
    parameter LOG_BETA = 10,
    parameter SHIFT = WORD_SIZE - (L * LOG_BETA)
)
(
    input logic clk,
    input logic rst,
    input logic start,
    input logic [WORD_SIZE - 1: 0] in_data [0: N - 1],
    output logic done,
    output logic [WORD_SIZE - 1: 0] out_data [0: L - 1][0: N - 1]
);
    typedef enum logic [1:0] {IDLE, RUN, FINISH} state_t;
    state_t state;

    logic [LOG_N - 1: 0] i;

    always_ff @( posedge clk or posedge rst ) begin 
        if(rst) begin
            state <= IDLE;
            done <= 1'b0;
            i <= 0;
        end else begin
            case (state) 
                IDLE: begin
                    done <= 1'b0;
                    i <= 0;
                    if (start) state <= RUN;
                end

                RUN: begin
                    automatic logic [WORD_SIZE - 1: 0] val = in_data[i] >> SHIFT;
                    automatic logic [WORD_SIZE - 1: 0] carry = 0;

                    for(int j = 0; j < L; j++) begin
                        automatic logic [WORD_SIZE - 1: 0] piece;
                        piece = (val & ((1 << LOG_BETA) - 1)) + carry;

                        if(piece >= (1 << (LOG_BETA - 1))) begin
                            out_data[L - 1 - j][i] <= piece - (1 << LOG_BETA);
                            carry = 1;
                        end else begin
                            out_data[L - 1 - j][i] <= piece;
                            carry = 0;
                        end
                        val = val >> LOG_BETA;
                    end

                    if (i == LOG_N'(N - 1)) begin
                        state <= FINISH;
                    end else begin
                        i <= i + 1;
                    end
                end

                FINISH: begin
                    done <= 1'b1;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
