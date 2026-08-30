/*
 * units.h --
 *
 * This file defines the interface provided to the units.c,
 * which gives the user a choice of dimensional units used in commands.
 *
 * rcsid $$
 */

#define _UNITS

/*
 * Interface procedures.
 */

extern Void UnitsCommand(); 
extern int UnitsValidS();
extern char *UnitsI2S();
extern int UnitsS2I();
