comment Flip Flop with asynchronous set

set preset setb

function q = IQ

# Special synopsys header for a flip-flop
header
	ff (IQ,IQN){
		clocked_on : "clk";
                next_state : "d";
		preset : "!setb";
	}
end
# Special verilog code, too complicated to auto-generate
verilog
	reg	q;

	always @(posedge clk or negedge setb)
		if (setb == 0)
			q <= #1 1'b1;
		else
			q <= #1 d;
end

step {clk ^v} {d 0} {setb 1}
measure {q ^} with {d 1} {clk ^v} 
measure {q v} with {d 0} {clk ^v} 
measure {q ^} with {setb v}


# measure the input capacitance of wen when clk is low
cap clk with {d 0} {setb 1}
cap d with {clk 0}
cap setb with {clk 0}

# measure setup/hold times
setup {d ^} to {q ^} with {clk ^v} {setb 1}
setup {d v} to {q v} with {clk ^v} {setb 1}
hold {d ^} to {q v} with {clk ^v} {setb 1}
hold {d v} to {q ^} with {clk ^v} {setb 1}

