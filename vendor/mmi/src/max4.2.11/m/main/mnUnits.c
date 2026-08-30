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



/*
 * mnUnits.c --
 *
 * Gives user the option of using choosing Microns or Internal Units when
 * dimensions are given or taken on commands.
 *
 */

#ifndef lint
static char rcsid[]="$$";
#endif  not lint

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include "magic.h"
#include "main.h"
#include "message.h"
#include "geometry.h"
#include "layout.h"
#include "mgcint.h"
#include "cif.h"

/* user units - should not need to be referenced outside of this file */
#define UU_INTERNAL	0		/* internal magic units */
#define UU_MICRONS	1		/* microns (for current cifoutput style) */
int	unitsUU = UU_MICRONS;

/* if set routines check that units fall on grid (exact multiples of CIFDBRes) */
static bool mnUnitsCheck = TRUE;

/*
 * ----------------------------------------------------------------------------
 *
 * UnitsValidS --
 *
 * Check to see if string is valid dimension.
 *
 * Results:
 *	TRUE if string is OK, else FALSE
 *
 * ----------------------------------------------------------------------------
 */
    
    /* ARGSUSED */
int
UnitsValidS(char *s)
{
    switch (unitsUU)
    {
        case UU_INTERNAL:
            return StrIsInt(s);
	case UU_MICRONS:
	    {
	        char *end;
		int i;
		double d;

		d = strtod(s,&end);
		if(*end!='\0') return FALSE;

		if(!mnUnitsCheck) return TRUE;

		i = ROUND(d/CIFDBRes);
		if(ABSDIFF(i*CIFDBRes,d)>UNIT_TOLERANCE)
		{
		    MsgErrorF("%g not on %g micron design grid\n",
			   d, CIFDBRes);
		    return FALSE;
		}
	    }
	    return TRUE;

	default:
	    ASSERT(FALSE, "UnitsValidS, bad units.");
    }
    
    /* keep gcc from fussing */
    return FALSE;
}

char unitsBuf[80];
/*
 * ----------------------------------------------------------------------------
 *
 * UnitsI2S --
 *
 * Convert integer in internal units, to user unit string.
 *
 * Results:
 *	Pointer to string holding value in user units.
 *
 * Side effects:
 *      Modifies unitsBuf to appropriate value.
 *
 * ----------------------------------------------------------------------------
 */
    
    /* ARGSUSED */
char *
UnitsI2S(int i)
{
    switch (unitsUU)
    {
        case UU_INTERNAL:
            sprintf(unitsBuf,"%d",i);
	    break;
	case UU_MICRONS:
	    {
	      char *s;
	      sprintf(unitsBuf,"%4.4f",i*CIFDBRes);

	      /* strip extra 0's from fractional part */
	      for(s=unitsBuf;*s!='\0';s++);
	      for(s--;*s=='0';s--);
	      if(*s=='.') s--;
	      s++;                
	      *s = '\0';
	    }
            break;
	default:
	    ASSERT(FALSE, "UnitsI2S, bad units.");
    }

    return(unitsBuf);
}


char unitsBuf[80];
/*
 * ----------------------------------------------------------------------------
 *
 * UnitsI2D --
 *
 * Convert integer in internal units, to user double
 *
 * Results:
 *	floating point number
 *
 * ----------------------------------------------------------------------------
 */
    
    /* ARGSUSED */
double
UnitsI2D(int i)
{
    switch (unitsUU)
    {
        case UU_INTERNAL:
	  return i;
	case UU_MICRONS:
	  return i*CIFDBRes;
	default:
	    ASSERT(FALSE, "UnitsI2S, bad units.");
	    return 0; /* keep compiler happy */  
    }
}

/*
 * ----------------------------------------------------------------------------
 *
 * UnitsI2D --
 *
 * Convert integer in internal units, to user double
 *
 * Results:
 *	floating point number
 *
 * ----------------------------------------------------------------------------
 */
    
    /* ARGSUSED */
double
UnitsF2D(float f)
{
    switch (unitsUU)
    {
        case UU_INTERNAL:
	  return f;
	case UU_MICRONS:
	  return f*CIFDBRes;
	default:
	    ASSERT(FALSE, "UnitsI2S, bad units.");
	    return 0; /* keep compiler happy */  
    }
}

/*
 * ----------------------------------------------------------------------------
 *
 * UnitsS2I --
 *
 * Convert user unit string to integer in internal units.
 *
 * Results:
 *	integer in internal units
 *
 *
 * ----------------------------------------------------------------------------
 */

/* min and max coordinates allowed */
int unitsMin = -0.45 * INFINITY;
int unitsMax = 0.45 * INFINITY;

int UnitsS2I(char *s)
{
    switch (unitsUU)
    {
        case UU_INTERNAL:
            return atoi(s);
	case UU_MICRONS:
	    {
		int i;
		double d = atof(s);

		i = ROUND(d/CIFDBRes);
		if(mnUnitsCheck && ABSDIFF(i*CIFDBRes,d)> UNIT_TOLERANCE)
		{
		    MsgWarnF("%g not on %g design grid, approximating as %g\n",
			   d, CIFDBRes, i*CIFDBRes);
		}
		/* bound to avoid overflow coredumps */
		if(i<unitsMin) 
		{
		  i = unitsMin;
		  MsgWarnF("%g out of bounds, clipping to %g\n",
			   d, i*CIFDBRes);
		}
		/* bound to avoid overflow coredumps */
		if(i>unitsMax) 
		{
		  i = unitsMax;
		  MsgWarnF("%g out of bounds, clipping to %g\n",
			   d, i*CIFDBRes);
		}
		
		return(i);
	    }

        default:
	    ASSERT(FALSE, "UnitsS2I, bad units.");
    }

    /* keep gcc from fussing */
    return 0;
}

/*
 * ----------------------------------------------------------------------------
 *
 * UnitsValidSF --
 *
 * Check to see if string is valid float.
 *
 * Results:
 *	TRUE if string is OK, else FALSE
 *
 * ----------------------------------------------------------------------------
 */
int
UnitsValidSF(char *s)
{
    float f;

    return ( sscanf(s,"%g",&f) == 1 );
}

/*
 * ----------------------------------------------------------------------------
 *
 * UnitsF2S --
 *
 * Convert float in internal units, to user unit string.
 *
 * Results:
 *	Pointer to string holding value in user units.
 *
 * Side effects:
 *      Modifies unitsBuf to appropriate value.
 *
 * ----------------------------------------------------------------------------
 */
char *
UnitsF2S(float internal)
{
    switch (unitsUU)
    {
        case UU_INTERNAL:
            sprintf(unitsBuf,"%g",internal);
	    break;
	case UU_MICRONS:
	    {
	        sprintf(unitsBuf,"%g",internal*CIFDBRes);
	    }

            break;
	default:
	    ASSERT(FALSE, "UnitsF2S, bad units.");
    }

    return(unitsBuf);
}

/*
 * ----------------------------------------------------------------------------
 *
 * UnitsS2F --
 *
 * Convert user unit string to float in internal units.
 *
 * Results:
 *	integer in internal units
 *
 *
 * ----------------------------------------------------------------------------
 */
float
UnitsS2F(char *s)
{
    switch (unitsUU)
    {
        case UU_INTERNAL:
            return atoi(s);
	case UU_MICRONS:
	    {
		double d = atof(s);
		return d/CIFDBRes;
	    }
            break;
	default:
	    ASSERT(FALSE, "UnitsS2F, bad units.");
    }

    /* keep gcc from fussing */
    return 0.0;
}

/*
 * ----------------------------------------------------------------------------
 *
 * mnUnitsTclCommand --
 *
 * mn_units tcl command. 
 *
 * C Result:
 *	A standard Tcl result.
 *
 * Side effects:
 *       The value of UserUnits is modified as specified.
 *
 * ----------------------------------------------------------------------------
 */

#define mn_units_DESC "Select between microns or internal 'user' units" 

#define mn_units_DOC "
 Usage:
	mn_units [ internal | microns ]

  Result:
      <units> <resolution> 

 Specifies whether numerical  dimensions are presented to, and taken from, user 
 in Magic internal units (1 unit =  resolution) or in microns (as determined by 
 the cifoutput style in effect at the time the units are read or written).
"

static int    
mnUnitsTclCmd(ClientData clientData, Tcl_Interp *interp, int argc, char *argv[])
{
    CMD_BEGIN(interp);

    /* if more than one arg, error */
    if (argc > 2) goto usage;

    /* if there is an arg, set units accordingly */
    if (argc == 2)
    {
        if (strcmp(argv[1],"internal") == 0)
	{
	    unitsUU = UU_INTERNAL;
	}
	else if (strcmp(argv[1],"microns") == 0)
	{
	    unitsUU = UU_MICRONS;
	}   
	else
	{
	    MsgErrorF("Unrecognized units:  %s\n", argv[1]);
	    goto usage;
	}
     }

    /* return <units> <resolution> */
    switch (unitsUU)
    {
        case UU_INTERNAL:
            Tcl_AppendResult(interp, "internal 1", (char *) NULL);
	    break;
	case UU_MICRONS:
	    {
		char buf[100];

		sprintf(buf,"microns %g", CIFDBRes);
		Tcl_AppendResult(interp, buf, (char *) NULL);
	    }
	    break;
	default:
	    ASSERT(FALSE, "UnitsCmd");
    }
    CMD_RETURN(interp);
  
    usage:
 	MsgErrorF("Usage:  %s [internal | microns]\n",argv[0]); 
        CMD_RETURN(interp);
}


/*
 * ----------------------------------------------------------------------------
 *
 * MnUnitsTclInit --
 *
 * Initialize units tcl command.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Registers command(s) with tcl.
 *	
 * ----------------------------------------------------------------------------
 */

void
mnUnitsTclInit(Tcl_Interp *interp)
{
   MnDocCreateCommand(interp, 
	       "mn_units", mnUnitsTclCmd,
	       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL,
	       mn_units_DESC, mn_units_DOC);

   MnDocLinkVar(interp, "MN_UNITS_CHECK", 
		(char *) &mnUnitsCheck, TCL_LINK_BOOLEAN,
		"if set, warn on round-off error when converting
                 user units (microns) to internal database units.",
		NULL);
}



