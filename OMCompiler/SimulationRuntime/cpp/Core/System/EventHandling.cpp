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

/** @addtogroup coreSystem
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/System/FactoryExport.h>
#include <Core/System/ContinuousEvents.h>
#include <Core/System/DiscreteEvents.h>
#include <Core/System/EventHandling.h>

/**
Constructor
\param system Modelica system object
\param dim Dimenson of help variables
*/
EventHandling::EventHandling()
{
  _continuousEvents =  shared_ptr<ContinuousEvents>(new ContinuousEvents());
}

EventHandling::EventHandling(EventHandling& instance)
{
  _continuousEvents =  shared_ptr<ContinuousEvents>(new ContinuousEvents());
}

EventHandling::~EventHandling(void)
{
}

/**
Inits the event variables
*/
shared_ptr<DiscreteEvents> EventHandling::initialize(IEvent* event_system,shared_ptr<ISimVars> sim_vars)
{

  shared_ptr<DiscreteEvents> discreteEvents = shared_ptr<DiscreteEvents>(new DiscreteEvents(sim_vars));
  discreteEvents->initialize();
  //initialize continuous event handling
  _continuousEvents->initialize(event_system);
  return discreteEvents;
}




bool EventHandling::startEventIteration(bool& state_vars_reinitialized)
{
   return _continuousEvents->startEventIteration(state_vars_reinitialized);
}

/** @} */ // end of coreSystem

