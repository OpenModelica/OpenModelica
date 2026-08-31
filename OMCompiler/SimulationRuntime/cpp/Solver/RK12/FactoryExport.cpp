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

/** @addtogroup solverEuler
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#if defined(__vxworks)


#include <Solver/RK12/RK12.h>
#include <Solver/RK12/RK12Settings.h>

extern "C" ISolver* createEuler(IMixedSystem* system, ISolverSettings* settings)
{
    return new Euler(system,settings);
}

extern "C" ISolverSettings* createEulerSettings(IGlobalSettings* globalSettings)
{
    return new EulerSettings(globalSettings);
}

#elif defined(SIMSTER_BUILD)

#include <Policies/FactoryConfig.h>
#include <Solver/RK12/RK12.h>
#include <Solver/RK12/RK12Settings.h>

/*Simster factory*/
extern "C" void BOOST_EXTENSION_EXPORT_DECL extension_export_euler(boost::extensions::factory_map & fm)
{
    fm.get<ISolver,int,IMixedSystem*, ISolverSettings*>()[1].set<Euler>();
    fm.get<ISolverSettings,int, IGlobalSettings* >()[2].set<RK12Settings>();
}

#elif defined(OMC_BUILD)


#include <SimCoreFactory/OMCFactory/OMCFactory.h>
#include <Solver/RK12/RK12.h>
#include <Solver/RK12/RK12Settings.h>

    /* OMC factory */
    using boost::extensions::factory;

    BOOST_EXTENSION_TYPE_MAP_FUNCTION {
    types.get<std::map<std::string, factory<ISolver,IMixedSystem*, ISolverSettings*> > >()
    ["rk12Solver"].set<RK12>();
    types.get<std::map<std::string, factory<ISolverSettings, IGlobalSettings* > > >()
    ["rk12Settings"].set<RK12Settings>();
    }

#else
error "operating system not supported"
#endif

/** @} */ // end of solverEuler

