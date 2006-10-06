package DAEEXT "
This file is part of OpenModelica.

Copyright (c) 1998-2006, Linköpings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

 Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

 Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

 Neither the name of Linköpings universitet nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

  
  file:	 DAEEXT.rml
  module:      DAEEXT

  
  The DAEEXT module is an externally implemented module (in file runtime/daeext.cpp) 
  used for the BLT and index reduction algorithms in \'DAELow\'. The implementation 
  mainly consists of several bitvectors implemented using std::vector<bool> since 
  such functionality is not available in RML.
"

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

