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

/** @defgroup simcorefactoriesPolicies SimCoreFactory.Policies
 *  Object factory policy classes for all targets
 *  @{
 */
#if defined(__vxworks)

  /*Defines*/
  #define PATH std::string

  #include <Core/System/ISystemProperties.h>
  #include <Core/System/ISystemInitialization.h>
  #include <Core/System/IWriteOutput.h>
  #include <Core/System/IContinuous.h>
  #include <Core/System/ITime.h>
  #include <Core/System/IEvent.h>
  #include <Core/System/IStepEvent.h>
  #include <Core/Solver/INonLinSolverSettings.h>
  #include <Core/Solver/ILinSolverSettings.h>
  #include <Core/DataExchange/IHistory.h>
  #include <Core/System/IMixedSystem.h>
  #include <Core/SimulationSettings/IGlobalSettings.h>
  #include <Core/System/IMixedSystem.h>
  #include <Core/System/ILinearAlgLoop.h>
  #include <Core/System/INonLinearAlgLoop.h>
  #include <Core/Solver/ISolverSettings.h>
  #include <Core/Solver/ISolver.h>
  #include <Core/Solver/IAlgLoopSolver.h>
  #include <Core/System/IAlgLoopSolverFactory.h>
  #include <Core/System/ISimVars.h>
  #include <Core/DataExchange/ISimVar.h>
  #include <Core/SimController/ISimData.h>
  #include <Core/System/ISimObjects.h>
  #include <Core/SimulationSettings/ISimControllerSettings.h>
  #include <Core/SimController/ISimController.h>
  #include <SimCoreFactory/VxWorksFactory/VxWorksFactory.h>

#elif defined(__TRICORE__)

  /*Defines*/
  #define PATH string
  #include <BodasFactory/BodasFactory.h>

#elif defined(SIMSTER_BUILD)

  /*Defines*/
  #define PATH fs::path
  #include <Genericfactory/GenericFactory.h>

#elif defined(OMC_BUILD) && !defined(RUNTIME_STATIC_LINKING)

  /*Factory includes*/
  #include <Core/Utils/extension/extension.hpp>
  #include <Core/Utils/extension/factory.hpp>
  #include <Core/Utils/extension/type_map.hpp>
  #include <Core/Utils/extension/shared_library.hpp>
  #include <Core/Utils/extension/convenience.hpp>
  #include <Core/Utils/extension/factory_map.hpp>
  /*Namespaces*/
  using namespace boost::extensions;
  using std::string;
  /*Defines*/
  #define PATH string
  #include "LibrariesConfig.h"
  #include <SimCoreFactory/OMCFactory/OMCFactory.h>

#elif defined(OMC_BUILD) && defined(RUNTIME_STATIC_LINKING)

  /*Factory includes*/
  #include <Core/Utils/extension/extension.hpp>
  #include <Core/Utils/extension/factory.hpp>
  #include <Core/Utils/extension/type_map.hpp>
  #include <Core/Utils/extension/shared_library.hpp>
  #include <Core/Utils/extension/convenience.hpp>
  /*Namespaces*/
  using namespace boost::extensions;
  using std::string;
  /*Defines*/
  #define PATH string
  #include "LibrariesConfig.h"
  /*interface includes*/
  #include <Core/System/ISystemProperties.h>
  #include <Core/System/ISystemInitialization.h>
  #include <Core/System/IWriteOutput.h>
  #include <Core/System/IContinuous.h>
  #include <Core/System/ITime.h>
  #include <Core/System/IEvent.h>
  #include <Core/System/IStepEvent.h>
  #include <Core/Solver/INonLinSolverSettings.h>
  #include <Core/Solver/ILinSolverSettings.h>
  #include <Core/DataExchange/IHistory.h>
  #include <Core/SimulationSettings/IGlobalSettings.h>
  #include <Core/System/ILinearAlgLoop.h>
  #include <Core/System/INonLinearAlgLoop.h>
  #include <Core/Solver/ISolverSettings.h>
  #include <Core/Solver/ISolver.h>
  #include <Core/Solver/ILinearAlgLoopSolver.h>
  #include <Core/Solver/INonLinearAlgLoopSolver.h>
  #include <Core/System/IAlgLoopSolverFactory.h>
  #include <Core/System/ISimVars.h>
  #include <Core/DataExchange/ISimVar.h>
  #include <Core/SimController/ISimData.h>
  #include <Core/System/ISimObjects.h>
  #include <Core/System/IMixedSystem.h>
  #include <Core/SimulationSettings/ISimControllerSettings.h>
  #include <Core/SimController/ISimController.h>
  #include <SimCoreFactory/OMCFactory/StaticOMCFactory.h>
#else
  #error "operating system not supported"
#endif

/** @} */ // end of simcorefactoriesPolicies
