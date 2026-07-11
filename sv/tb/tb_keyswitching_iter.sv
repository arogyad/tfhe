module tb_keyswitching_iter;
    import tfhe_pkg::*;

    parameter KEY_L = 8;
    parameter KEY_LOG_BETA = 4;

    logic clk;
    logic rst;
    logic start;
    data_t A;
    data_t KSK_i[0: KEY_L - 1][0: n];
    data_t accum_i[0: n];
    logic done;


    keyswitching_iter #(
        .KEY_L(KEY_L),
        .KEY_LOG_BETA(KEY_LOG_BETA)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .A(A),
        .KSK_i(KSK_i),
        .accum_i(accum_i),
        .done(done)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; 
        rst = 1;
        start = 0;

        for (int i = 0; i < KEY_L; i++) begin
            for (int j = 0; j < n + 1; j++) begin
                KSK_i[i][j] = WORD_SIZE'(i + j);
            end
        end
        A = 5 << 50;

        #20;
        rst = 0;
        #10;

        start = 1;
        #10;
        start = 0;

        wait(done);
        #10;

        for (int i = 0; i < (n + 1); i++) begin
            $display("accum_i[%0d] = %0h", i, accum_i[i]);
        end

        $finish;
    end

endmodule
