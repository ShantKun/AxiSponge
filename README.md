# AxiSponge: High-Performance SHAKE256 Hardware Accelerator

**AxiSponge** is a research-oriented, modular SystemVerilog implementation of the **FIPS-202 (Keccak) SHAKE256** Extendable Output Function (XOF). Designed for high-throughput cryptographic applications and Hardware Security Modules (HSMs), it features a native **AXI4-Stream interface**, autonomous dynamic padding, and a sophisticated Python-based co-simulation environment.

---

## 1. Research Motivation
In the landscape of Post-Quantum Cryptography (PQC), the Keccak family serves as a fundamental primitive. **AxiSponge** explores the trade-offs between modular RTL design and hardware resource efficiency. The objective was to develop an indigenous "drop-in" IP core that offloads computationally expensive permutation and padding tasks from general-purpose CPUs to dedicated silicon logic.

---

## 2. Architecture & Design

### 2.1 The Sponge Construction
AxiSponge implements the sponge construction with a rate $r = 1088$ and capacity $c = 512$. The design manages the internal 1600-bit state through iterative absorption and permutation phases.

![Keccak Sponge Construction](https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/Keccak_Sponge_Construction.svg/1024px-Keccak_Sponge_Construction.svg.png)

### 2.2 The Permutation Engine
The core consists of 24 rounds of the Keccak-p[1600] function. Each round $R$ is implemented as a combinational path through five distinct stages:

$$S_{out} = \iota(\chi(\pi(\rho(\theta(S_{in})))))$$

* **$\theta$ (Theta):** Parity calculation and diffusion across columns.
* **$\rho$ (Rho):** Inter-lane bit rotations for dispersion across the Z-axis.
* **$\pi$ (Pi):** Lane transposition to scramble the $5 \times 5$ state array.
* **$\chi$ (Chi):** Non-linear mapping using AND/NOT logic (the primary security layer).
* **$\iota$ (Iota):** Symmetry breaking via round-constant injection.

---

## 3. Technical Implementation

### 3.1 AXI4-Stream Interface
To ensure compatibility with modern SoC interconnects (like Xilinx AXI SmartConnect), the core implements a robust Slave AXI4-Stream interface.
* **`s_tvalid` / `s_tready`:** Hardware backpressure and flow control.
* **`s_tkeep`:** Byte-level granularity allowing for variable-length message inputs.
* **`s_tlast`:** End-of-message signal triggering the autonomous hardware padding logic.

### 3.2 Dynamic Hardware Padding
AxiSponge natively handles the **pad10*1** rule. By analyzing `s_tkeep` during the `tlast` cycle, the core automatically injects the `0x1f` suffix (for SHAKE) and the `0x80` most-significant bit in a single clock cycle, eliminating the need for software-side preprocessing.

---

## 4. Verification & Co-Simulation
This project utilizes a modern **Hardware-in-the-Loop** verification strategy using **Verilator**.

### 4.1 Python-C++ Co-Simulation Bridge
We employ a Python wrapper that communicates with the compiled C++ simulation model. This allows for rapid prototyping and validation against high-level libraries.

```python
import subprocess
import re

def get_hsm_hash(input_string):
    """
    Interfaces with the compiled Verilator hardware model.
    Pushes data through the AXI-Stream pipeline and retrieves 512-bit hash.
    """
    executable = "./obj_dir/Vshake256_top"
    result = subprocess.run([executable, input_string], capture_output=True, text=True)
    
    # Extract the 512-bit hex result from hardware stdout
    match = re.search(r"0x([a-fA-F0-9]+)", result.stdout)
    return match.group(1) if match else "Error"
