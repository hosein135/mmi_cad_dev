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
 * DBprop.c --
 *
 * Implement properties on database cells.  Properties are name-value pairs
 * and provide a flexible way of extending the data that is stored in a
 * CellDef. 
 *
 *
 *     ********************************************************************* 
 *     * Copyright (C) 1985, 1990 Regents of the University of California. * 
 *     * Permission to use, copy, modify, and distribute this              * 
 *     * software and its documentation for any purpose and without        * 
 *     * fee is hereby granted, provided that the above copyright          * 
 *     * notice appear in all copies.  The University of California        * 
 *     * makes no representations about the suitability of this            * 
 *     * software for any purpose.  It is provided "as is" without         * 
 *     * express or implied warranty.  Export of this software outside     * 
 *     * of the United States of America may require an export license.    * 
 *     *********************************************************************
 */

#include <stdio.h>
#include "magic.h"
#include "malloc.h"
#include "geometry.h"
#include "tile.h"
#include "ihash.h"
#include "utils.h"
#include "database.h"
#include "databaseInt.h"

typedef struct property
{
    char *prop_name;
    char *prop_value;
    struct groupattribute *prop_hashLink;
} Property;


/* ----------------------------------------------------------------------------
 *
 * DBPropInitDef --
 *
 * Called when def initialized to set up property hash table.
 *
 * ----------------------------------------------------------------------------
 */
void DBPropInitDef(CellDef *def)
{
    def->cd_props = IHashInit(4, /* initial buckets */
			      OFFSET(Property,prop_name),  /* key */
			      OFFSET(Property,prop_hashLink), 
			      IHashStringPKeyHash, /* string keys */
			      IHashStringPKeyEq);	
}



/* ----------------------------------------------------------------------------
 *
 * dbPropFree --
 *
 * Free property (and contents)
 *
 * ----------------------------------------------------------------------------
 */

static void
dbPropFree(void *entry)
{
  Property *prop = entry;

  FREE(prop->prop_name);
  FREE(prop->prop_value);
  FREE_TAG(prop,"Property");
}


/* ----------------------------------------------------------------------------
 *
 * DBPropSet --
 *
 * Set property value.
 *
 * (if value is NULL, delete property) 
 *
 * ----------------------------------------------------------------------------
 */

void
DBPropSet(CellDef *def, char *name, char *value)
{
  Property *prop = 
    (Property *) IHashLookUp(def->cd_props, &name);

  /* if no value given, delete the property */
  if(!value)
  {
    if(prop)
    {
      dbUndoPropSet(def,name,prop->prop_value, NULL);
      IHashDelete(def->cd_props, prop);
      dbPropFree(prop);
    }

    return;
  }
    
  if(prop)
  {
    dbUndoPropSet(def,name,prop->prop_value, value);
    (void) StrDup(&(prop->prop_value), value);
    return;
  }

  dbUndoPropSet(def,name, NULL, value);
  CALLOC_TAG(Property *, prop, sizeof(*prop), "Property");
  prop->prop_name = StrDup(NULL, name);
  prop->prop_value = StrDup(NULL, value);

  IHashAdd(def->cd_props, prop);
}


/* ----------------------------------------------------------------------------
 *
 * DBPropGet--
 *
 * get property value
 *
 * ----------------------------------------------------------------------------
 */

char *
DBPropGet(CellDef *def, char *name)
{
  Property *prop = 
    (Property *) IHashLookUp(def->cd_props, &name);

  if(!prop) return NULL;
  return prop->prop_value;
}


/* ----------------------------------------------------------------------------
 *
 * DBPropEnum --
 *
 * call supplied func on each property in def
 *
 * ----------------------------------------------------------------------------
 */
static void (*dbPropClientFunc)();

static void dbPropEnumFunc(void *entry)
{
  Property *prop = entry;

  (*dbPropClientFunc)(prop->prop_name, prop->prop_value);
}

void DBPropEnum(CellDef *def, void (*func)())
{
  dbPropClientFunc = func;
  IHashEnum(def->cd_props, dbPropEnumFunc);
}


/* ----------------------------------------------------------------------------
 *
 * DBPropClearDef --
 *
 * clear all properties and reclaim associated storage
 * (used to when restoring cell to initial (empty) state) 
 *
 * ----------------------------------------------------------------------------
 */
void DBPropClearDef(CellDef *def)
{
  IHashEnum(def->cd_props, dbPropFree);
  IHashClear(def->cd_props);
}


/* ----------------------------------------------------------------------------
 *
 * DBPropFreeDef --
 *
 * Free all properties and reclaim associated storage
 * (used when deallocating celldef)
 *
 * ----------------------------------------------------------------------------
 */
void DBPropFreeDef(CellDef *def)
{
  IHashEnum(def->cd_props, dbPropFree);
  IHashFree(def->cd_props);
}

/*
 * ----------------------------------------------------------------------------
 *
 * DBPropsQ --
 *
 * return TRUE iff there are any properties associated with cell
 *
 *
 * ----------------------------------------------------------------------------
 */

bool
DBPropsQ(CellDef *def)
{
  return (IHashEntries(def->cd_props)>0); 
}


/* 
 * ==============================================================================
 *
 * PROPERTY I/O
 *
 * ==============================================================================
 */

FILE *dbPropWriteFile;
#define OUTS(s)\
{\
     if (fputs(s,dbPropWriteFile) == EOF) goto ioerror;\
     DBFileOffset += strlen(s);\
}



/*
 * ----------------------------------------------------------------------------
 *
 * dbPropertiesWrite --
 *
 * Write contents of propertys section for given def.
 *
 * Results:
 *	Returns TRUE normally, or FALSE on error or EOF.
 *
 * Side effects:
 *	See above.
 *
 * ----------------------------------------------------------------------------
 */

/* helper func,  write property */
static void dbPropWriteFunc(void *entry)
{
  Tcl_DString ds;
  Property *prop = (Property *) entry;

  Tcl_DStringInit(&ds);
  Tcl_DStringAppend(&ds,"\t",-1);
  Tcl_DStringAppendElement(&ds,prop->prop_name);
  Tcl_DStringAppendElement(&ds,prop->prop_value);
  Tcl_DStringAppend(&ds,"\n",-1);
  OUTS(Tcl_DStringValue(&ds));
  Tcl_DStringFree(&ds);

  /* TODO handle errors */
ioerror: 
  Tcl_DStringFree(&ds);
}

bool
dbPropertiesWrite(CellDef *def, FILE *f)
{
  dbPropWriteFile = f;
  IHashEnum(def->cd_props, dbPropWriteFunc);

  return TRUE;
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbPropertiesRead --
 *
 * Starting with the line "SECTION PROPERTIES {", read the PROPERTIES section.
 *
 * Results:
 *	Returns TRUE normally, or FALSE on error or EOF.
 *
 * ----------------------------------------------------------------------------
 */

/* helper func, read a single property */
static __inline__ bool
dbPropRead(CellDef *def, char *lineBuf, int bufSize, FILE *f)
{
  int argc;
  char **argv;
  int r;
  char *complete;
  Tcl_DString completeDS;  /* used to assemble complete name/value pair
		        * (handles embedded newlines)
			*/
  bool ds = FALSE;
  static Tcl_Interp *privInterp = NULL;

  /* use private interpeter so we don't mess up result codes in real interp */
  if(!privInterp) privInterp = Tcl_CreateInterp();

  /* assemble complete name/value pair 
   * NOTE:  any newlines must be internal to name or value, not between them
   */
  if(Tcl_CommandComplete(lineBuf))
  {
    complete = lineBuf;
  }
  else
  {
      ds = TRUE;
      Tcl_DStringInit(&completeDS);
      complete = Tcl_DStringAppend(&completeDS, lineBuf, -1);
      while (!Tcl_CommandComplete(complete))
      {
          if(!dbReadNextLine(lineBuf, bufSize, f)) goto parseError;
          complete = Tcl_DStringAppend(&completeDS, lineBuf, -1);
      }
  }

  /* parse complete string into (newly malloced) elements */
  r = Tcl_SplitList(privInterp, complete, &argc, &argv);

  if(r != TCL_OK)
  {
    MsgErrorF("%s\n", privInterp->result);
    Tcl_ResetResult(privInterp);
    goto parseError;
  }

  if(argc!=2)
  {
    MsgErrorF("wrong number of arguments in property name/value pair\n");
    goto parseError;
  }

  DBPropSet(def, argv[0], argv[1]);

  free(argv);  /* using free instead of FREE here since argv was malloced by tcl */
  if(ds) Tcl_DStringFree(&completeDS);
  return TRUE;

parseError:
    MsgErrorF("parse error in property:  '%s'\n",
	      complete);

    free(argv);  /* using free instead of FREE here since argv was malloced by tcl */
    if(ds) Tcl_DStringFree(&completeDS);
    return FALSE;
}

bool
dbPropertiesRead(CellDef *def, 
		        /* def being read */ 
	     char *lineBuf, 
               		/* Line buffer */
	     int bufSize, 
            		/* Size of lineBuf */	     
	     FILE *f)
            		/* Input file */
{
    while (dbReadNextLine(lineBuf, bufSize, f))
    {
      if (lineBuf[0]== '}' && 
	  strcmp(lineBuf,"} SECTION PROPERTIES\n") == 0) return TRUE;
       if(!dbPropRead(def,lineBuf, bufSize, f)) return FALSE;
    }
    return (FALSE);
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbPropertiesFree --
 *
 * Delete all properties associated with def, and reclaim storage.
 *
 * NOTE:  Assumes paint planes already cleared (so no pointers left to groups).
 *
 * ----------------------------------------------------------------------------
 */

void
dbPropertiesFree(CellDef *cellDef)
{
  fprintf(stderr,"TODO dbPropertiesFree()\n");
}
