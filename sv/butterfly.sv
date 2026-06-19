module butterfly import tfhe_pkg::*; (
    input  data_t a,
    input  data_t b,
    input  data_t w,
    output data_t u,
    output data_t v
);

    data_t mod_mul;
    logic [WORD_SIZE:0] sum;

    mod_alu mul_unit (
        .val1(b),
        .val2(w),
        .out_mul(mod_mul)
    );

    always_comb begin
        sum = (WORD_SIZE + 1)'(a) + (WORD_SIZE + 1)'(mod_mul);
        if (sum >= (WORD_SIZE + 1)'(q)) begin
            u = (WORD_SIZE)'(sum - (WORD_SIZE + 1)'(q));
        end else begin
            u = (WORD_SIZE)'(sum);
        end

        if (a < mod_mul) begin
            v = (WORD_SIZE)'(((WORD_SIZE + 1)'(a) + (WORD_SIZE + 1)'(q)) - (WORD_SIZE + 1)'(mod_mul));
        end else begin
            v = (WORD_SIZE)'(a - mod_mul);
        end
    end

endmodule
