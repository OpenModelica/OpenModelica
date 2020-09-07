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

#include <iostream>
#include <fstream>
#include <queue>
#include <deque>
#include <list>
#include <string.h>
#include <stdlib.h>
#include <utility>
#include "errorext.h"
#include "openmodelica.h"
#include "meta/meta_modelica.h"
#include "util/omc_error.h"
#include "util/ModelicaUtilitiesExtra.h"

using namespace std;

const char* ErrorLevel_toStr(int ix) {
  const char* toStr[4] = {"Internal error","Error","Warning","Notification"};
  if (ix<0 || ix>=4) return "#Internal Error: Unknown ErrorLevel#";
  return toStr[ix];
}

const char* ErrorType_toStr(int ix) {
  const char* toStr[6] = {"SYNTAX","GRAMMAR","TRANSLATION","SYMBOLIC","RUNTIME","SCRIPTING"};
  if (ix<0 || ix>=6) return "#Internal Error: Unknown ErrorType#";
  return toStr[ix];
}

#include "ErrorMessage.hpp"

typedef struct errorext_struct {
  bool pop_more_on_rollback;
  int numErrorMessages;
  int numWarningMessages;
  deque<ErrorMessage*> *errorMessageQueue; // Global variable of all error messages.
  vector<pair<int,string> > *checkPoints; // a checkpoint has a message index no, and a unique identifier
  string *lastDeletedCheckpoint;
  int showErrorMessages;
} errorext_members;

#include <pthread.h>

pthread_once_t errorext_once_create_key = PTHREAD_ONCE_INIT;
pthread_key_t errorExtKey;

static void free_error(void *data)
{
  errorext_members *members = (errorext_members *) data;
  if (data == NULL) return;
  delete members->errorMessageQueue;
  delete members->checkPoints;
  delete members->lastDeletedCheckpoint;
  free(members);
}

static void make_key()
{
  pthread_key_create(&errorExtKey,free_error);
}

static errorext_members* getMembers(threadData_t *threadData)
{
  if (threadData && threadData->localRoots[LOCAL_ROOT_ERROR_MO]) {
    return (errorext_members*) threadData->localRoots[LOCAL_ROOT_ERROR_MO];
  }
  pthread_once(&errorext_once_create_key,make_key);
  errorext_members *res = (errorext_members*) pthread_getspecific(errorExtKey);
  if (res != NULL) return res;
  /* We use malloc instead of new because when we do dynamic loading of functions, C++ objects in TLS might be free'd upon return to the main process. */
  res = (errorext_members*) malloc(sizeof(errorext_members));
  res->pop_more_on_rollback = false;
  res->numErrorMessages = 0;
  res->numWarningMessages = 0;
  res->errorMessageQueue = new deque<ErrorMessage*>;
  res->checkPoints = new vector<pair<int,string> >;
  res->lastDeletedCheckpoint = new string;
  res->showErrorMessages = 0;
  pthread_setspecific(errorExtKey,res);
  if (threadData) {
    /* Still use pthreads API to free the buffer on thread exit even though we pass this thing around
     * We could change this to storing the free function in MMC_CATCH_TOP, but this might be faster if we pool threads
     */
    threadData->localRoots[LOCAL_ROOT_ERROR_MO] = res;
  }
  return res;
}

static void push_message(threadData_t *threadData,ErrorMessage *msg)
{
  errorext_members *members = getMembers(threadData);
  if (members->showErrorMessages)
  {
    std::cerr << msg->getFullMessage() << std::endl;
  }
  // adrpo: ALWAYS PUSH THE ERROR MESSAGE IN THE QUEUE, even if we have showErrorMessages because otherwise the numErrorMessages is completely wrong!
  members->errorMessageQueue->push_back(msg);
  if (msg->getSeverity() == ErrorLevel_error || msg->getSeverity() == ErrorLevel_internal) members->numErrorMessages++;
  if (msg->getSeverity() == ErrorLevel_warning) members->numWarningMessages++;
}

/* pop the top of the message stack (and any duplicate messages that have also been added) */
static void pop_message(threadData_t *threadData, bool rollback)
{
  errorext_members *members = getMembers(threadData);
  bool pop_more;
  do {
    ErrorMessage *msg = members->errorMessageQueue->back();
    if (msg->getSeverity() == ErrorLevel_error || msg->getSeverity() == ErrorLevel_internal) members->numErrorMessages--;
    if (msg->getSeverity() == ErrorLevel_warning) members->numWarningMessages--;
    members->errorMessageQueue->pop_back();
    pop_more = (!(members->errorMessageQueue->empty()) && !(rollback && members->errorMessageQueue->size() <= members->checkPoints->back().first) && msg->getFullMessage() == members->errorMessageQueue->back()->getFullMessage());
    delete msg;
  } while (pop_more);
}

static void* pop_message_and_return(threadData_t *threadData, bool rollback)
{
  errorext_members *members = getMembers(threadData);
  ErrorMessage *msg = members->errorMessageQueue->back();
  if (msg->getSeverity() == ErrorLevel_error || msg->getSeverity() == ErrorLevel_internal) members->numErrorMessages--;
  if (msg->getSeverity() == ErrorLevel_warning) members->numWarningMessages--;
  members->errorMessageQueue->pop_back();
  return msg;
}

/* Adds a message with file information */
void add_source_message(threadData_t *threadData,
      int errorID,
      ErrorType type,
      ErrorLevel severity,
      const char* message,
      ErrorMessage::TokenList tokens,
      int startLine,
      int startCol,
      int endLine,
      int endCol,
      bool isReadOnly,
      const char* filename)
{
  ErrorMessage* msg = new ErrorMessage((long)errorID,
       type,
       severity,
       std::string(message),
       tokens,
       (long)startLine,
       (long)startCol,
       (long)endLine,
       (long)endCol,
       isReadOnly,
       std::string(filename));
  push_message(threadData,msg);
}

extern "C"
{

#if defined(OPENMODELICA_BOOTSTRAPPING_STAGE_1)
extern void ErrorImpl__updateCurrentComponent(threadData_t *threadData,const char* newVar, int wr, const char* fn, int rs, int re, int cs, int ce)
{
}
#endif

static void printCheckpointStack(threadData_t *threadData)
{
  errorext_members *members = getMembers(threadData);
  pair<int,string> cp;
  std::string res("");
  printf("Current Stack:\n");
  for (int i=members->checkPoints->size()-1; i>=0; i--)
  {
    cp = (*members->checkPoints)[i];
    printf("%5d %s   message:", i, cp.second.c_str());
    while(members->errorMessageQueue->size() > cp.first && !members->errorMessageQueue->empty()){
      res = members->errorMessageQueue->back()->getMessage(0)+string(" ")+res;
      pop_message(threadData,false);
    }
    printf("%s\n", res.c_str());
  }
}

extern void ErrorImpl__setCheckpoint(threadData_t *threadData,const char* id)
{
  errorext_members *members = getMembers(threadData);
  members->checkPoints->push_back(make_pair(members->errorMessageQueue->size(),string(id)));
  // fprintf(stderr, "setCheckpoint(%s)\n",id); fflush(stderr);
  //printf(" ERROREXT: setting checkpoint: (%d,%s)\n",(int)errorMessageQueue->size(),id);
}

extern void ErrorImpl__delCheckpoint(threadData_t *threadData,const char* id)
{
  errorext_members *members = getMembers(threadData);
  pair<int,string> cp;
  // fprintf(stderr, "delCheckpoint(%s)\n",id); fflush(stderr);
  if (members->checkPoints->size() > 0){
    //printf(" ERROREXT: deleting checkpoint: %d\n", checkPoints[checkPoints->size()-1]);

    // extract last checkpoint
    cp = (*members->checkPoints)[members->checkPoints->size()-1];
    if (0 != strcmp(cp.second.c_str(),id)) {
      fprintf(stderr, "ERROREXT: deleting checkpoint called with id:'%s' but top of checkpoint stack has id:'%s'\n",
          id,
          cp.second.c_str());
      printCheckpointStack(threadData);
      abort();
    }
    // remember the last deleted checkpoint
    *members->lastDeletedCheckpoint = cp.second;
    members->checkPoints->pop_back();
  }
  else{
    fprintf(stderr, " ERROREXT: nothing to delete when calling delCheckPoint(%s)\n",id);
    abort();
  }
}
extern void ErrorImpl__deleteNumCheckpoints(threadData_t *threadData, int n)
{
  errorext_members *members = getMembers(threadData);
  pair<int,string> cp;
  // fprintf(stderr, "delCheckpoint(%s)\n",id); fflush(stderr);
  if (members->checkPoints->size() < n) {
    std::cerr << "ERROREXT: calling ErrorImpl__deleteNumCheckpoints with n: " << n << " > " << members->checkPoints->size() << std::endl;
    abort();
  }
  while (--n >= 0) {
    // extract last checkpoint
    cp = (*members->checkPoints)[members->checkPoints->size()-1];
    // remember the last deleted checkpoint
    *members->lastDeletedCheckpoint = cp.second;
    members->checkPoints->pop_back();
  }
}

extern int ErrorImpl__getNumCheckpoints(threadData_t *threadData)
{
  return getMembers(threadData)->checkPoints->size();
}

extern void ErrorImpl__rollBack(threadData_t *threadData,const char* id)
{
  errorext_members *members = getMembers(threadData);
  // fprintf(stderr, "rollBack(%s)\n",id); fflush(NULL);
  if (members->checkPoints->size() > 0){
    //printf(" ERROREXT: rollback to: %d from %d\n",checkPoints->back(),errorMessageQueue->size());
    //std::string res("");
    //printf(res.c_str());
    //printf(" rollback from: %d to: %d\n",members->errorMessageQueue->size(),members->checkPoints->back().first);
    while(members->errorMessageQueue->size() > members->checkPoints->back().first && !members->errorMessageQueue->empty()){
      //printf("*** %d deleted %d ***\n",members->errorMessageQueue->size(),members->checkPoints->back().first);
      /*if(!errorMessageQueue->empty()){
        res = res+errorMessageQueue->back()->getMessage()+string("\n");
        printf( (string("Deleted: ") + res).c_str());
      }*/
      pop_message(threadData,true);
    }
    /*if(!errorMessageQueue->empty()){
      res = res+errorMessageQueue->back()->getMessage()+string("\n");
      printf("(%d)new bottom message: %s\n",checkPoints->size(),res.c_str());
    }*/
    pair<int,string> cp;
    cp = (*members->checkPoints)[members->checkPoints->size()-1];
    if (0 != strcmp(cp.second.c_str(),id)) {
      fprintf(stderr, "ERROREXT: rolling back checkpoint called with id:'%s' but top of checkpoint stack has id:'%s'\n",
          id,
          cp.second.c_str());
      printCheckpointStack(threadData);
      abort();
    }
    members->checkPoints->pop_back();
  } else {
    fprintf(stderr, "ERROREXT: caling rollback with id: %s on empty checkpoint stack\n",id);
    abort();
  }
}

extern void* ErrorImpl__pop(threadData_t *threadData,const char* id)
{
  void *lst = mmc_mk_nil();
  errorext_members *members = getMembers(threadData);
  if (members->checkPoints->size() > 0){
    while(members->errorMessageQueue->size() > members->checkPoints->back().first && !members->errorMessageQueue->empty()){
      lst = mmc_mk_cons(pop_message_and_return(threadData,true), lst);
    }
    pair<int,string> cp;
    cp = (*members->checkPoints)[members->checkPoints->size()-1];
    if (0 != strcmp(cp.second.c_str(),id)) {
      fprintf(stderr, "ERROREXT: rolling back checkpoint called with id:'%s' but top of checkpoint stack has id:'%s'\n",
          id,
          cp.second.c_str());
      printCheckpointStack(threadData);
      abort();
    }
    members->checkPoints->pop_back();
  } else {
    fprintf(stderr, "ERROREXT: caling rollback with id: %s on empty checkpoint stack\n",id);
    abort();
  }
  return lst;
}

extern void ErrorImpl__pushMessages(threadData_t *threadData, void *handles)
{
  errorext_members *members = getMembers(threadData);
  while (!listEmpty(handles)) {
    char *handle = (char*) MMC_CAR(handles);
    handles = MMC_CDR(handles);
    push_message(threadData,(ErrorMessage*) handle /* pointer was stored as Integer */);
  }
}

extern void ErrorImpl__freeMessages(threadData_t *threadData, void *handles)
{
  errorext_members *members = getMembers(threadData);
  while (!listEmpty(handles)) {
    char *handle = (char*) MMC_CAR(handles);
    handles = MMC_CDR(handles);
    free((ErrorMessage*) handle);
  }
}

extern void ErrorImpl__rollbackNumCheckpoints(threadData_t *threadData, int n)
{
  errorext_members *members = getMembers(threadData);
  if (members->checkPoints->size() < n) {
    std::cerr << "ERROREXT: calling ErrorImpl__rollbackNumCheckpoints with n: " << n << " > " << members->checkPoints->size() << std::endl;
    exit(1);
  }
  while (--n >= 0) {
    while(members->errorMessageQueue->size() > members->checkPoints->back().first && !members->errorMessageQueue->empty()){
      pop_message(threadData,true);
    }
    members->checkPoints->pop_back();
  }
}

extern char* ErrorImpl__rollBackAndPrint(threadData_t *threadData,const char* id)
{
  errorext_members *members = getMembers(threadData);
  std::string res("");
  // fprintf(stderr, "rollBackAndPrint(%s)\n",id); fflush(stderr);
  if (members->checkPoints->size() > 0){
    while(members->errorMessageQueue->size() > members->checkPoints->back().first && !members->errorMessageQueue->empty()){
      res = members->errorMessageQueue->back()->getMessage(0)+string("\n")+res;
      pop_message(threadData,true);
    }
    pair<int,string> cp;
    cp = (*members->checkPoints)[members->checkPoints->size()-1];
    if (0 != strcmp(cp.second.c_str(),id)) {
      fprintf(stderr, "ERROREXT: rolling back checkpoint called with id:'%s' but top of checkpoint stack has id:'%s'\n",
          id,
          cp.second.c_str());
      printCheckpointStack(threadData);
      abort();
    }
    members->checkPoints->pop_back();
  } else {
    fprintf(stderr, "ERROREXT: caling rollback with id: %s on empty checkpoint stack\n",id);
    abort();
  }
  // fprintf(stderr, "Returning %s\n", res.c_str());
  return strdup(res.c_str());
}

/*
 * @author: adrpo
 * checks to see if a checkpoint exists or not AS THE TOP of the stack!
 */
extern int ErrorImpl__isTopCheckpoint(threadData_t *threadData,const char* id)
{
  errorext_members *members = getMembers(threadData);
  pair<int,string> cp;
  //printf("existsCheckpoint(%s)\n",id);
  if(members->checkPoints->size() > 0){
    //printf(" ERROREXT: searching checkpoint: %d\n", checkPoints[checkPoints->size()-1]);

    // search
    cp = (*members->checkPoints)[members->checkPoints->size()-1];
    if (0 == strcmp(cp.second.c_str(),id))
    {
      // found our checkpoint, return true;
      return 1;
    }
  }
  // not found
  return 0;
}

/*
 * @author: adrpo
 * retrieves the last deleted checkpoint
 */
static const char* ErrorImpl__getLastDeletedCheckpoint(threadData_t *threadData)
{
  return getMembers(threadData)->lastDeletedCheckpoint->c_str();
}

#if !defined(OPENMODELICA_BOOTSTRAPPING_STAGE_1)
#if !defined(OMC_GENERATE_RELOCATABLE_CODE)
extern void* omc_Error_getCurrentComponent
#else
extern void* (*omc_Error_getCurrentComponent)
#endif
  (threadData_t *threadData, modelica_integer *sline, modelica_integer *scol, modelica_integer *eline, modelica_integer *ecol, modelica_integer *read_only, void **filename);
#endif

extern void c_add_message(threadData_t *threadData,int errorID, ErrorType type, ErrorLevel severity, const char* message, const char** ctokens, int nTokens)
{
  const char *str, *filename;
  modelica_integer sline, scol, eline, ecol, read_only;
  if (!threadData) {
    threadData = (threadData_t*)pthread_getspecific(mmc_thread_data_key);
  }
  ErrorMessage::TokenList tokens;
  for (int i=nTokens-1; i>=0; i--) {
    tokens.push_back(std::string(ctokens[i]));
  }
#if !defined(OPENMODELICA_BOOTSTRAPPING_STAGE_1)
  void *mmc_filename;
  str = MMC_STRINGDATA(omc_Error_getCurrentComponent(threadData, &sline, &scol, &eline, &ecol, &read_only, &mmc_filename));
  filename = MMC_STRINGDATA(mmc_filename);
#else
  sline=0;
  scol=0;
  eline=0;
  ecol=0;
  read_only=0;
  str="";
  filename="";
#endif
  ErrorMessage *msg = *(const char*)MMC_STRINGDATA(str) ?
    new ErrorMessage((long)errorID, type, severity, std::string((const char*)MMC_STRINGDATA(str)) + std::string(message), tokens, sline , scol, eline, ecol, read_only, MMC_STRINGDATA(filename)) :
    new ErrorMessage((long)errorID, type, severity, message, tokens);
  push_message(threadData,msg);
}

extern void c_add_source_message(threadData_t *threadData,int errorID, ErrorType type, ErrorLevel severity, const char* message, const char** ctokens, int nTokens, int startLine, int startCol, int endLine, int endCol, int isReadOnly, const char* filename)
{
  ErrorMessage::TokenList tokens;
  for (int i=nTokens-1; i>=0; i--) {
    tokens.push_back(std::string(ctokens[i]));
  }
  add_source_message(threadData,errorID,type,severity,message,tokens,startLine,startCol,endLine,endCol,isReadOnly,filename);
}

extern int ErrorImpl__getNumErrorMessages(threadData_t *threadData) {
  return getMembers(threadData)->numErrorMessages;
}

extern int ErrorImpl__getNumWarningMessages(threadData_t *threadData) {
  return getMembers(threadData)->numWarningMessages;
}

extern void ErrorImpl__clearMessages(threadData_t *threadData)
{
  // fprintf(stderr, "-> ErrorImpl__clearMessages error messages: %d queue size: %d\n", numErrorMessages, (int)errorMessageQueue->size()); fflush(NULL);
  while(!getMembers(threadData)->errorMessageQueue->empty()) {
    pop_message(threadData,false);
  }
}

static void* get_message_alloc(errorext_members *members)
{
  void *id = mmc_mk_icon(members->errorMessageQueue->back()->getID());
  void *ty,*severity;

  switch (members->errorMessageQueue->back()->getSeverity()) {
    case ErrorLevel_internal:     severity = Error__INTERNAL;     break;
    case ErrorLevel_error:        severity = Error__ERROR;        break;
    case ErrorLevel_warning:      severity = Error__WARNING;      break;
    case ErrorLevel_notification: severity = Error__NOTIFICATION; break;
  }

  switch (members->errorMessageQueue->back()->getType()) {
    case ErrorType_syntax:      ty=Error__SYNTAX;      break;
    case ErrorType_grammar:     ty=Error__GRAMMAR;     break;
    case ErrorType_translation: ty=Error__TRANSLATION; break;
    case ErrorType_symbolic:    ty=Error__SYMBOLIC;    break;
    case ErrorType_runtime:     ty=Error__SIMULATION;  break;
    case ErrorType_scripting:   ty=Error__SCRIPTING;   break;
  }

  void *message = Util__notrans(mmc_mk_scon(members->errorMessageQueue->back()->getShortMessage().c_str()));
  void *msg = Error__MESSAGE(id,ty,severity,message);
  void *sl = mmc_mk_icon(members->errorMessageQueue->back()->getStartLineNo());
  void *sc = mmc_mk_icon(members->errorMessageQueue->back()->getStartColumnNo());
  void *el = mmc_mk_icon(members->errorMessageQueue->back()->getEndLineNo());
  void *ec = mmc_mk_icon(members->errorMessageQueue->back()->getEndColumnNo());
  void *filename = mmc_mk_scon(members->errorMessageQueue->back()->getFileName().c_str());
  void *readonly = mmc_mk_icon(members->errorMessageQueue->back()->getIsFileReadOnly());
  void *info = SourceInfo__SOURCEINFO(filename,readonly,sl,sc,el,ec,mmc_mk_rcon(0));
  return Error__TOTALMESSAGE(msg, info);
}

// TODO: Use a string builder instead of creating intermediate results all the time?
extern void* ErrorImpl__getMessages(threadData_t *threadData)
{
  errorext_members *members = getMembers(threadData);
  void *res = mmc_mk_nil();
  while(!members->errorMessageQueue->empty()) {
    void *msg = get_message_alloc(members);
    res = mmc_mk_cons(msg, res);
    pop_message(threadData, false);
  }
  return res;
}

extern void* ErrorImpl__getCheckpointMessages(threadData_t *threadData)
{
  errorext_members *members = getMembers(threadData);
  void *res = mmc_mk_nil();

  if (members->checkPoints->size() == 0) return res;

  int id = members->checkPoints->back().first;
  while (members->errorMessageQueue->size() > id) {
    void *msg = get_message_alloc(members);
    res = mmc_mk_cons(msg, res);
    pop_message(threadData, false);
  }

  return res;
}

} // extern "C"

// TODO: Use a string builder instead of creating intermediate results all the time?
extern std::string ErrorImpl__printErrorsNoWarning(threadData_t *threadData)
{
  errorext_members *members = getMembers(threadData);
  std::string res("");
  while(!members->errorMessageQueue->empty()) {
    //if(strncmp(errorMessageQueue->back()->getSeverity(),"Error")==0){
    if(members->errorMessageQueue->back()->getSeverity() == ErrorLevel_error
        || members->errorMessageQueue->back()->getSeverity() == ErrorLevel_internal) {
      res = members->errorMessageQueue->back()->getMessage(0)+string("\n")+res;
      members->numErrorMessages--;
    }
    delete members->errorMessageQueue->back();
    members->errorMessageQueue->pop_back();
  }
  return res;
}

// TODO: Use a string builder instead of creating intermediate results all the time?
extern std::string ErrorImpl__printMessagesStr(threadData_t *threadData, int warningsAsErrors)
{
  errorext_members *members = getMembers(threadData);
  // fprintf(stderr, "-> ErrorImpl__printMessagesStr error messages: %d queue size: %d\n", numErrorMessages, (int)errorMessageQueue->size()); fflush(NULL);
  std::string res("");
  while(!members->errorMessageQueue->empty()) {
    res = members->errorMessageQueue->back()->getMessage(warningsAsErrors)+string("\n")+res;
    pop_message(threadData,false);
  }
  return res;
}

int showErrorMessages(threadData_t *threadData)
{
  return getMembers(threadData)->showErrorMessages;
}

/* Handle ModelicaFormatError called during translation (external Modelica packages, print to Error.mo instead of stdout) */
extern "C" {

void OpenModelica_ErrorModule_ModelicaVFormatError(const char *fmt, va_list ap)
{
  const char *str;
  GC_vasprintf(&str, fmt, ap);
  c_add_message(NULL,0,ErrorType_runtime,ErrorLevel_error,str,NULL,0);
  MMC_THROW();
}

void OpenModelica_ErrorModule_ModelicaError(const char *str)
{
  c_add_message(NULL,0,ErrorType_runtime,ErrorLevel_error,str,NULL,0);
  MMC_THROW();
}

void Error_moveMessagesToParentThread(threadData_t *threadData)
{
  errorext_members *thread, *parent;
  if (NULL == threadData->parent) {
    return;
  }
  thread = getMembers(threadData);
  pthread_mutex_lock(&threadData->parent->parentMutex);
  parent = getMembers(threadData->parent);
  while(!thread->errorMessageQueue->empty()) {
    parent->errorMessageQueue->push_back(thread->errorMessageQueue->front());
    thread->errorMessageQueue->pop_front();
  }
  pthread_mutex_unlock(&threadData->parent->parentMutex);
}

}
