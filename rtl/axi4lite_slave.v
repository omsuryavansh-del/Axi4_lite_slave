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
/*
    // address read channel lines
    input [31:0] araddr,
    input arvalid,
    output reg arready,

    // read data channel lines
    output reg [31:0] rdata,
    output reg [1:0] rresp,
    output reg rvalid,
    input rready,
*/
    //async fifo lines
    input full,
    output reg [31:0] Tx_data,
    output reg write_en
);

    reg [31:0] address_latch;
    reg [31:0] data_latch;

    reg [31:0] control_register;

    reg handshake;
    reg wdata_resp;
    reg control_resp;
    reg wrong_address;
    reg resp_check;

    reg [1:0] state, next_state;

    localparam IDLE = 2'b00,
               CAPTURE = 2'b01,
               WRITE = 2'b10,
               RESPONSE = 2'b11;

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            state <= IDLE;
        end
        else begin
            state <= next_state;
        end
    end

    always @(posedge aclk or negedge aresetn) begin
        case(state)
            IDLE: begin
                awready <= 0;
                wready <= 0;
                bvalid <= 0;
                write_en <= 0;
            end

            CAPTURE: begin
                if(awvalid && wvalid) begin
                    awready <= 1;
                    wready <= 1;
                end

                if(awready && wready) begin
                    address_latch <= awaddr;
                    data_latch <= data_in;
                    awready <= 0;
                    wready <= 0;
                    handshake <= 1;
                end
                else handshake <= 0;
            end

            WRITE: begin
                if(!full) write_en <= 1;
                else write_en <= 0;

                if(write_en == 1 && address_latch == 32'h08) begin
                    Tx_data <= data_latch;
                    wdata_resp <= 1;
                end

                if(write_en == 1 && address_latch == 32'h00) begin
                    control_register <= data_latch;
                    control_resp <= 1;
                end

                if(write_en == 1 && (address_latch == 32'h0c || address_latch == 32'h04)) begin
                    wrong_address <= 1;
                end
            end

            RESPONSE: begin
                if(wdata_resp || control_resp) begin
                    bresp <= 00;
                    resp_check <= 1;
                end
                else if (wrong_address) begin
                    bresp <= 10;
                    resp_check <= 1;
                end
                else begin
                    bresp <= 11;
                    resp_check <= 1;
                end
            end
        endcase
    end

    always @(*) begin
        if (!aresetn) begin
            next_state <= IDLE;
        end
        else begin
            case(state)
                IDLE: begin
                    if(awvalid && wvalid) next_state = CAPTURE;
                    else next_state <= IDLE;
                end

                CAPTURE: begin
                    if(handshake) next_state = WRITE;
                    else next_state <= CAPTURE;
                end

                WRITE: begin
                    if (wdata_resp || control_resp || wrong_address) next_state <= RESPONSE;
                    else next_state <= WRITE;
                end

                RESPONSE: begin
                    if (resp_check) next_state <= IDLE;
                    else next_state <= RESPONSE;
                end 
            endcase
        end
    end

endmodule

