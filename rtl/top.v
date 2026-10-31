module top(
    //clock signals
    input aclk,
    input aresetn,

    input sclk,
    input sresetn,

    // address write channel lines
    input [31:0] awaddr,
    input awvalid,
    output reg awready,

    // write data channel lines
    input [31:0] data_in,
    //input [3:0] wstrb,
    input wvalid,
    output reg wready,

    // write response channel lines
    output reg [1:0] bresp,
    output reg bvalid,
    input bready,

    // address read channel lines
    input [31:0] araddr,
    input arvalid,
    output reg arready,

    // read data channel lines
    output reg [31:0] rdata,
    output reg [1:0] rresp,
    output reg rvalid,
    input rready    

    //
);

    reg Tx_write_en, Tx_read_en;
    reg Tx_full, Tx_empty;
    reg [31:0] Tx_data_in;
    reg [31:0] Tx_data_out;

    reg [31:0] Rx_data_in;
    reg [31:0] Rx_data_out;
    reg Rx_write_en, Rx_read_en;
    reg Rx_full, Rx_empty;

    axi4lite_slave  slave (
        .aclk(aclk),
        .aresetn(aresetn),    

        // address write channel lines
        .awaddr(awaddr),
        .awvalid(awvalid),
        .awready(awready),

        // write data channel lines
        .data_in(data_in),
        // [3:0] wstrb,
        .wvalid(wvalid),
        .wready,

        // write response channel lines
        .bresp(bresp),
        .bvalid(bvalid),
        .bready(bready),

        // address read channel lines
        .araddr(araddr),
        .arvalid(arvalid),
        .arready(arready),

        // read data channel lines
        .rdata(rdata),
        .rresp(rresp),
        .rvalid(rvalid),
        .rready(rready),

        //async fifo lines
        .full(Tx_full),
        .empty(Rx_empty),
        .Tx_data(Tx_data_in),
        .write_en(Tx_write_en),
        .read_en(Rx_read_en),
        .Rx_data(Rx_data_out)
    );

    Tx_async_fifo write_fifo (
        .clk_wr(aclk),
        .clk_rd(sclk),

        .rst_wr(aresetn),
        .rst_rd(sclk),

        .write_en(Tx_write_en),
        .read_en(Tx_read_en),

        .data_in_top(Tx_data_in),
        .data_out_top(Tx_data_out),

        .full(Tx_full),
        .empty(Tx_empty)
    );

    Rx_async_fifo read_fifo (
    .clk_wr(sclk),
    .clk_rd(aclk),

    .rst_wr(sresetn),
    .rst_rd(aresetn),

    .write_en(Rx_write_en),
    .read_en(Rx_read_en),

    .data_in_top(Rx_data_in),
    .data_out_top(Rx_data_out),

    .full(Rx_full),
    .empty(Tx_empty)
    );
endmodule