module blind_rotation_iter import tfhe_pkg::*; #(
    parameter L = 2,
    parameter LOG_BETA = 10
)(
    input logic clk,
    input logic rst,
    input logic start,
    input data_t C [0:1][0: N - 1],
    input data_t BSK_i[0: (2 * L) - 1][0:1][0: N - 1],
    input data_t a_i,
    output logic done,
    output data_t C_prime [0: 1][0: N - 1]
);

    typedef enum logic [3:0] {IDLE, RUN_EXTERNAL, RUN_POLY, WAIT_POLY, RUN_ADD, FINISH} state_t;
    state_t state;

    data_t external_product_out [0: 1][0: N - 1];
    logic external_done;
    logic external_start;

    external_product #(.L(L), .LOG_BETA(LOG_BETA)) ext_product (
        .clk(clk),
        .rst(rst),
        .start(external_start),
        .C(C),
        .BSK_i(BSK_i),
        .done(external_done),
        .out_data(external_product_out)
    );

    logic poly_r_start;
    logic poly_a_done;
    logic poly_b_done;
    data_t poly_out [0: 1][0: N - 1];
    logic [LOG_N - 1: 0] i;

    poly_rotate poly_r_a (
        .clk(clk),
        .rst(rst),
        .start(poly_r_start),
        .poly(external_product_out[0]),
        .rot(a_i),
        .done(poly_a_done),
        .out_data(poly_out[0])
    );

    poly_rotate poly_r_b (
        .clk(clk),
        .rst(rst),
        .start(poly_r_start),
        .poly(external_product_out[1]),
        .rot(a_i),
        .done(poly_b_done),
        .out_data(poly_out[1])
    );

    data_t sub_out [0:1][0: N - 1];

    function automatic logic [WORD_SIZE - 1:0] reduce(input logic signed [WORD_SIZE : 0] v);
        if (v >= q_signed_2) 
            reduce = WORD_SIZE'(v - q_signed_2);
        else if (v < 0) begin
            reduce = WORD_SIZE'(v + q_signed_2);
        end else begin 
            reduce = WORD_SIZE'(v);
        end
    endfunction

    always_ff @( posedge clk or posedge rst ) begin
        if(rst) begin
            state <= IDLE;
            done <= 1'b0;
            external_start <= 1'b0;
            poly_r_start <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin 
                        external_start <= 1'b1;
                        state <= RUN_EXTERNAL;
                    end
                end

                RUN_EXTERNAL: begin
                    external_start <= 1'b0;
                    if(external_done) begin
                        state <= RUN_POLY;
                        poly_r_start <= 1'b1;
                        i <= 0;
                    end
                end

                RUN_POLY: begin
                    poly_r_start <= 1'b0;
                    sub_out[0][i] <= reduce(signed'({1'b0, C[0][i]}) - signed'({1'b0, external_product_out[0][i]})); 
                    sub_out[1][i] <= reduce(signed'({1'b0, C[1][i]}) - signed'({1'b0, external_product_out[1][i]})); 

                    if( i == LOG_N'(N - 1) ) begin
                        state <= WAIT_POLY;
                    end else begin
                        i <= i + 1;
                    end
                end

                WAIT_POLY: begin
                    if (poly_a_done && poly_b_done) begin
                        state <= RUN_ADD;
                        i <= 0;
                    end
                end

                RUN_ADD: begin
                    C_prime[0][i] <= reduce({1'b0, poly_out[0][i]} + {1'b0, sub_out[0][i]});
                    C_prime[1][i] <= reduce({1'b0, poly_out[1][i]} + {1'b0, sub_out[1][i]});
                    if( (i == LOG_N'(N - 1)) ) begin
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
