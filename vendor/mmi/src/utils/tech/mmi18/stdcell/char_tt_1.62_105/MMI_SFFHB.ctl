comment Scan Flip Flop with input hold mux

function q = IQ

# Special synopsys header for a flip-flop
header
        test_cell() {
            ff(IQ,IQN) {
                next_state : "((!hold&d)|(hold&IQ))" ;
                clocked_on : "clk" ;
            }
            pin(d) {
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
            pin(hold) {
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
                next_state : "(!s_en&((!hold&d)|(hold&IQ)))|(s_en&s_in)";
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

step {clk ^v} {d 1} {hold 0} {s_in 0} {s_en 0}
measure {q v} with {d 0} {clk ^v} {hold 0}
measure {q ^} with {d 1} {clk ^v} {hold 0}
step {clk ^v} {d 1} {hold 0} {s_in 0} {s_en 1}
measure {s_out ^} with {s_in 1} {s_en 1} {hold 0} {clk ^v}
measure {s_out v} with {s_in 0} {s_en 1} {hold 0} {clk ^v}


# measure the input capacitance when clk is low
cap clk with {d 0} {hold 0} {s_en 0}
cap d with {clk 0} {s_en 0}
cap hold with  {s_en 0}
cap s_in with {s_en 1}
cap s_en with

# measure setup/hold times
setup {d ^} to {q ^} with {clk ^v} {hold 0} {s_in 0} {s_en 0}
setup {d v} to {q v} with {clk ^v} {hold 0} {s_in 0} {s_en 0}
setup {s_in ^} to {q ^} with {clk ^v} {d 0} {s_en 1} {hold 0}
setup {s_in v} to {q v} with {clk ^v} {d 0} {s_en 1} {hold 0}
setup {s_en ^} to {q ^} with {clk ^v} {d 0} {s_in 1} {hold 0}
setup {s_en v} to {q v} with {clk ^v} {d 0} {s_in 1} {hold 0}
hold {d ^} to {q v} with {clk ^v} {hold 0} {s_in 0} {s_en 0}
hold {d v} to {q ^} with {clk ^v} {hold 0} {s_in 0} {s_en 0}
hold {s_in ^} to {q v} with {clk ^v} {d 0} {s_en 1} {hold 0}
hold {s_in v} to {q ^} with {clk ^v} {d 0} {s_en 1} {hold 0}
hold {s_en ^} to {q v} with {clk ^v} {d 0} {s_in 1} {hold 0}
hold {s_en v} to {q ^} with {clk ^v} {d 0} {s_in 1} {hold 0}

