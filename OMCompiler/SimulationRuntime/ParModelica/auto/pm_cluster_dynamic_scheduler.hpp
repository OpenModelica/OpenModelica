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
#ifndef id776A2949_F8C6_41C1_8E5205C1984621C1
#define id776A2949_F8C6_41C1_8E5205C1984621C1

/*
 Mahder.Gebremedhin@liu.se  2014-03-06
*/

#include <tbb/flow_graph.h>
#include "pm_clustering.hpp"

namespace openmodelica { namespace parmodelica {

template <typename TaskType>
struct ClusterLauncher {
    typedef TaskSystem_v2<TaskType>              TaskSystemType;
    typedef typename TaskSystemType::ClusterType ClusterType;

  private:
    ClusterType& clust;

  public:
    ClusterLauncher(ClusterType& c) : clust(c) {}

    void operator()(tbb::flow::continue_msg) const { clust.execute(); }
};

template <typename TaskType>
class ClusterDynamicScheduler {
  public:
    typedef TaskSystem_v2<TaskType> TaskSystemType;

    typedef typename TaskSystemType::GraphType     GraphType;
    typedef typename TaskSystemType::ClusterType   ClusterType;
    typedef typename TaskSystemType::ClusterIdType ClusterIdType;

    typedef typename TaskType::FunctionType FunctionType;

  private:

    size_t max_num_threads;

    tbb::flow::graph                                   dynamic_graph;
    tbb::flow::broadcast_node<tbb::flow::continue_msg> flow_root;

    bool flow_graph_created;

    std::map<ClusterIdType, tbb::flow::continue_node<tbb::flow::continue_msg>*> cluster_flow_id_map;

  public:
    PMTimer         execution_timer;
    PMTimer         clustering_timer;
    TaskSystemType& task_system;

    int sequential_evaluations;
    int total_evaluations;
    int parallel_evaluations;

    ClusterDynamicScheduler(TaskSystemType& task_system, size_t mnt)
        : max_num_threads(mnt)
        , flow_root(dynamic_graph)
        , flow_graph_created(false)
        , task_system(task_system) {
        sequential_evaluations = 0;
        parallel_evaluations = 0;
        total_evaluations = 0;
    }

    /*! Measure the cost of every individual task (equation) by executing each
        one once and timing it. The clustering passes below need these costs to
        balance work; without them every task has cost 0 and clustering becomes
        a no-op, leaving one fine-grained flow node per equation. */
    void profile_execute() {
        GraphType& sys_graph = task_system.sys_graph;

        typename GraphType::vertex_iterator vert_iter, vert_end;
        boost::tie(vert_iter, vert_end) = vertices(sys_graph);
        /*! skip the root node. */
        ++vert_iter;
        for (; vert_iter != vert_end; ++vert_iter) {
            sys_graph[*vert_iter].profile_execute();
        }

        ++sequential_evaluations;
        ++total_evaluations;
    }

    void schedule() {
        // task_system.dump_graphml("original");
        clustering_timer.start_timer();

        /*! A couple of untimed warm-up evaluations so the profiled costs are
            not skewed by cold caches / first-touch page faults. */
        {
            GraphType& sys_graph = task_system.sys_graph;
            typename GraphType::vertex_iterator vert_iter, vert_end;
            for (int warmup = 0; warmup < 2; ++warmup) {
                boost::tie(vert_iter, vert_end) = vertices(sys_graph);
                ++vert_iter; /*! skip the root node. */
                for (; vert_iter != vert_end; ++vert_iter)
                    sys_graph[*vert_iter].execute();
            }
        }

        /*! Profile per-equation cost, then merge tasks into coarser clusters so
            that TBB's per-node scheduling overhead is amortized over real work.
            First collapse single-parent chains, then bin each level down to
            ~2*max_num_threads balanced clusters. */
        profile_execute();

        if (task_system.levels_valid == false)
            task_system.update_node_levels();

        cluster_merge_common::apply(task_system);
        cluster_merge_level_for_bins::apply(task_system);

        task_system.levels_valid = false;
        task_system.update_node_levels();

        construct_flow_graph();
        clustering_timer.stop_timer();
    }

    void construct_flow_graph() {

        using namespace tbb;
        GraphType&     sys_graph = task_system.sys_graph;
        ClusterIdType& root_node_id = task_system.root_node_id;

        typename GraphType::vertex_iterator vert_iter, vert_end;

        /*! First pass: create a flow node for every cluster and record it in the
            map. We can not create edges in the same pass because clustering may
            have reordered the vertices so that a parent no longer precedes its
            child in the vertex list; looking it up before it exists would throw
            std::out_of_range. */
        boost::tie(vert_iter, vert_end) = vertices(sys_graph);
        /*! skip the root node. */
        ++vert_iter;
        for (; vert_iter != vert_end; ++vert_iter) {
            ClusterIdType& curr_clust_id = *vert_iter;
            ClusterType&   curr_clust = sys_graph[curr_clust_id];

            /*! create new flow node for tbb. */
            flow::continue_node<flow::continue_msg>* curr_f_node =
                new flow::continue_node<flow::continue_msg>(dynamic_graph, ClusterLauncher<TaskType>(curr_clust));

            /*! create a maping. we use it to add edges between nodes below. */
            cluster_flow_id_map.insert(std::make_pair(curr_clust_id, curr_f_node));
        }

        /*! Second pass: now that every node exists in the map, wire the edges. */
        boost::tie(vert_iter, vert_end) = vertices(sys_graph);
        /*! skip the root node. */
        ++vert_iter;
        for (; vert_iter != vert_end; ++vert_iter) {
            ClusterIdType& curr_clust_id = *vert_iter;
            flow::continue_node<flow::continue_msg>* curr_f_node = cluster_flow_id_map.at(curr_clust_id);

            /*! Iterate through all parents of the current node and add edges.*/
            typename GraphType::inv_adjacency_iterator par_iter, par_end;
            boost::tie(par_iter, par_end) = inv_adjacent_vertices(curr_clust_id, sys_graph);
            for (; par_iter != par_end; ++par_iter) {
                const ClusterIdType& curr_parent_id = *par_iter;
                // ClusterType& curr_parent = sys_graph[curr_parent_id];
                /*! the parent is the root in the task_graph. So here connect it to
                  the root of the flow graph*/
                if (curr_parent_id == root_node_id) {
                    flow::make_edge(flow_root, *curr_f_node);
                    // std::cout << "   edge to root " << std::endl;
                }
                else {
                    flow::make_edge(*(cluster_flow_id_map.at(curr_parent_id)), *curr_f_node);
                    // std::cout << "   edge to " << sys_graph[*par_iter].index << std::endl;
                }
            }
        }

        flow_graph_created = true;
    }

    void execute() {

        if (!flow_graph_created) {
            schedule();
        }

        execution_timer.start_timer();
        flow_root.try_put(tbb::flow::continue_msg());
        dynamic_graph.wait_for_all();
        execution_timer.stop_timer();

        total_evaluations++;
        parallel_evaluations++;
    }
};

}} // namespace openmodelica::parmodelica

#endif // header
