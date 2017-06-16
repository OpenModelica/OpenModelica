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

#include <sys/types.h>
#include <stdio.h>

#if defined(__MINGW32__) || defined(_MSC_VER)
#include <winsock2.h>
#include <ws2tcpip.h>

#include <unistd.h>
#include <errno.h>
#include <io.h>

int
fsync (int fd)
{
  HANDLE h = (HANDLE) _get_osfhandle (fd);
  DWORD err;

  if (h == INVALID_HANDLE_VALUE)
    {
      errno = EBADF;
      return -1;
    }

  if (!FlushFileBuffers (h))
    {
      /* Translate some Windows errors into rough approximations of Unix
       * errors.  MSDN is useless as usual - in this case it doesn't
       * document the full range of errors.
       */
      err = GetLastError ();
      switch (err)
       {
         /* eg. Trying to fsync a tty. */
       case ERROR_INVALID_HANDLE:
         errno = EINVAL;
         break;

       default:
         errno = EIO;
       }
      return -1;
    }

  return 0;
}

#else
#include <sys/socket.h>
#include <netinet/in.h>
#endif

#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include "errorext.h"

static int serversocket;
static unsigned fromlen;
static struct sockaddr_in clientAddr;

static int
make_socket (unsigned short int port)
{
#if defined(__MINGW32__) || defined(_MSC_VER)
  // Winsock.DLL Initialization
  WORD wVersionRequested;
  WSADATA wsaData;
  wVersionRequested = MAKEWORD(1, 1);
  if (WSAStartup (wVersionRequested, &wsaData) != 0) {
    printf("Failed to start the windows sockets!\n");
    return 0;
  }
#endif

  int sock;
  struct sockaddr_in name;
  socklen_t optlen;
  int one=1;

  /* Create the socket. */
  sock = socket (AF_INET, SOCK_STREAM, 0);
  if (sock < 0)
    {
      printf("Error creating socket\n");
      return 0;
    }

  /* Give the socket a name. */
  name.sin_family = AF_INET;
  name.sin_port = htons (port);
  name.sin_addr.s_addr = htonl (INADDR_ANY);
  if (setsockopt(sock,SOL_SOCKET,SO_REUSEADDR,(char*)&one,sizeof(int))) {
    return 0;
  }

  if (bind (sock, (struct sockaddr *) &name, sizeof (name)) < 0) {
    printf("Error binding socket\n");
    return 0;
  }
  printf("Started a tcp server on port %d\n", port);fflush(NULL);

  return sock;
}

extern int Socket_waitforconnect(int port)
{
  int ns;

  serversocket = make_socket(port);
  if (serversocket==0) {
    const char *tokens[1] = {strerror(errno)};
    c_add_message(NULL,-1,ErrorType_scripting,ErrorLevel_error,"make_socket failed: %s",tokens,1);
    return -1;
  }

  if (listen(serversocket,5)==-1) { /* Listen, pending client list length = 1 */
    const char *tokens[1] = {strerror(errno)};
    c_add_message(NULL,-1,ErrorType_scripting,ErrorLevel_error,"listen failed: %s",tokens,1);
    return -1;
  }

#if defined(__MINGW32__) || defined(_MSC_VER)
  int addr_length = sizeof(clientAddr);
  ns = accept(serversocket,(struct sockaddr *)&clientAddr, (int*)&addr_length);
#else
  ns = accept(serversocket,(struct sockaddr *)&clientAddr,&fromlen);
#endif

  if (ns < 0) {
    const char *tokens[1] = {strerror(errno)};
    c_add_message(NULL,-1,ErrorType_scripting,ErrorLevel_error,"accept failed: %s",tokens,1);
    return -1;
  }
  return ns;
}

extern char* SocketImpl_handlerequest(int sock)
{
  int bufSize=4000;
  char *tmpBuf,*buf;
  int nAdditionalElts;
  int tmpBufSize;
  int len;
  fd_set sockSet;
  struct timeval timeout={0,100000}; // 100 milliseconds timeout
  buf = (char*)malloc(bufSize+1);
  if (buf == NULL) {
    return NULL;
  }
  len = recv(sock,buf,bufSize,0);
  FD_ZERO(&sockSet);
  FD_SET(sock,&sockSet); // create fd set of
  if (len == bufSize) { // If we filled the buffer, check for more
    while ( select(sock+1,&sockSet,NULL,NULL,&timeout) > 0) {
      tmpBufSize=(int)(bufSize*1.4);
      nAdditionalElts = tmpBufSize-bufSize;
      tmpBuf=(char*)malloc(tmpBufSize);
      if (tmpBuf == NULL) {
        free(buf);
        return NULL;
      }
      memcpy(tmpBuf,buf,bufSize);
      free(buf);
      len +=recv(sock,tmpBuf+bufSize,nAdditionalElts,0);
      buf=tmpBuf;
      bufSize=tmpBufSize;
    }
  }
  buf[len]=0;
  return buf;
}

extern void Socket_close(int sock)
{
  int clerr;
  clerr=close(sock);
  if (clerr < 0) {
    perror("Socket close:");
    exit(1);
  }
}

extern void Socket_sendreply(int sock, const char* string)
{
  if(send(sock,string,strlen(string)+1,0)<0) {
    perror("sendreply:");
    exit(1);
  }
  fsync(sock);
}

extern void Socket_cleanup()
{
  int clerr;
  if ((clerr=close(serversocket))< 0 ) {
    perror("close:");
  }
}
