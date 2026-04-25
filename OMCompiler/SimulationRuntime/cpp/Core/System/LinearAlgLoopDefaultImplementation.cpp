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
#include <Core/System/LinearAlgLoopDefaultImplementation.h>

LinearAlgLoopDefaultImplementation::LinearAlgLoopDefaultImplementation()
  : _dimAEq         (0)
  ,_b(NULL)
  ,_AData(NULL)
  ,_Ax(NULL)
  ,_x0(NULL)
 , _firstcall(true)
{

}

LinearAlgLoopDefaultImplementation::~LinearAlgLoopDefaultImplementation()
{
  if(_b)
    delete [] _b;
 if (_x0)
	 delete [] _x0;
}

/// Provide number (dimension) of variables according to data type
int LinearAlgLoopDefaultImplementation::getDimReal() const
{
  return _dimAEq;
}

int LinearAlgLoopDefaultImplementation::getDimZeroFunc() const
{
   return _dimZeroFunc;
}
/// (Re-) initialize the system of equations
void LinearAlgLoopDefaultImplementation::initialize()
{
  if ( _dimAEq == 0 )
    throw ModelicaSimulationError(ALGLOOP_EQ_SYSTEM,"AlgLoop::initialize(): No constraint defined.");

  if(_b)
    delete [] _b;
  _b     = new double[_dimAEq];
  memset(_b,0,_dimAEq*sizeof(double));
  if(_x0)
	  delete [] _x0;
  _x0 = new double[_dimAEq];
};

void LinearAlgLoopDefaultImplementation::getb(double* res) const
{
  memcpy(res, _b, sizeof(double) * _dimAEq);
}


bool LinearAlgLoopDefaultImplementation::getUseSparseFormat(){
  return _useSparseFormat;
}

void LinearAlgLoopDefaultImplementation::setUseSparseFormat(bool value){
  _useSparseFormat = value;
}
void LinearAlgLoopDefaultImplementation::getRealStartValues(double* vars) const
{
    memcpy(vars, _x0, sizeof(double) * _dimAEq);
}


//void LinearAlgLoopDefaultImplementation::getSparseAdata(double* data, int nonzeros)
//{
//  memcpy(data, _AData, sizeof(double) * nonzeros);
//}
/** @} */ // end of coreSystem
