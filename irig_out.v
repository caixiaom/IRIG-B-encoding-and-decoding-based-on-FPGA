module  irig_out(       
		input	                    clk,
		input       			    _rst,
        input                       pps,
		input		[3:0]	   		second_l_bcd,
		input		[3:0]	   		second_h_bcd,
		input		[3:0]	   		minute_l_bcd,
		input		[3:0]	   		minute_h_bcd,
		input		[3:0]	   		hour_l_bcd,
		input		[3:0]	   		hour_h_bcd,
		input		[3:0]	   		days_l_bcd,
		input		[3:0]	   		days_m_bcd,
		input		[3:0]	   		days_h_bcd,
		input		[3:0]	   		year_l_bcd,
		input		[3:0]	   		year_h_bcd,
		output   reg                out

	  	 );	
		wire 						clk_100M;
		wire         				out_reg;
		wire 	   [99:0] 			initial_value;
		reg		   [99:0]	        out_buf; 
		reg        [27:0]           cnt_clk10M;
		reg                       syn_1pps_1clk;
		reg		   [19:0]	        pwm_counter;																																				
	    reg		   [6:0]	        cnt_time;																																				
	    reg			    			out_P;	
				




	    wire [18:0] 		    	second_day;	
		wire [18:0]                 mul_song_ip0_result;
		wire [18:0]                 mul_song_ip1_result;
		wire [18:0]                 mul_song_ip2_result;
		wire [18:0]                 mul_song_ip3_result;
		wire [18:0]                 mul_song_ip4_result;
        wire [5:0]                  hour_o  ;
        wire [5:0]                  minute_o; 
        wire [5:0]                  second_o; 
        wire [18:0]                 hour_i  ; 
        wire [18:0]                 minute_i; 
        wire [5:0]                  second_i; 
        reg  [10:0]                 finish_reg_shift ;
        reg  [18:0]                 hour  ; 
        reg  [18:0]                 minute; 
        reg  [5:0]                  second;  


        assign hour_o   = mul_song_ip0_result[4:0]+hour_l_bcd;
        assign minute_o = mul_song_ip1_result[5:0]+minute_l_bcd;
        assign second_o = mul_song_ip2_result[5:0]+second_l_bcd;
		assign hour_i   = mul_song_ip3_result;        //以秒为单位
        assign minute_i = mul_song_ip4_result;        //以秒为单位
        assign second_i = second_o;  


		assign    second_day=hour+minute+second;   //当天的秒数


always @(posedge clk or negedge _rst)  
			if(!_rst)	
				finish_reg_shift <= 11'h0;
			   
			else
			   finish_reg_shift <= { finish_reg_shift[9:0], 1'b1};  //最终的second,minute,hour的值，需等待各个计算值稳定后赋值，finish_reg_shift[10]是赋值控制信号
				
				
		always @(posedge clk or negedge _rst)      
   			if(!_rst)	                              
       			second  <=6'h0;                           			                     
   			else if(finish_reg_shift[10])          
       			second  <=second_i;               
	   
		always @(posedge clk or negedge _rst)  
           if(!_rst)	begin
               hour  <=18'h0;
               minute<=18'h0;
           end
           else if(finish_reg_shift[10])  begin
               hour  <=hour_i  ;
               minute<=minute_i;
           end



mul_song	mul_song_0 (
	.dataa ( 12'd10 ),
	.datab ( {3'b0,hour_h_bcd} ),
	.result ( mul_song_ip0_result )
	);

mul_song	mul_song_1 (
	.dataa ( 12'd10 ),
	.datab ( {3'b0,minute_h_bcd} ),
	.result ( mul_song_ip1_result )
	);

mul_song	mul_song_2 (
	.dataa ( 12'd10 ),
	.datab ( {3'b0,second_h_bcd} ),
	.result ( mul_song_ip2_result )
	);

mul_song   mul_song_3(    
    .dataa   (12'd3600),      
    .datab   ({2'b0,hour_o}  ),            
    .result  (mul_song_ip3_result)             
    ); 

mul_song	mul_song_4 (
	.dataa ( 12'd60 ),
	.datab ( {1'b0,minute_o} ),
	.result ( mul_song_ip4_result )
	);


//write data into out_buf initial_value
		assign  initial_value[0]      =  1'b0;
	    assign  initial_value[4:1]    =  second_l_bcd; 
		assign  initial_value[5]      =  1'b0; 	
	    assign  initial_value[9:6]    =  second_h_bcd;
	    assign  initial_value[13:10]  =  minute_l_bcd;
		assign  initial_value[14]     =  1'b0;	
	    assign  initial_value[18:15]  =  minute_h_bcd;
		assign  initial_value[19]     =  1'b0;	
	    assign  initial_value[23:20]  =  hour_l_bcd; 
		assign  initial_value[24]     =  1'b0;	
	    assign  initial_value[28:25]  =  hour_h_bcd;
		assign  initial_value[29]     =  1'b0;	
	    assign  initial_value[33:30]  =  days_l_bcd;  
		assign  initial_value[34]     =  1'b0;	
	    assign  initial_value[38:35]  =  days_m_bcd;
		assign  initial_value[39]     =  1'b0;	
	    assign  initial_value[43:40]  =  days_h_bcd; 
		assign  initial_value[49:44]  =  6'b0;	
	    assign  initial_value[53:50]  =  year_l_bcd;  
		assign  initial_value[54]     =  1'b0;	
	    assign  initial_value[58:55]  =  year_h_bcd[3:0];       
	    assign  initial_value[79:59]  =  21'b0;     
	    assign  initial_value[88:80]  =  second_day[8:0];
		assign  initial_value[89]     =  1'b0;
	    assign  initial_value[97:90]  =  second_day[16:9];
		assign  initial_value[99:98]  =  2'b0;	

always @(posedge clk or negedge _rst) begin 
			if(!_rst)	
				out_buf <= 100'd0;			   
            else if(syn_1pps_1clk)//////////////////////syn_1pps_1clk///////////////////////by yang	
			    	out_buf <= initial_value;
			else if(pwm_counter==20'd499999)                         //10ms移位一次
					out_buf <= {1'b0, out_buf[99:1]};				
		end
		
  		assign out_reg =  out_buf[0];



always @(posedge clk  or negedge _rst)	
begin
			if(!_rst)
				cnt_time<=0;
			else if(syn_1pps_1clk)
				cnt_time<=0;
			else if(cnt_time==7'd99&&pwm_counter==20'd499999)   //10ms *100 = 1s
				cnt_time<=0;
			else if(pwm_counter==20'd499999)	
				cnt_time<=cnt_time+6'b1;		
end


always @(posedge clk or negedge _rst)	
begin
			if(!_rst)
				out_P<=1'b0;
			else if(!syn_1pps_1clk)
				case(cnt_time)
				7'd0 :out_P  <=1'b1;
				7'd9 :out_P  <=1'b1;
				7'd19:out_P  <=1'b1;
				7'd29:out_P  <=1'b1;
				7'd39:out_P  <=1'b1;
				7'd49:out_P  <=1'b1;
				7'd59:out_P  <=1'b1;
				7'd69:out_P  <=1'b1;
				7'd79:out_P  <=1'b1;
				7'd89:out_P  <=1'b1;
				7'd99:out_P  <=1'b1;
				default:out_P<=0;
				endcase
end




//generate 2ms,5ms,8ms pluse and output
always @(posedge clk or negedge _rst)	
begin   //10ms pulse
			if(!_rst)	
				pwm_counter<=0;
			else if(syn_1pps_1clk)	
					pwm_counter<=0;				
		    else if(pwm_counter>=20'd499999)	
					pwm_counter<=0;
			else
					pwm_counter<=pwm_counter+20'd1;    	
end	
		
always @(posedge clk or negedge _rst)	
begin
			if(!_rst)		
				out<=1'b0;
			else  begin				
					if(!out_P&&out_reg)	begin         //5ms pulse 表示 1
					   if(pwm_counter>=20'd250000)
							out<=1'b0;
				       else
				            out<=1'b1;
					end
					else if(!out_P&&!out_reg)	begin  //2ms pulse 表示 0
						if(pwm_counter>=20'd100000)
							out<=1'b0;
				        else
				            out<=1'b1;
					end
					else if(out_P)	begin
						if(pwm_counter>=20'd400000)     //8ms pulse 表示位置索引
							out<=1'b0;
				        else
				            out<=1'b1;
					end				
			end
end	


always @(posedge clk or negedge _rst)  begin
			if (!_rst) 
				cnt_clk10M<=0;
		
			else begin
				if(pps)
				 	cnt_clk10M<=cnt_clk10M+28'd1;
				else
					cnt_clk10M<=0;
			end
		end
		
always @(posedge clk or negedge _rst)  begin
			if (!_rst) 
				syn_1pps_1clk<=0;
			else begin
				if(cnt_clk10M==0)	 
					syn_1pps_1clk<=0;
				else if(cnt_clk10M==28'd1398357)
					syn_1pps_1clk<=1;	
				else if(cnt_clk10M==28'd1398358)
					syn_1pps_1clk<=0;
				else
					syn_1pps_1clk<=syn_1pps_1clk;
			end
		end






endmodule