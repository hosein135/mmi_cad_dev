#header <<
#include "charptr.h"
#define AST_FIELDS   int token; char *text; int num;
#define zzcr_ast(tr, attr, tok, txt) { def2pnl2_cr_ast (tr, attr, tok, txt); }
#define zzmk_ast(tr, tok, txt)	     (AST *) def2pnl2_mk_ast (tr, tok, txt)
#define zzcr_attr(attr, tok, txt)
>>
<<
#include <strings.h>

#define ID_MODE	 zzmode (IDENTIFIER)

static
char *
get_history_string (char *text)
{
  char *s = text;
  char *result;
  int len;

  while ( *s && (*s == ';' || *s == ' ' || *s == '\t' || *s == '\n' ) ) {
    s++;
  }

  result = strdup (s);
  len = strlen (s) - 2;

  while (len >= 0 &&
         (result[len] == ' ' || result[len] == '\t' || result[len] == '\n')) {
    len--;
  }

  result[len+1] = 0;
  return result;
}
>>


#token			"[\ \t]+"	<< zzskip (); >>
#token			"\n"		<< zzline++; zzskip (); >>

#token DEF_BUSBITCHARS		"BUSBITCHARS"
#token DEF_BY			"BY"
#token DEF_COMPONENT		"COMPONENT"
#token DEF_COMPONENTS		"COMPONENTS"
#token DEF_DEFAULT		"DEFAULT"
#token DEF_DESIGN		"DESIGN"
#token DEF_DIEAREA		"DIEAREA"
#token DEF_DIRECTION		"DIRECTION"
#token DEF_DIST			"DIST"
#token DEF_DISTANCE		"DISTANCE"
#token DEF_DIVIDERCHAR		"DIVIDERCHAR"
#token DEF_DO			"DO"
#token DEF_END			"END"
#token DEF_GCELLGRID		"GCELLGRID"
#token DEF_GROUND		"GROUND"
#token DEF_HISTORY		"HISTORY"
#token DEF_HORIZONTAL		"HORIZONTAL"
#token DEF_IN			"IN"
#token DEF_INOUT		"INOUT"
#token DEF_INPUT		"INPUT"
#token DEF_LAYER		"LAYER"
#token DEF_MICRONS		"MICRONS"
#token DEF_NAMESCASESENSITIVE	"NAMESCASESENSITIVE"
#token DEF_NET			"NET"
#token DEF_NETS			"NETS"
#token DEF_OFF			"OFF"
#token DEF_ON			"ON"
#token DEF_OUT			"OUT"
#token DEF_OUTPUT		"OUTPUT"
#token DEF_PIN			"PIN"
#token DEF_PINS			"PINS"
#token DEF_PLACED		"PLACED"
#token DEF_POWER		"POWER"
#token DEF_PROPERTYDEFINITIONS	"PROPERTYDEFINITIONS"
#token DEF_RECT			"RECT"
#token DEF_REGIONS		"REGIONS"
#token DEF_ROW			"ROW"
#token DEF_ROWS			"ROWS"
#token DEF_SIGNAL		"SIGNAL"
#token DEF_SITE			"SITE"
#token DEF_SOURCE		"SOURCE"
#token DEF_SPECIAL		"SPECIAL"
#token DEF_SPECIALNET		"SPECIALNET"
#token DEF_SPECIALNETS		"SPECIALNETS"
#token DEF_START		"START"
#token DEF_STEP			"STEP"
#token DEF_STOP			"STOP"
#token DEF_STRING		"STRING"
#token DEF_TECHNOLOGY		"TECHNOLOGY"
#token DEF_TRACKS		"TRACKS"
#token DEF_UNITS		"UNITS"
#token DEF_UNPLACED		"UNPLACED"
#token DEF_USE			"USE"
#token DEF_VERILOGDESIGNNAME	"VERILOGDESIGNNAME"
#token DEF_VERSION		"VERSION"
#token DEF_VERTICAL		"VERTICAL"
#token DEF_VIAS			"VIAS"
#token DEF_X			"X"
#token DEF_Y			"Y"
#token DEF_N			"N"
#token DEF_S			"S"
#token DEF_FN			"FN"
#token DEF_FS			"FS"

#token DEF_SEMI		";"
#token DEF_NUMBER	"(\-|[])[0-9]+"
#token			"\""		<< zzmode (STRING); zzskip (); >>


#lexclass IDENTIFIER

#token			"[\ \t]+"	<< zzskip (); >>
#token			"\n"		<< zzline++; zzskip (); >>
#token DEF_SEMI		";"		<< zzmode (START); >>
#token DEF_IDENT	"~[\ \t\n]+"	<< zzmode (START); >>


#lexclass STRING

#token			"~[\\\"\n]+"	<< zzmore (); >>
#token			"\\~[\n]"	<< zzmore (); >>
#token			"\\\n"		<< zzmore ();
					   zzline++;
					>>
#token			"\n"		<< zzmore ();
					   zzline++;
					>>
#token DEF_QUOTED	"\""		<< zzreplchar ('\0');
					   zzmode (START);
					>>


#lexclass LEX_HISTORY

#token			"[\ \t]+"	<< zzmore (); >>
#token			"\n"		<< zzline++; zzmore (); >>
#token			"~[\\\";]+"	<< zzmore (); >>
#token			"\\~[]"		<< zzmore (); >>
#token			"\""            << zzmode (LEX_HISTORY_STRING); 
					   zzmore ();
					>>
#token DEF_HISTORY_LIST	";"		<< zzmode (START); >>


#lexclass LEX_HISTORY_STRING

#token			"~[\\\"]+"	<< zzmore (); >>
#token			"\\~[]"		<< zzmore (); >>
#token 			"\""		<< zzmode (LEX_HISTORY); zzmore (); >>



#lexclass START


def_file	: ( header )*
		  def_design
		;

header		: version
		| namescasesensitive
		| dividerchar
		| busbitchars
		;

version		: DEF_VERSION^ << ID_MODE; >> DEF_IDENT DEF_SEMI!
		;

namescasesensitive
		: DEF_NAMESCASESENSITIVE^ ( DEF_ON | DEF_OFF ) DEF_SEMI!
		;

dividerchar	: DEF_DIVIDERCHAR^ DEF_QUOTED DEF_SEMI!
		;

busbitchars	: DEF_BUSBITCHARS^ DEF_QUOTED DEF_SEMI!
		;

def_design	: DEF_DESIGN^ << ID_MODE; >> DEF_IDENT DEF_SEMI!
		    ( declaration )*
		    ( constituent )*
		  DEF_END! DEF_DESIGN!
		;

declaration	: units_decl
		| diearea_decl
		| tracks_decl
		| history_decl 
		| row_decl
		| propertydefinitions_decl
		| gcellgrid_decl
		;

units_decl	: DEF_UNITS^ DEF_DISTANCE DEF_MICRONS DEF_NUMBER DEF_SEMI!
		;

diearea_decl	: DEF_DIEAREA^ coordinate coordinate DEF_SEMI! 
		;

tracks_decl	: DEF_TRACKS^ ( DEF_X | DEF_Y ) number
		  DEF_DO number DEF_STEP number
		  DEF_LAYER << ID_MODE; >> ( DEF_IDENT << ID_MODE; >> )+ 
		  DEF_SEMI!
		;

history_decl	: DEF_HISTORY^ << zzmode (LEX_HISTORY); >> history_list
		;

history_list	: hist:DEF_HISTORY_LIST
		    << { char *str = get_history_string (#hist->text);
			 #0 = #[DEF_IDENT, str];
			 free (str);
		       }
		    >>
		;

row_decl	: DEF_ROW^ << ID_MODE; >> DEF_IDENT << ID_MODE; >> DEF_IDENT
		  number number orientation DEF_DO number DEF_BY number
		  DEF_STEP number number DEF_SEMI!
		;

gcellgrid_decl	: DEF_GCELLGRID^ ( DEF_X | DEF_Y ) number
		  DEF_DO number DEF_STEP number DEF_SEMI!
		;

propertydefinitions_decl
		: DEF_PROPERTYDEFINITIONS^
		    ( propertydefinition )*
		  DEF_END! DEF_PROPERTYDEFINITIONS!
		;

propertydefinition
		: DEF_DESIGN DEF_VERILOGDESIGNNAME^
		  DEF_STRING DEF_QUOTED DEF_SEMI!
		;

constituent	: vias
		| components
		| specialnets
		| nets
		| pins
		;

vias		: DEF_VIAS^ number DEF_SEMI!
		    ( via )*
		  DEF_END! DEF_VIAS!
		;

via		: "\-"! << ID_MODE; >> DEF_IDENT^ ( via_plus )* DEF_SEMI!
		;

via_plus	: "\+"! ( rect_clause )
		;

components	: DEF_COMPONENTS^ number DEF_SEMI!
		    ( component )*
		  DEF_END! DEF_COMPONENTS!
		;

component	: "\-"! << ID_MODE; >> DEF_IDENT^ << ID_MODE; >> DEF_IDENT
		    ( component_plus )* DEF_SEMI!
		;

pins		: DEF_PINS^ number DEF_SEMI!
		    ( pin )*
		  DEF_END! DEF_PINS!
		;

pin		: "\-"! << ID_MODE; >> DEF_IDENT^ ( pin_plus )* DEF_SEMI!
		;

nets		: DEF_NETS^ number DEF_SEMI!
		    ( net )*
		  DEF_END! DEF_NETS!
		;

specialnets	: DEF_SPECIALNETS^ number DEF_SEMI!
		    ( net )*
		  DEF_END! DEF_SPECIALNETS!
		;

net		: "\-"! << ID_MODE; >> DEF_IDENT^
		    ( net_connection )* ( net_plus )* DEF_SEMI!
		;

net_connection	: "\("! << ID_MODE; >> cell:DEF_IDENT^ << ID_MODE; >> DEF_IDENT "\)"!
		    << /* This has to be a special case. */
		      if ( strcmp (#cell->text, "PIN") == 0 ) {
			#cell->token = DEF_PIN;
		      }
		    >>
		;

component_plus	: "\+"! ( placed_clause
			| unplaced_clause )
		;

pin_plus	: "\+"! ( placed_clause
			| net_clause
			| dir_clause
			| use_clause
			| layer_clause )
		;

net_plus	: "\+"! use_clause
		;

placed_clause	: DEF_PLACED^ "\("! number number "\)"! orientation
		;

fixed_clause	: DEF_FIXED^ "\("! number number "\)"! orientation
		;

unplaced_clause	: DEF_UNPLACED^
		;

net_clause	: DEF_NET^ << ID_MODE; >> DEF_IDENT
		;

dir_clause	: DEF_DIRECTION^ ( DEF_INPUT | DEF_OUTPUT | DEF_INOUT )
		;

use_clause	: DEF_USE^ ( DEF_SIGNAL | DEF_POWER | DEF_GROUND )
		;

layer_clause	: DEF_LAYER^ << ID_MODE; >> DEF_IDENT coordinate coordinate
		;

rect_clause	: DEF_RECT^ << ID_MODE; >> DEF_IDENT coordinate coordinate 
		;

coordinate	: "\("! DEF_NUMBER^ DEF_NUMBER "\)"!
		;

orientation	: DEF_N | DEF_S | DEF_FN | DEF_FS
		;

number		: DEF_NUMBER
		;
