/*
 * File: matchmaker.h
 * Content: Method descriptions and constants for matchmaker
 * Author: Kamer Kaya, Johannes Langguth and Bora Ucar
 * Version: 0.3
 *
 * Please see the reports:
 *
 *   "I. S. Duff, K. Kaya and B. Ucar.
 *   'Design, Implementations and Analysis of Maximum Transversal Algorithms'
 *   CERFACS Tech. Report TR/PA/10/76, October, 2010."
 *
 *   "K. Kaya, J. Langguth, F. Manne and B. Ucar.
 *   'Experiments on Push-Relabel-based Maximum Cardinality Matching Algorithms for Bipartite Graphs'
 *   CERFACS Tech. Report TR/PA/11/33, May, 2011."
 *
 * for more details and cite them if you use the codes.
 */

#ifndef MATCHMAKER_H_
#define MATCHMAKER_H_

#define do_old_cheap 1
#define do_sk_cheap 2
#define do_sk_cheap_rand 3
#define do_mind_cheap 4

#define do_dfs 1
#define do_bfs 2
#define do_mc21 3
#define do_pf 4
#define do_pf_fair 5
#define do_hk 6
#define do_hk_dw 7
#define do_abmp 8
#define do_abmp_bfs 9
#define do_pr_fifo_fair 10

void old_cheap(int* col_ptrs, int* col_ids, int* match, int* row_match, int n, int m);
void sk_cheap(int* col_ptrs, int* col_ids, int* row_ptrs, int* row_ids, int* match, int* row_match, int n, int m);
void sk_cheap_rand(int* col_ptrs, int* col_ids, int* row_ptrs, int* row_ids, int* match, int* row_match, int n, int m);
void mind_cheap(int* col_ptrs, int* col_ids, int* row_ptrs, int* row_ids, int* match, int* row_match, int n, int m);

void match_dfs(int* col_ptrs, int* col_ids, int* match, int* row_match, int n, int m);
void match_bfs(int* col_ptrs, int* col_ids, int* match, int* row_match, int n, int m);
void match_mc21(int* col_ptrs, int* col_ids, int* match, int* row_match, int n, int m);
void match_pf(int* col_ptrs, int* col_ids, int* match, int* row_match, int n, int m);
void match_pf_fair(int* col_ptrs, int* col_ids, int* match, int* row_match, int n, int m);
void match_hk(int* col_ptrs, int* col_ids, int* row_ptrs, int* row_ids, int* match, int* row_match, int n, int m);
void match_hk_dw(int* col_ptrs, int* col_ids, int* row_ptrs, int* row_ids, int* match, int* row_match, int n, int m);
void match_abmp(int* col_ptrs, int* col_ids, int* row_ptrs, int* row_ids, int* match, int* row_match, int n, int m);
void match_abmp_bfs(int* col_ptrs, int* col_ids, int* row_ptrs, int* row_ids, int* match, int* row_match, int n, int m);
void match_pr_fifo_fair(int* col_ptrs, int* col_ids, int* row_ptrs, int* row_ids, int* match, int* row_match, int n, int m, double relabel_period);

void pr_global_relabel(int* l_label, int* r_label, int* row_ptrs, int* row_ids, int* match, int* row_match, int n, int m);

void cheap_matching(int* col_ptrs, int* col_ids, int* row_ptrs, int* row_ids, int* match, int* row_match, int n, int m, int cheap_id);

void cheapmatching(int* col_ptrs, int* col_ids, int* match, int* row_match, int n, int m, int cheap_id, int clear_match);
void matching(int* col_ptrs, int* col_ids, int* match, int* row_match, int n, int m, int match_id, int cheap_id, double relabel_period, int clear_match);

#endif /* MATCHMAKER_H_ */
