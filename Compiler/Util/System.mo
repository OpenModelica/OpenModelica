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

encapsulated package System
" file:         System.mo
  package:     System
  description: This file contains runtime system specific function, which are implemented in C.


  This module contain a set of system calls, for e.g. compiling and
  executing stuff, reading and writing files and so on."

protected
import Autoconf;

public function trim
"removes chars in charsToRemove from begin and end of inString"
  input String inString;
  input String charsToRemove = " \f\n\r\t\v";
  output String outString;

  external "C" outString=System_trim(inString,charsToRemove) annotation(Library = "omcruntime");
end trim;

public function trimWhitespace
"removes chars in ' \f\n\r\t\v' from begin and end of inString"
  input String inString;
  output String outString;
algorithm
  outString := trim(inString);
end trimWhitespace;

public function trimChar
  input String inString1;
  input String inString2;
  output String outString;

  external "C" outString=System_trimChar(inString1,inString2) annotation(Library = "omcruntime");
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

  external "C" outInteger=System_strcmp(inString1,inString2) annotation(Library = "omcruntime");
end strcmp;

public function strcmp_offset
"Like strcmp, but also takes offset and lengths of the strings in order to avoid building them through substring"
  input String string1;
  input Integer offset1;
  input Integer length1;
  input String string2;
  input Integer offset2;
  input Integer length2;
  output Integer outInteger;

  external "C" outInteger=System_strcmp_offset(string1,offset1,length1,string2,offset2,length2) annotation(Library = "omcruntime");
end strcmp_offset;

public function stringFind "locates substring searchStr in str. If succeeds return position, otherwise return -1"
  input String str;
  input String searchStr;
  output Integer outInteger;

  external "C" outInteger=System_stringFind(str,searchStr) annotation(Library = "omcruntime");
end stringFind;

public function stringFindString "locates substring searchStr in str. If succeeds return the string, otherwise fail"
  input String str;
  input String searchStr;
  output String outString;

  external "C" outString=System_stringFindString(str,searchStr) annotation(Library = "omcruntime");
end stringFindString;

public function regex "Fails and sets Error.mo if the regex does not compile.

  The returned result is the same as POSIX regex():
  The first value is the complete matched string
  The rest are the substrings that you wanted.
  For example:
  regex(lorem,\" \\([A-Za-z]*\\) \\([A-Za-z]*\\) \",maxMatches=3)
  => {\" ipsum dolor \",\"ipsum\",\"dolor\"}
  This means if you have n groups, you want maxMatches=n+1
"
  input String str;
  input String re;
  input Integer maxMatches "The maximum number of matches that will be returned";
  input Boolean extended=false "Use POSIX extended or regular syntax";
  input Boolean ignoreCase=false;
  output Integer numMatches "0 means no match, else returns a number 1..maxMatches (1 if maxMatches<0)";
  output list<String> strs "This list has length = maxMatches. Substrings that did not match are filled with the empty string";

  external "C" strs=System_regex(str,re,maxMatches,extended,ignoreCase,numMatches) annotation(Library = "omcruntime");
end regex;

public function strncmp
  input String inString1;
  input String inString2;
  input Integer len;
  output Integer outInteger;

  external "C" outInteger=System_strncmp(inString1,inString2,len) annotation(Library = "omcruntime");
end strncmp;

public function stringReplace
  input String str;
  input String source;
  input String target;
  output String res;

  external "C" res=System_stringReplace(str,source,target) annotation(Library = "omcruntime");
end stringReplace;

public function makeC89Identifier "Replaces unknown characters with _"
  input String str;
  output String res;

  external "C" res=System_makeC89Identifier(str) annotation(Library = "omcruntime");
end makeC89Identifier;

public function toupper
  input String inString;
  output String outString;

  external "C" outString=System_toupper(inString) annotation(Library = "omcruntime");
end toupper;

public function tolower
  input String inString;
  output String outString;

  external "C" outString=System_tolower(inString) annotation(Library = "omcruntime");
end tolower;

public function strtok
  input String string;
  input String token;
  output list<String> strings;

  external "C" strings=System_strtok(string,token) annotation(Library = "omcruntime");
end strtok;

public function strtokIncludingDelimiters
"as strtok but also includes *all* delimiters
 split the string at delimiters into a list of strings including *all* delimiters
 stringSplitInTokens(*a**b*, *) => {*, a, *, *, b, *}"
  input String string;
  input String token;
  output list<String> strings;

  external "C" strings=System_strtokIncludingDelimiters(string,token) annotation(Library = "omcruntime");
end strtokIncludingDelimiters;

public function setCCompiler
  input String inString;

  external "C" SystemImpl__setCCompiler(inString) annotation(Library = "omcruntime");
end setCCompiler;

public function getCCompiler
  output String outString;

  external "C" outString=System_getCCompiler() annotation(Library = "omcruntime");
end getCCompiler;

public function setCFlags
  input String inString;

  external "C" SystemImpl__setCFlags(inString) annotation(Library = "omcruntime");
end setCFlags;

public function getCFlags
  output String outString;

  external "C" outString=System_getCFlags() annotation(Library = "omcruntime");
end getCFlags;

public function setCXXCompiler
  input String inString;

  external "C" SystemImpl__setCXXCompiler(inString) annotation(Library = "omcruntime");
end setCXXCompiler;

public function getCXXCompiler
  output String outString;

  external "C" outString=System_getCXXCompiler() annotation(Library = "omcruntime");
end getCXXCompiler;

public function getOMPCCompiler
  output String outString;

  external "C" outString=System_getOMPCCompiler() annotation(Library = "omcruntime");
end getOMPCCompiler;

public function setLinker
  input String inString;

  external "C" SystemImpl__setLinker(inString) annotation(Library = "omcruntime");
end setLinker;

public function getLinker
  output String outString;

  external "C" outString=System_getLinker() annotation(Library = "omcruntime");
end getLinker;

public function setLDFlags
  input String inString;

  external "C" SystemImpl__setLDFlags(inString) annotation(Library = "omcruntime");
end setLDFlags;

public function getLDFlags
  output String outString;

  external "C" outString=System_getLDFlags() annotation(Library = "omcruntime");
end getLDFlags;

public function loadLibrary
  input String inLib;
  input Boolean inPrintDebug;
  output Integer outLibHandle;

  external "C" outLibHandle=System_loadLibrary(inLib, inPrintDebug) annotation(Library = "omcruntime");
end loadLibrary;

public function lookupFunction
  input Integer inLibHandle;
  input String inFunc;
  output Integer outFuncHandle;

  external "C" outFuncHandle=System_lookupFunction(inLibHandle,inFunc) annotation(Library = "omcruntime");
end lookupFunction;

public function freeFunction
  input Integer inFuncHandle;
  input Boolean inPrintDebug;

  external "C" System_freeFunction(inFuncHandle, inPrintDebug) annotation(Library = "omcruntime");
end freeFunction;

public function freeLibrary
  input Integer inLibHandle;
  input Boolean inPrintDebug;

  external "C" System_freeLibrary(inLibHandle, inPrintDebug) annotation(Library = "omcruntime");
end freeLibrary;

public function writeFile
"This function will write to the file given by first argument the given string"
  input String fileNameToWrite "a filename where to write the data";
  input String stringToBeWritten "the data";
  external "C" System_writeFile(fileNameToWrite,stringToBeWritten) annotation(Library = "omcruntime");
end writeFile;

public function appendFile
  input String file;
  input String data;
  external "C" System_appendFile(file,data) annotation(Library = "omcruntime");
end appendFile;

public function readFile
"Does not fail. Returns strings describing the error instead."
  input String inString;
  output String outString;
  external "C" outString = System_readFile(inString) annotation(Library = "omcruntime");
end readFile;

public function systemCall
  input String command;
  input String outFile = "" "empty file means no redirection unless it is part of the command";
  output Integer outInteger;
  external "C" outInteger=SystemImpl__systemCall(command,outFile) annotation(Library = "omcruntime");
end systemCall;

public function popen "Run the command and return the stdout as a string"
  input String command;
  output String contents;
  output Integer status;
  external "C" contents=System_popen(OpenModelica.threadData(), command, status) annotation(Library = "omcruntime");
end popen;

public function systemCallParallel
  input list<String> inStrings;
  input Integer numThreads;
  output list<Integer> outIntegers;
  external "C" outIntegers=SystemImpl__systemCallParallel(inStrings,numThreads) annotation(Library = "omcruntime");
end systemCallParallel;

public function spawnCall
  input String path "The absolute path to the executable";
  input String str "The list of arguments with executable";
  output Integer outInteger;
  external "C" outInteger=SystemImpl__spawnCall(path,str) annotation(Library = "omcruntime");
end spawnCall;

public function plotCallBackDefined
  output Boolean outBoolean;
  external "C" outBoolean=SystemImpl__plotCallBackDefined(OpenModelica.threadData()) annotation(Library = "omcruntime");
end plotCallBackDefined;

public function plotCallBack
  input Boolean externalWindow;
  input String filename;
  input String title;
  input String grid;
  input String plotType;
  input String logX;
  input String logY;
  input String xLabel;
  input String yLabel;
  input String x1;
  input String x2;
  input String y1;
  input String y2;
  input String curveWidth;
  input String curveStyle;
  input String legendPosition;
  input String footer;
  input String autoScale;
  input String variables;
  external "C" SystemImpl__plotCallBack(OpenModelica.threadData(), externalWindow, filename, title, grid, plotType, logX, logY, xLabel, yLabel, x1, x2, y1, y2, curveWidth, curveStyle, legendPosition, footer, autoScale, variables) annotation(Library = "omcruntime");
end plotCallBack;

public function cd
  input String inString;
  output Integer outInteger;
  external "C" outInteger=chdir(inString) annotation(Library = "omcruntime");
end cd;

public function createDirectory
  input String inString;
  output Boolean outBool;
  external "C" outBool=SystemImpl__createDirectory(inString) annotation(Library = "omcruntime");
end createDirectory;

public function createTemporaryDirectory
  input String inPrefix;
  output String outName;
  external "C" outName=SystemImpl__createTemporaryDirectory(inPrefix) annotation(Library = "omcruntime");
end createTemporaryDirectory;

public function pwd
  output String outString;
  external "C" outString=SystemImpl__pwd() annotation(Library = "omcruntime");
end pwd;

public function readEnv "Reads the environment variable given as string, fails if variable not found"
  input String inString;
  output String outString;
  external "C" outString=System_readEnv(inString) annotation(Library = "omcruntime");
end readEnv;

public function setEnv ""
  input String varName;
  input String value;
  input Boolean overwrite "is always true on Windows, so recommended to always call it using true";
  output Integer outInteger;
  external "C" outInteger=setenv(varName,value,overwrite) annotation(Library = "omcruntime");
end setEnv;

public function subDirectories
  input String inString;
  output list<String> outStringLst;
  external "C" outStringLst=System_subDirectories(inString) annotation(Library = "omcruntime");
end subDirectories;

public function moFiles
  input String inString;
  output list<String> outStringLst;
  external "C" outStringLst=System_moFiles(inString) annotation(Library = "omcruntime");
end moFiles;

public function mocFiles
  input String inString;
  output list<String> outStringLst;
  external "C" outStringLst=System_mocFiles(inString) annotation(Library = "omcruntime");
end mocFiles;

public function getLoadModelPath
  input String className;
  input list<String> prios;
  input list<String> mps;
  input Boolean requireExactVersion = false;
  output String dir;
  output String name;
  output Boolean isDir;
  external "C" System_getLoadModelPath(className,prios,mps,requireExactVersion,dir,name,isDir) annotation(Library = "omcruntime");
end getLoadModelPath;

public function time
  output Real outReal;
  external "C" outReal=SystemImpl__time() annotation(Library = "omcruntime");
end time;

public function regularFileExists
  input String inString;
  output Boolean outBool;
  external "C" outBool = SystemImpl__regularFileExists(inString) annotation(Library = "omcruntime");
end regularFileExists;

public function removeFile "Removes a file, returns 0 if suceeds, implemented using remove() in stdio.h"
  input String fileName;
  output Integer res;
  external "C" res=SystemImpl__removeFile(fileName) annotation(Library = "omcruntime");
end removeFile;

public function directoryExists
  input String inString;
  output Boolean outBool;
  external "C" outBool=SystemImpl__directoryExists(inString) annotation(Library = "omcruntime");
end directoryExists;

public function copyFile
  input String source;
  input String destination;
  output Boolean outBool;
  external "C" outBool=SystemImpl__copyFile(source, destination) annotation(Library = "omcruntime");
end copyFile;


public function removeDirectory
  input String inString;
  output Boolean outBool;
algorithm
  outBool := System.removeDirectory_dispatch(inString);
  // oh Windows crap: stat fails on very long paths!
  if (not outBool) then
    if Autoconf.os == "Windows_NT" then
      // try rm as that somehow works on long paths
      outBool := (0 == System.systemCall("rm -r " + inString));
    end if;
  end if;
end removeDirectory;

protected function removeDirectory_dispatch
  input String inString;
  output Boolean outBool;
  external "C" outBool=SystemImpl__removeDirectory(inString) annotation(Library = "omcruntime");
end removeDirectory_dispatch;

public function getClassnamesForSimulation
  output String outString;
  external "C" outString=System_getClassnamesForSimulation() annotation(Library = "omcruntime");
end getClassnamesForSimulation;

public function setClassnamesForSimulation
  input String inString;
  external "C" System_setClassnamesForSimulation(inString) annotation(Library = "omcruntime");
end setClassnamesForSimulation;

public function getVariableValue
  input Real timeStamp;
  input list<Real> timeValues;
  input list<Real> varValues;
  output Real outValue;
  external "C" outValue=System_getVariableValue(timeStamp,timeValues,varValues) annotation(Library = "omcruntime");
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
  external "C" outValue=System_getFileModificationTime(fileName) annotation(Library = "omcruntime");
end getFileModificationTime;

public function getCurrentTime
"@author adrpo
 this system function returns current time elapsed
 since the Epoch (00:00:00 UTC, January 1, 1970)."
  output Real outValue;
  external "C" outValue=SystemImpl__getCurrentTime() annotation(Library = "omcruntime");
end getCurrentTime;

public function getCurrentDateTime
"@author Frenkel TUD
 this system function returns current time elapsed
 since the Epoch (00:00:00 UTC, January 1, 1970)."
  output Integer sec;
  output Integer min;
  output Integer hour;
  output Integer mday;
  output Integer mon;
  output Integer year;
  external "C" System_getCurrentDateTime(sec,min,hour,mday,mon,year) annotation(Library = "omcruntime");
end getCurrentDateTime;

public function getCurrentTimeStr "
returns current time in format Www Mmm dd hh:mm:ss yyyy
using the asctime() function in time.h (libc)
"
  output String timeStr;
  external "C" timeStr=System_getCurrentTimeStr() annotation(Library = "omcruntime");
end getCurrentTimeStr;

public function readFileNoNumeric
  input String inString;
  output String outString;
  external "C" outString=SystemImpl__readFileNoNumeric(inString) annotation(Library = "omcruntime");
end readFileNoNumeric;

public function setHasExpandableConnectors
"@author: adrpo
 sets the external flag that signals the
 presence of expandable connectors in a model"
  input Boolean hasExpandable;
  external "C" System_setHasExpandableConnectors(hasExpandable) annotation(Library = "omcruntime");
end setHasExpandableConnectors;

public function getHasExpandableConnectors
"@author: adrpo
 retrieves the external flag that signals the
 presence of expandable connectors in a model"
  output Boolean hasExpandable;
  external "C" hasExpandable = System_getHasExpandableConnectors() annotation(Library = "omcruntime");
end getHasExpandableConnectors;

public function setHasOverconstrainedConnectors
"@author: adrpo
 sets the external flag that signals the
 presence of overconstrained connectors in a model"
  input Boolean hasOverconstrained;
  external "C" System_setHasOverconstrainedConnectors(hasOverconstrained) annotation(Library = "omcruntime");
end setHasOverconstrainedConnectors;

public function getHasOverconstrainedConnectors
"@author: adrpo
 retrieves the external flag that signals the
 presence of overconstrained connectors in a model"
  output Boolean hasOverconstrained;
  external "C" hasOverconstrained = System_getHasOverconstrainedConnectors() annotation(Library = "omcruntime");
end getHasOverconstrainedConnectors;

public function setPartialInstantiation
"@author: adrpo
 sets the external flag that signals the
 presence of expandable connectors in a model"
  input Boolean isPartialInstantiation;
  external "C" System_setPartialInstantiation(isPartialInstantiation) annotation(Library = "omcruntime");
end setPartialInstantiation;

public function getPartialInstantiation
"@author: adrpo
 retrieves the external flag that signals the
 presence of expandable connectors in a model"
  output Boolean isPartialInstantiation;
  external "C" isPartialInstantiation=System_getPartialInstantiation() annotation(Library = "omcruntime");
end getPartialInstantiation;

public function setHasStreamConnectors
"@author: adrpo
 sets the external flag that signals the
 presence of stream connectors in a model"
  input Boolean hasStream;
  external "C" System_setHasStreamConnectors(hasStream) annotation(Library = "omcruntime");
end setHasStreamConnectors;

public function getHasStreamConnectors
"@author: adrpo
 retrieves the external flag that signals the
 presence of stream connectors in a model"
  output Boolean hasStream;
  external "C" hasStream=System_getHasStreamConnectors() annotation(Library = "omcruntime");
end getHasStreamConnectors;

public function setUsesCardinality
  "Sets the external flag that signals the use of the cardinality operator."
  input Boolean inUses;
  external "C" System_setUsesCardinality(inUses) annotation(Library = "omcruntime");
end setUsesCardinality;

public function getUsesCardinality
  "Retrieves the external flag that signals the use of the cardinality operator."
  output Boolean outUses;
  external "C" outUses=System_getUsesCardinality() annotation(Library = "omcruntime");
end getUsesCardinality;

public function setHasInnerOuterDefinitions
"@author: adrpo
 sets the external flag that signals the presence
 of inner/outer comoponent definitions in a model"
  input Boolean hasInnerOuterDefinitions;
  external "C" System_setHasInnerOuterDefinitions(hasInnerOuterDefinitions) annotation(Library = "omcruntime");
end setHasInnerOuterDefinitions;

public function getHasInnerOuterDefinitions
"@author: adrpo
 retrieves the external flag that signals the presence
 of inner/outer comoponent definitions in a model"
  output Boolean hasInnerOuterDefinitions;
  external "C" hasInnerOuterDefinitions=System_getHasInnerOuterDefinitions() annotation(Library = "omcruntime");
end getHasInnerOuterDefinitions;

public function tmpTick
  "returns a tick that can be reset"
  output Integer tickNo;
algorithm
  tickNo := tmpTickIndex(index=0);
end tmpTick;

public function tmpTickReset
  "resets the tick so it restarts on start"
  input Integer start;
  external "C" SystemImpl_tmpTickReset(OpenModelica.threadData(),start) annotation(Library = "omcruntime");
end tmpTickReset;

public function tmpTickIndex
  "returns a tick that can be reset. TODO: remove me when bootstrapped (default argument index=0)"
  input Integer index;
  output Integer tickNo;
  external "C" tickNo = SystemImpl_tmpTickIndex(OpenModelica.threadData(),index) annotation(Library = "omcruntime");
end tmpTickIndex;

public function tmpTickIndexReserve
  "returns a tick that can be reset and reserves N values in it.
   TODO: remove me when bootstrapped (default argument index=0)"
  input Integer index;
  input Integer reserve "current tick + reserve";
  output Integer tickNo;
  external "C" tickNo = SystemImpl_tmpTickIndexReserve(OpenModelica.threadData(),index,reserve) annotation(Library = "omcruntime");
end tmpTickIndexReserve;

public function tmpTickResetIndex
  "resets the tick so it restarts on start. TODO: remove me when bootstrapped (default argument index=0)"
  input Integer start;
  input Integer index;
  external "C" SystemImpl_tmpTickResetIndex(OpenModelica.threadData(),start,index) annotation(Library = "omcruntime");
end tmpTickResetIndex;

public function tmpTickSetIndex
  "sets the index, like tmpTickResetIndex, but does not reset the maximum counter"
  input Integer start;
  input Integer index;
  external "C" SystemImpl_tmpTickSetIndex(OpenModelica.threadData(),start,index) annotation(Library = "omcruntime");
end tmpTickSetIndex;

public function tmpTickMaximum
  "returns the max tick since the last reset"
  input Integer index;
  output Integer maxIndex;
  external "C" maxIndex=SystemImpl_tmpTickMaximum(OpenModelica.threadData(),index) annotation(Library = "omcruntime");
end tmpTickMaximum;

public function userIsRoot
"Returns true if the current user is root.
Used by main to disable running omc as root as it is very dangerous.
Consider opening a socket and letting anyone run system() commands without authentication. As root."
  output Boolean isRoot;
  external "C" isRoot=System_userIsRoot() annotation(Library = "omcruntime");
end userIsRoot;

public function getuid
  output Integer uid;
  external "C" uid=System_getuid() annotation(Library = "omcruntime");
end getuid;

public function realtimeTick
"Tock returns the time since the last tock; undefined if tick was never called.
The clock index is 0-31. The function fails if the number is out of range."
  input Integer clockIndex;
  external "C" System_realtimeTick(clockIndex) annotation(Library = "omcruntime");
end realtimeTick;

public function realtimeTock
"Tock returns the time since the last tock, undefined if tick was never called.
The clock index is 0-31. The function fails if the number is out of range."
  input Integer clockIndex;
  output Real outTime;
  external "C" outTime = System_realtimeTock(clockIndex) annotation(Library = "omcruntime");
end realtimeTock;

public function realtimeClear
"Clears the timer.
The clock index is 0-31. The function fails if the number is out of range."
  input Integer clockIndex;
  external "C" System_realtimeClear(clockIndex) annotation(Library = "omcruntime");
end realtimeClear;

public function realtimeNtick
"Returns the number of ticks since last clear.
The clock index is 0-31. The function fails if the number is out of range."
  input Integer clockIndex;
  output Integer n;
  external "C" n = System_realtimeNtick(clockIndex) annotation(Library = "omcruntime");
end realtimeNtick;

function resetTimer
"@autor: adrpo
  this function will reset the timer to 0."
  external "C" System_resetTimer() annotation(Library = "omcruntime");
end resetTimer;

function startTimer
"@autor: adrpo
  this function will start counting the time
  that should be aggregated."
  external "C" System_startTimer() annotation(Library = "omcruntime");
end startTimer;

function stopTimer
"@autor: adrpo
  this function will stop counting the time
  that should be aggregated."
  external "C" System_stopTimer() annotation(Library = "omcruntime");
end stopTimer;

function getTimerIntervalTime
"@autor: adrpo
  this function will return the time that
  passed between the last [startTimer,stopTimer] interval.
  Notice that if start/stop are called recursively this
  function will return the time passed between the
  corresponding intervals.
  Example:
  (start1,
    (start2,
      (start3, stop3) call getTimerIntervalTime -> (stop3-start3)
     stop2) call getTimerIntervalTime -> (stop2-start2)
   stop1)  call getTimerIntervalTime -> (stop1-start1)"
  output Real timerIntervalTime;
  external "C" timerIntervalTime=System_getTimerIntervalTime() annotation(Library = "omcruntime");
end getTimerIntervalTime;

function getTimerCummulatedTime
"@autor: adrpo
  this function will return the cummulated time
  by adding all the interval times [startTimer,stopTimer].
  Note that if you have recursive calls to start/stop
  this function will not return the *correct* time.
  Example:
   Recursive:
     (start1, (start2, (start3, stop3) stop2) stop1)
     getTimerCummulatedTime =
       stop3-start3 + stop2-start2 + stop1-start1.
   Serial:
     (start1, stop1) (start2, stop2) (start3, stop3)
     getTimerCummulatedTime =
       stop3-start3 + stop2-start2 + stop1-start1."
  output Real timerCummulatedTime;
  external "C" timerCummulatedTime=System_getTimerCummulatedTime() annotation(Library = "omcruntime");
end getTimerCummulatedTime;

function getTimerElapsedTime
"@autor: adrpo
  this function will return the time
  passed since the first call to startTimeer
  Example:
    (start1, (start2, (start3, stop3), stop2) ...
    getTimerSinceFirstStartTime = timeNow-start1."
  output Real timerElapsedTime;
  external "C" timerElapsedTime=System_getTimerElapsedTime() annotation(Library = "omcruntime");
end getTimerElapsedTime;

function getTimerStackIndex
"@autor: adrpo
  this function will return number of
  times start/stop was called recursively.
  You can use this function for pretty printing.
  Example:
     index 0
    (start1, index 1
       (start2, index 2
          (start3, index 3
           stop3), index 2
        stop2) index 1
     stop1) index 0"
  output Integer stackIndex;
  external "C" stackIndex=System_getTimerStackIndex() annotation(Library = "omcruntime");
end getTimerStackIndex;


public function getUUIDStr "creates the Globally Unique IDentifier and return it as String"
  output String uuidStr;
  external "C" uuidStr=System_getUUIDStr() annotation(Library = "omcruntime");
end getUUIDStr;

public function basename
"Returns the name of the file without any leading directory path.
See man 3 basename."
  input String filename;
  output String base;
  // We need to strdup the input, so we can't use basename() directly
  external "C" base = System_basename(filename) annotation(Library = "omcruntime");
end basename;

public function dirname
"Returns the name of the file without any leading directory path.
See man 3 dirname."
  input String filename;
  output String base;
  // We need to strdup the input, so we can't use basename() directly
  external "C" base = System_dirname(filename) annotation(Library = "omcruntime");
end dirname;

public function escapedString
"Because list() requires escape-sequences to be in the AST, we need to be
able to unescape them in some places of the code."
  input String unescapedString;
  input Boolean unescapeNewline;
  output String escapedString;
  external "C" escapedString=System_escapedString(unescapedString,unescapeNewline) annotation(Library = "omcruntime");
end escapedString;

public function unescapedString
"Because list() requires escape-sequences to be in the AST, we need to be
able to unescape them in some places of the code."
  input String escapedString;
  output String unescapedString;
  external "C" unescapedString=System_unescapedString(escapedString) annotation(Library = "omcruntime");
end unescapedString;

public function unescapedStringLength
"Calculates the C string length of the input, if the input was used as a string
literal in C. For example unescapedStringLength('\"')=1, unescapedStringLength('ab')=2."
  input String unescapedString;
  output Integer length;
  external "C" length=SystemImpl__unescapedStringLength(unescapedString) annotation(Library = "omcruntime");
end unescapedStringLength;

public function unquoteIdentifier
  "Quoted identifiers, for example 'xyz' need to be translated into canonical form; for example _omcQuot_0x2778797A27"
  input String str;
  output String outStr;
  external "C" outStr=System_unquoteIdentifier(str) annotation(Library = "omcruntime");
end unquoteIdentifier;

public function forceQuotedIdentifier
  "Forced quoted identifiers, for example xyz is translated into canonical form; for example _omcQuot_0x78797A"
  input String str;
  output String outStr;
  external "C" outStr=System_forceQuotedIdentifier(str) annotation(Library = "omcruntime");
end forceQuotedIdentifier;

public function intMaxLit "Returns the maximum integer that can be represent using this version of the compiler"
  output Integer outInt;
  external "builtin" outInt=intMaxLit();
end intMaxLit;

public function realMaxLit "Returns the maximum integer that can be represent using this version of the compiler"
  output Real outReal;
  external "builtin" outReal=realMaxLit();
end realMaxLit;

public function uriToClassAndPath "Handles modelica:// and file:// URI's. The result is an absolute path on the local system.
  The result depends on the current MODELICAPATH. Sets the error buffer on failure."
  input String uri;
  output String scheme "file:// or modelica://, in lower-case";
  output String classname "empty if file:// is used";
  output String pathname;
  external "C" System_uriToClassAndPath(uri,scheme,classname,pathname) annotation(Library = "omcruntime");
end uriToClassAndPath;

public function modelicaPlatform "Returns the standardized platform name according to the Modelica specification:
  win32 [Microsoft Windows 32 bit]
  win64 [Microsoft Windows 64 bit]
  i386-pc-linux [Linux Intel 32 bit]
  x64_86-linux  [Linux Intel 64 bit]
  Else, the openModelicaPlatform() is returned
  "
  output String platform;
  external "C" platform=System_modelicaPlatform() annotation(Library = "omcruntime");
end modelicaPlatform;

public function openModelicaPlatform "
  Returns uname -sm (with spaces replaced by dashes and only lower-case letters) on Unix platforms
  mingw32 or mingw64 is returned for OMDev mingw
  "
  output String platform;
  external "C" platform=System_openModelicaPlatform() annotation(Library = "omcruntime");
end openModelicaPlatform;

public function gccDumpMachine "
  Returns gcc -dumpmachine
  "
  output String machine;
  external "C" machine=System_gccDumpMachine() annotation(Library = "omcruntime");
end gccDumpMachine;

public function gccVersion "
  Returns gcc --version
  "
  output String version;
  external "C" version=System_gccVersion() annotation(Library = "omcruntime");
end gccVersion;

public function dgesv
 "# dgesv from LAPACK

  ## Purpose
  DGESV computes the solution to a real system of linear equations
    A * X = B,
  where A is an N-by-N matrix and X and B are N-by-NRHS matrices.

  The LU decomposition with partial pivoting and row interchanges is
  used to factor A as
    A = P * L * U,
  where P is a permutation matrix, L is unit lower triangular, and U is
  upper triangular. The factored form of A is then used to solve the
  system of equations A * X = B.

  ## Return values
  ### output list<Real> X
  On exit, if info = 0, the N-by-NRHS solution matrix X.

  ### output Integer info
  = 0:  successful exit
  < 0:  if INFO = -i, the i-th argument had an illegal value
  > 0:  if INFO = i, U(i,i) is exactly zero. The factorization
        has been completed, but the factor U is exactly
        singular, so the solution could not be computed.
  "
  input list<list<Real>> A;
  input list<Real> B;
  output list<Real> X;
  output Integer info;
  external "C" info=SystemImpl__dgesv(A,B,X) annotation(Library = {"omcruntime","Lapack"});
end dgesv;

public function lpsolve55
  "lpsolve55"
  input list<list<Real>> A;
  input list<Real> B;
  input list<Integer> intIndices;
  output list<Real> X;
  output Integer info;
  external "C" info=SystemImpl__lpsolve55(A,B,intIndices,X) annotation(Library = {"omcruntime"});
end lpsolve55;

public function reopenStandardStream
  input Integer _stream "stdin,stdout,stderr";
  input String filename;
  output Boolean success;
  external "C" success=SystemImpl__reopenStandardStream(_stream,filename) annotation(Library = {"omcruntime"});
end reopenStandardStream;

function iconv "The iconv() function converts one multibyte characters from one character
  set to another.
  See man (3) iconv for more information.
"
  input String string;
  input String from;
  input String to;
  output String result;
external "C" result=SystemImpl__iconv(string,from,to,true /* Print errors */) annotation(Library = {"omcruntime"});
end iconv;

function snprintff "sprintf format string that takes one double as argument"
  input String format;
  input Integer maxlen;
  input Real val;
  output String str;
external "C" str=System_snprintff(format,maxlen,val) annotation(Library = {"omcruntime"});
end snprintff;

function sprintff
  "sprintf format string that takes one double as argument, but unlike snprintff
   it takes no buffer size as argument.

   NOTE: This function doesn't actually call sprintf, since that would be unsafe.
         It instead calls snprintf with a fixed buffer size that should be enough
         for most cases, and if that fails it resizes the buffer to the size
         snprintf said it needed and calls snprintf again."
  input String format;
  input Real val;
  output String str;
external "C" str = System_sprintff(format, val) annotation(Library = {"omcruntime"});
end sprintff;

public function realRand
  "Returns a value in the intervals (0,1]"
  output Real r;

  external "C" r = SystemImpl__realRand() annotation(Library = {"omcruntime"});
end realRand;

public function intRand
  "Returns a integer value in the interval (0,n].
  The number of possible values is n, the maximum value n-1."
  input Integer n;
  output Integer i;
algorithm
  i := integer(realRand()*n);
end intRand;

public function intRandom
  "Returns a value in the interval [0,n)"
  input Integer n;
  output Integer ret;
algorithm
  ret := intMod(intRandom0(), n);
end intRandom;

protected function intRandom0
  "Returns a value in the intervals [0,RAND_MAX) using the C method rand()."
  output Integer ret;

  external "C"  ret = rand() annotation(Include = "#include <stdlib.h>");
end intRandom0;

public function gettextInit
  "Choose a locale for subsequent gettext calls. Prints warnings on failures."
  input String locale = "" "Empty string choses automatically from the environment";
  external "C" SystemImpl__gettextInit(locale) annotation(Library = {"omcruntime"});
end gettextInit;

public function gettext
  "Translate a string from msgid to msgstr using the language of the chosen locale"
  input String msgid;
  output String msgstr;
  external "C" msgstr = SystemImpl__gettext(msgid) annotation(Library = {"omcruntime"});
end gettext;

public function anyStringCode
  "Takes any boxed input"
  input Any any;
  output String str;
  replaceable type Any subtypeof Any;
  external "C" str = anyStringCode(any);
end anyStringCode;

public function numBits
  output Integer n;
  external "C" n=architecture_numbits() annotation(Include="#define architecture_numbits() (8*sizeof(void*))");
end numBits;

public function realpath
  input String path;
  output String fullpath;
  external "C" fullpath = System_realpath(path) annotation(Library = {"omcruntime"});
end realpath;

public function getSimulationHelpText
  input Boolean detailed=false;
  input Boolean sphinx=false;
  output String text;
  external "C" text = System_getSimulationHelpTextSphinx(detailed,sphinx) annotation(Library = {"omcruntime"});
end getSimulationHelpText;

public function getTerminalWidth
  output Integer width;
  external "C" width = System_getTerminalWidth() annotation(Library = {"omcruntime"});
end getTerminalWidth;

public function fileIsNewerThan
  input String file1;
  input String file2;
  output Boolean result;
  external "C" result = System_fileIsNewerThan(file1,file2) annotation(Library = {"omcruntime"});
end fileIsNewerThan;

public function fileContentsEqual
  input String file1;
  input String file2;
  output Boolean result;
  external "C" result = SystemImpl__fileContentsEqual(file1,file2) annotation(Library = {"omcruntime"});
end fileContentsEqual;

public function rename
  input String source;
  input String dest;
  output Boolean result;
  external "C" result = SystemImpl__rename(source,dest) annotation(Library = {"omcruntime"});
end rename;

public function numProcessors
  output Integer result;
  external "C" result = System_numProcessors() annotation(Library = {"omcruntime"});
end numProcessors;

public function launchParallelTasks "Takes a list of inputs and produces a list of Boolean (true if the function call was successful). The function is called by not using forks (experimental version using threads because fork doesn't play nice). Only returns if all functions return."
  input Integer numThreads;
  input list<AnyInput> inData;
  input ForkFunction func;
  output list<AnyOutput> result;
  partial function ForkFunction
    input AnyInput inData;
    output AnyOutput outData;
  end ForkFunction;
  replaceable type AnyInput subtypeof Any;
  replaceable type AnyOutput subtypeof Any;
external "C" result = System_launchParallelTasks(OpenModelica.threadData(), numThreads, inData, func) annotation(Library = {"omcruntime"});
end launchParallelTasks;

public function exit "Exits the compiler at this point with the given exit status."
  input Integer status;
external "C" exit(status) annotation(Include = "#include <stdlib.h>");
end exit;

public function threadWorkFailed "Exits the current thread with a failure."
  external "C" System_threadFail(OpenModelica.threadData());
end threadWorkFailed;

public function getMemorySize
  output Real memory(unit="MB");
external "C" memory=System_getMemorySize() annotation(Library = {"omcruntime"});
end getMemorySize;

public function initGarbageCollector "this needs to be called first in Main.mo"
external "C" System_initGarbageCollector() annotation(Library = {"omcruntime"});
end initGarbageCollector;

public function ctime
  input Real t;
  output String str;
external "C" str=SystemImpl__ctime(t) annotation(Library = {"omcruntime"},Documentation(info="<html>
<p>Like <a href=\"http://linux.die.net/man/3/ctime\">ctime(3)</a>, except the input is of type real because of limited precision of Integer.</p>
</html>"));
end ctime;

public function stat
  input String filename;
  output Boolean success;
  output Real st_size; /* An integer stored as double for higher precision  */
  output Real st_mtime; /* An integer stored as double for higher precision  */
external "C" success=SystemImpl__stat(filename,st_size,st_mtime) annotation(Library = {"omcruntime"},Documentation(info="<html>
<p>Like <a href=\"http://linux.die.net/man/2/stat\">stat(2)</a>, except the output is of type real because of limited precision of Integer.</p>
</html>"));
end stat;

public function alarm
  input Integer seconds;
  output Integer previousAlarm;
external "C" previousAlarm=SystemImpl__alarm(seconds) annotation(Library = {"omcruntime"},Documentation(info="<html>
<p>Like <a href=\"http://linux.die.net/man/2/alarm\">alarm(2)</a>.</p>
</html>"));
end alarm;

public function covertTextFileToCLiteral
  input String textFile;
  input String outFile;
  input String target "this would be what is set for +target=msvc|gcc";
  output Boolean success;
external "C" success=SystemImpl__covertTextFileToCLiteral(textFile, outFile, target);
end covertTextFileToCLiteral;

public function dladdr<T>
  input T symbol "Function pointer";
  output String info;
  output String file;
  output String name;
algorithm
  (file,name) := _dladdr(symbol);
  info := file + ": " + name;
protected

function _dladdr<T>
  input T symbol "Function pointer";
  output String file;
  output String name;
external "C" SystemImpl__dladdr(symbol, file, name) annotation(Library = {"omcruntime"},Documentation(info="<html>
<p>Like <a href=\"http://linux.die.net/man/3/dladdr\">dladdr(3)</a>.</p>
<p>Only works on Linux. Other platforms return dummy strings.</p>.
</html>"));
end _dladdr;
annotation(Documentation(info="<html>
<p>Like <a href=\"http://linux.die.net/man/3/dladdr\">dladdr(3)</a>.</p>
<p>Only works on Linux. Other platforms return dummy strings.</p>.
</html>"));
end dladdr;

class StringAllocator
  extends ExternalObject;
  function constructor
    input Integer sz;
    output StringAllocator str;
  external "C" str=StringAllocator_constructor(sz) annotation(Include="
void* StringAllocator_constructor(int sz)
{
  if (sz < 0) {
    MMC_THROW();
  }
  return mmc_alloc_scon(sz);
}
");
  end constructor;
  function destructor
    input StringAllocator str;
  algorithm
    /* Nothing */
  end destructor;
end StringAllocator;

function stringAllocatorStringCopy
  input StringAllocator dest;
  input String source;
  input Integer destOffset=0;
external "C" om_stringAllocatorStringCopy(dest,source,destOffset) annotation(Include="
void om_stringAllocatorStringCopy(void *dest, char *source, int destOffset) {
  if (*source) {
    strcpy(MMC_STRINGDATA(dest)+destOffset, source);
  }
}
", Documentation(info="<html>
<p>Does a strcpy into the (input) destination. This is dangerous and not valid Modelica.</p>
<p>Make sure the String has been allocated properly and is not shared. The input lengths are not validated, so this function can write out of bounds if called incorrectly.</p>
</html>"));
end stringAllocatorStringCopy;

function stringAllocatorResult<T>
  input StringAllocator sa;
  input T dummy "This is just added so we do not make an extra allocation for the string" annotation(__OpenModelica_UnusedVariable=true);
  output T res;
external "C" res=om_stringAllocatorResult(sa) annotation(Include="
void* om_stringAllocatorResult(void *sa) {
  return sa;
}
");
end stringAllocatorResult;

function relocateFunctions
  input String fileName "shared object";
  input list<tuple<String,String>> names "tuple of names to relocate; first is the local name and second is the name in the shared object";
  output Boolean res;
external "C" res=SystemImpl__relocateFunctions(fileName, names) annotation(Library = {"omcruntime"},Documentation(info="<html>
<p>Update symbols in the running program to ones defined in the given shared object.</p>
<p>This will hot-swap the functions at run-time, enabling a smart build system to do some incremental compilation
(as long as the function interfaces are the same).</p>
</html>"));
end relocateFunctions;

function fflush
external "C" SystemImpl__fflush() annotation(Include = "
#include <stdio.h>
void SystemImpl__fflush(void)
{
  fflush(NULL);
}
",Documentation(info="<html>
<p>This function will call fflush(NULL) to flush all buffers.</p>
</html>"));
end fflush;

function updateUriMapping
  input array<String> namesAndDirs;
external "C" OpenModelica_updateUriMapping(OpenModelica.threadData(), namesAndDirs) annotation(Documentation(info="<html>
<p>Used to set the mapping from package names to directories, for loadResource. Part of the C runtime.</p>
<p>Odd indexes are names and even indexes are the corresponding directory.</p>
</html>"));
end updateUriMapping;

function getSizeOfData<T>
  input T data;
  output Real sz;
  output Real raw_sz "The size without granule overhead";
  output Real nonSharedStringSize "The size that could be saved if String sharing was enabled";
external "C" sz=SystemImpl__getSizeOfData(data, raw_sz, nonSharedStringSize) annotation(Library = {"omcruntime"}, Documentation(info="<html>
Counts the number of bytes that were allocated to hold the given data structure.
Includes constant data and handles cycles.
</html>"));
end getSizeOfData;

annotation(__OpenModelica_Interface="util");
end System;
