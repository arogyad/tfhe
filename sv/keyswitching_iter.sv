module keyswitching_iter import tfhe_pkg::*; #(
    parameter KEY_L = 8,
    parameter KEY_LOG_BETA = 4
)(
    input logic clk,
    input logic rst,
    input logic start,
    input data_t A,
    input data_t KSK_i[0: KEY_L - 1][0: n],
    output data_t accum_i[0: n],
    output logic done
);
    typedef enum logic [1:0] {IDLE, RUN_DCMP, RUN_MUL, FINISH} state_t;
    state_t state;

    logic  a_decomp_start;
    logic a_decomp_done;
    data_t a_decomp_out [0: KEY_L - 1];
    gadget_decomp_scalar #(.L(KEY_L), .LOG_BETA(KEY_LOG_BETA)) decomp_a (
        .clk(clk),
        .rst(rst),
        .in_data(A),
        .start(a_decomp_start),
        .done(a_decomp_done),
        .out_data(a_decomp_out)
    );

    logic a_mul_start;
    logic [KEY_L - 1: 0] a_mul_done;
    data_t a_mul_out [0: KEY_L - 1][0: n]; // this is so inefficient
    genvar gi;
    // initiate KEY_L number of pointwise multiplication
    generate
        for (gi = 0; gi < KEY_L; gi++) begin: gen_mult
            // parameterize this
            pointwise_mult_scalar mul_a(
                .clk(clk),
                .rst(rst),
                .start(a_mul_start),
                .a( a_decomp_out[gi] ),
                .b( KSK_i[gi] ),
                .done(a_mul_done[gi]),
                .out_data(a_mul_out[gi])
            );
        end
    endgenerate

    function automatic data_t add_reduce(input logic [WORD_SIZE:0] v);
        if (v >= q_signed_2) 
            add_reduce = WORD_SIZE'(v - q_signed_2);
        else 
            add_reduce = WORD_SIZE'(v);
    endfunction

    always_comb begin
        for (int i = 0; i < n + 1; i++) begin
            accum_i[i] = '0;
            for (int j = 0; j < KEY_L; j++) begin
                accum_i[i] = add_reduce(accum_i[i] + a_mul_out[j][i]);
            end
        end
    end

    always_ff @( posedge clk or posedge rst ) begin

        if (rst) begin
            state <= IDLE;
            done <= 1'b0;
            a_decomp_start <= 1'b0;
            a_mul_start <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin 
                        a_decomp_start <= 1'b1;
                        state <= RUN_DCMP;
                    end
                end

                RUN_DCMP: begin
                    a_decomp_start <= 1'b0;
                    if (a_decomp_done) begin
                        a_mul_start <= 1'b1;
                        state <= RUN_MUL;
                    end
                end

                RUN_MUL: begin
                    a_mul_start <= 1'b0;
                    if (&a_mul_done) state <= FINISH;
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
