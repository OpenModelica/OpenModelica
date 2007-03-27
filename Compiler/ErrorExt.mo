package ErrorExt "
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

  
  file:	 ErrorExt.mo
  module:      ErrorExt
  description: Error handling External interface
 
  RCS: $Id$
 
  This file contains the external interface to the error handling.
  Error messages are stored externally, impl. in C++.
   
"

public import Error;

public function addMessage
  input Error.ErrorID inErrorID1;
  input String inString2;
  input String inString3;
  input String inString4;
  input list<String> inStringLst5;

  external "C" ;
end addMessage;

public function addSourceMessage
  input Error.ErrorID inErrorID1;
  input String inString2;
  input String inString3;
  input Integer inInteger4;
  input Integer inInteger5;
  input Integer inInteger6;
  input Integer inInteger7;
  input Boolean inBoolean8;
  input String inString9;
  input String inString10;
  input list<String> inStringLst11;

  external "C" ;
end addSourceMessage;

public function printMessagesStr
  output String outString;

  external "C" ;
end printMessagesStr;

public function getMessagesStr
  output String outString;

  external "C" ;
end getMessagesStr;

public function errorOff

  external "C" ;
end errorOff;

public function errorOn

  external "C" ;
end errorOn;
end ErrorExt;

