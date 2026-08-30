// ************************************************************************
// 
// Copyright (c) 1995-2002 Juniper Networks, Inc. All rights reserved.
// Portions Copyright (c) 1994 Sun Microsystems, Inc. All rights reserved.
// 
// Permission is hereby granted, without written agreement and without
// license or royalty fees, to use, copy, modify, and distribute this
// software and its documentation for any purpose, provided that the
// above copyright notice and the following three paragraphs appear in
// all copies of this software.
// 
// IN NO EVENT SHALL JUNIPER NETWORKS, INC. OR SUN MICROSYSTEMS, INC. BE
// LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR
// CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
// DOCUMENTATION, EVEN IF JUNIPER NETWORKS, INC. OR SUN MICROSYSTEMS,
// INC. HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// 
// JUNIPER NETWORKS, INC. AND SUN MICROSYSTEMS, INC. SPECIFICALLY
// DISCLAIM ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
// NON-INFRINGEMENT.
// 
// THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND JUNIPER
// NETWORKS, INC. AND SUN MICROSYSTEMS, INC. HAVE NO OBLIGATION TO
// PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
// 
// ************************************************************************


/* tcl C procedures for implementing Micro Magic's new spicetool MMI_NST */

#include <tk.h>
#include <tcl.h>
#include <blt.h>
#include <stdio.h>
#include <math.h>
#include <string.h>
#include <strings.h>
/* #include <X11/Xlib.h> */

/* Some useful macros and constants */

#define MAX(a,b)  ( (a)<(b) ? (b) : (a) )
#define MIN(a,b)  ( (a)>(b) ? (b) : (a) )
#define ABS(a) (((a) < 0) ? (-(a)) : (a))

#define FALSE NULL
#define TRUE !NULL

/* bi endian stuff */
static  int     bad_blk = 0 , try_rev = 0 ;


#define RAD_TO_DEG 180.0/3.14159265

/* need to define type numbers for hspice binary data types */
#define VOLTAGE 1
#define CURRENT 8
#define HERTZ 2     /* frequency */
#define PHASE 5     /* phase, either voltage or current */
#define SWEEP 6     /* for dc sweeps, the sweep variable */

#define VM 11       /* voltage magnitude */
#define VP 12       /* voltage phase */
#define IM 13       /* current magnitude */
#define IP 14       /* current phase */


struct data_struct
{
  int var_count;                /* total # of vars = nodknt + numnoi */
  int nodknt;                   /* number of nodes, either voltage of current */
  int numnoi;			/* number of special data types (not used here) */
  int cndcnt;			/* are there sweeps, 1=multiple */
  int sweepcnt;			/* number of sweeps */
  char version[5];              /* 9007 for anything beyond 9007 (not used here) */
  char qtitle[77];              /* hspice title card (first card in spice deck) */
  char cdate[9];                /* date hspice job was run in format 31-aug94 */
  char ctime[9];                /* time hspice job was run in format 10: 5:56 */
/*  char (*cnam)[17]; */            /* 16 character node/current name */ 
  char (**cnam);             /* 16 character node/current name */
  int  *ityp;                   /* 1 = voltage, !1 = current */
  float **sample_vector;        /* data.  auto grows */
  int sample_vector_size;       /* current array size allocated for data points
				   per node.  auto grows */
  int points;                   /* number of data points per node */
};


struct tmp_struct
{
  char type; 
  char *name;
  struct tmp_struct *next;
};


char error_msg[256];


/* nst_read_tr0 reads in the spice data file and stuffs the information in
   a big data struct and some tcl associative arrays.  Takes two arguments:
   the spice data file name and an id number for the node arrays.
*/

nst_read_tr0(clientData,interp,argc,argv)
ClientData clientData;
Tcl_Interp *interp;
int argc;
char *argv[];
{
  struct data_struct *data_ptr,*read_file(),*read_ascii_file(),
         *read_intel_file();
  FILE *fp,*fp2;
  int i,code;
  char i_str[16],buf[20],*filename,*tclname,*pad(),type[64],*ctmp;

  sprintf (error_msg,"");
  if (argc < 2 || argv[1] == NULL) {
    interp->result = "nst_read_tr0 requires a file name.";
    return TCL_ERROR;
  }

  if ((fp = fopen (argv[1],"r")) == NULL ) {
    sprintf (error_msg,"nst_read_tr0 cannot find file %s.",argv[1]);
    interp->result = error_msg;
    return TCL_ERROR;
  }

  ctmp = strrchr(argv[1],'.');
  if (ctmp != NULL && strcmp(ctmp,".split") == 0) {
    char tmp[1024],*msg;
    
    /* special intel TIM format */

    /* make the filename for the .spo file */
    sprintf(tmp, "nst_spo_from_split %s", argv[1]);

    Tcl_Eval(interp, tmp);
    msg = interp->result;

    /* look for the .spo file with node names/types */
    if ((fp2 = fopen (msg,"r")) == NULL ) {
      fclose (fp);      

      sprintf (error_msg,"nst internal cannot find file %s.",msg);
      interp->result = error_msg;
      return TCL_ERROR;
    }

    data_ptr = read_intel_file(fp,fp2);
    fclose (fp2);
    sprintf(type,"INTEL");

  } else {
    /* not intel */

    fgets(buf, 20, fp);
    rewind(fp);
    if (strstr(buf,"ascii") != NULL || strstr(buf,"ASCII") != NULL) {
      data_ptr = read_ascii_file(fp);
      sprintf(type,"ascii");
    } else {
      bad_blk = 0 ; try_rev = 0;
      data_ptr = read_file(fp);
      if (bad_blk) {
	fprintf(stderr, "Bad block size - retrying with reverse order\n");
	free(data_ptr);
	try_rev = 1;
	rewind(fp);
	bad_blk=0;
	data_ptr = read_file(fp);
	sprintf(type,"%s binary reverse_endian", data_ptr->version);
      } else {
	sprintf(type,"%s binary", data_ptr->version);
      }
    }
  }

  fclose (fp);

  if (strcmp(error_msg,"") != 0) {
    interp->result = error_msg;
    return TCL_ERROR;
  }

  printf("Read %s file %s:  %d variables, %d data points per variable\n",
	 type,argv[1],data_ptr->var_count,data_ptr->points);

  /* strip off directory name if there is one */
  if (rindex(argv[1],'/') == NULL) {
    filename = argv[1];
  } else {
    filename = (char *)(rindex(argv[1],'/') + 1);
  }

  /* Need to store a pointer to this data structure and it has to be a
     string.  Aghhhh! */
  sprintf(i_str,"%d",data_ptr);
  nst_add_tcl_info (interp,filename,"ptr",i_str,"","");

  nst_add_tcl_info (interp,filename,"title",data_ptr->qtitle,"{","}");
  nst_add_tcl_info (interp,filename,"date",data_ptr->cdate,"{","}");
  nst_add_tcl_info (interp,filename,"time",data_ptr->ctime,"{","}");

  sprintf(i_str,"%d",data_ptr->var_count - 1);
  nst_add_tcl_info (interp,filename,"nodes",i_str,"","");
  sprintf(i_str,"%d",data_ptr->points - 1);
  nst_add_tcl_info (interp,filename,"steps",i_str,"","");

  for (i = 0; i < data_ptr->var_count; i++ ) {
    sprintf(i_str,"%d",i);

    /* must pad [ and ] with a \ */
    tclname = pad(data_ptr->cnam[i],"[]",'\\');

    /* save away the default x axis */
    if (i == 0) {
	nst_add_tcl_info (interp,filename,"xdefault",tclname,"{","}");
    }

    code = Tcl_VarEval(interp,"set nst_nodes_",argv[2],"(",
		       tclname,") ",i_str, (char *) NULL);
    if (code == TCL_ERROR) {
      printf ("TCL_ERROR: %s%s%s%s%s\n",
	      "set nst_nodes_",argv[2],"(",tclname,") ",i_str);
    }
    sprintf(i_str,"%d",data_ptr->ityp[i]);
    code = Tcl_VarEval(interp,"set nst_node_types_",argv[2],"(",
		       tclname,") ",i_str, (char *) NULL);
    if (code == TCL_ERROR) {
      printf ("TCL_ERROR: %s%s%s%s%s\n",
	      "set nst_node_types_",argv[2],"(",tclname,") ",i_str);
    }
  }

  if (strcmp(error_msg,"") != 0) {
    interp->result = error_msg;
    return TCL_ERROR;
  } else {
    sprintf (error_msg,"File %s loaded into nst.\n",filename);
    interp->result = error_msg;
    return TCL_OK;
  }
}


/* inserts a pad character before every character in s1 that is in s2 */

char pad_string[64];

char *
pad(s1,s2,padchar)
char *s1,*s2,padchar;
{
  int i,j;

  for (i=j=0 ; i < strlen(s1) ; i++,j++) {
    if (index(s2,s1[i]) != NULL) {
      pad_string[j++] = padchar;
    }
    pad_string[j] = s1[i];
  }
  pad_string[j] = '\0';

  return pad_string;
}


/* nst_add_tcl builds up the nst_datasets array for use in tcl */

nst_add_tcl_info(interp,filename,ident,data,sep1,sep2)
Tcl_Interp *interp;
char *filename,*ident,*data,*sep1, *sep2;
{
  int code;

  code = Tcl_VarEval(interp,"set nst_datasets(",filename,",",ident,") ",
		     sep1,data,sep2,(char *) NULL);
  if (code == TCL_ERROR) {
    printf ("TCL_ERROR: %s%s%s%s%s%s%s%s\n",
	    "set nst_datasets(",filename,",",ident,") ",sep1,data,sep2);
  }
}


/* nst_get_node transfers the data for the given node into the graph format.
   arguments are:  string ptr to dataset, node name, node id
*/

nst_get_node(clientData,interp,argc,argv)
ClientData clientData;
Tcl_Interp *interp;
int argc;
char *argv[];
{
  struct data_struct *data_ptr;
  float *samples;
  int j, node_id;
  char *node_name;
  Blt_Vector *x;
  double *values;

  /* munge that string back to a pointer */
  data_ptr = (struct data_struct *) atoi(argv[1]);

  node_id = atoi(argv[3]);
  node_name = argv[2];

  /* Allocate space for the new vectors */
  values = (double *)malloc(sizeof(double) * data_ptr->points);

  for (j=0; j < data_ptr->points; j++) {
    samples = data_ptr->sample_vector[j];

    /* Write the data points into the vectors */
    values[j] = samples[node_id];
  }

  /*  printf ("plotting node=%s points=%d\n",argv[2],data_ptr->points); */

  /* Update the BLT vector */
  if (Blt_VectorExists(interp, node_name))  {
    if (Blt_GetVector(interp, node_name, &x) != TCL_OK) {
      return TCL_ERROR;
    }
  } else {
    if (Blt_CreateVector(interp, node_name, 0, &x) != TCL_OK) {
      return TCL_ERROR;
    }
  }

  if ((Blt_ResetVector(x, values, data_ptr->points, data_ptr->points,
		       TCL_DYNAMIC) != TCL_OK)) {
    return TCL_ERROR;
  } else {
    /* success */
    return TCL_OK;
  }
}


/* nst_free_struct frees a given data structure once it is no longer required */

nst_free_struct(clientData,interp,argc,argv)
ClientData clientData;
Tcl_Interp *interp;
int argc;
char *argv[];
{
  struct data_struct *data_ptr;

  /* munge that string back to a pointer */
  data_ptr = (struct data_struct *) atoi(argv[1]);
  free(data_ptr);

  return TCL_OK;
}

size_t fread_rev(ptr, size, nitems, stream)
char *ptr;
size_t size, nitems;
FILE *stream;
{
	char *tmp_buf;
	size_t ret;
	register int i;

	if ( try_rev == 0 )
		return fread(ptr, size, nitems, stream) ;
	else {
		tmp_buf = (char *) malloc(size*nitems);
		ret = fread(tmp_buf, size, nitems, stream) ;
		for ( i = 0 ; i < ret*size ; i = i+4 ) {
			ptr[i+0] = tmp_buf[i+3];
			ptr[i+1] = tmp_buf[i+2];
			ptr[i+2] = tmp_buf[i+1];
			ptr[i+3] = tmp_buf[i+0];
		}
		free(tmp_buf);
		return ret;
	}

}


/* read_file does all of the grossness required to read the binary spice
   output file.  Returns a pointer to the data structure for the data points
   and other goob.
*/

struct data_struct *
read_file(infile)
    FILE *infile;
{
  struct data_struct *d1;
  int junk1,junk2, junk3, junk4, junk5;
  char buf[128];
  char temp[9];
  int i, j, k, kstart, done, message, mode;
  char *paren, *tmp;
  float floatval;
  double real;
  int newsweep = 1;
  int blocksize;
  float *samples;
  int records;
  int morebytes;
  char *current;

  d1 = (struct data_struct *)malloc(sizeof(struct data_struct));

  /* read the preamble */

  fread_rev(&junk1, sizeof(int), 1, infile);
  fread_rev(&junk2, sizeof(int), 1, infile);
  fread_rev(&junk3, sizeof(int), 1, infile);
  fread_rev(&blocksize, sizeof(int), 1, infile);

  /* printf("%d %d %d, blocksize is %d\n", junk1, junk2, junk3, blocksize); */

/* Updated for > 9999 nodes. This is a huge assumption that the extra 4 characters
   are all for nodes. */
  fread(&temp[4], 1, 4, infile);

  fread(buf, 1, 4, infile);
  buf[4] = '\0';
  d1->numnoi = atoi(buf);

  fread(buf, 1, 4, infile);
  buf[4] = '\0';
  d1->cndcnt = atoi(buf);

  fread(temp, 1, 4, infile);
  temp[8] = '\0';
  d1->nodknt = atoi(temp);
  d1->var_count = d1->nodknt + d1->numnoi;

  fread(d1->version, 1, 4, infile);
  d1->version[4] = '\0';

  if (strcmp(d1->version,"9007") == 0 || strcmp(d1->version,"9601") == 0) {}
  else {
    sprintf (error_msg,
	     "Load aborted, version %s of binary format.  NST only reads version 9007 or 9601.\n",
	     d1->version);
    return d1;
  }

  fread(d1->qtitle, 1, 76, infile);
  d1->qtitle[76] = '\0';

  fread(d1->cdate, 1, 8, infile);
  d1->cdate[8] = '\0';

  fread(d1->ctime, 1, 8, infile);
  d1->ctime[8] = '\0';

  /* metasoft copyright notice */
  fread(buf, 1, 72, infile);

  /* sweep count */
  fread_rev(buf, 1, 4, infile);
  d1->sweepcnt = atoi(buf);
  /* printf("cndcnt = %d, sweepcnt = %d\n", d1->cndcnt, d1->sweepcnt); */

  /* montic: reserved for future use in monti carlo simulations */
  fread_rev(buf, 1, 76, infile);

  blocksize -= 264;

  /* must allocate twice the size for ac sweeps
     to allow for long names in 9601 char pointer pointers are
     allocated. Storage for names is allocated on the fly in 16
     character increments. */

  d1->cnam = (char **) malloc(d1->var_count * sizeof(char *) * 2);
  d1->ityp = (int *) malloc(d1->var_count * sizeof(int) * 2);

  /* printf("%d variables, blocksize = %d\n",d1->var_count,blocksize); */

  /* read in the variable types */
  for (i = 0; i < d1->var_count ; i++ ) {
    fread(buf, 1, 8, infile);
    buf[8] = '\0';
    blocksize -= 8;
    d1->ityp[i] = atoi(buf);
    /* the mode is determined by the first type of variable */
    if (i == 0) {
	mode = d1->ityp[i];
    }
    /* in ac mode, both the real and imaginary part are stored.
       These will later be converted into magnitude and phase */
    if (mode == HERTZ) {
	if (d1->ityp[i] == VOLTAGE) {
	    d1->ityp[i] = VM;
	    i = i + 1;
	    d1->ityp[i] = VP;
	    d1->var_count++;
	}
	if (d1->ityp[i] == CURRENT) {
	    d1->ityp[i] = IM;
	    i = i + 1;
	    d1->ityp[i] = IP;
	    d1->var_count++;
	}
    }

    if (blocksize == 0) {
      fread_rev(&junk1, sizeof(int), 1, infile);
      fread_rev(&junk2, sizeof(int), 1, infile);
      fread_rev(&junk3, sizeof(int), 1, infile);
      fread_rev(&junk4, sizeof(int), 1, infile);
      fread_rev(&blocksize, sizeof(int), 1, infile);
    }
  }

  if (blocksize < 0) {
    bad_blk = 1;
    if (try_rev) sprintf (error_msg,"Load aborted, bad block size.");
    return d1;
  }

  /* read in the variable names (16 chars) */
  /* in 9007 16 characters per name, in 9601 multiple
     16 character records - hence we malloc on the fly */

  for (i = 0; i < d1->var_count; i++ ) {
    records = 1;
    morebytes = 1;
    while(morebytes == 1) {
      /* get next 16 characters */
      if (blocksize < 16) {
        if (blocksize > 0) {
          /* special case -- name is split across a block boundary */
          fread(buf, 1, blocksize, infile);
	  if (buf[0] == ' ') {
	    /* blank */
	    blocksize = 0;
	    /* printf("setting blocksize to 0\n"); */
	  }
	}

        fread_rev(&junk1, sizeof(int), 1, infile);
        fread_rev(&junk2, sizeof(int), 1, infile);
        fread_rev(&junk3, sizeof(int), 1, infile);
        fread_rev(&junk4, sizeof(int), 1, infile);
        fread_rev(&junk5, sizeof(int), 1, infile);
/* printf("%d %d %d %d %d\n",junk1, junk2, junk3, junk4, junk5); */
        fread(buf + blocksize, 1, 16 - blocksize, infile);
        junk5 -= (16 - blocksize);
        blocksize = junk5;
      }
      else {
        fread(buf, 1, 16, infile);
        blocksize -= 16;

	if (buf[0] == ' ' && records == 1) {
	  /* weird case where there isn't enough room in this block
	     for the next name, which is longer than 16 chars. */
	  continue;
	}
      }

      if (records != 1) {
        current = d1->cnam[i];
        d1->cnam[i] = (char *) malloc(sizeof(char) * (records * 16 + 1));
        memcpy(d1->cnam[i], current, 16 * (records - 1) * sizeof(char));
        free(current);
      }
      else {
        d1->cnam[i] = (char *) malloc(sizeof(char) * 17);
      }
      memcpy(d1->cnam[i] + 16 * (records - 1), buf, 16 * sizeof(char));
  
      d1->cnam[i][records * 16] = ' ';
      tmp = strchr(d1->cnam[i],' ');
  
      if (tmp != NULL) {
        *tmp = '\0';
      }

      if(strlen(d1->cnam[i]) < (16 * records) || strcmp(d1->version, "9007") == 0) {
        morebytes = 0;
      }
      else {
        morebytes = 1;
        records++;
      }

    }

    if (strcmp(d1->cnam[i],"time") == 0) {
      /* special case -- must be uppercase */
      strcpy(d1->cnam[i],"TIME");
    }

    /* printf("%d / %d --> %s\n",i,d1->var_count,d1->cnam[i]); */

    /* fix up for ac mode */
    if (mode == HERTZ) {
      if (d1->ityp[i] == VM || d1->ityp[i] == IM) {
        i = i + 1;
        d1->cnam[i] = (char *) malloc(sizeof(char) * (records * 16 + 1));
        sprintf(d1->cnam[i],"%s,p",d1->cnam[i-1]);
      }
    }
/* printf("%d (blocksize %d) -> %s\n", i, blocksize, d1->cnam[i]); */

  }

  /* TODODO fix xxxxx */
  if ( d1->cndcnt == 1 ) {
    /* special case of inlined data statement. */
    kstart = 0;
  } else {
    kstart = 1;
  }

  for (i = 0; i < d1->cndcnt; i++) {

    if (blocksize == 0) {
      fread_rev(&junk1, sizeof(int), 1, infile);
      fread_rev(&junk2, sizeof(int), 1, infile);
      fread_rev(&junk3, sizeof(int), 1, infile);
      fread_rev(&junk4, sizeof(int), 1, infile);
      fread_rev(&blocksize, sizeof(int), 1, infile);
    }

    fread(buf, 1, 16, infile);
    buf[16] = '\0';
    blocksize -= 16;
    /* printf("%d cndcnt is %s\n", i, buf); */

    if (strncmp(buf,"MONTE_CARLO",11) == 0) {
      /* special case -- like multiple sweeps */
      kstart = 0;
    }
  }

  fread(buf, 1, 8, infile);
  buf[8] = '\0';
  blocksize -= 8;
  /* printf("blocksize is %d & the terminator node is %s\n",blocksize,buf); */
  if (blocksize != 0) {
    bad_blk = 1;
    if (try_rev) sprintf (error_msg,"Load aborted, bad block size.");
    return d1;
  }

  fread_rev(&junk1, sizeof(int), 1, infile);
  fread_rev(&junk2, sizeof(int), 1, infile);
  fread_rev(&junk3, sizeof(int), 1, infile);
  fread_rev(&junk4, sizeof(int), 1, infile);
  fread_rev(&blocksize, sizeof(int), 1, infile);

  /* printf("%d %d %d %d %d\n",junk1, junk2, junk3, junk4, blocksize); */

  d1->points = 0;
  /* initial size - it grows if this isn't big enough */
  d1->sample_vector_size = 1000;
  d1->sample_vector = (float **) malloc(d1->sample_vector_size * sizeof(float));
  while (blocksize != 0) {
    if (newsweep) {
      newsweep = 0;
      for (k = kstart; k < d1->cndcnt; k++) {
	fread_rev(&floatval, sizeof(float), 1, infile);
	/* printf("value is %e\n", floatval); */
	blocksize -= 4;
      }
    }

    samples = (float *) malloc(d1->var_count * sizeof(float));
    if (d1->points >= d1->sample_vector_size) {
      float **old_sample_vector;

      /* grow the sample vector */
      old_sample_vector = d1->sample_vector;
      d1->sample_vector_size *= 2;
      d1->sample_vector = (float **) malloc(d1->sample_vector_size* sizeof(float));
      memcpy(d1->sample_vector, old_sample_vector, d1->points * sizeof(float *));
      free(old_sample_vector);
    }

    d1->sample_vector[d1->points++] = samples;
/* printf ("variable count = %d, data pts = %d\n",d1->var_count,d1->points); */

    /* read in a set of data points */
    for (i = 0; i < d1->var_count && blocksize != 0; i++ ) {
      fread_rev(&samples[i], sizeof(float), 1, infile);

      /* printf("data(%d,%d) %s = %e\n",i, d1->points - 1,d1->cnam[i],samples[i]); */

      blocksize -= 4;
      if (blocksize == 0) {
	fread_rev(&junk1, sizeof(int), 1, infile);
	fread_rev(&junk2, sizeof(int), 1, infile);
	fread_rev(&junk3, sizeof(int), 1, infile);
	fread_rev(&junk4, sizeof(int), 1, infile);
	fread_rev(&blocksize, sizeof(int), 1, infile);
	/* printf("%d --> %d %d %d %d, blocksize is %d\n", samples[i], junk1, junk2, junk3, junk4, blocksize); */
	if ( samples[i] >= 0.1e+31 ) {
	  i--;
	  if (blocksize != 0) {
	    for (k = kstart; k < d1->cndcnt; k++) {
	      fread_rev(&floatval, sizeof(float), 1, infile);
	      blocksize -= 4;
	      /* printf("next value is %e\n", floatval); */
	    }
	  }
	  else {
	    d1->points--;
	  }
	}
      }

      /* fix up for ac mode */
      if (mode == HERTZ) {
	  if (d1->ityp[i] == VP || d1->ityp[i] == IP) {
	      /* convert from real/imaginary to magnitude/phase */
	      real = samples[i-1];
	      /* compute magnitude */
	      samples[i-1] = sqrt(real*real + samples[i]*samples[i]);
	      /* compute phase and convert to degrees */
	      if (samples[i-1] != 0.0) {
		  samples[i] = atan2((double)samples[i],real) * RAD_TO_DEG;
	      }
	  }
      }
    }
  }

  if (blocksize != 0) {
    sprintf (error_msg,"Load incomplete.");
    return d1;
  }

  /* if the spice job is still running, the tr0 file will have lots of
     zeros at the end which we want to remove. */

  /* only look at first 10 variables (or all of them if there are less than 10) */
  i = MIN(10,d1->var_count);

  for (done = 0, message = 0; done == 0 ;) {
    samples = d1->sample_vector[d1->points - 1];

    for (j = 0; j < i ; j++ ) {
      if (samples[j] != 0) {
	done = 1;
	break;
      }
    }

    if (done == 0 && message == 0) {
      printf ("Cleaning partial tr0 file...\n");
      message = 1;
    }

    if (done == 0) {
      d1->points--;
    }

    if (d1->points < 1) {
      done = 1;
    }
  }

  //  samples = d1->sample_vector[d1->points - 1];
  //  printf("%d --> %g\n",d1->points,samples[0]);

  return d1;
}


/* Reads in an ascii file with the first line being the data names, and
   the subsequent lines the data   */

struct data_struct *
read_ascii_file(infile)
    FILE *infile;
{
  struct data_struct *d1;
  char buf[1024],buf2[1024],*token;
  int i, j, k;
  float *samples;

  d1 = (struct data_struct *)malloc(sizeof(struct data_struct));

  /* the first line is the title */
  fgets(buf,1024,infile);
  strncpy(d1->qtitle,buf,76);
  d1->qtitle[76] = '\0';

  fgets(buf,1024,infile);
  strcpy(buf2,buf);

  /* first count up the number of names */
  strtok(buf2," \t\n");
  for (i=1; strtok(NULL," \t\n") != NULL; i++);
  d1->var_count = i;

  /* allocate memory.  Must allocate twice the size for ac sweeps */
  d1->cnam = (char **) malloc(d1->var_count * sizeof(char *) * 2);
  d1->ityp = (int *) malloc(d1->var_count * sizeof(int) * 2);

  /* now read in the names and assign a bogus type */
  d1->cnam[0] = (char *) malloc(sizeof(char) * 2 * 17);
  strcpy(d1->cnam[0],strtok(buf," \t\n"));
  d1->ityp[0] = HERTZ;
  for (i=1; i<d1->var_count; i++) {
      d1->cnam[i] = (char *) malloc(sizeof(char) * 2 * 17);
      strcpy(d1->cnam[i],strtok(NULL," \t\n"));
      d1->ityp[i] = VOLTAGE;
  }

  /* make up something for these */
  d1->cndcnt = 1;
  d1->version[0] = '\0';
  d1->cdate[0] = '\0';
  d1->ctime[0] = '\0';

  d1->points = 0;
  /* initial size - it grows if this isn't big enough */
  d1->sample_vector_size = 1000;
  d1->sample_vector =
      (float **) malloc(d1->sample_vector_size * sizeof(float));

  /* read in a set of data points */
  while (fgets(buf,1024,infile) != NULL) {

      /* ignore lines with white space */
      if (sscanf(buf,"%s",buf2) == EOF) {
	  continue;
      }

      samples = (float *) malloc(d1->var_count * sizeof(float));
      if (d1->points >= d1->sample_vector_size) {
	  float **old_sample_vector;

	  /* grow the sample vector */
	  old_sample_vector = d1->sample_vector;
	  d1->sample_vector_size *= 2;
	  d1->sample_vector =
	      (float **) malloc(d1->sample_vector_size* sizeof(float));
	  memcpy(d1->sample_vector, old_sample_vector,
		 d1->points * sizeof(float *));
	  free(old_sample_vector);
      }

      d1->sample_vector[d1->points++] = samples;

      sscanf(strtok(buf," \t\n"),"%f",&samples[0]);
      for (i=1; i<d1->var_count; i++) {
	  if ((token = strtok(NULL," \t\n")) == NULL) {
	      /* read from the next line */
	      if (fgets(buf,1024,infile) != NULL) {
		  token = strtok(buf," \t\n");
	      } else {
		  printf("Warning, incomplete ascii file.\n");
		  /* just set the rest of the values to previous value */
		  for (; i<d1->var_count; i++) {
		      samples[i] = d1->sample_vector[d1->points - 2][i];
		  }
		  return d1;
	      }
	  }
	  sscanf(token,"%f",&samples[i]);
      }
  }

  return d1;
}


/* Reads in an Intel TIM format file */

struct data_struct *
read_intel_file(infile,namefile)
    FILE *infile, *namefile;
{
  struct data_struct *d1;
  struct tmp_struct *tmp_struct, *tmp_struct_start;
  char buf[1024],*buf2,*token;
  int i;
  float *samples, *junk;

  d1 = (struct data_struct *)malloc(sizeof(struct data_struct));

  /* bogus for now */
  strncpy(d1->qtitle,"",76);
  d1->qtitle[76] = '\0';

  d1->var_count = 0;

  /* get the node names */
  i = 0;
  while (fgets(buf,1024,namefile) != NULL) {
    if (strstr(buf,"OUTPUTORDER {") != NULL) {
      /* found the start of the nodes */
      i = 1;
      break;
    }
  }

  if (i == 0) {
    /* no OUTPUTORDER line, assume every line it except first 4 */
    /* doesn't work */
    rewind(namefile);

    fgets(buf,1024,namefile);
    fgets(buf,1024,namefile);
    fgets(buf,1024,namefile);
    fgets(buf,1024,namefile);
  }

  while (fgets(buf,1024,namefile) != NULL) {
    if (buf[0] == '}') {
      /* end of stuff */
      break;
    }

    if (buf[0] == '\n' || buf[0] == ' ' || buf[0] == '\r') {
      /* empty line */
      continue;
    }

    /*    printf("%d --> %s",buf[0],buf); */

    if (d1->var_count == 0) {
      /* first time */
      tmp_struct_start = (struct tmp_struct *)malloc(sizeof(struct tmp_struct));
      tmp_struct = tmp_struct_start;

    } else {
      tmp_struct->next = (struct tmp_struct *)malloc(sizeof(struct tmp_struct));
      tmp_struct = tmp_struct->next;
    }

    /* type is I or V */
    strtok(buf," \t\r");
    tmp_struct->type = buf[0];

    /* put this into link list of structure */
    buf2 = strtok(NULL," \t\n\r");

    tmp_struct->name = (char *) malloc(strlen(buf2) + 1);
    strcpy(tmp_struct->name, buf2);

    d1->var_count += 1;
  }

  tmp_struct->next = NULL;

  /* printf ("num vars = %d\n",d1->var_count); */

  /* allocate memory.  Must allocate twice the size for ac sweeps */
  d1->cnam = (char **) malloc(d1->var_count * sizeof(char *) * 2);
  d1->ityp = (int *) malloc(d1->var_count * sizeof(int) * 2);

  /* time is special */
  d1->cnam[0] = "TIME";
  d1->ityp[0] = HERTZ;

  /* now add in the names and assign types */
  tmp_struct = tmp_struct_start;
  for (i=1 ; tmp_struct != NULL ; i++) {
    d1->cnam[i] = tmp_struct->name;
    /*    printf("%d name = %s\n",i,tmp_struct->name); */

    if (tmp_struct->type == 'I') {
      d1->ityp[i] = CURRENT;
    } else {
      d1->ityp[i] = VOLTAGE;
    }

    tmp_struct_start = tmp_struct;
    tmp_struct = tmp_struct->next;
    free(tmp_struct_start);
  }

  /* make up something for these */
  d1->cndcnt = 1;
  d1->version[0] = '\0';
  d1->cdate[0] = '\0';
  d1->ctime[0] = '\0';

  d1->points = 0;
  /* initial size - it grows if this isn't big enough */
  d1->sample_vector_size = 1000;
  d1->sample_vector = (float **) malloc(d1->sample_vector_size * sizeof(float));

  /* read data points */
  while (feof(infile) == 0) {

    /* printf("point -> %d\n",d1->points); */

    /* 4-byte header */
    fread(&junk, 4, 1, infile);

    if (feof(infile)) {
      break;
    }

    samples = (float *) malloc((d1->var_count + 1) * sizeof(float));
    if (d1->points >= d1->sample_vector_size) {
      float **old_sample_vector;

      /* grow the sample vector */
      old_sample_vector = d1->sample_vector;
      d1->sample_vector_size *= 2;
      d1->sample_vector =
	(float **) malloc(d1->sample_vector_size* sizeof(float));
      memcpy(d1->sample_vector, old_sample_vector,
	     d1->points * sizeof(float *));
      free(old_sample_vector);

      /* printf("auto grow %d\n",d1->sample_vector_size); */
    }

    d1->sample_vector[d1->points++] = samples;

    /* data except for time */
    fread(&samples[1], 4, d1->var_count, infile);

    /* time */
    fread(&samples[0], 4, 1, infile);

    /* 4-byte trailer */
    fread(&junk, 4, 1, infile);
  }

  /* for time -- handled differently */
  d1->var_count += 1;

  return d1;
}
