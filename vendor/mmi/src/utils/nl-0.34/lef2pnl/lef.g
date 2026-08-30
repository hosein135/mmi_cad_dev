#header <<
#include "port.h"
#include "charptr.h"
#include "error.h"
#include "mem.h"
#include "ar.h"
#include "hashtab.h"
#include "skip-list.h"
#include "nl.h"
#include "pnl.h"
#include "lef2pnl.h"
#include "lef2pnl_int.h"

#if 0
#  define AST_FIELDS   int token; char *text;
#  define zzcr_ast(tr, attr, tok, txt) { cr_ast (tr, attr, tok, txt); }
#  define zzmk_ast(tr, tok, txt)	     (AST *) mk_ast (tr, tok, txt)
#  define zzcr_attr(attr, tok, txt)
#endif

#define zzcr_attr(attr, tok, text)	(*(attr) = (text))
#undef  zzd_attr

extern int lef2pnl_pre_comment_mode;

#define USER_ZZSYN
>>

#parser "lef"
	
<<
#define ID_MODE	 zzmode (IDENTIFIER)


void
lef_zzsyn (char *text, int tok, char *egroup, SetWordType *eset,
	   int etok, int k, char *bad_text)
{
  error ("Syntax error, line %d at \"%s\"", zzline, bad_text);
}


int lef2pnl_pre_comment_mode;


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

/*
(defun lef-token (tok)
  (interactive "stoken: ")
  (beginning-of-line)
  (open-line 1)
  (insert (format "#token LEF_%s" (upcase tok)))
  (move-to-column-force 32)
  (insert (concat "\"" (mapconcat '(lambda (c)
                                     (format "[%c%c]" (upcase c) (downcase c)))
				  tok "")
		  "\"")))
*/
>>

#token			"[\ \t]+"	<< zzskip (); >>
#token			"\n"		<< zzline++; zzskip (); >>

#token			"#"		<< zzskip ();
					   lef2pnl_pre_comment_mode = START;
					   zzmode (LEF_COMMENT);
					>>

#token LEF_ABUTMENT		"[Aa][Bb][Uu][Tt][Mm][Ee][Nn][Tt]"
#token LEF_ANTENNASIZE          "[Aa][Nn][Tt][Ee][Nn][Nn][Aa][Ss][Ii][Zz][Ee]"
#token LEF_ANTENNADIFFAREA      "[Aa][Nn][Tt][Ee][Nn][Nn][Aa][Dd][Ii][Ff][Ff][Aa][Rr][Ee][Aa]"
#token LEF_ANTENNAGATEAREA      "[Aa][Nn][Tt][Ee][Nn][Nn][Aa][Gg][Aa][Tt][Ee][Aa][Rr][Ee][Aa]"
#token LEF_BLOCK		"[Bb][Ll][Oo][Cc][Kk]"
#token LEF_BY                   "[Bb][Yy]"
#token LEF_CAPACITANCE          "[Cc][Aa][Pp][Aa][Cc][Ii][Tt][Aa][Nn][Cc][Ee]"
#token LEF_CLASS                "[Cc][Ll][Aa][Ss][Ss]"
#token LEF_CLOCK                "[Cc][Ll][Oo][Cc][Kk]"
#token LEF_CO                   "[Cc][Oo]"
#token LEF_CORE                 "[Cc][Oo][Rr][Ee]"
#token LEF_COVER                "[Cc][Oo][Vv][Ee][Rr]"
#token LEF_CPERSQDIST           "[Cc][Pp][Ee][Rr][Ss][Qq][Dd][Ii][Ss][Tt]"
#token LEF_CUT                  "[Cc][Uu][Tt]"
#token LEF_DATABASE             "[Dd][Aa][Tt][Aa][Bb][Aa][Ss][Ee]"
#token LEF_DEFAULT              "[Dd][Ee][Ff][Aa][Uu][Ll][Tt]"
#token LEF_DIRECTION            "[Dd][Ii][Rr][Ee][Cc][Tt][Ii][Oo][Nn]"
#token LEF_END                  "[Ee][Nn][Dd]"
#token LEF_ENDCAP		"[Ee][Nn][Dd][Cc][Aa][Pp]"
#token LEF_FEEDTHRU		"[Ff][Ee][Ee][Dd][Tt][Hh][Rr][Uu]"
#token LEF_FOREIGN              "[Ff][Oo][Rr][Ee][Ii][Gg][Nn]"
#token LEF_GENERATE             "[Gg][Ee][Nn][Ee][Rr][Aa][Tt][Ee]"
#token LEF_GND                  "[Gg][Nn][Dd]"
#token LEF_GROUND               "[Gg][Rr][Oo][Uu][Nn][Dd]"
#token LEF_HORIZONTAL           "[Hh][Oo][Rr][Ii][Zz][Oo][Nn][Tt][Aa][Ll]"
#token LEF_INOUT                "[Ii][Nn][Oo][Uu][Tt]"
#token LEF_INPUT                "[Ii][Nn][Pp][Uu][Tt]"
#token LEF_LAYER                "[Ll][Aa][Yy][Ee][Rr]"
#token LEF_LIBRARY              "[Ll][Ii][Bb][Rr][Aa][Rr][Yy]"
#token LEF_MACRO                "[Mm][Aa][Cc][Rr][Oo]"
#token LEF_MASTERSLICE          "[Mm][Aa][Ss][Tt][Ee][Rr][Ss][Ll][Ii][Cc][Ee]"
#token LEF_METALOVERHANG        "[Mm][Ee][Tt][Aa][Ll][Oo][Vv][Ee][Rr][Hh][Aa][Nn][Gg]"
#token LEF_MICRONS              "[Mm][Ii][Cc][Rr][Oo][Nn][Ss]"
#token LEF_MINFEATURE           "[Mm][Ii][Nn][Ff][Ee][Aa][Tt][Uu][Rr][Ee]"
#token LEF_NAMESCASESENSITIVE   "[Nn][Aa][Mm][Ee][Ss][Cc][Aa][Ss][Ee][Ss][Ee][Nn][Ss][Ii][Tt][Ii][Vv][Ee]"
#token LEF_OBS                  "[Oo][Bb][Ss]"
#token LEF_ON                   "[Oo][Nn]"
#token LEF_ORIGIN		"[Oo][Rr][Ii][Gg][Ii][Nn]"
#token LEF_OUTPUT               "[Oo][Uu][Tt][Pp][Uu][Tt]"
#token LEF_OVERHANG             "[Oo][Vv][Ee][Rr][Hh][Aa][Nn][Gg]"
#token LEF_PAD			"[Pp][Aa][Dd]"
#token LEF_PIN                  "[Pp][Ii][Nn]"
#token LEF_PITCH                "[Pp][Ii][Tt][Cc][Hh]"
#token LEF_POLY                 "[Pp][Oo][Ll][Yy]"
#token LEF_POLYGON              "[Pp][Oo][Ll][Yy][Gg][Oo][Nn]"
#token LEF_PORT                 "[Pp][Oo][Rr][Tt]"
#token LEF_POWER                "[Pp][Oo][Ww][Ee][Rr]"
#token LEF_R90			"[Rr]90"
#token LEF_RECT                 "[Rr][Ee][Cc][Tt]"
#token LEF_RESISTANCE           "[Rr][Ee][Ss][Ii][Ss][Tt][Aa][Nn][Cc][Ee]"
#token LEF_RING			"[Rr][Ii][Nn][Gg]"
#token LEF_ROUTING              "[Rr][Oo][Uu][Tt][Ii][Nn][Gg]"
#token LEF_RPERSQ               "[Rr][Pp][Ee][Rr][Ss][Qq]"
#token LEF_SAMENET              "[Ss][Aa][Mm][Ee][Nn][Ee][Tt]"
#token LEF_SHAPE		"[Ss][Hh][Aa][Pp][Ee]"
#token LEF_SIGNAL               "[Ss][Ii][Gg][Nn][Aa][Ll]"
#token LEF_SITE                 "[Ss][Ii][Tt][Ee]"
#token LEF_SIZE                 "[Ss][Ii][Zz][Ee]"
#token LEF_SPACING              "[Ss][Pp][Aa][Cc][Ii][Nn][Gg]"
#token LEF_STACK                "[Ss][Tt][Aa][Cc][Kk]"
#token LEF_SYMMETRY             "[Ss][Yy][Mm][Mm][Ee][Tt][Rr][Yy]"
#token LEF_TO                   "[Tt][Oo]"
#token LEF_TURN                 "[Tt][Uu][Rr][Nn]"
#token LEF_TYPE                 "[Tt][Yy][Pp][Ee]"
#token LEF_UNITS                "[Uu][Nn][Ii][Tt][Ss]"
#token LEF_USE                  "[Uu][Ss][Ee]"
#token LEF_VDD                  "[Vv][Dd][Dd]"
#token LEF_VERSION              "[Vv][Ee][Rr][Ss][Ii][Oo][Nn]"
#token LEF_VERTICAL             "[Vv][Ee][Rr][Tt][Ii][Cc][Aa][Ll]"
#token LEF_VIA                  "[Vv][Ii][Aa]"
#token LEF_VIARULE              "[Vv][Ii][Aa][Rr][Uu][Ll][Ee]"
#token LEF_WIDTH                "[Ww][Ii][Dd][Tt][Hh]"
#token LEF_X                    "[Xx]"
#token LEF_Y                    "[Yy]"

#token LEF_SEMI		";"
#token LEF_NUMBER	"(\-|[])[0-9]+{\.[0-9]+}"
#token			"\""		<< zzmode (STRING);
					   zzmore ();
					>>

#token LEF_BAD_KEYWORD	"[A-Za-z_][A-Za-z0-9_]*"


#lexclass IDENTIFIER

#token			"[\ \t]+"	<< zzskip (); >>
#token			"\n"		<< zzline++; zzskip (); >>
#token LEF_SEMI		";"		<< zzmode (START); >>
#token LEF_IDENT	"~[#\ \t\n]+"	<< zzmode (START); >>
#token			"#"		<< zzskip ();
					   lef2pnl_pre_comment_mode = IDENTIFIER;
					   zzmode (LEF_COMMENT);
					>>

#lexclass STRING

#token			"~[\\\"]+"	<< zzmore (); >>
#token			"\\~[]"		<< zzmore (); >>
#token LEF_QUOTED	"\""		<< zzmode (START); >>


#lexclass LEX_HISTORY

#token			"[\ \t]+"	<< zzmore (); >>
#token			"\n"		<< zzline++;
					   zzmore ();
					>>
#token			"~[\\\";]+"	<< zzmore (); >>
#token			"\\~[]"		<< zzmore (); >>
#token			"\""            << zzmode (LEX_HISTORY_STRING); 
					   zzmore ();
					>>
#token LEF_HISTORY_LIST	";"		<< zzmode (START); >>


#lexclass LEX_HISTORY_STRING

#token			"~[\\\"]+"	<< zzmore (); >>
#token			"\\~[]"		<< zzmore (); >>
#token 			"\""		<< zzmode (LEX_HISTORY);
					   zzmore ();
					>>

#lexclass LEF_COMMENT

#token			"~[\n]+"	<< zzskip (); >>
#token			"\n"		<< zzline++;
					   zzskip ();
					   zzmode (lef2pnl_pre_comment_mode);
					>>


#lexclass START


file [pnl_library plibrary]
		: ( statement [plibrary] )*
		  { LEF_END LEF_LIBRARY }
		;

statement [pnl_library plibrary]
		: macro [plibrary]
//		| version
//		| namescasesensitive
//		| units
//		| layer
//		| via
//		| viarule
//		| spacing
//		| minfeature
//		| site
		;

version		: LEF_VERSION << ID_MODE; >> LEF_IDENT LEF_SEMI
		;

namescasesensitive
		: LEF_NAMESCASESENSITIVE ( LEF_ON | LEF_OFF ) LEF_SEMI
		;

units		: LEF_UNITS LEF_DATABASE LEF_MICRONS LEF_NUMBER LEF_SEMI
		  LEF_END LEF_UNITS
		;

//layer		: LEF_LAYER << ID_MODE; >> LEF_IDENT ( layer_guts )*
//		  LEF_END << ID_MODE; >> LEF_IDENT
//		;

//layer_guts	: LEF_TYPE
//		    (   LEF_ROUTING LEF_SEMI routing_layer 
//		    | LEF_CUT LEF_SEMI cut_layer
//		    | ( LEF_MASTERSLICE | LEF_OVERLAP ) LEF_SEMI masterslice_layer
//		    )
//		;

//layer_type	: LEF_ROUTING LEF_SEMI routing_layer
//		| LEF_CUT LEF_SEMI cut_layer
//		| ( LEF_MASTERSLICE | LEF_OVERLAP ) LEF_SEMI masterslice_layer
//		;

//routing_layer
//		: layer_pitch
//		  ( layer_offset | )
//		  layer_width
//		  ( layer_resistance | )
//		  ( layer_capacitance | )
//		;
		

layer_pitch	: LEF_PITCH number LEF_SEMI
		;

layer_width	: LEF_WIDTH number LEF_SEMI
		;

layer_spacing
		: LEF_SPACING number LEF_SEMI
		;

layer_resistance
		: LEF_RESISTANCE LEF_RPERSQ number LEF_SEMI
		;

layer_capacitance
		: LEF_CAPACITANCE CPERSQDIST number LEF_SEMI
		;

macro [pnl_library plibrary]
		: << char *name;
		     pnl_libcell plibcell;
		  >>
		  LEF_MACRO << ID_MODE; >> id1:LEF_IDENT
			<< name = STRDUPA ($id1);
			   plibcell = lef2pnl_get_libcell (name, plibrary);
			>>
		    ( macro_stmt [plibcell] )*
		  LEF_END << ID_MODE; >> id2:LEF_IDENT
			<< if ( strcmp ($id2, name) != 0 ) {
			     lef2pnl_error ("END name, %s, does not match MACRO "
					    " name for %s", $id2, name);
			   }
			>>
		;

macro_stmt [pnl_libcell plibcell]
		: macro_class [plibcell]
		| macro_foreign [plibcell]
		| macro_origin [plibcell]
		| macro_size [plibcell]
		| macro_symmetry [plibcell]
		| macro_site [plibcell]
		| macro_pin [plibcell]
		| macro_obs [plibcell]
		;

macro_class [pnl_libcell plibcell]
		: << pnl_cellclass class; >>
		  LEF_CLASS cellclass > [class]
			<< pnl_libcell_set_class (plibcell, class); >>
		  LEF_SEMI
		;

macro_foreign [pnl_libcell plibcell]
		: << int n1, n2; >>
		  LEF_FOREIGN << ID_MODE; >> id:LEF_IDENT
		  number > [n1] number > [n2]
		  LEF_SEMI
		;

macro_origin [pnl_libcell plibcell]
		: << int x, y; >>
		  LEF_ORIGIN coordinate > [x, y]
		  LEF_SEMI
			<< pnl_libcell_set_origin (plibcell, x, y); >>
		;

macro_size [pnl_libcell plibcell]
		: << int width;
		     int height; 
		  >>
		  LEF_SIZE number > [width] LEF_BY number > [height] LEF_SEMI
			<< pnl_libcell_set_size (plibcell, width, height); >>
		;

macro_symmetry [pnl_libcell plibcell]
		: << pnl_symmetry sym; >>
		  LEF_SYMMETRY
		    ( symmetry > [sym]
			<< pnl_libcell_add_symmetry (plibcell, sym); >>
		    )*
		  LEF_SEMI
		;

macro_site [pnl_libcell plibcell]
		: LEF_SITE << ID_MODE; >> id:LEF_IDENT
			<< pnl_libcell_set_site (plibcell, $id); >>
		  LEF_SEMI
		;

macro_pin [pnl_libcell plibcell]
		: << char *name;
		     pnl_libpin plibpin;
		  >>
		  LEF_PIN << ID_MODE; >> id1:LEF_IDENT
			<< name = STRDUPA ($id1);
			   plibpin = lef2pnl_get_libpin ($id1, plibcell);
			>>
		    ( pin_stmt [plibpin] )*
		  LEF_END << ID_MODE; >> id2:LEF_IDENT
			<< if ( strcmp ($id2, name) != 0 ) {
			     lef2pnl_error ("END name, %s, does not match PIN name"
					    " for %s on macro %s", $id2, name,
					    pnl_libcell_name (plibcell));
			   }

			   pnl_libpin_compute_location (plibpin);
			>>
		;

macro_obs [pnl_libcell plibcell]
		: << pnl_geometry g; >>
		  LEF_OBS
		    ( geometry > [g]
			<< pnl_libcell_add_obs_geometry (plibcell, g); >>
		    )*
		  LEF_END
		;

pin_stmt [pnl_libpin plibpin]
		: pin_direction [plibpin]
		| pin_use [plibpin]
		| pin_shape [plibpin]
		| pin_capacitance [plibpin]
		| pin_port [plibpin]
		| pin_antennadiffarea [plibpin]
		| pin_antennagatearea [plibpin]
		| pin_antennasize [plibpin]
		;

pin_direction [pnl_libpin plibpin]
		: << nl_direction dir;
		     int flag;
		  >>
		  LEF_DIRECTION direction > [dir] LEF_SEMI!
			<< flag = pnl_libpin_set_or_check_direction (plibpin,
								     dir);
			   if ( !flag ) {
			     pnl_libcell plibcell
			       = pnl_libpin_libcell (plibpin);
			     lef2pnl_error ("inconsistent direction for PIN %s on "
					    "MACRO %s",
					    pnl_libpin_name (plibpin),
					    pnl_libcell_name (plibcell));
			   }
			>>
		;

pin_use [pnl_libpin plibpin]
		: << nl_use u;
		     int flag;
		  >>
		  LEF_USE use > [u] LEF_SEMI
			<< flag = pnl_libpin_set_or_check_use (plibpin, u);
			   if ( !flag ) {
			     pnl_libcell plibcell
			       = pnl_libpin_libcell (plibpin);
			     lef2pnl_error ("inconsistent use for PIN %s on "
					    "MACRO %s",
					    pnl_libpin_name (plibpin),
					    pnl_libcell_name (plibcell));
			   }
			>>
		;

pin_shape [pnl_libpin plibpin]
		: << pnl_shape s; >>
		  LEF_SHAPE shape > [s] LEF_SEMI
			<< pnl_libpin_set_shape (plibpin, s); >>
		;

pin_capacitance [pnl_libpin plibpin]
		: << float cap; >>
		  LEF_CAPACITANCE n:LEF_NUMBER 
			<< sscanf ($n, "%f", &cap);
			   pnl_libpin_set_capacitance (plibpin, cap);
			>>
		  LEF_SEMI
		;

pin_port [pnl_libpin plibpin]
		: << pnl_geometry g; >>
		  LEF_PORT
		    ( geometry > [g]
			<< pnl_libpin_add_port_geometry (plibpin, g); >>
		    )*
		  LEF_END
		;

pin_antennadiffarea [pnl_libpin plibpin]
		: << int area; >>
		  LEF_ANTENNADIFFAREA area_number > [area] LEF_SEMI
			<< pnl_libpin_set_antennadiffarea (plibpin, area); >>
		;

pin_antennagatearea [pnl_libpin plibpin]
		: << int area; >>
		  LEF_ANTENNAGATEAREA area_number > [area] LEF_SEMI
			<< pnl_libpin_set_antennagatearea (plibpin, area); >>
		;

pin_antennasize [pnl_libpin plibpin]
		: << int size; >>
		  LEF_ANTENNASIZE area_number > [size] LEF_SEMI
		;

geometry > [pnl_geometry g]
		: layer_geometry > [$g]
		| via_geometry > [$g]
		;

layer_geometry > [pnl_geometry result]
		: << int x0, y0;
		     int x1, y1;
	             ar points = NULL;
		  >>
		  LEF_LAYER << ID_MODE; >> id:LEF_IDENT
			<< $result
			     = pnl_geometry_create (pnl_geometryclass_layer,
						    $id);
			>>
		  LEF_SEMI
		  ( LEF_RECT coordinate > [x0, y0] coordinate > [x1, y1] 
			<< pnl_geometry_add_rectangle ($result, 
						       x0, y0, x1, y1);
			>>
		    LEF_SEMI
		  | LEF_POLYGON
			<< points = ar_alloc (8, sizeof (int)); >>
		      ( coordinate > [x0, y0]
				<< ar_add (points, &x0);
				   ar_add (points, &y0);
				>>
		      )+
			<< pnl_geometry_add_polygon ($result, points);
			   ar_free (points);
			   points = NULL;
			>>
		    LEF_SEMI
		  )*
		;

via_geometry > [pnl_geometry result]
		: << char *via_name;
		     int x, y;
		  >>
		  LEF_VIA number > [x] n:LEF_NUMBER
			<< y = lef2pnl_translate_number ($n, 3);
			   ID_MODE;
			>>
		  id:LEF_IDENT
			<< $result
			     = pnl_geometry_create (pnl_geometryclass_via,
						    $id);
			   pnl_geometry_add_point ($result, x, y);
			>>
		  LEF_SEMI
		;

cellclass > [pnl_cellclass result]
		: LEF_COVER	<< $result = pnl_cellclass_COVER; >>
		| LEF_RING	<< $result = pnl_cellclass_RING; >>
		| LEF_BLOCK	<< $result = pnl_cellclass_BLOCK; >>
		| LEF_PAD	<< $result = pnl_cellclass_PAD; >>
		| LEF_CORE	<< $result = pnl_cellclass_CORE; >>
		| LEF_ENDCAP	<< $result = pnl_cellclass_ENDCAP; >>
		;

use > [nl_use result]
		: LEF_SIGNAL	<< $result = nl_use_signal; >>
		| LEF_CLOCK	<< $result = nl_use_clock; >>	
		| LEF_ANALOG	<< $result = nl_use_analog; >>
		| LEF_GROUND	<< $result = nl_use_ground; >>
		| LEF_POWER	<< $result = nl_use_power; >>
		;

shape > [pnl_shape result]
		: LEF_ABUTMENT	<< $result = pnl_shape_ABUTMENT; >>
		| LEF_FEEDTHRU	<< $result = pnl_shape_FEEDTHRU; >>	
		| LEF_RING	<< $result = pnl_shape_RING; >>
		;

direction > [nl_direction result]
		: LEF_INPUT	<< $result = nl_direction_in; >>
		| LEF_OUTPUT	<< $result = nl_direction_out; >>
		| LEF_INOUT	<< $result = nl_direction_inout; >>
		;

orientation > [pnl_orientation result]
		: LEF_N 	<< $result = pnl_orientation_N; >>
		| LEF_S		<< $result = pnl_orientation_S; >>
		| LEF_E		<< $result = pnl_orientation_E; >>
		| LEF_W		<< $result = pnl_orientation_W; >>
		| LEF_FN	<< $result = pnl_orientation_FN; >>
		| LEF_FS	<< $result = pnl_orientation_FS; >>
		| LEF_FE	<< $result = pnl_orientation_FE; >>
		| LEF_FW	<< $result = pnl_orientation_FW; >>
		;

symmetry > [pnl_symmetry result]
		: LEF_X		<< $result = pnl_symmetry_X; >>
		| LEF_Y		<< $result = pnl_symmetry_Y; >>
		| LEF_R90	<< $result = pnl_symmetry_R90; >>
		;

coordinate > [int x, int y]
		: number > [$x] number > [$y]
		;

number > [int result]
		: n:LEF_NUMBER
			<< $result = lef2pnl_translate_number ($n, 3); >>
		;

area_number > [int result]
		: n:LEF_NUMBER
			<< $result = lef2pnl_translate_number ($n, 6); >>
		;


