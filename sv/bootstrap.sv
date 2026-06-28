module bootstrap import tfhe_pkg::*; #(
    parameter L = 2,
    parameter LOG_BETA = 10
)
(
    input logic clk,
    input logic rst,
    input logic start,
    input data_t V [0:1][0: N - 1],
    /* verilator lint_off UNUSEDSIGNAL */
    input data_t b,
    /* verilator lint_on UNUSEDSIGNAL */
    input data_t A[0: n - 1],
    input data_t BSK [0: n - 1][0: (2 * L) - 1][0: 1][0: N - 1],
    output logic done,
    output data_t out_a [0 : N - 1],
    output data_t out_b
);

    typedef enum logic [2:0] {IDLE, RUN_V_B, RUN_BLIND, FINISH} state_t;
    state_t state;

    data_t V_b [0:1][0: N - 1];
    logic [LOG_N : 0] rot;
    assign rot = (LOG_N + 1)'((LOG_N + 2)'(2 * (LOG_N+2)'(N)) - {1'b0, b[WORD_SIZE - 1: WORD_SIZE - (LOG_N + 1)]});

    logic V_b_a_start;
    logic V_b_b_start;
    logic V_b_a_done;
    logic V_b_b_done;

    poly_rotate poly_a_vb(
        .clk(clk),
        .rst(rst),
        .start(V_b_a_start),
        .poly(V[0]),
        .rot(rot),
        .done(V_b_a_done),
        .out_data(V_b[0])
    );

    poly_rotate poly_b_vb(
        .clk(clk),
        .rst(rst),
        .start(V_b_b_start),
        .poly(V[1]),
        .rot(rot),
        .done(V_b_b_done),
        .out_data(V_b[1])
    );

    logic blind_rotation_start;
    logic blind_rotation_done;
    data_t blind_rotate_out [0:1] [0: N - 1];
    blind_rotation#(.L(L), .LOG_BETA(LOG_BETA)) blind_rotate (
        .clk(clk),
        .rst(rst),
        .start(blind_rotation_start),
        .V_b(V_b),
        .A(A),
        .BSK(BSK),
        .done(blind_rotation_done),
        .out_data(blind_rotate_out)
    );

    sample_extract sample_ext (
        .in_data(blind_rotate_out),
        .out_a(out_a),
        .out_b(out_b)
    );

    always_ff @( posedge clk or posedge rst ) begin
        if (rst) begin
            state <= IDLE;
            done <= 1'b0;
            blind_rotation_start <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if(start) begin
                        V_b_a_start <= 1'b1;
                        V_b_b_start <= 1'b1;
                        state <= RUN_V_B;
                    end
                end

                RUN_V_B: begin
                    V_b_a_start <= 1'b0;
                    V_b_b_start <= 1'b0;
                    if (V_b_a_done && V_b_b_done) begin
                        blind_rotation_start <= 1'b1;
                        state <= RUN_BLIND;
                    end
                end

                RUN_BLIND: begin
                    blind_rotation_start <= 1'b0;
                    if(blind_rotation_done) begin
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
