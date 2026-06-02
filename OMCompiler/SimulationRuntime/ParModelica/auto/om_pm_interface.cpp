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

/*
 Mahder.Gebremedhin@liu.se  2020-10-12
*/

#include <iostream>
#include <algorithm>
#include <cstring>

#include <tbb/task_arena.h>
#include <tbb/task_scheduler_observer.h>

#include "gc.h"

#include "om_pm_interface.hpp"
#include "om_pm_model.hpp"

namespace {

/* The simulation runtime allocates with the Boehm GC, which only scans threads
   that have registered with it. Unlike the old (patched) TBB fork that spawned
   its workers via GC_pthread_create, stock oneTBB worker threads are unknown to
   the GC, so model code allocating on a worker (e.g. simple_array_alloc_copy)
   corrupts the GC heap and crashes. This global task_scheduler_observer mirrors
   the C runtime's OpenMP handling (see dassl.c): register every worker thread
   with the GC as it enters a TBB arena. Threads stay registered for their
   lifetime (TBB workers are pooled for the whole run), matching the C runtime. */
class GCThreadRegistrationObserver : public tbb::task_scheduler_observer {
public:
    GCThreadRegistrationObserver() : tbb::task_scheduler_observer() {
        GC_allow_register_threads();
        observe(true);
    }
    void on_scheduler_entry(bool /*is_worker*/) override {
        if (!GC_thread_is_registered()) {
            struct GC_stack_base sb;
            memset(&sb, 0, sizeof(sb));
            GC_get_stack_base(&sb);
            GC_register_my_thread(&sb);
        }
    }
};

/* Activate GC registration of TBB worker threads exactly once. */
void ensure_gc_thread_registration() {
    static GCThreadRegistrationObserver observer;
    (void)observer;
}

} // anonymous namespace

extern "C" {

using namespace openmodelica::parmodelica;
typedef Equation::FunctionType FunctionType;

PMTimer seq_ode_timer;

void* PM_Model_create(const char* model_name, DATA* data, threadData_t* threadData, size_t in_max_num_threads) {

    /* When the user does not request a specific thread count (-parmodNumThreads),
       do NOT default to all hardware threads. These task graphs are fine-grained
       and often memory-bound, so a large TBB arena oversubscribes the few ready
       tasks per level and the parallel run ends up slower than serial on
       many-core machines. Cap the default at a modest value; users can still
       override upwards explicitly. */
    const size_t default_thread_cap = 6;
    size_t max_num_threads = in_max_num_threads
                                 ? in_max_num_threads
                                 : std::min((size_t)tbb::this_task_arena::max_concurrency(), default_thread_cap);

    // Make TBB worker threads known to the Boehm GC before any task runs model code.
    ensure_gc_thread_registration();

    OMModel* pm_om_model = new OMModel(model_name, max_num_threads);
    pm_om_model->data = data;
    pm_om_model->threadData = threadData;

    return pm_om_model;
}

void PM_Model_load_ODE_system(void* v_model, FunctionType* ode_system_funcs) {

    OMModel& model = *(static_cast<OMModel*>(v_model));
    model.ode_system_funcs = ode_system_funcs;
    model.load_ODE_system();
}

void PM_evaluate_ODE_system(void* v_model) {

    OMModel& model = *(static_cast<OMModel*>(v_model));
    model.ODE_scheduler.execute();

    // pm_om_model.ODE_scheduler.execution_timer.start_timer();
    // for(int i = 0; i < size; ++i)
    // functionODE_systems[i](data, threadData);
    // pm_om_model.ODE_scheduler.execution_timer.stop_timer();
}

void seq_ode_timer_start() {
    seq_ode_timer.start_timer();
}

void seq_ode_timer_stop() {
    seq_ode_timer.stop_timer();
}

void seq_ode_timer_reset() {
    seq_ode_timer.reset_timer();
}

void seq_ode_timer_get_elapsed_time2() {
    std::cerr << seq_ode_timer.get_elapsed_time();
}

double seq_ode_timer_get_elapsed_time() {
    return seq_ode_timer.get_elapsed_time();
}

void dump_times(void* v_model) {
    OMModel& model = *(static_cast<OMModel*>(v_model));

#ifdef USE_LEVEL_SCHEDULER
    utility::log("") << "Using level scheduler" << std::endl;
#else
#ifdef USE_FLOW_SCHEDULER
    utility::log("") << "Using flow scheduler" << std::endl;
#else
#error "please specify scheduler. See makefile"
#endif
#endif
    utility::log("") << "Nr.of threads " << model.max_num_threads << std::endl;
    utility::log("") << "Nr.of ODE evaluations: " << model.ODE_scheduler.total_evaluations << std::endl;
    utility::log("") << "Nr.of profiling ODE Evaluations: " << model.ODE_scheduler.sequential_evaluations << std::endl;
    // utility::log("") << "Total ODE evaluation time : " << model.ODE_scheduler.total_parallel_cost << std::endl;
    utility::log("") << "Total ODE evaluation time : " << model.ODE_scheduler.execution_timer.get_elapsed_time()
                     << std::endl;
    utility::log("") << "Avg. ODE evaluation time : "
                     << model.ODE_scheduler.execution_timer.get_elapsed_time() /
                            model.ODE_scheduler.parallel_evaluations
                     << std::endl;
    utility::log("") << "Total ODE loading time: " << model.load_system_timer.get_elapsed_time() << std::endl;
    utility::log("") << "Total ODE Clustering time: " << model.ODE_scheduler.clustering_timer.get_elapsed_time()
                     << std::endl;
}

} // extern "C"
