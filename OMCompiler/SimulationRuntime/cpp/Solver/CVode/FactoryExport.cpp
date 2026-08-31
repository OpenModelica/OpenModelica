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

/** @addtogroup solverCvode
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#if defined(__vxworks)


#elif defined(SIMSTER_BUILD)




/*Simster factory*/
extern "C" void BOOST_EXTENSION_EXPORT_DECL extension_export_cvode(boost::extensions::factory_map & fm)
{
    fm.get<ISolver,int,IMixedSystem*, ISolverSettings*>()[1].set<Cvode>();
    //fm.get<ISolverSettings,int, IGlobalSettings* >()[2].set<CVodeSettings>();
}

#elif defined(OMC_BUILD) && !defined(RUNTIME_STATIC_LINKING)

#include <Solver/CVode/CVode.h>
#include <Solver/CVode/CVodeSettings.h>

    /* OMC factory */
    using boost::extensions::factory;

    BOOST_EXTENSION_TYPE_MAP_FUNCTION {
    types.get<std::map<std::string, factory<ISolver,IMixedSystem*, ISolverSettings*> > >()
    ["cvodeSolver"].set<Cvode>();
    types.get<std::map<std::string, factory<ISolverSettings, IGlobalSettings* > > >()
    ["cvodeSettings"].set<CVodeSettings>();
    }
#elif defined(OMC_BUILD) && defined(RUNTIME_STATIC_LINKING)
#include <Solver/CVode/CVodeSettings.h>
#include <Solver/CVode/CVode.h>
#include <Solver/IDA/IDASettings.h>
#include <Solver/IDA/IDA.h>

  #ifdef ENABLE_SUNDIALS_STATIC
    shared_ptr<ISolver> createCVode(IMixedSystem* system, shared_ptr<ISolverSettings> solver_settings)
    {
        shared_ptr<ISolver> cvode = shared_ptr<ISolver>(new Cvode(system,solver_settings.get()));
        return cvode;
    }
    shared_ptr<ISolverSettings> createCVodeSettings(shared_ptr<IGlobalSettings> globalSettings)
    {
         shared_ptr<ISolverSettings> cvode_settings = shared_ptr<ISolverSettings>(new CVodeSettings(globalSettings.get()));
         return cvode_settings;
    }
  #else
    shared_ptr<ISolver> createCVode(IMixedSystem* system, shared_ptr<ISolverSettings> solver_settings)
    {
      throw ModelicaSimulationError(SOLVER,"CVode was disabled during build");
    }
    shared_ptr<ISolverSettings> createCVodeSettings(shared_ptr<IGlobalSettings> globalSettings)
    {
      throw ModelicaSimulationError(SOLVER,"CVode was disabled during build");
    }
  #endif //ENABLE_SUNDIALS_STATIC

#else
error "operating system not supported"
#endif
/** @} */ // end of solverCvode

