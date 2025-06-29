// Top-level wrapper for both 2D and 3D matrix multiplication
// Address mapping:
// 0x0000_0000 - 0x0000_FFFF: 2D Matrix Multiplication
// 0x0001_0000 - 0x0001_FFFF: 3D Matrix Multiplication
module AXIMatmulWrapper #(
    parameter BSZ = 4,  // Batch size for 3D
    parameter M = 8,
    parameter N = 8,
    parameter K = 8
)(
    input logic clk,
    input logic rst_n,

    // AXI4-Lite Interface
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

    // Address decode parameters
    localparam int ADDR_2D_BASE = 32'h0000_0000;
    localparam int ADDR_3D_BASE = 32'h0001_0000;
    localparam int ADDR_MASK    = 32'hFFFF_0000;

    // Address decode signals
    logic sel_2d, sel_3d;
    logic sel_2d_wr, sel_3d_wr;
    logic sel_2d_rd, sel_3d_rd;

    // 2D handler signals
    logic        awready_2d, wready_2d, bvalid_2d;
    logic [1:0]  bresp_2d;
    logic        arready_2d, rvalid_2d;
    logic [31:0] rdata_2d;
    logic [1:0]  rresp_2d;

    // 3D handler signals
    logic        awready_3d, wready_3d, bvalid_3d;
    logic [1:0]  bresp_3d;
    logic        arready_3d, rvalid_3d;
    logic [31:0] rdata_3d;
    logic [1:0]  rresp_3d;

    // Address decode logic
    assign sel_2d_wr = (awaddr & ADDR_MASK) == ADDR_2D_BASE;
    assign sel_3d_wr = (awaddr & ADDR_MASK) == ADDR_3D_BASE;
    assign sel_2d_rd = (araddr & ADDR_MASK) == ADDR_2D_BASE;
    assign sel_3d_rd = (araddr & ADDR_MASK) == ADDR_3D_BASE;

    // Output multiplexing
    assign awready = sel_2d_wr ? awready_2d : sel_3d_wr ? awready_3d : 1'b0;
    assign wready  = sel_2d_wr ? wready_2d  : sel_3d_wr ? wready_3d  : 1'b0;
    assign bvalid  = bvalid_2d | bvalid_3d;
    assign bresp   = bvalid_2d ? bresp_2d : bresp_3d;

    assign arready = sel_2d_rd ? arready_2d : sel_3d_rd ? arready_3d : 1'b0;
    assign rvalid  = rvalid_2d | rvalid_3d;
    assign rdata   = rvalid_2d ? rdata_2d : rdata_3d;
    assign rresp   = rvalid_2d ? rresp_2d : rresp_3d;

    // 2D Matrix Multiplication Handler
    AXIMatmulHandler #(.M(M), .N(N), .K(K)) u_axi_2d (
        .clk(clk),
        .rst_n(rst_n),

        .awvalid(awvalid & sel_2d_wr),
        .awaddr(awaddr),
        .awready(awready_2d),

        .wvalid(wvalid & sel_2d_wr),
        .wdata(wdata),
        .wstrb(wstrb),
        .wready(wready_2d),

        .bvalid(bvalid_2d),
        .bresp(bresp_2d),
        .bready(bready),

        .arvalid(arvalid & sel_2d_rd),
        .araddr(araddr),
        .arready(arready_2d),

        .rvalid(rvalid_2d),
        .rdata(rdata_2d),
        .rresp(rresp_2d),
        .rready(rready)
    );

    // 3D Matrix Multiplication Handler
    AXI3DMatmulHandler #(.BSZ(BSZ), .M(M), .N(N), .K(K)) u_axi_3d (
        .clk(clk),
        .rst_n(rst_n),

        .awvalid(awvalid & sel_3d_wr),
        .awaddr(awaddr - ADDR_3D_BASE), // Offset address for 3D handler
        .awready(awready_3d),

        .wvalid(wvalid & sel_3d_wr),
        .wdata(wdata),
        .wstrb(wstrb),
        .wready(wready_3d),

        .bvalid(bvalid_3d),
        .bresp(bresp_3d),
        .bready(bready),

        .arvalid(arvalid & sel_3d_rd),
        .araddr(araddr - ADDR_3D_BASE), // Offset address for 3D handler
        .arready(arready_3d),

        .rvalid(rvalid_3d),
        .rdata(rdata_3d),
        .rresp(rresp_3d),
        .rready(rready)
    );

endmodule 