#! /bin/nawk -f

BEGIN	{
		for (i = 2; i < 81; i += 2) {
			printf "fstobdf -fn \"-adobe-helvetica-bold-r-normal-*-%d-*-75-75-p-*-iso8859-1\" -s mmi18:7100 > Helvetica-Bold%d.bdf\n", i, i;
		}
	}
