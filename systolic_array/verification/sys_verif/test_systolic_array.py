import cocotb
import numpy as np
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotb.triggers import RisingEdge, FallingEdge

def systolic_array_4x4(A, B):
        
    A_ext = np.zeros((4, 4))
    B_ext = np.zeros((4, 4))
    A_ext[:3, :3] = A
    B_ext[:3, :3] = B

    # Initialize the systolic array
    C_ext = np.zeros((4, 4))
    
    # Simulate the systolic array computation
    for t in range(6):  # Number of steps to complete computation
        for i in range(4):
            for j in range(4):
                if i - t >= 0 and j - t >= 0:
                    C_ext[i, j] += A_ext[i - t, t] * B_ext[t, j - t]

    # Extract the 3x3 result from the extended matrix
    C = C_ext[:3, :3]
    return C

# Example matrices
A = np.array([[0, 1, 2],
              [3, 4, 5],
              [6, 7, 8]])

B = np.array([[0, 1, 2],
              [3, 4, 5],
              [6, 7, 8]])

# Perform matrix multiplication
C = systolic_array_4x4(A, B)


@cocotb.test()
async def test_mkSystolicArray(dut):
    # Generate a clock on CLK
    clock = Clock(dut.CLK, 10, units="ns")  # 10ns period clock
    cocotb.start_soon(clock.start())  # Start the clock
    cocotb.log.info("Clock started")

    elements = [0,1,2,3,4,5,6,7,8]
    cocotb.log.info(f"Input elements: {elements}")

    # Reset the DUT
    dut.RST_N.value = 0  # Active-low reset
    cocotb.log.info("Asserting reset")
    await RisingEdge(dut.CLK)
    dut.RST_N.value = 1  # De-assert reset
    cocotb.log.info("De-asserting reset")
    await RisingEdge(dut.CLK)
    
    dut.EN_a.value = 0
    dut.EN_b.value = 0
    cocotb.log.info("Initial enable signals set to 0")
    
    dut.EN_a.value = 1
    dut.EN_b.value = 1
    cocotb.log.info("Enable signals set to 1")
    
    # Drive inputs
    for i in range(9):
        dut.a_x.value = elements[i]  # Assign the value
        cocotb.log.info(f"Current value of a_x: {dut.a_x.value}")  # Print the current value of a_x
        cocotb.log.info(f"Driven a_x with element[{i}]: {hex(elements[i])}")
        await RisingEdge(dut.CLK)  # Wait for the next clock edge


    for i in range(9):
        dut.b_x.value = elements[i]
        cocotb.log.info(f"Current value of b_x: {dut.b_x.value}")  # Print the current value of a_x
        cocotb.log.info(f"Driven b_x with element[{i}]: {hex(elements[i])}")
        await RisingEdge(dut.CLK)

    # Wait for ready signals
    for _ in range(5):
        await RisingEdge(dut.CLK)
    cocotb.log.info("Waited for initial clock cycles")

    await Timer(22000, units='ns')
    # Check and print the read signal for index 8
   
    
    for i in range(9):
        read_signal = getattr(dut, f"RDY_op_{i}__read")  # Dynamically get the ready signal
        cocotb.log.info(f"Checking read_signal for index {i}: {read_signal.value}")
        
       
        output_signal = getattr(dut, f"op_{i}__read")    # Dynamically get the output signal
        cocotb.log.info(f"Checking output_signal for index {i}: {output_signal.value}")

    
    # Add assertions (if needed) for validation
    # Replace `expected_value` with the actual expected value for the output
    # assert output_value == expected_value, "Test failed: Unexpected output value"
