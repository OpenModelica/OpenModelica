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

//OpenModelica Simulation Interface
#include <omsi.h>

class IOMSI
{
public:
    virtual omsi_status initialize_omsi_evaluate_functions(omsi_function_t* omsi_function) = 0;
    virtual omsi_status omsi_evaluateAll(omsi_function_t* simulation, const omsi_values* model_vars_and_params,
                                         void* data) = 0;
};

class IOMSIInitialize
{
public:
    virtual omsi_status initialize_omsi_initialize_functions(omsi_function_t* omsi_function) = 0;
    virtual omsi_status omsi_initializeAll(omsi_function_t* simulation, const omsi_values* model_vars_and_params,
                                           void* data) = 0;
};


class OMSICallBackWrapper
{
public:
    static omsi_status evaluate(struct omsi_function_t* this_function,
                                const omsi_values* read_only_vars_and_params,
                                void* data)
    {
        return _omsu_system->omsi_evaluateAll(this_function, read_only_vars_and_params, data);
    };

    static omsi_status initialize(struct omsi_function_t* this_function,
                                  const omsi_values* read_only_vars_and_params,
                                  void* data)
    {
        return _omsu_initialize->omsi_initializeAll(this_function, read_only_vars_and_params, data);
    };

    static omsi_status setUpInitializeFunction(omsi_function_t* omsi_function)
    {
        return _omsu_initialize->initialize_omsi_initialize_functions(omsi_function);
    };

    static omsi_status setUpEvaluateFunction(omsi_function_t* omsi_function)
    {
        return _omsu_system->initialize_omsi_evaluate_functions(omsi_function);
    };

    static void setOMSISystem(IOMSI& obj)
    {
        _omsu_system = &obj;
    }

    static void setOMSIInitialize(IOMSIInitialize& obj)
    {
        _omsu_initialize = &obj;
    }

private:
    static IOMSI* _omsu_system;
    static IOMSIInitialize* _omsu_initialize;
};
