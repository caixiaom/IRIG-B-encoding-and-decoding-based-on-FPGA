module b_decoder (
    input wire clk_10Khz,
    input wire rst_n,
    input wire irig_b,
    output wire [7:0]second_out,
    output wire [7:0]minute_out,
    output wire [7:0]hour_out,
    output wire [9:0]day_out,
    output wire [7:0]year_out,
    output wire time_vaild,
    output reg pps
);

parameter MAX_8MS = 80;
parameter MAX_5MS = 50;
parameter MAX_2MS = 20;
parameter MAX_1S = 99;
parameter IDLE = 4'b0000;
parameter P = 4'b0001;
parameter SEC = 4'b0011;
parameter MIN = 4'b0010;
parameter HOUR = 4'b0110;
parameter DAY1 = 4'b0111;
parameter DAY2 = 4'b0101;
parameter YEAR = 4'b0100;
parameter S0 = 4'b1100;
parameter S1 = 4'b1101;
parameter S2 = 4'b1111;
parameter S3 = 4'b1110;

reg irig_b_r1;
reg [19:0]cnt_pos;
reg [1:0]decode;
reg [3:0]state;
reg [6:0]cnt_1s;

reg  time_vaild_r;

reg [6:0]second;
reg [6:0]minute;
reg [5:0]hour;
reg [9:0]day;
reg [7:0]year;

//下降沿和上升沿判断
//延迟一拍的输入波形
always @(posedge clk_10Khz or negedge rst_n) begin
    if (~rst_n) begin
        irig_b_r1 <= 1'b0;
    end
    else begin
        irig_b_r1 <= irig_b;
    end
end


assign edge_pos = irig_b & ~irig_b_r1;//上升沿
assign edge_neg = ~irig_b & irig_b_r1;//下降沿

//b码高电平计数
always @(posedge clk_10Khz or negedge rst_n) begin
    if (~rst_n) begin
        cnt_pos <= 20'd0;
    end
    else if (edge_pos) begin
        cnt_pos <= 20'd1;
    end
    else if (irig_b) begin
        cnt_pos <= cnt_pos +20'b1;
    end
    else begin
        cnt_pos <= cnt_pos;
    end
end

//下降沿判断，波形编码
always @(posedge clk_10Khz or negedge rst_n) begin
    if (~rst_n) begin
        decode <= 2'b00;
    end
    else if (cnt_pos == MAX_8MS  && edge_neg) begin
        decode <= 2'b11;
    end
    else if (cnt_pos == MAX_5MS  && edge_neg) begin
        decode <= 2'b01;
    end
    else if (cnt_pos == MAX_2MS  && edge_neg) begin
        decode <= 2'b00;
    end
end

//状态机
always @(posedge clk_10Khz or negedge rst_n) begin
    if (~rst_n) begin
        state <= IDLE;

    end
    else case (state)
        IDLE : begin
            if (decode == 2'b11 && edge_pos) begin
                state <= P;
            end
            else begin
                state <= state;
            end
        end
        P : begin
            if (decode == 2'b11 && edge_pos) begin
                state <= SEC;
            end
            else if ((decode == 2'b00 && edge_pos)||(decode == 2'b00 && edge_pos)) begin
                state <= IDLE;
            end
            else begin
                state <= state;
            end
        end
        SEC : begin
            if (decode == 2'b11 && edge_pos) begin
                state <= MIN;
            end
            else begin
                state <= state;
            end
        end
        MIN : begin
            if (decode == 2'b11 && edge_pos) begin
                state <= HOUR;
            end
            else begin
                state <= state;
            end
        end
        HOUR : begin
            if (decode == 2'b11 && edge_pos) begin
                state <= DAY1;
            end
            else begin
                state <= state;
            end
        end
        DAY1 : begin
            if (decode == 2'b11 && edge_pos) begin
                state <= DAY2;
            end
            else begin
                state <= state;
            end
        end
        DAY2 : begin
            if (decode == 2'b11 && edge_pos) begin
                state <= YEAR;
            end
            else begin
                state <= state;
            end
        end
        YEAR : begin
            if (decode == 2'b11 && edge_pos) begin
                state <= S0;
            end
            else begin
                state <= state;
            end
        end
        S0 : begin
            
            if (decode == 2'b11 && edge_pos) begin
                state <= S1;
            end
            else begin
                state <= state;
            end
        end
        S1 : begin
            if (decode == 2'b11 && edge_pos) begin
                state <= S2;
            end
            else begin
                state <= state;
            end
        end
        S2 : begin
            if (decode == 2'b11 && edge_pos) begin
                state <= S3;
            end
            else begin
                state <= state;
            end
        end
        S3 : begin
            if (decode == 2'b11 && edge_pos) begin
                state <= P;
            end
            else begin
                state <= state;
            end
        end
        default: state <= state;
    endcase
end
    
    
// 根据状态机控制cnt_1s计数
always @(posedge clk_10Khz or negedge rst_n) begin
    if (~rst_n) begin
        cnt_1s <= 7'd0;
    end
    else if (cnt_1s == MAX_1S && edge_pos) begin
        cnt_1s <= 7'd0;
    end
    else if (state == P && edge_pos) begin
        cnt_1s <= 7'd1;
    end
    else if (edge_pos) begin
        cnt_1s <= cnt_1s + 7'd1;
    end
    else begin
        cnt_1s <= cnt_1s;
    end
end

//产生用于显示的基准信号
always @(posedge clk_10Khz or negedge rst_n) begin
    if (~rst_n) begin
        pps <= 'd0;
    end
    else if (cnt_1s == 1'd1 ) begin
        pps <= 'd1; 
    end
    else begin
        pps <= 'd0;
    end
end


//赋值
always @(posedge clk_10Khz or negedge rst_n) begin
    if (~rst_n) begin
        second <= 7'b0;
    end
    else if (cnt_1s == 8'd1) begin
        second[0] <= decode[0];
    end
    else if (cnt_1s == 8'd2) begin
        second[1] <= decode[0];
    end
    else if (cnt_1s == 8'd3) begin
        second[2] <= decode[0];
    end
    else if (cnt_1s == 8'd4) begin
        second[3] <= decode[0];
    end
    else if (cnt_1s == 8'd6) begin
        second[4] <= decode[0];
    end
    else if (cnt_1s == 8'd7) begin
        second[5] <= decode[0];
    end
    else if (cnt_1s == 8'd8) begin
        second[6] <= decode[0];
    end
    else begin
        second <= second;
    end
end

always @(posedge clk_10Khz or negedge rst_n) begin
    if (~rst_n) begin
        minute <= 7'b0;
    end
    else if (cnt_1s == 8'd10) begin
        minute[0] <= decode[0];
    end
    else if (cnt_1s == 8'd11) begin
        minute[1] <= decode[0];
    end
    else if (cnt_1s == 8'd12) begin
        minute[2] <=decode[0];
    end
    else if (cnt_1s == 8'd13) begin
        minute[3] <= decode[0];
    end
    else if (cnt_1s == 8'd15) begin
        minute[4] <= decode[0];
    end
    else if (cnt_1s == 8'd16) begin
        minute[5] <= decode[0];
    end
    else if (cnt_1s == 8'd17) begin
        minute[6] <= decode[0];
    end
    else begin
        minute <= minute;
    end
end

always @(posedge clk_10Khz or negedge rst_n) begin
    if (~rst_n) begin
        hour <= 6'b0;
        time_vaild_r <= 'b0;
    end
    else if (cnt_1s == 8'd20) begin
        hour[0] <= decode[0];
    end
    else if (cnt_1s == 8'd21) begin
        hour[1] <= decode[0];
    end
    else if (cnt_1s == 8'd22) begin
        hour[2] <= decode[0];
    end
    else if (cnt_1s == 8'd23) begin
        hour[3] <= decode[0];
    end
    else if (cnt_1s == 8'd25) begin
        hour[4] <= decode[0];
    end
    else if (cnt_1s == 8'd26) begin
        hour[5] <= decode[0];
    end
    else if (cnt_1s == 8'd27 && edge_neg) begin
        time_vaild_r <= 'b1;
        end
    else begin
        hour <= hour;
        time_vaild_r <= 'b0;
    end
end

always @(posedge clk_10Khz or negedge rst_n) begin
    if (~rst_n) begin
        day <= 10'b0;
    end
    else if (cnt_1s == 8'd30) begin
        day[0] <= decode[0];
    end
    else if (cnt_1s == 8'd31) begin
        day[1] <= decode[0];
    end
    else if (cnt_1s == 8'd32) begin
        day[2] <= decode[0];
    end
    else if (cnt_1s == 8'd33) begin
        day[3] <= decode[0];
    end
    else if (cnt_1s == 8'd35) begin
        day[4] <= decode[0];
    end
    else if (cnt_1s == 8'd36) begin
        day[5] <= decode[0];
    end
    else if (cnt_1s == 8'd37) begin
        day[6] <= decode[0];
    end
    else if (cnt_1s == 8'd38) begin
        day[7] <= decode[0];
    end
    else if (cnt_1s == 8'd40) begin
        day[8] <= decode[0];
    end
    else if (cnt_1s == 8'd41) begin
        day[9] <= decode[0];
    end
    else begin
        day <= day;
    end
end

always @(posedge clk_10Khz or negedge rst_n) begin
    if (~rst_n) begin
        year <= 6'b0;
    end
    else if (cnt_1s == 8'd50) begin
        year[0] <= decode[0];
    end
    else if (cnt_1s == 8'd51) begin
        year[1] <= decode[0];
    end
    else if (cnt_1s == 8'd52) begin
        year[2] <= decode[0];
    end
    else if (cnt_1s == 8'd53) begin
        year[3] <= decode[0];
    end
    else if (cnt_1s == 8'd55) begin
        year[4] <= decode[0];
    end
    else if (cnt_1s == 8'd56) begin
        year[5] <= decode[0];
    end
    else if (cnt_1s == 8'd57) begin
        year[6] <= decode[0];
    end
    else if (cnt_1s == 8'd58) begin
        year[7] <= decode[0];
    end
    else begin
        year <= year;
    end
end


assign second_out = {{1'b0,second[6:4]},second[3:0]};
assign minute_out = {{1'b0,minute[6:4]},minute[3:0]};
assign hour_out = {{2'b0,hour[5:4]},hour[3:0]};
assign day_out = day[9:8]*100 + day[7:4]*10 + day[3:0];
assign year_out = year[7:4]*10 + year[3:0];
assign time_vaild = time_vaild_r;

endmodule
