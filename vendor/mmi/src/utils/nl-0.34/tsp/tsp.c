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

#include "port.h"
#include "mem.h"
#include "ar.h"
#include "tsp.h"


typedef struct tsp_point_s *tsp_point;


struct tsp_point_s {
  tsp_point next;
  tsp_point prev;
  int next_cost;
  uint timestamp;
  void *data;
};


struct tsp_problem_s {
  tsp_cost_fun cost_fun;
  ar points;
  uint time;
};


static void tsp_clear_marks (tsp_problem prob) UNUSED;


tsp_problem
tsp_problem_create (tsp_cost_fun cost_fun)
{
  tsp_problem result = MALLOC (sizeof (*result));

  result->cost_fun = cost_fun;
  result->points = ar_alloc (0, sizeof (struct tsp_point_s));
  result->time = 1;

  return result;
}


void
tsp_problem_free (tsp_problem prob)
{
  ar_free (prob->points);
  FREE (prob);
}


int
tsp_problem_num_points (tsp_problem prob)
{
  int num_points = ar_size ((ar) prob);

  return num_points;
}


void
tsp_problem_add_point (tsp_problem prob, void *data)
{
  struct tsp_point_s point;

  point.next = NULL;
  point.prev = NULL;
  point.timestamp = 0;
  point.data = data;

  ar_add (prob->points, &point);
}


static
int
tsp_link_cost (tsp_problem prob, tsp_point from, tsp_point to)
{
  int cost = prob->cost_fun (from->data, to->data);

  return cost;
}


static
int
tsp_tour_cost (tsp_problem prob)
{
  int total_cost = 0;
  
  ar_for_all (prob->points, struct tsp_point_s, point_s) {
    int cost = tsp_link_cost (prob, &point_s, point_s.next);

    total_cost += cost;
  } ar_end_for;

  return total_cost;
}


static
void
tsp_clear_marks (tsp_problem prob)
{
  prob->time++;
}


static
void
tsp_mark_point (tsp_problem prob, tsp_point point)
{
  point->timestamp = prob->time;
}


static
void
tsp_unmark_point (tsp_point point)
{
  point->timestamp = 0;
}


static
int
tsp_is_marked (tsp_problem prob, tsp_point point)
{
  return (point->timestamp == prob->time);
}  


static
void
tsp_do_swap (tsp_problem prob, tsp_point p1, tsp_point p2)
{
  tsp_point p1_next = p1->next;
  tsp_point p2_next = p2->next;

  {
    tsp_point t = p2;

    while ( t != p1 ) {
      tsp_point t_next = t->next;
      tsp_point t_prev = t->prev;

      t->timestamp = t_prev->timestamp;
      t->next = t_prev;
      t->next_cost = t_prev->next_cost;
      t->prev = t_next;

      t = t_prev;
    }
  }

  p1->next = p2;
  p1->next_cost = tsp_link_cost (prob, p1, p1->next);
  p2->prev = p1;
  p1_next->next = p2_next;
  p1_next->next_cost = tsp_link_cost (prob, p1_next, p1_next->next);
  p2_next->prev = p1_next;

  tsp_unmark_point (p1);
  tsp_unmark_point (p2);
  tsp_unmark_point (p1_next);
  tsp_unmark_point (p2_next);
}
  

static
tsp_point
tsp_find_max_link (tsp_problem prob)
{
  int max = 0;
  tsp_point max_point = NULL;

  ar_for_all_pointers (prob->points, elt_ptr) {
    tsp_point point = elt_ptr;
    int flag = tsp_is_marked (prob, point);

    if ( flag ) {
      continue;
    }
    else {
      /* int length = tsp_link_cost (prob, point, point->next); */
      int length = point->next_cost;

      if ( length > max ) {
	max = length;
	max_point = point;
      }
    }
  } ar_end_for;

  return max_point;
}


static
tsp_point
tsp_find_best_swap (tsp_problem prob, tsp_point from)
{
  int best = 0;
  tsp_point best_point = NULL;
  tsp_point from_next = from->next;
  /* int from_cost = tsp_link_cost (prob, from, from_next); */
  int from_cost = from->next_cost;
  tsp_point t = from_next;

  while ( t != from ) {
    int t_cost = t->next_cost; /* tsp_link_cost (prob, t, t->next); */
    int new_cost1 = tsp_link_cost (prob, from, t);
    int new_cost2 = tsp_link_cost (prob, from_next, t->next);
    int gain = new_cost1 + new_cost2 - from_cost - t_cost;

    if ( gain < best ) {
      best = gain;
      best_point = t;
    }

    t = t->next;
  }

  return best_point;
}

static void tsp_check_next_cost (tsp_problem prob) UNUSED;

static
void
tsp_check_next_cost (tsp_problem prob)
{
  ar_for_all_pointers (prob->points, elt_ptr) {
    tsp_point point = elt_ptr;
    int cost = tsp_link_cost (prob, point, point->next);

    if ( cost != point->next_cost ) {
      printf ("next_cost for %08x is incorrect: is %d, should be %d\n",
	      (uint)point, point->next_cost, cost);
    }
  } ar_end_for;
}


static
void
tsp_optimize_tour (tsp_problem prob, int limit, int silent)
{
  int iter = 0;

  if ( !silent ) {
    printf ("TSP optimization:\n");
    printf (" %6s  %10s\n", "iter", "cost");
    printf (" %6s  %10s\n", "----", "----");
    printf (" %6d  %10d\n", 0, tsp_tour_cost (prob));
  }

  while (1) {
    tsp_point max_link = tsp_find_max_link (prob);
    tsp_point best_swap;

    if ( max_link == NULL ) {
      break;
    }

    best_swap = tsp_find_best_swap (prob, max_link);

    if ( best_swap == NULL ) {
      tsp_mark_point (prob, max_link);
      continue;
    }

    tsp_do_swap (prob, max_link, best_swap);

    /* tsp_check_next_cost (prob); */

    tsp_unmark_point (best_swap);
      
    iter++;

    if ( iter == limit )
      break;

    if ( !silent && (iter % 1000 == 0) ) {
      printf (" %6d  %10d\n", iter, tsp_tour_cost (prob));
    }
  }

  if ( !silent ) {
    printf (" %6d  %10d\n", iter, tsp_tour_cost (prob));
    printf ("TSP optimization complete\n");
    printf ("\n");
  }
}


static
void
tsp_initialize_tour (tsp_problem prob)
{
  tsp_point first = NULL;
  tsp_point prev = NULL;

  ar_for_all_pointers (prob->points, elt_ptr) {
    tsp_point point = elt_ptr;

    if ( prev == NULL ) {
      prev = point;
      first = prev;
    }
    else {
      prev->next = point;
      prev->next_cost = tsp_link_cost (prob, prev, prev->next);
      point->prev = prev;
      prev = point;
    }
  } ar_end_for;

  prev->next = first;
  prev->next_cost = tsp_link_cost (prob, prev, prev->next);
  first->prev = prev;
}


static
void
tsp_store_tour (tsp_problem prob, ar result)
{
  tsp_point first = ar_addr_of (prob->points, 0);
  tsp_point p = first;

  do {
    ar_add (result, &p->data);
    p = p->next;
  } while ( p != first );
}


int
tsp_solve (tsp_problem prob, int limit, int silent, ar result)
{
  int final_cost;

  tsp_initialize_tour (prob);
  /* tsp_check_next_cost (prob); */
  tsp_optimize_tour (prob, limit, silent);
  tsp_store_tour (prob, result);

  final_cost = tsp_tour_cost (prob);

  return final_cost;
}
