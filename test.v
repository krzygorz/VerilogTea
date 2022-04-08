module test;
wire [63:0] out;
wire [63:0] out1;
//tea_encrypt enc(64'h1234567812345678,128'h12345678123456781234567812345678,out);
tea_encrypt enc(64'h1234567812345678,128'h12121212343434345656565678787878,out);
//tea_decrypt dec(out,128'h12345678123456781234567812345678,out1);
initial begin
        #2;
        $monitor("%h",out);
//        #2;
//        $monitor("%h",out1);
        #2;
end
    
endmodule
