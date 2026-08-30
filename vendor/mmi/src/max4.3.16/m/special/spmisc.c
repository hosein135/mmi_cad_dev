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

#include <stdio.h>
#include <string.h>
#include "main.h"
#include "magic.h"
#include "database.h"
#include "databaseInt.h"
#include "geometry.h"
#include "geometry.h"
#include "tile.h"
#include "hash.h"
#include "database.h"
#include "databaseInt.h"
#include "message.h"
#include "signals.h"
#include "utils.h"
#include "units.h"
#include "special.h"

static char *rcsid = "$Header: /volume/mmi/src/max/m/special/RCS/spmisc.c,v 1.1 2002/02/19 22:56:30 pat Exp $";



// Load cell by name.  If not found, dont complain or leave an empty cell around,
// just return NULL.
// This should be moved into the DB routines!
// The code below is a terrible hack, but there just doesnt seem to be
// any other way to get this functionality in C.
CellDef *SPCellLoad(char *cellname)
{
    CellDef *def;

    if ((def = DBCellLookDef(cellname))) {return def;} 
    def = DBCellNewDef(cellname,NULL);
    def->cd_flags |= CD_NOT_FOUND;   // HACK!!! Suppresses the error message if cell not found.
    if (!DBReadCell(def)) {
	DBCellDeleteDef(def);
	return NULL;
    }
    def->cd_flags &= ~CD_NOT_FOUND;
    return def;
}
