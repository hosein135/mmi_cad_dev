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


#define PNL_TRANS_MAX 10

/* These map pnl orientation to a,b,d,e of the standard matric transform [a b c d e f] */
/* where x2 = a*x1 + b*y1 + c;  y2 = d*x1 + e*y1 + f. */
static int t_a[PNL_TRANS_MAX] = {0};
static int t_b[PNL_TRANS_MAX] = {0};
static int t_d[PNL_TRANS_MAX] = {0};
static int t_e[PNL_TRANS_MAX] = {0};

/* lookup table for transform of a transform. */
static int trans_lookup[PNL_TRANS_MAX][PNL_TRANS_MAX] = {{0}};

/* lookup table for orientation inverse. */
static int trans_invert[PNL_TRANS_MAX] = {0};



/* Multiply val by ab, where ab is 0,1 or -1. */
#define TRANSMULT(val,ab) (ab>0 ? (val) : ab<0 ? - (val) : 0)

#define TRANS_INIT(ori,a,b,d,e) \
  {t_a[ori] = (a); t_b[ori] = (b); t_d[ori] = (d); t_e[ori] = (e);}


static void pat_trans_init()
{
    static int inited = 0;
    if (inited) return;
    inited = 1;

    /* Its: TRANS_INIT(orientation, a, b, d, e); */
    TRANS_INIT(pnl_orientation_N,1,0,0,1);
    TRANS_INIT(pnl_orientation_S,-1,0,0,-1);
    TRANS_INIT(pnl_orientation_E,0,1,-1,0);
    TRANS_INIT(pnl_orientation_W,0,-1,1,0);
    TRANS_INIT(pnl_orientation_FN,-1,0,0,1);
    TRANS_INIT(pnl_orientation_FS,1,0,0,-1);
    TRANS_INIT(pnl_orientation_FE,0,-1,-1,0);
    TRANS_INIT(pnl_orientation_FW,0,1,1,0);

    /* Using matrix transforms, the orientation inverse is calculated from: */
    /* xinv->t_a = xt->t_a; */
    /* xinv->t_b = xt->t_d; */
    /* xinv->t_d = xt->t_b; */
    /* xinv->t_e = xt->t_e; */

    /* All orientations are their own inverse except E and W. */
    trans_invert[pnl_orientation_N] = pnl_orientation_N;
    trans_invert[pnl_orientation_S] = pnl_orientation_S;
    trans_invert[pnl_orientation_E] = pnl_orientation_W;
    trans_invert[pnl_orientation_W] = pnl_orientation_E;
    trans_invert[pnl_orientation_FN] = pnl_orientation_FN;
    trans_invert[pnl_orientation_FS] = pnl_orientation_FS;
    trans_invert[pnl_orientation_FE] = pnl_orientation_FE;
    trans_invert[pnl_orientation_FW] = pnl_orientation_FW;

    trans_lookup[pnl_orientation_N][pnl_orientation_N] = pnl_orientation_N;
    trans_lookup[pnl_orientation_N][pnl_orientation_S] = pnl_orientation_S;
    trans_lookup[pnl_orientation_N][pnl_orientation_FN] = pnl_orientation_FN;
    trans_lookup[pnl_orientation_N][pnl_orientation_FS] = pnl_orientation_FS;
    trans_lookup[pnl_orientation_N][pnl_orientation_E] = pnl_orientation_E;
    trans_lookup[pnl_orientation_N][pnl_orientation_W] = pnl_orientation_W;
    trans_lookup[pnl_orientation_N][pnl_orientation_FW] = pnl_orientation_FW;
    trans_lookup[pnl_orientation_N][pnl_orientation_FE] = pnl_orientation_FE;
    trans_lookup[pnl_orientation_S][pnl_orientation_N] = pnl_orientation_S;
    trans_lookup[pnl_orientation_S][pnl_orientation_S] = pnl_orientation_N;
    trans_lookup[pnl_orientation_S][pnl_orientation_FN] = pnl_orientation_FS;
    trans_lookup[pnl_orientation_S][pnl_orientation_FS] = pnl_orientation_FN;
    trans_lookup[pnl_orientation_S][pnl_orientation_E] = pnl_orientation_W;
    trans_lookup[pnl_orientation_S][pnl_orientation_W] = pnl_orientation_E;
    trans_lookup[pnl_orientation_S][pnl_orientation_FW] = pnl_orientation_FE;
    trans_lookup[pnl_orientation_S][pnl_orientation_FE] = pnl_orientation_FW;
    trans_lookup[pnl_orientation_FN][pnl_orientation_N] = pnl_orientation_FN;
    trans_lookup[pnl_orientation_FN][pnl_orientation_S] = pnl_orientation_FS;
    trans_lookup[pnl_orientation_FN][pnl_orientation_FN] = pnl_orientation_N;
    trans_lookup[pnl_orientation_FN][pnl_orientation_FS] = pnl_orientation_S;
    trans_lookup[pnl_orientation_FN][pnl_orientation_E] = pnl_orientation_FW;
    trans_lookup[pnl_orientation_FN][pnl_orientation_W] = pnl_orientation_FE;
    trans_lookup[pnl_orientation_FN][pnl_orientation_FW] = pnl_orientation_E;
    trans_lookup[pnl_orientation_FN][pnl_orientation_FE] = pnl_orientation_W;
    trans_lookup[pnl_orientation_FS][pnl_orientation_N] = pnl_orientation_FS;
    trans_lookup[pnl_orientation_FS][pnl_orientation_S] = pnl_orientation_FN;
    trans_lookup[pnl_orientation_FS][pnl_orientation_FN] = pnl_orientation_S;
    trans_lookup[pnl_orientation_FS][pnl_orientation_FS] = pnl_orientation_N;
    trans_lookup[pnl_orientation_FS][pnl_orientation_E] = pnl_orientation_FE;
    trans_lookup[pnl_orientation_FS][pnl_orientation_W] = pnl_orientation_FW;
    trans_lookup[pnl_orientation_FS][pnl_orientation_FW] = pnl_orientation_W;
    trans_lookup[pnl_orientation_FS][pnl_orientation_FE] = pnl_orientation_E;
    trans_lookup[pnl_orientation_E][pnl_orientation_N] = pnl_orientation_E;
    trans_lookup[pnl_orientation_E][pnl_orientation_S] = pnl_orientation_W;
    trans_lookup[pnl_orientation_E][pnl_orientation_FN] = pnl_orientation_FE;
    trans_lookup[pnl_orientation_E][pnl_orientation_FS] = pnl_orientation_FW;
    trans_lookup[pnl_orientation_E][pnl_orientation_E] = pnl_orientation_S;
    trans_lookup[pnl_orientation_E][pnl_orientation_W] = pnl_orientation_N;
    trans_lookup[pnl_orientation_E][pnl_orientation_FW] = pnl_orientation_FN;
    trans_lookup[pnl_orientation_E][pnl_orientation_FE] = pnl_orientation_FS;
    trans_lookup[pnl_orientation_W][pnl_orientation_N] = pnl_orientation_W;
    trans_lookup[pnl_orientation_W][pnl_orientation_S] = pnl_orientation_E;
    trans_lookup[pnl_orientation_W][pnl_orientation_FN] = pnl_orientation_FW;
    trans_lookup[pnl_orientation_W][pnl_orientation_FS] = pnl_orientation_FE;
    trans_lookup[pnl_orientation_W][pnl_orientation_E] = pnl_orientation_N;
    trans_lookup[pnl_orientation_W][pnl_orientation_W] = pnl_orientation_S;
    trans_lookup[pnl_orientation_W][pnl_orientation_FW] = pnl_orientation_FS;
    trans_lookup[pnl_orientation_W][pnl_orientation_FE] = pnl_orientation_FN;
    trans_lookup[pnl_orientation_FW][pnl_orientation_N] = pnl_orientation_FW;
    trans_lookup[pnl_orientation_FW][pnl_orientation_S] = pnl_orientation_FE;
    trans_lookup[pnl_orientation_FW][pnl_orientation_FN] = pnl_orientation_W;
    trans_lookup[pnl_orientation_FW][pnl_orientation_FS] = pnl_orientation_E;
    trans_lookup[pnl_orientation_FW][pnl_orientation_E] = pnl_orientation_FS;
    trans_lookup[pnl_orientation_FW][pnl_orientation_W] = pnl_orientation_FN;
    trans_lookup[pnl_orientation_FW][pnl_orientation_FW] = pnl_orientation_N;
    trans_lookup[pnl_orientation_FW][pnl_orientation_FE] = pnl_orientation_S;
    trans_lookup[pnl_orientation_FE][pnl_orientation_N] = pnl_orientation_FE;
    trans_lookup[pnl_orientation_FE][pnl_orientation_S] = pnl_orientation_FW;
    trans_lookup[pnl_orientation_FE][pnl_orientation_FN] = pnl_orientation_E;
    trans_lookup[pnl_orientation_FE][pnl_orientation_FS] = pnl_orientation_W;
    trans_lookup[pnl_orientation_FE][pnl_orientation_E] = pnl_orientation_FN;
    trans_lookup[pnl_orientation_FE][pnl_orientation_W] = pnl_orientation_FS;
    trans_lookup[pnl_orientation_FE][pnl_orientation_FW] = pnl_orientation_S;
    trans_lookup[pnl_orientation_FE][pnl_orientation_FE] = pnl_orientation_N;
}

/* apply transform tr to x,y. */
/* Very similar to pat_trans_trans. */
void pat_trans_xy(Pat_transform *tr,int *px,int *py)
{
    int tx = *px, ty = *py;
    pat_trans_init();

    *px = TRANSMULT(tx,t_a[tr->ori]) + TRANSMULT(ty,t_b[tr->ori]) + tr->x;
    *py = TRANSMULT(tx,t_d[tr->ori]) + TRANSMULT(ty,t_e[tr->ori]) + tr->y;
}


/* apply transfrom t2 to location or transform t1, return result in out. */
/* Note that out can not be the same as t1. */
void pat_trans_trans(Pat_transform *t1, Pat_transform *t2, Pat_transform *out)
{
  pat_trans_init();

  /* Equivalent to: */
  /* out->t_a = first->t_a*second->t_a + first->t_d*second->t_b; */
  /* out->t_b = first->t_b*second->t_a + first->t_e*second->t_b; */
  /* out->t_c = first->t_c*second->t_a + first->t_f*second->t_b + second->t_c; */
  /* out->t_d = first->t_a*second->t_d + first->t_d*second->t_e; */
  /* out->t_e = first->t_b*second->t_d + first->t_e*second->t_e; */
  /* out->t_f = first->t_c*second->t_d + first->t_f*second->t_e + second->t_f; */

  /* So: */
  /* net->x = t1->x*t2->a + t1->y*t2->b + t2->x; */
  /* net->y = t1->x*t2->t_d + t1->y*t2->t_e + t2->y; */

  assert(out != t1 && out != t2);
  out->x = TRANSMULT(t1->x,t_a[t2->ori]) + TRANSMULT(t1->y,t_b[t2->ori]) + t2->x;
  out->y = TRANSMULT(t1->x,t_d[t2->ori]) + TRANSMULT(t1->y,t_e[t2->ori]) + t2->y;
  out->ori = trans_lookup[t1->ori][t2->ori];
}


/* Make rectangle canonical, ie, make (x1,y1) the lower left corner. */
void pat_can_rect(Pat_rect *box)
{
    int tmp;
    if (box->x1 > box->x2) {
	tmp = box->x1;
	box->x1 = box->x2;
	box->x2 = tmp;
    }
    if (box->y1 > box->y2) {
	tmp = box->y1;
	box->y1 = box->y2;
	box->y2 = tmp;
    }
}


/* apply transfrom tr to box.  Return box in canonical format. */
void pat_trans_rect(Pat_transform *tr, Pat_rect *box)
{
    pat_trans_xy(tr,&box->x1,&box->y1);
    pat_trans_xy(tr,&box->x2,&box->y2);
    pat_can_rect(box);
}



/* Invert the transform. */
void pat_trans_invert(Pat_transform *in, Pat_transform *out)
{
  pat_trans_init();

  /* Equivalent to: */
  /* t->t_a = in->t_a; */
  /* t->t_b = in->t_d; */
  /* t->t_d = in->t_b; */
  /* t->t_e = in->t_e; */
  /* t->t_c = t->t_f = 0; */
  /* out->t_a = t->t_a; */
  /* out->t_b = t->t_b; */
  /* out->t_d = t->t_d; */
  /* out->t_e = t->t_e; */
  /* out->t_c = x*t->t_a + y*t->t_b + t->t_c; */
  /* out->t_f = x*t->t_d + y*t->t_e + t->t_f; */

  out->ori = trans_invert[in->ori];
  out->x = - TRANSMULT(in->x,t_a[out->ori]) - TRANSMULT(in->y,t_b[out->ori]);
  out->y = - TRANSMULT(in->x,t_d[out->ori]) - TRANSMULT(in->y,t_e[out->ori]);
}



#if 0  /* Not using this */

#define SET_TRANSFORM(xform,a,b,c,d,e,f) { \
  xform->t_a=(a);xform->t_b=(b);xform->t_c=(c);xform->t_d=(d);xform->t_e=(e);xform->t_f=(f);\
  }

/* Set xform based on x,y and integer pnl orientation. */
/* Return 0 on success. */
int pat_location2transform(int x, int y, int iori, Pat_transform *xform)
{
  switch (iori) {
    case pnl_orientation_N:
      SET_TRANSFORM(xform,1,0,x,0,1,y);
      return 0;
    case pnl_orientation_S:
      SET_TRANSFORM(xform,-1,0,x,0,-1,y);
      return 0;
    case pnl_orientation_E:
      SET_TRANSFORM(xform,0,1,x,1,0,y);
      return 0;
    case pnl_orientation_W:
      SET_TRANSFORM(xform,0,-1,x,1,0,y);
      return 0;
    case pnl_orientation_FN:
      SET_TRANSFORM(xform,-1,0,x,0,1,y);
      return 0;
    case pnl_orientation_FS:
      SET_TRANSFORM(xform,1,0,x,0,-1,y);
      return 0;
    case pnl_orientation_FE:
      SET_TRANSFORM(xform,0,-1,x,-1,0,y);
      return 0;
    case pnl_orientation_FW:
      SET_TRANSFORM(xform,0,1,x,1,0,y);
      return 0;
    default:
      return -1;
  }
  assert(0);
}
#endif

int pat_string_to_ori(char *ori) {

  /* Look for MAX orientations */
  if ( strcmp (ori, "") == 0 )
    return pnl_orientation_N;
  if ( strcmp (ori, "r180") == 0 )
    return pnl_orientation_S;
  if ( strcmp (ori, "r90") == 0 )
    return pnl_orientation_E;
  if ( strcmp (ori, "r270") == 0 )
    return pnl_orientation_W;
  if ( strcmp (ori, "fx") == 0 )
    return pnl_orientation_FN;
  if ( strcmp (ori, "fy") == 0 )
    return pnl_orientation_FS;
  if ( strcmp (ori, "fy_r90") == 0 )
    return pnl_orientation_FE;
  if ( strcmp (ori, "fx_r90") == 0 )
    return pnl_orientation_FW;

  /* Look for DEF orientations */
  if ( strcasecmp (ori, "N") == 0 )
    return pnl_orientation_N;
  if ( strcasecmp (ori, "S") == 0 )
    return pnl_orientation_S;
  if ( strcasecmp (ori, "E") == 0 )
    return pnl_orientation_E;
  if ( strcasecmp (ori, "W") == 0 )
    return pnl_orientation_W;
  if ( strcasecmp (ori, "FN") == 0 )
    return pnl_orientation_FN;
  if ( strcasecmp (ori, "FS") == 0 )
    return pnl_orientation_FS;
  if ( strcasecmp (ori, "FE") == 0 )
    return pnl_orientation_FE;
  if ( strcasecmp (ori, "FW") == 0 )
    return pnl_orientation_FW;

  /* Look for SUE orientations */
  if ( strcmp (ori, "R0") == 0 )
    return pnl_orientation_N;
  if ( strcmp (ori, "RXY") == 0 )
    return pnl_orientation_S;
  if ( strcmp (ori, "R90") == 0 )
    return pnl_orientation_E;
  if ( strcmp (ori, "R270") == 0 )
    return pnl_orientation_W;
  if ( strcmp (ori, "RX") == 0 )
    return pnl_orientation_FN;
  if ( strcmp (ori, "RY") == 0 )
    return pnl_orientation_FS;
  if ( strcmp (ori, "R90Y") == 0 )
    return pnl_orientation_FE;
  if ( strcmp (ori, "R90X") == 0 )
    return pnl_orientation_FW;

  if ( strcasecmp (ori, "null") == 0 )
    return pnl_orientation_null;
  if ( strcasecmp (ori, "none") == 0 )
    return pnl_orientation_none;
  
  return pnl_orientation_null;
}
