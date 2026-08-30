// ************************************************************************
// 
// Copyright (c) 1995-2002 Juniper Networks, Inc. All rights reserved.
// 
// Permission is hereby granted, without written agreement and without
// license or royalty fees, to use, copy, modify, and distribute this
// software and its documentation for any purpose, provided that the
// above copyright notice and the following three paragraphs appear in
// all copies of this software.
// 
// IN NO EVENT SHALL JUNIPER NETWORKS, INC. BE LIABLE TO ANY PARTY FOR
// DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
// ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF
// JUNIPER NETWORKS, INC. HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
// DAMAGE.
// 
// JUNIPER NETWORKS, INC. SPECIFICALLY DISCLAIMS ANY WARRANTIES,
// INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
// NON-INFRINGEMENT.
// 
// THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND JUNIPER
// NETWORKS, INC. HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
// UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
// 
// ************************************************************************

/* Memory Monitor */
/* for debugging malloc/free problems. */

#include <stdio.h>
#include <malloc.h>
#include <assert.h>

/* number of free lists */
#define NUM_LISTS 20

#define PAT_GUARD1 0xf1f1f1f1
#define PAT_GUARD2 0xf2f2f2f2
#define PAT_GUARD3 0xf3f3f3f3
#define PAT_FREE  0xf4
#define PAT_ALLOC  0xf5
#define TYPE_HOLD 1
#define TYPE_FREE 2
#define TYPE_ALLOC 3

/* size of memory grabed */
int MMChunkSize = (1024*32000);

/* max bytes on hold list */
int MMHoldMax = (1024*1000);

/* check / give statistics every nth malloc */ 
int MMCheckInterval = 25000; 
/* int MMCheckInterval = 1; */

int MMStatisticsInterval = 25000;

/* memory block */
/* note preamble, and suffix need to be double word multiples
 * to keep everything aligned.
 */
typedef struct mBlock
{
    int mb_guard1;
    struct mBlock *mb_next;
    struct mBlock *mb_prev;  /* used only on alloc list, to allow
			      * freeing of block without traversing
			      * whole alloc list
			      */
    int mb_sizeUsed;
    int mb_size;
    int mb_flags;
    int mb_type;
    int mb_guard2;
                        /* NOTE: above preamble must be multiple of 8 bytes */ 
    unsigned char mb_contents[8]; /* place holder, followed by 8 byte mb_guard3 */
} MBlock;

/* lists 
 * array of free lists: 
 *   different lists for different size blocks
 *   last list for "over-sized" blocks.
 *
 * hold lists are used so recently released blocks are not reallocated for
 * as long as possible - so easier to tell if they are referenced after free.
 */
MBlock *mmHoldList = NULL;
MBlock *mmHoldOldList = NULL;
MBlock *mmFreeList[NUM_LISTS];
MBlock *mmAllocList;

/* size of current hold list in bytes */
int mmHoldSize = 0;

/* list sizes */
int mmFreeNumBlocks[NUM_LISTS];
int mmAllocNumBlocks;
int mmHoldNumBlocks;
int mmHoldOldNumBlocks;

/* number of calls */
int mmMallocCalls = 0;
int mmFreeCalls = 0;

/* offset between memory block and what we pass to user */
int mmOffset;

/* size MBlock exceeds user data by */
int mmOverHead;

/* min size MBlock must exceed user request to warrant splitting it */
int mmSplitThreshold;

/* already initialed? */
int mmInit = 0;
    
void mm_Init()
{
  int i;
  MBlock dum;

  /* only initial once! */
  if(mmInit) return;
  mmInit = 1;

  /* offset between start of user area and mBlock */
  mmOffset = (int) &dum.mb_contents[0];
  mmOffset -= (int) &dum;
  
  assert(mmOffset%8 == 0);

  /* total amount of extra bytes around user data in an mBlock */
  mmOverHead = sizeof(MBlock);

  /* min size mBlock must exceed user req. before its split */
  mmSplitThreshold = 2*mmOverHead + 10;

  /* initial free lists */
  for(i=0; i<NUM_LISTS; i++)
  {
    mmFreeList[i] = NULL;
    mmFreeNumBlocks[i] = 0;
  }
}

void MM_Statistics(void)
{
  FILE *f = stderr;
  int totFree = 0;
  int i;
 
  /* initial */
  if(!mmInit) mm_Init();

  /* number of calls */
  fprintf(f,"\n==============\nMalloc calls: %d, Free calls: %d\n",
	  mmMallocCalls, mmFreeCalls);

  /* alloced blocks */
  fprintf(f,"Alloced: %d blocks\n", mmAllocNumBlocks);

  /* total free  */
  for(i=0; i<NUM_LISTS; i++)
  {
    totFree +=  mmFreeNumBlocks[i];
  }
  fprintf(f,"Free (total): %d blocks\n", totFree);

  /* hold blocks */
  fprintf(f,"Hold: %d blocks (%d bytes)\n", mmHoldNumBlocks, mmHoldSize);
  fprintf(f,"HoldOld: %d blocks\n\n", mmHoldOldNumBlocks);

#ifdef HIDE
  /* free detail */
  for(i=0; i<NUM_LISTS-1; i++)
  {
    fprintf(f,"Free (size %d): %d blocks\n", 
	    (i+1)*8, mmFreeNumBlocks[i]);
  }
  fprintf(f,"Free (size > %d): %d blocks\n", 
	 (NUM_LISTS-1)*8, mmFreeNumBlocks[NUM_LISTS-1]);
#endif HIDE
}

static void mm_BlockCheck(MBlock *block, int type)
{
  int i;
  register unsigned char *p, *pend;

  /* check alignment */
  if ( ((int) block) & 7 != 0 ) 
  {
    fprintf(stderr, "mm_BlockCheck block = %x.\n", (int) block);
    fprintf(stderr, "mm_BlockCheck bad alignment. (should be double word aligned)\n");
  }

  /* check guards */
  p = (char *) block;
  if(
     block->mb_guard1 != PAT_GUARD1 ||
     block->mb_guard2 != PAT_GUARD2 ||
     *((int *) (p + sizeof(MBlock) + block->mb_size - 8)) != PAT_GUARD3 || 
     *((int *) (p + sizeof(MBlock) + block->mb_size - 4)) != PAT_GUARD3)
  {
    fprintf(stderr, "mm_BlockCheck block = %x.\n", (int) block);
    fprintf(stderr, "mm_BlockCheck bad guards.\n");
    abort();
  }

  /* check type */
  if(block->mb_type != type)
  {
    fprintf(stderr, "mm_BlockCheck block = %x.\n", (int) block);
    fprintf(stderr, "mm_BlockCheck bad type:  type=%d expected=%d\n",
	    block->mb_type, type);
    abort();
  }

  /* check size consistency */
  if(block->mb_sizeUsed < 0 || 
     block->mb_size < 0 ||
     block->mb_sizeUsed > block->mb_size)
  {
    fprintf(stderr, "mm_BlockCheck block = %x.\n", (int) block);
    fprintf(stderr, "mm_BlockCheck bad size:  size=%d sizeUsed=%d\n",
	    block->mb_size, block->mb_sizeUsed);
    abort();
  }

  /* free blocks should have 0 sizeUsed */
  if(block->mb_type == TYPE_FREE && block->mb_sizeUsed != 0)
  {
    fprintf(stderr, "mm_BlockCheck block = %x.\n", (int) block);
    fprintf(stderr, "mm_BlockCheck free block has sizeUsed: sizeUsed=%d\n",
	    block->mb_sizeUsed);
    abort();
  }
	
  /* check pattern in unused content */
  p = &block->mb_contents[block->mb_sizeUsed];
  pend = &block->mb_contents[block->mb_size];
  while(p!=pend)
  {
    if( *(p++) != PAT_FREE)
    {
      fprintf(stderr, "mm_BlockCheck block = %x.\n", (int) block);
      fprintf(stderr, "mm_BlockCheck unused part of block overwritten.\n"); 
      abort();
    }
  }
}

/* like mm_BlockCheck except that we save time but not checking
 * entire free area of huge blocks.
 */
static void mm_BlockCheckFast(MBlock *block, int type)
{
  int i;
  register unsigned char *p, *pend;

  /* check alignment */
  if ( ((int) block) & 7 != 0 ) 
  {
    fprintf(stderr, "mm_BlockCheck block = %x.\n", (int) block);
    fprintf(stderr, "mm_BlockCheck bad alignment. (should be double word aligned)\n");
  }

  /* check guards */
  p = (char *) block;
  if(
     block->mb_guard1 != PAT_GUARD1 ||
     block->mb_guard2 != PAT_GUARD2 ||
     *((int *) (p + sizeof(MBlock) + block->mb_size - 8)) != PAT_GUARD3 ||
     *((int *) (p + sizeof(MBlock) + block->mb_size - 4)) != PAT_GUARD3)
  {
    fprintf(stderr, "mm_BlockCheck block = %x.\n", (int) block);
    fprintf(stderr, "mm_BlockCheck bad guards.\n");
    abort();
  }

  /* check type */
  if(block->mb_type != type)
  {
    fprintf(stderr, "mm_BlockCheck block = %x.\n", (int) block);
    fprintf(stderr, "mm_BlockCheck bad type:  type=%d expected=%d\n",
	    block->mb_type, type);
    abort();
  }

  /* check size consistency */
  if(block->mb_sizeUsed < 0 || 
     block->mb_size < 0 ||
     block->mb_sizeUsed > block->mb_size)
  {
    fprintf(stderr, "mm_BlockCheck block = %x.\n", (int) block);
    fprintf(stderr, "mm_BlockCheck bad size:  size=%d sizeUsed=%d\n",
	    block->mb_size, block->mb_sizeUsed);
    abort();
  }

  /* free blocks should have 0 sizeUsed */
  if(block->mb_type == TYPE_FREE && block->mb_sizeUsed != 0)
  {
    fprintf(stderr, "mm_BlockCheck block = %x.\n", (int) block);
    fprintf(stderr, "mm_BlockCheck free block has sizeUsed: sizeUsed=%d\n",
	    block->mb_sizeUsed);
    abort();
  }
	
  /* check pattern in unused content */
  p = &block->mb_contents[block->mb_sizeUsed];
  pend = &block->mb_contents[block->mb_size];
  /* CHECK ONLY FIRST PART OF LARGE FREE AREAS */
  if(pend-p>1000) pend = p+1000;
  while(p!=pend)
  {
    if( *(p++) != PAT_FREE)
    {
      fprintf(stderr, "mm_BlockCheck block = %x.\n", (int) block);
      fprintf(stderr, "mm_BlockCheck unused part of block overwritten.\n"); 
      abort();
    }
  }
}
    
void MM_Check()
{
  MBlock *b;
  int num, i;
 
  /* initial */
  if(!mmInit) mm_Init();

  /* check alloced list */
  num = 0;
  for(b=mmAllocList; b; b=b->mb_next)
  {
    mm_BlockCheck(b, TYPE_ALLOC);
    num++;
  }
  if(num != mmAllocNumBlocks)
  {
    fprintf(stderr, "MM_Check %d blocks on alloc list, should be %d\n",
	    num, mmAllocNumBlocks);
    abort();
  }

  /* check hold list */
  num = 0;
  for(b=mmHoldList; b; b=b->mb_next)
  {
    mm_BlockCheck(b, TYPE_HOLD);
    num++;
  }
  if(num != mmHoldNumBlocks)
  {
    fprintf(stderr, "MM_Check %d blocks on hold list, should be %d\n",
	    num, mmHoldNumBlocks);
    abort();
  }

  /* check old hold list */
  num = 0;
  for(b=mmHoldOldList; b; b=b->mb_next)
  {
    mm_BlockCheck(b, TYPE_HOLD);
    num++;
  }
  if(num != mmHoldOldNumBlocks)
  {
    fprintf(stderr, "MM_Check %d blocks on holdOld list, should be %d\n",
	    num, mmHoldOldNumBlocks);
    abort();
  }

  /* check free lists */
  for(i=0; i<NUM_LISTS; i++)
  {
    num = 0;
    for(b=mmFreeList[i]; b; b=b->mb_next)
    {
      mm_BlockCheck(b, TYPE_FREE);
      num++;
    }
    if(num != mmFreeNumBlocks[i])
    {
      fprintf(stderr, "MM_Check %d blocks on free list #%d, should be %d\n",
	      num, i, mmFreeNumBlocks[i]);
      abort();
    }
  }
}

/* add block to (doubly linked) alloc list */
static __inline__ void mm_AllocAdd(MBlock *block)
{
  block->mb_prev = NULL;
  block->mb_next = mmAllocList;
  
  if(mmAllocList) mmAllocList->mb_prev = block;

  mmAllocList = block;
  mmAllocNumBlocks++;
}

/* remove block from (doubly linked) alloc list */
static __inline__ void mm_AllocRemove(MBlock *block)
{
  MBlock *prev = block->mb_prev;
  MBlock *next = block->mb_next;

  if(prev) 
  {
    prev->mb_next = next;
  }
  else
  {
    mmAllocList = next;
  }

  if(next) next->mb_prev = prev;

  mmAllocNumBlocks--;
}
    
void mm_BlockInit(MBlock *block, int type, int sizeUsed)
{
  int i;
  register unsigned char *p, *pend;

  if(sizeUsed>block->mb_size)
  {
    fprintf(stderr,"mm_BlockInit: sizeUsed (%d) exceeds size (%d)!\n",
	    sizeUsed, block->mb_size);
    abort();
  }
  block->mb_sizeUsed = sizeUsed;
  block->mb_type = type;

  /* set guards */
  block->mb_guard1 = PAT_GUARD1;
  block->mb_guard2 = PAT_GUARD2;
  p = (void *) block;
  *((int *) (p + sizeof(MBlock) + block->mb_size - 8)) = PAT_GUARD3;
  *((int *) (p + sizeof(MBlock) + block->mb_size - 4)) = PAT_GUARD3;

	    
  /* initial content */
  p = &block->mb_contents[0];
  pend=&block->mb_contents[sizeUsed];
  while(p!=pend) *(p++) = PAT_ALLOC;
  pend=&block->mb_contents[block->mb_size];
  while(p!=pend) *(p++) = PAT_FREE;

/*  for(i=0; i<sizeUsed; i++) block->mb_contents[i] = PAT_ALLOC; */
/*  for(i=sizeUsed; i<block->mb_size; i++) block->mb_contents[i] = PAT_FREE; */
}


/* special fast version of mm_BlockInit(), for initializing blocks
 * whose (empty) content was previously initialized.
 */
void mm_BlockInitEmpty(MBlock *block, int type, int sizeUsed)
{
  char *p, *pend;

  assert(block->mb_sizeUsed==0);

  if(sizeUsed>block->mb_size)
  {
    fprintf(stderr,"mm_BlockInitEmpty: sizeUsed (%d) exceeds size (%d)!\n",
	    sizeUsed, block->mb_size);
    abort();
  }
  block->mb_sizeUsed = sizeUsed;
  block->mb_type = type;

  /* set guards */
  block->mb_guard1 = PAT_GUARD1;
  block->mb_guard2 = PAT_GUARD2;
  p = (void *) block;
  *((int *) (p + sizeof(MBlock) + block->mb_size - 4)) = PAT_GUARD3;
  *((int *) (p + sizeof(MBlock) + block->mb_size - 8)) = PAT_GUARD3;
	    
  /* initial content */
  /* SAVE TIME BY NOT REINITIALIZING CONTENT !! */
}

void mm_MoveToFreeLists(MBlock *list)
{
  MBlock *block, *next;

  for(block=list; block; block=next)
  {
    int size = block->mb_size;
    int dwords = size/8;

    assert(dwords>=1);

    /* remember next */
    next = block->mb_next;

    /* change type to free */
    block->mb_type = TYPE_FREE;

    /* add block to appropriate free list */
    if(dwords < NUM_LISTS)
    {
      block->mb_next = mmFreeList[dwords-1];
      mmFreeList[dwords-1] = block;
      mmFreeNumBlocks[dwords-1] += 1;
    }
    else
    {
      block->mb_next = mmFreeList[NUM_LISTS-1];
      mmFreeList[NUM_LISTS-1] = block;
      mmFreeNumBlocks[NUM_LISTS-1] += 1;
    }
  } 
}

/* add block to hold list
 * if hold list max size exceeded, flush old hold list and retire this one.
 */
void mm_Hold(MBlock *block)
{
  MBlock *list;

  /* add block to hold list */
  block->mb_next = mmHoldList;
  mmHoldList = block;
  mmHoldNumBlocks += 1;
  mmHoldSize += block->mb_size;

  /* if max size exceeded, retire hold list */
  if(mmHoldSize > MMHoldMax)
  {
    MM_Check();

    mm_MoveToFreeLists(mmHoldOldList);
    mmHoldOldList = mmHoldList;
    mmHoldOldNumBlocks = mmHoldNumBlocks;
    mmHoldList=NULL;
    mmHoldNumBlocks = 0;
    mmHoldSize = 0;
  }
}

static MBlock *mm_NewBlock(int size)
{
  MBlock *block;


  if(size > MMChunkSize - mmOverHead - 7)  /* 7 to allow for dword align */
  {
    fprintf(stderr,"mm_NewBlock:  request too big!  %d>%d\n",
	    size, MMChunkSize-mmOverHead-7); 
    abort();
  }

  fprintf(stderr,"mm_NewBlock:  new memory block (%d k)\n", MMChunkSize/1024); 

  {
    int p, p2, actualSize;
    p = (int) malloc(MMChunkSize);
    /* make sure we have doubleword align */
    p2 = ((p+7)/8)*8;
    actualSize = MMChunkSize - (p2-p);
    
    block = (MBlock *) (MBlock *) p2;
    block->mb_size = actualSize - mmOverHead;
  }
  mm_BlockInit(block, TYPE_FREE, 0);

  return block;
}  

/* split unused part of alloced block off as separate free block */
static void mm_SplitBlock(MBlock *block)
{
  int avail, end;
  MBlock *bNew;

  /* compute amount of space available */
  avail = block->mb_size - block->mb_sizeUsed;
  if(avail < mmSplitThreshold) return;

  /* just past end of block we are splitting */
  end = (int) block + mmOverHead + block->mb_size;
  
  /* create new block */
  bNew = (MBlock *) ( ((int) block) + mmOverHead + block->mb_sizeUsed);
  bNew = (MBlock *) ( ((((int) bNew)+7)/8)*8);
  bNew->mb_size = end - ((int) bNew) - mmOverHead;
  bNew->mb_sizeUsed = 0;
  mm_BlockInitEmpty(bNew, TYPE_FREE, 0);
  bNew->mb_next = NULL;

  /* adjust block */
  block->mb_size = ((int) bNew) - ((int) block) - mmOverHead;
  mm_BlockInit(block, TYPE_ALLOC, block->mb_sizeUsed);

  assert(block->mb_size>7);

  /* move new block to free list */
  mm_MoveToFreeLists(bNew);
}  


void MM_Free(void *cdata)
{
  MBlock *block = (MBlock*)( (char*)cdata - mmOffset);

  if(!mmInit) 
  {
    fprintf(stderr,"MM_Free() called prior to mm_Init.\n");
    abort();
  }

  mmFreeCalls++;

  /* check block */
  mm_BlockCheck(block,TYPE_ALLOC);

  /* remove block from alloc list */
  mm_AllocRemove(block);

  /* re(init) block */
  mm_BlockInit(block, TYPE_HOLD, 0);

  /* add to hold list */
  mm_Hold(block);
}

void *MM_Malloc(unsigned size)
{
  MBlock *block = NULL;
  MBlock **bpp;
  int dwords = (size+7)/8;

  assert(size>0);

  /* initial */
  if(!mmInit) mm_Init();

  /* check and give stats every so oftern mallocs */
  mmMallocCalls++;
  if(mmMallocCalls%MMCheckInterval ==0)
  {
    MM_Check();
  }
  if(mmMallocCalls%MMStatisticsInterval ==0)
  {
    MM_Statistics();
  }

  /* first try grabbing block from exact size list */
  if(dwords < NUM_LISTS && mmFreeList[dwords-1])
  {
    block = mmFreeList[dwords-1];
    mmFreeList[dwords-1] = block->mb_next;
    mmFreeNumBlocks[dwords-1] -= 1;
    goto gotBlock;
  }

  /* next look for big enough block on "oversize" free list */
  for(bpp = &mmFreeList[NUM_LISTS-1]; *bpp; bpp=&((*bpp)->mb_next))
  {
    if((*bpp)->mb_size>=size) 
    {
      block = (*bpp);
      (*bpp) = (*bpp)->mb_next;
      mmFreeNumBlocks[NUM_LISTS-1] -= 1;
      goto gotBlock;
    }
  }

  /* ok need new block */
  block = mm_NewBlock(dwords*8);

gotBlock:

  /* check block */
  mm_BlockCheckFast(block,TYPE_FREE);

  /* (re)init block */
  mm_BlockInitEmpty(block, TYPE_ALLOC, size);

  /* add block to alloc list */  
  mm_AllocAdd(block);

  /* if block oversized, split off unused part */
  if(block->mb_size - block->mb_sizeUsed >= mmSplitThreshold)
  {
    mm_SplitBlock(block);
  }

  return (void*) (((char *) block) + mmOffset);
}

