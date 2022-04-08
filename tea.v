module tea_encrypt (input [63:0] v, input [127:0] k, output [63:0] out);
    parameter rounds = 32;
    `include "tea_round.v"
    localparam DELTA = 32'h9E3779B9;
    function [63:0] tea_cycle (input[63:0] v, input[127:0] k, input[32:0] sum);
        logic[31:0] tmp1, tmp2;
        begin
            tmp1=v[63:32]+tea_round_func(v[31:0],k[63:0], sum);
            tmp2=v[31:0]+tea_round_func(tmp1,k[127:64], sum);
            tea_cycle = {tmp1,tmp2};
        end
    endfunction

    function [63:0] tea_iter(input[63:0] v, input[127:0] k, input integer n);
        integer sum;
        begin
            sum = 0;
            tea_iter = v;
            for(integer i=0; i<n; i = i+1) begin
                sum = sum + DELTA;
                tea_iter[63:32] = tea_iter[63:32]+tea_round_func(tea_iter[31:0] , k[63:0],   sum);
                tea_iter[31:0]  = tea_iter[31:0] +tea_round_func(tea_iter[63:32], k[127:64], sum);
                //tea_iter = tea_cycle(tea_iter,k,sum);
            end
        end
    endfunction

    assign out=tea_iter(v,k,rounds);
endmodule

module tea_decrypt(input [63:0] v, input [127:0] k, output [63:0] out);
    parameter rounds = 32;
    `include "tea_round.v"
    localparam DELTA = 32'h9E3779B9;
    localparam SUM_START = rounds*DELTA;
    function [63:0] tea_cycle (input[63:0] v, input[127:0] k, input[32:0] sum);
        begin
            tea_cycle[31:0]=v[31:0]-tea_round_func(v[63:32],k[127:64], sum);
            tea_cycle[63:32]=v[63:32]-tea_round_func(tea_cycle[31:0],k[63:0], sum);
        end
    endfunction

    function [63:0] tea_iter(input[63:0] v, input[127:0] k, input integer n);
        integer sum;
        begin
            sum = SUM_START;
            tea_iter = v;
            for(integer i=0; i<n; i = i+1) begin
                tea_iter = tea_cycle(tea_iter,k,sum);
                sum = sum - DELTA;
            end
        end
    endfunction
    
    assign out=tea_iter(v,k,rounds);
endmodule
