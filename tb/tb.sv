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
    
    reg [31:0] fifo [$];

    reg [31:0] control;
	
    
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
    
    task write_fifo(input write_en, input TX_data, output full);

        if(write_en) begin 
            fifo.push = TX_data;
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
        awaddr  <=  32'Hx08;
        repeat (2) @(posedge aclk);
        awvalid <= 1;
        $display("awready = %0d, wready = %0d",awready,wready);
        repeat (5) @(posedge aclk);
        data_in <= $urandom;
        repeat (2) @(posedge aclk);
        wvalid <= 1;

        $display("awready = %0d, wready = %0d",awready,wready);
        repeat (6) @(posedge aclk);
        bready <= 1;

        $display("awready = %0d, wready = %0d, ",awready,wready);
        repeat (5) @(posedge aclk);
        $finish;

    end
    
    
     
endmodule