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

// if error_on is true, message is added, otherwise not.
bool error_on=true;

#include "ErrorMessage.hpp"

  queue<ErrorMessage> errorMessageQueue; // Global variable of all error messages.
  /* Adds a message without file info. */
  void add_message(int errorID,
		   char* type,
		   char* severity,
		   char* message,
		   std::list<std::string> tokens) 
  {
    ErrorMessage msg((long)errorID,
		     std::string(type ),
		     std::string(severity), 
		     std::string(message),
		     tokens);
    if (errorMessageQueue.empty() || 
	(!errorMessageQueue.empty() && errorMessageQueue.front().getFullMessage() != msg.getFullMessage())) {
      //std::cerr << "inserting error message "<< msg.getFullMessage() << std::endl;
      errorMessageQueue.push(msg);
    }
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
    ErrorMessage msg((long)errorID,
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
	(!errorMessageQueue.empty() && errorMessageQueue.front().getFullMessage() != msg.getFullMessage())) {
      //std::cerr << "inserting error message "<< msg.getFullMessage() << std::endl;
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
    while(!errorMessageQueue.empty()) errorMessageQueue.pop();
  }

  RML_BEGIN_LABEL(ErrorExt__errorOn)
  {
    error_on = true;
    RML_TAILCALLK(rmlSC);
  }

  RML_BEGIN_LABEL(ErrorExt__errorOff)
  {
    error_on = false;
    RML_TAILCALLK(rmlSC);
  }

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

  RML_BEGIN_LABEL(ErrorExt__printMessagesStr)
  {
    std::string res("");
    while(!errorMessageQueue.empty()) {
      res = res+errorMessageQueue.front().getMessage()+string("\n");
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
      res = res+errorMessageQueue.front().getFullMessage()+string("\n");
      errorMessageQueue.pop();
    }
    res+=string("}");
    rmlA0 = mk_scon((char*)res.c_str());
    RML_TAILCALLK(rmlSC);
  } 
  RML_END_LABEL


} //extern "C"
