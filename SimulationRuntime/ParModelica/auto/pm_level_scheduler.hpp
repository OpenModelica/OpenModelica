#pragma once
#ifndef idDB873A43_F8D8_4666_8209C3B5AB1F01C2
#define idDB873A43_F8D8_4666_8209C3B5AB1F01C2


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



#include <iostream>

#include "pm_task_system.hpp"
#include "pm_timer.hpp"


namespace openmodelica {
namespace parmodelica {


template<typename TaskTypeT>
struct TaskQueue {
    typedef TaskTypeT TaskType;
    TaskQueue() : total_cost(0) {}
    std::vector<typename TaskSystem<TaskTypeT>::Node > nodes;
    double total_cost; 
    
    static bool TaskQueue_cost_comparator(const TaskQueue<TaskTypeT>& lhs, const TaskQueue<TaskTypeT>& rhs) {
        return lhs.total_cost < rhs.total_cost;
    }
    
};

// template<typename TaskTypeT>
// using ProcessorQueues = std::vector< typename TaskQueue<TaskTypeT> >;


template<typename TaskTypeT>
struct Level {
    typedef TaskTypeT TaskType;
    typedef typename TaskSystem<TaskTypeT>::Node NodeIdType;
    
    Level() : level_cost(0) {}
    double level_cost;
    std::vector<NodeIdType> nodes;
};

template<typename TaskTypeT, typename FunctionArray>
struct LevelExecutor {
    typedef typename TaskSystem<TaskTypeT>::Graph GraphType;
    typedef TaskQueue<TaskTypeT> TaskQueueType;
    typedef std::vector<TaskQueueType> ProcessorQueuesType;
private:    
    GraphType& graph;
    FunctionArray function_systems;
    void* data;

public:
    LevelExecutor(GraphType& g, FunctionArray f, void* d) : graph(g), function_systems(f), data(d) {}
    
    void operator()(const TaskQueueType& task_queue) const {
        for(unsigned i = 0; i < task_queue.nodes.size(); ++i) {
            function_systems[graph[task_queue.nodes[i]].node_id](data);
        }
    }
    
};


template<typename TaskTypeT>
class LevelScheduler {
public:
    typedef TaskTypeT TaskType;
    typedef typename TaskSystem<TaskTypeT>::Graph GraphType;
    typedef typename TaskSystem<TaskTypeT>::Node NodeIdType;
    typedef TaskQueue<TaskTypeT> TaskQueueType;
    typedef std::vector<TaskQueueType> ProcessorQueuesType;
    typedef std::vector<ProcessorQueuesType> ProcessorQueuesAllLevelsType;

private:    
    int number_of_processors;
    bool nodes_have_been_leveled;
    std::vector< Level<TaskTypeT> > levels;
    
public:
    LevelScheduler(TaskSystem<TaskTypeT>& task_system);
    TaskSystem<TaskTypeT>& task_system;
    
    bool profiled;
    double total_parallel_cost;
    PMTimer execution_timer;
    ProcessorQueuesAllLevelsType processor_queue_levels;
    
    
    void get_node_levels();
    void print_node_levels(std::ostream& ostr = utility::test_log());
    
    // void schedule();
    void schedule(int number_of_processors);
    // void re_schedule();
    void re_schedule(int number_of_processors);
    void print_schedule(std::ostream& ostr = utility::test_log()) const;
    
    template<typename FunctionArray>
    void execute_tasks(FunctionArray, void*);

    template<typename FunctionArray>
    void profile_execute(FunctionArray, void*);
    
    
};


  
} // parmodelica
} // openmodelica


#include "pm_level_scheduler.inl"

#endif // header