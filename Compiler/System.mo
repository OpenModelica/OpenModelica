/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
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

package System
" file:	       System.mo
  package:     System
  description: This file contains runtime system specific function, which are implemented in C.

  RCS: $Id$

  This module contain a set of system calls, for e.g. compiling and
  executing stuff, reading and writing files and so on."

public import Values;

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

public function stringFind "locates substring searchStr in str. If succeeds return position, otherwise return -1"
  input String str;
  input String searchStr;
  output Integer outInteger;

  external "C" ;
end stringFind;

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

public function executeFunction
  input Integer inFuncHandle;
  input list<Values.Value> inValLst;
  output Values.Value outVal;

  external "C" ;
end executeFunction;

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

public function readPtolemyplotVariables
  input String inString;
  input String inVisVars;
  output list<String> outStringLst;

  external "C" ;
end readPtolemyplotVariables;

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

public function readPtolemyplotDataset
  input String inString;
  input list<String> inStringLst;
  input Integer inInteger;
  output Values.Value outValue;

  external "C" ;
end readPtolemyplotDataset;

public function getVariableNames
  input String modelname;
  output String variables;

  external "C";
end getVariableNames;

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

public function readEnv "Reads the environment variable given as string, fails if variable not found"
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
  output Integer outInteger "returns 0 if file exists";

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

public function os "Returns a string with the operating system name

For linux : 'linux'

For Windowns : 'Windows_NT' (the name of env var OS )

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

public function readValuesFromFile
  input String inString;
  output Values.Value outValue;

  external "C" ;
end readValuesFromFile;


end System;

