module gadget_decomp_scalar import tfhe_pkg::*; #(
    parameter L = 2,
    parameter LOG_BETA = 10,
    parameter SHIFT = WORD_SIZE - (L * LOG_BETA)
)
(
    input logic clk,
    input logic rst,
    input logic start,
    input data_t in_data,
    output logic done,
    output data_t out_data [0: L - 1]
);
    typedef enum logic [1:0] {IDLE, RUN, FINISH} state_t;
    state_t state;

    always_ff @( posedge clk or posedge rst ) begin 
        if(rst) begin
            state <= IDLE;
            done <= 1'b0;
            for (int k = 0; k < L; k++) out_data[k] <= '0;
        end else begin
            case (state) 
                IDLE: begin
                    done <= 1'b0;
                    if (start) state <= RUN;
                end

                RUN: begin
                    automatic data_t val = (in_data + (data_t'(1) << (SHIFT - 1))) >> SHIFT;
                    automatic data_t carry = 0;

                    for (int j = 0; j < L; j++) begin
                        automatic data_t piece;
                        piece = (val & ((1 << LOG_BETA) - 1)) + carry;

                        if (piece >= (1 << (LOG_BETA - 1))) begin
                            out_data[L - 1 - j] <= piece + q - (1 << LOG_BETA);
                            carry = 1;
                        end else begin
                            out_data[L - 1 - j] <= piece;
                            carry = 0;
                        end
                        val = val >> LOG_BETA;
                    end

                    state <= FINISH;
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
