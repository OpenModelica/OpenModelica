/*
This file is part of OpenModelica.

Copyright (c) 1998-2006, Linköpings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

* Neither the name of Linköpings universitet nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


// windows and mingw32
#if defined(__MINGW32__) || defined(_MSC_VER)

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


#else /* *********************************** UNIX IMPLEMENTATION ***********************************/

#include "rml.h"
#include <sys/types.h>
#include <sys/socket.h>
#include <stdio.h>
#include <netinet/in.h>

int 
make_socket (unsigned short int port)
{
  int sock;
  struct sockaddr_in name;
  socklen_t optlen;
  int one=1;
  
  /* Create the socket. */
  sock = socket (PF_INET, SOCK_STREAM, 0);
  if (sock < 0)
    {
      printf("Error creating socket\n");
      return 0;
    }
  
  /* Give the socket a name. */
  name.sin_family = PF_INET;
  name.sin_port = htons (port);
  name.sin_addr.s_addr = htonl (INADDR_ANY);
  if (setsockopt(sock,SOL_SOCKET,SO_REUSEADDR,(char*)&one,sizeof(int))) {
    return 0;
  }

  if (bind (sock, (struct sockaddr *) &name, sizeof (name)) < 0)
    {
      printf("Error binding socket\n");
      return 0;
    }
  
  return sock;
}


void Socket_5finit(void)
{

}

extern int errno;
int serversocket;
int fromlen;
struct sockaddr_in clientAddr;


RML_BEGIN_LABEL(Socket__waitforconnect)
{
  int port=(int) RML_UNTAGFIXNUM(rmlA0);
  int ns;
 
  serversocket = make_socket(port);
  if (serversocket==0) { 
    RML_TAILCALLK(rmlFC);
  }
  
  if (listen(serversocket,5)==-1) { /* Listen, pending client list length = 1 */ 
    perror("listen:");
    exit(1);
  }

  ns = accept(serversocket,(struct sockaddr *)&clientAddr,&fromlen);

  if (ns < 0) {
    perror("accept:");
    exit(1);
  }
  

  rmlA0=(void*)mk_icon(ns);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Socket__handlerequest)
{
  char *buf,*tmpBuf;
  int bufSize=4000;
  int nAdditionalElts;
  int tmpBufSize;
  int len;
  fd_set sockSet;
  struct timeval timeout={0,100000}; // 100 milliseconds timeout
  int sock=(int) RML_UNTAGFIXNUM(rmlA0);
  buf = (char*)malloc(bufSize+1);
  if (buf == NULL) {
    RML_TAILCALLK(rmlFC);
  }
  len = recv(sock,buf,bufSize,0);
  FD_ZERO(&sockSet);
  FD_SET(sock,&sockSet); // create fd set of 
  if (len == bufSize) { // If we filled the buffer, check for more
    while ( select(sock+1,&sockSet,NULL,NULL,&timeout) > 0) {
      tmpBufSize*=(int)(bufSize*1.4);
      nAdditionalElts = tmpBufSize-bufSize;
      tmpBuf=(char*)malloc(tmpBufSize);
      if (tmpBuf == NULL) {
	RML_TAILCALLK(rmlFC);
      }
    
      memcpy(tmpBuf,buf,bufSize);
      free(buf);
      len +=recv(sock,tmpBuf+bufSize,nAdditionalElts,0);
      buf=tmpBuf; bufSize=tmpBufSize;    
    }
  }
  buf[len]=0;
  rmlA0=(void*)mk_scon(buf);
  free(buf);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Socket__close)
{
  int sock=(int) RML_UNTAGFIXNUM(rmlA0);
  int clerr;
  clerr=close(sock);
  if (clerr < 0) {
    perror("Socket close:");
    exit(1);
  }
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(Socket__sendreply)
{
  int sock = (int) RML_UNTAGFIXNUM(rmlA0);
  char *string = RML_STRINGDATA(rmlA1);
  
  if(send(sock,string,strlen(string)+1,0)<0) {
    perror("sendreply:");
    exit(1);
  }
  fsync(sock);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Socket__cleanup)
{
  int clerr;
  if ((clerr=close(serversocket))< 0 ) {
    perror("close:");
  }  
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

#endif /* MING32 */
