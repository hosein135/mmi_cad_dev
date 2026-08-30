comment Flip Flop with input hold mux

function q = IQ

# Special synopsys header for a flip-flop
header
	ff (IQ,IQN){
		clocked_on : "clk";
                next_state : "((!sel&d0)|(sel&d1))";
	}
end
# Special verilog code, too complicated to auto-generate
verilog
	reg	q;

	always @(posedge clk)
		if (sel == 1)
			q <= #1 d1;
		else
			q <= #1 d0;
end

step {clk ^v} {d0 1} {d1 1} {sel 0}
measure {q v} with {d0 0} {d1 1} {clk ^v} {sel 0}
measure {q ^} with {d0 1} {d1 1} {clk ^v} {sel 0}
measure {q v} with {d1 0} {d0 1} {clk ^v} {sel 1}
measure {q ^} with {d1 1} {d0 1} {clk ^v} {sel 1}

# measure the input capacitance when clk is low
cap clk with {d0 0} {d1 1} {sel 1}
cap d0 with {clk 0} {d1 1}
cap d1 with {clk 0} {d0 1}
cap sel with {d0 0} {d1 1}

# measure setup/hold times
setup {d0 ^} to {q ^} with {clk ^v} {d1 0} {sel 0}
setup {d0 v} to {q v} with {clk ^v} {d1 1} {sel 0}
setup {d1 ^} to {q ^} with {clk ^v} {d0 0} {sel 1}
setup {d1 v} to {q v} with {clk ^v} {d0 1} {sel 1}
setup {sel v} to {q ^} with {clk ^v} {d0 1} {d1 0}
setup {sel ^} to {q v} with {clk ^v} {d0 1} {d1 0}
hold {d0 ^} to {q v} with {clk ^v} {sel 0} {d1 0}
hold {d0 v} to {q ^} with {clk ^v} {sel 0} {d1 1}
hold {d1 ^} to {q v} with {clk ^v} {sel 1} {d0 0}
hold {d1 v} to {q ^} with {clk ^v} {sel 1} {d0 1}
hold {sel ^} to {q v} with {clk ^v} {d0 0} {d1 1}
hold {sel v} to {q ^} with {clk ^v} {d0 0} {d1 1}

