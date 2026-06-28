module intt_twiddle import tfhe_pkg::*; (
    input  logic [LOG_N - 1:0] stage,
    input  logic [LOG_N - 1:0] j,
    output data_t w
);
    // these were calculated using https://github.com/CeresB/tfhe-processor-artifacts/tree/main/src/ntt_param_computation.ipynb
    always_comb begin
        case (stage)
            LOG_N'(0): begin
                case (j)
                    LOG_N'(0): w = 64'hFBFFFFFF04000001;
                    LOG_N'(1): w = 64'hFFFFBFFF00004001;
                    LOG_N'(2): w = 64'hFFFFFFFB00000005;
                    LOG_N'(3): w = 64'hFFBFFFFF00000001;
                    LOG_N'(4): w = 64'hFFFFFBFF00000001;
                    LOG_N'(5): w = 64'hFFFFFFFEC0000001;
                    LOG_N'(6): w = 64'hFFFFFFFEFFFC0001;
                    LOG_N'(7): w = 64'hFFFFFFFEFFFFFFC1;
                    default: w = 64'h0000000000000001;
                endcase
            end
            LOG_N'(1): begin
                case (j)
                    LOG_N'(0): w = 64'hFFEFFFFF00100001;
                    LOG_N'(1): w = 64'hEFFFFFFF00000001;
                    LOG_N'(2): w = 64'hFFFFFFEF00000001;
                    LOG_N'(3): w = 64'hFFFFFFFEFFFFF001;
                    default: w = 64'h0000000000000001;
                endcase
            end
            LOG_N'(2): begin
                case (j)
                    LOG_N'(0): w = 64'hFFFFFEFF00000101;
                    LOG_N'(1): w = 64'hFFFFFFFEFF000001;
                    default: w = 64'h0000000000000001;
                endcase
            end
            LOG_N'(3): begin
                w = 64'hFFFEFFFF00000001; 
            end
            default: w = 64'h0000000000000001;
        endcase
    end 

endmodule
