comment Latch with Positive Enable

function q = IQ

# Special synopsys header for a flip-flop
header
        latch (IQ,IQN){
                enable : "clk";
                data_in : "d";
        }
end

# Special verilog code, too complicated to auto-generate
verilog
	reg	q;

	always @(clk or d)
		if (clk == 1)
		q <= #1 d;
end

step {clk 1} {d 1} 
measure {q v} with {d 0} {clk ^}
measure {q ^} with {d 1} {clk ^}
measure {q v} with {d v} {clk 1}
measure {q ^} with {d ^} {clk 1}

# measure the input capacitance
cap clk with {d 1}
cap d with {clk 1}

# measure setup/hold times
setup {d ^} to {q ^} with {clk v}
setup {d v} to {q v} with {clk v}
hold  {d ^} to {q v} with {clk v}
hold  {d v} to {q ^} with {clk v}

