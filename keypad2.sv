module keypad2(input logic MAX10_CLK1_50, 
				  input logic[1:0] KEY,
				  inout wire [15:0] ARDUINO_IO,
				  output logic[7:0] HEX5,HEX4,HEX3,HEX2,HEX1,HEX0,
                                  output logic [2:0] present_state
				  );
				   
  logic clk;	 
  wire [3:0] col_wires;
  logic [3:0] col;
  wire [3:0] row_wires;
  logic [3:0] row, row_scan;
  logic [3:0] key_code, key_code_latched;
  logic reset, valid_press,valid_press_latched,pressed_sync, debounceOK,count_done,press;
  logic[7:0] segments,off,segments_latched;
  logic[47:0] buffer;
  
  assign ARDUINO_IO[7:4]=row_wires;
  assign col_wires=ARDUINO_IO[3:0];
  assign reset=~KEY[0];
  assign clk=MAX10_CLK1_50;
  assign {HEX5,HEX4,HEX3,HEX2,HEX1,HEX0}=buffer;
  assign off=8'b11111111;
  
  typedef enum int unsigned{
                            SCAN1=1,
									 SCAN2=2,
									 SCAN3=3,
									 SCAN4=4,
									 DECODE=5,
									 SEND=6
									 } statetype;
									 
  statetype present;
  assign present_state=present;
  
  kb_db u1(clk,reset,row_wires,col_wires,row_scan,present,row,col,valid_press,debounceOK,pressed_sync);
  decoder u2(row,col,key_code);
  seven_seg u3(key_code,segments);
  pulse_counter u4(clk,reset,count_done);
  
  //Finite State Machine
  always_ff @(posedge clk) begin
      if(reset) begin
		  present<=SCAN1;
		end
		else begin
		case(present)
			SCAN1:begin
    		row_scan<=4'b0111;
			if(count_done)begin
			if(valid_press_latched)begin
				present<=DECODE;
			end
			else begin
				present<=SCAN2;
			end
			end
			end
	
			SCAN2:begin		
			row_scan<=4'b1011;
			if(count_done)begin
			if(valid_press_latched)begin
				present<=DECODE;
			end
			else begin
				present<=SCAN3;
			end
			end
			end
	
			SCAN3:begin
			row_scan<=4'b1101;
			if(count_done)begin
			if(valid_press_latched)begin
			present<=DECODE;
			end
			else begin 
			present<=SCAN4;
			end
			end
			end
	
			SCAN4:begin	
			row_scan<=4'b1110;
			if(count_done)begin
			if(valid_press_latched)begin
				present<=DECODE;
			end
			else begin
				present<=SCAN1;
			end
			end
		   end
	
			DECODE:begin
			if(!pressed_sync&&debounceOK)begin
				present<=SEND;
			end
			else begin
				segments_latched<=segments;
				present<=DECODE;
			end
                        end 
			SEND: begin
			  present<=SCAN1;
			end
			
			default:begin
			 present<=SCAN1;
			end
		endcase
		end
	end
  
  // HEX displaying keys pressed
  always_ff @(posedge clk) begin
   if(reset)begin
	  buffer<={off,off,off,off,off,off};
	end
	else if(present==SEND)begin
	  buffer<={buffer[39:0],segments_latched};
	end
  end

  always_ff @(posedge clk) begin
   if(reset) begin
    valid_press_latched<= 0;
   end
   else begin
    if (present==DECODE) begin
      valid_press_latched<=0;
    end
    else if( valid_press ) begin
     valid_press_latched<= 1;
    end
   end
end
  
endmodule

module decoder(input logic[3:0] row,
               input logic[3:0] col,
					output logic[3:0] key_code);
					
					always_comb begin
					 key_code=4'h0;
					 case(row)
					  4'b0111:begin
					  if(col==4'b0111) key_code=4'h1;
					  else if(col==4'b1011) key_code=4'h2;
					  else if(col==4'b1101) key_code=4'h3;
					  else if(col==4'b1110) key_code=4'ha;
					  end
					  
					  4'b1011:begin
					  if(col==4'b0111) key_code=4'h4;
					  else if(col==4'b1011) key_code=4'h5;
					  else if(col==4'b1101) key_code=4'h6;
					  else if(col==4'b1110) key_code=4'hb;
					  end
					  
					  4'b1101:begin
					  if(col==4'b0111) key_code=4'h7;
					  else if(col==4'b1011) key_code=4'h8;
					  else if(col==4'b1101) key_code=4'h9;
					  else if(col==4'b1110) key_code=4'hc;
					  end
					  
					  4'b1110:begin
					  if(col==4'b0111) key_code=4'hf;
					  else if(col==4'b1011) key_code=4'h0;
					  else if(col==4'b1101) key_code=4'he;
					  else if(col==4'b1110) key_code=4'hd;
					  end
					  
					  //default:begin
					  //key_code=4'ha;
					  //end
					 endcase
					end
endmodule

module seven_seg(input logic [3:0] data,
                 output logic[7:0] segments);
  always_comb
	case(data)
	//gfe_dcfa
	4'h0: segments =8'b11000000;
	4'h1: segments =8'b11111001;
	4'h2: segments =8'b10100100;
	4'h3: segments =8'b10110000;
	4'h4: segments= 8'b10011001;
	4'h5: segments= 8'b10010010;
	4'h6: segments= 8'b10000010;	
	4'h7: segments= 8'b11111000;	
	4'h8: segments= 8'b10000000;
	4'h9: segments= 8'b10011000;
	4'ha: segments= 8'b10001000;	
   4'hb: segments= 8'b10000011;
   4'hc: segments= 8'b10100111;
   4'hd: segments= 8'b10100001;
	4'he: segments= 8'b10000110;
	4'hf: segments= 8'b10001110;
 
	default: segments= 8'b11111111;
	endcase
endmodule

module kb_db #( DELAY=16 ) (
	input logic clk, 
	input logic rst,
	inout wire [3:0] row_wires, // could be ?output logic?
	inout wire [3:0] col_wires, // could be ?input logic?
	input logic [3:0] row_scan,
        input logic [2:0] present,
	output logic [3:0] row,
	output logic [3:0] col,
	output logic valid,
	output logic debounceOK,
	output logic press
	);
	
	logic [3:0] col_F1, col_F2;
	logic [3:0] row_F1, row_F2;
	logic pressed, row_change, col_change;
        
        logic [3:0] row_sync;
        logic [3:0]	col_sync;
	logic pressed_sync;
	
	
	assign row_wires = row_scan;
	assign pressed = ~&( col_F2 );
	assign col_change = pressed ^ pressed_sync;
	assign row_change = |(row_scan ^ row_F1);

	// synchronizer
	always_ff @( posedge clk ) begin
		row_F1 <= row_scan; col_F1 <= col_wires;
		row_F2 <= row_F1; col_F2 <= col_F1;
		row_sync <= row_F2; col_sync <= col_F2;
      
		pressed_sync <= pressed;
	end
	
	// final retiming flip-flops
	// ensure row/col/valid appear together at the same time
	always_ff @( posedge clk ) begin
		valid <= debounceOK& pressed_sync;
		if( debounceOK & pressed_sync ) begin
		row <= row_sync;
		col <= col_sync;
		end else if(present== 3'h6) begin
		row <= 0;	
		col <= 0;
		end
	end
	
	// debounce counter
	logic [DELAY:0] counter;
	//initial counter = 0;
	always_ff @( posedge clk ) begin
		if( rst | row_change | col_change ) begin
		counter <= 0;
		end else begin
                if( !debounceOK )begin
                counter <= counter+1;
 		end
                else begin
                counter<=0;
                end
		end
	end
	
	assign debounceOK = counter[DELAY];
	assign press=pressed_sync;
	
endmodule

module pulse_counter(input logic clk, reset,
                     output logic count_done);
							
		logic	[32:0] counter;
		
		always_ff @(posedge clk,posedge reset) begin
		  if(reset) begin
		   counter<=0;
			count_done<=0;
		  end
		  else begin
		   if(counter==1048576)begin
			  counter<=0;
			  count_done<=1;
			end
			else begin
			  counter<=counter+1;
			  count_done<=0;
			end
		  end
		end
		
endmodule



