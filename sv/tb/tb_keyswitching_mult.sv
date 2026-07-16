module tb_keyswitching_mult;
    import tfhe_pkg::*;

    parameter KEY_L = 8;
    parameter KEY_LOG_BETA = 4;

    logic clk;
    logic rst;
    logic start;
    data_t A[0: N - 1];
    data_t KSK [0: N - 1][0: KEY_L - 1][0: n];
    data_t total_sum[0: n];
    logic done;

    keyswitching_mult #(
        .KEY_L(KEY_L),
        .KEY_LOG_BETA(KEY_LOG_BETA)
    ) dut(
        .clk(clk),
        .rst(rst),
        .start(start),
        .A(A),
        .KSK(KSK),
        .total_sum(total_sum),
        .done(done)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        start = 0;

        for (int i = 0; i < N; i++) begin
            A[i] = WORD_SIZE'(i) << 55;
        end

        for (int i = 0; i < N; i++) begin
            for (int j = 0; j < KEY_L; j++) begin
                for(int k = 0; k < n + 1; k++) begin
                    KSK[i][j][k] = (WORD_SIZE'(i) + WORD_SIZE'(j) + WORD_SIZE'(k));
                end
            end
        end

        #20;
        rst = 0;
        #10;

        start = 1;
        #10;
        start = 0;

        wait(done);
        #10;

        for(int i = 0; i < (n + 1); i++) begin
            $display("total_sum[%0d] = %0h", i, total_sum[i]);
        end
        $finish;
    end

endmodule
