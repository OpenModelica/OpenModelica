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

#include <iostream>
#include <fstream>
#include <queue>
#include <stack>
#include <list>

using namespace std;

void add_message(int errorID,
		 char* type,
		 char* severity,
		 char* message,
		 std::list<std::string> tokens);

extern "C" {
  void c_add_message(int errorID,
		     char* type,
		     char* severity,
		     char* message,
		     char** ctokens,
		     int nTokens)
  {
    std::list<std::string> tokens;
    for (int i=nTokens-1; i>=0; i--) {
      tokens.push_back(std::string(ctokens[i]));
    }
    add_message(errorID,type,severity,message,tokens);
  }
}
struct absyn_info{
	std::string fn;
	bool wr;
	int rs;
	int re;
	int cs;
	int ce;
};
// if error_on is true, message is added, otherwise not.
bool error_on=true;

#include "ErrorMessage.hpp"
  std::string currVariable("");
  absyn_info finfo;
  bool haveInfo(false);
  stack<ErrorMessage*> errorMessageQueue; // Global variable of all error messages.
  vector<int> checkPoints;
  /* Adds a message without file info. */
  void add_message(int errorID,
		   char* type,
		   char* severity,
		   char* message,
		   std::list<std::string> tokens)
  {
	  std::string tmp("");
	  if(currVariable.length()>0){
	  	tmp = "Variable "+currVariable+": " +message;
	  }
	  else{
	  	tmp=message;
	  }
    if(!haveInfo){
    	ErrorMessage *msg = new ErrorMessage((long)errorID, std::string(type ), std::string(severity), /*std::string(message),*/ tmp, tokens);
    	if (errorMessageQueue.empty() ||
	    (!errorMessageQueue.empty() && errorMessageQueue.top()->getFullMessage() != msg->getFullMessage())) {
           /*std::cerr << "inserting error message "<< msg.getFullMessage() << " on variable "<< currVariable << std::endl;*/
           errorMessageQueue.push(msg);
        }
    }
    else{
    	ErrorMessage *msg = new ErrorMessage((long)errorID, std::string(type ), std::string(severity), /*std::string(message),*/ tmp, tokens,
    	    finfo.rs,finfo.cs,finfo.re,finfo.ce,finfo.wr/*not important?*/,finfo.fn);

    	if (errorMessageQueue.empty() ||
	    (!errorMessageQueue.empty() && errorMessageQueue.top()->getFullMessage() != msg->getFullMessage())) {
           /*std::cerr << "inserting error message "<< msg.getFullMessage() << " on variable "<< currVariable << std::endl;
           std::cerr << "values: " << finfo.rs << " " << finfo.ce << std::endl;*/
           errorMessageQueue.push(msg);
        }
    }
  }
 /* sets the current_variable(which is beeing instantiated) */
  void update_current_component(char* newVar,bool wr, char* fn, int rs, int re, int cs, int ce)
  {
	currVariable = std::string(newVar);
	if( (rs+re+cs+ce) > 0)
	{
		finfo.wr = wr;
		finfo.fn = fn;
		finfo.rs = rs;
		finfo.re = re;
		finfo.cs = cs;
		finfo.ce = ce;
		haveInfo = true;
	}
	else
	{haveInfo = false;}
  }
  /* Adds a message with file information */
  void add_source_message(int errorID,
			  char* type,
			  char* severity,
			  char* message,
			  std::list<std::string> tokens,
			  int startLine,
			  int startCol,
			  int endLine,
			  int endCol,
			  bool isReadOnly,
			  char* filename)
  {
    ErrorMessage* msg = new ErrorMessage((long)errorID,
		     std::string(type),
		     std::string(severity),
		     std::string(message),
		     tokens,
		     (long)startLine,
		     (long)startCol,
		     (long)endLine,
		     (long)endCol,
		     isReadOnly,
		     std::string(filename));
    if (errorMessageQueue.empty() ||
	(!errorMessageQueue.empty() && errorMessageQueue.top()->getFullMessage() != msg->getFullMessage())) {
      /*std::cerr << "inserting error message "<< msg.getFullMessage() << std::endl;*/
      errorMessageQueue.push(msg);
    }
}

extern "C"
{


#include <assert.h>
#include "rml.h"


  void ErrorExt_5finit(void)
  {
    // empty the queue.
    while(!errorMessageQueue.empty()) {
        delete errorMessageQueue.top();
    	errorMessageQueue.pop();
    }
  }
  RML_BEGIN_LABEL(ErrorExt__setCheckpoint)
  {
	  checkPoints.push_back(errorMessageQueue.size());
	  //printf(" ERROREXT: setting checkpoint: %d\n",errorMessageQueue.size());
	  RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL
  RML_BEGIN_LABEL(ErrorExt__delCheckpoint)
  {
	  if(checkPoints.size() > 0){
		  //printf(" ERROREXT: deleting checkpoint: %d\n", checkPoints[checkPoints.size()-1]);
		  checkPoints.pop_back();
	  }
	  else{
		  //printf(" ERROREXT: nothing to delete\n");
	  }
	  RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL
  RML_BEGIN_LABEL(ErrorExt__rollBack)
  {
	  if(checkPoints.size() > 0){
		  //printf(" ERROREXT: rollback to: %d from %d\n",checkPoints.back(),errorMessageQueue.size());
		  std::string res("");
		  //printf(res.c_str());
		  //printf(" rollback from: %d to: %d\n",errorMessageQueue.size(),checkPoints.back());
		  while(errorMessageQueue.size() > checkPoints.back() && errorMessageQueue.size() > 0){
			  //printf("*** %d deleted %d ***\n",errorMessageQueue.size(),checkPoints.back());
			  /*if(!errorMessageQueue.empty()){
				  res = res+errorMessageQueue.top()->getMessage()+string("\n");
				  printf( (string("Deleted: ") + res).c_str());
			  }*/
			  errorMessageQueue.pop();
		  }
		  /*if(!errorMessageQueue.empty()){
		  	res = res+errorMessageQueue.top()->getMessage()+string("\n");
		    printf("(%d)new bottom message: %s\n",checkPoints.size(),res.c_str());
		  }*/
		  checkPoints.pop_back();
	  }
	  RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL
  RML_BEGIN_LABEL(ErrorExt__errorOn)
  {
    error_on = true;
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL
  RML_BEGIN_LABEL(ErrorExt__errorOff)
  {
    error_on = false;
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL
  /* Function to give feedback to the user on which component the error is "on" */
  RML_BEGIN_LABEL(ErrorExt__updateCurrentComponent)
  {
	char* newVar = RML_STRINGDATA(rmlA0);
	bool write = RML_STRINGDATA(rmlA1);
	char* fileName = RML_STRINGDATA(rmlA2);
	int rs = RML_UNTAGFIXNUM(rmlA3);
	int re = RML_UNTAGFIXNUM(rmlA4);
	int cs = RML_UNTAGFIXNUM(rmlA5);
	int ce = RML_UNTAGFIXNUM(rmlA6);
	update_current_component(newVar,write,fileName,rs,re,cs,ce);
	RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL
  RML_BEGIN_LABEL(ErrorExt__addMessage)
  {

    int errorID = RML_UNTAGFIXNUM(rmlA0);
    char* tp = RML_STRINGDATA(rmlA1);
    char* severity = RML_STRINGDATA(rmlA2);
    char* message = RML_STRINGDATA(rmlA3);
    void* tokenlst = rmlA4;
    std::list<std::string> tokens;
    if (error_on) {
      while(RML_GETHDR(tokenlst) != RML_NILHDR) {
	tokens.push_back(string(RML_STRINGDATA(RML_CAR(tokenlst))));
	tokenlst=RML_CDR(tokenlst);
      }
      add_message(errorID,tp,severity,message,tokens);
      //printf(" Adding message, size: %d, %s\n",errorMessageQueue.size(),message);
    }
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(ErrorExt__addSourceMessage)
  {
    int errorID = RML_UNTAGFIXNUM(rmlA0);
    char* tp = RML_STRINGDATA(rmlA1);
    char* severity = RML_STRINGDATA(rmlA2);
    int sline = RML_UNTAGFIXNUM(rmlA3);
    int scol = RML_UNTAGFIXNUM(rmlA4);
    int eline = RML_UNTAGFIXNUM(rmlA5);
    int ecol = RML_UNTAGFIXNUM(rmlA6);
    bool isReadOnly = RML_UNTAGFIXNUM(rmlA7)?true:false;
    char* filename = RML_STRINGDATA(rmlA8);
    char* message = RML_STRINGDATA(rmlA9);
    void* tokenlst = rmlA10;
    std::list<std::string> tokens;

    if (error_on) {
      while(RML_GETHDR(tokenlst) != RML_NILHDR) {
	tokens.push_back(string(RML_STRINGDATA(RML_CAR(tokenlst))));
	tokenlst=RML_CDR(tokenlst);
      }

      add_source_message(errorID,tp,severity,message,tokens,sline,scol,eline,ecol,isReadOnly,filename);
    }
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(ErrorExt__getNumMessages)
    {
      rmlA0 = mk_icon((errorMessageQueue.size()));
      RML_TAILCALLK(rmlSC);
    }
  RML_END_LABEL

  RML_BEGIN_LABEL(ErrorExt__printMessagesStr)
  {
    std::string res("");
    while(!errorMessageQueue.empty()) {
      res = errorMessageQueue.top()->getMessage()+string("\n")+res;
      delete errorMessageQueue.top();
      errorMessageQueue.pop();
    }
    rmlA0 = mk_scon((char*)res.c_str());
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(ErrorExt__getMessagesStr)
  {
    std::string res("{");
    while(!errorMessageQueue.empty()) {
      res = errorMessageQueue.top()->getFullMessage()+string("\n")+res;
      delete errorMessageQueue.top();
      errorMessageQueue.pop();
    }
    res+=string("}");
    rmlA0 = mk_scon((char*)res.c_str());
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(ErrorExt__clearMessages)
   {
     while(!errorMessageQueue.empty()) {
    	delete errorMessageQueue.top();
    	errorMessageQueue.pop();
     }
     RML_TAILCALLK(rmlSC);
   }
   RML_END_LABEL
} //extern "C"
