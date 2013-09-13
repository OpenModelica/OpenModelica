/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
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

extern "C" {
#include "rml.h"
}
#include "Absyn.h"
/* Cannot include Error.h as there exists one the Simulation Runtime as well */
#include "../Error.h"
#include "../Util.h"
#include "rml.h"
#define UNBOX_OFFSET 0
#include "errorext.cpp"
extern "C" {

void ErrorExt_5finit(void)
{
}

RML_BEGIN_LABEL(ErrorExt__setCheckpoint)
{
  ErrorImpl__setCheckpoint(RML_STRINGDATA(rmlA0));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ErrorExt__delCheckpoint)
{
  ErrorImpl__delCheckpoint(RML_STRINGDATA(rmlA0));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ErrorExt__rollBack)
{
  ErrorImpl__rollBack(RML_STRINGDATA(rmlA0));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ErrorExt__isTopCheckpoint)
{
  rmlA0 = mk_bcon(ErrorImpl__isTopCheckpoint(RML_STRINGDATA(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ErrorExt__getLastDeletedCheckpoint)
{
  rmlA0 = mk_scon(ErrorImpl__getLastDeletedCheckpoint());
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

/* Function to give feedback to the user on which component the error is "on" */
RML_BEGIN_LABEL(ErrorExt__updateCurrentComponent)
{
char* newVar = RML_STRINGDATA(rmlA0);
bool write = RML_UNTAGFIXNUM(rmlA1);
char* fileName = RML_STRINGDATA(rmlA2);
int rs = RML_UNTAGFIXNUM(rmlA3);
int re = RML_UNTAGFIXNUM(rmlA4);
int cs = RML_UNTAGFIXNUM(rmlA5);
int ce = RML_UNTAGFIXNUM(rmlA6);
ErrorImpl__updateCurrentComponent(newVar,write,fileName,rs,re,cs,ce);
RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ErrorExt__addMessage)
{
  int errorID = RML_UNTAGFIXNUM(rmlA0);
  ErrorType tp = (ErrorType) (RML_UNTAGFIXNUM(rmlA1));
  ErrorLevel severity = (ErrorLevel) (RML_UNTAGFIXNUM(rmlA2));
  char* message = RML_STRINGDATA(rmlA3);
  void* tokenlst = rmlA4;
  ErrorMessage::TokenList tokens;
  while(RML_GETHDR(tokenlst) != RML_NILHDR) {
    tokens.push_back(string(RML_STRINGDATA(RML_CAR(tokenlst))));
    tokenlst=RML_CDR(tokenlst);
  }
  add_message(errorID,tp,severity,message,tokens);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ErrorExt__addSourceMessage)
{
  int errorID = RML_UNTAGFIXNUM(rmlA0);
  ErrorType tp = (ErrorType) (RML_UNTAGFIXNUM(rmlA1));
  ErrorLevel severity = (ErrorLevel) (RML_UNTAGFIXNUM(rmlA2));
  int sline = RML_UNTAGFIXNUM(rmlA3);
  int scol = RML_UNTAGFIXNUM(rmlA4);
  int eline = RML_UNTAGFIXNUM(rmlA5);
  int ecol = RML_UNTAGFIXNUM(rmlA6);
  bool isReadOnly = RML_UNTAGFIXNUM(rmlA7)?true:false;
  char* filename = RML_STRINGDATA(rmlA8);
  char* message = RML_STRINGDATA(rmlA9);
  void* tokenlst = rmlA10;
  ErrorMessage::TokenList tokens;

  while(RML_GETHDR(tokenlst) != RML_NILHDR) {
    tokens.push_back(string(RML_STRINGDATA(RML_CAR(tokenlst))));
    tokenlst=RML_CDR(tokenlst);
  }
  add_source_message(errorID,tp,severity,message,tokens,sline,scol,eline,ecol,isReadOnly,filename);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ErrorExt__getNumMessages)
{
  rmlA0 = mk_icon((getMembers()->errorMessageQueue->size()));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ErrorExt__getNumErrorMessages)
{
  rmlA0 = mk_icon(ErrorImpl__getNumErrorMessages());
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ErrorExt__printErrorsNoWarning)
{
  std::string res = ErrorImpl__printErrorsNoWarning();
  rmlA0 = mk_scon((char*)res.c_str());
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ErrorExt__printMessagesStr)
{
  std::string res = ErrorImpl__printMessagesStr();
  rmlA0 = mk_scon((char*)res.c_str());
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ErrorExt__getMessages)
{
  rmlA0 = ErrorImpl__getMessages();
  RML_TAILCALLQ(RML__list_5freverse,1);
}
RML_END_LABEL

RML_BEGIN_LABEL(ErrorExt__clearMessages)
{
  ErrorImpl__clearMessages();
 RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ErrorExt__setShowErrorMessages)
{
  showErrorMessages = RML_UNTAGFIXNUM(rmlA0) ? 1 : 0;
  RML_TAILCALLK(rmlSC);
}

} //extern "C"
