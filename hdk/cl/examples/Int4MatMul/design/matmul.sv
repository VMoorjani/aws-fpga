// Multiplies 2 Int4 matrices with shapes MxK, KxN
module matmul #(
    parameter M = 8,
    parameter N = 8,
    parameter K = 8
)(
    input logic clk,
    input logic reset_n,
    
    input logic start,
    output logic busy,
    output logic done,
    
    input logic signed [3:0] A [M][K],
    input logic signed [3:0] B [K][N],
    output logic signed [15:0] C [M][N]
    );
    
    typedef enum logic [1:0] {
        awaiting_start, 
        computing,
        complete    
    } state;
    
    state current_state, next_state;
    
    logic [$clog2(M)-1:0] row_in_a, next_row_in_a; 
    logic [$clog2(N)-1:0] col_in_b, next_col_in_b;
    logic [$clog2(K)-1:0] cur_idx, next_idx;
    
    logic signed [15:0] accumulator, next_accumulator;
    logic signed [7:0] product;
    
    always_ff @(posedge clk) 
        begin
            if (!reset_n) begin
                current_state <= awaiting_start;
                row_in_a <= 0;
                col_in_b <= 0;
                cur_idx <= 0;
                accumulator <= 0; 
            end else begin
                current_state <= next_state;
                row_in_a <= next_row_in_a;
                col_in_b <= next_col_in_b;
                cur_idx <= next_idx;
                accumulator <= next_accumulator;
                if (current_state == computing && cur_idx == K - 1) C[row_in_a][col_in_b] <= accumulator + product; // Since the product will only be addded to accumulator in this clock cycle, need to account
            end
        end
    
    
    always_comb begin
        next_state = current_state;
        done = 1'b0;
        busy = 1'b0;
        next_row_in_a = row_in_a;
        next_col_in_b = col_in_b;
        next_idx = cur_idx;
        next_accumulator = accumulator;
        product = A[row_in_a][cur_idx] * B[cur_idx][col_in_b];
        
        case (current_state)
            awaiting_start: begin
                if (start) begin
                    next_state = computing;
                    next_row_in_a = 0;
                    next_col_in_b = 0;
                    next_idx = 0;
                    next_accumulator = 0;
                end 
            end
            
            computing: begin
                busy = 1'b1;
                // have you reached the end of the current row/col?
                next_accumulator = accumulator + product;
                if (cur_idx < K - 1) next_idx = cur_idx + 1;
                else begin // you have reached the end of the current row and column
                    next_idx = 0;
                    next_accumulator = 0;
                    if (col_in_b < N - 1) next_col_in_b = col_in_b + 1;
                    else begin
                        next_col_in_b = 0;
                        if (row_in_a < M - 1) next_row_in_a = row_in_a + 1;
                        else next_state = complete;
                    end
                end
            end
            complete: begin
                done = 1'b1; // I could check if start is high here, but I want there to be some buffer between computations, at least while debugging
                next_state = awaiting_start;
            end
        endcase
     end
     
     
     // Since I am using INT4 can be between -8 and 7. So the max any multiplication can be is between -56 and 64. 7 bit int would have a range of -64 to 63 so have to use 8bit int for the product. 
     // Now each individual product can be upto 8 bits, but adding many of these can go well beyond. Since you are adding K of them together for a single cell, so the potential output range is from 
     // -64K to 63K. The range for 16 bits will be -2^15 to 2^15-1 which is -32768 to 32767. So basically, K can go upto 512 without any issues with overflowing for 16 bits. 
endmodule