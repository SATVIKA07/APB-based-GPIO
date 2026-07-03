module gpio_core(
    input         PCLK, PRESET,
    output [31:0] PRDATA,
    input  [31:0] PADDR, PWDATA,
    input         PSEL, PENABLE, PWRITE,
    input  [31:0] aux_in,
    output        IRQ, PREADY,
    inout  [31:0] io_pad,
    input         ext_clk_pad_i
);

wire [31:0] in_pad_i;
wire         gpio_we;
wire [31:0]  gpio_adr;
wire [31:0]  gpio_dat_i;
wire [31:0]  gpio_dat_o;
wire [31:0]  out_pad_o, oen_padoe_o;
wire          gpio_inta_o;
wire          sys_clk, sys_rst;
wire [31:0]   aux_i;
wire           g1;

apb_slave_interface APB_INTERFACE(
    .PADDR(PADDR),
    .PWDATA(PWDATA),
    .PRESET(PRESET),
    .PSEL(PSEL),
    .PENABLE(PENABLE),
    .PWRITE(PWRITE),
    .PREADY(PREADY),
    .PRDATA(PRDATA),
    .IRQ(IRQ),
    .gpio_inta_o(gpio_inta_o),
    .gpio_we(gpio_we),
    .gpio_adr(gpio_adr),
    .gpio_dat_i(gpio_dat_i),
    .gpio_dat_o(gpio_dat_o),
    .PCLK(PCLK),
    .sys_clk(sys_clk),
    .sys_rst(sys_rst)
);

aux_interface AUX_INTERFACE(
    .clk(sys_clk),
    .rst(sys_rst),
    .aux_in(aux_in),
    .aux_i(aux_i)
);

gpio_register GPIO_REGISTER(
    .sys_clk(sys_clk),
    .sys_rst(sys_rst),
    .gpio_adr(gpio_adr),
    .gpio_we(gpio_we),
    .gpio_dat_i(gpio_dat_i),
    .gpio_dat_o(gpio_dat_o),
    .in_pad_i(in_pad_i),
    .out_pad_o(out_pad_o),
    .gpio_inta_o(gpio_inta_o),
    .oen_padoe_o(oen_padoe_o),
    .gpio_eclk(g1),
    .aux_i(aux_i)
);

io_interface IO_INTERFACE(
    .in_pad_i(in_pad_i),
    .out_pad_o(out_pad_o),
    .oen_padoe_o(oen_padoe_o),
    .io_pad(io_pad),
    .ext_clk_pad_i(ext_clk_pad_i),
    .gpio_eclk(g1)
);

endmodule