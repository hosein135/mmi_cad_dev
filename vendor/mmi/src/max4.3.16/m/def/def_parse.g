#header <<
#include <assert.h>
#include <stdio.h>
#include <stdarg.h>
#include "def2max.h"

// TODO: Redefine zzsyn from $MMI_UTILS/pccts/h/err.h to provide better error messages.
//#define USER_ZZSYN

// I dont think this is needed:
//#define ZZCOL

#define ZZLEXBUFSIZE 2050	/* DEF doc says 2048 max */
#define ZZA_STACKSIZE 400	/* way overkill */

#define zzfailed_pred(_p)     def2max_failed_pred(_p);

// This is a clever way to get the error routines for the parser to go to the
// max error printer, without rewriting all the routines.
// This must be here in the header so the .h file included by the lexer gets this too.
#define fprintf def_parse_fprintf

extern int def2max_pre_comment_mode;

#define NEXT_LINE if (++zzline%10000==0) {printf("\r%d ",zzline);fflush(stdout);}

>>

#parser "def"

<<
#include "database.h"
#define ID_MODE	 zzmode (IDENTIFIER)

int def_parse_fprintf(FILE*somewhere,char *fmt, ...)
{
    va_list args;
    va_start(args,fmt);
    if (somewhere==stderr) {
	MsgErrorV(fmt,args);
    } else {
	vfprintf(somewhere,fmt,args);
    }
    va_end(args);
    return 0;
}

//static char *stralloc(char *s) {return strcpy((char*)malloc(strlen(s)+1),s);}

int def2max_pre_comment_mode;
>>


#token			"[\ \t]+"	<< zzskip (); >>
#token			"\n"		<< NEXT_LINE; zzskip (); >>

#token DEF_ANALOG               "[Aa][Nn][Aa][Ll][Oo][Gg]"
#token DEF_BALANCED             "[Bb][Aa][Ll][Aa][Nn][Cc][Ee][Dd]"
#token DEF_BUSBITCHARS          "[Bb][Uu][Ss][Bb][Ii][Tt][Cc][Hh][Aa][Rr][Ss]"
#token DEF_BY                   "[Bb][Yy]"
#token DEF_CLOCK                "[Cc][Ll][Oo][Cc][Kk]"
#token DEF_COMPONENT            "[Cc][Oo][Mm][Pp][Oo][Nn][Ee][Nn][Tt]"
#token DEF_COMPONENTS           "[Cc][Oo][Mm][Pp][Oo][Nn][Ee][Nn][Tt][Ss]"
#token DEF_COVER                "[Cc][Oo][Vv][Ee][Rr]"
#token DEF_DEFAULT              "[Dd][Ee][Ff][Aa][Uu][Ll][Tt]"
#token DEF_DESIGN               "[Dd][Ee][Ss][Ii][Gg][Nn]"
#token DEF_DIEAREA              "[Dd][Ii][Ee][Aa][Rr][Ee][Aa]"
#token DEF_DIRECTION            "[Dd][Ii][Rr][Ee][Cc][Tt][Ii][Oo][Nn]"
#token DEF_DIST                 "[Dd][Ii][Ss][Tt]"
#token DEF_DISTANCE             "[Dd][Ii][Ss][Tt][Aa][Nn][Cc][Ee]"
#token DEF_DIVIDERCHAR          "[Dd][Ii][Vv][Ii][Dd][Ee][Rr][Cc][Hh][Aa][Rr]"
#token DEF_DO                   "[Dd][Oo]"
#token DEF_END                  "[Ee][Nn][Dd]"
#token DEF_FIXED                "[Ff][Ii][Xx][Ee][Dd]"
#token DEF_GCELLGRID            "[Gg][Cc][Ee][Ll][Ll][Gg][Rr][Ii][Dd]"
#token DEF_GROUND               "[Gg][Rr][Oo][Uu][Nn][Dd]"
#token DEF_HISTORY              "[Hh][Ii][Ss][Tt][Oo][Rr][Yy]"
#token DEF_HORIZONTAL           "[Hh][Oo][Rr][Ii][Zz][Oo][Nn][Tt][Aa][Ll]"
#token DEF_IN                   "[Ii][Nn]"
#token DEF_INOUT                "[Ii][Nn][Oo][Uu][Tt]"
#token DEF_INPUT                "[Ii][Nn][Pp][Uu][Tt]"
#token DEF_LAYER                "[Ll][Aa][Yy][Ee][Rr]"
#token DEF_MICRONS              "[Mm][Ii][Cc][Rr][Oo][Nn][Ss]"
#token DEF_NAMESCASESENSITIVE   "[Nn][Aa][Mm][Ee][Ss][Cc][Aa][Ss][Ee][Ss][Ee][Nn][Ss][Ii][Tt][Ii][Vv][Ee]"
#token DEF_NET                  "[Nn][Ee][Tt]"
#token DEF_NETS                 "[Nn][Ee][Tt][Ss]"
#token DEF_NEW                  "[Nn][Ee][Ww]"
#token DEF_OFF                  "[Oo][Ff][Ff]"
#token DEF_ON                   "[Oo][Nn]"
#token DEF_OUT                  "[Oo][Uu][Tt]"
#token DEF_OUTPUT               "[Oo][Uu][Tt][Pp][Uu][Tt]"
#token DEF_PATTERN              "[Pp][Aa][Tt][Tt][Ee][Rr][Nn]"
#token DEF_PIN                  "[Pp][Ii][Nn]"
#token DEF_PINS                 "[Pp][Ii][Nn][Ss]"
#token DEF_PLACED               "[Pp][Ll][Aa][Cc][Ee][Dd]"
#token DEF_POWER                "[Pp][Oo][Ww][Ee][Rr]"
#token DEF_PROPERTYDEFINITIONS  "[Pp][Rr][Oo][Pp][Ee][Rr][Tt][Yy][Dd][Ee][Ff][Ii][Nn][Ii][Tt][Ii][Oo][Nn][Ss]"
#token DEF_RECT                 "[Rr][Ee][Cc][Tt]"
#token DEF_REGIONS              "[Rr][Ee][Gg][Ii][Oo][Nn][Ss]"
#token DEF_ROUTED               "[Rr][Oo][Uu][Tt][Ee][Dd]"
#token DEF_ROW                  "[Rr][Oo][Ww]"
#token DEF_ROWS                 "[Rr][Oo][Ww][Ss]"
#token DEF_SIGNAL               "[Ss][Ii][Gg][Nn][Aa][Ll]"
#token DEF_SITE                 "[Ss][Ii][Tt][Ee]"
#token DEF_SOURCE               "[Ss][Oo][Uu][Rr][Cc][Ee]"
#token DEF_SPECIAL              "[Ss][Pp][Ee][Cc][Ii][Aa][Ll]"
#token DEF_SPECIALNET           "[Ss][Pp][Ee][Cc][Ii][Aa][Ll][Nn][Ee][Tt]"
#token DEF_SPECIALNETS          "[Ss][Pp][Ee][Cc][Ii][Aa][Ll][Nn][Ee][Tt][Ss]"
#token DEF_START                "[Ss][Tt][Aa][Rr][Tt]"
#token DEF_STEINER              "[Ss][Tt][Ee][Ii][Nn][Ee][Rr]"
#token DEF_STEP                 "[Ss][Tt][Ee][Pp]"
#token DEF_STOP                 "[Ss][Tt][Oo][Pp]"
#token DEF_STRING               "[Ss][Tt][Rr][Ii][Nn][Gg]"
#token DEF_TECHNOLOGY           "[Tt][Ee][Cc][Hh][Nn][Oo][Ll][Oo][Gg][Yy]"
#token DEF_TIEOFF               "[Tt][Ii][Ee][Oo][Ff][Ff]"
#token DEF_TRACKS               "[Tt][Rr][Aa][Cc][Kk][Ss]"
#token DEF_TRUNK                "[Tt][Rr][Uu][Nn][Kk]"
#token DEF_UNITS                "[Uu][Nn][Ii][Tt][Ss]"
#token DEF_UNPLACED             "[Uu][Nn][Pp][Ll][Aa][Cc][Ee][Dd]"
#token DEF_USE                  "[Uu][Ss][Ee]"
#token DEF_VERILOGDESIGNNAME    "[Vv][Ee][Rr][Ii][Ll][Oo][Gg][Dd][Ee][Ss][Ii][Gg][Nn][Nn][Aa][Mm][Ee]"
#token DEF_VERSION              "[Vv][Ee][Rr][Ss][Ii][Oo][Nn]"
#token DEF_VERTICAL             "[Vv][Ee][Rr][Tt][Ii][Cc][Aa][Ll]"
#token DEF_VIAS                 "[Vv][Ii][Aa][Ss]"
#token DEF_WIREDLOGIC           "[Ww][Ii][Rr][Ee][Dd][Ll][Oo][Gg][Ii][Cc]"
#token DEF_X                    "[Xx]"
#token DEF_Y                    "[Yy]"
#token DEF_N                    "[Nn]"
#token DEF_S                    "[Ss]"
#token DEF_E                    "[Ee]"
#token DEF_W                    "[Ww]"
#token DEF_FN                   "[Ff][Nn]"
#token DEF_FS                   "[Ff][Ss]"
#token DEF_FE                   "[Ff][Ee]"
#token DEF_FW                   "[Ff][Ww]"

#token DEF_PLUS		"\+"
#token DEF_SEMI		";"
#token DEF_NUMBER	"(\-|[])[0-9]+"
#token			"\""		<< zzmode (STRING); zzmore (); >>
#token			"[A-Za-z0-9_]+"
#token                  "#"             << zzskip ();
                                           def2max_pre_comment_mode = START;
                                           zzmode (COMMENT);
                                        >>



#lexclass IDENTIFIER

#token			"[\ \t]+"	<< zzskip (); >>
#token			"\n"		<< NEXT_LINE; zzskip (); >>
#token DEF_SEMI		";"		<< zzmode (START); >>
#token DEF_IDENT	"~[\ \t\n]+"	<< zzmode (START); >>
#token                  "#"             << zzskip ();
                                           def2max_pre_comment_mode = IDENTIFIER;
                                           zzmode (COMMENT);
                                        >>


#lexclass IDENT_NEW_OR_PLUS

#token			"[\ \t]+"	<< zzskip (); >>
#token			"\n"		<< NEXT_LINE; zzskip (); >>
#token DEF_SEMI		";"		<< zzmode (START); >>
#token DEF_PLUS         "\+"		<< zzmode (START); >>
#token DEF_NEW		"NEW"		<< zzmode (START); >>
#token DEF_ID_OPEN	"\("		<< zzmode (START); >>
#token DEF_IDENT	"~[\ \t\n]+"	<< zzmode (START); >>
#token                  "#"             << zzskip ();
                                           def2max_pre_comment_mode = IDENT_NEW_OR_PLUS;
                                           zzmode (COMMENT);
                                        >>


#lexclass STRING

#token			"~[\\\"]+"	<< zzmore (); >>
#token			"\\~[]"		<< zzmore (); >>
#token DEF_QUOTED	"\""		<< zzmode (START); >>


#lexclass LEX_HISTORY

#token			"[\ \t]+"	<< zzmore (); >>
#token			"\n"		<< NEXT_LINE; zzmore (); >>
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

#lexclass COMMENT

#token                  "~[\n]+"        << zzskip (); >>
#token                  "\n"            << NEXT_LINE;
                                           zzskip ();
                                           zzmode (def2max_pre_comment_mode);
                                        >>




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
		: DEF_NAMESCASESENSITIVE^
		( DEF_ON  << def2max_case_sensitive(1); >>
		| DEF_OFF << def2max_case_sensitive(0); >>
		) DEF_SEMI!
		;

dividerchar	: DEF_DIVIDERCHAR^ str:DEF_QUOTED
			<< def2max_divider_char ($str.text); >>
		  DEF_SEMI!
		;

busbitchars	: DEF_BUSBITCHARS^ str:DEF_QUOTED
			<< def2max_busbit_char($str.text); >>
		  DEF_SEMI!
		;

def_design	: DEF_DESIGN^ << ID_MODE; >> name:DEF_IDENT
			<< def2max_design ($name.text); >>
		  DEF_SEMI!
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

units_decl	: << char name[2050];
		     int num;
		  >>
		  DEF_UNITS^ DEF_DISTANCE << ID_MODE; >>
		  id:DEF_IDENT 		<< strcpy(name,$id.text); >>
		  number > [num]
		  DEF_SEMI!
			<< def2max_distance_units (name, num); >>
		;

diearea_decl	: << int x0, y0;
		     int x1, y1;
		  >>
		  DEF_DIEAREA^ coordinate > [x0, y0] coordinate > [x1, y1]
		  DEF_SEMI! 
			<< def2max_die_area (x0, y0, x1, y1); >>
		;

tracks_decl	: DEF_TRACKS^
		  ( DEF_X | DEF_Y )
		  number_discarded
		  DEF_DO number_discarded
		  DEF_STEP number_discarded
		  DEF_LAYER	<< ID_MODE; >>
		  ( id:DEF_IDENT << ID_MODE; >> )+ 
		  DEF_SEMI!
		;

history_decl	: DEF_HISTORY^ << zzmode (LEX_HISTORY); >> hist:DEF_HISTORY_LIST
			<< def2max_history ($hist.text); >>
		;

row_decl	: 
		  DEF_ROW^		<< ID_MODE; >>
		  name_id:DEF_IDENT	<< ID_MODE; >>
		  core_id:DEF_IDENT
		  number_discarded number_discarded orientation
		  DEF_DO number_discarded DEF_BY number_discarded
		  DEF_STEP number_discarded number_discarded
		  DEF_SEMI!
		;

gcellgrid_decl	: DEF_GCELLGRID^ ( DEF_X | DEF_Y ) number_discarded
		  DEF_DO number_discarded DEF_STEP number_discarded DEF_SEMI!
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

vias		: DEF_VIAS^ number_discarded DEF_SEMI!
		    ( via )*
		  DEF_END! DEF_VIAS!
		;

via		: "\-"! << ID_MODE; >> DEF_IDENT^ ( via_plus )* DEF_SEMI!
		;

via_plus	: DEF_PLUS! ( rect_clause )
		;

components	: DEF_COMPONENTS^ number_discarded DEF_SEMI!
		    ( component )*
		  DEF_END! DEF_COMPONENTS!
		;

component	: << char inst_name[ZZLEXBUFSIZE];
		     char mod_name[ZZLEXBUFSIZE];
		  >>
		  "\-"! << ID_MODE; >> i:DEF_IDENT^
			<< strcpy(inst_name, $i.text);
			   ID_MODE;
			>>
			m:DEF_IDENT
			<< strcpy(mod_name,$m.text); >>
		    ( component_plus [inst_name, mod_name] )* DEF_SEMI!
		;

pins		: DEF_PINS^ number_discarded DEF_SEMI!
		    ( pin )*
		  DEF_END! DEF_PINS!
		;

pin		: << defparse_place portbuf; >>
		  "\-"! << ID_MODE; >> n:DEF_IDENT^ 
			<< strcpy(portbuf.name,$n.text);
			    portbuf.x = portbuf.y = 0;
			    portbuf.iotype = LAB_COMMENT;	// TODO: default should be what?
			    portbuf.layer[0] = 0;
			>>
		    ( pin_plus [&portbuf] )* DEF_SEMI! << def2max_port(&portbuf); >>
		;

nets		: DEF_NETS^ number_discarded DEF_SEMI!
		    ( net [0] )*
		  DEF_END! DEF_NETS!
		;

specialnets	: DEF_SPECIALNETS^ number_discarded DEF_SEMI!
		    ( net [1] )*
		  DEF_END! DEF_SPECIALNETS!
		;

net [int special]
		: << pnl_net pnet; >>
		  "\-" << ID_MODE; >> id:DEF_IDENT
			<< pnet = def2max_net ($id.text, special); >>
		    ( net_connection )* ( net_plus [pnet, special] )* DEF_SEMI!
		;

net_connection	: "\("! << ID_MODE; >> cell:DEF_IDENT^
		  << ID_MODE; >> DEF_IDENT "\)"!
//		    << /* This has to be a special case. */
//		      if ( strcmp (#cell->text, "PIN") == 0 ) {
//			#cell->token = DEF_PIN;
//		      }
//		    >>
		;

component_plus [char *inst_name, char *mod_name]
		: << defparse_place placebuf; >>
		  DEF_PLUS! placed_clause[&placebuf]
				<< def2max_component (inst_name, mod_name,
				       placebuf.loctype, placebuf.x, placebuf.y, placebuf.orient);
				>>
		;

pin_plus [defparse_place *pport]
		: << int unused; >>
		DEF_PLUS!
		    ( placed_clause [pport]
		    | net_clause
		    | dir_clause [pport]
		    | use_clause > [unused]
		    | layer_clause [pport]
		    )
		;

net_plus [pnl_net pnet, int special]
		: << pnl_use use;
		     pnl_pattern pattern;
		     pnl_route route;
		  >>
		  DEF_PLUS! 
		    ( use_clause > [use]
				<< /*pnl_net_set_use (pnet, use);*/ >>
		    | pattern_clause > [pattern]
				<< /*pnl_net_set_pattern (pnet, pattern);*/ >>
		    | route_clause [special] > [route]
				<< /*pnl_net_add_route (pnet, route);*/ >>
		    )
		;

placed_clause [defparse_place *pport]
		: << int x,y,orient; >>
		( DEF_PLACED^		<< pport->loctype = pnl_loctype_PLACED; >> 
		  | DEF_FIXED^		<< pport->loctype = pnl_loctype_FIXED; >> 
		  | DEF_COVER^		<< pport->loctype = pnl_loctype_COVER; >> 
		  )
		coordinate > [x, y] orientation > [orient]
			<< pport->x = x;
			   pport->y = y;
			   pport->orient = orient;
			>>
		| DEF_UNPLACED^		<< pport->loctype = pnl_loctype_UNPLACED;
					   pport->x = 0;
					   pport->y = 0;
					   pport->orient = pnl_orientation_none;
					>>
		;

net_clause	: DEF_NET^ << ID_MODE; >> DEF_IDENT
		;

dir_clause [defparse_place *pport]
		: DEF_DIRECTION^ ( 
		DEF_INPUT << pport->iotype = LAB_INPUT; >>
		| DEF_OUTPUT << pport->iotype = LAB_OUTPUT; >>
		| DEF_INOUT << pport->iotype = LAB_INOUT; >>
		)
		;

use_clause > [pnl_use result]
		: DEF_USE^
		  ( DEF_SIGNAL		<< $result = pnl_use_SIGNAL; >>
		  | DEF_POWER		<< $result = pnl_use_POWER; >>
		  | DEF_GROUND		<< $result = pnl_use_GROUND; >>
		  | DEF_CLOCK		<< $result = pnl_use_CLOCK; >>
		  | DEF_TIEOFF		<< $result = pnl_use_TIEOFF; >>
		  | DEF_ANALOG		<< $result = pnl_use_ANALOG; >>
		  )
		;

pattern_clause > [pnl_pattern result]
		: DEF_PATTERN
		  ( DEF_STEINER		<< $result = pnl_pattern_STEINER; >>
		  | DEF_BALANCED	<< $result = pnl_pattern_BALANCED; >>
		  | DEF_WIREDLOGIC	<< $result = pnl_pattern_WIREDLOGIC; >>
		  | DEF_TRUNK		<< $result = pnl_pattern_TRUNK; >>
		  )
		;

route_clause [int special] > [pnl_route route]
		: << pnl_routekind routekind;
		     pnl_branch branch;
		  >>
		  ( DEF_ROUTED	<< routekind = pnl_routekind_ROUTED; ID_MODE;>>
		  | DEF_FIXED	<< routekind = pnl_routekind_FIXED; ID_MODE; >>
		  | DEF_COVER	<< routekind = pnl_routekind_COVER; ID_MODE; >>
		  )
			<< $route = 0; /*pnl_route_create (routekind);*/ >>
		  route_branch [special] > [branch]
			<< /*pnl_route_add_branch ($route, branch);*/ >>
 		  ( DEF_NEW
			<< ID_MODE; >>
		    route_branch [special] > [branch]
			<< /*pnl_route_add_branch ($route, branch);*/ >>
		  )*
		;

route_branch [int special] > [pnl_branch branch]
		: << int x0;
		     int y0;
		     int width = -1;
		     pnl_segment segment;
		     char layer[ZZLEXBUFSIZE];
		  >>
		  id:DEF_IDENT << strcpy(layer,$id.text); >>
		  ( << special >>? number > [width] 
		  | << !special>>? /* empty */
		  )
		  "\(" number > [x0] number > [y0] "\)"
				<< $branch = 0; /*pnl_branch_create (layer, x0, y0, width);*/
			           zzmode (IDENT_NEW_OR_PLUS);
				>>
		  ( route_segment > [segment]
				<< /*pnl_branch_add_segment ($branch, segment);*/
				>>
		  )+
		;

route_segment > [pnl_segment segment]
		: << int x, y; >> 
		  ( DEF_ID_OPEN	( number > [x] "\*"
					<< $segment = 0;/*pnl_segment_create_x_segment (x);*/ >>
				| "\*" number > [y]
					<< $segment = 0;/*pnl_segment_create_y_segment (y);*/ >>
				) "\)"
					<< zzmode (IDENT_NEW_OR_PLUS); >>
		  | via_name:DEF_IDENT
			<< $segment = 0;/*pnl_segment_create_via ($via_name.text);*/
			   zzmode (IDENT_NEW_OR_PLUS);
			>>
		  )
		;

layer_clause [defparse_place *pport]
		: << int x0, y0;
		     int x1, y1;
		  >>
		  DEF_LAYER^	<< ID_MODE; >>
		  id:DEF_IDENT	<< strcpy(pport->layer,$id.text); >>
		  coordinate > [x0, y0] coordinate > [x1, y1]
				<< /*pnl_port_set_geometry (pport, name, x0, y0, x1, y1);*/
				>>
		;

rect_clause	: DEF_RECT^ << ID_MODE; >> DEF_IDENT coordinate coordinate 
		;

coordinate > [int x, int y]
		: "\("! number > [$x] number > [$y]"\)"!
		;

orientation > [pnl_orientation orient]
		: DEF_N		<< $orient = pnl_orientation_N; >>
		| DEF_S		<< $orient = pnl_orientation_S; >>
		| DEF_E		<< $orient = pnl_orientation_E; >>
		| DEF_W		<< $orient = pnl_orientation_W; >>
		| DEF_FN	<< $orient = pnl_orientation_FN; >>
		| DEF_FS	<< $orient = pnl_orientation_FS; >>
		| DEF_FE	<< $orient = pnl_orientation_FE; >>
		| DEF_FW	<< $orient = pnl_orientation_FW; >>
		;

number > [int result]
		: n:DEF_NUMBER	<< $result = atoi ($n.text); >>
		;

number_discarded
		: DEF_NUMBER
		;
