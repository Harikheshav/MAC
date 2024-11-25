
# Systolic Array using MAC 

## Assignment Completion Status

Assignment 1:

1. int32 :
a. pipelined design: code - not-completed, verification - not-completed
b. unpipeined design : code - completed, verification - completed

2. bfloat16:
a. pipelined design: code - not-completed, verification - not-completed
b. unpipeined design : code - partially completed, verification - not-completed

Assignment 2:

int32: code - completed, verification - not-completed
bfloat16: code - not-completed, verification - not-completed

## Project Structure

**Phase 1 MAC Design**
* To design a Multiply-Accumulate (MAC) unit supporting two configurations:

  S1: Handles int8 inputs for A and B, and int32 for C and output.
  S2: Supports bf16 inputs for A and B, and fp32 for C and output.

**Phase 2 Systolic Array Design**

* Based on the MAC unit design a 4 x 4 systolic array to do 3 x 3 matrix multiplication 

  
## Design Decisions & Verification Methodologies

**Input Types:**

* S1: A and B as int8 (Signed 8-bit integer) and C as int32 (Signed 32-bit integer). The output MAC is also int32.
* S2: A and B as bf16 (bfloat16 format), C as fp32 (32-bit floating point). The output MAC is fp32

**Multiplier Design:**
* For both int8 and bf16 operations, a **shift-and-add multiplier** is used due to its simplicity 
* For bf16 multiplication, the exponent and mantissa are handled separately, leveraging the reduced precision of bf16 to simplify the computation

**Adder Design**
* A ripple carry adder (RCA) is used for addition due to its straightforward implementation

## How to Run

### To run and verify MAC design 
 **To run Bluespec Testbench**

1. Enter into the project directory:
  
2. Execute the following commands to clean, compile and generate verilog for the design:
   ```
   make all_bsim
   ```
 **To run Verification**
1. Enter into the project directory

2. Execute the following commands to clean, compile and generate verilog for the design:
   ```
   make all_vsim
   ```
3. Change directory to verification

 **Activate pyenv**
   ```
   pyenv activate py38
   ```
4. Run the command
   ```
   make simulate
   ```

### To run and verify Systolic Array design 
 **To run Bluespec Testbench**

1. Enter into the project directory and change directory to systolic array:
  
2. Execute the following commands to clean, compile and generate verilog for the design:
   ```
   make all_bsim
   ```
 **To run Verification**
1. Enter into the project directory and change directory to systolic array:

2. Execute the following commands to clean, compile and generate verilog for the design:
   ```
   make all_vsim
   ```
3. Change directory to verification

 **Activate pyenv**
   ```
   pyenv activate py38
   ```
4. Run the command
   ```
   make simulate
   ```
