
gate_type! > [nl_reference gate_ref, char *file, int line]
		: tr:TRAN_GATE	<< gate_ref = v2nl_primitive_reference ($tr->token);
				   file = $tr->file; line = $tr->line; >>
		| an:AND_GATE	<< gate_ref = v2nl_primitive_reference ($an->token);
				   file = $an->file; line = $an->line; >>
		| or:OR_GATE	<< gate_ref = v2nl_primitive_reference ($or->token);
				   file = $or->file; line = $or->line; >>
		| nd:NAND_GATE	<< gate_ref = v2nl_primitive_reference ($nd->token);
				   file = $nd->file; line = $nd->line; >>
		| nr:NOR_GATE	<< gate_ref = v2nl_primitive_reference ($nr->token);
				   file = $nr->file; line = $nr->line; >>
		| xo:XOR_GATE	<< gate_ref = v2nl_primitive_reference ($xo->token);
				   file = $xo->file; line = $xo->line; >>
		| xn:XNOR_GATE	<< gate_ref = v2nl_primitive_reference ($xn->token);
				   file = $xn->file; line = $xn->line; >>
		| no:NOT_GATE	<< gate_ref = v2nl_primitive_reference ($no->token);
				   file = $no->file; line = $no->line; >>
		| bu:BUF_GATE	<< gate_ref = v2nl_primitive_reference ($bu->token);
				   file = $bu->file; line = $bu->line; >>
		;
