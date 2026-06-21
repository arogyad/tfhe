module intt_top import tfhe_pkg::*; (
    input logic     clk,
    input logic     rst,
    input logic     start,
    input logic [WORD_SIZE - 1:0] in_data [0:N - 1],
    output logic    done,
    output logic [WORD_SIZE - 1:0] out_data [0: N - 1]
);
    typedef enum logic [1:0] {IDLE, RUN, FINISH} state_t;
    state_t state;

    logic [LOG_N - 1:0] stage;
    logic [LOG_N - 1:0] b_cnt;

    logic [WORD_SIZE - 1:0] mem[0: N - 1];
    logic [WORD_SIZE - 1:0] a, b, w, u, v;
    
    logic [LOG_N - 1:0] stride;
    logic [LOG_N - 1:0] addr_a, addr_b;
    logic [LOG_N - 1:0] group_start, offset;

    intt_butterfly bfly(
        .a(a),
        .b(b),
        .w(w),
        .u(u),
        .v(v)
    );

    intt_twiddle tw_rom (
        .stage(stage),
        .j(offset),
        .w(w)
    );

    function automatic [LOG_N - 1:0] bitrev(input [LOG_N - 1:0] x);
        logic [LOG_N - 1:0] res;
        res = 0;
        for (int k = 0; k < LOG_N; k++) begin
            res[k] = x[LOG_N - 1 - k];
        end
        return res;
    endfunction

    always_comb begin
        stride = LOG_N'(1) << (LOG_N'(LOG_N - 1) - stage);
    end

    always_comb begin
        group_start = (b_cnt & ~(stride - LOG_N'(1))) << LOG_N'(1);
        offset = b_cnt & (stride - LOG_N'(1));
    end

    always_comb begin
        addr_a = group_start + offset;
        addr_b = addr_a + stride;
    end
        
    always_comb begin
        a = mem[addr_a];
        b = mem[addr_b];
    end

    always_ff @(posedge clk or posedge rst) begin 
        if (rst) begin
            state <= IDLE;
            done <= 1'b0;
            stage <= 0;
            b_cnt <= 0;
        end else begin
            case (state) 
                IDLE: begin
                    done <= 1'b0;
                    stage <= 0;
                    b_cnt <= 0;
                    if (start) begin
                        for (int i = 0; i < N; i++) begin
                            mem[i] <= in_data[i];
                        end
                        state <= RUN;
                    end
                end
                RUN: begin
                    mem[addr_a] <= u;
                    mem[addr_b] <= v;

                    if(b_cnt == LOG_N'((N >> 1) - 1)) begin
                        b_cnt <= 0;
                        if(stage == LOG_N'(LOG_N - 1)) begin
                            state <= FINISH;
                        end else begin
                            stage <= stage + 1;
                        end
                    end else begin
                        b_cnt <= b_cnt + 1;
                    end
                end

                FINISH: begin
                    for(int i = 0; i < N; i++) begin
                        out_data[i] <= WORD_SIZE'((128'(mem[bitrev(LOG_N'(i))]) * 128'(N_INV)) % 128'(q));
                    end
                    done <= 1'b1;
                    state <= IDLE;
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase 
        end
    end
endmodule
