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
/** @addtogroup coreSystem
 *
 *  @{
 */
/**
Auxiliary  class to handle system events
Implements the Modelica pre,edge,change operators
Holds a help vector for the discrete variables
Holds an event queue to handle all events occured at the same time
*/

class ContinuousEvents;
class DiscreteEvents;
/*
#ifdef RUNTIME_STATIC_LINKING
class EventHandling
#else*/
class BOOST_EXTENSION_EVENTHANDLING_DECL EventHandling
/*#endif*/
{
public:
  EventHandling();
  EventHandling(EventHandling& instance);
  virtual ~EventHandling(void);
  //Inits the event variables
   shared_ptr<DiscreteEvents> initialize(IEvent* system,shared_ptr<ISimVars> sim_vars);


  //saves a variable in _pre_vars vector
  bool startEventIteration(bool& state_vars_reinitialized);

private:
shared_ptr<ContinuousEvents> _continuousEvents;

};
/** @} */ // end of coreSystem