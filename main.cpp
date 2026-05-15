#include <iostream>
#include <iomanip>
#include <string>
#include <vector>
#include "Vshake256_top.h"
#include "verilated.h"

void tick(Vshake256_top* top) {
    top->clk = 1; top->eval();
    top->clk = 0; top->eval();
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    
    std::string input_str = (argc > 1) ? argv[1] : "";
    std::cout << "Hashing string: '" << input_str << "'" << std::endl;

    Vshake256_top* top = new Vshake256_top;
    top->clk = 0; top->rst_n = 0; top->s_tvalid = 0; top->s_tlast = 0;

    tick(top);
    top->rst_n = 1;
    tick(top);

    size_t length = input_str.length();
    size_t num_words = (length / 8) + 1;
    
    for (size_t i = 0; i < num_words; ++i) {
        uint64_t word = 0;
        uint8_t keep = 0;
        
        for (size_t j = 0; j < 8; ++j) {
            size_t char_idx = (i * 8) + j;
            if (char_idx < length) {
                word |= ((uint64_t)(uint8_t)input_str[char_idx]) << (j * 8);
                keep |= (1 << j);
            }
        }

        while (!top->s_tready) { tick(top); }

        top->s_tdata = word;
        top->s_tkeep = keep;
        top->s_tlast = (i == num_words - 1) ? 1 : 0;
        top->s_tvalid = 1;
        tick(top);
    }
    
    top->s_tvalid = 0;
    top->s_tlast = 0;

    std::cout << "Hardware calculating padding and permutations..." << std::endl;
    int timeout = 500;
    
    // FIX 1: Declare and track the cycles variable
    int cycles = 0; 
    while (!top->hash_valid && timeout > 0) {
        tick(top);
        timeout--;
        cycles++; // Increment the counter
    }

   if (top->hash_valid) {
        std::cout << "SUCCESS! Hardware Permutation Complete in " << cycles << " cycles." << std::endl;
        std::cout << "SHAKE256 Hash Output:" << std::endl << "0x";
        
        // FIX 2: Safely extract the pointer from the VlWide array type
        uint8_t* hash_bytes = (uint8_t*)&(top->hash_out[0]);
        
        // Print them from byte 0 up to byte 31 (FIPS 202 Little-Endian byte stream)
        for (int i = 0; i < 32; i++) {
            std::cout << std::hex << std::setw(2) << std::setfill('0') << (int)hash_bytes[i];
        }
        std::cout << std::endl;
    } else {
        std::cout << "ERROR: Core timed out." << std::endl;
    }
    delete top;
    return 0;
}