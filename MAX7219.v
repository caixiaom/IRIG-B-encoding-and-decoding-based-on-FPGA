module MAX7219#(parameter Freq_MegaHZ = 50)
(sys_clk, _rst, str, busy, 
IRreg, data, CS, CLK, Din);


input sys_clk, _rst, str;
input [7:0]data, IRreg;
output busy;
output reg CS = 1'b1, Din = 1'b0, CLK = 1'b0;



reg [5:0]cnt = 'd0;
reg [1:0]state = 2'd0;
/*---------------------------------------------------*/
parameter IDLE     = 2'd0;
parameter Address  = 2'd1;
parameter TxData   = 2'd2;
parameter finished = 2'd3;
parameter ON       = 8'h01;
parameter OFF      = 8'h00;
/*---------------------------------------------------*/
reg clk_spi = 1'b0;
assign busy = (state==IDLE)?0:1;
/*---------------------------------------------------*/
	always@(posedge sys_clk, negedge  _rst)begin
		if(!_rst)begin
			cnt     <= 'd0;
			clk_spi <= 1'b0;
		end
		else begin
			if(str)begin
				if(cnt==Freq_MegaHZ/2)begin
					clk_spi <= ~clk_spi;
					cnt     <= 'd0;
				end
				else 
					cnt <= cnt + 1'b1;
			end
			else begin
				cnt     <= 'd0;
				clk_spi <= 1'b0;
			end
		end
	end
/*---------------------------------------------------*/
reg [2:0]TxCnt = 3'd7;
reg [2:0]flag = 3'b001;
	always@(posedge clk_spi, negedge  _rst)begin
		if(!_rst)begin
			flag   <= 3'b001;
			CS     <= 1'b1;
			TxCnt  <= 3'd7;
			state  <= IDLE;
		end
		else begin
			case(state)
				IDLE:begin
					if(str)begin
						TxCnt <= 3'd7;
						CS    <= 1'b0;
						flag  <= 3'b001;
						state <= Address;
					end
					else begin
						CS    <= 1'b1;
						state <= IDLE;
					end
				end
				Address:begin
					flag <= flag << 1;
					if(flag==3'b001)
						Din  <= IRreg[TxCnt];
					else if(flag==3'b010)
						CLK  <= 1'b1;
					else if(flag==3'b100)begin
						CLK  <= 1'b0;
						flag <= 3'b001;
						if(TxCnt==3'd0)begin
							TxCnt <= 3'd7;
							state <= TxData;
						end
						else
							TxCnt <= TxCnt - 1'b1;
					end
				end
				TxData:begin
					flag <= flag << 1;
					if(flag==3'b001)
						Din  <= data[TxCnt];
					else if(flag==3'b010)
						CLK  <= 1'b1;
					else if(flag==3'b100)begin
						CLK  <= 1'b0;
						flag <= 3'b001;
						if(TxCnt==3'd0)begin
							TxCnt  <= 3'd7;
							state  <= finished;
						end
						else
							TxCnt <= TxCnt - 1'b1;
					end
				end
				finished:begin
					Din    <= 1'b0;
					CS     <= 1'b1;
					state  <= IDLE;
				end
			endcase
		end
	end
/*---------------------------------------------------*/
endmodule 