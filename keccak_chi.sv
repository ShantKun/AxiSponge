module keccak_chi (
    input  logic [63:0] state_in [5][5],
    output logic [63:0] state_out [5][5]
);
    always_comb begin
        for (int x = 0; x < 5; x++) begin
            for (int y = 0; y < 5; y++) begin
                // Chi formula: out = in ^ (~in_next_1 & in_next_2)
                state_out[x][y] = state_in[x][y] ^ (~state_in[(x+1)%5][y] & state_in[(x+2)%5][y]);
            end
        end
    end
endmodule