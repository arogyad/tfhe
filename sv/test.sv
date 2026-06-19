module test;

    import tfhe_pkg::*;

    logic clk;
    logic rst;

    logic ntt_start;
    logic ntt_done;
    logic [WORD_SIZE - 1:0] in_data [0:N - 1];
    logic [WORD_SIZE - 1:0] ntt_out [0:N - 1];

    logic intt_start;
    logic intt_done;
    logic [WORD_SIZE - 1:0] intt_out [0:N - 1];

    ntt_top dut_ntt (
        .clk(clk),
        .rst(rst),
        .start(ntt_start),
        .in_data(in_data),
        .done(ntt_done),
        .out_data(ntt_out)
    );

    intt_top dut_intt (
        .clk(clk),
        .rst(rst),
        .start(intt_start),
        .in_data(ntt_out),
        .done(intt_done),
        .out_data(intt_out)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        for (int i = 0; i < N; i++) begin
            in_data[i] = WORD_SIZE'(i);
        end

        rst = 1;
        ntt_start = 0;
        intt_start = 0;

        #20;
        rst = 0;
        
        #10;
        ntt_start = 1;
        #10;
        ntt_start = 0;

        wait(ntt_done == 1'b1);
        #10; 

        intt_start = 1;
        #10;
        intt_start = 0;

        wait(intt_done == 1'b1);
        #10;

        for (int i = 0; i < N; i = i + 1) begin
            logic [WORD_SIZE - 1:0] final_val;
            logic [127:0] prod;
            
            prod = 128'(intt_out[i]) * 128'(64'hEFFFFFFF10000001); // N^-1
            final_val = WORD_SIZE'(prod % 128'(q));

            if (final_val !== in_data[i]) begin
                $display("index %0d: got %0h expected %0h", i, final_val, in_data[i]);
                $fatal;
            end else begin
                $display("out[%0d] = %0h", i, final_val);
            end
        end

        $finish;
    end
endmodule
