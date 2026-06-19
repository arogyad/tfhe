module tb_mod_alu;
  import tfhe_pkg::*;
  data_t val1;
  data_t val2;
  data_t out_mul;

  mod_alu dut (.*);

  initial begin
    val1 = 64'd10; 
    val2 = 64'd5;
    #10;
    $display("%0d * %0d mod q = %0d", val1, val2, out_mul);

    val1 = 64'h8B00B54B_A5DAE5FD; 
    val2 = 64'h27DDB16B_3B3E6A4E;
    #10;
    $display("%0h * %0h mod q = %0h", val1, val2, out_mul);

    val1 = 64'h80000000_00000000; 
    val2 = 64'h80000000_00000000;
    #10;
    $display("%0h * %0h mod q = %0h", val1, val2, out_mul);


    $finish;
  end
endmodule
