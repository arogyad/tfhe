module tb_ntt_mul;

    import tfhe_pkg::*;

    logic clk;
    logic rst;

    logic ntt_start;
    logic ntt_done_1;
    logic ntt_done_2;
    logic [WORD_SIZE - 1:0] in_data [0:N - 1];
    logic [WORD_SIZE - 1:0] ntt_out_1 [0:N - 1];
    logic [WORD_SIZE - 1:0] ntt_out_2 [0:N - 1];

    logic mul_start;
    logic mul_done;
    logic [WORD_SIZE - 1:0] mul_out [0:N - 1];

    logic intt_start;
    logic intt_done;
    logic [WORD_SIZE - 1:0] intt_out [0:N - 1];

    ntt_top dut_ntt_1 (
        .clk(clk),
        .rst(rst),
        .start(ntt_start),
        .in_data(in_data),
        .done(ntt_done_1),
        .out_data(ntt_out_1)
    );

    ntt_top dut_ntt_2 (
        .clk(clk),
        .rst(rst),
        .start(ntt_start),
        .in_data(in_data),
        .done(ntt_done_2),
        .out_data(ntt_out_2)

    );

    pointwise_mult dut_mul(
        .clk(clk),
        .rst(rst),
        .start(mul_start),
        .in_a(ntt_out_1),
        .in_b(ntt_out_2),
        .done(mul_done),
        .out_data(mul_out)
    );

    intt_top dut_intt (
        .clk(clk),
        .rst(rst),
        .start(intt_start),
        .in_data(mul_out),
        .done(intt_done),
        .out_data(intt_out)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        for (int i = 0; i < N; i++) begin
            // in_data[i] = WORD_SIZE'(0);
            in_data[i] = 0;
        end
        in_data[0] = 1;
        in_data[1] = 2; // I am taking polynomials (1 + 2x) . (1 + 2x) so answer should be 1 + 4x + 4x^2

        rst = 1;
        ntt_start = 0;
        intt_start = 0;

        #20;
        rst = 0;
        
        #10;
        ntt_start = 1;
        #10;
        ntt_start = 0;

        wait(ntt_done_1 == 1'b1 && ntt_done_2 == 1'b1);
        #10; 

        mul_start = 1;
        #10;
        mul_start = 0;

        wait(mul_done == 1'b1);
        #10;

        intt_start = 1;
        #10;
        intt_start = 0;

        wait(intt_done == 1'b1);
        #10;

        for (int i = 0; i < N; i = i + 1) begin
            $display("out[%0d] = %0h", i, intt_out[i]); // [1, 4, 4, 0, ..., 0] so (1 + 4x + 4x^2) matches
        end

        $finish;
    end
endmodule
