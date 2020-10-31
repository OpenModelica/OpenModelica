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
 Mahder.Gebremedhin@liu.se  2020-10-12
*/

#include <algorithm>
#include <functional>

#include "pm_graph_dump.hpp"

// #include <boost/thread.hpp>

namespace openmodelica { namespace parmodelica {

template <typename TaskTypeT>
LevelSchedulerThreadOblivious<TaskTypeT>::LevelSchedulerThreadOblivious(TaskSystem<TaskTypeT>& task_system)
    : task_system(task_system)
    , tbb_task_init(4) {
    nodes_have_been_leveled = false;
    total_parallel_cost = 0;
    is_set_up_ = false;
    profiled = false;
}

template <typename TaskTypeT>
void LevelSchedulerThreadOblivious<TaskTypeT>::get_node_levels() {

    GraphType& graph = this->task_system.graph;

    int critical_path = 0;
    // boost::dijkstra_shortest_paths(graph,task_system.root_node,boost::weight_map(
    // boost::make_constant_property<TaskSystem<TaskTypeT>::Edge>(1)).distance_map(boost::get(&TaskTypeT::level,graph)));
    BGL_FORALL_VERTICES_T(v, graph, GraphType) {
        int                                        max_p_lvl = graph[v].level - 1;
        typename GraphType::inv_adjacency_iterator neighbourIt, neighbourEnd;
        boost::tie(neighbourIt, neighbourEnd) = inv_adjacent_vertices(v, graph);
        for (typename GraphType::inv_adjacency_iterator adj_iter = neighbourIt; adj_iter != neighbourEnd; ++adj_iter) {
            max_p_lvl = std::max(max_p_lvl, graph[*adj_iter].level);
        }
        graph[v].level = max_p_lvl + 1;
        critical_path = max_p_lvl > critical_path ? max_p_lvl : critical_path;
    }

    levels.resize(critical_path + 2);
    BGL_FORALL_VERTICES_T(node, graph, GraphType) {
        levels[graph[node].level].push_back(node);
        levels[graph[node].level].level_cost += graph[node].cost;
    }

    /*! Sort the level by cost so that we can pick the node that fits the scheduling time easily.*/
    Node_cost_comparatorR<TaskTypeT>                 vccR(graph);
    typename std::vector<Level<TaskTypeT>>::iterator level_iter;
    for (level_iter = levels.begin() + 1; level_iter != levels.end(); ++level_iter) {
        Level<TaskTypeT>& current_level = *level_iter;
        std::sort(current_level.begin(), current_level.end(), vccR);
    }

    this->nodes_have_been_leveled = true;
}

template <typename TaskTypeT>
void LevelSchedulerThreadOblivious<TaskTypeT>::print_node_levels(std::ostream& ostr) const {

    GraphType& graph = this->task_system.graph;

    ostr << "------------------------------------------------------------------------------------------" << newl;

    for (unsigned curr_lvl = 0; curr_lvl < levels.size(); curr_lvl++) {
        ostr << "Level " << curr_lvl << " : " << levels[curr_lvl].level_cost << " : ";
        for (unsigned curr_eq = 0; curr_eq < levels[curr_lvl].size(); ++curr_eq) {
            typename TaskSystem<TaskTypeT>::Node node = levels[curr_lvl][curr_eq];
            ostr << "(" << graph[node].index << ", " << graph[node].cost << "), ";
        }
        ostr << newl;
    }
    ostr << "------------------------------------------------------------------------------------------" << newl;
}

template <typename TaskTypeT>
void LevelSchedulerThreadOblivious<TaskTypeT>::set_up_executor(FunctionType* function_systems_, void* data_) {
    this->function_systems = function_systems_;
    this->data = data_;
    level_executor.set_up(function_systems_, data_);
    this->is_set_up_ = true;
}

template <typename TaskTypeT>
void LevelSchedulerThreadOblivious<TaskTypeT>::schedule(int number_of_processors) {

    if (!this->nodes_have_been_leveled)
        this->get_node_levels();
}

template <typename TaskTypeT>
void LevelSchedulerThreadOblivious<TaskTypeT>::print_schedule(std::ostream& ostr) const {
    print_node_levels(ostr);
}

template <typename TaskTypeT>
void LevelSchedulerThreadOblivious<TaskTypeT>::execute() {

    if (!this->is_set_up_) {
        std::cerr << "Set up the executor first" << std::endl;
        exit(1);
    }
    if (!profiled)
        return profile_execute();

    execution_timer.start_timer();

    typename LevelsType::iterator level_iter;
    level_iter = levels.begin() + 1;
    for (; level_iter != levels.end(); ++level_iter) {
        unsigned           nr_of_tasks = level_iter->size();
        std::vector<long>& l_task_ids = level_iter->task_ids;
        /*! cutoff cost. For now here is no optimal value. Just try to pick a cost that will give
          benefit over the overhead of thread context switching*/
        if (level_iter->level_cost > 0.1) {
            tbb::parallel_for(
                tbb::blocked_range<std::vector<long>::const_iterator>(l_task_ids.begin(), l_task_ids.end()),
                level_executor);
        }
        else {
            for (unsigned j = 0; j < nr_of_tasks; ++j) {
                function_systems[l_task_ids[j]](data);
            }
        }
    }

    execution_timer.stop_timer();
}

template <typename TaskTypeT>
void LevelSchedulerThreadOblivious<TaskTypeT>::profile_execute() {

    GraphType&                       system_graph = this->task_system.graph;
    Node_cost_comparatorR<TaskTypeT> vccR(system_graph);

    std::cout << "system cost before = " << task_system.total_cost << std::endl;
    std::cout << "Scheduler cost before = " << total_parallel_cost << std::endl;
    std::cout << "Peak speedup before = " << task_system.total_cost / total_parallel_cost << std::endl;

    task_system.total_cost = 0;
    PMTimer cost_timer;
    double  curr_cost;

    execution_timer.start_timer();

    typename LevelsType::iterator level_iter;
    level_iter = levels.begin() + 1;
    for (; level_iter != levels.end(); ++level_iter) {
        level_iter->level_cost = 0;
        unsigned nr_of_tasks = level_iter->size();
        for (unsigned j = 0; j < nr_of_tasks; ++j) {
            cost_timer.start_timer();
            function_systems[system_graph[level_iter->at(j)].node_id](data);
            cost_timer.stop_timer();
            curr_cost = cost_timer.get_elapsed_time() * 10000;
            cost_timer.reset_timer();
            system_graph[level_iter->at(j)].cost = curr_cost;
            level_iter->level_cost += curr_cost;
        }
        task_system.total_cost += level_iter->level_cost;

        /*! Sort if needed. hoping that larger tasks will be picked up first*/
        std::sort(level_iter->begin(), level_iter->end(), vccR);

        /*! save the task_ids so that we don't have to access them using the node id and then going
         to the graph every time.*/
        for (unsigned j = 0; j < nr_of_tasks; ++j) {
            level_iter->task_ids.push_back(system_graph[level_iter->at(j)].node_id);
        }
    }

    profiled = true;

    execution_timer.stop_timer();

    std::cout << "system cost after = " << task_system.total_cost << std::endl;
    std::cout << "Scheduler cost after = " << total_parallel_cost << std::endl;
    std::cout << "Peak speedup after = " << task_system.total_cost / total_parallel_cost << std::endl;
    std::cout << "-------------------------------------------------------------" << std::endl;

    print_node_levels(std::cout);
}

template <typename TaskTypeT>
LevelSchedulerThreadAware<TaskTypeT>::LevelSchedulerThreadAware(TaskSystem<TaskTypeT>& task_system)
    : task_system(task_system)
    , tbb_task_init(4) {
    nodes_have_been_leveled = false;
    total_parallel_cost = 0;
    is_set_up_ = false;
    profiled = false;
}

template <typename TaskTypeT>
void LevelSchedulerThreadAware<TaskTypeT>::get_node_levels() {

    GraphType& graph = this->task_system.graph;

    int critical_path = 0;
    // boost::dijkstra_shortest_paths(graph,task_system.root_node,boost::weight_map(
    // boost::make_constant_property<TaskSystem<TaskTypeT>::Edge>(1)).distance_map(boost::get(&TaskTypeT::level,graph)));
    BGL_FORALL_VERTICES_T(v, graph, GraphType) {
        int                                        max_p_lvl = graph[v].level - 1;
        typename GraphType::inv_adjacency_iterator neighbourIt, neighbourEnd;
        boost::tie(neighbourIt, neighbourEnd) = inv_adjacent_vertices(v, graph);
        for (typename GraphType::inv_adjacency_iterator adj_iter = neighbourIt; adj_iter != neighbourEnd; ++adj_iter) {
            max_p_lvl = std::max(max_p_lvl, graph[*adj_iter].level);
        }
        graph[v].level = max_p_lvl + 1;
        critical_path = max_p_lvl > critical_path ? max_p_lvl : critical_path;
    }

    levels.resize(critical_path + 2);
    BGL_FORALL_VERTICES_T(node, graph, GraphType) {
        levels[graph[node].level].push_back(node);
        levels[graph[node].level].level_cost += graph[node].cost;
    }

    /*! Sort the level by cost so that we can pick the node that fits the scheduling time easily.*/
    Node_cost_comparatorR<TaskTypeT>                 vccR(graph);
    typename std::vector<Level<TaskTypeT>>::iterator level_iter;
    for (level_iter = levels.begin() + 1; level_iter != levels.end(); ++level_iter) {
        Level<TaskTypeT>& current_level = *level_iter;
        std::sort(current_level.begin(), current_level.end(), vccR);
    }

    this->nodes_have_been_leveled = true;
}

template <typename TaskTypeT>
void LevelSchedulerThreadAware<TaskTypeT>::print_node_levels(std::ostream& ostr) const {

    GraphType& graph = this->task_system.graph;

    ostr << "------------------------------------------------------------------------------------------" << newl;

    for (unsigned curr_lvl = 0; curr_lvl < levels.size(); curr_lvl++) {
        ostr << "Level " << curr_lvl << " : " << levels[curr_lvl].level_cost << " : ";
        for (unsigned curr_eq = 0; curr_eq < levels[curr_lvl].size(); ++curr_eq) {
            typename TaskSystem<TaskTypeT>::Node node = levels[curr_lvl][curr_eq];
            ostr << "(" << graph[node].index << ", " << graph[node].cost << "), ";
        }
        ostr << newl;
    }
    ostr << "------------------------------------------------------------------------------------------" << newl;
}

template <typename TaskTypeT>
void LevelSchedulerThreadAware<TaskTypeT>::set_up_executor(FunctionType* function_systems_, void* data_) {
    this->function_systems = function_systems_;
    this->data = data_;
    level_executor.set_up(function_systems_, data_);
    this->is_set_up_ = true;
}

// template<typename TaskTypeT>
// void LevelSchedulerThreadAware<TaskTypeT>::schedule() {
// schedule(boost::thread::hardware_concurrency());
// }

template <typename TaskTypeT>
void LevelSchedulerThreadAware<TaskTypeT>::schedule(int number_of_processors) {

    GraphType& system_graph = this->task_system.graph;

    /*! get the node levels if they haven't been leveled yet. */
    if (!this->nodes_have_been_leveled)
        this->get_node_levels();

    // print_node_levels(std::cout);

    processor_queue_levels.resize(levels.size());

    long level_number = 1;

    /*! Iterate over all levels. That means visiting all children of the root first and then children of each node in
     * there and so on*/
    typename std::vector<Level<TaskTypeT>>::iterator level_iter;
    for (level_iter = this->levels.begin() + 1; level_iter != this->levels.end(); ++level_iter, ++level_number) {
        Level<TaskTypeT>& current_level = *level_iter;

        /*! calculate the maximum parallel cost of the current level*/
        double max = current_level.level_cost / number_of_processors;
        if (max < system_graph[current_level.front()].cost) {
            max = system_graph[current_level.front()].cost;
        }

        ConcurrentQueuesType& current_group = processor_queue_levels[level_number];
        current_group.resize(number_of_processors);

        typename ConcurrentQueuesType::iterator pqueue_iter;
        for (pqueue_iter = current_group.begin(); pqueue_iter != current_group.end(); ++pqueue_iter) {
            TaskQueueType& current_queue = *(pqueue_iter);

            // We have free processor but we run out of tasks.
            if (current_level.empty()) {
                break;
            }

            current_queue.push_back(current_level.front());
            current_queue.total_cost += system_graph[current_level.front()].cost;
            current_level.erase(current_level.begin());

            double gap = max - current_queue.total_cost;
            if (gap != 0) {
                typename std::vector<NodeIdType>::iterator node_iter;
                for (node_iter = current_level.begin(); node_iter != current_level.end() && gap != 0;) {
                    if (system_graph[*node_iter].cost <= gap) {
                        gap = gap - system_graph[*node_iter].cost;
                        current_queue.push_back(*node_iter);
                        current_queue.total_cost += system_graph[*node_iter].cost;
                        node_iter = current_level.erase(node_iter);
                    }
                    else
                        ++node_iter;
                }
            }

            current_group.total_cost = current_queue.total_cost;
        }

        /*! See if any nodes remain in the current level that have not been assigned by the
          loop above. can happpen for some combination of costs. If there are nodes remaining
          add them to the queue with the least cost currently.*/
        while (current_level.size() != 0) {
            // utility::test_log("Info") << "vertices remaining. " << current_level.size() << " " <<
            // system_graph[current_level.front()].index << newl;
            pqueue_iter = std::min_element(current_group.begin(), current_group.end(), TaskQueueType::cost_comparator);
            pqueue_iter->push_back(current_level.front());
            pqueue_iter->total_cost += system_graph[current_level.front()].cost;
            current_level.erase(current_level.begin());
        }

        current_group.parallel_cost =
            std::max_element(current_group.begin(), current_group.end(), TaskQueueType::cost_comparator)->total_cost;
        total_parallel_cost += current_group.parallel_cost;

        /*! check if there are empty queues i.e. processors with no possible jobs. Then resize the
         queue vector to avoid launching threads for empty queues later.*/
        pqueue_iter = std::find_if(current_group.begin(), current_group.end(), std::mem_fun_ref(&TaskQueueType::empty));

        if (pqueue_iter != current_group.end()) {
            current_group.resize(std::distance(current_group.begin(), pqueue_iter));
        }

        /*! now that scheduling is done collect the task ids in the correct order
          so that we don't have to refere to the actuall system system_graph in execution time
          to get the task id using a node id.*/
        for (pqueue_iter = current_group.begin(); pqueue_iter != current_group.end(); ++pqueue_iter) {
            TaskQueueType& current_queue = *(pqueue_iter);
            for (unsigned i = 0; i < current_queue.size(); ++i) {
                current_queue.task_ids.push_back(system_graph[current_queue[i]].node_id);
            }
        }
    }
}

// template<typename TaskTypeT>
// void LevelSchedulerThreadAware<TaskTypeT>::re_schedule() {
// re_schedule(boost::thread::hardware_concurrency());
// }

template <typename TaskTypeT>
void LevelSchedulerThreadAware<TaskTypeT>::re_schedule(int number_of_processors) {

    /*TODO nodes should not be releveled here. Save the old level somehow and use it.
      maybe copy it before rescheduling. The scheduler as it is now removes nodes from it
      as it schedules. */
    nodes_have_been_leveled = false;
    total_parallel_cost = 0;

    levels.clear();
    processor_queue_levels.clear();

    schedule(number_of_processors);
    // print_node_levels(std::cout);
    // print_schedule(std::cout);
}

template <typename TaskTypeT>
void LevelSchedulerThreadAware<TaskTypeT>::print_schedule(std::ostream& ostr) const {

    GraphType& graph = this->task_system.graph;

    long                                                 level_number = 1;
    typename TaskQueueGroupAllLevelsType::const_iterator pq_level_iter;
    for (pq_level_iter = this->processor_queue_levels.begin() + 1; pq_level_iter != this->processor_queue_levels.end();
         ++pq_level_iter, ++level_number) {
        const ConcurrentQueuesType& current_group = *pq_level_iter;

        double total_level_cost = 0;
        ostr << "-------------------------------Strarting level " << level_number
             << " ---------------------------------------------" << newl;

        for (unsigned j = 0; j < current_group.size(); ++j) {
            for (unsigned i = 0; i < current_group[j].size(); ++i)
                ostr << graph[current_group[j][i]].index << ", ";

            total_level_cost += current_group[j].total_cost;
            ostr << newl << "---" << current_group[j].total_cost << newl;
        }

        ostr << "Level total cost : " << total_level_cost << newl;
        ostr << "Level parallel cost : " << current_group.parallel_cost << newl;
    }
    ostr << "----------------------------------------------------------------------------------------------------------"
            "---------"
         << newl;
}

template <typename TaskTypeT>
void LevelSchedulerThreadAware<TaskTypeT>::execute() {

    if (!this->is_set_up_) {
        std::cerr << "Set up the executor first" << std::endl;
        exit(1);
    }
    if (!profiled)
        return profile_execute();

    execution_timer.start_timer();

    typename TaskQueueGroupAllLevelsType::const_iterator pq_level_iter;
    pq_level_iter = processor_queue_levels.begin() + 1;
    for (; pq_level_iter != processor_queue_levels.end(); ++pq_level_iter) {
        const ConcurrentQueuesType& current_group = *pq_level_iter;

        if (current_group.parallel_cost > 0.05) {
            tbb::parallel_for(tbb::blocked_range<typename ConcurrentQueuesType::const_iterator>(current_group.begin(),
                                                                                                current_group.end()),
                              level_executor);
        }
        else {
            pq_level_iter->execute(function_systems, data);
        }

        // std::for_each(current_group.begin(), current_group.end(), level_executor);
    }

    execution_timer.stop_timer();
}

template <typename TaskTypeT>
void LevelSchedulerThreadAware<TaskTypeT>::profile_execute() {

    GraphType& system_graph = this->task_system.graph;

    std::cout << "system cost before = " << task_system.total_cost << std::endl;
    std::cout << "Scheduler cost before = " << total_parallel_cost << std::endl;
    std::cout << "Peak speedup before = " << task_system.total_cost / total_parallel_cost << std::endl;

    task_system.total_cost = 0;
    PMTimer cost_timer;
    double  curr_cost;

    execution_timer.start_timer();

    typename TaskQueueGroupAllLevelsType::iterator pq_level_iter;
    pq_level_iter = processor_queue_levels.begin() + 1;
    for (; pq_level_iter != processor_queue_levels.end(); ++pq_level_iter) {
        const ConcurrentQueuesType& current_group = *pq_level_iter;
        for (unsigned j = 0; j < current_group.size(); ++j) {
            const TaskQueueType& current_queue = current_group[j];
            for (unsigned i = 0; i < current_queue.size(); ++i) {
                cost_timer.start_timer();
                function_systems[system_graph[current_queue[i]].node_id](data);
                cost_timer.stop_timer();
                curr_cost = cost_timer.get_elapsed_time() * 10000;
                cost_timer.reset_timer();

                system_graph[current_queue[i]].cost = curr_cost;
                task_system.total_cost += curr_cost;
            }
        }
    }

    profiled = true;
    re_schedule(4);

    execution_timer.stop_timer();

    std::cout << "system cost after = " << task_system.total_cost << std::endl;
    std::cout << "Scheduler cost after = " << total_parallel_cost << std::endl;
    std::cout << "Peak speedup after = " << task_system.total_cost / total_parallel_cost << std::endl;
    std::cout << "-------------------------------------------------------------" << std::endl;

    print_schedule(std::cout);

    dump_graphml(task_system, "current-");
}

}} // namespace openmodelica::parmodelica
