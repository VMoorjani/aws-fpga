// ============================================================================
// Amazon FPGA Hardware Development Kit
//
// Copyright 2024 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Amazon Software License (the "License"). You may not use
// this file except in compliance with the License. A copy of the License is
// located at
//
//    http://aws.amazon.com/asl/
//
// or in the "license" file accompanying this file. This file is distributed on
// an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or
// implied. See the License for the specific language governing permissions and
// limitations under the License.
// ============================================================================


//====================================================================================
// Top level module file for SmolLM135M
//====================================================================================

`include "cl_dram_dma_pkg.sv"

module SmolLM135M
    #(
      parameter EN_DDR = 0,
      parameter EN_HBM = 1
    )
    (
      `include "cl_ports.vh"
    );

`include "cl_id_defines.vh" // CL ID defines required for all examples
`include "SmolLM135M_defines.vh"

//=============================================================================
// INTERNAL INTERFACES
//=============================================================================

  axi_bus_t  hbm_axi4_bus();
  cfg_bus_t  hbm_stat_cfg_bus();

//=============================================================================
// GLOBALS
//=============================================================================

  logic hbm_ready;

  always_comb begin
     cl_sh_flr_done    = 'b1;
     cl_sh_status0     = 'b0;
     cl_sh_status1     = 'b0;
     cl_sh_status2     = 'b0;
     cl_sh_id0         = `CL_SH_ID0;
     cl_sh_id1         = `CL_SH_ID1;
     cl_sh_status_vled = {15'b0, hbm_ready};
     cl_sh_dma_wr_full = 'b0;
     cl_sh_dma_rd_full = 'b0;
  end


//=============================================================================
// PCIM
//=============================================================================

  // Cause Protocol Violations
  always_comb begin
    cl_sh_pcim_awaddr  = 'b0;
    cl_sh_pcim_awsize  = 'b0;
    cl_sh_pcim_awburst = 'b0;
    cl_sh_pcim_awvalid = 'b0;

    cl_sh_pcim_wdata   = 'b0;
    cl_sh_pcim_wstrb   = 'b0;
    cl_sh_pcim_wlast   = 'b0;
    cl_sh_pcim_wvalid  = 'b0;

    cl_sh_pcim_araddr  = 'b0;
    cl_sh_pcim_arsize  = 'b0;
    cl_sh_pcim_arburst = 'b0;
    cl_sh_pcim_arvalid = 'b0;
  end

  // Remaining CL Output Ports
  always_comb begin
    cl_sh_pcim_awid    = 'b0;
    cl_sh_pcim_awlen   = 'b0;
    cl_sh_pcim_awcache = 'b0;
    cl_sh_pcim_awlock  = 'b0;
    cl_sh_pcim_awprot  = 'b0;
    cl_sh_pcim_awqos   = 'b0;
    cl_sh_pcim_awuser  = 'b0;

    cl_sh_pcim_wid     = 'b0;
    cl_sh_pcim_wuser   = 'b0;

    cl_sh_pcim_arid    = 'b0;
    cl_sh_pcim_arlen   = 'b0;
    cl_sh_pcim_arcache = 'b0;
    cl_sh_pcim_arlock  = 'b0;
    cl_sh_pcim_arprot  = 'b0;
    cl_sh_pcim_arqos   = 'b0;
    cl_sh_pcim_aruser  = 'b0;

    cl_sh_pcim_rready  = 'b0;
  end

//=============================================================================
// PCIS
//=============================================================================

  // Cause Protocol Violations
  always_comb begin
    cl_sh_dma_pcis_bresp   = 'b0;
    cl_sh_dma_pcis_rresp   = 'b0;
    cl_sh_dma_pcis_rvalid  = 'b0;
  end

  // Remaining CL Output Ports
  always_comb begin
    cl_sh_dma_pcis_awready = 'b0;

    cl_sh_dma_pcis_wready  = 'b0;

    cl_sh_dma_pcis_bid     = 'b0;
    cl_sh_dma_pcis_bvalid  = 'b0;

    cl_sh_dma_pcis_arready  = 'b0;

    cl_sh_dma_pcis_rid     = 'b0;
    cl_sh_dma_pcis_rdata   = 'b0;
    cl_sh_dma_pcis_rlast   = 'b0;
    cl_sh_dma_pcis_ruser   = 'b0;
  end

//=============================================================================
// OCL
//=============================================================================

  // Cause Protocol Violations
  always_comb begin
    cl_ocl_bresp   = 'b0;
    cl_ocl_rresp   = 'b0;
    cl_ocl_rvalid  = 'b0;
  end

  // Remaining CL Output Ports
  always_comb begin
    cl_ocl_awready = 'b0;
    cl_ocl_wready  = 'b0;

    cl_ocl_bvalid = 'b0;

    cl_ocl_arready = 'b0;

    cl_ocl_rdata   = 'b0;
  end

//=============================================================================
// SDA
//=============================================================================

  // Cause Protocol Violations
  always_comb begin
    cl_sda_bresp   = 'b0;
    cl_sda_rresp   = 'b0;
    cl_sda_rvalid  = 'b0;
  end

  // Remaining CL Output Ports
  always_comb begin
    cl_sda_awready = 'b0;
    cl_sda_wready  = 'b0;

    cl_sda_bvalid = 'b0;

    cl_sda_arready = 'b0;

    cl_sda_rdata   = 'b0;
  end

//=============================================================================
// SH_DDR
//=============================================================================

   sh_ddr
     #(
       .DDR_PRESENT (EN_DDR)
       )
   SH_DDR
     (
      .clk                       (clk_main_a0 ),
      .rst_n                     (            ),
      .stat_clk                  (clk_main_a0 ),
      .stat_rst_n                (            ),
      .CLK_DIMM_DP               (CLK_DIMM_DP ),
      .CLK_DIMM_DN               (CLK_DIMM_DN ),
      .M_ACT_N                   (M_ACT_N     ),
      .M_MA                      (M_MA        ),
      .M_BA                      (M_BA        ),
      .M_BG                      (M_BG        ),
      .M_CKE                     (M_CKE       ),
      .M_ODT                     (M_ODT       ),
      .M_CS_N                    (M_CS_N      ),
      .M_CLK_DN                  (M_CLK_DN    ),
      .M_CLK_DP                  (M_CLK_DP    ),
      .M_PAR                     (M_PAR       ),
      .M_DQ                      (M_DQ        ),
      .M_ECC                     (M_ECC       ),
      .M_DQS_DP                  (M_DQS_DP    ),
      .M_DQS_DN                  (M_DQS_DN    ),
      .cl_RST_DIMM_N             (RST_DIMM_N  ),
      .cl_sh_ddr_axi_awid        (            ),
      .cl_sh_ddr_axi_awaddr      (            ),
      .cl_sh_ddr_axi_awlen       (            ),
      .cl_sh_ddr_axi_awsize      (            ),
      .cl_sh_ddr_axi_awvalid     (            ),
      .cl_sh_ddr_axi_awburst     (            ),
      .cl_sh_ddr_axi_awuser      (            ),
      .cl_sh_ddr_axi_awready     (            ),
      .cl_sh_ddr_axi_wdata       (            ),
      .cl_sh_ddr_axi_wstrb       (            ),
      .cl_sh_ddr_axi_wlast       (            ),
      .cl_sh_ddr_axi_wvalid      (            ),
      .cl_sh_ddr_axi_wready      (            ),
      .cl_sh_ddr_axi_bid         (            ),
      .cl_sh_ddr_axi_bresp       (            ),
      .cl_sh_ddr_axi_bvalid      (            ),
      .cl_sh_ddr_axi_bready      (            ),
      .cl_sh_ddr_axi_arid        (            ),
      .cl_sh_ddr_axi_araddr      (            ),
      .cl_sh_ddr_axi_arlen       (            ),
      .cl_sh_ddr_axi_arsize      (            ),
      .cl_sh_ddr_axi_arvalid     (            ),
      .cl_sh_ddr_axi_arburst     (            ),
      .cl_sh_ddr_axi_aruser      (            ),
      .cl_sh_ddr_axi_arready     (            ),
      .cl_sh_ddr_axi_rid         (            ),
      .cl_sh_ddr_axi_rdata       (            ),
      .cl_sh_ddr_axi_rresp       (            ),
      .cl_sh_ddr_axi_rlast       (            ),
      .cl_sh_ddr_axi_rvalid      (            ),
      .cl_sh_ddr_axi_rready      (            ),
      .sh_ddr_stat_bus_addr      (            ),
      .sh_ddr_stat_bus_wdata     (            ),
      .sh_ddr_stat_bus_wr        (            ),
      .sh_ddr_stat_bus_rd        (            ),
      .sh_ddr_stat_bus_ack       (            ),
      .sh_ddr_stat_bus_rdata     (            ),
      .ddr_sh_stat_int           (            ),
      .sh_cl_ddr_is_ready        (            )
      );

  always_comb begin
    cl_sh_ddr_stat_ack   = 'b0;
    cl_sh_ddr_stat_rdata = 'b0;
    cl_sh_ddr_stat_int   = 'b0;
  end

//=============================================================================
// USER-DEFIEND INTERRUPTS
//=============================================================================

  always_comb begin
    cl_sh_apppf_irq_req = 'b0;
  end

//=============================================================================
// VIRTUAL JTAG
//=============================================================================

  always_comb begin
    tdo = 'b0;
  end

//=============================================================================
// HBM INTERFACE
//=============================================================================

  // Tie off the HBM AXI4 bus for now (user can connect their logic here)
  always_comb begin
    hbm_axi4_bus.awvalid = 'b0;
    hbm_axi4_bus.awaddr  = 'b0;
    hbm_axi4_bus.awid    = 'b0;
    hbm_axi4_bus.awlen   = 'b0;
    hbm_axi4_bus.awsize  = 'b0;
    hbm_axi4_bus.awburst = 'b0;
    
    hbm_axi4_bus.wvalid  = 'b0;
    hbm_axi4_bus.wdata   = 'b0;
    hbm_axi4_bus.wstrb   = 'b0;
    hbm_axi4_bus.wlast   = 'b0;
    hbm_axi4_bus.wid     = 'b0;
    
    hbm_axi4_bus.bready  = 'b1;
    
    hbm_axi4_bus.arvalid = 'b0;
    hbm_axi4_bus.araddr  = 'b0;
    hbm_axi4_bus.arid    = 'b0;
    hbm_axi4_bus.arlen   = 'b0;
    hbm_axi4_bus.arsize  = 'b0;
    hbm_axi4_bus.arburst = 'b0;
    
    hbm_axi4_bus.rready  = 'b1;
  end

  // Tie off the HBM stats config bus for now
  always_comb begin
    hbm_stat_cfg_bus.ack   = 'b1;
    hbm_stat_cfg_bus.rdata = 'b0;
  end

  logic hbm_sync_rst_n;

  xpm_cdc_async_rst CDC_ASYNC_RST_N_HBM
  (
    .src_arst               (rst_main_n               ),
    .dest_clk               (clk_main_a0              ),
    .dest_arst              (hbm_sync_rst_n           )
  );

  cl_hbm_axi4
  #(
    .HBM_PRESENT            (EN_HBM                   )
  )
  CL_HBM
  (
    .clk_hbm_ref            (clk_hbm_ref              ),
    .clk                    (clk_main_a0              ),
    .rst_n                  (hbm_sync_rst_n           ),
    .hbm_axi4_bus           (hbm_axi4_bus             ),
    .hbm_stat_bus           (hbm_stat_cfg_bus         ),
    .i_hbm_apb_preset_n_1   (hbm_apb_preset_n_1       ),
    .o_hbm_apb_paddr_1      (hbm_apb_paddr_1          ),
    .o_hbm_apb_pprot_1      (hbm_apb_pprot_1          ),
    .o_hbm_apb_psel_1       (hbm_apb_psel_1           ),
    .o_hbm_apb_penable_1    (hbm_apb_penable_1        ),
    .o_hbm_apb_pwrite_1     (hbm_apb_pwrite_1         ),
    .o_hbm_apb_pwdata_1     (hbm_apb_pwdata_1         ),
    .o_hbm_apb_pstrb_1      (hbm_apb_pstrb_1          ),
    .o_hbm_apb_pready_1     (hbm_apb_pready_1         ),
    .o_hbm_apb_prdata_1     (hbm_apb_prdata_1         ),
    .o_hbm_apb_pslverr_1    (hbm_apb_pslverr_1        ),
    .i_hbm_apb_preset_n_0   (hbm_apb_preset_n_0       ),
    .o_hbm_apb_paddr_0      (hbm_apb_paddr_0          ),
    .o_hbm_apb_pprot_0      (hbm_apb_pprot_0          ),
    .o_hbm_apb_psel_0       (hbm_apb_psel_0           ),
    .o_hbm_apb_penable_0    (hbm_apb_penable_0        ),
    .o_hbm_apb_pwrite_0     (hbm_apb_pwrite_0         ),
    .o_hbm_apb_pwdata_0     (hbm_apb_pwdata_0         ),
    .o_hbm_apb_pstrb_0      (hbm_apb_pstrb_0          ),
    .o_hbm_apb_pready_0     (hbm_apb_pready_0         ),
    .o_hbm_apb_prdata_0     (hbm_apb_prdata_0         ),
    .o_hbm_apb_pslverr_0    (hbm_apb_pslverr_0        ),
    .o_cl_sh_hbm_stat_int   (                         ),
    .o_hbm_ready            (hbm_ready                )
  );

//=============================================================================
//
//=============================================================================

  always_comb begin
    PCIE_EP_TXP    = 'b0;
    PCIE_EP_TXN    = 'b0;

    PCIE_RP_PERSTN = 'b0;
    PCIE_RP_TXP    = 'b0;
    PCIE_RP_TXN    = 'b0;
  end

endmodule // SmolLM135M
