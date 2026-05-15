module keccak_pi (
    input  logic [63:0] state_in [5][5],
    output logic [63:0] state_out [5][5]
);
    always_comb begin
        for (int x = 0; x < 5; x++) begin
            for (int y = 0; y < 5; y++) begin
                // The mathematical Pi permutation: out[Y][(2X + 3Y) mod 5] = in[X][Y]
                state_out[y][(2*x + 3*y) % 5] = state_in[x][y];
            end
        end
    end
endmodule