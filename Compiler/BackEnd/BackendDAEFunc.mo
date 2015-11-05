/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package BackendDAEFunc
" file:        BackendDAEFunc.mo
  package:     BackendDAEFunc
  description: BackendDAEFunc defines the partial functions (interfaces) to function pointers that are sent around.

  RCS: $Id: BackendDAEFunc.mo 17568 2013-10-07 01:59:38Z adrpo $
"

public import BackendDAE;

/*************************************/
/*   Interfaces */
/*************************************/

public
partial function optimizationModule
 "This is the interface for pre/post-optimization modules."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
end optimizationModule;

partial function stateDeselectionFunc
  input BackendDAE.BackendDAE inDAE;
  input list<Option<BackendDAE.StructurallySingularSystemHandlerArg>> inArgs;
  output BackendDAE.BackendDAE outDAE;
end stateDeselectionFunc;

partial function StructurallySingularSystemHandlerFunc
  input list<list<Integer>> eqns;
  input Integer actualEqn;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input array<Integer> inAssignments1;
  input array<Integer> inAssignments2;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output list<Integer> changedEqns;
  output Integer continueEqn;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output array<Integer> outAssignments1;
  output array<Integer> outAssignments2;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
end StructurallySingularSystemHandlerFunc;

partial function matchingAlgorithmFunc
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Boolean clearMatching;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
end matchingAlgorithmFunc;

annotation(__OpenModelica_Interface="backend");
end BackendDAEFunc;
