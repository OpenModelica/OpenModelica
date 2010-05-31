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


package IOStreamExt
"file:        IOStreamExt.mo
 package:     IOStreamExt
 description: External Stream Utilities
 @author:     Adrian Pop [adrpo@ida.liu.se]
 @date:       2010-05-19
 
 RCS: $Id: IOStreamExt.mo 5482 2010-05-10 05:56:23Z adrpo $

 This package describes an external interface for streams.
 The external C implementation is in TOP/Compiler/runtime/IOStreamExt.c"
  
function createFile
  input String fileName;  
  output Integer fileID;

  external "C";
end createFile;

function closeFile  
  input Integer fileID;

  external "C";
end closeFile;

function deleteFile  
  input Integer fileID;

  external "C";
end deleteFile;

function clearFile  
  input Integer fileID;

  external "C";
end clearFile;

function appendFile
  input Integer fileID;  
  input String inString;

  external "C";
end appendFile;

function readFile
  input Integer fileID;  
  output String outString;

  external "C";
end readFile;

function printFile
  input Integer fileID;
  input Integer whereToPrint "stdout:1, stderr:2";

  external "C";
end printFile;

function createBuffer
  output Integer bufferID;
  
  external "C";
end createBuffer;

function appendBuffer
  input Integer bufferID;  
  input String inString;

  external "C";
end appendBuffer;

function deleteBuffer  
  input Integer bufferID;

  external "C";
end deleteBuffer;

function clearBuffer  
  input Integer bufferID;

  external "C";
end clearBuffer;

function readBuffer
  input Integer bufferID;  
  output String outString;

  external "C";
end readBuffer;

function printBuffer
  input Integer bufferID;
  input Integer whereToPrint "stdout:1, stderr:2";

  external "C";
end printBuffer;

function appendReversedList
  input list<String> inStringLst;
  output String outString;
  
  external "C";
end appendReversedList;

function printReversedList
  input list<String> inStringLst;
  input Integer whereToPrint "stdout:1, stderr:2";
  
  external "C";
end printReversedList;

end IOStreamExt;