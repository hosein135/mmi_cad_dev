#header << // -*-Fundamental-*-
#include <assert.h>
#include "port.h"
#include "charptr.h"
#include "error.h"
#include "mem.h"
#include "ar.h"
#include "hashtab.h"
#include "skip-list.h"
#include "nl.h"
#include "pnl.h"
#include "vim2nl.h"
#include "vim2nl_int.h"

#define USER_ZZSYN

#if 0
#  define AST_FIELDS   int token; char *text;
#  define zzcr_ast(tr, attr, tok, txt) { cr_ast (tr, attr, tok, txt); }
#  define zzmk_ast(tr, tok, txt)	     (AST *) mk_ast (tr, tok, txt)
#endif

#define zzcr_attr(attr, tok, text)	(*(attr) = (text))
#undef  zzd_attr

>>

#parser "vim"


#lexclass START

#token 			"[\ \t]+"	<< zzskip (); >>
#token VIM_VERSION	"VIM_VERSION"	<< zzmode (STRINGS); >>
#token PRTDEF		"PRTDEF"	<< zzmode (STRINGS); >>
#token PRTREF		"PRTREF"	<< zzmode (STRINGS); >>
#token NET		"NET"		<< zzmode (STRINGS); >>
#token PNET		"PNET"		<< zzmode (STRINGS); >>
#token USGDEF		"USGDEF"	<< zzmode (STRINGS); >>
#token UPIN		"UPIN"		<< zzmode (STRINGS); >>
#token PPIN		"PPIN"		<< zzmode (STRINGS); >>
#token RPIN		"RPIN"		<< zzmode (STRINGS); >>
#token TECH		"TECH"		<< zzmode (STRINGS); >>
#token PLACE		"PLACE"		<< zzmode (STRINGS); >>
#token SCALE		"SCALE"		<< zzmode (STRINGS); >>
#token GROUP		"GROUP"
#token CKTROW		"CKTROW"	<< zzmode (STRINGS); >>
#token OUTLINE		"OUTLINE"	<< zzmode (STRINGS); >>
#token RCT		"RCT"		<< zzmode (STRINGS); >>
#token RULEDEF		"RULEDEF"	<< zzmode (STRINGS); >>
#token PHYSCELL		"PHYSCELL"	<< zzmode (STRINGS); >>
#token PORT		"PORT"		<< zzmode (STRINGS); >>


#lexclass STRINGS

#token STRING		"~[\ \t\n]+"
#token			"[\ \t]+"	<< zzskip (); >>
#token 			"\n\+~[\ ]*"	<< zzline++;
					   zzskip ();
					   zzmode (STRINGS);
					>>
#token EOL		"\n"		<< zzline++;
					   zzmode (START);
					>>

#lexclass START

tech_file	: ( tech_line )+
		;

place_file	: ( place_line )+
		;

physcell_file	: ( physcell_line )+
		;

tech_line	: version	
		| prtdef
		| netdef
		| pnetdef
		| usgdef
		| ppin
		| group
		;

place_line	: version
		| scale
		| prtref
		| place
		;

physcell_line	: version
	 	| scale
		| ruledef
		| outline
	 	| cktrow
		| rpin
		;

ruledef		: RULEDEF n:STRING	<< vim2nl_place_design ($n);
					   vim2nl_distance_units ();
					   zzmode (START);
					>>
		  PHYSCELL ( STRING )* EOL
		;

outline		: << char *layer;
		     int x, y;
		     int xsize, ysize;
		  >>
		  OUTLINE STRING EOL
		  rct > [layer, x, y, xsize, ysize]
					<< vim2nl_outline (layer, x, y,
							   xsize, ysize);
					   FREE (layer);
					>>
		;

cktrow		: << char *name;
		     int x, y;
		     int xsize, ysize;
		  >>
		  CKTROW n:STRING	<< name = STRDUPA ($n); >>
		  x_coord > [x]	    y_coord > [y]
		  x_coord > [xsize] y_coord > [ysize]
		  STRING STRING EOL
					<< vim2nl_row (name, x, y, xsize, ysize); >>
		;

rpin		: << nl_port nlport;
		     nl_direction dir;
		  >>
		  RPIN n:STRING		<< nlport = vim2nl_get_port ($n); >>
		  STRING direction > [dir] STRING EOL
					
		  ( port [nlport] )*
		;

port [nl_port port]
		: << char *layer;
		     int x, y;
		     int xsize, ysize;
		  >>
		  PORT STRING EOL
		  rct > [layer, x, y, xsize, ysize]
					<< vim2nl_place_port (port, layer, x, y,
							      xsize, ysize);
					   FREE (layer);
					>>
		;

rct > [char *layer, int x, int y, int xsize, int ysize]
		: RCT n:STRING		<< $layer = STRDUP ($n); >>
		  STRING
		  x_coord > [$x]     y_coord > [$y]
		  x_coord > [$xsize] y_coord > [$ysize]
		  EOL
		;

version		: VIM_VERSION STRING EOL
		;

prtdef		: PRTDEF n:STRING	<< vim2nl_design ($n);
					   zzmode (START);
					>>
		  TECH STRING attributes EOL
		;

prtref		: PRTREF n:STRING	<< vim2nl_place_design ($n);
					   zzmode (START);
					>>
		  TECH attributes EOL
		;

scale		: SCALE n:STRING	<< vim2nl_scale ($n); >>
		  EOL
		;

netdef		: NET n:STRING		<< vim2nl_net ($n); >>
		  attributes EOL
		;

pnetdef		: PNET STRING STRING attributes EOL
		;

usgdef		: << char *name;
		     nl_reference ref;
		     nl_cell cell;
		  >>
		  USGDEF n:STRING	<< name = STRDUPA ($n); >>
		  reference_ref > [ref]	<< cell = vim2nl_cell (name, ref); >>
		  attributes EOL
		  ( upin [cell] )*
		;

ppin		: << char *name;
		     nl_direction dir;
		     nl_net net;
		  >>
		  PPIN n:STRING		<< name = STRDUPA ($n); >>
		  direction > [dir]	
		  net_ref > [net]	<< vim2nl_port (name, dir, net); >>
		  attributes EOL
		;

group		: GROUP 		<< zzmode (STRINGS); >>
		  ( STRING )+ EOL
		;

place		: << nl_cell cell;
		     int x, y;
		     pnl_orientation ori;
		  >>
		  PLACE
		  n1:STRING		<< cell = vim2nl_get_cell ($n1); >>
		  n2:STRING		<< vim2nl_check_reference (cell, $n2); >>
		  x_coord > [x]
		  y_coord > [y]
		  orientation > [ori]
					<< vim2nl_place_cell (cell, x, y, ori); >>
		  ( place_attributes [cell] )*
		  EOL
		;

place_attributes [nl_cell cell]
		: n:STRING		<< vim2nl_place_attribute (cell, $n); >>
		;

upin [nl_cell cell]
		: << nl_pin pin;
		     nl_net net;
		  >>
		  UPIN pin_ref [cell] > [pin]
		  net_ref > [net]	<< vim2nl_connect (pin, net); >>
		  EOL		
		;

attributes	: ( STRING )*
		;

pin_ref [nl_cell cell] > [nl_pin result]
		: << char *name;
		     nl_direction dir;
		  >>
		  n:STRING 		<< name = STRDUPA ($n); >>
		  direction > [dir]	<< $result = vim2nl_pin (cell, name, dir); >>
		;

net_ref > [nl_net result]
		: n:STRING		<< $result = vim2nl_get_net ($n); >>
		;

reference_ref > [nl_reference result]
		: n:STRING		<< $result = vim2nl_get_ref ($n); >>
		;

direction > [nl_direction result]
		: n:STRING		<< $result = vim2nl_direction ($n); >>
		;

orientation > [pnl_orientation result]
		: << int flipped; 
		     int rotation;
		  >>
		  n:STRING		<< flipped = ($n[0] == 'Y'); >>
		  integer > [rotation]	<< $result = vim2nl_orientation (flipped, rotation); >>
		;

integer > [int result]
		: n:STRING		<< $result = atoi ($n); >>
		;

x_coord > [int result]
		: n:STRING		<< $result = vim2nl_coordinate ($n, 'x'); >>
		;

y_coord > [int result]
		: n:STRING		<< $result = vim2nl_coordinate ($n, 'y'); >>
		;

