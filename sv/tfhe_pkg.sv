package tfhe_pkg;

    localparam logic [63:0] q = 64'hFFFFFFFF00000001; // solinas prime as taken from the research paper

    localparam int n = 16; // size of lwe
    localparam int N = 32; // size of poly
    localparam int WORD_SIZE = 64;

    typedef logic [WORD_SIZE-1:0] data_t;

    typedef struct packed {
        data_t [n - 1:0] a;
        data_t               b;
    } lwe_ct_t;

    typedef struct packed {
        data_t [N - 1:0] a;
        data_t [N - 1:0] b;
    } rlwe_ct_t;

endpackage : tfhe_pkg
