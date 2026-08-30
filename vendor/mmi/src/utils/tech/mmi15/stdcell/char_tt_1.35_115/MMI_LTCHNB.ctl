comment Latch with Negative Enable

function q = IQ

# Special synopsys header for a flip-flop
header
        latch (IQ,IQN){
                enable : "!clk";
                data_in : "d";
        }
end

# Special verilog code, too complicated to auto-generate
verilog
	reg	q;

	always @(clk or d)
		if (clk == 0)
		q <= #1 d;
end

step {clk 0} {d 1} 
measure {q v} with {d 0} {clk v}
measure {q ^} with {d 1} {clk v}
measure {q v} with {d v} {clk 0}
measure {q ^} with {d ^} {clk 0}

# measure the input capacitance
cap clk with {d 1}
cap d with {clk 0}

# measure setup/hold times
setup {d ^} to {q ^} with {clk ^}
setup {d v} to {q v} with {clk ^}
hold  {d ^} to {q v} with {clk ^}
hold  {d v} to {q ^} with {clk ^}

