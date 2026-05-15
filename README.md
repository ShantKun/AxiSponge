# AxiSponge: SHAKE256 Hardware Hash Accelerator

**AxiSponge** is a SystemVerilog project that implements the **SHAKE256** hashing algorithm in hardware. I built this to explore how complex mathematical algorithms are translated into digital logic (RTL) and how hardware can communicate with software via standard interfaces.

---

## 1. Project Goal
The goal of this project was to move the SHAKE256 hashing process from a standard computer CPU into dedicated hardware logic. By doing this in hardware, we can process data using a custom "Sponge" architecture, which is the foundation of the modern Keccak (SHA-3) family of hashes.

---

## 2. How it Works

### 2.1 The "Sponge" Design
SHAKE256 works like a sponge. It **absorbs** data into its internal state, mixes it up thoroughly using 24 rounds of permutations, and then **squeezes** out the resulting hash.
![Keccak Sponge Construction](https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/Keccak_Sponge_Construction.svg/1024px-Keccak_Sponge_Construction.svg.png)

> **<img width="802" height="386" alt="Screenshot from 2026-05-16 02-12-33" src="https://github.com/user-attachments/assets/835111da-1b49-4dc1-8316-fc66e47dd345" />**


*NIST Sponge Construction - Absorption and Squeezing phases*

### 2.2 Modular Logic
To keep the code clean and easy to test, I broke the main hashing engine into five smaller modules. Each one handles a specific mathematical "mixing" step in a single round ($S_{out} = \iota(\chi(\pi(\rho(\theta(S_{in})))))$):

* **Theta ($\theta$):** Spreads bit changes across columns for high diffusion.
* **Rho ($\rho$) & Pi ($\pi$):** Rotates and moves bits around the 1600-bit state array.
* **Chi ($\chi$):** The primary non-linear step that provides cryptographic security.
* **Iota ($\iota$):** Adds a unique round constant to break symmetry.

---

## 3. Key Features

### 3.1 AXI4-Stream Interface
The core uses the **AXI4-Stream** protocol. This is an industry-standard "handshake" method (using `valid` and `ready` signals) that ensures data moves correctly between software and hardware without data loss.

### 3.2 Automatic Hardware Padding
Hashing algorithms require input to be a specific length. AxiSponge handles **padding** entirely in hardware. It detects the end of a message (`tlast`) and automatically adds the required extra bits (0x1f and 0x80) so the software doesn't have to do any pre-processing.

---

## 4. Verification & Output
To verify the design, I created a **Co-Simulation** environment using **Verilator**. This allows a Python script to drive the SystemVerilog hardware model and compare the results with real-world standards.

### 4.1 Python Bridge Snippet
The following Python script acts as the "driver" for the hardware core:

> **<img width="1423" height="844" alt="Screenshot from 2026-05-16 02-02-36" src="https://github.com/user-attachments/assets/c3bc2740-bd96-4b9b-9375-7cfdf3822295" />**

### 4.2 Hardware vs. Website Result
I verified the hardware output against a standard SHAKE256 online tool to ensure 100% mathematical accuracy.

> **<img width="1660" height="501" alt="Screenshot from 2026-05-16 02-04-14" src="https://github.com/user-attachments/assets/16a46c62-55c3-4d86-9372-f8ff6bddcda6" />**

---

## 5. Future Goal: FPGA Deployment
This project is currently verified through high-speed simulation. My next objective is to deploy and test this on physical hardware:
* **Target Board:** Xilinx Basys3 (Artix-7 FPGA)
* **Goal:** Measure real-world resource usage (LUTs/Flip-Flops) and maximize clock frequency.

---

## 6. How to Run
1. **Compile the Hardware:**
   ```bash
   verilator -Wall --cc *.sv --exe main.cpp -O3 --top-module shake256_top
   make -j$(nproc) -C obj_dir -f Vshake256_top.mk Vshake256_top
