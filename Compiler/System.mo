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

package System
" file:	       System.mo
  package:     System
  description: This file contains runtime system specific function, which are implemented in C.

  RCS: $Id$

  This module contain a set of system calls, for e.g. compiling and
  executing stuff, reading and writing files and so on."

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
"This function returns:
  0 if inString1 == inString2
  1 if inString1 >  inString2
 -1 if inString1 <  inString2
 This is different from what C strcmp
 returns (negative values if <, positive values if >).
 We fix negative values to -1 and positive to +1 so
 we can pattern match on them directly in MetaModelica!"
  input String inString1;
  input String inString2;
  output Integer outInteger;

  external "C" ;
end strcmp;

public function stringFind "locates substring searchStr in str. If succeeds return position, otherwise return -1"
  input String str;
  input String searchStr;
  output Integer outInteger;

  external "C" ;
end stringFind;

public function stringFindString "locates substring searchStr in str. If succeeds return the string, otherwise fail"
  input String str;
  input String searchStr;
  output String outString;

  external "C";
end stringFindString;

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

public function tolower
  input String inString;
  output String outString;

  external "C" ;
end tolower;

public function strtok
  input String inString1;
  input String inString2;
  output list<String> outStringLst;

  external "C" ;
end strtok;

public function setCCompiler
  input String inString;

  external "C" ;
end setCCompiler;

public function getCCompiler
  output String outString;

  external "C" ;
end getCCompiler;

public function setCFlags
  input String inString;

  external "C" ;
end setCFlags;

public function getCFlags
  output String outString;

  external "C" ;
end getCFlags;

public function setCXXCompiler
  input String inString;

  external "C" ;
end setCXXCompiler;

public function getCXXCompiler
  output String outString;

  external "C" ;
end getCXXCompiler;

public function setLinker
  input String inString;

  external "C" ;
end setLinker;

public function getLinker
  output String outString;

  external "C" ;
end getLinker;

public function setLDFlags
  input String inString;

  external "C" ;
end setLDFlags;

public function getLDFlags
  output String outString;

  external "C" ;
end getLDFlags;

public function getExeExt
  output String outString;

  external "C" ;
end getExeExt;

public function getDllExt
  output String outString;

  external "C" ;
end getDllExt;

public function loadLibrary
  input String inLib;
  output Integer outLibHandle;

  external "C" ;
end loadLibrary;

public function lookupFunction
  input Integer inLibHandle;
  input String inFunc;
  output Integer outFuncHandle;

  external "C" ;
end lookupFunction;

public function freeFunction
  input Integer inFuncHandle;

  external "C" ;
end freeFunction;

public function freeLibrary
  input Integer inLibHandle;

  external "C" ;
end freeLibrary;

public function sendData
  input String inString1;
  input String inString2; //interpolation
  input String title;
  input Boolean legend;
  input Boolean grid;
  input Boolean logX;
  input Boolean logY;
  input String xLabel;
  input String yLabel;
  input Boolean points;
  input String range;
  external "C" ;
end sendData;

public function enableSendData
  input Boolean enable;
  external "C";
end enableSendData;

public function setDataPort
  input Integer port;
  external "C";
end setDataPort;

public function setVariableFilter
  input String variables;
  output Boolean b;
  external "C";

end setVariableFilter;

public function sendData2
  input String inString1;
  input String inString2;

  external "C" ;
end sendData2;

public function writeFile
"This function will write to the file given by first argument the given string"
  input String fileNameToWrite "a filename where to write the data";
  input String stringToBeWritten "the data";

  external "C" ;
end writeFile;

public function appendFile
  input String inString1;
  input String inString2;

  external "C" ;
end appendFile;

public function readFile
"Does not fail. Returns strings describing the error instead."
  input String inString;
  output String outString;

  external "C" ;
end readFile;

public function getVariableNames
  input String modelname;
  output String variables;

  external "C";
end getVariableNames;

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

public function readEnv "Reads the environment variable given as string, fails if variable not found"
  input String inString;
  output String outString;

  external "C" ;
end readEnv;



public function setEnv ""
  input String varName;
  input String value;
  input Boolean overwrite "is always true on Windows, so recommended to always call it using true";
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
  output Boolean outBool;

  external "C" ;
end regularFileExists;

public function removeFile "Removes a file, returns 0 if suceeds, implemented using remove() in stdio.h"
  input String fileName;
  output Integer res;

  external "C";
end removeFile;

public function getPackageFileNames
  input String inString1;
  input String inString2;
  output String outString;

  external "C" ;
end getPackageFileNames;

public function directoryExists
  input String inString;
  output Boolean outBool;

  external "C" ;
end directoryExists;

public function platform
  output String outString;

  external "C" ;
end platform;

public function realCeil
  input Real inReal;
  output Real outReal;

  external "C" ;
end realCeil;


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

public function getFileModificationTime
"@author adrpo
 this system function returns the modification time of a file as a
 SOME(Real) which represents the time elapsed since the
 Epoch (00:00:00 UTC, January 1, 1970).
 If the file does not exist or if there is an error the returned value
 will be NONE.
"
  input  String       fileName;
  output Option<Real> outValue;

  external "C" ;
end getFileModificationTime;

public function getCurrentTime
"@author adrpo
 this system function returns current time elapsed
 since the Epoch (00:00:00 UTC, January 1, 1970)."
  output Real outValue;

  external "C" ;
end getCurrentTime;

public function getCurrentTimeStr "
returns current time in format Www Mmm dd hh:mm:ss yyyy
using the asctime() function in time.h (libc)
"
  output String timeStr;
  external "C";
end getCurrentTimeStr;

public function isSameFile "Checks if two filenames points to the same file"
  input String fileName1;
  input String fileName2;
  external "C";
end isSameFile;

public function isIdenticalFile "Checks if two filenames points to the exact same file"
  input String fileName1;
  input String fileName2;
  output Boolean same;
  external "C";
end isIdenticalFile;

public function windowsNewline "returns /r/n, since MetaModelica has a bug for representing this as a literal"
output String str;
external "C";
end windowsNewline;

public function os "Returns a string with the operating system name

For linux: 'linux'
For OSX: 'OSX'
For Windows : 'Windows_NT' (the name of env var OS )

Why it returns linux for OSX, we have no clue. But it does, so let's
document it.
"
  output String str;
  external "C" ;
end os;

public function compileCFile
  input String inString;

  external "C" ;
end compileCFile;

public function readFileNoNumeric
  input String inString;
  output String outString;

  external "C" ;
end readFileNoNumeric;

public function setHasExpandableConnectors
"@author: adrpo
 sets the external flag that signals the
 presence of expandable connectors in a model"
  input Boolean hasExpandable;
  external "C" ;
end setHasExpandableConnectors;

public function getHasExpandableConnectors
"@author: adrpo
 retrieves the external flag that signals the
 presence of expandable connectors in a model"
  output Boolean hasExpandable;
  external "C" ;
end getHasExpandableConnectors;

public function setHasInnerOuterDefinitions
"@author: adrpo
 sets the external flag that signals the presence
 of inner/outer comoponent definitions in a model"
  input Boolean hasInnerOuterDefinitions;
  external "C" ;
end setHasInnerOuterDefinitions;

public function getHasInnerOuterDefinitions
"@author: adrpo
 retrieves the external flag that signals the presence
 of inner/outer comoponent definitions in a model"
  output Boolean hasInnerOuterDefinitions;
  external "C" ;
end getHasInnerOuterDefinitions;

public function tmpTick "returns a tick that can be reset"
output Integer tickNo;
  external "C";
end tmpTick;

public function tmpTickReset "resets the tick so it restarts on start
"
input Integer start;
  external "C";
end tmpTickReset;

public function listAppendUnsafe
  replaceable type Type_a subtypeof Any;
  input list<Type_a> firstList;
  input list<Type_a> secondList;
  output list<Type_a> appendedList;

  external "C" ;
end listAppendUnsafe;

public function addToRoots
"@author: adrpo
 this function binds a name to an external root.
 BEWARE! this is a side effect!
         addToRoots(0, value) should match
         value = getToRoots(0) and the type
         of the value should be the same!"
  replaceable type Type_a subtypeof Any;
  input Integer index "index in the external hash, starting from 0";
  input Type_a anyValue;
  external "C" ;
end addToRoots;

public function getFromRoots
"@author: adrpo
 this function returns an external root for a name
 BEWARE! this is a side effect!
         addToRoots(0, value) should match
         value = getToRoots(0) and the type
         of the value should be the same!"
  replaceable type Type_a subtypeof Any;
  input Integer index "index in the external hash, starting from 0";
  output Type_a anyValue;
  external "C" ;
end getFromRoots;

public function enableTrace
"@author: adrpo
 this function enables the stderr tracing"

  external "C" ;
end enableTrace;

public function disableTrace
"@author: adrpo
 this function disables the stderr tracing"

  external "C" ;
end disableTrace;

public function getSendDataLibs
"Returns a string containing the compiler flags used for SENDDATALIBS"
  output String sendDataLibs;
  external "C" ;
end getSendDataLibs;

public function userIsRoot
"Returns true if the current user is root.
Used by main to disable running omc as root as it is very dangerous.
Consider opening a socket and letting anyone run system() commands without authentication. As root."
  output Boolean isRoot;
  external "C";
end userIsRoot;

public function configureCommandLine
"Returns the date and command used to configure OpenModelica.
On the platforms that don't configure options, like OMDev, the returned string
is more generic and does not contain a date."
  output String cmdLine;
  external "C";
end configureCommandLine;

public function realtimeTick
"Tock returns the time since the last tock; undefined if tick was never called.
The clock index is 0-15. The function fails if the number is out of range."
  input Integer clockIndex;
  external "C";
end realtimeTick;

public function realtimeTock
"Tock returns the time since the last tock, undefined if tick was never called.
The clock index is 0-15. The function fails if the number is out of range."
  input Integer clockIndex;
  output Real outTime;
  external "C";
end realtimeTock;

function resetTimer
"@autor: adrpo
  this function will reset the timer to 0."
  external "C";
end resetTimer;

function startTimer
"@autor: adrpo
  this function will start counting the time
  that should be aggregated."
  external "C";
end startTimer;

function stopTimer
"@autor: adrpo
  this function will stop counting the time
  that should be aggregated."
  external "C";
end stopTimer;

function getTimerTime
"@autor: adrpo
  this function will return the cummulated time 
  between all calls to startTimer and stopTimer."
  output Real timerTime;
  external "C";
end getTimerTime;

function stringAppendList
"@autor: adrpo
  This function will append all the strings in the given-as-input
  list<String> into a new string. It does so by creating the new
  string directly and thus avoiding a lot of stringAppend which
  can generate a lot of garbage. This function will pe part of the
  new MetaModelica/RML release, later on."
  input list<String> listWithStrings;
  output String appendedString;
  
  external "C";
end stringAppendList;

function refEqual
"@autor: adrpo
  This function checks if two MetaModelica references point to the same structure"
  replaceable type Type_a subtypeof Any;
  input  Type_a ref1;
  input  Type_a ref2;
  output Boolean result;
  
  external "C";
end refEqual;

end System;

