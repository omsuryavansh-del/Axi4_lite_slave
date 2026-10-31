
module Tx_async_fifo #(parameter data_width = 8, depth = 8, ptr_width = $clog2(depth) )(
    input clk_wr,
    input clk_rd,

    input rst_wr,
    input rst_rd,

    input write_en,
    input read_en,

    input [data_width-1:0] data_in_top,
    output [data_width-1:0] data_out_top,

    output full,
    output empty
);

    wire [ptr_width:0] async_wr_gptr, async_rd_gptr, sync_rd_gptr, sync_wr_gptr;
    wire full_con,empty_con;
    wire [ptr_width-1:0] write_addr, read_addr;

    write_ptr #(ptr_width) write_pointer (
        .wr_clk(clk_wr),
        .wr_rst_n(rst_wr),

        .write_en(write_en),
        .rd_gptr(sync_rd_gptr),

        .write_addr(write_addr),
        .wr_gptr(async_wr_gptr),
        .full(full_con)
    );
   
    read_ptr #(ptr_width) read_pointer (
        .rd_clk(clk_rd),
        .rd_rst_n(rst_rd),

        .read_en(read_en),
        .wr_gptr(sync_wr_gptr),

        .read_addr(read_addr),
        .rd_gptr(async_rd_gptr),
        .empty(empty_con)
    );

    FF_sync #(ptr_width) sync_write (
        .dest_clk(clk_rd),
        .rst_n(rst_rd),

        .ptr(async_wr_gptr),
        .sync_ptr(sync_wr_gptr)
    );

    FF_sync #(ptr_width) sync_read (
        .dest_clk(clk_wr),
        .rst_n(rst_wr),

        .ptr(async_rd_gptr),
        .sync_ptr(sync_rd_gptr)
    );

    fifo_mem #(data_width, depth, ptr_width) fifo_memory (
        .wr_clk(clk_wr),
        .rd_clk(clk_rd),
        
        .wr_addr(write_addr),
        .rd_addr(read_addr),

        .write_en(write_en),
        .read_en(read_en),

        .data_in(data_in_top),
        .data_out(data_out_top),

        .full(full_con),
        .empty(empty_con)
    );

    assign full = full_con;
    assign empty = empty_con;
endmodule

module FF_sync #(parameter WIDTH = 4) (
    input dest_clk,
    input rst_n,

    input [WIDTH-1:0] ptr,
    output [WIDTH-1:0] sync_ptr

);

(* ASYNC_REG = "TRUE", DONT_TOUCH = "TRUE" *) reg [WIDTH-1:0] sync_ff1;
(* ASYNC_REG = "TRUE", DONT_TOUCH = "TRUE" *) reg [WIDTH-1:0] sync_ff2;

always @(posedge dest_clk or negedge rst_n) begin 
    if (!rst_n) begin 
        sync_ff1 <= 0;
        sync_ff2 <= 0;
    end
    else begin 
        sync_ff1 <= ptr;
        sync_ff2 <= sync_ff1;
    end
end

assign sync_ptr = sync_ff2;
endmodule 


module fifo_mem #(parameter data_width = 8, depth = 8 ,ptr_width = $clog2(depth) ) (
//clock signals
    input wr_clk,
    input rd_clk,

//address
    input [ptr_width-1:0]wr_addr,
    input [ptr_width-1:0]rd_addr,

//enable signals
    input write_en,
    input read_en,

//data signals    
    input [data_width-1:0] data_in,
    output reg [data_width-1:0] data_out,

// flags
    input full,
    input empty
);

    reg [data_width-1:0] mem [0:depth - 1];
    
    always @(posedge wr_clk) begin
        if(write_en && !full) mem[wr_addr] <= data_in;
    end
    
    always @(posedge rd_clk) begin
        if(read_en && !empty) data_out <= mem[rd_addr];
    end
endmodule

module read_ptr #(parameter ptr_width = 3 ) (
    input rd_clk,
    input rd_rst_n,

    input read_en,
    input [ptr_width:0] wr_gptr,

    output [ptr_width - 1:0] read_addr,
    output reg [ptr_width:0]rd_gptr,
    output empty
);

reg [ptr_width:0] rd_ptr;

always @(posedge rd_clk or negedge rd_rst_n) begin
    if (!rd_rst_n)begin 
        rd_ptr <= {ptr_width + 1{1'b0}};
        rd_gptr <= {ptr_width + 1{1'b0}};
    end else begin
        if(read_en && (!empty)) begin
            rd_ptr <= rd_ptr + 1'b1;
            //gray logic
            rd_gptr <= ((rd_ptr + 1'b1) >> 1) ^ (rd_ptr + 1'b1);
        end
    end
end

assign empty = rd_gptr == wr_gptr;
assign read_addr = rd_ptr[ptr_width-1:0];
endmodule

module write_ptr #( parameter ptr_width = 3) (
    input wr_clk,
    input wr_rst_n,

    input write_en,
    input [ptr_width:0] rd_gptr,

    output [ptr_width - 1:0]write_addr,
    output reg [ptr_width:0] wr_gptr,
    output full
);
    
//gray counter
reg [ptr_width:0] wr_ptr;

always @(posedge wr_clk or negedge wr_rst_n) begin 
    if(!wr_rst_n) begin 
        wr_ptr <= {ptr_width + 1{1'b0}};
        wr_gptr <= {ptr_width + 1{1'b0}};
    end else begin 
        if (write_en && (!full)) begin  
            wr_ptr <= wr_ptr + 1'b1;
            //binary to gray logic
            wr_gptr <= {((wr_ptr + 1'b1) >> 1) ^ (wr_ptr + 1'b1)};
        end
    end 
end

assign full = (wr_gptr[ptr_width] != rd_gptr[ptr_width]) && (wr_gptr[ptr_width-1] != rd_gptr[ptr_width-1]) && (wr_gptr[ptr_width-2:0] == rd_gptr[ptr_width-2:0]);
assign write_addr = wr_ptr[ptr_width-1:0];
endmodule