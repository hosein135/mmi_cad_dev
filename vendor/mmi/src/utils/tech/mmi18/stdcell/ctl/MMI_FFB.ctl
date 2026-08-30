comment Flip Flop with no scan, set or clr

function q = IQ

# Special synopsys header for a flip-flop
header
	ff (IQ,IQN){
		clocked_on : "clk";
		next_state : "d";
	}
end
# Special verilog code, too complicated to auto-generate
verilog
	reg	q;

	always @(posedge clk )
		q <= #1 d;
end

step {clk ^v} {d 0} 
measure {q ^} with {d 1} {clk ^v} 
measure {q v} with {d 0} {clk ^v} 

# measure the input capacitance of wen when clk is low
cap clk with {d 0} 
cap d with {clk 0}

# measure setup/hold times
setup {d ^} to {q ^} with {clk ^v}
setup {d v} to {q v} with {clk ^v}
hold  {d ^} to {q v} with {clk ^v}
hold  {d v} to {q ^} with {clk ^v}


