#header << // -*-Fundamental-*-
#include "port.h"
#include "mem.h"
#include "ar.h"
#include "hashtab.h"
#include "nl.h"
#include "v2nl.h"

struct attrib_s {
  char *text;
  int token;
  char *file;
  int line;
};

typedef struct attrib_s Attrib;

#define v2nl_AST void
#include "v2nl_int.h"
#undef v2nl_AST

#define USER_ZZSYN
#define ZZCOL

#define AST_FIELDS   int token; union { char *text; int num; } u;

#define zzcr_ast(tr, attr, tok, text)	v2nl_cr_ast (tr, attr, tok)
#define zzmk_ast(tr, tok, attr)		v2nl_cr_ast (tr, attr, tok)
#define zzd_ast(tr)			v2nl_d_ast (tr)

#define zzcr_attr(attr, tok, txt)	\
  ((attr)->text = (txt), (attr)->token = tok, \
   (attr)->file = v2nl_current_file, (attr)->line = zzline)
#undef zzd_attr

#define malloc MALLOC
#define calloc CALLOC
#define realloc REALLOC
#define free FREE

#define USER_DEFINED_AST
typedef struct nl_ast_s AST;

#define zzASTright(x)         nl_ast_sibling (x)
#define zzASTright_addr(x)    nl_ast_sibling_addr (x)
#define zzASTdown(x)          nl_ast_child (x)
#define zzASTset_right(x, y)  nl_ast_set_sibling (x, y)
#define zzASTset_down(x, y)   nl_ast_set_child (x, y)
#define zzASTtoken(x)	      nl_ast_token (x)
#define zzASTset_token(x, y)  nl_ast_set_token (x, y)

#define ZZA_STACKSIZE 1024
#define ZZAAT_STACKSIZE 1024

#define zzfailed_pred(_p)     v2nl_failed_predicate (_p);

>>


#parser "v2nl"


<<
#include "v2nl_gettok.h"
>>


#token "[\ \t]+"	<< zzskip (); >>
#token "\n"		<< zzline++;
			   zzendcol = 1;
			   zzskip ();
                        >>

// pre-processor stuff

#token "@"				<< v2nl_wrap (); >>

#token "`timescale"			<< zzskip ();
					   v2nl_line_comment = 1;
					   zzmode (COMMENT);
					>>
#token "`celldefine"			<< zzskip ();
					   v2nl_line_comment = 1;
					   zzmode (COMMENT);
					>>
#token "`endcelldefine"			<< zzskip ();
					   v2nl_line_comment = 1;
					   zzmode (COMMENT);
					>>
#token "`delay_mode_path"		<< zzskip ();
					   v2nl_line_comment = 1;
					   zzmode (COMMENT);
					>>
#token "`define[\ \t]+[A-Za-z_$][A-Za-z0-9_$]*{[\ \t]+~[\n]*}"
					<< zzskip ();
					   v2nl_do_macro_definition (zztext);
					>>

#token "`define[\ \t\n]~[\n]*"		<< v2nl_error ("improper `define syntax"); >>

#token "`undef[\ \t]+[A-Za-z_$][A-Za-z0-9_$]*{[\ \t]+~[\n]*}"
					<< zzskip ();
					   v2nl_do_macro_undef (zztext);
					>>

#token "`undef[\ \t\n]~[\n]*"		<< v2nl_error ("improper `undef syntax"); >>

#token "`include[\ \t]+\"~[\"]+\"~[\n]*"
					<< zzskip ();
					   v2nl_do_include_file (zztext);
					>>

#token "`include[\ \t\n]~[\n]*"		<< v2nl_error ("improper `include syntax"); >>

#token "`ifdef[\ \t]+[A-Za-z_$][A-Za-z0-9_$]*[\ \t]*"
					<<
					   zzskip ();
					   v2nl_do_ifdef (zztext);
					>>

#token "`ifdef[\ \t\n]~[\n]*"		<< v2nl_error ("improper `ifdef syntax"); >>
	
#token "`else{[\ \t]+~[\n]*}"		<< zzskip ();
					   v2nl_do_else (zztext);
					>>

#token "`endif{[\ \t]+~[\n]*}"		<< zzskip ();
					   v2nl_do_endif (zztext);
					>>

#token "`[A-Za-z_$][A-Za-z0-9_$]*"	<< zzskip ();
					   v2nl_do_macro_expansion (zztext);
					>>


// Comments and pragmae.

#token "//[\ \t]*[A-Za-z_$][A-Za-z0-9_$]+"
					<< zzskip ();
					   v2nl_line_comment = 1;
					   if (v2nl_is_pragma_begin (zztext))
					     zzmode (PRAGMA);
					   else
					     zzmode (COMMENT);
					>>

#token "//[\ \t]*{[A-Za-z_$]}"		<< zzskip ();
					   v2nl_line_comment = 1;
					   zzmode (COMMENT);
					>>

#token "/\*[\ \t]*[A-Za-z_$][A-Za-z0-9_$]+"
					<< zzskip ();
					   v2nl_line_comment = 0;
					   if (v2nl_is_pragma_begin (zztext))
					     zzmode (PRAGMA);
					   else
					     zzmode (COMMENT);
					>>

#token "/\*[\ \t]*{[A-Za-z_$]}"		<< zzskip ();
					   v2nl_line_comment = 0;
					   zzmode (COMMENT);
					>>

#token MODULE		"module"
#token ENDMODULE	"endmodule"
#token ASSIGN		"assign"
#token INPUT		"input"
#token OUTPUT		"output"
#token INOUT		"inout"
#token WIRE		"wire"
#token WAND		"wand"
#token WOR		"wor"
#token TRI		"tri"
#token REG		"reg"
#token TRIREG		"trireg"
#token SUPPLY0		"supply0"
#token SUPPLY1		"supply1"
#token PARAMETER	"parameter"
#token STRONG0		"strong0"
#token STRONG1		"strong1"
#token PULL0		"pull0"
#token PULL1		"pull1"
#token WEAK0		"weak0"
#token WEAK1		"weak1"
#token HIGHZ0		"highz0"
#token HIGHZ1		"highz1"
#token TRAN_GATE	"tran"
#token AND_GATE		"and"
#token NAND_GATE	"nand"
#token OR_GATE		"or"
#token NOR_GATE		"nor"
#token XOR_GATE		"xor"
#token XNOR_GATE	"xnor"
#token BUF_GATE		"buf"
#token NOT_GATE		"not"
#token BIN_RADIX	"'[bB]"		<< zzmode (GET_NUMBER); >>
#token HEX_RADIX	"'[hH]"		<< zzmode (GET_NUMBER); >>
#token DEC_RADIX	"'[dD]"		<< zzmode (GET_NUMBER); >>
#token OCT_RADIX	"'[oO]"		<< zzmode (GET_NUMBER); >>

// RTL tokens
#token BEGIN		"begin"
#token END		"end"
#token ALWAYS		"always"
#token INITIAL		"initial"
#token POSEDGE		"posedge"
#token NEGEDGE		"negedge"
#token SENS_OR		"or"
#token IF		"if"
#token ELSE		"else"
#token CASE		"case"
#token CASEX		"casex"
#token CASEZ		"casez"
#token DEFAULT		"default"
#token ENDCASE		"endcase"
#token FOR		"for"
#token FOREVER		"forever"
#token WAIT		"wait"
#token WHILE		"while"
#token FUNCTION		"function"
#token ENDFUNCTION	"endfunction"
#token TASK		"task"
#token ENDTASK		"endtask"
#token SHR		"\>\>"
#token SHL		"\<\<"
#token COND		"?"
#token INTEGER		"integer"

// Unary operators
#token BITNOT		"\~"
#token LOGNOT		"!"
#token AND_REDUCE	
#token NAND_REDUCE	"\~&"
#token OR_REDUCE	
#token NOR_REDUCE	"\~\|"
#token XOR_REDUCE
#token XNOR_REDUCE

// Binary operators
#token AND		"&"
#token OR		"\|"
#token XOR		"^"
#token XNOR		"^\~"
#token XNOR		"\~^"
#token ANDAND		"&&"
#token OROR		"\|\|"
#token ADD		"\+"
#token SUB		"\-"
#token MUL		"\*"
#token DIV		"/"
#token MOD		"%"
#token GT		">"
#token GEQ		">="
#token LT		"<"
#token LEQ		"<="
#token EQ2		"=="
#token EQ3		"==="
#token NEQ		"!="
#token NEQ2		"!=="


// Identifiers and numbers
#token NUMBER		"[0-9_]+"
#token ID		"[A-Za-z0-9_$][A-Za-z0-9_$]*"
#token ID		"\\~[\ \n\t]+"	<< v2nl_process_escaped_id (); >>

// RTL AST node tokens
#token CONCAT
#token REPEAT_CONCAT
#token REF
#token BIT
#token VARBIT
#token SLICE
#token BLOCK
#token LIST
#token CASE_ITEM
#token POS
#token NEG
#token BLOCK_ASSIGN
#token NONBLOCK_ASSIGN
#token DELAY
#token INSTANCE
#token PIN
#token PARAMS
#token FUNCALL
#token CALL
#token VARSHL
#token VARSHR
#token IN
#token RANGE


#lexclass ESCAPED_ID

#token ID	"~[\ \t\n]+"	<< v2nl_process_escaped_id ();
				   zzmode (START);
				 >>

#lexclass GET_NUMBER

#token		"[\ \t]+"	<< zzskip (); >>
#token		"\n"		<< zzskip ();
				   zzline++;
				>>

#token VERILOG_NUMBER	"[0-9a-fA-fxXzZ?_]+"	
				<< zzmode (START); >>


#lexclass COMMENT

#token		"~[\*\n]+"	<< zzskip (); >>
#token		"\n"		<< zzskip ();
				   zzline++;
				   zzendcol = 0;
				   v2nl_maybe_end_comment (zztext);
				>>
#token		"\*~[/\*\n]"	<< zzskip (); >>
#token		"\*[\n]"	<< zzskip ();
				   zzline++;
				   zzendcol = 0;
				   v2nl_maybe_end_comment ("\n");
				>>
#token		"\*/"		<< zzskip ();
				   v2nl_maybe_end_comment (zztext);
				>>
#token		"\*"		<< zzskip (); >>

#token		"@"		<< v2nl_maybe_end_comment (zztext);
				   zzskip ();
				>>


#lexclass PRAGMA

#token PARALLEL_CASE	"parallel_case"	<< if ( v2nl_translate_off )
					     zzskip ();
					>>

#token FULL_CASE	"full_case"	<< if ( v2nl_translate_off )
					     zzskip ();
					>>

#token INFER_MUX	"infer_mux"	<< if ( v2nl_translate_off )
					     zzskip ();
					>>

#token STRING		"string"	<< if ( v2nl_translate_off )
					     zzskip ();
					>> 

#token BOOLEAN		"boolean"	<< if ( v2nl_translate_off )
					     zzskip ();
					>> 

#token INTEGER		"integer"	<< if ( v2nl_translate_off )
					     zzskip ();
					>> 

#token P_BEGIN		"begin"		<< if ( v2nl_translate_off )
					     zzskip ();
					>>

#token P_END		"end"		<< if ( v2nl_translate_off )
					     zzskip ();
					>>

#token ATTRIBUTE	"attribute"	<< if ( v2nl_translate_off )
					     zzskip ();
					>>

#token DENSE		"dense"		<< if ( v2nl_translate_off )
					     zzskip ();
					>>

#token CELL		"cell"		<< if ( v2nl_translate_off )
					     zzskip ();
					>>

#token NET		"net"		<< if ( v2nl_translate_off )
					     zzskip ();
					>>

#token PORT		"port"		<< if ( v2nl_translate_off )
					     zzskip ();
					>>

#token DESIGN		"design"	<< if ( v2nl_translate_off )
					     zzskip ();
					>>

#token MAP_TO_MODULE	"map_to_module"	<< if ( v2nl_translate_off )
					     zzskip ();
					>>

#token RETURN_PORT_NAME	"return_port_name"
					<< if ( v2nl_translate_off )
					     zzskip ();
					>>

#token SYNC_SET_RESET	"sync_set_reset"
					<< if ( v2nl_translate_off )
					     zzskip ();
					>>

#token ASYNC_SET_RESET	"async_set_reset"
					<< if ( v2nl_translate_off )
					     zzskip ();
					>>

#token DC_SCRIPT_BEGIN	"dc_script_begin" <<
					   zzskip ();
					   if ( !v2nl_translate_off ) {
					     v2nl_dc_script = 1;
					     zzmode (COMMENT);
					   }
					>>
					
#token DC_SCRIPT_END	"dc_script_end" << zzskip ();
					   if ( !v2nl_translate_off ) {
					     v2nl_dc_script = 0;
					   }
					>>
					
#token P_EQL		"="		<< if ( v2nl_translate_off )
					     zzskip ();
					>>

#token P_SEMI		";"		<< if ( v2nl_translate_off )
					     zzskip ();
					>>

#token 			"(translate|synthesis)_off"
					<< zzskip ();
					   v2nl_translate_off = 1;
					>>

#token 			"(translate|synthesis)_on"
					<< zzskip ();
					   v2nl_translate_off = 0;
					>>

#token P_ID		"[A-Za-z_$][A-Za-z0-9_$]*"
					<< if ( v2nl_translate_off )
					     zzskip ();
					>>

#token P_STRING		"\"~[\"]*\""	<< if ( v2nl_translate_off )
					     zzskip ();
					>>

#token P_NUMBER		"[0-9]+"	<< if ( v2nl_translate_off )
					     zzskip ();
					>>

#token			"~[A-Za-z0-9_$;=\*\ \t\n]+"
					<< if ( !v2nl_translate_off )
					     v2nl_error ("Unrecognized pragma: "
							 "%s", zztext);
					>>

#token			"\*~[\*/]+"	<< if ( !v2nl_translate_off )
					     v2nl_error ("Unrecognized pragma: "
							 "%s", zztext);
					>>

#token			"[\ \t]+"	<< zzskip (); >>

#token			"\n"		<< zzskip ();
					   zzline++;
					   zzendcol = 0;
					   v2nl_maybe_end_comment (zztext);
					>>

#token			"\*+/"		<< zzskip ();
					   v2nl_maybe_end_comment ("*/");
					>>

#token			"\*+"		<< if ( !v2nl_translate_off )
					     v2nl_error ("Unrecognized pragma: "
							 "%s", zztext);
					>>


#lexclass TRANSLATE_OFF

#token "//[\ \t]*[A-Za-z_$][A-Za-z0-9_\$]+"
					<< zzskip ();
					   v2nl_line_comment = 1;
					   if (v2nl_is_pragma_begin (zztext))
					     zzmode (PRAGMA);
					   else
					     zzmode (COMMENT);
					>>

#token "//[\ \t]*"			<< zzskip ();
					   v2nl_line_comment = 1;
					   zzmode (COMMENT);
					>>

#token "/\*[\ \t]*[A-Za-z_$][A-Za-z0-9_\$]+"
					<< zzskip ();
					   v2nl_line_comment = 0;
					   if (v2nl_is_pragma_begin (zztext))
					     zzmode (PRAGMA);
					   else
					     zzmode (COMMENT);
					>>

#token "/\*[\ \t]*"			<< zzskip ();
					   v2nl_line_comment = 0;
					   zzmode (COMMENT);
					>>

#token "/"				<< zzskip (); >>
#token "~[/\n]+"			<< zzskip (); >>
#token "\n"				<< zzline++;
					   zzendcol = 0;
					   zzskip ();
					>>


#lexclass IFDEF_IGNORE

#token "`ifdef[\ \t]+[A-Za-z_$][A-Za-z0-9_$]*{[\ \t]+~[\n]*}"
					<<
					   zzskip ();
					   v2nl_do_ifdef (zztext);
					>>

#token "`ifdef[\ \t\n]~[\n]*"		<< v2nl_error ("improper `ifdef syntax"); >>

#token "`else{[\ \t]+~[\n]*}"		<< zzskip ();
					   v2nl_do_else (zztext);
					>>

#token "`endif{[\ \t]+~[\n]*}"		<< zzskip ();
					   v2nl_do_endif (zztext);
					>>

#token "~[\ \t\n]+"			<< zzskip (); >>
#token "[\ \t]+"			<< zzskip (); >>
#token "\n"				<< zzskip ();
					   zzendcol = 0;
					   zzline++;
					>>


#lexclass START


verilog_file! 	: ( module )*
		;

module!		: MODULE name:ID	<< v2nl_mod ($name.text); >>
		    port_list ";"
		    ( statement )*
        	  ENDMODULE		<< v2nl_endmod (); >>
		;

port_list!	: "\("	port0:ID	<< v2nl_port ($port0.text); >>
			( "," portn:ID	<< v2nl_port ($portn.text); >>
			)*
		  "\)"
		| /* empty */
	        ;

id_list! [nl_wireclass class, nl_direction dir, nl_type type]
		: id_decl [class, dir, type]
		  ( "," id_decl [class, dir, type] )*
	        ;

id_decl! [nl_wireclass class, nl_direction dir, nl_type type]
		: << char *name; >>
		  id:ID		<< name = STRDUPA ($id.text);
				   v2nl_variable (class, dir, type, name);
				>>
		  { id_decl_assignment [name] }
		;

id_decl_assignment! [char *name]
		: <<  v2nl_rtl >>? rtl_decl_assignment [name]
		| << !v2nl_rtl >>? decl_assignment [name]
		;	 

statement!	: io_decl
		| wire_decl
		| module_inst
		| primitive_inst
		| attribute_stmt
		| pragma_stmt
		| <<  v2nl_rtl >>? integer_decl
		| <<  v2nl_rtl >>? parameter_decl
		| << !v2nl_rtl >>? assign_stmt
		| <<  v2nl_rtl >>? a:rtl_assign_stmt
		| <<  v2nl_rtl >>? p:rtl_process
					<< if ( v2nl_rtl ) {
					     v2nl_create_process (#p);
					   }
					>>
		| <<  v2nl_rtl >>? f:rtl_function
//		| <<  v2nl_rtl >>? t:rtl_task
//					<< if ( v2nl_rtl ) {
//					     nl_ast_dump (#t);
//					     putchar ('\n');
//					   }
//					>>
		;


pragma_stmt!	: SYNC_SET_RESET! P_STRING!
		| ASYNC_SET_RESET! P_STRING!
		;

attribute_stmt!	: attribute_begin
		| attribute_end
		| attribute_decl
		;


attribute_decl!	: << char *name;
		     nl_density density;
		     char object;
		     char type;
		  >>
		  ( DENSE 		<< density = nl_density_dense; >>
		  | /* empty */		<< density = nl_density_sparse; >>
		  )
		  ( CELL		<< object = 'c'; >>
		  | PORT		<< object = 'p'; >>
		  | NET			<< object = 'n'; >>
		  | DESIGN		<< object = 'd'; >>
		  )
		  ATTRIBUTE id:P_ID	<< name = STRDUPA ($id.text); >>
		  ( BOOLEAN		<< type = 'b'; >>
		  | STRING		<< type = 's'; >>
		  | INTEGER		<< type = 'i'; >>
		  )
		  P_SEMI
			<< v2nl_new_attribute (name, density, object, type); >>
		;

attribute_begin!: << char *name;
		     char *str;
		     int n;
		  >>
		  P_BEGIN ATTRIBUTE id:P_ID
				<< name = STRDUPA ($id.text); >>
		  ( P_EQL ( s:P_STRING
				<< str = STRDUPA ($s.text); >>
			    P_SEMI
				<< v2nl_begin_string_attribute (name, str); >>
			  | num:P_NUMBER
				<< n = v2nl_translate_integer ($num.text); >>
			    P_SEMI
				<< v2nl_begin_integer_attribute (name, n); >>
			  )
		  | P_SEMI	<< v2nl_begin_boolean_attribute (name); >>
		  )
		;

attribute_end!	: P_END ATTRIBUTE id:P_ID 	<< v2nl_end_attribute ($id.text); >>
		  P_SEMI
		;	

io_decl!	: << nl_direction dir;
		     nl_type type;
		     nl_wireclass wireclass;
		  >>
		  direction > [dir]	<< switch ( dir ) {
					   case nl_direction_in:
					     wireclass = nl_wireclass_input;
					     break;
					   case nl_direction_out:
					     wireclass = nl_wireclass_output;
					     break;
					   case nl_direction_inout:
					     wireclass = nl_wireclass_inout;
					     break;
					   default:
					     ASSERT (0);
					   }
					>>
		  range_type > [type]
		  id_list [wireclass, dir, type]
		  ";"
		;

direction! > [nl_direction dir]
		: INPUT			<< $dir = nl_direction_in; >>
		| OUTPUT		<< $dir = nl_direction_out; >>
		| INOUT			<< $dir = nl_direction_inout; >>
		;

wire_decl!	: << int class;
		     nl_type type;
		  >>
		  wire_class > [class]
		  range_type > [type]
		  id_list [class, nl_direction_null, type]
		  ";"
		;

wire_class! > [nl_wireclass class]
		: WIRE			<< $class = nl_wireclass_wire; >>
		| TRI			<< $class = nl_wireclass_tri; >>
		| SUPPLY0		<< $class = nl_wireclass_supply0; >>
		| SUPPLY1		<< $class = nl_wireclass_supply1; >>
		| WAND			<< $class = nl_wireclass_wand; >>
		| WOR			<< $class = nl_wireclass_wor; >>
		| REG			<< $class = nl_wireclass_reg; >>
		| TRIREG		<< $class = nl_wireclass_trireg; >>
		;

integer_decl!	: << nl_type type = v2nl_integer (); >>
		  INTEGER id_list [nl_wireclass_reg, nl_direction_null, type]
		  ";"
		;

parameter_decl!	: << int left, right; >>
		  PARAMETER
		  ( range > [left, right]
				<< v2nl_warning ("parameter range, [%d:%d], "
						 "is ignored.", left, right);
				>>
		  | /* empty */
		  )
		  parameter_assignment ( "," parameter_assignment )*
		  ";"
		;

parameter_assignment!
		: << char *name; >>
		  id:ID		<< name = STRDUPA ($id.text); >>
		  "="
		  e:rtl_expr	<< v2nl_parameter (name, #e); >>
		;

range_type! > [nl_type type]
		: << int left, right; >>
		  range > [left, right]
					<< $type = v2nl_array (left, right);>>
		| /* empty */		<< $type = v2nl_scalar (); >>
		;

range! > [int left, int right]
		: "\[" integer_expr > [$left] ":" integer_expr > [$right] "\]"
		;

integer_expr! > [int value]
		// The purpose of splitting out NUMBER as a special
		// case is improve performance in the typical case in
		// which an integer_expr is just a number.  This
		// produces an ambiguity warning from ANTLR, but it's
		// OK, because ANTLR picks the first subrule by default.
		: n:NUMBER	<< $value = v2nl_translate_integer ($n.text);
				>>
		| exp:rtl_expr	<< $value = v2nl_eval_integer_expr (#exp);
				>>
		;

integer_expr2! > [int value]
		: exp:rtl_expr	<< $value = v2nl_eval_integer_expr (#exp); >>
		;

assign_stmt!	: ASSIGN { drive_strength } { delay }
		  assignment ( "," assignment )*
		  ";"
		;

delay!		: "#" NUMBER
		;

drive_strength!	: "\(" strength0 "," strength1 "\)"
		| "\(" strength1 "," strength0 "\)"
		;

strength0!	: SUPPLY0 
		| STRONG0
		| PULL0
		| WEAK0
		| HIGHZ0
		;

strength1!	: SUPPLY1
		| STRONG1
		| PULL1
		| WEAK1
		| HIGHZ1
		;

assignment!
		: << ar lhs, rhs; >>
		  lvalue > [lhs] eq:"="! expr > [rhs]
			<< v2nl_assign (lhs, rhs, &($eq));
			   ar_free (lhs);
			   ar_free (rhs);
			>>
		; 

decl_assignment! [char *name]
		: << ar lhs, rhs; >>
		  eq:"="! expr > [rhs]
			<< lhs = v2nl_var_ref (name);
			   v2nl_assign (lhs, rhs, &($eq));
			   ar_free (lhs);
			   ar_free (rhs);
			>>   
		;

primitive_inst!	: << nl_reference gate_ref;
		     char *file;
		     int line;
		     Attrib t;
		  >>
		  gate_type > [t]	<< gate_ref = v2nl_primitive_reference (&t);
					   file = t.file;
					   line = t.line;
					>>
		  { delay }
		  gate_instance [gate_ref, file, line]
		    ( "," gate_instance [gate_ref, file, line] )*
		  ";"
		;


gate_type! > [Attrib t]
		: tr:TRAN_GATE	<< $t = $tr; >>
		| an:AND_GATE 	<< $t = $an; >>
		| or:OR_GATE  	<< $t = $or; >>
		| nd:NAND_GATE	<< $t = $nd; >>
		| nr:NOR_GATE 	<< $t = $nr; >>
		| xo:XOR_GATE 	<< $t = $xo; >>
		| xn:XNOR_GATE	<< $t = $xn; >>
		| no:NOT_GATE 	<< $t = $no; >>
		| bu:BUF_GATE	<< $t = $bu; >>
		;

gate_instance_name! > [char *name, nl_type type, char *file, int line]
		: n:ID		<< $name = STRDUP ($n.text);
				   $file = $n.file; 
				   $line = $n.line;
				>>
		  range_type > [$type]
		;

gate_instance! [nl_reference gate_ref, char *file, int line]
		: << char *name;
		     nl_type type;
		     ar nets;
		     ar params = ar_alloc (4, sizeof (ar));
		  >>
  		  ( gate_instance_name > [name, type, file, line]
		  | /* empty */		<< name = NULL;
					   type = v2nl_scalar ();
					>>
		  )
		  "\(" expr > [nets]		<< ar_add (params, &nets); >>
		 	( "," expr > [nets]	<< ar_add (params, &nets); >>
		       	)*		
		  "\)"			<< v2nl_primitive_gate (name, gate_ref,
								type, params,
								file, line);

					   if ( name != NULL ) {
					     FREE (name);
					   }

					   ar_for_all (params, ar, nets) {
					     ar_free (nets);
					   } ar_end_for;

					   ar_free (params);
					>>
		;
		
module_inst!	: << char *ref_name;
		     nl_reference ref;
		     ar params = NULL;
		  >>
		  mod:ID		<< ref_name = STRDUPA ($mod.text); >>
		  { module_parameters > [params] }
					<< ref = v2nl_reference (ref_name,
								 params);
					>>
		  instance_list[ref] ";"
		;

module_parameters! > [ar result]
		: << int val; >>
		  "#" "\(" integer_expr > [val]
				<< $result = ar_alloc (1, sizeof (int));
				   ar_add ($result, &val);
				>>
			   ( "," integer_expr > [val]
				<< ar_add ($result, &val); >>
			   )* 
		      "\)"
		;

instance_list! [nl_reference ref]
		: instance [ref] (","! instance [ref] )*
		;

instance! [nl_reference ref]
		: << nl_cell cell; >>
		  inst:ID 		<< cell = v2nl_cell (ref, &($inst)); >>
		  "\("
		    { named_inst_ports [cell] | positional_inst_ports [cell] }
		  "\)"
		;

named_inst_ports! [nl_cell cell]
		: << !v2nl_rtl >>? named_inst_port[cell]
				   ( "," named_inst_port[cell] )*
		| <<  v2nl_rtl >>? rtl_named_inst_port[cell]
				   ( "," rtl_named_inst_port[cell] )*
		;


rtl_named_inst_port! [nl_cell cell]
		: << ar nets;
		     char *pin_name;
		  >>
		  "\." pin:ID		<< pin_name = STRDUPA ($pin.text);
					   v2nl_rtl_allow_implicit_wires (1);
					>>
		  "\(" ( e:rtl_expr	<< nets = v2nl_random_expr (#e);
					   v2nl_pins (cell, pin_name, nets);
					   ar_free (nets);
					>>
		       | /* empty */	<< v2nl_pins (cell, pin_name, NULL);
					>>
		       )
		  "\)"			<< v2nl_rtl_allow_implicit_wires (0); >>
		;

named_inst_port! [nl_cell cell]
		: << ar nets;
		     char *pin_name;
		  >>
		  "\." pin:ID		<< pin_name = STRDUPA ($pin.text); >>
		  "\(" ( expr > [nets]
					<< v2nl_pins (cell, pin_name, nets);
					   ar_free (nets);
					>>
		       | /* empty */	<< v2nl_pins (cell, pin_name, NULL);
					>>
		       )
		  "\)"
		;

positional_inst_ports! [nl_cell cell]
		: << int count = 1; >>
		  positional_inst_port [count]
		  ( "," << count++; >> positional_inst_port [count] )*
		;

positional_inst_port! [int index]
		: exp:rtl_expr	<< 
				   v2nl_error ("positional port connections are not supported.");
				   /* 
				   v2nl_pos_refpin (index);
				   v2nl_pins ($exp);
				   */
				>>
		;

variable_ref! > [ar result]
		: << char *name;
		     int l, r;
		  >>
		  id:ID		<< name = STRDUPA ($id.text); >>
		    ( "\[" integer_expr > [l]
			( ":" integer_expr > [r]
				<< $result = v2nl_var_slice (name, l, r); >>
			| /* empty */
				<< $result = v2nl_var_bit (name, l); >>
			)
		      "\]"
		    | /* empty */
				<< $result = v2nl_var_ref (name); >>
		    )
		;

expr! > [ar result]
		: concat_expr > [$result]
		| variable_ref > [$result]
		| constant > [$result]
		;

expr_list! > [ar result]
		: << ar nets; >>
		  expr > [$result]
		  ( "," expr > [nets]	<< ar_append ($result, nets);
					   ar_free (nets);
					>>
		  )*
		;

concat_expr! > [ar result]
		: << int x;
		     ar nets;
		  >>
		  "\{" ( n:NUMBER << x = v2nl_translate_integer ($n.text); >>
			 ( concat_expr > [nets]
				<< $result = v2nl_repeat_concat (x, nets);
				   ar_free (nets);
				>>
			 | "," expr_list > [nets]
				<< $result = v2nl_get_integer (x);
				   ar_append ($result, nets);
				   ar_free (nets);
				>>
			 )
		       | expr_list > [$result]
		       )
		  "\}"
		;

//concat_expr! > [ar result]
//		: << int repeat;
//		     ar nets;
//		  >>
//		  "\{"	( n:NUMBER
//				<< repeat = v2nl_translate_integer ($n.text); >>
//			  concat_expr > [nets]
//				<< $result = v2nl_repeat_concat (repeat, nets);
//				   ar_free (nets);
//				>>
//			| expr_list > [$result]
//			)
//		  "\}"
//		;

lvalue! > [ar result]
		: variable_ref > [$result]
		| lvalue_concat > [$result]
		;

lvalue_list! > [ar result]
		: << ar nets; >>
		  lvalue > [$result]
		  ( "," lvalue > [nets]	<< ar_append ($result, nets);
					   ar_free (nets);
					>>
		  )*
		;

lvalue_concat! > [ar result]
		: "\{" lvalue_list > [$result] "\}"
		;

constant! > [ar result]
		: << int x;
		     char radix;
		  >>
		  n:NUMBER << x = v2nl_translate_integer ($n.text); >>
		    (	( BIN_RADIX	<< radix = 'b'; >>
			| HEX_RADIX	<< radix = 'h'; >>
			| DEC_RADIX	<< radix = 'd'; >>
			| OCT_RADIX	<< radix = 'o'; >>
			) m:VERILOG_NUMBER
			<< $result = v2nl_get_constant_nets (x, radix, $m.text); >>
		    | /* empty */
			<< $result = v2nl_get_integer (x); >>
		    )
		;

rtl_process	: ALWAYS^ rtl_sens_list rtl_seq_statement
		;

rtl_sens_list	: a:"\@"! "\("! l:rtl_sens_items "\)"!
			<< #0 = #(#[LIST, &($a)], #l); >>
		| /* empty */
			<< #0 = #[LIST, NULL]; >>
		;

rtl_sens_items	: rtl_sens_item ( SENS_OR! rtl_sens_item )*
		;

rtl_sens_item	: POSEDGE^ rtl_variable_ref
		| NEGEDGE^ rtl_variable_ref
		| rtl_variable_ref
		;

rtl_wire_class! > [nl_wireclass class]
		: WIRE			<< $class = nl_wireclass_wire; >>
		| TRI			<< $class = nl_wireclass_tri; >>
		| SUPPLY0		<< $class = nl_wireclass_supply0; >>
		| SUPPLY1		<< $class = nl_wireclass_supply1; >>
		| WAND			<< $class = nl_wireclass_wand; >>
		| WOR			<< $class = nl_wireclass_wor; >>
		| REG			<< $class = nl_wireclass_reg; >>
		| TRIREG		<< $class = nl_wireclass_trireg; >>
		| INPUT			<< $class = nl_wireclass_input; >>
		| OUTPUT		<< $class = nl_wireclass_output; >>
		| INOUT			<< $class = nl_wireclass_inout; >>
		;

rtl_decl! [nl_subprogram subr]
		: << nl_wireclass class;
		     nl_type type;
		  >>
		  rtl_wire_class > [class]
		  range_type > [type] 
                  rtl_id_list [subr, class, type]
		  ";"
		;

rtl_id_list! [nl_subprogram subr, nl_wireclass class, nl_type type]
		: rtl_id_decl [subr, class, type]
		  ( "," rtl_id_decl [subr, class, type] )*
		;

rtl_id_decl! [nl_subprogram subr, nl_wireclass class, nl_type type]
		: id:ID	<< v2nl_declare_rtl_var (subr, class, type, $id.text);
			>>
		;

rtl_range!	: "\["! l:rtl_integer_expr a:":"! r:rtl_integer_expr "\]"!
					<< #0 = #(#[RANGE, &($a)], #l, #r); >>
		| /* empty */
					<< #0 = #[RANGE, NULL]; >>
		;

rtl_function!	: << nl_type type;
		     char *name;
		     nl_subprogram subr;
		  >>
	          FUNCTION range_type > [type] id:ID 
			<< subr = v2nl_create_function ($id.text, type);
			   v2nl_current_subprogram = subr;
			>>
		  ";"
		  prags:rtl_function_pragmas
			<< v2nl_add_function_pragmas (subr, #prags); >>
		  rtl_decls [subr]
		  body:rtl_seq_statement
		  ENDFUNCTION!
			<< v2nl_add_function_body (subr, #body);
			   v2nl_current_subprogram = NULL;
			>>
		;

rtl_decls [nl_subprogram subr]
		: ( rtl_decl [subr] )*
		;

rtl_function_pragmas
		: ( rtl_function_pragma )*
		;

rtl_function_pragma
		: MAP_TO_MODULE^ P_ID
		| RETURN_PORT_NAME^ P_ID
		;

//rtl_task	: TASK^ ID
//		  ( rtl_decl )*
//		  rtl_seq_statement
//		  ENDTASK
//		;

rtl_assign_stmt!: ASSIGN { delay }
		  rtl_cont_assignment ( "," rtl_cont_assignment )* ";"
		;

rtl_cont_assignment!
		: << ar lhs; >>
		  lvalue > [lhs] eq:"=" e:rtl_expr
			<< v2nl_do_rtl_assign (lhs, #e, &($eq));
			   ar_free (lhs);
			>>
		;

rtl_decl_assignment! [char *name]
		: << int flag;
		     ar lhs;
		  >>
		  eq:"=" e:rtl_expr
			<< lhs = v2nl_var_ref (name);
			   v2nl_do_rtl_assign (lhs, #e, &($eq));
			   ar_free (lhs);
			>>
		;

//rtl_module_inst!: << char *modname;
//		     nl_reference ref;
//		  >>
//		  m:ID		<< modname = STRDUPA ($m.text); >>
//		  p:rtl_module_parameters
//				<< ref = v2nl_parameterized_ref (modname, #p); >>
//		  instance_list [ref]
//		  ";"
//		;

//rtl_module_parameters
//		: a:"#"! "\("! p:rtl_integer_expr ( ","! rtl_integer_expr )* "\)"!
//				<< #0 = #(#[PARAMS, &($a)], #p); >>
//		| /* empty */
//				<< #0 = #(#[PARAMS, NULL]); >>
//		;

rtl_begin_name	: ":"! ID
		| /* empty */	<< #0 = #[LIST, NULL]; >>
		;
rtl_seq_statement
		: BEGIN^ rtl_begin_name ( rtl_seq_statement )+ END!
		| rtl_assignment_statement
		| rtl_if_statement
		| rtl_case_statement
		| rtl_for_statement
		| rtl_task_enable
		| rtl_delay rtl_seq_statement_or_null
		;

rtl_task_enable	: id:ID { "\("! rtl_expr ( ","! rtl_expr )* "\)"! } ";"!
				<< #0 = #(#[CALL, &($id)], #id); >>
		;
rtl_seq_statement_or_null
		: rtl_seq_statement
		| ";"!
		;

rtl_if_statement: IF^ "\("! rtl_expr "\)"! rtl_seq_statement_or_null
		  ( ELSE! rtl_seq_statement_or_null
		  | /* empty */
		  )
		;

rtl_case_statement
		: ( CASE^ | CASEX^ | CASEZ^ ) "\("! rtl_expr "\)"!
		  rtl_case_pragma_list
		  ( rtl_case_item )+
		  ENDCASE!
		;

rtl_for_assignment!
		: lhs:rtl_lvalue a:"=" rhs:rtl_expr
			<< #0 = #(#[BLOCK_ASSIGN, &($a)], #rhs, #lhs); >>
		;		
		
rtl_for_statement
		: FOR^ "\("!
		  rtl_for_assignment ";"!
		  rtl_expr ";"!
		  rtl_for_assignment "\)"!
		  rtl_seq_statement
		;

rtl_case_pragma_list
		: ( rtl_case_pragma )*	<< #0 = #(#[LIST, NULL], #0); >>
		;

rtl_case_pragma
		: FULL_CASE
		| PARALLEL_CASE
		| INFER_MUX
		;

rtl_case_item	: e:rtl_expr_list a:":"! rtl_seq_statement_or_null
				<< #0 = #(#[CASE_ITEM, &($a)], #e); >>
		| DEFAULT^ { ":"! } rtl_seq_statement_or_null
		;

rtl_expr_list	: e:rtl_expr ( ","! rtl_expr )*
			<< #0 = #(#[LIST, NULL], #e); >>
		;

rtl_delay	: a:"#"! n:NUMBER	<< #0 = #(#[DELAY, &($a)], #n); >>
		;

rtl_assignment_statement!
		: << int tok;
		     Attrib *attr;
		  >>
		  lhs:rtl_lvalue
		  ( eq:"="!	<< tok = BLOCK_ASSIGN;
				   attr = &($eq);
				>>
		  | leq:LEQ!	<< tok = NONBLOCK_ASSIGN;
				   attr = &($leq);
				>>
		  )
		  { del:rtl_delay } rhs:rtl_expr ";"!
				<< #0 = #(#[tok, attr], #rhs, #lhs, #del); >>
		;

rtl_lvalue	: rtl_variable_ref
		| rtl_lvalue_concat
		;

rtl_lvalue_list	: rtl_lvalue ( ","! rtl_lvalue )*
		;

rtl_lvalue_concat
		: a:"\{"! e:rtl_lvalue (","! rtl_lvalue )* "\}"!
					<< #0 = #(#[CONCAT, &($a)], #e); >>
		;

rtl_variable_ref: << int l, r;
		     int is_param;
		     int flag;
		  >>
		  v:rtl_variable > [is_param]
		  ( ( a:"\["!	<< if ( is_param ) {
				     v2nl_error ("bit or slice operation "
						 "applied to parameter");
				   }
				>>
			l:rtl_expr!
			( ":"! r:rtl_integer_expr!
				<< l = v2nl_eval_integer_expr (#l);
				   #0 = #(#[SLICE, &($a)], #v,
				 	  v2nl_make_integer_ast (l),
					  #r);
				>>
			| /* empty */
				<< flag = v2nl_eval_expr (#l, &l);
				   if ( flag ) {
				     zzfree_ast (#l);
				     #0 = #(#[BIT, &($a)], #v,
					    v2nl_make_integer_ast (l));
				   }
				   else {
				     #0 = #(#[VARBIT, &($a)], #v, #l);
				   }
				>>
			)
		      "\]"!
		    | /* empty */
			)
		  )
		;

rtl_variable! > [int is_param]
		: id:ID	<< #0 = v2nl_rtl_var_ref (&($id), &($is_param)); >>
		;

rtl_integer_expr: << int value; >>
		  exp:rtl_expr	<< value = v2nl_eval_integer_expr (#exp);
				   #0 = v2nl_make_integer_ast (value);
				>>
		;

rtl_expr	: rtl_expr11
		;

rtl_expr11	: rtl_expr10 { COND^ rtl_expr11 ":"! rtl_expr11 }
		;

rtl_expr10	: rtl_expr9  ( OROR^ rtl_expr9 )*
		;

rtl_expr9	: rtl_expr8  ( ANDAND^ rtl_expr8 )*
		;

rtl_expr8	: rtl_expr7  ( OR^ rtl_expr7 )*
		;

rtl_expr7	: rtl_expr6  ( (AND^ | XOR^ | XNOR^) rtl_expr6 )*
		;

rtl_expr6	: rtl_expr5  ( (EQ2^ | NEQ^ | EQ3^ | NEQ2^) rtl_expr5 )*
		;

rtl_expr5	: rtl_expr4  ( (LT^ | LEQ^ | GT^ | GEQ^) rtl_expr4 )*
		;

rtl_expr4	: rtl_expr3  ( (SHR^ | SHL^) rtl_expr3 )*
		;

rtl_expr3	: rtl_expr2  ( (ADD^ | SUB^) rtl_expr2 )*
		;

rtl_expr2	: rtl_expr1  ( (MUL^ | DIV^ | MOD^) rtl_expr1 )*
		;

rtl_expr1	: aa:ADD!    	a:rtl_expr1	<< #0 = #(#[POS,        &($aa)], #a); >>
		| ba:SUB!	b:rtl_expr1	<< #0 = #(#[NEG,        &($ba)], #b); >>
		| ca:AND!	c:rtl_expr1	<< #0 = #(#[AND_REDUCE, &($ca)], #c); >>
		| da:OR!	d:rtl_expr1	<< #0 = #(#[OR_REDUCE,  &($da)], #d); >>
		| ea:XOR!	e:rtl_expr1	<< #0 = #(#[XOR_REDUCE, &($ea)], #e); >>
		| fa:XNOR!	f:rtl_expr1	<< #0 = #(#[XNOR_REDUCE,&($fa)], #f); >>
		| NAND_REDUCE^	rtl_expr1
		| NOR_REDUCE^	rtl_expr1
		| LOGNOT^	rtl_expr1
		| BITNOT^	rtl_expr1
		| rtl_expr0
		;

rtl_expr0	: rtl_concat_expr
		| rtl_variable_ref
		| rtl_constant
		| rtl_function_call
		| "\("! rtl_expr "\)"!
		;

rtl_function_call
		: id:ID "\("! ( rtl_expr ( ","! rtl_expr )*
			      | /* empty */
			      )
		  	"\)"!
				<< #0 = v2nl_function_call (#id); >>
		;

rtl_concat_expr	: << int n;
		     AST *rpt;
		  >>
		  a:"\{"! e:rtl_expr ( c:rtl_concat_expr
					<< zzASTset_right (#e, NULL);
					   n = v2nl_eval_integer_expr (#e);
					   rpt = v2nl_make_integer_ast (n);
					   #0 = #(#[REPEAT_CONCAT, &($a)], 
						  rpt, #c);
					>>
				   | ( ","! rtl_expr )*
					<< #0 = #(#[CONCAT, &($a)], #e); >>
				   )
		  "\}"!
		;

rtl_integer	: NUMBER
		;

rtl_constant	: NUMBER
		  { ( BIN_RADIX^ | HEX_RADIX^ | DEC_RADIX^ | OCT_RADIX^ )
	 	    VERILOG_NUMBER
		  }
		;
