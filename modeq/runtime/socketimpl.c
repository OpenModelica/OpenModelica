#include "rml.h"
#include <sys/types.h>
#include <sys/socket.h>
#include <stdio.h>
#include <assert.h>
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
      perror ("socket");
      exit (1);
    }
  
  /* Give the socket a name. */
  name.sin_family = PF_INET;
  name.sin_port = htons (port);
  name.sin_addr.s_addr = htonl (INADDR_ANY);
  assert(setsockopt(sock,SOL_SOCKET,SO_REUSEADDR,(char*)&one,sizeof(int)) == 0);

  if (bind (sock, (struct sockaddr *) &name, sizeof (name)) < 0)
    {
      perror ("bind");
      exit (1);
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
  buf[len]=0;
  FD_ZERO(&sockSet);
  FD_SET(sock,&sockSet); // create fd set of 
  while ( select(1,&sockSet,NULL,NULL,&timeout) > 0) {
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
