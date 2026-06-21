module tb_gadget_decomp;
    import tfhe_pkg::*;

    logic clk;
    logic rst;

    logic decomp_start;
    logic decomp_done;

    logic [WORD_SIZE - 1: 0] in_data [0: N - 1];
    logic [WORD_SIZE - 1: 0] out_data [0: 1][0: N - 1];

    gadget_decomp dut_decomp(
        .clk(clk),
        .rst(rst),
        .start(decomp_start),
        .in_data(in_data),
        .done(decomp_done),
        .out_data(out_data)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        for(int i = 0; i < N; i++) begin
            in_data[i] = 0;
        end
        in_data[0] = 64'h3FFFFFFFFFFFFFFF;

        rst = 1;
        decomp_start = 0;

        #20;
        rst = 0;

        #10;
        decomp_start = 1;
        #10;
        decomp_start = 0;

        wait(decomp_done == 1'b1);
        #10;

        $display("%0d", q);
        #10;
        // L = 2
        for (int i = 0; i < 2; i = i + 1) begin
            for (int j = 0; j < N; j = j + 1) begin
                $display("out[%0d][%0d] = %0h", i, j, out_data[i][j]);
            end
        end

        $finish;
    end
endmodule
