module fan_fg(
        input         clk_10us,
        input         reset_temp,
        input         fan_detec,
        output  [1:0] fan_detec_bit
);

    reg [1:0] fan_detec_bit;

	/*根据规格书T=60/N,T这里是两个周期，N是转速，波形的占空比为50%，单周期持续的时间是T/2=30/N 秒

    对于6000转的风扇设三档转速：
	25%转速是3000转（误差±20%为2400~3600转），使用10us时钟计数一个周期，计数范围为833~1250
	50%转速是4500转（误差±15%为3825~5175转），使用10us时钟计数一个周期，计数范围为580~784
	100%转速是6000转（误差±10%为5400~6600转），使用10us时钟计数一个周期，计数范围为455~556
    每两个范围之间取平均值得到：455~578~780~1250

    对于5000转的风扇设三档转速：
    50%转速是2500转（误差±15%为2125~2875转），使用10us时钟计数一个周期，计数范围为1043~1412
	75%转速是3750转（误差±10%为3375~4125转），使用10us时钟计数一个周期，计数范围为727~889
	100%转速是5000转（误差±10%为4500~5500转），使用10us时钟计数一个周期，计数范围为545~667


    设定低于1500转以下是停转，使用10us时钟计数一个周期，计数为2000
    */
    parameter  FAN_STOP_CNT = 2000;

    // ====================== FG信号同步与双边沿检测 =======================
    reg [2:0] fg_sync;
    reg fg_rising_edge_d;      // 寄存的上升沿检测信号
    reg fg_falling_edge_d;     // 寄存的下降沿检测信号
    wire fg_rising_edge, fg_falling_edge, fg_any_edge;

    always @(posedge clk_10us or negedge reset_temp) begin
        if (!reset_temp) begin
            fg_sync <= 3'b0;
            fg_rising_edge_d <= 1'b0;
            fg_falling_edge_d <= 1'b0;
        end
        else begin
            fg_sync <= {fg_sync[1:0], fan_detec};
            // 将边沿检测结果寄存一拍，确保时序稳定
            fg_rising_edge_d <= (fg_sync[2:1] == 2'b01);
            fg_falling_edge_d <= (fg_sync[2:1] == 2'b10);
        end
    end

    // 使用寄存后的信号
    assign fg_rising_edge = fg_rising_edge_d;
    assign fg_falling_edge = fg_falling_edge_d;
    assign fg_any_edge = fg_rising_edge | fg_falling_edge;


    // ====================== 停转检测计数器 =======================
    reg [10:0] stop_cnt;
    reg        fan_stopped;

    always @(posedge clk_10us or negedge reset_temp) begin
        if (!reset_temp) begin
            stop_cnt <= (FAN_STOP_CNT/2);   //由于是用任意边沿检测，计数只需计一半
            fan_stopped = 1'b1;
        end
        else begin
            if (fg_any_edge) begin
                stop_cnt <= 11'b0;
                fan_stopped = 1'b0;
            end
            else begin
                if (stop_cnt < (FAN_STOP_CNT/2)) begin
                    stop_cnt <= stop_cnt + 1;
                end
                else begin
                    fan_stopped = 1'b1;
                end
            end
        end
    end


    // ====================== 周期测量 ========================
    reg [10:0] period_cnt;
    reg [10:0] last_period;
    reg        pulse_valid;

    always @(posedge clk_10us or negedge reset_temp) begin
        if (!reset_temp) begin
            period_cnt <= 11'b0;
            last_period <= 11'b0;
            pulse_valid <= 1'b0;
        end
        else begin
            if (fan_stopped) begin
                pulse_valid <= 1'b0;
                period_cnt <= 11'b0;
            end
            else begin
                if (fg_rising_edge) begin
                    if (period_cnt > 11'b0) begin
                        last_period <= period_cnt;
                        pulse_valid <= 1'b1;
                    end
                    period_cnt <= 0;
                end
                else begin
                    period_cnt <= period_cnt + 1;
                end
            end
        end
    end


    // ====================== 判断转速 =======================
    always @(posedge clk_10us or negedge reset_temp) begin
        if (!reset_temp) begin
            fan_detec_bit <= 2'b00;
        end
        else begin
            if (fan_stopped) begin
                fan_detec_bit <= 2'b00;
            end
            else if (pulse_valid) begin
                if (last_period > 1500) begin               //停转（1250+250避免误判）
                    fan_detec_bit <= 2'b00;
                end
                else begin
                    if(last_period > 780) begin             //低速
                        fan_detec_bit <= 2'b01;
                    end
                    else begin
                        if(last_period > 578) begin         //中速
                            fan_detec_bit <= 2'b10;
                        end
                        else begin
                            if(last_period > 455) begin     //高速
                                fan_detec_bit <= 2'b11;
                            end                            
                        end 
                    end
                end
            end
        end
    end



endmodule