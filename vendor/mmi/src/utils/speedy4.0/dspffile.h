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

#ifndef dspf_file_h
#define dspf_file_h

#define LINEBUFSIZE	0x1000

class DSPFNET;
class DSPFPOINT;
class ListOfDSPFPOINT;
class DSPFSEGMENT;
class ListOfDSPFSEGMENT;

// Sue calls speedy_output_file to open a DSPF file for writing,
// following which sue feeds nets with ports located; Speedy 
// does a steiner routing of the net and writes to the file.
// Someday soon, perhaps, location information will come from NL.
//
// Speedy also reads dspf files (produced by extraction or whatever)
// in order to do timing verification.

class DSPFFILE {
    public:
	// in sue mode, sue feeds us the port locations & we steinerize
	// the net and WRITE the informaiton to the file (as well as
	// using it internally)
	// 
	// for reading, assume that the INSTANCEs have been loaded
	// from .vg; then read nets from DSPF. The DSPF doesn't give
	// location information (at least not with current extraction
	// tools), but gives segment R and C directly, so we can do 
	// timing stuff.
	//
	// (Naturally, we COULD read logical nets from .vg and
	// INSTANCE/PORT locations from .def, or maybe from NL,
	// and do steiner stuff as previous.)
	//
		DSPFFILE(char *filename);
		~DSPFFILE();

	rc_t		read();		// assumes netlist is already loaded, maybe from nl
	rc_t		read_design();

	// .. helpers
	rc_t		read_dspfnet();
	rc_t		read_port(NET *);
	rc_t		read_node(NET *);
	rc_t		read_extconn(NET *);
	rc_t		read_capacitor(NET *);
	rc_t		read_resistor(NET *);
	void		chain_segments(SEGMENT *);

	rc_t		read_line();
	void		regularize_separators(char *);	// deal with DELIMIITER and DIVIDER
	void		unget_line();
	rc_t		skip_to_end_of_net();

	// field separators, specifable in file
	char		DIVIDER;	// default to '/'
	char		DELIMITER;	// default to '.'

	// some junky stuff for read()
	char *		name;
	FILE *		rfid;
	char *		rv;		// return value from fgets
	char 		linebuf[LINEBUFSIZE];	// ... return data
	char *		linep;		// cleaned up data
	int		lineno;
	BOOLEAN		line_was_ungot;
	int		error_count;
	
	class R {
	    public:
		R(PORT *arg_end1, PORT *arg_end2, float arg_r) 
			: end1(arg_end1), end2(arg_end2), resistance(arg_r), next(NULL) {
		}
		~R() {
		}
	
		PORT *	end1;
		PORT *	end2;
		float	resistance;

		R *	next;
	};

	R *		rlist;	// temp use while reading one dspf net

	class C {
	    public:
		C(PORT *arg_port, C* arg_next) 
			: port(arg_port), capacitance(0.0), next(arg_next) {
		}
		~C() {
		}
	
		PORT *	port;
		float	capacitance;

		C *	next;
	};

	C *		clist;	// temp use while reading one dspf net

	// write the file
	// as sue passes information from DPC netlist, compute 
	// a plausible (steiner) spanning tree and write out the
	// results.  See the header comment in sue_dspf.cc

		DSPFFILE(int fd,
		    double rconstx, double rconsty,
		    double cconstx, double cconsty, 
		    double min_rc,
		    char *string, BOOLEAN timing_tool_is_primetime);

	// cap_fudge: for some reason sometimes we tack on 
	// some extra capacitance for some nets sometimes 
	// maybe. Ask Lee.
	rc_t	write_net(NET *);
	rc_t	write_segment(NET *, SEGMENT *, PORT *left_end);

	char *	string;		// we just write this back to the file

        BOOLEAN timing_tool_is_primetime;	// flag for special stuff

	float	min_rc;		// if total net rc is less than this,
				// just write out lumped capacitance

	int	rc_index;	// reference designator in output file for
				// Rs and Cs.  Unique in file.
	int	wfd;
        FILE *  wfid;

};


#endif
