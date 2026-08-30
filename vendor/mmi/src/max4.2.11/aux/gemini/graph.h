/*
$Id: graph.h,v 2.7 1993/12/17 04:50:10 mckenzie Exp mckenzie $
*/
/*******************************************************************/
/* Structure declarations for the graphs used by GEMINI
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

#define DEVICE 0		/* Node of type device */
#define NET 1			/* Node of type net */

#define MAXDEVICETYPES 100	/* Maximum number of device types */
#define MAXCOMPOSITETYPES 100	/* Maximum size of composite type */

#define NO_CONNECTION 0		/* CMOS specific stuff */
#define DRAIN 5			/* CMOS specific stuff */
#define GATE 3			/* CMOS specific stuff */
#define SUBSTRATE 7		/* CMOS specific stuff */

/* SIM file formats */
#define GEM 'G'
#define MIT 'M'
#define UCB 'B'
#define LBL 'L'

/*******************************************************************/
/* Node flags
/*******************************************************************/

#define PENDING 0
#define UNIQUE 	0x01
#define SUSPECT	0x02
#define BAD	0x04
#define MATCHING 0x08		/* Will be matched next time around */
#define DELETED 0x10		/* Deleted by chain compression */
#define ALLFLAGS (UNIQUE|SUSPECT|BAD)

#define suspectNode(node) 	(((node)->flag)==SUSPECT)
#define uniqueNode(node)	(((node)->flag)==UNIQUE)
#define badNode(node)		(((node)->flag)==BAD)
#define pendingNode(node)	(((node)->flag)==PENDING)

#define setSuspectNode(node)	\
   Errors++;			\
   node->flag = SUSPECT;	\
   node->nodeValue = 0;

#define setBadNode(node)	\
   Errors++;			\
   node->flag = BAD;		\
   node->nodeValue = 0;

/*******************************************************************/
/* Terminal classes are small integers starting at 0
/*******************************************************************/

/*typedef unsigned char termClass;	/* old way */
typedef unsigned short termClass;	/* NM 7-11-92 */

/*******************************************************************/
/* A device definition defines the number and type of connections of the
 * device.  The device ID is simply the index of the definition in the
 * array of device definitions: DeviceDefs
/*******************************************************************/

typedef struct DeviceDefinition {
  char *name;			/* Name of device type */
  int numTerminals;		/* Number of terminals on device */
  termClass *terminals;		/* Vector of terminal classes */
} DeviceDefinition;

/*******************************************************************/
/* Connections to a device must give the device and terminal number 
/*******************************************************************/

typedef struct {
  struct Node *node;		/* Device to which net is connected */
  unsigned short int terminal;  /* Terminal index of device for connection */
  unsigned short int class;	/* Class of terminal of device connection */
} DeviceConnection;

/*******************************************************************/
/* Each device/net in the network is represented by a Node
/*******************************************************************/

typedef struct Node
  {
   union {
     struct Property *property;	/* From properties.h : technology independent */
     struct NetProp *netprop;
     } p;
   char *name;			/* Name of node */
   unsigned int nodeValue;	/* Hashed value for node */
   union {
      int nodeDef;		/* Device: device definition index */
      int netConnects;		/* Net: number of connections */
     } n;
   union { /* ConnectUnion */
      struct Node **netList;	/* Device: array of net connections */
      DeviceConnection *devList;/* Net: array of device connections */
     } connects ;
   
   struct Node *next;		/* Link used to keep nodes in queues and lists,
   				 * eg. the hash table */
   short int pass;		/* For unique nodes: the pass in which they
   				 * became unique. For non-unique nodes:
				 * the pass in which they were put in the
				 * queue.  This is used to determine if the
				 * node is in the queue already in order not to
				 * queue it twice.
				 */
   char nodeType;		/* Device or Net */
   char flag;			/* Flags node category: Unique, suspect, etc.*/
   int partitionSize;		/* So we know how many in partition */
   int SimIndex;		/* cross-ref to SIM file structure */
  } Node, *NodePt;

/*******************************************************************/
/*	Returns the number of links the node has.
/*******************************************************************/

#define NumberOfLinksN(net) ((net)->n.netConnects)
#define NumberOfLinksD(dev) (DeviceDefs[(dev)->n.nodeDef].numTerminals)
#define NumberOfLinks(aNode)	\
(((aNode)->nodeType == DEVICE) ? NumberOfLinksD(aNode) : NumberOfLinksN(aNode))

#define TerminalList(dev) (DeviceDefs[(dev)->n.nodeDef].terminals)

/*******************************************************************/
/* Each bucket in the hash table contains two disjoint lists of node entries
/*******************************************************************/

typedef struct Bucket
  {
    int bucketSum;		/* Check sum by bucket */
    int minPartSize;		/* Smallest of non-singleton partitions */
    Queue notUnique;		/* List of non-unique entries */
    Queue Unique;		/* Queue of unique entries */
    Queue overflow;		/* Queue of 'extra' nonUnique entries */
  } Bucket;

/*******************************************************************/
/* The Graph structure contains all the information for one graph.  Gemini
   operates on one of these structures
/*******************************************************************/

typedef struct Graph
  {
    char graphNumber;		/* First or second graph on command line */
    char SimFormat;		/* MIT or UCB format */
    char *graphName;		/* File name */
    double SimUnits;		/* Number of .01 microns per sim unit */
    Bucket *hashTable;		/* graph has private hash table */
    int checkSum;		/* check sum of bucket check sums */
    Queue newUniques;		/* Nodes that became unique in the 
    				   current pass	*/
    Queue nextEvalQueue;	/* List of nodes to be evaluated in the next 
        			   pass */
    int lastUniquePass;  	/* The pass number when a unique node was last
    				   found: used to detect progress */
    Queue devices, nets;	/* Nets and devices that are still pending */

    Node *deviceVector,		/* Graph nodes are in two vectors */
         *netVector;
    int numDevices, numNets;	/* Length of the two vectors */

    NodePt *pendingDevices,	/* VECTOR of devices and nets currently */
	   *pendingNets;	/* being processed.  Unique, bad, and suspect
				   are sometimes present, but are weeded out
				   periodically */
    int numPendingDevices, 	/* Number of pending nets/devices in the */
        numPendingNets;		/* remainingDevices/Nets vectors 	 */

    Queue uniqueDevices,	/* Nets and devices already found unique */
    	  uniqueNets;
    Queue suspectDevices,	/* Suspect nodes */
	  suspectNets;
    Queue badDevices,		/* Bad nodes: unique but do not match */
	  badNets;
  } Graph;

#define PendingNetsAreClean(graph)		\
(graph->numNets == graph->numPendingNets + graph->suspectNets.size + 	\
  		   graph->badNets.size + graph->uniqueNets.size)

#define PendingDevicesAreClean(graph)		\
(graph->numDevices == graph->numPendingDevices + graph->suspectDevices.size + \
  		      graph->badDevices.size + graph->uniqueDevices.size)
