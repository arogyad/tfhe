module pointwise_mult import tfhe_pkg::*; (
    input logic clk,
    input logic rst,
    input logic start,
    input data_t in_a [0:N - 1],
    input data_t in_b [0:N - 1],
    output logic done,
    output data_t out_data [0:N - 1]
);
    typedef enum logic [1:0] {IDLE, RUN, FINISH} state_t;
    state_t state;

    logic [LOG_N - 1: 0] i;

    data_t mult_out;

    mod_alu alu_unit (
        .val1(in_a[i]),
        .val2(in_b[i]),
        .out_mul(mult_out)
    );

    always_ff @( posedge clk  or posedge rst) begin

        if (rst) begin
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
                    out_data[i] <= mult_out;
                    if(i == LOG_N'(N - 1)) begin
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
