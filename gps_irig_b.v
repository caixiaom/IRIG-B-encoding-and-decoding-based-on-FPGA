`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/29 15:58:41
// Design Name: 
// Module Name: gps_irig_b
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


module gps_irig_b(
    input wire sys_clk , //系统时钟50MHz
    input wire sys_rst_n , //全局复位

    // input wire [7:0] data_1,
    // input wire flag_1,
    // input wire str,


    input wire rx_1 , //串口1接收数据  PC to FPGA
    input wire rx_2,  //串口2接收数据  GPS to FPGA

    input wire pps,  //秒脉冲信号 
    input wire irig_b, //编码信号输入

    output wire irig_b_test,   

    output wire tx_1, //串口1发送数据 FPGA to PC
    output wire tx_2, //串口2发送数据 FPGA to GPS

    output wire CS, 
    output wire Din,
    output wire CLK,

    output wire CS2, 
    output wire Din2,
    output wire CLK2,

    output wire out_test,   
    output wire out,
    output wire clk_1Mhz
    );

 //parameter define
    parameter UART_BPS = 14'd9600; //比特率
    parameter CLK_FREQ = 26'd50_000_000; //时钟频率

    //wire define
    wire [7:0] data_1;    
    wire flag_1;
    wire [7:0] data_2;  
    wire flag_2;
    wire [7:0] data_3;  
    wire  flag_3;
    wire [7:0]data_4;
    wire time_flag/*synthesis keep*/;  
    wire time_vaild;
    wire pps_out;
    wire [7:0] sec_r /*synthesis keep*/; 
    wire [7:0] min_r/*synthesis keep*/; 
    wire [7:0] hour_r/*synthesis keep*/; 

    wire [7:0] sec_out /*synthesis keep*/; 
    wire [7:0] min_out/*synthesis keep*/; 
    wire [7:0] hour_out/*synthesis keep*/; 

    
    wire [3:0] days_h_bcd;
    wire [3:0] days_l_bcd;
    wire [3:0] days_m_bcd;
    wire [3:0] hour_h_bcd;
    wire [3:0] hour_l_bcd;
    wire [3:0] minute_h_bcd;
    wire [3:0] minute_l_bcd;
    wire [3:0] second_h_bcd;
    wire [3:0] second_l_bcd;
    wire [3:0] year_h_bcd;
    wire [3:0] year_l_bcd;

    

    assign second_h_bcd = sec_r[7:4];
    assign second_l_bcd = sec_r[3:0];
    assign minute_h_bcd = min_r[7:4];
    assign minute_l_bcd = min_r[3:0];
    assign hour_h_bcd = hour_r[7:4];
    assign hour_l_bcd = hour_r[3:0];
    assign irig_b_test = irig_b;
    assign out_test = out;

 //------------------------PC to FPGA 串口2---------------------//
 uart_rx_1
 #(
 .UART_BPS (UART_BPS), //串口波特率
 .CLK_FREQ (CLK_FREQ) //时钟频率
 )
 uart_rx_1_inst
 (
 .sys_clk (sys_clk ), //input sys_clk
 .sys_rst_n (sys_rst_n ), //input sys_rst_n
 .rx (rx_1 ), //input rx

 .po_data (data_1 ), //output [7:0] po_data_1
 .po_flag (flag_1 ) //output po_flag_1
 );
//--------------------------------------------------------------//


//------------------------FPGA to PC 串口1----------------------//
 uart_tx_1    //发送给电脑，测试用
 #(
 .UART_BPS (UART_BPS), //串口波特率
 .CLK_FREQ (CLK_FREQ) //时钟频率
 )
 uart_tx_1_inst
 (
 .sys_clk (sys_clk ), //input sys_clk
 .sys_rst_n (sys_rst_n ), //input sys_rst_n
 .pi_data (sec_r ), //input [7:0] pi_data
 .pi_flag (time_flag ), //input pi_flag

 .tx (tx_1 ) //output tx
 );
//---------------------------------------------------------------//


//------------------------GPS to FPGA 串口2----------------------//
 uart_rx_2
 #(
 .UART_BPS (UART_BPS), //串口波特率
 .CLK_FREQ (CLK_FREQ) //时钟频率
 )
 uart_rx_2_inst
 (
 .sys_clk (sys_clk ), //input sys_clk
 .sys_rst_n (sys_rst_n ), //input sys_rst_n
 .rx (rx_2 ), //input rx

 .po_data (data_2 ), //output [7:0] po_data
 .po_flag (flag_2 ) //output po_flag
 );
//---------------------------------------------------------------//


//------------------------FPGA to GPS 串口2----------------------// 
 uart_tx_2
 #(
 .UART_BPS (UART_BPS), //串口波特率
 .CLK_FREQ (CLK_FREQ) //时钟频率
 )
 uart_tx_2_inst
 (
 .sys_clk (sys_clk ), //input sys_clk
 .sys_rst_n (sys_rst_n ), //input sys_rst_n
 .pi_data (data_3), //input [7:0] pi_data
 .pi_flag (flag_3), //input pi_flag

 .tx (tx_2 ) //output tx
 );
//---------------------------------------------------------------//


//------------------------GPS时间提取模块------------------------//
 frame_filter frame_filter_inst 
 (
     .clk (sys_clk),                 // 时钟信号
     .reset (sys_rst_n),             // 复位信号
     .serial_in (data_2),       // 输入数据
     .data_valid (flag_2),     // 输入数据有效信号
     .pps (pps),
              
     .sec (sec_r),      // 输出秒数据（8位）
     .min (min_r),      // 输出分钟数据（8位）
     .hour (hour_r),    // 输出小时数据（8位）

     .year_h_bcd(year_h_bcd), 
     .year_l_bcd(year_l_bcd),
     .days_h_bcd(days_h_bcd),
     .days_l_bcd(days_l_bcd),
     .days_m_bcd(days_m_bcd),  

     .frame_valid (time_flag)       // 输出数据有效信号
 );
//---------------------------------------------------------------//


//------------------------GPS时间显示模块------------------------//
frame_led frame_led_inst
(
    .sys_clk (sys_clk ), 
    ._rst (sys_rst_n),  
    .sec (sec_r),      // 输入秒数据（8位）
    .min (min_r),      // 输入分钟数据（8位）
    .hour (hour_r),     // 输入小时数据（8位）
    .Din (Din), 
    .CS (CS), 
    .CLK (CLK),
    .flag (time_flag),
    .pps (pps)
);
//---------------------------------------------------------------//


//------------------------IRIG-B编码模块------------------------//
irig_out irig_out_i1 
(
	._rst(sys_rst_n),
	.clk(sys_clk),
	.days_h_bcd(days_h_bcd),
	.days_l_bcd(days_l_bcd),
	.days_m_bcd(days_m_bcd),
	.hour_h_bcd(hour_h_bcd),
	.hour_l_bcd(hour_l_bcd),
	.minute_h_bcd(minute_h_bcd),
	.minute_l_bcd(minute_l_bcd),

	.out(out),

	.pps(pps),
	.second_h_bcd(second_h_bcd),
	.second_l_bcd(second_l_bcd),
	.year_h_bcd(year_h_bcd),
	.year_l_bcd(year_l_bcd)
);
//---------------------------------------------------------------//


//------------------------IRIG-B解码模块------------------------//
 b_decoder b_decoder_l1     
 (

    .clk_10Khz(clk_10Khz),
    .rst_n(sys_rst_n),

    .irig_b(irig_b),
    
    .second_out(sec_out),
    .minute_out(min_out),
    .hour_out(hour_out),
    .day_out(),
    .year_out(),
    .time_vaild(time_vaild),
    .pps(pps_out)

);
//---------------------------------------------------------------//


//------------------------解码数据显示模块------------------------//
frame_led frame_led_inst2
(
    .sys_clk (sys_clk ), 
    ._rst (sys_rst_n),  

/*  
    .sec (sec_r),      // 输入秒数据（8位）     测试用
    .min (min_r),      // 输入分钟数据（8位）   测试用
    .hour (hour_r),     // 输入小时数据（8位）  测试用 
*/

    .sec (sec_out),      // 输入秒数据（8位）
    .min (min_out),      // 输入分钟数据（8位）
    .hour (hour_out),     // 输入小时数据（8位）

    .Din (Din2), 
    .CS (CS2), 
    .CLK (CLK2),
    .flag (time_vaild),
    .pps (pps_out)
);
//---------------------------------------------------------------//


//----------------------解码模块所需的分频器---------------------//
PLL_1Mhz	PLL_1Mhz_inst 
    (
	.inclk0 ( sys_clk ),
	.c0 ( clk_10Khz )
	);
//--------------------------------------------------------------//


endmodule
