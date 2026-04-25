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
#ifndef idD09C04B9_F1BC_4139_8CFF2E562C8C1060
#define idD09C04B9_F1BC_4139_8CFF2E562C8C1060

/*
 Mahder.Gebremedhin@liu.se  2020-10-12
*/

#include <tbb/task_scheduler_init.h>
#include <simulation_data.h>

#include "pm_cluster_level_scheduler.hpp"
#include "pm_cluster_dynamic_scheduler.hpp"

#include "pm_timer.hpp"

#include "om_pm_equation.hpp"



namespace openmodelica {
namespace parmodelica {


class OMModel;

struct Equation : public TaskNode {

    typedef void (*FunctionType)(DATA *, threadData_t*);
private:
    FunctionType* function_system;
    DATA *data;
    threadData_t* threadData;

public:
    Equation();

    long index;
    std::set<std::string> lhs;
    std::set<std::string> rhs;
    std::string type;

    bool depends_on(const TaskNode&) const;

    void execute();

    friend class OMModel;

};


class OMModel
  : boost::noncopyable {
    typedef Equation::FunctionType FunctionType;

    // typedef LevelSchedulerThreadAware<Equation> SchedulerT;
    // typedef LevelSchedulerThreadOblivious<Equation> SchedulerT;
    // typedef DynamicScheduler<Equation> SchedulerT;
    // typedef TaskSystem<Equation> TaskSystemT;
#ifdef USE_LEVEL_SCHEDULER
    typedef StepLevels<Equation> SchedulerT;
#else
  #ifdef USE_FLOW_SCHEDULER
    typedef ClusterDynamicScheduler<Equation> SchedulerT;
  #else
    #error "please specify scheduler. See makefile"
  #endif
#endif
    typedef TaskSystem_v2<Equation> TaskSystemT;



public:
    std::string name;
    size_t max_num_threads;
    tbb::task_scheduler_init tbb_system;

    bool intialized;
    DATA* data;
    threadData_t* threadData;


public:
    OMModel(const std::string& name, size_t max_num_threads);
    void load_ODE_system();

    PMTimer load_system_timer;

    FunctionType* ini_system_funcs;
    TaskSystemT INI_system;
    SchedulerT INI_scheduler;

    FunctionType* dae_system_funcs;
    TaskSystemT DAE_system;
    SchedulerT DAE_scheduler;

    FunctionType* ode_system_funcs;
    TaskSystemT ODE_system;
    SchedulerT ODE_scheduler;

    FunctionType alg_system_funcs;
    TaskSystemT ALG_system;
    SchedulerT ALG_scheduler;

    void load_from_xml(TaskSystemT&, const std::string&, FunctionType*);
    void load_from_json(TaskSystemT&, const std::string&, FunctionType*);
};








} // openmodelica
} // parmodelica



#endif // header
