module keyswitching import tfhe_pkg::*#(
    parameter KEY_L = 8,
    parameter KEY_LOG_BETA = 4
) (
    input logic clk,
    input logic rst,
    input logic start,
    // A, B input in the same way sample_extract returns them
    input data_t A[0: N - 1],
    input data_t B,
    input data_t KSK[0: N - 1][0: KEY_L - 1][0: n],
    output data_t lwe[0: n],
    output logic done
);
    typedef enum logic [2:0] {IDLE, RUN_MUL, RUN_SUB, FINISH} state_t;
    state_t state;

    logic mult_start;
    logic mult_done;
    data_t total_sum[0: n];

    keyswitching_mult#(.KEY_L(KEY_L), .KEY_LOG_BETA(KEY_LOG_BETA)) mult(
        .clk(clk),
        .rst(rst),
        .start(mult_start),
        .A(A),
        .KSK(KSK),
        .total_sum(total_sum),
        .done(mult_done)
    );

    always_ff @( posedge clk or posedge rst ) begin
        if(rst) begin
            state <= IDLE;
            done <= 1'b0;
            mult_start <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        mult_start <= 1'b1;
                        state <= RUN_MUL;
                        for(int i = 0; i < n + 1; i++) begin
                            lwe[i] <= 0;
                        end
                    end
                end

                RUN_MUL: begin
                    mult_start <= 1'b0;
                    if(mult_done) state <= RUN_SUB;
                end

                RUN_SUB: begin
                    for (int i = 0; i < n; i++) begin
                        if(total_sum[i] == 0) begin
                            lwe[i] <= 0;
                        end else begin
                            lwe[i] <= q - total_sum[i];
                        end
                    end

                    if (B >= total_sum[n]) begin
                        lwe[n] <= B - total_sum[n];
                    end else begin
                        lwe[n] <= q - (total_sum[n] - B);
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