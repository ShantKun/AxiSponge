module shake256_top (
    input  logic clk,
    input  logic rst_n,

    // AXI4-Stream Input
    input  logic [63:0] s_tdata,
    input  logic [7:0]  s_tkeep,  
    input  logic        s_tlast,  
    input  logic        s_tvalid,
    output logic        s_tready, 

    // Output Interface
    output logic [255:0] hash_out,
    output logic         hash_valid
);

    logic [63:0] RC [24];
    assign RC[0] = 64'h0000000000000001; assign RC[1] = 64'h0000000000008082;
    assign RC[2] = 64'h800000000000808A; assign RC[3] = 64'h8000000080008000;
    assign RC[4] = 64'h000000000000808B; assign RC[5] = 64'h0000000080000001;
    assign RC[6] = 64'h8000000080008081; assign RC[7] = 64'h8000000000008009;
    assign RC[8] = 64'h000000000000008A; assign RC[9] = 64'h0000000000000088;
    assign RC[10]= 64'h0000000080008009; assign RC[11]= 64'h000000008000000A;
    assign RC[12]= 64'h000000008000808B; assign RC[13]= 64'h800000000000008B;
    assign RC[14]= 64'h8000000000008089; assign RC[15]= 64'h8000000000008003;
    assign RC[16]= 64'h8000000000008002; assign RC[17]= 64'h8000000000000080;
    assign RC[18]= 64'h000000000000800A; assign RC[19]= 64'h800000008000000A;
    assign RC[20]= 64'h8000000080008081; assign RC[21]= 64'h8000000000008080;
    assign RC[22]= 64'h0000000080000001; assign RC[23]= 64'h8000000080008008;

    logic [63:0] state_reg [5][5];
    logic [63:0] next_state [5][5];
    logic [4:0]  round_idx;
    logic [4:0]  word_cnt; 
    logic        is_last_word; // NEW: Hardware memory for the tlast flag
    
    typedef enum logic [2:0] {IDLE, ABSORB, PAD_FINISH, PERMUTE, SQUEEZE} state_t;
    state_t fsm_state;

    keccak_round u_round (
        .state_in(state_reg),
        .round_constant(RC[round_idx]),
        .state_out(next_state)
    );

    logic [63:0] padded_word;
    always_comb begin
        padded_word = 64'h0;
        if (s_tkeep == 8'hFF) padded_word = s_tdata; 
        else if (s_tkeep == 8'h7F) padded_word = {8'h1F, s_tdata[55:0]};
        else if (s_tkeep == 8'h3F) padded_word = {16'h001F, s_tdata[47:0]};
        else if (s_tkeep == 8'h1F) padded_word = {24'h00001F, s_tdata[39:0]};
        else if (s_tkeep == 8'h0F) padded_word = {32'h0000001F, s_tdata[31:0]};
        else if (s_tkeep == 8'h07) padded_word = {40'h000000001F, s_tdata[23:0]};
        else if (s_tkeep == 8'h03) padded_word = {48'h00000000001F, s_tdata[15:0]};
        else if (s_tkeep == 8'h01) padded_word = {56'h0000000000001F, s_tdata[7:0]};
        else if (s_tkeep == 8'h00) padded_word = {56'h0, 8'h1F}; 
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fsm_state <= IDLE;
            round_idx <= '0;
            word_cnt  <= '0;
            hash_valid <= 1'b0;
            s_tready <= 1'b0;
            is_last_word <= 1'b0;
            for (int x=0; x<5; x++) for (int y=0; y<5; y++) state_reg[x][y] <= '0;
        end else begin
            case (fsm_state)
                IDLE: begin
                    hash_valid <= 1'b0;
                    s_tready <= 1'b1;
                    word_cnt <= '0;
                    is_last_word <= 1'b0;
                    if (s_tvalid && s_tready) begin
                        // FIX: Instantly capture Word 0 into the origin lane, clear the rest
                        for (int x=0; x<5; x++) begin
                            for (int y=0; y<5; y++) begin
                                if (x==0 && y==0) state_reg[x][y] <= s_tlast ? padded_word : s_tdata;
                                else state_reg[x][y] <= '0;
                            end
                        end
                        
                        if (s_tlast) begin
                            s_tready <= 1'b0;
                            is_last_word <= 1'b1; // Remember the message is over!
                            if (s_tkeep == 8'hFF) begin
                                word_cnt <= 1; 
                                fsm_state <= PAD_FINISH;
                            end else begin
                                fsm_state <= PAD_FINISH;
                            end
                        end else begin
                            word_cnt <= 1; 
                            fsm_state <= ABSORB;
                        end
                    end
                end

                ABSORB: begin
                    if (s_tvalid && s_tready) begin
                        state_reg[word_cnt%5][word_cnt/5] <= state_reg[word_cnt%5][word_cnt/5] ^ (s_tlast ? padded_word : s_tdata);
                        
                        if (s_tlast) begin
                            s_tready <= 1'b0; 
                            is_last_word <= 1'b1; // Remember the message is over!
                            if (s_tkeep == 8'hFF) begin
                                word_cnt <= word_cnt + 1;
                                fsm_state <= PAD_FINISH; 
                            end else begin
                                if (word_cnt == 16) begin
                                    state_reg[1][3] <= state_reg[1][3] ^ (padded_word ^ 64'h80000000_00000000);
                                    fsm_state <= PERMUTE;
                                end else begin
                                    fsm_state <= PAD_FINISH;
                                end
                            end
                        end else begin
                            if (word_cnt == 16) begin
                                s_tready <= 1'b0; 
                                fsm_state <= PERMUTE;
                            end else begin
                                word_cnt <= word_cnt + 1;
                            end
                        end
                    end
                end

                PAD_FINISH: begin
                    if (s_tkeep == 8'hFF && word_cnt <= 16) begin
                         state_reg[word_cnt%5][word_cnt/5] <= state_reg[word_cnt%5][word_cnt/5] ^ 64'h00000000_0000001F;
                    end
                    state_reg[1][3] <= state_reg[1][3] ^ 64'h80000000_00000000;
                    fsm_state <= PERMUTE;
                end

                PERMUTE: begin
                    s_tready <= 1'b0;
                    if (round_idx == 23) begin
                        round_idx <= '0;
                        if (is_last_word) begin 
                             fsm_state <= SQUEEZE; // We remembered! Proceed to squeeze.
                        end else begin 
                            fsm_state <= ABSORB;
                            word_cnt <= '0;
                            s_tready <= 1'b1;
                        end
                        state_reg <= next_state;
                    end else begin
                        state_reg <= next_state;
                        round_idx <= round_idx + 1;
                    end
                end

                SQUEEZE: begin
                    hash_out <= {state_reg[3][0], state_reg[2][0], state_reg[1][0], state_reg[0][0]};
                    hash_valid <= 1'b1;
                    fsm_state <= IDLE;
                end
                
                default: fsm_state <= IDLE; // Fixes the Verilator CASEINCOMPLETE warning
            endcase
        end
    end
endmodule