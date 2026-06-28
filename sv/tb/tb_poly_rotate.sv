module tb_poly_rotate;
    import tfhe_pkg::*;

    logic clk;
    logic rst;

    logic start;
    data_t poly[0: N - 1];
    logic [LOG_N : 0] rot;
    logic done;
    data_t out_data [0: N - 1];

    poly_rotate dut_poly (
        .clk(clk),
        .rst(rst),
        .start(start),
        .poly(poly),
        .rot(rot),
        .done(done),
        .out_data(out_data)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        for (int i = 0; i < N; i++) begin
            poly[i] = WORD_SIZE'(i);
        end
        rot = 0;

        rst = 1;
        start = 0;

        #20;
        rst = 0;

        #10;
        start = 1;
        #10
        start = 0;

        wait(done == 1'b1);
        #10

        for (int i = 0; i < N; i = i + 1) begin
            $display("out[%0d] = %0h", i, out_data[i]); // [1, 4, 4, 0, ..., 0] so (1 + 4x + 4x^2) matches
        end

        $finish;
    end

endmodule
