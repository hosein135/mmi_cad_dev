/*
$Id: simread.h,v 2.7 1993/12/17 04:50:10 mckenzie Exp mckenzie $
*/
/*******************************************************************/
/* This file contains data definitions and declarations used by the
 * procedures that read SIM format files.
/*******************************************************************/

/*******************************************************************/
/*
 *	COPYRIGHT (C) 1983  Carl Ebeling and Ofer Zajicek
 *	COPYRIGHT (C) 1988  Carl Ebeling
 *
/*******************************************************************/

/*******************************************************************/
/* HISTORY
/*******************************************************************/

/*******************************************************************/
/* Devices are a linked list.  Each has an index, a pointer to a 
 * net for each terminal and a next pointer to the next device in the
 * list.  The devices are in index order.
/*******************************************************************/

#define NUMBERTYPES	2
#define NTYPE		1
#define PTYPE		0

#define NO_CONNECT_NAME "No connect"

typedef struct Device {
  int index;
  int type;	/*   NTYPE, PTYPE	*/
  Property *property;
  struct Device *next;
  struct Net *connections[4];
} Device;

/*******************************************************************/
/* Connections to a device must give the device and terminal number 
/*******************************************************************/

typedef struct SIMdevConnect {
  int dev;			/* Index of device to which net is connected */
  short unsigned int terminal;  /* Terminal index of device for connection */
  short unsigned int class;	/* Class of terminal */
  struct SIMdevConnect *next;	/* Next connection in list */
} SIMdevConnect;

/*******************************************************************/
/* The structure for net contains the information on each net.  Nets are kept
 * in the hash table.
/*******************************************************************/

typedef struct Net
  {
    char *name;
    int index;			/* Index (0 based) assigned to net */
    int numConnects;		/* Number of connections: -1 ==> equated net */
    union
      { SIMdevConnect *list;	/* List of net connections */
        struct Net *equalNet;	/* Net that is equal to this one */
      } connections;
    struct Net *next;		/* Link nets in one hash bucket */
    struct Net *nextInOrder;	/* For list of all nets in index order */
    NetProp *np;		/* Property list of this net */
  } Net;


/*******************************************************************/
/*  return the index of the net or the index of the alias
 *  if the index is -1.
/*******************************************************************/

#define IndexOfNet(net)						\
	( ( (net)->index == -1) ? RealNet(net)->index		\
	  : (net)->index)

#define simhash(name, value) \
{ register char *p = name; \
  value = 0; \
  if (CaseFold) while (*p) value = (value << 1) + pCharTran[*p++]; \
  else while (*p) value = (value + 337351) * *p++; \
  value = (((unsigned int) value) % hashSize);  \
  }

#define nextarg() while (spaces[*line]) line++; arg = line; \
while (*line && (spaces[*line] == 0)) line++; *line++ = '\0'; 
#define argerror() if (*arg == '\0') { \
fprintf(stderr, "File format error: line %d\n", lineNumber); \
break;  }
