
#ifdef __MINGW32__

#include "../winruntime/corbaimpl_stub.cpp"

#else

extern "C" {
#include "rml.h"
#include "../values.h"
#include <stdio.h>
#include "../absyn_builder/yacclib.h"
#include <pthread.h>
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


RML_BEGIN_LABEL(Corba__wait_5ffor_5fcommand)
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

#endif /* MINGW32 */