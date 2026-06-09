
module testbench();
    logic clk;
    logic [7:0] HEX5,HEX4,HEX3,HEX2,HEX1,HEX0;
    logic [1:0] KEY;
    wire [15:0] ARDUINO;
    logic press5;
    logic [2:0]present;
     
    keypad2 dut(.MAX10_CLK1_50(clk), .KEY(KEY),.ARDUINO_IO(ARDUINO),.HEX5(HEX5),.HEX4(HEX4),.HEX3(HEX3),.HEX2(HEX2),.HEX1(HEX1),
                .HEX0(HEX0), .present_state(present));
    assign ARDUINO[3:0] =
    (press5 && ARDUINO[7:4] == 4'b1011)
    ? 4'b1011
    : 4'b1111;

    always
	begin
	
	clk=1;#10;
	clk=0;#10;
	end

    initial 
     begin
        
	KEY[0]=0; 
        press5=0;
        #50;
	KEY[0]=1;
        #1000;
        
        press5=1;
        #50000000;

        press5=0;
        #15000000;

         if( HEX0==8'b10010010) 
           $display("correct key pressed");
         else
           $display("wrong key pressed");

           press5=1;
           #100000;
           press5=0;
           #200000;
         
         $finish;

     end
endmodule