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

encapsulated package Global
" file:        Global.mo
  package:     Global
  description: Global contains structures that are available globally.


  The Global package contains structures that are available globally."


constant Integer recursionDepthLimit = 256;
constant Integer maxFunctionFileLength = 50;

// Thread-local roots
constant Integer instOnlyForcedFunctions = 0;
constant Integer codegenTryThrowIndex = 1;
constant Integer codegenFunctionList = 2;
// Global roots start at index=9
constant Integer instHashIndex = 9;
constant Integer builtinIndex = 12;
constant Integer builtinEnvIndex = 13;
constant Integer profilerTime1Index = 14;
constant Integer profilerTime2Index = 15;
constant Integer flagsIndex = 16;
constant Integer builtinGraphIndex = 17;
constant Integer rewriteRulesIndex = 18;
constant Integer stackoverFlowIndex = 19;
constant Integer gcProfilingIndex = 20;
constant Integer inlineHashTable = 21; // TODO: Should be a local root?
constant Integer currentInstVar = 22;
constant Integer operatorOverloadingCache = 23;
constant Integer optionSimCode = 24;
constant Integer interactiveCache = 25;

// indexes in System.tick
// ----------------------
// temp vars index
constant Integer tmpVariableIndex = 4;
// file seq
constant Integer backendDAE_fileSequence = 20;
// jacobian name
constant Integer backendDAE_jacobianSeq = 21;
// nodeId
constant Integer fgraph_nextId = 22;
// csevar name
constant Integer backendDAE_cseIndex = 23;
// strong component index
constant Integer strongComponent_index = 24;

// ----------------------

public function initialize "Called to initialize global roots (when needed)"
algorithm
  setGlobalRoot(instOnlyForcedFunctions,  NONE());
  setGlobalRoot(rewriteRulesIndex,  NONE());
  setGlobalRoot(stackoverFlowIndex, NONE());
  setGlobalRoot(inlineHashTable, NONE());
  setGlobalRoot(currentInstVar, NONE());
  setGlobalRoot(interactiveCache, NONE());
end initialize;

annotation(__OpenModelica_Interface="util");
end Global;
