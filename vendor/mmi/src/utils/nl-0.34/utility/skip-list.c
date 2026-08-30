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

/* $Id: skip-list.c,v 1.1 1998/05/26 06:17:33 jka Exp $ */

#include "port.h"
#include "skip-list.h"


char sl_rcs_id[] = "$Id: skip-list.c,v 1.1 1998/05/26 06:17:33 jka Exp $";


#define MAX_LEVEL 32


typedef struct node *node;


struct skip_list_s {
  node head;
  int level;
};


struct node {
  unsigned int key;
  void *data;
  node forward[1];
};


struct node sl_nil_node = { 0xffffffff, 0, { 0 } };

node sl_nil = &sl_nil_node;


static
node
sl_node_create( int level, unsigned int key, void *data )
{
  node result = malloc( sizeof( *result ) + (level-1) * sizeof( node ) );

  result->key = key;
  result->data = data;

  return result;
}


static
int
sl_random_level( int current_max )
{
  static unsigned int r;
  static int n = 0;
  int result = 0;

  if ( current_max == MAX_LEVEL )
    current_max--;

  do {
    r >>= 2;

    if ( n <= 0 ) {
      r = random();
      n = 32;
    }
    
    n -= 2;

    result++;

  } while ( ((r & 0x3) == 0) && (result <= current_max) );

  return result;
}


static int comparisons;


static
int
sl_op( skip_list sl, unsigned int key, void **data_p,
       int put, int get, int extend, int remove )
{
  static node update[MAX_LEVEL];
  int level = sl->level;
  node head = sl->head;
  node x = head;
  int i;

  for ( i = level - 1; i >= 0; i-- ) {
    node next;

    do {
      next = x->forward[i];

      comparisons++;

      if ( key <= next->key )
        break;

      x = next;
    } while ( 1 );

    update[i] = x;
  }

  x = x->forward[0];

  if ( x != sl_nil && key == x->key ) {
    /* found */
    void *d = x->data;

    if ( put ) {
      x->data = *data_p;
    }

    if ( get ) {
      *data_p = d;
    }

    if ( remove ) {
      for ( i = 0; i < level; i++ ) {
        if ( update[i]->forward[i] != x )
          break;
        update[i]->forward[i] = x->forward[i];
      }
      free( x );
      while ( level > 1 &&
              head->forward[level] == sl_nil ) {
        level--;
      }
      sl->level = level;
    }
    
    return 1;
  }
  else {
    /* not found */

    if ( extend ) {
      int new_level = sl_random_level( level );

      if ( new_level > level ) {
        for ( i = level; i < new_level; i++ ) {
          update[i] = head;
        }
        sl->level = new_level;
      }

      x = sl_node_create( new_level, key, *data_p );

      for ( i = 0; i < new_level; i++ ) {
        x->forward[i] = update[i]->forward[i];
        update[i]->forward[i] = x;
      }

      if ( get ) {
	*data_p = x->data;
      }
    }

    return 0;
  }
}


#if 0
static
node
sl_find( skip_list sl, unsigned int key)
{
  static node update[MAX_LEVEL];
  int level = sl->level;
  node head = sl->head;
  node x = head;
  int i;

  for ( i = level - 1; i >= 0; i-- ) {
    node next;

    do {
      next = x->forward[i];

      comparisons++;

      if ( key <= next->key )
        break;

      x = next;
    } while ( 1 );

    update[i] = x;
  }

  x = x->forward[0];

  return x;
}
#endif


skip_list
sl_create( void )
{
  int i;
  skip_list result = malloc( sizeof( *result ) );
  node head = sl_node_create( MAX_LEVEL, 0, 0 );

  for ( i = 0; i < MAX_LEVEL; i++ ) {
    head->forward[i] = sl_nil;
  }

  result->head = head;
  result->level = 1;

  return result;
}


void
sl_free( skip_list sl )
{
  node x = sl->head;

  free( sl );

  while ( x != sl_nil ) {
    node y = x->forward[0];
    free( x );
    x = y;
  }
}


int
sl_member( skip_list sl, unsigned int key )
{
  int result = sl_op( sl, key, (void **)0, 0, 0, 0, 0 );

  return result;
}


int
sl_get( skip_list sl, unsigned int key, void **data_p )
{
  int result = sl_op( sl, key, data_p, 0, 1, 0, 0 );

  return result;
}


int
sl_put( skip_list sl, unsigned int key, void **data_p )
{
  int result = sl_op( sl, key, data_p, 1, 0, 0, 0 );

  return result;
}


int
sl_add( skip_list sl, unsigned int key, void *data )
{
  void *data_int = data;
  int result = sl_op( sl, key, &data_int, 0, 0, 1, 0 );

  return result;
}


int
sl_remove( skip_list sl, unsigned int key )
{
  int result = sl_op( sl, key, (void **)0, 0, 0, 0, 1 );

  return result;
}


int
sl_insert( skip_list sl, unsigned int key, void *data )
{
  void *local = data;
  int result = sl_op( sl, key, &local, 1, 0, 1, 0 );

  return result;
}


int
sl_intern( skip_list sl, unsigned int key, void **data_p )
{
  int result = sl_op( sl, key, data_p, 0, 1, 1, 0 );

  return result;
}


int
sl_extract( skip_list sl, unsigned int key, void **data_p )
{
  int result = sl_op( sl, key, data_p, 0, 1, 0, 1 );

  return result;
}


int
sl_exchange( skip_list sl, unsigned int key, void **data_p )
{
  int result = sl_op( sl, key, data_p, 1, 1, 0, 0 );

  return result;
}


int
sl_toggle( skip_list sl, unsigned int key, void *data )
{
  void *local = data;
  int result = sl_op( sl, key, &local, 0, 0, 1, 1 );

  return result;
}


void
sl_print( skip_list sl )
{
  node x = sl->head;

  putchar( '(' );
  while ( x->forward[0] != sl_nil ) {
    x = x->forward[0];
    printf( "[%d,%d]", x->key, (int) x->data );
    if ( x->forward[0] != sl_nil ) {
      putchar( ' ' );
    }
  }
  putchar( ')' );
  putchar( '\n' );
}


sl_node
sl_first_node (skip_list sl)
{
  node first =  sl->head->forward[0];

  if ( first == sl_nil ) {
    return NULL;
  }
  else {
    return (sl_node)first;
  }
}


sl_node
sl_next_node (sl_node n)
{
  node next = ((node) n)->forward[0];

  if ( next == sl_nil )
    return NULL;
  else
    return (sl_node) next;
}


int
sl_node_key_data (sl_node sln, unsigned int *key_p, void **data_p)
{
  node n = (node) sln;
  *key_p = n->key;
  *data_p = n->data;
  return 1;
}


void
sl_diagram( skip_list sl )
{
  int i;

  for ( i = sl->level-1; i >= 0; i-- ) {
    node x = sl->head;
    node next = sl->head;
    do {
      if ( x == sl->head ) {
	printf( "[]" );
	next = x->forward[i];
      }
      else if ( x == next ) {
	printf( "->[]" );
	next = x->forward[i];
      }
      else {
	printf( "----" );
      }
      x = x->forward[0];
    } while ( x != sl_nil );

    printf( "->[]\n" );
  }

  {
    node x = sl->head;

    do {
      if ( x != sl->head )
	printf( "%4d", x->key );
      else
	printf( "  " );

      x = x->forward[0];
    } while ( x != sl_nil );

    printf( "\n" );
    
    x = sl->head;

    do {
      if ( x != sl->head )
	printf( "%4d", (int) x->data );
      else
	printf( "  " );

      x = x->forward[0];
    } while ( x != sl_nil );

    printf( "\n" );
  }
}


#ifdef STANDALONE


main()
{
  static char buf[256];
  skip_list sl = sl_create();

  while ( 1 ) {
    fprintf( stderr, "(sl) " );
    gets( buf );

    switch ( buf[0] ) {
    case 'm': {
      unsigned int key;
      int ret;
      sscanf( buf+1, "%d%d", &key );
      ret = sl_member( sl, key );
      printf( "sl_member( sl, %d ) returns %d\n",
              key, ret );
      break;
    }
    case 'g': {
      unsigned int key;
      int data;
      int ret;
      sscanf( buf+1, "%d", &key );
      ret = sl_get( sl, key, (void **)&data );
      printf( "sl_get( sl, %d, 0 ) returns %d\n",
	      key, ret );
      printf( "  returned data is %d\n", data );
      break;
    }
    case 'p': {
      unsigned int key;
      int data;
      int ret;
      sscanf( buf+1, "%d%d", &key, &data );
      ret = sl_put( sl, key, (void **)&data );
      printf( "sl_put( sl, %d, %d ) returns %d\n",
              key, data, ret );
      break;
    }
    case 'a': {
      unsigned int key;
      int data;
      int ret;
      sscanf( buf+1, "%d%d", &key, &data );
      ret = sl_add( sl, key, (void *)data );
      printf( "sl_add( sl, %d, %d ) returns %d\n",
              key, data, ret );
      break;
    }
    case 'r': {
      unsigned int key;
      int ret;
      sscanf( buf+1, "%d%d", &key );
      ret = sl_remove( sl, key );
      printf( "sl_remove( sl, %d ) returns %d\n",
              key, ret );
      break;
    }
    case 'n': {
      unsigned int key;
      int data;
      int ret;
      int new_data;
      sscanf( buf+1, "%d%d", &key, &data );
      new_data = data;
      ret = sl_intern( sl, key, (void **)&new_data );
      printf( "sl_intern( sl, %d, %d ) returns %d\n",
              key, data, ret );
      printf( "  returned data is %d\n", new_data );
      break;
    }
    case 'e': {
      unsigned int key;
      int data;
      int ret;
      int new_data;
      sscanf( buf+1, "%d", &key );
      ret = sl_extract( sl, key, (void **)&new_data );
      printf( "sl_extract( sl, %d, 0 ) returns %d\n",
              key, ret );
      printf( "  returned data is %d\n", new_data );
      break;
    }
    case 'x': {
      unsigned int key;
      int data;
      int ret;
      int new_data;
      sscanf( buf+1, "%d%d", &key, &data );
      new_data = data;
      ret = sl_exchange( sl, key, (void **)&new_data );
      printf( "sl_exchange( sl, %d, %d ) returns %d\n",
              key, data, ret );
      printf( "  returned data is %d\n", new_data );
      break;
    }
    case 't': {
      unsigned int key;
      int data;
      int ret;
      sscanf( buf+1, "%d%d", &key, &data );
      ret = sl_toggle( sl, key, (void *)data );
      printf( "sl_toggle( sl, %d, %d ) returns %d\n",
              key, data, ret );
      break;
    }
    case 'P': {
      sl_print( sl );
      break;
    }
    case 'D': {
      sl_diagram( sl );
      break;
    }
    case 'T': {
      int i;
      int iter;
      int sum = 0;
      int sumsq = 0;
      int max = 0;

      sscanf( buf+1, "%d", &iter );

      sl_free( sl );
      sl = sl_create();

      for ( i = 0; i < iter; i++ ) {
	sl_add( sl, i, 0 );
      }

      for ( i = 0; i < iter; i++ ) {
	void *data = (void *)0;
	comparisons = 0;
	sl_get( sl, i, &data );
	sum += comparisons;
	sumsq += comparisons * comparisons;
	if ( comparisons > max )
	  max = comparisons;
      }
      {
	double avg = sum / (double)iter;
	double dev = sqrt( sumsq / (double)iter - avg * avg );
	printf( "avg = %.2f, sd = %.4f, max = %d\n", avg, dev, max );
      }
      break;
    }
    case 'R': {
      int i;
      int iter;
      int hist[MAX_LEVEL];

      sscanf( buf+1, "%d", &iter );

      for ( i = 0; i < MAX_LEVEL; i++ )
	hist[i] = 0;

      for ( i = 0; i < iter; i++ ) {
	int r = sl_random_level( MAX_LEVEL-1 );
	hist[r]++;
      }
      for ( i = 0; i < MAX_LEVEL; i++ ) {
	double pct = 100.0 * hist[i] / (double)iter;
	printf( "%2d:  %6d  %6.2f\n", i, hist[i], pct );
      }
      break;
    }
    case 'q': {
      return 0;
    }
    }
  }
}

#endif
