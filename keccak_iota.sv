module keccak_iota (
    input  logic [63:0] state_in [5][5],
    input  logic [63:0] round_constant,
    output logic [63:0] state_out [5][5]
);
    always_comb begin
        // Pass the entire state through
        state_out = state_in;
        // Inject the round constant into the [0][0] lane
        state_out[0][0] = state_in[0][0] ^ round_constant;
    end
endmodule