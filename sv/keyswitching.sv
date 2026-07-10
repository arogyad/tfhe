module keyswitching import tfhe_pkg::*; #(
    parameter KEY_L = 8,
    parameter KEY_LOG_BETA = 4,
) (
    input logic clk,
    input logic rst,
    input logic start,
    input data_t A[0: N - 1],
    input data_t KSK [0: N - 1][0: KEY_L - 1][0: n],
    output logic done
);
    
        

endmodule
