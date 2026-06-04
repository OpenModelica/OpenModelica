/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

#pragma once
#ifndef id46CF8262_ACA8_41CD_9972EE0E43C8C5E7
#define id46CF8262_ACA8_41CD_9972EE0E43C8C5E7

/*
 Mahder.Gebremedhin@liu.se  2014-03-13
*/

#include "pm_cluster_system.hpp"
#include "pm_runtime_config.hpp"
#include <algorithm>
#include <cstdlib>
#include <vector>
#include <map>
#include <set>

namespace openmodelica { namespace parmodelica {

struct concat_clusters {

    template <typename TaskSystemType>
    static void apply(TaskSystemType& task_system, const typename TaskSystemType::ClusterIdType& dest_id,
                      const typename TaskSystemType::ClusterIdType& src_id) {

        typedef typename TaskSystemType::GraphType              GraphType;
        typedef typename TaskSystemType::ClusterType            ClusterType;
        typedef typename TaskSystemType::adjacency_iterator     adjacency_iterator;
        typedef typename TaskSystemType::inv_adjacency_iterator inv_adjacency_iterator;

        GraphType& sys_graph = task_system.sys_graph;

        if (dest_id == src_id)
            return;

        ClusterType& dest = sys_graph[dest_id];
        ClusterType& src = sys_graph[src_id];

        if (dest.level > src.level) {
            std::cout << "trying to add edge : " << dest.level << " -> " << src.level << std::endl;
        }

        // std::cout << "Trying merege "  << dest.index_list << " and " << src.index_list << std::endl;

        typename ClusterType::iterator task_iter;
        for (task_iter = src.begin(); task_iter != src.end(); ++task_iter) {
            dest.add_task(*task_iter);
        }

        adjacency_iterator src_child_iter, src_child_end, curr_src_child_iter;
        boost::tie(src_child_iter, src_child_end) = adjacent_vertices(src_id, sys_graph);
        while (src_child_iter != src_child_end) {

            /*! Increment before erase. Apparently erasing an edge invalidates the vertex iterators in VS.
              something is going on inside boost that I don't know yet. Or VS is just being VS as ususal.
              (the edge container is in fact a set, but that should matter only if we iterate over ages.
              well apparently not :) )*/
            curr_src_child_iter = src_child_iter;
            ++src_child_iter;

            if (dest_id != *curr_src_child_iter) {
                boost::add_edge(dest_id, *curr_src_child_iter, sys_graph);
            }
            else {
                std::cout << "trying to add edge : " << sys_graph[dest_id].index_list << " -> "
                          << sys_graph[*curr_src_child_iter].index_list << std::endl;
            }
            boost::remove_edge(src_id, *curr_src_child_iter, sys_graph);
        }

        inv_adjacency_iterator src_parent_iter, src_parent_end, curr_src_parent_iter;
        boost::tie(src_parent_iter, src_parent_end) = inv_adjacent_vertices(src_id, sys_graph);
        while (src_parent_iter != src_parent_end) {

            /*! Increment before erase. Apparently erasing an edge invalidates the vertex iterators in VS.
              something is going on inside boost that I don't know yet. Or VS is just being VS as ususal.
              (the edge container is in fact a set, but that should matter only if we iterate over ages.
              well apparently not :) )*/
            curr_src_parent_iter = src_parent_iter;
            ++src_parent_iter;

            if (*curr_src_parent_iter != dest_id) {
                boost::add_edge(*curr_src_parent_iter, dest_id, sys_graph);
            }
            else {
                std::cout << "trying to add edge : " << sys_graph[*curr_src_parent_iter].index_list << " -> "
                          << sys_graph[dest_id].index_list << std::endl;
            }
            boost::remove_edge(*curr_src_parent_iter, src_id, sys_graph);
        }

        // boost::clear_vertex(src_id, sys_graph);
        boost::remove_vertex(src_id, sys_graph);
    }
};

// struct concat_same_level_clusters {
//
//    template<typename TaskSystemType>
//    static void apply(TaskSystemType& task_system,
//                        const typename TaskSystemType::ClusterIdType& dest_id,
//                        const typename TaskSystemType::ClusterIdType& src_id) {
//
//        typedef typename TaskSystemType::GraphType GraphType;
//        typedef typename TaskSystemType::ClusterType ClusterType;
//        typedef typename TaskSystemType::adjacency_iterator adjacency_iterator;
//        typedef typename TaskSystemType::inv_adjacency_iterator inv_adjacency_iterator;
//
//        GraphType& sys_graph = task_system.sys_graph;
//
//        ClusterType& dest = sys_graph[dest_id];
//        ClusterType& src = sys_graph[src_id];
//
//        typename ClusterType::iterator task_iter;
//        for(task_iter = src.begin(); task_iter != src.end(); ++task_iter) {
//            dest.add_task(*task_iter);
//        }
//
//        adjacency_iterator src_child_iter, src_child_end, curr_src_child_iter;
//        boost::tie(src_child_iter, src_child_end) = adjacent_vertices(src_id, sys_graph);
//		while(src_child_iter != src_child_end) {
//			/*! Increment before erase. Apparently erasing an edge invalidates the vertex iterators in VS.
//			  something is going on inside boost that I don't know yet. Or VS is just being VS as ususal.
//			  (the edge container is in fact a set, but that should matter only if we iterate over ages.
//			  well apparently not :) )*/
//			curr_src_child_iter = src_child_iter;
//			++src_child_iter;
//
//			boost::add_edge(dest_id, *curr_src_child_iter, sys_graph);
//            boost::remove_edge(src_id, *curr_src_child_iter, sys_graph);
//		}
//
//        /*for (; src_child_iter != src_child_end; ++src_child_iter) {
//            boost::add_edge(dest_id, *src_child_iter, sys_graph);
//            boost::remove_edge(src_id, *src_child_iter, sys_graph);
//        }*/
//
//        inv_adjacency_iterator src_parent_iter, src_parent_end, curr_src_parent_iter;
//        boost::tie(src_parent_iter, src_parent_end) = inv_adjacent_vertices(src_id, sys_graph);
//
//
//		while(src_parent_iter != src_parent_end) {
//			/*! Increment before erase. Apparently erasing an edge invalidates the vertex iterators in VS.
//			  something is going on inside boost that I don't know yet. Or VS is just being VS as ususal.
//			  (the edge container is in fact a set, but that should matter only if we iterate over ages.
//			  well apparently not :) )*/
//			curr_src_parent_iter = src_parent_iter;
//			++src_parent_iter;
//
//			boost::add_edge(*curr_src_parent_iter, dest_id, sys_graph);
//            boost::remove_edge(*curr_src_parent_iter, src_id, sys_graph);
//		}
//
//
//        /*for (; src_parent_iter != src_parent_end; ++src_parent_iter) {
//            boost::add_edge(*src_parent_iter, dest_id, sys_graph);
//            boost::remove_edge(*src_parent_iter, src_id, sys_graph);
//        }*/
//
//		boost::remove_vertex(src_id, sys_graph);
//    }
//
//};

// struct concat_with_parent {
//    static std::string name() {
//        return "concat_with_parent";
//    }
//
//    template<typename TaskSystemType>
//    static void apply(TaskSystemType& task_system,
//                        const typename TaskSystemType::ClusterIdType& parent_id,
//                        const typename TaskSystemType::ClusterIdType& child_id) {
//
//        typedef typename TaskSystemType::GraphType GraphType;
//        typedef typename TaskSystemType::ClusterType ClusterType;
//        typedef typename TaskSystemType::adjacency_iterator adjacency_iterator;
//
//        GraphType& sys_graph = task_system.sys_graph;
//
//        ClusterType& parent = sys_graph[parent_id];
//        ClusterType& child = sys_graph[child_id];
//
//        typename ClusterType::iterator task_iter;
//        for(task_iter = child.begin(); task_iter != child.end(); ++task_iter) {
//            parent.add_task(*task_iter);
//        }
//
//        adjacency_iterator grand_child_iter, grand_child_end, curr_grand_child_iter;
//        boost::tie(grand_child_iter, grand_child_end) = adjacent_vertices(child_id, sys_graph);
//		while(grand_child_iter != grand_child_end) {
//
//			/*! Increment before erase. Apparently erasing an edge invalidates the vertex iterators in VS.
//			  something is going on inside boost that I don't know yet. Or VS is just being VS as ususal.
//			  (the edge container is in fact a set, but that should matter only if we iterate over ages.
//			  well apparently not :) )*/
//			curr_grand_child_iter = grand_child_iter;
//			++grand_child_iter;
//
//			boost::add_edge(parent_id, *curr_grand_child_iter, sys_graph);
//            boost::remove_edge(child_id, *curr_grand_child_iter, sys_graph);
//
//		}
//
//
//        boost::remove_edge(parent_id, child_id, sys_graph);
//		// boost::clear_vertex(child_id, sys_graph);
//		boost::remove_vertex(child_id, sys_graph);
//
//    }
//
//};

struct cluster_none {
    static std::string name() { return "cluster_none"; }

    template <typename TaskSystemType>
    static void dump_graph(TaskSystemType& task_system, std::string suffix = "") {
        /*! No op*/
    }

    template <typename TaskSystemType>
    static void apply(TaskSystemType& task_system) {
        /*! No op. */
    }
};

struct cluster_merge_level_for_cost {
    static std::string name() { return "cluster_merge_level_for_cost"; }

    template <typename TaskSystemType>
    static void dump_graph(TaskSystemType& task_system, std::string suffix = "cluster_merge_level_for_cost") {
        task_system.dump_graphml(cluster_merge_level_for_cost::name() + "_" + suffix);
    }

    template <typename TaskSystemType>
    static void apply(TaskSystemType& task_system) {

        typedef typename TaskSystemType::GraphType     GraphType;
        typedef typename TaskSystemType::ClusterLevels ClusterLevels;
        typedef typename TaskSystemType::ClusterType   ClusterType;
        typedef typename TaskSystemType::ClusterIdType ClusterIdType;

        typedef typename ClusterLevels::value_type SameLevelClusterIdsType;

        ClusterLevels& clusters_by_level = task_system.clusters_by_level;
        GraphType&     sys_graph = task_system.sys_graph;

        int nr_of_clusters = 8;

        if (task_system.levels_valid == false)
            task_system.update_node_levels();

        typename ClusterLevels::iterator level_iter = clusters_by_level.begin();
        /*! Skip the first level. Which contains only the root node and some invlaidated clusters.*/
        ++level_iter;
        int level_number = 1;
        for (; level_iter != clusters_by_level.end(); ++level_iter, ++level_number) {
            SameLevelClusterIdsType& current_level = *level_iter;

            /*!Sort the level by cost so that we can pick the nodes that fits the gap easily*/
            // sort in decreasing order
            cluster_cost_comparator_by_id<GraphType> cccbi(sys_graph);
            std::sort(current_level.rbegin(), current_level.rend(), cccbi);

            double target_cost = current_level.total_level_cost / nr_of_clusters;
            if (target_cost < sys_graph[current_level.front()].cost) {
                target_cost = sys_graph[current_level.front()].cost;
            }

            target_cost = std::max(target_cost, 0.0);

            int                                        cluster_count = 0;
            typename SameLevelClusterIdsType::iterator clustid_iter = current_level.begin();

            /*! Cluster in to 'n' groups. Anything that doesn't fit in the target cost is handled in the
              next for loop. DO NOT modify the iterator if you are not sure.*/
            for (; clustid_iter != current_level.end() && cluster_count < nr_of_clusters; ++clustid_iter) {
                ClusterIdType& curr_clust_id = *clustid_iter;
                ClusterType&   curr_clust = sys_graph[curr_clust_id];

                /*! cluster is valid*/
                ++cluster_count;

                double gap = target_cost - curr_clust.cost;
                if (gap == 0) {
                    continue;
                }

                typename SameLevelClusterIdsType::iterator othersid_iter = clustid_iter;

                /*! start from the next node.*/
                ++othersid_iter;
                while (othersid_iter != current_level.end()) {
                    ClusterIdType& other_clust_id = *othersid_iter;
                    ClusterType&   other_clust = sys_graph[other_clust_id];

                    if (other_clust.cost <= gap) {
                        gap = gap - other_clust.cost;
                        task_system.concat_same_level_clusters(curr_clust_id, other_clust_id);
                        othersid_iter = current_level.erase(othersid_iter);
                    }
                    else {
                        ++othersid_iter;
                    }
                }
            }

            typename SameLevelClusterIdsType::iterator remaining_iter, smallest_clust_iter;
            while (clustid_iter != current_level.end()) {
                smallest_clust_iter =
                    std::min_element(current_level.begin(), current_level.begin() + nr_of_clusters, cccbi);
                task_system.concat_same_level_clusters(*smallest_clust_iter, *clustid_iter);
                clustid_iter = current_level.erase(clustid_iter);
            }
        }

        task_system.levels_valid = false;
    }
};

struct cluster_merge_level_for_bins {
    static std::string name() { return "cluster_merge_level_for_bins"; }

    template <typename TaskSystemType>
    static void dump_graph(TaskSystemType& task_system, std::string suffix = "cluster_merge_level_for_bins") {
        task_system.dump_graphml(cluster_merge_level_for_bins::name() + "_" + suffix);
    }

    template <typename TaskSystemType>
    static void apply(TaskSystemType& task_system) {

        typedef typename TaskSystemType::GraphType     GraphType;
        typedef typename TaskSystemType::ClusterLevels ClusterLevels;
        // typedef typename TaskSystemType::ClusterType ClusterType;
        // typedef typename TaskSystemType::ClusterIdType ClusterIdType;

        typedef typename ClusterLevels::value_type SameLevelClusterIdsType;

        ClusterLevels& clusters_by_level = task_system.clusters_by_level;
        GraphType&     sys_graph = task_system.sys_graph;

        /*! Decouple the per-level cluster count from the raw core count.
            Using max_num_threads*2 means a many-core machine fragments every
            level into many tiny clusters, so TBB's per-node scheduling overhead
            dominates the (small) per-cluster work and the parallel run ends up
            slower than serial. We cap the number of clusters per level at a
            fixed, tunable bound so clusters stay coarse regardless of core
            count; the TBB flow graph still load-balances them across all
            threads. Override with the parmodClustersPerLevel flag (or the
            PARMOD_CLUSTERS_PER_LEVEL env var), resolved by parmod_config(). */
        unsigned cluster_cap = 8;
        int      configured_cap = parmod_config().clusters_per_level;
        if (configured_cap > 0)
            cluster_cap = (unsigned)configured_cap;
        unsigned nr_of_clusters = std::min((unsigned)(task_system.max_num_threads * 2), cluster_cap);
        if (nr_of_clusters < 1)
            nr_of_clusters = 1;

        if (task_system.levels_valid == false)
            task_system.update_node_levels();

        typename ClusterLevels::iterator level_iter = clusters_by_level.begin();
        /*! Skip the first level. Which contains only the root node and some invlaidated clusters.*/
        ++level_iter;
        int level_number = 1;
        for (; level_iter != clusters_by_level.end(); ++level_iter, ++level_number) {
            SameLevelClusterIdsType& current_level = *level_iter;

            if (current_level.size() <= nr_of_clusters)
                continue;

            /*!Sort the level by cost so that we can pick the nodes that fits the gap easily*/
            // sort in decreasing order
            cluster_cost_comparator_by_id<GraphType> cccbi(sys_graph);
            std::sort(current_level.rbegin(), current_level.rend(), cccbi);

            // std::cout << "current level {";
            // for(auto& c: current_level)
            // std::cout << sys_graph[c].cost << ",";
            // std::cout << "}" << std::endl;

            typename SameLevelClusterIdsType::iterator smallest_clust_iter, clustid_iter, end_of_accepted;

            // Accept the first n clusters as merged tasks
            end_of_accepted = current_level.begin();
            std::advance(end_of_accepted, nr_of_clusters);
            // std::cout << "will start at: " << std::distance(current_level.begin(), end_of_accepted) << ": "<<
            // sys_graph[*end_of_accepted].cost << std::endl;

            // iterate through the rest and merge with the smallest currently
            clustid_iter = end_of_accepted;
            while (clustid_iter != current_level.end()) {
                // std::cout << "current level {";
                // for(auto& c: current_level)
                // std::cout << sys_graph[c].cost << ",";
                // std::cout << "}" << std::endl;

                smallest_clust_iter = std::min_element(current_level.begin(), end_of_accepted, cccbi);
                // std::cout << "smallest is " << std::distance(current_level.begin(), smallest_clust_iter) << ": "<<
                // sys_graph[*smallest_clust_iter].cost << std::endl;
                task_system.concat_same_level_clusters(*smallest_clust_iter, *clustid_iter);
                clustid_iter = current_level.erase(clustid_iter);
            }

            // std::cout << "current level {";
            // for(auto& c: current_level)
            // std::cout << sys_graph[c].cost << ",";
            // std::cout << "}" << std::endl;
        }

        task_system.levels_valid = false;
    }
};

/*! FixedWidthMinHeight clustering.

    Cluster the task nodes of every level into a fixed number of lanes equal to
    the number of available CPU cores, then minimize the height of the resulting
    layered graph (the longest root->leaf path, summed over cluster costs) so the
    longest computation path is as short as possible.

    Each task's estimated cost is its node out-degree. The height of the graph is
    the sum of the cost of the clusters along a path from the root to the leaves.
    To minimize it we repeatedly take the longest path, move a task off the
    heaviest cluster on that path into a lighter cluster (lane) at the same level,
    and keep the move only while it strictly reduces the height; we stop at the
    fixpoint where no move helps.

    The optimization runs on auxiliary per-node arrays (lane assignment) and only
    afterwards realizes the chosen lanes on the boost graph via
    concat_same_level_clusters. Moving a task between lanes of the same level keeps
    every dependency edge pointing to a strictly higher level, so the cluster graph
    stays acyclic (verified below). */
struct cluster_fixed_width_min_height {
    static std::string name() { return "cluster_fixed_width_min_height"; }

    template <typename TaskSystemType>
    static void dump_graph(TaskSystemType& task_system, std::string suffix = "cluster_fixed_width_min_height") {
        task_system.dump_graphml(cluster_fixed_width_min_height::name() + "_" + suffix);
    }

    template <typename TaskSystemType>
    static void apply(TaskSystemType& task_system) {

        typedef typename TaskSystemType::GraphType          GraphType;
        typedef typename TaskSystemType::ClusterIdType      ClusterIdType;
        typedef typename TaskSystemType::vertex_iterator    vertex_iterator;
        typedef typename TaskSystemType::adjacency_iterator adjacency_iterator;

        GraphType& sys_graph = task_system.sys_graph;

        if (task_system.levels_valid == false)
            task_system.update_node_levels();

        /* ---- Phase A: build auxiliary arrays from the leveled single-task graph ---- */
        std::map<ClusterIdType, int> id_to_idx;
        std::vector<ClusterIdType>   vid;   // idx -> vertex id
        std::vector<int>             level; // idx -> level
        std::vector<double>          cost;  // idx -> out-degree cost (per the spec)

        const ClusterIdType root_id = task_system.root_node_id;

        vertex_iterator vert_iter, vert_end;
        boost::tie(vert_iter, vert_end) = vertices(sys_graph);
        for (; vert_iter != vert_end; ++vert_iter) {
            const ClusterIdType v = *vert_iter;
            if (v == root_id)
                continue;
            id_to_idx[v] = (int)vid.size();
            vid.push_back(v);
            level.push_back((int)sys_graph[v].level);
            cost.push_back((double)out_degree(v, sys_graph));
        }

        const int N = (int)vid.size();
        if (N == 0) {
            task_system.levels_valid = false;
            return;
        }

        std::vector<std::vector<int> > children(N);
        int                            max_level = 0;
        for (int i = 0; i < N; ++i) {
            max_level = std::max(max_level, level[i]);
            adjacency_iterator c_iter, c_end;
            boost::tie(c_iter, c_end) = adjacent_vertices(vid[i], sys_graph);
            for (; c_iter != c_end; ++c_iter) {
                typename std::map<ClusterIdType, int>::iterator it = id_to_idx.find(*c_iter);
                if (it != id_to_idx.end())
                    children[i].push_back(it->second);
            }
        }

        std::vector<std::vector<int> > nodes_by_level(max_level + 1);
        for (int i = 0; i < N; ++i)
            nodes_by_level[level[i]].push_back(i);

        /* Required cycle check: every dependency edge must go to a strictly higher
           level. If so, grouping nodes by (level, lane) can never form a cycle. */
        for (int i = 0; i < N; ++i)
            for (size_t e = 0; e < children[i].size(); ++e)
                if (level[children[i][e]] <= level[i]) {
                    std::cerr << "cluster_fixed_width_min_height: non-forward edge "
                              << level[i] << " -> " << level[children[i][e]]
                              << " would create a cycle; skipping clustering." << std::endl;
                    task_system.levels_valid = false;
                    return;
                }

        int K = (int)task_system.max_num_threads;
        if (K < 1)
            K = 1;

        /* ---- Phase B: initial fixed-width partition per level (LPT load balance) ---- */
        std::vector<int> lane(N, 0);
        for (int L = 1; L <= max_level; ++L) {
            std::vector<int>& level_nodes = nodes_by_level[L];
            if (level_nodes.empty())
                continue;
            const int width = std::min((int)level_nodes.size(), K);
            std::sort(level_nodes.begin(), level_nodes.end(),
                      [&](int a, int b) { return cost[a] > cost[b]; });
            std::vector<double> lane_load(width, 0.0);
            for (size_t t = 0; t < level_nodes.size(); ++t) {
                const int n = level_nodes[t];
                int       best = 0;
                for (int l = 1; l < width; ++l)
                    if (lane_load[l] < lane_load[best])
                        best = l;
                lane[n] = best;
                lane_load[best] += cost[n];
            }
        }

        /* ---- Phase C: minimize the height by moving tasks between same-level lanes ---- */
        const int LANES = K;
        auto      cid_of = [&](int i) { return level[i] * LANES + lane[i]; };

        /* Returns the height and, via out-params, the cluster on the critical path
           that is heaviest plus that cluster's (level, lane). */
        auto analyze = [&](int& hot_level, int& hot_lane) -> double {
            std::map<int, double> ccost;
            for (int i = 0; i < N; ++i)
                ccost[cid_of(i)] += cost[i];

            std::map<int, std::set<int> > preds; // cluster -> predecessor clusters
            for (int i = 0; i < N; ++i) {
                const int ci = cid_of(i);
                for (size_t e = 0; e < children[i].size(); ++e) {
                    const int cj = cid_of(children[i][e]);
                    if (ci != cj)
                        preds[cj].insert(ci);
                }
            }

            std::vector<int> cids;
            cids.reserve(ccost.size());
            for (std::map<int, double>::iterator it = ccost.begin(); it != ccost.end(); ++it)
                cids.push_back(it->first);
            /* process in increasing level order (cid = level*LANES + lane) */
            std::sort(cids.begin(), cids.end(), [&](int a, int b) { return (a / LANES) < (b / LANES); });

            std::map<int, double> dp;
            std::map<int, int>    par;
            double                height = 0;
            int                   end_c = -1;
            for (size_t k = 0; k < cids.size(); ++k) {
                const int c = cids[k];
                double    best_pred = 0;
                int       best_pc = -1;
                std::map<int, std::set<int> >::iterator pit = preds.find(c);
                if (pit != preds.end())
                    for (std::set<int>::iterator p = pit->second.begin(); p != pit->second.end(); ++p)
                        if (dp[*p] > best_pred) {
                            best_pred = dp[*p];
                            best_pc = *p;
                        }
                dp[c] = best_pred + ccost[c];
                par[c] = best_pc;
                if (dp[c] > height) {
                    height = dp[c];
                    end_c = c;
                }
            }

            /* walk back the critical path and pick its heaviest cluster */
            hot_level = -1;
            hot_lane = -1;
            double hot_cost = -1;
            for (int c = end_c; c != -1; c = par[c])
                if (ccost[c] > hot_cost) {
                    hot_cost = ccost[c];
                    hot_level = c / LANES;
                    hot_lane = c % LANES;
                }
            return height;
        };

        const long max_evals = 20000; /* safety budget on analyze() calls */
        long       evals = 0;
        while (evals < max_evals) {
            int    hot_level = -1, hot_lane = -1;
            double height = analyze(hot_level, hot_lane);
            ++evals;
            if (hot_level < 1)
                break;

            std::vector<int>& level_nodes = nodes_by_level[hot_level];
            const int         width = std::min((int)level_nodes.size(), K);
            if (width <= 1)
                break; /* nothing to move into at this level */

            /* lightest lane at this level that is not the hot lane */
            std::vector<double> lane_load(width, 0.0);
            for (size_t t = 0; t < level_nodes.size(); ++t)
                lane_load[lane[level_nodes[t]]] += cost[level_nodes[t]];
            int target = -1;
            for (int l = 0; l < width; ++l)
                if (l != hot_lane && (target < 0 || lane_load[l] < lane_load[target]))
                    target = l;
            if (target < 0)
                break;

            /* try moving each task of the hot cluster (heaviest first) to the target
               lane; keep the first move that strictly reduces the height. */
            std::vector<int> hot_nodes;
            for (size_t t = 0; t < level_nodes.size(); ++t)
                if (lane[level_nodes[t]] == hot_lane)
                    hot_nodes.push_back(level_nodes[t]);
            std::sort(hot_nodes.begin(), hot_nodes.end(), [&](int a, int b) { return cost[a] > cost[b]; });

            bool improved = false;
            for (size_t h = 0; h < hot_nodes.size() && evals < max_evals; ++h) {
                const int n = hot_nodes[h];
                const int old_lane = lane[n];
                lane[n] = target;
                int    dummy_l, dummy_w;
                double new_height = analyze(dummy_l, dummy_w);
                ++evals;
                if (new_height < height) {
                    improved = true; /* commit: leave lane[n] == target */
                    break;
                }
                lane[n] = old_lane; /* revert */
            }
            if (!improved)
                break; /* fixpoint */
        }

        /* ---- Phase D: realize the lanes on the boost graph ---- */
        for (int L = 1; L <= max_level; ++L) {
            std::vector<int>& level_nodes = nodes_by_level[L];
            const int         width = std::min((int)level_nodes.size(), K);
            for (int target_lane = 0; target_lane < width; ++target_lane) {
                ClusterIdType rep = ClusterIdType();
                bool          have_rep = false;
                for (size_t t = 0; t < level_nodes.size(); ++t) {
                    const int n = level_nodes[t];
                    if (lane[n] != target_lane)
                        continue;
                    if (!have_rep) {
                        rep = vid[n];
                        have_rep = true;
                    }
                    else {
                        task_system.concat_same_level_clusters(rep, vid[n]);
                    }
                }
                /* Record the real lane (core) this cluster was assigned to, so it
                   can be exported (collect_clusters_json) and the schedule lanes
                   visualized as-computed instead of reconstructed. The lane index
                   is consistent across levels: lane l is the l-th worker lane. */
                if (have_rep)
                    task_system.sys_graph[rep].lane = target_lane;
            }
        }

        task_system.levels_valid = false;
    }
};

struct cluster_merge_common {
    static std::string name() { return "cluster_merge_common"; }

    template <typename TaskSystemType>
    static void dump_graph(TaskSystemType& task_system, std::string suffix = "cluster_merge_common") {
        task_system.dump_graphml(cluster_merge_common::name() + "_" + suffix);
    }

    template <typename TaskSystemType>
    static int concat_children_recursive(TaskSystemType&                               task_system,
                                         const typename TaskSystemType::ClusterIdType& curr_clust_id) {

        typedef typename TaskSystemType::GraphType          GraphType;
        typedef typename TaskSystemType::ClusterType        ClusterType;
        typedef typename TaskSystemType::ClusterIdType      ClusterIdType;
        typedef typename TaskSystemType::adjacency_iterator adjacency_iterator;
        // typedef typename TaskSystemType::out_edge_iterator out_edge_iterator;

        GraphType& sys_graph = task_system.sys_graph;

        ClusterType& curr_clust = sys_graph[curr_clust_id];

        double target_cost = 20;

        int                nr_of_parents;
        adjacency_iterator child_iter, child_end, next_child_iter;
        boost::tie(child_iter, child_end) = adjacent_vertices(curr_clust_id, sys_graph);

        std::vector<ClusterIdType> child_ids;
        for (; child_iter != child_end; ++child_iter) {
            const ClusterIdType& curr_child_id = *child_iter;

            nr_of_parents = in_degree(curr_child_id, sys_graph);
            if (nr_of_parents == 1)
                child_ids.push_back(curr_child_id);
        }

        // sort in decreasing order
        cluster_cost_comparator_by_id<GraphType> cccbi(sys_graph);
        std::sort(child_ids.rbegin(), child_ids.rend(), cccbi);

        typename std::vector<ClusterIdType>::iterator id_iter = child_ids.begin();
        for (; id_iter != child_ids.end(); ++id_iter) {
            const ClusterIdType& curr_child_id = *id_iter;
            ClusterType&         curr_child = sys_graph[curr_child_id];

            double gap = target_cost - curr_child.cost;
            if (gap < 0.005) {
                continue;
            }

            typename std::vector<ClusterIdType>::iterator othersid_iter = id_iter;
            /*! start from the next node.*/
            ++othersid_iter;
            while (othersid_iter != child_ids.end()) {
                ClusterIdType& other_child_id = *othersid_iter;
                ClusterType&   other_child = sys_graph[other_child_id];

                if (other_child.cost <= gap) {
                    gap = gap - other_child.cost;
                    task_system.concat_same_level_clusters(curr_child_id, other_child_id);
                    othersid_iter = child_ids.erase(othersid_iter);
                }
                else {
                    ++othersid_iter;
                }
            }
        }

        adjacency_iterator curr_child_iter;
        boost::tie(child_iter, child_end) = adjacent_vertices(curr_clust_id, sys_graph);
        while (child_iter != child_end) {

            /*! Increment before concat. Apparently erasing an edge invalidates the vertex iterators in VS.
              something is going on inside boost that I don't know yet. Or VS is just being VS as ususal.
              (the edge container is in fact a set, but that should matter only if we iterate over ages.
              well apparently not :) )*/
            curr_child_iter = child_iter;
            ++child_iter;

            const ClusterIdType& curr_child_id = *curr_child_iter;
            ClusterType&         curr_child = sys_graph[curr_child_id];

            nr_of_parents = concat_children_recursive(task_system, curr_child_id);
            if (nr_of_parents == 1) {
                if (curr_clust.cost + curr_child.cost < target_cost) {
                    task_system.concat_with_parent(curr_clust_id, curr_child_id);
                }
            }
        }

        return in_degree(curr_clust_id, sys_graph);
    }

    template <typename TaskSystemType>
    static void apply(TaskSystemType& task_system) {

        typedef typename TaskSystemType::GraphType          GraphType;
        typedef typename TaskSystemType::ClusterIdType      ClusterIdType;
        typedef typename TaskSystemType::adjacency_iterator adjacency_iterator;

        GraphType&           sys_graph = task_system.sys_graph;
        const ClusterIdType& root_node_id = task_system.root_node_id;

        adjacency_iterator child_iter, child_end;
        boost::tie(child_iter, child_end) = adjacent_vertices(root_node_id, sys_graph);

        for (; child_iter != child_end; ++child_iter) {
            const ClusterIdType& curr_child_id = *child_iter;
            concat_children_recursive(task_system, curr_child_id);
        }

        task_system.levels_valid = false;
    }
};

struct cluster_merge_single_parent {
    static std::string name() { return "cluster_merge_single_parent"; }

    template <typename TaskSystemType>
    static void dump_graph(TaskSystemType& task_system, std::string suffix = "cluster_merge_single_parent") {
        task_system.dump_graphml(cluster_merge_single_parent::name() + "_" + suffix);
    }

    template <typename TaskSystemType>
    static void apply(TaskSystemType& task_system) {

        typedef typename TaskSystemType::GraphType          GraphType;
        typedef typename TaskSystemType::ClusterType        ClusterType;
        typedef typename TaskSystemType::ClusterIdType      ClusterIdType;
        typedef typename TaskSystemType::vertex_iterator    vertex_iterator;
        typedef typename TaskSystemType::adjacency_iterator adjacency_iterator;

        GraphType& sys_graph = task_system.sys_graph;

        vertex_iterator vert_iter, vert_end;
        boost::tie(vert_iter, vert_end) = vertices(sys_graph);
        /*! skip the root node. */
        ++vert_iter;
        for (; vert_iter != vert_end; ++vert_iter) {
            const ClusterIdType& curr_clust_id = *vert_iter;
            ClusterType&         curr_clust = sys_graph[curr_clust_id];

            if (!curr_clust.is_valid()) {
                continue;
            }

            adjacency_iterator child_iter, child_end, curr_child_iter;
            boost::tie(child_iter, child_end) = adjacent_vertices(curr_clust_id, sys_graph);
            while (child_iter != child_end) {
                /*! Increment before concat. Apparently erasing an edge invalidates the vertex iterators in VS.
                  something is going on inside boost that I don't know yet. Or VS is just being VS as ususal.
                  (the edge container is in fact a set, but that should matter only if we iterate over ages.
                  well apparently not :) )*/
                curr_child_iter = child_iter;
                ++child_iter;

                const ClusterIdType& curr_child_id = *curr_child_iter;
                // ClusterType& curr_child = sys_graph[curr_child_id];

                int nr_parents = in_degree(curr_child_id, sys_graph);
                if (nr_parents == 1) {
                    task_system.concat_with_parent(curr_clust_id, curr_child_id);
                }
            }
        }

        task_system.levels_valid = false;
    }
};

struct cluster_merge_level_parents {
    static std::string name() { return "cluster_merge_level_parents"; }

    template <typename TaskSystemType>
    static void dump_graph(TaskSystemType& task_system, std::string suffix = "cluster_merge_level_parents") {
        task_system.dump_graphml(cluster_merge_level_parents::name() + "_" + suffix);
    }

    template <typename TaskSystemType>
    static void apply(TaskSystemType& task_system) {

        typedef typename TaskSystemType::GraphType              GraphType;
        typedef typename TaskSystemType::ClusterLevels          ClusterLevels;
        typedef typename TaskSystemType::ClusterType            ClusterType;
        typedef typename TaskSystemType::ClusterIdType          ClusterIdType;
        typedef typename TaskSystemType::inv_adjacency_iterator inv_adjacency_iterator;
        typedef typename ClusterLevels::value_type              SameLevelClusterIdsType;

        GraphType&     sys_graph = task_system.sys_graph;
        ClusterLevels& clusters_by_level = task_system.clusters_by_level;

        if (task_system.levels_valid == false)
            task_system.update_node_levels();

        typename ClusterLevels::iterator level_iter = clusters_by_level.begin();
        /*! Skip the first level. Which contains only the root node and some invlaidated clusters.*/
        ++level_iter;
        /*! Skip the second level as well. All nodes here have root as parent.*/
        ++level_iter;

        int level_number = 2;
        for (; level_iter != clusters_by_level.end(); ++level_iter, ++level_number) {
            SameLevelClusterIdsType& current_level = *level_iter;

            typename SameLevelClusterIdsType::iterator clustid_iter = current_level.begin();
            for (; clustid_iter != current_level.end(); ++clustid_iter) {
                ClusterIdType& curr_clust_id = *clustid_iter;
                ClusterType&   curr_clust = sys_graph[curr_clust_id];

                if (!curr_clust.is_valid()) {
                    continue;
                }

                if (in_degree(curr_clust_id, sys_graph) == 1) {
                    continue;
                }

                std::vector<ClusterIdType> parent_ids;
                inv_adjacency_iterator     parent_iter, parent_end;
                boost::tie(parent_iter, parent_end) = inv_adjacent_vertices(curr_clust_id, sys_graph);
                const ClusterIdType& main_parent_id = *parent_iter;
                ClusterType&         main_parent = sys_graph[main_parent_id];

                /*! start from the second parent.*/
                parent_iter++;
                for (; parent_iter != parent_end; ++parent_iter) {
                    const ClusterIdType& other_parent_id = *parent_iter;
                    ClusterType&         other_parent = sys_graph[other_parent_id];
                    /*! Don't merge different level parents for now.*/
                    if (other_parent.level == main_parent.level)
                        parent_ids.push_back(*parent_iter);
                }

                typename std::vector<ClusterIdType>::iterator id_iter;
                for (id_iter = parent_ids.begin(); id_iter != parent_ids.end(); ++id_iter) {
                    task_system.concat_same_level_clusters(main_parent_id, *id_iter);
                }
            }
        }

        task_system.levels_valid = false;
    }
};

struct cluster_merge_connected_for_cost {
    static std::string name() { return "cluster_merge_connected_for_cost"; }

    template <typename TaskSystemType>
    static void dump_graph(TaskSystemType& task_system, std::string suffix = "cluster_merge_connected_for_cost") {
        task_system.dump_graphml(cluster_merge_connected_for_cost::name() + "_" + suffix);
    }

    template <typename TaskSystemType>
    static void find_connected(TaskSystemType& task_system, const typename TaskSystemType::ClusterIdType& curr_clust_id,
                               std::list<typename TaskSystemType::ClusterIdType>& connected_comps,
                               int                                                nr_of_connected) {

        typedef typename TaskSystemType::GraphType              GraphType;
        typedef typename TaskSystemType::ClusterType            ClusterType;
        typedef typename TaskSystemType::ClusterIdType          ClusterIdType;
        typedef typename TaskSystemType::inv_adjacency_iterator inv_adjacency_iterator;
        typedef typename TaskSystemType::adjacency_iterator     adjacency_iterator;

        GraphType& sys_graph = task_system.sys_graph;

        ClusterType& curr_clust = sys_graph[curr_clust_id];
        if (!curr_clust.is_valid())
            return;

        inv_adjacency_iterator parent_iter, parent_end;
        boost::tie(parent_iter, parent_end) = inv_adjacent_vertices(curr_clust_id, sys_graph);

        for (; parent_iter != parent_end; ++parent_iter) {
            const ClusterIdType& curr_parent_id = *parent_iter;
            // ClusterType& curr_parent = sys_graph[curr_parent_id];

            find_connected(task_system, curr_parent_id, connected_comps, nr_of_connected);
        }

        if (curr_clust.group != 0)
            std::cout << "Already visited node " << curr_clust.index_list << std::endl;
        else {
            connected_comps.push_back(curr_clust_id);
            curr_clust.group = nr_of_connected;
            curr_clust.valid = false;
        }

        adjacency_iterator child_iter, child_end;
        boost::tie(child_iter, child_end) = adjacent_vertices(curr_clust_id, sys_graph);

        for (; child_iter != child_end; ++child_iter) {
            const ClusterIdType& curr_child_id = *child_iter;
            // ClusterType& curr_child = sys_graph[curr_child_id];

            find_connected(task_system, curr_child_id, connected_comps, nr_of_connected);
        }
    }

    template <typename TaskSystemType>
    static void apply(TaskSystemType& task_system) {

        typedef typename TaskSystemType::GraphType          GraphType;
        typedef typename TaskSystemType::ClusterType        ClusterType;
        typedef typename TaskSystemType::ClusterIdType      ClusterIdType;
        typedef typename TaskSystemType::adjacency_iterator adjacency_iterator;

        GraphType&     sys_graph = task_system.sys_graph;
        ClusterIdType& root_node_id = task_system.root_node_id;

        adjacency_iterator top_iter, top_end;
        boost::tie(top_iter, top_end) = adjacent_vertices(root_node_id, sys_graph);
        sys_graph[root_node_id].valid = false;

        std::vector<std::list<ClusterIdType>> connected_comps_list;
        int                                   nr_of_connected = 0;
        for (; top_iter != top_end; ++top_iter) {
            const ClusterIdType& curr_top_id = *top_iter;
            ClusterType&         curr_top = sys_graph[curr_top_id];

            if (!curr_top.is_valid())
                continue;

            curr_top.valid = false;
            ++nr_of_connected;

            connected_comps_list.push_back(std::list<ClusterIdType>());
            std::list<ClusterIdType>& connected_comps = connected_comps_list.back();
            connected_comps.push_back(curr_top_id);
            if (curr_top.group != 0)
                std::cout << "Top Already visited node " << curr_top.index_list << std::endl;

            curr_top.group = nr_of_connected;

            adjacency_iterator child_iter, child_end;
            boost::tie(child_iter, child_end) = adjacent_vertices(curr_top_id, sys_graph);

            for (; child_iter != child_end; ++child_iter) {
                const ClusterIdType& curr_child_id = *child_iter;
                // const ClusterType& curr_child = sys_graph[curr_child_id];

                find_connected(task_system, curr_child_id, connected_comps, nr_of_connected);
            }

            typename std::list<ClusterIdType>::iterator iter = connected_comps.begin();
            for (; iter != connected_comps.end(); ++iter) {
                const ClusterIdType& curr_clust_id = *iter;
                ClusterType&         curr_clust = sys_graph[curr_clust_id];
                // curr_clust.valid = true;

                std::cout << curr_clust.index_list << ", ";
            }
            std::cout << std::endl;
        }

        sys_graph[root_node_id].valid = true;

        double                                                   target_cost = 2000;
        typename std::vector<std::list<ClusterIdType>>::iterator list_iter;
        list_iter = connected_comps_list.begin();
        for (; list_iter != connected_comps_list.end(); ++list_iter) {
            std::list<ClusterIdType>&                   connected_comps = *list_iter;
            typename std::list<ClusterIdType>::iterator iter = connected_comps.begin();
            ClusterIdType                               main_clust_id = *iter;
            sys_graph[main_clust_id].valid = true;

            ++iter;
            long prev_level = sys_graph[main_clust_id].level;
            for (; iter != connected_comps.end(); ++iter) {
                const ClusterIdType& curr_clust_id = *iter;
                ClusterType&         curr_clust = sys_graph[curr_clust_id];
                curr_clust.valid = true;

                if ((sys_graph[main_clust_id].cost + curr_clust.cost <= target_cost) &&
                    (prev_level <= curr_clust.level)) {
                    std::cout << "Merging " << sys_graph[main_clust_id].index_list << " " << curr_clust.index_list
                              << std::endl;
                    prev_level = curr_clust.level;
                    concat_clusters::apply(task_system, main_clust_id, curr_clust_id);
                }
                else {
                    std::cout << "Chainging main " << sys_graph[main_clust_id].index_list << " "
                              << sys_graph[main_clust_id].level << " ";
                    std::cout << curr_clust.index_list << " " << curr_clust.level << " = "
                              << sys_graph[main_clust_id].cost + curr_clust.cost << std::endl;
                    main_clust_id = curr_clust_id;
                    prev_level = curr_clust.level;
                    std::cout << "New main " << sys_graph[main_clust_id].index_list << std::endl;
                }
            }
        }
        task_system.levels_valid = true;
        task_system.update_node_levels2();

        std::cout << "Done connected : " << connected_comps_list.size() << std::endl;
    }
};

}} // namespace openmodelica::parmodelica

#endif // header
