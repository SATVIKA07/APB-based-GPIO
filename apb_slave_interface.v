module apb_slave_interface(
    input  [31:0] PADDR,
    input  [31:0] PWDATA,
    input         PCLK,
    input         PSEL,
    input         PENABLE,
    input         PWRITE,
    input         PRESET,

    output reg [31:0] PRDATA,
    output            PREADY,

    input             gpio_inta_o,

    output            IRQ,
    output reg        gpio_we,

    output [31:0]     gpio_adr,
    output reg [31:0] gpio_dat_i,

    input  [31:0]     gpio_dat_o,

    output            sys_clk,
    output            sys_rst
);

parameter IDLE   = 2'b00,
          SETUP  = 2'b01,
          ENABLE = 2'b10;

reg [1:0] STATE, NEXT_STATE;

always @(posedge PCLK or posedge PRESET)
begin
    if (PRESET)
        STATE <= IDLE;
    else
        STATE <= NEXT_STATE;
end

always @(*)
begin
    case (STATE)

        IDLE:
        begin
            if (PSEL && !PENABLE)
                NEXT_STATE = SETUP;
            else
                NEXT_STATE = IDLE;
        end

        SETUP:
        begin
            if (PSEL && PENABLE)
                NEXT_STATE = ENABLE;

            else if (PSEL && !PENABLE)
                NEXT_STATE = SETUP;

            else
                NEXT_STATE = IDLE;
        end

        ENABLE:
        begin
            if (PSEL)
                NEXT_STATE = SETUP;
            else
                NEXT_STATE = IDLE;
        end

        default:
            NEXT_STATE = IDLE;

    endcase
end

assign PREADY = (STATE == ENABLE) ||
                ((STATE == IDLE) && PRESET) ? 1'b1 : 1'b0;

always @(*)
begin

    if (PWRITE && STATE == ENABLE)
    begin
        gpio_dat_i = PWDATA;
        gpio_we    = 1'b1;
        PRDATA     = 32'b0;
    end

    else if (!PWRITE && STATE == ENABLE)
    begin
        PRDATA     = gpio_dat_o;
        gpio_we    = 1'b0;
        gpio_dat_i = 32'b0;
    end

    else
    begin
        gpio_dat_i = 32'b0;
        gpio_we    = 1'b0;
        PRDATA     = 32'b0;
    end

end

assign IRQ      = gpio_inta_o;
assign sys_clk  = PCLK;
assign sys_rst  = PRESET;
assign gpio_adr = PADDR;

endmodule



module tb_apb_slave_interface;

reg [31:0] PADDR;
reg [31:0] PWDATA;
reg PCLK;
reg PSEL;
reg PENABLE;
reg PWRITE;
reg PRESET;
reg gpio_inta_o;
reg [31:0] gpio_dat_o;

wire [31:0] PRDATA;
wire PREADY;
wire IRQ;
wire gpio_we;
wire [31:0] gpio_adr;
wire [31:0] gpio_dat_i;
wire sys_clk;
wire sys_rst;

apb_slave_interface DUT(
.PADDR(PADDR),
.PWDATA(PWDATA),
.PCLK(PCLK),
.PSEL(PSEL),
.PENABLE(PENABLE),
.PWRITE(PWRITE),
.PRESET(PRESET),
.PRDATA(PRDATA),
.PREADY(PREADY),
.gpio_inta_o(gpio_inta_o),
.IRQ(IRQ),
.gpio_we(gpio_we),
.gpio_adr(gpio_adr),
.gpio_dat_i(gpio_dat_i),
.gpio_dat_o(gpio_dat_o),
.sys_clk(sys_clk),
.sys_rst(sys_rst)
);

always #5 PCLK=~PCLK;

initial
begin

PCLK=0;
PADDR=0;
PWDATA=0;
PSEL=0;
PENABLE=0;
PWRITE=0;
PRESET=1;
gpio_inta_o=0;
gpio_dat_o=0;

#10;
PRESET=0;

#10;

PADDR=32'h00000010;
PWDATA=32'hA5A5A5A5;
PWRITE=1;
PSEL=1;
PENABLE=0;

#10;

PENABLE=1;

#10;

PSEL=0;
PENABLE=0;
PWRITE=0;

#20;

gpio_dat_o=32'h12345678;
PADDR=32'h00000020;
PWRITE=0;
PSEL=1;
PENABLE=0;

#10;

PENABLE=1;

#10;

PSEL=0;
PENABLE=0;

#20;

gpio_inta_o=1;

#10;

gpio_inta_o=0;

#20;

$finish;

end

initial
begin
$monitor("TIME=%0t PRESET=%b PSEL=%b PENABLE=%b PWRITE=%b PADDR=%h PWDATA=%h PRDATA=%h gpio_we=%b gpio_dat_i=%h PREADY=%b IRQ=%b",
$time,PRESET,PSEL,PENABLE,PWRITE,PADDR,PWDATA,PRDATA,gpio_we,gpio_dat_i,PREADY,IRQ);
end

endmodule