comment Scan Flip Flop with input hold mux

function q = IQ

# Special synopsys header for a flip-flop
header
        test_cell() {
            ff(IQ,IQN) {
                next_state : "((!sel&d0)|(sel&d1))" ;
                clocked_on : "clk" ;
            }
            pin(d0) {
                direction : input ;
            }
            pin(d1) {
                direction : input ;
            }
            pin(s_in) {
                direction : input ;
                signal_type : "test_scan_in" ;
            }
            pin(s_en) {
                direction : input ;
                signal_type : "test_scan_enable" ;
            }
            pin(clk) {
                direction : input ;
            }
            pin(sel) {
                direction : input ;
            }
            pin(s_out) {
                direction : output ;
                signal_type : "test_scan_out" ;
                function : "IQ" ;
                test_output_only : true ;
            }
            pin(q) {
                direction : output ;
                function : "IQ" ;
            }
        }
	ff (IQ,IQN){
		clocked_on : "clk";
                next_state : "(!s_en&((!sel&d0)|(sel&d1)))|(s_en&s_in)";
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

step {clk ^v} {d0 1} {d1 1} {sel 0} {s_in 0} {s_en 0}
measure {q v} with {d0 0} {d1 1} {clk ^v} {sel 0}
measure {q ^} with {d0 1} {d1 1} {clk ^v} {sel 0}
measure {q v} with {d1 0} {d0 1} {clk ^v} {sel 1}
measure {q ^} with {d1 1} {d0 1} {clk ^v} {sel 1}
measure {s_out ^} with {d1 1} {d0 1} {s_in 1} {s_en 1} {sel 1} {clk ^v}
measure {s_out v} with {d1 1} {d0 1} {s_in 0} {s_en 1} {sel 1} {clk ^v}


# measure the input capacitance when clk is low
cap clk with {d0 0} {d1 1} {sel 1} {s_en 0}
cap d0 with {clk 0} {d1 1} {s_en 0}
cap d1 with {clk 0} {d0 1} {s_en 0}
cap sel with  {s_en 0} {d0 0} {d1 1}
cap s_in with {s_en 1}
cap s_en with

# measure setup/hold times
setup {d0 ^} to {q ^} with {clk ^v} {d1 0} {sel 0} {s_in 0} {s_en 0}
setup {d0 v} to {q v} with {clk ^v} {d1 1} {sel 0} {s_in 0} {s_en 0}
setup {d1 ^} to {q ^} with {clk ^v} {d0 0} {sel 1} {s_in 0} {s_en 0}
setup {d1 v} to {q v} with {clk ^v} {d0 1} {sel 1} {s_in 0} {s_en 0}
setup {sel v} to {q ^} with {clk ^v} {d0 1} {d1 0} {s_in 0} {s_en 0}
setup {sel ^} to {q v} with {clk ^v} {d0 1} {d1 0} {s_in 0} {s_en 0}
setup {s_in ^} to {q ^} with {clk ^v} {d0 0} {d1 1} {s_en 1} {sel 0}
setup {s_in v} to {q v} with {clk ^v} {d0 0} {d1 1} {s_en 1} {sel 0}
setup {s_en ^} to {q ^} with {clk ^v} {d0 0} {d1 1} {s_in 1} {sel 0}
setup {s_en v} to {q v} with {clk ^v} {d0 0} {d1 1} {s_in 1} {sel 0}
hold {d0 ^} to {q v} with {clk ^v} {sel 0} {d1 0} {s_in 0} {s_en 0}
hold {d0 v} to {q ^} with {clk ^v} {sel 0} {d1 1} {s_in 0} {s_en 0}
hold {d1 ^} to {q v} with {clk ^v} {sel 1} {d0 0} {s_in 0} {s_en 0}
hold {d1 v} to {q ^} with {clk ^v} {sel 1} {d0 1} {s_in 0} {s_en 0}
hold {sel ^} to {q v} with {clk ^v} {d0 0} {d1 1} {s_in 0} {s_en 0}
hold {sel v} to {q ^} with {clk ^v} {d0 0} {d1 1} {s_in 0} {s_en 0}
hold {s_in ^} to {q v} with {clk ^v} {d0 0} {d1 0} {s_en 1} {sel 1}
hold {s_in v} to {q ^} with {clk ^v} {d0 0} {d1 0} {s_en 1} {sel 1}
hold {s_en ^} to {q v} with {clk ^v} {d0 0} {d1 0} {s_in 1} {sel 1}
hold {s_en v} to {q ^} with {clk ^v} {d0 0} {d1 0} {s_in 1} {sel 1}

