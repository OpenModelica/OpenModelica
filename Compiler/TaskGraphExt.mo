package TaskGraphExt "
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

  
  file:	 TaskGraphExt.mo
  module:      TaskGraphExt
  description: The external representation of a task graph, using Boost Graph Library
  in C++.
 
  RCS: $Id$
  

  
  This module is the interface to the externally implemented task graph using Boost 
  Graph Library in C++
"

public import OpenModelica.Compiler.Exp;
public import OpenModelica.Compiler.DAELow;

public function newTask
  input String inString;
  output Integer outInteger;

  external "C" ;
end newTask;

public function addEdge
  input Integer inInteger1;
  input Integer inInteger2;
  input String inString3;
  input Integer inInteger4;

  external "C" ;
end addEdge;

public function getTask
  input String inString;
  output Integer outInteger;

  external "C" ;
end getTask;

public function storeResult
  input String inString1;
  input Integer inInteger2;
  input Boolean inBoolean3;
  input String inString4;

  external "C" ;
end storeResult;

public function dumpGraph
  input String inString;

  external "C" ;
end dumpGraph;

public function dumpMergedGraph
  input String inString;

  external "C" ;
end dumpMergedGraph;

public function registerStartStop
  input Integer inInteger1;
  input Integer inInteger2;

  external "C" ;
end registerStartStop;

public function getStartTask
  output Integer outInteger;

  external "C" ;
end getStartTask;

public function getStopTask
  output Integer outInteger;

  external "C" ;
end getStopTask;

public function mergeTasks
  input Real inReal1;
  input Real inReal2;

  external "C" ;
end mergeTasks;

public function schedule
  input Integer inInteger;

  external "C" ;
end schedule;

public function generateCode
  input Integer inInteger1;
  input Integer inInteger2;
  input Integer inInteger3;

  external "C" ;
end generateCode;

public function setExecCost
  input Integer inInteger;
  input Real inReal;

  external "C" ;
end setExecCost;

public function setTaskType
  input Integer inInteger1;
  input Integer inInteger2;

  external "C" ;
end setTaskType;

public function setCommCost
  input Integer inInteger1;
  input Integer inInteger2;
  input Integer inInteger3;

  external "C" ;
end setCommCost;

public function addInitVar
  input Integer inInteger1;
  input String inString2;
  input String inString3;

  external "C" ;
end addInitVar;

public function addInitState
  input Integer inInteger1;
  input String inString2;
  input String inString3;

  external "C" ;
end addInitState;

public function addInitParam
  input Integer inInteger1;
  input String inString2;
  input String inString3;

  external "C" ;
end addInitParam;
end TaskGraphExt;

