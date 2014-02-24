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
 Mahder.Gebremedhin@liu.se  2014-02-10
*/



namespace openmodelica {
namespace parmodelica {


template<typename TaskTypeT>
LevelScheduler<TaskTypeT>::LevelScheduler(TaskSystem<TaskTypeT>& task_system) :
        task_system(task_system)
{
    nodes_have_been_leveled = false;
    total_parallel_cost = 0;
    profiled = false;
}


template<typename TaskTypeT>
void LevelScheduler<TaskTypeT>::get_node_levels() {

    GraphType& graph = this->task_system.graph;

    int critical_path = 0;
    // boost::dijkstra_shortest_paths(graph,task_system.root_node,boost::weight_map(
                // boost::make_constant_property<TaskSystem<TaskTypeT>::Edge>(1)).distance_map(boost::get(&TaskTypeT::level,graph)));
    BGL_FORALL_VERTICES_T(v,graph,GraphType)
    {
        int max_p_lvl = graph[v].level - 1;
        typename GraphType::inv_adjacency_iterator neighbourIt, neighbourEnd;
        boost::tie(neighbourIt, neighbourEnd) = inv_adjacent_vertices( v, graph );
        for(typename GraphType::inv_adjacency_iterator adj_iter = neighbourIt; adj_iter != neighbourEnd; ++adj_iter) {
            max_p_lvl = std::max(max_p_lvl, graph[*adj_iter].level);
        }
        graph[v].level = max_p_lvl + 1;
        critical_path = max_p_lvl > critical_path ? max_p_lvl : critical_path;
    }

    utility::test_log("Info") << "Critical path = " << critical_path + 1 << newl;

    levels.resize(critical_path + 2);
    BGL_FORALL_VERTICES_T(node,graph,GraphType)
    {
        levels[graph[node].level].nodes.push_back(node);
        levels[graph[node].level].level_cost += graph[node].cost;
    }

    /*! Sort the nodes by cost so that we can pick the node that fits the scheduling time easily.*/
    Node_cost_comparatorR<TaskTypeT> vccR(graph);
    typename std::vector<Level<TaskTypeT> >::iterator level_iter;
    for(level_iter = levels.begin() + 1; level_iter != levels.end(); ++level_iter) {
        Level<TaskTypeT>& current_level = *level_iter;
        std::sort(current_level.nodes.begin(), current_level.nodes.end(), vccR);
    }

    this->nodes_have_been_leveled = true;

}


template<typename TaskTypeT>
void LevelScheduler<TaskTypeT>::print_node_levels(std::ostream& ostr) {

    GraphType& graph = this->task_system.graph;

    ostr << "------------------------------------------------------------------------------------------" << newl;

    for(unsigned curr_lvl = 0; curr_lvl < levels.size(); curr_lvl++) {
        ostr << "Level " << curr_lvl << " : ";
        for(unsigned curr_eq = 0; curr_eq < levels[curr_lvl].nodes.size(); ++curr_eq) {
            typename TaskSystem<TaskTypeT>::Node node = levels[curr_lvl].nodes[curr_eq];
            ostr << "(" << graph[node].index << ", "  << graph[node].node_id << "), ";

        }
        ostr << newl;

    }
    ostr << "------------------------------------------------------------------------------------------" << newl;

}


template<typename TaskTypeT>
void LevelScheduler<TaskTypeT>::schedule(int number_of_processors) {

    GraphType& graph = this->task_system.graph;

    /*! get the node levels if they haven't been leveled yet. */
    if(!this->nodes_have_been_leveled)
        this->get_node_levels();

    processor_queue_levels.resize(levels.size());

    long level_number = 1;

    /*! Iterate over all levels. That means visiting all children of the root first and then children of each node in there and so on*/
    typename std::vector<Level<TaskTypeT> >::iterator level_iter;
    for(level_iter = this->levels.begin() + 1; level_iter != this->levels.end(); ++level_iter, ++level_number) {
        Level<TaskTypeT>& current_level = *level_iter;

        /*! calculate the maximum parallel cost of the current level*/
        double max = current_level.level_cost/number_of_processors;
        if(max < graph[current_level.nodes.front()].cost) {
            max = graph[current_level.nodes.front()].cost;
        }


        ProcessorQueuesType& pqueues = processor_queue_levels[level_number];
        pqueues.resize(number_of_processors);


        typename ProcessorQueuesType::iterator pqueue_iter;
        for(pqueue_iter = pqueues.begin(); pqueue_iter != pqueues.end(); ++pqueue_iter) {

            // We have free processor but we run out of tasks.
            if(current_level.nodes.empty()) {
                break;
            }

            pqueue_iter->nodes.push_back(current_level.nodes.front());
            pqueue_iter->total_cost += graph[current_level.nodes.front()].cost;
            current_level.nodes.erase(current_level.nodes.begin());

            double gap = max - pqueue_iter->total_cost;
            if(gap != 0)
            {
                typename std::vector<NodeIdType>::iterator node_iter;
                for(node_iter = current_level.nodes.begin(); node_iter != current_level.nodes.end() && gap != 0; ) {
                    if(graph[*node_iter].cost <= gap) {
                        gap = gap - graph[*node_iter].cost;
                        pqueue_iter->nodes.push_back(*node_iter);
                        pqueue_iter->total_cost += graph[*node_iter].cost;
                        node_iter = current_level.nodes.erase(node_iter);
                    }
                    else
                        ++node_iter;

                }
            }

        }

        while(current_level.nodes.size() != 0) {
            // utility::test_log("Info") << "vertices remaining. " << current_level.nodes.size() << " " << graph[current_level.nodes.front()].index << newl;
            typename ProcessorQueuesType::iterator pqueue_iter = std::min_element(pqueues.begin(), pqueues.end(), TaskQueueType::TaskQueue_cost_comparator);
            pqueue_iter->nodes.push_back(current_level.nodes.front());
            pqueue_iter->total_cost += graph[current_level.nodes.front()].cost;
            current_level.nodes.erase(current_level.nodes.begin());
        }


        double level_cost = std::max_element(pqueues.begin(), pqueues.end(), TaskQueueType::TaskQueue_cost_comparator)->total_cost;
        total_parallel_cost += level_cost;

    }

    utility::test_log("Info") << "Total parallel cost : " << total_parallel_cost << newl;


}


template<typename TaskTypeT>
void LevelScheduler<TaskTypeT>::re_schedule(int number_of_processors) {

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


template<typename TaskTypeT>
void LevelScheduler<TaskTypeT>::print_schedule(std::ostream& ostr) const {

    GraphType& graph = this->task_system.graph;

    long level_number = 1;
    typename ProcessorQueuesAllLevelsType::const_iterator pq_level_iter;
    for(pq_level_iter = this->processor_queue_levels.begin() + 1; pq_level_iter != this->processor_queue_levels.end(); ++pq_level_iter, ++level_number) {
        const ProcessorQueuesType& pqueues = *pq_level_iter;

        ostr << "-------------------------------Strarting level "<< level_number << " ---------------------------------------------" << newl;

        for(unsigned j = 0; j < pqueues.size(); ++j) {
            for(unsigned i = 0; i < pqueues[j].nodes.size(); ++i)
                ostr << graph[pqueues[j].nodes[i]].index << ", ";

            ostr << newl << "---" << pqueues[j].total_cost << newl;
        }

        double level_cost = std::max_element(pqueues.begin(), pqueues.end(), TaskQueueType::TaskQueue_cost_comparator)->total_cost;
        ostr << "Level parallel cost : " << level_cost << newl;

    }
    ostr << "-------------------------------------------------------------------------------------------------------------------" << newl;

}


template<typename TaskTypeT>
void LevelScheduler<TaskTypeT>::execute() {

    GraphType& graph = this->task_system.graph;

    typename ProcessorQueuesAllLevelsType::iterator pq_level_iter;
    for(pq_level_iter = processor_queue_levels.begin() + 1; pq_level_iter != processor_queue_levels.end(); ++pq_level_iter) {
        LevelScheduler<TaskTypeT>::ProcessorQueuesType& pqueues = *pq_level_iter;

        for(unsigned j = 0; j < pqueues.size(); ++j) {
            for(unsigned i = 0; i < pqueues[j].nodes.size(); ++i) {
                std::cout << "(" << graph[pqueues[j].nodes[i]].index << ", " << graph[pqueues[j].nodes[i]].node_id << ")" << newl;
                // functionInitialEquations_systems[graph[pqueues[j].nodes[i]].node_id](data);
            }
        }

    }

}




}
}