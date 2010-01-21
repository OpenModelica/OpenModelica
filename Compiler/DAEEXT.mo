/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

package DAEEXT
" file:	 DAEEXT.mo
  package:      DAEEXT

  The DAEEXT module is an externally implemented module (in file runtime/daeext.cpp)
  used for the BLT and index reduction algorithms in \'DAELow\'. The implementation
  mainly consists of several bitvectors implemented using std::vector<bool> since
  such functionality is not available in MetaModelica Compiler (MMC)."

public function initMarks
  input Integer inInteger1;
  input Integer inInteger2;

  external "C" ;
end initMarks;

public function eMark
  input Integer inInteger;

  external "C" ;
end eMark;

public function getEMark
  input Integer inInteger;
  output Boolean outBoolean;

  external "C" ;
end getEMark;

public function vMark
  input Integer inInteger;

  external "C" ;
end vMark;

public function getVMark
  input Integer inInteger;
  output Boolean outBoolean;

  external "C" ;
end getVMark;

public function getMarkedEqns
  output list<Integer> outIntegerLst;

  external "C" ;
end getMarkedEqns;

public function getDifferentiatedEqns
  output list<Integer> outIntegerLst;

  external "C" ;
end getDifferentiatedEqns;

public function clearDifferentiated

  external "C" ;
end clearDifferentiated;

public function markDifferentiated
  input Integer inInteger;

  external "C" ;
end markDifferentiated;

public function getMarkedVariables
  output list<Integer> outIntegerLst;

  external "C" ;
end getMarkedVariables;

public function dumpMarkedEquations
  input Integer inInteger;

  external "C" ;
end dumpMarkedEquations;

public function dumpMarkedVariables
  input Integer inInteger;

  external "C" ;
end dumpMarkedVariables;

public function initLowLink
  input Integer inInteger;

  external "C" ;
end initLowLink;

public function initNumber
  input Integer inInteger;

  external "C" ;
end initNumber;

public function setLowLink
  input Integer inInteger1;
  input Integer inInteger2;

  external "C" ;
end setLowLink;

public function getLowLink
  input Integer inInteger;
  output Integer outInteger;

  external "C" ;
end getLowLink;

public function setNumber
  input Integer inInteger1;
  input Integer inInteger2;

  external "C" ;
end setNumber;

public function getNumber
  input Integer inInteger;
  output Integer outInteger;

  external "C" ;
end getNumber;

public function initV
  input Integer inInteger;

  external "C" ;
end initV;

public function initF
  input Integer inInteger;

  external "C" ;
end initF;

public function setV
  input Integer inInteger1;
  input Integer inInteger2;

  external "C" ;
end setV;

public function getV
  input Integer inInteger;
  output Integer outInteger;

  external "C" ;
end getV;

public function setF
  input Integer inInteger1;
  input Integer inInteger2;

  external "C" ;
end setF;

public function getF
  input Integer inInteger;
  output Integer outInteger;

  external "C" ;
end getF;
end DAEEXT;

