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

        test_enc_dec(64'h0000000000000000, 64'h0a3aea4140a9ba94, 128'h00000000000000000000000000000000);
        test_enc_dec(64'h74657374206d652e, 64'h775d2a6af6ce9209, 128'h2b02056806144976775d0e266c287843);
        test_enc_dec(64'h6c6f6e6765725f74, 64'hbe7abb81952d1f1e, 128'h0965431166443925513a16100a08126e);
        test_enc_dec(64'h6573745f76656374, 64'hdd89a1250421df95, 128'h0965431166443925513a16100a08126e);

        test_enc_dec(64'h5465612069732067, 64'he04d5d3cb78c3647, 128'h4d763217053f752c5d0416361572632f);
        test_enc_dec(64'h6f6f6420666f7220, 64'h94189591a9fc49f8, 128'h4d763217053f752c5d0416361572632f);
        test_enc_dec(64'h796f752121212072, 64'h44d12dc299b8082a, 128'h4d763217053f752c5d0416361572632f);
        test_enc_dec(64'h65616c6c79212121, 64'h078973c24592c690, 128'h4d763217053f752c5d0416361572632f);
        $finish;
    end
endmodule
