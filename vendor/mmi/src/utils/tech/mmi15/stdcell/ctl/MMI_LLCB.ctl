comment Latch with negative enable and asynchronous clear

set clear clrb

function q = IQ

# Special synopsys header for a flip-flop
header
        latch (IQ,IQN){
                enable : "!clk";
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
		else if (clk == 0)
			q <= #1 d;
end

step {clk 0} {d 1} {clrb 1}
measure {q v} with {d 0} {clk v} {clrb 1}
measure {q ^} with {d 1} {clk v} {clrb 1}
measure {q v} with {d v} {clk 0} {clrb 1}
measure {q ^} with {d ^} {clk 0} {clrb 1}
measure {q v} with {d 1} {clk 1} {clrb v}

# measure the input capacitances
cap clk with {d 1} {clrb 1}
cap d with {clk 0}
cap clrb with {clk 1}

# measure setup/hold times
setup {d ^} to {q ^} with {clrb 1} {clk ^}
setup {d v} to {q v} with {clrb 1} {clk ^}
hold  {d ^} to {q v} with {clrb 1} {clk ^}
hold  {d v} to {q ^} with {clrb 1} {clk ^}

