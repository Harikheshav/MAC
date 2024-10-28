import cocotb
import random
from cocotb.triggers import RisingEdge, Timer
from cocotb.clock import Clock
from cocotb_coverage.coverage import CoverPoint, coverage_db

def mac_model(a: int, b: int, c: int) -> int:
    """Python model for MAC with 32-bit signed result."""
    result = (a * b) + c

    result &= 0xFFFFFFFF

    if result >= 2**31:
        signed_result = result - 2**32
        signed_binary = format((signed_result + 2**32) % (2**32), '032b')
        return signed_result  
    else:
        unsigned_binary = format(result, '032b')
        return result  

def twos_complement_to_decimal(binary_str) -> int:
    binary_str = str(binary_str)
    #print(binary_str)
    if binary_str[0] == '1':  
       
        inverted = ''.join('1' if bit == '0' else '0' for bit in binary_str)  
        decimal_value = -((int(inverted, 2) + 1))  
        #print(decimal_value)
    else:
        decimal_value = int(binary_str, 2)  
        #print(decimal_value)
    return decimal_value


@CoverPoint("input.a_x", xf=lambda a, b, c: a, bins=list(range(0, 2**16, 512)), at_least=1)
@CoverPoint("input.b_x", xf=lambda a, b, c: b, bins=list(range(0, 2**16, 512)), at_least=1)
@CoverPoint("input.c_x", xf=lambda a, b, c: c, bins=[0, 2**16 - 1, 2**24, 2**32 - 1], at_least=1)
@CoverPoint("output.mac_op", xf=lambda a, b, c: mac_model(a, b, c), bins=[0, 1, 2**32 - 1], at_least=1)


def read_values_from_files():
    """Read values from A_decimal.txt, B_decimal.txt, C_decimal.txt, and MAC_decimal.txt."""
    with open("A_decimal.txt", "r") as f1, open("B_decimal.txt", "r") as f2, \
         open("C_decimal.txt", "r") as f3, open("MAC_decimal.txt", "r") as f4:
        for line1, line2, line3, line4 in zip(f1, f2, f3, f4):
            a = int(line1.strip())
            b = int(line2.strip())
            c = int(line3.strip())
            expected_output = int(line4.strip())
            yield a, b, c, expected_output

@cocotb.test()
async def test_mkMac(dut):
    """Testbench for mkMac with coverage."""
    for _ in range(500):
        dut.EN_a.value = 0
        dut.EN_b.value = 0
        dut.EN_c.value = 0
        dut.EN_mac_op.value = 0

        clock = Clock(dut.CLK, 10, units="ns") 
        cocotb.start_soon(clock.start(start_high=False))
        
        
        dut.RST_N.value = 0
        await RisingEdge(dut.CLK)
        dut.RST_N.value = 1
        await RisingEdge(dut.CLK)
        
        
        a = random.randint(-32768, 32767) 
        b = random.randint(-32767,  32767)  
        c = random.randint(-2**24 , 2**24 - 1)  
        dut.EN_a.value = 1
        dut.a_x.value = a
        dut.EN_b.value = 1
        dut.b_x.value = b
        dut.EN_c.value = 1
        dut.c_x.value = c
        #dut._log.info('Values are given, doing operation')
        
        #dut._log.info('Inputs applied:')
        dut._log.info(f'a = {a}, b = {b}, c = {c}') 
        await Timer(10000, units='ns')
        dut.EN_a.value = 0
        dut.EN_b.value = 0
        dut.EN_c.value = 0
        #dut._log.info(f'output {twos_complement_to_decimal(dut.mac_op.value)}') 
        dut.EN_mac_op.value = 0
               
        for _ in range(10):
            await RisingEdge(dut.CLK)
            
            
        dut.EN_a.value = 0
        dut.EN_b.value = 0
        dut.EN_c.value = 0
        dut.EN_mac_op.value = 0
            
            
        expected_val = mac_model(a, b, c)
        print(f"Testing with a_x={a}, b_x={b}, c_x={c}. "
        f"Expected op: {expected_val}, Got: {twos_complement_to_decimal(dut.mac_op.value)}")

        assert twos_complement_to_decimal(dut.mac_op.value) == (expected_val), \
        f"Test failed with a_x={a}, b_x={b}, c_x={c}. " \
        f"Expected: {expected_val}, Got: {twos_complement_to_decimal(dut.mac_op.value)}"

      

        # Report coverage results
        coverage_db.export_to_yaml(filename="coverage_mac.yml")
        #print("All tests completed successfully!")
        

    #Test files values check
    for a, b, c, expected_output in read_values_from_files():
        dut.EN_a.value = 0
        dut.EN_b.value = 0
        dut.EN_c.value = 0
        dut.EN_mac_op.value = 0
        
        clock = Clock(dut.CLK, 10, units="ns")
        cocotb.start_soon(clock.start(start_high=False))

        dut.RST_N.value = 0
        await RisingEdge(dut.CLK)
        dut.RST_N.value = 1
        await RisingEdge(dut.CLK)
        dut.EN_a.value = 1
        dut.a_x.value = a
        dut.EN_b.value = 1      
        dut.b_x.value = b
        dut.EN_c.value = 1
        dut.c_x.value = c

        dut._log.info(f"Inputs applied: a={a}, b={b}, c={c}")

        await Timer(1000, units='ns')

        output = twos_complement_to_decimal(dut.mac_op.value)
        expected_val = mac_model(a, b, c)

        dut._log.info(f"Expected (Model): {expected_val}, Got (DUT): {output}")
        assert output == expected_val, \
        f"Model mismatch: a={a}, b={b}, c={c}. Expected: {expected_val}, Got: {output}"

        dut._log.info(f"Expected (File): {expected_output}, Got (DUT): {output}")
        assert output == expected_output, \
        f"File mismatch: a={a}, b={b}, c={c}. Expected: {expected_output}, Got: {output}"

        

        dut.EN_a.value = 0
        dut.EN_b.value = 0
        dut.EN_c.value = 0

        #Wait for a few clock cycles before the next iteration
        for _ in range(10):
            await RisingEdge(dut.CLK)

        #Export coverage data to a YAML file
        coverage_db.export_to_yaml(filename="coverage_mac_testcases.yml")

#print("All tests completed successfully!")


 