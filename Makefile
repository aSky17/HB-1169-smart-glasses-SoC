VERILATOR_FLAGS = -Wall --trace --timing --binary --top-module tb_dummy_accel -Mdir obj_dir

.PHONY: sim_dummy clean

sim_dummy:
	verilator $(VERILATOR_FLAGS) \
	  hw/rtl/compute_fabric/dummy_accel.sv \
	  hw/sim/sv_tbs/tb_dummy_accel.sv \
	  -o sim_dummy
	./obj_dir/sim_dummy

clean:
	rm -rf obj_dir *.vcd
