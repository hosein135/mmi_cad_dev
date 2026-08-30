// ************************************************************************
// 
// Copyright (c) 1995-2002 Juniper Networks, Inc. All rights reserved.
// 
// Permission is hereby granted, without written agreement and without
// license or royalty fees, to use, copy, modify, and distribute this
// software and its documentation for any purpose, provided that the
// above copyright notice and the following three paragraphs appear in
// all copies of this software.
// 
// IN NO EVENT SHALL JUNIPER NETWORKS, INC. BE LIABLE TO ANY PARTY FOR
// DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
// ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF
// JUNIPER NETWORKS, INC. HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
// DAMAGE.
// 
// JUNIPER NETWORKS, INC. SPECIFICALLY DISCLAIMS ANY WARRANTIES,
// INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
// NON-INFRINGEMENT.
// 
// THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND JUNIPER
// NETWORKS, INC. HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
// UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
// 
// ************************************************************************

#ifndef	expressions_h
#define expressions_h



///////////////////////////////////////////////////////

// Now that I mention it, I don't know why I need an EXPRESSION 
// base class.  Maybe I will think of a reason later....
// In the meantime, it is as if....
// class EXPRESSION {
//     public:
//	   virtual rc_t		read_in()	= 0;
//	   virtual void		print()		= 0; 
// }
//
// every expression class needs a "read_in()"
// method that gets tokens to complete the expression.  
// Many times the read_in method will have to create a nested
// expression and call its read_in method.
// When the read_in method is called, we assume that the last token
// read was the keyword identifying the expression type, so read_in
// just picks up the arguements (according to the format in the
// EDIF reference manual) and the trailing RPAR.  This means that
// when the <arg>::read_in method returns, the next token to be 
// read will be the first token of the next arg, or the RPAR of
// the enclosing expression.  Too wordy?
//
// we also want a "print" method that will (recursively) output
// and edif file such as the one we already read, nicely 
// prettyprinted, please.  Note that when a list of expressions 
// has been printed 
//	ie, from an EDIF definition like 
//		( enclosing_expr_type
//			[ nameDef_or_nameRef ]
//			{ various_expr_types }
//		)
// the <various_expr_types> have been reordered, so that the
// resulting output may not be a legal EDIF file due to the
// "defined before used" constraint on names.
//
// NOTE: this is only a partial implementatin of the reader.
// Declarations for data members of unsupported types are 
// included in the expression class declaration and commented out.


///////////////////////////////////////////////////////
// DIRECTION, JUSTIFY, and ORIENTATION are specified as
// regular expression types, but seems like overkill to me.

enum DIRECTION {
    DIRECTION_NOT_SPECIFIED,
    INOUT, INPUT, OUTPUT
};

///////////////////////////////////////////////////////

enum JUSTIFY {
	JUSTIFY_NOT_SPECIFIED,
	UPPERLEFT, UPPERCENTER, UPPERRIGHT,
	CENTERLEFT, CENTERCENTER, CENTERRIGHT,
	LOWERLEFT, LOWERCENTER, LOWERRIGHT
};

///////////////////////////////////////////////////////

enum ORIENTATION {
    ORIENTATION_NOT_SPECIFIED,
    R0, R90, R180, R270, 
    MX, MY, MYR90, MXR90
};

///////////////////////////////////////////////////////

class ANNOTATE_EXPR {
    public:	
		ANNOTATE_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	char *				stringvalue;
	class STRINGDISPLAY_EXPR *	stringdisplay;
};

class ListOfANNOTATE_EXPR {
    public:
		ListOfANNOTATE_EXPR(ANNOTATE_EXPR *, ListOfANNOTATE_EXPR *);

	ListOfANNOTATE_EXPR *	next;
	ANNOTATE_EXPR *		expr;
};

///////////////////////////////////////////////////////

class ARC_EXPR {
    public:	
		ARC_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	class PT_EXPR *		pt1;
	class PT_EXPR *		pt2;
	class PT_EXPR *		pt3;
};

class ListOfARC_EXPR {
    public:
		ListOfARC_EXPR(ARC_EXPR *, ListOfARC_EXPR *);

	ListOfARC_EXPR *	next;
	ARC_EXPR *		expr;
};

///////////////////////////////////////////////////////

class BOUNDINGBOX_EXPR {
    public:	
		BOUNDINGBOX_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	class RECTANGLE_EXPR *		rectangle;
};

///////////////////////////////////////////////////////

enum CELL_TYPE {
	GENERIC, TIE, RIPPER
};

class CELL_EXPR {
    public:	
		CELL_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	class NAMEDEF *			namedef;
	class NAMESCOPE *		namescope;

	CELL_TYPE			celltype;
	class STATUS_EXPR *		status;
	class VIEWMAP_EXPR *		viewmap;
	class ListOfVIEW_EXPR *		view_list;
	class ListOfPROPERTY_EXPR *	property_list;
//	class ListOfCOMMENT_EXPR *	comment_list;
//	class ListOfUSER_DATA *		userdata_list;
};

class ListOfCELL_EXPR {
    public:
		ListOfCELL_EXPR(CELL_EXPR *, ListOfCELL_EXPR *);

	void *			debug;
	ListOfCELL_EXPR *	next;
	CELL_EXPR *		expr;
};

///////////////////////////////////////////////////////

class CELLREF_EXPR {
    public:	
		CELLREF_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	class NAMEREF *			cellnameref;
	class NAMEDEF *			cellnamedef;

	class LIBRARYREF_EXPR *		libraryref;
};

///////////////////////////////////////////////////////

class CIRCLE_EXPR {
    public:	
		CIRCLE_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	class PT_EXPR *			pt1;
	class PT_EXPR *			pt2;
	class ListOfPROPERTY_EXPR * 	property_list;
};

class ListOfCIRCLE_EXPR {
    public:
		ListOfCIRCLE_EXPR(CIRCLE_EXPR *, ListOfCIRCLE_EXPR *);

	ListOfCIRCLE_EXPR *	next;
	CIRCLE_EXPR *		expr;
};

///////////////////////////////////////////////////////

class COMMENTGRAPHICS_EXPR {
    public:	
		COMMENTGRAPHICS_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	class BOUNDINGBOX_EXPR *		boundingbox;
	class ListOfANNOTATE_EXPR *		annotate_list;
	class ListOfFIGURE_EXPR *		figure_list;
	class ListOfINSTANCE_EXPR *		instance_list;
	class ListOfPROPERTY_EXPR *		property_list;
//	class ListOfCOMMENT_EXPR *		comment_list;
//	class ListOfUSERDATA_EXPR *		userdata_list;
};

class ListOfCOMMENTGRAPHICS_EXPR {
    public:
		ListOfCOMMENTGRAPHICS_EXPR(COMMENTGRAPHICS_EXPR *, 
		    ListOfCOMMENTGRAPHICS_EXPR *);

	ListOfCOMMENTGRAPHICS_EXPR *	next;
	COMMENTGRAPHICS_EXPR *		expr;
};

///////////////////////////////////////////////////////

class CONNECTLOCATION_EXPR {
    public:	
		CONNECTLOCATION_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	class ListOfFIGURE_EXPR *		figure_list;
};

class ListOfCONNECTLOCATION_EXPR {
    public:
		ListOfCONNECTLOCATION_EXPR(CONNECTLOCATION_EXPR *, 
		    ListOfCONNECTLOCATION_EXPR *);

	ListOfCONNECTLOCATION_EXPR *	next;
	CONNECTLOCATION_EXPR *		expr;
};

///////////////////////////////////////////////////////

class CONTENTS_EXPR {
    public:	
		CONTENTS_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	class BOUNDINGBOX_EXPR *	boundingbox;
	class ListOfINSTANCE_EXPR *	instance_list;
//	class ListOfOFFPAGECONNECTOR_EXPR *	offpageconnector_list;
	class ListOfFIGURE_EXPR *	figure_list;
//	class ListOfSECTION_EXPR *	section_list;
	class ListOfNET_EXPR *		net_list;
//	class ListOfNETBUNDLE_EXPR *	netbundle_list;
	class ListOfPAGE_EXPR *		page_list;
	class ListOfCOMMENTGRAPHICS_EXPR *	commentgraphics_list;
	class ListOfPORTIMPLEMENTATION_EXPR *	portimplementation_list;
//	class ListOfTIMING_EXPR *	timing_list;
//	class ListOfSIMULATE_EXPR *	simulate_list;
//	class ListOfWHEN_EXPR *		when_list;
//	class ListOfFOLLOW_EXPR *	follow_list;
//	class ListOfLOGICPORT_EXPR *	logicport_list;
//	class ListOfCOMMENT_EXPR *	comment_list;
//	class ListOfUSER_DATA *		userdata_list;
};

///////////////////////////////////////////////////////

// A curve is composed of points (which define a line
// segment) and arcs, which have to be kept in order.

class CURVE_ELEMENT {
    public:
		CURVE_ELEMENT(PT_EXPR *);
		CURVE_ELEMENT(ARC_EXPR *);

	class PT_EXPR *			pt;
	class ARC_EXPR *		arc;
	class CURVE_ELEMENT *		next;
};

class CURVE_EXPR {
    public:	
		CURVE_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	class CURVE_ELEMENT *		element_list;
};

class ListOfCURVE_EXPR {
    public:
		ListOfCURVE_EXPR(CURVE_EXPR *, ListOfCURVE_EXPR *);

	ListOfCURVE_EXPR *	next;
	CURVE_EXPR *		expr;
};

///////////////////////////////////////////////////////

class DISPLAY_EXPR {
    public:	
		DISPLAY_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	// nameRef or figureGroupOverride
	class NAMEREF *			nameref;
	class NAMEDEF *			namedef;
	class FIGUREGROUPOVERRIDE_EXPR *figuregroupoverride;

	JUSTIFY				justify;
	ORIENTATION			orientation;
	class ORIGIN_EXPR *		origin;
};

class ListOfDISPLAY_EXPR {
    public:
		ListOfDISPLAY_EXPR(DISPLAY_EXPR *, ListOfDISPLAY_EXPR *);

	ListOfDISPLAY_EXPR *	next;
	DISPLAY_EXPR *		expr;
};

///////////////////////////////////////////////////////

class DOT_EXPR {
    public:	
		DOT_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	class PT_EXPR *			pt;
	class ListOfPROPERTY_EXPR *	property_list;
};

class ListOfDOT_EXPR {
    public:
		ListOfDOT_EXPR(DOT_EXPR *, ListOfDOT_EXPR *);

	ListOfDOT_EXPR *	next;
	DOT_EXPR *		expr;
};

///////////////////////////////////////////////////////

class EDIF_EXPR {
    public:	
		EDIF_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	class NAMEDEF *			namedef;
	class NAMESCOPE *		namescope;

//	class EDIF_VERSION_EXPR *	edif_version;
//	class EDIF_LEVEL_EXPR *		edif_level;
//	class KEYWORD_MAP_EXPR *	keyword_map;
	class STATUS_EXPR *		status;
//	class ListOfEXTERNAL_EXPR *	external_list;
	class ListOfLIBRARY_EXPR *	library_list;
//	class ListOfDESIGN_EXPR *	design_list;
//	class ListOfCOMMENT_EXPR *	comment_list;
//	class ListOfUSER_DATA *		userdata_list;
};

///////////////////////////////////////////////////////

class FIGURE_EXPR {
    public:	
		FIGURE_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	class NAMEREF *			nameref;
	class NAMEDEF *			namedef;
	class FIGUREGROUPOVERRIDE_EXPR *figuregroupoverride;

	class ListOfCIRCLE_EXPR *	circle_list;
	class ListOfDOT_EXPR *		dot_list;
	class ListOfOPENSHAPE_EXPR *	openshape_list;
	class ListOfPATH_EXPR *		path_list;
	class ListOfPOLYGON_EXPR *	polygon_list;
	class ListOfRECTANGLE_EXPR *	rectangle_list;
	class ListOfSHAPE_EXPR *	shape_list;
//	class ListOfCOMMENT_EXPR *	comment_list;
//	class ListOfUSERDATA_EXPR *	userdata_list;
};

class ListOfFIGURE_EXPR {
    public:
		ListOfFIGURE_EXPR(FIGURE_EXPR *, 
		    ListOfFIGURE_EXPR *);

	ListOfFIGURE_EXPR *	next;
	FIGURE_EXPR *		expr;
};

///////////////////////////////////////////////////////

class FIGUREGROUP_EXPR {
    public:	
		FIGUREGROUP_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	class NAMEDEF *			namedef;
	class NAMESCOPE *		namescope;

//	class CORNERTYPE_EXPR *		cornertype;
//	class ENDTYPE *			endtype;
//	class PATHWIDTH *		pathwidth;
//	class BORDERWIDTH *		borderwidth;
//	class COLOR *			color;
//	class FILLPATTERN *		fillpattern;
//	class BORDERPATTERN *		borderpattern;
	int				textheight;
	BOOLEAN				textheight_valid;
//	class VISIBLE *			visible;
//	class ListOfINCLUDEFIGUREGROUP_EXPR * includefiguregroup_list;
	class ListOfPROPERTY_EXPR *	property_list;
//	class ListOfCOMMENT_EXPR *	comment_list;
//	class ListOfUSERDATA_EXPR *	userdata_list;
};

class ListOfFIGUREGROUP_EXPR {
    public:
		ListOfFIGUREGROUP_EXPR(FIGUREGROUP_EXPR *, 
		    ListOfFIGUREGROUP_EXPR *);

	ListOfFIGUREGROUP_EXPR *	next;
	FIGUREGROUP_EXPR *		expr;
};

///////////////////////////////////////////////////////

class FIGUREGROUPOVERRIDE_EXPR {
    public:	
		FIGUREGROUPOVERRIDE_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	class NAMEREF *			nameref;
	class NAMEDEF *			namedef;

//	class CORNERTYPE_EXPR *		cornertype;
//	class ENDTYPE_EXPR *		endtype;
//	class PATHWIDTH_EXPR *		pathwidth;
//	class BORDERWIDTH_EXPR *	borderwidth;
//	class COLOR_EXPR *		color;
//	class FILLPATTERN_EXPR *	fillpattern;
//	class BORDERPATTERN_EXPR *	borderpattern;
	int				textheight;
	BOOLEAN				textheight_valid;
//	class VISIBLE_EXPR *		visible;
	class ListOfPROPERTY_EXPR * 	property_list;
//	class ListOfCOMMENT_EXPR * 	comment_list;
//	class ListOfUSERDATA_EXPR * 	userdata_list;
};

class ListOfFIGUREGROUPOVERRIDE_EXPR {
    public:
		ListOfFIGUREGROUPOVERRIDE_EXPR(FIGUREGROUPOVERRIDE_EXPR *, ListOfFIGUREGROUPOVERRIDE_EXPR *);

	ListOfFIGUREGROUPOVERRIDE_EXPR *	next;
	FIGUREGROUPOVERRIDE_EXPR *		expr;
};

///////////////////////////////////////////////////////

class INSTANCE_EXPR {
    public:	
		INSTANCE_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	class NAMEDEF *			namedef;
	class NAMESCOPE *		namescope;

	class VIEWREF_EXPR *		viewref;
//	class VIEWLIST_EXPR *		viewlist;

	class TRANSFORM_EXPR *		transform;
//	class DESIGNATOR_EXPR *		designator;
//	class ListOfPARAMETERASSIGN_EXPR * parameterassign_list;
//	class ListOfPORTINSTANCE_EXPR *	portinstancd_list;
//	class ListOfTIMING_EXPR *	timing_list;
	class ListOfPROPERTY_EXPR *	property_list;
//	class ListOfCOMMENT_EXPR *	comment_list;
//	class ListOfUSERDATA_EXPR *	userdata_list;
};

class ListOfINSTANCE_EXPR {
    public:
		ListOfINSTANCE_EXPR(INSTANCE_EXPR *, ListOfINSTANCE_EXPR *);

	ListOfINSTANCE_EXPR *	next;
	INSTANCE_EXPR *		expr;
};

///////////////////////////////////////////////////////

class INTERFACE_EXPR {
    public:	
		INTERFACE_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	class SYMBOL_EXPR *		symbol;
//	class PROTECTIONFRAME_EXPR *	protectionframe;
//	class ARRAYRELATEDINFO_EXPR *	arrayrelatedinfo;
//	class DESIGNATOR_EXPR *		designator;

	class ListOfPORT_EXPR *		port_list;
//	class ListOfPORTBUNDLE_EXPR *	portbundle_list;
//	class ListOfPARAMETER_EXPR *	parameter_list;
//	class ListOfJOINED_EXPR *	joined_list;
//	class ListOfMUSTJOIN_EXPR *	mustjoin_list;
//	class ListOfWEAKJOINED_EXPR *	weakjoined_list;
//	class ListOfPERMUTABLE_EXPR *	permutable_list;
//	class ListOfTIMING_EXPR *	timing_list;
//	class ListOfSIMULATE_EXPR *	simulate_list;
//	class ListOfCONSTANT_EXPR *	constant_list;
//	class ListOfCONSTRAINT_EXPR *	constraint_list;
//	class ListOfVARIABLE_EXPR *	variable_list;
//	class ListOfASSIGN_EXPR *	assign_list;
//	class ListOfBLOCK_EXPR *	block_list;
//	class ListOfIF_EXPR *		if_list;
//	class ListOfITERATE_EXPR *	iterate_list;
//	class ListOfWHILE_EXPR *	while_list;
	class ListOfPROPERTY_EXPR * 	property_list;
//	class ListOfCOMMENT_EXPR * 	comment_list;
//	class ListOfUSERDATA_EXPR * 	userdata_list;
};

class ListOfINTERFACE_EXPR {
    public:
		ListOfINTERFACE_EXPR(INTERFACE_EXPR *, ListOfINTERFACE_EXPR *);

	ListOfINTERFACE_EXPR *	next;
	INTERFACE_EXPR *		expr;
};

///////////////////////////////////////////////////////

class INSTANCEREF_EXPR {
    public:	
		INSTANCEREF_EXPR();
		~INSTANCEREF_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	class NAMEREF *			instancenameref;
	class NAMEDEF *			instancenamedef;

	// this is portnamedef->get_stringvalue; 
	// a convenience member because I find myself
	// referencing it a lot, and it seems horrible
	// to be doing all those mallocs.
	char *				resolved_name;

//	class INSTANCEREF_EXPR *	instanceref;
//	class VIEWREF_EXPR *		viewref;

};

///////////////////////////////////////////////////////

class JOINED_EXPR {
    public:	
		JOINED_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	class ListOfPORTREF_EXPR *	portref_list;
//	class ListOfPORTLIST_EXPR *	portlist_list;
//	class ListOfGLOBALPORTREF_EXPR *globalportref_list;
};

class ListOfJOINED_EXPR {
    public:
		ListOfJOINED_EXPR(JOINED_EXPR *, ListOfJOINED_EXPR *);

	ListOfJOINED_EXPR *	next;
	JOINED_EXPR *		expr;
};

///////////////////////////////////////////////////////

class KEYWORDDISPLAY_EXPR {
    public:	
		KEYWORDDISPLAY_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	class NAMEREF *			nameref;
	class NAMEDEF *			namedef;
	class ListOfDISPLAY_EXPR *	display_list;
};

class ListOfKEYWORDDISPLAY_EXPR {
    public:
		ListOfKEYWORDDISPLAY_EXPR(KEYWORDDISPLAY_EXPR *, ListOfKEYWORDDISPLAY_EXPR *);

	ListOfKEYWORDDISPLAY_EXPR *	next;
	KEYWORDDISPLAY_EXPR *		expr;
};

///////////////////////////////////////////////////////

class LIBRARY_EXPR {
    public:	
		LIBRARY_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	class NAMEDEF *			namedef;
	class NAMESCOPE *		namescope;

	class TECHNOLOGY_EXPR *		technology;
	class STATUS_EXPR *		status;
	class ListOfCELL_EXPR *		cell_list;
//	class ListOfCOMMENT_EXPR *	comment_list;
//	class ListOfUSER_DATA *		userdata_list;
};

class ListOfLIBRARY_EXPR {
    public:
		ListOfLIBRARY_EXPR(LIBRARY_EXPR *, ListOfLIBRARY_EXPR *);

	ListOfLIBRARY_EXPR *	next;
	LIBRARY_EXPR *		expr;
};

///////////////////////////////////////////////////////

class LIBRARYREF_EXPR {
    public:	
		LIBRARYREF_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	class NAMEREF *			librarynameref;
	class NAMEDEF *			librarynamedef;
};

///////////////////////////////////////////////////////

class NAME_EXPR {
    public:	
		NAME_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	char *				identifier;
	class ListOfDISPLAY_EXPR *	display_list;
};

class ListOfNAME_EXPR {
    public:
		ListOfNAME_EXPR(NAME_EXPR *, ListOfNAME_EXPR *);

	ListOfNAME_EXPR *	next;
	NAME_EXPR *		expr;
};

///////////////////////////////////////////////////////

class NET_EXPR {
    public:	
		NET_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	class NAMEDEF *			namedef;
	class NAMESCOPE *		namescope;

	class JOINED_EXPR *		joined;
//	class CRITICALITY_EXPR *	criticality;
//	class ListOfNETDELAY_EXPR *	netdelay_list;
	class ListOfFIGURE_EXPR *	figure_list;
	class ListOfNET_EXPR *		net_list;
	class ListOfINSTANCE_EXPR *	instance_list;
	class ListOfCOMMENTGRAPHICS_EXPR *commentgraphics_list;
	class ListOfPROPERTY_EXPR * 	property_list;
	class ListOfCOMMENT_EXPR * 	comment_list;
	class ListOfUSERDATA_EXPR * 	userdata_list;
};

class ListOfNET_EXPR {
    public:
		ListOfNET_EXPR(NET_EXPR *, ListOfNET_EXPR *);

	ListOfNET_EXPR *	next;
	NET_EXPR *		expr;
};

///////////////////////////////////////////////////////

class OPENSHAPE_EXPR {
    public:	
		OPENSHAPE_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	class CURVE_EXPR *		curve;
	class ListOfPROPERTY_EXPR * 	property_list;
};

class ListOfOPENSHAPE_EXPR {
    public:
		ListOfOPENSHAPE_EXPR(OPENSHAPE_EXPR *, ListOfOPENSHAPE_EXPR *);

	ListOfOPENSHAPE_EXPR *	next;
	OPENSHAPE_EXPR *	expr;
};

///////////////////////////////////////////////////////

class ORIGIN_EXPR {
    public:	
		ORIGIN_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	class PT_EXPR *		pt;
};

///////////////////////////////////////////////////////

class PAGE_EXPR {
    public:	
		PAGE_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	class NAMEDEF *			namedef;
	class NAMESCOPE *		namescope;

//	class PAGESIZE_EXPR *		pagesize;
	class BOUNDINGBOX_EXPR *	boundingbox;
	class ListOfINSTANCE_EXPR *	instance_list;
	class ListOfNET_EXPR *		net_list;
//	class ListOfNETBUNDLE_EXPR *	netbundle_list;
	class ListOfCOMMENTGRAPHICS_EXPR *commentgraphics_list;
	class ListOfPORTIMPLEMENTATION_EXPR *portimplementation_list;
//	class ListOfCOMMENT_EXPR * 	comment_list;
//	class ListOfUSERDATA_EXPR * 	userdata_list;
};

class ListOfPAGE_EXPR {
    public:
		ListOfPAGE_EXPR(PAGE_EXPR *, ListOfPAGE_EXPR *);

	ListOfPAGE_EXPR *	next;
	PAGE_EXPR *		expr;
};

///////////////////////////////////////////////////////

class PATH_EXPR {
    public:	
		PATH_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	class POINTLIST_EXPR *		pointlist;
	class ListOfPROPERTY_EXPR * 	property_list;
};

class ListOfPATH_EXPR {
    public:
		ListOfPATH_EXPR(PATH_EXPR *, ListOfPATH_EXPR *);

	ListOfPATH_EXPR *	next;
	PATH_EXPR *		expr;
};

///////////////////////////////////////////////////////

class POINTLIST_EXPR {
    public:	
		POINTLIST_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	class ListOfPT_EXPR *		pt_list;
};

class ListOfPOINTLIST_EXPR {
    public:
		ListOfPOINTLIST_EXPR(POINTLIST_EXPR *, ListOfPOINTLIST_EXPR *);

	ListOfPOINTLIST_EXPR *	next;
	POINTLIST_EXPR *		expr;
};


///////////////////////////////////////////////////////

class POLYGON_EXPR {
    public:	
		POLYGON_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	class POINTLIST_EXPR *		pointlist;
	class ListOfPROPERTY_EXPR * 	property_list;
};

class ListOfPOLYGON_EXPR {
    public:
		ListOfPOLYGON_EXPR(POLYGON_EXPR *, ListOfPOLYGON_EXPR *);

	ListOfPOLYGON_EXPR *	next;
	POLYGON_EXPR *		expr;
};

///////////////////////////////////////////////////////

class PORT_EXPR {
    public:	
		PORT_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	class NAMEDEF *			namedef;
	class NAMESCOPE *		namescope;

	DIRECTION			direction;
//	class UNUSED_EXPR *		unused;
//	class DESIGNATOR_EXPR *		designator;
//	class DCFANINLOAD_EXPR *	dcfaninload;
//	class DCFANOUTLOAD_EXPR *	dcfanoutload;
//	class DCMAXFANIN_EXPR *		dcmaxfanin;
//	class DCMAXFANOUT_EXPR *	dcmaxfanout;
//	class ACLOAD_EXPR *		acload;
//	class ListOfPORTDELAY_EXPR *	portdelay_list;
	class ListOfPROPERTY_EXPR * 	property_list;
	class ListOfCOMMENT_EXPR * 	comment_list;
	class ListOfUSERDATA_EXPR * 	userdata_list;
};

class ListOfPORT_EXPR {
    public:
		ListOfPORT_EXPR(PORT_EXPR *, ListOfPORT_EXPR *);

	ListOfPORT_EXPR *	next;
	PORT_EXPR *		expr;
};

///////////////////////////////////////////////////////

class PORTIMPLEMENTATION_EXPR {
    public:	
		PORTIMPLEMENTATION_EXPR();

	// generated during conversion
	ORIENTATION			orientation;	

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);
				
	class NAMEREF *			nameref;
	class NAMEDEF *			namedef;

	class CONNECTLOCATION_EXPR *	connectlocation;
	class ListOfFIGURE_EXPR *	figure_list;
	class ListOfINSTANCE_EXPR *	instance_list;
	class ListOfCOMMENTGRAPHICS_EXPR *commentgraphics_list;
//	class ListOfPROPERTYDISPLAY_EXPR *propertydisplay_list;
	class ListOfKEYWORDDISPLAY_EXPR *keyworddisplay_list;
	class ListOfPROPERTY_EXPR * 	property_list;
//	class ListOfCOMMENT_EXPR * 	comment_list;

	// userdata expression is being used 
	// to provide rotation information
	class ListOfUSERDATA_EXPR * 	userdata_list;
};

class ListOfPORTIMPLEMENTATION_EXPR {
    public:
		ListOfPORTIMPLEMENTATION_EXPR(
		    PORTIMPLEMENTATION_EXPR *, 
		    ListOfPORTIMPLEMENTATION_EXPR *);

	ListOfPORTIMPLEMENTATION_EXPR *	next;
	PORTIMPLEMENTATION_EXPR *		expr;
};

///////////////////////////////////////////////////////

class PORTREF_EXPR {
    public:	
		PORTREF_EXPR();
		~PORTREF_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	class NAMEREF *			portnameref;
	class NAMEDEF *			portnamedef;

	// this is portnamedef->get_stringvalue; 
	// a convenience member because I find myself
	// referencing it a lot, and it seems horrible
	// to be doing all those mallocs.
	char *				resolved_name;

//	class PORTREF_EXPR *		portref;
	class INSTANCEREF_EXPR *	instanceref;
//	class VIEWREF_EXPR *		viewref;

};

class ListOfPORTREF_EXPR {
    public:
		ListOfPORTREF_EXPR(
		    PORTREF_EXPR *, 
		    ListOfPORTREF_EXPR *);

	ListOfPORTREF_EXPR *	next;
	PORTREF_EXPR *		expr;
};

///////////////////////////////////////////////////////

enum PROPERTY_VALUE_TYPE {
	BOOLEAN_PV, 
	INTEGER_PV, 
//	MINOMAX_PV,	// "minimum-nominal-maximum", aka "mnm"
	NUMBER_PV,		// floating point
	POINT_PV, 
	STRING_PV
};

class PROPERTY_EXPR {
    public:	
		PROPERTY_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	rc_t	read_number();

	// return a printable string representing the value of the
	// property.  No type info, hope he knows what he's doing.
	// ...strdup'd, delete when done.
	char	*get_value_str();

	// property's name was listed as IGNORE_PROPERTY
	BOOLEAN				is_ignorable;

	class NAMEDEF *			namedef;
	class NAMESCOPE *		namescope;

	PROPERTY_VALUE_TYPE		value_type;	
	BOOLEAN				boolean_value;
	int				integer_value;
	class PT_EXPR *			pt_value;
	char *				string_value;
	float				number_value;
	int				number_mantissa;
	int				number_exponent;
	
//	class OWNER_EXPR *		owner;
//	class UNIT_EXPR *		unit;
	class ListOfPROPERTY_EXPR * 	property_list;
//	class ListOfCOMMENT_EXPR * 	comment_list;
};

class ListOfPROPERTY_EXPR {
    public:
		ListOfPROPERTY_EXPR(PROPERTY_EXPR *, ListOfPROPERTY_EXPR *);

	ListOfPROPERTY_EXPR *	next;
	PROPERTY_EXPR *		expr;
};

///////////////////////////////////////////////////////

class PT_EXPR {
    public:	
		PT_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	int	xvalue;
	int	yvalue;
};

class ListOfPT_EXPR {
    public:
		ListOfPT_EXPR(PT_EXPR *, ListOfPT_EXPR *);
		~ListOfPT_EXPR();

	ListOfPT_EXPR *	next;
	PT_EXPR *		expr;
};

///////////////////////////////////////////////////////

class RECTANGLE_EXPR {
    public:	
		RECTANGLE_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	class PT_EXPR *			corner1;
	class PT_EXPR *			corner2;
	class ListOfPROPERTY_EXPR * 	property_list;
};

class ListOfRECTANGLE_EXPR {
    public:
		ListOfRECTANGLE_EXPR(RECTANGLE_EXPR *, 
		    ListOfRECTANGLE_EXPR *);

	ListOfRECTANGLE_EXPR *	next;
	RECTANGLE_EXPR *		expr;
};


///////////////////////////////////////////////////////

class RENAME_EXPR {
    public:	
		RENAME_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	class NAME_EXPR *	name;		// "identifier or name"
	char *			identifier;
	char *			string;		// "string token"
	class STRINGDISPLAY_EXPR *stringdisplay;
};

///////////////////////////////////////////////////////

// we don't use this type, but just for checking legal syntax
// it is conveinnt to have something defined with non-zero size.
// probably I am being silly.

class STATUS_EXPR {
	char *	string;	
};


///////////////////////////////////////////////////////

class STRINGDISPLAY_EXPR {
    public:	
		STRINGDISPLAY_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	// BUG... this should support stringValue,
	// which comprehends arrays
	char*				string;

	class ListOfDISPLAY_EXPR *	display_list;
};

class ListOfSTRINGDISPLAY_EXPR {
    public:
		ListOfSTRINGDISPLAY_EXPR(STRINGDISPLAY_EXPR *, 
		    ListOfSTRINGDISPLAY_EXPR *);

	ListOfSTRINGDISPLAY_EXPR *	next;
	STRINGDISPLAY_EXPR *		expr;
};

///////////////////////////////////////////////////////

class SYMBOL_EXPR {
    public:	
		SYMBOL_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	class PAGESIZE_EXPR *		pagesize;
	class BOUNDINGBOX_EXPR *	boundingbox;


	class ListOfPORTIMPLEMENTATION_EXPR * portimplementation_list;
	class ListOfFIGURE_EXPR *	figure_list;
	class ListOfANNOTATE_EXPR *	annotate_list;
	class ListOfINSTANCE_EXPR *	instance_list;
	class ListOfCOMMENTGRAPHICS_EXPR *commentgraphics_list;
//	class ListOfPROPERTYDISPLAY_EXPR *propertydisplay_list;
//	class ListOfKEYWORDDISPLAY_EXPR *keyworddisplay_list;
//	class ListOfPARAMATER_EXPR *	paramater_list;
	class ListOfPROPERTY_EXPR * 	property_list;
//	class ListOfCOMMENT_EXPR * 	comment_list;
//	class ListOfUSERDATA_EXPR * 	userdata_list;
};

class ListOfSYMBOL_EXPR {
    public:
		ListOfSYMBOL_EXPR(SYMBOL_EXPR *, ListOfSYMBOL_EXPR *);

	ListOfSYMBOL_EXPR *	next;
	SYMBOL_EXPR *		expr;
};

///////////////////////////////////////////////////////

class TECHNOLOGY_EXPR {
    public:	
		TECHNOLOGY_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	class ListOfFIGUREGROUP_EXPR *	figuregroup_list;
//	class ListOfFABRICATE_EXPR *	fabricate_list;
//	class SIMULATIONINFO_EXPR *	simulationinfo;
//	class PHYSICALDESIGNRULE_EXPR * physicaldesignrule;
//	class ListOfCOMMENT_EXPR *	comment_list;
//	class ListOfUSERDATA_EXPR *	userdata_list;	
};

///////////////////////////////////////////////////////

class TRANSFORM_EXPR {
    public:	
		TRANSFORM_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

//	class SCALE_EXPR *		scalex;
//	class SCALE_EXPR *		scaley;
//	class PT_EXPR *			delta;
	ORIENTATION			orientation;
	class ORIGIN_EXPR *		origin;
};

class ListOfTRANSFORM_EXPR {
    public:
		ListOfTRANSFORM_EXPR(TRANSFORM_EXPR *, 
		    ListOfTRANSFORM_EXPR *);

	ListOfTRANSFORM_EXPR *	next;
	TRANSFORM_EXPR *		expr;
};

///////////////////////////////////////////////////////

// userdata expression is being used to store
// rotation information for portimplementation expression

class USERDATA_EXPR {
    public:	
		USERDATA_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	char *	identifier;
	ORIENTATION orientation;
};

class ListOfUSERDATA_EXPR {
    public:
		ListOfUSERDATA_EXPR(USERDATA_EXPR *, 
		    ListOfUSERDATA_EXPR *);
		~ListOfUSERDATA_EXPR();

	ListOfUSERDATA_EXPR *	next;
	USERDATA_EXPR *		expr;
};

///////////////////////////////////////////////////////

// we don't use this type, but just for checking legal syntax
// it is conveinnt to have something defined with non-zero size.
// probably I am being silly.

class VIEWMAP_EXPR {
	char *	string;	
};


///////////////////////////////////////////////////////

enum VIEWTYPE {
    BEHAVIOR, DOCUMENT, GRAPHIC, LOGICMODEL, MASKLAYOUT,
    NETLIST, PCBLAYOUT, SCHEMATIC, STRANGER, SYMBOLIC
};

class VIEW_EXPR {
    public:
		VIEW_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	class NAMEDEF *			namedef;
	class NAMESCOPE *		namescope;

	VIEWTYPE			viewtype;
	class INTERFACE_EXPR *		interface;
	class STATUS_EXPR *		status;
	class CONTENTS_EXPR *		contents;
//	class ListOfCOMMENT_EXPR *	comment_list;
	class ListOfPROPERTY_EXPR *	property_list;
//	class ListOfUSER_DATA *		userdata_list;
};

class ListOfVIEW_EXPR {
    public:
		ListOfVIEW_EXPR(VIEW_EXPR *, 
		    ListOfVIEW_EXPR *);

	ListOfVIEW_EXPR *	next;
	VIEW_EXPR *		expr;
};


///////////////////////////////////////////////////////

// this is part of the naming system
// the viewnameref must be resolved in the cellref, 
// if there is one (not locally)

class VIEWREF_EXPR {
    public:	
		VIEWREF_EXPR();

	rc_t	read_in(NAMESCOPE *);
	void	print(int indent);

	class NAMEREF *			viewnameref;
	class NAMEDEF *			viewnamedef;

	class CELLREF_EXPR *		cellref;
};


#endif
