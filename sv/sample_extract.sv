module sample_extract import tfhe_pkg::*; (
    input data_t in_data[0:1][0: N - 1],
    output data_t out_a[0: N - 1],
    output data_t out_b
);
    always_comb begin
        out_b = in_data[1][0];
        
        out_a[0] = in_data[0][0];

        // simpler case of a'_{iN + j}
        for (int j = 1; j < N; j++) begin
            out_a[j] = (in_data[0][N - j] == 0) ? 0 : (q - in_data[0][N - j]);
        end
    end
endmodule
