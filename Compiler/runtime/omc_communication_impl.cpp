
#ifdef __MINGW32__

#include "../winruntime/omc_communication_impl.cpp"

#else 

#include "omc_communication_impl.h"

extern "C" {
  #include "rml.h"
  #include <pthread.h>
}

extern pthread_cond_t omc_waitformsg;
extern pthread_mutex_t omc_waitlock;

extern bool omc_waiting;

extern pthread_cond_t corba_waitformsg;
extern pthread_mutex_t corba_waitlock;

extern bool corba_waiting;

extern char * omc_message;
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
  omc_message = (char*)expr;
  pthread_cond_signal(&omc_waitformsg);
  pthread_mutex_unlock(&omc_waitlock);

  // Wait for omc to process message
  pthread_mutex_lock(&corba_waitlock);
  while (!corba_waiting) {
    pthread_cond_wait(&corba_waitformsg,&corba_waitlock);
  }
  corba_waiting = false;
  pthread_mutex_unlock(&corba_waitlock);
  
  return omc_message; // Has already been string_dup (prepared for CORBA)
} 

char* OmcCommunication_impl::sendClass( const char* expr )
{
  // Signal to omc that message has arrived. 
  pthread_mutex_lock(&omc_waitlock);
  omc_waiting=true;
  omc_message = (char*)expr;
  pthread_cond_signal(&omc_waitformsg);
  pthread_mutex_unlock(&omc_waitlock);

  // Wait for omc to process message
  pthread_mutex_lock(&corba_waitlock);
  
  while (!omc_waiting) {
    pthread_cond_wait(&corba_waitformsg,&corba_waitlock);
  }
  corba_waiting = false;
  pthread_mutex_unlock(&corba_waitlock);
  
  return omc_message; // Has already been string_dup (prepared for CORBA)

}

#endif /* MINGW32 */