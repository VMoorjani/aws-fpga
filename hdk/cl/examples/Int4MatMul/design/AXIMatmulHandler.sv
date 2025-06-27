module AXIMatmulHandler #(
    parameter M = 8,
    parameter N = 8,
    parameter K = 8
)(
    input logic clk,
    input logic rst_n,

    input  logic        awvalid,
    input  logic [31:0] awaddr,
    output logic        awready,
    input  logic        wvalid,
    input  logic [31:0] wdata,
    input  logic [3:0]  wstrb,
    output logic        wready,
    output logic        bvalid,
    output logic [1:0]  bresp,
    input  logic        bready,
    input logic         arvalid,
    input logic  [31:0] araddr,
    output logic        arready,
    output logic        rvalid,
    output logic [31:0] rdata,
    output logic [1:0]  rresp,
    input logic         rready
);

    logic rst_n_sync;
    logic [31:0] control_reg; // 0x0000000

    logic signed [3:0] A [M][K];
    logic signed [3:0] B [K][N];
    logic signed [15:0] C [M][N];
    
    logic [31:0] axi_wr_addr;
    logic [31:0] axi_rd_addr;
    logic axi_wr_active;
    logic axi_rd_active;

    logic start_mult;
    logic busy_mult;
    logic done_mult;

    localparam int ADDR_CTL     = 32'h0000_0000;
    localparam int ADDR_A_BASE  = 32'h0000_0004;
    localparam int ADDR_B_BASE  = ADDR_A_BASE + (M*K)*4; // Start of B
    localparam int ADDR_C_BASE  = ADDR_B_BASE + (K*N)*4; // Start of C

    assign awready = !axi_wr_active; // ready for a write address = not already writing data
    assign arready = !axi_rd_active;
    assign wready = axi_wr_active && wvalid; // ready for write data = currently writing data && write data valid by master
    assign bresp = 2'b00;
    assign rresp = 2'b00;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rst_n_sync <= 1'b0;
        end else begin
            rst_n_sync <= 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n_sync) begin
            axi_wr_active <= 1'b0;
            axi_wr_addr <= 32'h00000000;
        end else begin
            if (awvalid && awready) begin
                axi_wr_active <= 1'b1;
                axi_wr_addr <= awaddr;
            end else if (wvalid && wready) axi_wr_active <= 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n_sync) bvalid <= 1'b0;
        else begin
            if (wvalid && wready) bvalid <= 1'b1;
            else if (bvalid && bready) bvalid <= 1'b0;
        end
    end

    matmul #(.M(M), .N(N), .K(K)) u_matmul (
        .clk(clk),
        .reset_n(rst_n_sync),
        .start(start_mult),
        .busy(busy_mult),
        .done(done_mult),
        .A(A),
        .B(B),
        .C(C) );

    assign start_mult = control_reg[0];

    always_ff @(posedge clk) begin
        if (!rst_n_sync) begin
            control_reg <= 32'h00000000;
        end else begin 
            if (busy_mult) control_reg[0] <= 1'b0;
            control_reg[2] <= busy_mult;
            if (done_mult) control_reg[3] <= 1'b1;
            if (busy_mult) control_reg[3] <= 1'b0;

            if (control_reg[1]) control_reg <= 32'h00000000;
            else if (wvalid && wready) begin
                if (axi_wr_addr == ADDR_CTL) begin
                    if (wstrb[0]) begin
                        control_reg[7:0] <= wdata[7:0];
                        if (wdata[0]) control_reg[3] <= 1'b0;
                    end
                    if (wstrb[1]) control_reg[15:8]  <= wdata[15:8];
                    if (wstrb[2]) control_reg[23:16] <= wdata[23:16];
                    if (wstrb[3]) control_reg[31:24] <= wdata[31:24];
                end else if (!busy_mult) begin
                    if (axi_wr_addr >= ADDR_A_BASE && axi_wr_addr < ADDR_B_BASE) begin
                        if (wstrb[0]) begin
                            int idx  = (axi_wr_addr - ADDR_A_BASE) >> 2; // word index
                            int row  = idx / K;
                            int col  = idx % K;
                            if (row < M) A[row][col] <= wdata[3:0];
                        end
                    end else if (axi_wr_addr >= ADDR_B_BASE && axi_wr_addr < ADDR_C_BASE) begin
                        if (wstrb[0]) begin
                            int idx  = (axi_wr_addr - ADDR_B_BASE) >> 2;
                            int row  = idx / N;
                            int col  = idx % N;
                            if (row < K) B[row][col] <= wdata[3:0];
                        end
                    end
                end
            end
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n_sync) begin
            axi_rd_active <= 1'b0;
            axi_rd_addr <= 32'h00000000;
        end else begin
            if (arvalid && arready) begin
                axi_rd_active <= 1'b1;
                axi_rd_addr <= araddr;
            end else if (rvalid && rready) axi_rd_active <= 1'b0;
        end
    end
    
    always_ff @(posedge clk) begin
        if (!rst_n_sync) begin
            rvalid <= 1'b0;
            rdata <= 32'h00000000;
        end else begin
            if (arvalid && arready) begin
                rvalid <= 1'b1;
                if (araddr == ADDR_CTL) begin
                    rdata <= control_reg;
                end else if (araddr >= ADDR_C_BASE && araddr < ADDR_C_BASE + (M*N)*4) begin
                    int idx  = (araddr - ADDR_C_BASE) >> 2;
                    int row  = idx / N;
                    int col  = idx % N;
                    rdata <= {16'h0, C[row][col]};
                end else begin
                    rdata <= 32'h00000000;
                end
            end else if (rvalid && rready) begin
                rvalid <= 1'b0;
                rdata <= 32'h00000000;
            end
        end
    end
    
endmodule