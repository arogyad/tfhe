module keyswitching_mult import tfhe_pkg::*; #(
    parameter KEY_L = 8,
    parameter KEY_LOG_BETA = 4
) (
    input logic clk,
    input logic rst,
    input logic start,
    input data_t A[0: N - 1],
    input data_t KSK [0: N - 1][0: KEY_L - 1][0: n],
    output data_t total_sum[0: n], 
    output logic done
);
    typedef enum logic [1:0] {IDLE, RUN_ITER, FINISH} state_t;
    state_t state;

    logic [LOG_N - 1: 0] i;
    logic keyswitching_iter_start;
    logic keyswitching_iter_done;

    data_t accum_i[0 : n];

    keyswitching_iter#(.KEY_L(KEY_L), .KEY_LOG_BETA(KEY_LOG_BETA)) keyswitch_iter (
        .clk(clk),
        .rst(rst),
        .start(keyswitching_iter_start),
        .A(A[i]),
        .KSK_i(KSK[i]),
        .accum_i(accum_i),
        .done(keyswitching_iter_done)
    );


    function automatic data_t add_reduce(input logic [WORD_SIZE:0] v);
        if (v >= q_signed_2) 
            add_reduce = WORD_SIZE'(v - q_signed_2);
        else 
            add_reduce = WORD_SIZE'(v);
    endfunction

    always_ff @( posedge clk or posedge rst ) begin

        if (rst) begin
            state <= IDLE;
            done <= 1'b0;
            keyswitching_iter_start <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    i <= 0;
                    if (start) begin
                        keyswitching_iter_start <= 1'b1;
                        state <= RUN_ITER;
                        for (int j = 0; j < n + 1; j++) begin
                            total_sum[j] <= '0;
                        end
                    end
                end

                RUN_ITER: begin
                    keyswitching_iter_start <= 1'b0;
                    if(keyswitching_iter_done) begin
                        for (int j = 0; j < n + 1; j++) begin
                            total_sum[j] <= add_reduce(total_sum[j] + accum_i[j]);
                        end
                        if(i == LOG_N'(N - 1)) begin
                            state <= FINISH;
                        end else begin
                            i <= i + 1;
                            keyswitching_iter_start <= 1'b1;
                        end
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
