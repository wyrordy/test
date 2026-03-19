//********私有协议A:protocolA
//********私有协议B:protocolB
//********私有协议C:protocolC
//********私有协议D:protocolD
//********私有协议4:protocol4
//********私有协议5:protocol5
//********私有协议6:protocol6
//********私有协议7:protocol7
module  csmux7_cpld1(
		input clk_25m, //40ns 
		input reset,
		//主控板卡号：1：5主控1，0：6主控2
		input main_present,
		input another_main_present,  //0：另一个板卡在位（1.0没有这个脚）
		//逻辑间通信
		output cpld1_tx_clk,cpld1_tx_data,
		input cpld2_rx_clk,cpld2_rx_data,
		//主控间通信
		output cputocpu_clk_tx,cputocpu_data_tx,
		input cputocpu_clk_rx,cputocpu_data_rx,
		//主控与逻辑间通信
		input cpu_tx_clk1,cpu_tx_data1,cpu_tx_clk2,cpu_tx_data2,
		output cpu_rx_clk1,cpu_rx_data1,cpu_rx_clk2,cpu_rx_data2,
		//业务板卡间通信
		output c1_tx_clk,c2_tx_clk,c3_tx_clk,c4_tx_clk,c5_tx_clk,c6_tx_clk,c7_tx_clk,c8_tx_clk,
		output c1_tx_data,c2_tx_data,c3_tx_data,c4_tx_data,c5_tx_data,c6_tx_data,c7_tx_data,c8_tx_data,
		input c1_rx_clk,c2_rx_clk,c3_rx_clk,c4_rx_clk,c5_rx_clk,c6_rx_clk,c7_rx_clk,c8_rx_clk,
		input c1_rx_data,c2_rx_data,c3_rx_data,c4_rx_data,c5_rx_data,c6_rx_data,c7_rx_data,c8_rx_data,
		//电源通信
		input power1_clk,power1_data,power2_clk,power2_data,
		//风扇控制
		output fan1_clt,fan2_clt,fan3_clt,fan4_clt,fan5_clt,fan6_clt,
		output fan1_speed,fan2_speed,fan3_speed,fan4_speed,fan5_speed,fan6_speed,
		input fan1_detec,fan2_detec,fan3_detec,fan4_detec,fan5_detec,fan6_detec,
		//板卡在位信号
		input fan_panel_detec,anoth_main_present,x1_present,x2_present,x3_present,x4_present,x5_present,x6_present,x7_present,power1_present,power2_present,
		//其他
		output sfp0_tx_power,sfp1_tx_power,sfp2_tx_power,sfp3_tx_power,sfp4_tx_power,sfp5_tx_power,sfp6_tx_power,sfp7_tx_power,qsfp1_tx_power,
		output pin60,pin55,
		input pannel_new_detec0  //背板接地用来检测版本，主控1.4，背板1.2版本才,默认1，插上位0
	  );
	//assign pin55 = another_main_reset_temp;
	//assign pin60 = another_main_reset;
//********上电产生10us时钟********//	
	reg [6:0] num_clk_10us = 0;
	reg        clk_10us = 1'b0;	
	always@(posedge clk_25m) begin
		if(num_clk_10us<124) begin   //数数-1
			num_clk_10us<=num_clk_10us+1;
		end
		else begin
			clk_10us<= ~ clk_10us;
			num_clk_10us<=0;
		end
	end	
//********上电产生50us时钟********//	
	reg [9:0] num_clk_50us = 0;
	reg        clk_50us = 1'b0;	
	always@(posedge clk_25m) begin
		if(num_clk_50us<624) begin   //数数-1
			num_clk_50us<=num_clk_50us+1;
		end
		else begin
			clk_50us<= ~ clk_50us;
			num_clk_50us<=0;
		end
	end	
//********上电产生250us时钟********//	
	reg [11:0] num_clk_250us = 0;
	reg        clk_250us = 1'b0;
	always@(posedge clk_25m) begin
		if(num_clk_250us<3124) begin   //数数-1
			num_clk_250us<=num_clk_250us+1;
		end
		else begin
			clk_250us<= ~ clk_250us;
			num_clk_250us<=0;
		end
	end
//********上电产生1ms时钟,用于发送私有协议********//		
	reg [13:0] num_clk_1ms = 0;
	reg        clk_1ms = 1'b0;
	always@(posedge clk_25m) begin
		if(num_clk_1ms<12499) begin   //数数-1
			num_clk_1ms<=num_clk_1ms+1;
		end
		else begin
			clk_1ms<= ~ clk_1ms;
			num_clk_1ms<=0;
		end
	end
//********上电产生10ms时钟********//	
	reg [16:0] num_clk_10ms = 0;
	reg        clk_10ms = 1'b0;
	always@(posedge clk_25m) begin
		if(num_clk_10ms<124999) begin   //数数-1
			num_clk_10ms<=num_clk_10ms+1;
		end
		else begin
			clk_10ms<= ~ clk_10ms;
			num_clk_10ms<=0;
		end
	end	
//********上电2s保持为0********//	
	reg [7:0] power_up_num = 0;
	reg		  power_up_temp	= 1'b0;
	always@(posedge clk_10ms) begin
		if(power_up_num<200) begin
			power_up_num<=power_up_num+1;
			power_up_temp<=1'b0;
		end
		else begin
			power_up_temp<=1'b1;
		end
	end
			
//********复位控制********//	
	wire reset_temp;
	assign reset_temp = reset & reset_power;
	//assign reset_temp = reset;
//********私有协议A，逻辑之间通信：发送 时钟周期200us，间隔2ms不停发，TX********//
	wire [131:0] cpld1_tx_clk_temp;
	wire [131:0] cpld1_tx_data_temp;
	reg  [8:0]   cpld1_tx_data_num; 
	reg          cpld1_tx_data;
	reg          cpld1_tx_clk;

	always@(posedge clk_50us or negedge reset_temp) begin
		if(!reset_temp) begin
			cpld1_tx_data_num<=0;
			cpld1_tx_clk<=1'b0;
			cpld1_tx_data<=1'b0;
		end
		else begin
			if(cpld1_tx_data_num<132) begin  //  产生串行时钟数据
				cpld1_tx_clk<= cpld1_tx_clk_temp[cpld1_tx_data_num];
				cpld1_tx_data<= cpld1_tx_data_temp[cpld1_tx_data_num];
				cpld1_tx_data_num<=cpld1_tx_data_num+1;
			end
				else if(cpld1_tx_data_num<172) begin  
					cpld1_tx_clk<=1'b0;
					cpld1_tx_data<= 1'b0;
					cpld1_tx_data_num<=cpld1_tx_data_num+1;
				end
				else begin   //间隔2ms不间断发
					cpld1_tx_data_num<=0;
				end
		end
	end
	//串行时钟
	assign cpld1_tx_clk_temp = {2'b00,{32{4'b1100}},2'b00};
	//串行数据
	assign cpld1_tx_data_temp[131:130] = 2'b0;
	assign cpld1_tx_data_temp[129:126] = {1'b1,1'b1,1'b1,1'b1};
	assign cpld1_tx_data_temp[125:122] = {1'b1,1'b1,1'b1,1'b1};
	assign cpld1_tx_data_temp[121:118] = {1'b1,1'b1,1'b1,1'b1};
	assign cpld1_tx_data_temp[117:114] = {1'b1,1'b1,1'b1,1'b1};
	assign cpld1_tx_data_temp[113:110] = {1'b1,1'b1,1'b1,1'b1};
	assign cpld1_tx_data_temp[109:106] = {1'b1,1'b1,1'b1,1'b1};
	assign cpld1_tx_data_temp[105:102] = {1'b1,1'b1,1'b1,1'b1};
	assign cpld1_tx_data_temp[101:98]  = {1'b1,1'b1,1'b1,1'b1};
	assign cpld1_tx_data_temp[97:94]   = {1'b1,1'b1,1'b1,1'b1};
	assign cpld1_tx_data_temp[93:90]   = {1'b1,1'b1,1'b1,1'b1};
	assign cpld1_tx_data_temp[89:86]   = {1'b1,1'b1,1'b1,1'b1};
	assign cpld1_tx_data_temp[85:82]   = {1'b1,1'b1,1'b1,1'b1};
	assign cpld1_tx_data_temp[81:78]   = {1'b1,1'b1,1'b1,1'b1};
	assign cpld1_tx_data_temp[77:74]   = {1'b1,1'b1,1'b1,1'b1};
	assign cpld1_tx_data_temp[73:70]   = {1'b1,1'b1,1'b1,1'b1};
	assign cpld1_tx_data_temp[69:66]   = {1'b1,1'b1,1'b1,1'b1};
	assign cpld1_tx_data_temp[65:62]   = {1'b1,1'b1,1'b1,1'b1};
	assign cpld1_tx_data_temp[61:58]   = {1'b1,1'b1,1'b1,1'b1};
	assign cpld1_tx_data_temp[57:54]   = {1'b1,1'b1,1'b1,1'b1};
	assign cpld1_tx_data_temp[53:50]   = {1'b1,1'b1,1'b1,1'b1};
	assign cpld1_tx_data_temp[49:46]   = {1'b1,1'b1,1'b1,1'b1};
	assign cpld1_tx_data_temp[45:42]   = {1'b1,1'b1,1'b1,1'b1};
	assign cpld1_tx_data_temp[41:38]   = {1'b1,1'b1,1'b1,1'b1};
	assign cpld1_tx_data_temp[37:34]   = {1'b1,1'b1,1'b1,1'b1};
	assign cpld1_tx_data_temp[33:30]   = {1'b1,1'b1,1'b1,1'b1};
	assign cpld1_tx_data_temp[29:26]   = {pannel_new_detec0,pannel_new_detec0,pannel_new_detec0,pannel_new_detec0};
	assign cpld1_tx_data_temp[25:22]   = {main_present,main_present,main_present,main_present};
	assign cpld1_tx_data_temp[21:18]   = {another_main_bootmode_ctl[0],another_main_bootmode_ctl[0],another_main_bootmode_ctl[0],another_main_bootmode_ctl[0]};
	assign cpld1_tx_data_temp[17:14]   = {another_main_bootmode_ctl[1],another_main_bootmode_ctl[1],another_main_bootmode_ctl[1],another_main_bootmode_ctl[1]};
	assign cpld1_tx_data_temp[13:10]   = {another_main_reset_ctl,another_main_reset_ctl,another_main_reset_ctl,another_main_reset_ctl};
	assign cpld1_tx_data_temp[9:6]     = {another_main_power_ctl,another_main_power_ctl,another_main_power_ctl,another_main_power_ctl};
	assign cpld1_tx_data_temp[5:2]     = {1'b1,1'b1,1'b1,1'b1}; //第一位上电时候会高
	assign cpld1_tx_data_temp[1:0]     = 2'b0;
//********私有协议B，逻辑间通信：接收RX********//
	reg [4:0]  cpld2_rx_data_clear_num;
	reg        cpld2_rx_data_clear;
	reg [31:0] cpld2_rx_data_temp;
	reg [5:0]  cpld2_rx_data_num;
	wire       board_reset_all;
	wire       board_power_all;
	wire		reset_power;
	//清0标识，0清0
	always@(posedge clk_50us or negedge reset_temp) begin  //私有协议清0标志
		if(!reset_temp) begin
			cpld2_rx_data_clear<=1'b1;
			cpld2_rx_data_clear_num<=0;
		end
		else begin
			if(cpld2_rx_clk) begin
				cpld2_rx_data_clear<=1'b1;
				cpld2_rx_data_clear_num<=0;
			end
				else if(cpld2_rx_data_clear_num<10) begin  //500us等待时间
					cpld2_rx_data_clear_num<=cpld2_rx_data_clear_num+1;
					cpld2_rx_data_clear<=1'b1;
				end
					else if(cpld2_rx_data_clear_num<20) begin
						cpld2_rx_data_clear_num<=cpld2_rx_data_clear_num+1;
						cpld2_rx_data_clear<=1'b0;  //私有协议清0标志，0清0,持续500us
					end
					else begin
						cpld2_rx_data_clear<=1'b1;
					end
		end
	end
	//读取串行信号
	always@(posedge cpld2_rx_clk or negedge reset_temp or negedge cpld2_rx_data_clear) begin
		if(!reset_temp) begin
			//cpld2_rx_data_temp<=32'b11111111111111111111111111110110; //左31→0，顺序别错
			cpld2_rx_data_temp<=32'b11111111111111111111111111111110; //左31→0，顺序别错
			cpld2_rx_data_num<=0;
		end
		else begin
			if(!cpld2_rx_data_clear) begin
				cpld2_rx_data_num<=0;
			end
				else if(cpld2_rx_data_num<31) begin
					cpld2_rx_data_temp[cpld2_rx_data_num]<=cpld2_rx_data;
					cpld2_rx_data_num<=cpld2_rx_data_num+1;
				end
					else begin
						cpld2_rx_data_temp[cpld2_rx_data_num]<=cpld2_rx_data;
						cpld2_rx_data_num<=0;
					end
		end
	end
	assign board_reset_all =cpld2_rx_data_temp[1];  //控制整个机框进行复位，0复位，1正常
	assign board_power_all =cpld2_rx_data_temp[2];  //控制整个机框进行断电，0断电，1正常
	assign reset_power =cpld2_rx_data_temp[3]?1'b1:1'b0;
//********私有协议C 主控间通信：发送TX，发给另一个主控，时钟周期1ms，间隔10ms不停发********//
	wire [131:0] cputocpu_clk_tx_temp;
	wire [131:0] cputocpu_data_tx_temp;
	reg  [8:0]   cputocpu_data_tx_num; 
	reg          cputocpu_clk_tx;
	reg          cputocpu_data_tx;

	always@(posedge clk_250us or negedge reset or negedge power_up_temp) begin
		if((reset==1'b0) || (power_up_temp==1'b0)) begin
			cputocpu_data_tx_num<=0;
			cputocpu_clk_tx<=1'b0;
			cputocpu_data_tx<=1'b0;
		end
		else begin
			if(cputocpu_data_tx_num<132) begin  //  产生串行时钟数据
				cputocpu_clk_tx<= cputocpu_clk_tx_temp[cputocpu_data_tx_num];
				cputocpu_data_tx<= cputocpu_data_tx_temp[cputocpu_data_tx_num];
				cputocpu_data_tx_num<=cputocpu_data_tx_num+1;
			end
				else if(cputocpu_data_tx_num<172) begin  
					cputocpu_clk_tx<=1'b0;
					cputocpu_data_tx<= 1'b0;
					cputocpu_data_tx_num<=cputocpu_data_tx_num+1;
				end
				else begin   //间隔10ms不停发
					cputocpu_data_tx_num<=0;
				end
		end
	end
	//串行时钟
	assign cputocpu_clk_tx_temp = {2'b00,{32{4'b1100}},2'b00};
	//串行数据
	assign cputocpu_data_tx_temp[131:130] = 2'b0;
	assign cputocpu_data_tx_temp[129:126] = {1'b1,1'b1,1'b1,1'b1};
	assign cputocpu_data_tx_temp[125:122] = {1'b1,1'b1,1'b1,1'b1};
	assign cputocpu_data_tx_temp[121:118] = {1'b1,1'b1,1'b1,1'b1};
	assign cputocpu_data_tx_temp[117:114] = {1'b1,1'b1,1'b1,1'b1};
	assign cputocpu_data_tx_temp[113:110] = {1'b1,1'b1,1'b1,1'b1};
	assign cputocpu_data_tx_temp[109:106] = {1'b1,1'b1,1'b1,1'b1};
	assign cputocpu_data_tx_temp[105:102] = {1'b1,1'b1,1'b1,1'b1};
	assign cputocpu_data_tx_temp[101:98]  = {1'b1,1'b1,1'b1,1'b1};
	assign cputocpu_data_tx_temp[97:94]   = {1'b1,1'b1,1'b1,1'b1};
	assign cputocpu_data_tx_temp[93:90]   = {1'b1,1'b1,1'b1,1'b1};
	assign cputocpu_data_tx_temp[89:86]   = {1'b1,1'b1,1'b1,1'b1};
	assign cputocpu_data_tx_temp[85:82]   = {1'b1,1'b1,1'b1,1'b1};
	assign cputocpu_data_tx_temp[81:78]   = {1'b1,1'b1,1'b1,1'b1};
	assign cputocpu_data_tx_temp[77:74]   = {1'b1,1'b1,1'b1,1'b1};
	assign cputocpu_data_tx_temp[73:70]   = {1'b1,1'b1,1'b1,1'b1};
	assign cputocpu_data_tx_temp[69:66]   = {1'b1,1'b1,1'b1,1'b1};
	assign cputocpu_data_tx_temp[65:62]   = {1'b1,1'b1,1'b1,1'b1};
	assign cputocpu_data_tx_temp[61:58]   = {1'b1,1'b1,1'b1,1'b1};
	assign cputocpu_data_tx_temp[57:54]   = {1'b1,1'b1,1'b1,1'b1};
	assign cputocpu_data_tx_temp[53:50]   = {1'b1,1'b1,1'b1,1'b1};
	assign cputocpu_data_tx_temp[49:46]   = {1'b1,1'b1,1'b1,1'b1};
	assign cputocpu_data_tx_temp[45:42]   = {1'b1,1'b1,1'b1,1'b1};
	assign cputocpu_data_tx_temp[41:38]   = {1'b1,1'b1,1'b1,1'b1};
	assign cputocpu_data_tx_temp[37:34]   = {1'b0,1'b0,1'b0,1'b0};
	assign cputocpu_data_tx_temp[33:30]   = {1'b1,1'b1,1'b1,1'b1};
	assign cputocpu_data_tx_temp[29:26]   = {1'b1,1'b1,1'b1,1'b1};
	assign cputocpu_data_tx_temp[25:22]   = {another_main_bootmode[0],another_main_bootmode[0],another_main_bootmode[0],another_main_bootmode[0]};
	assign cputocpu_data_tx_temp[21:18]   = {another_main_bootmode[1],another_main_bootmode[1],another_main_bootmode[1],another_main_bootmode[1]};
	assign cputocpu_data_tx_temp[17:14]   = {another_main_reset,another_main_reset,another_main_reset,another_main_reset};
	assign cputocpu_data_tx_temp[13:10]   = {another_main_power,another_main_power,another_main_power,another_main_power};
	assign cputocpu_data_tx_temp[9:6]     = {main_present,main_present,main_present,main_present};
	assign cputocpu_data_tx_temp[5:2]     = {1'b1,1'b1,1'b1,1'b1};  //需要不在位的时候清0.
	assign cputocpu_data_tx_temp[1:0]     = 2'b0;
//********私有协议D,主控间通信：接收来自另一个主控得控制信号********//
	reg [4:0]  cputocpu_data_rx_clear_num;
	reg        cputocpu_data_rx_clear;
	reg [7:0] cputocpu_data_rx_timeout_num;
	reg        cputocpu_data_rx_timeout;
	reg [31:0] cputocpu_data_rx_temp;
	reg [5:0]  cputocpu_data_rx_num;
	reg       another_main_power_ctl;  //另外板对本板卡控制电源
	reg       another_main_reset_ctl;  //另外板对本板卡控制复位
	reg [1:0] another_main_bootmode_ctl;  //另外板对本板卡控制启动模式
	wire        cputocpu_data_end;
	//清0标识，0清0
	always@(posedge clk_250us or negedge reset) begin  //私有协议清0标志
		if(!reset) begin
			cputocpu_data_rx_clear<=1'b1;
			cputocpu_data_rx_clear_num<=0;
		end
		else begin
			if(cputocpu_clk_rx) begin
				cputocpu_data_rx_clear<=1'b1;
				cputocpu_data_rx_clear_num<=0;
			end
				else if(cputocpu_data_rx_clear_num<20) begin  //5ms等待时间
					cputocpu_data_rx_clear_num<=cputocpu_data_rx_clear_num+1;
					cputocpu_data_rx_clear<=1'b1;
				end
					else if(cputocpu_data_rx_clear_num<30) begin
						cputocpu_data_rx_clear_num<=cputocpu_data_rx_clear_num+1;
						cputocpu_data_rx_clear<=1'b0;  //私有协议清0标志，0清0,持续2.5ms
					end
					else begin
						cputocpu_data_rx_clear<=1'b1;
					end
		end
	end
	//读取串行信号
	always@(posedge cputocpu_clk_rx or negedge reset or negedge cputocpu_data_rx_clear) begin
		if(!reset) begin
			cputocpu_data_rx_temp<=32'b11111111111111111111111111110100;
			cputocpu_data_rx_num<=0;
		end
		else begin
			if(!cputocpu_data_rx_clear) begin
				cputocpu_data_rx_num<=0;
				cputocpu_data_rx_temp[31]<=1'b0;  //1持续5ms
			end
				else if(cputocpu_data_rx_num<31) begin
					cputocpu_data_rx_temp[cputocpu_data_rx_num]<=cputocpu_data_rx;
					cputocpu_data_rx_num<=cputocpu_data_rx_num+1;
				end
					else begin
						cputocpu_data_rx_temp[cputocpu_data_rx_num]<=cputocpu_data_rx;
						cputocpu_data_rx_num<=0;
					end
		end
	end
	//默认没接板卡时候another_main_present:1,接板卡为0
	assign cputocpu_data_end = cputocpu_data_rx_temp[31];
	always@(*) begin
		if(!reset) begin
			another_main_power_ctl=1'b1;
			another_main_reset_ctl=1'b0;
			another_main_bootmode_ctl[1]=1'b1;
			another_main_bootmode_ctl[0]=1'b1;
		end
		else if(cputocpu_data_end) begin
			another_main_power_ctl=cputocpu_data_rx_temp[2];
			another_main_reset_ctl=cputocpu_data_rx_temp[3];
			another_main_bootmode_ctl[1]=cputocpu_data_rx_temp[4];
			another_main_bootmode_ctl[0]=cputocpu_data_rx_temp[5];
		end
	end
	/*assign another_main_power_ctl = another_main_present? 1'b1:cputocpu_data_rx_temp[2];
	assign another_main_reset_ctl = another_main_present? 1'b0:cputocpu_data_rx_temp[3];
	assign another_main_bootmode_ctl[1] = another_main_present? 1'b1:cputocpu_data_rx_temp[4];
	assign another_main_bootmode_ctl[0] = another_main_present? 1'b1:cputocpu_data_rx_temp[5];*/

//********私有协议4：cpu to cpld1********//
	reg [8:0]  cpu_tx_data1_clear_num;
	reg        cpu_tx_data1_clear;
	reg [31:0] cpu_tx_data1_temp;
	reg [5:0]  cpu_tx_data1_num;
	reg [4:0] channel_switch;
	reg       another_main_power = 1'b1;  //控制另外板卡电源，倒换概率发0，新改
	wire       another_main_reset_temp;  //控制另外板卡复位，倒换概率发0，新改
	reg [1:0] another_main_bootmode = 2'b11;  //控制另外板卡启动模式，倒换概率发0，新改
	wire        qsfp1_tx_power;
	wire        sfp0_tx_power;
	wire        sfp1_tx_power;
	wire        sfp2_tx_power;
	wire        sfp3_tx_power;
	wire        sfp4_tx_power;
	wire        sfp5_tx_power;
	wire        sfp6_tx_power;
	wire        sfp7_tx_power;
	//清0标识，0清0
	always@(posedge clk_50us or negedge reset_temp) begin  //私有协议清0标志
		if(!reset_temp) begin
			cpu_tx_data1_clear<=1'b1;
			cpu_tx_data1_clear_num<=0;
		end
		else begin
			if(cpu_tx_clk1) begin
				cpu_tx_data1_clear_num<=0;
				cpu_tx_data1_clear<=1'b1;
			end
				else if(cpu_tx_data1_clear_num<400) begin  //20ms等待时间，给cpu忙时候反应时间
					cpu_tx_data1_clear_num<=cpu_tx_data1_clear_num+1;
					cpu_tx_data1_clear<=1'b1;
				end
					else if(cpu_tx_data1_clear_num<440) begin
						cpu_tx_data1_clear_num<=cpu_tx_data1_clear_num+1;
						cpu_tx_data1_clear<=1'b0;  //私有协议清0标志，0清0,持续2ms
					end
					else begin
						cpu_tx_data1_clear<=1'b1;
					end
		end
	end
	//读取串行信号
	always@(posedge cpu_tx_clk1 or negedge reset_temp or negedge cpu_tx_data1_clear) begin
		if(!reset_temp) begin
			cpu_tx_data1_temp<=32'b11111111111111101111111111000000;  //启动默认状态
			cpu_tx_data1_num<=0;
		end
		else begin
			if(!cpu_tx_data1_clear) begin
				cpu_tx_data1_num<=0;
				cpu_tx_data1_temp[16]<=1'b0;
				cpu_tx_data1_temp[19]<=1'b0;
			end
				else if(cpu_tx_data1_num<31) begin
					cpu_tx_data1_temp[cpu_tx_data1_num]<=cpu_tx_data1;
					cpu_tx_data1_num<=cpu_tx_data1_num+1;
				end
					else begin
						cpu_tx_data1_temp[cpu_tx_data1_num]<=cpu_tx_data1;
						cpu_tx_data1_num<=0;
					end
		end
	end
	assign another_main_reset_temp = cpu_tx_data1_temp[16]; //正常0，复位1
	//assign channel_switch[4] = cpu_tx_data1_temp[0];
	//assign channel_switch[3] = cpu_tx_data1_temp[1];
	//assign channel_switch[2] = cpu_tx_data1_temp[2];
	//assign channel_switch[1] = cpu_tx_data1_temp[3];
	//assign channel_switch[0] = cpu_tx_data1_temp[4];
	assign qsfp1_tx_power = ~ cpu_tx_data1_temp[6];  //0开1关
	assign sfp0_tx_power = ~ cpu_tx_data1_temp[7];
	assign sfp1_tx_power = ~ cpu_tx_data1_temp[8];
	assign sfp2_tx_power = ~ cpu_tx_data1_temp[9];
	assign sfp3_tx_power = ~ cpu_tx_data1_temp[10];
	assign sfp4_tx_power = ~ cpu_tx_data1_temp[11];
	assign sfp5_tx_power = ~ cpu_tx_data1_temp[12];
	assign sfp6_tx_power = ~ cpu_tx_data1_temp[13];
	assign sfp7_tx_power = ~ cpu_tx_data1_temp[14];
	//assign another_main_power = cpu_tx_data1_temp[15];
	//assign another_main_bootmode[1] = cpu_tx_data1_temp[17];
	//assign another_main_bootmode[0] = cpu_tx_data1_temp[18];
	//接收完毕再赋值
	always@(negedge cpu_tx_clk1) begin //注意这里不会恢复位0，要等下一个数据位
		if(cpu_tx_data1_temp[19]) begin
			channel_switch[4] <= cpu_tx_data1_temp[0];
			channel_switch[3] <= cpu_tx_data1_temp[1];
			channel_switch[2] <= cpu_tx_data1_temp[2];
			channel_switch[1] <= cpu_tx_data1_temp[3];
			channel_switch[0] <= cpu_tx_data1_temp[4];
			another_main_power = cpu_tx_data1_temp[15];
			//another_main_reset_temp = cpu_tx_data1_temp[16]; //注意这里不会恢复位0，要等下一个数据位
			another_main_bootmode[1] = cpu_tx_data1_temp[17];
			another_main_bootmode[0] = cpu_tx_data1_temp[18];
		end
	end
	//另外板卡控制复位，2ms周期不够看门狗喂狗，延时1s下发让另一个主板延后复位，保持2s触发复位
	reg [12:0]	another_main_reset_num = 8000;
	reg			another_main_reset = 1'b0;  //需要保持2s为0，给看门狗时间
	
	always@(posedge clk_250us or negedge reset_temp) begin
		if(!reset_temp) begin
			another_main_reset_num = 8000;
			another_main_reset<=1'b0;
		end
		else if(another_main_reset_temp==1'b1) begin  //持续2ms为1（看软件），复位
			another_main_reset_num<=0;
			another_main_reset<=1'b1;
		end
			else if(another_main_reset_num<8000) begin //为1保持2s,
				another_main_reset_num<=another_main_reset_num+1;
				another_main_reset<=1'b1;
			end
				else begin
					another_main_reset<=1'b0;
				end
	end	
//发送通道切换
	reg		fan_tx_clk;
	reg		fan_tx_data;
	reg		c1_tx_clk;
	reg		c1_tx_data;
	reg		c2_tx_clk;
	reg		c2_tx_data;
	reg		c3_tx_clk;
	reg		c3_tx_data;
	reg		c4_tx_clk;
	reg		c4_tx_data;
	reg		c5_tx_clk;
	reg		c5_tx_data;
	reg		c6_tx_clk;
	reg		c6_tx_data;
	reg		c7_tx_clk;
	reg		c7_tx_data;
	reg		c8_tx_clk;
	reg		c8_tx_data;
	reg		power1_tx_clk;
	reg		power1_tx_data;
	reg		power2_tx_clk;
	reg		power2_tx_data;
	wire	allboard_tx_temp;
	//接收通道
	reg		cpu_rx_clk2;
	reg		cpu_rx_data2;
	reg		fan_rx_clk;
	reg		fan_rx_data;
	reg		power1_rx_clk;
	reg		power1_rx_data;
	reg		power2_rx_clk;
	reg		power2_rx_data;
	assign allboard_tx_temp = board_reset_all & board_power_all; //有一个为0即触发
	
	always@(*) begin
		if(!allboard_tx_temp) begin
			//1：x1
			c1_tx_clk=allboard_clk_tx;
			c1_tx_data=allboard_data_tx;
			//2：x2
			c2_tx_clk=allboard_clk_tx;
			c2_tx_data=allboard_data_tx;
			//3：x3
			c3_tx_clk=allboard_clk_tx;
			c3_tx_data=allboard_data_tx;
			//4：x4
			c4_tx_clk=allboard_clk_tx;
			c4_tx_data=allboard_data_tx;
			//7：x7
			c5_tx_clk=allboard_clk_tx;
			c5_tx_data=allboard_data_tx;
			//8：x8
			c6_tx_clk=allboard_clk_tx;
			c6_tx_data=allboard_data_tx;
			//9:x9
			c7_tx_clk=allboard_clk_tx;
			c7_tx_data=allboard_data_tx;
			//10:reserve
			c8_tx_clk=allboard_clk_tx;
			c8_tx_data=allboard_data_tx;
		end
		else begin
			case(channel_switch)
				5'b00000:begin  //0：风扇
					fan_tx_clk=cpu_tx_clk2;
					fan_tx_data=cpu_tx_data2;
					cpu_rx_clk2=fan_rx_clk;
					cpu_rx_data2=fan_rx_data;
					c1_tx_clk=1'b0;
					c1_tx_data=1'b0;
					c2_tx_clk=1'b0;
					c2_tx_data=1'b0;
					c3_tx_clk=1'b0;
					c3_tx_data=1'b0;
					c4_tx_clk=1'b0;
					c4_tx_data=1'b0;
					c5_tx_clk=1'b0;
					c5_tx_data=1'b0;
					c6_tx_clk=1'b0;
					c6_tx_data=1'b0;
					c7_tx_clk=1'b0;
					c7_tx_data=1'b0;
					c8_tx_clk=1'b0;
					c8_tx_data=1'b0;
					power1_tx_clk=1'b0;
					power1_tx_data=1'b0;
					power2_tx_clk=1'b0;
					power2_tx_data=1'b0;
				end
				5'b00001:begin  //1：x1
					c1_tx_clk=cpu_tx_clk2;
					c1_tx_data=cpu_tx_data2;
					cpu_rx_clk2=c1_rx_clk;
					cpu_rx_data2=c1_rx_data;
					fan_tx_clk=1'b0;;
					fan_tx_data=1'b0;;
					c2_tx_clk=1'b0;
					c2_tx_data=1'b0;
					c3_tx_clk=1'b0;
					c3_tx_data=1'b0;
					c4_tx_clk=1'b0;
					c4_tx_data=1'b0;
					c5_tx_clk=1'b0;
					c5_tx_data=1'b0;
					c6_tx_clk=1'b0;
					c6_tx_data=1'b0;
					c7_tx_clk=1'b0;
					c7_tx_data=1'b0;
					c8_tx_clk=1'b0;
					c8_tx_data=1'b0;
					power1_tx_clk=1'b0;
					power1_tx_data=1'b0;
					power2_tx_clk=1'b0;
					power2_tx_data=1'b0;
				end
				5'b00010:begin  //2：x2
					c2_tx_clk=cpu_tx_clk2;
					c2_tx_data=cpu_tx_data2;
					cpu_rx_clk2=c2_rx_clk;
					cpu_rx_data2=c2_rx_data;
					fan_tx_clk=1'b0;;
					fan_tx_data=1'b0;;
					c1_tx_clk=1'b0;
					c1_tx_data=1'b0;
					c3_tx_clk=1'b0;
					c3_tx_data=1'b0;
					c4_tx_clk=1'b0;
					c4_tx_data=1'b0;
					c5_tx_clk=1'b0;
					c5_tx_data=1'b0;
					c6_tx_clk=1'b0;
					c6_tx_data=1'b0;
					c7_tx_clk=1'b0;
					c7_tx_data=1'b0;
					c8_tx_clk=1'b0;
					c8_tx_data=1'b0;
					power1_tx_clk=1'b0;
					power1_tx_data=1'b0;
					power2_tx_clk=1'b0;
					power2_tx_data=1'b0;
				end
				5'b00011:begin  //3：x3
					c3_tx_clk=cpu_tx_clk2;
					c3_tx_data=cpu_tx_data2;
					cpu_rx_clk2=c3_rx_clk;
					cpu_rx_data2=c3_rx_data;
					fan_tx_clk=1'b0;;
					fan_tx_data=1'b0;;
					c1_tx_clk=1'b0;
					c1_tx_data=1'b0;
					c2_tx_clk=1'b0;
					c2_tx_data=1'b0;
					c4_tx_clk=1'b0;
					c4_tx_data=1'b0;
					c5_tx_clk=1'b0;
					c5_tx_data=1'b0;
					c6_tx_clk=1'b0;
					c6_tx_data=1'b0;
					c7_tx_clk=1'b0;
					c7_tx_data=1'b0;
					c8_tx_clk=1'b0;
					c8_tx_data=1'b0;
					power1_tx_clk=1'b0;
					power1_tx_data=1'b0;
					power2_tx_clk=1'b0;
					power2_tx_data=1'b0;	
				end
				5'b00100:begin  //4：x4
					c4_tx_clk=cpu_tx_clk2;
					c4_tx_data=cpu_tx_data2;
					cpu_rx_clk2=c4_rx_clk;
					cpu_rx_data2=c4_rx_data;
					fan_tx_clk=1'b0;;
					fan_tx_data=1'b0;;
					c1_tx_clk=1'b0;
					c1_tx_data=1'b0;
					c2_tx_clk=1'b0;
					c2_tx_data=1'b0;
					c3_tx_clk=1'b0;
					c3_tx_data=1'b0;
					c5_tx_clk=1'b0;
					c5_tx_data=1'b0;
					c6_tx_clk=1'b0;
					c6_tx_data=1'b0;
					c7_tx_clk=1'b0;
					c7_tx_data=1'b0;
					c8_tx_clk=1'b0;
					c8_tx_data=1'b0;
					power1_tx_clk=1'b0;
					power1_tx_data=1'b0;
					power2_tx_clk=1'b0;
					power2_tx_data=1'b0;
				end
				5'b00101:begin  //5：主控1
					//c5_tx_clk=channel_tx_clk;
					//c5_tx_data=channel_tx_data;
				end
				5'b00110:begin  //6：主控2
					//c6_tx_clk=channel_tx_clk;
					//c6_tx_data=channel_tx_data;
				end
				5'b00111:begin  //7：x7
					c5_tx_clk=cpu_tx_clk2;
					c5_tx_data=cpu_tx_data2;
					cpu_rx_clk2=c5_rx_clk;
					cpu_rx_data2=c5_rx_data;
					fan_tx_clk=1'b0;;
					fan_tx_data=1'b0;;
					c1_tx_clk=1'b0;
					c1_tx_data=1'b0;
					c2_tx_clk=1'b0;
					c2_tx_data=1'b0;
					c3_tx_clk=1'b0;
					c3_tx_data=1'b0;
					c4_tx_clk=1'b0;
					c4_tx_data=1'b0;
					c6_tx_clk=1'b0;
					c6_tx_data=1'b0;
					c7_tx_clk=1'b0;
					c7_tx_data=1'b0;
					c8_tx_clk=1'b0;
					c8_tx_data=1'b0;
					power1_tx_clk=1'b0;
					power1_tx_data=1'b0;
					power2_tx_clk=1'b0;
					power2_tx_data=1'b0;
				end
				5'b01000:begin  //8：x8
					c6_tx_clk=cpu_tx_clk2;
					c6_tx_data=cpu_tx_data2;
					cpu_rx_clk2<=c6_rx_clk;
					cpu_rx_data2<=c6_rx_data;
					fan_tx_clk=1'b0;;
					fan_tx_data=1'b0;;
					c1_tx_clk=1'b0;
					c1_tx_data=1'b0;
					c2_tx_clk=1'b0;
					c2_tx_data=1'b0;
					c3_tx_clk=1'b0;
					c3_tx_data=1'b0;
					c4_tx_clk=1'b0;
					c4_tx_data=1'b0;
					c5_tx_clk=1'b0;
					c5_tx_data=1'b0;
					c7_tx_clk=1'b0;
					c7_tx_data=1'b0;
					c8_tx_clk=1'b0;
					c8_tx_data=1'b0;
					power1_tx_clk=1'b0;
					power1_tx_data=1'b0;
					power2_tx_clk=1'b0;
					power2_tx_data=1'b0;
				end
				5'b01001:begin  //9:x9
					c7_tx_clk=cpu_tx_clk2;
					c7_tx_data=cpu_tx_data2;
					cpu_rx_clk2=c7_rx_clk;
					cpu_rx_data2=c7_rx_data;
					fan_tx_clk=1'b0;;
					fan_tx_data=1'b0;;
					c1_tx_clk=1'b0;
					c1_tx_data=1'b0;
					c2_tx_clk=1'b0;
					c2_tx_data=1'b0;
					c3_tx_clk=1'b0;
					c3_tx_data=1'b0;
					c4_tx_clk=1'b0;
					c4_tx_data=1'b0;
					c5_tx_clk=1'b0;
					c5_tx_data=1'b0;
					c6_tx_clk=1'b0;
					c6_tx_data=1'b0;
					c8_tx_clk=1'b0;
					c8_tx_data=1'b0;
					power1_tx_clk=1'b0;
					power1_tx_data=1'b0;
					power2_tx_clk=1'b0;
					power2_tx_data=1'b0;
				end
				5'b01010:begin  //10:reserve
					c8_tx_clk=cpu_tx_clk2;
					c8_tx_data=cpu_tx_data2;
					cpu_rx_clk2=c8_rx_clk;
					cpu_rx_data2=c8_rx_data;
					fan_tx_clk=1'b0;;
					fan_tx_data=1'b0;;
					c1_tx_clk=1'b0;
					c1_tx_data=1'b0;
					c2_tx_clk=1'b0;
					c2_tx_data=1'b0;
					c3_tx_clk=1'b0;
					c3_tx_data=1'b0;
					c4_tx_clk=1'b0;
					c4_tx_data=1'b0;
					c5_tx_clk=1'b0;
					c5_tx_data=1'b0;
					c6_tx_clk=1'b0;
					c6_tx_data=1'b0;
					c7_tx_clk=1'b0;
					c7_tx_data=1'b0;
					power1_tx_clk=1'b0;
					power1_tx_data=1'b0;
					power2_tx_clk=1'b0;
					power2_tx_data=1'b0;
				end
				5'b01011:begin  //11:电源板1
					power1_tx_clk=cpu_tx_clk2;
					power1_tx_data=cpu_tx_data2;
					cpu_rx_clk2=power1_rx_clk;
					cpu_rx_data2=power1_rx_data;
					fan_tx_clk=1'b0;;
					fan_tx_data=1'b0;;
					c1_tx_clk=1'b0;
					c1_tx_data=1'b0;
					c2_tx_clk=1'b0;
					c2_tx_data=1'b0;
					c3_tx_clk=1'b0;
					c3_tx_data=1'b0;
					c4_tx_clk=1'b0;
					c4_tx_data=1'b0;
					c5_tx_clk=1'b0;
					c5_tx_data=1'b0;
					c6_tx_clk=1'b0;
					c6_tx_data=1'b0;
					c7_tx_clk=1'b0;
					c7_tx_data=1'b0;
					c8_tx_clk=1'b0;
					c8_tx_data=1'b0;
					power2_tx_clk=1'b0;
					power2_tx_data=1'b0;
				end
				5'b01100:begin  //12：电源板2
					power2_tx_clk=cpu_tx_clk2;
					power2_tx_data=cpu_tx_data2;
					cpu_rx_clk2=power2_rx_clk;
					cpu_rx_data2=power2_rx_data;
					fan_tx_clk=1'b0;;
					fan_tx_data=1'b0;;
					c1_tx_clk=1'b0;
					c1_tx_data=1'b0;
					c2_tx_clk=1'b0;
					c2_tx_data=1'b0;
					c3_tx_clk=1'b0;
					c3_tx_data=1'b0;
					c4_tx_clk=1'b0;
					c4_tx_data=1'b0;
					c5_tx_clk=1'b0;
					c5_tx_data=1'b0;
					c6_tx_clk=1'b0;
					c6_tx_data=1'b0;
					c7_tx_clk=1'b0;
					c7_tx_data=1'b0;
					c8_tx_clk=1'b0;
					c8_tx_data=1'b0;
					power1_tx_clk=1'b0;
					power1_tx_data=1'b0;
				end
				default:begin  //12：电源板2
					cpu_rx_clk2=1'b0;
					cpu_rx_data2=1'b0;
					fan_tx_clk=1'b0;;
					fan_tx_data=1'b0;;
					c1_tx_clk=1'b0;
					c1_tx_data=1'b0;
					c2_tx_clk=1'b0;
					c2_tx_data=1'b0;
					c3_tx_clk=1'b0;
					c3_tx_data=1'b0;
					c4_tx_clk=1'b0;
					c4_tx_data=1'b0;
					c5_tx_clk=1'b0;
					c5_tx_data=1'b0;
					c6_tx_clk=1'b0;
					c6_tx_data=1'b0;
					c7_tx_clk=1'b0;
					c7_tx_data=1'b0;
					c8_tx_clk=1'b0;
					c8_tx_data=1'b0;
					power1_tx_clk=1'b0;
					power1_tx_data=1'b0;
					power2_tx_clk=1'b0;
					power2_tx_data=1'b0;
				end				
			endcase
		end
	end
//****************私有协议5:protocol5 ****************//
//5.1 风扇板卡通道控制
	reg [8:0]  fan_tx_data_clear_num;
	reg        fan_tx_data_clear;	
	reg [31:0] fan_tx_data_temp;
	reg [5:0]  fan_tx_data_num;
	
	wire [3:0]  fan_function_select;
	reg [11:0] fan_speed_bit;
	wire        fan_read_write;  //1读0写
	wire        fan_dataend_temp;
		//清0标识，0清0
	always@(posedge clk_50us or negedge reset_temp) begin  //私有协议清0标志
		if(!reset_temp) begin
			fan_tx_data_clear<=1'b1;
			fan_tx_data_clear_num<=0;
		end
		else begin
			if(fan_tx_clk) begin
				fan_tx_data_clear<=1'b1;
				fan_tx_data_clear_num<=0;
			end
				else if(fan_tx_data_clear_num<400) begin  //10ms等待时间
					fan_tx_data_clear_num<=fan_tx_data_clear_num+1;
					fan_tx_data_clear<=1'b1;
				end
					else if(fan_tx_data_clear_num<440) begin
						fan_tx_data_clear_num<=fan_tx_data_clear_num+1;
						fan_tx_data_clear<=1'b0;  //私有协议清0标志，0清0,持续2ms
					end
					else begin
						fan_tx_data_clear<=1'b1;
					end
		end
	end
		//读取串行信号
	always@(posedge fan_tx_clk or negedge reset_temp or negedge fan_tx_data_clear) begin
		if(!reset_temp) begin
			fan_tx_data_temp<=32'b11111111111111111111111111111111;
			fan_tx_data_num<=0;
		end
		else begin
			if(!fan_tx_data_clear) begin
				fan_tx_data_num<=0;
				fan_tx_data_temp[9]<=1'b0;  //读写位清0
				fan_tx_data_temp[31]<=1'b1;
			end
				else if(fan_tx_data_num<31) begin
					fan_tx_data_temp[fan_tx_data_num]<=fan_tx_data;
					fan_tx_data_num<=fan_tx_data_num+1;
				end
					else begin
						fan_tx_data_temp[fan_tx_data_num]<=fan_tx_data;
						fan_tx_data_num<=0;
					end
		end
	end
		
	assign fan_function_select[3] =fan_tx_data_temp[5];
	assign fan_function_select[2] =fan_tx_data_temp[6];
	assign fan_function_select[1] =fan_tx_data_temp[7];
	assign fan_function_select[0] =fan_tx_data_temp[8];
	assign fan_read_write =fan_tx_data_temp[9];
	assign fan_dataend_temp =fan_tx_data_temp[31];
	//数据结束回复标识
	reg [5:0]   fan_read_star_num;
	reg         fan_read_star;
	
	always@(posedge clk_50us or negedge reset_temp ) begin //or posedge fan_dataend_temp) begin  //私有协议清0标志
		if(reset_temp == 1'b0) begin
			fan_read_star<=1'b1;
			fan_read_star_num<=0;
		end
		else begin
			if((fan_dataend_temp == 1'b1)||(fan_read_write == 1'b0)) begin
				fan_read_star<=1'b1;
				fan_read_star_num<=0;
			end
				else if(fan_read_star_num<20) begin  //1ms等待时间
					fan_read_star_num<=fan_read_star_num+1;
					fan_read_star<=1'b1;
				end
					else if(fan_read_star_num<60) begin  //持续2ms
						fan_read_star_num<=fan_read_star_num+1;
						fan_read_star<=1'b0;  //私有协议清0标志，0清0,持续2ms
					end
					else begin
						fan_read_star<=1'b1;
					end
		end
	end
	//5.1.1 fan调速
	reg		fan1_speed;
	reg		fan2_speed;
	reg		fan3_speed;
	reg		fan4_speed;
	reg		fan5_speed;
	reg		fan6_speed;
		//fan1**注意得功能选择稳定后再进行判断速率，否则功能检测改变顺便会异常
	always@(posedge clk_25m or negedge reset_temp) begin
		if(!reset_temp) begin
            fan_speed_bit[1:0]<=2'b11;
        end
		else if(!fan_tx_data_clear) begin
			if(fan_function_select[3:0]==4'b1000) begin
				fan_speed_bit[0] <= fan_tx_data_temp[10];
				fan_speed_bit[1] <= fan_tx_data_temp[11];
			end
		end
	end

	always@(*) begin
		case(fan_speed_bit[1:0])
			2'b00:begin
				fan1_speed = 1'b1;
			end
			2'b10:begin
				fan1_speed = pwm_duty_25;
			end
			2'b01:begin
				fan1_speed = pwm_duty_50;
			end
			2'b11:begin
				fan1_speed = 1'b0;
			end
		endcase
	end
		//fan2
	always@(posedge clk_25m or negedge reset_temp) begin
		if(!reset_temp) begin
            fan_speed_bit[3:2]<=2'b11;
        end
		else if(!fan_tx_data_clear) begin
			if(fan_function_select[3:0]==4'b1000) begin
				fan_speed_bit[2] <= fan_tx_data_temp[12];
				fan_speed_bit[3] <= fan_tx_data_temp[13];
			end
		end
	end

	always@(*) begin
		case(fan_speed_bit[3:2])
			2'b00:begin
				fan2_speed = 1'b1;
			end
			2'b10:begin
				fan2_speed = pwm_duty_25;
			end
			2'b01:begin
				fan2_speed = pwm_duty_50;
			end
			2'b11:begin
				fan2_speed = 1'b0;
			end	
		endcase
	end
		//fan3
	always@(posedge clk_25m or negedge reset_temp) begin
		if(!reset_temp) begin
            fan_speed_bit[5:4]<=2'b11;
        end
		else if(!fan_tx_data_clear) begin
			if(fan_function_select[3:0]==4'b1000) begin
				fan_speed_bit[4] <= fan_tx_data_temp[14];
				fan_speed_bit[5] <= fan_tx_data_temp[15];
			end
		end
	end

	always@(*) begin
		case(fan_speed_bit[5:4])
			2'b00:begin
				fan3_speed = 1'b1;
			end
			2'b10:begin
				fan3_speed = pwm_duty_25;
			end
			2'b01:begin
				fan3_speed = pwm_duty_50;
			end
			2'b11:begin
				fan3_speed = 1'b0;
			end
		endcase
	end
		//fan4
	always@(posedge clk_25m or negedge reset_temp) begin
		if(!reset_temp) begin
            fan_speed_bit[7:6]<=2'b11;
        end
		else if(!fan_tx_data_clear) begin
			if(fan_function_select[3:0]==4'b1000) begin
				fan_speed_bit[6] <= fan_tx_data_temp[16];
				fan_speed_bit[7] <= fan_tx_data_temp[17];
			end
		end
	end

	always@(*) begin
		case(fan_speed_bit[7:6])
			2'b00:begin
				fan4_speed = 1'b1;
			end
			2'b10:begin
				fan4_speed = pwm_duty_25;
			end
			2'b01:begin
				fan4_speed = pwm_duty_50;
			end
			2'b11:begin
				fan4_speed = 1'b0;
			end
		endcase
	end
		//fan5
	always@(posedge clk_25m or negedge reset_temp) begin
		if(!reset_temp) begin
            fan_speed_bit[9:8]<=2'b11;
        end
		else if(!fan_tx_data_clear) begin
			if(fan_function_select[3:0]==4'b1000) begin
				fan_speed_bit[8] <= fan_tx_data_temp[18];
				fan_speed_bit[9] <= fan_tx_data_temp[19];
			end
		end
	end

	always@(*) begin
		case(fan_speed_bit[9:8])
			2'b00:begin
				fan5_speed = 1'b1;
			end
			2'b10:begin
				fan5_speed = pwm_duty_25;
			end
			2'b01:begin
				fan5_speed = pwm_duty_50;
			end
			2'b11:begin
				fan5_speed = 1'b0;
			end
		endcase
	end
		//fan6
	always@(posedge clk_25m or negedge reset_temp) begin
		if(!reset_temp) begin
            fan_speed_bit[11:10]<=2'b11;
        end
		else if(!fan_tx_data_clear) begin
			if(fan_function_select[3:0]==4'b1000) begin
				fan_speed_bit[10] <= fan_tx_data_temp[20];
				fan_speed_bit[11] <= fan_tx_data_temp[21];
			end
		end
	end

	always@(*) begin
		case(fan_speed_bit[11:10])
			2'b00:begin
				fan6_speed = 1'b1;
			end
			2'b10:begin
				fan6_speed = pwm_duty_25;
			end
			2'b01:begin
				fan6_speed = pwm_duty_50;
			end
			2'b11:begin
				fan6_speed = 1'b0;
			end
		endcase
	end

	//5.1.1 风扇打开				
/*	assign fan1_clt = 1'b1;
	assign fan2_clt = 1'b1;
	assign fan3_clt = 1'b1;
	assign fan4_clt = 1'b1;
	assign fan5_clt = 1'b1;
	assign fan6_clt = 1'b1;*/
	reg [8:0] fan_open_delay_1s;
	reg        fan1_clt;
	reg        fan2_clt;
	reg        fan3_clt;
	reg        fan4_clt;
	reg        fan5_clt;
	reg        fan6_clt;

	always@(posedge clk_10ms or negedge reset_temp) begin
		if(!reset_temp) begin
			fan_open_delay_1s<=0;
			fan1_clt<=1'b0;
			fan2_clt<=1'b0;
			fan3_clt<=1'b0;
			fan4_clt<=1'b0;
			fan5_clt<=1'b0;
			fan6_clt<=1'b0;
		end
		else if(fan_panel_detec) begin
			fan_open_delay_1s<=0;
			fan1_clt<=1'b0;
			fan2_clt<=1'b0;
			fan3_clt<=1'b0;
			fan4_clt<=1'b0;
			fan5_clt<=1'b0;
			fan6_clt<=1'b0;
		end
		else begin
			if(fan_open_delay_1s<99) begin
				fan_open_delay_1s<=fan_open_delay_1s+1;
				fan1_clt<=1'b1;
				fan2_clt<=1'b0;
				fan3_clt<=1'b0;
				fan4_clt<=1'b0;
				fan5_clt<=1'b0;
				fan6_clt<=1'b0;
			end
				else if(fan_open_delay_1s<199)begin
					fan_open_delay_1s<=fan_open_delay_1s+1;
					fan1_clt<=1'b1;
					fan2_clt<=1'b1;
					fan3_clt<=1'b0;
					fan4_clt<=1'b0;
					fan5_clt<=1'b0;
					fan6_clt<=1'b0;
				end
					else if(fan_open_delay_1s<299)begin
						fan_open_delay_1s<=fan_open_delay_1s+1;
						fan1_clt<=1'b1;
						fan2_clt<=1'b1;
						fan3_clt<=1'b1;
						fan4_clt<=1'b0;
						fan5_clt<=1'b0;
						fan6_clt<=1'b0;
					end
						else if(fan_open_delay_1s<399)begin
							fan_open_delay_1s<=fan_open_delay_1s+1;
							fan1_clt<=1'b1;
							fan2_clt<=1'b1;
							fan3_clt<=1'b1;
							fan4_clt<=1'b1;
							fan5_clt<=1'b0;
							fan6_clt<=1'b0;
						end
							else if(fan_open_delay_1s<499)begin
								fan_open_delay_1s<=fan_open_delay_1s+1;
								fan1_clt<=1'b1;
								fan2_clt<=1'b1;
								fan3_clt<=1'b1;
								fan4_clt<=1'b1;
								fan5_clt<=1'b1;
								fan6_clt<=1'b0;
							end
								else begin
									fan1_clt<=1'b1;
									fan2_clt<=1'b1;
									fan3_clt<=1'b1;
									fan4_clt<=1'b1;
									fan5_clt<=1'b1;
									fan6_clt<=1'b1;                    
								end
		end
	end
	
    //产生25K pwm风扇调速时钟
    reg [9:0] num_pwm;
    reg       pwm_duty_25;      //6000风扇这个占空比对应3000转               
    reg       pwm_duty_50;      //6000风扇这个占空比对应4500转 
    reg       pwm_duty_75;

    always@(posedge clk_25m or negedge reset) begin
        if(!reset) begin
            num_pwm<=10'b0;
            pwm_duty_25<=1'b0;
            pwm_duty_50<=1'b0;
            pwm_duty_75<=1'b0;
        end
        else begin
            if(num_pwm<10'd250-1) begin
                num_pwm<=num_pwm+1;
            end
            else if(num_pwm<10'd500-1) begin
                num_pwm<=num_pwm+1;
                pwm_duty_25<=1'b1;
                pwm_duty_50<=1'b0;
                pwm_duty_75<=1'b0;
            end
                else if(num_pwm<10'd750-1) begin
                    num_pwm<=num_pwm+1;
                    pwm_duty_25<=1'b1;
                    pwm_duty_50<=1'b1;
                    pwm_duty_75<=1'b0;
                end
                    else if(num_pwm<10'd1000-1) begin 
                        num_pwm<=num_pwm+1;
                        pwm_duty_25<=1'b1;
                        pwm_duty_50<=1'b1;
                        pwm_duty_75<=1'b1;                    
                    end
                        else begin
                            num_pwm<=10'b0;
                            pwm_duty_25<=1'b0;
                            pwm_duty_50<=1'b0;
                            pwm_duty_75<=1'b0;                        
                        end        
        end
    end

//5.2 电源1板卡控制,cpu发给逻辑处理
	reg [8:0]  power1_tx_data_clear_num;
	reg        power1_tx_data_clear;	
	reg [31:0] power1_tx_data_temp;
	reg [5:0]  power1_tx_data_num;
	wire [3:0]  power1_function_select;
	wire        power1_read_write;  //1读0写
	reg        power1_dataend_temp;
		//清0标识，0清0
	always@(posedge clk_50us or negedge reset_temp) begin  //私有协议清0标志
		if(!reset_temp) begin
			power1_tx_data_clear<=1'b1;
			power1_tx_data_clear_num<=0;
		end
		else begin
			if(power1_tx_clk) begin
				power1_tx_data_clear<=1'b1;
				power1_tx_data_clear_num<=0;
			end
				else if(power1_tx_data_clear_num<400) begin  //20ms等待时间
					power1_tx_data_clear_num<=power1_tx_data_clear_num+1;
					power1_tx_data_clear<=1'b1;
				end
					else if(power1_tx_data_clear_num<440) begin
						power1_tx_data_clear_num<=power1_tx_data_clear_num+1;
						power1_tx_data_clear<=1'b0;  //私有协议清0标志，0清0,持续2ms
					end
					else begin
						power1_tx_data_clear<=1'b1;
					end
		end
	end
		//读取串行信号
	always@(posedge power1_tx_clk or negedge reset_temp or negedge power1_tx_data_clear) begin
		if(!reset_temp) begin
			power1_tx_data_temp<=32'b10000000000000000000000000000000;
			power1_tx_data_num<=0;
			power1_dataend_temp<=1'b0;
		end
		else begin
			if(!power1_tx_data_clear) begin
				power1_tx_data_num<=0;
				power1_tx_data_temp[9]<=1'b0;  //读写位清0
				power1_dataend_temp<=1'b0;
			end
				else if(power1_tx_data_num<31) begin
					power1_tx_data_temp[power1_tx_data_num]<=power1_tx_data;
					power1_tx_data_num<=power1_tx_data_num+1;
				end
					else begin
						power1_tx_data_temp[power1_tx_data_num]<=power1_tx_data;
						power1_tx_data_num<=0;
						power1_dataend_temp<=1'b1;  //32位数据接收结束标志1
					end
		end
	end
		
	assign power1_function_select[3] =power1_tx_data_temp[5];
	assign power1_function_select[2] =power1_tx_data_temp[6];
	assign power1_function_select[1] =power1_tx_data_temp[7];
	assign power1_function_select[0] =power1_tx_data_temp[8];
	assign power1_read_write =power1_tx_data_temp[9];
	//数据结束开始回复标识
	reg [6:0]   power1_read_star_num;
	reg         power1_read_star;
	
	always@(posedge clk_50us or negedge reset_temp) begin
		if(reset_temp == 1'b0) begin
			power1_read_star<=1'b0;
			power1_read_star_num<=0;
		end
		else if(!power1_tx_data_clear) begin
			power1_read_star<=1'b0;
			power1_read_star_num<=0;
		end
		else if((power1_dataend_temp == 1'b1)&&(power1_read_write == 1'b1)) begin //都为1才开始回复数据
			if(power1_read_star_num<10) begin
				power1_read_star_num<=power1_read_star_num+1;
				power1_read_star<=1'b0;
			end
				else if(power1_read_star_num<100) begin  //持续5ms
					power1_read_star_num<=power1_read_star_num+1;
					power1_read_star<=1'b1;
				end
					else begin
						power1_read_star<=1'b0;
					end
		end
		else begin
			power1_read_star<=1'b0;
		end
	end
	
//5.3 电源2板卡控制,cpu发给逻辑处理
	reg [8:0]  power2_tx_data_clear_num;
	reg        power2_tx_data_clear;	
	reg [31:0] power2_tx_data_temp;
	reg [5:0]  power2_tx_data_num;
	wire [3:0]  power2_function_select;
	wire        power2_read_write;  //1读0写
	reg        power2_dataend_temp;
		//清0标识，0清0
	always@(posedge clk_50us or negedge reset_temp) begin  //私有协议清0标志
		if(!reset_temp) begin
			power2_tx_data_clear<=1'b1;
			power2_tx_data_clear_num<=0;
		end
		else begin
			if(power2_tx_clk) begin
				power2_tx_data_clear<=1'b1;
				power2_tx_data_clear_num<=0;
			end
				else if(power2_tx_data_clear_num<400) begin  //20ms等待时间
					power2_tx_data_clear_num<=power2_tx_data_clear_num+1;
					power2_tx_data_clear<=1'b1;
				end
					else if(power2_tx_data_clear_num<440) begin
						power2_tx_data_clear_num<=power2_tx_data_clear_num+1;
						power2_tx_data_clear<=1'b0;  //私有协议清0标志，0清0,持续2ms
					end
					else begin
						power2_tx_data_clear<=1'b1;
					end
		end
	end
		//读取串行信号
	always@(posedge power2_tx_clk or negedge reset_temp or negedge power2_tx_data_clear) begin
		if(!reset_temp) begin
			power2_tx_data_temp<=32'b10000000000000000000000000000000;
			power2_tx_data_num<=0;
			power2_dataend_temp<=1'b0;
		end
		else begin
			if(!power2_tx_data_clear) begin
				power2_tx_data_num<=0;
				power2_tx_data_temp[9]<=1'b0;  //读写位清0
				power2_dataend_temp<=1'b0;
			end
				else if(power2_tx_data_num<31) begin
					power2_tx_data_temp[power2_tx_data_num]<=power2_tx_data;
					power2_tx_data_num<=power2_tx_data_num+1;
				end
					else begin
						power2_tx_data_temp[power2_tx_data_num]<=power2_tx_data;
						power2_tx_data_num<=0;
						power2_dataend_temp<=1'b1;  //32位数据接收结束标志1
					end
		end
	end
		
	assign power2_function_select[3] =power2_tx_data_temp[5];
	assign power2_function_select[2] =power2_tx_data_temp[6];
	assign power2_function_select[1] =power2_tx_data_temp[7];
	assign power2_function_select[0] =power2_tx_data_temp[8];
	assign power2_read_write =power2_tx_data_temp[9];
	//数据结束开始回复标识
	reg [6:0]   power2_read_star_num;
	reg         power2_read_star;
	
	always@(posedge clk_50us or negedge reset_temp) begin
		if(reset_temp == 1'b0) begin
			power2_read_star<=1'b0;
			power2_read_star_num<=0;
		end
		else if(!power2_tx_data_clear) begin
			power2_read_star<=1'b0;
			power2_read_star_num<=0;
		end
		else if((power2_dataend_temp == 1'b1)&&(power2_read_write == 1'b1)) begin //都为1才开始回复数据
			if(power2_read_star_num<10) begin
				power2_read_star_num<=power2_read_star_num+1;
				power2_read_star<=1'b0;
			end
				else if(power2_read_star_num<100) begin  //持续5ms
					power2_read_star_num<=power2_read_star_num+1;
					power2_read_star<=1'b1;
				end
					else begin
						power2_read_star<=1'b0;
					end
		end
		else begin
			power2_read_star<=1'b0;
		end
	end
//5.4 整台设备复位&断电控制,cpu发给所有板卡,OK
	wire [131:0] allboard_clk_tx_temp;
	wire [131:0] allboard_data_tx_temp;
	reg  [8:0]   allboard_data_tx_num; 
	reg          allboard_clk_tx;
	reg          allboard_data_tx;

	always@(posedge clk_50us or negedge reset_temp) begin
		if(!reset_temp) begin
			allboard_data_tx_num<=0;
			allboard_clk_tx<=1'b0;
			allboard_data_tx<=1'b0;
		end
		else begin
			if(allboard_tx_temp==1'b1) begin
				allboard_data_tx_num<=0;
			end
				else if(allboard_data_tx_num<132) begin  //  产生串行时钟数据
					allboard_clk_tx<= allboard_clk_tx_temp[allboard_data_tx_num];
					allboard_data_tx<= allboard_data_tx_temp[allboard_data_tx_num];
					allboard_data_tx_num<=allboard_data_tx_num+1;
				end
		end
	end
	//串行时钟
	assign allboard_clk_tx_temp = {2'b00,{32{4'b1100}},2'b00};
	//串行数据
	assign allboard_data_tx_temp[131:130] = 2'b0;
	assign allboard_data_tx_temp[129:126] = {1'b1,1'b1,1'b1,1'b1};
	assign allboard_data_tx_temp[125:122] = {1'b1,1'b1,1'b1,1'b1};
	assign allboard_data_tx_temp[121:118] = {1'b1,1'b1,1'b1,1'b1};
	assign allboard_data_tx_temp[117:114] = {1'b1,1'b1,1'b1,1'b1};
	assign allboard_data_tx_temp[113:110] = {1'b1,1'b1,1'b1,1'b1};
	assign allboard_data_tx_temp[109:106] = {1'b1,1'b1,1'b1,1'b1};
	assign allboard_data_tx_temp[105:102] = {1'b1,1'b1,1'b1,1'b1};
	assign allboard_data_tx_temp[101:98]  = {1'b1,1'b1,1'b1,1'b1};
	assign allboard_data_tx_temp[97:94]   = {1'b1,1'b1,1'b1,1'b1};
	assign allboard_data_tx_temp[93:90]   = {1'b1,1'b1,1'b1,1'b1};
	assign allboard_data_tx_temp[89:86]   = {1'b1,1'b1,1'b1,1'b1};
	assign allboard_data_tx_temp[85:82]   = {1'b1,1'b1,1'b1,1'b1};
	assign allboard_data_tx_temp[81:78]   = {1'b1,1'b1,1'b1,1'b1};
	assign allboard_data_tx_temp[77:74]   = {1'b1,1'b1,1'b1,1'b1};
	assign allboard_data_tx_temp[73:70]   = {1'b1,1'b1,1'b1,1'b1};
	assign allboard_data_tx_temp[69:66]   = {1'b0,1'b0,1'b0,1'b0};
	assign allboard_data_tx_temp[65:62]   = {1'b1,1'b1,1'b1,1'b1};
	assign allboard_data_tx_temp[61:58]   = {1'b1,1'b1,1'b1,1'b1};
	assign allboard_data_tx_temp[57:54]   = {1'b0,1'b0,1'b0,1'b0};
	assign allboard_data_tx_temp[53:50]   = {1'b1,1'b1,1'b1,1'b1};
	assign allboard_data_tx_temp[49:46]   = {~board_reset_all,~board_reset_all,~board_reset_all,~board_reset_all}; //1复位，0正常
	assign allboard_data_tx_temp[45:42]   = {board_power_all,board_power_all,board_power_all,board_power_all};
	assign allboard_data_tx_temp[41:38]   = {1'b0,1'b0,1'b0,1'b0};
	assign allboard_data_tx_temp[37:34]   = {1'b1,1'b1,1'b1,1'b1};
	assign allboard_data_tx_temp[33:30]   = {1'b1,1'b1,1'b1,1'b1};
	assign allboard_data_tx_temp[29:26]   = {1'b0,1'b0,1'b0,1'b0};
	assign allboard_data_tx_temp[25:22]   = {1'b0,1'b0,1'b0,1'b0};
	assign allboard_data_tx_temp[21:18]   = {1'b1,1'b1,1'b1,1'b1};
	assign allboard_data_tx_temp[17:14]   = {1'b0,1'b0,1'b0,1'b0};
	assign allboard_data_tx_temp[13:10]   = {1'b0,1'b0,1'b0,1'b0};
	assign allboard_data_tx_temp[9:6]     = {1'b0,1'b0,1'b0,1'b0};
	assign allboard_data_tx_temp[5:2]     = {1'b0,1'b0,1'b0,1'b0};
	assign allboard_data_tx_temp[1:0]     = 2'b0;
//****************私有协议6:protocol6 ****************//
//********6.1 风扇通道接收
	wire [131:0] fan_rx_clk_temp;
	wire [131:0] fan_rx_data_temp;
	reg  [7:0]   fan_rx_num;
	wire		parity_check6_fan;	

	always@(posedge clk_1ms or negedge reset_temp ) begin //or negedge fan_read_star ) begin      //  产生串行时钟
		if(!reset_temp) begin
			fan_rx_num<=0;
			fan_rx_clk<=1'b0;
			fan_rx_data<=1'b0;
		end
		else begin
			if(!fan_read_star) begin  //0进行清0，0发数据
				fan_rx_num<=0;
			end
				else if(fan_rx_num<132) begin
					fan_rx_clk<= fan_rx_clk_temp[fan_rx_num];
					fan_rx_data<= fan_rx_data_temp[fan_rx_num];
					fan_rx_num<=fan_rx_num+1;
				end
		end
	end
	//串行时钟
	assign fan_rx_clk_temp = {2'b00,{32{4'b0011}},2'b00};
	//串行数据
	assign fan_rx_data_temp[131:130] = 2'b0;
	assign fan_rx_data_temp[129:126] = {parity_check6_fan,parity_check6_fan,parity_check6_fan,parity_check6_fan};  //31
	assign fan_rx_data_temp[125:122] = {1'b0,1'b0,1'b0,1'b0};
	assign fan_rx_data_temp[121:118] = {1'b0,1'b0,1'b0,1'b0};
	assign fan_rx_data_temp[117:114] = {1'b0,1'b0,1'b0,1'b0};
	assign fan_rx_data_temp[113:110] = {1'b0,1'b0,1'b0,1'b0};  //27
	assign fan_rx_data_temp[109:106] = {1'b0,1'b0,1'b0,1'b0};
	assign fan_rx_data_temp[105:102] = {1'b1,1'b1,1'b1,1'b1};
	assign fan_rx_data_temp[101:98]  = {1'b1,1'b1,1'b1,1'b1};
	assign fan_rx_data_temp[97:94]   = {1'b1,1'b1,1'b1,1'b1};  //23
	assign fan_rx_data_temp[93:90]   = {1'b1,1'b1,1'b1,1'b1};
	assign fan_rx_data_temp[89:86]   = {fan6_detec_bit[0],fan6_detec_bit[0],fan6_detec_bit[0],fan6_detec_bit[0]};
	assign fan_rx_data_temp[85:82]   = {fan6_detec_bit[1],fan6_detec_bit[1],fan6_detec_bit[1],fan6_detec_bit[1]};
	assign fan_rx_data_temp[81:78]   = {fan5_detec_bit[0],fan5_detec_bit[0],fan5_detec_bit[0],fan5_detec_bit[0]};  //19
	assign fan_rx_data_temp[77:74]   = {fan5_detec_bit[1],fan5_detec_bit[1],fan5_detec_bit[1],fan5_detec_bit[1]};
	assign fan_rx_data_temp[73:70]   = {fan4_detec_bit[0],fan4_detec_bit[0],fan4_detec_bit[0],fan4_detec_bit[0]};
	assign fan_rx_data_temp[69:66]   = {fan4_detec_bit[1],fan4_detec_bit[1],fan4_detec_bit[1],fan4_detec_bit[1]};
	assign fan_rx_data_temp[65:62]   = {fan3_detec_bit[0],fan3_detec_bit[0],fan3_detec_bit[0],fan3_detec_bit[0]};  //15
	assign fan_rx_data_temp[61:58]   = {fan3_detec_bit[1],fan3_detec_bit[1],fan3_detec_bit[1],fan3_detec_bit[1]};
	assign fan_rx_data_temp[57:54]   = {fan2_detec_bit[0],fan2_detec_bit[0],fan2_detec_bit[0],fan2_detec_bit[0]};
	assign fan_rx_data_temp[53:50]   = {fan2_detec_bit[1],fan2_detec_bit[1],fan2_detec_bit[1],fan2_detec_bit[1]};
	assign fan_rx_data_temp[49:46]   = {fan1_detec_bit[0],fan1_detec_bit[0],fan1_detec_bit[0],fan1_detec_bit[0]};  //11
	assign fan_rx_data_temp[45:42]   = {fan1_detec_bit[1],fan1_detec_bit[1],fan1_detec_bit[1],fan1_detec_bit[1]};
	assign fan_rx_data_temp[41:38]   = {1'b1,1'b1,1'b1,1'b1};
	assign fan_rx_data_temp[37:34]   = {1'b1,1'b1,1'b1,1'b1};
	assign fan_rx_data_temp[33:30]   = {1'b0,1'b0,1'b0,1'b0};  //7
	assign fan_rx_data_temp[29:26]   = {1'b0,1'b0,1'b0,1'b0};
	assign fan_rx_data_temp[25:22]   = {1'b1,1'b1,1'b1,1'b1};
	assign fan_rx_data_temp[21:18]   = {1'b0,1'b0,1'b0,1'b0};
	assign fan_rx_data_temp[17:14]   = {1'b0,1'b0,1'b0,1'b0};  //3
	assign fan_rx_data_temp[13:10]   = {1'b0,1'b0,1'b0,1'b0};
	assign fan_rx_data_temp[9:6]     = {1'b0,1'b0,1'b0,1'b0};
	assign fan_rx_data_temp[5:2]     = {1'b0,1'b0,1'b0,1'b0}; 
	assign fan_rx_data_temp[1:0]     = 2'b0;
	//异或奇偶校验，相同0，不同为1，奇数个1为1，偶数个1为0
	assign parity_check6_fan = fan1_detec_bit[1] ^ fan1_detec_bit[0] ^ fan2_detec_bit[1] ^ fan2_detec_bit[0] ^ fan3_detec_bit[1] ^ fan3_detec_bit[0] ^ fan4_detec_bit[1] ^ fan4_detec_bit[0] ^ fan5_detec_bit[1] ^ fan5_detec_bit[0] ^ fan6_detec_bit[1] ^ fan6_detec_bit[0] ^ 1'b1;
	//********6.11 风扇检测

	wire [1:0] fan1_detec_bit;  //4种转速状态用2位表示
	wire [1:0] fan2_detec_bit; 
    wire [1:0] fan3_detec_bit;
    wire [1:0] fan4_detec_bit;
    wire [1:0] fan5_detec_bit;
    wire [1:0] fan6_detec_bit; 

    fan_fg fan_fg1(.clk_10us(clk_10us),
                   .reset_temp(reset_temp),
                   .fan_detec(fan1_detec),
                   .fan_detec_bit(fan1_detec_bit)
                   );

    fan_fg fan_fg2(.clk_10us(clk_10us),
                   .reset_temp(reset_temp),
                   .fan_detec(fan2_detec),
                   .fan_detec_bit(fan2_detec_bit)
                   );

    fan_fg fan_fg3(.clk_10us(clk_10us),
                   .reset_temp(reset_temp),
                   .fan_detec(fan3_detec),
                   .fan_detec_bit(fan3_detec_bit)
                   );

    fan_fg fan_fg4(.clk_10us(clk_10us),
                   .reset_temp(reset_temp),
                   .fan_detec(fan4_detec),
                   .fan_detec_bit(fan4_detec_bit)
                   );

    fan_fg fan_fg5(.clk_10us(clk_10us),
                   .reset_temp(reset_temp),
                   .fan_detec(fan5_detec),
                   .fan_detec_bit(fan5_detec_bit)
                   );

    fan_fg fan_fg6(.clk_10us(clk_10us),
                   .reset_temp(reset_temp),
                   .fan_detec(fan6_detec),
                   .fan_detec_bit(fan6_detec_bit)
                   );

//********6.2 电源1通道接收power1
	//********6.2.1 电源1发给主控逻辑数据 24位数据，时钟周期1ms，间隔200ms，电压，电流，温度（AC），循环发
	//输入power1的时钟数据处理，边沿去抖
	reg		power1_clk_temp;
	reg		power1_data_temp;
	
	always@(posedge clk_10us or negedge reset) begin
		if(!reset) begin
            power1_clk_temp<=1'b0;
        end
        else begin
			if(power1_clk) begin
				power1_clk_temp<=1'b1;
			end
			else if(!power1_clk) begin
				power1_clk_temp<=1'b0;
			end
		end
	end
	always@(posedge clk_10us or negedge reset) begin
		if(!reset) begin
            power1_data_temp<=1'b0;
        end
        else begin
			if(power1_data) begin
				power1_data_temp<=1'b1;
			end
			else if(!power1_data) begin
				power1_data_temp<=1'b0;
			end
		end
	end
	//对power1的24位数据提取
	reg  [4:0]  power1_rx_data_clear_num;
	reg         power1_rx_data_clear;	
	reg  [23:0] power1_rx_data_temp;
	reg  [4:0]  power1_rx_data_num;	
	wire [1:0]  power1_rx_function_select;
	wire		power1_position;
	wire        power1_type;
	wire [15:0] power1_data_bit;
	wire [1:0]  power1_alarm_bit;
	reg		power1_rx_data_end;
		//清0标识，0清0
	always@(posedge clk_250us or negedge reset) begin  //私有协议清0标志
		if(!reset) begin
			power1_rx_data_clear<=1'b1;
			power1_rx_data_clear_num<=0;
		end
		else begin
			if(power1_clk_temp) begin
				power1_rx_data_clear<=1'b1;
				power1_rx_data_clear_num<=0;
			end
				else if(power1_rx_data_clear_num<20) begin  //5ms等待时间
					power1_rx_data_clear_num<=power1_rx_data_clear_num+1;
					power1_rx_data_clear<=1'b1;
				end
					else if(power1_rx_data_clear_num<30) begin
						power1_rx_data_clear_num<=power1_rx_data_clear_num+1;
						power1_rx_data_clear<=1'b0;  //私有协议清0标志，0清0,持续2.5ms
					end
					else begin
						power1_rx_data_clear<=1'b1;
					end
		end
	end
		//读取串行信号
	always@(posedge power1_clk_temp or negedge reset or negedge power1_rx_data_clear) begin
		if(!reset) begin
			power1_rx_data_temp<=24'b110000000000000000000000;
			power1_rx_data_num<=0;
			power1_rx_data_end<=1'b0;
		end
		else begin
			if(!power1_rx_data_clear) begin
				power1_rx_data_num<=0;
				power1_rx_data_end<=1'b0;
			end
				else if(power1_rx_data_num<23) begin
					power1_rx_data_temp[power1_rx_data_num]<=power1_data_temp;
					power1_rx_data_num<=power1_rx_data_num+1;
				end
					else begin
						power1_rx_data_temp[power1_rx_data_num]<=power1_data_temp;
						power1_rx_data_num<=0;
						power1_rx_data_end<=1'b1;  //数据结束为1，持续5ms
					end
		end
	end
		
	assign power1_position = power1_rx_data_temp[0];	
	assign power1_type = power1_rx_data_temp[1];
	assign power1_rx_function_select[1] = power1_rx_data_temp[2];
	assign power1_rx_function_select[0] = power1_rx_data_temp[3];
	//********6.2.2 power1按功能存储数据
	reg [15:0]	power1_voltage_data_bit;
	reg [1:0]	power1_voltage_alarm_bit;
	reg [15:0]	power1_current_data_bit;
	reg 		power1_current_alarm_bit;
	reg [15:0]	power1_temperature_data_bit;
	reg 		power1_temperature_alarm_bit;
	
	always@(posedge clk_25m) begin
		if(power1_rx_data_end) begin
			case(power1_rx_function_select)
				2'b00:begin
					power1_voltage_data_bit[15:0] = power1_rx_data_temp[19:4]; //注意低位是实际数据的高位
					power1_voltage_alarm_bit[1] =  power1_rx_data_temp[20];
					power1_voltage_alarm_bit[0] =  power1_rx_data_temp[21];
				end
				2'b01:begin
					power1_current_data_bit[15:0] = power1_rx_data_temp[19:4];
					power1_current_alarm_bit = ~ power1_rx_data_temp[20];
				end
				2'b10:begin
					power1_temperature_data_bit[15:0] = power1_rx_data_temp[19:4];
					power1_temperature_alarm_bit = power1_rx_data_temp[20];
				end
			endcase
		end
	end
	
	//6.2.3 power1按功能发送数据给cpu
	// power1按照功能位给与数据
	reg	[15:0] power1_cpu_data;
	
	always@(posedge clk_25m) begin
		case(power1_function_select)
			4'b1100:begin  //电压
				power1_cpu_data[15:0] = power1_voltage_data_bit[15:0];
			end
			4'b1101:begin  //电流
				power1_cpu_data[15:0] = power1_current_data_bit[15:0];
			end
			4'b1110:begin  //温度，ac才有
				power1_cpu_data[15:0] = power1_temperature_data_bit[15:0];
			end
			4'b1111:begin  //告警
				power1_cpu_data[0] = power1_type;
				power1_cpu_data[1] = power1_voltage_alarm_bit[1];
				power1_cpu_data[2] = power1_voltage_alarm_bit[0];
				power1_cpu_data[3] = power1_temperature_alarm_bit;
				power1_cpu_data[4] = power1_current_alarm_bit;
				power1_cpu_data[15:5] = 11'b11111111111;
			end
		endcase
	end			
	//power1数据回复给主控
	wire [131:0] power1_rxclk_temp;
	wire [131:0] power1_rxdata_temp;
	reg  [7:0]   power1_to_cpu_num; 
	wire		parity_check6_power1;
	
	always@(posedge clk_1ms or negedge reset_temp ) begin
		if(!reset_temp) begin
			power1_to_cpu_num<=0;
			power1_rx_clk<=1'b0;
			power1_rx_data<=1'b0;
		end
		else begin
			if(power1_read_star) begin  //为1清0，0发送。
				power1_to_cpu_num<=0;
			end
				else if(power1_to_cpu_num<132) begin
					power1_rx_clk<= power1_rxclk_temp[power1_to_cpu_num];
					power1_rx_data<= power1_rxdata_temp[power1_to_cpu_num];
					power1_to_cpu_num<=power1_to_cpu_num+1;
				end
		end
	end
		//串行时钟
	assign power1_rxclk_temp = {2'b00,{32{4'b0011}},2'b00};
		//串行数据
	assign power1_rxdata_temp[131:130] = 2'b0;
	assign power1_rxdata_temp[129:126] = {parity_check6_power1,parity_check6_power1,parity_check6_power1,parity_check6_power1};  //31
	assign power1_rxdata_temp[125:122] = {1'b0,1'b0,1'b0,1'b0};
	assign power1_rxdata_temp[121:118] = {1'b0,1'b0,1'b0,1'b0};
	assign power1_rxdata_temp[117:114] = {1'b0,1'b0,1'b0,1'b0};
	assign power1_rxdata_temp[113:110] = {1'b0,1'b0,1'b0,1'b0};  //27
	assign power1_rxdata_temp[109:106] = {1'b0,1'b0,1'b0,1'b0};
	assign power1_rxdata_temp[105:102] = {power1_cpu_data[15],power1_cpu_data[15],power1_cpu_data[15],power1_cpu_data[15]};
	assign power1_rxdata_temp[101:98]  = {power1_cpu_data[14],power1_cpu_data[14],power1_cpu_data[14],power1_cpu_data[14]};
	assign power1_rxdata_temp[97:94]   = {power1_cpu_data[13],power1_cpu_data[13],power1_cpu_data[13],power1_cpu_data[13]};
	assign power1_rxdata_temp[93:90]   = {power1_cpu_data[12],power1_cpu_data[12],power1_cpu_data[12],power1_cpu_data[12]};
	assign power1_rxdata_temp[89:86]   = {power1_cpu_data[11],power1_cpu_data[11],power1_cpu_data[11],power1_cpu_data[11]};
	assign power1_rxdata_temp[85:82]   = {power1_cpu_data[10],power1_cpu_data[10],power1_cpu_data[10],power1_cpu_data[10]};
	assign power1_rxdata_temp[81:78]   = {power1_cpu_data[9],power1_cpu_data[9],power1_cpu_data[9],power1_cpu_data[9]};
	assign power1_rxdata_temp[77:74]   = {power1_cpu_data[8],power1_cpu_data[8],power1_cpu_data[8],power1_cpu_data[8]};
	assign power1_rxdata_temp[73:70]   = {power1_cpu_data[7],power1_cpu_data[7],power1_cpu_data[7],power1_cpu_data[7]};
	assign power1_rxdata_temp[69:66]   = {power1_cpu_data[6],power1_cpu_data[6],power1_cpu_data[6],power1_cpu_data[6]};
	assign power1_rxdata_temp[65:62]   = {power1_cpu_data[5],power1_cpu_data[5],power1_cpu_data[5],power1_cpu_data[5]};
	assign power1_rxdata_temp[61:58]   = {power1_cpu_data[4],power1_cpu_data[4],power1_cpu_data[4],power1_cpu_data[4]};
	assign power1_rxdata_temp[57:54]   = {power1_cpu_data[3],power1_cpu_data[3],power1_cpu_data[3],power1_cpu_data[3]};
	assign power1_rxdata_temp[53:50]   = {power1_cpu_data[2],power1_cpu_data[2],power1_cpu_data[2],power1_cpu_data[2]};
	assign power1_rxdata_temp[49:46]   = {power1_cpu_data[1],power1_cpu_data[1],power1_cpu_data[1],power1_cpu_data[1]};
	assign power1_rxdata_temp[45:42]   = {power1_cpu_data[0],power1_cpu_data[0],power1_cpu_data[0],power1_cpu_data[0]};
	assign power1_rxdata_temp[41:38]   = {1'b1,1'b1,1'b1,1'b1};
	assign power1_rxdata_temp[37:34]   = {power1_function_select[0],power1_function_select[0],power1_function_select[0],power1_function_select[0]};
	assign power1_rxdata_temp[33:30]   = {power1_function_select[1],power1_function_select[1],power1_function_select[1],power1_function_select[1]};
	assign power1_rxdata_temp[29:26]   = {power1_function_select[2],power1_function_select[2],power1_function_select[2],power1_function_select[2]};
	assign power1_rxdata_temp[25:22]   = {power1_function_select[3],power1_function_select[3],power1_function_select[3],power1_function_select[3]};
	assign power1_rxdata_temp[21:18]   = {1'b1,1'b1,1'b1,1'b1};//电源位号
	assign power1_rxdata_temp[17:14]   = {1'b1,1'b1,1'b1,1'b1};
	assign power1_rxdata_temp[13:10]   = {1'b0,1'b0,1'b0,1'b0};
	assign power1_rxdata_temp[9:6]     = {1'b1,1'b1,1'b1,1'b1};
	assign power1_rxdata_temp[5:2]     = {1'b0,1'b0,1'b0,1'b0}; 
	assign power1_rxdata_temp[1:0]     = 2'b0;
	//异或奇偶校验，相同0，不同为1，奇数个1为1，偶数个1为0
	assign parity_check6_power1 = power1_function_select[3] ^ power1_function_select[2] ^ power1_function_select[1] ^ power1_function_select[0] ^ power1_cpu_data[15] ^ power1_cpu_data[14] ^ power1_cpu_data[13] ^ power1_cpu_data[12] ^ power1_cpu_data[11] ^ power1_cpu_data[10] ^ power1_cpu_data[9] ^ power1_cpu_data[8] ^ power1_cpu_data[7] ^ power1_cpu_data[6] ^ power1_cpu_data[5] ^ power1_cpu_data[4] ^ power1_cpu_data[3] ^ power1_cpu_data[2] ^ power1_cpu_data[1] ^ power1_cpu_data[0];
//********6.3 电源2通道接收power2
	//********6.3.1 电源2发给主控逻辑数据 24位数据，时钟周期1ms，间隔200ms，电压，电流，温度（AC），循环发
	//输入power2的时钟数据处理，边沿去抖
	reg		power2_clk_temp;
	reg		power2_data_temp;
	
	always@(posedge clk_10us or negedge reset) begin
		if(!reset) begin
            power2_clk_temp<=1'b0;
        end
        else begin
			if(power2_clk) begin
				power2_clk_temp<=1'b1;
			end
			else if(!power2_clk) begin
				power2_clk_temp<=1'b0;
			end
		end
	end
	always@(posedge clk_10us or negedge reset) begin
		if(!reset) begin
            power2_data_temp<=1'b0;
        end
        else begin
			if(power2_data) begin
				power2_data_temp<=1'b1;
			end
			else if(!power2_data) begin
				power2_data_temp<=1'b0;
			end
		end
	end
	//对power2的24位数据提取
	reg  [4:0]  power2_rx_data_clear_num;
	reg         power2_rx_data_clear;	
	reg  [23:0] power2_rx_data_temp;
	reg  [4:0]  power2_rx_data_num;	
	wire [1:0]  power2_rx_function_select;
	wire		power2_position;
	wire        power2_type;
	wire [15:0] power2_data_bit;
	wire [1:0]  power2_alarm_bit;
	reg			power2_rx_data_end;
		//清0标识，0清0
	always@(posedge clk_250us or negedge reset) begin  //私有协议清0标志
		if(!reset) begin
			power2_rx_data_clear<=1'b1;
			power2_rx_data_clear_num<=0;
		end
		else begin
			if(power2_clk_temp) begin
				power2_rx_data_clear<=1'b1;
				power2_rx_data_clear_num<=0;
			end
				else if(power2_rx_data_clear_num<20) begin  //5ms等待时间
					power2_rx_data_clear_num<=power2_rx_data_clear_num+1;
					power2_rx_data_clear<=1'b1;
				end
					else if(power2_rx_data_clear_num<30) begin
						power2_rx_data_clear_num<=power2_rx_data_clear_num+1;
						power2_rx_data_clear<=1'b0;  //私有协议清0标志，0清0,持续2.5ms
					end
					else begin
						power2_rx_data_clear<=1'b1;
					end
		end
	end
		//读取串行信号
	always@(posedge power2_clk_temp or negedge reset or negedge power2_rx_data_clear) begin
		if(!reset) begin
			power2_rx_data_temp<=24'b110000000000000000000000;
			power2_rx_data_num<=0;
			power2_rx_data_end<=1'b0;
		end
		else begin
			if(!power2_rx_data_clear) begin
				power2_rx_data_num<=0;
				power2_rx_data_end<=1'b0;
			end
				else if(power2_rx_data_num<23) begin
					power2_rx_data_temp[power2_rx_data_num]<=power2_data_temp;
					power2_rx_data_num<=power2_rx_data_num+1;
				end
					else begin
						power2_rx_data_temp[power2_rx_data_num]<=power2_data_temp;
						power2_rx_data_num<=0;
						power2_rx_data_end<=1'b1;  //数据结束为1，持续5ms
					end
		end
	end
		
	assign power2_position = power2_rx_data_temp[0];	
	assign power2_type = power2_rx_data_temp[1];
	assign power2_rx_function_select[1] = power2_rx_data_temp[2];
	assign power2_rx_function_select[0] = power2_rx_data_temp[3];
	//********6.3.2 power2按功能存储数据
	reg [15:0]	power2_voltage_data_bit;
	reg [1:0]	power2_voltage_alarm_bit;
	reg [15:0]	power2_current_data_bit;
	reg 		power2_current_alarm_bit;
	reg [15:0]	power2_temperature_data_bit;
	reg 		power2_temperature_alarm_bit;
	
	always@(posedge clk_25m) begin
		if(power2_rx_data_end) begin
			case(power2_rx_function_select)
				2'b00:begin
					power2_voltage_data_bit[15:0] = power2_rx_data_temp[19:4]; //注意低位是实际数据的高位
					power2_voltage_alarm_bit[1] =  power2_rx_data_temp[20];
					power2_voltage_alarm_bit[0] =  power2_rx_data_temp[21];
				end
				2'b01:begin
					power2_current_data_bit[15:0] = power2_rx_data_temp[19:4];
					power2_current_alarm_bit = ~ power2_rx_data_temp[20];
				end
				2'b10:begin
					power2_temperature_data_bit[15:0] = power2_rx_data_temp[19:4];
					power2_temperature_alarm_bit = power2_rx_data_temp[20];
				end
			endcase
		end
	end
	
	//6.3.3 power2按功能发送数据给cpu
	// power2按照功能位给与数据
	reg	[15:0] power2_cpu_data;
	
	always@(posedge clk_25m) begin
		case(power2_function_select)
			4'b1100:begin  //电压
				power2_cpu_data[15:0] = power2_voltage_data_bit[15:0];
			end
			4'b1101:begin  //电流
				power2_cpu_data[15:0] = power2_current_data_bit[15:0];
			end
			4'b1110:begin  //温度，ac才有
				power2_cpu_data[15:0] = power2_temperature_data_bit[15:0];
			end
			4'b1111:begin  //告警
				power2_cpu_data[0] = power2_type;
				power2_cpu_data[1] = power2_voltage_alarm_bit[1];
				power2_cpu_data[2] = power2_voltage_alarm_bit[0];
				power2_cpu_data[3] = power2_temperature_alarm_bit;
				power2_cpu_data[4] = power2_current_alarm_bit;
				power2_cpu_data[15:5] = 11'b11111111111;
			end
		endcase
	end			
	//power2数据回复给主控
	wire [131:0] power2_rxclk_temp;
	wire [131:0] power2_rxdata_temp;
	reg  [7:0]   power2_to_cpu_num; 
	wire		parity_check6_power2;
	
	always@(posedge clk_1ms or negedge reset_temp ) begin
		if(!reset_temp) begin
			power2_to_cpu_num<=0;
			power2_rx_clk<=1'b0;
			power2_rx_data<=1'b0;
		end
		else begin
			if(power2_read_star) begin  //为1清0，0发送。
				power2_to_cpu_num<=0;
			end
				else if(power2_to_cpu_num<132) begin
					power2_rx_clk<= power2_rxclk_temp[power2_to_cpu_num];
					power2_rx_data<= power2_rxdata_temp[power2_to_cpu_num];
					power2_to_cpu_num<=power2_to_cpu_num+1;
				end
		end
	end
		//串行时钟
	assign power2_rxclk_temp = {2'b00,{32{4'b0011}},2'b00};
		//串行数据
	assign power2_rxdata_temp[131:130] = 2'b0;
	assign power2_rxdata_temp[129:126] = {parity_check6_power2,parity_check6_power2,parity_check6_power2,parity_check6_power2};  //31
	assign power2_rxdata_temp[125:122] = {1'b0,1'b0,1'b0,1'b0};
	assign power2_rxdata_temp[121:118] = {1'b0,1'b0,1'b0,1'b0};
	assign power2_rxdata_temp[117:114] = {1'b0,1'b0,1'b0,1'b0};
	assign power2_rxdata_temp[113:110] = {1'b0,1'b0,1'b0,1'b0};  //27
	assign power2_rxdata_temp[109:106] = {1'b0,1'b0,1'b0,1'b0};
	assign power2_rxdata_temp[105:102] = {power2_cpu_data[15],power2_cpu_data[15],power2_cpu_data[15],power2_cpu_data[15]};
	assign power2_rxdata_temp[101:98]  = {power2_cpu_data[14],power2_cpu_data[14],power2_cpu_data[14],power2_cpu_data[14]};
	assign power2_rxdata_temp[97:94]   = {power2_cpu_data[13],power2_cpu_data[13],power2_cpu_data[13],power2_cpu_data[13]};
	assign power2_rxdata_temp[93:90]   = {power2_cpu_data[12],power2_cpu_data[12],power2_cpu_data[12],power2_cpu_data[12]};
	assign power2_rxdata_temp[89:86]   = {power2_cpu_data[11],power2_cpu_data[11],power2_cpu_data[11],power2_cpu_data[11]};
	assign power2_rxdata_temp[85:82]   = {power2_cpu_data[10],power2_cpu_data[10],power2_cpu_data[10],power2_cpu_data[10]};
	assign power2_rxdata_temp[81:78]   = {power2_cpu_data[9],power2_cpu_data[9],power2_cpu_data[9],power2_cpu_data[9]};
	assign power2_rxdata_temp[77:74]   = {power2_cpu_data[8],power2_cpu_data[8],power2_cpu_data[8],power2_cpu_data[8]};
	assign power2_rxdata_temp[73:70]   = {power2_cpu_data[7],power2_cpu_data[7],power2_cpu_data[7],power2_cpu_data[7]};
	assign power2_rxdata_temp[69:66]   = {power2_cpu_data[6],power2_cpu_data[6],power2_cpu_data[6],power2_cpu_data[6]};
	assign power2_rxdata_temp[65:62]   = {power2_cpu_data[5],power2_cpu_data[5],power2_cpu_data[5],power2_cpu_data[5]};
	assign power2_rxdata_temp[61:58]   = {power2_cpu_data[4],power2_cpu_data[4],power2_cpu_data[4],power2_cpu_data[4]};
	assign power2_rxdata_temp[57:54]   = {power2_cpu_data[3],power2_cpu_data[3],power2_cpu_data[3],power2_cpu_data[3]};
	assign power2_rxdata_temp[53:50]   = {power2_cpu_data[2],power2_cpu_data[2],power2_cpu_data[2],power2_cpu_data[2]};
	assign power2_rxdata_temp[49:46]   = {power2_cpu_data[1],power2_cpu_data[1],power2_cpu_data[1],power2_cpu_data[1]};
	assign power2_rxdata_temp[45:42]   = {power2_cpu_data[0],power2_cpu_data[0],power2_cpu_data[0],power2_cpu_data[0]};
	assign power2_rxdata_temp[41:38]   = {1'b1,1'b1,1'b1,1'b1};
	assign power2_rxdata_temp[37:34]   = {power2_function_select[0],power2_function_select[0],power2_function_select[0],power2_function_select[0]};
	assign power2_rxdata_temp[33:30]   = {power2_function_select[1],power2_function_select[1],power2_function_select[1],power2_function_select[1]};
	assign power2_rxdata_temp[29:26]   = {power2_function_select[2],power2_function_select[2],power2_function_select[2],power2_function_select[2]};
	assign power2_rxdata_temp[25:22]   = {power2_function_select[3],power2_function_select[3],power2_function_select[3],power2_function_select[3]};
	assign power2_rxdata_temp[21:18]   = {1'b0,1'b0,1'b0,1'b0}; //电源位号
	assign power2_rxdata_temp[17:14]   = {1'b0,1'b0,1'b0,1'b0}; 
	assign power2_rxdata_temp[13:10]   = {1'b1,1'b1,1'b1,1'b1};
	assign power2_rxdata_temp[9:6]     = {1'b1,1'b1,1'b1,1'b1};
	assign power2_rxdata_temp[5:2]     = {1'b0,1'b0,1'b0,1'b0}; 
	assign power2_rxdata_temp[1:0]     = 2'b0;
	//异或奇偶校验，相同0，不同为1，奇数个1为1，偶数个1为0
	assign parity_check6_power2 = power2_function_select[3] ^ power2_function_select[2] ^ power2_function_select[1] ^ power2_function_select[0] ^ power2_cpu_data[15] ^ power2_cpu_data[14] ^ power2_cpu_data[13] ^ power2_cpu_data[12] ^ power2_cpu_data[11] ^ power2_cpu_data[10] ^ power2_cpu_data[9] ^ power2_cpu_data[8] ^ power2_cpu_data[7] ^ power2_cpu_data[6] ^ power2_cpu_data[5] ^ power2_cpu_data[4] ^ power2_cpu_data[3] ^ power2_cpu_data[2] ^ power2_cpu_data[1] ^ power2_cpu_data[0] ^ 1'b1;
//****************私有协议7 protocol7:接收通道，告诉板卡再位信息：下降沿发送,周期4ms，间隔20ms****************//
	wire [131:0] cpu_rx_clk1_temp;
	wire [131:0] cpu_rx_data1_temp;
	reg  [7:0]   cpu_rx_num7; 
	reg          cpu_rx_data1;
	reg          cpu_rx_clk1;
	wire		main1_panel_detec;
	wire		main2_panel_detec;
	wire		parity_check7;


	always@(posedge clk_1ms or negedge reset_temp) begin      //  产生串行时钟
		if(!reset_temp) begin
			cpu_rx_num7<=0;
			cpu_rx_clk1<=1'b0;
			cpu_rx_data1<=1'b0;
		end
		else begin
			if(cpu_rx_num7<132) begin
				cpu_rx_clk1<= cpu_rx_clk1_temp[cpu_rx_num7];
				cpu_rx_data1<= cpu_rx_data1_temp[cpu_rx_num7];
				cpu_rx_num7<=cpu_rx_num7+1;
			end
				else if(cpu_rx_num7<151) begin //间隔20ms
					cpu_rx_clk1<= 1'b0;
					cpu_rx_data1<= 1'b0;
					cpu_rx_num7<=cpu_rx_num7+1;
				end
				else begin
					cpu_rx_num7<=0;	
				end
		end
	end
	//串行时钟
	assign cpu_rx_clk1_temp = {2'b00,{32{4'b0011}},2'b00};
	//串行数据
	assign cpu_rx_data1_temp[131:130] = 2'b0;
	assign cpu_rx_data1_temp[129:126] = {parity_check7,parity_check7,parity_check7,parity_check7};
	assign cpu_rx_data1_temp[125:122] = {1'b0,1'b0,1'b0,1'b0};
	assign cpu_rx_data1_temp[121:118] = {1'b0,1'b0,1'b0,1'b0};
	assign cpu_rx_data1_temp[117:114] = {1'b0,1'b0,1'b0,1'b0};
	assign cpu_rx_data1_temp[113:110] = {1'b0,1'b0,1'b0,1'b0};
	assign cpu_rx_data1_temp[109:106] = {1'b0,1'b0,1'b0,1'b0};
	assign cpu_rx_data1_temp[105:102] = {1'b0,1'b0,1'b0,1'b0};
	assign cpu_rx_data1_temp[101:98]  = {1'b0,1'b0,1'b0,1'b0};
	assign cpu_rx_data1_temp[97:94]   = {1'b1,1'b1,1'b1,1'b1};
	assign cpu_rx_data1_temp[93:90]   = {1'b1,1'b1,1'b1,1'b1};
	assign cpu_rx_data1_temp[89:86]   = {1'b1,1'b1,1'b1,1'b1};
	assign cpu_rx_data1_temp[85:82]   = {1'b1,1'b1,1'b1,1'b1};
	assign cpu_rx_data1_temp[81:78]   = {1'b1,1'b1,1'b1,1'b1};
	assign cpu_rx_data1_temp[77:74]   = {1'b1,1'b1,1'b1,1'b1};
	assign cpu_rx_data1_temp[73:70]   = {1'b1,1'b1,1'b1,1'b1};
	assign cpu_rx_data1_temp[69:66]   = {1'b1,1'b1,1'b1,1'b1};
	assign cpu_rx_data1_temp[65:62]   = {1'b1,1'b1,1'b1,1'b1};
	assign cpu_rx_data1_temp[61:58]   = {1'b1,1'b1,1'b1,1'b1};
	assign cpu_rx_data1_temp[57:54]   = {1'b1,1'b1,1'b1,1'b1};
	assign cpu_rx_data1_temp[53:50]   = {~power2_present,~power2_present,~power2_present,~power2_present}; //12位
	assign cpu_rx_data1_temp[49:46]   = {~power1_present,~power1_present,~power1_present,~power1_present};
	assign cpu_rx_data1_temp[45:42]   = {1'b0,1'b0,1'b0,1'b0};
	assign cpu_rx_data1_temp[41:38]   = {~x7_present,~x7_present,~x7_present,~x7_present};
	assign cpu_rx_data1_temp[37:34]   = {~x6_present,~x6_present,~x6_present,~x6_present};
	assign cpu_rx_data1_temp[33:30]   = {~x5_present,~x5_present,~x5_present,~x5_present};
	assign cpu_rx_data1_temp[29:26]   = {main2_panel_detec,main2_panel_detec,main2_panel_detec,main2_panel_detec};
	assign cpu_rx_data1_temp[25:22]   = {main1_panel_detec,main1_panel_detec,main1_panel_detec,main1_panel_detec};
	assign cpu_rx_data1_temp[21:18]   = {~x4_present,~x4_present,~x4_present,~x4_present};
	assign cpu_rx_data1_temp[17:14]   = {~x3_present,~x3_present,~x3_present,~x3_present};
	assign cpu_rx_data1_temp[13:10]   = {~x2_present,~x2_present,~x2_present,~x2_present};
	assign cpu_rx_data1_temp[9:6]     = {~x1_present,~x1_present,~x1_present,~x1_present};
	assign cpu_rx_data1_temp[5:2]     = {~fan_panel_detec,~fan_panel_detec,~fan_panel_detec,~fan_panel_detec};
	assign cpu_rx_data1_temp[1:0]	  = 2'b0;
	//异或奇偶校验，相同0，不同为1，奇数个1为1，偶数个1为0
	assign parity_check7 = (~fan_panel_detec) ^ (~x1_present) ^ (~x2_present) ^ (~x3_present) ^ (~x4_present) ^ main1_panel_detec ^ main2_panel_detec ^ (~x5_present) ^ (~x6_present) ^ (~x7_present) ^ (~power1_present) ^ (~power2_present)^ 1'b1;
	//主控板卡号：1：5主控1，0：6主控2
	assign main1_panel_detec = main_present? main_present : ~ another_main_present;
	assign main2_panel_detec = ~ main_present? ~ main_present : ~ another_main_present;
	
    //测试用注释
    reg test1;
endmodule