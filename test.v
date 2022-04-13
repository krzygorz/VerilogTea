module tea_test;
    reg [63:0] in;
    wire [63:0] out;

    reg mode, writekey;
    reg clk;
    tea_interface iface(in, mode, writekey, clk, out);

    always #1 clk = !clk;

    task test(input[63:0] testdata, input[63:0] expected, input[127:0] key);
        begin
        //send first half of the key
        in = key[127:64];
        mode = 0; //encryption
        writekey = 1;
        #2
        //send second half of the key
        writekey = 0;
        in = key[63:0];
        #2
        //send input data
        in = testdata;
        #2
        if (out != expected)
            $display("ERROR: wrong enc(x): %x != %x", out, expected);
        $display("%x", out);
        //now decrypt the received output
        in = out;
        mode = 1; //decryption
        #0.1
        $display("%x", out);
        if (out != testdata)
            $display("ERROR: dec(enc(x)) != x: %x != %x", out, testdata);
        end
    endtask

    initial begin
        clk = 0;

        test(64'h74657374206d652e, 64'h775d2a6af6ce9209, 128'h2b02056806144976775d0e266c287843);

        $finish;
    end
endmodule
