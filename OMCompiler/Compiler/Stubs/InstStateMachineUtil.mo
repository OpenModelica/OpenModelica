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

encapsulated package InstStateMachineUtil

import DAE;
type SMNodeToFlatSMGroupTable = Integer;

function getSMStatesInContext<A,B>
  input A eqns;
  input B inPrefix;
  output list<DAE.ComponentRef> states = {};
  output list<DAE.ComponentRef> initialStates = {};
end getSMStatesInContext;

function createSMNodeToFlatSMGroupTable<A>
  input A inDae;
  output SMNodeToFlatSMGroupTable smNodeToFlatSMGroup = 0;
end createSMNodeToFlatSMGroupTable;

function wrapSMCompsInFlatSMs<A,B>
  input A inIH;
  input B inDae1;
  input B inDae2;
  input SMNodeToFlatSMGroupTable smNodeToFlatSMGroup;
  input list<DAE.ComponentRef> smInitialCrefs;
  output B outDae1 = inDae1;
  output B outDae2 = inDae2;
end wrapSMCompsInFlatSMs;

annotation(__OpenModelica_Interface="frontend");
end InstStateMachineUtil;
