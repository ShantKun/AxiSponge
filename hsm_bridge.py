import subprocess
import re
import sys

def get_hsm_hash(input_string):
    """
    Passes a string to the simulated hardware and retrieves the result.
    """
    executable = "./obj_dir/Vshake256_top"
    
    try:
        # We wrap the input in literal quotes to ensure the hardware 
        # receives the exact string, including spaces.
        result = subprocess.run(
            [executable, input_string],
            capture_output=True,
            text=True,
            check=True
        )
        
        # Look for the hex string starting with 0x
        match = re.search(r"0x([a-fA-F0-9]+)", result.stdout)
        if match:
            return match.group(1)
        else:
            return "Error: Hardware did not return a valid hex hash."
            
    except FileNotFoundError:
        return "Error: obj_dir/Vshake256_top not found. Run 'make' first!"
    except subprocess.CalledProcessError as e:
        return f"Simulation Error: {e.stderr}"

def main():
    
    print(" SHAKE256 -")
    
    
    while True:
        try:
            val = input("\nEnter string to hash (or 'exit' to stop): ")
            if val.lower() in ['exit', 'quit']:
                break
                
            print(f"Feeding hardware...")
            hw_hash = get_hsm_hash(val)
            
            print(f"\n[INPUT]: {val}")
            print(f"[HASH]:  {hw_hash}")
            print("-" * 50)
            
        except KeyboardInterrupt:
            break

if __name__ == "__main__":
    main()