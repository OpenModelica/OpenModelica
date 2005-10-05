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

#include "omc_communication_impl.h"

extern "C" {
  #include "rml.h"
}

#include <windows.h>

HANDLE clientlock;

extern HANDLE omc_client_request_event;
extern HANDLE omc_return_value_ready;

extern char * omc_message;
using namespace std;

//This is the implementation of the omc communication using mico (CORBA)

OmcCommunication_impl::OmcCommunication_impl()
{
	clientlock = CreateMutex(NULL, FALSE, "clientlock");
}

char* OmcCommunication_impl::sendExpression( const char* expr )
{
  char* retval;
  WaitForSingleObject(clientlock,INFINITE); // Lock so no other tread can talk to omc.

	
	// Signal to omc that message has arrived. 

  omc_message = (char*)expr;
  SetEvent(omc_client_request_event);

  // Wait for omc to process message
  while(WAIT_OBJECT_0 != WaitForSingleObject(omc_return_value_ready, INFINITE));
  retval = omc_message;
  ReleaseMutex(clientlock);
  
  return retval; // Has already been string_dup (prepared for CORBA)
} 

char* OmcCommunication_impl::sendClass( const char* expr )
{
  char* retval;
  WaitForSingleObject(clientlock,INFINITE); // Lock so no other tread can talk to omc.
  // Signal to omc that message has arrived. 
  omc_message = (char*)expr;
  SetEvent(omc_client_request_event);

  // Wait for omc to process message
  while(WAIT_OBJECT_0 != WaitForSingleObject(omc_return_value_ready, INFINITE));
  retval = omc_message;
  ReleaseMutex(clientlock);
  
  return retval; // Has already been string_dup (prepared for CORBA)
}
