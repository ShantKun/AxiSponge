module keccak_theta (
    input  logic [63:0] state_in [5][5],
    output logic [63:0] state_out [5][5]
);
    logic [63:0] C[5];
    logic [63:0] D[5];

    always_comb begin
        // Step 1: Calculate the parity of each column (X)
        for (int x = 0; x < 5; x++) begin
            C[x] = state_in[x][0] ^ state_in[x][1] ^ state_in[x][2] ^ state_in[x][3] ^ state_in[x][4];
        end
        
        // Step 2: Calculate the D value (XOR of adjacent columns + 1 bit left rotate)
        for (int x = 0; x < 5; x++) begin
            // A 1-bit circular left shift is done via concatenation: {val[62:0], val[63]}
            D[x] = C[(x+4)%5] ^ {C[(x+1)%5][62:0], C[(x+1)%5][63]};
        end
        
        // Step 3: Apply D to all lanes in the state array
        for (int x = 0; x < 5; x++) begin
            for (int y = 0; y < 5; y++) begin
                state_out[x][y] = state_in[x][y] ^ D[x];
            end
        end
    end
endmodule 
