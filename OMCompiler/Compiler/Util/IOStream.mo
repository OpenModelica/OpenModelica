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


encapsulated package IOStream
"file:        IOStream.mo
 package:     IOStream
 description: IOStream Utilities
 @author:     Adrian Pop [adrpo@ida.liu.se]
 @date:       2010-05-19


 This package implement these stream types:
 - file streams   (stream as file)
 - list streams   (stream as list<String>)
 - buffer streams (stream as an external C buffer)

 A stream has a type and several functions to create,
 append, delete, close, print, or transform to string"

uniontype IOStreamType "TODO! change these to X_TYPE"
   record FILE String name; end FILE;
   record LIST end LIST;
   record BUFFER end BUFFER;
end IOStreamType;

uniontype IOStreamData
  record FILE_DATA
    Integer data;
  end FILE_DATA;

  record LIST_DATA
    list<String> data;
  end LIST_DATA;

  record BUFFER_DATA
    Integer data;
  end BUFFER_DATA;
end IOStreamData;

uniontype IOStream
  record IOSTREAM
    String name;
    IOStreamType ty;
    IOStreamData data;
  end IOSTREAM;
end IOStream;

constant Integer stdInput = 0;
constant Integer stdOutput = 1;
constant Integer stdError = 2;

constant IOStream emptyStreamOfTypeList = IOSTREAM("emptyStreamOfTypeList", LIST(), LIST_DATA({}));

protected import IOStreamExt;
protected import List;

public
function create
  input String streamName;
  input IOStreamType streamType;
  output IOStream outStream;
algorithm
  outStream := match (streamName, streamType)
    local
      String fileName;
      Integer fileID, bufferID;

    case (_, FILE(fileName))
      equation
        fileID = IOStreamExt.createFile(fileName);
      then
        IOSTREAM(streamName, streamType, FILE_DATA(fileID));

    case (_, LIST())
      then
        IOSTREAM(streamName, streamType, LIST_DATA({}));

    case (_, BUFFER())
      equation
        bufferID = IOStreamExt.createBuffer();
      then
        IOSTREAM(streamName, streamType, BUFFER_DATA(bufferID));
  end match;
end create;

function append
  input IOStream inStream;
  input String inString;
  output IOStream outStream;
algorithm
  outStream := match (inStream, inString)
    local
      list<String> listData;
      Integer fileID, bufferID;
      IOStream fStream, lStream, bStream;
      String streamName;
      IOStreamType streamType;

    case (fStream as IOSTREAM(data = FILE_DATA(fileID)), _)
      equation
        IOStreamExt.appendFile(fileID, inString);
      then
        fStream;

    case (IOSTREAM(streamName, streamType, LIST_DATA(listData)), _)
      then
        IOSTREAM(streamName, streamType, LIST_DATA(inString::listData));

    case (bStream as IOSTREAM(data = BUFFER_DATA(bufferID)), _)
      equation
        IOStreamExt.appendBuffer(bufferID, inString);
      then
        bStream;
  end match;
end append;

function appendList
  input IOStream inStream;
  input list<String> inStringList;
  output IOStream outStream;
algorithm
  outStream := List.foldr(inStringList, append, inStream);
end appendList;

function close
  input IOStream inStream;
  output IOStream outStream;
algorithm
  outStream := matchcontinue (inStream)
    local
      list<String> listData;
      Integer fileID, bufferID;
      IOStream fStream, lStream, bStream;

    case (fStream as IOSTREAM(data = FILE_DATA(fileID)))
      equation
        IOStreamExt.closeFile(fileID);
      then
        fStream;

    // close does nothing for list or buffer streams
    else inStream;
  end matchcontinue;
end close;

function delete
  input IOStream inStream;
algorithm
  _ := match (inStream)
    local
      list<String> listData;
      Integer fileID, bufferID;
      IOStream fStream, lStream, bStream;

    case (IOSTREAM(data = FILE_DATA(fileID)))
      equation
        IOStreamExt.deleteFile(fileID);
      then
        ();

    case (IOSTREAM(data = LIST_DATA()))
      then
        ();

    case (IOSTREAM(data = BUFFER_DATA(bufferID)))
      equation
        IOStreamExt.deleteBuffer(bufferID);
      then
        ();
  end match;
end delete;

function clear
  input IOStream inStream;
  output IOStream outStream;
algorithm
  outStream := matchcontinue (inStream)
    local
      list<String> listData;
      Integer fileID, bufferID;
      IOStream fStream, lStream, bStream;
      String name;
      IOStreamData data;
      IOStreamType ty;

    case (fStream as IOSTREAM(data = FILE_DATA(fileID)))
      equation
        IOStreamExt.clearFile(fileID);
      then
        fStream;

    case (IOSTREAM(name, ty, _))
      then
        IOSTREAM(name, ty, LIST_DATA({}));

    case (bStream as IOSTREAM(data = BUFFER_DATA(bufferID)))
      equation
        IOStreamExt.clearBuffer(bufferID);
      then
        bStream;
  end matchcontinue;
end clear;

function string
  input IOStream inStream;
  output String string;
algorithm
  string := match (inStream)
    local
      list<String> listData;
      Integer fileID, bufferID;
      IOStream fStream, lStream, bStream;
      String str;

    case (IOSTREAM(data = FILE_DATA(fileID)))
      equation
        str = IOStreamExt.readFile(fileID);
      then
        str;

    case (IOSTREAM(data = LIST_DATA(listData)))
      equation
        str = IOStreamExt.appendReversedList(listData);
      then
        str;

    case (IOSTREAM(data = BUFFER_DATA(bufferID)))
      equation
        str = IOStreamExt.readBuffer(bufferID);
      then
        str;
  end match;
end string;

function print
"@author: adrpo
  This function will print a string depending on the second argument
  to the standard output (1) or standard error (2).
  Use IOStream.stdOutput, IOStream.stdError constants"
  input IOStream inStream;
  input Integer whereToPrint;
algorithm
  _ := match (inStream, whereToPrint)
    local
      list<String> listData;
      Integer fileID, bufferID;
      IOStream fStream, lStream, bStream;

    case (IOSTREAM(data = FILE_DATA(fileID)), _)
      equation
        IOStreamExt.printFile(fileID, whereToPrint);
      then
        ();

    case (IOSTREAM(data = BUFFER_DATA(bufferID)), _)
      equation
        IOStreamExt.printBuffer(bufferID, whereToPrint);
      then
        ();

    case (IOSTREAM(data = LIST_DATA(listData)), _)
      equation
        IOStreamExt.printReversedList(listData, whereToPrint);
      then
        ();

  end match;
end print;

/*
TODO! Global Streams to be implemented later
IOStream.remember(IOStream, id);
IOStream = IOStream.aquire(id);
IOStream.forget(IOStream, id);
*/

annotation(__OpenModelica_Interface="util");
end IOStream;
