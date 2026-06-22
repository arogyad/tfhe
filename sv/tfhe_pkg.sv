package tfhe_pkg;

    localparam int N = 16; // size of poly
    localparam int WORD_SIZE = 64;
    localparam int LOG_N = 4;

    localparam logic [WORD_SIZE - 1:0] q = 64'hFFFFFFFF00000001; // solinas prime as taken from the research paper
    localparam logic signed [65:0] q_signed = signed'({2'b0, q});
    localparam logic [WORD_SIZE - 1:0] N_INV = 64'hEFFFFFFF10000001; 

    typedef logic [WORD_SIZE-1:0] data_t;

endpackage : tfhe_pkg
