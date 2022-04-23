/*
* Verilog implementation of Tiny Encryption Algorithm (TEA)
* This is a single module that implements both encryption and decryption.
* Tested with using Icarus Verilog.
*
* This file defines two modules:
* - `tea_enc_dec` - Implementation of the encoding and decoding.
* - `tea_interface` - Exposes a more user-friendly interface. To save I/O pins,
*   the 128-bit key is written using the 64-bit wide input and stored in a
*   register. The rest of the comments apply to this module.
*
* Initialization:
* - Set `reset` to 1 and `in` to the first half of the key. It will be read
*   on positive clock edge.
* - In the next clock cycle, set `reset` to 0 and set `in` to the second
*   half of the key.
*
* Writing data:
* - Set `mode`
*   - 0 for encryption
*   - 1 for decryption
* - Set `writedata` to 1 and set `in` to the data to be encrypted/decrypted
* - After a positive clock edge set `writedata` to 0 and wait for 32 clock cycles.
* - Read the output from out.
*
* The total time from inputting the data to output is therefore 33 cycles, where the
* first cycle is for writing the data.
*
* By default, the interface module interprets 64-bit data as two 32-bit
* little-endian integers. To use big-endian instead, set the parameter
* `swapbytes` to 0. See ref.c for more discussion on endianness issues.
*/

module tea_enc_dec (
    input [63:0] in,
    input [127:0] key,
    input mode,
    input reset,
    input write,
    input clk,
    output reg [63:0] out,
    output reg out_ready
);
    parameter rounds = 32;
    parameter swapbytes = 1;

    reg[31:0] sum;
    reg[5:0] round_counter;

    localparam DELTA = 32'h9E3779B9;

    function [31:0] tea_round_func (input[31:0] vhalf, input[63:0] khalf, input[31:0] sum);
        begin
            tea_round_func = ((vhalf << 4) + khalf[63:32]) ^
                             (vhalf + sum) ^
                             ((vhalf >> 5) + khalf[31:0]);
        end
    endfunction

    function [63:0] encrypt_cycle(input[63:0] v, input[127:0] k, input[63:0] sum);
        begin
            encrypt_cycle = v;
            encrypt_cycle[63:32] += tea_round_func(encrypt_cycle[31:0] , k[127:64], sum);
            encrypt_cycle[31:0]  += tea_round_func(encrypt_cycle[63:32], k[63:0],   sum);
        end
    endfunction

    function [63:0] decrypt_cycle(input[63:0] v, input[127:0] k, input [63:0] sum);
        begin
            decrypt_cycle = v;
            decrypt_cycle[31:0]  -= tea_round_func(decrypt_cycle[63:32], k[63:0],   sum);
            decrypt_cycle[63:32] -= tea_round_func(decrypt_cycle[31:0],  k[127:64], sum);
        end
    endfunction

    always@(posedge clk) begin
        $display("%d %x %x %b",round_counter, sum, out, mode);
        if (reset) begin
            round_counter <= 0;
            out_ready <= 0;
        end else if (write) begin
            round_counter <= 0;
            out <= in;
            sum <= mode ? (rounds)*DELTA : DELTA;
            out_ready <= 0;
        end else if (round_counter < rounds) begin
            round_counter <= round_counter + 1;
            if(mode == 0) begin
                out <= encrypt_cycle(out, key, sum);
                sum <= sum + DELTA;
            end else begin
                out <= decrypt_cycle(out, key, sum);
                sum <= sum - DELTA;
            end
        end else
            out_ready <= 1;
    end
endmodule

module tea_interface(
    input [63:0] in,
    input mode,
    input reset,
    input write,
    input clk,
    output [63:0] out,
    output out_ready
);
    parameter swapbytes = 1;

    wire [63:0] encdec_out;
    wire [63:0] unswapped_in;

    reg[127:0] key;
    reg waiting_key;

    assign unswapped_in = swapbytes ? byteswap32_64(in) : in;
    assign out = swapbytes ? byteswap32_64(encdec_out) : encdec_out;

    tea_enc_dec encdec(unswapped_in, key, mode, reset, write, clk, encdec_out, out_ready);

    function [31:0] byteswap32(input[31:0] x);
        byteswap32 = {x[7:0], x[15:8], x[23:16], x[31:24]};
    endfunction
    function [63:0] byteswap32_64(input[63:0] x);
        byteswap32_64 = {
            byteswap32(x[63:32]),
            byteswap32(x[31:0])
        };
    endfunction

    always@(posedge clk) begin
        if (reset) begin
            key[127:64] <= unswapped_in;
            waiting_key <= 1;
        end else if (waiting_key) begin
            key[63:0] <= unswapped_in;
            waiting_key <= 0;
        end
    end
endmodule
