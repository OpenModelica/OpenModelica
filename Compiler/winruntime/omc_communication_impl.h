#ifndef _OMC_COMMUNICATION_IMPL_H
#define _OMC_COMMUNICATION_IMPL_H
#include "omc_communication.h"

class OmcCommunication_impl :  virtual public POA_OmcCommunication{
 public:
  OmcCommunication_impl();
  char* sendExpression( const char* expr );
  char* sendClass( const char* expr );
};
    

#endif
