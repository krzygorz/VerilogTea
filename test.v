module tea_test;
    reg [63:0] in;
    wire [63:0] out;
    wire out_ready;
    reg mode, reset, write;
    reg clk;
    tea_interface iface(in, mode, reset, write, clk, out, out_ready);

    always #1 clk = !clk;

    task set_key(input[127:0] key);
    begin
        reset = 1;
        in = key[127:64];
        #2
        reset = 0;
        in = key[63:0];
        #2;
    end
    endtask

    task run_with_data(input[63:0] testdata, input _mode);
    begin
        //send input data
        mode = _mode;
        write = 1;
        in = testdata;
        #2;
        write = 0;
        for(integer i=1; i<= 31; i++) begin
            #2;
            if (out_ready)
                $display("out_ready too soon: %d/32", i);
        end
        #2;
        #2;
        if (!out_ready)
                $display("out_ready not set after 32 cycles");
    end
    endtask

    task test_enc_dec(input[63:0] testdata, input[63:0] expected, input[127:0] key);
        begin
        set_key(key);
        run_with_data(testdata, 0);

        if (out !== expected)
            $display("ERROR: wrong enc(x): %x != %x", out, expected);
        $display("enc %x", out);

        run_with_data(out, 1);
        $display("dec %x", out);
        if (out !== testdata)
            $display("ERROR: dec(enc(x)) != x: %x != %x", out, testdata);
        end
    endtask

    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, tea_test);

        clk = 0;

        test_enc_dec(64'h74657374206d652e, 64'h775d2a6af6ce9209, 128'h2b02056806144976775d0e266c287843);

        $finish;
    end
endmodule
