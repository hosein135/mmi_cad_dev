/* 
 *     ********************************************************************* 
 *     * Copyright (C) 1988, 1990 Stanford University.                     * 
 *     * Permission to use, copy, modify, and distribute this              * 
 *     * software and its documentation for any purpose and without        * 
 *     * fee is hereby granted, provided that the above copyright          * 
 *     * notice appear in all copies.  Stanford University                 * 
 *     * makes no representations about the suitability of this            * 
 *     * software for any purpose.  It is provided "as is" without         * 
 *     * express or implied warranty.  Export of this software outside     * 
 *     * of the United States of America may require an export license.    * 
 *     ********************************************************************* 
 */

/*
 * The routines in this file handle network input (from sim files).
 * The input routine "rd_network" replaces the work formerly done by presim.
 * This version differs from the former in the following:
 *  1. voltage drops across transistors are ignored (assumes transistors
 *     driven by nodes with voltage drops have the same resistance as those
 *     driven by a full swing).
 *  2. static power calculations not performed (only useful for nmos anyhow).
 */

#include <stdio.h>
#include "defs.h"
#include "net.h"
#include "globals.h"
#include "net_macros.h"


#define LSIZE		2000		/* size for input line buffer */
#define	MAXARGS		20		/* max. # of arguments per line */


public	nptr   VDD_node;		/* power supply nodes */
public	nptr   GND_node;

public	lptr   on_trans;		/* always on transistors */

public	int    nnodes;			/* number of actual nodes */
public	int    naliases;		/* number of aliased nodes */
public	int    ntrans[ NTTYPES ];	/* number of txtors indexed by type */

public	lptr   freeLinks = NULL;	/* free list of Tlist structs */
public	tptr   freeTrans = NULL;	/* free list of Transistor structs */
public	nptr   freeNodes = NULL;	/* free list of Node structs */

public	tptr   tcap = NULL;		/* list of capacitor-transistors */

private	int    lineno;			/* current input file line number */
private	char   *simfname;		/* current input filename */
private	int    nerrs = 0;		/* # of erros found in sim file */
private	int    isBinFile;		/* TRUE binary file, FALSE sim file */

private	tptr   rd_tlist;		/* list of transistors just read */

public
#define	MIN_CAP		0.0005		/* minimum node capacitance (in pf) */


#define	WARNING		0
#define	WARN		1
#define	MAX_ERRS	20
#define	FATAL		(MAX_ERRS + 1)

private	char    bad_argc_msg[] = "Wrong number of args for '%c' (%d)\n";

#define	BAD_ARGC( CMD, ARGC, ARGV )			\
  {							\
    error( simfname, lineno, bad_argc_msg, CMD, ARGC );	\
    PrArgs( ARGC, ARGV );				\
    CheckErrs( WARN );					\
    return;						\
  }							\


private void PrArgs( argc, argv )
  int   argc;
  char  *argv[];
  {
    while( argc-- != 0 )
      (void) fprintf( stderr, "%s ", *argv++ );
    (void) fputs( "\n", stderr );
  }


private void CheckErrs( n )
  {
    nerrs += n;
    if( nerrs > MAX_ERRS )
      {
	if( n != FATAL )
	    (void) fprintf( stderr, "Too many errors in sim file <%s>\n",
	      simfname );
	exit( 1 );
      }
  }



/*
 * Traverse the transistor list and add the node connection-list.  We have
 * to be careful with ALIASed nodes.  Note that transistors with source/drain
 * connected VDD and GND nodes are not linked.
 */
private nptr connect_txtors()
  {
    register tptr  t, tnext;
    register nptr  gate, src, drn, nd_list;
    register int   type;
    register long  visited;

    visited = VISITED;
    nd_list = NULL;

    for( t = rd_tlist; t != NULL; t = tnext )
      {
	tnext = t->scache.t;
	for( gate = t->gate; gate->nflags & ALIAS; gate = gate->nlink);
	for( src = t->source; src->nflags & ALIAS; src = src->nlink );
	for( drn = t->drain; drn->nflags & ALIAS; drn = drn->nlink );

	t->gate = gate;
	t->source = src;
	t->drain = drn;

	type = t->ttype;
	t->state = ( type & ALWAYSON ) ? WEAK : UNKNOWN;
	t->tflags = 0;

	ntrans[ type ]++;
	if( src == drn or (src->nflags & drn->nflags & POWER_RAIL) )
	  {
	    t->ttype |= TCAP;		/* transistor is just a capacitor */
	    LINK_TCAP( t );
	  }
	else
	  {
		/* do not connect gate if ALWAYSON since they do not matter */
	    if( t->ttype & ALWAYSON )
	      {
		CONNECT( on_trans, t );
	      }
	    else
	      {
		CONNECT( t->gate->ngate, t );
	      }

	    if( not (src->nflags & POWER_RAIL) )
	      {
		CONNECT( src->nterm, t );
		LINK_TO_LIST( src, nd_list, visited );
	      }
	    if( not (drn->nflags & POWER_RAIL) )
	      {
		CONNECT( drn->nterm, t );
		LINK_TO_LIST( drn, nd_list, visited );
	      }
	  }
      }

    return( nd_list );
  }


/*
 * node area and perimeter info (N sim command).
 */
private void node_info( targc, targv )
  int   targc;
  char  *targv[];
  {
    register nptr  n;

    if( targc != 8 )
	BAD_ARGC( 'N', targc, targv );

    n = GetNode( targv[1] );

    n->ncap += 	atof( targv[4] ) * (CMA * LAMBDA2) +
		atof( targv[5] ) * (CPA * LAMBDA2) +
		atof( targv[6] ) * (CDA * LAMBDA2) +
		atof( targv[7] ) * 2.0 * (CDP * LAMBDA);
  }


/*
 * new format node area and perimeter info (M sim command).
 */
private void nnode_info( targc, targv )
  int   targc;
  char  *targv[];
  {
    register nptr  n;

    if( targc != 14 )
	BAD_ARGC( 'M', targc, targv );

    n = GetNode( targv[1] );

    n->ncap +=	atof( targv[4] ) * (CM2A * LAMBDA2) +
		atof( targv[5] ) * 2.0 * (CM2P * LAMBDA) +
		atof( targv[6] ) * (CMA * LAMBDA2) +
		atof( targv[7] ) * 2.0 * (CMP * LAMBDA) +
		atof( targv[8] ) * (CPA * LAMBDA2) +
		atof( targv[9] ) * 2.0 * (CPP * LAMBDA) +
		atof( targv[10] ) * (CDA * LAMBDA) +
		atof( targv[11] ) * 2.0 * (CDP * LAMBDA) +
		atof( targv[12] ) * (CPDA * LAMBDA2) +
		atof( targv[13] ) * 2.0 * (CPDP * LAMBDA);
  }


/*
 * new transistor.  Implant specifies type.
 * AreaPos specifies the argument number that contains the area (if any).
 */
private void newtrans( implant, targc, targv )
  int   implant;
  int   targc;
  char  *targv[];
  {
    nptr           gate, src, drn, ntemp;
    long           x, y, width, length;
    double         cap;
    register tptr  t;

    if( implant == RESIST )
      {
	if( targc != 4 )
	    BAD_ARGC( 'r', targc, targv );

	gate = VDD_node;
	src = GetNode( targv[1] );
	drn = GetNode( targv[2] );

	length = atof( targv[3] ) * LAMBDACM;
	width = 0;
      }
    else
      {
	if( targc < 4 or targc > 11 )
	    BAD_ARGC( targv[0][0], targc, targv );

	gate = GetNode( targv[1] );
	src = GetNode( targv[2] );
	drn = GetNode( targv[3] );

	if( targc > 5 )
	  {
	    length = atof( targv[4] ) * LAMBDACM;
	    width = atof( targv[5] ) * LAMBDACM;
	    if( width <= 0 or length <= 0 )
	      {
		error( simfname, lineno,
		  "Bad transistor width=%g or length=%g\n", width, length );
		return;
	      }
	    if( targc > 7 )
	      {
		x = atoi( targv[6] );
		y = atoi( targv[7] );
	      }
	  }
	else
	    width = length = 2 * LAMBDACM;

	cap = length * width * CTGA;
      }

    NEW_TRANS( t );			/* create new transistor */

    t->ttype = implant;
    t->gate = gate;
    t->source = src;
    t->drain = drn;

    if( targc > 7 )
      {
	t->x.pos = x;
	t->y.pos = y;
	EnterPos( t, TRUE );		/* Enter transistor position */
      }
    else
	EnterPos( t, FALSE );		/* Enter transistor position */

    t->scache.t = rd_tlist;		/* link it to the list */
    rd_tlist = t;

    t->r = requiv( implant, width, length );

		/* update node capacitances  */
    gate->ncap += cap;

    if( config_flags & TDIFFCAP )
      {
	cap = CTDW * width + CTDE;
	src->ncap += cap;
	drn->ncap += cap;
      }
  }
		

/*
 * accept a bunch of aliases for a node (= sim command).
 */
private void alias( targc, targv )
  int   targc;
  char  *targv[];
  {
    register nptr  n, m;
    register int   i;

    if( targc < 3 )
	BAD_ARGC( '=', targc, targv );

    n = GetNode( targv[1] );

    for( i = 2; i < targc; i++ )
      {
	m = GetNode( targv[i] );
	if( m == n )
	    continue;

	if( m->nflags & POWER_RAIL )
	    SWAP_NODES( m, n );

	if( m->nflags & POWER_RAIL )
	  {
	    error( simfname, lineno, "Can't alias the power supplies\n" );
	    continue;
	  }

	n->ncap += m->ncap;

	m->nlink = n;
	m->nflags |= ALIAS;
	m->ncap = 0.0;
	nnodes--;
	naliases++;
      }
  }


/*
 * node threshold voltages (t sim command).
 */
private void nthresh( targc, targv )
  int   targc;
  char  *targv[];
  {
    register nptr  n;

    if( targc != 4 )
	BAD_ARGC( 't', targc, targv );

    n = GetNode( targv[1] );
    n->vlow = atof( targv[2] );
    n->vhigh = atof( targv[3] );
  }


/*
 * User delay for a node (D sim command).
 */
private void ndelay( targc, targv )
  int   targc;
  char  *targv[];
  {
    register nptr  n;

    if( targc != 4 )
	BAD_ARGC( 'D', targc, targv );

    n = GetNode( targv[1] );
    n->nflags |= USERDELAY;
    n->tplh = ns2d( atof( targv[2] ) );
    n->tphl = ns2d( atof( targv[3] ) );
  }


/*
 * add capacitance to a node (c sim command).
 */
private void ncap( targc, targv )
  int   targc;
  char  *targv[];
  {
    register nptr n, m;
    float         cap;

    if( targc == 3 )
      {
	n = GetNode( targv[1] );
	n->ncap += atof( targv[2] );
      }
    else if( targc == 4 )		/* two terminal caps	*/
      {
	cap = atof( targv[3] ) / 1000;		/* ff to pf conversion */
	n = GetNode( targv[1] );
	m = GetNode( targv[2] );
	if( n != m )			/* add cap to both nodes */
	  {
	    if( m != GND_node )	m->ncap += cap;
	    if( n != GND_node )	n->ncap += cap;
	  }
	else if( n == GND_node )	/* same node, only GND makes sense */
	    n->ncap += cap;
      }
    else
	BAD_ARGC( 'c', targc, targv );
  }


/*
 * parse input line into tokens, filling up carg and setting targc
 */
private int parse_line( line, carg )
  register char  *line;
  register char  **carg;
  {
    register char  ch;
    register int   targc;

    targc = 0;
    while( ch = *line++ )
      {
	if( ch <= ' ' )
	    continue;
	targc++;
	*carg++ = line - 1;
	while( *line > ' ' )
	    line++;
	if( *line )
	    *line++ = '\0';
      }
    *carg = 0;
    return( targc );
  }


private	int    R_error = FALSE;
private	int    A_error = FALSE;


private int input_sim( simfile )
  char  *simfile;
  {
    FILE  *fin;
    char  line[LSIZE];
    char  *targv[MAXARGS];	/* tokens on current command line */
    int   targc;		/* number of args on command line */
    long  offset;		/* state of previously opened file */
    int   olineno;

    if( (fin = fopen( simfile, "r" )) == NULL )
      {
	lprintf( stderr, "cannot open '%s' for sim input\n", simfile );
	return( FALSE );
      }
    simfname = simfile;
    lineno = 0;

    while( fgetline( line, LSIZE, fin ) != NULL )
      {
	lineno++;
	targc = parse_line( line, targv );
	if( targv[0] == NULL )
	    continue;
	switch( targv[0][0] )
	  {
	    case '@' :
		if( targc != 2 )
		  {
		    error( simfname, lineno, bad_argc_msg, '@', targc );
		    CheckErrs( WARN );
		    break;
		  }
		offset = ftell( fin );
		olineno = lineno;
		(void) fclose( fin );
		(void) input_sim( targv[1] );
		if( (fin = fopen( simfile, "r" )) == NULL )
		  {
		    error( simfname, lineno, "can't re-open sim file '%s'\n",
		       simfile );
		    CheckErrs( WARN );
		    return( FALSE );
		  }
		(void) fseek( fin, offset, 0 );
		simfname = simfile;
		lineno = olineno;
		break;

	    case '|' :
		break;
	    case 'e' :
	    case 'n' :
		newtrans( NCHAN, targc, targv );
		break;
	    case 'p' :
		newtrans( PCHAN, targc, targv );
		break;
	    case 'd' :
		newtrans( DEP, targc, targv );
		break;
	    case 'r' :
		newtrans( RESIST, targc, targv );
		break;
	    case 'N' :
		node_info( targc, targv );
		break;
	    case 'M' :
		nnode_info( targc, targv );
		break;
	    case 'c' :
	    case 'C' :
	    	ncap( targc, targv );
		break;
	    case '=' :
	    	alias( targc, targv );
		break;
	    case 't' :
	    	nthresh( targc, targv );
		break;
	    case 'D' : 
	    	ndelay( targc, targv );
		break;
	    case 'R' : 
		if( not R_error )	/* only warn about this 1 time */
		  {
		    lprintf( stderr,
		      "%s: Ignoring lumped-resistance ('R' construct)\n",
		      simfname );
		    R_error = TRUE;
		  }
		break;
	    case 'A' :
		if( not A_error )	/* only warn about this 1 time */
		  {
		    lprintf( stderr,
		      "%s: Ignoring attribute-line ('A' construct)\n",
		      simfname );
		    A_error = TRUE;
		  }
		break;
	    case '<' : 
		if( lineno == 1 and rd_netfile( fin, line ) )
		  {
		    (void) fclose( fin );
		    return( TRUE );
		  }
		/* fall through if rd_netfile returns FALSE */
	    default :
		error( simfname, lineno, "Unrecognized input line (%s)\n",
		  targv[0] );
		CheckErrs( WARN );
	  }
      }
    (void) fclose( fin );
    return( FALSE );
  }



private void init_counts()
  {
    register int  i;

    for( i = 0; i < NTTYPES; i++ )
	ntrans[i] = 0;
    nnodes = naliases = 0;
  }


public int rd_network( simfile )
  char  *simfile;
  {
    static int      firstcall = 1;

    if( firstcall )
      {
	rd_tlist = NULL;
	init_hash();
	init_counts();
	init_listTbl();

	VDD_node = GetNode( "Vdd" );
	VDD_node->npot = HIGH;
	VDD_node->nflags |= (INPUT | POWER_RAIL);
	VDD_node->head.inp = 1;
	VDD_node->head.val = HIGH;
	VDD_node->head.punt = 0;
	VDD_node->head.time = 0;
	VDD_node->head.t.r.rtime = VDD_node->head.t.r.delay = 0;
	VDD_node->head.next = last_hist;
	VDD_node->curr = &(VDD_node->head);

	GND_node = GetNode( "Gnd" );
	GND_node->npot = LOW;
	GND_node->nflags |= (INPUT | POWER_RAIL);
	GND_node->head.inp = 1;
	GND_node->head.val = LOW;
	GND_node->head.punt = 0;
	GND_node->head.time = 0;
	GND_node->head.t.r.rtime = GND_node->head.t.r.delay = 0;
	GND_node->head.next = last_hist;
	GND_node->curr = &(GND_node->head);

	NEW_TRANS( tcap );
	tcap->scache.t = tcap->dcache.t = tcap;
	tcap->x.pos = 0;

	firstcall = 0;
      }
    nerrs = 0;

    isBinFile = input_sim( simfile );
    if( nerrs > 0 )
	exit( 1 );
  }


public void pTotalNodes()
  {
    lprintf( stdout, "%d nodes", nnodes );
    if( naliases != 0 )
	lprintf( stdout, ", %d aliases", naliases );
    lprintf( stdout, "; " );
  }


public void pTotalTxtors()
  {
    int  i;

    lprintf( stdout, "transistors:" );
    for( i = 0; i < NTTYPES; i++ )
	if( ntrans[i] != 0 )
	    lprintf( stdout, " %s=%d", ttype[i], ntrans[i] );
    if( tcap->x.pos != 0 )
	lprintf( stdout, " shorted=%d", tcap->x.pos );
    lprintf( stdout, "\n" );
  }


public void ConnectNetwork()
  {
    nptr  ndlist;

    pTotalNodes();

    ndlist = ( isBinFile ) ? bin_connect_txtors() : connect_txtors();

    make_parallel( ndlist );
    make_stacks( ndlist );

    pTotalTxtors();
    pParallelTxtors();
    pStackedTxtors();
  }
