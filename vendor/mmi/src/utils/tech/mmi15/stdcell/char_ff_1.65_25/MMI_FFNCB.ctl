comment Neg Edge Flip Flop with asynchronous clear

set clear clrb

function q = IQ

# Special synopsys header for a flip-flop
header
	ff (IQ,IQN){
		clocked_on : "!clk";
                next_state : "d";
		clear : "!clrb";
	}
end
# Special verilog code, too complicated to auto-generate
verilog
	reg	q;

	always @(negedge clk or negedge clrb)
		if (clrb == 0)
			q <= #1 1'b0;
		else
			q <= #1 d;
end

step {clk ^v} {d 1} {clrb 1} 
measure {q v} with {d 0} {clk v}
measure {q ^} with {d 1} {clk v}
measure {q v} with {clrb v}

# measure the input capacitance when clk is high
cap clk with {d 0} {clrb 1} 
cap d with {clk 1} 
cap clrb with {clk 1}

# measure setup/hold times
setup {d ^} to {q ^} with {clk v} {clrb 1}
setup {d v} to {q v} with {clk v} {clrb 1}
hold {d ^} to {q v} with {clk v} {clrb 1}
hold {d v} to {q ^} with {clk v} {clrb 1}

