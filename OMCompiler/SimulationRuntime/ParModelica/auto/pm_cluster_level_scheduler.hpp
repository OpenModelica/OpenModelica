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

#include "gc.h"

#include <tbb/parallel_for.h>
#include <tbb/task_scheduler_init.h>
#include <tbb/tick_count.h>

// #include <sys/types.h>
// #include <sys/syscall.h>

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
    std::set<pid_t>& knownthreads;

public:
    TBBConcurrentStepExecutor(GraphType& g, std::set<pid_t>& k) : sys_graph(g) , knownthreads(k) {}

    void operator()( tbb::blocked_range<ClusteIdIter>& range ) const {

        // pid_t id;
        // /* Register thread to bohem GC if it is not registered already*/
        // if(!GC_thread_is_registered()) {
            // id = syscall(SYS_gettid);
            // fprintf(stderr,"Found unregisterd thread =  %d \n", id);

            // struct GC_stack_base sb;
            // memset (&sb, 0, sizeof(sb));
            // GC_get_stack_base(&sb);
            // GC_register_my_thread (&sb);
            // // std::cerr << "New Theread registerd = " << GC_thread_is_registered() << std::endl;
        // }
        // else {
            // id = syscall(SYS_gettid);
            // if(!knownthreads.count(id)) {
                // fprintf(stderr,"parmod registerd thread =  %d \n", id);
                // knownthreads.insert(id);
            // }
        // }

        for(ClusteIdIter clustid_iter = range.begin(); clustid_iter != range.end(); ++clustid_iter) {
            ClusterIdType& curr_clust_id = *clustid_iter;
            ClusterType& curr_clust = sys_graph[curr_clust_id];

            curr_clust.execute();
        }
    }

};



template<typename TaskType,
         typename clustetring1 = cluster_merge_common, /* for now default here*/
         typename clustetring2 = cluster_merge_level_for_bins, /* for now default here*/
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


public:
    const TaskSystemType& task_system_org;
    TaskSystemType task_system;


    bool profiled;
    bool schedule_available;

    tbb::task_scheduler_init tbb_system;
    TBBConcurrentStepExecutor<TaskType> step_executor;

    std::set<pid_t> knownthreads;

    int total_evaluations;
    int parallel_evaluations;
    int sequential_evaluations;

    double par_avg_at_last_sch;
    double par_current_avg;
    double total_parallel_cost;
    bool has_run_parallel;
public:

    std::string name;

    PMTimer execution_timer;
	PMTimer clustering_timer;
    PMTimer step_timer;

    std::vector<double> parallel_eval_costs;


    StepLevels(TaskSystemType& ts) :
      task_system_org(ts)
      , task_system("invalid")  // implement a constrctor with no parameters and remove this
      , tbb_system(NUM_THREADS)
      , step_executor(task_system.sys_graph, knownthreads)
    {
        GC_allow_register_threads();
        // GC_use_threads_discovery();

        profiled = false;
        schedule_available = false;

        total_evaluations = 0;
        parallel_evaluations = 0;
        sequential_evaluations = 0;

        total_parallel_cost = 0;
        par_avg_at_last_sch = 0;
        has_run_parallel = false;

    }

    bool avg_needs_reschedule() {

        double diff = std::abs(par_avg_at_last_sch - par_current_avg);
        double change = diff/par_avg_at_last_sch;

        if(change > 0.5) {
            // std::cout << "Reschedule needed P: " << par_avg_at_last_sch << " :C: " << par_current_avg << std::endl;
            return true;
        }

        return false;
    }

    bool reschedule_needed() {
        if(!this->schedule_available)
            return true;


        if(this->avg_needs_reschedule())
            return true;

        return false;
    }

    void clear_schedule() {
        task_system = task_system_org;

        profiled = false;
        schedule_available = false;

    }

    void execute_and_schedule() {
        clear_schedule();
        profile_execute();
        schedule();
        par_avg_at_last_sch = par_current_avg;
    }

    void schedule() {

        clustering_timer.start_timer();

        if(task_system.levels_valid == false)
            task_system.update_node_levels();

        // clustetring1::apply(task_system);
		// clustetring1::dump_graph(task_system, std::to_string(this->total_evaluations));

        clustetring2::apply(task_system);
		// clustetring2::dump_graph(task_system, std::to_string(this->total_evaluations));

        clustetring3::apply(task_system);
		clustetring3::dump_graph(task_system);

		clustetring4::apply(task_system);
		clustetring4::dump_graph(task_system);

        clustetring5::apply(task_system);
		clustetring5::dump_graph(task_system);

        schedule_available = true;
        task_system.levels_valid = false;
        task_system.update_node_levels();

        estimate_speedup();
		clustering_timer.stop_timer();


        // task_system_org.dump_graphml("original");


    }


    void execute()
    {

        if(this->reschedule_needed())
            return execute_and_schedule();

        // paranoia
        if(task_system.levels_valid == false)
            exit(1);

        execution_timer.start_timer();
        step_timer.start_timer();

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
        step_timer.stop_timer();

        ++this->total_evaluations;
        ++this->parallel_evaluations;


        // if(total_evaluations%100 == 0) {
            double step_cost = step_timer.get_elapsed_time();
            parallel_eval_costs.push_back(step_cost);
            total_parallel_cost += step_cost;
            par_current_avg = total_parallel_cost/this->parallel_evaluations;
            // std::cout << total_evaluations << " : " << parallel_evaluations << " : " << step_cost << " : " << par_current_avg << std::endl;
            // std::cout << "P" <<  " : " << total_evaluations << " : " << step_cost << " : "<< par_current_avg << std::endl;
            step_timer.reset_timer();
        // }

        if(!has_run_parallel) {
            par_avg_at_last_sch = par_current_avg;
            has_run_parallel = true;
        }

    }


    void profile_execute()
    {

        // if(this->total_evaluations == 0)
            // std::cout << "Type" <<  " : " << "Eval" << " : " << "Eval_cost" << " : "<< "Curr_Par_Avg" << " : " << "Prev_Sch_Avg"<< std::endl;

        GraphType& sys_graph = task_system.sys_graph;

        typename GraphType::vertex_iterator vert_iter, vert_end;
        boost::tie(vert_iter, vert_end) = vertices(sys_graph);

        execution_timer.start_timer();
        step_timer.start_timer();
        /*! skip the root node. */
        ++vert_iter;
        for ( ; vert_iter != vert_end; ++vert_iter) {
            sys_graph[*vert_iter].profile_execute();
        }
        ++this->total_evaluations;
        ++this->sequential_evaluations;

        step_timer.stop_timer();
        execution_timer.stop_timer();

        double step_cost = step_timer.get_elapsed_time();
        // utility::log("") << "Profiled on step :" << this->total_evaluations << " cost: " << step_cost << std::endl;
        std::cout << "S" <<  " : " << this->total_evaluations << " : " << step_cost << " : " << par_current_avg << " : " << par_avg_at_last_sch << std::endl;
        step_timer.reset_timer();


        // task_system.dump_graphml("profiled_" + std::to_string(this->total_evaluations));

        this->profiled = true;
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
            // sort in decreasing order
            std::sort(current_level.rbegin(), current_level.rend(), cccbi);
            total_level_scheduler_cost += sys_graph[current_level.front()].cost;

            total_system_cost += current_level.total_level_cost;
        }

        // utility::log("") << "Total_system_cost: " << total_system_cost << std::endl;
        // utility::log("") << "Total_level_scheduler_cost: " << total_level_scheduler_cost << std::endl;
        // utility::log("") << "Ideal speedup: " << total_system_cost/total_level_scheduler_cost << std::endl;

    }

};


/*! The default level scheduler uses these two clusterings*/
//template<typename Tasktype>
//using LevelScheduler = StepLevels<TaskType
                                    // , cluster_merge_common
                                    // , cluster_merge_level_for_bins
                                   // >;

template<typename TaskType>
struct LevelScheduler : StepLevels<TaskType
                                    , cluster_merge_common
                                    , cluster_merge_level_for_bins
                                  > {};




} // openmodelica
} // parmodelica






#endif // header
