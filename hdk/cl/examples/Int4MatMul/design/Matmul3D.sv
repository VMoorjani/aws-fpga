// Multiplies 2 3D Int4 tensors with shapes BxMxK, BxKxN (batched 2D matrix multiplication)
module Matmul3D #(
    parameter BSZ = 4,  // Batch size
    parameter M = 8,
    parameter N = 8,
    parameter K = 8
)(
    input logic clk,
    input logic reset_n,
    
    input logic start,
    output logic busy,
    output logic done,
    
    input logic signed [3:0] A [BSZ][M][K],
    input logic signed [3:0] B [BSZ][K][N],
    output logic signed [15:0] C [BSZ][M][N]
    );
    
    typedef enum logic [1:0] {
        awaiting_start, 
        computing,
        complete    
    } state;
    
    state current_state, next_state;
    
    logic [$clog2(BSZ)-1:0] batch_idx, next_batch_idx;
    logic [$clog2(M)-1:0] row_in_a, next_row_in_a; 
    logic [$clog2(N)-1:0] col_in_b, next_col_in_b;
    logic [$clog2(K)-1:0] cur_idx, next_idx;
    
    logic signed [15:0] accumulator, next_accumulator;
    logic signed [7:0] product;
    
    always_ff @(posedge clk) 
        begin
            if (!reset_n) begin
                current_state <= awaiting_start;
                batch_idx <= 0;
                row_in_a <= 0;
                col_in_b <= 0;
                cur_idx <= 0;
                accumulator <= 0; 
            end else begin
                current_state <= next_state;
                batch_idx <= next_batch_idx;
                row_in_a <= next_row_in_a;
                col_in_b <= next_col_in_b;
                cur_idx <= next_idx;
                accumulator <= next_accumulator;
                if (current_state == computing && cur_idx == K - 1) 
                    C[batch_idx][row_in_a][col_in_b] <= accumulator + product;
            end
        end
    
    
    always_comb begin
        next_state = current_state;
        done = 1'b0;
        busy = 1'b0;
        next_batch_idx = batch_idx;
        next_row_in_a = row_in_a;
        next_col_in_b = col_in_b;
        next_idx = cur_idx;
        next_accumulator = accumulator;
        product = A[batch_idx][row_in_a][cur_idx] * B[batch_idx][cur_idx][col_in_b];
        
        case (current_state)
            awaiting_start: begin
                if (start) begin
                    next_state = computing;
                    next_batch_idx = 0;
                    next_row_in_a = 0;
                    next_col_in_b = 0;
                    next_idx = 0;
                    next_accumulator = 0;
                end 
            end
            
            computing: begin
                busy = 1'b1;
                next_accumulator = accumulator + product;
                
                if (cur_idx < K - 1) begin
                    next_idx = cur_idx + 1;
                end else begin 
                    next_idx = 0;
                    next_accumulator = 0;
                    
                    if (col_in_b < N - 1) begin
                        next_col_in_b = col_in_b + 1;
                    end else begin
                        next_col_in_b = 0;
                        if (row_in_a < M - 1) begin
                            next_row_in_a = row_in_a + 1;
                        end else begin
                            next_row_in_a = 0;
                            if (batch_idx < BSZ - 1) begin
                                next_batch_idx = batch_idx + 1;
                            end else begin
                                next_state = complete;
                            end
                        end
                    end
                end
            end
            
            complete: begin
                done = 1'b1;
                next_state = awaiting_start;
            end
        endcase
     end
endmodule
