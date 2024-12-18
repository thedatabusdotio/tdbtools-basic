ys_eqv_check:
	yosys ./and_eqv_check.ys

verilator-test:
	verilator -cc and_gate.v
	cp and_gate_testbench.cpp obj_dir
	verilator -Wall --trace -cc and_gate.v --exe and_gate_testbench.cpp
	make -C obj_dir -f Vand_gate.mk Vand_gate
	./obj_dir/Vand_gate
	gtkwave ./and_gate_testbench.vcd 

iverilog-test:
	iverilog and_gate_testbench.v and_gate.v -o and_gate_testbench.vvp
	./and_gate_testbench.vvp
	gtkwave ./and_gate_testbench.vcd
clean:
	rm -f *.pid *.dot \
	rm -f *.vvp *.vcd \
	rm -rf *.vcd obj_dir
