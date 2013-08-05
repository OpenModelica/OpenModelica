#include "rml.h"
#include <stdio.h>

char* corbaSessionName;

void Corba_5finit(void)
{
}

static void errmsg() {
  fprintf(stderr, "CORBA disabled. Configure with --with-omniORB (or --with-MICO) and recompile to enable.");
}

RML_BEGIN_LABEL(Corba__setObjectReferenceFilePath)
{
  errmsg();
  RML_TAILCALLK(rmlFC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Corba__haveCorba)
{
  rmlA0 = mk_icon(0);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Corba__setSessionName)
{
  errmsg();
  RML_TAILCALLK(rmlFC);
}
RML_END_LABEL

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
