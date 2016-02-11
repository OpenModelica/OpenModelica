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

encapsulated package BackendDAEEXT
" file:        BackendDAEEXT.mo
  package:     BackendDAEEXT
  description: The BackendDAEEXT module is an externally implemented module (in file
               Compiler/runtime/BackendDAEEXT.cpp) used for the BLT and index reduction
               algorithms in BackendDAE.
               The implementation mainly consists of several bitvectors implemented
               using std::vector<bool> since such functionality is not available in
               MetaModelica Compiler (MMC).

"

public function initMarks
  input Integer inInteger1;
  input Integer inInteger2;

  external "C" BackendDAEEXT_initMarks(inInteger1,inInteger2) annotation(Library = "omcruntime");
end initMarks;

public function eMark
  input Integer inInteger;

  external "C" BackendDAEEXT_eMark(inInteger) annotation(Library = "omcruntime");
end eMark;

/* TODO: Implement an external C function for bootstrapped omc or remove me. DO NOT SIMPLY REMOVE THIS COMMENT
public function getEMark
  input Integer inInteger;
  output Boolean outBoolean;

  external "C" outBoolean=BackendDAEEXT_getEMark(inInteger) annotation(Library = "omcruntime");
end getEMark;*/

public function vMark
  input Integer inInteger;

  external "C" BackendDAEEXT_vMark(inInteger) annotation(Library = "omcruntime");
end vMark;

public function getVMark
  input Integer inInteger;
  output Boolean outBoolean;

  external "C" outBoolean=BackendDAEEXT_getVMark(inInteger) annotation(Library = "omcruntime");
end getVMark;

public function getMarkedEqns
  output list<Integer> outIntegerLst;

  external "C" outIntegerLst=BackendDAEEXT_getMarkedEqns() annotation(Library = "omcruntime");
end getMarkedEqns;

public function getDifferentiatedEqns
  output list<Integer> outIntegerLst;

  external "C" outIntegerLst=BackendDAEEXT_getDifferentiatedEqns() annotation(Library = "omcruntime");
end getDifferentiatedEqns;

public function clearDifferentiated

  external "C" BackendDAEEXT_clearDifferentiated() annotation(Library = "omcruntime");
end clearDifferentiated;

public function markDifferentiated
  input Integer inInteger;

  external "C" BackendDAEEXT_markDifferentiated(inInteger) annotation(Library = "omcruntime");
end markDifferentiated;

public function getMarkedVariables
  output list<Integer> outIntegerLst;

  external "C" outIntegerLst=BackendDAEEXT_getMarkedVariables() annotation(Library = "omcruntime");
end getMarkedVariables;

public function initLowLink
  input Integer inInteger;

  external "C" BackendDAEEXT_initLowLink(inInteger) annotation(Library = "omcruntime");
end initLowLink;

public function initNumber
  input Integer inInteger;

  external "C" BackendDAEEXT_initNumber(inInteger) annotation(Library = "omcruntime");
end initNumber;

public function setLowLink
  input Integer inInteger1;
  input Integer inInteger2;

  external "C" BackendDAEEXT_setLowLink(inInteger1,inInteger2) annotation(Library = "omcruntime");
end setLowLink;

public function getLowLink
  input Integer inInteger;
  output Integer outInteger;

  external "C" outInteger=BackendDAEEXT_getLowLink(inInteger) annotation(Library = "omcruntime");
end getLowLink;

public function setNumber
  input Integer inInteger1;
  input Integer inInteger2;

  external "C" BackendDAEEXT_setNumber(inInteger1,inInteger2) annotation(Library = "omcruntime");
end setNumber;

public function getNumber
  input Integer inInteger;
  output Integer outInteger;

  external "C" outInteger=BackendDAEEXT_getNumber(inInteger) annotation(Library = "omcruntime");
end getNumber;

/* TODO: Implement an external C function for bootstrapped omc or remove me. DO NOT SIMPLY REMOVE THIS COMMENT
public function dumpMarkedEquations
  input Integer inInteger;

  external "C" BackendDAEEXT_dumpMarkedEquations(inInteger) annotation(Library = "omcruntime");
end dumpMarkedEquations;

public function dumpMarkedVariables
  input Integer inInteger;

  external "C" BackendDAEEXT_dumpMarkedVariables(inInteger) annotation(Library = "omcruntime");
end dumpMarkedVariables;

public function initV
  input Integer inInteger;

  external "C" BackendDAEEXT_initV(inInteger) annotation(Library = "omcruntime");
end initV;

public function initF
  input Integer inInteger;

  external "C" BackendDAEEXT_initF(inInteger) annotation(Library = "omcruntime");
end initF;

public function setV
  input Integer inInteger1;
  input Integer inInteger2;

  external "C" BackendDAEEXT_setV(inInteger1,inInteger2) annotation(Library = "omcruntime");
end setV;

public function getV
  input Integer inInteger;
  output Integer outInteger;

  external "C" outInteger=BackendDAEEXT_getV(inInteger) annotation(Library = "omcruntime");
end getV;

public function setF
  input Integer inInteger1;
  input Integer inInteger2;

  external "C" BackendDAEEXT_setF(inInteger1,inInteger2) annotation(Library = "omcruntime");
end setF;

public function getF
  input Integer inInteger;
  output Integer outInteger;

  external "C" outInteger=BackendDAEEXT_getF(inInteger) annotation(Library = "omcruntime");
end getF;
*/

/******************************************
 C-Implementation Stuff from
 Kamer Kaya, Johannes Langguth and Bora Ucar
 see: http://bmi.osu.edu/~kamer/index.html
 *****************************************/

public function setIncidenceMatrix "author: Frenkel TUD 2012-04"
  input Integer nv;
  input Integer ne;
  input Integer nz;
  input array<list<Integer>> m;

  external "C" BackendDAEEXT_setIncidenceMatrix(nv,ne,nz,m) annotation(Library = "omcruntime");
end setIncidenceMatrix;

/* TODO: Implement an external C function for bootstrapped omc or remove me. DO NOT SIMPLY REMOVE THIS COMMENT
public function cheapmatching
"author: Frenkel TUD 2012-04
  calls cheapmatching algorithms
  cheapID: id of cheap algo (1-4)
      1: Simple Greedy
      2: Karp-Sipser
      3: Random Karp-Sipser (DEFAULT)
      4: Minimum Degree (two-sided)

     Other than these two, non-positive values are not allowed.
  "
  input Integer nv;
  input Integer ne;
  input Integer cheapID;
  input Integer clear_match;
  external "C" BackendDAEEXT_cheapmatching(nv,ne,cheapID,clear_match) annotation(Library = "omcruntime");
end cheapmatching;*/

public function matching
"author: Frenkel TUD 2012-04
  calls matching algorithms
  matchingID: id of match algo (1-10)
      1: DFS based
      2: BFS based
      3: MC21 (DFS + lookahead)
      4: PF (Pothen and Fan' algorithm)
      5: PF+ (PF + fairness)
      6: HK (Hopcroft and Karp's algorithm)
      7: HK-DW (Duff-Wiberg implementation of HK)
      8: ABMP (Alt et al.'s algorithm)
      9: ABMP-BFS (ABMP + BFS)
     10: PR-FIFO-FAIR (DEFAULT)

  cheapID: id of cheap algo (0-4)
      0: No Cheap Matching
      1: Simple Greedy
      2: Karp-Sipser
      3: Random Karp-Sipser (DEFAULT)
      4: Minimum Degree (two-sided)

  relabel_period: used only when matchID = 10. Otherwise it is ignored.
      For the PR based algorithm, a global relabeling is started after
      every (m+n) x 'relabel_period' pushes where m and
      n are the number of rows and columns of the matrix. Default is 1.
       -1: for a global relabeling after every m pushes
       -2: for a global relabeling after every n pushes
     Other than these two, non-positive values are not allowed.
  "
  input Integer nv;
  input Integer ne;
  input Integer matchingID;
  input Integer cheapID;
  input Real relabel_period;
  input Integer clear_match;
  external "C" BackendDAEEXT_matching(nv,ne,matchingID,cheapID,relabel_period,clear_match) annotation(Library = "omcruntime");
end matching;

public function getAssignment "author: Frenkel TUD 2012-04"
  input array<Integer> ass1;
  input array<Integer> ass2;
  external "C" BackendDAEEXT_getAssignment(ass1, ass2) annotation(Library = "omcruntime");
end getAssignment;

public function setAssignment
"author: Frenkel TUD 2012-04"
  input Integer lenass1;
  input Integer lenass2;
  input array<Integer> ass1;
  input array<Integer> ass2;
  output Boolean outBoolean;

  external "C" outBoolean=BackendDAEEXT_setAssignment(lenass1,lenass2,ass1,ass2) annotation(Library = "omcruntime");
end setAssignment;

annotation(__OpenModelica_Interface="backend");
end BackendDAEEXT;
