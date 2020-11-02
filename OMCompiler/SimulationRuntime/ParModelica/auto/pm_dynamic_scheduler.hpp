#pragma once
#ifndef id7426C38B_09FD_4530_95712AEE15226ED9
#define id7426C38B_09FD_4530_95712AEE15226ED9

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

#include "pm_task_system.hpp"

namespace openmodelica { namespace parmodelica {

template <typename TaskTypeT>
struct TaskLauncher {
    typedef TaskTypeT                       TaskType;
    typedef typename TaskType::FunctionType FunctionType;

  private:
    /*! These refere to the dynamic schedulers funcs and data.
      This is to allow setting up the data and funcs after scheduling by
      DynamicScheduler::scheduler(). */
    long           task_id;
    FunctionType** function_systems;
    void**         data;

  public:
    TaskLauncher(long id, FunctionType** f, void** d) : task_id(id), function_systems(f), data(d) {}

    void operator()(tbb::flow::continue_msg) const { (*function_systems)[task_id](*data); }
};

template <typename TaskTypeT>
class DynamicScheduler {
  public:
    typedef TaskTypeT                             TaskType;
    typedef typename TaskSystem<TaskTypeT>::Graph GraphType;
    typedef typename TaskSystem<TaskTypeT>::Node  NodeIdType;

    typedef typename TaskType::FunctionType FunctionType;

  private:
    bool is_set_up_;

    FunctionType* function_systems;
    void*         data;

    tbb::flow::graph                                                dynamic_graph;
    tbb::flow::broadcast_node<tbb::flow::continue_msg>              flow_root;
    std::vector<tbb::flow::continue_node<tbb::flow::continue_msg>*> fnode_ps;

  public:
    PMTimer                execution_timer;
    TaskSystem<TaskTypeT>& task_system;

    DynamicScheduler(TaskSystem<TaskTypeT>& task_system) : flow_root(dynamic_graph), task_system(task_system) {
        is_set_up_ = false;
    }

    void set_up_executor(FunctionType* f, void* d) {
        function_systems = f;
        data = d;
        is_set_up_ = true;
    }

    bool is_set_up() { return is_set_up_; }

    void schedule(int number_of_processors) {
        using namespace tbb;
        GraphType& b_graph = task_system.graph;

        typename GraphType::vertex_iterator vert_iter, vert_end;
        boost::tie(vert_iter, vert_end) = vertices(b_graph);

        /*! skip the root node. */
        ++vert_iter;
        for (; vert_iter != vert_end; ++vert_iter) {
            TaskTypeT& curr_b_node = b_graph[*vert_iter];
            // std::cout << "adding " << curr_b_node.index << std::endl;

            /*! create new flow node for tbb. */
            flow::continue_node<flow::continue_msg>* curr_f_node = new flow::continue_node<flow::continue_msg>(
                dynamic_graph, TaskLauncher<TaskType>(curr_b_node.node_id, &function_systems, &data));

            /*! store the node pointer. we use to add edges from it's children later. */
            fnode_ps.push_back(curr_f_node);

            /*! Iterate through all parents of the current node and add edges.*/
            typename GraphType::inv_adjacency_iterator par_iter, par_end;
            boost::tie(par_iter, par_end) = inv_adjacent_vertices(*vert_iter, b_graph);
            for (; par_iter != par_end; ++par_iter) {
                /*! the parent is the root in the task_graph. So here connect it to
                  the root of the flow graph*/
                if (b_graph[*par_iter].node_id == -1) {
                    flow::make_edge(flow_root, *curr_f_node);
                    // std::cout << "   edge to root " << std::endl;
                }
                else {
                    flow::make_edge(*(fnode_ps[b_graph[*par_iter].node_id]), *curr_f_node);
                    // std::cout << "   edge to " << b_graph[*par_iter].index << std::endl;
                }
            }
        }
    }

    void execute() {
        if (!this->is_set_up_) {
            std::cerr << "Set up the executor for the dynmaic scheduler first" << std::endl;
            exit(1);
        }

        execution_timer.start_timer();
        flow_root.try_put(tbb::flow::continue_msg());
        dynamic_graph.wait_for_all();
        execution_timer.stop_timer();
    }
};

}} // namespace openmodelica::parmodelica

#endif // header
