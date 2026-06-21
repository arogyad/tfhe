package tfhe_pkg;

    localparam int n = 16; // size of lwe
    localparam int N = 16; // size of poly
    localparam int WORD_SIZE = 64;
    localparam int LOG_N = 4;

    localparam logic [WORD_SIZE - 1:0] q = 64'hFFFFFFFF00000001; // solinas prime as taken from the research paper
    localparam logic [WORD_SIZE - 1:0] N_INV = 64'hEFFFFFFF10000001; 

    typedef logic [WORD_SIZE-1:0] data_t;

    typedef struct packed {
        data_t [n - 1:0]     a;
        data_t               b;
    } lwe_ct_t;

    typedef struct packed {
        data_t [N - 1:0] a;
        data_t [N - 1:0] b;
    } rlwe_ct_t;

endpackage : tfhe_pkg
