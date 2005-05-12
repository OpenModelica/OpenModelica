#include "modeq_communication_impl.h"

extern "C" {
  #include "rml.h"
  #include <pthread.h>
}

extern pthread_cond_t modeq_waitformsg;
extern pthread_mutex_t modeq_waitlock;

extern bool modeq_waiting;

extern pthread_cond_t corba_waitformsg;
extern pthread_mutex_t corba_waitlock;

extern bool corba_waiting;

extern char * modeq_message;
using namespace std;

//This is the implementation of the modeq communication using mico (CORBA)

ModeqCommunication_impl::ModeqCommunication_impl()
{
}

char* ModeqCommunication_impl::sendExpression( const char* expr )
{
  char* result;
  // Signal to modeq that message has arrived. 
  pthread_mutex_lock(&modeq_waitlock);
  modeq_waiting=true;
  modeq_message = (char*)expr;
  pthread_cond_signal(&modeq_waitformsg);
  pthread_mutex_unlock(&modeq_waitlock);

  // Wait for modeq to process message
  pthread_mutex_lock(&corba_waitlock);
  while (!corba_waiting) {
    pthread_cond_wait(&corba_waitformsg,&corba_waitlock);
  }
  corba_waiting = false;
  pthread_mutex_unlock(&corba_waitlock);
  
  return modeq_message; // Has already been string_dup (prepared for CORBA)
} 

char* ModeqCommunication_impl::sendClass( const char* expr )
{
  // Signal to modeq that message has arrived. 
  pthread_mutex_lock(&modeq_waitlock);
  modeq_waiting=true;
  modeq_message = (char*)expr;
  pthread_cond_signal(&modeq_waitformsg);
  pthread_mutex_unlock(&modeq_waitlock);

  // Wait for modeq to process message
  pthread_mutex_lock(&corba_waitlock);
  
  while (!modeq_waiting) {
    pthread_cond_wait(&corba_waitformsg,&corba_waitlock);
  }
  corba_waiting = false;
  pthread_mutex_unlock(&corba_waitlock);
  
  return modeq_message; // Has already been string_dup (prepared for CORBA)

}

