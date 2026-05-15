module keccak_rho (
    input  logic [63:0] state_in [5][5],
    output logic [63:0] state_out [5][5]
);
    // Helper function for circular left shift
    function automatic logic [63:0] rotl(input logic [63:0] val, input integer shift);
        return (shift == 0) ? val : ((val << shift) | (val >> (64 - shift)));
    endfunction

    always_comb begin
        // Hardcoded Rho offsets mapped to their specific [x][y] coordinates
        state_out[0][0] = rotl(state_in[0][0], 0);
        state_out[1][0] = rotl(state_in[1][0], 1);
        state_out[2][0] = rotl(state_in[2][0], 62);
        state_out[3][0] = rotl(state_in[3][0], 28);
        state_out[4][0] = rotl(state_in[4][0], 27);
        
        state_out[0][1] = rotl(state_in[0][1], 36);
        state_out[1][1] = rotl(state_in[1][1], 44);
        state_out[2][1] = rotl(state_in[2][1], 6);
        state_out[3][1] = rotl(state_in[3][1], 55);
        state_out[4][1] = rotl(state_in[4][1], 20);
        
        state_out[0][2] = rotl(state_in[0][2], 3);
        state_out[1][2] = rotl(state_in[1][2], 10);
        state_out[2][2] = rotl(state_in[2][2], 43);
        state_out[3][2] = rotl(state_in[3][2], 25);
        state_out[4][2] = rotl(state_in[4][2], 39);
        
        state_out[0][3] = rotl(state_in[0][3], 41);
        state_out[1][3] = rotl(state_in[1][3], 45);
        state_out[2][3] = rotl(state_in[2][3], 15);
        state_out[3][3] = rotl(state_in[3][3], 21);
        state_out[4][3] = rotl(state_in[4][3], 8);
        
        state_out[0][4] = rotl(state_in[0][4], 18);
        state_out[1][4] = rotl(state_in[1][4], 2);
        state_out[2][4] = rotl(state_in[2][4], 61);
        state_out[3][4] = rotl(state_in[3][4], 56);
        state_out[4][4] = rotl(state_in[4][4], 14);
    end
endmodule