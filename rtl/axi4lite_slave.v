module axi4lite (
    // global signals
    input aclk,
    input aresetn,    

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
    input rready,

    //async fifo lines
    input full,
    input empty,
    output reg [31:0] Tx_data,
    output reg write_en,
    output reg read_en,
    input [31:0] Rx_data
);

    reg [31:0] address_latch;
    reg [31:0] data_latch;
    reg [31:0] control_register;
    reg write_success;

    reg read_success;
    reg [31:0] raddress_latch;

    reg [1:0] state, next_state;
    reg [1:0] state_r, next_state_r;

    localparam IDLE = 2'b00,
               CAPTURE = 2'b01,
               WRITE = 2'b10,
               RESPONSE = 2'b11;
    
    localparam IDLE_R = 2'b00,
               CAPTURE_R = 2'b01,
               READ = 2'b10,
               DONE = 2'b11;


    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            state <= IDLE;
        end
        else begin
            state <= next_state;
        end
    end
//write block
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin 
            state <= IDLE;
        end else begin
            case(state)
                IDLE: begin
                    awready <= 0;
                    wready <= 0;
                    bvalid <= 0;
                    write_en <= 0;
                end

                CAPTURE: begin
                    awready <= 1;
                    wready <= 1;
                    if(awready && wready) begin
                        address_latch <= awaddr;
                        data_latch <= data_in;
                        awready <= 0;
                        wready <= 0;
                    end
                end

                WRITE: begin
                    if(address_latch[1:0] == 2'b00) begin   
                        case (address_latch[3:2])
                            2'b00: begin
                                control_register <= data_latch;
                                bresp <= 2'b00;
                                write_success <= 1'b1;
                            end
                            2'b10: begin
                                if(!full) begin
                                    Tx_data <= data_latch;
                                    write_en <= 1'b1;
                                    bresp <= 2'b00;
                                    write_success <= 1'b1;
                                end
                            end
                            default: begin
                                bresp <= 2'b10;
                                write_success <= 1'b1;
                            end
                        endcase
                    end else begin
                        bresp <= 2'b10;
                        write_success <= 1'b1;
                    end
                end

                RESPONSE: begin
                    bvalid <= 1'b1;
                    write_en <= 1'b0;
                end
            endcase
        end
    end

    always @(*) begin
        if (!aresetn) begin
            next_state = IDLE;
        end
        else begin
            case(state)
                IDLE: next_state = (awvalid & wvalid) ? CAPTURE:IDLE;
                CAPTURE: next_state = (awready & wready)? WRITE: CAPTURE;
                WRITE: next_state = (write_success) ? RESPONSE: WRITE;
                RESPONSE: next_state = bready ? IDLE: RESPONSE;
            endcase
        end
    end

//read block
    always @(posedge aclk or negedge aresetn) begin 
        if(!aresetn) begin
            state_r <= IDLE;
        end else begin
            state_r <= next_state_r;
        end
    end

    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            state_r <= IDLE;
        end else begin
            case(state_r) 
                IDLE_R: begin
                    arready <= 1'b0;
                    read_en <= 1'b0;
                    bvalid <= 1'b0;
                end

                CAPTURE_R: begin     
                    arready <= 1'b1;  
                    if(arready) begin
                        raddress_latch <= araddr;
                    end
                end

                READ: begin
                    if(!empty && raddress_latch == 32'h0c) begin
                        read_en <= 1'b1;
                        rresp <= 2'b00;
                    end else begin
                        rresp <= 2'b10;
                        read_success <= 1'b1;
                    end
                    if(read_en) begin
                        rdata <= Rx_data;
                        read_success <= 1'b1;
                    end
                end

                DONE: begin
                    read_en <= 1'b0;
                    bvalid <= 1'b1;
                end
            endcase
        end
    end

    always @(*) begin 
        case(state_r)
            IDLE_R: next_state_r = arvalid? CAPTURE_R:IDLE_R;
            CAPTURE_R: next_state_r = arready? READ:CAPTURE_R;
            READ: next_state_r = read_success? DONE:READ; 
            DONE: next_state_r = bready? IDLE:DONE;
        endcase
    end
endmodule

