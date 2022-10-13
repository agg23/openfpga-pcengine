module pce_audio (
    input wire clk_sys_42_95,

    input wire [15:0] cdda_sl,
    input wire [15:0] cdda_sr,
    input wire [15:0] adpcm_s,
    input wire [15:0] psg_sl,
    input wire [15:0] psg_sr,

    output wire [15:0] audio_l,
    output wire [15:0] audio_r
);

  // TODO: Status
  wire [63:0] status = 0;

  wire PSG_EN = 1;
  wire CDDA_EN = 1;
  wire ADPCM_EN = 1;

  localparam [3:0] comp_f1 = 4;
  localparam [3:0] comp_a1 = 2;
  localparam       comp_x1 = ((32767 * (comp_f1 - 1)) / ((comp_f1 * comp_a1) - 1)) + 1; // +1 to make sure it won't overflow
  localparam comp_b1 = comp_x1 * comp_a1;

  localparam [3:0] comp_f2 = 8;
  localparam [3:0] comp_a2 = 4;
  localparam       comp_x2 = ((32767 * (comp_f2 - 1)) / ((comp_f2 * comp_a2) - 1)) + 1; // +1 to make sure it won't overflow
  localparam comp_b2 = comp_x2 * comp_a2;

  function [15:0] compr;
    input [15:0] inp;
    reg [15:0] v, v1, v2;
    begin
      v = inp[15] ? (~inp) + 1'd1 : inp;
      v1 = (v < comp_x1[15:0]) ? (v * comp_a1) : (((v - comp_x1[15:0]) / comp_f1) + comp_b1[15:0]);
      v2 = (v < comp_x2[15:0]) ? (v * comp_a2) : (((v - comp_x2[15:0]) / comp_f2) + comp_b2[15:0]);
      v = status[19] ? v2 : v1;
      compr = inp[15] ? ~(v - 1'd1) : v;
    end
  endfunction

  reg [17:0] audio_l_int, audio_r_int;
  reg [15:0] cmp_l, cmp_r;

  logic [4:0] div_audio;
  logic adpcm_ce, psg_ce;

  logic [15:0] adpcm_filt, psg_l_filt, psg_r_filt;

  always @(posedge clk_sys_42_95) begin
    // 2684650 and 1342323
    div_audio <= div_audio + 1'd1;

    adpcm_ce <= &div_audio[4:0];
    psg_ce <= &div_audio[3:0];
  end

  IIR_filter #(
      .coeff_x (0.00200339512841342642),
      .coeff_x0(2),
      .coeff_x1(1),
      .coeff_x2(0),
      .coeff_y0(-1.95511712863912712201),
      .coeff_y1(0.95667938324280066276),
      .coeff_y2(0),
      .stereo  (1)
  ) psg_filter (
      .clk      (clk_sys_42_95),
      .ce       (psg_ce),         // (1342323 * 2)
      .sample_ce(1),
      .input_l  (psg_sl),
      .input_r  (psg_sr),
      .output_l (psg_l_filt),
      .output_r (psg_r_filt)
  );

  IIR_filter #(
      .coeff_x (0.00002488367092441635),
      .coeff_x0(3),
      .coeff_x1(3),
      .coeff_x2(1),
      .coeff_y0(-2.94383188882174362533),
      .coeff_y1(2.88923013608993572987),
      .coeff_y2(-0.94537670406128904155),
      .stereo  (0)
  ) adpcm_filter (
      .clk      (clk_sys_42_95),
      .ce       (adpcm_ce),       // 1342323
      .sample_ce(1),
      .input_l  (adpcm_s),
      .output_l (adpcm_filt)
  );

  always @(posedge clk_sys_42_95) begin
    reg [17:0] pre_l, pre_r;
    reg signed [16:0] adpcm_boost;
    adpcm_boost <= $signed(
        {adpcm_filt[15], adpcm_filt}
    ) + $signed(
        (status[22] ? {{3{adpcm_filt[15]}}, adpcm_filt[15:2]} : 17'd0)
    );

    pre_l <= ( CDDA_EN                  ? {{2{cdda_sl[15]}},         cdda_sl} : 18'd0)
			 + ((CDDA_EN && status[20]) ? {{2{cdda_sl[15]}},         cdda_sl} : 18'd0)
			 + ( PSG_EN                 ? {{2{psg_l_filt[15]}},   psg_l_filt} : 18'd0)
			 + ( ADPCM_EN               ? {adpcm_boost[16],   adpcm_boost} : 18'd0);

    pre_r <= ( CDDA_EN                  ? {{2{cdda_sr[15]}},         cdda_sr} : 18'd0)
			 + ((CDDA_EN && status[20]) ? {{2{cdda_sr[15]}},         cdda_sr} : 18'd0)
			 + ( PSG_EN                 ? {{2{psg_r_filt[15]}},   psg_r_filt} : 18'd0)
			 + ( ADPCM_EN               ? {adpcm_boost[16],   adpcm_boost} : 18'd0);

    if (~status[20]) begin
      // 3/4 + 1/4 to cover the whole range.
      audio_l_int <= $signed(pre_l) + ($signed(pre_l) >>> 2);
      audio_r_int <= $signed(pre_r) + ($signed(pre_r) >>> 2);
    end else begin
      audio_l_int <= pre_l;
      audio_r_int <= pre_r;
    end

    cmp_l <= compr(audio_l_int[17:2]);
    cmp_r <= compr(audio_r_int[17:2]);
  end

  assign audio_l = status[19:18] > 0 ? cmp_l : audio_l_int[17:2];
  assign audio_r = status[19:18] > 0 ? cmp_r : audio_r_int[17:2];

endmodule
