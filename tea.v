/*
* Verilog implementation of Tiny Encryption Algorithm (TEA)
* This is a single module that implements both encryption and decryption.
* Tested with using Icarus Verilog.
*
* To save I/O pins, the 128-bit key is written using the 64-bit wide input and
* stored in a register.
*
* Initialization:
* - Set `writekey` to 1 and `in` to the first half of the key. It will be read
*   on positive clock edge.
* - In the next clock cycle, set `writekey` to 0 and set `in` to the second
*   half of the key.
*
* After that, all the data appearing at the input will be encrypted/decrypted
* and set to output.
*
* Mode selection:
* - Set `mode` to 0 for encryption
* - Set `mode` to 1 for decryption
*
* WARNING: The encryption/decryption logic is currently a big, purely
* combinatorial circuit.  If it even fits on a real FPGA, the delays will be
* large and max frequency small.
*/

module tea_interface(input [63:0] in, input mode, input writekey, input clk, output [63:0] out);
    reg[127:0] key;
    reg waiting_key;

    localparam rounds = 32;
    localparam swapbytes = 1;

    localparam DELTA = 32'h9E3779B9;

    function [31:0] tea_round_func (input[31:0] vhalf, input[63:0] khalf, input[31:0] sum);
        begin
            tea_round_func = ((vhalf << 4) + khalf[63:32]) ^ 
                             (vhalf + sum) ^
                             ((vhalf >> 5) + khalf[31:0]);
        end
    endfunction

    function [63:0] encrypt_nrounds(input[63:0] v, input[127:0] k, input integer n);
        integer sum;
        begin
            sum = 0;
            encrypt_nrounds = v;
            for(integer i=0; i<n; i = i+1) begin
                sum = sum + DELTA;
                encrypt_nrounds[63:32] += tea_round_func(encrypt_nrounds[31:0] , k[127:64], sum);
                encrypt_nrounds[31:0]  += tea_round_func(encrypt_nrounds[63:32], k[63:0],   sum);
            end
        end
    endfunction

    function [63:0] decrypt_nrounds(input[63:0] v, input[127:0] k, input integer n);
        integer sum;
        begin
            sum = rounds*DELTA;
            decrypt_nrounds = v;
            for(integer i=0; i<n; i = i+1) begin
                decrypt_nrounds[31:0]  -= tea_round_func(decrypt_nrounds[63:32], k[63:0],   sum);
                decrypt_nrounds[63:32] -= tea_round_func(decrypt_nrounds[31:0],  k[127:64], sum);
                sum = sum - DELTA;
            end
        end
    endfunction

    always@(posedge clk) begin
        if (writekey) begin
            key[127:64] = in;
            waiting_key = 1;
        end else if (waiting_key) begin
            waiting_key = 0;
            key[63:0] = in;
            $display("key %x %x", key[127:64], key[63:0]);
        end else if (mode == 0) begin
            waiting_key = 0;
        end
    end

    function [31:0] byteswap32(input[31:0] x);
        byteswap32 = {x[7:0], x[15:8], x[23:16], x[31:24]};
    endfunction
    function [63:0] le32_blocks64(input[63:0] x);
        le32_blocks64 = {
            byteswap32(x[63:32]),
            byteswap32(x[31:0])
        };
    endfunction
    function [127:0] le32_blocks128(input[127:0] x);
        le32_blocks128 = {
            le32_blocks64(x[127:64]),
            le32_blocks64(x[63:0])
        };
    endfunction

    function [63:0] compute_out(input mode, input[63:0] in, input[127:0] key, input integer rounds);
        begin
            if(swapbytes) begin
                in = le32_blocks64(in);
                key = le32_blocks128(key);
            end

            if (mode == 0)
                compute_out = encrypt_nrounds(in, key, rounds);
            else
                compute_out = decrypt_nrounds(in, key, rounds);

            if(swapbytes)
                compute_out = le32_blocks64(compute_out);
        end
    endfunction

    assign out = compute_out(mode,in,key,rounds);
endmodule

