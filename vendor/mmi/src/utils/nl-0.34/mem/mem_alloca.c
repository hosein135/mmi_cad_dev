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

struct mem_alloca_header {
  void *stack;
  mem_alloca_header prev;
};
  

static int mem_stack_direction = 0;
static void *mem_alloca_buffer = NULL;
static int mem_alloca_buffer_size = 0;
static mem_alloca_header mem_alloca_header;


static
int
mem_figure_stack_direction (void *ptr)
{
  if ( ptr ) {
    if ( (ptrdiff_t) ptr > (ptrdiff_t) &ptr ) {
      /* grows downward */
      return -1;
    }
    else {
      /* grows upward */
      return 1;
    }
  }
  else {
    int dir = figure_stack_direction (&ptr);

    return dir;
  }
}


static
void
mem_init_alloca (void)
{
  mem_stack_direction = mem_figure_stack_direction (NULL);
  mem_alloca_buffer = malloc (4096);
  mem_alloca_buffer_size = 4096;
}


void *
mem_alloca (size_t size)
{
  if ( mem_alloca_buffer == NULL ) {
    mem_init_alloca ();
  }

  
