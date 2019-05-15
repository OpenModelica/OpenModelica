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


encapsulated package IOStreamExt
"file:        IOStreamExt.mo
 package:     IOStreamExt
 description: External Stream Utilities
 @author:     Adrian Pop [adrpo@ida.liu.se]
 @date:       2010-05-19


 This package describes an external interface for streams.
 The external C implementation is in TOP/Compiler/runtime/IOStreamExt.c"

function createFile
  input String fileName;
  output Integer fileID;

  external "C" fileID=IOStreamExt_createFile(fileName) annotation(Library = "omcruntime");
end createFile;

function closeFile
  input Integer fileID;

  external "C" IOStreamExt_closeFile(fileID) annotation(Library = "omcruntime");
end closeFile;

function deleteFile
  input Integer fileID;

  external "C" IOStreamExt_deleteFile(fileID) annotation(Library = "omcruntime");
end deleteFile;

function clearFile
  input Integer fileID;

  external "C" IOStreamExt_clearFile(fileID) annotation(Library = "omcruntime");
end clearFile;

function appendFile
  input Integer fileID;
  input String inString;

  external "C" IOStreamExt_appendFile(fileID,inString) annotation(Library = "omcruntime");
end appendFile;

function readFile
  input Integer fileID;
  output String outString;

  external "C" outString=IOStreamExt_readFile(fileID) annotation(Library = "omcruntime");
end readFile;

function printFile
  input Integer fileID;
  input Integer whereToPrint "stdout:1, stderr:2";

  external "C" IOStreamExt_printFile(fileID,whereToPrint) annotation(Library = "omcruntime");
end printFile;

function createBuffer
  output Integer bufferID;

  external "C" bufferID = IOStreamExt_createBuffer() annotation(Library = "omcruntime");
end createBuffer;

function appendBuffer
  input Integer bufferID;
  input String inString;

  external "C" IOStreamExt_appendBuffer(bufferID,inString) annotation(Library = "omcruntime");
end appendBuffer;

function deleteBuffer
  input Integer bufferID;

  external "C" IOStreamExt_deleteBuffer(bufferID) annotation(Library = "omcruntime");
end deleteBuffer;

function clearBuffer
  input Integer bufferID;

  external "C" IOStreamExt_clearBuffer(bufferID) annotation(Library = "omcruntime");
end clearBuffer;

function readBuffer
  input Integer bufferID;
  output String outString;

  external "C" outString=IOStreamExt_readBuffer(bufferID) annotation(Library = "omcruntime");
end readBuffer;

function printBuffer
  input Integer bufferID;
  input Integer whereToPrint "stdout:1, stderr:2";

  external "C" IOStreamExt_printBuffer(bufferID,whereToPrint) annotation(Library = "omcruntime");
end printBuffer;

function appendReversedList
  input list<String> inStringLst;
  output String outString;

  external "C" outString = IOStreamExt_appendReversedList(inStringLst) annotation(Library = "omcruntime");
end appendReversedList;

function printReversedList
  input list<String> inStringLst;
  input Integer whereToPrint "stdout:1, stderr:2";

  external "C" IOStreamExt_printReversedList(inStringLst, whereToPrint) annotation(Library = "omcruntime");
end printReversedList;

annotation(__OpenModelica_Interface="util");
end IOStreamExt;
