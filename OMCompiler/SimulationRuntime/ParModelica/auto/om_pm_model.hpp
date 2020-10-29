#pragma once
#ifndef idD09C04B9_F1BC_4139_8CFF2E562C8C1060
#define idD09C04B9_F1BC_4139_8CFF2E562C8C1060

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

#include <simulation_data.h>

// #include "pm_task_system.hpp"
#include "pm_cluster_level_scheduler.hpp"
#include "pm_cluster_dynamic_scheduler.hpp"

// #include "pm_level_scheduler.hpp"
// #include "pm_dynamic_scheduler.hpp"

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
    bool intialized;
    DATA* data;
    threadData_t* threadData;

public:
    OMModel(const std::string&);
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
