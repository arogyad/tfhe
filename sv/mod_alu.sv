module mod_alu import tfhe_pkg::*; (
    input data_t val1,
    input data_t val2,
    output data_t out_mul
);

    logic [127:0] v;
    logic [65:0] a, b, c, d;
    logic signed [65:0] r_val;
    localparam logic signed [65:0] q_signed = signed'({2'b0, q});

    always_comb begin
        v = val1 * val2;

        a = 66'(v[127:96]);
        b = 66'(v[95:64]);
        c = 66'(v[63:32]);
        d = 66'(v[31:0]); 

        r_val = ((b + c) << 32) + d - a - b;

        if (r_val >= q_signed) 
            out_mul = WORD_SIZE'(r_val - q_signed);
        else if (r_val < 0)
            out_mul = WORD_SIZE'(r_val + q_signed);
        else 
            out_mul = WORD_SIZE'(r_val);
    end

endmodule
