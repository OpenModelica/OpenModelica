#ifndef _MODEQ_COMMUNICATION_IMPL_H
#define _MODEQ_COMMUNICATION_IMPL_H
#include "modeq_communication.h"

class ModeqCommunication_impl :  virtual public POA_ModeqCommunication{
 public:
  ModeqCommunication_impl();
  char* sendExpression( const char* expr );
  char* sendClass( const char* expr );
};
    

#endif
