

extern "C" {
#include "rml.h"
}

#include <cstdlib>
#include <iostream>
#include <fstream>


using namespace std;


extern "C" {
  
void Corba_5finit(void)
{
}

void errmsg() {
  cerr << "CORBA disabled. Configure with --with-CORBA and recompile for enabling." << endl;
}

RML_BEGIN_LABEL(Corba__initialize)
{
  errmsg();
  RML_TAILCALLK(rmlFC);
}
RML_END_LABEL


RML_BEGIN_LABEL(Corba__waitForCommand)
{
  errmsg();
  RML_TAILCALLK(rmlFC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Corba__sendreply)
{
  errmsg();
  RML_TAILCALLK(rmlFC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Corba__close)
{
  errmsg();
  RML_TAILCALLK(rmlFC);
}
RML_END_LABEL
}
