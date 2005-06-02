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
