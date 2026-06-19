module intt_butterfly import tfhe_pkg::*; (
    input  data_t a,
    input  data_t b,
    input  data_t w,
    output data_t u,
    output data_t v
);

    logic [WORD_SIZE:0] sum;
    data_t diff;

    always_comb begin
        sum = (WORD_SIZE + 1)'(a) + (WORD_SIZE + 1)'(b);
        if (sum >= (WORD_SIZE + 1)'(q)) begin
            u = WORD_SIZE'(sum - (WORD_SIZE + 1)'(q));
        end else begin
            u = WORD_SIZE'(sum);
        end

        if (a < b) begin
            diff = WORD_SIZE'( ((WORD_SIZE + 1)'(a) + (WORD_SIZE + 1)'(q)) - (WORD_SIZE + 1)'(b) );
        end else begin
            diff = WORD_SIZE'(a - b);
        end
    end

    mod_alu mul_unit (
        .val1(diff),
        .val2(w),
        .out_mul(v)
    );

endmodule
