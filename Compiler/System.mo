package System "
This file is part of OpenModelica.

Copyright (c) 1998-2005, Linköpings universitet, Department of
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

  
  file:	 System.rml
  module:      System
  description: This file contains runtime system specific function, which are implemented in 
  C.
 
  RCS: $Id$
 
  This module contain a set of system calls, for e.g. compiling and 
  executing stuff, reading and writing files and so on.
  
"

public import OpenModelica.Compiler.Values;



public function removeFirstAndLastChar
  input String inString;
  output String outString;

  external "C" ;
end removeFirstAndLastChar;

public function trim
  input String inString1;
  input String inString2;
  output String outString;

  external "C" ;
end trim;

public function trimChar
  input String inString1;
  input String inString2;
  output String outString;

  external "C" ;
end trimChar;

public function strcmp
  input String inString1;
  input String inString2;
  output Integer outInteger;

  external "C" ;
end strcmp;

public function strncmp
  input String inString1;
  input String inString2;
  input Integer len;
  output Integer outInteger;

  external "C" ;
end strncmp;


public function stringReplace
  input String str;
  input String source;
  input String target;
  output String res;

  external "C" ;
end stringReplace;

public function toupper
  input String inString;
  output String outString;

  external "C" ;
end toupper;

public function strtok
  input String inString1;
  input String inString2;
  output list<String> outStringLst;

  external "C" ;
end strtok;

public function compileCFile
  input String inString;

  external "C" ;
end compileCFile;

public function setCCompiler
  input String inString;

  external "C" ;
end setCCompiler;

public function setCFlags
  input String inString;

  external "C" ;
end setCFlags;

public function executeFunction
  input String inString;

  external "C" ;
end executeFunction;

public function writeFile
  input String inString1;
  input String inString2;

  external "C" ;
end writeFile;

public function readFile
  input String inString;
  output String outString;

  external "C" ;
end readFile;

public function readValuesFromFile
  input String inString;
  output Values.Value outValue;

  external "C" ;
end readValuesFromFile;

public function readPtolemyplotDataset
  input String inString;
  input list<String> inStringLst;
  input Integer inInteger;
  output Values.Value outValue;

  external "C" ;
end readPtolemyplotDataset;

public function readPtolemyplotDatasetSize
  input String inString;
  output Values.Value outValue;

  external "C" ;
end readPtolemyplotDatasetSize;

public function systemCall
  input String inString;
  output Integer outInteger;

  external "C" ;
end systemCall;

public function cd
  input String inString;
  output Integer outInteger;

  external "C" ;
end cd;

public function pwd
  output String outString;

  external "C" ;
end pwd;

public function readEnv
  input String inString;
  output String outString;

  external "C" ;
end readEnv;

public function setEnv
  input String inString1;
  input String inString2;
  input Integer inInteger3;
  output Integer outInteger;

  external "C" ;
end setEnv;

public function subDirectories
  input String inString;
  output list<String> outStringLst;

  external "C" ;
end subDirectories;

public function moFiles
  input String inString;
  output list<String> outStringLst;

  external "C" ;
end moFiles;

public function time
  output Real outReal;

  external "C" ;
end time;

public function hash
  input String inString;
  output Integer outInteger;

  external "C" ;
end hash;

public function pathDelimiter
  output String outString;

  external "C" ;
end pathDelimiter;

public function groupDelimiter
  output String outString;

  external "C" ;
end groupDelimiter;

public function regularFileExists
  input String inString;
  output Integer outInteger;

  external "C" ;
end regularFileExists;

public function directoryExists
  input String inString;
  output Integer outInteger;

  external "C" ;
end directoryExists;

public function platform
  output String outString;

  external "C" ;
end platform;

public function asin
  input Real inReal;
  output Real outReal;

  external "C" ;
end asin;

public function acos
  input Real inReal;
  output Real outReal;

  external "C" ;
end acos;

public function atan
  input Real inReal;
  output Real outReal;

  external "C" ;
end atan;

public function atan2
  input Real inReal1;
  input Real inReal2;
  output Real outReal;

  external "C" ;
end atan2;

public function cosh
  input Real inReal;
  output Real outReal;

  external "C" ;
end cosh;

public function log
  input Real inReal;
  output Real outReal;

  external "C" ;
end log;

public function log10
  input Real inReal;
  output Real outReal;

  external "C" ;
end log10;

public function sinh
  input Real inReal;
  output Real outReal;

  external "C" ;
end sinh;

public function tanh
  input Real inReal;
  output Real outReal;

  external "C" ;
end tanh;

public function getClassnamesForSimulation
  output String outString;

  external "C" ;
end getClassnamesForSimulation;

public function setClassnamesForSimulation
  input String inString;

  external "C" ;
end setClassnamesForSimulation;

public function getVariableValue
  input Real timeStamp;
  input list<Real> timeValues;
  input list<Real> varValues; 
  output Real outValue;

  external "C" ;
end getVariableValue;

end System;

