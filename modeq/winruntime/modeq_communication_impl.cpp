/*
    Copyright PELAB, Linkoping University

    This file is part of Open Source Modelica (OSM).

    OSM is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    OSM is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with OpenModelica; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

*/

#include "modeq_communication_impl.h"

extern "C" {
  #include "rml.h"
}

#include <windows.h>


extern HANDLE modeq_client_request_event;
extern HANDLE modeq_return_value_ready;

extern char * modeq_message;
using namespace std;

//This is the implementation of the modeq communication using mico (CORBA)

ModeqCommunication_impl::ModeqCommunication_impl()
{
}

char* ModeqCommunication_impl::sendExpression( const char* expr )
{
  // Signal to modeq that message has arrived. 
  modeq_message = (char*)expr;
  SetEvent(modeq_client_request_event);

  // Wait for modeq to process message
  while(WAIT_OBJECT_0 != WaitForSingleObject(modeq_return_value_ready, INFINITE));
  
  return modeq_message; // Has already been string_dup (prepared for CORBA)
} 

char* ModeqCommunication_impl::sendClass( const char* expr )
{
  // Signal to modeq that message has arrived. 
  modeq_message = (char*)expr;
  SetEvent(modeq_client_request_event);

  // Wait for modeq to process message
  while(WAIT_OBJECT_0 != WaitForSingleObject(modeq_return_value_ready, INFINITE));
  
  return modeq_message; // Has already been string_dup (prepared for CORBA)

}
