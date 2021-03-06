/*
The MIT License (MIT)

Copyright (c) 2016 EDF Energy

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

#ifndef __dynlb__
#define __dynlb__

/* simple morton ordering based point balancer */
void dynlb_morton_balance (int n, REAL *point[3], int ranks[]);

enum dynlb_part /* space partitioning type */
{
  DYNLB_RADIX_TREE, /* radix tree based on morton ordering */
  DYNLB_RCB_TREE /* recursive coordinate bisection tree */
};

struct dynlb /* load balancer interface */
{
  int ntasks; /* number of taks used; 0 means use hardware optimum */
  int cutoff; /* partitioning tree cutoff; 0 means use default selection */
  REAL epsilon; /* imbalance epsilon; rebalance when imbalance > 1.0 + epsilon */
  enum dynlb_part part; /* partitioning type */

  void *ptree; /* partitioning tree; used internally */
  int ptree_size; /* partitioning tree size; used internally */

  REAL imbalance; /* current imbalance */
  int npoint; /* current number of points on this MPI rank */
};

/* create load balancer */
struct dynlb* dynlb_create (int ntasks, int n, REAL *point[3], int cutoff, REAL epsilon, enum dynlb_part part);

/* assign an MPI rank to a point; return this rank */
int dynlb_point_assign (struct dynlb *lb, REAL point[]);

/* assign MPI ranks to a box spanned between lo and hi points; return the number of ranks assigned */
int dynlb_box_assign (struct dynlb *lb, REAL lo[], REAL hi[], int ranks[]);

/* update load balancer */
void dynlb_update (struct dynlb *lb, int n, REAL *point[3]);

/* destroy load balancer */
void dynlb_destroy (struct dynlb *lb);

#endif
