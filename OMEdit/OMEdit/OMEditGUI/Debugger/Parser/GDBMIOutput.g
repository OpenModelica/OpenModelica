/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linkopings universitet, Department of Computer and Information Science,
 * SE-58183 Linkoping, Sweden.
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
 *         Adrian Pop <adrian.pop@liu.se>
 *
 * Based on gdb/mi Output Syntax defined here,
 * https://sourceware.org/gdb/current/onlinedocs/gdb/GDB_002fMI-Output-Syntax.html#GDB_002fMI-Output-Syntax
 */
/*
 * Copyright (c) 2010-2013 Ryan Sturmer
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 * The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * GDB Machine Interface Grammar for Python
 * Ryan Sturmer
 * 2009/04/20
 */

grammar GDBMIOutput;

options {
  ASTLabelType = pANTLR3_BASE_TREE;
  language = C;
}

@includes {
#include "GDBMIParser.h"
using namespace GDBMIParser;
}

result_record returns [GDBMIResultRecord* miResultRecord]
  @init {
    miResultRecord = new GDBMIResultRecord;
  }
  : (TOKEN {miResultRecord->token = atoi((char*)$TOKEN.text->chars);})? RESULT
    RESULT_CLASS {miResultRecord->cls = (char*)$RESULT_CLASS.text->chars;}
    (COMMA result {miResultRecord->miResultsList.push_back($result.miResult);})* WS* NL?
  ;

output returns [GDBMIResponse* miResponse]
  @init {
    miResponse = new GDBMIResponse;
  }
  : (out_of_band_record {miResponse->type = GDBMIResponse::OutOfBandRecordResponse; miResponse->miOutOfBandRecordList.push_back($out_of_band_record.miOutOfBandRecord);})*
    (result_record {miResponse->type = GDBMIResponse::ResultRecordResponse; miResponse->miResultRecord = $result_record.miResultRecord;})? WS* NL?
  ;

out_of_band_record returns [GDBMIOutOfBandRecord* miOutOfBandRecord]
  @init {
    miOutOfBandRecord = new GDBMIOutOfBandRecord;
  }
  : async_record {miOutOfBandRecord->type = GDBMIOutOfBandRecord::AsyncRecord; miOutOfBandRecord->miResultRecord = $async_record.miResultRecord;}
  | stream_record {miOutOfBandRecord->type = GDBMIOutOfBandRecord::StreamRecord; miOutOfBandRecord->miStreamRecord = $stream_record.miStreamRecord;}
  ;

async_record returns [GDBMIResultRecord* miResultRecord]
  : exec_async_output {miResultRecord = $exec_async_output.miResultRecord;}
  | status_async_output {miResultRecord = $status_async_output.miResultRecord;}
  | notify_async_output {miResultRecord = $notify_async_output.miResultRecord;}
  ;

exec_async_output returns [GDBMIResultRecord* miResultRecord]
  : (TOKEN {miResultRecord->token = atoi((char*)$TOKEN.text->chars);})? EXEC async_output {miResultRecord = $async_output.miResultRecord;}
  ;

status_async_output returns [GDBMIResultRecord* miResultRecord]
  : (TOKEN {miResultRecord->token = atoi((char*)$TOKEN.text->chars);})? STATUS async_output {miResultRecord = $async_output.miResultRecord;}
  ;

notify_async_output returns [GDBMIResultRecord* miResultRecord]
  : (TOKEN {miResultRecord->token = atoi((char*)$TOKEN.text->chars);})? NOTIFY async_output {miResultRecord = $async_output.miResultRecord;}
  ;

async_output returns [GDBMIResultRecord* miResultRecord]
  @init {
    miResultRecord = new GDBMIResultRecord;
  }
  : (RESULT_CLASS {miResultRecord->cls = (char*)$RESULT_CLASS.text->chars;})
    (COMMA result {miResultRecord->miResultsList.push_back($result.miResult);})* NL?
  ;

var returns [string txt]
  @init {
    string txt;
  }
  : STRING {
      txt = (char*)$STRING.text->chars;
    }
  ;

constant returns [string txt]
  @init {
    string txt;
  }
  : C_STRING {
      txt = (char*)$C_STRING.text->chars;
    }
  ;

value returns [GDBMIValue* miValue]
  @init {
    miValue = new GDBMIValue;
  }
  : constant {
      miValue->type = GDBMIValue::ConstantValue;
      miValue->value = (char*)$constant.text->chars;
    }
    | modelica_tuple {
      miValue->type = GDBMIValue::TupleValue;
      miValue->miTuple = $modelica_tuple.miTuple;
    }
    | lista {
      miValue->type = GDBMIValue::ListValue;
      miValue->miList = $lista.miList;
    }
  ;

result returns [GDBMIResult* miResult]
  @init {
    miResult = new GDBMIResult;
  }
  : (var '=' value) {
      miResult->variable = (char*)$var.text->chars;
      miResult->miValue = $value.miValue;
    }
  ;

modelica_tuple returns [GDBMITuple* miTuple]
  @init {
    miTuple = new GDBMITuple;
  }
  : '{}'
  | '{' a=result {miTuple->miResultsList.push_back(a);} (COMMA b=result {miTuple->miResultsList.push_back(b);})* '}'
  ;

stream_record returns [GDBMIStreamRecord *miStreamRecord]
  @init {
    miStreamRecord = new GDBMIStreamRecord;
  }
  : console_stream_output {miStreamRecord->type = GDBMIStreamRecord::ConsoleStream; miStreamRecord->value = $console_stream_output.txt;}
  | target_stream_output {miStreamRecord->type = GDBMIStreamRecord::TargetStream; miStreamRecord->value = $target_stream_output.txt;}
  | log_stream_output {miStreamRecord->type = GDBMIStreamRecord::LogStream; miStreamRecord->value = $log_stream_output.txt;}
  ;

lista returns [GDBMIList* miList]
  @init {
    miList = new GDBMIList;
  }
  : '[]'
  | '[' a=value {miList->type = GDBMIList::ValuesList; miList->miValuesList.push_back(a);} (COMMA b=value {miList->miValuesList.push_back(b);})* ']'
  | '[' c=result {miList->type = GDBMIList::ResultsList; miList->miResultsList.push_back(c);} (COMMA d=result {miList->miResultsList.push_back(d);})* ']'
  ;

console_stream_output returns [char* txt]
  : CONSOLE C_STRING {txt = (char*)$C_STRING.text->chars;}
  ;

target_stream_output returns [char* txt]
  : TARGET C_STRING {txt = (char*)$C_STRING.text->chars;}
  ;

log_stream_output returns [char* txt]
  : LOG C_STRING {txt = (char*)$C_STRING.text->chars;}
  ;

// LEXER

// Can't use the omission (!) operator here for some reason... weird.
C_STRING : '"' ('\\''"' | ~('"' |'\n'|'\r'))* '"';

RESULT_CLASS :
  'done'
  | 'running'
  | 'connected'
  | 'error'
  | 'exit'
  | 'stopped'
  | 'thread-group-added'
  | 'thread-group-started'
  | 'thread-group-created'
  | 'thread-created'
  | 'download'
  | 'thread-group-exited'
  | 'thread-exited'
  | 'loaded'
  | 'library-loaded'
  | 'library-unloaded'
  ;

STRING :
  ('_' | 'A'..'Z' | 'a'..'z')('-' | '_' | 'A'..'Z' | 'a'..'z'|'0'..'9')*
  ;

NL :
  ('\r')?'\n'
  ;

WS :
  (' ' | '\t')
  ;

TOKEN :
  ('0'..'9')+
  ;

COMMA :
  ','
  ;

EOM :
  '(gdb)'
  ;

CONSOLE :
  '~'
  ;
TARGET  :
  '@'
  ;
LOG :
  '&'
  ;

EXEC :
  '*'
  ;
STATUS :
  '+'
  ;
NOTIFY :
  '='
  ;

RESULT :
  '^'
  ;
