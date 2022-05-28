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
* - Set `write` to 1 and set `in` to the data to be encrypted/decrypted
* - After a positive clock edge set `write` to 0 and wait for 32 clock cycles.
* - Read the output from out.
*
* The total time from inputting the data to output is therefore 33 cycles, where the
* first cycle is for writing the data.
*
* By default, the interface module interprets 64-bit data as two 32-bit
* little-endian integers. This makes using the Linux test vectors more
* convenient. To use big-endian instead, set the parameter `swapbytes` to 0.
*/

module tea_enc_dec (
    input [63:0] in,
    input [127:0] key,
    input mode,
    input write,
    input clk,
    output reg [63:0] out,
    output reg out_ready
);
    //The `out` register is also used for intermediate data.
    
    //The number of rounds can be changed to obtain a variant of the usual TEA.
    parameter rounds = 32;

    reg[31:0] sum;
    reg[5:0] round_counter;

    localparam DELTA = 32'h9E3779B9;

    /*
    * Computes a single round(half-cycle) of TEA. The output of this should be
    * added to the appropriate half of register v. Used both for encryption
    * and decryption.
    */
    function [31:0] tea_round_func (input[31:0] vhalf, input[63:0] khalf, input[31:0] sum);
        begin
            tea_round_func = ((vhalf << 4) + khalf[63:32]) ^
                             (vhalf + sum) ^
                             ((vhalf >> 5) + khalf[31:0]);
        end
    endfunction

    /*
    * Computes a single cycle of TEA. The output should replace the old value
    * of v.
    */
    function [63:0] encrypt_cycle(input[63:0] v, input[127:0] k, input[63:0] sum);
        begin
            encrypt_cycle = v;
            encrypt_cycle[63:32] += tea_round_func(encrypt_cycle[31:0] , k[127:64], sum);
            encrypt_cycle[31:0]  += tea_round_func(encrypt_cycle[63:32], k[63:0],   sum);
        end
    endfunction

    /*
    * Computes a single cycle of TEA, in reverse direction (decryption). The
    * output should replace the old value of v.
    */
    function [63:0] decrypt_cycle(input[63:0] v, input[127:0] k, input [63:0] sum);
        begin
            decrypt_cycle = v;
            decrypt_cycle[31:0]  -= tea_round_func(decrypt_cycle[63:32], k[63:0],   sum);
            decrypt_cycle[63:32] -= tea_round_func(decrypt_cycle[31:0],  k[127:64], sum);
        end
    endfunction

    always@(posedge clk) begin
        //$display("%d %x %x %b",round_counter, sum, out, mode);
        if (write) begin
            round_counter <= 0;
            out <= in;
            //sum starts from `DELTA` rather than 0 because unlike in the
            //reference C code, we increase `sum` after computing each round.
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
        end else //counted 32 rounds, mark output as ready.
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
    wire [63:0] swapped_out;
    wire [63:0] unswapped_in;

    reg[127:0] key;
    
    // set to 1 if the first half of the key is already read, and the module is
    // waiting for the second half
    reg waiting_key;
    reg enable_output;

    // For consistency, `in` should not be used directly in this module, but
    // through `unswapped_in` which is affected by the `swapbytes` parameter
    assign unswapped_in = swapbytes ? byteswap32_64(in) : in;


    // Output from enc_dec is swapped if `swapbytes` is set.
    // Output is set to a predictable value (0) after reset.
    assign swapped_out = swapbytes ? byteswap32_64(encdec_out) : encdec_out;
    assign out = enable_output ? swapped_out : 0;

    tea_enc_dec encdec(unswapped_in, key, mode, write, clk, encdec_out, out_ready);

    //convert one 32-bit integer from big endian to little endian
    function [31:0] byteswap32(input[31:0] x);
        byteswap32 = {x[7:0], x[15:8], x[23:16], x[31:24]};
    endfunction
    //convert two consecutive 32-bit integers from big endian to little endian
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
            enable_output <= 0;
        end else if (waiting_key) begin
            key[63:0] <= unswapped_in;
            waiting_key <= 0;
        end else if (write) begin
            enable_output <= 1;
        end
    end
endmodule
