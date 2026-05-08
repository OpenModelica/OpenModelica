/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package SimCodeUtil

import SimCode;
import SimCodeFunction;
import SimCodeVar;

function sortEqSystems<T>
  input T eqs;
  output T outEqs;
algorithm
  assert(false, getInstanceName());
end sortEqSystems;

function eqInfo<T>
  input T eq;
  output SourceInfo info;
algorithm
  assert(false, getInstanceName());
end eqInfo;

function getSimCode
  output SimCode.SimCode code;
algorithm
  assert(false, getInstanceName());
end getSimCode;

function cref2simvar<A,B>
  input A inCref;
  input B inCrefToSimVarHT;
  output SimCodeVar.SimVar outSimVar;
algorithm
  assert(false, getInstanceName());
end cref2simvar;

function simVarFromHT<A,B>
  input A inCref;
  input B simCode;
  output SimCodeVar.SimVar outSimVar;
algorithm
  assert(false, getInstanceName());
end simVarFromHT;

function localCref2SimVar<A,B>
  input A inCref;
  input B inCrefToSimVarHT;
  output SimCodeVar.SimVar outSimVar;
algorithm
  assert(false, getInstanceName());
end localCref2SimVar;

function localCref2Index<A,B>
  input A inCref;
  input B inOMSIFunction;
  output String outIndex;
algorithm
  assert(false, getInstanceName());
end localCref2Index;

function codegenExpSanityCheck
  input output DAE.Exp e;
  input SimCodeFunction.Context context;
algorithm
  /* Do nothing */
end codegenExpSanityCheck;

function getExpNominal
  input output DAE.Exp e;
algorithm
  /* Do nothing */
end getExpNominal;

function getValueReference
  input SimCodeVar.SimVar inSimVar;
  input SimCode.SimCode inSimCode;
  input Boolean inElimNegAliases;
  output String outValueReference;
algorithm
  /* Do nothing */
end getValueReference;

function getLocalValueReference<A>
  input SimCodeVar.SimVar inSimVar;
  input SimCode.SimCode inSimCode;
  input A inCrefToSimVarHT;
  input Boolean inElimNegAliases "=false to keep negative alias references";
  output String outValueReference;
algorithm
  /* Do nothing */
end getLocalValueReference;

public function hashEqSystemMod
  input SimCode.SimEqSystem eq;
  input Integer mod;
  output Integer hash = 0;
algorithm
  assert(false, getInstanceName());
end hashEqSystemMod;

annotation(__OpenModelica_Interface="backend");
end SimCodeUtil;
