#pragma once
#ifndef idC49A2D93_44C9_41C1_BFCE81120109B873
#define idC49A2D93_44C9_41C1_BFCE81120109B873

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
 Mahder.Gebremedhin@liu.se  2014-03-13
*/

#include <tbb/parallel_for.h>
#include <tbb/task_scheduler_init.h>

#include "pm_clustering.hpp"


namespace openmodelica {
namespace parmodelica {


template<typename TaskType>
struct TBBConcurrentStepExecutor {

    typedef TaskSystem_v2<TaskType> TaskSystemType;

    typedef typename TaskSystemType::GraphType GraphType;
    typedef typename TaskSystemType::ClusterType ClusterType;
    typedef typename TaskSystemType::ClusterIdType ClusterIdType;

    typedef typename TaskSystemType::ClusterLevels ClusterLevels;
    typedef typename ClusterLevels::value_type SameLevelClusterIdsType;
    typedef typename SameLevelClusterIdsType::iterator ClusteIdIter;

private:
    GraphType& sys_graph;

public:
    TBBConcurrentStepExecutor(GraphType& g) : sys_graph(g) {}

    void operator()( tbb::blocked_range<ClusteIdIter>& range ) const {

        for(ClusteIdIter clustid_iter = range.begin(); clustid_iter != range.end(); ++clustid_iter) {
            ClusterIdType& curr_clust_id = *clustid_iter;
            ClusterType& curr_clust = sys_graph[curr_clust_id];

            curr_clust.execute();
        }
    }

};



template<typename TaskType,
         typename clustetring1 = cluster_merge_common, /* for now default here*/
         typename clustetring2 = cluster_merge_level_for_cost, /* for now default here*/
         typename clustetring3 = cluster_none,
         typename clustetring4 = cluster_none,
         typename clustetring5 = cluster_none
        >
class StepLevels :
  boost::noncopyable {
public:

    typedef TaskSystem_v2<TaskType> TaskSystemType;
    typedef typename TaskSystemType::GraphType GraphType;
    typedef typename TaskSystemType::ClusterType ClusterType;
    typedef typename TaskSystemType::ClusterIdType ClusterIdType;

    typedef typename TaskSystemType::ClusterLevels ClusterLevels;
    typedef typename ClusterLevels::value_type SameLevelClusterIdsType;


private:
    TaskSystemType& task_system;
    bool profiled;
    bool schedule_valid;

    tbb::task_scheduler_init tbb_system;
    TBBConcurrentStepExecutor<TaskType> step_executor;

public:

    PMTimer execution_timer;
	PMTimer clustering_timer;
    // PMTimer extra_timer;

    StepLevels(TaskSystemType& ts) :
      task_system(ts)
      , tbb_system(4)
      , step_executor(task_system.sys_graph)
    {
        profiled = false;
        schedule_valid = false;
    }

    void estimate_speedup() {

        if(task_system.levels_valid == false)
            task_system.update_node_levels();

        GraphType& sys_graph = task_system.sys_graph;

        double total_level_scheduler_cost = 0;
        double total_system_cost = 0;
        typename ClusterLevels::iterator level_iter = task_system.clusters_by_level.begin();
        /*! Skip the first level. Which contains only the root node and some invlaidated clusters.*/
        ++level_iter;
        int level_number = 1;
        for( ;level_iter != task_system.clusters_by_level.end(); ++level_iter, ++level_number) {
            SameLevelClusterIdsType& current_level = *level_iter;

            cluster_cost_comparator_by_id<GraphType> cccbi(sys_graph);
            std::sort(current_level.begin(), current_level.end(), cccbi);
            total_level_scheduler_cost += sys_graph[current_level.front()].cost;

            total_system_cost += current_level.level_cost;
        }

        utility::log("") << "total_system_cost: " << total_system_cost << std::endl;
        utility::log("") << "total_level_scheduler_cost: " << total_level_scheduler_cost << std::endl;
        utility::log("") << "speedup: " << total_system_cost/total_level_scheduler_cost << std::endl;

    }

    void schedule() {

        if(schedule_valid)
            return;

        clustering_timer.start_timer();

        if(task_system.levels_valid == false)
            task_system.update_node_levels();

        task_system.dump_graphml("original");

        clustetring1::apply(task_system);
		clustetring1::dump_graph(task_system);

        clustetring2::apply(task_system);
		clustetring2::dump_graph(task_system);

        clustetring3::apply(task_system);
		clustetring3::dump_graph(task_system);

		clustetring4::apply(task_system);
		clustetring4::dump_graph(task_system);

        clustetring5::apply(task_system);
		clustetring5::dump_graph(task_system);

        schedule_valid = true;
        task_system.levels_valid = false;

        estimate_speedup();
		clustering_timer.stop_timer();

    }


    void execute()
    {

        if(!this->profiled)
            return profile_execute();

        execution_timer.start_timer();
        // extra_timer.start_timer();

        // GraphType& sys_graph = task_system.sys_graph;

        if(task_system.levels_valid == false)
            task_system.update_node_levels();

        typename ClusterLevels::iterator level_iter = task_system.clusters_by_level.begin();
        /*! Skip the first level. Which contains only the root node */
        ++level_iter;
        int level_number = 1;
        for( ;level_iter != task_system.clusters_by_level.end(); ++level_iter, ++level_number) {
            SameLevelClusterIdsType& current_level = *level_iter;

            // if(current_level.level_cost > 0.009) {
                tbb::parallel_for(
                    tbb::blocked_range<typename SameLevelClusterIdsType::iterator>(
                    current_level.begin(), current_level.end())
                    , step_executor);
            // }
            // else {
                // typename SameLevelClusterIdsType::iterator clustid_iter = current_level.begin();
                // for( ;clustid_iter != current_level.end(); ++clustid_iter) {
                    // ClusterIdType& curr_clust_id = *clustid_iter;
                    // ClusterType& curr_clust = sys_graph[curr_clust_id];

                    // curr_clust.execute();

                // }
            // }
        }

        execution_timer.stop_timer();
        // extra_timer.stop_timer();
        // double step_cost = extra_timer.get_elapsed_time();
        // std::cout << "E: " << step_cost << std::endl;
        // extra_timer.reset_timer();

    }


    void profile_execute()
    {
        execution_timer.start_timer();


        GraphType& sys_graph = task_system.sys_graph;

        typename GraphType::vertex_iterator vert_iter, vert_end;
        boost::tie(vert_iter, vert_end) = vertices(sys_graph);
        /*! skip the root node. */
        ++vert_iter;
        for ( ; vert_iter != vert_end; ++vert_iter) {
            sys_graph[*vert_iter].profile_execute();
        }

        execution_timer.stop_timer();
        // double step_cost = execution_timer.get_elapsed_time();
        // std::cout << "P: " << step_cost << std::endl;
        // execution_timer.reset_timer();

        this->profiled = true;
        this->schedule_valid = false;
        schedule();

    }

};


/*! The default level scheduler uses these two clusterings*/
//template<typename Tasktype>
//using LevelScheduler = StepLevels<TaskType
                                    // , cluster_merge_common
                                    // , cluster_merge_level_for_cost
                                   // >;

template<typename TaskType>
struct LevelScheduler : StepLevels<TaskType
                                    , cluster_merge_common
                                    , cluster_merge_level_for_cost
                                  > {};




} // openmodelica
} // parmodelica






#endif // header
