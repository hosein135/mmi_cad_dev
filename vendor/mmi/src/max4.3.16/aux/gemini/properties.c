/*
$Id: properties.c,v 2.7 1993/12/17 04:49:32 mckenzie Exp mckenzie $
*/
/*******************************************************************/
/*	COPYRIGHT (C) 1988  Carl Ebeling
/* This file contains technology dependent routines for handling properties
 * which is the only item that is technology dependent
/*******************************************************************/

#include "gemini.h"

/************************************************************************/
/* Allocate a property  (Clean up later??)
/************************************************************************/
Property *AllocProperty()
{
  Property *property;
  
  property = (Property *) FastAlloc(sizeof(Property));
  property->length = property->width = property->xLoc = property->yLoc = 0;
  property->next = NULL;
  return property;
}

/*******************************************************************/
/* Write a marker into the Magic file (filePT) at the location of the original 
 * device.  In the current sim format, only devices have properties and
 * therefore a Magic file location.
/*******************************************************************/

void MagicOutNode(node, error)
register Node *node;
char *error;			/* Used to distinguish errors */
{
  register Property *property;
  int i, j;
  char buffer[100];
  
    switch (node->nodeType) {
    case DEVICE:
      MagicDevices++;
      for (property = node->p.property;
	   property != NULL;
	   property = property->next) {
	fprintf(MagicFilePtr, "<< error_s >>\nrect %d %d %d %d\n",
		property->xLoc/MagicLambda,
		property->yLoc/MagicLambda,
		property->xLoc/MagicLambda + 3,
		property->yLoc/MagicLambda + 3);
	fprintf(MagicFilePtr,"<< labels >>\nrlabel space %d %d %d %d 8 D:%s\n",
		property->xLoc/MagicLambda,
		property->yLoc/MagicLambda,
		property->xLoc/MagicLambda,
		property->yLoc/MagicLambda, error);
      }
      break;

    case NET:
/* This is complicated because of combined devices */
/* Print the one transistor to which the net is connected in the case of
   combined devices */
      if (node->n.netConnects <= NetPrintLimit) {
	MagicNets++;
	for (i = 0; i < node->n.netConnects; i++) {
	  if (node == node->connects.devList[i].node->connects.netList[0]) {
	    sprintf(buffer, "2 %s[S]%s", error, node->name);
	    property = node->connects.devList[i].node->p.property;
	  } else if (node == node->connects.devList[i].node->connects.netList[1]) {
	    sprintf(buffer, "2 %s[S]%s", error, node->name);
	    /* Find end of list */
	    for (property = node->connects.devList[i].node->p.property;
		 property->next != NULL;
		 property = property->next) ;
	  } else {
	    sprintf(buffer, "4 %s[G]%s", error, node->name);
	    for (property = node->connects.devList[i].node->p.property, j = 3;
		 property != NULL;
		 property = property->next, j++) {
	      if (node == node->connects.devList[i].node->connects.netList[j]){
		break;
	      }
	    }
	  }
	  if (property == NULL) continue;
	  fprintf(MagicFilePtr, "<< error_s >>\nrect %d %d %d %d\n",
		  property->xLoc/MagicLambda,
		  property->yLoc/MagicLambda,
		  property->xLoc/MagicLambda + 3,
		  property->yLoc/MagicLambda + 3);
	  fprintf(MagicFilePtr,"<< labels >>\nrlabel space %d %d %d %d %s\n",
		  property->xLoc/MagicLambda,
		  property->yLoc/MagicLambda,
		  property->xLoc/MagicLambda,
		  property->yLoc/MagicLambda, buffer);
	}
      }
    }
}

/*******************************************************************/
/* Print the Magic locations of an entire queue of nodes
/*******************************************************************/

void MagicOutQueue(queue)
register 
Queue *queue;
{
  register Node *node;
  int i;

  for (node = queue->top; node != NULL; node = node->next) {
    MagicOutNode(node, "");
  }
}


/*******************************************************************/
/* Run through the transistors in the two graphs and check sizes.
/* Compare two properties: for NMOS/CMOS we will compare the first two numbers
 * (transistor length and width) to within 10%
/*******************************************************************/

void CompareProperties(graph1, graph2)
Graph *graph1, *graph2;
{
  Node *node1, *node2;
  register Property *property1, *property2;
  int count = graph1->uniqueDevices.size;
  int i;
  int error;
  int warnings = 0;
  Property *prop1list[MAXDEVICETYPES];
  Property *prop2list[MAXDEVICETYPES];
  int reverse_order;
  int rev_i;
  
  node1 = graph1->uniqueDevices.top;
  node2 = graph2->uniqueDevices.top;
  while (count--) {
    error = FALSE;

/* detect if transistor chain has gates in reverse order */
    reverse_order =
	(node1->p.property != NULL) && (node2->p.property != NULL) &&
	(node1->connects.netList[0]->nodeValue !=
	 node2->connects.netList[0]->nodeValue);
/*
** NM 4/6/1993
** Ifdef'ed out the following section of code.
** Reason: the property list is not guaranteed to have the same sequence
** as the netList, so the implied correspondence is bogus and leads
** to erroneous error messages.
*/

#if 0
    for (property1 = node1->p.property, property2 = node2->p.property;
      (property1 != NULL) && (property2 != NULL);
      property1 = property1->next, property2 = property2->next)
      {
      printf("%s <--> %s\n",property1->gatenet->name, property2->gatenet->name);
      if ((property1->length == 0) || (property2->length == 0) ||
        (property1->width == 0) || (property2->width == 0) ||
        ((fabs((float) (property1->width - property2->width))/
        (float) property2->width) > SizePercent) ||
        ((fabs((float) (property1->length - property2->length))/
        (float) property2->length) > SizePercent)) {
	error = TRUE;
	if (MagicFilePtr != NULL) {
	  char buffer[20];
	  sprintf(buffer, "[%d/%d]", property2->length, property2->width);
	  MagicOutNode(node1, buffer);
	}
      }
    }
#endif

    for (i = 3; i < DeviceDefs[node1->n.nodeDef].numTerminals; i++) {
      char *en1 = node1->connects.netList[i]->name;
      char *en2;
      if (reverse_order) {
	rev_i = DeviceDefs[node1->n.nodeDef].numTerminals - i + 2;
	en2 = node2->connects.netList[rev_i]->name;
      } else {
	en2 = node2->connects.netList[i]->name;
      }
      for (property1 = node1->p.property; property1 != NULL;
        property1 = property1->next) {
        property1->gatenet = RealNet(property1->gatenet);
	if (casestreq(property1->gatenet->name,en1))
	  goto got1;
      }
      assert(0, "unknown net in first input file\n");
got1:
      for (property2 = node2->p.property; property2 != NULL;
        property2 = property2->next) {
        property2->gatenet = RealNet(property2->gatenet);
	if (casestreq(property2->gatenet->name,en2))
	  goto got2;
      }
      assert(0, "unknown net in second input file\n");
got2:
#ifdef DEBUG
      printf("%s <--> %s\n",property1->gatenet->name, property2->gatenet->name);
#endif
      prop1list[i] = property1;
      prop2list[i] = property2;
      if ((property1->length == 0) || (property2->length == 0) ||
        (property1->width == 0) || (property2->width == 0) ||
        ((fabs((float) (property1->width - property2->width))/
        (float) property2->width) > SizePercent) ||
        ((fabs((float) (property1->length - property2->length))/
        (float) property2->length) > SizePercent)) {
	error = TRUE;
	if (MagicFilePtr != NULL) {
	  char buffer[20];
	  sprintf(buffer, "[%d/%d]", property2->length, property2->width);
	  MagicOutNode(node1, buffer);
	}
      }
    }
    if (error) {
      char *s1, *s2, *s3, *s4;	/* print only the suffix */

      if (warnings++ == 0) {
	printf("The following transistors do not match in size:\n");
      s1 = graph1->graphName;
      s2 = graph2->graphName;
      if (strlen(s1) > 36) s1 += strlen(s1) - 36;
      if (strlen(s2) > 36) s2 += strlen(s2) - 36;
      printf("%39s : %36s\n",s1, s2);
      }
      printf("(%d) Device type %s:\n", warnings,
	DeviceDefs[node1->n.nodeDef].name);
      s1 = node1->connects.netList[0]->name;
      s2 = node1->connects.netList[1]->name;
      s3 = node2->connects.netList[reverse_order]->name;
      s4 = node2->connects.netList[1-reverse_order]->name;
      if (strlen(s1) > 17) s1 += strlen(s1) - 17;
      if (strlen(s2) > 17) s2 += strlen(s2) - 17;
      if (strlen(s3) > 17) s3 += strlen(s3) - 17;
      if (strlen(s4) > 17) s4 += strlen(s4) - 17;
      printf("s,d:%17s %17s : %18s %17s\n",s1, s2, s3, s4);
      for (i = 3; i < DeviceDefs[node1->n.nodeDef].numTerminals; i++) {
        s1 = node1->connects.netList[i]->name;
	if (reverse_order) {
	  rev_i = DeviceDefs[node1->n.nodeDef].numTerminals - i + 2;
          s2 = node2->connects.netList[rev_i]->name;
	} else {
          s2 = node2->connects.netList[i]->name;
	}
        if (strlen(s1) > 17) s1 += strlen(s1) - 17;
        if (strlen(s2) > 17) s2 += strlen(s2) - 17;
	printf("g:%19s  l/w: %5d/%5d :%19s  l/w: %5d/%5d\n",
	  s1, prop1list[i]->length, prop1list[i]->width,
	  s2, prop2list[i]->length, prop2list[i]->width);
      }
    }
    node1 = node1->next;
    node2 = node2->next;
  }
  if (warnings)
    printf("\n");
/*  printf("%d size warnings printed\n", warnings);  */
}

void CompareNetProperties(graph1, graph2)
Graph *graph1, *graph2;
{
  Node *node1, *node2;
  int i;
  int warnings = 0;
  int count = graph1->uniqueNets.size;
  long p1;
  long p2;
  long psum;
  long pdif;
  
  node1 = graph1->uniqueNets.top;
  node2 = graph2->uniqueNets.top;
  while (count--) {
    p1 = node1->p.netprop->capacitance;
    p2 = node2->p.netprop->capacitance;
    psum = p1 + p2;
    pdif = labs(p1 - p2);

    if ((p1 < 0) || (p2 < 0) ||
      ((psum != 0) && ((pdif * 100 / psum) > CapPercent))) {
      if (warnings++ == 0) {
        printf("\nThe following nets do not match in capacitance:\n");
      }
      printf("%d> %s: %g", warnings, node1->name, (float)p1/1000.0);
      printf("\n");
      printf("%d> %s: %g", warnings, node2->name, (float)p2/1000.0);
      printf("\n");
    }
    node1 = node1->next;
    node2 = node2->next;
  }
}

/*******************************************************************/
/* Run through the matching nets in the two graphs and dump to the 
   dictionary file.
   The name dictionaries are in some sense dependent on the input: in the
   case of sim files, we only print net names that match
/*******************************************************************/

void WriteDictionary(graph1, graph2)
Graph *graph1, *graph2;
{
  register Node *node1, *node2;
  register int count = graph1->uniqueNets.size;
  int numDictEntries = 0;

  node1 = graph1->uniqueNets.top;
  node2 = graph2->uniqueNets.top;
  while (count--) {
/* omit 'No Connect' from user dictionary */
    if (strcmp(NO_CONNECT_NAME,node1->name)) {
      fprintf(DictFilePtr, "= %s %s\n", node1->name, node2->name);
      numDictEntries++;
    }
    node1 = node1->next;
    node2 = node2->next;
  }
  printf("%d entries written to the dictionary file.\n", numDictEntries);
  fclose(DictFilePtr);
}
