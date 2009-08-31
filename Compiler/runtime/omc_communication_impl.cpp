/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linkopings University,
 * Department of Computer and Information Science,
 * SE-58183 Linkoping, Sweden.
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
 * from Linkopings University, either from the above address,
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

#include "omc_communication_impl.h"
extern "C" {
  #include <string.h>
  #include "rml.h"
}

// windows and mingw32
#if defined(__MINGW32__) || defined(_MSC_VER)

#include <windows.h>

extern HANDLE clientlock;

extern HANDLE omc_client_request_event;
extern HANDLE omc_return_value_ready;

extern char* omc_cmd_message;
extern char* omc_reply_message;

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

extern pthread_mutex_t clientlock;

extern pthread_cond_t omc_waitformsg;
extern pthread_mutex_t omc_waitlock;

extern bool omc_waiting;

extern pthread_cond_t corba_waitformsg;
extern pthread_mutex_t corba_waitlock;

extern bool corba_waiting;

extern char* omc_cmd_message;
extern char* omc_reply_message;

using namespace std;

//This is the implementation of the omc communication using mico (CORBA)

OmcCommunication_impl::OmcCommunication_impl()
{
}

char* OmcCommunication_impl::sendExpression( const char* expr )
{
  pthread_mutex_lock(&clientlock);
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
  result = CORBA::string_dup(omc_reply_message);
  pthread_mutex_unlock(&corba_waitlock);
  pthread_mutex_unlock(&clientlock);
  return result; // Has already been string_dup (prepared for CORBA)
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
