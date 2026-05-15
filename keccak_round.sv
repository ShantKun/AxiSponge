module keccak_round (
    input  logic [63:0] state_in [5][5],
    input  logic [63:0] round_constant,
    output logic [63:0] state_out [5][5]
);
    // Intermediate wire arrays connecting the outputs to the inputs
    logic [63:0] theta_to_rho [5][5];
    logic [63:0] rho_to_pi    [5][5];
    logic [63:0] pi_to_chi    [5][5];
    logic [63:0] chi_to_iota  [5][5];

    keccak_theta u_theta (
        .state_in  (state_in),
        .state_out (theta_to_rho)
    );

    keccak_rho u_rho (
        .state_in  (theta_to_rho),
        .state_out (rho_to_pi)
    );

    keccak_pi u_pi (
        .state_in  (rho_to_pi),
        .state_out (pi_to_chi)
    );

    keccak_chi u_chi (
        .state_in  (pi_to_chi),
        .state_out (chi_to_iota)
    );

    keccak_iota u_iota (
        .state_in       (chi_to_iota),
        .round_constant (round_constant),
        .state_out      (state_out)
    );

endmodule