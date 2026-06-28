module twiddle import tfhe_pkg::*; (
    input  logic [LOG_N - 1:0] stage,
    input  logic [LOG_N - 1:0] j,
    output data_t w
);

    // these were calculated using https://github.com/CeresB/tfhe-processor-artifacts/tree/main/src/ntt_param_computation.ipynb
   always_comb begin
        case (stage)
            LOG_N'(0): begin
                w = 64'h00010000_00000000; 
            end
            LOG_N'(1): begin
                case (j)
                    LOG_N'(0): w = 64'h00000000_01000000;
                    LOG_N'(1): w = 64'h000000FF_FFFFFF00;
                    default: w = 64'h00010000_00000000;
                endcase
            end
            LOG_N'(2): begin
                case (j)
                    LOG_N'(0): w = 64'h00000000_00001000;
                    LOG_N'(1): w = 64'h00000010_00000000;
                    LOG_N'(2): w = 64'h10000000_00000000;
                    LOG_N'(3): w = 64'h000FFFFF_FFF00000;
                    default: w = 64'h00010000_00000000;
                endcase
            end
            LOG_N'(3): begin
                case (j)
                    LOG_N'(0): w = 64'h00000000_00000040;
                    LOG_N'(1): w = 64'h00000000_00040000;
                    LOG_N'(2): w = 64'h00000000_40000000;
                    LOG_N'(3): w = 64'h00000400_00000000;
                    LOG_N'(4): w = 64'h00400000_00000000;
                    LOG_N'(5): w = 64'h00000003_FFFFFFFC;
                    LOG_N'(6): w = 64'h00003FFF_FFFFC000;
                    LOG_N'(7): w = 64'h03FFFFFF_FC000000;
                    default: w = 64'h00010000_00000000;
                endcase
            end
            default: w = 64'h00010000_00000000;
        endcase
    end 

endmodule
