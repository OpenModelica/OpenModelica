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
/** @defgroup coreSystem Core.System
 *  Core module for all algebraic and ode systems
 *  @{
 */
/*****************************************************************************/
/**

Services, which can be used by systems.
Implementation of standart functions (e.g. giveRHS(...), etc.).
Provision of member variables used by all systems.

Note:
The order of variables in the extended state vector perserved (see: "Sorting
variables by using the index" in "Design proposal for a general solver interface
for Open Modelica", September, 10 th, 2008
*/

//omsi header
#include <omsi.h>


#include <Core/System/SystemDefaultImplementation.h>

class BOOST_EXTENSION_EXTENDEDSYSTEM_DECL ExtendedSystem : public SystemDefaultImplementation
{
public:
    ExtendedSystem(shared_ptr<IGlobalSettings> globalSettings, string modelName,
                             size_t dim_real, size_t dim_int, size_t dim_bool, size_t dim_string, size_t dim_pre_vars,
                                size_t dim_z, size_t z_i);
   
    ExtendedSystem(shared_ptr<IGlobalSettings> globalSettings, string modelName, omsi_t * omsu);
    
    ExtendedSystem(shared_ptr<IGlobalSettings> globalSettings);
    ExtendedSystem(ExtendedSystem & instance);
    virtual ~ExtendedSystem();

 

    shared_ptr<ISimData > getSimData();
 
protected:
   
    
    //optional OMSI instance
    omsi_t * _omsu;
   
    
};


/** @} */ // end of coreSystem
