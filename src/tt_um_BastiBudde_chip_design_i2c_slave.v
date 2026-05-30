/*
 * Copyright (c) 2026 Janina Speckmann, Sebastian Budde
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_BastiBudde_chip_design_i2c_slave (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

// I2C bus on uio[0] = SCL, uio[1] = SDA
wire scl_in    = uio_in[0];
wire sda_in    = uio_in[1];
wire sda_oe;                    // 1 = pull SDA low, 0 = release

top_level top_level_inst (
    .clk     (clk),
    .N_RST   (rst_n),
    .SCL     (scl_in),
    .sda_in  (sda_in),
    .sda_oe  (sda_oe)
);

    // SCL is input-only for the slave: never drive it
    // SDA is open-drain: drive '0' when sda_oe=1, otherwise release (Z)
    assign uio_out[0] = 1'b0;       // SCL output value (irrelevant, never driven)
    assign uio_out[1] = 1'b0;       // SDA drives '0' when enabled
    assign uio_out[7:2] = 6'b000000;

    assign uio_oe[0] = 1'b0;        // SCL never driven (always input)
    assign uio_oe[1] = sda_oe;      // SDA drives only when sda_oe is high
    assign uio_oe[7:2] = 6'b000000; // all other uio pins are inputs

    // Unused outputs
    assign uo_out = 8'b0;

    // Tell the synthesizer we deliberately ignore these inputs
    wire _unused = &{ena, ui_in, uio_in[7:2], 1'b0};

endmodule
