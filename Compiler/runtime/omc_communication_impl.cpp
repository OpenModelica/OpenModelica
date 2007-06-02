/*
Copyright (c) 1998-2007, Linköpings universitet, Department of
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

// windows and mingw32
#if defined(__MINGW32__) || defined(_MSC_VER)

#include <windows.h>

extern HANDLE clientlock;

extern HANDLE omc_client_request_event;
extern HANDLE omc_return_value_ready;

char* omc_cmd_message = "";
char* omc_reply_message = "";

using namespace std;

//This is the implementation of the omc communication using mico (CORBA)

OmcCommunication_impl::OmcCommunication_impl()
{
}

char* OmcCommunication_impl::sendExpression( const char* expr )
{
  WaitForSingleObject(clientlock,INFINITE); // Lock so no other tread can talk to omc.
  //const char* retval = "";

  // Signal to omc that message has arrived. 

  omc_cmd_message = (char*)expr;
  SetEvent(omc_client_request_event);

  // Wait for omc to process message
  while(WAIT_OBJECT_0 != WaitForSingleObject(omc_return_value_ready, INFINITE));
  //retval = CORBA::string_dup(omc_reply_message); // dup the string here on this thread!
  ReleaseMutex(clientlock);
  
  return CORBA::string_dup(omc_reply_message); // Has already been string_dup (prepared for CORBA)
} 

char* OmcCommunication_impl::sendClass( const char* expr )
{
  WaitForSingleObject(clientlock,INFINITE); // Lock so no other tread can talk to omc.
  char* retval = "";

  // Signal to omc that message has arrived. 
  omc_cmd_message = (char*)expr;
  SetEvent(omc_client_request_event);

  // Wait for omc to process message
  while(WAIT_OBJECT_0 != WaitForSingleObject(omc_return_value_ready, INFINITE));
  retval = CORBA::string_dup(omc_reply_message); // dup the string here on this thread!
  ReleaseMutex(clientlock);
  
  return retval; // Has already been string_dup (prepared for CORBA) 
}

#else /* linux stuff here! */

extern "C" {
  #include <pthread.h>
}

extern pthread_cond_t omc_waitformsg;
extern pthread_mutex_t omc_waitlock;

extern bool omc_waiting;

extern pthread_cond_t corba_waitformsg;
extern pthread_mutex_t corba_waitlock;

extern bool corba_waiting;

char* omc_cmd_message = "";
char* omc_reply_message = "";

using namespace std;

//This is the implementation of the omc communication using mico (CORBA)

OmcCommunication_impl::OmcCommunication_impl()
{
}

char* OmcCommunication_impl::sendExpression( const char* expr )
{
  char* result;
  // Signal to omc that message has arrived. 
  pthread_mutex_lock(&omc_waitlock);
  omc_waiting=true;
  omc_cmd_message = (char*)expr;
  pthread_cond_signal(&omc_waitformsg);
  pthread_mutex_unlock(&omc_waitlock);

  // Wait for omc to process message
  pthread_mutex_lock(&corba_waitlock);
  while (!corba_waiting) {
    pthread_cond_wait(&corba_waitformsg,&corba_waitlock);
  }
  corba_waiting = false;
  pthread_mutex_unlock(&corba_waitlock);
  
  return CORBA::string_dup(omc_reply_message); // Has already been string_dup (prepared for CORBA)
} 

char* OmcCommunication_impl::sendClass( const char* expr )
{
  // Signal to omc that message has arrived. 
  pthread_mutex_lock(&omc_waitlock);
  omc_waiting=true;
  omc_cmd_message = (char*)expr;
  pthread_cond_signal(&omc_waitformsg);
  pthread_mutex_unlock(&omc_waitlock);

  // Wait for omc to process message
  pthread_mutex_lock(&corba_waitlock);
  
  while (!omc_waiting) {
    pthread_cond_wait(&corba_waitformsg,&corba_waitlock);
  }
  corba_waiting = false;
  pthread_mutex_unlock(&corba_waitlock);
  
  return CORBA::string_dup(omc_reply_message); // dup the string here on this thread!

}

#endif /* MINGW32 and MSVC*/
