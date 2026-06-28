module blind_rotation import tfhe_pkg::*; #(
    parameter L = 2,
    parameter LOG_BETA = 10
)
(
    input logic clk,
    input logic rst,
    input logic start,
    input data_t V_b [0:1][0: N - 1],
    input data_t A [0: n - 1],
    input data_t BSK [0: n - 1][0: (2 * L) - 1][0:1][0: N - 1],
    output logic done,
    output data_t out_data [0:1][0: N - 1]
);

    typedef enum logic [1:0] {IDLE, RUN, FINISH} state_t;
    state_t state;

    logic [LOG_N - 1: 0] i;
    logic blind_iter_start;
    logic blind_iter_done;
    data_t V [0:1][0: N - 1];
    data_t V_ [0:1][0: N - 1];

    blind_rotation_iter#(.L(L), .LOG_BETA(LOG_BETA)) blind_iter (
        .clk(clk),
        .rst(rst),
        .start(blind_iter_start),
        .C(V),
        .BSK_i(BSK[i]),
        .a_i(A[i]),
        .done(blind_iter_done),
        .C_prime(V_)
    );

    always_ff @( posedge clk or posedge rst ) begin
        if (rst) begin
            state <= IDLE;
            done <= 1'b0;
            blind_iter_start <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    i <= 0;
                    if(start) begin
                        blind_iter_start <= 1'b1;
                        V <= V_b;
                        state <= RUN;
                    end
                end

                RUN: begin
                    blind_iter_start <= 1'b0;
                    if(blind_iter_done) begin
                        V <= V_;
                        if(i == LOG_N'(n - 1)) begin
                            state <= FINISH;
                        end else begin
                            $display("Blind Rotation Processing at index: %0d", i);
                            i <= i + 1;
                            blind_iter_start <= 1'b1;
                        end
                    end
                end

                FINISH: begin
                    done <= 1'b1;
                    out_data <= V;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
