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
class IHistory;

class IWriteOutput
{
public:
    /// Enumeration to control the output
    enum OUTPUT
    {
        UNDEF_OUTPUT = 0x00000000,
        WRITEOUT = 0x00000001,
        ///< vxworks! Store current position of curser and write out current results
        RESET = 0x00000002,
        ///< Reset curser position
        OVERWRITE = 0x00000003,
        ///< RESET|WRITE
        HEAD_LINE = 0x00000010,
        ///< Write out head line
        RESULTS = 0x00000020,
        ///< Write out results
        SIMINFO = 0x00000040 ///< Write out simulation info (e.g. number of steps)
    };

    virtual ~IWriteOutput()
    {
    };


  /// Output routine (to be called by the solver after every successful integration step)
  virtual void writeOutput(const OUTPUT command = UNDEF_OUTPUT) = 0;
  virtual shared_ptr<IHistory> getHistory() = 0;

};

/** @} */ // end of coreSystem
