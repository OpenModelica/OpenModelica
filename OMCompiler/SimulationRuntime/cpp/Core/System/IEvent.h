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

/*****************************************************************************/
/**

Abstract interface class for discrete systems in open modelica.

\date     October, 1st, 2008
\author

*/



typedef std::map<double,unsigned long> event_times_type;
class IEvent
{
public:
    virtual ~IEvent()    {};

    /// Provide number (dimension) of zero functions
    virtual int getDimZeroFunc() = 0;
     virtual int getDimClock() = 0;
    /// Provides current values of root/zero functions
    virtual void getZeroFunc(double* f) = 0;
    /// Set tolerance for zero crossings
    virtual void setZeroTol(double dt) = 0;
    /// Set and get conditions
    virtual void setConditions(bool* c) = 0;
    virtual void getConditions(bool* c) = 0;
    virtual void getClockConditions(bool* c) = 0;
    //Deactivated: virtual void saveDiscreteVars() = 0;
     //Saves all variables before an event is handled, is needed for the pre, edge and change operator
    virtual void saveAll() = 0;
    /// Called to handle an event
    virtual void handleEvent(const bool* events) = 0;
    ///Checks if a discrete variable has changed and triggered an event, returns true if a second event iteration is needed
    virtual bool checkForDiscreteEvents() = 0;
    virtual  bool getCondition(unsigned int index) = 0;
    //virtual void initPreVariables(unordered_map<double* const,unsigned int>&,unordered_map<int* const,unsigned int>&,unordered_map<bool* const,unsigned int>&)= 0;
};
/** @} */ // end of coreSystem