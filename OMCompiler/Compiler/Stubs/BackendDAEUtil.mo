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

encapsulated package BackendDAEUtil

import BackendDAE;

function getSolvedSystem<A>
  input A inDAE;
  input String fileNamePrefix;
  input Option<list<String>> strPreOptModules = NONE();
  input Option<String> strmatchingAlgorithm = NONE();
  input Option<String> strdaeHandler = NONE();
  input Option<list<String>> strPostOptModules = NONE();
  output A outSODE;
  output A outInitDAE;
  output Option<A> outInitDAE_lambda0;
  output Option<BackendDAE.InlineData> inlineData;
  output list<BackendDAE.Equation> outRemovedInitialEquationLst;
algorithm
  assert(false, getInstanceName());
end getSolvedSystem;

function preOptimizeBackendDAE<T>
  input T inDAE;
  input Option<list<String>> strPreOptModules;
  output T outDAE;
algorithm
  assert(false, getInstanceName());
end preOptimizeBackendDAE;

function transformBackendDAE<A,B>
  input A inDAE;
  input Option<B> inMatchingOptions;
  input Option<String> strmatchingAlgorithm;
  input Option<String> strindexReductionMethod;
  output A outDAE;
algorithm
  assert(false, getInstanceName());
end transformBackendDAE;

function getAdjacencyMatrixfromOption
  input BackendDAE.EqSystem inSyst;
  input BackendDAE.IndexType inIndxType;
  input Option<DAE.FunctionTree> inFunctionTree;
  output BackendDAE.EqSystem outSyst;
  output BackendDAE.AdjacencyMatrix outM;
  output BackendDAE.AdjacencyMatrix outMT;
algorithm
  assert(false, getInstanceName());
end getAdjacencyMatrixfromOption;

function getAllVarLst
  input BackendDAE.BackendDAE dae;
  output list<BackendDAE.Var> varLst;
algorithm
  assert(false, getInstanceName());
end getAllVarLst;

annotation(__OpenModelica_Interface="backend");
end BackendDAEUtil;
