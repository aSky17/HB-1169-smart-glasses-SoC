import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer


@cocotb.test()
async def test_dummy_addition(dut):
    # Start a 10 ns period clock on dut.clk
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    # Apply reset (active-low)
    dut.rst_n.value = 0
    dut.a.value = 0
    dut.b.value = 0

    # Wait a couple of clock cycles in reset
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    # Release reset
    dut.rst_n.value = 1

    # Apply test stimulus
    dut.a.value = 10
    dut.b.value = 5

    # Wait for the registered output to update (one or two cycles)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    # Read and check result
    sum_val = int(dut.sum.value)
    cocotb.log.info(
        f"a={int(dut.a.value)} b={int(dut.b.value)} sum={sum_val}"
    )

    assert sum_val == 15, f"Expected 15, got {sum_val}"
