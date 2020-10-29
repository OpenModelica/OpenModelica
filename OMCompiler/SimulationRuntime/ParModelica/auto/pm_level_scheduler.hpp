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
 Mahder.Gebremedhin@liu.se  2020-10-12
*/

#include <iostream>

#include <tbb/parallel_for.h>
#include <tbb/task_scheduler_init.h>

#include "pm_task_system.hpp"
#include "pm_timer.hpp"

namespace openmodelica { namespace parmodelica {

template <typename>
class LevelSchedulerThreadOblivious;

template <typename>
class LevelSchedulerThreadAware;

/*! Using the thread aware level scheduler by default*/
// template<typename TaskTypeT>
// using LevelScheduler = LevelSchedulerThreadAware<TaskTypeT>;

template <typename TaskTypeT>
struct Level : public utility::pm_vector<typename TaskSystem<TaskTypeT>::Node> {
    typedef TaskTypeT                            TaskType;
    typedef typename TaskSystem<TaskTypeT>::Node NodeIdType;

    Level() : level_cost(0) {}
    double level_cost;

    std::vector<long> task_ids;
};

template <typename TaskTypeT>
struct TBBLevelExecutor {

    typedef TaskTypeT                         TaskType;
    typedef typename TaskType::FunctionType   FunctionType;
    typedef std::vector<long>::const_iterator TaskIdIter;

  private:
    FunctionType* function_systems;
    void*         data;

  public:
    TBBLevelExecutor() : data(NULL) {}
    void set_up(FunctionType* function_systems_, void* data_) {
        data = data_;
        function_systems = function_systems_;
    }

    void operator()(const tbb::blocked_range<TaskIdIter>& range) const {
        for (TaskIdIter iter = range.begin(); iter != range.end(); ++iter) {
            function_systems[*iter](data);
        }
    }
};

template <typename TaskTypeT>
class LevelSchedulerThreadOblivious : boost::noncopyable {
  public:
    typedef TaskTypeT                             TaskType;
    typedef typename TaskSystem<TaskTypeT>::Graph GraphType;
    typedef typename TaskSystem<TaskTypeT>::Node  NodeIdType;

    typedef typename TaskType::FunctionType FunctionType;
    typedef std::vector<Level<TaskTypeT>>   LevelsType;

  private:
    bool                          is_set_up_;
    int                           number_of_processors;
    bool                          nodes_have_been_leveled;
    std::vector<Level<TaskTypeT>> levels;
    FunctionType*                 function_systems;
    void*                         data;
    bool                          profiled;

  public:
    LevelSchedulerThreadOblivious(TaskSystem<TaskTypeT>& task_system);

    TaskSystem<TaskTypeT>&      task_system;
    tbb::task_scheduler_init    tbb_task_init;
    TBBLevelExecutor<TaskTypeT> level_executor;

    double  total_parallel_cost;
    PMTimer execution_timer;

    void get_node_levels();
    void set_up_executor(FunctionType*, void*);
    bool is_set_up() { return is_set_up_; }

    void schedule(int number_of_processors);
    void execute();
    void profile_execute();

    void print_schedule(std::ostream&) const;
    void print_node_levels(std::ostream&) const;
};

template <typename TaskTypeT>
struct TaskQueue : public utility::pm_vector<typename TaskSystem<TaskTypeT>::Node> {
    typedef TaskTypeT                        TaskType;
    typedef typename TaskTypeT::FunctionType FunctionType;

    TaskQueue() : total_cost(0) {}
    double total_cost;

    /*! this is just to avoid refering to the actual graph to get the task_ids since
      the whole scheduling operations work on node_ids i.e. ids of nodes in the graph
      which has in a sense nothing to do with the acutal task. So once we get all the
      nodes that belong in this queue we collect the task_id for each node here and use
      it to launch tasks.*/
    std::vector<long> task_ids;

    static bool cost_comparator(const TaskQueue<TaskTypeT>& lhs, const TaskQueue<TaskTypeT>& rhs) {
        return lhs.total_cost < rhs.total_cost;
    }

    void execute(FunctionType* function_systems, void* data) const {
        for (unsigned i = 0; i < this->size(); ++i) {
            function_systems[task_ids[i]](data);
        }
    }
};

template <typename TaskQueueTypeT>
struct ConcurrentQueues : public utility::pm_vector<TaskQueueTypeT> {
    typedef TaskQueueTypeT                                              TaskQueueType;
    typedef typename TaskQueueType::FunctionType                        FunctionType;
    typedef typename utility::pm_vector<TaskQueueTypeT>::const_iterator const_iterator;

    ConcurrentQueues() : total_cost(0), parallel_cost(0) {}

    double total_cost;
    double parallel_cost;

    void execute(FunctionType* function_systems, void* data) const {
        const_iterator iter;
        for (iter = this->begin(); iter != this->end(); ++iter) {
            iter->execute(function_systems, data);
        }
    }
};

template <typename ConcurrentQueuesTypeT>
struct TBBConcurrentExecutor {

    typedef ConcurrentQueuesTypeT                         ConcurrentQueuesType;
    typedef typename ConcurrentQueuesType::FunctionType   FunctionType;
    typedef typename ConcurrentQueuesType::const_iterator ConQueIter;

  private:
    FunctionType* function_systems;
    void*         data;

  public:
    TBBConcurrentExecutor() : data(NULL) {}
    void set_up(FunctionType* function_systems_, void* data_) {
        data = data_;
        function_systems = function_systems_;
    }

    void operator()(const tbb::blocked_range<ConQueIter>& range) const {
        for (ConQueIter iter = range.begin(); iter != range.end(); ++iter) {
            iter->execute(function_systems, data);
        }
    }
};

template <typename TaskTypeT>
class LevelSchedulerThreadAware : boost::noncopyable {
  public:
    typedef TaskTypeT                             TaskType;
    typedef typename TaskSystem<TaskTypeT>::Graph GraphType;
    typedef typename TaskSystem<TaskTypeT>::Node  NodeIdType;

    typedef TaskQueue<TaskTypeT>                 TaskQueueType;
    typedef typename TaskQueueType::FunctionType FunctionType;
    typedef ConcurrentQueues<TaskQueueType>      ConcurrentQueuesType;
    typedef std::vector<ConcurrentQueuesType>    TaskQueueGroupAllLevelsType;

  private:
    bool is_set_up_;
    bool profiled;
    int  number_of_processors;
    bool nodes_have_been_leveled;

    std::vector<Level<TaskTypeT>> levels;

    FunctionType* function_systems;
    void*         data;

  public:
    LevelSchedulerThreadAware(TaskSystem<TaskTypeT>& task_system);

    TaskSystem<TaskTypeT>&                      task_system;
    tbb::task_scheduler_init                    tbb_task_init;
    TBBConcurrentExecutor<ConcurrentQueuesType> level_executor;

    double                      total_parallel_cost;
    PMTimer                     execution_timer;
    TaskQueueGroupAllLevelsType processor_queue_levels;

    void get_node_levels();
    void set_up_executor(FunctionType*, void*);
    bool is_set_up() { return is_set_up_; }

    // void schedule();
    void schedule(int number_of_processors);
    // void re_schedule();
    void re_schedule(int number_of_processors);
    void execute();
    void profile_execute();

    void print_node_levels(std::ostream&) const;
    void print_schedule(std::ostream&) const;
};

}} // namespace openmodelica::parmodelica

#include "pm_level_scheduler.inl"

#endif // header