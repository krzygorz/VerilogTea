function [31:0] tea_round_func (input[31:0] vhalf, input[63:0] khalf, input[31:0] sum);
    begin
        tea_round_func=((vhalf << 4) + khalf[31:0]) ^ 
                       (vhalf + sum) ^
                       ((vhalf >> 5) + khalf[63:32]);
    end
endfunction
