module tb_blind_rotation_iter;
    import tfhe_pkg::*;

    parameter L = 2;
    parameter LOG_BETA = 10;

    logic clk;
    logic rst;
    logic start;
    logic [WORD_SIZE - 1: 0] C [0: 1][0: N - 1];
    logic [WORD_SIZE - 1: 0] BSK_i [0: (2 * L) - 1][0:1][0: N - 1];
    data_t a_i;
    logic done;
    logic [WORD_SIZE - 1: 0] C_prime [0: 1][0: N - 1];

    blind_rotation_iter #(
        .L(L),
        .LOG_BETA(LOG_BETA)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .C(C),
        .BSK_i(BSK_i),
        .a_i(a_i),
        .done(done),
        .C_prime(C_prime)
    );

    always #5 clk = ~clk; 

    initial begin
        clk = 0;
        rst = 1;
        start = 0;

        for (int i = 0; i < 2; i++) begin
            for (int j = 0; j < N; j++) begin
                C[i][j] = WORD_SIZE'(j) << 50; 
            end
        end

        for (int i = 0; i < 2 * L; i++) begin
            for (int j = 0; j < N; j++) begin
                BSK_i[i][0][j] = WORD_SIZE'(i + j); 
                BSK_i[i][1][j] = WORD_SIZE'(i + j); 
            end
        end
        a_i = 5;

        #20;
        rst = 0;
        #10;

        start = 1;
        #10;
        start = 0;

        wait(done);
        #10;

        for(int i = 0; i < N; i = i + 1) begin
            $display("out_data[0][%0d] = %0h", i, C_prime[0][i]);
        end
        $finish;
    end

endmodule
