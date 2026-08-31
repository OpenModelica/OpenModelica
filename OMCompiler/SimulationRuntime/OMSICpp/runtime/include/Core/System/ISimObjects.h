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
/** @addtogroup coreSimcontroller
 *
 *  @{
 */


/**
 *
 */
class ISimObjects
{
public:

    virtual ~ISimObjects()
    {
    };
   
    /**
    Creates  SimVars object, stores all model variable in continuous block of memory
       @param  model name
       @param dim_real  number of all real variables (real algebraic vars,discrete algebraic vars, state vars, der state vars)
       @param dim_int   number of all integer variables integer algebraic vars
       @param dim_bool  number of all bool variables (boolean algebraic vars)
       @param dim_pre_vars number of all pre variables (real algebraic vars,discrete algebraic vars, boolean algebraic vars, integer algebraic vars, state vars, der state vars)
       @param dim_z number of all state variables
       @param z_i start index of state vector in real_vars list
       */
    virtual weak_ptr<ISimVars> LoadSimVars(string modelKey, size_t dim_real, size_t dim_int, size_t dim_bool,
                                           size_t dim_string, size_t dim_pre_vars, size_t dim_z, size_t z_i) = 0;
    

  
    virtual shared_ptr<ISimVars> getSimVars(string modelname) = 0;
    
    virtual void eraseSimVars(string modelname) = 0;

    virtual ISimObjects* clone() = 0;

    virtual shared_ptr<IAlgLoopSolverFactory> getAlgLoopSolverFactory() = 0;
};

/** @} */ // end of coreSimcontroller
