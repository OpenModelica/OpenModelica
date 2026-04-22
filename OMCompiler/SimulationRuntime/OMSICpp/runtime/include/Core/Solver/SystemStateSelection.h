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
/** @addtogroup coreSolver
 *
 *  @{
 */
#if defined(__TRICORE__) || defined(__vxworks)
#define BOOST_EXTENSION_STATESELECT_DECL
#endif

#include <Core/System/IStateSelection.h>
#include <boost/shared_array.hpp>

class BOOST_EXTENSION_STATESELECT_DECL SystemStateSelection
{
public:
    SystemStateSelection(IMixedSystem * system);
    ~SystemStateSelection();

  bool stateSelection(int switchStates);
  void initialize();

private:
  void setAMatrix(int* newEnable, unsigned int index);
  int comparePivot(int* oldPivot, int* newPivot, int switchStates, unsigned int index);

    IMixedSystem * _system;
    IStateSelection * _state_selection;
  vector<boost::shared_array<int> > _rowPivot;
  vector<boost::shared_array<int> > _colPivot;
  unsigned int _dimStateSets;
  vector<unsigned int> _dimStates;
  vector<unsigned int> _dimDummyStates;
  vector<unsigned int> _dimStateCanditates;
  bool _initialized;


};
/** @} */ // end of coreSolver
