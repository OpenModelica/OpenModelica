/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
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
/*
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#ifndef GDBMIPARSER_H
#define GDBMIPARSER_H

#include <map>
#include <stdio.h>
#include <string>
#include <sstream>
#include <list>

using namespace std;

namespace GDBMIParser {

class GDBMITuple;
class GDBMIList;
class GDBMIValue
{
public:
  enum ValueType {
    NoneValue,
    ConstantValue,  /* Used for constant values. */
    TupleValue,     /* Used for tuple values. */
    ListValue       /* Used for list values. */
  };
  ValueType type;
  string value;
  GDBMITuple *miTuple;
  GDBMIList *miList;

  GDBMIValue();
  ~GDBMIValue();
};

class GDBMIResult;
typedef list<GDBMIResult*>GDBMIResultList;
class GDBMITuple
{
public:
  GDBMIResultList miResultsList;

  ~GDBMITuple();
};

typedef list<GDBMIValue*>GDBMIValueList;
class GDBMIList
{
public:
  enum ListType {
    NoneList,
    ValuesList,  /* Used for values list. */
    ResultsList  /* Used for results list. */
  };
  ListType type;
  GDBMIValueList miValuesList;
  GDBMIResultList miResultsList;

  GDBMIList();
  ~GDBMIList();
};

class GDBMIResult
{
public:
  string variable;
  GDBMIValue *miValue;

  GDBMIResult();
  ~GDBMIResult();
};

class GDBMIResultRecord
{
public:
  int token;
  string cls;
  GDBMIResultList miResultsList;
  string consoleStreamOutput;
  string logStreamOutput;

  GDBMIResultRecord();
  ~GDBMIResultRecord();
};

class GDBMIStreamRecord
{
public:
  enum StreamType {
    ConsoleStream,  /* Used for console stream output. */
    TargetStream,   /* Used for target stream output. */
    LogStream       /* Used for log stream output. */
  };
  StreamType type;
  string value;
};

class GDBMIOutOfBandRecord
{
public:
  enum OutOfBandRecordType {
    NoneRecord,
    AsyncRecord,  /* Used for async-record. */
    StreamRecord  /* Used for stream-record . */
  };
  OutOfBandRecordType type;
  GDBMIResultRecord *miResultRecord;
  GDBMIStreamRecord *miStreamRecord;

  GDBMIOutOfBandRecord();
  ~GDBMIOutOfBandRecord();
};

typedef list<GDBMIOutOfBandRecord*>GDBMIOutOfBandRecordList;
class GDBMIResponse
{
public:
  enum ResponseType {
    NoneResponse,
    OutOfBandRecordResponse,  /* Used for out-of-band record response. */
    ResultRecordResponse      /* Used for result record response. */
  };
  ResponseType type;
  GDBMIOutOfBandRecordList miOutOfBandRecordList;
  GDBMIResultRecord *miResultRecord;

  GDBMIResponse();
  ~GDBMIResponse();
};

bool printGDBMIResponse(GDBMIResponse *miResponse);
void printGDBMIOutOfBandRecordList(GDBMIOutOfBandRecordList miOutOfBandRecordList);
void printGDBMIOutOfBandRecord(GDBMIOutOfBandRecord *miOutOfBandRecord);
void printStreamRecord(GDBMIStreamRecord *miStreamRecord);
void printGDBMIResultRecord(GDBMIResultRecord *miResultRecord);
void printGDBMIResultList(GDBMIResultList miResultsList);
void printGDBMIResult(GDBMIResult *miResult);
void printGDBMIValue(GDBMIValue *miValue);
void printGDBMITuple(GDBMITuple *miTuple);
void printGDBMIList(GDBMIList *miList);

list<string> getLexerErrorsList();
void clearLexerErrorsList();
list<string> getParserErrorsList();
void clearParserErrorsList();
GDBMIResponse* parseGDBOutput(const char* data);

} // namespace GDBMIParser
#endif // GDBMIPARSER_H
