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
  reg prev_disable_pix = 0;

  reg [9:0] output_line_width  /* synthesis noprune */;

  reg [3:0] enable_delay = 0;
  reg [3:0] border_delay = 0;

  always @(posedge clk_vid) begin
    prev_hsync_in <= hsync_in;
    prev_vsync_in <= vsync_in;
    prev_disable_pix <= disable_pix;

    bank_write <= 0;

    if (hsync_in && ~prev_hsync_in) begin
      // Hsync, switch banks
      output_bank_select <= ~output_bank_select;

      // Latch width of new output bank
      output_line_width  <= bank_line_width;
    end

    // Handle the weird timing of borders
    if (~disable_pix && prev_disable_pix) begin
      // Falling edge of border
      enable_delay <= 3;
    end else if (disable_pix && ~prev_disable_pix) begin
      // Rising edge of border
      border_delay <= 4;
    end else if (ce_pix) begin
      if (border_delay > 0) begin
        border_delay <= border_delay - 1;
      end

      if (~disable_pix || border_delay > 0) begin
        if (enable_delay > 0) begin
          enable_delay <= enable_delay - 1;
        end else begin
          // Delay finished, draw pixel
          bank_write <= 1;
        end
      end
    end
  end

  // Outgoing video data
  reg prev_de = 0;

  reg [3:0] hs_delay = 0;
  reg [8:0] border_start_offset = 0;
  reg [8:0] border_end_offset = 0;
  reg line_started = 0;

  reg [9:0] expected_line_width;
  reg [3:0] slot;

  always @(*) begin
    if (output_line_width < 280) begin
      expected_line_width <= 10'd256;
      slot <= 0;
    end else if (output_line_width < 380) begin
      expected_line_width <= 10'd360;
      slot <= 2;
    end else begin
      expected_line_width <= 10'd512;
      slot <= 4;
    end
  end

  wire [9:0] width_diff = expected_line_width > output_line_width ? expected_line_width - output_line_width : 0  /* synthesis keep */;
  wire [8:0] calculated_border = width_diff[9:1]  /* synthesis keep */;

  wire [23:0] video_slot_rgb = {7'b0, slot, 10'b0, 3'b0};

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
      line_started <= 0;

      border_start_offset <= 0;
      border_end_offset <= 0;
    end

    if (calculated_border == 0 && hs_delay == 1) begin
      // If no border, set read ack high one pixel early
      bank_read_ack <= 1;
    end else if (hs_delay == 0 && ~bank_empty) begin
      // Write out video data
      // TODO: Calculate centering
      de <= 1;

      // Track whether we've written pixels
      line_started <= 1;

      if (border_start_offset < calculated_border) begin
        if (border_start_offset == calculated_border - 1) begin
          // Set high one pixel early
          bank_read_ack <= 1;
        end
        border_start_offset <= border_start_offset + 1;

        rgb_out <= 0;
      end else begin
        bank_read_ack <= 1;

        rgb_out <= bank_q;
      end
    end else if (line_started && bank_empty && border_end_offset < calculated_border) begin
      // We've exhausted the line buffer, write black until we're done
      border_end_offset <= border_end_offset + 1;

      de <= 1;
      rgb_out <= 0;
    end else if (prev_de) begin
      // Falling edge of de
      rgb_out <= video_slot_rgb;
    end

    prev_de <= de;
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
