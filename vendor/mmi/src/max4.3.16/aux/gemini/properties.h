/*
$Id: properties.h,v 2.5 1993/04/24 03:51:09 mckenzie Exp $
*/
/************************************************************************/
/*	COPYRIGHT (C) 1988  Carl Ebeling
/* Define the properties for devices and nets.  This is all technology
 * dependent stuff.
/************************************************************************/

/* SIM file transistor properties */

typedef struct Property {
  int width, length;		/* Transistor size */
  int xLoc, yLoc;		/* Transistor location */
  struct Property *next;
  struct Net *gatenet;		/* associated transistor gate */
} Property;

typedef struct NetProp {
  long capacitance;		/* capacitance in 10^-18 farad steps */
} NetProp;
