comment Latch with positive enable and asynchronous clear

set clear clrb

function q = IQ

# Special synopsys header for a flip-flop
header
        latch (IQ,IQN){
                enable : "clk";
                data_in : "d";
		clear : "!clrb";
        }
end

# Special verilog code, too complicated to auto-generate
verilog
	reg	q;

	always @(clk or d or clrb)
		if (clrb == 0)
			q <= #1 1'b0;
		else if (clk == 1)
			q <= #1 d;
end

step {clk 1} {d 1} {clrb 1}
measure {q v} with {d 0} {clk ^} {clrb 1}
measure {q ^} with {d 1} {clk ^} {clrb 1}
measure {q v} with {d v} {clk 1} {clrb 1}
measure {q ^} with {d ^} {clk 1} {clrb 1}
measure {q v} with {d 1} {clk 1} {clrb v}
step {clrb 1}

# measure the input capacitance
cap clk with {d 1} {clrb 1}
cap d with {clk 1}
cap clrb with {clk 0}

# measure setup/hold times
setup {d ^} to {q ^} with {clrb 1} {clk v}
setup {d v} to {q v} with {clrb 1} {clk v}
hold  {d ^} to {q v} with {clrb 1} {clk v}
hold  {d v} to {q ^} with {clrb 1} {clk v}

