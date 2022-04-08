module tea_interface(input [63:0] in, input mode, input writekey, input clk, output [63:0] out);
    reg[127:0] key;
    reg waiting_key;

    localparam rounds = 32;

    wire[63:0] enc_out, dec_out;
    tea_encrypt enc(in, key, enc_out);
    tea_decrypt dec(in, key, dec_out);

    defparam enc.rounds = rounds;
    defparam dec.rounds = rounds;

    always@(posedge clk) begin
        if (writekey) begin
            key[127:64] = in;
            waiting_key = 1;
        end else if (waiting_key) begin
            waiting_key = 0;
            key[63:0] = in;
            //$display("key %x", key);
        end else if (mode == 0) begin
            waiting_key = 0;
        end
    end 

    assign out = mode ? dec_out : enc_out;
endmodule

module tea_test;
    localparam key = 128'h12121212343434345656565678787878;
    reg [63:0] in;
    wire [63:0] out;

    reg mode, writekey;
    reg clk;
    tea_interface iface(in, mode, writekey, clk, out);

    always #1 clk = !clk;

    initial begin
        clk = 0;
        in = key[127:64];
        mode = 0;
        writekey = 1;
        #2
        writekey = 0;
        in = key[63:0];
        #2
        in = 64'h1234567812345678;
        #2
        $display("%x", out);
        in = out;
        #2
        mode = 1;
        #2
        $display("%x", out);
        $finish;
    end
endmodule
