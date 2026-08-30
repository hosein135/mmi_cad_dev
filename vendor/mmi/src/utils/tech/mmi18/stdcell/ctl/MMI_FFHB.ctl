comment Flip Flop with input hold mux
# note: doesn't measure setup or hold of hold input
function q = IQ

# Special synopsys header for a flip-flop
header
	ff (IQ,IQN){
		clocked_on : "clk";
                next_state : "((!hold&d)|(hold&IQ))";
	}
end
# Special verilog code, too complicated to auto-generate
verilog
	reg	q;

	always @(posedge clk)
		if (hold == 1)
			q <= #1 q;
		else
			q <= #1 d;
end

step {clk ^v} {d 1} {hold 0}
measure {q v} with {d 0} {clk ^v} {hold 0}
measure {q ^} with {d 1} {clk ^v} {hold 0}


# measure the input capacitance when clk is low
cap clk with {d 0} {hold 0}
cap d with {clk 0}
cap hold with {clk 0} 

# measure setup/hold times
setup {d ^} to {q ^} with {clk ^v} {hold 0}
setup {d v} to {q v} with {clk ^v} {hold 0}
hold {d ^} to {q v} with {clk ^v} {hold 0}
hold {d v} to {q ^} with {clk ^v} {hold 0}

