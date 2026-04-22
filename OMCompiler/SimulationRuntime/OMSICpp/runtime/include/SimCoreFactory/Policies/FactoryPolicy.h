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

/** @addtogroup simcorefactoriesPolicies
 *
 *  @{
 */
#include <SimCoreFactory/ObjectFactory.h>

#if defined(OMC_BUILD) && !defined(RUNTIME_STATIC_LINKING)


    /*Policy include*/
    #include <SimCoreFactory/Policies/SolverOMCFactory.h>
    #include <SimCoreFactory/Policies/SolverSettingsOMCFactory.h>
    #include <SimCoreFactory/Policies/SystemOMCFactory.h>
    #include <SimCoreFactory/Policies/NonLinSolverOMCFactory.h>
    #include <SimCoreFactory/Policies/LinSolverOMCFactory.h>
    #include <SimCoreFactory/Policies/SimObjectOMCFactory.h>
    #include <SimCoreFactory/Policies/ExtendedSimObjectOMCFactory.h>
    /*Policy defines*/
    typedef OMCFactory BaseFactory;
    typedef SystemOMCFactory<BaseFactory> SimControllerPolicy;
    typedef SimObjectOMCFactory<BaseFactory> SimObjectPolicy;
    typedef ExtendedSimObjectOMCFactory<BaseFactory> ExtendedSimObjectPolicy;
    typedef SolverOMCFactory<BaseFactory> ConfigurationPolicy;
    typedef LinSolverOMCFactory<BaseFactory> LinSolverPolicy;
    typedef NonLinSolverOMCFactory<BaseFactory> NonLinSolverPolicy;
    typedef SolverSettingsOMCFactory<BaseFactory> SolverSettingsPolicy;

#elif defined(OMC_BUILD) && defined(RUNTIME_STATIC_LINKING)

  /*Policy include*/
  #include <SimCoreFactory/OMCFactory/OMCFactory.h>
  #include <SimCoreFactory/Policies/StaticSolverOMCFactory.h>
  #include <SimCoreFactory/Policies/StaticSolverSettingsOMCFactory.h>
  #include <SimCoreFactory/Policies/StaticSystemOMCFactory.h>
  #include <SimCoreFactory/Policies/StaticLinSolverOMCFactory.h>
  #include <SimCoreFactory/Policies/StaticNonLinSolverOMCFactory.h>
  #include <SimCoreFactory/Policies/StaticSimObjectOMCFactory.h>
#include <SimCoreFactory/Policies/StaticExtendedSimObjectOMCFactory.h>
  /*Policy defines*/
  typedef BaseOMCFactory BaseFactory;
  typedef StaticSystemOMCFactory<BaseFactory> SimControllerPolicy;
  typedef StaticSimObjectOMCFactory<BaseFactory> SimObjectPolicy;
  typedef StaticExtendedSimObjectOMCFactory<BaseFactory> ExtendedSimObjectPolicy;
  typedef StaticSolverOMCFactory<BaseFactory> ConfigurationPolicy;
  typedef StaticLinSolverOMCFactory<BaseFactory> LinSolverPolicy;
  typedef StaticNonLinSolverOMCFactory<BaseFactory> NonLinSolverPolicy;
  typedef StaticSolverSettingsOMCFactory<BaseFactory> SolverSettingsPolicy;

//#else
//    #error "operating system not supported"
#endif
/** @} */ // end of simcorefactoriesPolicies
