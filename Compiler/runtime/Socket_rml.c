/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

// windows and mingw32
#if defined(__MINGW32__) || defined(_MSC_VER)

#include "rml.h"

void Socket_5finit(void)
{

}

extern int errno;
static int serversocket;
static unsigned int fromlen;

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


#else /* *********************************** UNIX IMPLEMENTATION ***********************************/

#include "socketimpl.c"
#include "rml.h"

void Socket_5finit(void)
{

}

RML_BEGIN_LABEL(Socket__waitforconnect)
{
  int port=(int) RML_UNTAGFIXNUM(rmlA0);
  rmlA0=(void*)mk_icon(Socket_waitforconnect(port));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Socket__handlerequest)
{
  int sock=(int) RML_UNTAGFIXNUM(rmlA0);
  char *buf = SocketImpl_handlerequest(sock);
  rmlA0=(void*)mk_scon(buf);
  free(buf);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Socket__close)
{
  int sock=(int) RML_UNTAGFIXNUM(rmlA0);
  Socket_close(sock);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(Socket__sendreply)
{
  int sock = (int) RML_UNTAGFIXNUM(rmlA0);
  char *string = RML_STRINGDATA(rmlA1);
  Socket_sendreply(sock,string);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Socket__cleanup)
{
  Socket_cleanup();
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

#endif /* MING32 */
