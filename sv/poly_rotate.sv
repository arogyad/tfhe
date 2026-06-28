module poly_rotate import tfhe_pkg::*; (
    input logic clk,
    input logic rst,
    input logic start,
    input data_t poly [0: N - 1],
    input logic [LOG_N : 0] rot,
    output logic done,
    output data_t out_data [0: N - 1]
);

    typedef enum logic [1:0] {IDLE, RUN, FINISH} state_t;
    state_t state;
    logic [LOG_N : 0] rot2;
    logic signed [1:0] sign;
    logic [LOG_N - 1: 0] i;

    always_ff @( posedge clk or posedge rst ) begin
        if(rst) begin
            state <= IDLE;
            done <= 1'b0;
            rot2 <= 0;
            sign <= 1;
            i <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0; 
                    i <= 0;

                    if (rot >= (LOG_N + 1)'(N)) begin
                        sign <= -1;
                        rot2 <= rot - (LOG_N + 1)'(N);
                        // $display("Rotation is: %0d", rot2);
                    end else begin
                        sign <= 1;
                        rot2 <= rot;
                    end
                    
                    if (start) state <= RUN;
                end

                RUN: begin
                    logic [LOG_N - 1: 0] out_i;
                    logic signed [WORD_SIZE : 0] curr_val;

                    out_i = i + LOG_N'(rot2);

                    if (i <= LOG_N'(N - 32'(rot2) - 1)) begin
                        curr_val = signed'({1'b0, poly[i]}) * sign;
                    end else begin
                        curr_val = -signed'({1'b0, poly[i]}) * sign;
                    end

                    if (curr_val >= q_signed_2)  
                        out_data[out_i] <= WORD_SIZE'(curr_val - q_signed_2);
                    else if (curr_val < 0) 
                        out_data[out_i] <= WORD_SIZE'(curr_val + q_signed_2);
                    else
                        out_data[out_i] <= WORD_SIZE'(curr_val);

                    if (i == LOG_N'(N - 1)) begin
                        state <= FINISH;
                    end else begin
                        i <= i + 1;
                    end
                end

                FINISH: begin
                    done <= 1'b1;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
