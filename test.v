module tea_test;
    localparam key = 128'h1234567890abcdeffedcba0987654321;
    //localparam key = 128'h12345678123456781234567812345678;
    reg [63:0] in;
    wire [63:0] out;

    reg mode, writekey;
    reg clk;
    tea_interface iface(in, mode, writekey, clk, out);

    always #1 clk = !clk;

    localparam testdata = 64'h1234567890abcdef;

    initial begin
        clk = 0;

        //send first half of the key
        in = key[127:64];
        mode = 0;
        writekey = 1;
        #2
        //send second half of the key
        writekey = 0;
        in = key[63:0];
        #2
        //send input data
        in = testdata;
        #2
        $display("%x", out);
        //now decrypt the received output
        in = out;
        mode = 1;
        #0.1
        $display("%x", out);
        if (out != testdata)
            $display("ERROR: dec(enc(x)) != x: %x != %x", out, testdata);
        $finish;
    end
endmodule
