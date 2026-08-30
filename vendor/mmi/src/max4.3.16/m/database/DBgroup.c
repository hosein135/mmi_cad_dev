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
 * DBgroup.c --
 *
 * Implements groups.
 */

static char rcsid[] = "$Header$";

#include <stdio.h>
#include "magic.h"
#include "database.h"
#include "databaseInt.h"
#include "memory.h"
#include "utils.h"

/* 
 * ==============================================================================
 *
 * GROUP TILE TYPES
 *
 * ==============================================================================
 */


/* ----------------------------------------------------------------------------
 *
 * DBGroupTileTypesMask --
 *
 * returns mask of all tile types of tile (all groups)
 *
 * ----------------------------------------------------------------------------
 */
TileTypeBitMask *DBGroupTileTypesMask(Tile *tile)
{
  static TileTypeBitMask mask;
  GroupList *gl;
  int i = 0;
  char *s;

  TTMaskZero(&mask);

  /*** SINGLE GROUP CASE ***/
  if (!DBisSetTileFlag(tile,TF_MULTIGROUP))
  {
    TTMaskSetType(&mask,DBgetTileType(tile));
    return &mask;
  }

  /*** MULTI GROUP CASE ***/
  for(gl=(GroupList *) TiGetGroups(tile);
      gl;
      gl=gl->gl_next)
  {
    TTMaskSetType(&mask,gl->gl_type);
  }
  return &mask;
}


/* ----------------------------------------------------------------------------
 *
 * DBGroupTileTypes2S --
 *
 * convert tiles groups/types to string (writes to buf)
 *
 * ----------------------------------------------------------------------------
 */
void DBGroupTileTypes2S(char *buf, int bufSize, Tile *tile)
{
  GroupList *gl;
  int i = 0;
  char *s;

  /*** SINGLE GROUP CASE ***/
  if (!DBisSetTileFlag(tile,TF_MULTIGROUP))
  {
    Group *group = (Group *) TiGetGroups(tile);

    /* copy group id */
    if(group)
    {
      for(s=group->g_name;*s;s++)
      {
	if(i<bufSize-2) buf[i++]=*s;
      }
      if(i<bufSize-2) buf[i++]=':';
    }

    /* copy type */
    for(s=DBTypeShortName(DBgetTileType(tile)); *s; s++)
    {
      if(i<bufSize-2) buf[i++]=*s;
    }
    buf[i]='\0';
    return;
  }

  /*** MULTI GROUP CASE ***/
  for(gl=(GroupList *) TiGetGroups(tile);
      gl;
      gl=gl->gl_next)
  {
    /* copy group id */
    if(gl->gl_group)
    {
      for(s=gl->gl_group->g_name;*s;s++)
      {
	if(i<bufSize-2) buf[i++]=*s;
      }
      if(i<bufSize-2) buf[i++]=':';
    }

    /* copy type */
    for(s=DBTypeShortName(gl->gl_type); *s; s++)
    {
      if(i<bufSize-2) buf[i++]=*s;
    }
    if(i<bufSize-2) buf[i++]=' ';
  }
  buf[i]='\0';
}

/* helper func for DBsetTypeG() (in database.h) */
extern void DBsetTypeG_multiGroup(Tile *tile, TileType newType, Group *group)
{
  GroupList *gl, *glPrev;

  ASSERT(DBisSetTileFlag(tile,TF_MULTIGROUP),"DBsetTypeG_multiGroup");

  /* look up group in list */
  for(gl=(GroupList *) TiGetGroups(tile),glPrev=NULL; gl; glPrev=gl,gl=gl->gl_next)
  {
      if(gl->gl_group == group) break;
  }
  if(!gl) glPrev = NULL;

  /* "erase" case */
  if(newType == TT_SPACE)
  {

      if(glPrev)
      {
         glPrev->gl_next = gl->gl_next;
         goto deleted;
         
      }

      if(gl)
      {
         TiSetGroups(tile,(Group *) gl->gl_next);
         goto deleted;
      }
      return;

deleted:
      FREE(gl);
      gl=(GroupList *) TiGetGroups(tile);
      DBsetTileType(tile,gl->gl_type);
      if(gl->gl_next == NULL) 
      {
          TiSetGroups(tile,gl->gl_group);
	  DBresetTileFlag(tile,TF_MULTIGROUP);
          FREE(gl);
      }
      return;
    }

    /* "group found" case */
    if(gl)
    {
        gl->gl_type = newType;
        if(!glPrev) DBsetTileType(tile,newType);
        return;
    }

    /* "add group" case */
    {
        GroupList *new;
        MALLOC(GroupList *, new, sizeof (GroupList));
	new->gl_type = newType;
	new->gl_group = group;

        gl=(GroupList *) TiGetGroups(tile);

	/* add to head of group list, unless head is in null group */
        new->gl_next = gl;
        TiSetGroups(tile, (Group *) new);
        DBsetTileType(tile, newType);

        return;
    }
}

/* 
 * ==============================================================================
 *
 * GROUP CLASSES
 *
 * ==============================================================================
 */

/* table of group classes */
static  IHashTable *dbGroupClassTable=NULL;


/* ----------------------------------------------------------------------------
 *
 * dbGroupClassTableInit --
 *
 * Called first time group type table referenced.
 *
 * ----------------------------------------------------------------------------
 */
static void dbGroupClassTableInit()
{
    dbGroupClassTable = IHashInit(4, /* initial buckets */
				       OFFSET(GroupClass,gc_name),  /* key */
				       OFFSET(GroupClass,gc_hashLink), 
				       IHashStringPKeyHash, /* string keys */
				       IHashStringPKeyEq);	
}


/* ----------------------------------------------------------------------------
 *
 * DBGroupClassNew --
 *
 * Define a new group class
 *
 * Returns pointer to the new group class
 *
 * ----------------------------------------------------------------------------
 */

GroupClass *
DBGroupClassNew(char *name)
{
  GroupClass *new;

  if(!dbGroupClassTable) dbGroupClassTableInit();

  CALLOC(GroupClass *, new, sizeof(GroupClass));
  new->gc_name = StrDup(NULL, name);
  IHashAdd(dbGroupClassTable, new);

  return new;
}


/* ----------------------------------------------------------------------------
 *
 * DBGroupClassFromName--
 *
 * Lookup named group class
 *
 * Returns pointer to named group (0 if not found)
 *
 * ----------------------------------------------------------------------------
 */

GroupClass *
DBGroupClassFromName(char *name)
{
  if(!dbGroupClassTable) dbGroupClassTableInit();

  return IHashLookUp(dbGroupClassTable, &name);
}

/* 
 * ==============================================================================
 *
 * GROUP ATTRIBUTES
 *
 * ==============================================================================
 */

typedef struct groupattribute
{
    char *ga_name;
    char *ga_value;
    struct groupattribute *ga_hashLink;
} GroupAttribute;


/* ----------------------------------------------------------------------------
 *
 * dbGroupAttributeInit --
 *
 * Called when group initialized
 *
 * ----------------------------------------------------------------------------
 */
static void dbGroupAttributeInit(Group *group)
{
    group->g_attributes = 
      (ClientData) IHashInit(4, /* initial buckets */
			     OFFSET(GroupAttribute,ga_name),  /* key */
			     OFFSET(GroupAttribute,ga_hashLink), 
			     IHashStringPKeyHash, /* string keys */
			     IHashStringPKeyEq);	
}


/* ----------------------------------------------------------------------------
 *
 * DBGroupAttributeSet --
 *
 * Set attribute value.
 *
 * ----------------------------------------------------------------------------
 */

void
DBGroupAttributeSet(Group *group, char *name, char *value)
{
  GroupAttribute *ga = 
    (GroupAttribute *) IHashLookUp((IHashTable *) group->g_attributes, &name);

  if(ga)
  {
    if(ga->ga_value) FREE(ga->ga_value);
    (void) StrDup(&(ga->ga_value), value);
    return;
  }

  CALLOC(GroupAttribute *, ga, sizeof(GroupAttribute));
  ga->ga_name = StrDup(NULL, name);
  ga->ga_value = StrDup(NULL, value);

  IHashAdd((IHashTable *) group->g_attributes, ga);
}


/* ----------------------------------------------------------------------------
 *
 * DBGroupAttributeGet--
 *
 * get attribute value
 *
 * ----------------------------------------------------------------------------
 */

char *
DBGroupAttributeGet(Group *group, char *name)
{
  GroupAttribute *ga = 
    (GroupAttribute *) IHashLookUp((IHashTable *) group->g_attributes, &name);

  if(!ga) return NULL;
  return ga->ga_value;
}

/* 
 * ==============================================================================
 *
 * GROUP CREATION AND LOOKUP
 *
 * ==============================================================================
 */


/* ----------------------------------------------------------------------------
 *
 * DBGroupNew --
 *
 * Add a group to a cell def.
 *
 * Returns pointer to the new group
 *
 * ----------------------------------------------------------------------------
 */

Group *
DBGroupNew(CellDef *cell, char *name)
{
  Group *new;

  CALLOC(Group *, new, sizeof(Group));
  new->g_name = StrDup(NULL, name);
  dbGroupAttributeInit(new);
  IHashAdd(cell->cd_groupTable, new);

  return new;
}


/* ----------------------------------------------------------------------------
 *
 * DBGroupFromName--
 *
 * Lookup named group
 *
 * Returns pointer to named group (0 if not found)
 *
 * ----------------------------------------------------------------------------
 */

Group *
DBGroupFromName(CellDef *cell, char *name)
{
  return IHashLookUp(cell->cd_groupTable, &name);
}

/* 
 * ==============================================================================
 *
 * GROUP I/O
 *
 * ==============================================================================
 */

FILE *dbGroupsWriteFile;
#define OUTS(s)\
{\
     if (fputs(s,dbGroupsWriteFile) == EOF) goto ioerror;\
     DBFileOffset += strlen(s);\
}

/* write group attribute */
static void dbGroupsWriteFunc2(void *entry)
{
  Tcl_DString ds;
  GroupAttribute *ga = (GroupAttribute *) entry;

  Tcl_DStringInit(&ds);
  Tcl_DStringAppend(&ds,"\t",-1);
  Tcl_DStringAppendElement(&ds,ga->ga_name);
  Tcl_DStringAppendElement(&ds,ga->ga_value);
  Tcl_DStringAppend(&ds,"\n",-1);
  OUTS(Tcl_DStringValue(&ds));
  Tcl_DStringFree(&ds);

  /* TODO handle errors */
ioerror: 
  Tcl_DStringFree(&ds);
}

/* write group */
static void dbGroupsWriteFunc(void *entry)
{
  Group *group = (Group *) entry;

  if(group->g_class) 
  {
    OUTS(group->g_class->gc_name); 
    OUTS(" "); 
    OUTS(group->g_name);
    OUTS(" {\n");
    IHashEnum((IHashTable *) group->g_attributes, dbGroupsWriteFunc2);
    OUTS("}\n");
  }

  /* TODO handle errors */
ioerror: ;
}

/* write groups */
bool
dbGroupsWrite(CellDef *def, FILE *f)
{
  dbGroupsWriteFile = f;
  IHashEnum(def->cd_groupTable, dbGroupsWriteFunc);

  return TRUE;
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbGroupsRead --
 *
 * Starting with the line "SECTION GROUPS {", read the GROUPS section.
 *
 * Results:
 *	Returns TRUE normally, or FALSE on error or EOF.
 *
 * Side effects:
 *	See above.
 *
 * ----------------------------------------------------------------------------
 */

/* helper func, read group attribute */
static __inline__ bool
dbGroupReadAttribute(Group *group, char *lineBuf, int bufSize, FILE *f)
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
    MsgErrorF("wrong number of arguments in attribute/value pair\n");
    goto parseError;
  }

  DBGroupAttributeSet(group, argv[0], argv[1]);

  free(argv);  /* using free instead of FREE here since argv was malloced by tcl */
  if(ds) Tcl_DStringFree(&completeDS);
  return TRUE;

parseError:
    MsgErrorF("parse error in group %s %s:  '%s'\n",
	      group->g_class->gc_name,
	      group->g_name,
	      complete);

    free(argv);  /* using free instead of FREE here since argv was malloced by tcl */
    if(ds) Tcl_DStringFree(&completeDS);
    return FALSE;
}

/* helper func - reads one group */
static __inline__ bool
dbGroupRead(CellDef *cellDef, 
                     	/* Cell whose groups are being read */
	     char *lineBuf, 
               		/* Line buffer */
	     int bufSize, 
            		/* Size of lineBuf */	     
	     FILE *f)
            		/* Input file */
{
    char className[1024];
    char id[1024];
    GroupClass *class;
    Group *group;

    /* read header line */
    if (sscanf(lineBuf, "%1023s %1023s {", className, id) != 2)
    {
	MsgErrorF("Bad group header: '%s'\n", lineBuf);
	return (FALSE);
    }

    /* look up class */
    class = DBGroupClassFromName(className);
    if(!class)
    {
	MsgErrorF("Unrecognized group class: '%s'\n", className);
	return (FALSE);
    }

    /* create new group */
    group = DBGroupNew(cellDef, id);
    group->g_class = class;

    while (dbReadNextLine(lineBuf, bufSize, f))
    {
       if (lineBuf[0]== '}' && strcmp(lineBuf,"}\n") == 0) return TRUE;
       if(!dbGroupReadAttribute(group,lineBuf, bufSize, f)) return FALSE;
    }
    return (FALSE);
}

bool
dbGroupsRead(CellDef *cellDef, 
                     	/* Cell whose groups are being read */
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
	    strcmp(lineBuf,"} SECTION GROUPS\n") == 0) return TRUE;
        if(!dbGroupRead(cellDef, lineBuf, bufSize, f)) return FALSE;
    }
    return (FALSE);
}


/*
 * ----------------------------------------------------------------------------
 *
 * dbGroupsFree --
 *
 * Delete all groups associated with def, and reclaim storage.
 *
 * NOTE:  Assumes paint planes already cleared (so no pointers left to groups).
 *
 * ----------------------------------------------------------------------------
 */

void
dbGroupsFree(CellDef *cellDef)
{
  /* DEBUG TODO dbGroupsDelete */
}


/*
 * ----------------------------------------------------------------------------
 *
 * DBGroupsQ --
 *
 * return TRUE iff there are any properties associated with cell
 *
 *
 * ----------------------------------------------------------------------------
 */

bool
DBGroupsQ(CellDef *def)
{
  return (IHashEntries(def->cd_groupTable)>0); 
}
