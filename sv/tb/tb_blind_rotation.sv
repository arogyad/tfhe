module tb_blind_rotation;
    import tfhe_pkg::*;

    parameter L = 4;
    parameter LOG_BETA = 10;

    logic clk;
    logic rst;
    logic start;
    data_t V_b [0:1][0: N - 1];
    data_t A [0: n - 1];
    data_t BSK [0: n - 1][0: (2 * L) - 1][0: 1][0: N - 1];
    logic done;
    data_t out_data [0: 1][0: N - 1];

    blind_rotation #(
        .L(L),
        .LOG_BETA(LOG_BETA)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .V_b(V_b),
        .A(A),
        .BSK(BSK),
        .done(done),
        .out_data(out_data)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        start = 0;

        for (int i = 0; i < 2; i++) begin
            for (int j = 0; j < N; j++)  begin
                V_b[i][j] = WORD_SIZE'(j) << 50;
            end
        end

        for (int i = 0; i < n; i++) begin
            A[i] = WORD_SIZE'(i);
            for (int j = 0; j < 2 * L; j++) begin
                for (int k = 0; k < N; k++) begin
                    BSK[i][j][0][k] = WORD_SIZE'(i + j);
                    BSK[i][j][1][k] = WORD_SIZE'(i + j);
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

        for(int i = 0; i < N; i++) begin
            $display("out_data[0][%0d] = %0h", i, out_data[0][i]);
        end
        $finish;
    end

endmodule
