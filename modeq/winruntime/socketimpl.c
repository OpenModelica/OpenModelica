#include "rml.h"
#include <stdio.h>
#include <assert.h>

int 
make_socket (unsigned short int port)
{
  
  return 0;
}


void Socket_5finit(void)
{

}

extern int errno;
int serversocket;
int fromlen;


RML_BEGIN_LABEL(Socket__waitforconnect)
{
  RML_TAILCALLK(rmlFC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Socket__handlerequest)
{
  RML_TAILCALLK(rmlFC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Socket__close)
{
  RML_TAILCALLK(rmlFC);
}
RML_END_LABEL


RML_BEGIN_LABEL(Socket__sendreply)
{
  RML_TAILCALLK(rmlFC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Socket__cleanup)
{
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
