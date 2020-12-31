//this module contains the top level for the electric drum set utilizing the arduino analog inputs
module ElectricDrums(
      input logic MAX10_CLK1_50,
      output logic [9:0] LEDR,
      output logic [7:0] HEX0,
      output logic [7:0] HEX1,
      output logic [7:0] HEX2
);

parameter [11:0] min_hit = 100;
parameter [11:0] min_foot = 1024;

logic reset_n;
logic sys_clk;

assign reset_n = 1'b1;

adc_qsys u0 (
	.clk_clk                              (MAX10_CLK1_50),                              //                    clk.clk
	.reset_reset_n                        (reset_n),                        //                  reset.reset_n
	.modular_adc_0_command_valid          (command_valid),          //  modular_adc_0_command.valid
	.modular_adc_0_command_channel        (command_channel),        //                       .channel
	.modular_adc_0_command_startofpacket  (command_startofpacket),  //                       .startofpacket
	.modular_adc_0_command_endofpacket    (command_endofpacket),    //                       .endofpacket
	.modular_adc_0_command_ready          (command_ready),          //                       .ready
	.modular_adc_0_response_valid         (response_valid),         // modular_adc_0_response.valid
	.modular_adc_0_response_channel       (response_channel),       //                       .channel
	.modular_adc_0_response_data          (response_data),          //                       .data
	.modular_adc_0_response_startofpacket (response_startofpacket), //                       .startofpacket
	.modular_adc_0_response_endofpacket   (response_endofpacket),    //                       .endofpacket
	.clock_bridge_sys_out_clk_clk         (sys_clk)          // clock_bridge_sys_out_clk.clk
);

// command
logic  command_valid;
logic  [4:0] command_channel;
logic  command_startofpacket;
logic  command_endofpacket;
logic command_ready;

// continused send command
assign command_startofpacket = 1'b1; // // ignore in altera_adc_control core
assign command_endofpacket = 1'b1; // ignore in altera_adc_control core
assign command_valid = 1'b1; // 
assign command_channel = 1+channel; // SW2/SW1/SW0 down: map to arduino ADC_IN0

// response
logic response_valid/* synthesis keep */;
logic [4:0] response_channel;
logic [11:0] response_data;
logic response_startofpacket;
logic response_endofpacket;
logic [4:0]  cur_adc_ch /* synthesis noprune */;
logic [11:0] adc_sample_data /* synthesis noprune */;

// multiple path saves
logic [11:0] red, yellow, blue, green, foot;
logic [2:0] channel;

always @ (posedge sys_clk)
begin
	if (response_valid)
	begin
		if(response_channel == 1)
			red <= response_data;
		else if(response_channel == 2)
			yellow <= response_data;
		else if(response_channel == 3)
			blue <= response_data;
		else if(response_channel == 4)
			green <= response_data;
		else if(response_channel == 5)
			foot <= response_data;
		else
			adc_sample_data <= response_data;
			
		if(channel == 7)
			channel <= 0;
		else
			channel <= channel + 1;
	end
end

assign HEX2[7] = 1'b1; // low active
assign HEX1[7] = 1'b1; // low active
assign HEX0[7] = 1'b1; // low active

HexDriver driver2 (.In0(foot[11:8]), .Out0(HEX2[6:0]));
HexDriver driver1 (.In0(foot[7:4]), .Out0(HEX1[6:0]));
HexDriver driver0 (.In0(foot[3:0]), .Out0(HEX0[6:0]));

always_comb
begin
	if(red > min_hit)
		LEDR[9] = 1'b1;
	else
		LEDR[9] = 1'b0;
		
	if(yellow > min_hit)
		LEDR[8] = 1'b1;
	else
		LEDR[8] = 1'b0;
	
	if(blue > min_hit)
		LEDR[7] = 1'b1;
	else
		LEDR[7] = 1'b0;
	
	if(green > min_hit)
		LEDR[6] = 1'b1;
	else
		LEDR[6] = 1'b0;
	
	if(foot > min_foot)
		LEDR[5] = 1'b1;
	else
		LEDR[5] = 1'b0;
end

endmodule
