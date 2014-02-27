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



#include "pm_task_system.hpp"
#include "pm_level_scheduler.hpp"
#include "pm_timer.hpp"

#include "om_pm_equation.hpp"



extern "C" void PM_Model_init(const char*, void*);


namespace openmodelica {
namespace parmodelica {


class OMModel {

public:
    typedef void (*om_function_system)(void *);

private:    
    std::string model_name;
    bool intialized;
    void* data;
    
public:    
    OMModel();
    
    
    om_function_system* ini_system_funcs;
    TaskSystem<Equation> INI_system;
    LevelScheduler<Equation> INI_scheduler;
    void system_execute_ini();
    
    om_function_system* dae_system_funcs;
    TaskSystem<Equation> DAE_system;  
    LevelScheduler<Equation> DAE_scheduler;
    void system_execute_dae();
    
    om_function_system* ode_system_funcs;
    TaskSystem<Equation> ODE_system;
    LevelScheduler<Equation> ODE_scheduler;
    void system_execute_ode();
    
    PMTimer total_alg_time;
    TaskSystem<Equation> ALG_system;
        
    void initialize();
    
    // This needs explicit global scoping because of the extern "C" qualifier. 
    friend void ::PM_Model_init(const char* , void* );

};








} // openmodelica
} // parmodelica



#endif // header
