`timescale 1ns/100ps
module tb;
    
    reg aclk;
    reg aresetn;    

    // address write channel lines
    reg [31:0] awaddr;
    reg awvalid;
    wire awready;

    // write data channel lines
    reg [31:0] data_in;
    //reg [3:0] wstrb,
    reg wvalid;
    wire wready;

    // write response channel lines
    wire [1:0] bresp;
    wire bvalid;
    reg bready;

    wire [31:0] Tx_data;
    reg full;
    wire write_en;
    
    reg [31:0] fifo [$:8];

    reg [31:0] control_reg;
	
    
    axi4lite dut ( 
    .aclk(aclk),
	.aresetn(aresetn),

	.awaddr(awaddr),
	.awready(awready),
    .awvalid(awvalid),
    
	.data_in(data_in),
	.wvalid(wvalid),
	.wready(wready),

	.bresp(bresp),
	.bready(bready),
    .bvalid(bvalid),

    .full(full),
    .Tx_data(Tx_data),
    .write_en(write_en)
    );
    
    task write_fifo(input  write_en, input [31:0] TX_data, output full);
        begin
            if(write_en) begin 
                fifo.push_back(TX_data);
            end
            if (fifo.size() > 7) full = 1'b1;
            else full = 1'b0;
        end
    endtask
    
    initial begin 
    	aclk = 0;
    end 

    always #5 aclk = ~aclk;

    initial begin 
	    aresetn <= 0;
	    repeat(4) @(posedge aclk);
	    aresetn <= 1;
        full <= 0;
        awaddr  <=  32'h0000_0008;
        repeat (2) @(posedge aclk);
        awvalid <= 1;
        $display("awready = %0d, wready = %0d",awready,wready);
        repeat (5) @(posedge aclk);
        data_in <= $urandom;
        write_fifo(write_en, Tx_data ,full);
        repeat (2) @(posedge aclk);
        wvalid <= 1;
        write_fifo(write_en, Tx_data ,full);
        $display("awready = %0d, wready = %0d, fifo_data = %0h",awready,wready,fifo.pop_front());
        repeat (2) @(posedge aclk);
        write_fifo(write_en, Tx_data ,full);
        $display("awready = %0d, wready = %0d, fifo_data = %0h",awready,wready,fifo.pop_front());
        repeat (4) @(posedge aclk);
        bready <= 1;
        write_fifo(write_en, Tx_data ,full);
        $display("awready = %0d, wready = %0d, ",awready,wready);
        repeat(4) @(posedge aclk);
        data_in <= $urandom;
        wvalid <= 1;
        write_fifo(write_en, Tx_data ,full);
        $display("awready = %0d, wready = %0d, fifo_data = %0h",awready,wready,fifo.pop_front());
        repeat (6) @(posedge aclk);
        awaddr <= 32'h0000_0000;
        awvalid <= 1;
        write_fifo(write_en, Tx_data ,full);
        $display("awready = %0d, wready = %0d, fifo_data = %0h",awready,wready,fifo.pop_front());
        repeat (5) @(posedge aclk);

        $finish;

    end
    
    
     
endmodule