module external_product import tfhe_pkg::*; #(
    parameter L = 2,
    parameter LOG_BETA = 10
) (
    input logic clk,
    input logic rst,
    input logic start,
    input logic [WORD_SIZE - 1: 0] C [0: 1][0: N - 1],
    input logic [WORD_SIZE - 1: 0] BSK_i [0: (2 * L) - 1][0: N - 1], // because RLWE our k = 1, so BSK_i is (2 * L) polynomials
    output logic done,
    output logic [WORD_SIZE - 1: 0] out_data [0: 1][0: N - 1]
);

    typedef enum logic [3:0] {IDLE, RUN_DECOMP, RUN_NTT, RUN_MUL, RUN_INTT, FINISH} state_t;
    state_t state;

    logic a_decomp_done;
    logic b_decomp_done;

    logic [WORD_SIZE - 1: 0] out_data_a [0: L - 1][0: N - 1];
    logic [WORD_SIZE - 1: 0] out_data_b [0: L - 1][0: N - 1];

    gadget_decomp #(.L(L), .LOG_BETA(LOG_BETA)) decomp_a(
        .clk(clk),
        .rst(rst),
        .start(start),
        .in_data(C[0]),
        .done(a_decomp_done),
        .out_data(out_data_a)
    );

    gadget_decomp #(.L(L), .LOG_BETA(LOG_BETA)) decomp_b(
        .clk(clk),
        .rst(rst),
        .start(start),
        .in_data(C[1]),
        .done(b_decomp_done),
        .out_data(out_data_b)
    );

    logic ntt_start;
    logic [L - 1: 0] ntt_done_a, ntt_done_b;
    logic [WORD_SIZE - 1: 0] ntt_out_a [0: L - 1][0: N - 1];
    logic [WORD_SIZE - 1: 0] ntt_out_b [0: L - 1][0: N - 1];

    logic mul_start;
    logic [L - 1: 0] mul_done_a, mul_done_b;
    logic [WORD_SIZE - 1: 0] mul_out_a [0: L - 1][0: N - 1];
    logic [WORD_SIZE - 1: 0] mul_out_b [0: L - 1][0: N - 1];

    genvar i;
    generate
        for (i = 0; i < L; i++) begin
            ntt_top ntt_a (
                .clk(clk), .rst(rst), .start(ntt_start),
                .in_data(out_data_a[i]), .done(ntt_done_a[i]), .out_data(ntt_out_a[i])
            );

            pointwise_mult mul_a (
                .clk(clk), .rst(rst), .start(mul_start),
                .in_a(ntt_out_a[i]), 
                .in_b(BSK_i[i]),
                .done(mul_done_a[i]), .out_data(mul_out_a[i])
            );

            ntt_top ntt_b (
                .clk(clk), .rst(rst), .start(ntt_start),
                .in_data(out_data_b[i]), .done(ntt_done_b[i]), .out_data(ntt_out_b[i])
            );

            pointwise_mult mul_b (
                .clk(clk), .rst(rst), .start(mul_start),
                .in_a(ntt_out_b[i]), 
                .in_b(BSK_i[i + L]),
                .done(mul_done_b[i]), .out_data(mul_out_b[i])
            );
        end
    endgenerate 

    logic [WORD_SIZE - 1: 0] accum_a [0: N - 1];
    logic [WORD_SIZE - 1: 0] accum_b [0: N - 1];

    function automatic logic [WORD_SIZE - 1:0] add_reduce(input logic [WORD_SIZE:0] v);
        if (v >= {1'b0, q}) 
            add_reduce = WORD_SIZE'(v - {1'b0, q});
        else 
            add_reduce = WORD_SIZE'(v);
    endfunction

    // is this bad design?
    always_comb begin
        for (int j = 0; j < N; j++) begin
            accum_a[j] = 0;
            accum_b[j] = 0;
            for (int k = 0; k < L; k++) begin
                accum_a[j] = add_reduce(accum_a[j] + mul_out_a[k][j]);
                accum_b[j] = add_reduce(accum_b[j] + mul_out_b[k][j]);
            end
        end
    end

    logic intt_start;
    logic [1:0] intt_done;
 
    intt_top intt_a (
        .clk(clk),
        .rst(rst),
        .start(intt_start),
        .in_data(accum_a),
        .done(intt_done[0]),
        .out_data(out_data[0])
    );

    intt_top intt_b (
        .clk(clk),
        .rst(rst),
        .start(intt_start),
        .in_data(accum_b),
        .done(intt_done[1]),
        .out_data(out_data[1])
    );

    always_ff @( posedge clk or posedge rst ) begin
        if(rst) begin
            state <= IDLE;
            done <= 1'b0;
            ntt_start <= 1'b0;
            mul_start <= 1'b0;
            intt_start <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) state <= RUN_DECOMP;
                end

                RUN_DECOMP: begin
                    if(a_decomp_done && b_decomp_done) begin 
                        state <= RUN_NTT;
                        ntt_start <= 1'b1;
                    end
                end

                RUN_NTT: begin
                    ntt_start <= 1'b0;
                    if (&ntt_done_a && &ntt_done_b) begin
                        state <= RUN_MUL;
                        mul_start <= 1'b1;
                    end
                end

                RUN_MUL: begin
                    mul_start <= 1'b0;
                    if (&mul_done_a && &mul_done_b) begin
                        state <= RUN_INTT;
                        intt_start <= 1'b1;
                    end
                end

                RUN_INTT: begin
                    intt_start <= 1'b0;
                    if(&intt_done) begin
                        state <= FINISH;
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
