BPRectCPlaneNew --
------------------

Return newly created Bplane.

BPRectCAdd --
-------------

add the given rectc to the given bplane

BPRectCEnumInit --
------------------

set up search.

BPEnumNext --
-------------

get next element in enumeration.

BPTclInit --
------------

Initialize tcl commands for this module

Results:
None.

Side effects:
Registers command(s) with tcl.

CIFGenLayer --
--------------

This routine will generate one CIF layer.
It provides the core of the CIF generator.

Results:
Returns a malloc'ed plane with tiles of type CIF_SOLIDTYPE
marking the area of this CIF layer as built up by op.

Side effects:
None, except to create a new plane holding the CIF for the layer.
The CIF that's generated may fall outside of area... it's what
results from considering everything in area.  In most cases the
caller will clip the results down to the desired area.

CIFGen --
---------

This procedure generates a complete set of CIF layers for
a particular area of a particular cell.  NOTE: if the argument
genAllPlanes is FALSE, only planes for those layers having
a bit set in 'layers' are generated; the others are set
to NULL.

Results:
None.

Side effects:
The parameters realPlanes and tempPlanes are modified
to hold the CIF and temporary layers for area of cellDef,
as determined by the current CIF generation rules.

CIFClearPlanes --
-----------------

This procedure clears out a collection of CIF planes.

Results:
None.

Side effects:
Each of the planes in "planes" is re-initialized to point to
an empty paint plane.

CIFInitCells --
---------------

This procedure just sets up cell definitions and uses needed
for hierarchical checking and other CIF uses.

Results:
None.

Side effects:
DRCUse, DRCDef, and DRCDummyUse are set up if they're not
there already.

CIFGenSubcells --
-----------------

This procedure computes all of the CIF that must be added to
a given area to compensate for interactions between subcells.

Results:
None.

Side effects:
The parameter "output" is modified (by OR'ing) to hold all
the CIF that was generated for subcells.

CIFGenArrays --
---------------

This procedure computes all of the CIF that must be added to
a given area of a parent to compensate for interactions between
elements of arrays in that area.

Results:
None.

Side effects:
The parameter output is modified (by OR'ing) to hold all
the CIF that was generated for array interactions.

CIFPrintStats --
----------------

This procedure prints out CIF statistics including both
total values and counts since the last printing.

Results:
None.

Side effects:
Several messages are printed.

CIFSetStyle --
--------------

This procedure changes the current CIF output style to the one
named by the parameter.

Results:
None.

Side effects:
The current CIF style is changed.  If the name doesn't match,
or is ambiguous, then a list of all CIF styles is output.

The variables exporting unit sizes are set to this style.

CIFNameToMask --
----------------

Finds the CIF planes for a given name.

Results:
TRUE if successful, FALSE if "name" failed to match any layers.

Side effects:
If there's no match, then an error message is output.
The sets 'result' to be all types containing the CIF layer named
"name".  The current CIF style is used for the lookup.

CIFError --
-----------

This procedure is called by low-level CIF generation routines
when a problem is encountered in generating CIF.  This procedure
notes the problem using the feedback mechanism.

Results:
None.

Side effects:
Feedback information is added.  The caller must have set CIFErrorDef
to point to the cell definition that area refers to.  If CIFErrorDef
is NULL, then errors are ignored.

CIFReadCellInit --
------------------

This procedure initializes the data structures in this
module just prior to reading a CIF or GDS file.

If ptrkeys is 0, the keys used in this hash table will
be strings; if it is 1, the keys will be CIF numbers.

Results:
None.

Side effects:
The cell hash table is initialized, and things are set up
to put information in the EditCell first.

CIFReadCellCleanup --
---------------------

Free temporary storage after a CIF or GDS file has been read in.

CIFParseStart --
----------------

Parse the beginning of a symbol (cell) definition.
ds ::= D { blank } S integer [ sep integer sep integer ]

Results:
TRUE is returned if the parse completed successfully, and
FALSE is returned otherwise.

Side effects:
Set up information for the new cell, including the CIF
planes and creating a Magic cell (if one doesn't exist
already).

CIFPaintCurrent --
------------------

This procedure does geometrical processing on the current
set of CIF planes, and paints the results into the current
CIF cell.

Results:
None.

Side effects:
Lots of information gets added to the current Magic cell.

CIFParseFinish --
-----------------

This procedure is called at the end of a cell definition.

Results:
TRUE is returned if the parse completed successfully, and
FALSE is returned otherwise.

Side effects:
Process the CIF planes and paint the results into the Magic
cell.

CIFParseDelete --
-----------------

This procedure is called to handle delete-symbol statements.

Results:
TRUE is returned if the parse completed successfully, and
FALSE is returned otherwise.

Side effects:
The mapping between numbers and cells is modified to eliminate
some symbols.

CIFParseCall --
---------------

This procedure processes subcell uses.  The syntax of a call is
call ::= C integer transform

Results:
TRUE is returned if the parse completed successfully, and
FALSE is returned otherwise.

Side effects:
A subcell is added to the current Magic cell we're generating.

CIFParseUser --
---------------

This procedure is called to process user-defined statements.
The syntax is user ::= digit usertext.

Results:
TRUE is returned if the parse completed successfully, and
FALSE is returned otherwise.

Side effects:
Depends on the user command.

CIFReadCellFinish --
--------------------

This procedure is called after processing the CIF file.
(not GDS!) to perform final processing after the cif has
been read in.

Results:
None.

Side effects:
The area of each cell is DRC'ed and redisplayed.  Error
messages are output for any cells whose contents weren't
in the CIF file.  An error message is also output if
we're still in the middle of reading a subcell.

CIFPolyToRects --
-----------------

Converts a manhattan polygon (specified as a path) into a
linked list of rectangles.

Results:
The return value is a linked list of rectangles, or NULL if
something went wrong.

Side effects:
Memory is allocated to hold the list of rectangles.  It is
the caller's responsibility to free up the memory.

CIFParseBox --
--------------

This procedure parses a CIF box command.

Results:
TRUE is returned if the parse completed successfully, and
FALSE is returned otherwise.

Side effects:
A box is added to the CIF information for this cell.  The
box better not have corners that fall on half-unit boundaries.

CIFParseFlash --
----------------

This routine parses and processes a roundflash command.  The syntax is:
roundflash ::= R diameter center

We approximate a roundflash by a box.

Results:
TRUE is returned if the parse completed successfully, and
FALSE is returned otherwise.

Side effects:
Paint is added to the current CIF plane.

CIFParseWire --
---------------

This procedure parses CIF wire commands, and adds paint
to the current CIF cell.  A wire command consists of
an integer width, then a path.

Results:
TRUE is returned if the parse completed successfully, and
FALSE is returned otherwise.

Side effects:
The current CIF planes are modified.

CIFParseLayer --
----------------

This procedure parses layer changes.  The syntax is:
layer ::= L { blank } processchar layerchars

Results:
TRUE is returned if the parse completed successfully, and
FALSE is returned otherwise.

Side effects:
Switches the CIF plane where paint is being saved.

CIFParsePoly --
---------------

This procedure reads and processes a polygon command.  The syntax is:
polygon ::= path

Results:
TRUE is returned if the parse completed successfully, and
FALSE is returned otherwise.

Side effects:
Paint is added to the current CIF plane.

CIFReadNameToType --
--------------------

This procedure finds the type (integer index) of a given
layer name.

Results:
The return value is the type.  If we ran out of space in
the CIF layer table, or if the layer wasn't recognized and
it isn't OK to make a new layer, -1 gets returned.

Side effects:
If no layer exists by the given name and newOK is TRUE, a
new layer is created.

CIFCalmaLayerToCifLayer --
--------------------------

Find the CIF number of the layer matching the supplied Calma
layer number and datatype.

Results:
Returns the CIF number of the above layer, or -1 if it
can't be found.

Side effects:
None.

CIFParseReadLayers --
---------------------

Given a comma-separated list of CIF layer names, builds a
bit mask of all those layer names.

Results:
Number of layers in list.

Side effects:
Modifies the parameter pointed to by mask so that it contains
a mask of all the CIF layers indicated.  If any of the CIF
layers didn't exist, new ones are created.  If we run out
of CIF layers, an error message is output.

CIFReadTechInit --
------------------

Called once at the beginning of technology file read-in to
initialize data structures.

Results:
None.

Side effects:
Clears out the layer data structure.

CIFReadTechLine --
------------------

This procedure is called once by the tech module for each line
in the "cifinput" section of the technology file.

Results:
None.

Side effects:
Sets up information in the tables used to read CIF, and prints
error messages if problems arise.

CIFReadTechFinal --
-------------------

This procedure is invoked after all the lines of a technology
file have been read.  It checks to make sure that the information
read in "cifinput" sections is reasonably complete.

Results:
None.

Side effects:
Error messages may be output.

CIFReadError --
---------------

This procedure is called to print out error messages during
CIF file reading.

Results:
None.

Side effects:
An error message is printed.

Note:
You can add more arguments if three turns out not to be enough.

CIFSkipBlanks --
----------------

This procedure skips over whitespace in the CIF file,
keeping track of the line number and other information
for error reporting.

Results:
None.

Side effects:
Advances through the CIF file.

CIFSkipSep --
-------------

Skip over separators in the CIF file.  Blanks and upper-case
characters are separators.

Results:
None.

Side effects:
Advances through the CIF file.

CIFSkipToSemi --
----------------

This procedure is called after errors.  It skips everything
in the CIF file up to the next semi-colon.

Results:
None.

Side effects:
Advances through the CIF file.

CIFSkipSemi --
--------------

Skips a semi-colon, including blanks around the semi-colon.

Results:
None.

Side effects:
Advances through the CIF file.

CIFParseSInteger --
-------------------

This procedure parses a signed integer from the CIF file.

Results:
TRUE is returned if the parse completed without error,
FALSE otherwise.

Side effects:
The integer pointed to by valuep is modified with the
value of the signed integer.

CIFParseInteger --
------------------

Parses a positive integer from the CIF file.

Results:
TRUE is returned if the parse was completed successfully,
FALSE otherwise.

Side effects:
The value pointed to by valuep is modified to hold the integer.

CIFParsePoint --
----------------

Parse a point from a CIF file.  A point is two integers
separated by CIF separators.

Results:
TRUE is returned if the point was parsed correctly, otherwise
FALSE is returned.

Side effects:
The parameter pointp is filled in with the coordinates of
the point.

CIFParsePath --
---------------

This procedure parses a CIF path, which is sequence of
one or more points.

If the path is non-Manhattan, we introduce additional
stair-steps a minimum of one Max DB unit 
high and wide along each non-Manhattan segment.

Results:
TRUE is returned if the path was parsed successfully,
FALSE otherwise.

Side effects:
Modifies the parameter pathheadpp to point to the path
that is constructed.

CIFMakeManhattanPath --
-----------------------

Convert a non-Manhattan path into a Manhattan one by adding
additional points.  These points are added using a simple
scan-conversion algorithm that generates a series of stair
steps that are at least one Max Database units
high and wide (but which may be higher or wider).

Results:
None.

Side effects:
May insert additional points in the path.

CIFFreePath --
--------------

This procedure frees up a path once it has been used.

Results:
None.

Side effects:
All the elements of path are returned to the storage allocator.

CIFDirectionToTrans --
----------------------

This procedure is used to convert from a direction vector
to a Magic transformation.  The direction vector is a point
giving a direction from the origin.  It better be along
one of the axes.

Results:
The return value is the transformation corresponding to
the direction, or the identity transform if the direction
isn't along one of the axes.

Side effects:
None.

CIFParseTransform --
--------------------

This procedure is called to read in a transform from a
CIF file.

Results:
TRUE is returned if the parse completed successfully, and
FALSE is returned otherwise.

Side effects:
The parameter pointed to by transformp is modified to
contain the transform indicated by the CIF file.

CIFReadFile --
--------------


CIFSetReadStyle --
------------------

This procedure changes the current style used for reading
CIF.

Results:
None.

Side effects:
The CIF style is changed to the one specified by name.  If
there is no style by that name, then a list of all valid
styles is output.

CIFSeeLayer --
--------------

Generates CIF over a given area of a given cell, then
highlights a particular CIF layer on the screen.

Results:
None.

Side effects:
Highlight information is drawn on the screen.

CIFSeeHierLayer --
------------------

This procedure is similar to CIFSeeLayer except that it only
generates hierarchical interaction information.

Results:
None.

Side effects:
CIF information is highlighed on the screen.  If arrays is
TRUE, then CIF that stems from array interactions is displayed.
if subcells is TRUE, then CIF stemming from subcell interactions
is displayed.  If both are TRUE, then both are displayed.

CIFTechInit --
--------------

Called once at beginning of technology file read-in to
initialize data structures.

Results:
None.

Side effects:
Just clears out the layer data structures.

CIFTechLine --
--------------

This procedure is called once for each line in the "cif"
section of the technology file.

Results:
TRUE normally, FALSE on error.

Side effects:
Sets up information in the tables of CIF layers, and
prints error messages where there are problems.

CIFTechFinal --
---------------

This procedure is invoked after all the lines of a technology
file have been read.  It checks to make sure that the
section ended at a consistent point, and computes the interaction
distances for hierarchical CIF processing.

Results:
None.

Side effects:
Error messages are output if there's incomplete stuff left.
Interaction distances get computed for each CIF style
in two steps.  First, for each layer the total grow and
shrink distances are computed.	These are the maximum distances
that edges may move because of grows and shrinks in creating
the layer.  Second, the	radius for the style is computed.
The radius is used in two ways: first to determine how far
apart two subcells may be and still interact during CIF
generation;  and second, to see how much material to yank in
order to find all additional CIF resulting from interactions.
Right now, a conservative approach is used:  use the greater
of twice the largest grow distance or twice the largest shrink
distance for both.  Twice the grow distance must be considered
because two pieces of material may each grow towards the other
and interact in the middle.  Twice the largest shrink distance
is needed because subcells considered individually may each
shrink away from a boundary where they touch;  the parent must
fill in the gap.  To do this, it must include 2S additional
material:  S is the size of the gap that must be filled, but
its outside edge will shrink in by S, so we must start with
2S material to have S left after the shrink.  Finally, one extra
unit gets added because two pieces of material one radius apart
can interact:  to find all this material we must look one unit
farther out for anything overlapping (the search routines only
look for overlapping material and ignore abutting material).

CIFWrite --
-----------

Write out the entire tree rooted at the supplied CellDef in CIF format,
to the specified file.

Results:
TRUE if the cell could be written successfully, FALSE otherwise.

Side effects:
Writes a file to disk.
In the event of an error while writing out the cell,
the external integer errno is set to the UNIX error
encountered.

Algorithm:
We make a depth-first traversal of the entire design tree,
marking each cell with a CIF symbol number and then outputting
it to the CIF file.  If a given cell is not read in when we
visit it, we read it in.

No hierarchical design rule checking or bounding box computation
occur during this traversal -- both are explicitly avoided.

CIFWriteFlat --
---------------

Write out the entire tree rooted at the supplied CellDef in CIF format,
to the specified file, but write non-hierarchical CIF.  

Results:
TRUE if the cell could be written successfully, FALSE otherwise.

Side effects:
Writes a file to disk.
In the event of an error while writing out the cell,
the external integer errno is set to the UNIX error
encountered.

Algorithm:
We operate on the cell in chunks chosen to keep the memory utilization
reasonable.  Foreach chunk, we use DBSearchPaint and cifHierCopyFunc to 
flatten the 
chunk into a yank buffer ("eliminating" the subcell problem), then use 
cifOut to generate the CIF.
No hierarchical design rule checking or bounding box computation
occur during this operation -- both are explicitly avoided.

DBArrayTransformInfo
--------------------

transform celluse array info 

DBMakeArray --
--------------

Turn cellUse into an array whose X indices run from xlo through xhi
and whose Y indices run from ylo through yhi.  The separation between
adjacent array elements is xsep in the X direction, and ysep in the
Y direction.

The X and Y information is in coordinates of the root cell def.
It gets transformed down to the def of cellUse according to the
transform supplied.  What we do guarantee is that the array
indices will appear, in root coordinates, to run from xlo to xhi
left-to-right, and from ylo to yhi bottom-to-top.

Results:
None.

Side Effects:
The array information if toCellUse is modified.

DBArrayOverlap --
-----------------

Determine which elements of an array overlap the supplied clipping
rectangle.  Assumes that the clipping rectangle overlaps at least
some part of the array area.

Results:
None.

WARNING:
This code is very sensitive to being changed.  Make sure you
understand it before you change it.

Side Effects:
Sets *pxlo, *pxhi, *pylo, *pyhi to be the inclusive range of array
indices which overlay the given clipping rectangle.

If there is any overlap in X, *pxlo <= *pxhi; similarly, if there
is any overlap in Y, *pylo <= *pyhi.

DBComputeArrayArea --
---------------------

Given an area in native coordinates of a celldef, computes the
corresponding area in a parent's coordinates, for a particular
celluse and a particular element of an array.

Results:
None.

Side Effects:
Sets *prect to the given area in the given array instance,
subject to the arraying and transformation inforamtion in
the given cellUse.

DBGetArrayTransform --
----------------------

This procedure computes the transform from a particular element
of an array to the coordinates of the array as a whole.

Results:
The return result is a pointer to a transform describing how
coordinates of use->cu_def must be transformed in order to
appear in the (x,y) element location.  In other words, if the
transform for the whole array (use->cu_transform) were
GeoIdentityTransform, this is the transform from use->cu_def
to the parent use for the (x,y) element.  By the way, the
return result is a locally-allocated transform that goes away
the next time this procedure is called, so use it carefully.

Side effects:
None.

DBBoxCellInitial --
-------------------

Sets cells bbox to rectangle with corners at (0,0) and (1,1)
Used as (initial) bbox for empty cells.

DBBoxPlane --
-------------

Determine the bounding box for the supplied tile plane.
The bounding box is the smallest rectangle that completely
encloses all non-space tiles.

If the tile plane is completely empty, we return a 0x0 bounding
box at the origin.

Results:
TRUE if the tile plane contains any geometry, FALSE
if it is completely empty.

Side effects:
Sets *rect to the bounding rectangle.

DBBoundPlane --
---------------

Determine the bounding rectangle for the supplied tile plane.
The bounding rectangle is the smallest rectangle that completely
encloses all non-space tiles.

If the tile plane is completely empty, we return a 0x0 bounding
box at the origin.

Results:
TRUE if the tile plane contains any geometry, FALSE
if it is completely empty.

Side effects:
Sets *rect to the bounding rectangle.

DBBoundPlaneVert --
-------------------

Determine the bounding rectangle for the supplied tile plane,
which is organized into maximal vertical strips instead of
maximal horizontal ones.

The bounding rectangle is the smallest rectangle that completely
encloses all non-space tiles.

If the tile plane is completely empty, we return a 0x0 bounding
box at the origin.

Results:
TRUE if the tile plane contains any geometry, FALSE
if it is completely empty.

Side effects:
Sets *rect to the bounding rectangle.

DBCellLookDef --
----------------

Find the definition of the cell with the given name.

Results:
Returns a pointer to the CellDef with the given name if it
exists.  Otherwise, returns (CellDef *) NULL.

Side effects:
None.

DBCellNewDef --
---------------

Create a new cell definition with the given name.  There must not
be any cells already known with the same name.

Results:
Returns a pointer to the newly created CellDef.  The CellDef
is completely initialized, showing no uses and having all
tile planes initialized via TiNewPlane() to contain a single
space tile.  The filename associated with the cell is set to
the name supplied, but no attempt is made to open it or create
it.

If the cellName supplied is NULL, the cell is entered into
the symbol table with a name of UNNAMED.

Returns NULL if a cell by the given name already exists.

Side effects:
The name of the CellDef is entered into the symbol table
of known cells.

DBCellRenameDef --
------------------

Renames the indicated CellDef.

Results:
TRUE if successful, FALSE if the new name was not unique.

Side effects:
The name of the CellDef is entered into the symbol table
of known cells.  The CDMODIFIED bit is set in the flags
of each of the parents of the CellDef to force them to
be written out using the new name.

DBCellDeleteDef --
------------------

Removes the CellDef from the symbol table of known CellDefs and
frees the storage allocated to the CellDef.  

If the CellDef is referenced (has uses), its contents are cleared
and it is marked unavailable, but the def is not actually removed. 

NOTE:  If the cell is removed, the undo stack is flushed, since it
could contain references to the def.

Results:
TRUE if successful, FALSE if there were any outstanding
CellUses found.

DBNewYank --
------------

Create a new yank buffer with name 'yname'.

Results:
None.

Side effects:
Fills in *pydef with a newly created CellDef by that name, and
*pyuse with a newly created CellUse pointing to the new def.
The CellDef pointed to by *pydef has the CD_INTERNAL flag
set, and is marked as being available.

DBCellClearContents --
----------------------

Empties out all tile planes of the indicated CellDef, making it
as though the def had been newly allocated.

Results:
None.

Side effects:
The paint and subcells stored in the CellDef are all deleted.
Sets the bounding box to the degenerate (0,0)::(1,1) box.

DBCellClearContentsUp --
------------------------

Wrapper around DBCellClearContents that does all appropriate updates,
e.g. display and drc.

Empties out all tile planes of the indicated CellDef, making it
as though the def had been newly allocated.

Results:
None.

Side effects:
The paint and subcells stored in the CellDef are all deleted.
Sets the bounding box to the degenerate (0,0)::(1,1) box.

DBCellSetAvail --
-----------------
DBCellClearAvail --

Mark a cell as available/unavailable.
These exist mainly to create a cell for the first time, and to
allow a cell to be 'flushed' via the "flush" command.

Results:
None.

Side effects:
Modifies flags in cellDef.

DBCellSrDefs --
---------------

Search for all cell definitions matching a given pattern.
For each cell definition whose flag word contains any of the
bits in pattern, the supplied procedure is invoked.

The procedure should be of the following form:
int
func(cellDef, cdata)
CellDef *cellDef;
ClientData cdata;
{
}
Func should normally return 0.  If it returns 1 then the
search is aborted.

Results:
Returns 1 if the search completed normally, 1 if it aborted.

Side effects:
Whatever the user-supplied procedure does.

DBSelectCell --
---------------

Select the next cell containing a given point.

Results:
Returns a pointer to the next CellUse containing the given
point, or NULL if we have visited all CellUses containing it.
The ordering of CellUses visited is smallest in area to largest.
Both expanded cells, and unexpanded cells all of whose parents
are expanded, are returned.

Side effects:
Sets *transform to be the transform from coordinates of
the CellUse's definition to those of the root cell use.
Sets *selp to be the x and y array indices of the selected cell.
Returns path in the argument "tpath".

DBCellNewUse --
---------------

Create a new cell use of the supplied CellDef.

Results:
Returns a pointer to the new CellUse.  The CellUse is initialized
to reflect that cellDef is its definition.  The transform is
initialized to the identity, and the parent pointer initialized
to NULL.

Side effects:
Updates the use list for cellDef.

DBCellInitTempUse --
--------------------

Initialize a temporary use.  

This is bascially a light weight alternative to DBCellNewUse, for use
in DBSearch routines to create initial use (handle) from which to start 
search.  Avoids Malloc (can be passed a use from stack), and does not
link use in cd_uses list, so DBCellDeleteUse() call is not needed. 

Results:
None.

Side effects:
Initializes use. 

DBCellDeleteUse --
------------------

Remove a CellUse.
Frees the storage allocated to the CellUse, 
unlinks use from corresponding defs cd_use list.

It is required that the CellUse has been removed from any CellTileBodies
in the subcell plane of its parent.  The parent pointer for this
CellUse must therefore be NULL.

Results:
TRUE if the CellUse was successfully removed, FALSE if
the parent pointer were not NULL.

Side effects:
All storage for the CellUse is freed.
The list of all CellUses associated with a given CellDef is
updated to reflect the absence of the deleted CellUse.

DBCellUseSetBBox --
-------------------

Compute the bounding box for a CellUse in coordinates of its parent.

Results:
None.

Side effects:

Sets cellUse->cu_bbox to be the bounding box for the indicated CellUse
in coordinates of that CellUse's parent.

Sets cu_vBBOX to cd_vBBOX of subcell.

DBCellUseSetArray --
--------------------

Copy the array information from fromCellUse to toCellUse

Results:
None.

Side Effects:
The array information if toCellUse is modified.

DBCellUseSetTrans --
--------------------

Change the transform for cellUse to that supplied.

Results:
None.

Side Effects:
Updates cellUse->cu_trans and cellUse->cu_bbox

DBChangedArea --
----------------

Handle all the bookkeeping necessary when a change has been made
to the database, including:

redisplay scheduling   
drc notification
keeping bounding box info up to date.

DBChangeNewInstance --
----------------------

Called by DBInstanceAdd()

Checks versions on new instance and sets cd_changesPending in
parent as required (to be propagated on next DBChangedArea())

Assumes DBChangedArea() will be called on the 
area including the instance!

DBChunk --
----------

This procedure finds largest rectangular chunk of homogeneous material
on given layer and covering given area.

largest:
first, maximum minimum dimension.
second (subordinate to above), maximum maximum dimension.

Adjusts scx_area to chunk.  

DBTreeCopyConnect --
--------------------

This procedure copies connected information from a given cell
hierarchy to a given (flat) cell.  Starting from the tile underneath
the given area, this procedure copies all connected paint 
(in all cells) to the result cell.

If there are several electrically
distinct nets underneath the given area, one is picked at "random".

NOTE: This routine assumes the dest cell starts out empty!
May not work correctly if the dest cell doesn't start out empty.

DBTechInitContact --
--------------------

Mark all types as being non-contacts initially.

Results:
None.

Side effects:
Initializes dbLayerInfo.
Also marks each type in DBLayerTypeMaskTbl[] as consisting
only of itself (no other images).

DBTechAddContact --
-------------------

Add the definition of a new contact type.
The syntax of each line in the "contact" section is:

contactType res1 res2 [res3]

where res1, res2, and res3 are the residue types on the planes
connected by the contact.  At most three residue types may be
specified.  Furthermore, one must be on the home plane of the
contact (the plane specified in the "types" section for the type
contactType), and the others must be on adjacent planes.  Finally,
there can be only a single contactType that has the same residues.

Results:
FALSE on error, TRUE if successful.

Side effects:
Adds the definition of a new contact type.

DBTechFinalContact --
---------------------

Conclude reading the "contact" section of a technology file.
At this point, all tile types are known so we can call dbTechInitPaint()
to fill in the default paint/erase tables, and dbTechInitMasks() to fill
in the various exported TileTypeBitMasks.

Results:
None.

Side effects:
Fills in the dbLayerInfo table for non-contacts.
Sets DBLayerTypeMaskTbl to its final value.
Initializes DBTypePlaneMaskTbl[] and DBPlaneTypes[].

DBTechGetContact --
-------------------

Given two tile types, determine the corresponding contact type.

Results:
Returns a contact type.

Side effects:
Prints stuff if it can't find a contact type.

DBCopyPaint --
--------------

Copy paint and polygons from scx->scx_use and descendents
to targetUse, transforming according to the transform in scx.

Only the types specified by typeMask are copied.

Flags:
DBCP_NON_RECURSIVE - paint from top cell only.
DBCP_ACTIVE_GROUP_ONLY - only copy active group.
DBCP_NO_TILES - don't copy paint tiles. 
DBCP_NO_POLY - don't copy polygons
DBCP_NO_WP - don't copy wirepaths

DBCellCopyAllLabelsG --
-----------------------

Copy labels from the tree rooted at scx->scx_use to targetUse,
transforming according to the transform in scx.  Only labels
attached to layers of the types specified by mask are copied.
The area to be copied is determined by GEO_LABEL_IN_AREA.

Results:
None.

Side effects:
Copies labels to targetUse, clipping against scx->scx_area.
If pArea is given, store in it the bounding box of all the
labels copied.

DBCellCopyAllLabels --
----------------------

Copy labels from the tree rooted at scx->scx_use to targetUse,
transforming according to the transform in scx.  Only labels
attached to layers of the types specified by mask are copied.
The area to be copied is determined by GEO_LABEL_IN_AREA.

Results:
None.

Side effects:
Copies labels to targetUse, clipping against scx->scx_area.
If pArea is given, store in it the bounding box of all the
labels copied.

DBCellCopyLabelsG --
--------------------

Copy labels from scx->scx_use to targetUse, transforming according to
the transform in scx.  Only labels attached to layers of the types
specified by mask are copied.  If mask contains the L_LABEL bit, then
all labels are copied regardless of their layer.  The area copied is 
determined by GEO_LABEL_IN_AREA.

Results:
None.

Side effects:
Updates the labels in targetUse.  If pArea is given, it will
be filled in with the bounding box of all labels copied.

DBCellCopyLabels --
-------------------

Copy labels from scx->scx_use to targetUse, transforming according to
the transform in scx.  Only labels attached to layers of the types
specified by mask are copied.  If mask contains the L_LABEL bit, then
all labels are copied regardless of their layer.  The area copied is 
determined by GEO_LABEL_IN_AREA.

Results:
None.

Side effects:
Updates the labels in targetUse.  If pArea is given, it will
be filled in with the bounding box of all labels copied.

DBCellCopyAllCells --
---------------------

Copy unexpanded subcells from the tree rooted at scx->scx_use
to the subcell plane of targetUse, transforming according to
the transform in scx.

This effectively "flattens" a cell hierarchy in the sense that
all unexpanded subcells in a region (which would appear in the
display as bounding boxes) are copied into targetUse without
regard for their original location in the hierarchy of scx->scx_use.
If an array is unexpanded, it is copied as an array, not as a
collection of individual cells.

Results:
None.

Side effects:
Updates the cell plane in targetUse.  If pArea is given, it
will be filled in with the total area of all cells copied.

DBCellCopyCells --
------------------

Copy all subcells that are immediate children of scx->scx_use->cu_def
into the subcell plane of targetUse, transforming according to
the transform in scx.  Arrays are copied as arrays, not as a
collection of individual cells.  If a cell is already present in
targetUse that would be exactly duplicated by a new cell, the new
cell isn't copied.

Results:
None.

Side effects:
Updates the cell plane in targetUse.  If pArea is given, it will
be filled in with the bounding box of all cells copied.

DBNewPaintTable --
------------------

This procedure changes the paint table to be used by 
DBCopyPaint()

Results:
The return value is the address of the paint table that used
to be in effect.  It is up to the client to restore this
value with another call to this procedure.

Side effects:
A new paint table takes effect.

DBNewPaintPlane --
------------------

This procedure changes the painting procedure to be used by the
DBCellCopyPaint and DBCellCopyAllPaint procedures.

Results:
The return value is the address of the paint procedure that
used to be in effect.  It is up to the client to restore this
value with another call to this procedure.

Side effects:
A new paint procedure takes effect.

DBCellCopyDef--
---------------

Copies the contents of the source cell def to the destination cell def.
Does not clear the dest def first!

DBTreeCountPaint --
-------------------

Allow the client to compute statistics on the paint in a subtree.
The client provides three functions: 'count', 'hiercount', and
'cleanup', which should be of the following form:

int
count(def, cdata)
CellDef *def;
ClientData cdata;
{
}

The 'count' function is applied in a pre-order traversal of the
cell graph; if it returns 0 then the subcells of 'def' are visited;
if it returns 1 then the subcells are not visited.

Void
hiercount(parent, uses, child, cdata)
CellDef *parent, *child;
int uses;		/# Scale factor: number of times child
# is used by parent
#/
ClientData cdata;
{
}

The 'hiercount' function is applied in a post-order traversal of
the cell graph, ie, it is applied only after all children of a
cell have been visited.

int
cleanup(def, cdata)
CellDef *def;
ClientData cdata;
{
}

The 'cleanup' function is applied in a pre-order traversal of the
cell graph; if it returns 0 then the subcells of 'def' are visited;
if it returns 1 then the subcells are not visited.

Results:
None.

Side effects:
Applies the client procedures as described above.
The client is free to use each CellDef's cd_client
field, but should reset this field to zero when the
cleanup procedure is supplied.

Algorithm:
We first visit all CellDefs in the tree, applying the
client's 'count' procedure to each CellDef.

Next, we make a second pass over the cells, applying
the client's 'hiercount' procedure to each CellDef
in post-order (ie, the 'hiercount' procedure is first
applied recursively to all the subtrees of a given
def before being applied to the def itself).

Finally, we make a pass over all CellDefs and apply
the client's 'cleanup' procedure.

DBEnumRoots --
--------------

Apply the supplied procedure to each root CellUse that contains the baseDef
either as rootdef or descendent.

A root is a CellUse with no parent def.

The procedure should be of the following form:
int
func(cellUse, transform, cdarg)
CellUse *cellUse;
Transform *transform;
ClientData cdarg;
{
}

Transform is from coordinates of baseDef to those of the def of cellUse.
Func normally returns 0.  If it returns 1 then the search is aborted.

Results:
0 is returned if the search terminated normally.  1 is returned
if it was aborted.

Side effects:
Whatever side effects are brought about by applying the
procedure supplied.

DBEnumChildren --
-----------------

Apply the supplied procedure once to each CellUse in the subcell tile
plane of the supplied CellDef.  

Note differs from DBSrChildren in that this is not an area search and
does not use scx.


The procedure should be of the following form:
int
func(use, cdarg)
CellUse *use;
ClientData cdarg;
{
}

Func returns 0 normally, 1 to abort the search.

Results:
0 if search terminated normally, 1 if it aborted.

Side effects:
Whatever side effects are brought about by applying the
procedure supplied.

TODO: consider recoding DBEnumChildren() using kid strucs instead of subcell plane 

DBEnumArrayElements --
----------------------

Finds all elements of an array that fall in a particular area
of the parent, and calls func for each element found.

The procedure should be of the following form:
int
func(cellUse, trans, x, y, cdarg)
CellUse *celluse;
Transform *trans;
int x, y;
ClientData cdarg;
{}

In the above, cellUse is the original cellUse, trans is
a transformation from the coordinates of the cell def to
the coordinates of the use (for this array element), x and
y are the indices of this array element, and cdarg is
the ClientData supplied to us.	If 1 is returned by func,
it is a signal to abort the search.

Results:
0 is returned if the search finished normally.  1 is returned
if the search was aborted.

Side effects:
Whatever func does.

DBExpand --
-----------

Expand/unexpand a single CellUse.

Results:
None.

Side effects:
If expandFlag is TRUE, sets all the bits of expandMask in
the flags of the given cellUse.
If expandFlag is FALSE, clears all bits of expandMask.

If expandFlag is TRUE and the cell being expanded has not
been read in, reads it in from disk.

DBExpandAll --
--------------

Recursively expand/unexpand all cells which intersect or are
contained within the given rectangle.  Furthermore, if func is
non-NULL, it is invoked for each cell whose status has changed,
just after the change has been made.  The calling sequence is

int
func(cellUse, cdarg)
CellUse *cellUse;
ClientData cdarg;
{
}

In the calls to func, cellUse is the use whose expand bit has just
been changed, and cdarg is the argument that the caller gave to us.
Func should normally return 0.  If it returns a non-zero value, then
the call terminates immediately and no more cells are expanded.

Results:
None.

Side effects:
If expandFlag is TRUE, sets all the bits specified by
expandMask in the flags of each CellUse found to intersect
the given rectangle.  If expandFlag is FALSE, clears all bits
of expandMask.

NOTE:  a cell that is unexpanded and read-in and whose previous bbox
(stored with parent) does not intersect the area, will not be
expanded, since we do not know that it intersects the area. 

DBCellReadArea --
-----------------

Recursively read all cells which intersect or are contained within
the given rectangle.

Results:
None.

Side effects:
May make new cells known to the database.  Sets the CDAVAILABLE
bit in all cells intersecting the search area.

DBFlyLineNotifyLabelChange --
-----------------------------

Called to notify flyline module whenever a label is added or deleted.

Adjusts flyline endpoints attached to labels (if any) and notifys
Layout module for redisplay.

DBFlyLineInstanceChangeNotify --
--------------------------------

Called to notify flyline module whenever an instance is changed in a way
that could impact flylines.

Adjusts flyline endpoints attached to labels (if any) and notifys
Layout module for redisplay.

DBGroupTileTypesMask --
-----------------------

returns mask of all tile types of tile (all groups)

DBGroupTileTypes2S --
---------------------

convert tiles groups/types to string (writes to buf)

DBGroupClassNew --
------------------

Define a new group class

Returns pointer to the new group class

DBGroupClassFromName--
----------------------

Lookup named group class

Returns pointer to named group (0 if not found)

DBGroupAttributeSet --
----------------------

Set attribute value.

DBGroupAttributeGet--
---------------------

get attribute value

DBGroupNew --
-------------

Add a group to a cell def.

Returns pointer to the new group

DBGroupFromName--
-----------------

Lookup named group

Returns pointer to named group (0 if not found)

DBInit --
---------

Initialize this module.

Results:
None.

DBInstanceFindByName --
-----------------------

Find the instance with the given id in the supplied parent CellDef.

Results:
Returns a pointer to the found CellUse, or NULL if it was not
found.

Side effects:
None.

DBIsChild --
------------

Test to see if cu1 is a child of cu2.

Results:
TRUE if cu1 is a child of cu2, FALSE otherwise.

Side effects:
None.

DBIsAncestor --
---------------

Determine if cellDef1 is an ancestor of cellDef2.

Results:
TRUE if cellDef1 is an ancestor of cellDef2, FALSE if not.

Side effects:
None.

DBInstanceAdd --
----------------

Make a celluse an instance.

flags:
DBIA_INFOMSG_ON_RENAME - print message when changing instance id
(to make it unique).

DBIA_ERROR_ON_RENAME   - generate error, if instance id not unique.

DBIA_INFOMSG_ON_DUP    - print message when not adding instance, since
exact duplicate already present.

DBIA_ERROR_ON_DUP      - generate error if exact dupicate instance already
present.

cellkid and cellpar sturctures are also updated.

This operation is not recorded on the undo list, as it always accompanies
the creation of a new cell use.

Results:
TRUE on success, FALSE on failure

Deletes use on failure.

DBInstanceUnlink --
-------------------

Update the use-id hash table in parentDef to reflect the fact
that 'use' no longer is known by instance-id use->cu_id.

Notfiy flyline (sub)module of instance change.

Results:
None.

Side effects:
See above.

DBInstanceRename --
-------------------

Change the instance id of the supplied CellUse.
If the instance id is non-NULL, and the new id is the same
as the old one, we do nothing.

Results:
Returns TRUE if successful, FALSE if the new name was not
unique within the parent def.

Side effects:
May modify the cu_id of the supplied CellUse.

DBInstancePlace --
------------------

Add a CellUse to the subcell tile plane of a CellDef.
Assumes prior check that the new CellUse is not an exact duplicate
of one already in place.

Results:
None.

Side effects:
Modifies the subcell tile plane of the given CellDef.
CellDef's parent pointer to point to the parent def.

DBInstanceUnplace --
--------------------

Remove a CellUse from the subcell tile plane of a CellDef.

Results:
None.

Side effects:
Modifies the subcell tile plane of the CellDef, sets the
parent pointer of the deleted CellUse to NULL.

DBLabelKindName --
------------------


Results:
Name string for label kind

DBLabelTypedText --
-------------------

Put label text, with prepended label kind id in nameBuf

DBLabelKindParse --
-------------------

convert kind name string to integer code.

Results:
Label kind, -1 on error.

DBLabelAlloc --
---------------

Allocate a label, copy text into it.

Label is not linked into a cell.  

See also: DBLabelLink() and DBLabelAddG() 

DBLabelDup --
-------------

Allocate a new label, and copy old label values into it.

Label is not linked into a cell.  
NOTE: new label does not inherit old labels group (since groups are per def) 

See also: DBLabelLink() and DBLabelAddG() 

DBLabelLink --
--------------

Link label into cell def.
If duplicate, frees (new) label and returns.

Goes to pains to add label to end of list (may be required by extractor?)

NOTE: there is no DBLabelUnlink() only DBLabelErase() - if you add
DBLabelUnlink(), beware that undoing a DBLabelLink() frees the label!

DBLabelEraseNext --
-------------------

unlink and free label with given next pointer
returns pointer to next label in cells list.

DBLabelAddG --
--------------

Place a rectangular label in the database, in given group in given cell.

Results:
The return value is the actual alignment position used for
the label.  This may be different from align, if align is
defaulted.

Side effects:
Updates the label list in the CellDef to contain the label.
Updates cd_labelHash 

DBLabelAdd --
-------------

Place a rectangular label in the database, in a particular cell
in the currently active group.

Results:
The return value is the actual alignment position used for
the label.  This may be different from align, if align is
defaulted.

Side effects:
Updates the label list in the CellDef to contain the label.

DBLabelErase --
---------------

Delete given label from given def.

DBLabelsEraseArea --
--------------------

Delete labels attached to tiles of the indicated types that
are in the given area (as determined by the macro GEO_LABEL_IN_AREA).  
If this procedure is called as part of a command that also modifies paint, 
then the paint modifications should be done BEFORE calling here.

Only erases labels from activeGroup 

Results:
TRUE if any labels were deleted, FALSE otherwise.

Side effects:
This procedure tries to be clever in order to avoid deleting
labels whenever possible.  If there's enough material on the
label's attached layer so that the label can stay on its
current layer, or if the label can be migrated to a layer that
connects to its current layer, then the label is not deleted.
Deleting up to the edge of a label won't cause the label
to go away.  There's one final exception:  if the mask includes
L_LABEL, then labels are deleted from all layers even if there's
still enough material to keep them around.

DBLabelsEraseByContentG --
--------------------------

Erase any labels found on the label list for the given
CellDef and specified group that match the given specification.

Results:
None.

Side effects:
Modifies the label list for the argument CellDef.  The
Layind module is notified about any labels that were
deleted.

DBLabelsEraseByContent --
-------------------------

Erase any labels found on the label list for the given
CellDef, that match the given specification.

Only labels in the currently active group are erased.

Results:
None.

Side effects:
Modifies the label list for the argument CellDef.  The
Layind module is notified about any labels that were
deleted.

DBLabelsClear --
----------------

Remove all labels from celldef.

DBSearchLabel --
----------------

Search for all occurrences of a point label matching the pattern in the
region rect in the indicated cell and all of its children.  On each label
matching the pattern found in the area, the supplied procedure is invoked.

The supplied procedure should be of the form
int
func(scx, label, tpath, cdarg)
SearchContext *scx;
Label *label;
TerminalPath *tpath;
ClientData cdarg;
{
}

In the above, scx is a search context specifying the cell use whose
def was found to contain the label, and label is a pointer to the
Label structure itself.  The transform specified in scx is from
coordinates of the def of the cell containing the label to "root"
coordinates.  Func should normally return 0.  If it returns 1 then
the search is aborted.

Results:
If the search terminates normally, 0 is returned.  1 is
returned if the search was aborted.

Side effects:
Applies the supplied procedure to each tile containing a label
matching the pattern.

WARNING: because of the way regex(3) works, it is possible to be
searching for at most one pattern at a time.

DBTreeFindUse --
----------------

This procedure finds the cell use with the given hierarchical name.

Results:
None.

Side effects:
Sets scx->scx_use to the cell use found, with scx->scx_trans
and scx->scx_x, scx->scx_y also valid.  If the cell was not
found, leaves scx->scx_use set to NULL.

DBSrLabelLoc --
---------------

This procedure finds the locations of all labels with a given
hierarchical name.  For each label found, a client-supplied
search function is called.  The search function has the form:

int
func(scx, rect, name, label, cdarg)
SearchContext *scx;
Rect *rect;
char *name;
Label *label;
ClientData cdarg;

Rect is the location of the label, in the coordinates of rootUse->cu_def,
name is the label's hierarchical name (just the parameter passed to us),
label is a pointer to the label, and cdarg is the client data passed in
to us by the client.  Note that there can be more than one label with the
same name.  Func should normally return 0.  If it returns 1, then the
search is aborted.

Results:
The return value is 0, unless func returned a non-zero value,
in which case the return value is 1.

Side effects:
Whatever the search function does.

DBSrLabelLocDef --
------------------

Just like DBSrlabelLoc() except first arg is def not use!

This procedure finds the locations of all labels with a given
hierarchical name.  For each label found, a client-supplied
search function is called.  The search function has the form:

int
func(scx, rect, name, label, cdarg)
SearchContext *scx;
Rect *rect;
char *name;
Label *label;
ClientData cdarg;

Rect is the location of the label, in the coordinates of rootUse->cu_def,
name is the label's hierarchical name (just the parameter passed to us),
label is a pointer to the label, and cdarg is the client data passed in
to us by the client.  Note that there can be more than one label with the
same name.  Func should normally return 0.  If it returns 1, then the
search is aborted.

Results:
The return value is 0, unless func returned a non-zero value,
in which case the return value is 1.

Side effects:
Whatever the search function does.

DBNearestLabel --
-----------------

This procedure finds the nearest label to a given point
and returns its hierarchical name and location.

Results:
Area is searched in cellUse to find the nearest label
to point.  TRUE is returned if any label was found.
If there is no label in the given area, FALSE is
returned.

Side effects:
The parameter labelArea is filled in with the location of
the label, if one was found.  LabelName is filled in with
the hierarchical name of the label.

DBTechNameType --
-----------------

Map from a type name into a type number.  If the type name has
the form "<type>/<plane>" and <type> is a contact, then the
type returned is the image of the contact on <plane>.  Of
course, in this case, <type> must have an image on <plane>.

Results:
Type number.  A value of -2 indicates that the type name was
unknown; -1 indicates that it was ambiguous.

Side effects:
None.

The following returns a bitmask with the appropriate types set for the
----------------------------------------------------------------------
typename supplied.  This is useful when searching for plane-qualified
images, where there may be more than one that fits the bill.

Results: returns the first type found

Side Effects: sets bitmask with the appropriate types.

DBTechNoisyNameType --
----------------------

Map from a type name into a type number, complaining if the type
is unknown.

Results:
Type number.  A value of -2 indicates that the type name was
unknown; -1 indicates that it was ambiguous.

Side effects:
Prints a diagnostic message if the type name is unknown.

DBTechNamePlane --
------------------

Map from a plane name into a plane number.

Results:
Plane number.  A value of -2 indicates that the plane name was
unknown; -1 indicates that it was ambiguous.

Side effects:
None.

DBTechNoisyNamePlane --
-----------------------

Map from a plane name into a plane number, complaining if the plane
is unknown.

Results:
Plane number.  A value of -2 indicates that the plane name was
unknown; -1 indicates that it was ambiguous.

Side effects:
Prints a diagnostic message if the type name is unknown.

DBTypeShortName --
------------------
DBPlaneShortName --

Return the short name for a type or plane.
The short name is the "official abbreviation" for the type or plane,
identified by a leading '*' in the list of names in the technology
file.

Results:
Pointer to the primary short name for the given type or plane.
If the type or plane has no official abbreviation, returns
a pointer to the string "???".

Side effects:
None.

DBTechTypesToPlanes --
----------------------

Convert a TileTypeBitMask into a mask of the planes which may
contain tiles of that type.

Results:
A mask with bits set for those planes in which tiles of
the types specified by the mask may reside.  The mask
is guaranteed only to contain bits corresponding to
paint tile planes.

Side effects:
None.

DBTechPrintTypes --
-------------------

This routine prints out all the layer names for types defined
in the current technology.

Results:
None.

Side effects:
Stuff is printed.

DBTechNoisyNameMask --
----------------------

Parses an argument string that selects a group of layers.
The string may contain one or more layer names separated
by commas.  The special layer name of "0" specifies no layer,
it is used as a place holder, e.g., to specify a null
layer list for the CornerTypes field in a drc edge-rule.
In addition, a tilde may be used to indicate
"all layers but", and parentheses may be used for grouping.
Thus ~x means "all layers but x", and ~(x,y),z means "z plus
everything except x and y)".  When contacts are specified,
ALL images of the contact are automatically included, unless
a specific plane is indicated in the layer specification
using "/".  For example, x/foo refers to the image of contact
"x" on plane "foo".  The layer specification may also follow
a parenthesized group.  For example, ~(x,y)/foo refers to
all layers on plane "foo" except "x" and "y".

Results:
None.

Side effects:
Error messages are output if layers aren't understood.
Sets the TileTypeBitMask 'mask' to all the layer names indicated.

DBTechMinSetPlanes --
---------------------

Given a TileTypeBitMask, find the minimum set of planes that
contains one image for each of the tile types in the mask.
Also return a new tile type mask that contains the images
of the original tiles that fall in the result planes.

WARNING: must be called AFTER all the database technology
initialization has completed.

Results:
A mask of planes.

Side effects:
The parameter newTypes is modified.

DBTechSubsetLayers --
---------------------

Eliminate all bits from one mask that aren't in another, and
check to be sure that this elimination only occurs for contact
types that will still have one image in the result.

Results:
TRUE is returned if the subsetting was successful.  Success
means that for each layer in "src", the corresponding layer
is in "mask" or else "src" contains another image of the bit
that is in "mask".

Side effects:
The mask pointed to by "result" is modified to contain the
subset of "src" that is in "mask".

DBTechAddPlane --
-----------------

Define a tile plane type for the new technology.

Results:
TRUE if successful, FALSE on error

Side effects:
Updates the database technology variables.
In particular, updates the number of known tile planes.

DBTechAddType --
----------------

Define a tile type for the new technology.

Results:
TRUE if successful, FALSE on error

Side effects:
Updates the database technology variables.
In particular, updates the number of known tile types.

DBTechFinalType --
------------------

After processing the types and planes sections, compute the
various derived type and plane masks and tables.

Results:
None.

Side effects:
Initializes DBNumUserLayers to be DBNumTypes at the time
this procedure is called, since none of the automatically
generated plane images have yet been created.
Initializes the following bit masks:
DBAllTypeBits
DBSpaceBits
DBBuiltinLayerBits
DBAllButSpaceBits
DBAllButSpaceAndDRCBits
DBUserLayerBits
DBNonSpaceUserLayerBits
DBFlyLineBits

DBNextEdge --
-------------

Find next edge in given direction.

Results:
pointer to statically allocated point of intersection between ray from 
starting point in given direction and the edge that was found.

NULL if no edge found.

NOTE:  boundary conditions handled carefully to make code using this
routine direction independent.  e.g. we hide which edges are contained
in a tile from caller.

DBNextDistance --
-----------------

Find next point in given direction where distance to edge changes on given
side (right-side or left-side)

Results:
Final point.

NOTE:  boundary conditions handled carefully to make code using this
routine direction independent.  e.g. we hide which edges are contained
in a tile from caller.

DBNextEdgeH --
--------------

Find next edge in given direction.
Like DBNextEdge(), but hierarchical (looks at instances)

Results:
point of intersection between ray from 
starting point in given direction and the edge that was found.

NULL if no edge found.

NOTE:  boundary conditions handled carefully to make code using this
routine direction independent.  e.g. we hide which edges are contained
in a tile from caller.

DBNextDistanceH --
------------------

Find next point in given direction where distance to edge changes on given
side (right-side or left-side)
Like DBNextDistance(), but hierarchical (looks at instances)

Results:
new point.

NOTE:  boundary conditions handled carefully to make code using this
routine direction independent.  e.g. we hide which edges are contained
in a tile from caller.

DBNextLargestBoxInit --
-----------------------

Resets planes for DBNextLargestBox.

DBNextLargestBox --
-------------------

Find largest box containing point on layer, without width change.
(Hierarchical (looks at subcells))

Results:
largest box.

DBPaintPlaneG --
----------------

Paint a rectangular area ('area') on a single tile plane ('plane'), for 
a specified group.

The argument 'resultTbl' is a table, indexed by the type of each tile
found while enumerating 'area', that gives the result type for this
operation.  The semantics of painting, erasing, and "writing" (storing
a new type in the area without regard to the previous contents) are
all encapsulated in this table. 

If undo is desired, 'undo' should point to a PaintUndoInfo struct
that contains everything needed to build an undo record.  Otherwise,
'undo' can be NULL.

Results:
None.

Side effects:
Modifies the database plane that contains the given tile.

REMINDER:
Callers are responsible for change notification on the cell
being modified

DBPaintPlane --
---------------

Paint a rectangular area ('area') on a single tile plane ('plane'), for 
group 0.

See documentation for DBPaintPlaneG().

DBPaintPlaneMergeOnce --
------------------------

This routine used in place of DBPaintPlane above by drc.
Unlike DBPaintPlane, it is non interruptable.
NOTE:  CURRENTLY this routine is not "group aware"

Paint a rectangular area ('area') on a single tile plane ('plane').
This is identical to DBPaintPlane(), except that we work in two
passes:

Pass 1: clip all tiles to lie inside the area to be painted,
merging all outside tiles as required.  Change the
types of each of these internal tiles.

Pass 2:	re split and merge to insure that the database is
once again in maximal horizontal strips.

See DBPaintPlane for other comments.

Results:
None.

Side effects:
Modifies the database plane that contains the given tile.

DBPaint --
----------

Paint a rectangular area with a specific tile type.
All paint tile planes in cellDef are painted.

Up to caller to call DBChangedArea() to notify of change.

Results:
None.

Side effects:
Modifies potentially all paint tile planes in cellDef.

DBErase --
----------

Erase a specific tile type from a rectangular area.
The plane in which tiles of the given type reside is modified
in cellDef.

Up to caller to call DBChangedArea()

Results:
None.

Side effects:
Modifies potentially all paint tile planes in cellDef.

DBEraseG --
-----------

Erase a specific tile type from a rectangular area.
The plane in which tiles of the given type reside is modified
in cellDef.

Only the active group is erased.

Up to caller to call DBChangedArea()

Results:
None.

Side effects:
Modifies potentially all paint tile planes in cellDef.

DBPaintMask --
--------------

Paint a rectangular area with all tile types specified in the
mask supplied.

Results:
None.

Side effects:
Modifies potentially all paint tile planes in cellDef.

DBEraseMask --
--------------

Erase a rectangular area with all tile types specified in the
mask supplied.

Results:
None.

Side effects:
Modifies potentially all paint tile planes in cellDef.

DBEraseMask --
--------------

Erase a rectangular area with all tile types specified in the
mask supplied.

Results:
None.

Side effects:
Modifies potentially all paint tile planes in cellDef.

DBTechInitCompose --
--------------------

Initialize the painting and erasing rules prior to processing
the "compose" section.  The rules for builtin types are computed
here, as well as the default rules for all other types.  This
procedure must be called after the "types" and "contacts" sections
have been read, since we need to know about all existing tile types.

Results:
None.

Side effects:
Modifies the paint and erase tables.

DBTechAddCompose --
-------------------

Process a single compose/erase rule.  If the type being described is
a contact, save the rule and defer processing it until the end of this
section, because we need to know the behavior of all non-contact types
that might be residues before processing a contact composition rule.
Rules for non-contact types are processed here.

Results:
TRUE if successful, FALSE on error.

Side effects:
Modifies the paint/erase tables if the type being described
is not a contact; otherwise, appends a rule to the list of
contact erase/compose rules for later processing.  Marks the
paint/erase table entries affected to show that they contain
user-specified rules instead of the default ones, so we don't
override them later.

DBTechFinalCompose --
---------------------

Process all the contact erase/compose rules saved by DBTechAddCompose
when it was reading in the "compose" section of a technology file.
Also sets up the default paint/erase rules for contacts.

Since by the end of this section we've processed all the painting
rules, we initialize the tables that say which planes get affected
by painting/erasing a given type.

There's a great deal of work done here, so it's broken up into a
number of separate procedures, each of which implements a single
operation or default rule.  Most of the work deals with painting
and erasing contacts.

Results:
None.

Side effects:
Modifies the paint/erase tables.
Initializes DBTypePaintPlanesTbl[] and DBTypeErasePlanesTbl[].

DBPlaneNew --
-------------

Allocates and initializes a new tile plane for a cell.
The new plane contains a single tile whose body is specified by
the caller.  The tile extends from minus infinity to plus infinity.

Results:
Returns a pointer to a new tile plane.

Side effects:
None.

DBFreePaintPlane --
-------------------

Deallocate all tiles in a paint tile plane of a given CellDef.
Don't deallocate the four boundary tiles, or the plane itself.

This is a procedure internal to the database.  

Results:
None.

Side effects:
Deallocates a lot of memory.  

*** WARNING ***

This procedure uses a carfully constructed non-recursive area 
enumeration algorithm.  Care is taken to not access a tile that has
been deallocated.  The only exception is for a tile that has just been
passed to TiFree(), but no more calls to TiFree() or TiAlloc() have been made.  
All this care is obsolete!  As long as no TiAlloc() calls are made 
and ti_client fields of freed tiles are not referenced, everything 
is hunky-doory.

DBPlaneClearPaint --
--------------------

Similar in effect to painting space over an entire tile plane, but
much faster.  The resultant tile plane is guaranteed to contain a
single central space tile, exactly as though it had been newly allocated.

Results:
None.

Side effects:
Modifies the database plane given.

DBPlaneResetClients --
----------------------

Reset the ti_client fields of all tiles in a paint tile plane to
the value 'cdata'.

Results:
None.

Side effects:
Resets the ti_client fields of all tiles.

DBPlaneCheckMaxHStrips --
-------------------------

Check the maximal horizontal strip property for the
tile plane 'plane' over the area 'area'.

Results:
Normally returns 0; returns 1 if the procedure
(*proc)() returned 1 or if the search were
aborted with an interrupt.

Side effects:
Calls the procedure (*proc)() for each offending tile.
This procedure should have the following form:

int
proc(tile, side, cdata)
Tile *tile;
int side;
ClientData cdata;
{
}

The client data is the argument 'cdata' passed to us.
The argument 'side' is one of GEO_NORTH, GEO_SOUTH,
GEO_EAST, or GEO_WEST, and indicates which side of
the tile the strip property was violated on.
If (*proc)() returns 1, we abort and return 1
to our caller.

DBPlaneCheckMaxVStrips --
-------------------------

Check the maximal vertical strip property for the
tile plane 'plane' over the area 'area'.

Results:
Normally returns 0; returns 1 if the procedure
(*proc)() returned 1 or if the search were
aborted with an interrupt.

Side effects:
See DBPlaneCheckMaxHStrips() above.

DBPlaneEnumAreaInstances --
---------------------------

Search the cell plane of a def over the specified area.

Applies the given procedure to each non space (i.e. subcell) tile found.
The procedure should be of the following form:

int
func(tile, cdata)
Tile *tile;
ClientData cdata;
{
}

Func normally should return 0.  If it returns 1 then the search
will be aborted.  

WARNING: THE CALLED PROCEDURE MUST NOT MODIFY THE PLANE BEING SEARCHED!

WARNING: THE ORDER OF ENUMERATION (NW TO SE WAVEFRONT) IS RELIED UPONT
BY DBInstancePlace() AND DBInstanceUnplace()

Results:
0 is returned if the search completed normally.  1 is returned
if it aborted.

DBPlaneEnumAreaPaint --
-----------------------

Find all tiles overlapping a given area whose types are contained
in the mask supplied.  Apply the given procedure to each such tile.
The procedure should be of the following form:

int
func(tile, cdata)
Tile *tile;
ClientData cdata;
{
}

Func normally should return 0.  If it returns 1 then the search
will be aborted.  WARNING: THE CALLED PROCEDURE MAY NOT MODIFY
THE PLANE BEING SEARCHED!!!


Results:
0 is returned if the search completed normally.  1 is returned
if it aborted.

NOTE:  for searching PL_CELL plane (subcell plane) use
DBPlaneEnumAreaInstances() instead.

DBPlaneEnumAreaPaintG --
------------------------

Like DBPlaneEnumAreaPaint, but enumerates given group.

Find all tiles overlapping a given area whose types are contained
in the mask supplied.  Apply the given procedure to each such tile.
The procedure should be of the following form:

int
func(tile, cdata)
Tile *tile;
ClientData cdata;
{
}

Func normally should return 0.  If it returns 1 then the search
will be aborted.  WARNING: THE CALLED PROCEDURE MAY NOT MODIFY
THE PLANE BEING SEARCHED!!!


Results:
0 is returned if the search completed normally.  1 is returned
if it aborted.

NOTE:  for searching PL_CELL plane (subcell plane) use
DBPlaneEnumAreaInstances() instead.

DBPlaneEnumAreaPaintClient --
-----------------------------

Find all tiles overlapping a given area whose types are contained
in the mask supplied, and whose ti_client field matches 'client'.
Apply the given procedure to each such tile.  The procedure should
be of the following form:

int
func(tile, cdata)
Tile *tile;
ClientData cdata;
{
}

Func normally should return 0.  If it returns 1 then the search
will be aborted.

Results:
0 is returned if the search completed normally.  1 is returned
if it aborted.

Side effects:
Whatever side effects result from application of the
supplied procedure.

DBPointsAlloc --
----------------

Malloc a new point array, and copy in to it

if in is NULL, no initialization.

DBPointsFree --
---------------

Free point array.

if in is NULL, no copy is done.

DBPointsBBox --
---------------

compute bbox of point array.

NOTE: result is overwritten on next call.

DBPointsDump --
---------------

print points for debugging.

DBPolyNew --
------------

Create new polygon.  
If def is not null, links polygon into def.
if def non-null, and not part of wirepath (notifies undo)

Returns:
pointer to new polygon  

Side effects:
Calls the undo package.

NOTE: points array will be FREEd when polygon is deleted!

DBPolyDelete --
---------------

Delete polygon.  
If def is not null, unlinks polygon from def.
if def non null (and not part of wirepath) undo is notified.

NOTE: frees polygons point array. 

DBPolygonCopy --
----------------

Copy polygon. 
If def is not null, links polygon into def.
If trans, not null, transforms polygon while copying.

Returns:
pointer to new polygon  

Side effects:
Notifys undo package (if polygon is linked into def)

DBPolyFind --
-------------

Find polygon in def matching the given specification

Returns pointer to matching Polygon (NULL if none found).

DBPolygonIntersectRectQ1 --
---------------------------

Does real work for inline func DBPolygonIntersectQ()

Check for intersection between polygon and rect.
Two point polygons are treated as circle inscribed in
"polygon" bbox.

Returns TRUE if "poly" intersected with the closed rectangle
"rect" is non-empty and FALSE otherwise.

NOTE: assumes rect is not inverted:  "ll.x < ur.x" and "ll.y < ur.y"

NOTE: assumes caller has already checked that following special cases
do not hold:
1. polygon bbox contained in rect.
2. polygon bbox and rect disjoint.

DBPolygonIntersectRect1 --
--------------------------

Does real work for inline function DBPolygonIntersectRect()

This routine clips "poly" against "rect".  

RETURNS the number of resulting polygons, >= 0.

storage is allocated for and:
dbPolyPoints is filled in with points for the clipped polygon(s).
dbPolyList is filled in with pointers to the start of the points 
for each polygon in the result.  An additional final entry 
in "list" points one beyond the end of the points in clip.
This is so "list[i+1] - list[i]" always gives the number 
of points in polygon i (which start at "list[i]").
THESE DATA AREAS ARE REUSED ON NEXT CALL.

*listp is set to point to dbPolyList.

This algorithm is based on "Efficient Clipping of Arbitrary Polygons"
by Gunther Greiner and Kai Hormann, ACM Transactions on Graphics,
Vol. 17, No. 4, April 1998, pages 71-83.  It has been specialized
for one of the polygons being a rectangle (in places).


NOTE:  results are overwritten on next call to this routine.

NOTE: assumes rect is not inverted:  "ll.x < ur.x" and "ll.y < ur.y"

NOTE: assumes caller has already checked that following special cases
do not hold:

1. polygon bbox contained in rect.
2. polygon bbox and rect disjoint.

NOTE:

DBPolygonIntersectPolyQ1 --
---------------------------

Does real work for inline func DBPolygonIntersectPolyQ()

Check for intersection between polygon and polygon.
Two point polygons (circles) are not treated.

Returns TRUE if "poly1" intersected with "poly2" 
is non-empty and FALSE otherwise.

NOTE: assumes rect is not inverted:  "ll.x < ur.x" and "ll.y < ur.y"

NOTE: assumes caller has already checked that following special case
do not hold:
1. poly1 bbox and poly2 bbox.

DBPolygonIntersectPolygonQ1 --
------------------------------

Does real work for inline func DBPolygonIntersectPolygonQ()

RETURNS:  TRUE if one polygon, "poly1", intersected with another
polygon, "poly2", is non-empty and FALSE otherwise.


NOTE: Caller (DBPolygonIntersectPolygonQ) handles case where polygon
bboxes are disjoint.

DBPropInitDef --
----------------

Called when def initialized to set up property hash table.

DBPropSet --
------------

Set property value.

(if value is NULL, delete property) 

DBPropGet--
-----------

get property value

DBPropEnum --
-------------

call supplied func on each property in def

DBPropClearDef --
-----------------

clear all properties and reclaim associated storage
(used to when restoring cell to initial (empty) state) 

DBPropFreeDef --
----------------

Free all properties and reclaim associated storage
(used when deallocating celldef)

DBGetTech --
------------

Reads the first few lines of a file to find out what technology
it is.

Results:
The return value is a pointer to a string containing the name
of the technology of the file containing cell cellName.  NULL
is returned if the file couldn't be read or isn't in Magic
format.  The string is stored locally to this procedure and
will be overwritten on the next call to this procedure.

Side effects:
None.

DBCellRead --
-------------

If the cell is already marked as available (CDAVAILABLE), do nothing.

If the cell is generated (a gcell) call tcl proc "gcell_load name"   
and set CDAVAILABLE

Otherwise, read in the paint for a cell from its associated disk file.
If a filename for the cell is specified, we try to open it
somewhere in the search path.  Otherwise, we try the filename
already associated with the cell, or the name of the cell itself
as the name of the file containing the definition of the cell.

Mark the cell definition as "read in" (CDAVAILABLE), and
call DBChangedArea() to process database changes.

Results:
TRUE if the cell could be read successfully, FALSE
otherwise.  If the cell is already read in, TRUE is
also returned.

Side effects:
Updates the cell definition.
In the event of an error while reading in the cell,
the external integer errno is set to the UNIX error
encountered.

The cell definition is marked as available.
The cell's MODIFIED bit is cleared by this routine. 

DBCellReadTree --
-----------------

Read in entire cell tree rooted at def.  
Does not read in cells already in memory.

DBSrChildrenSAVECODEFORNOW --  
-------------------------------

Applys func to EVERY child of scx def in search area.
Used by DBSearch routines (as well as similiar routines in other modules)
to implement hierarchical searches.

Apply the supplied procedure to each of the cellUses found in the
given area in the subcell plane of the child def of the supplied
search context.

The procedure is applied to each array element in each cell use that
overlaps the clipping rectangle.  The scx_x and scx_y parts of
the SearchContext passed to the filter function correspond to the
array element being visited.  The same CellUse is, of course, passed
as scx_use for all elements of the array.

The array elements are visited by varying the X coordinate fastest.

The procedure should be of the following form:
int
func(scx, cdarg)
SearchContext *scx;
ClientData cdarg;
{
}

Func normally returns 0.  If it returns 1 then the search is
aborted.  If it returns 2, then any remaining elements in the
current array are skipped.

Results:
0 is returned if the search terminated normally.  1 is
returned if it was aborted.

Side effects:
Whatever side effects are brought about by applying the
procedure supplied.

DBSrChildrenNested --
---------------------

Like DBSrChildren() above, but does not update cu_bbox of root use.
(This is useful for recursive DBSrChildren() calls when cells read in,
since it doesn't screw up the PL_CELL plane of the "parent" search)  

Apply the supplied procedure to each of the cellUses found in the
given area in the subcell plane of the child def of the supplied
search context.

The procedure is applied to each array element in each cell use that
overlaps the clipping rectangle.  The scx_x and scx_y parts of
the SearchContext passed to the filter function correspond to the
array element being visited.  The same CellUse is, of course, passed
as scx_use for all elements of the array.

The array elements are visited by varying the X coordinate fastest.

The procedure should be of the following form:
int
func(scx, cdarg)
SearchContext *scx;
ClientData cdarg;
{
}

Func normally returns 0.  If it returns 1 then the search is
aborted.  If it returns 2, then any remaining elements in the
current array are skipped.

Results:
0 is returned if the search terminated normally.  1 is
returned if it was aborted.

Side effects:
Whatever side effects are brought about by applying the
procedure supplied.

DBSrPrintUseId --
-----------------

Generate the print name of the use identifier indicated by the supplied
SearchContext.

Results:
Returns a pointer to the NULL byte at the end of the string
generated.

Side effects:
The character string pointed to by name is set to contain the use
id of scx->scx_use followed by any array indices.  If scx->scx_use
is a two dimensional array, the array indices are of the form [y,x],
otherwise there is a single array index either of the form [y] or [x].
The array indices are taken from scx->scx_x and scx->scx_y.  At most
size characters are copied into the string pointed to by name.

DBSearchPaintNew2 --
--------------------

Recursively search downward from the supplied CellUse for
all visible paint tiles and/or polygons matching the supplied type mask.

The callback procedures should be of the following form:
int func(Tile *tile,TreeContext *cxp);
int polygonFunc(SearchContext *scx, 
Polygon *poly, 
ClientData cdarg)
int wirePathFunc(SearchContext *scx, 
WirePath *wp, 
ClientData cdarg)

If tpath is nonnull a 4th tpath arg is appended to polygonFunc() and
wirePathFunc().

To search only tiles or only polygons set the other func arg to NULL.

The SearchContext is stored in cxp->tc_scx, and the user's arg is stored
in cxp->tc_filter->tf_arg.

In the above, the scx transform is the net transform from the coordinates
of tile to "world" coordinates (or whatever coordinates the initial
transform supplied to DBSearchPaint was a transform to).  Func and 
polygonFunc return 0 under normal conditions.  If 1 is returned, 
it is a request to abort the search.

*** WARNING ***

The client procedure should not modify any of the paint planes in
the cells visited by DBSearchPaint, because we use DBPlaneEnumAreaPaint
as our paint-tile enumeration function.

Results:
0 is returned if the search finished normally.  1 is returned
if the search was aborted.

Side effects:
Whatever side effects are brought about by applying the
procedure supplied.

DBSearchLabels --
-----------------

Recursively search downward from the supplied CellUse for
all visible labels attached to layers matching the supplied
type mask.

The procedure should be of the following form:
int
func(scx, label, tpath, cdarg)
SearchContext *scx;
Label *label;
TerminalPath *tpath;
ClientData cdarg;
{
}

In the above, the use associated with scx is the parent of the
CellDef containing the tile which contains the label, and the
transform associated is the net transform from the coordinates
of the tile to "root" coordinates.  Func normally returns 0.  If
func returns 1, it is a request to abort the search without finding
any more labels.

Results:
0 is returned if the search terminated normally.  1 is returned
if the search was aborted.

Side effects:
Whatever side effects are brought about by applying the
procedure supplied.

DBSearchFlyLines --
-------------------

Recursively search downward from the supplied CellUse for
all visible flylines.

The procedure should be of the following form:

int func(scx *SearchContext, FlyLine *flyline, Clientdata cdarg)

In the above, the use associated with scx is the parent of the
CellDef containing the fly line, and the
transform associated is the net transform from the coordinates
of the use to "root" coordinates.  Func normally returns 0.  If
func returns 1, it is a request to abort the search without finding
any more flylines.

Results:
0 is returned if the search terminated normally.  1 is returned
if the search was aborted.

Side effects:
Whatever side effects are brought about by applying the
procedure supplied.

DBSearchInstances --
--------------------

Recursively search downward from the supplied CellUse for
all CellUses whose parents are expanded but which themselves
are unexpanded (unless DBSI_INCLUDE_EXPANDED set).

The procedure should be of the following form:
int func(SearchContext *scx, ClientData cdarg) {}

If tpath is nonnull a 3rd tpath arg is added to the procedure call.

In the above, the transform scx->scx_trans is from coordinates of
the def of scx->scx_use to the "root".  The array indices
scx->scx_x and scx->scx_y identify this element if it is a
component of an array.  Func normally returns 0.  If func returns
1, then the search is aborted.  If func returns 2, then all
remaining elements of the current array are skipped, but the
search is not aborted.

Each element of an array is returned separately.

Results:
0 is returned if the search terminated normally.  1 is
returned if it was aborted.

Side effects:
Whatever side effects are brought about by applying the
procedure supplied.

DBSrTouchingTypes --
--------------------

Generate mask of all types touching or covering a given point. 

Results:
Mask of all types touching or covering a given point in cellUse or
expanded subcell.  If an unexpanded subcell is 
covering or touching point TT_SUBCELL is included in the result as
well.

Side effects:
None.

DBTclInit --
------------

Initialize database tcl commands.

Results:
None.

Side effects:
Registers command(s) with tcl.

DBTechInit --
-------------

Clear technology description information for database module.
CURRENTLY A NO-OP.  EVENTUALLY WILL CLEAR OUT ALL TECHNOLOGY
VARIABLES PRIOR TO REINITIALIZING A NEW TECHNOLOGY.

Results:
None.

Side effects:
None.

DBTechSetTech --
----------------

Set the name for the technology.

Results:
Returns FALSE if there were an improper number of
tokens on the line.

Side effects:
Sets DBTechName to the name of the technology.

DBTechSetVersion --
-------------------

Set the version number & description for the technology.

Results:
Returns FALSE if there were an improper number of
tokens on the line.

Side effects:
Sets DBTechVersion and DBTechDescription.

DBTechInitConnect --
--------------------

Initialize the connectivity tables.

Results:
None.

Side effects:
Initializes DBConnectTbl[], DBConnPlanes[], and DBAllConnPlanes[].

DBTechAddConnect --
-------------------

Add connectivity information.
Record the fact that material of the types in the comma-separated
list types1 connects to material of the types in the list types2.

Results:
TRUE if successful, FALSE on error

Side effects:
Updates DBConnectTbl[].

DBTechFinalConnect --
---------------------

Postprocessing for the connectivity information.
Modify DBConnectTbl[] so that:

(1) Any type connecting to one of the images of a contact
connects to all images of the contact.
(2) Each image of a contact connects to the union of what
all the images connect to.

Modify DBConnPlanes[] so that only types belonging to a contact
appear to connect to any plane other than their own.

Constructs DBAllConnPlanes, which will be non-zero for those planes
to which each type connects, exclusive of that type's home plane and
those planes to which it connects as a contact.

Create DBNotConnectTbl[], the complement of DBConnectTbl[].

Results:
None.

Side effects:
Modifies DBConnPlanes[], DBAllConnPlanes[], and DBConnectTbl[]
as above.

DBUndoFlush --
--------------

Called by undo module whenever the undo stack is flushed.
database module.

DBUndoPutLabel --
-----------------

Record on the undo list the painting of a new label.

Results:
None.

Side effects:
Updates the undo list.

DBUndoEraseLabel --
-------------------

Record on the undo list the erasing of an existing label

Results:
None.

Side effects:
Updates the undo list.

DBUndoAddPoly --
----------------

Record a polygon add on the undo list.

Results:
None.

Side effects:
Updates the undo list.

DBUndoDeletePoly --
-------------------

Record polygon deletion on undo list.

Results:
None.

Side effects:
Updates the undo list.

DBUndoAddWP --
--------------

Record a wirepath add on the undo list.

Results:
None.

Side effects:
Updates the undo list.

DBUndoDeleteWP --
-----------------

Record wirepath deletetion on undo list.

Results:
None.

Side effects:
Updates the undo list.

DBUndoCellUse --
----------------

Record one of the following subcell actions:
UNDO_CELL_PLACE		placement in a parent
UNDO_CELL_DELETE	removal from a parent
UNDO_CELL_CLRID		deleting the use id
UNDO_CELL_SETID		setting the use id

The last two, deleting and setting the use id, normally occur in
pairs except when the name is set for the first time.

Because both the parent and child cell uses are stored
in the def, we don't bother to use or update dbUndoLastCell.

Results:
None.

Side effects:
Updates the undo list.

DBUpdate1 --
------------

Does the real work for inline DBUpdate().
Make all bboxes in cell tree rooted at def up-to-date
Make drc change areas up-to-date for tree rooted at def

DBWPathEnumPolygons --
----------------------

calls func for each (implicit) polygon in wirepath.

func should returns 0 to continue search, 1 to abort search.

Results:
0 is returned if the search finished normally.  1 is returned
if the search was aborted.

NOTE: (re)creates polygon points, does not search for them!

DBWPathNew --
-------------

Create new WirePath
If def is not null, links polygon into def.
if def non-null, notify undo

Returns:
pointer to new wirepath

Side effects:
Calls the undo package.

NOTE: points array will be FREEd when polygon is deleted!

DBWPathDelete --
----------------

Delete wirepath.  
If def is not null, unlinks wp from def.
if def non null undo is notified.

NOTE: frees wirepaths point array. 

DBWPathFind --
--------------

Find wirepath in def matching the given specification

Returns pointer to matching wirepath (NULL if none found).

DBWirePathIntersectRectQ1 --
----------------------------

Does real work for inline func DBWirePathIntersectQ()

Check for intersection between wirepath and rect.

Returns TRUE if "wp" intersected with the closed rectangle
"rect" is non-empty and FALSE otherwise.

NOTE: assumes rect is not inverted:  "ll.x < ur.x" and "ll.y < ur.y"

NOTE: assumes caller has already checked that following special cases
do not hold:
1. wp bbox contained in rect.
2. wp bbox and rect disjoint.

DBWirePathIntesectPolygonQ --
-----------------------------

Does real work for inline DBWirePathIntersectPolygonQ()

Returns TRUE if "wp" intersects the polygon

NOTE: assumes caller handles following special case:
wp bbox and poly bbox disjoint.

DBCellWrite --
--------------

Write a cell to its associated disk file.
Mark the cell as having been written out. 

This code is fairly tricky to ensure that we never destroy the
original contents of a cell in the event of an I/O error.  We
try the following approaches in order.

1.	If we can create a temporary file in the same directory as the
target cell, do so.  Then write to the temporary file and rename
it to the target cell name.

2.	If we can't create the above temporary file, open the target
cell for APPENDING, then write the new contents to the END of
the file.  If successful, rewind the now-expanded file and
overwrite the beginning of the file, then truncate it.

Results:
TRUE if the cell could be written successfully, FALSE otherwise.

Side effects:
Writes a file to disk.
If successful, clears the CDMODIFIED
in cellDef->cd_flags.

In the event of an error while writing out the cell,
the external integer errno is set to the UNIX error
encountered, and the above bits are not cleared in
cellDef->cd_flags.

BUG:  Currently on some errors CDMODIFIED is set.   2/17/95 mha
BUG:  (cont.) other flags are left cleared.         2/17/95 mha 

DBPanicSave --
--------------

Save all modified cells to disk, in files "cellname.max_panic_save".
This is intended as an emergency measure for cases when max
has to die (eg, upon receiving a SIGTERM signal).  

Results:
None.

Side effects:
Writes cells to disk.
Does NOT clear the modified bits.

DRCArrayCheck --
----------------

This procedure finds all DRC errors in a given area of
a given cell that stem from array formation errors in
children of that cell.  Func is called for each violation
found.  Func should have the same form as in DRCBasicCheck.
Note: the def passed to func is the dummy DRC definition,
and the errors are all expressed in coordinates of celluse.

Results:
The number of errors found.

Side effects:
Whatever is done by func.

DRCBasicCheck --
----------------

This is the top-level routine for basic design-rule checking.

Results:
Number of errors found.

Side effects:
Calls function for each design-rule violation in celldef
that is triggered by an edge in rect and whose violation
area falls withing clipRect.  This routine makes a flat check:
it considers only information in the paint planes of celldef,
and does not expand children.  Function should have the form:
void
function(def, area, rule, cdarg)
CellDef *def;
Rect *area;
DRCCookie *rule;
ClientData cdarg;
{
}

In the call to function, def is the definition containing the
basic area being checked, area is the actual area where a
rule is violated, rule is the rule being violated, and cdarg
is the client data passed through all of our routines.

Note:
If an interrupt occurs (SigInterruptPending gets set), then
the basic will be aborted immediately.  This means the check
may be incomplete.

DRCChangedArea --
-----------------

Mark area in def for redrc.

Paints check tile into the DRC_CHECK plane of the cell,
and sets the CD_DRC_PENDING flag.

DRCChangeAddDef --
------------------

Call the drc's attention to a def.  (continuous drc will check
for TT_CHECKPAINT areas.

DRCInit --
----------

This procedure initializes DRC data.  It must be called after
the technology file has been read.

Results:
None.

Side effects:
Owns shared between the DRC modules are initialized.

DRCContinuous --
----------------

Called by toplevel event loop in main(), prior to blocking to
wait for new events.

This routine checks to see if there are any areas of the layout that
need to be design-rule-checked.  If so, it does the appropriate checks.
This procedure will abort itself at the earliest convenient moment
if events pending.

NOTE:  Tcl_DoOneEvent called to check for new events, 
events may be processed "inside" this procedure, but no
"do when idle" events (such as redisplay) 
will be processed before exiting this procedure.

Results:
Returns 0 if there was nothing to do, 1 otherwise.

Side effects:
Modifies the DRC_CHECK and DRC_ERROR planes 
of the CellDefs on the DRCPending list.

DRCPrintStats --
----------------

Prints out statistics gathered by the DRC checking routines.

Results:
None.

Side effects:
Statistics are printed.  Two values are printed for each
statistic:  the number since statistics were last printed,
and the total to date.	The own variables used to keep
track of statistics are updated.

DRCWhy --
---------

This procedure finds all errors within an area and prints messages
about each distinct kind of violation found.

Results:
None.

Side effects:
None, except that error messages are printed.  The given
area is DRC'ed for both paint and subcell violations in every
cell of def's tree that it intersects.

DRCCheck --
-----------

Marks area, to force recheck by the DRC. 

Results:
None.

Side effects:
Check tiles are painted.

DRCCount --
-----------

Searches the entire hierarchy underneath the given area.
For each cell found, counts design-rule violations in
that cell and outputs the counts.

Results:
None.

Side effects:
None, except for the text output.

DRCCatchUp--
------------

This procedure just runs the background checker, regardless
of whether it's enabled or not, and waits for it to complete.

Results:
None.

Side effects:
Error and check tiles get painted and erased by the checker.

DRCFind --
----------

Locates the next violation tile in the cell pointed to by def.
Successive calls will located successive violations, in
circular order.

Results:
If an error tile was found in def, returns the indx of
the error tile (> 0).  Returns 0 if there were no error
tiles in def, or if a specific indx was given and there
weren't that many error tiles in def.

Side effects:
Rect is filled with the location of the tile, if one is found.

DRCClean --
-----------

Called to declare a def drc correct (whether it really is or not).
Rms all check areas, syncs up instance versions, rms all drc error
tiles.

Subsequent changes will cause areas to be checked.

DRCPrintRulesTable --
---------------------

Write compiled DRC rules table and adjacency matrix to the given file.

Results:
None.

Side effects:
None.

DRCFindInteractions --
----------------------

This procedure finds the bounding box of all subcell-subcell
or subcell-paint interactions in a given area of a given cell.

Results:
Returns TRUE if there were any interactions in the given
area, FALSE if there were none.

Side effects:
The parameter interaction is set to contain the bounding box
of all places in area where one subcell comes within radius
of another subcell, or where paint in def comes within radius
of a subcell.  Interactions between elements of array are not
considered here, but interactions between arrays and other
things are considered.  This routine is a bit clever, in that
it not only checks for bounding boxes interacting, but also
makes sure the cells really contain material in the interaction
area.

DRCInteractionCheck --
----------------------

This is the top-level procedure that performs subcell interaction
checks.  All interaction rule violations in area of def are
found, and func is called for each one.

Results:
The number of errors found.

Side effects:
The procedure func is called for each violation found.  See
the header for DRCBasicCheck for information about how func
is called.  The violations passed to func are expressed in
the coordinates of def.  Only violations stemming from
interactions in def, as opposed to def's children, are reported.

Design Note:
This procedure is trickier than you think.  The problem is that
DRC must be guaranteed to produce EXACTLY the same collection
of errors in an area, no matter how the area is checked.  Checking
it all as one big area should produce the same results as
checking it in several smaller pieces.  Otherwise, "drc why"
won't work correctly, and the error configuration will depend
on how the chip was checked, which is intolerable.  This problem
is solved here by dividing the world up into squares along a grid
of dimension drcStepSize aligned at the origin.  Interaction areas
are always computed by considering everything inside one grid square
at a time.  We may have to consider several grid squares in order
to cover the area passed in by the client.

DRCFlatCheck --
---------------

This is a top-level procedure that performs a DRC of a cell by
flattening everything.  This is useful when we have a big chip were
everything interacts -- such as when everything is covered by wiring.
In these cases, a flat check of the topmost cell will catch all errors
more quickly.

Results:
The number of errors found.

Side effects:
The procedure func is called for each violation found.  See
the header for DRCBasicCheck for information about how func
is called.  The violations passed to func are expressed in
the coordinates of def.  All voilations found, even those in children,
are reported.

Design Note:
This procedure is trickier than you think, in the same way as
DRCInteractionCheck.  See the comments there.  
Since this is a flat check of a single cell, no DRC updates are done
to subcells.  Also, if this is interrupted the DRC error tiles will
be incorrect!  This a a tradeoff to gain a slight amount of speed.

DRCTclInit --
-------------

Initialize drc tcl commands, and link C and tcl variables..

Results:
None.

DRCTechInit --
--------------

Initialize the technology-specific variables for the DRC module.

Results:
None.

Side effects:
Clears out all the DRC tables.

DRCTechAddRule --
-----------------

Add a new entry to the DRC table.

Results:
Always returns TRUE so that tech file read-in doesn't abort.

Side effects:
Updates the DRC technology variables.

Organization:
We select a procedure based on the first keyword (argv[0])
and call it to do the work of implementing the rule.  Each
such procedure is of the following form:

int
proc(argc, argv)
int argc;
char *argv[];
{
}

It returns the distance associated with the design rule,
or -1 in the event of a fatal error that should cause
DRCTechAddRule() to return FALSE (currently, none of them
do, so we always return TRUE).  If there is no distance
associated with the design rule, 0 is returned.

DRCTechFinal --
---------------

Called after all lines of the drc section in the technology file have been
read.  The preliminary DRC Rules Table is pruned by removing rules covered
by other (longer distance) rules, and by removing the dummy rule at the
front of each list.  Where edges are completely illegal, the rule list is
pruned to a single rule.

Results:
None.

Side effects:
May remove DRCCookies from the linked lists of the DRCRulesTbl.

DRCTechRuleStats --
-------------------

Print out some statistics about the design rule database.

Results:
None.

Side effects:
A bunch of stuff gets printed on the terminal.

ExtSortTerminals --
-------------------

Sort the terminals of a transistor so that the terminal with the
lowest leftmost coordinate on the plane with the lowest number is
output first.

Results:
None

Side effects:
The tr_termnode, tr_termlen, and tr_termpos entries may change.

ExtCell --
----------

Extract the cell 'def', plus all its interactions with its subcells.
Place the result in the file named 'outName'.

Results:
None.

Side effects:
Creates the file 'outName'.ext and writes to it.
May leave feedback information where errors were encountered.
Upon return, extNumFatal contains the number of fatal errors
encountered while extracting 'def', and extNumWarnings contains
the number of warnings.

ExtFindInteractions --
----------------------

Paint into the supplied tile plane 'resultPlane' TT_ERROR_P tiles
for each area in the CellDef 'def' that must be processed for
interactions.

Each interaction arises from paint in two different subtrees
being less than (but not equal to) 'halo' units away from
each other.  In this definition, a subtree refers to a single
CellUse, which may be either a single cell or an entire array.

If 'bloat' is non-zero, each interaction area is bloated by
this amount when being painted into the result plane.

Results:
None.

Side effects:
Paints into the plane 'resultPlane'.

ShowRect (FOR DEBUGGING) --
---------------------------

Show an area in the cell 'def', for debugging.
In this implementation, the area is only displayed in windows
where 'def' is the root cell.

Results:
None.

Side effects:
See above.
Because this procedure bypasses the normal display package,
it can leave data on the screen messed up.  Callers should
use styles that affect only the highlight layer to minimize
the amount of damage.

ExtSetDriver --
---------------
ExtSetReceiver --

Add a terminal name to either the driver or the receiver table.

Results:
None.

Side effects:
Adds an entry to the hash tables extDriverHash or extReceiverHash
respectively.  The initial value of the hash entry is 0.

ExtLengthClear --
-----------------

Kill extDriverHash and extReceiverHash, and re-initialize them.

Results:
None.

Side effects:
See above.

ExtInit --
----------

Initialize the technology-independent part of the extraction module.
This procedure should be called once, after the database module has
been initialized.

Results:
None.

Side effects:
Initializes the local variables of the extraction module.
Registers the extractor with the debugging module.

ExtSetup --
-----------

called on each invocation of extractor, 
sets up "stepsize" etc. 

ExtAll --
---------

Extract the subtree rooted at the CellDef 'rootUse->cu_def'.
Each cell is extracted to a file in the current directory
whose name consists of the last part of the cell's path,
with a .ext suffix.

Results:
None.

Side effects:
Creates a number of .ext files and writes to them.
Adds feedback information where errors have occurred.

ExtUnique --
------------

For each cell in the subtree rooted at rootUse->cu_def, make
sure that there are not two different nodes with the same label.
If there are, and either the label ends in a '#' or allNames is
TRUE, we generate unique names by appending a numeric suffix to
all but one of the offending labels.  Otherwise, if the label
doesn't end in a '!', we leave feedback.

Results:
None.

Side effects:
May modify the label lists of some of the cells rooted
at rootUse->cu_def, and mark the cells as CDMODIFIED.
May also leave feedback.

ExtParents --
-------------
ExtShowParents --

ExtParents extracts the cell use->cu_def and all its parents.
ExtShowParents merely finds and prints all the parents without
extracting them.

As in ExtAll, each cell is extracted to a file in the current
directory whose name consists of the last part of the cell's path,
with a .ext suffix.

Results:
None.

Side effects:
Creates a number of .ext files and writes to them.
Adds feedback information where errors have occurred.

ExtParentArea --
----------------

ExtParentArea extracts the cell use->cu_def and each of its
parents that contain geometry touching or overlapping the area
of use->cu_def.

Results:
None.

Side effects:
Creates one or more .ext files and writes to them.
Adds feedback information where errors have occurred.

ExtIncremental --
-----------------

Starting at 'rootUse', extract all cell defs that have changed.
Right now, we forcibly read in the entire tree before doing the
extraction.

Results:
None.

Side effects:
Creates a number of .ext files and writes to them.
Adds feedback information where errors have occurred.

ExtFindNeighbors --
-------------------

For each tile adjacent to 'tile' that connects to it (according to
arg->fra_connectsTo), and (if it is a contact) for tiles on other
planes that connect to it, we recursively visit the tile, call the
client's filter procedure (*arg->fra_each)(), if it is non-NULL.
The tile is marked as being visited by setting it's ti_client field
to arg->fra_region.

Results:
Returns 0 normally, or 1 if a client decided to abort the
search, or if an interrupt was seen.

Side effects:
See comments above.

ExtFindRegions --
-----------------

Find all the connected geometrical regions in a given area of a CellDef
that will correspond to nodes or devices in the extracted circuit.
Two procedures are supplied by the caller, 'first' and 'each'.

The function 'first' must be non-NULL.  It is called for each tile
tile found in the region.  It must return a pointer to a Region
struct (or one of the client forms of a Region struct; see the
comments in extractInt.h).

Region *
(*first)(tile, arg)
Tile *tile;		/# Tile is on plane arg->fra_pNum #/
FindRegion *arg;
{
}

If the function 'each' is non-NULL, it is applied once to each tile found
in the region:

(*each)(tile, planeNum, arg)
Tile *tile;
int planeNum;	/# May be different than arg->fra_pNum #/
FindRegion *arg;
{
}

Results:
Returns a pointer to the first element in the linked list
of Region structures for this CellDef.  The Region structs
may in fact contain more than the basic Region struct; this
will depend on what the function 'first' allocates.

Side effects:
Each non-space tile has its ti_client field left pointing
to a Region structure that describes the region that tile
belongs to.

Non-interruptible.  It is the caller's responsibility to check
for interrupts.

ExtLabelRegions --
------------------

Given a CellDef whose tiles have been set to point to LabRegions
by ExtFindRegions, walk down the label list and assign labels
to regions.  If the tile over which a label lies is still uninitialized
ie, points to extUnInit, we skip the label.

A label is attached to the LabRegion for a tile if the label's
type and the tile's type are connected according to the table
'connTo'.  This disambiguates the case where a label lies
on the boundary between two tiles of different types.

Results:
None.

Side effects:
Each LabRegion has labels added to its label list.

ExtLabelOneRegion --
--------------------

Same as ExtLabelRegion, but it only assigns labels to one particular
region.

Results:
None.

Side effects:
The region has labels added to its label list.

ExtResetTiles --
----------------

Given a CellDef whose tiles have been set to point to Regions
by ExtFindRegions, reset all the tiles to uninitialized.

Results:
None.

Side effects:
All the non-space tiles in the CellDef have their ti_client
fields set back to uninitialized.  Does not free the Region
structs that these tiles point to; that must be done by
ExtFreeRegions, ExtFreeLabRegions, or ExtFreeHierLabRegions.

Non-interruptible.

ExtFreeRegions --
-----------------
ExtFreeLabRegions --
ExtFreeHierLabRegions --

Free a list of Regions.
ExtFreeLabRegions also frees the LabelLists pointed to by lreg_labels.
ExtFreeHierLabRegions, in addition to freeing the LabelLists, frees
the labels they point to.

Results:
None.

Side effects:
Frees memory.

Non-interruptible.

ExtTclInit --
-------------

Initialize extraction tcl commands.

Results:
None.

Side effects:
Registers command(s) with tcl.

ExtSetStyle --
--------------

Set the current extraction style to 'name', or print
the available and current styles if 'name' is NULL.

Results:
None.

Side effects:
Just told you.

ExtTechLine --
--------------

Process a line from the "extract" section of a technology file.

Each line in the extract section of a technology begins
with a keyword that identifies the format of the rest of
the line.

The following three kinds of lines are used to define the resistance
and parasitic capacitance to substrate of each tile type:

resist	 types resistance
areacap	 types capacitance
perimcap inside outside capacitance

where 'types', 'inside', and 'outside' are comma-separated lists
of tile types, 'resistance' is an integer giving the resistance
per square in milli-ohms, and 'capacitance' is an integer giving
capacitance (per square lambda for areacap, or per lambda perimeter
for perimcap) in attofarads.

The perimeter (sidewall) capacitance depends both on the types
inside and outside the perimeter.  For a given 'perimcap' line,
any segment of perimeter with a type in 'inside' inside the
perimeter and a type in 'outside' ontside the perimeter will
have the indicated capacitance.

Both area and perimeter capacitance computed from the information
above apply between a given node and the substrate beneath it, as
determined by extSubstrate[].

Contact resistances are specified by:

contact	type	minsize	resistance

where type is the type of contact tile, minsize is chosen so that contacts
that are integer multiples of minsize get an additional contact cut for each
increment of minsize, and resistance is in milliohms.

+++ FOR NOW, CONSIDER ALL SUBSTRATE TO BE AT GROUND +++

Overlap coupling capacitance is specified by:

overlap	 toptypes bottomtypes capacitance [shieldtypes]

where 'toptypes' and 'bottomtypes' are comma-separated lists of tile types,
and 'capacitance' is an integer giving capacitance in attofarads per
square lambda of overlap.  The sets 'toptypes' and 'bottomtypes' should
be disjoint.  Also, the union of the planes of 'toptypes' should be disjoint
from the union of the planes of 'bottomtypes'.  If 'shieldtypes' are
present, they should also be a comma-separated list of types, on
planes disjoint from those of either 'toptypes' or 'bottomtypes'.

Whenever a tile of a type in 'toptypes' overlaps one of a type in
'bottomtypes', we deduct the capacitance to substrate of the 'toptypes'
tile for the area of the overlap, and create an overlap capacitance
between the two nodes based on 'capacitance'.  When material in
'shieldtypes' appears over any of this overlap area, however, we
only deduct the substrate capacitance; we don't create an overlap
capacitor.

Sidewall coupling capacitance is specified by:

sidewall  intypes outtypes neartypes fartypes capacitance

where 'intypes', 'outtypes', 'neartypes', and 'fartypes' are all comma-
separated lists of types, and 'capacitance' is an integer giving capacitance
in attofarads.  All of the tiles in all four lists should be on the same
plane.

Whenever an edge of the form i|j is seen, where 'i' is in intypes and
'j' is in outtypes, we search on the 'j' side for a distance of
ExtCurStyle->exts_sideCoupleHalo for edges with 'neartypes' on the
close side and 'fartypes' on the far side.  We create a capacitance
equal to the length of overlap, times capacitance, divided by the
separation between the edges (poor approximation, but better than
none).

Sidewall overlap coupling capacitance is specified by:

sideoverlap  intypes outtypes ovtypes capacitance

where 'intypes', 'outtypes', and 'ovtypes' are comma-separated lists
of types, and 'capacitance' is an integer giving capacitance in attofarads
per lambda.  Both intypes and outtypes should be in the same plane, and
ovtypes should be in a different plane from intypes and outtypes.

The next kind of line describes transistors:

fet	 types terminals min-#terminals names substrate gscap gccap

where 'types' and 'terminals' are comma-separated lists of tile types.
The meaning is that each type listed in 'types' is a transistor, whose
source and drain connect to any of the types listed in 'terminals'.
These transistors must have exactly min-#terminals terminals, in addition
to the gate (whose connectivity is specified in the system-wide connectivity
table in the "connect" section of the .tech file).  Currently gscap and
gccap are unused, but refer to the gate-source (or gate-drain) capacitance
and the gate-channel capacitance in units of attofarads per lambda and
attofarads per square lambda respectively.

The resistances of transistors is specified by:

fetresist type region ohms

where type is a type of tile that is a fet, region is a string ("linear"
is treated specially), and ohms is the resistance per square of the fet
type while operating in "region".  The values of fets in the "linear"
region are stored in a separate table.

Results:
Returns TRUE normally, or FALSE if the line from the
technology file is so malformed that Max should abort.
Currently, we always return TRUE.

Side effects:
Initializes the per-technology variables that appear at the
beginning of this file.

ExtTechFinal --
---------------

Postprocess the technology specific information for extraction.
Builds the connectivity tables exts_nodeConn[], exts_resistConn[],
and exts_transConn[].

Results:
None.

Side effects:
Initializes the tables mentioned above.
Leaves ExtCurStyle pointing to the first style in the list
ExtAllStyles.

ExtractTest --
--------------

Command interface for testing circuit extraction.
Usage:
*extract

Results:
None.

Side effects:
Extracts the current cell, writing a file named
currentcellname.ext.

ExtTimes --
-----------

Time the extractor.
All cells in the tree rooted at 'rootUse' are extracted.
We report the following times for each cell (seconds of CPU
time, accurate to 10 milliseconds).

Time to extract just its paint.
Time to extract it completely.
Time to perform incremental re-extraction if just this cell changed.

In addition, we report:

Fets/second paint extraction speed
Fets/second cell extraction speed
Fets/second hierarchical extraction speed
Rects/second paint extraction speed
Rects/second cell extraction speed
Rects/second hierarchical extraction speed

Also for each cell, we report the number of transistors, number
of rectangles, and rectangles per transistor.

In addition, we report the following cumulative information, as
means, standard deviation, min, and max:

Fets/second flat extraction speed
Fets/second complete extraction speed
Rects/second flat extraction speed
Rects/second complete extraction speed
Incremental extraction time after changing one cell.

Results:
None.

Side effects:
Writes to the file 'f'.

ExtInterCount --
----------------

Find all interaction areas in an entire design, and count
the fraction of the total area that is really an interaction
area.  Report this for each cell in the design, and as a
fraction of the total area.

Results:
None.

Side effects:
Writes to the FILE 'f'.

GDSTechInit --
--------------

Do some checks one time checks at startup time (during technology
file read in)

Results:
None.

Side effects:
Error checking.

GDSTclInit --
-------------

Initialize tcl commands for this module

Results:
None.

Side effects:
Registers command(s) with tcl.

GDSWriteFile --
---------------

Write out the entire tree rooted at the supplied CellDef in Calma
GDS-II stream format, to the specified file.

Results:
TRUE if the cell could be written successfully, FALSE otherwise.

Side effects:
Writes a file to disk.
In the event of an error while writing out the cell,
the external integer errno is set to the UNIX error
encountered.

Algorithm:

Calma names can be strings of up to CALMANAMELENGTH characters.
Because general names won't map into Calma names, we use the
original cell name only if it is legal Calma, and otherwise
generate a unique numeric name for the cell.

We make a depth-first traversal of the entire design tree, outputting
each cell to the Calma file.  If a given cell has not been read in
when we visit it, we read it in ourselves.

No hierarchical design rule checking or bounding box computation
occur during this traversal -- both are explicitly avoided.

GrInit --
---------
Initialize graphics 
called once at startup time.

May cause Max restart with "-colormap new"  
(if there were not enough color planes left in the
shared color map)

Exits on error.

GrFlush:
--------
Flush pending graphics to display.

Avoid calling unnecessarily, since it syncs up with X
and can slow graphics down dramatically if called too
frequently.

GrTicService -
--------------

Call from time to time to keep connection to XServer active.

GrRegisterWindow --
-------------------

Create a GrDrawable struct for the given tkwin
and return an opaque pointer to it.

NOTE:  if the window changes size, it shoud be unregistered
and reregistered.

GrUnregisterWindow --
---------------------

Free GrDrawable struct. 

GrCreatePixmap --
-----------------

Create pixmap of specified dimensions
Initial contents undefined.

Results:	returns (opaque) pointer to GrDrawable struct for Pixmap

GrFreePixmap --
---------------

Free pixmap and associated GrDrawable struct

GrFreeStipple --
----------------

Free stipple and associated gr struct.

GrCreateStipple -
-----------------
Create a stipple pattern.

Results:	returns (opaque) pointer to Pixmap

GrCreateStippleFromPixmapPlane -
--------------------------------
Create a stipple pattern.

Results:	returns (opaque) pointer to Pixmap

GrCreateLinePattern --
----------------------

Convert pattern string to X dash specification.

GrColorMapWrite --
------------------

Set a colormap entry.

GrTextBBox --
-------------

Determine bounding box of a text string in pixels 
origin is left end of base line. 

GrSetDrawable --
----------------

Set window or pixmap to direct output to.
(Can specify translation to apply to all input coordinates.)

GrSetClipRect --
----------------

Causes subsequent graphics to be clipped to specified region of 
window.

NULL arg resets clipping to entire window.

Clip area expanded one pixel to left and bottom, to not clip
rectangles that were expanded from 0 pixel width/height.

GrSetFontSize --
----------------

Set text font. (size=0,1,2,3  - in order of increasing size)

GrDrawText ---
--------------

Draw a text string.

GrFillPolygon -
---------------

Draw a polygon as a filled region.

Special case:  two point polygons specify ovals!

GrCopyPixmap --
---------------

Copy rectangular region of src pixmap into current drawable.

GrAdjustStippleOrigin --
------------------------

adjust stipple origin to match default stipple origin of gd

NOTE: result depends on size of current stipple, so need to call AFTER
setting stipple.

GrDefaultStippleOrigin --
-------------------------

restore default origin back to default.

GrCopyPlane --
--------------

Like GrCopyPixmap, but uses single plane in
src pixmap mapping 0 and 1 bits to specified colors. 

ToolGetBox --
-------------

Returns the box CellDef and location in CellDef coords.

Results:
TRUE if the box exists.

Side effects:
The rootArea parameter is modified to contain the area
of the box.  If rootArea is NULL, it is ignored.
Same with rootDef.

ToolGetBoxWindow --
-------------------

Returns information about the current box location.  Used by
command processing routines.

Results:
The return value is a pointer to a window containing the
box, or NULL if the box doesn't exist in any window.  Note:
the box may actually be in more than one window, so this
isn't necessarily the only window containing the box.

Side effects:
The rootArea parameter is modified to contain the area
of the box.  If rootArea is NULL, it is ignored.  The
integer pointed to by pMask is modified to contain a
mask of all windows containing the box (there may be more
than one).  If pMask is NULL, it is ignored.

ToolGetEditBox --
-----------------

Fill in the location of the box in edit cell coordinates.

Results:
TRUE if the box can indeed be put into edit cell coordinates.
FALSE and an error message otherwise.

Side effects:
Sets *rect to be the coordinates of the box tool in edit cell
coordinates, if TRUE was returned.

Prints an error message if the box is not found or the box
is not in the edit cell coordinate system.

LaySetBox --
------------

Change the location and/or size of the box.

Results:
None.

Side effects:
Information is recorded so that the box will be redrawn.

LayChangedWindow --
-------------------

Mark part of layout window for future redisplay, and schedule
redisplay.

The area is noted as having changed in window w.  
If area is NULL, the entire window is marked for redisplay.
If w is NULL, all layout windows are marked for redisplay.

LayChangedDisplay --
--------------------

Called when something effecting redisplay is changed, 
e.g. the layers visible on the screen or the styles for
displaying layers are changned.

LayChangedHighlight --
----------------------

Schedule highlight redisplay of given area in given rootdef.

Highlights are "white".  They include, box,selection,feedback areas 
and flylines.  The important thing about highlights is that, they
use their own color-map plane, and hence can be changed without
having to redraw "underlying" paint etc. 

Results:
None.

LayChangedSelection --
----------------------

TODO:  call LayChangedHighlight directly!
Mark areas for redisplay.

Results:
None.

LayChangedDef --
----------------

Schedule redisplay of specified area in windows containing the specifed
cellDef as root.

If any labels may have been deleted in the area, layers should be NULL. 
If layers = NULL, the area is automatically expanded enough to encompass
any text that may have stuck out from labels in this area (so it is properly
erased.

NOTE:  only effects windows with cellDef as root.

Results:
None.

LayChangedScheduleDef --
------------------------

Schedule redisplay for windows having rootDef as their root
def.

NOTE:  This call does not specify which areas to redisplay.  The redisplay
code does a DBUpdate() to generate calls to LayChangedDef()
for areas that need redisplay.

Results:
None.

LayCoarseDelete --
------------------

Delete coarse db for given def

LayCoarseChange --
------------------

Mark changed area for recomputation of coarse db.
NULL area means recompute entire bbox.

LayCoarseFlush --
-----------------

Delete coarse planes for all defs.

LayCurWindow --
---------------

Get current layout window.  Used by Mgc/ module.

Result:
Current Layout window.

Side Effects:      
None

LayDisplayInit --
-----------------

Called at startup time, 
after technology file read in and graphics initialization.

LayDisplayHLBox --
------------------

This procedure is called by LayDisplay() to
to redraw the box in a given window.

ALSO called by layChangedBox() to mark box areas for later highlight
redisplay.

modes: 
----
LDB_DISPLAY - redisplay box.
LDB_CHANGED - mark old box loc for redisplay.

NOTE: box redrawn in its entirity on every HIGHLIGHT redisplay, 
so new box loc need not be explicitly marked for redisplay.

Results:
None.

LayFeedbackClear --
-------------------

This procedure clears all existing feedback information.

Results:
None.

Side effects:
Any existing feedback information is cleared from the screen
and from our database.

LayFeedbackAdd --
-----------------

Adds a new piece of feedback information to the list we have
already.

Results:
None.

Side effects:
CellDef's ancestors are searched until its first root definition
is found, and the coordinates of area are transformed into the
root.  Then the feedback area is added to our current list, using
the style and scalefactor given.  This stuff will be displayed on
the screen at the end of the current command.

LayFeedbackNth --
-----------------

Provides the area and text associated with a particular
feedback area.

Results:
None.

Side effects:
The parameter "area" is filled with the area of the nth
feedback, and the text of that feedback is returned. *pRootDef
is filled in with rootDef for window of feedback area.  *pStyle
is filled in with the display style for the feedback area.  If
the particular area doesn't exist (nth >= LayFeedbackCount),
area and *pRootDef  and *pStyle are untouched and NULL is
returned.  NULL	may also be returned if there simply wasn't
any text associated with the selected feedback.

LayFrame --
-----------

Make the given database area visible in the layout widget.
(Sets up the db/pixel transform accordingly)

PROPERTIES OF THIS ROUTINE:

lowerleft corner of window corresponds to db point.
(right and upper edges generally not on exact db grid).

iterated LayFrame call on lay_dbArea does not change the transform.

LayloadWindow --
----------------

Replace the root cell of a window by the specified cell.

A cell name of NULL causes the cell with name "(UNNAMED)" to be
created if it does not already exist, or used if it does.

Results:
None.

Side effects:
Makes new cell the edit cell.
Clears the selection.  (to make sure no refs to old rootUse)

WindSearch --
-------------

Search for all of the Layout windows that contain a particular
surface area, whether exposed or not.

Results:
if func ever returns non-zero, WindSearch() terminates search and
returns with the same result.  Otherwise WindSearch() returns 0.

Side effects:
Calls the function 'func' for each window that matches. 'func' should
be of the form

int func(window, clientData)
Layout *window;		
ClientData clientData;
{
}

Window is the window that matched the search, and clientData is the
clientData parameter supplied to this procedure.
If the function returns a non-zero value the search is aborted, and
that value is returned.  Otherwise the search continues and 0 is
returned.

LayoutTclInit --
----------------

Initialize tcl commands for this module.  

LayoutInit --
-------------

Technology independent module initialization.  

LayPointGet --
--------------

rootPoint set to nearst DB point.
rootArea  set to one-by-one rect containing point.

returns pointer to Layout window containing point. 

LayTechAddStyle --
------------------

Add a new entry to the style tables.

Results:
TRUE if successful, FALSE on error.

Side effects:
Updates the display module's technology variables.

LayUndoOldEdit --
-----------------
LayUndoNewEdit --

Record the old and new edit cells when the edit cell changes.

Results:
None.

Side effects:
Each creates a single undo list entry.

LayUndoBox --
-------------

Remember a box change for later undo-ing.

Results:
None.

Side effects:
An entry is added to the undo list.

LayUndoLoad --
--------------

Remember a window rootcell change for later undo-ing.

Results:
None.

Side effects:
An entry is added to the undo list.

DebugAddClient --
-----------------

Add a client to the debugging module.
The argument 'name' is used to identify the client, and the
argument 'maxflags' indicates the maximum number of flags
that will be added for that client.

Results:
Returns a word of ClientData that identifies the
client just added.  This word must be passed to
DebugAddFlag, DebugSet(), or DebugShow() to identify
the client being referred to.

Side effects:
Updates the list of known debugging clients.

DebugAddFlag --
---------------

Add a debugging flag for a particular client.
This flag can be set when DebugSet() is called with 'clientID',
and will appear in the display of DebugShow().

WARNING:
The order in which flags appear for purposes of setting them
with DebugSet(), and when being displayed with DebugShow(),
will be the same as the order in which they are passed to
DebugAddFlag().  To make LookupStruct() work best for DebugSet(),
the flag names should be ordered monotonically.

Results:
Returns the index of the debugging flag in the array
debugFlags[].

Side effects:
Updates the array debugFlags[].

DebugShow --
------------

Show all the debugging flags and their values for a particular
client.

Results:
None.

Side effects:
Writes to the terminal.

DebugSet --
-----------

Allow debugging flags to be set or cleared for the client 'clientID'.
The argument 'argv' contains an array of 'argc' string pointers,
each of which is the name of a flag that will be set to 'value'
(either TRUE or FALSE).

Results:
None.

Side effects:
Updates the debugging flags specified in (argc, argv).
Will complain about any unrecognized flag names.

DebugUnitsTclInit --
--------------------

Initialize debug tcl stuff

Results:
None.

Side effects:
Registers command(s) with tcl.

HistCreate --
-------------

Create a histogram.

Results:
None.

Side effects:
Allocates buckets for a histogram of the given size, plus coverage of
lower and upper ranges.  Links the bucket onto a list.

HistAdd --
----------

Add an entry into the named histogram.

Results:
None.

Side effects:
Searches the histogram list for the named histogram.  Adds one to the
appropriate range in the histogram.

HistPrint --
------------

Print all histograms to the named file.

Results:
None.

Side effects:
Creates a file.

MsgCmdBegin
-----------

Called at beginning of tcl commands to push error context stack

NOTE:  Don't call directly, use CMD_BEGIN() macro.

MsgCmdEnd
---------

Called just prior to return from tcl commands.

NOTE:  Don't call directly, use CMD_RETURN() macro instead.

Results:
Appropriate return code for tcl command.

Side Effects:
Pops error stack.
If MsgErrorF called during execution, sets tcl return value to 
error text.

MsgInfoV:
---------

MsgInfoF() with var args roled into single arg.
Called by var arg funcs to invoke MsgInfoF internally.
See MsgInfoF below.

Results:
None.

Side effects:
See MsgInfoF

MsgInfoF:
---------

Args like printf, for info messages.

"Info" messages are messages during normal exectuion.

Info messages go to standard out by default.
But they can be diverted (see msg_catch and msg_map).

Results:
None.

Side effects:
See above.

MsgWarnV:
---------

MsgWarnF() with var args roled into single arg.
Called by var arg funcs to invoke MsgInfoF internally.
See MsgInfoF below.

Results:
None.

Side effects:
See MsgWarnF

MsgWarnF:
---------

Args like printf, for warning messages.

"warning" are used to indicate abnormal events, when command exection is not aborted.

Warn messages go to standard error by default.
But they can be diverted (see msg_catch and msg_map).

Results:
None.

Side effects:
See above.

MsgErrorV:
----------

MsgErrorF() with var args roled into single arg.
Called by var arg funcs to invoke MsgErrorF internally.
See MsgErrorF below.

Results:
None.

Side effects:
See MsgErrorF

MsgErrorF:
----------

Args like printf, for error messages.
Error messages inside commands indicate command is aborting.

INSIDE COMMAND, collects error messages in Dynamic string.
On command completion (txCmdEnd() called) error messages copied to
tcl result, and command returns TCL_ERROR.

NOT INSIDE COMMAND messages sent to standard error.

Results:
None.

Side effects:
See above.

MsgTclInit --
-------------

Initialize tcl commands for this module.

Results:
None.

Side effects:
Registers command(s) with tcl.

MaxAbort --
-----------

Handle fatal errors.

Args give error message.  Like printf, first arg is format, subsequent args
to fill in "%" escapes in format.

Results:
None.

Side effects:
Backup modified cells, send error message to stderr, and abort.
(abort normally causes coredump.)

MnDocCreateCommand --
---------------------

Register Tcl Command for Max, and update documentation database

MnDocVar --
-----------

Document a Tcl Variable.

Used to document Tcl variables that already exist.

MnDocLinkVar --
---------------

Link C and Tcl Variable, and update documentation database.

MnDocSetVar --
--------------

Set (initial) Tcl Variable, and document it. 

MnDocSetVar2 --
---------------

Set (initial) Tcl Variable, and document it. 

SigInit:
--------

Set up signal handling for all signals.

Results:
None.

Side effects:
Signal handling is set up.

MnTclInit --
------------

Set linked tcl string variable.  
(free old value, and copy new value to freshly malloced block).

Results:
None.

NOTE:  Critical to use system malloc() and free() here, for 
compatibility with tcl.

MnTechError --
--------------

This procedure is called to print out error messages during
Tech file reading.  (Gives filename, section, and line number)

Results:
None.

Side effects:
An error message is printed.

TechLoad --
-----------

Read in a tech file.

Results:
None.

Side effects:
Tech file opened and read.
"Client" procedures called to process various lines in tech file.

MainTermInit --
---------------

Setup processing of command input from controlling terminal.

Results:
None.

Side effects:
stdin filehandler registered, prompt issued.

MnTicService(void)
------------------

Called at intervals (from MnTic) to perform periodically
required operations (such as reading from the X event socket
so the socket doesn't time out).

MnTypicalWireWidth --
---------------------

Return estimate of typical wire width in current technology 
(in database units).

Results:
estimate of typical wire width in internal units.

Side effects:
None.

UnitsValidS --
--------------

Check to see if string is valid dimension.

Results:
TRUE if string is OK, else FALSE

UnitsI2S --
-----------

Convert integer in internal units, to user unit string.

Results:
Pointer to string holding value in user units.

Side effects:
Modifies unitsBuf to appropriate value.

UnitsS2I --
-----------

Convert user unit string to integer in internal units.

Results:
integer in internal units

UnitsValidSF --
---------------

Check to see if string is valid float.

Results:
TRUE if string is OK, else FALSE

UnitsF2S --
-----------

Convert float in internal units, to user unit string.

Results:
Pointer to string holding value in user units.

Side effects:
Modifies unitsBuf to appropriate value.

UnitsS2F --
-----------

Convert user unit string to float in internal units.

Results:
integer in internal units

MnUnitsTclInit --
-----------------

Initialize units tcl command.

Results:
None.

Side effects:
Registers command(s) with tcl.

CmdArray --
-----------

Implement the "array" command.  Make everything in the selection
into an array.  For paint and labels, just copy.  For subcells,
make each use into an arrayed use.

Usage:
array xlo xhi ylo yhi
array xsize ysize

Results:
None.

Side effects:
Changes the edit cell.

CmdCalma --
-----------

Implement the "calma" command.

Usage:
calma option args

Results:
None.

Side effects:
There are no side effects on the circuit.  Currently, there
is only a single option, "write", to write a CALMA stream
file.

CmdCheckPoint --
----------------

Implement the "checkpoint" command.
Writes the EditCell out to the indicated file without changing the editcell
without clearing modified bits in cd-flags.

Usage:
checkpoint file

Results:
None.

Side effects:
Writes the cell out to specified file.
Clears the modified bit in the cd_flags.

CmdCif --
---------

Implement the "cif" command.

Usage:
cif option args

Results:
None.

Side effects:
There are no side effects on the circuit.  Various options
may produce cif files, read cif, or display cif information
on the screen.

CmdClockwise --
---------------

Implement the "clockwise" command.  Rotate the selection and the
box clockwise around the point.

Usage:
clockwise [degrees]

Results:
None.

Side effects:
Modifies the edit cell.

CmdCopy --
----------

Implement the "copy" command.

Usage:
copy [direction [amount]]
copy to x y

Results:
None.

Side effects:
The selection is copied.

CmdCorner --
------------

Implement the "corner" command.  Find all paint touching one side
of the box, and paint it around two edges of the box in an "L"
shape.

Usage:
corner firstDirection secondDirection [layers]

Results:
None.

Side effects:
The edit cell is modified.

CmdDelete --
------------

Implement the "delete" command.

Usage:
delete

Results:
None.

Side effects:
The selection is deleted.

CmdDrc --
---------

Implement the "drc" command.

Usage:
drc option

Results:
None.

Side effects:
Most options have no side effects.  The only major side
effects are to turn continuous DRC on or off, or recheck an
area of a cell.

CmdDump --
----------

Implement the ":dump" command.

Usage:
dump cellName [child refPointChild] [parent refPointParent]

where the refPoints are either a label name, e.g., SOCKET_A, or an x-y
pair of integers, e.g., 100 200.  The words "child" and "parent" are
keywords, and may be abbreviated.

Results:
None.

Side effects:
Copies the contents of a given cell into the edit cell,
so that refPointChild in the child cell (or the lower-left
corner of its bounding box) ends up at location refPointParent
in the edit cell (or the location of the box tool's lower-left).

MgcLayoutCmdWrapper --
----------------------

Tcl command procedure!
Called back by tcl interp for magic layout commands

Results:
TODO.

Side effects:
Command is executed.

MgcLayoutInit --
----------------

Register the Magic Layout commands in the above tables with tcl.

Results:
None.

Side effects:
Register Magic layout commands.

CmdEdit --
----------

Implement the "edit" command.
Use the cell that is currently selected as the edit cell.  If more than
one cell is selected, use the point to choose between them.

Usage:
edit

Results:
None.

Side effects:
Sets EditCellUse.

CmdErase --
-----------

Implement the "erase" command.
Erase paint in the specified layers from underneath the box in
EditCellUse->cu_def.

Usage:
erase [layers]

Results:
None.

Side effects:
Modified EditCellUse->cu_def.

CmdExpand --
------------

Implement the "expand" command.

Usage:
expand
expand toggle

Results:
None.

Side effects:
If "toggle" is specified, flips the expanded/unexpanded status
of all selected cells.  Otherwise, aren't any unexpanded cells
left under the box.  May read cells in from disk, and updates
bounding boxes that have changed.

CmdExtract --
-------------

Implement the "extract" command.

Usage:
extract option args

Results:
None.

Side effects:
There are no side effects on the circuit.  Various options
may produce .ext files or change extraction parameters.

CmdFeedback --
--------------

Implement the "feedback" command, which provides facilities
for querying and manipulating feedback information provided
by other commands when they have troubles or want to highlight
certain things.

Usage:
feedback option [additional_args]

Results:
None.

Side effects:
Depends on the option.

CmdFill --
----------

Implement the "fill" command.  Find all paint touching one side
of the box, and paint it across to the other side of the box.  Can
operate in any of four directions.

Usage: 
fill direction [layers]

Results:
None.

Side effects:
Modifies the edit cell definition.

CmdFindBox --
-------------

Center the display on a corner of the box.  If 'zoom', then make the box
fill the window.

Usage:
findbox [zoom]

Results:
None.

Side effects:
The window underneath the cursor is moved.

CmdFlush --
-----------

Implement the "flush" command.
Throw away all changes made within magic to the specified cell,
and re-read it from disk.  If no cell is specified, the default
is the current edit cell.

Usage:
flush [cellname]

Results:
None.

Side effects:
THIS IS NOT UNDO-ABLE!
Modifies the specified CellDef.

CmdGetcell --
-------------

Implement the ":getcell" command.

Usage:
getcell cellName [child refPointChild] [parent refPointParent]

where the refPoints are either a label name, e.g., SOCKET_A, or an x-y
pair of integers, e.g., 100 200.  The words "child" and "parent" are
keywords, and may be abbreviated.

Results:
None.

Side effects:
Makes cellName a subcell of the edit cell, positioned so
that refPointChild in the child cell (or the lower-left
corner of its bounding box) ends up at location refPointParent
in the edit cell (or the location of the box tool's lower-left).

CmdGetnode --
-------------

Implement the "getnode" command.
Returns the name of the node pointed by the mouse

Usage:
getnode
getnode abort
getnode abort string
getnode alias on
getnode alias off
getnode fast

Results:
None.

Side effects:
The GetNode hash tables may be modified.

CmdIdentify --
--------------

Implement the "identify" command.
Sets the instance identifier for the currently selected cell.

Usage:
identify use_id

Results:
None.

Side effects:
Modifies the instance identifier for the selected cell (the
first selected cell, if there are many).

CmdLabel --
-----------

Implement the "label" command.
Place a label at a specific point on a specific type in EditCell

Usage:
label text [direction [layer]]

Direction may be one of:
right left top bottom
east west north south
ne nw se sw
or any unique abbreviation.  If not specified, it defaults to a value
chosen to keep the label text inside the cell.

Layer defaults to the type of material beneath the degenerate box.
If the box is a rectangle, then use the lower left corner to determine
the material.

If more than more than one tiletype other than space touches the box,
then the "layer" must be specified in the command.

Results:
None.

Side effects:
Modified EditCellUse->cu_def.

CmdLoad --
----------

Implement the "load" command.

Usage:
load [name]

If name is supplied, then the window containing the point tool is
remapped so as to edit the cell with the given name.

If no name is supplied, then a new cell with the name "(UNNAMED)"
is created in the selected window.  If there is already a cell by
that name in existence (eg, in another window), that cell gets loaded
rather than a new cell being created.

Results:
None.

Side effects:
Sets EditCellUse.

CmdMove --
----------

Implement the "move" command.

Usage:
move [direction [amount]]
move to x y

Results:
None.

Side effects:
Moves everything that's currently selected.

CmdPaint --
-----------

Implement the "paint" command.
Paint the specified layers underneath the box in EditCellUse->cu_def.

Usage:
paint [layers]

Results:
None.

Side effects:
Modified EditCellUse->cu_def.

MgcTclInit --
-------------

This procedure is called to register the Magic commands with the tcl
interpreter.

Results:
None.

Side effects:
Register Magic commands with tcl.

CmdRsim
-------

Starts Rsim under Max.

Results:
None.

Side effects:
Rsim is forked.

CmdSave --
----------

Implement the "save" command.
Writes the EditCell out to a disk file.

Usage:
save [file]

Results:
None.

Side effects:
Writes the cell out to file, if specified, or the file
associated with the cell otherwise.
Updates the caption in the window if the name of the edit
cell has changed.
Clears the modified bit in the cd_flags.

CmdSee --
---------

This procedure is used to enable or disable display of certain
things on the screen.

Usage:
see [no] stuff

Stuff consists of mask layers or the keyword "allSame"

Results:
None.

Side effects:
The indicated mask layers are enabled or disabled from being
displayed in the current window.

CmdSelect --
------------

Implement the "select" command.

Usage:
select [option args]

Results:
None.

Side effects:
The current selection is modified.  See the user documentation
for all the possible things this command can do.

CmdSideways --
--------------

Implement the "sideways" command.

Usage:
sideways

Results:
None.

Side effects:
The selection and box are flipped left-to-right, using the
center of the selection as the axis for flipping.

CmdStartRsim
------------

This command starts Rsim under Max, escapes Rsim, and returns
back to Max.

Results:
Rsim is forked from Max.

Side effects:
None.

CmdSimCmd
---------

Applies the given rsim command to the currently selected nodes.

Results:
Whatever rsim replys to the commands input.

Side effects:
None.

CmdStretch --
-------------

Implement the "stretch" command.

Usage:
stretch [-g] [direction [distance]]

Results:
None.

Side effects:
Moves everything that's currently selected, erases material that
the selection would sweep over, and fills in material behind the
selection.

CmdParseLayers --
-----------------

Convert a string specifying a collection of layers into a TileTypeBitMask
representing the layers specified.

A special layer, '$', refers to all tile types underneath the point
tool, except for the DRC "CHECKxxx" types.

The layer '*' refers to all tile types except for "check-this" and
the label and cell pseudo-types.

Results:
TRUE on success, FALSE if any layers are unrecognized.

Side effects:
Prints an error message if any layers are unrecognized.
Sets bits in 'mask' according to layers in layer specification.
Leaves 'mask' set to 0 if any layers are unrecognized.

Eventually, this routine should return a "minimal" TileTypeBitMask,
ie, one with the minimum number of bits set consistent with the
string supplied it.

CmdGetRootPoint --
------------------

Get the window containing the point tool, and return (in root cell
coordinates for that window) the coordinates of the point, and of
a minimum-grid-size rectangle enclosing the point.

Results:
Pointer to window containing the point tool, or NULL if the
point tool is not present.

Side effects:
Sets *point to be the coordinates of the point tool in root
coordinates, and *rect to be the minimum-grid-size enclosing
rectangle.

Prints an error message if the point is not found.

If either arg is null pointer, it is not set.

CmdGetEditPoint --
------------------

Get the window containing the point tool, and return (in edit cell
coordinates for that window) the coordinates of the point, and of
a minimum-grid-size rectangle enclosing the point.

Results:
Pointer to window containing the point tool, or NULL if the
point tool is not present.

Side effects:
Sets *point to be the coordinates of the point tool in edit
coordinates, and *rect to be the minimum-grid-size enclosing
rectangle.

If either arg is null pointer, it is not set.

CmdGetSelectedCell --
---------------------

This procedure returns a pointer to the selected cell.

Results:
The return value is a pointer to the selected cell.  If more
than one cell is selected, the upper-leftmost cell is returned.
If no cell is selected, NULL is returned.

Side effects:
If pTrans isn't NULL, the area it points to is modified to hold
the transform from coords of the selected cell to root coords.

CmdIllegalChars --
------------------

Checks a string for any of a number of illegal characters.
If any is found, it's printed in an error message.

Results:
TRUE is returned if any of the characters in "illegal" is
also in "string", or if "string" contains any control or
non-ASCII characters.	Otherwise, FALSE is returned.

Side effects:
None.

CmdUnexpand --
--------------

Implement the "unexpand" command.

Usage:
unexpand

Results:
None.

Side effects:
Unexpands all cells under the box that don't completely
contain the box.

CmdUpsidedown --
----------------

Implement the "upsidedown" command.

Usage:
upsidedown

Results:
None.

Side effects:
The box and verything in the selection are flipped upside down
using the point as the axis around which to flip.

CmdCoord --
-----------

Show the coordinates of various things:
Point tool		edit coords, root coords, curr coords
Box tool		edit coords, root coords, curr coords
Edit cell bounding box	edit coords, root coords
Root cell bounding box	edit coords, root coords
Curr cell bounding box	curr coords, root coords

Results:
None.

Side effects:
None.

CmdExtractTest --
-----------------

Debugging of circuit extraction.

Usage:
*extract cmd [args]

Results:
None.

Side effects:
See comments in ExtractTest() in extract/ExtTest.c for details.

CmdShowtech --
--------------

Usage:

showtech [outfile]

Display all the internal technology tables.

Results:
None.

Side effects:
May write to a disk file.

CmdTilestats --
---------------

Generate statistics on tile utilization.
The output is either to the terminal or to the file supplied.
Usage:
*tilestats -a [file]	to generate statistics for all cells
*tilestats [file]	to generate statistics for the currently
selected cell.

If the argument 'file' is specified, it is created to hold the
output of the *tilestats command.

Results:
None.

Side effects:
May create a disk file.

CmdPsearch --
-------------

Run point search a number of times the point at the lower-left
corner of the box tool to each point in the edit cell.

Usage:
psearch plane count

Where plane is the name of the plane on which the search is to be
carried out, and count is the number of searches to be performed.

Results:
None.

Side effects:
None.

CmdWatch --
-----------

Enable/disable watching of tile planes in the given window.

Results:
None.

Side effects:
Causes the display package to display the actual tile structure
for a given plane, or disables such display.

ResSanityChecks -- Checks that resistor and node lists are consistant.
----------------------------------------------------------------------
Make sure that all resistors are connected, and that each node 
to which a resistor is connected has the correct pointer in its list.

Results: none

Side Effects: prints out error messages if it finds something bogus.

ResCalcPerimOverlap--
---------------------

Results:

Side Effects:

DBTreeCopyConnectDCS --
-----------------------

Basically the same as DBTreeCopyConnect, except it calls 
dbcTile2TileDCS.

Results:
None.

Side effects:
The contents of the result cell are modified.

ResPrintNodeList--  Prints out all the nodes in nodelist.
---------------------------------------------------------


Results: node

Side effects: prints out the 'nodes' in list to fp.

ResPrintResistorList--
----------------------


results: none


side effects: prints out Resistors in list to file fp.

ResPrintTransistorList--
------------------------


Results: none

Side effects: prints out transistors in list to file fp.

ResFracture --  Convert a maxiumum horizontal strips cell def into
------------------------------------------------------------------
one where the split at each concave corner is in the direction
with the least material of the same tiletype.  This is done
using TiSplitX and TiJoinY.  Joins are only done on tiles with
the same time; this implies that contacts should first be erased 
using ResDissolve contacts. 

We can't use DBPlaneEnumAreaPaint because  the fracturing
routines modify the database.  This is essentially the same routine
except that has to be careful that it doesn't merge away the
current tile in the search.

ResCheckConcavity -- Called when two tiles of the same type are found.
----------------------------------------------------------------------
These tiles can form concave edges 4 different ways; check for
each such case.  When one is found, call the resWalk routines to
decide whether any tiles need to be split.

Results: none.

Side Effects: may change the plane on which it acts.  Can also modify
the global variable resTopTile.

ResSplitX -- calls TiSplitX, sets the tiletype,
-----------------------------------------------
then tries to join tiles that share a common long edge.

Results: none

Side Effects: modifies the tile plane and the global variables
resSrTile and resTopTile.

TODO MHA ResSplitX may need updating for groups?

ResNewSDTransistor-- called when a transistor is reached via a piece of
-----------------------------------------------------------------------
diffusion. (Transistors  reached via poly, i.e.
gates, are handled by resEachTile.)

Results:none

Side Effects: determines to which terminal (source or drain) node 
is connected. Makes new node if node hasn't already been created .
Allocates breakpoint in current tile for transistor.

ResProcessJunction-- Called whenever a tile  connecting to the tile being
-------------------------------------------------------------------------
worked on is found. If a junction is already present, its address is
returned. Otherwise, a new junction is made. 

Results: Returns the address of the junction between the two tiles.

Side Effects: Junctions may be created.

ResInitializeConn--
-------------------

Sets up mask by Source/Drain type of transistors. This is 
exts_transSDtypes turned inside out.

Results: none

Side Effects: Sets up ResConnectWithSD.

ResGetReCell --
---------------

This procedure makes sure that ResUse,ResDef
have been properly initialized to refer to a cell definition
named "__RESIS__".

Results:
None.

Side effects:
A new cell use and/or def are created if necessary.

ResDissolveContacts--
---------------------

results:  none

Side Effects:  All contacts in the design are broken into their 
constituent
layers.  There should be no contacts in ResDef after this procedure
runs.

ResFindNewContactTiles --
-------------------------


Results:  none

Side Effects:  dissolving contacts eliminated the tiles that 
contacts->nextcontact pointed to. This procedure finds the tile now under
center and sets that tile's ti_client field to point to the contact.  The
old value of clientdata is set to nextTilecontact.

ResProcessTiles--Calls resEachTile with processed tiles belonging to
--------------------------------------------------------------------
nodes in ResNodeQueue.  When all the tiles corresponding
to a node have been processed, the node is moved to
ResNodeList.

Results: none

Side Effects: Cleans extraneous linked lists from nodes. 

ResExtractNet-- extracts the resistance net at the specified 
-------------------------------------------------------------
rn_loc. If the resulting net is greater than the tolerance,
simplify and return the resulting network.

Results:  0 iff it worked.

Side effects: Produces a resistance network for the node.

ResCleanUpEverything--After each net is extracted by ResExtractNet,
-------------------------------------------------------------------
the resulting memory must be freed up, and varius trash swept under
the carpet in preparation for the next extraction.

Results: none

Side Effects: Frees up memory formerly occupied by network elements.

FindStartTile-- To start the extraction, we need to find the first driver.
--------------------------------------------------------------------------
The sim file gives us the location of a point in  or near (within 1
unit) of the transistor. FindStartTile looks for the transistor, then
for adjoining diffusion. The diffusion tile is returned.

Results: returns source diffusion tile, if it exists. Otherwise, return
NULL.

Side Effects: none

ResGetTransistor-- Once the net is extracted, we still have to equate
---------------------------------------------------------------------
the sim file transistors with the layout transistors. ResGetTransistor
looks for a transistor at the given location.

Results: returns transistor structure at location TransistorPoint, if it
exists.

Side Effects: none

ResCalcTileResistance-- Given a set of partitions for a tile, the tile can
--------------------------------------------------------------------------
be converted into resistors. To do this, nodes are sorted in the 
direction of current flow. Resistors are created by counting squares
between successive breakpoints. Breakpoints with the same coordinate
are combined.

Results: returns TRUE if the startnode was involved in a merge.

Side Effects:  Resistor structures are produced.  Some nodes may be
eliminated.

ResCalcEastWest-- Makes resistors from an EastWest partition.
-------------------------------------------------------------

Results: Returns TRUE if the sacredNode was involved in a merge.

Side Effects: Makes resistors. Frees breakpoints.

ResCalcNorthSouth-- Makes resistors from a NorthSouth partition
---------------------------------------------------------------

Results: Returns TRUE if the resCurrentNode was involved in a merge.

Side Effects: Makes resistors. Frees breakpoints

ResCalcNearTransistor-- Calculating the direction of current flow near
----------------------------------------------------------------------
transistors is tricky because there are two adjoining regions with
vastly different sheet resistances.  ResCalcNearTransistor is called
whenever a diffusion tile adjoining a real tile is found.  It makes
a guess at the correct direction of current flow, removes extra 
breakpoints, and call either ResCalcEastWest or ResCalcNorthSouth

Side Effects: Makes resistors. Frees breakpoints

ResDoContacts-- Add node (or nodes) for a contact.  If there are contact
------------------------------------------------------------------------
resistances, also add a resistor.

Results: 

Side Effects: Creates nodes and resistors

ResDoneWithNode--After all connections to node are made, ResDoneWithNode
------------------------------------------------------------------------
is called. It checks for parallel, series, loop, triangle,
and single conections, and simplifies the network where possible.

Results: none

Side Effects: deletes resistors and/or nodes.

ResFixRes--
-----------

Results: none

Side Effects: ResFixRes combines two resistors in series.  the second 
Resistor is eliminated.  Resptr is the node that is "cut out" of the
nextwork.

ResFixParallel--
----------------

Results: none

Side Effects: ResFixParallel combines two resistors in parallel. T
The second  Resistor is eliminated.  

ResParallelCheck -- tries to do parallel combinations of transistors.
---------------------------------------------------------------------

Results: returns PARALLEL if successful

Side Effects: may delete resistors and nodes.

ResTriangleCheck -- looks for places to do the traingle-to-Y conversion.
------------------------------------------------------------------------

Results: returns TRIANGLE if successful.

Side Effects: may allocate a new node.

ResMergeNodes--
---------------

results: none

side effects: appends all the cElement, jElement, tElement and
resElement structures from node 2 onto node 1.  Node 2 is
then eliminated.

ResDeleteResPointer-- Deletes the pointer from a node to a resistor.
--------------------------------------------------------------------
Used when a resistor is deleted.

Results:none

Side Effects: Modifies a node's resistor list.

ResEliminateResistor--
----------------------

Results:none

Side Effects: Deletes a resistor. Does not delete pointers from nodes to
resistor.

ResCleanNode--removes the linked lists of junctions and contacts after
----------------------------------------------------------------------
they are no longer needed. If the 'junk' option is used,
the node is eradicated.

Results:

Side Effects: frees memory

ResFixBreakPoint--moves breakpoints from one node to another, checking
----------------------------------------------------------------------
first to see whether the target node already has the breakpoint.
Used when nodes are merged.

Results: none

Side Effects: may free up memory if breakpoint is already present.

ResPrintExtRes-- Print resistor network to output file.
-------------------------------------------------------

Results:none

Side Effects:prints network.

ResPrintExtTran-- Print out all transistors that have had at least 
-------------------------------------------------------------------
one terminal changed.

Results:none

Side Effects:prints transistor lines to output file

ResPrintExtNode-- Prints out all the nodes in the extracted net.
----------------------------------------------------------------

Results:none

Side Effects: Prints out extracted net. It may add new nodes to the
node hash table.

ResPrintStats -- Prints out the node name, the number of transistors,
---------------------------------------------------------------------
and the number of nodes for each net added.  Also keeps a running
track of the totals.

Results:

Side Effects:

ResReadSim.c -- Routines to parse .sim files
--------------------------------------------


ResReadNode-- Reads in a node file, puts location of nodes into node
--------------------------------------------------------------------
structures.

Results: returns 0 if nodes file is correct, 1 if not.

Side Effects:see above

ResSimNewNode-- Adds a new node to the Node Hash Table.
-------------------------------------------------------

Results: returns zero if node is added correctly, one otherwise.

Side Effects: Allocates a new ResSimNode

ResSimProcessDrivePoints -- if the sim file contains a res:drive attribute,
---------------------------------------------------------------------------
and we are doing a signal extraction,
we need to search through the .ext file looking for attr labels that
contain this text. For efficiency, the .ext file is only parsed when
the first res:drive is encountered.  res:drive labels only work if 
they are in the root cell.

Results:

Side Effects:

ResSimProcessFixPoints -- if the sim file contains a "res:fix:name" label 
--------------------------------------------------------------------------
and we are checking for power supply noise, then we have to 
parse the .ext file looking for the fix label locations.  This
is only done after the first res:fix label is encountered.


Results: For each new name, allocate

Side Effects:

ResInitializeNode-- Gets the node corresponding to a given hash table
---------------------------------------------------------------------
entry.  If no such node exists, one is created.

Results:Returns ResSimNode corresponding to entry.

Side Effects: May allocate a new ResSimNode.

ResReadSim--
------------

Results: returns 0 if sim file is correct, 1 if not.

Side Effects: Reads in SimTable and makes a hash table of nodes.

ResWriteExtFile
---------------

Results:

Side Effects:

ResCommand --  reads in sim file and layout, and produces patches to the
------------------------------------------------------------------------
.ext files and .sim files that include resistors.

Results: returns 0 if it completes correctly.

Side Effects: Produces .res.sim file and .res.ext file for all nets that
require resistors.

ResFixUpConnections-- Changes the connection to  a terminal of the sim 
-----------------------------------------------------------------------
transistor.  The new name is formed by appending .t# to the old name.
The new name is added to the hash table of node names.

Results:none

Side Effects: Allocates new ResSimNodes. Modifies the terminal connections
of sim Transistors.

ResFixTranName-- Moves transistor connection to new node.
---------------------------------------------------------

Results: returns zero if node is added correctly, one otherwise.

Side Effects: May create a new node. Creates a new transistor pointer.

ResSortByGate--sorts transistor pointers whose terminal field is either
-----------------------------------------------------------------------
drain or source by gate node number, then by drain (source) number.
This places transistors with identical connections next to one 
another.

Results: none

Side Effects: modifies order of transistors

ResWriteLumpFile
----------------

Results:

Side Effects:

ResSimplify -- contains routines used to simplify signal nets.
--------------------------------------------------------------


ResSimplifyNet- Reduces complete (?) net produced by ResProcessTiles into
-------------------------------------------------------------------------
something a little less chaotic.

Results: none

Side Effects:  Can eliminate nodes and resistors, and move transistors from
one node to another.

ResMoveTransistors-- move transistors from one node1 to node2
-------------------------------------------------------------

Results: none

Side Effects: Changes transistor connections and node tElements.

ResScrunchNet-- Last ditch net simplification. Used to break deadlocks
----------------------------------------------------------------------
in ResSimplifyNet.  Resistors are sorted by value. The smallest 
resistor is combined with its smallest neighbor, and ResSimplifyNet
is called.  This continues until the smallest resistor is greater
than the tolerance.

Results:none

Side Effects: Nodes and resistors are eliminated.

ResAddResistorToList-- Adds resistor to list according to its value 
--------------------------------------------------------------------
(smallest first).

Results:none

Side Effects: modifies locallist.

ResdistributeSubstrateCapacitance--
-----------------------------------

Results: takes total capacitance to VDD or GND in a node and distributes
it onto the new nodes.

Side Effects:

ResCalculateChildCapacitance-- calculates capacitance of this node and 
-----------------------------------------------------------------------
all downstream nodes. 

Results: Returns capacitance of this node and children nodes if connected
to a tree- returns -1 If the subtree contains loops.

Side Effects:  Adds RCDelayStuff fields to nodes.

ResCalculateTDi- Calculates TDi numbers for all the nodes in the circuit.
-------------------------------------------------------------------------

Results: none

Side Effects: sets the rc_Tdi fields of the RCDelayStuff fields of the
nodes.

ResPruneTree-- Designed to be run just after ResCalculateTDi to prune all 
--------------------------------------------------------------------------
branches off the tree whose end node value of Tdi is less than the
tolerance.  This eliminates many resistors in nets with high fanout.

Results: none

Side Effects: May Eliminate Resistors and Merge Nodes

ResFirst -- Checks to see if tile is a contact. If it is, allocate a 
---------------------------------------------------------------------
contact structure.


Results: Always returns null.

Side effects:
Memory is allocated by ResFirst.
We cons the newly allocated region onto the front of the existing
region list.

ResAddPlumbing-- Each tile is a tileJunk structure associated with it
---------------------------------------------------------------------
to keep track of various things used by the extractor. ResAddPlumbing
adds this structure and sets the tile's ClientData field to point to it.
If the tile is a transistor, then a transistor structure is also added;
all connected transistor tiles are enumerated and their transistorList 
fields set to the new structure.

Results: always returns 0

Side Effects:see above

ResRemovePlumbing-- Removes and deallocates all the tileJunk fields.
--------------------------------------------------------------------

Results: returns 0

Side Effects: frees up memory; resets tile->ti_client fields to MINFINITY

ResPreprocessTransistors-- Given a list of all the transistor tiles and 
------------------------------------------------------------------------
a list of all the transistors, this procedure calculates the width and 
length.. The width is set equal to the sum of all edges that touch 
diffusion divided by 2. The length is the remaining perimeter divided by 
2*tiles.  The perimeter and area fields of transistor structures are also
fixed.

Results: none

Side Effects: sets length and width of transistors. "ResTransTile" 
structures are freed.

ResAddToQueue-- adds new nodes to list of nodes requiring processing.
---------------------------------------------------------------------

Side Effects: nodes are added to list (i.e they have their linked list
pointers modified.)

ResRemoveFromQueue-- removes node from queue. Complains if it notices
---------------------------------------------------------------------
that the node isn't in the supplied list.

Results: none

Side Effects: modifies nodelist

SelectInit --
-------------

Non-technology dependent intialization of selection stuff.

Results:
None.

Side effects:
The select cells are created if they don't already exist.
Selection undo-ing is also initialized.

SelectClear --
--------------

This procedure clears the current selection.

Results:
None.

Side effects:
All information is removed from the select cell, and selection
information is also taken off the screen.

SelectArea --
-------------

This procedure selects all information of given types that
falls in a given area.

Results:
None.

Side effects:
The indicated information is added to the select cell, and
outlined on the screen.  Only information of particular
types, and in expanded cells (according to xMask) is
selected.

SelectChunk --
--------------

This procedure selects a single rectangular chunk of 
homogeneous material, maximizing the minimum dimension.

Results:
None.

Side effects:
More material is added to the select cell and displayed
on the screen.  This procedure finds the largest rectangular
chunk of material "type" that contains the area given in
in scx.  The material need not all be in one cell, but it
must all be in cells that are expanded according to "xMask".
If pArea is given, the rectangle it points to is filled in
with the area of the chunk that was selected.

SelectRegion --
---------------

Select an entire region of material, no matter what its
shape.

Results:
None.

Side effects:
This procedure traces out the region consisting entirely
of type "type", and selects all that material.  The search
starts from "type" material under scx and continues outward
to get all material in all cells connected to the area under
scx by material of type "type".  If pArea is specified, then
the rectangle that it points to is filled in with the bounding
box of the region that was selected.

SelectNet --
------------

This procedure selects an entire electrically-connected net.

Results:
None.

Side effects:
Starting from material of type "type" under scx, this procedure
finds and highlights all material in all expanded cells that
is electrically-connected to the starting material through a
chain of expanded cells.  If pArea is specified, then the
rectangle that it points to is filled in with the bounding box
of the net that was selected.

SelectCell --
-------------

Select a subcell by making a copy of it in the __SELECT__ cell.

Results:
None.

Side effects:
The given use is copied into the selection.  If replace is TRUE,
then the last subcell to be selected via this procedure is
deselected.

SelEnumPaint --
---------------

Find all selected paint, and call the client's procedure for
all the areas of paint that are found.  Only consider paint
on "layers", and if "editOnly" is TRUE, then only consider
paint that is in the edit cell.  The client procedure must
be of the form

int
func(rect, type, clientData)
Rect *rect;
TileType type;
ClientData clientData;
{
}

The rect and type parameters identify the paint that was found,
in root coordinates, and clientData is just the clientData
argument passed to this	procedure.  Func should normally return
0.  If it returns a non-zero return value, then the search
will be aborted.

Results:
Returns 0 if the search finished normally.  Returns 1 if the
search was aborted.

Side effects:
If foundNonEdit is non-NULL, its target is set to indicate
whether there was selected paint from outside the edit cell.
Otherwise, the only side effects are those of func.

SelEnumCells --
---------------

Call a client-supplied procedure for each selected subcell.
If "editOnly" is TRUE, then only consider selected subcells
that are children of the edit cell.  The client procedure
must be of the form

int
func(selUse, realUse, transform, clientData)
CellUse *selUse;
CellUse *realUse;
Transform *transform;
TerminalPath *tPath;
ClientData clientData;
{
}

SelUse is a pointer to a cellUse that's in the selection cell.
RealUse is a pointer to the corresponding cell that's part of
the layout.  Transform is a transform from the coordinates of
RealUse to root coordinates.  tPath (if nonNull) is set to
path to parent.  

If the cell is an array, only one
call is made for the entire array, and transform is the transform
for the root element of the array (array[xlo, ylo]).  Func should
normally return 0.  If it returns a non-zero return value, then
the search will be aborted.

NOTE:  func may safely modify the database but should not modify
the selection.

Results:
Returns 0 if the search finished normally.  Returns 1 if the
search was aborted.

Side effects:
If foundNonEdit is non-NULL, its target is set to indicate
whether there were selected cells that weren't children of
the edit cell. 	Otherwise, the only side effects are those
of func.

SelEnumLabels --
----------------

Find all selected labels, and call the client's procedure for
each label found.  Only consider labels attached to "layers",
and if "editOnly" is TRUE, then only consider labels that
are in the edit cell.  The client procedure must be of the
form

int
func(label, cellDef, transform, tpath, clientData)
Label *label;
CellDef *cellDef;
Transform *transform;
TerminalPath *tpath;   
ClientData clientData;
{
}

Label is a pointer to a selected label.  It refers to the label
in cellDef, and transform gives the transform from that
cell's coordinates to root coordinates.  Terminal path gives
hierarchical name of the instance containing the label.
ClientData is just
the clientData argument passed to this procedure.  Func
should normally return 0.  If it returns a non-zero return
value, then the search will be aborted.

NOTE:  user function may safely modify database, but should not
modify selection during enumeration.

Results:
Returns 0 if the search finished normally.  Returns 1 if the
search was aborted.

Side effects:
If foundNonEdit is non-NULL, its target is set to indicate
whether there was at least one selected label that was not
in the edit cell.  Otherwise, the only side effects are
those of func.

SelectDelete --
---------------

Delete everything in the edit cell that's selected.

Results:
None.

Side effects:
Stuff is removed from the edit cell.  If there's selected
stuff that isn't in the edit cell, the user is warned.

SelectCopy --
-------------

This procedure makes a copy of the selection.

Results:
None.

Side effects:
The selection is copied, with the copy being transformed by
"transform" relative to the current selection.  The copy is
made the new selection.

SelectTransform --
------------------

This procedure modifies the selection by transforming
it geometrically.

Results:
None.

Side effects:
The selection is modified and redisplayed.

SelectGroupTransfer --
----------------------

Copies selection to newGroup,
Deletes parts of selection in the activeGroup.
Leaves ActiveGroup as newGroup!

Results:
None.

Side effects:
The selection is modified and redisplayed.  
The activeGroup is changed

SelectExpand --
---------------

Expand all of the selected cells that are unexpanded, and
unexpand all of those that are expanded.

Results:
None.

Side effects:
The contents of the selected cells will become visible or
invisible on the display in the indicated window(s).

SelInternals --
---------------

Expand/unexpand selected cells.

Results:
None.

Side effects:
The contents of the selected cells will become visible or
invisible on the display.

SelectArray --
--------------

Array everything in the selection.  Cells get turned into
arrays, and paint and labels get replicated.

Results:
None.

Side effects:
The edit cell is modified in a big way.  It's also redisplayed.

SelectStretch --
----------------

Move the selection a given amount in x (or y).  While moving,
erase everything that the selection passes over, and stretch
material behind the selection.

Results:
None.

Side effects:
The edit cell is modified.  The selection is also modified
and redisplayed.

SelectDump --
-------------

Copies an area of one cell into the edit cell, selecting the
copy so that it can be manipulated later.

Results:
None.

Side effects:
The edit cell is modified.

SelTclInit --
-------------

Initialize tcl commands for this module.

Results:
None.

Side effects:
Registers command(s) with tcl.

SelUndoForw --
--------------
SelUndoBack --

Called to process undo redisplay events.  The two procedures
are identical except that each one looks at different events.
The idea is to do the selection redisplay only AFTER the selection
has actually been modified.

Results:
None.

Side effects:
Highlights (including the selection) are redisplayed.

SelUndoInit --
--------------

Adds us as a client to the undo package.

Results:
None.

Side effects:
Adds a new client to the undo package, and sets SelUndoClientID.

SelRemoveArea --
----------------

Remove a rectangular chunk of the select cell, possibly masked
by a user-specified mask (which may include the pseudo-levels
L_CELL and L_LABEL).

Results:
None.

Side effects:
Paint, labels, and/or cell uses may be removed from the select cell.
The selection highlights are redrawn, and undo checkpoints are saved,
so this thrilling process may be undone or redone.  The select cell's
bounding box is updated.

SelRemoveSel2 --
----------------
Run through the select2 cell, removing corresponding paint and labels
from the select cell.

Results:
Should always return zero; returns 1 if there is a problem traversing
select2.

Side effects:
Paint and labels (but not cell uses) may be deleted from the select
cell.  The calling procedure is responsible for updating highlighting
and undo information.

Labels may be placed in the select2 cell; SelRemoveSel2 assumes that
there are no labels in select2 when it is called.

SelRemoveCellSearchFunc --
--------------------------
find the cell use in the select cell which matches a given
cell use in the root def.

Results:
Returns 1 to abort the search if it finds a match.  Otherwise
returns zero.

Side effects:
fills in the sel_use field of its client argument if it finds a match.

SelectRemoveCellUse --
----------------------
remove the cell use in the select cell which matches the given
use from the root def.

Results:
Returns 1 if no such use was found; returns zero otherwise.

Side effects:
If SelectRemoveCellUse returns 1, there are no side effects.
Otherwise:  undo/redo markers will be created, one cell use
will be deleted from the select cell, the select cell's bounding
box will be recomputed, the highlights redrawn, and the area
which had been covered by the cell use will be marked as
changed.  If selectLastUse was pointing to the use, it will
be set to NULL, so the select cycling code will not try
to deselect this (now trashed) cell use.

TiNewPlane --
-------------

Allocate and initialize a new tile plane.

Results:
A newly allocated Plane with all corner stitches set
appropriately.

Side effects:
Adjusts the corner stitches of the Tile supplied to
point to the appropriate bounding tile in the newly
created Plane.

TiFreePlane --
--------------

Free the storage associated with a tile plane.
Only the plane itself and its four border tiles are deallocated.

Results:
None.

Side effects:
Frees memory.

TiToRect --
-----------

Convert a tile to a rectangle.

Results:
None.

Side effects:
Sets *rect to the bounding box for the supplied tile.

TiSplitY --
-----------

Given a tile and a Y coordinate, split the tile into two
along a horizontal line running through the given coordinate.

Results:
Returns the new tile resulting from the splitting, which
is the tile occupying the top half of the original
tile.

Side effects:
Modifies the corner stitches in the database to reflect
the presence of two tiles in place of the original one.

TiSplitX_Left --
----------------

Given a tile and an X coordinate, split the tile into two
along a line running vertically through the given coordinate.
Intended for use when plowing to the left.

Results:
Returns the new tile resulting from the splitting, which
is the tile occupying the left-hand half of the original
tile.

Side effects:
Modifies the corner stitches in the database to reflect
the presence of two tiles in place of the original one.

TiSplitY_Bottom --
------------------

Given a tile and a Y coordinate, split the tile into two
along a horizontal line running through the given coordinate.
Used when plowing down.

Results:
Returns the new tile resulting from the splitting, which
is the tile occupying the bottom half of the original
tile.

Side effects:
Modifies the corner stitches in the database to reflect
the presence of two tiles in place of the original one.

TiJoinX --
----------

Given two tiles sharing an entire common vertical edge, replace
them with a single tile occupying the union of their areas.

Results:
None.

Side effects:
The first tile is simply relinked to reflect its new size.
The second tile is deallocated.  Corner stitches in the
neighboring tiles are updated to reflect the new structure.
If the hint tile pointer in the supplied plane pointed to
the second tile, it is adjusted to point instead to the
first.

TiJoinY --
----------

Given two tiles sharing an entire common horizontal edge, replace
them with a single tile occupying the union of their areas.

Results:
None.

Side effects:
The first tile is simply relinked to reflect its new size.
The second tile is deallocated.  Corner stitches in the
neighboring tiles are updated to reflect the new structure.
If the hint tile pointer in the supplied plane pointed to
the second tile, it is adjusted to point instead to the
first.

TiSrPoint --
------------

Search for a point.

Results:
A pointer to the tile containing the point.
The bottom and left edge of a tile are considered part of
the tile; the top and right edge are not.

Side effects:
Updates the hint tile in the supplied plane to point
to the tile found.

UndoAddClient --
----------------

Define an undo "type".

Results:
Returns an UndoType which must be passed in future calls
to UndoNewEvent().  If -1 is returned, this means that there
are too many clients of the undo package.

Side effects:
Initializes local state in the undo package.

UndoDisable --
--------------

Turn the undo package off.
Future calls to UndoNewEvent() will return NULL, and future calls
to UndoIsEnabled() will return FALSE, until the next call to
UndoEnable();

Results:
None.

Side effects:
Disables undoing until the next call to UndoEnable().

UndoEnable --
-------------

Turn the undo package on.
Re-enables the undo package after a call to UndoDisable().

Results:
None.

Side effects:
Re-enables undoing.

UndoFlush --
------------

Flush the current undo list.

Results:
None.

Side effects:
Deletes everything from the undo list.

UndoNewEvent --
---------------

Return a pointer to a new UndoEvent of the specified type and capable
of holding size bytes of client data.

Results:
A pointer to a new UndoEvent.

WARNING:
The pointer to the new UndoEvent must not be retained past the
next call to any of the routines in the undo package, as the
event is liable to be reallocated. ???

Side effects:
Appends new event after the current
event, and makes it current (events forward of the current event
are flushed, i.e. no redo info after a new event is added.)

UndoDelim --
------------

Delimit a sequence of operations to the undo package with an event
delimiter.  

(Operations between delims are treated as single command for
purposes of undo/redo.)

Results:
None.

Side effects:
Appends a marker to the undo list signifying a "command" boundary.

UndoBackward --
---------------

Play the undo log backward n events.

Argument of 0 means delete recent events (i.e. up to last delim).

Results:
The number of events actually played backward.  Normally, this
will be equal to n unless we encounter the beginning of the log.

Side effects:
Applies the client backEvent() procedures to each event encountered
in playing the log backward.

UndoForward --
--------------

Play the undo log forward n events.

Results:
The number of events actually played forward.  Normally, this
will be equal to n unless we encounter the end of the log.

Side effects:
Applies the client forwEvent() procedures to each event encountered
in playing the log forward.

UndoTclInit --
--------------

Register tcl commands in this module.

Results:
None.

Side effects:
Registers command(s) with tcl.

DQInit --
---------

Initialize a new queue to have a certain capacity.

Results:
None.

Side Effects:
None.

DQFree --
---------

Free up a queue.

Results:
None.

Side Effects:
None.

DQPushFront & DQPushRear --
---------------------------

Push a new element onto one end of the DQueue.

Results:
None.

Side Effects:
Puts an element in the queue.

DQPopFront & DQPopRear --
-------------------------

Pop an element from one end of the queue.

Results:
The element, or NULL if there is none.

Side Effects:
Removes the element from the queue.

DQChangeSize --
---------------

Change the size of a DQueue -- either increase or decrease.

Results:
None

Side Effects:
The DQueue changes size.

DQCopy --
---------

Copy one DQueue into another.

Results:
None.

Side Effects:
Elements (ClientData pointers) are copied.

Main --
-------

Test out this module.

Results:
None.

Side Effects:
Stuff on the screen.

Declarations of exported transforms:
------------------------------------


Declaration of the table of opposite directions:
------------------------------------------------


Declarations of exported rectangles:
------------------------------------


GeoTransPoint --
----------------
Transforms a point from one coordinate system to another.

Results:	None.

Side Effects:
P2 is set to contain the coordinates that result from transforming
p1 by t.

GeoTransPointFOut --
--------------------
Transforms a point from one coordinate system to another.

Results:	None.

Side Effects:
P2 is set to contain the coordinates that result from transforming
p1 by t.

GeoTransPointF --
-----------------
Transforms a point from one coordinate system to another.

Results:	None.

Side Effects:
P2 is set to contain the coordinates that result from transforming
p1 by t.

GeoTransRect --
---------------
Transforms a rectangle from one coordinate system to another.

Results:	None.

Side Effects:
R2 is set to contain the coordinates that result from transforming
r1 by t.

GeoTranslateTrans --
--------------------
Translate a transform by the indicated (x, y) amount.

Results:	None.

Side Effects:
Trans2 is set to the result of transforming trans1 by
a translation of (x, y).

GeoTransTranslate --
--------------------
Transform a translation by the indicated (x, y) amount.

This is the dual of GeoTranslateTrans, in that if
Tinv is the inverse of T,

GeoTransTranslate(T, x, y) * GeoTranslateTrans(Tinv, -x, -y)
is the identity transform.

Results:	None.

Side Effects:
Trans2 is set to the result of transforming a translation
of (x, y) by trans1.

GeoTransTrans --
----------------
This routine transforms a transform.

Results:	None.

Side Effects:
The transform referred to by net is set to produce a geometrical
transformation equivalent in effect to the application of transform
first, followed by the application of transform second.

GeoNameToTrans --
-----------------
Map a transform name (orientation) to corresponding transform. 

Returns NULL if name invalid

GeoTransToName --
-----------------
Map a transform to its name (orientation)

GeoNameToPos --
---------------
Map the name of a position into an integer position parameter.
Position names may be unique abbreviations for direction names.

Results:
Returns a position parameter (0 - 8, corresponding to GEO_CENTER
through GEO_NORTHWEST), -1 if the position name was ambiguous,
and -2 if it was unrecognized.

Side Effects:	None.

GeoPosToName --
---------------

Given a geometric name, return its position name.

Results:
Pointer to a static string holding the position name.
NOTE: you'd better not try to alter the returned string!

Side effects:
None.

GeoTransPos --
--------------
This routine computes the transform of a relative position.

Results:
The return value is a position equal to the position parameter
transformed by t.

Side Effects:	None.

GeoInvertTrans --
-----------------
This routine computes the inverse of a transform.

Results:	None.

Side Effects:
The transform pointed to by inverse is overwritten with
the inverse transform of t.  Note:  this method of inversion
only works for rotations that are multiples of 90 degrees with
unit scale factor.  Beware any changes to this!

GeoInclude --
-------------
This routine includes one rectangle into another by expanding
the second.

Results:
TRUE is returned if the destination had to be enlarged.

Side Effects:
The destination is enlarged (if necessary) so that it completely
contains the area of both the original src and dst rectangles.

GeoIncludeAll --
----------------
This routine includes one rectangle into another by expanding
the second.  This routine differs from GeoInclude in that zero-
size source rectangles are processed.  The source or destination
rectangle is considered to be NULL only if its lower-left corner
is above or to the right of its upper right corner.  In this
case, the other rectangle is the result.

Results:
TRUE is returned if the destination is enlarged; otherwise FALSE.

Side Effects:
The destination is enlarged (if necessary) so that it completely
contains the area of both the original src and dst rectangles.

GeoIncludePoint --
------------------
This routine includes a point into a rectangle by expanding
the rectangle if necessary.  If the destination rectangle has
its lower left corner above or to the right of its upper right
corner, then use the source point to initialize the destination
rectangle.

Results:
None.

Side Effects:
The destination is enlarged (if necessary) so that it completely
contains the area of both the original src and dst.

GeoClip --
----------
clips one rectangle against another.

Results:	None.

Side Effects:
Rectangle r is clipped so that it includes only the
intersection area between r and area.  The rectangle
may end up being turned inside out (xbot>xtop) if
there was absolutely no intersection between the two
boxes.

GeoClipPoint --
---------------
Clips one point against a rectangle, moving the point into
the rectangle if needed.

Results:	None.

Side Effects:
Point p is clipped so that it lies within or on the rectangle.

GeoDisjoint --
--------------

Clip a rectanglular area against a clipping box, applying the
supplied procedure to each rectangular region in "area" which
falls outside "clipbox".  This works in tile space, where a
rectangle is assumed to contain its lower x- and y-coordinates
but not its upper coordinates.  It does NOT work in pixel space
(think about this carefully before using it for pixels!).

The procedure should be of the form:
bool func(box, cdarg)
Rect	   * box;
ClientData   cdarg;

Results:
Return TRUE unless the supplied function returns FALSE.

Side effects:
The side effects of the invoked procedure.

GeoCanonicalRect --
-------------------
Turns a rectangle into a canonical form in which the
lower left is really below and to the left of the upper right.

Results:	None.

Side Effects:
Rectangle rnew is set to the canonical form of rectangle r.

GeoScale --
-----------

Returns the scale factor associated with a transform.

Results:
Scale factor.

Side Effects:
None.

GeoRectPointSide --
-------------------

Returns the side of the rect on which a point lies.

Results:
A direction, or GEO_CENTER if the point is off the boundary.

Side Effects:
None.

GeoRectRectSide --
------------------

Returns the side of the first rect on which the second one
lies.

Results:
A direction, or GEO_CENTER if the rects don't share some
coordinate.  Note, this won't detect the case where the
rectangles don't touch but do share some coordinate.

Side Effects:
None.

GeoDecomposeTransform --
------------------------

Break a transform up into an optional mirror followed by an optional
rotation.  Translation is ignored.  Maybe someone will add this at
a later date.

Results:
None.

Side Effects:
Modifies 'angle' and 'upsidedown' parameters.

GetRect --
----------

Parse a rectangle from a file and fill in the supplied rect struct.
We assume that the rectangle consists of four decimal numbers, each
separated from the next by a single space, and terminated by a newline.

ESTHETIC WARNING:
The algorithm used here is gross but extremely fast.

Results:
FALSE on end of file or error, TRUE otherwise.

Side effects:
Fills in the contents of *rect.

HashInit --
-----------
HashInitClient --

These procedures simply set up the hash table.  The standard
way of initializing the hash table is to use HashInit(), but
if it's desired to provide the hash module with procedures to
use for comparing and copying hash table keys, use HashInitClient().

The number of buckets in the table at the start is 'nBuckets',
which is automatically rounded up to a power of two.  This isn't
a limit on the number of buckets the table will eventually contain,
though, since more buckets are automatically created if the table
gets too full (the number of buckets increases by 4x).

Results:
None.

Side Effects:
Memory is allocated for the initial bucket area.

Table Organization:
Tables can be organized in either of four ways, depending
on the type of comparison keys as specified by ptrKeys.

HT_STRINGKEYS:
Keys are NULL-terminated; their address is passed to
HashFind as a (char *).

HT_WORDKEYS:
These are any 32-bit word, passed to HashFind as a (char *).

HT_STRUCTKEYS:
Actually, any value of ptrKeys >= HT_STRUCTKEYS means
that keys are ptrKeys-word values whose ADDRESS is
passed to HashFind as a (char *).

HT_CLIENTKEYS:
Like HT_WORDKEYS, these are also 32-bit values, passed
to HashFind as a (char *).  However, they are compared
and copied using user-supplied procedures passed to
HashInitClient() when the hash table was created.
(Note that hash tables with keys of type HT_CLIENTKEYS
can ONLY be created using HashInitClient()).

Single-word values, a la HT_WORDKEYS, are fastest but most
restrictive.

Client procedures:
Four client procedures are provided to HashInitClient()
for use in dealing with HT_CLIENTKEYS data.  They should
be of the following form:

Compare two hash keys; return 0 if equal, 1 if not.  If this
procedure is NULL, comparison is just 32-bit comparison of
k1 and k2.

int
(*compareFn)(k1, k2)
char *k1, *k2;
{
}

Create a copy of a hash key for storing in a newly created
hash entry.  If this procedure is NULL, the key is stored
without being copied.

char *
(*copyFn)(key)
char *key;
{
}

Produce a single 32-bit integer for a key value that will
then be randomized by the hashing function.  If NULL, then
the key itself is used as the 32-bit integer.

int
(*hashFn)(key)
char *key;
{
}

Free a key that had been allocated with (*copyFn)().
If NULL, then nothing is done.

Void
(*killFn)(key)
char *key;
{
}

HashLookOnly --
---------------

Searches a hash table for an entry corresponding to key.

Results:
The return value is a pointer to the entry for key,
if key was present in the table.  If key was not
present, NULL is returned.

Side Effects:
None.

HashFind --
-----------

Searches a hash table for an entry corresponding to
key.  If no entry is found, then one is created.

Results:
The return value is a pointer to the entry for key.
If the entry is a new one, then the h_pointer field
of the entry we return is zero.

Side Effects:
Memory is allocated, and the hash buckets may be modified.

HashStats --
------------

This routine merely prints statistics about the
current bucket situation.

Results:
None.

Side Effects:
Junk gets printed.

HashStartSearch --
------------------

This procedure sets things up for a complete search
of all entries recorded in the hash table.

Results:
None.

Side Effects:
The information in hs is initialized so that successive
calls to HashNext will return successive HashEntry's
from the table.

HashNext --
-----------

This procedure returns successive entries in the
hash table.

Results:
The return value is a pointer to the next HashEntry
in the table, or NULL when the end of the table is
reached.

Side Effects:
The information in hs is modified to advance to the
next entry.

HashKill --
-----------

This routine removes everything from a hash table
and frees up the memory space it occupied.

Results:
None.

Side Effects:
Lots of memory is freed up.

HeapInit --
-----------
HeapInitType --

Initialize a heap.  The first form is a heap with integer keys; the
second allows specification of the type of key to use.

Note that with this addressing scheme it is necessary to allocate
2**n + 1 locations for the heap block, location 0 being unused.

Results:
None.

Side effects:
Allocates storage for the heap.  Initializes the fields in the heap
struct.  Memory is allocated.

HeapKill --
-----------

Deallocate all storage associated with the heap.

Results:
None.

Side effects:
Storage is freed.  Fields in the heap record are reset.  If func is
not NULL then call it with each heap element before freeing the heap
entry.

HeapFreeIdFunc --
-----------------

Supplied function to HeapKill.  Frees the referenced entry id if it
is a string, otherwise do nothing.

Results:
None.

Side effects:
Memory is freed.

HeapRemoveTop --
----------------
Delete the top element from the heap.

Results:
Pointer to the removed heap element, which is the same as the entry
pointer passed to the function from outside,  or NULL if no entries
remain.

Side effects:
If the heap has been touched, restore the heap property before removing
the top element.

HeapLookAtTop --
----------------

Return pointer to top element, but don't remove it.

Results:
Pointer to the top heap element, or NULL if heap is empty.

Side effects:
If the heap has been touched, restore the heap property before 
returning the top element.

HeapAdd --
----------

Add an item to the bottom of the heap.  Restore the heap structure
by propagating the item upwards.

Results:
None.

Side effects:
Things get shuffled around in the heap.
Free the old block and allocate a larger block if necessary.

Warning:
Something awful may happen if the id value was declared a string in
HeapInit and you provide something else.

HeapDump --
-----------
Dump the contents of the heap for debugging purposes.

Results:
None.

Side effects:
None.

Lookup --
---------
Searches a table of strings to find one that matches a given
string.  It's useful mostly for command lookup.

Only the portion of a string in the table up to the first
blank character is considered significant for matching.

Results:
If str is the same as
or an unambiguous abbreviation for one of the entries
in table, then the index of the matching entry is returned.
If str is not the same as any entry in the table, but 
an abbreviation for more than one entry, 
then -1 is returned.  If str doesn't match any entry, then
-2 is returned.  Case differences are ignored.

NOTE:  
Table entries need no longer be in alphabetical order
and they need not be lower case.  The irouter command parsing
depends on these features.

Side Effects:
None.

LookupStruct --
---------------

Searches a table of structures, each of which contains a string
pointer as its first element, in a manner similar to that of Lookup()
above.  Each structure in the table has the following form:

struct
{
char *string;
... rest of structure
};

The 'string' field of each structure is matched against the
argument 'str'.  The size of a single structure is given by
the argument 'size'.

Results:
If str is the same as
or an unambiguous abbreviation for one of the entries
in table, then the index of the matching entry is returned.
If str is not the same as any entry in the table, but 
an abbreviation for more than one entry, 
then -1 is returned.  If str doesn't match any entry, then
-2 is returned.  Case differences are ignored.

NOTE:  Table entries need no longer be in alphabetical order
and they need not be lower case.  The irouter command parsing
depends on these features.

Side Effects:
None.

LookupFull --
-------------

Look up a string in a table of pointers to strings.  The last
entry in the string table must be a NULL pointer.
This is much simpler than Lookup() in that it does not
allow abbreviations.

Results:
Index of the name supplied in the table, or -1 if the name
is not found.

Side effects:
None.

LookupAny --
------------

Look up a single character in a table of pointers to strings.  The last
entry in the string table must be a NULL pointer.
The index of the first string in the table containing the indicated
character is returned.

Results:
Index of the name supplied in the table, or -1 if the name
is not found.

Side effects:
None.

Match --
--------

Sees if two strings match, using csh-like pattern matching.

Results:
TRUE is returned if the two strings match, FALSE is returned
if they don't.  The first string, pattern, can contain the
special characters *, ?, \, and [], which are matched as by
the csh.

Side effects:
None.

PaConvertTilde --
-----------------
This routine converts tilde notation into standard directory names.

NOTE:  Intended for search paths, for single names, see PaTildeExpand()
below.

Results:
If the conversion was done successfully, then the return value
is the number of bytes of space left in the destination area.
If a user name couldn't be found in the password file, then
-1 is returned.

Side Effects:
If the first character of the string indicated by psource is a
tilde ("~") then the subsequent user name is converted to a login
directory name and stored in the string indicated by dest.  Then
remaining characters in the file name at psource are copied to
pdest (the file name is terminated by white space, a null character,
or a colon) and psource is updated.  Upon return, psource points
to the terminating character in the source file name, and pdest
points to the null character terminating the expanded name.
If a tilde cannot be converted because the user name cannot
be found, psource is still advanced past the current entry, but
nothing	is stored at the destination.  At most size characters
(including the terminating null character) will be stored at pdest.
Note:  the name "~" with no user name expands to the home directory.

PaTildeExpandName --
--------------------
This routine expands tilde notation in a name.

Results:
Returns a newly mallocated string giving the tilde ('~') expanded name.
Returns NULL if the conversion failed.

Side Effects:
mallocs a string larger enough to hold the result.

PaHasExtension --
-----------------
Check if given name already has an extension.
(i.e. has . in part of name after final /)

Results:
TRUE if extension present, else FALSE

Side Effects:
None.

PaExtendedName --
-----------------
if fName doesn't have extension, default extension tacked on.
Results:
Extended file name
NOTE:  result destroyed on next call to this routine.

PaOpen --
---------
This routine does a file lookup using the current path and
supplying a default extension.

Results:
A pointer to a FILE, or NULL if the file couldn't be found.

Side Effects:
If ext is specified, and file has no extension (no '.' following
final '/', then ext is tacked onto the end of
the given file name.  

If the first character of the
file name is "~" or "/" or if nosearch is TRUE, then we try
to look up the file with the original name, doing tilde
expansion of course and returning that result.  If none of 
these conditions is met, we go through the path	trying to
look up the file once for each path entry by prepending the
path entry to the original file name. This concatenated name
is stored in a static string and made available to the caller
through prealName if the open succeeds.  If the entire path is
tried, and still nothing works, then we try each entry in the
library path next.
Note: the static string will be trashed on the next call to this
routine.  Also, note that no individual file name is allowed to
be more than MAXSIZE characters long.  Excess characters are lost.

Path Format:
A path is a string containing directory names separated by
colons or white space.  Tilde notation may be used within paths.

PaSubsWD --
-----------

Replaces all uses of the working directory in a path
by some fixed directory.

Results:
The return result is a path that is just like the path
argument except that every implicit or explicit use of
the working directory is replaced by the newWD argument.
The result is a static array, which will be trashed on
the next call to this procedure.

Side effects:
None.

PaEnum --
---------

Call a client procedure with each directory in a path
prepended to a filename.  The client procedure is as
follows:

int
(*proc)(name, cdata)
char *name;		/# A directory in the path prepended to
# a file name.
#/
ClientData *cdata;	/# Provided by caller #/
{
}

The client procedure should return 0 normally, or 1 to abort
the path enumeration.  If a directory in the search path
refers to a non-existent user name (using the ~user syntax),
we skip that component.

Results:
Returns 0 if all the clients returned 0, or 1 if
some client returned 1.  When a client returns 1
we abort the enumeration.

Side effects:
Calls the client procedure.

PaSplitName --
--------------

Split a path name, into directory part, base name, and extension.
e.g. for "/home/foo/bar.max":
dir = "/home/foo/"
base = "bar"
ext = ".max"

RunStats --
-----------

This procedure collects information about the process.
Depending on the flags provided, the following information is
returned:

RS_TCUM	 -- cumulative user and system time
RS_TINCR -- difference between current cumulative user and system
time and that when RunStats was last called with RS_TINCR
as a flag.
RS_MEM	 -- number of bytes in the heap area.

Results:
The return value is a string of the form "[ ... <stuff> ...]",
where <stuff> contains the information specified by the flags.
Times are of the form "mins:secsu mins:secss", where the first
time is the amount of user-space CPU time this process has
used, and the second time is the amount of system time used.
Memory is specified by a string of the form "Nk", where N
is the number of kilobytes of heap area used so far.

Side Effects:
If RS_TINCR is specified, the parameters lastt and deltat
are set (if they are both non-NULL).  Both point to tms structs;
the one pointed to by deltat is set to the difference between
the current user/system time and the time given in the tms struct
pointed to by lastt; the one pointed to by lastt is then set to
the current user/system time.

RunStatsRealTime --
-------------------

Reports the real time, both since the first invocation and incremental
since the last invocation.

Results:
A statically allocated string of the form:
x:xx.x x:xx.x
where the first number is the amount of elapsed real time since the
first call to this routine, and the second is the amount of elapsed
real time since the lastest call to this routine.

Side Effects:
None.

StackNew --
-----------

Allocate and initialize a new Stack.

Results:
Returns a pointer to a newly heap-allocated and initialized
stack, with its growth increment set to the specified
size (in entries).

Side effects:
None.

StackFree --
------------

Deallocate a Stack.

Results:
None.

Side effects:
Deallocates all memory currently assigned to the Stack.

StackPush --
------------

Push a new element on to a stack.

Results:
None.

Side effects:
The argument stack is updated to reflect the new
item placed upon it.

StackPop --
-----------

Pop the top element from a Stack and return it.

Results:
Top element from stack.
If the stack is already empty, returns NULL.
Callers should probably avoid popping from an empty
stack.

Side effects:
Updates the stack to reflect the result of popping its top.

StackLook --
------------

Return the top element from a Stack, but don't pop it off.

Results:
Top element from stack.
If the stack is already empty, returns NULL.

Side effects:
None.

StackEnum --
------------

Enumerate all elements on the stack.  Call the supplied function
for each occurrence.

The supplied function is of the form:
int func(stackItem, i, clientData)
ClientData stackItem;    Item put on the stack
int i;		     Index of the item on stack
ClientData cd;	     Points to whatever you want
The function normally returns 0.  The enumeration terminates if it
returns anything else.

Results:
None.

Side effects:
None.

StackCopy --
------------

Make a copy of a stack.

Results:
Memory may get allocated if the copystr parameter says to copy
strings rather than pointers to them.

Side effects:
dest gets a copy of src.  If dest is non-null, it gets freed.

StrDup --
---------

Return a malloc'd copy of a string.

Results:
Returns a pointer to a newly malloc'd character array just
large enough to hold the supplied string and its trailing
null byte, which contains a copy of the supplied string.

Side effects:
MALLOC's a character array large enough to hold str, and
copies str into it, unless str is NULL.  If str is NULL, no
MALLOC is done.  Also, if oldstr is non-NULL, then a) if
*oldstr is not NULL, frees the storage allocated to oldstr,
and b) sets *oldstr to the new string allocated, or to
NULL if str is NULL.

StrIsWhite:
-----------

Check to see if a string is all white space or is a comment.

Results:
True if it is all white, false otherwise.

Side effects:
none.

StrIsInt --
-----------

Check a string for being an integer.

Results:
TRUE if the string is a well-formed integer, FALSE otherwise.

Side effects:
None.

StrIsDecimal --
---------------

Check a string for being a valid decimal number.

Results:
TRUE if the string is a well-formed float without exponential
notation, FALSE otherwise.

Side effects:
None.

StrToLower --
-------------

Convert string to all lowercase.

StrToUpper --
-------------

Convert string to all lowercase.

