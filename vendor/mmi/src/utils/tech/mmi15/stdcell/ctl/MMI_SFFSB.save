comment Scan Flip Flop with asynchronous set

set preset setb

function q = IQ

# Special synopsys header for a flip-flop
header
        test_cell() {
            ff(IQ,IQN) {
                next_state : "d" ;
                clocked_on : "clk" ;
                preset : "!setb" ;
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
            pin(setb) {
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
                signal_type : "test_scan_out" ;
            }
        }
	ff (IQ,IQN){
		clocked_on : "clk";
                next_state : "((!s_en&d)|(s_en&s_in))";
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

step {clk ^v} {d 0} {setb 1} {s_in 0} {s_en 0}
measure {q ^} with {d 1} {clk ^v} 
measure {q v} with {d 0} {clk ^v} 
measure {q ^} with {setb v}
measure {s_out ^} with {s_in 1} {s_en 1} {setb 1} {clk ^v}
measure {s_out v} with {s_in 0} {s_en 1} {setb 1} {clk ^v}
measure {s_out ^} with {setb v}


# measure the input capacitance of wen when clk is low
cap clk with {d 0} {setb 1} {s_en 0}
cap d with {clk 0} {s_en 0}
cap setb with  {s_en 0}
cap s_in with {s_en 1}
cap s_en with

# measure setup/hold times
setup {d ^} to {q ^} with {clk ^v} {setb 1} {s_in 0} {s_en 0}
setup {d v} to {q v} with {clk ^v} {setb 1} {s_in 0} {s_en 0}
setup {s_in ^} to {q ^} with {clk ^v} {setb 1} {d 0} {s_en 1}
setup {s_in v} to {q v} with {clk ^v} {setb 1} {d 0} {s_en 1}
setup {s_en ^} to {q ^} with {clk ^v} {setb 1} {d 0} {s_in 1}
setup {s_en v} to {q v} with {clk ^v} {setb 1} {d 0} {s_in 1}
hold {d ^} to {q v} with {clk ^v} {setb 1} {s_in 0} {s_en 0}
hold {d v} to {q ^} with {clk ^v} {setb 1} {s_in 0} {s_en 0}
hold {s_in ^} to {q v} with {clk ^v} {d 0} {s_en 1} {setb 1}
hold {s_in v} to {q ^} with {clk ^v} {d 0} {s_en 1} {setb 1}
hold {s_en ^} to {q v} with {clk ^v} {d 0} {s_in 1} {setb 1}
hold {s_en v} to {q ^} with {clk ^v} {d 0} {s_in 1} {setb 1}

