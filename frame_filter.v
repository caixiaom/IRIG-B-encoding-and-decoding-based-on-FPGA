`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/19 21:51:21
// Design Name: 
// Module Name: frame_filter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module frame_filter (
    input wire clk,
    input wire reset,
    input wire  [7:0] serial_in,
    input wire data_valid, 
    input wire pps, 

    output reg [7:0] sec,
    output reg [7:0] min,
    output reg [7:0] hour,
    
    output reg [3:0] year_h_bcd,
    output reg [3:0] year_l_bcd,
    output reg [3:0] days_h_bcd,
    output reg [3:0] days_m_bcd,
    output reg [3:0] days_l_bcd,
    output reg frame_valid
)/*synthesis noprune*/; 

parameter IDLE      = 3'b000;
parameter RECEIVE    = 3'b001;
parameter OUT      = 3'b010;


reg [5:0] byte_count; // 用于计数
reg [7:0] data_buffer [0:26]/*synthesis noprune*/; // 存储数据，最大40字节数据其中6字节为帧头

wire [7:0] hour10_r;  /*synthesis keep*/
wire [7:0] hour_r;   /*synthesis keep*/
wire [7:0] sec_10_r;  /*synthesis keep*/
wire [7:0] sec_1_r;   /*synthesis keep*/
wire [7:0] min_10_r;/*synthesis keep*/
wire [7:0] min_1_r;  /*synthesis keep*/
wire [7:0] hour_10_r;/*synthesis keep*/
wire [7:0] hour_1_r; /*synthesis keep*/

wire [7:0] month_10_r;
wire [7:0] month_1_r;
wire [7:0] month_r;
wire [3:0] day_100_r;
wire [3:0] day_10_r;
wire [3:0] day_1_r;

reg [9:0] day_d;

wire [7:0] year_10_r;
wire [7:0] year_1_r;


reg [3:0] hundreds_digit;
reg [3:0] tens_digit;
reg [3:0] ones_digit;
reg [11:0] bcd_out;


wire [7:0] gps_hour_dec;
wire [7:0] bj_hour;
reg [2:0] state, next_state;

// data_buffer[263:256] 时：十位
// data_buffer[255:248] 时：个位
    assign  hour_r =  data_buffer[8];
    assign  hour10_r =  data_buffer[7];
    assign  gps_hour_dec = {hour10_r[3:0],hour_r[3:0]};
    assign  bj_hour = gps_hour_dec >8'b00010101 ? (gps_hour_dec > 8'b00011001 ? {4'b0,gps_hour_dec[3:0]}  + 8'b0100 : {4'b0,gps_hour_dec[3:0]} - 8'b0110) : (gps_hour_dec == 8'b00010000||gps_hour_dec == 8'b00010001||gps_hour_dec == 8'b00000000||gps_hour_dec == 8'b00000001)?gps_hour_dec + 8'b1000 : gps_hour_dec + 8'b1000 +8'b0110;
    // assign   time_buffer [0] =  (data_buffer[255:248] > 8'h31 && data_buffer[263:256] < 8'h32) ? (data_buffer[263:256] + 8'h01) : 0   ;
    // assign   time_buffer [1] =  (data_buffer[255:248] > 8'h31)? (data_buffer[255:248] - 8'h02) : (data_buffer[255:248] + 8'h08);
    assign   hour_10_r = {4'b0011,bj_hour[7:4]};
    assign   hour_1_r = {4'b0011,bj_hour[3:0]};
    assign   min_10_r =  data_buffer[9];
    assign   min_1_r =  data_buffer[10];
    assign   sec_10_r =  data_buffer[11];
    assign   sec_1_r =  data_buffer[12];  


    assign   day_10_r = data_buffer[17];
    assign   day_1_r = data_buffer[18];
    assign   month_10_r = data_buffer[20];
    assign   month_1_r  = data_buffer[21];
    assign   month_r    = {month_10_r[3:0],month_1_r[3:0]};
    assign   year_10_r = data_buffer[25];
    assign   year_1_r  = data_buffer[26];

always @(*) begin
    case (month_r)
        8'h01:begin
                    day_d <= day_10_r[3:0]*'d10 + day_1_r[3:0];
              end  
        8'h02:begin
                    day_d <= 'd31 + day_10_r[3:0]*'d10 + day_1_r[3:0];
              end
        8'h03:begin
                    day_d <= 'd60 + day_10_r[3:0]*'d10 + day_1_r[3:0];
              end
        8'h04:begin
                    day_d <= 'd91 + day_10_r[3:0]*'d10 + day_1_r[3:0];
              end
        8'h05:begin
                    day_d <= 'd121 + day_10_r[3:0]*'d10 + day_1_r[3:0];
              end
        8'h06:begin
                    day_d <= 'd152 + day_10_r[3:0]*'d10 + day_1_r[3:0];
              end
        8'h07:begin
                    day_d <= 'd182 + day_10_r[3:0]*'d10 + day_1_r[3:0];
              end 
        8'h08:begin
                    day_d <= 'd213 + day_10_r[3:0]*'d10 + day_1_r[3:0];
              end
        8'h09:begin
                    day_d <= 'd244 + day_10_r[3:0]*'d10 + day_1_r[3:0];
              end
        8'h10:begin
                    day_d <= 'd274 + day_10_r[3:0]*'d10 + day_1_r[3:0];
              end
        8'h11:begin
                    day_d <= 'd305 + day_10_r[3:0]*'d10 + day_1_r[3:0];
              end
        8'h12:begin
                    day_d <= 'd335 + day_10_r[3:0]*'d10 + day_1_r[3:0];
              end                                                                                                              
        default:  day_d <= 'd0;
    endcase
end



always @(*) begin
    hundreds_digit = day_d / 100;
    tens_digit = (day_d % 100) / 10;
    ones_digit = day_d % 10;
    bcd_out = {hundreds_digit, tens_digit, ones_digit};
end




initial begin
    state = IDLE;
    byte_count = 0;
    frame_valid = 0;
   
end


reg prev_pps_signal;
reg pps_rise;

always @(posedge clk) begin
    prev_pps_signal <= pps;
    if (prev_pps_signal == 0 && pps == 1) begin  // 检测到上升沿
        pps_rise <= 1;
    end else begin
        pps_rise <= 0;
    end
end



always @(posedge clk or negedge reset) begin
    if (!reset) begin
        state <= IDLE;
    end
    else begin
        state <= next_state;
    end
end

 //下一状态逻辑
    always @(*) begin
        case (state)
            IDLE: begin

                if (pps_rise) begin
                    next_state = RECEIVE;
                end else begin
                    next_state = IDLE;
                end
            end
            RECEIVE: begin
                if(byte_count == 6'd27) begin
                   next_state = OUT;
                end else begin
                    next_state = RECEIVE;
                end
            end
            OUT: begin
                if(byte_count == 6'd28 )begin
                    next_state = IDLE;
                end else begin
                    next_state = OUT;
                end
            end
        endcase
    end

// 数据接收逻辑
always @(posedge clk or negedge reset) begin
        if (!reset) begin
            byte_count <= 0;
            frame_valid <= 0;
            sec <= 0;
            min <= 0;
            hour <= 0;
        end else begin
            case (state)
                IDLE: begin
                    byte_count <= 0;
                    frame_valid <= 0;
                end
                RECEIVE: begin
                    if(data_valid) begin
                        if(byte_count < 6'd27) begin
                            data_buffer[byte_count] <= serial_in;
                            byte_count <= byte_count +'d1;
                        end else begin
                            byte_count <= 0;
                        end
                    end 
                end
                OUT: begin
                    hour <= {hour_10_r[3:0],hour_1_r[3:0]};
                    min <= {min_10_r[3:0],min_1_r[3:0]};
                    sec <= {sec_10_r[3:0],sec_1_r[3:0]};
                    year_h_bcd <= year_10_r[3:0];
                    year_l_bcd <= year_1_r[3:0];
                    days_h_bcd <= hundreds_digit;
                    days_m_bcd <= tens_digit;
                    days_l_bcd <= ones_digit;
                    if(byte_count < 6'd28)
                    begin
                        frame_valid <=1;
                        byte_count <= byte_count +'d1;
                    end else begin
                        frame_valid <=0;
                    end
                
                end
               
            endcase
        end
    end


endmodule
