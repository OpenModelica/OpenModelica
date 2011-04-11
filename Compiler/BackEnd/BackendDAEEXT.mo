/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
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
  
  RCS: $Id: BackendDAEEXT.mo 7671 2011-01-10 11:19:36Z sjoelund.se $
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

public function getEMark
  input Integer inInteger;
  output Boolean outBoolean;

  external "C" outBoolean=BackendDAEEXT_getEMark(inInteger) annotation(Library = "omcruntime");
end getEMark;

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

public function dumpMarkedEquations
  input Integer inInteger;

  external "C" BackendDAEEXT_dumpMarkedEquations(inInteger) annotation(Library = "omcruntime");
end dumpMarkedEquations;

public function dumpMarkedVariables
  input Integer inInteger;

  external "C" BackendDAEEXT_dumpMarkedVariables(inInteger) annotation(Library = "omcruntime");
end dumpMarkedVariables;

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
end BackendDAEEXT;

