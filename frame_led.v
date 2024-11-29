module frame_led(sys_clk, _rst, Din, CS, CLK,sec,min,hour,flag,pps);
input sys_clk, _rst;
input wire [7:0] sec;
input wire [7:0] min;
input wire [7:0] hour;
input flag;
input wire pps;
output Din, CS, CLK;
/*---------------------------------------------------*/
reg [4:0]IRreg = 5'b00000;
reg [7:0]data = 8'h00;
reg clk_roll = 1'b0;
reg [7:0]display[7:0];
reg str;


reg prev_pps_signal;
reg pps_rise;

	parameter           IDLE   = 3'd0 ;
    parameter           NO_SIGNAL  = 3'd1 ;
    parameter           SIGNAL  = 3'd2 ;
	parameter 			READY = 3'd3;
	parameter 			WAIT = 3'd4;
	parameter           NO_SIGNAL_ADD  = 3'd5 ;
	parameter           NO_SIGNAL_SHOW  = 3'd6 ;	
	parameter 			ONE_SECOND_COUNT = 50_000_000;
 
/*---------------------------------------------------*/

reg [3:0]sec_10 = 4'b0000;
reg [3:0]sec_1 = 4'b0000;
reg [3:0]min_10 = 4'b0000;
reg [3:0]min_1 = 4'b0000;
reg [3:0]hour_10 = 4'b0000;
reg [3:0]hour_1 = 4'b0000;


/*---------------------------------------------------*/
MAX7219#(.Freq_MegaHZ(50))
		U0(
		.sys_clk(sys_clk), 
		 ._rst(_rst), 
		 .str(str), 
		 .busy(busy), 
		 .IRreg({3'b000,IRreg}), 
		 .data(data), 
		 .CS(CS),
		.CLK(CLK), 
		.Din(Din)
		);
/*---------------------------------------------------*/

reg  [4:0]IRreg_r = 5'b00000;

always @(posedge sys_clk) begin
    IRreg_r <= IRreg;
end

/*---------------------------------------------------

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


---------------------------------------------------*/

reg [31:0] pps_1s_counter;
reg  pps_1s;                 //每秒收到信号标志

/*---------------------------------------------------*/

reg [2:0]    next_state;
reg [2:0]    state ;

    //(1) state transfer
    always @(posedge sys_clk or negedge _rst) begin
        if (!_rst) begin
            state   <= IDLE ;
        end
        else begin
            state   <= next_state ;
        end
    end

 	always@(*) begin
 		if(_rst == 1'b0)
		begin
 			next_state <= IDLE; //任何情况下只要按复位就回到初始状态
		end else begin
		case(state)
			IDLE : 
				if(pps_rise == 1) 
				begin
					next_state <= READY;
				end else begin
					next_state <= IDLE;
				end
			READY :
				if(flag == 1 && pps_1s_counter == 0) 
				begin
					next_state <= SIGNAL;
				end else begin
					next_state <= READY;
				end
			SIGNAL : 
				if(IRreg == 5'h00 && IRreg_r ==5'h0f) 
				begin
					next_state <= WAIT;
				end else 
				begin
					next_state <= SIGNAL;
				end
			WAIT:
				if(pps_rise == 1)
				begin
					next_state <= READY;
				end else begin
					if(pps_1s == 1)
					begin
						next_state <= NO_SIGNAL_ADD;
					end else 
					begin
						next_state <= WAIT;
					end

				end
			NO_SIGNAL_ADD :
				begin
					next_state <= NO_SIGNAL_SHOW;
				end
			NO_SIGNAL_SHOW : 
				if(IRreg == 5'h00 && IRreg_r ==5'h0f) 
				begin
					next_state <= WAIT;
				end else 
				begin
					next_state <= NO_SIGNAL_SHOW;
				end

			default: next_state <= IDLE;
		endcase
		end
	end
		
		always@(posedge sys_clk or negedge _rst)
			if(_rst == 1'b0) begin
			
			pps_1s_counter <= 'd0;
			pps_1s <= 'd0;
			end else 
			begin
				case(state)

					IDLE: 	
						begin
							
							str <= 'b0;
							
							pps_1s_counter <= 'd0;
							pps_1s <= 'd0;
						end
					READY:
						begin
							pps_1s_counter <= 0;
							sec_1 <= sec[3:0];
							sec_10 <= sec[7:4];
							min_1 <= min[3:0];
							min_10 <= min[7:4];
							hour_1 <= hour[3:0];
							hour_10 <= hour[7:4];
						end
					WAIT:
						begin
							str <= 'b0;	
							
							if (pps_1s_counter == ONE_SECOND_COUNT - 1) 
							begin
								pps_1s_counter <= 0;
								pps_1s <= 1;
							end else 
							begin
								pps_1s <= 0;
								pps_1s_counter <= pps_1s_counter + 1;
							end	
						end
					SIGNAL:
						begin
							str <= 'b1;	
							display[7] <= {4'b0000,hour[7:4]};
							display[6] <= {4'b0000,hour[3:0]};
							display[5] <= 8'b1010;
							display[4] <= {4'b0000,min[7:4]};
							display[3] <= {4'b0000,min[3:0]};
							display[2] <= 8'b1010;
							display[1] <= {4'b0000,sec[7:4]};
							display[0] <= {4'b0000,sec[3:0]};
						end
				
					NO_SIGNAL_ADD:
						begin
							sec_1 <= sec_1 + 'd1;
            				if (sec_1 == 'd9) begin
								sec_1<= 0;
								sec_10 <= sec_10 + 'd1;
							end
							if (sec_10 == 'd5 && sec_1 == 'd9) begin
								sec_10 <= 0;
								min_1 <= min_1 + 'd1;
							end
							if (min_1 == 'd9 && sec_10 == 'd5 && sec_1 == 'd9) begin
								min_1 <= 0;
								min_10 <= min_10 + 'd1;
							end
							if (min_10 == 'd5 && min_1 == 'd9 &&  sec_10 == 'd5 && sec_1 == 'd9) begin
								min_10 <= 0;
								hour_1 <= hour_1 + 'd1;
							end
							if (hour_1 == 'd9 && min_10 == 'd5 && min_1 == 'd9 &&  sec_10 == 'd5 && sec_1 == 'd9) begin
								hour_1 <= 0;
								hour_10 <= hour_10 + 'd1;
							end
							if (hour_10 == 'd2 && hour_1 == 'd3 && min_10 == 'd5 && min_1 == 'd9 && sec_10 == 'd5 && sec_1 == 'd9 ) begin
								hour_1 <= 0;
								hour_10 <= 0;
							end	
						end
					
					
					NO_SIGNAL_SHOW:

						begin
							str <= 'b1;	
							display[7] <= {4'b0000,hour_10};
							display[6] <= {4'b0000,hour_1};
							display[5] <= 8'b1010;
							display[4] <= {4'b0000,min_10};
							display[3] <= {4'b0000,min_1};
							display[2] <= 8'b1010;
							display[1] <= {4'b0000,sec_10};
							display[0] <= {4'b0000,sec_1};
						end


				endcase
			end
/*---------------------------------------------------*/



always @(posedge sys_clk) begin
    prev_pps_signal <= pps;
    if (prev_pps_signal == 0 && pps == 1) begin  // 检测到上升沿
        pps_rise <= 1;
    end else begin
        pps_rise <= 0;
    end
end

/*---------------------------------------------------
	always@(posedge clk_roll, negedge _rst)begin
		if(!_rst)begin
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
---------------------------------------------------*/
	always@(negedge busy, negedge _rst)begin
		if(!_rst)
			IRreg <= 5'd0;
		else
			if(IRreg == 5'h0f ) begin
				IRreg <= 5'd0;
			end else
			begin
				IRreg <= IRreg + 1;
			end
	end
/*---------------------------------------------------*/

	always@(IRreg)begin
		case(IRreg)
			5'h0:data  = 8'h00;
			5'h1:data  = display[0];
			5'h2:data  = display[1];
			5'h3:data  = display[2];
			5'h4:data  = display[3];
			5'h5:data  = display[4];
			5'h6:data  = display[5];
			5'h7:data  = display[6];
			5'h8:data  = display[7];
			5'h9:data  = 8'hff;//decode mode
			5'hA:data  = 8'h05;//light(0~15)
			5'hB:data  = 8'h07;//scanline(0~7)
			5'hC:data  = 8'h01;//shutdown
			5'hF:data  = 8'h00;//test
			default:data  = 8'h00;
		endcase
	end
/*---------------------------------------------------*/




endmodule 