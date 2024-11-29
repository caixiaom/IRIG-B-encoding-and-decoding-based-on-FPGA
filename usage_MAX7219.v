module usage_MAX7219(sys_clk, _rst, Din, CS, CLK,pi_data,flag,pps);
input sys_clk, _rst;
input wire [7:0] pi_data;
input flag;
input wire pps;
output Din, CS, CLK;
/*---------------------------------------------------*/
reg [3:0]IRreg = 4'b0000;
reg [7:0]data = 8'h00;
reg clk_roll = 1'b0;
reg [7:0]display[7:0];
/*---------------------------------------------------*/
MAX7219#(.Freq_MegaHZ(50))
		U0(
		.sys_clk(sys_clk), 
		 ._rst(_rst), 
		 .str('d1), 
		 .busy(busy), 
		 .IRreg({4'b0000,IRreg}), 
		 .data(data), 
		 .CS(CS),
		.CLK(CLK), 
		.Din(Din)
		);
/*---------------------------------------------------*/
reg [22:0]cnt = 'd0;
	always@(posedge sys_clk)begin
		if(!_rst)begin
			cnt      <= 'd0;
			clk_roll <= 1'b0;
		end
		else begin
			if(cnt=='d5000000)begin
				clk_roll <= ~clk_roll;
				cnt <= 'd0;
			end
			else
				cnt <= cnt + 1'b1;
		end
	end
/*---------------------------------------------------*/
reg [47:0]data_tim = 'd0;
reg [2:0] cnt_tim = 'd0;
	always@(posedge sys_clk or negedge _rst)begin
		if(!_rst)begin
			cnt_tim  <= 'd0;
			data_tim <= 'd0;
		end
		else begin
			if(flag && cnt_tim < 6)begin
				data_tim <= {data_tim[39:0],pi_data};
				cnt_tim <= cnt_tim + 1'b1;
			end
			else
				cnt_tim <= 'd0;
		end
	end
/*---------------------------------------------------*/
	always@(posedge clk_roll, negedge _rst)begin
		if(!_rst)begin
		/*          mode 1
			display[0] <= 8'b11111111;
			display[1] <= 8'b00111100;
			display[2] <= 8'b00111100;
			display[3] <= 8'b11100111;
			display[4] <= 8'b11100111;
			display[5] <= 8'b00111100;
			display[6] <= 8'b00111100;
			display[7] <= 8'b11111111;*/
			display[0] <= 8'b10101010;
			display[1] <= 8'b01010101;
			display[2] <= 8'b10101010;
			display[3] <= 8'b01010101;
			display[4] <= 8'b10101010;
			display[5] <= 8'b01010101;
			display[6] <= 8'b10101010;
			display[7] <= 8'b01010101;
		end else begin
			 if(pps == 1) 
			begin
			display[0] <= 8'b10101010;
			display[1] <= 8'b01010101;
			display[2] <= 8'b10101010;
			display[3] <= 8'b01010101;
			display[4] <= 8'b10101010;
			display[5] <= 8'b01010101;
			display[6] <= 8'b10101010;
			display[7] <= 8'b01010101;
			end else begin 
			display[0] <= data_tim[7:0];  
			display[1] <= data_tim[15:8];
			display[2] <= 8'b1010;
			display[3] <= data_tim[23:16];
			display[4] <= data_tim[31:24];
			display[5] <= 8'b1010;
			display[6] <= data_tim[39:32];
			display[7] <= data_tim[47:40];
			end
		end
	end
/*---------------------------------------------------*/
	always@(negedge busy, negedge _rst)begin
		if(!_rst)
			IRreg <= 4'd0;
		else
			IRreg <= IRreg + 1;
	end
/*---------------------------------------------------*/
	always@(IRreg)begin
		case(IRreg)
			4'h0:data  = 8'h00;
			4'h1:data  = display[0];
			4'h2:data  = display[1];
			4'h3:data  = display[2];
			4'h4:data  = display[3];
			4'h5:data  = display[4];
			4'h6:data  = display[5];
			4'h7:data  = display[6];
			4'h8:data  = display[7];
			4'h9:data  = 8'hff;//decode mode
			4'hA:data  = 8'h08;//light(0~15)
			4'hB:data  = 8'h07;//scanline(0~7)
			4'hC:data  = 8'h01;//shutdown
			4'hF:data  = 8'h00;//test
			default:data  = 8'h00;
		endcase
	end
/*---------------------------------------------------*/



endmodule 