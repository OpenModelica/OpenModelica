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
