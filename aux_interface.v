module aux_interface(
    input        clk,
    input        rst,
    input  [31:0] aux_in,
    output reg [31:0] aux_i
);

// To store the auxiliary inputs
always @(posedge clk or posedge rst)
begin
    if (rst)
        aux_i <= 32'b0;
    else
        aux_i <= aux_in;
end

endmodule


module tb_aux_interface;

    // Inputs
    reg         clk;
    reg         rst;
    reg [31:0]  aux_in;

    // Output
    wire [31:0] aux_i;

    // Instantiate the DUT (Device Under Test)
    aux_interface uut (
        .clk    (clk),
        .rst    (rst),
        .aux_in (aux_in),
        .aux_i  (aux_i)
    );

    // Clock generation (10 ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Stimulus
    initial begin

        // Initialize inputs
        rst    = 1;
        aux_in = 32'h00000000;

        // Hold reset for some time
        #12;
        rst = 0;

        // Apply test values
        #10 aux_in = 32'h12345678;
        #10 aux_in = 32'hAAAAAAAA;
        #10 aux_in = 32'h55555555;
        #10 aux_in = 32'hFFFFFFFF;
        #10 aux_in = 32'h0F0F0F0F;

        // Assert reset again
        #10 rst = 1;
        #10 rst = 0;

        // Apply another value
        #10 aux_in = 32'hABCDEF12;

        // End simulation
        #20;
        $finish;
    end

    // Monitor signals
    initial begin
        $monitor("Time=%0t | rst=%b | aux_in=%h | aux_i=%h",
                  $time, rst, aux_in, aux_i);
    end

endmodule