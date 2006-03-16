/*
This file is part of OpenModelica.

Copyright (c) 1998-2005, Linköpings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

* Neither the name of Linköpings universitet nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
#include <iostream>
#include <fstream>
#include <queue>


using namespace std;

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
#include "../absyn_builder/yacclib.h"
  

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
