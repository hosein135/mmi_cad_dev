#include "port.h"
#include "error.h"
#include "mem.h"
#include "ar.h"
#include "hashtab.h"
#include "str.h"
#include "skip-list.h"
#include "nl.h"
#include "pnl.h"
#include "tcl.h"
#include "pat.h"
#include "pat_int.h"


/* Names of nl attributes used herein. */
#define ATTR_DES_BOX "des box"
#define ATTR_HIER_LOC   "cell hloc"


/* Function prototype for pat_hier_walk_cells() */
/* If function returns non-zero, abort the walking, and return that value, */
/* and anything placed in errmsg, if non-null, to the caller. */
/* loc is the location and orientation of cell in a flat context. */
/* The path is the instance path to the current cell. */
/* What barfo syntax. */
/* Modified (jka): replaced errmsg with error (), removed errmsg arg. */
/* typedef int (*hier_walk_cells_func)(nl_cell cell,Pat_location*loc,char*path); */


/* If errmsg is non-null, fill it in with error message, if any. */
/* Modified (jka): replaced errmsg with error (), removed errmsg arg. */
static int _pat_hier_walk_cells_int(nl_design des,hier_walk_cells_func func,char *path,
	Pat_transform *xform)
{
  nl_object downobj;
  Pat_transform loc, flatloc;
  int pathlen = strlen(path);

  assert(des && nl_object_kind((nl_object)des) == nl_kind_design);

  nl_design_for_all_cells(des,cell) {
      assert(nl_object_kind((nl_object)cell) == nl_kind_cell);


      /* Might return a design or a libcell, or NULL. */
      downobj = nl_reference_down_design(nl_cell_reference(cell));
      if (downobj == NULL) {
	/* Design is not linked, or no sub-design or libcell exists. */
	error ("no down design for design %s cell %s",
	       nl_design_name (des), nl_cell_name (cell));
      }

      switch (nl_object_kind(downobj)) {
	default:
	  assert(!"unrecognized object kind");

	case nl_kind_libcell: {
	  int ret;
	  /* Get cell location, then transform by xform to get flatloc; */
	  if (pat_get_cell_location(cell,&loc)) { return -1; }
	  pat_trans_trans(&loc,xform,&flatloc);
	  if ((ret = func(cell,&flatloc,path))) {return ret;}
	  break;
	}
	case nl_kind_design: {
	  /* Walk the sub-design. */
	  nl_design subdes = (nl_design) downobj;
	  int ret;

	  /* Add cell instance name to path. */
	  if (pathlen!=0) {strcat(path,"/");}
	  strcat(path,nl_cell_name(cell));

	  /* Get cell origin, then transform by xform to get flatloc; */
	  if (pat_get_cell_location(cell,&loc)) { return -1; }
	  pat_trans_trans(&loc,xform,&flatloc);

	  if ((ret = _pat_hier_walk_cells_int(subdes,func,path,&flatloc))) {return ret;}

	  path[pathlen] = 0; /* Remove this cell from path */
	  break;
	}
      } /*switch */

    }
    nl_end_for /*nl_design_for_all_cells */
  
  return 0;  /* completion */
}


/* Apply func to all leaf cells in hierarchical design. */
/* Leaf cells are known because they are nl "libcells", */
/* typically read in from a LEF file. */
/* Set errmsg (pointer to large buffer), if non-null, on failure. */
/* Modified (jka): replaced errmsg with error (), removed errmsg arg. */
int pat_hier_walk_cells(nl_design des,hier_walk_cells_func func)
{
  Pat_transform identity_transform = {0,0,pnl_orientation_N};
  char pathbuf[10000];
  pathbuf[0] = 0;

  return _pat_hier_walk_cells_int(des,func,pathbuf,&identity_transform);
}



/* These should be in ../nl */
/* Set attribute by name on obj in design des.  If obj == des, it is an attribute on des. */
/* If attribute does not pre-exist, create dense attribute in des. */
static void pat_attr_set(nl_design des, nl_object obj, char *name,
		  void *data, int size)
{
  nl_attr attr = nl_design_get_attr_by_name(des,name);

  if (attr == NULL) {
      attr = nl_attr_create(name, (nl_object) des, nl_object_kind(obj),
			    nl_density_dense, size, NULL, NULL);
  }

  nl_attr_set(attr,obj,data);
}


/* Get attribute by name on obj in design des.  Return 0 if found. */
static int pat_attr_get(nl_design des, nl_object obj, char *name, void *data)
{
  nl_attr attr = nl_design_get_attr_by_name(des,name);
  if (attr == NULL) {return 1;}
  nl_attr_get(attr,obj,data);
  return 0;
}


void
pat_get_design_size (nl_design design, Pat_rect *box)
{
  int flag = pat_attr_get (design, (nl_object) design, ATTR_DES_BOX, box);

  if ( flag ) {
    error ("design %s size is not set", nl_design_name (design));
  }
}


void
pat_set_design_size (nl_design design, Pat_rect *box)
{
  pat_attr_set (design, (nl_object) design, ATTR_DES_BOX, box,
		sizeof (Pat_rect));
}


/* Return the size of obj in the pbox argument. */
/* Obj may be a design, cell, or libcell. */
/* Return 0 on success, non-zero on failure. */
/* Set errmsg (pointer to large buffer), if non-null, on failure. */
/* Failure caused if size of object is unknown. */
/* Modified (jka): replaced errmsg with error (), removed errmsg arg. */
int pat_get_cell_bbox(nl_object obj, Pat_rect *pbox)
{
    int ret;
    assert(obj && pbox);

    switch (nl_object_kind(obj)) {
      default:
	  assert(!"unrecognized object kind");

      case nl_kind_cell: {
	  nl_cell cell = (nl_cell)obj;
	  nl_object downobj;
	  nl_reference ref = nl_cell_reference(cell);
	  assert(ref);
	  downobj = nl_reference_down_design(ref);  /* Might return a design or a libcell. */
	  if (downobj==NULL) {
	    error ("no down design or libcell for cell %s",
		   nl_cell_name (cell));
	  }
	  if ((ret=pat_get_cell_bbox(downobj,pbox))) {return ret;}
	  break;
      }
      case nl_kind_libcell: {
	  /* Cell size was specified in LEF.  Hopefully. */
	  nl_libcell libcell = (nl_libcell) obj;
	  nl_library library = nl_libcell_library (libcell);
	  pnl_library plibrary;
	  pnl_libcell plibcell;
	  assert(library);

	  nl_library_attr_get_by_name("pnl library", library, &plibrary);
	  assert(plibrary);
	  plibcell = pnl_library_get_libcell(plibrary, libcell);

	  pbox->x1 = pbox->y1 = 0;
	  pbox->x2 = pnl_libcell_sizex(plibcell);
	  pbox->y2 = pnl_libcell_sizey(plibcell);
	  break;
      }
      case nl_kind_design: {
	nl_design des = (nl_design) obj;
	if (pat_attr_get(des,obj,ATTR_DES_BOX,pbox)) {return 1;}
	break;
      }
    } /* switch */

    return 0;	/* success */
}


/* Return 0 on success, non-zero on failure. */
/* Set errmsg (pointer to large buffer), if non-null, on failure. */
/* If corner==1, set location of cell lower left corner, otherwise of origin. */
/* This is provided as a convenience when reading from DEF. */
/* Modified (jka): replaced errmsg with error (), removed errmsg arg. */
int pat_set_cell_location(nl_cell cell, Pat_location *ploc,int corner)
{
  nl_design des = nl_cell_design(cell);
  Pat_location s_loc = *ploc;

  if (corner) {
    /* We want to save the origin, but the given x,y are the lower left corner. */
    Pat_rect box;
    int xsize, ysize;
    if (pat_get_cell_bbox((nl_object)cell,&box)) {
      return -1;
    }
    xsize = box.x2 - box.x1;
    ysize = box.y2 - box.y1;

    switch (s_loc.ori) {
    case pnl_orientation_N:
      s_loc.x += box.x1;
      s_loc.y += box.y1;
      break;
    case pnl_orientation_S:
      s_loc.x += box.x1 + xsize;
      s_loc.y += box.y1 + ysize;
      break;
    case pnl_orientation_E:
      s_loc.x += box.y1;
      s_loc.y += box.x1 + xsize;    /* its rotated, so use xsize */
      break;
    case pnl_orientation_W:
      s_loc.x += box.y1 + ysize;	/* its rotated, so use ysize */
      s_loc.y += box.x1;
      break;
    case pnl_orientation_FN:
      s_loc.x += box.x1 + xsize;
      s_loc.y += box.y1;
      break;
    case pnl_orientation_FS:
      s_loc.x += box.x1;
      s_loc.y += box.y1 + ysize;
      break;
    case pnl_orientation_FE:
      s_loc.x += box.y1 + ysize;	/* its rotated, so use ysize */
      s_loc.y += box.x1 + xsize;	/* its rotated, so use xsize */
    case pnl_orientation_FW:
      /* rotated 90 and flipped about x, so origin is at lower left corner. */
      s_loc.x += box.y1;
      s_loc.y += box.x1;
      break;
    default:
      error ("unrecognized orientation for cell %s", nl_cell_name (cell));
    }
  }

  pat_attr_set(des,(nl_object)cell,ATTR_HIER_LOC,&s_loc,sizeof(Pat_location));
  return 0;  /* success */
}


/* Get cell origin and orientation in its immediate parent. */
/* Return 0 on success, non-zero on failure. */
/* Set errmsg (pointer to large buffer), if non-null, on failure. */
/* Note: use get_cell_bbox followed by pat_trans_rect to get the cell corners. */
/* Modified (jka): replaced errmsg with error (), removed errmsg arg. */
int pat_get_cell_location(nl_cell cell, Pat_location *loc)
{
  nl_design des = nl_cell_design(cell);
  Pat_location s_loc;

  assert(loc);

  if (pat_attr_get(des,(nl_object)cell,ATTR_HIER_LOC,&s_loc)) {
    error ("no location specified for design %s cell %s",
	   nl_design_name (des), nl_cell_name (cell));
  }

#if 0  /* old code.  Always returns origin, now. */
  if (origin) {
    /* s_loc saves the lower left corner, but we want the origin. */
    int xsize, ysize;
    if (pat_get_cell_size((nl_object)cell,&xsize,&ysize)) {
      return -1;
    }

    switch (s_loc.ori) {
       case pnl_orientation_N:
	 break;
       case pnl_orientation_S:
	 s_loc.x = s_loc.x + xsize;
	 s_loc.y = s_loc.y + ysize;
	 break;
       case pnl_orientation_E:
	 s_loc.y = s_loc.y + xsize;   /* its rotated, so use xsize */
	 break;
       case pnl_orientation_W:
	 s_loc.x = s_loc.x + ysize;	/* its rotated, so use ysize */
	 break;
       case pnl_orientation_FN:
	 s_loc.x = s_loc.x + xsize;
	 break;
       case pnl_orientation_FS:
	 s_loc.y = s_loc.y + ysize;
	 break;
       case pnl_orientation_FE:
	 s_loc.x = s_loc.x + ysize;	/* its rotated, so use ysize */
	 s_loc.y = s_loc.y + xsize;	/* its rotated, so use xsize */
       case pnl_orientation_FW:
	 break;
       default:
	 error ("unrecognized orientation for cell %s",
		nl_cell_name (cell));
    }
  }
#endif
  loc->x = s_loc.x;
  loc->y = s_loc.y;
  loc->ori = s_loc.ori;
  return 0; /* success */
}


