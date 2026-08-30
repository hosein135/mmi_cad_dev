
/* Structure to hold cell/port location in nl attributes. */
/* (x,y) are the coordinates of the cell origin, not the corner. */
/* The ori is one of pnl_orientation_N, ... */
struct Pat_location_s {
    int x, y;   /* x,y in nanons (10**-9 meters) */
    int ori;    /* orientation is a pnl_orientation enum value. */
};

typedef struct Pat_location_s Pat_location;

/* Same structure used for transforms as for locations. */
typedef struct Pat_location_s Pat_transform;


struct Pat_rect_s {
    int x1, y1, x2, y2;
};
typedef struct Pat_rect_s Pat_rect;


/* Function prototype for pat_hier_walk_cells() */
/* If function returns non-zero, abort the walking, and return that value, */
/* and anything placed in errmsg, if non-null, to the caller. */
/* loc is the location and orientation of cell in a flat context. */
/* The path is the instance path to the current cell. */
/* What barfo syntax. */
typedef int (*hier_walk_cells_func)(nl_cell cell,Pat_location*loc,char*path);

/* Get cell origin and orientation in its immediate parent. */
/* Return 0 on success, non-zero on failure. */
/* Set errmsg (pointer to large buffer), if non-null, on failure. */
/* Note: use get_cell_bbox followed by pat_trans_rect to get the cell corners. */
int pat_get_cell_location(nl_cell cell, Pat_location *loc);

/* Return 0 on success, non-zero on failure. */
/* Set errmsg (pointer to large buffer), if non-null, on failure. */
/* If corner==1, set location of cell lower left corner, otherwise of origin. */
/* This is provided as a convenience when reading from DEF. */
int pat_set_cell_location(nl_cell cell, Pat_location *ploc,int corner);

/* Return the size of obj in the pbox argument. */
/* Obj may be a design, cell, or libcell. */
/* Return 0 on success, non-zero on failure. */
/* Set errmsg (pointer to large buffer), if non-null, on failure. */
/* Failure caused if size of object is unknown. */
int pat_get_cell_bbox(nl_object obj, Pat_rect *pbox);

/* Apply func to all leaf cells in hierarchical design. */
/* Leaf cells are known because they are nl "libcells", */
/* typically read in from a LEF file. */
/* Set errmsg (pointer to large buffer), if non-null, on failure. */
int pat_hier_walk_cells(nl_design des,hier_walk_cells_func func);

/* apply transfrom tr to box.  Return box in canonical format. */
void pat_trans_rect(Pat_transform *tr, Pat_rect *box);

/* apply transform tr to x,y. */
/* Very similar to pat_trans_trans. */
void pat_trans_xy(Pat_transform *tr,int *px,int *py);

/* apply transfrom t2 to location or transform t1, return result in out. */
/* Note that out can not be the same as t1. */
void pat_trans_trans(Pat_transform *t1, Pat_transform *t2, Pat_transform *out);


void pat_get_design_size (nl_design, Pat_rect *);
void pat_set_design_size (nl_design, Pat_rect *);
