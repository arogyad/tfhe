package tfhe_pkg;

    /* verilator lint_off UNUSEDPARAM */
    localparam int n = 16; // size of lwe, should be 500
    localparam int N = 16; // size of poly, should be 512
    localparam int WORD_SIZE = 64;
    localparam int LOG_N = 4;
    localparam int LOG_n = 4;

    localparam logic [WORD_SIZE - 1:0] q = 64'hFFFFFFFF00000001; // solinas prime as taken from the research paper
    localparam logic signed [WORD_SIZE + 1:0] q_signed = signed'({2'b0, q});
    localparam logic signed [WORD_SIZE:0] q_signed_2 = signed'({1'b0, q});
    localparam logic [WORD_SIZE - 1:0] N_INV = 64'hEFFFFFFF10000001; 

    typedef logic [WORD_SIZE-1:0] data_t;
    /* verilator lint_on UNUSEDPARAM */

endpackage : tfhe_pkg
