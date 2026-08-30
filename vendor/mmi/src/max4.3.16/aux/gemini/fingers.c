/*
$Id: fingers.c,v 2.7.1.1 1994/01/01 00:43:32 mckenzie Exp mckenzie $
*/
/*
** fingers.c
** Combines fingered (forked) transistors into a single, wider transistor
** Author:
** Guntram Wolski                   gwolsk@sei.com
** Silicon Engineering, Inc.        408-438-5331 x112
** ...!{mips,ames,ucscc}!seidc!gwolsk
**
** Updated 7-16-1992 by Neil McKenzie (mckenzie@cs.washington.edu)
**
*/
#include "gemini.h"

/* hash_buckets must be prime! */
#define hash_buckets	4093
/* Stupid, but safe:  note that MIPS machines, like many computers, do
  not implement signed division as one might wish. */
#define hash_squash(x)	((((unsigned) x) & 0x7FFFFFFF) % 4093);
#define drain_prime	1637
#define gate_prime	311
#define type_prime	3

/*
  External entry points: AllocFingerHash, CombineFingers.
  Everything else is declared "static" (hence, local).
*/

/*
 hash_table--

   A standard bucket-and-chain table (prime size for simplicity
   of hashing).  The ->next link is used as the hash chain.
*/

static Node **hash_table = NULL;

/*
 RemoveConnections --
   removes the entries for a device from the nets it is connected to.

   Parameters:
     *dev:  the device to be disconnected.

   Side effects:
     The device disappears from the network graph.

   Returns:
     nothing.
*/

static void RemoveConnections(dev) Node *dev;
{
 Node **device_nets;
 DeviceConnection *net_devices;
 int i, j, k, n_c, n_d;

 device_nets = dev->connects.netList;
 n_c = NumberOfLinksD(dev);
 for (i = n_c; i > 0;) {
   --i;
   net_devices = device_nets[i]->connects.devList;
   n_d = NumberOfLinksN(device_nets[i]);
   for (j = n_d; j > 0;) {
     --j;
     if (net_devices[j].node == dev) {
       NumberOfLinksN(device_nets[i]) = --n_d;
       for (k = j; k < n_d; ++k)
	 net_devices[k] = net_devices[k+1];
       goto exit_device_loop;
     }
   }
 exit_device_loop:
   ;
 }
}

/*
 ParallelDevices --
   decides whether two devices are parallel fingers of a single
   gate.

   Parameters:
     *dev1, *dev2:  the devices to compare.

   Side effects:
     none.

   Returns:
     non-zero if:
       the devices are sim primitives (n, p)
       they are instances of the same primitive type (both n, both p),
       the devices are electrically parallel: same gate, same s/d
       connections, and
       (if device sizes are present) they are the same length.
     otherwise zero (non-parallel).
*/

static int ParallelDevices(dev1, dev2) Node *dev1; Node *dev2;
{
 Node **net1, **net2;

 if (dev1->n.nodeDef != dev2->n.nodeDef) return 0;
 if (dev1->n.nodeDef >= NUMBERTYPES) return 0;
 if (dev1->p.property != (Property *) NULL)
   {
     if (dev2->p.property == (Property *) NULL) return 0;
     if (dev1->p.property->length != dev2->p.property->length) return 0;
   }
 else if (dev2->p.property != (Property *) NULL) return 0;
 net1 = dev1->connects.netList;
 net2 = dev2->connects.netList;
 assert (net1, "Null pointer\n");
 assert (net2, "Null pointer\n");
 if (net1[2] != net2[2]) return 0;
 if (net1[3] != net2[3]) return 0;
 if ((net1[0] == net2[0]) && (net1[1] == net2[1])) return 1;
 if ((net1[1] == net2[0]) && (net1[0] == net2[1])) return 1;
 return 0;
}

/*
 CombineDevices--
   squashes two devices into one.

 Parameters:
   *major, *minor--the devices to combine.

 Side effects:
   *minor is removed from the graph and flagged as DELETED.  If device
   sizes are present, *major's width increases.

 Returns:
   nothing.
*/

static void CombineDevices(major, minor) Node *major; Node *minor;
{
 RemoveConnections(minor);
 if ((major->p.property != (Property *) NULL) &&
     (minor->p.property != (Property *) NULL))
   major->p.property->width += minor->p.property->width;
 minor->flag = DELETED;
}

/*
 HashFunction--
   produces a "random" (though repeatable) number based on connectivity
   and primitive type.

   Parameters:
     *dev:  the device to be hashed.

   Side effects:
     none.

   Returns:
     a hash index.  Since addresses tend to be aligned on various dull
     boundaries, we use modular arithmetic (i.e., lots o' primes, primes
     'r us) so as not to worry (or think).  This is easier than middle-square
     and more-or-less as good.
*/

static int HashFunction(dev) Node *dev;
{
 bigint s, d, g, t;

 s = (bigint) dev->connects.netList[0];
 d = (bigint) dev->connects.netList[1];
 g = (bigint) dev->connects.netList[3];
 t = dev->n.nodeDef;

 return hash_squash((s + d)*drain_prime + g*gate_prime + t*type_prime);
}

/*
 AllocFingerHash--
   allocate the hash table.

   Parameters:
     none.

   Side effects:
     hash_table is allocated.  Use FastAlloc because we will never
     free it.

   Returns:
     nothing.
*/

void AllocFingerHash()
{
 hash_table = (Node **) FastAlloc((unsigned) hash_buckets * sizeof(NodePt));
}

/*
 HashAndDestroy--
   enters some devices into the hash table, mulches others.

   Parameters:
     *dev:  the device to be hashed.  If a parallel finger is already
	    in the table, the two are combined (*dev is marked deleted,
	    the device in the hash table has its width adjusted).

   Side effects:
     If *dev is entered in the hash table, *dev->next is used as the
     hash chain (and so is set by HashAndDestroy).
     Otherwise, *dev is removed from the network graph and marked DELETED.

   Returns:
     nothing.
*/

static void HashAndDestroy(dev) Node *dev;
{
 int bucket_index;
 Node *major;

 if (dev->n.nodeDef >= NUMBERTYPES) return;
 if (NumberOfLinksD(dev) != 4) {
   return;
 }
 bucket_index = HashFunction(dev);
 if (hash_table[bucket_index] == (Node *) NULL) {
   dev->next = NULL;            /* NM 12-31-93 */
   hash_table[bucket_index] = dev;
   return;
 }
 for (major = hash_table[bucket_index]; major != (Node *) NULL;
   major = major->next) {
   if (ParallelDevices(major, dev)) {
     CombineDevices(major, dev);
     debug(INPUT,
       printf("CombineFingers: deleted device with index %d\n",bucket_index);)
     return;
   }
 }
 dev->next = hash_table[bucket_index];
 hash_table[bucket_index] = dev;
}

/*
 CombineFingers--
   glues fingered transistors together.

   Parameters:
     *graph:  the graph whose devices will be glued.

   Side effects:
     Some devices are deleted; some, on the other hand, are not.  A few
     become wider.

   Returns:
     nothing.
*/

void CombineFingers(graph) Graph *graph;
{
  int i;

  assert(hash_table != NULL, "Dereferencing null pointer in CombineFingers.");
/* clear local h-table memory */
  for (i = 0; i < hash_buckets; i++) {
	hash_table[i] = NULL;
  }
  for (i = graph->numDevices; i > 0;) {
    --i;
    if (graph->deviceVector[i].flag != DELETED)
      HashAndDestroy(&(graph->deviceVector[i]));
  }
}
