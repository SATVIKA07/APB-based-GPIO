
`define GPIO_RGPIO_IN      32'h00
`define GPIO_RGPIO_OUT     32'h04
`define GPIO_RGPIO_OE      32'h08
`define GPIO_RGPIO_INTE    32'h0c
`define GPIO_RGPIO_PTRIG   32'h10
`define GPIO_RGPIO_AUX     32'h14
`define GPIO_RGPIO_CTRL    32'h18
`define GPIO_RGPIO_INTS    32'h1c
`define GPIO_RGPIO_ECLK    32'h20
`define GPIO_RGPIO_NEC     32'h24

`define GPIO_RGPIO_CTRL_INTE   0
`define GPIO_RGPIO_CTRL_INTS   1



module gpio_core_tb();

reg         PCLK,PRESET;
wire [31:0] PRDATA;
reg  [31:0] PADDR,PWDATA;
reg         PSEL,PENABLE,PWRITE;
reg  [31:0] aux_in;
wire        IRQ,PREADY;
wire [31:0] io_pad;
reg         ext_clk_pad_i;


gpio_core DUT(
    PCLK,
    PRESET,
    PRDATA,
    PADDR,
    PWDATA,
    PSEL,
    PENABLE,
    PWRITE,
    aux_in,
    IRQ,
    PREADY,
    io_pad,
    ext_clk_pad_i
);

// Gen PCLK

initial
    PCLK=1'b0;

always #5
    PCLK=~PCLK;

//Gen extclk

initial
    ext_clk_pad_i=1'b0;

always #10
    ext_clk_pad_i=~ext_clk_pad_i;

//Reset

task reset;
begin

@(negedge PCLK)
PRESET=1'b1;

#10;

PRESET=1'b0;

end
endtask

//Initialize all to 0

task initialize;
begin

@(negedge PCLK)

PSEL=1'b0;
PWRITE=1'b0;
PENABLE=1'b0;
PADDR=32'h0;
PWDATA=32'h0;
aux_in=32'h0;

end
endtask

// Write AUX

task aux_write(input [31:0] in);
begin

@(negedge PCLK)

aux_in=in;

end
endtask

// Nrml Write

task apb_write(input [31:0] addr,
               input [31:0] in);

begin

@(negedge PCLK)
PADDR=addr;
PSEL=1'b1;
PWRITE=1'b1;
PENABLE=1'b0;
PWDATA=in;

@(negedge PCLK)
PADDR=addr;
PSEL=1'b1;
PWRITE=1'b1;
PENABLE=1'b1;
PWDATA=in;

@(negedge PCLK)
PADDR=addr;
PSEL=1'b1;
PWRITE=1'b1;
PENABLE=1'b0;
PWDATA=in;

@(negedge PCLK)
PADDR=addr;
PSEL=1'b0;
PWRITE=1'b0;
PENABLE=1'b0;
PWDATA=PWDATA;

end
endtask

//Read

task apb_read(input [31:0] addr);

begin

@(negedge PCLK)
PADDR   = addr;
PSEL    = 1'b1;
PWRITE  = 1'b0;
PENABLE = 1'b0;

@(negedge PCLK)
PADDR   = addr;
PSEL    = 1'b1;
PWRITE  = 1'b0;
PENABLE = 1'b1;

@(negedge PCLK)
PADDR   = addr;
PSEL    = 1'b1;
PWRITE  = 1'b0;
PENABLE = 1'b0;

@(negedge PCLK)
PADDR   = addr;
PSEL    = 1'b0;
PWRITE  = 1'b0;
PENABLE = 1'b0;

end
endtask


// io-dir

reg io_dir = 1'b1;      //used as input
reg [31:0] temp = 32'bz;

//io_pad inputs

task io_pad_input(input [31:0] in_temp);

begin

    io_dir = 1'b0;

    temp = in_temp;

end

endtask

//io_pad outputs

task io_pad_output;

begin

    io_dir = 1'b1;

end

endtask

assign io_pad = ~io_dir ? temp : 32'bz;    // driving iopad



initial
begin

initialize;

reset;

#10;

//general purpose as output

apb_write(`GPIO_RGPIO_INTE,32'h0);

apb_write(`GPIO_RGPIO_OUT,32'h56781234);

apb_write(`GPIO_RGPIO_OE,32'hffffffff);

io_pad_output;

//GPIO as Polled Input
//system clock


apb_write(`GPIO_RGPIO_OE,32'h0);          //I/O as Input

apb_write(`GPIO_RGPIO_CTRL,2'b00);        //Interrupt disabled

apb_write(`GPIO_RGPIO_INTE,32'b0);

apb_write(`GPIO_RGPIO_ECLK,32'h0);

io_pad_input(32'h12345678);

apb_read(`GPIO_RGPIO_IN);

//GPIO Aux input

aux_write(32'hf7f6f504);

apb_write(`GPIO_RGPIO_AUX,32'hffffffff);

apb_write(`GPIO_RGPIO_OE,32'hffffffff);

io_pad_output;

apb_write(`GPIO_RGPIO_AUX,32'h0);


//GPIO as bdir IO
//(system clock)

apb_write(`GPIO_RGPIO_INTE,32'h0);

apb_write(`GPIO_RGPIO_ECLK,32'h0);

apb_write(`GPIO_RGPIO_OUT,32'h10203040);     //output

apb_write(`GPIO_RGPIO_OE,32'hf0f0f0f0);

io_pad_input(32'hz5z1z0z9);                  //input

apb_read(`GPIO_RGPIO_IN);                   //value available in PRDATA


//GPIO as interrupt 
//(system clock)

io_pad_input(32'h0000ffff);

apb_write(`GPIO_RGPIO_OE,32'h0);            //I/O as Input

apb_write(`GPIO_RGPIO_CTRL,2'b01);          //Interrupt Mode

apb_write(`GPIO_RGPIO_INTE,32'hffffffff);   //enable interrupts

apb_write(`GPIO_RGPIO_PTRIG,32'hffff0000);  //positive edge trigger

apb_write(`GPIO_RGPIO_INTS,32'h0);          //clear interrupt status

apb_write(`GPIO_RGPIO_ECLK,32'h0);          //external clock disabled

io_pad_input(32'h87654321);

apb_read(`GPIO_RGPIO_INTS);                 //interrupt status

wait(IRQ);                                  //if interrupt generated

apb_read(`GPIO_RGPIO_IN);                   //value available in PRDATA

apb_write(`GPIO_RGPIO_INTS,32'h0);          //clear interrupt status


//GPIO as polled interupt (external clock)

apb_write(`GPIO_RGPIO_OE,32'h0);          // I/O as Input
apb_write(`GPIO_RGPIO_CTRL,2'b00);        // Interrupt disabled
apb_write(`GPIO_RGPIO_INTE,32'b0);
apb_write(`GPIO_RGPIO_NEC,32'h00000f0f);
apb_write(`GPIO_RGPIO_ECLK,32'h0000ffff);
io_pad_input(32'h12345678);
apb_read(`GPIO_RGPIO_IN);                 // value available in PRDATA


//GPIO nrml interrupt
//(external clock)

apb_write(`GPIO_RGPIO_OE,32'h0);                // I/O as Input
apb_write(`GPIO_RGPIO_INTE,32'hffffffff);       // set to enable generation of interrupts
apb_write(`GPIO_RGPIO_PTRIG,32'hffff0000);      // set to generate an interrupt on positive edge event
apb_write(`GPIO_RGPIO_INTS,32'h0);              // clear interrupt status register
apb_write(`GPIO_RGPIO_CTRL,2'b01);              // Interrupt Mode
apb_write(`GPIO_RGPIO_NEC,32'h00000f0f);
apb_write(`GPIO_RGPIO_ECLK,32'h0000ffff);       // external clock

io_pad_input(32'h87654321);

apb_read(`GPIO_RGPIO_INTS);                     // interrupt status

wait(IRQ);                                      // if interrupt generate read RGPIO_in

apb_read(`GPIO_RGPIO_IN);                       // value available in PRDATA

apb_write(`GPIO_RGPIO_INTS,32'h0);              // clear interrupt status register

apb_write(`GPIO_RGPIO_CTRL,2'b00);              // Interrupt Mode disabled

io_pad_output;


//GPIO as bidir
//(external clock)

apb_write(`GPIO_RGPIO_INTE,32'h0);

apb_write(`GPIO_RGPIO_OUT,32'h10203040);        // output

apb_write(`GPIO_RGPIO_OE,32'hf0f0f0f0);

apb_write(`GPIO_RGPIO_NEC,32'h0f0f0f0f);

apb_write(`GPIO_RGPIO_ECLK,32'h0f0f0f0f);

io_pad_output;

io_pad_input(32'hz4z5z6z7);                     // input

apb_read(`GPIO_RGPIO_IN);                       // value available in PRDATA


#500 $finish();

end

endmodule