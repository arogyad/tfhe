module twiddle import tfhe_pkg::*; (
    input  logic [LOG_N - 1:0] stage,
    input  logic [LOG_N - 1:0] j,
    output logic [WORD_SIZE - 1:0] w
);

    // these were calculated using https://github.com/CeresB/tfhe-processor-artifacts/tree/main/src/ntt_param_computation.ipynb
   always_comb begin
        case (stage)
            LOG_N'(0): begin
                w = 64'h00010000_00000000; 
            end
            LOG_N'(1): begin
                case (j)
                    4'd0: w = 64'h00000000_01000000;
                    4'd1: w = 64'h000000FF_FFFFFF00;
                    default: w = 64'h00010000_00000000;
                endcase
            end
            LOG_N'(2): begin
                case (j)
                    4'd0: w = 64'h00000000_00001000;
                    4'd1: w = 64'h00000010_00000000;
                    4'd2: w = 64'h10000000_00000000;
                    4'd3: w = 64'h000FFFFF_FFF00000;
                    default: w = 64'h00010000_00000000;
                endcase
            end
            LOG_N'(3): begin
                case (j)
                    4'd0: w = 64'h00000000_00000040;
                    4'd1: w = 64'h00000000_00040000;
                    4'd2: w = 64'h00000000_40000000;
                    4'd3: w = 64'h00000400_00000000;
                    4'd4: w = 64'h00400000_00000000;
                    4'd5: w = 64'h00000003_FFFFFFFC;
                    4'd6: w = 64'h00003FFF_FFFFC000;
                    4'd7: w = 64'h03FFFFFF_FC000000;
                    default: w = 64'h00010000_00000000;
                endcase
            end
            default: w = 64'h00010000_00000000;
        endcase
    end 

endmodule
