/*
 * The original source:
 * https://gitlab.inria.fr/bora-ucar/matchmaker/-/blob/225e66e6a79a31b3c9f668b7f9779e2f106302bb/matchmaker.h
 * Comes with the following terms [CeCILL-B license]:
 *
 * Copyright CNRS, Inria, ENS Lyon.
 * Contributors: Kamer Kaya, Johannes Langguth, and Bora Ucar.
 * (2019)
 *
 * kamer.kaya@sabanciuniv.edu,
 * langguth@simula.no,
 * bora.ucar@ens-lyon.fr
 *
 * This software is a computer program whose purpose is to implement
 * a number of algorithms for solving the maximum cardinality matching
 * problem in bipartite graphs.
 *
 * This software is governed by the CeCILL-B license under French law and
 * abiding by the rules of distribution of free software.  You can  use,
 * modify and/ or redistribute the software under the terms of the CeCILL-B
 * license as circulated by CEA, CNRS and INRIA at the following URL
 * "http://www.cecill.info".
 *
 * As a counterpart to the access to the source code and  rights to copy,
 * modify and redistribute granted by the license, users are provided only
 * with a limited warranty  and the software's author,  the holder of the
 * economic rights,  and the successive licensors  have only  limited
 * liability.
 *
 * In this respect, the user's attention is drawn to the risks associated
 * with loading,  using,  modifying and/or developing or reproducing the
 * software by the user in light of its specific status of free software,
 * that may mean  that it is complicated to manipulate,  and  that  also
 * therefore means  that it is reserved for developers  and  experienced
 * professionals having in-depth computer knowledge. Users are therefore
 * encouraged to load and test the software's suitability as regards their
 * requirements in conditions enabling the security of their systems and/or
 * data to be ensured and,  more generally, to use and operate it in the
 * same conditions as regards security.
 *
 * The fact that you are presently reading this means that you have had
 * knowledge of the CeCILL-B license and that you accept its terms.
 */

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
