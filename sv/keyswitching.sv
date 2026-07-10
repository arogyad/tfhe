module keyswitching import tfhe_pkg::*; #(
    parameter KEY_L = 2,
    parameter KEY_LOG_BETA = 10,
) (
    input logic clk,
    input logic rst,
    input logic start,
    input data_t A[0: N - 1],
    input data_t KSK [0: N - 1][0: KEY_L - 1][0: N],
    output logic done
);
    logic a_decomp_start;
    logic a_decomp_end;
    data_t a_decomp_out [0: K_L - 1];
    gadget_decomp #(.L(KEY_L), .LOG_BETA(KEY_LOG_BETA)) decomp_a (
        .clk(clk),
        .rst(rst),
        .start(a_decomp_start),
        .done(a_decomp_done),
        .out_data(a_decomp_out)
    );

    

endmodule
