// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module user_proj_example #(
    parameter BITS = 32
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] irq
);
    wire clock;
    wire reset;

    wire [`MPRJ_IO_PADS-1:0] io_in;
    wire [`MPRJ_IO_PADS-1:0] io_out;
    wire [`MPRJ_IO_PADS-1:0] io_oeb;

    wire sequence_in;
    wire detector_out;
    wire [28:0]in1;
    wire [2:0]in2;

    assign io_oeb = 0;
    assign {in1, clock, sequence_in, in2, reset} = io_in[`MPRJ_IO_PADS-2:0];
    assign io_out[37] = detector_out;

    Sequence_Detector_MOORE_Verilog uut(sequence_in,clock,reset,detector_out);
endmodule

module Sequence_Detector_MOORE_Verilog(sequence_in,clock,reset,detector_out);
input clock; 			// clock signal
input reset; 			// reset input
input sequence_in; 		// binary input
output reg detector_out; 		// output of the sequence detector
parameter
	Zero = 3'b000, 						// "Zero" State
  	One = 3'b001, 						// "One" State
  	OneOne = 3'b011, 					// "OneOne" State
  	OneOneOne = 3'b010, 				// "OneOneOne" State
  	OneOneOneOne = 3'b110;				// "OneOneOneOne" State
reg [2:0] current_state, next_state; 	// current state and next state
// sequential memory of the Moore FSM
always @(posedge clock, posedge reset)
begin
 	if(reset==1) 
 		current_state <= Zero;			// when reset=1, reset the state of the FSM to "Zero" State
 	else
 		current_state <= next_state; 	// otherwise, next state
end

// combinational logic of the Moore FSM
// to determine next state 
always @(current_state,sequence_in)
begin
 	case(current_state) 
 	Zero:begin
 	 	if(sequence_in == 1)
 	 	 	next_state = One;
 	 	else
 	 	 	next_state = Zero;
 	end
 	One:begin
 	 	if(sequence_in == 1)
 	 	 	next_state = OneOne;
 	 	else
 	 	 	next_state = Zero;
 	end
 	OneOne:begin
 	 	if(sequence_in == 1)
 	 	 	next_state = OneOneOne;
 	 	else
 	 	 	next_state = Zero;
 	end 
 	OneOneOne:begin
 	 	if(sequence_in == 1)
 	 	 	next_state = OneOneOneOne;
 	 	else
 	 	 	next_state = Zero;
 	end
 	OneOneOneOne:begin
 	 	if(sequence_in == 0)
 	 	 	next_state = Zero;
 	 	else
 	 	 	next_state = OneOneOneOne;
 	end
 	default:next_state = Zero;
 	endcase
end
// combinational logic to determine the output
// of the Moore FSM, output only depends on current state
always @(current_state)
begin 
 case(current_state) 
 Zero:   detector_out = 0;
 One:   detector_out = 0;
 OneOne:  detector_out = 0;
 OneOneOne:  detector_out = 0;
 OneOneOneOne:  detector_out = 1;
 default:  detector_out = 0;
 endcase
end 
endmodule
`default_nettype wire
