module pce (
    input wire clk_sys_42_95,
    input wire clk_mem_85_91,

    input wire reset_n,
    input wire pll_core_locked,

    // Input
    input wire button_a,
    input wire button_b,
    input wire button_select,
    input wire button_start,
    input wire dpad_up,
    input wire dpad_down,
    input wire dpad_left,
    input wire dpad_right,

    input wire sgx,

    // Settings
    input wire overscan_enable,
    input wire border_enable,
    input wire mb128_enable,

    output wire [1:0] dotclock_divider,

    // Data in
    input wire        ioctl_wr,
    input wire [23:0] ioctl_addr,
    input wire [15:0] ioctl_dout,
    input wire        cart_download,

    // Data out
    input wire [7:0] sd_buff_addr,
    input wire [16:0] sd_lba,
    input wire [15:0] sd_buff_dout,
    output wire [15:0] sd_buff_din,
    input wire save_loading,

    // SDRAM
    output wire [12:0] dram_a,
    output wire [ 1:0] dram_ba,
    inout  wire [15:0] dram_dq,
    output wire [ 1:0] dram_dqm,
    output wire        dram_clk,
    output wire        dram_cke,
    output wire        dram_ras_n,
    output wire        dram_cas_n,
    output wire        dram_we_n,

    // Video
    output wire hsync,
    output wire vsync,
    output wire hblank,
    output wire vblank,
    output wire [7:0] video_r,
    output wire [7:0] video_g,
    output wire [7:0] video_b,

    // Audio
    output wire [15:0] audio_l,
    output wire [15:0] audio_r
);

  wire                                    [63:0] status = 0;

  wire code_download = 0;

  // wire img_mounted = 0;
  // wire img_readonly = 0;
  // wire sd_ack = 0;
  // reg                                                              sd_rd = 0;
  // reg                                                              sd_wr = 0;
  // reg                                   [31:0]                     sd_lba = 0;

  wire VDC_BG_EN = 1;
  wire VDC_SPR_EN = 1;
  wire                                    [ 1:0] VDC_GRID_EN = 2'd0;
  wire CPU_PAUSE_EN = 0;

  wire reset = (~reset_n | save_loading);

  // wire code_index      = &ioctl_index;
  // wire code_download   = ioctl_download & code_index;
  // wire cart_download   = ioctl_download & (ioctl_index[5:0] <= 6'h01);
  // wire cd_dat_download = ioctl_download & (ioctl_index[5:0] == 6'h02);

  wire overscan = ~status[17];

  wire                                    [95:0]                     cd_comm;
  wire                                                               cd_comm_send;
  reg                                     [15:0]                     cd_stat;
  reg                                                                cd_stat_rec;
  reg                                                                cd_dataout_req;
  wire                                    [79:0]                     cd_dataout;
  wire                                                               cd_dataout_send;
  wire                                                               cd_reset_req;
  reg                                                                cd_region;

  wire                                    [21:0]                     cd_ram_a;
  wire cd_ram_rd, cd_ram_wr;
  wire [7:0] cd_ram_do;

  wire       ce_rom;

  wire [15:0] cdda_sl, cdda_sr, adpcm_s, psg_sl, psg_sr;

  pce_top #(LITE) pce_top (
      .RESET(reset | cart_download),
      .COLD_RESET(cart_download),

      .CLK(clk_sys_42_95),

      .ROM_RD(rom_rd),
      .ROM_RDY(rom_sdrdy),
      // .ROM_RDY(~rom_sdbusy),
      .ROM_A(rom_rdaddr),
      .ROM_DO(rom_sdata),
      .ROM_SZ(romwr_a[23:12]),
      .ROM_POP(populous[romwr_a[9]]),
      .ROM_CLKEN(ce_rom),

      .BRM_A (bram_addr),
      .BRM_DO(bram_q),
      .BRM_DI(bram_data),
      .BRM_WE(bram_wr),

      .GG_EN(status[5]),
      .GG_CODE(gg_code),
      .GG_RESET((cart_download | code_download) & ioctl_wr & !ioctl_addr),
      .GG_AVAIL(gg_avail),

      .SP64(status[11]),
      .SGX (sgx && !LITE),

      .JOY_OUT(joy_out),
      .JOY_IN (joy_in),

      .CD_EN(cd_en),
      .AC_EN(status[14]),

      // .CD_RAM_A (cd_ram_a),
      // .CD_RAM_DO(cd_ram_do),
      // .CD_RAM_DI(rom_sdata),
      // .CD_RAM_RD(cd_ram_rd),
      // .CD_RAM_WR(cd_ram_wr),

      // .CD_STAT(cd_stat[7:0]),
      // .CD_MSG(cd_stat[15:8]),
      // .CD_STAT_GET(cd_stat_rec),

      // .CD_COMM(cd_comm),
      // .CD_COMM_SEND(cd_comm_send),

      // .CD_DOUT_REQ(cd_dataout_req),
      // .CD_DOUT(cd_dataout),
      // .CD_DOUT_SEND(cd_dataout_send),

      // .CD_REGION(cd_region),
      // .CD_RESET (cd_reset_req),

      // .CD_DATA(!cd_dat_byte ? cd_dat[7:0] : cd_dat[15:8]),
      // .CD_WR(cd_wr),
      // .CD_DATA_END(cd_dat_req),
      // .CD_DM(cd_dm),

      .CDDA_SL(cdda_sl),
      .CDDA_SR(cdda_sr),
      .ADPCM_S(adpcm_s),
      .PSG_SL (psg_sl),
      .PSG_SR (psg_sr),

      .BG_EN(VDC_BG_EN),
      .SPR_EN(VDC_SPR_EN),
      .GRID_EN(VDC_GRID_EN),
      .CPU_PAUSE_EN(CPU_PAUSE_EN),

      .ReducedVBL(~overscan_enable),
      .BORDER_EN(border_enable),
      .DOTCLOCK_DIVIDER(dotclock_divider),
      .VIDEO_R(r),
      .VIDEO_G(g),
      .VIDEO_B(b),
      .VIDEO_BW(bw),
      //.VIDEO_CE(ce_vid),
      .VIDEO_CE_FS(ce_vid),
      .VIDEO_VS(vs),
      .VIDEO_HS(hs),
      .VIDEO_HBL(hbl),
      .VIDEO_VBL(vbl)
  );

  // CD communication

  // wire  [35:0] EXT_BUS;
  // reg  [112:0] cd_in = 0;
  // wire [112:0] cd_out;
  // hps_ext hps_ext
  // (
  // 	.clk_sys(clk_sys),
  // 	.EXT_BUS(EXT_BUS),
  // 	.cd_in(cd_in),
  // 	.cd_out(cd_out)
  // );

  reg        cd_en = 0;
  // always @(posedge clk_sys) begin
  // 	if(img_mounted && img_size) cd_en <= 1;
  // 	if(cart_download) cd_en <= 0;
  // end

  // reg        cd_dat_req;
  // always @(posedge clk_sys) begin
  // 	reg cd_out112_last = 1;
  // 	reg cd_comm_send_old = 0, cd_dataout_send_old = 0, cd_dat_req_old = 0, cd_reset_req_old = 0;

  // 	cd_stat_rec <= 0;
  // 	cd_dataout_req <= 0;
  // 	if (reset || cart_download) begin
  // 		cd_region <= 0;
  // 	end
  // 	else begin
  // 		if (cd_out[112] != cd_out112_last) begin
  // 			cd_out112_last <= cd_out[112];

  // 			cd_stat <= cd_out[15:0];
  // 			cd_stat_rec <= ~cd_out[16];
  // 			cd_dataout_req <= cd_out[16];
  // 			cd_region <= cd_out[17];
  // 		end

  // 		cd_comm_send_old <= cd_comm_send;
  // 		cd_dataout_send_old <= cd_dataout_send;
  // 		cd_dat_req_old <= cd_dat_req;
  // 		cd_reset_req_old <= cd_reset_req;
  // 		if (cd_comm_send && !cd_comm_send_old) begin
  // 			cd_in[95:0] <= cd_comm;
  // 			cd_in[111:96] <= {status[1],15'd0};
  // 			cd_in[112] <= ~cd_in[112];
  // 		end
  // 		else if (cd_dataout_send && !cd_dataout_send_old) begin
  // 			cd_in[79:0] <= cd_dataout;
  // 			cd_in[111:96] <= 16'h0001;
  // 			cd_in[112] <= ~cd_in[112];
  // 		end
  // 		else if (cd_dat_req && !cd_dat_req_old) begin
  // 			cd_in[111:96] <= 16'h0002;
  // 			cd_in[112] <= ~cd_in[112];
  // 		end
  // 		else if (cd_reset_req && !cd_reset_req_old) begin
  // 			cd_in[111:96] <= 16'h00FF;
  // 			cd_in[112] <= ~cd_in[112];
  // 		end
  // 	end
  // end

  reg [15:0] cd_dat = 0;
  reg        cd_wr = 0;
  reg        cd_dat_byte = 0;
  reg        cd_dm = 0;
  // always @(posedge clk_sys) begin
  // 	reg old_download;
  // 	reg head_pos, cd_dat_write;
  // 	reg [14:0] cd_dat_len, cd_dat_cnt;

  // 	old_download <= cd_dat_download;
  // 	if ((~old_download && cd_dat_download) || reset) begin
  // 		head_pos <= 0;
  // 		cd_dat_len <= 0;
  // 		cd_dat_cnt <= 0;
  // 	end
  // 	else if (ioctl_wr && cd_dat_download) begin
  // 		if (!head_pos) begin
  // 			{cd_dm,cd_dat_len} <= ioctl_dout;
  // 			cd_dat_cnt <= 0;
  // 			head_pos <= 1;
  // 		end
  // 		else if (cd_dat_cnt < cd_dat_len) begin
  // 			cd_dat_write <= 1;
  // 			cd_dat_byte <= 0;
  // 			cd_dat <= ioctl_dout;
  // 		end
  // 	end

  // 	if (cd_dat_write) begin
  // 		if (!cd_wr) begin
  // 			cd_wr <= 1;
  // 		end
  // 		else begin
  // 			cd_wr <= 0;
  // 			cd_dat_byte <= ~cd_dat_byte;
  // 			cd_dat_cnt <= cd_dat_cnt + 15'd1;
  // 			if (cd_dat_byte || cd_dat_cnt >= cd_dat_len-1) begin
  // 				cd_dat_write <= 0;
  // 			end
  // 		end
  // 	end
  // end

  ////////////////////////////  VIDEO  ///////////////////////////////////

  wire [2:0] r, g, b;
  wire hs, vs;
  wire hbl, vbl;
  wire bw;

  wire ce_vid;

  reg  ce_pix;
  always @(posedge clk_mem_85_91) begin
    reg old_ce;

    old_ce <= ce_vid;
    ce_pix <= ~old_ce & ce_vid;
  end

  logic [23:0] pal_color;

  dpram #(
      .addr_width(9),
      .data_width(24),
      .mem_init_file("palette.mif")
  ) palette_ram (
      .clock(clk_mem_85_91),

      .address_a({g, r, b}),
      .q_a(pal_color)
  );

  logic [7:0] r1, b1, g1;

  assign {r1, g1, b1} = status[28] ? {{r, r, r[2:1]}, {g, g, g[2:1]}, {b, b, b[2:1]}} : pal_color;

  color_mix color_mix (
      .clk_vid(clk_mem_85_91),
      .ce_pix(ce_pix),
      .mix(bw ? 3'd5 : 0),

      .R_in(r1),
      .G_in(g1),
      .B_in(b1),
      .HSync_in(hs),
      .VSync_in(vs),
      .HBlank_in(hbl),
      .VBlank_in(vbl),

      .R_out(video_r),
      .G_out(video_g),
      .B_out(video_b),
      .HSync_out(hsync),
      .VSync_out(vsync),
      .HBlank_out(hblank),
      .VBlank_out(vblank)
  );

  ////////////////////////////  AUDIO  ///////////////////////////////////

  pce_audio pce_audio (
      .clk_sys_42_95(clk_sys_42_95),

      .cdda_sl(cdda_sl),
      .cdda_sr(cdda_sr),
      .adpcm_s(adpcm_s),
      .psg_sl (psg_sl),
      .psg_sr (psg_sr),

      .audio_l(audio_l),
      .audio_r(audio_r)
  );

  ////////////////////////////  MEMORY  //////////////////////////////////

  localparam LITE = 1;

  wire [21:0] rom_rdaddr;
  wire [ 7:0] rom_sdata;
  wire rom_rd, rom_sdrdy;

  // wire [23:0] sdram_addr = ioctl_wr ? romwr_a : 
  //                          cd_ram_wr ? {2'b01, cd_ram_a} :
  //                          sdram_rom_rd ? {2'b00, (rom_rdaddr + (romwr_a[9] ? 22'h200 : 22'h0))} : {2'b01, cd_ram_a};

  // reg prev_rom_rd = 0;
  // reg prev_sdram_rom_rd_high = 0;
  // wire sdram_rom_rd_main = rom_rd != prev_rom_rd;
  // wire sdram_rom_rd = sdram_rom_rd_main || prev_sdram_rom_rd_high;

  // always @(posedge clk_mem_85_91) begin
  //   prev_rom_rd <= rom_rd;

  //   // Extend pulse by one cycle
  //   prev_sdram_rom_rd_high <= sdram_rom_rd_main;
  // end

  sdram sdram (
      .init(~pll_core_locked),
      .clk(clk_mem_85_91),
      .clkref(ce_rom),

      // .addr(sdram_addr),
      // .rd  (sdram_rom_rd),
      // .wr  (ioctl_wr),
      // .word(1),
      // .din (cart_download ? romwr_d : {cd_ram_do, cd_ram_do}),
      // .dout(rom_sdata),
      // .busy(rom_sdbusy),

      .waddr(cart_download ? romwr_a : {3'b001, cd_ram_a}),
      .din(cart_download ? romwr_d : {cd_ram_do, cd_ram_do}),
      .we(~cart_download & cd_ram_wr & ce_rom),
      .we_req(rom_wr),
      // .we_ack(sd_wrack),

      .raddr(rom_rd ? {3'b000, (rom_rdaddr + (romwr_a[9] ? 22'h200 : 22'h0))} : {3'b001, cd_ram_a}),
      .rd((rom_rd | cd_ram_rd) & ce_rom),
      .rd_rdy(rom_sdrdy),
      .dout(rom_sdata),

      // Actual SDRAM interface
      .SDRAM_DQ(dram_dq),
      .SDRAM_A(dram_a),
      .SDRAM_DQML(dram_dqm[0]),
      .SDRAM_DQMH(dram_dqm[1]),
      .SDRAM_BA(dram_ba),
      //   .SDRAM_nCS(),
      .SDRAM_nWE(dram_we_n),
      .SDRAM_nRAS(dram_ras_n),
      .SDRAM_nCAS(dram_cas_n),
      .SDRAM_CLK(dram_clk),
      .SDRAM_CKE(dram_cke)
  );


  wire romwr_ack;
  reg [23:0] romwr_a;
  wire [15:0] romwr_d = status[3] ?
		{ ioctl_dout[8], ioctl_dout[9], ioctl_dout[10],ioctl_dout[11],ioctl_dout[12],ioctl_dout[13],ioctl_dout[14],ioctl_dout[15],
		  ioctl_dout[0], ioctl_dout[1], ioctl_dout[2], ioctl_dout[3], ioctl_dout[4], ioctl_dout[5], ioctl_dout[6], ioctl_dout[7] }
		: ioctl_dout;

  reg prev_ioctl_wr = 0;
  reg rom_wr = 0;
  wire sd_wrack;

  // Special support for the Populous ROM
  reg [1:0] populous;
  // reg sgx;
  always @(posedge clk_sys_42_95) begin
    reg old_download;

    old_download  <= cart_download;
    // old_reset <= reset;
    prev_ioctl_wr <= ioctl_wr;

    // if (~old_reset && reset) ioctl_wait <= 0;
    if (~old_download && cart_download) begin
      romwr_a  <= 0;
      populous <= 2'b11;
      // sgx <= ioctl_index[0];
    end else begin
      if (ioctl_wr && ~prev_ioctl_wr) begin
        // ioctl_wait <= 1;
        rom_wr <= ~rom_wr;
        // Hacks for Populous game
        if ((romwr_a[23:4] == 'h212) || (romwr_a[23:4] == 'h1f2)) begin
          case (romwr_a[3:0])
            6:  if (romwr_d != 'h4F50) populous[romwr_a[13]] <= 0;
            8:  if (romwr_d != 'h5550) populous[romwr_a[13]] <= 0;
            10: if (romwr_d != 'h4F4C) populous[romwr_a[13]] <= 0;
            12: if (romwr_d != 'h5355) populous[romwr_a[13]] <= 0;
          endcase
        end
      end  // else if (rom_wr == sd_wrack) begin
      else if (~ioctl_wr && prev_ioctl_wr) begin
        // Falling edge of ioctl_wr
        // ioctl_wait <= 0;
        romwr_a <= romwr_a + 24'd2;
      end
    end
  end

  ////////////////////////////  CODES  ///////////////////////////////////

  reg [128:0] gg_code;
  wire gg_avail;

  // Code layout:
  // {clock bit, code flags,     32'b address, 32'b compare, 32'b replace}
  //  128        127:96          95:64         63:32         31:0
  // Integer values are in BIG endian byte order, so it up to the loader
  // or generator of the code to re-arrange them correctly.

  // always_ff @(posedge clk_sys_42_95) begin
  //   gg_code[128] <= 1'b0;

  //   if (code_download & ioctl_wr) begin
  //     case (ioctl_addr[3:0])
  //       0:  gg_code[111:96] <= ioctl_dout;  // Flags Bottom Word
  //       2:  gg_code[127:112] <= ioctl_dout;  // Flags Top Word
  //       4:  gg_code[79:64] <= ioctl_dout;  // Address Bottom Word
  //       6:  gg_code[95:80] <= ioctl_dout;  // Address Top Word
  //       8:  gg_code[47:32] <= ioctl_dout;  // Compare Bottom Word
  //       10: gg_code[63:48] <= ioctl_dout;  // Compare top Word
  //       12: gg_code[15:0] <= ioctl_dout;  // Replace Bottom Word
  //       14: begin
  //         gg_code[31:16] <= ioctl_dout;  // Replace Top Word
  //         gg_code[128]   <= 1'b1;  // Clock it in
  //       end
  //     endcase
  //   end
  // end

  ////////////////////////////  INPUT  ///////////////////////////////////

  wire [11:0] joy_0 = {
    1'b0,
    1'b0,
    1'b0,
    1'b0,
    button_start,
    button_select,
    button_b,
    button_a,
    dpad_up,
    dpad_down,
    dpad_left,
    dpad_right
  };

  wire [11:0] joy_1 = 0;
  wire [11:0] joy_2 = 0;
  wire [11:0] joy_3 = 0;
  wire [11:0] joy_4 = 0;

  wire [15:0] joy_data;
  always_comb begin
    case (joy_port)
      0:
      joy_data = (status[27:26] == 2'b01) ? {mouse_data, mouse_data} :
						                            ~{4'hF, joy_0[11:8], joy_0[1], joy_0[2], joy_0[0], joy_0[3], joy_0[7:4]};

      1:
      joy_data = (status[27:26] == 2'b10) ? pachinko                 : ~{4'hF, joy_1[11:8], joy_1[1], joy_1[2], joy_1[0], joy_1[3], joy_1[7:4]};
      2: joy_data = ~{4'hF, joy_2[11:8], joy_2[1], joy_2[2], joy_2[0], joy_2[3], joy_2[7:4]};
      3: joy_data = ~{4'hF, joy_3[11:8], joy_3[1], joy_3[2], joy_3[0], joy_3[3], joy_3[7:4]};
      4: joy_data = ~{4'hF, joy_4[11:8], joy_4[1], joy_4[2], joy_4[0], joy_4[3], joy_4[7:4]};
      default: joy_data = 16'h0FFF;
    endcase
  end

  reg [6:0] pachinko = 0;
  // always @(posedge clk_sys_42_95) begin
  //   reg use_paddle = 0;
  //   reg old_pd = 0;

  //   old_pd <= pd_0[5];
  //   if (old_pd ^ pd_0[5]) use_paddle <= 1;
  //   if (reset | cart_download) use_paddle <= 0;

  //   if (use_paddle) begin
  //     // use only second half of paddle range
  //     // Spring centering paddles then can simulate pachinko's spring

  //     pachinko <= pd_0[6:0];
  //     if (pd_0 < 8'h83) pachinko <= 7'h3;
  //     else if (pd_0 > 8'hF4) pachinko <= 7'h74;
  //   end else begin
  //     pachinko <= 7'd0 - joy_a[14:8];
  //     if (joy_a[15:8] > 8'hFC || !joy_a[15]) pachinko <= 7'h3;
  //     else if (joy_a[15:8] < 8'h8B) pachinko <= 7'h74;
  //   end
  // end

  wire [7:0] mouse_data = 0;
  // assign mouse_data[3:0] = ~{ joy_0[7:6] | {ps2_mouse_ext[8], ps2_mouse_ext[9]} , ps2_mouse[0], ps2_mouse[1]};

  // always_comb begin
  //   case (mouse_cnt)
  //     0: mouse_data[7:4] = ms_x[7:4];
  //     1: mouse_data[7:4] = ms_x[3:0];
  //     2: mouse_data[7:4] = ms_y[7:4];
  //     3: mouse_data[7:4] = ms_y[3:0];
  //   endcase
  // end

  reg [3:0] joy_latch;
  reg [2:0] joy_port;
  reg [1:0] mouse_cnt;
  reg [7:0] ms_x, ms_y;

  always @(posedge clk_sys_42_95) begin : input_block
    reg [ 1:0] last_gp;
    reg        high_buttons;
    reg [14:0] mouse_to;
    reg        ms_stb;
    reg [7:0] msr_x, msr_y;

    joy_latch <= joy_data[{high_buttons, joy_out[0], 2'b00}+:4];

    last_gp   <= joy_out;

    if (joy_out[1]) mouse_to <= 0;
    else if (~&mouse_to) mouse_to <= mouse_to + 1'd1;

    if (&mouse_to) mouse_cnt <= 3;
    if (~last_gp[1] & joy_out[1]) begin
      mouse_cnt <= mouse_cnt + 1'd1;
      if (&mouse_cnt) begin
        ms_x  <= msr_x;
        ms_y  <= msr_y;
        msr_x <= 0;
        msr_y <= 0;
      end
    end

    // ms_stb <= ps2_mouse[24];
    // if (ms_stb ^ ps2_mouse[24]) begin
    //   msr_x <= 8'd0 - ps2_mouse[15:8];
    //   msr_y <= ps2_mouse[23:16];
    // end

    if (joy_out[1]) begin
      joy_port <= 0;
      if (status[27:26] != 2'b11) begin
        joy_latch <= 0;
        if (~last_gp[1]) high_buttons <= ~high_buttons && status[4];
      end
    end
	else if (joy_out[0] && ~last_gp[0] && (status[2] | status[27]) && (status[27:26] != 2'b11)) begin	// suppress if XE-1AP
      joy_port <= joy_port + 3'd1;
    end
  end

  wire [1:0] joy_out;
  wire [3:0] joy_in = (mb128_ena & mb128_Active) ? mb128_Data : joy_latch;

  /////////////////////////  BACKUP RAM SAVE/LOAD  /////////////////////////////

  wire [15:0] mb128_dout;
  // wire mb128_dirty;
  wire mb128_ena = mb128_enable;
  wire mb128_Active;
  wire [3:0] mb128_Data;

  // MB128 MB128 (
  //     .reset  (reset | cart_download),
  //     .clk_sys(clk_sys_42_95),

  //     .i_Clk (mb128_ena & joy_out[1]),  // send only if MB128 enabled
  //     .i_Data(joy_out[0]),

  //     .o_Active(mb128_Active),  // high if MB128 asserts itself instead of joypad inputs
  //     .o_Data  (mb128_Data),

  //     .bk_clk(clk_sys_42_95),
  //     .bk_address({sd_lba[7:0] - 3'd4, sd_buff_addr}),
  //     .bk_din(sd_buff_dout),
  //     .bk_dout(mb128_dout),
  //     .bk_we(~bk_int & sd_buff_wr)
  //     // .bk_written(mb128_dirty)
  // );

  // reg bk_pending;

  // always @(posedge clk_sys_42_95) begin
  //   if (bk_ena && (bram_wr || mb128_dirty)) bk_pending <= 1'b1;
  //   else if (bk_state) bk_pending <= 1'b0;
  // end

  wire [10:0] bram_addr;
  wire [7:0] bram_data;
  wire [7:0] bram_q;
  wire bram_wr;

  // wire format = status[12];
  // reg [3:0] defbram = 4'hF;
  reg [15:0] defval[4] = '{16'h5548, 16'h4D42, 16'h8800, 16'h8010};  //{ HUBM,0x00881080 };

  wire bk_int = !sd_lba[15:2];
  wire [15:0] bk_int_dout;

  assign sd_buff_din = bk_int ? bk_int_dout : mb128_dout;

  dpram_difclk #(11, 8, 10, 16) backram (
      .clock0(clk_sys_42_95),
      .address_a(bram_addr),
      .data_a(bram_data),
      .wren_a(bram_wr),
      .q_a(bram_q),

      .clock1(clk_sys_42_95),
      // .address_b(defbram[3] ? {sd_lba[1:0], sd_buff_addr} : defbram[2:1]),
      // .data_b(defbram[3] ? sd_buff_dout : defval[defbram[2:1]]),
      // .wren_b(defbram[3] ? bk_int & sd_buff_wr & sd_ack : 1'b1),
      .address_b({sd_lba[1:0], sd_buff_addr}),
      .data_b(sd_buff_dout),
      .wren_b(bk_int & sd_buff_wr),

      .q_b(bk_int_dout)
  );

  wire downloading = cart_download;
  reg old_downloading = 0;

  // reg bk_ena = 0;
  // always @(posedge clk_sys_42_95) begin

  //   old_downloading <= downloading;
  //   if (~old_downloading & downloading) bk_ena <= 0;

  //   //Save file always mounted in the end of downloading state.
  //   if (downloading && img_mounted && !img_readonly) bk_ena <= 1;
  // end

  // wire bk_load    = status[16];
  // wire bk_save    = status[7] | (bk_pending && status[23]);
  // reg  bk_loading = 0;
  // reg  bk_state   = 0;

  // always @(posedge clk_sys_42_95) begin
  //   // reg old_format;
  //   reg old_load = 0, old_save = 0, old_ack;
  //   reg mb128sz;

  //   old_load <= bk_load;
  //   old_save <= bk_save;
  //   old_ack  <= sd_ack;

  //   if (~old_ack & sd_ack) {sd_rd, sd_wr} <= 0;

  //   if (!bk_state) begin
  //     if (bk_ena & ((~old_load & bk_load) | (~old_save & bk_save))) begin
  //       bk_state <= 1;
  //       bk_loading <= bk_load;
  //       mb128sz <= bk_load || (mb128_ena && mb128_dirty);
  //       sd_lba <= 0;
  //       sd_rd <= bk_load;
  //       sd_wr <= ~bk_load;
  //     end
  //     if (old_downloading & ~downloading & bk_ena) begin
  //       bk_state <= 1;
  //       bk_loading <= 1;
  //       mb128sz <= 1;
  //       sd_lba <= 0;
  //       sd_rd <= 1;
  //       sd_wr <= 0;
  //     end
  //   end else begin
  //     if (old_ack & ~sd_ack) begin
  //       if (sd_lba[8] == mb128sz && &sd_lba[1:0]) begin
  //         bk_loading <= 0;
  //         bk_state <= 0;
  //         sd_lba <= 0;
  //       end else begin
  //         sd_lba <= sd_lba + 1'd1;
  //         sd_rd  <= bk_loading;
  //         sd_wr  <= ~bk_loading;
  //       end
  //     end
  //   end

  //   // old_format <= format;
  //   // if (~old_format && format) begin
  //   //   defbram <= 0;
  //   // end
  //   // if (~defbram[3]) begin
  //   //   defbram <= defbram + 4'd1;
  //   // end
  // end

endmodule
