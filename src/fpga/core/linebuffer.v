module linebuffer (
    input wire clk_vid,

    input wire vsync_in,
    input wire hsync_in,

    input wire ce_pix,
    input wire disable_pix,
    input wire [23:0] rgb_in,

    output wire vsync_out,
    output wire hsync_out,

    output reg de,
    output reg [23:0] rgb_out
);

  // If 0, outputting bank 0, writing bank 1
  // If 1, outputting bank 1, writing bank 0
  reg output_bank_select = 0;

  reg bank_read_ack;
  reg bank_write;

  wire [23:0] bank0_q;
  wire [23:0] bank1_q;

  wire [9:0] bank0_used;
  wire [9:0] bank1_used;

  wire bank0_empty;
  wire bank1_empty;

  linebuffer_bank bank0 (
      .clk(clk_vid),

      .data(rgb_in),
      .read_ack(bank_read_ack && ~output_bank_select),
      .write_req(bank_write && output_bank_select),

      .q(bank0_q),
      .empty(bank0_empty),
      .used(bank0_used)
  );

  linebuffer_bank bank1 (
      .clk(clk_vid),

      .data(rgb_in),
      .read_ack(bank_read_ack && output_bank_select),
      .write_req(bank_write && ~output_bank_select),

      .q(bank1_q),
      .empty(bank1_empty),
      .used(bank1_used)
  );

  wire bank_empty = output_bank_select ? bank1_empty : bank0_empty;
  wire [23:0] bank_q = output_bank_select ? bank1_q : bank0_q;
  wire [9:0] bank_line_width = ~output_bank_select ? bank1_used : bank0_used;

  // Incoming video data
  reg prev_hsync_in = 0;
  reg prev_vsync_in = 0;

  reg [9:0] output_line_width  /* synthesis noprune */;

  always @(posedge clk_vid) begin
    prev_hsync_in <= hsync_in;
    prev_vsync_in <= vsync_in;

    bank_write <= 0;

    if (hsync_in && ~prev_hsync_in) begin
      // Hsync, switch banks
      output_bank_select <= ~output_bank_select;

      // Latch width of new output bank
      output_line_width  <= bank_line_width;
    end

    if (ce_pix && ~disable_pix) begin
      bank_write <= 1;
    end
  end

  // Outgoing video data
  reg [3:0] hs_delay = 0;

  always @(posedge clk_vid) begin
    bank_read_ack <= 0;
    de <= 0;
    rgb_out <= 0;

    if (hs_delay > 0) begin
      hs_delay <= hs_delay - 1;
    end

    if (~prev_hsync_in && hsync_in) begin
      // HSync went high. Delay by 6 vid cycles to prevent overlapping with VSync
      hs_delay <= 15;
    end

    if (hs_delay == 0 && ~bank_empty) begin
      // Write out video data
      // TODO: Calculate centering
      bank_read_ack <= 1;
      de <= 1;

      rgb_out <= bank_q;
    end
  end

  // Hsync delayed by 6 cycles
  assign hsync_out = hs_delay == 15 - 6;
  assign vsync_out = vsync_in && ~prev_vsync_in;

endmodule

module linebuffer_bank (
    input wire clk,

    input wire [23:0] data,
    input wire read_ack,
    input wire write_req,

    output wire [23:0] q,
    output wire empty,
    output wire [9:0] used
);
  scfifo bank (
      .clock(clk),
      .data(data),
      .rdreq(read_ack),
      .wrreq(write_req),
      .empty(empty),
      // .full(sub_wire1),
      .q(q),
      .usedw(used)
  );
  defparam bank.add_ram_output_register = "ON", bank.intended_device_family = "Cyclone V",
      bank.lpm_numwords = 1024, bank.lpm_showahead = "ON", bank.lpm_type = "scfifo",
      bank.lpm_width = 24, bank.lpm_widthu = 10, bank.overflow_checking = "ON",
      bank.underflow_checking = "ON", bank.use_eab = "ON";

endmodule
