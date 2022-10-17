#
# user core constraints
#
# put your clock groups in here as well as any net assignments
#

set_clock_groups -asynchronous \
 -group { bridge_spiclk } \
 -group { clk_74a } \
 -group { clk_74b } \
 -group { ic|mp1|mf_pllbase_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk \
          ic|mp1|mf_pllbase_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk \
          ic|mp1|mf_pllbase_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk \
          ic|mp1|mf_pllbase_inst|altera_pll_i|general[4].gpll~PLL_OUTPUT_COUNTER|divclk } \
 -group { ic|mp1|mf_pllbase_inst|altera_pll_i|general[3].gpll~PLL_OUTPUT_COUNTER|divclk } \
 -group { ic|mp1|mf_pllbase_inst|altera_pll_i|general[5].gpll~PLL_OUTPUT_COUNTER|divclk }

set_multicycle_path -from {ic|pce|sdram|*} -to [get_clocks {*|mp1|mf_pllbase_inst|altera_pll_i|*[1].*|divclk}] -start -setup 2
set_multicycle_path -from {ic|pce|*} -to [get_clocks {*|mp1|mf_pllbase_inst|altera_pll_i|*[1].*|divclk}] -start -hold 1
set_multicycle_path -from {ic|pce|*} -to [get_clocks {*|mp1|mf_pllbase_inst|altera_pll_i|*[1].*|divclk}] -start -setup 2

set_multicycle_path -from {ic|pce|pce_audio|psg_filter|*} -setup 3
set_multicycle_path -from {ic|pce|pce_audio|psg_filter|*} -hold 2
set_multicycle_path -from {ic|pce|pce_audio|adpcm_filter|*} -setup 3
set_multicycle_path -from {ic|pce|pce_audio|adpcm_filter|*} -hold 2

set_false_path -from [get_clocks {*|mp1|mf_pllbase_inst|altera_pll_i|*[4].*|divclk}] -to [get_clocks {*|mp1|mf_pllbase_inst|altera_pll_i|*[2].*|divclk}]
set_false_path -from [get_clocks {*|mp1|mf_pllbase_inst|altera_pll_i|*[2].*|divclk}] -to [get_clocks {*|mp1|mf_pllbase_inst|altera_pll_i|*[4].*|divclk}]

set_multicycle_path -from {ic|pce|color_mix|*} -to {isco|*} -start -hold 1
set_multicycle_path -from {ic|pce|color_mix|*} -to {isco|*} -start -setup 2
set_multicycle_path -from {ic|pce|color_mix|*} -to {iscc|*} -start -hold 1
set_multicycle_path -from {ic|pce|color_mix|*} -to {iscc|*} -start -setup 2
