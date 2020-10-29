#pragma once
#ifndef id776A2949_F8C6_41C1_8E5205C1984621C1
#define id776A2949_F8C6_41C1_8E5205C1984621C1

/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */


/*
 Mahder.Gebremedhin@liu.se  2014-03-06
*/

#include <tbb/flow_graph.h>
#include <tbb/task_scheduler_init.h>

#include "pm_clustering.hpp"


namespace openmodelica {
namespace parmodelica {

template<typename TaskType>
struct ClusterLauncher {
    typedef TaskSystem_v2<TaskType> TaskSystemType;
    typedef typename TaskSystemType::ClusterType ClusterType;
private:
    ClusterType& clust;

public:
    ClusterLauncher(ClusterType& c)
      : clust(c)
    {}

    void operator()( tbb::flow::continue_msg ) const {
        clust.execute();
    }
};

template<typename TaskType>
class ClusterDynamicScheduler {
public:
    typedef TaskSystem_v2<TaskType> TaskSystemType;

    typedef typename TaskSystemType::GraphType GraphType;
    typedef typename TaskSystemType::ClusterType ClusterType;
    typedef typename TaskSystemType::ClusterIdType ClusterIdType;

    typedef typename TaskType::FunctionType FunctionType;

private:
    tbb::task_scheduler_init tbb_system;

    tbb::flow::graph dynamic_graph;
    tbb::flow::broadcast_node<tbb::flow::continue_msg> flow_root;

    bool flow_graph_created;


    std::map<ClusterIdType, tbb::flow::continue_node<tbb::flow::continue_msg>* > cluster_flow_id_map;

public:
    PMTimer execution_timer;
    PMTimer clustering_timer;
    TaskSystemType& task_system;

    int sequential_evaluations;
    int total_evaluations;
    int parallel_evaluations;

    ClusterDynamicScheduler(TaskSystemType& task_system)
        : tbb_system(NUM_THREADS)
        , flow_root(dynamic_graph)
        , flow_graph_created(false)
        , task_system(task_system)
    {
        sequential_evaluations = 0;
        parallel_evaluations =0;
        total_evaluations = 0;
    }

    void schedule() {
        // task_system.dump_graphml("original");
        clustering_timer.start_timer();
        // cluster_merge_common::apply(task_system);
        // cluster_merge_common::dump_graph(task_system);
        construct_flow_graph();
        clustering_timer.stop_timer();
    }

    void construct_flow_graph()
    {

        using namespace tbb;
        GraphType& sys_graph = task_system.sys_graph;
        ClusterIdType& root_node_id = task_system.root_node_id;

        typename GraphType::vertex_iterator vert_iter, vert_end;
        boost::tie(vert_iter, vert_end) = vertices(sys_graph);

        /*! skip the root node. */
        ++vert_iter;
        for ( ; vert_iter != vert_end; ++vert_iter) {
            ClusterIdType& curr_clust_id = *vert_iter;
            ClusterType& curr_clust = sys_graph[curr_clust_id];
            // std::cout << "adding " << curr_b_node.index << std::endl;

            /*! create new flow node for tbb. */
            flow::continue_node<flow::continue_msg>* curr_f_node =
                    new flow::continue_node<flow::continue_msg>(dynamic_graph,
                        ClusterLauncher<TaskType>(curr_clust));

            /*! create a maping. we use it to add edges from this node to its children later. */
            cluster_flow_id_map.insert(std::make_pair(curr_clust_id,curr_f_node));

            /*! Iterate through all parents of the current node and add edges.*/
            typename GraphType::inv_adjacency_iterator par_iter, par_end;
            boost::tie(par_iter, par_end) = inv_adjacent_vertices( curr_clust_id, sys_graph );
            for(; par_iter != par_end; ++par_iter) {
                const ClusterIdType& curr_parent_id = *par_iter;
                // ClusterType& curr_parent = sys_graph[curr_parent_id];
                /*! the parent is the root in the task_graph. So here connect it to
                  the root of the flow graph*/
                if(curr_parent_id == root_node_id) {
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

        if(!flow_graph_created) {
            schedule();
        }

        execution_timer.start_timer();
        flow_root.try_put( tbb::flow::continue_msg() );
        dynamic_graph.wait_for_all();
        execution_timer.stop_timer();

        total_evaluations++;
        parallel_evaluations++;
    }

};



} // parmodelica
} // openmodelica




#endif // header
