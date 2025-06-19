module simple_register #(
    parameter DEFAULT_RESET_VALUE = 32'h00000000
)(
    input logic clk,
    input logic rst_n,

    // AXI Inputs
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

    logic [31:0] counter_reg;
    logic [31:0] reset_value_reg;
    logic [31:0] control_reg; // 0x0000000[0, 0, reset, enable]
    
    logic [31:0] axi_wr_addr;
    logic [31:0] axi_rd_addr;
    logic axi_wr_active;
    logic axi_rd_active;

    logic counter_enable;
    assign counter_enable = control_reg[0];
    logic software_reset_bit;
    assign software_reset_bit = control_reg[1];

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

    always_ff @(posedge clk) begin
        if (!rst_n_sync) begin
            counter_reg <= DEFAULT_RESET_VALUE;
            reset_value_reg <= DEFAULT_RESET_VALUE;
            control_reg <= 32'h00000000;
        end else begin 
            if (control_reg[1]) begin
                control_reg <= 32'h00000000;
                counter_reg <= reset_value_reg;
            end else if (wvalid && wready) begin
                case (axi_wr_addr[3:2])
                    2'b00: begin // 0x00000000
                        if (wstrb[0]) counter_reg[7:0]   <= wdata[7:0];
                        if (wstrb[1]) counter_reg[15:8]  <= wdata[15:8];
                        if (wstrb[2]) counter_reg[23:16] <= wdata[23:16];
                        if (wstrb[3]) counter_reg[31:24] <= wdata[31:24];
                    end
                    2'b01: begin // 0x00000004
                        if (wstrb[0]) reset_value_reg[7:0]   <= wdata[7:0];
                        if (wstrb[1]) reset_value_reg[15:8]  <= wdata[15:8];
                        if (wstrb[2]) reset_value_reg[23:16] <= wdata[23:16];
                        if (wstrb[3]) reset_value_reg[31:24] <= wdata[31:24];
                    end
                    2'b10: begin // 0x00000008
                        if (wstrb[0]) control_reg[7:0]   <= wdata[7:0];
                        if (wstrb[1]) control_reg[15:8]  <= wdata[15:8];
                        if (wstrb[2]) control_reg[23:16] <= wdata[23:16];
                        if (wstrb[3]) control_reg[31:24] <= wdata[31:24];
                    end
                    default: begin end
                endcase
            end else if (counter_enable) counter_reg <= counter_reg + 1;
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
                case (araddr[3:2])
                    2'b00: rdata <= counter_reg;
                    2'b01: rdata <= reset_value_reg;
                    2'b10: rdata <= control_reg;
                    default: rdata <= 32'h00000000;
                endcase
            end else if (rvalid && rready) begin
                rvalid <= 1'b0;
                rdata <= 32'h00000000;
            end
        end
    end
    
endmodule